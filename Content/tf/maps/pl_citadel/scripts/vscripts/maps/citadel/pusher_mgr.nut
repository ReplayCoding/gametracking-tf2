// entity pusher manager code, for PL_Citadel
// originally by ficool2, heavily edited and expanded by Sarexicus

::ROOT <- getroottable();

if (!("Pushers" in ROOT)) {
	::PusherPlayerData <- class
	{
		constructor(_player)
		{
			player = _player;
			jumped = false;
		}

		player = null;
		pusher = null;
		origin = null;
		mins = null;
		maxs = null;
		world_mins = null;
		world_maxs = null;
		ground = null;
		jumped = null;
	};

	::PusherBuildingData <- class
	{
		constructor (_building)
		{
			building = _building;
			origin = _building.GetOrigin();
			mins = _building.GetBoundingMins();
			maxs = _building.GetBoundingMaxs();
			world_mins = origin + mins;
			world_maxs = origin + maxs;
		}

		building = null;
		origin = null;
		mins = null;
		maxs = null;
		world_mins = null;
		world_maxs = null;
	};

	::Pushers <- [];
	::PushersScopes <- [];
	::PushersPlayers <- [];
	::PushersPlayersData <- [];
	::PushersBuildingsData <- [];
	::PusherDmgOwner <- null;
	::CurrentTime <- 0.0;

	// fold netprops
	foreach (k, v in ::NetProps.getclass())
		if (k != "IsValid")
			ROOT[k] <- ::NetProps[k].bindenv(::NetProps);

	const IN_JUMP = 2;
	const TF_DEATH_FEIGN_DEATH = 32;
	const EFL_PUSHER = 1048576;
	const FSOLID_TRIGGER = 8;
	const LAST_SHARED_COLLISION_GROUP = 20;
}

if (!PusherDmgOwner || !PusherDmgOwner.IsValid()) {
	::PusherDmgOwner <- SpawnEntityFromTable("trigger_hurt", {}); // so uber doesn't protect
	PusherDmgOwner.KeyValueFromString("classname", "vehicle");
	PusherDmgOwner.RemoveSolidFlags(FSOLID_TRIGGER); // prevent console errors
}

// allow collisions with the object
::PusherFixAmmopack <- function() {
	// self.SetCollisionGroup(LAST_SHARED_COLLISION_GROUP);
	// self.KeyValueFromString("classname", "pusher_ammo"); // don't iterate it again
}

// This handles all the dirty work, just copy paste it into your code
function CollectEventsInScope(events) {
	local events_id = UniqueString()
	getroottable()[events_id] <- events
	local events_table = getroottable()[events_id]
	foreach (name, callback in events) events_table[name] = callback.bindenv(this)
	local cleanup_user_func, cleanup_event = "OnGameEvent_scorestats_accumulated_update"
	if (cleanup_event in events) cleanup_user_func = events[cleanup_event].bindenv(this)
	events_table[cleanup_event] <- function(params)
	{
		if (cleanup_user_func) cleanup_user_func(params)
		delete getroottable()[events_id]
	} __CollectGameEventCallbacks(events_table)
}

CollectEventsInScope
({
	function OnGameEvent_player_spawn(params) {
		local player = GetPlayerFromUserID(params.userid);
		if (!player)
		return;

		if (params.team & 2)
		{
			local data = PusherPlayerData(player);
			local idx = PushersPlayers.find(player);
			if (idx == null)
			{
				PushersPlayers.append(player);
				PushersPlayersData.append(data);
			}
			else
			{
				PushersPlayersData[idx] = data;
			}
		}
	}

	function OnGameEvent_player_death(params) {
		local player = GetPlayerFromUserID(params.userid);
		if (!player)
		return;

		EntFire("tf_ammo_pack", "CallScriptFunction", "PusherFixAmmopack");
		EntFire("tf_dropped_weapon", "CallScriptFunction", "PusherFixAmmopack");

		if (params.death_flags & TF_DEATH_FEIGN_DEATH)
		return;

		local idx = PushersPlayers.find(player);
		if (idx != null)
		{
			PushersPlayers.remove(idx);
			PushersPlayersData.remove(idx);
		}
	}

	function OnGameEvent_player_disconnect(params) {
		local player = GetPlayerFromUserID(params.userid);
		if (!player)
		return;

		local idx = PushersPlayers.find(player);
		if (idx != null)
		{
			PushersPlayers.remove(idx);
			PushersPlayersData.remove(idx);
		}
	}

	function OnGameEvent_player_teleported(params) {
		local player = GetPlayerFromUserID(params.userid);
		if (!player)
		return;

		// fix tilted view from teleporters placed on tilted objects
		local eye_ang = player.EyeAngles();
		if (eye_ang.z != 0.0)
		{
			eye_ang.z = 0.0;
			player.SnapEyeAngles(eye_ang);
		}
	}

	function OnGameEvent_player_builtobject(params) {
		local building = EntIndexToHScript(params.index);
		if (!building)
		return;


		// ignore moving buildings
		local moveparent = building.GetMoveParent();
		if (moveparent != null) {
			// if built on the cart, speed up building time
			if (moveparent.IsEFlagSet(EFL_PUSHER)) {
				AddBuildSpeedIncrease(building)
			}
			return;
		}

		local building_origin = building.GetOrigin();
		local trace =
		{
			start = building_origin + Vector(0, 0, 12),
			end = building_origin - Vector(0, 0, 12),
			mask = MASK_PLAYERSOLID_BRUSHONLY,
			ignore = building
		};

		TraceLineEx(trace);
		if (trace.hit && trace.enthit.IsEFlagSet(EFL_PUSHER))
		{
			building.AcceptInput("SetParent", "!activator", trace.enthit, null);
			local ang = building.GetLocalAngles();
			building.SetLocalAngles(QAngle(0, ang.y, ang.z));

			// add build buff script
			AddBuildSpeedIncrease(building);
			return;
		}

		building.ValidateScriptScope();
		local scope = building.GetScriptScope();
		if (!("data" in scope))
		scope.data <- PusherBuildingData(building);

		local idx = PushersBuildingsData.find(scope.data);
		if (idx == null)
		PushersBuildingsData.append(scope.data);
		else
		PushersBuildingsData[idx] = scope.data;
	}

	function OnGameEvent_player_carryobject(params)
	{
		PusherMgr_RemoveBuilding(EntIndexToHScript(params.index));
	}

	function OnGameEvent_object_destroyed(params)
	{
		PusherMgr_RemoveBuilding(EntIndexToHScript(params.index));
		EntFire("tf_ammo_pack", "CallScriptFunction", "PusherFixAmmopack");
	}

	function OnGameEvent_object_removed(params)
	{
		PusherMgr_RemoveBuilding(EntIndexToHScript(params.index));
	}

	function OnGameEvent_object_detonated(params)
	{
		PusherMgr_RemoveBuilding(EntIndexToHScript(params.index));
		EntFire("tf_ammo_pack", "CallScriptFunction", "PusherFixAmmopack");
	}

	// event fired before the map is cleaned up
	function OnGameEvent_scorestats_accumulated_update(params)
	{
		Pushers.clear();
		PushersScopes.clear();
		PushersBuildingsData.clear();
	}

	function OnScriptHook_OnTakeDamage(params)
	{
		if (params.const_entity && params.const_entity.GetClassname() == "tf_projectile_pipe_remote") {
			local sticky = params.const_entity;
			local player = params.attacker;

			// prevent same-team damage dislodging stickies
			if(player != null && player.GetTeam() == sticky.GetTeam()) return;

			if (sticky.GetMoveParent() && sticky.GetMoveParent().GetClassname() != "func_tracktrain_advanced") return;
			local scope = sticky.GetScriptScope();
			if("unstuck" in scope && scope.unstuck) { return; }

			if (!(params.damage_type & Constants.FDmgType.DMG_BLAST)) {
				sticky.Kill();
				return;
			}
			UnstickSticky(sticky, player);
		}

		local attacker = params.attacker;
		if (attacker && attacker.IsEFlagSet(EFL_PUSHER))
		{
			// fix damage force
			PusherDmgOwner.SetAbsOrigin(attacker.GetOrigin());
			// bypass uber
			params.inflictor = PusherDmgOwner;
		}
	}

	function OnGameEvent_object_deflected(params) {
		local sticky = EntIndexToHScript(params.object_entindex);
		local player = GetPlayerFromUserID(params.userid);

		if (sticky && sticky.GetClassname() == "tf_projectile_pipe_remote" && sticky.GetMoveParent() != null) {
			if (sticky.GetMoveParent().GetClassname() != "func_tracktrain_advanced") return;

			local force = sticky.GetOrigin() - player.GetOrigin();
			force.Norm();
			force = force * 100;

			UnstickSticky(sticky, player);
			sticky.ApplyAbsVelocityImpulse(force);
		}
	}
});

function UnstickSticky(sticky, player) {
	local scope = sticky.GetScriptScope();
	if("unstuck" in scope && scope.unstuck) { return; }
	scope.unstuck <- true;
	local pos = sticky.GetOrigin();
	sticky.AcceptInput("ClearParent", "", null, null);
	sticky.SetOrigin(pos);
	sticky.SetMoveType(6, Constants.EMoveCollide.MOVECOLLIDE_DEFAULT);
	sticky.SetPhysVelocity(Vector(0, 0, 0));

	// prevent circular logic crash - don't generate damage events while dealing blast damage
	//  as the stickybomb is looking for those to generate an unstick
	NetProps.SetPropInt(sticky, "m_takedamage", 0);

	// re-enable stickybomb physics by dealing blast damage to it
	sticky.TakeDamageEx(player, player, player, Vector(0, 0, 0), sticky.GetOrigin(), 0, 2112);

	// ! this might be causing crashes, so maybe stop generating damage events entirely
	NetProps.SetPropInt(sticky, "m_takedamage", 1);
}

function AddBuildSpeedIncrease(building) {
	if (building.GetTeam() != 3) return;

	local buildspeed = {};
	IncludeScript("maps/citadel/building_speed_increase", buildspeed);

	building.ValidateScriptScope();
	local scope = building.GetScriptScope();

	scope.Think <- buildspeed.BuildSpeedThink;
	AddThinkToEnt(building, "Think");
}

function PusherMgr_RemoveBuilding(building) {
	if (!building)
		return;

	local scope = building.GetScriptScope();
	if (!scope || !("data" in scope))
		return;

	local idx = PushersBuildingsData.find(scope.data);
	if (idx != null)
		PushersBuildingsData.remove(idx);
}

function PusherMgr_Think() {
	CurrentTime = Time();

	local data, player, buttons, ground, parent;
	foreach (data in PushersPlayersData)
	{

		player = data.player;
		data.origin = player.GetOrigin();
		data.mins = player.GetPlayerMins();
		data.maxs = player.GetPlayerMaxs();
		data.world_mins = data.origin + data.mins;
		data.world_maxs = data.origin + data.maxs;

		// apply velocity when jumping off a pusher
		if (GetPropBool(player, "m_Shared.m_bJumping"))
		{
			if (!data.jumped)
			{
				ground = data.ground;
				if (ground && ground.IsEFlagSet(EFL_PUSHER))
				{
					local scope = ground.GetScriptScope();
					if (scope.CalcTransformation())
					{
						local vel = scope.GetDisplacement(data.origin);
						SetPropVector(player, "m_vecBaseVelocity", vel);
					}
				}
				data.jumped = true;
			}
		}
		else
		{
			data.jumped = false;
		}

		// do this after the jump check because ground is gone after a jump
		data.ground = GetPropEntity(player, "m_hGroundEntity");
	}

	// update every pusher
	for (local i = PushersScopes.len() - 1; i >= 0; i--)
	{
		// failsafe
		if (!Pushers[i].IsValid())
		{
			Pushers.remove(i);
			PushersScopes.remove(i);
			continue;
		}

		local pusher_scope = PushersScopes[i];
		pusher_scope.Push();
		// invalidate transform for next frame
		pusher_scope.transform = null;

		// allow objects to react properly to pushers
		pusher_scope.StickyTest();
		pusher_scope.JarTest();
	}

	return -1;
}

AddThinkToEnt(self, "PusherMgr_Think");