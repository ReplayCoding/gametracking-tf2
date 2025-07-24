// entity pusher code w/ buildings and stickybomb support, for PL_Citadel
// originally by ficool2, heavily edited and expanded by Sarexicus

::ROOT <- getroottable();

if (!("Pusher_Init" in ROOT))
{
	const SOLID_NONE = 0;
	const SOLID_VPHYSICS = 6;
	const MASK_PLAYERSOLID_BRUSHONLY = 81931; //CONTENTS_SOLID|CONTENTS_MOVEABLE|CONTENTS_WINDOW|CONTENTS_PLAYERCLIP|CONTENTS_GRATE
	const DMG_VEHICLE_CRUSH = 17;
	const DMG_VEHICLE = 16;
	const DMG_CRUSH = 1;
	const COLLISION_GROUP_DOOR_BLOCKER = 14;
	const EFL_PUSHER = 1048576;
	const SF_ROTATING_NOT_SOLID = 64;
	const FSOLID_NOT_SOLID = 4;
	const kRenderNone = 10;

	const DEFAULT_TICKDT = 0.015;
	const DEFAUlT_TICKRATE = 66.6667; // 1/DEFAULT_TICKDT

	::StepSizeDir <- Vector(0, 0, 18);

	const DEG2RAD = 0.0174532924; // PI/180.0
	const M_00 = 00; const M_01 = 01; const M_02 = 02; const M_03 = 03;
	const M_10 = 04; const M_11 = 05; const M_12 = 06; const M_13 = 07;
	const M_20 = 08; const M_21 = 09; const M_22 = 10; const M_23 = 11;
	const M_30 = 12; const M_31 = 13; const M_32 = 14; const M_33 = 15;

	function Matrix4x4_Init(origin, angles)
	{
		local out = array(16);

		local angle, sr, sp, sy, cr, cp, cy;
		if (angles.z != 0.0)
		{

			angle = angles.y * DEG2RAD;
			sy = sin(angle);
			cy = cos(angle);
			angle = angles.x * DEG2RAD;
			sp = sin(angle);
			cp = cos(angle);
			angle = angles.z * DEG2RAD;
			sr = sin(angle);
			cr = cos(angle);

			out[M_00] = cp * cy;
			out[M_01] = sr * sp * cy + cr * -sy;
			out[M_02] = cr * sp * cy + -sr * -sy;
			out[M_03] = origin.x;
			out[M_10] = cp * sy;
			out[M_11] = sr * sp * sy + cr * cy;
			out[M_12] = cr * sp * sy +- sr * cy;
			out[M_13] = origin.y;
			out[M_20] = -sp;
			out[M_21] = sr * cp;
			out[M_22] = cr * cp;
			out[M_23] = origin.z;
			out[M_30] = 0.0;
			out[M_31] = 0.0;
			out[M_32] = 0.0;
			out[M_33] = 1.0;
		}
		else if (angles.x != 0.0)
		{
			angle = angles.y * DEG2RAD;
			sy = sin(angle);
			cy = cos(angle);
			angle = angles.x * DEG2RAD;
			sp = sin(angle);
			cp = cos(angle);

			out[M_00] = cp * cy;
			out[M_01] = -sy;
			out[M_02] = sp * cy;
			out[M_03] = origin.x;
			out[M_10] = cp * sy;
			out[M_11] = cy;
			out[M_12] = sp * sy;
			out[M_13] = origin.y;
			out[M_20] = -sp;
			out[M_21] = 0.0;
			out[M_22] = cp;
			out[M_23] = origin.z;
			out[M_30] = 0.0;
			out[M_31] = 0.0;
			out[M_32] = 0.0;
			out[M_33] = 1.0;
		}
		else if (angles.y != 0.0)
		{
			angle = angles.y * DEG2RAD;
			sy = sin(angle);
			cy = cos(angle);

			out[M_00] = cy;
			out[M_01] = -sy;
			out[M_02] = 0.0;
			out[M_03] = origin.x;
			out[M_10] = sy;
			out[M_11] = cy;
			out[M_12] = 0.0;
			out[M_13] = origin.y;
			out[M_20] = 0.0;
			out[M_21] = 0.0;
			out[M_22] = 1.0;
			out[M_23] = origin.z;
			out[M_30] = 0.0;
			out[M_31] = 0.0;
			out[M_32] = 0.0;
			out[M_33] = 1.0;
		}
		else
		{
			out[M_00] = 1.0;
			out[M_01] = 0.0;
			out[M_02] = 0.0;
			out[M_03] = origin.x;
			out[M_10] = 0.0;
			out[M_11] = 1.0;
			out[M_12] = 0.0;
			out[M_13] = origin.y;
			out[M_20] = 0.0;
			out[M_21] = 0.0;
			out[M_22] = 1.0;
			out[M_23] = origin.z;
			out[M_30] = 0.0;
			out[M_31] = 0.0;
			out[M_32] = 0.0;
			out[M_33] = 1.0;
		}

		return out;
	}

	function VectorTransform(m, v)
	{
		return Vector
		(
			v.x * m[M_00] + v.y * m[M_01] + v.z * m[M_02] + m[M_03],
			v.x * m[M_10] + v.y * m[M_11] + v.z * m[M_12] + m[M_13],
			v.x * m[M_20] + v.y * m[M_21] + v.z * m[M_22] + m[M_23]
		);
	}

	function VectorITransform(m, v)
	{
		local dir = Vector
		(
			v.x - m[M_03],
			v.y - m[M_13],
			v.z - m[M_23]
		);
		return Vector
		(
			dir.x * m[M_00] + dir.y * m[M_10] + dir.z * m[M_20],
			dir.x * m[M_01] + dir.y * m[M_11] + dir.z * m[M_21],
			dir.x * m[M_02] + dir.y * m[M_12] + dir.z * m[M_22]
		);
	}

	// this routine is critical for physics performance so excuse the ugly return
	AABBTransform_Mins <- null;
	AABBTransform_Maxs <- null;

	function AABBTransform(m, mins, maxs)
	{
		local local_center = (mins + maxs) * 0.5;
		local local_extents = maxs - local_center;
		local world_center = VectorTransform(m, local_center);

		local world_extents = Vector
		(
			fabs(local_extents.x * m[M_00]) +
			fabs(local_extents.y * m[M_01]) +
			fabs(local_extents.z * m[M_02]),
			fabs(local_extents.x * m[M_10]) +
			fabs(local_extents.y * m[M_11]) +
			fabs(local_extents.z * m[M_12]),
			fabs(local_extents.x * m[M_20]) +
			fabs(local_extents.y * m[M_21]) +
			fabs(local_extents.z * m[M_22])
		);

		AABBTransform_Mins = world_center - world_extents;
		AABBTransform_Maxs = world_center + world_extents;
	}
}

function Precache()
{
	// ensure physics object isnt created
	local flags = NetProps.GetPropInt(self, "m_spawnflags");
	NetProps.SetPropInt(self, "m_spawnflags", flags | SF_ROTATING_NOT_SOLID);
}

function OnPostSpawn()
{
	self.SetMoveType(0, 0);
	self.AddEFlags(EFL_PUSHER);
	self.RemoveSolidFlags(FSOLID_NOT_SOLID);

	pusher <- self;
	mins <- self.GetBoundingMins();
	maxs <- self.GetBoundingMaxs();
	origin <- null;
	angles <- null;
	velocity <- null;
	avelocity <- null;
	new_origin <- null;
	new_angles <- null;
	old_velocity <- null;
	old_avelocity <- null;
	transform <- null;
	new_transform <- null;
	moving <- false;

	if (!("Pushers" in ROOT))
	{
		::Pushers <- [];
		::PushersScopes <- [];
	}

	Pushers.append(self);
	PushersScopes.append(this);

	// collider for serverside physics objects
	collider_server <- SpawnEntityFromTable("func_brush",
	{
		model = self.GetModelName(),
		parentname = self.GetName(),
		origin = self.GetOrigin(),
		angles = self.GetAbsAngles(),
		spawnflags = 2
	});

	// I'm not sure how this manages to only collide with vphysics objects, but it does
	collider_server.DisableDraw();
	collider_server.SetSolid(SOLID_VPHYSICS);
	collider_server.SetCollisionGroup(COLLISION_GROUP_DOOR_BLOCKER);
}

function Distance(a, b) {
    return (a - b).Length();
}

function BlockedPlayer(player, data)
{
	player.TakeDamage(999, DMG_VEHICLE_CRUSH, pusher);
}

function BlockedBuilding(building, data)
{
	if (building == null || !building.IsValid()) return;

	building.TakeDamage(99999, DMG_VEHICLE_CRUSH, pusher);
}

function CalcTransformation()
{
	// this is very expensive so don't rebuild transforms multiple times each frame
	if (transform)
		return true;

	if (pusher == null || !pusher.IsValid()) return;

	velocity = pusher.GetAbsVelocity();
	avelocity = pusher.GetAngularVelocity();
	if (old_velocity == null) old_velocity = velocity;
	if (old_avelocity == null) old_avelocity = avelocity;

	local ov = (velocity + old_velocity).Length()
	local oav = (avelocity + old_avelocity).Length()

	// if the velocity zeroes out or flips suddenly, reset transformation movement
	if ((avelocity.LengthSqr() < 8 && velocity.LengthSqr() < 8) || (ov < 2)) {
		new_origin = pusher.GetOrigin();
		new_angles = pusher.GetAbsAngles();
		return false;
	}

	origin = pusher.GetOrigin();
	angles = pusher.GetAbsAngles();
	old_velocity = velocity;
	old_avelocity = avelocity;

	transform = Matrix4x4_Init(origin, angles);
	new_origin = origin + velocity * DEFAULT_TICKDT;
	new_angles = (angles + avelocity * DEFAULT_TICKDT) + QAngle();
	new_transform = Matrix4x4_Init(new_origin, new_angles);
	return true;
}

function GetDisplacement(pos)
{
	if (transform)
	{
		local new_pos = VectorTransform(new_transform, VectorITransform(transform, pos));
		return (new_pos - pos) * DEFAUlT_TICKRATE;
	}

	return Vector();
}

function PlayerStuckPrevention(data) {
	local player = data.player;
	local check_origin = player.GetOrigin();
	local check_mins = data.mins;
	local check_maxs = data.maxs;

	local buildings = ["obj_dispenser", "obj_sentrygun", "obj_teleporter"];

	local tr;

	tr =
	{
		start = check_origin,
		end = check_origin,
		hullmin = check_mins,
		hullmax = check_maxs,
		mask = MASK_PLAYERSOLID_BRUSHONLY | 33554432,
		ignore = player
	};
	TraceHull(tr);

	// building-specific stuck prevention
	if (tr.hit && buildings.find(tr.enthit.GetClassname()) != null) {
		return tr;
	}
	return null;
}

function NudgePlayer(tr, data, nudge_dirs, check_new_origin) {
	local on_pusher = data.ground == pusher;
	local check = data.player;
	local check_origin = data.origin;
	TraceHull(tr);

	if (tr.hit)
	{
		local blocked = true;

		// see if the blockage can be escaped in certain directions
		foreach (nudge_dir in nudge_dirs)
		{
			local nudge_origin = check_new_origin + nudge_dir;
			tr.start = nudge_origin;
			tr.end = nudge_origin;
			TraceHull(tr);

			if (tr.hit)
				continue;

			check_new_origin = nudge_origin;
			blocked = false;
			break;
		}

		if (blocked)
		{
			return;
		}
	}

	check.SetAbsOrigin(check_new_origin);
}

function PushRotateMove()
{
	pusher.SetLocalOrigin(new_origin);
	pusher.SetLocalAngles(new_angles);

	collider_server.Teleport(true, new_origin, true, new_angles, false, Vector());

	// GetBoundingMinsMaxOriented doesn't transform the AABB correctly.. sigh
	AABBTransform(new_transform, mins, maxs);
	// avoid 6 table accesses each iteration
	local pusher_mins_x = AABBTransform_Mins.x;
	local pusher_mins_y = AABBTransform_Mins.y;
	local pusher_mins_z = AABBTransform_Mins.z;
	local pusher_maxs_x = AABBTransform_Maxs.x;
	local pusher_maxs_y = AABBTransform_Maxs.y;
	local pusher_maxs_z = AABBTransform_Maxs.z;

	local forward = new_angles.Forward();
	local right = new_angles.Left();
	local up = new_angles.Up();

	// try up direction first as thats usually where stuck cases happen
	// for tilted objects, use much more aggressive nudging so passengers dont tend to die
	local nudge_dirs;
	if (new_angles.x == 0.0)
	{
		nudge_dirs =
		[
			up, forward, forward * -1.0, right, right * -1.0,
			// try moving up steps
			StepSizeDir, forward + StepSizeDir, forward * -1.0 + StepSizeDir, right + StepSizeDir, right * -1.0 + StepSizeDir,
			forward * 2.0 + StepSizeDir, forward * -2.0 + StepSizeDir, right * 2.0 + StepSizeDir, right * -2.0 + StepSizeDir,
			forward * 10.0 + StepSizeDir, forward * -10.0 + StepSizeDir, right * 10.0 + StepSizeDir, right * -10.0 + StepSizeDir,
			up * 32.0, forward * 32.0, forward * -32.0, right * 32.0, right * -32.0
		];
	}
	else
	{
		nudge_dirs =
		[
			up * 2.0, forward * 1.5, forward * -1.5, right * 1.5, right * -1.5,
			up * 5.0, forward * 5.0, forward * -5.0, right * 5.0, right * -5.0,
			up * 16.0, forward * 16.0, forward * -16.0, right * 16.0, right * -16.0,
			up * 48.0, forward * 48.0, forward * -48.0, right * 48.0, right * -48.0
		];
	}

	foreach (data in PushersPlayersData)
	{
		local check_world_mins = data.world_mins;
		local check_world_maxs = data.world_maxs;

		local check_mins = data.mins;
		local check_maxs = data.maxs;

		local check = data.player;
		local check_origin = data.origin;

		// assume we're ok if the player is far enough away from the pusher
		if (Distance(check_origin, pusher.GetOrigin()) > 384) continue;

		local tr = PlayerStuckPrevention(data);
		if (tr) {
			// inlined GetDisplacement
			local check_new_origin = check_origin + (VectorTransform(new_transform, VectorITransform(transform, check_origin)) - check_origin);

			NudgePlayer(tr, data, nudge_dirs, check_new_origin);
			continue;
		}

		// cull out outside players
		if ((check_world_mins.x > pusher_maxs_x) || (check_world_maxs.x < pusher_mins_x))
			continue;
		if ((check_world_mins.y > pusher_maxs_y) || (check_world_maxs.y < pusher_mins_y))
			continue;
		if ((check_world_mins.z > pusher_maxs_z) || (check_world_maxs.z < pusher_mins_z))
			continue;


		// assume valid position if standing on the pusher
		local on_pusher = data.ground == pusher;
		if (!on_pusher)
		{
			tr =
			{
				start = check_origin,
				end = check_origin,
				hullmin = check_mins,
				hullmax = check_maxs,
				mask = MASK_PLAYERSOLID_BRUSHONLY,
				ignore = check
			};
			TraceHull(tr);

			if (!tr.hit || tr.enthit != pusher)
				continue;
		}

		// inlined GetDisplacement
		local check_new_origin = check_origin + (VectorTransform(new_transform, VectorITransform(transform, check_origin)) - check_origin);

		// reuse previous trace table since only "hit" is checked which always gets overriden
		if (tr)
		{
			tr.start = check_new_origin;
			tr.end = check_new_origin;
		}
		else
		{
			tr =
			{
				start = check_new_origin,
				end = check_new_origin,
				hullmin = check_mins,
				hullmax = check_maxs,
				mask = MASK_PLAYERSOLID_BRUSHONLY,
				ignore = check
			};
		}
		NudgePlayer(tr, data, nudge_dirs, check_new_origin);
	}

	// check for invalid buildings and remove if necessary
	local null_invalid_pushers = [];
	for (local i = 0; i < PushersBuildingsData.len(); i++) {
		local building = PushersBuildingsData[i].building;
		if (building == null || !building.IsValid()) {
			null_invalid_pushers.push(i);
		}
	}
	for (local i = null_invalid_pushers.len() - 1; i >= 0; i--) {
		PushersBuildingsData.remove(null_invalid_pushers[i]);
	}

	foreach (data in PushersBuildingsData)
	{
		local check_world_mins = data.world_mins;
		local check_world_maxs = data.world_maxs;

		if ((check_world_mins.x > pusher_maxs_x) || (check_world_maxs.x < pusher_mins_x))
			continue;
		if ((check_world_mins.y > pusher_maxs_y) || (check_world_maxs.y < pusher_mins_y))
			continue;
		if ((check_world_mins.z > pusher_maxs_z) || (check_world_maxs.z < pusher_mins_z))
			continue;

		local check = data.building;
		local check_origin = data.origin;
		local tr =
		{
			start = check_origin,
			end = check_origin,
			hullmin = data.mins,
			hullmax = data.maxs,
			mask = MASK_PLAYERSOLID_BRUSHONLY,
			ignore = check
		};
		TraceHull(tr);

		if (tr.hit)
		{
			if (tr.enthit == pusher)
				BlockedBuilding(check, data);
		}
	}
}


function StickyTest() {
	for (local entity; entity = Entities.FindByClassname(entity, "tf_projectile_pipe_remote");) {
		if (entity.GetMoveParent() != null) continue;

		local e_origin = entity.GetOrigin();
		local p_origin = pusher.GetCenter();
		if (Distance(e_origin, p_origin) > 512) continue;
		entity.ValidateScriptScope();
		local scope = entity.GetScriptScope();
		if ("stuck" in scope && scope.stuck) continue;

		local sticky_stick_distance = 32.0;

		local v = entity.GetPhysVelocity();
		if (v.Length() == 0) continue;
		v.Norm();
		v = v * sticky_stick_distance;

		local traceTable = {
			"start": e_origin,
			"end": e_origin + v,
			"ignore": entity,
			"mask": MASK_PLAYERSOLID_BRUSHONLY
		};
		TraceLineEx(traceTable);
		if (traceTable && traceTable.hit) {
			if (traceTable.enthit == pusher) {
				entity.SetOrigin(traceTable.endpos);
				scope.stuck <- true;
				entity.AcceptInput("SetParent", "!activator", pusher, null);
				entity.SetMoveType(7, Constants.EMoveCollide.MOVECOLLIDE_DEFAULT);
				NetProps.SetPropInt(entity, "m_takedamage", 2);
				continue;
			}
		}
	}
}

function JarTest() {
	for (local entity; entity = Entities.FindByClassname(entity, "tf_projectile_jar*");) {
		local e_origin = entity.GetOrigin();
		local p_origin = pusher.GetCenter();
		if (Distance(e_origin, p_origin) > 512) continue;

		local jar_stick_distance = 16.0;

		local traceTable = {
			start = e_origin,
			end = e_origin,
			hullmin = Vector(-jar_stick_distance, -jar_stick_distance, -jar_stick_distance),
			hullmax = Vector(jar_stick_distance, jar_stick_distance, jar_stick_distance),
			mask = MASK_PLAYERSOLID_BRUSHONLY
		};
		TraceHull(traceTable);
		if (traceTable && traceTable.hit) {
			if (traceTable.enthit == pusher) {
				local origin = entity.GetOrigin();

				local vecMins = entity.GetBoundingMins();
				local vecMaxs = entity.GetBoundingMins();

				// inflate the hitbox size to forcefully detonate the jar
				local hitbox_size = 640;
				entity.SetOrigin(traceTable.endpos);
				entity.SetSize(Vector(-hitbox_size, -hitbox_size, -hitbox_size), Vector(hitbox_size, hitbox_size, hitbox_size));
				entity.SetMoveType(Constants.EMoveType.MOVETYPE_FLY, Constants.EMoveCollide.MOVECOLLIDE_DEFAULT);
			}
		}
	}
}


function Push() {
	if (CalcTransformation()) {
		PushRotateMove();
	}
}

function Unpreserve() {
    // engineers are hardcoded to not allow building on tracktrain entities. change the entity name here
    NetProps.SetPropString(self, "m_iClassname", "func_tracktrain_advanced");
}

Unpreserve();