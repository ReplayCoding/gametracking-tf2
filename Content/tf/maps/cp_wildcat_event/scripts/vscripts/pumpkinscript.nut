CollectEventsInScope({
	OnGameEvent_player_spawn = function(params)
	{
		if (params.team != TEAM_UNASSIGNED) { EntFireByHandle(GetPlayerFromUserID(params.userid), "CallScriptFunction", "PostPlayerSpawn", 0, null, null) }
	}

	OnGameEvent_teamplay_round_start = function(params)
	{
		local i = 0
		local pickup; while (pickup = Entities.FindByClassname(pickup, "item_armor"))
		{
			local pickupName = format("pickup_%d", i); NetProps.SetPropString(pickup, "m_iName", pickupName)

			pickup.ValidateScriptScope()
			pickup.SetModel(PUMPKINPICKUPPOTIONMODEL)
			pickup.SetSkin(1)

			EntityOutputs.AddOutput(pickup, "OnUser1", pickupName, "RunScriptCode", "MakeAllPlayersWithinRangeAPumpkinFrom(self)", 0, -1)
			EntityOutputs.AddOutput(pickup, "OnUser1", pickupName, "RunScriptCode", "self.EmitSound(PUMPKINAPPEARSOUND)", 0, -1)
			EntityOutputs.AddOutput(pickup, "OnUser1", "!activator", "RunScriptCode", "SetPlayerIsAPumpkin(self, true, false)", 0, -1)
			EntityOutputs.AddOutput(pickup, "OnUser1", pickupName, "Disable", "", 0, -1)

			EntityOutputs.AddOutput(pickup, "OnUser2", pickupName, "Enable", "", 0, -1)

			i++
		}
	}

	OnGameEvent_post_inventory_application = function(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		local scope = GetPlayerScope(player)
		local currentWeaponIds = GetPlayerWeaponIds(player)

		NetProps.SetPropInt(player, "m_ArmorValue", 0x80000000)
		SetPlayerIsAPumpkin(player, false, false)

		//If the player's current weapons are different than their ones last post_inv, switch to the first weapon available to them to get around the T-Posing
		if (ArraysDifferUnordered(scope.weaponIds, currentWeaponIds)) { player.Weapon_Switch(GetPlayerWeapons(player, false)[0]) }

		scope.weaponIds = currentWeaponIds
		scope.lastDamageSource = 0
	}

	OnGameEvent_scorestats_accumulated_update = function(params) //Round restart
	{
		foreach(player in GetPlayers()) { SetPlayerIsAPumpkin(player, false, false) }
	}

	OnGameEvent_player_death = function(params)
	{
		if (!(params.death_flags & 32)) { CheckIfAttackerIsEligibleForContractObjective(params.userid, params.attacker) } //If this isn't a faked deadringer death
		SetPlayerIsAPumpkin(GetPlayerFromUserID(params.userid), false, true)
		DeleteAllCrumpkins()
	}

	OnGameEvent_player_hurt = function(params)
	{
		GetPlayerScope(GetPlayerFromUserID(params.userid)).lastDamageSource = params.attacker
	}
})

::MakeAllPlayersWithinRangeAPumpkinFrom <- function(from)
{
	local playerInRange = null
	while (playerInRange = FindByClassnameWithinTraced(playerInRange, "player", from.GetCenter(), PUMPKINTRANSFORMATIONRANGE, null))
	{
		SetPlayerIsAPumpkin(playerInRange, true, false)
	}
}

::SetPlayerIsAPumpkin <- function(player, state, explodeOnTransform)
{
	local scope = GetPlayerScope(player)

	if (state == scope.isAPumpkin) { return }
	if (state)
	{
		// #region Conditions removal
		player.RemoveInvisibility()
		player.RemoveDisguise()
		player.RemoveCondEx(TF_COND_SHIELD_CHARGE, true)
		player.RemoveCondEx(TF_COND_CRITBOOSTED, true)
		player.RemoveCondEx(TF_COND_ZOOMED, true)
		player.RemoveCondEx(TF_COND_AIMING, true)
		player.RemoveCondEx(TF_COND_URINE, true)
		player.RemoveCondEx(TF_COND_MAD_MILK, true)
		player.RemoveCondEx(TF_COND_MARKEDFORDEATH, true)
		player.RemoveCondEx(TF_COND_BLEEDING, true)
		player.RemoveCondEx(TF_COND_GAS, true)
		player.RemoveCondEx(TF_COND_BURNING, true)

		NetProps.SetPropInt(player, "m_iFOV", 0)
		// #endregion

		scope.isAPumpkin <- true
		scope.highestHealthAsPumpkin <- 0

		if (WEAPONIDSTOSWITCHFROMWHENTRANSFORMING.find(GetWeaponId(player.GetActiveWeapon())) != null)
		{
			player.Weapon_Switch(GetPlayerWeapons(player, false)[0])
		}

		EmitSoundOnPlayer(player, SKELETONGIGGLESOUNDS[RandomInt(0, SKELETONGIGGLESOUNDS.len() -1)])

		player.AddCustomAttribute("increase player capture value", player.GetPlayerClass() == TF_CLASS_SCOUT ? -2 : -1, -1)
		player.AddCustomAttribute("no double jump", 1, -1)
		player.AddCustomAttribute("voice pitch scale", 1.4, -1)
		player.AddCustomAttribute("cannot disguise", 1, -1)
		player.AddCustomAttribute("disable weapon switch", 1, -1)

		player.RemoveCustomAttribute("move speed penalty")

		local pumpkinModel = RandomChance(PUMPKINMODELS)
		player.SetForcedTauntCam(1)
		player.SetCustomModelWithClassAnimations(pumpkinModel)
		player.SetCustomModelVisibleToSelf(true)
		DispatchParticleEffect(PUMPKINAPPEARPARTICLE, player.GetOrigin() + PUMPKINMODELS[pumpkinModel].centre, Vector(0,0,0))

		NetProps.SetPropInt(player, "m_ArmorValue", 0)

		SetPlayerCosmeticsVisible(player, false)
		SetPlayerWeaponsVisible(player, false)
		player.AcceptInput("DisableShadow", "", null, null)

		if (player.GetHealth() <= player.GetMaxHealth() / 2 + 10) { player.SetHealth(player.GetMaxHealth() / 2 + 10) }

		AddThinkToEnt(player, "PumpkinThink")
	}
	else
	{
		scope.isAPumpkin <- false

		player.RemoveCustomAttribute("increase player capture value")
		player.RemoveCustomAttribute("no double jump")
		player.RemoveCustomAttribute("voice pitch scale")
		player.RemoveCustomAttribute("cannot disguise")
		player.RemoveCustomAttribute("disable weapon switch")

		player.RemoveCustomAttribute("major move speed bonus")

		NetProps.SetPropInt(player, "m_ArmorValue", 0x80000000)
		NetProps.SetPropInt(player, "m_nRenderMode", Constants.ERenderMode.kRenderNormal)

		player.SetForcedTauntCam(0)
		player.SetCustomModelVisibleToSelf(false)
		if (player.IsAlive()) { player.SetCustomModelWithClassAnimations("") }

		SetPlayerCosmeticsVisible(player, player.IsAlive())
		SetPlayerWeaponsVisible(player, player.IsAlive())

		if (explodeOnTransform) { SpawnDudPumpkinBombAndExplodeAt(player.GetOrigin()) }
		player.AcceptInput("EnableShadow", "", null, null)

		AddThinkToEnt(player, null)
	}
}

::PumpkinThink <- function() //The 'self' of this function is the same as player.GetScriptScope() elsewhere
{
	if (!isAPumpkin) return
	local player = self
	local buttonsLast = buttons ? buttons != null : 0
	local buttons = NetProps.GetPropInt(self, "m_nButtons")
	local buttonsChanged = buttonsLast ^ buttons
	local buttonsPressed = buttonsChanged & buttons
	local buttonsReleased = buttonsChanged & (~buttons)

	if (player.GetHealth() > highestHealthAsPumpkin)
	{
		highestHealthAsPumpkin = player.GetHealth()
		if (player.GetHealth() > player.GetMaxHealth()) { highestHealthAsPumpkin = player.GetMaxHealth() }
	}

	local intendedSpeed = !player.InCond(TF_COND_SPEED_BOOST) ? PUMPKINSPEED : PUMPKINSPEEDBOOSTSPEED

	if (NetProps.GetPropFloat(player, "m_flMaxspeed") != intendedSpeed)
	{
		player.RemoveCustomAttribute("major move speed bonus")
		player.AddCustomAttribute("major move speed bonus", intendedSpeed / NetProps.GetPropFloat(player, "m_flMaxspeed"), -1)
	}

	player.RemoveCondEx(TF_COND_PHASE, true)
	player.RemoveCondEx(TF_COND_PARACHUTE_ACTIVE, true)

	local playerIsTryingToUndisguise = buttonsPressed & IN_ATTACK || buttonsPressed & IN_ATTACK2 || player.InCond(TF_COND_TAUNTING)
	local playerWasForcedToUndisguise = player.GetHealth() <= highestHealthAsPumpkin - PUMPKINHEALTHDECREASETHRESHOLD || player.GetHealth() < player.GetMaxHealth() / 2

	if (playerWasForcedToUndisguise || playerIsTryingToUndisguise)
	{
		if (playerWasForcedToUndisguise)
		{
			CheckIfAttackerIsEligibleForContractObjective(GetPlayerUserID(player), lastDamageSource)
		}

		SetPlayerIsAPumpkin(player, false, true)
	}

	return -1
}

::CheckIfAttackerIsEligibleForContractObjective <- function(hurtUserId, attackerUserId)
{
	local hurtPlayer = GetPlayerFromUserID(hurtUserId)
	local attackerPlayer = GetPlayerFromUserID(attackerUserId)
	local isEligible =
	attackerPlayer != null //Grabbing the attacker doesn't return a null pointer
	&& attackerPlayer.GetClassname() == "player" //Attacker's classname is player
	&& GetPlayerScope(hurtPlayer).isAPumpkin //hurt player is a pumpkin
	&& hurtUserId != attackerUserId //Hurt user is not the same as the attacker
	&& (attackerPlayer.GetTeam() == TF_TEAM_BLUE || attackerPlayer.GetTeam() == TF_TEAM_RED) //Attacker is either on Blue or Red
	&& hurtPlayer.GetTeam() != attackerPlayer.GetTeam() //Attacker and Hurt player are on different teams

	// printl("(attackerPlayer != null " + (attackerPlayer != null ))
	// printl("(attackerPlayer.GetClassname() == player " + (attackerPlayer.GetClassname() == "player" ))
	// printl("(GetPlayerScope(hurtPlayer).isAPumpkin " + (GetPlayerScope(hurtPlayer).isAPumpkin ))
	// printl("(hurtUserId != attackerUserId " + (hurtUserId != attackerUserId ))
	// printl("((attackerPlayer.GetTeam() == TF_TEAM_BLUE || attackerPlayer.GetTeam() == TF_TEAM_RED) " + ((attackerPlayer.GetTeam() == TF_TEAM_BLUE || attackerPlayer.GetTeam() == TF_TEAM_RED) ))
	// printl("(hurtPlayer.GetTeam() != attackerPlayer.GetTeam()" + (hurtPlayer.GetTeam() != attackerPlayer.GetTeam()))

	// printl("isEligible: " + isEligible)

	if (isEligible)
	{
		SendGlobalGameEvent("pumpkin_forced_undisguise",
		{
			"userid": hurtUserId,
			"attacker": attackerUserId
		})
	}
}

::SpawnDudPumpkinBombAndExplodeAt <- function(pos)
{
	local pumpkin = SpawnEntityFromTable("tf_generic_bomb",{
		origin = pos,
		damage = 0,
		radius = 0
		sound = "items/pumpkin_explode1.wav",
		explode_particle = "pumpkin_explode",
	})

	local pumpkin_dynamic = SpawnEntityFromTable("prop_dynamic",{
		origin = pos,
		model = PUMPKINEXPLODEMODEL,
		solid = "0"
	})

	EntFireByHandle(pumpkin_dynamic, "Break", "", 0, null, null)
	pumpkin.AcceptInput("Detonate", "", null, null)
}

::GetPlayerScope <- function(player)
{
	if (player.GetScriptScope() == null) { return CreatePlayerScriptScope(player) }
	else { return player.GetScriptScope() }
}

::CreatePlayerScriptScope <- function(player)
{
	player.ValidateScriptScope()
	local s = player.GetScriptScope()

	s.buttonsLast <- 0
	s.buttons <- 0
	s.isAPumpkin <- false
	s.weaponIds <- {}
	s.highestHealthAsPumpkin <- 0
	s.lastDamageSource <- 0

	return s
}

::GetWeaponId <- function(weapon) { return NetProps.GetPropInt(weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex") }
::GetPlayerWeaponIds <- function(player)
{
	local weaponIds = []
	foreach (weapon in GetPlayerWeapons(player, true))
	{
		weaponIds.append(GetWeaponId(weapon))
	}
	return weaponIds
}

::SetPlayerWeaponsVisible <- function(player, state = true) { foreach(weapon in GetPlayerWeapons(player)) { weapon.SetDrawEnabled(state) }}
::SetPlayerCosmeticsVisible <- function(player, state = true) { foreach(wearable in GetPlayerWearables(player)) { if (state) wearable.EnableDraw(); else wearable.DisableDraw(); } }
::GetPlayerWearables <- function(player)
{
	local wearables = []
	for (local wearable = player.FirstMoveChild(); wearable != null; wearable = wearable.NextMovePeer())
	{
		if (wearable.GetClassname() == "tf_wearable" || wearable.GetClassname() == "tf_powerup_bottle" || wearable.GetClassname() == "tf_wearable_demoshield" || wearable.GetClassname() == "tf_wearable_razorback") { wearables.push(wearable); }
	}
	return wearables
}

::GetPlayerWeapons <- function(player, includeWearables = false)
{
	local weapons = []
	for (local i = 0; i < 8; i++)
	{
		local weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
		if (weapon == null) continue
		weapons.push(weapon)
	}

	if (includeWearables)
	{
		for (local wearable = player.FirstMoveChild(); wearable != null; wearable = wearable.NextMovePeer()) { if (wearable.GetClassname() == "tf_wearable_demoshield" || wearable.GetClassname() == "tf_wearable_razorback" || wearable.GetClassname() == "tf_weapon_buff_item") { weapons.push(wearable) } }
	}

	return weapons
}

::EmitSoundOnPlayer <- function(player, sound)
{
	for (local noiseRecipient; noiseRecipient = Entities.FindByClassnameWithin(noiseRecipient, "player", player.GetOrigin(), PUMPKINSOUNDSRANGE);)
	{
		EmitSoundEx({
		sound_name = sound,
		origin = player.GetCenter(),
		entity = noiseRecipient,
		filter_type = RECIPIENT_FILTER_SINGLE_PLAYER})
	}
}

::PostPlayerSpawn <- function() {  SetPlayerIsAPumpkin(self, false, false) }

::GetPlayers <- function(team = null)
{
	local allPlayers = []
	for (local i = 1; i <= MaxClients().tointeger(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player && player.GetTeam() > 1 && (!team || player.GetTeam() == team))
		allPlayers.push(player)
	}
	return allPlayers
}

local blacklist = [ "worldspawn", "func_door", "info_particle_system"]
// FindByClassnameWithin but will be trace checked for worldspawn or other entities that should be used to block Line of Sight
::FindByClassnameWithinTraced <- function(entWithin, filter, vecCenter, flRadius, ignored){
	// Set bounding boxes to 0,0,0 so the trace can continue, then revert afterwards.
	local hitEnts = []
	local bBoxMins = []
	local bBoxMaxs = []

	local trace = {
		start = vecCenter,
		end = null,
		mask = -1,
		ignore = ignored,
		enthit = null
	}

	while(entWithin = Entities.FindByClassnameWithin(entWithin, filter, vecCenter, flRadius)){
		trace.end = entWithin.GetCenter()
		while(TraceLineEx(trace) && trace.enthit){
			local entity = trace.enthit
			local hitBlacklist = false
			// Check if it hit worldspawn or a blacklisted entity before doing anything else.
			foreach(val in blacklist){
				if(entity.GetClassname() == val){
					if(hitEnts.len() > 0){
						for(local i = 0; i < hitEnts.len(); i++){
							hitEnts[i].SetSize(bBoxMins[i], bBoxMaxs[i])
						}
					}
					hitBlacklist = true
				}
			}
			if(hitBlacklist) { break }
			// Successfully hit the entity you wanted.

			if(entity == entWithin){
				if(hitEnts.len() > 0){
					for(local i = 0; i < hitEnts.len(); i++){
						hitEnts[i].SetSize(bBoxMins[i], bBoxMaxs[i])
					}
				}
				return entWithin
			}
			// If the trace didn't hit the entity you wanted.
			else {
				hitEnts.append(entity)
				if(entity.GetClassname() == "player"){
					// The player version of this accounts for size changes.
					bBoxMins.append(entity.GetPlayerMins())
					bBoxMaxs.append(entity.GetPlayerMaxs())
				}
				else {
					bBoxMins.append(entity.GetBoundingMins())
					bBoxMaxs.append(entity.GetBoundingMaxs())
				}
				entity.SetSize(Vector(),Vector())
				trace.ignore = entity
				trace.start = trace.endpos
				trace.enthit = null
			}
		}
	}
}

::ArraysDifferUnordered <- function(a, b)
{
    // Different lengths → definitely different
    if (a.len() != b.len())
        return true

    // Sort copies (so we don't mutate the originals)
    local sortedA = clone a
    local sortedB = clone b
    sortedA.sort(@(x, y) x <=> y)
    sortedB.sort(@(x, y) x <=> y)

    // Compare elements
    for (local i = 0; i < sortedA.len(); i++)
    {
        if (sortedA[i] != sortedB[i])
            return true
    }

    return false // No differences found
}

::RandomChance <- function(table)
{
	local roll = RandomFloat(0.0, 100.0)
	local cumulative = 0.0

	foreach (pumpkin, pumpkinTable in table)
	{
		cumulative += pumpkinTable.chance

		if (roll < cumulative)
			return pumpkin;
	}

	return null;
}

::DeleteAllCrumpkins <- function()
{
	local crumpkins = [];
	for (local tf_ammo_pack = null; tf_ammo_pack = Entities.FindByClassname(tf_ammo_pack, "tf_ammo_pack");)
	{
		NetProps.SetPropBool(tf_ammo_pack, "m_bForcePurgeFixedupStrings", true);
		if (NetProps.GetPropInt(tf_ammo_pack, "m_nModelIndex") == CRUMPKIN_INDEX)
		{
			crumpkins.push(tf_ammo_pack);
		}
	}

	foreach(crumpkin in crumpkins)
	{
		crumpkin.Kill();
	}
}

::GetPlayerUserID <- function(player) { return NetProps.GetPropIntArray(PlayerManager, "m_iUserID", player.entindex()) }
