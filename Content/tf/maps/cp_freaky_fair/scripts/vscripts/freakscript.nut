//////////////////////////////////////////////////////////////////////////////////////////////////////
///											BLOOD MONEY											   ///
///								Script and assets created by Diva Dan				               ///
///   This script enables MVM style potionType stations, with kills giving a team money to spend.  ///
//////////////////////////////////////////////////////////////////////////////////////////////////////

local GameRules = Entities.FindByClassname(null, "tf_gamerules")
local MAX_CLIENTS = MaxClients().tointeger()

::DebugPrint <- function(message) { if (developer() > 0) {printl(message)} }

function SpoofTournamentReady()
{
	// 0 - not ready
	// 1 - ready
	local ready_state = 1

	local red_check = false
	local blue_check = false

	for (local i = 1; i <= MAX_CLIENTS; i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (!player)
			continue

		local team = player.GetTeam()
		if (!(team & 2))
			continue

		if (team == 2)
		{
			if (red_check)
				continue
			red_check = true
		}
		else if (team == 3)
		{
			if (blue_check)
				continue
			blue_check = true
		}

		if (NetProps.GetPropBoolArray(GameRules, "m_bTeamReady", team))
			continue

		NetProps.SetPropBoolArray(GameRules, "m_bTeamReady", ready_state == 1, team)

		SendGlobalGameEvent("tournament_stateupdate",
		{
			userid = player.entindex(),
			readystate = ready_state,
			namechange = 0,
			oldname = " ",
			newname = " ",

		})

		if (ready_state == 0)
		{
			NetProps.SetPropFloat(GameRules, "m_flRestartRoundTime", -1.0)
			NetProps.SetPropBool(GameRules, "m_bAwaitingReadyRestart", true)
		}
	}
}

const STARTINGCREDITS = 250;
const CREDIT_MULTIPLIER = 4;
const TF_TEAM_RED = 2;
const TF_TEAM_BLU = 3;

const UPGRADEVOICELINECHANCE = 20;
const VOICELINECOOLDOWN = 5;

const REDPRINTCOLOUR = "\x07FF3F3F";
const BLUPRINTCOLOUR = "\x0799CCFF";
const DEFAULTPRINTCOLOUR = "\x07FFFFFF";
const EFFECTPRINTCOLOUR = "\x07FFD700";

const BUSTERIDLESOUND = "mvm/sentrybuster/mvm_sentrybuster_loop.wav";
const BUSTEREXPLODESOUND = "mvm/sentrybuster/mvm_sentrybuster_explode.wav";
const BUSTERSPINSOUND = "mvm/sentrybuster/mvm_sentrybuster_spin.wav";
const REDGHOSTMODEL = "models/props_halloween/ghost_no_hat_red.mdl";
const BLUGHOSTMODEL = "models/props_halloween/ghost_no_hat.mdl";
const POTIONCANTBEUSEDSOUND = "replay/cameracontrolerror.wav";

const BLASTRESIST = "dmg taken from blast reduced";
const BULLETSRESIST = "dmg taken from bullets reduced";
const CRITRESIST = "dmg taken from crit reduced";
const FIRERESIST = "dmg taken from fire reduced";
const HEALTHREGEN = "health regen";
const METALREGEN = "metal regen";
const MOVESPEED = "move speed bonus";
const JUMPHEIGHT = "increased jump height";

const SPOOFVALUE = 69420;

const printEventDetails = true;

::MAX_WEAPONS <- 8

::BUSTERMODEL <- "models/bots/demo/bot_sentry_buster_pumpkin.mdl";
::BUSTEREXPLOSIONRANGE <- 256;
::BUSTEREXPLODEDELAY <- 2.02;
::BUSTERHEALTH <- 1500;


::SCREAMSOUNDS <- ["vo/halloween_scream1.mp3", "vo/halloween_scream2.mp3", "vo/halloween_scream3.mp3", "vo/halloween_scream4.mp3", "vo/halloween_scream5.mp3", "vo/halloween_scream6.mp3", "vo/halloween_scream7.mp3", "vo/halloween_scream8.mp3"]
::GHOSTSOUNDS <- ["vo/halloween_boo1.mp3", "vo/halloween_boo2.mp3", "vo/halloween_boo3.mp3", "vo/halloween_boo4.mp3", "vo/halloween_boo5.mp3", "vo/halloween_boo6.mp3", "vo/halloween_boo7.mp3",]
::GHOSTSPOOKRANGE <- 384;
::GHOSTSPOOKDELAY <- 7;

::POTIONNOISERANGE <- 1024;

local banks = { [TF_TEAM_RED] = 0, [TF_TEAM_BLU] = 0 }
local lobbySize = 0; //amount of players currently in the lobby
local playersData = {};
local firstSpawnOfInitialSpawnWaveisDueToHappen = true;

local canteenTable = {
	"freaky fair kritz potion" : 				{"potionType": "kritz", 		"cost": 400,	"message": "has used a " + EFFECTPRINTCOLOUR + "KRITZ" + DEFAULTPRINTCOLOUR + " Potion"},
	"freaky fair uber potion" : 				{"potionType": "uber", 			"cost": 400,	"message": "has used a " + EFFECTPRINTCOLOUR + "UBER" + DEFAULTPRINTCOLOUR + " Potion"},
	"freaky fair giant potion" :	 			{"potionType": "giant", 		"cost": 300,	"message": "has used a " + EFFECTPRINTCOLOUR + "GIANT" + DEFAULTPRINTCOLOUR + " Potion and is now HUGE!"},
	"freaky fair buster potion" :				{"potionType": "buster", 		"cost": 300,	"message": "has used a " + EFFECTPRINTCOLOUR + "SENTRY BUSTER" + DEFAULTPRINTCOLOUR + " Potion"},
	"freaky fair healing potion" : 				{"potionType": "healing",	 	"cost": 200,	"message": "has used a " + EFFECTPRINTCOLOUR + "HEALING" + DEFAULTPRINTCOLOUR + " Potion and has healed themselves and the people around them"},
	"freaky fair ghost potion" : 				{"potionType": "ghost", 		"cost": 200,	"message": "has used a " + EFFECTPRINTCOLOUR + "GHOST" + DEFAULTPRINTCOLOUR + " Potion. Haunting!"},
	"freaky fair ammo potion" : 				{"potionType": "ammo", 			"cost": 50, 	"message": "has used a " + EFFECTPRINTCOLOUR + "AMMO" + DEFAULTPRINTCOLOUR + " Potion"},
	"freaky fair rtd potion" : 					{"potionType": "rtd", 			"cost": 150, 	"message": "has used a " + EFFECTPRINTCOLOUR + "RTD" + DEFAULTPRINTCOLOUR + " Potion"},
}

::DebugDrawHull <- function(trace, from_r, from_g, from_b, to_r, to_g, to_b, alpha, duration)
{
	DebugDrawBox(trace.start, trace.hullmin, trace.hullmax, from_r, from_g, from_b, alpha, duration)
	DebugDrawBox(trace.end, trace.hullmin, trace.hullmax, to_r, to_g, to_b, alpha, duration)
}

local defCharacterUpgrades = {
	[BLASTRESIST] =		1,
	[BULLETSRESIST] =	1,
	[CRITRESIST] =		1,
	[FIRERESIST] =		1,
	[HEALTHREGEN] =		0,
	[METALREGEN] =		0,
	[MOVESPEED] =		1,
	[JUMPHEIGHT] =		1,
}

local rtdEffects = [
	"bumperKart",
	"seventyFiveInvuln",
	"mfd",
	"frozen",
	"lowGrav",
	"negGrav",
	"overpowered",
	"respawned",
	"1000 health",
	"1 health",
	"speed bonus",
	"mini crits",
	"midas",
];

::effectsTable <- {
	"kritz": {
		"behaviour": function(params) { params.player.AddCondEx(TF_COND_CRITBOOSTED_CARD_EFFECT,  params.duration, params.player); },
		"resetBehaviour": function(params) {},
		"requirementsCheck": function(player) { return true; },
		"duration": 10,
		"message": "",
		"canDisguiseDuring": true,
		"playerTLK": "",
		"soundsOnUse": ["weapons/weapon_crit_charged_off.wav"],
	},
	"uber": {
		"behaviour": function(params) { params.player.AddCondEx(TF_COND_INVULNERABLE_CARD_EFFECT,  params.duration, params.player); },
		"resetBehaviour": function(params) {},
		"requirementsCheck": function(player) { return true; },
		"duration": 10,
		"message": "",
		"canDisguiseDuring": true,
		"playerTLK": "",
		"soundsOnUse": ["player/invulnerable_on.wav"],
	},
	"ammo": {
		"behaviour": function(params) { params.player.AddCustomAttribute("refill_ammo", 1, params.duration); },
		"resetBehaviour": function(params) {},
		"requirementsCheck": function(player) { return true; },
		"duration": 5,
		"message": "",
		"canDisguiseDuring": true,
		"playerTLK": "",
		"soundsOnUse": ["weapons/dispenser_generate_metal.wav"],
	},
	"giant": {
		"behaviour": function(params)
		{
			params.player.AddCondEx(TF_COND_HALLOWEEN_GIANT,  params.duration, params.player);
		},
		"resetBehaviour": function(params) {},
		"requirementsCheck": function(player)
		{
			local table = {
				start = player.GetOrigin(),
				end = player.GetOrigin(),
				hullmin = Vector(-24.5,-24.5,0)*1.75,
				hullmax = Vector(24.5,24.5,98)*1.75,
				ignore=player
			}

			TraceHull(table);

			// DebugPrint("table.hit: " + table.hit)

			return !table.hit;
		},
		"duration": 10,
		"message": "",
		"canDisguiseDuring": false,
		"playerTLK": "TLK_PLAYER_INCOMING",
		"soundsOnUse": ["giant.wav"],
	},
	"buster": {
		"behaviour": function(params)
		{
			SetPlayerIsASentryBuster(params.player, true)
			AddThinkToEnt(params.player, "BusterThink")
		},
		"resetBehaviour": function(params)
		{
			SetPlayerIsASentryBuster(params.player, false)
			AddThinkToEnt(params.player, null)
		},
		"requirementsCheck": function(player) { return true; },
		"duration": 15,
		"message": "",
		"canDisguiseDuring": false,
		"playerTLK": "",
		"soundsOnUse": ["mvm/sentrybuster/mvm_sentrybuster_intro.wav"],
	},
	"healing": {
		"behaviour": function(params) { ApplySpellOnPlayer(params.player, 2) },
		"resetBehaviour": function(params) { },
		"requirementsCheck": function(player) { return true; },
		"duration": 5,
		"message": "",
		"canDisguiseDuring": true,
		"playerTLK": "TLK_TAUNT_LAUGH",
		"soundsOnUse": ["misc/halloween/spell_overheal.wav"],
	},
	"ghost": {	//Ghost
		"behaviour": function(params)
		{
			params.player.AddCondEx(TF_COND_HALLOWEEN_GHOST_MODE,  params.duration, params.player);
			params.player.RemoveSolidFlags(FSOLID_NOT_SOLID)
			params.player.SetSolid(SOLID_BBOX)
			params.player.GetScriptScope().timeLastSpooked = Time();

			AddThinkToEnt(params.player, "GhostThink")
		},
		"resetBehaviour": function(params)
		{
			AddThinkToEnt(params.player, null)
		},
		"requirementsCheck": function(player) { return true; },
		"duration": 10,
		"message": "",
		"canDisguiseDuring": false,
		"playerTLK": "",
		"soundsOnUse": ["vo/halloween_boo1.mp3", "vo/halloween_boo2.mp3", "vo/halloween_boo3.mp3", "vo/halloween_boo4.mp3", "vo/halloween_boo5.mp3", "vo/halloween_boo6.mp3", "vo/halloween_boo7.mp3",]
	},
	"bumperKart": {	//////////////////////// RTD EFFECTS ////////////////////////
		"behaviour": function(params) { params.player.AddCondEx(TF_COND_HALLOWEEN_KART,  params.duration, params.player); },
		"resetBehaviour": function(params) { }
		"requirementsCheck": function(player) { return true; },
		"duration": 10,
		"message": "and is now in a BUMPER KART!",
		"canDisguiseDuring": false,
		"playerTLK": "TLK_PLAYER_BATTLECRY",
		"soundsOnUse": ["ambient/mvm_warehouse/car_horn_01.wav", "ambient/mvm_warehouse/car_horn_02.wav", "ambient/mvm_warehouse/car_horn_03.wav", "ambient/mvm_warehouse/car_horn_04.wav", "ambient/mvm_warehouse/car_horn_05.wav",],
	},
	"seventyFiveInvuln": {	//75% invulnerability
		"behaviour": function(params) { params.player.AddCondEx(TF_COND_OBSCURED_SMOKE,  params.duration, params.player); },
		"resetBehaviour": function(params) { }
		"requirementsCheck": function(player) { return true; },
		"duration": 10,
		"message": "and is UNAFFECTED BY DAMAGE (mostly)",
		"canDisguiseDuring": true,
		"playerTLK": "",
		"soundsOnUse": ["player/invuln_off_vaccinator.wav"],
	},
	"mfd": {
		"behaviour": function(params) { params.player.AddCondEx(TF_COND_MARKEDFORDEATH,  params.duration, params.player); },
		"resetBehaviour": function(params) { }
		"requirementsCheck": function(player) { return true; },
		"duration": 15,
		"message": "and is now MARKED FOR DEATH!",
		"canDisguiseDuring": true,
		"playerTLK": "TLK_PLAYER_NEGATIVE",
		"soundsOnUse": ["weapons/samurai/TF_marked_for_death_indicator.wav"],
	},
	"frozen": {
		"behaviour": function(params) { params.player.AddCondEx(TF_COND_FREEZE_INPUT,  params.duration, params.player); },
		"resetBehaviour": function(params) { }
		"requirementsCheck": function(player) { return true; },
		"duration": 5,
		"message": "and now is FROZEN STIFF...",
		"canDisguiseDuring": false,
		"playerTLK": "TLK_PLAYER_NEGATIVE",
		"soundsOnUse": ["weapons/icicle_freeze_victim_01.wav",]
	},
	"lowGrav": {
		"behaviour": function(params) { params.player.SetGravity(0.2); },
		"resetBehaviour": function(params) { params.player.SetGravity(1); },
		"requirementsCheck": function(player) { return true; },
		"duration": 10,
		"message": "and has LOW GRAVITY!",
		"canDisguiseDuring": true,
		"playerTLK": "TLK_MAGIC_GRAVITY",
		"soundsOnUse": ["lowgravityup.wav"],
	},
	"negGrav": {
		"behaviour": function(params) { params.player.SetGravity(-0.01); },
		"resetBehaviour": function(params) { params.player.SetGravity(1); }
		"requirementsCheck": function(player) { return true; },
		"duration": 10,
		"message": "and has REVERSE GRAVITY!",
		"canDisguiseDuring": true,
		"playerTLK": "TLK_MAGIC_GRAVITY",
		"soundsOnUse": ["lowgravitydown.wav"],
	},
	"1000 health": {
		"behaviour": function(params) {
			params.player.AddCustomAttribute("max health additive bonus", 1000 - params.player.GetMaxHealth(), params.duration);
			params.player.SetHealth(1000);
		},
		"resetBehaviour": function(params) { }
		"requirementsCheck": function(player) { return true; },
		"duration": 10,
		"message": "and now has 1000 HEALTH!",
		"canDisguiseDuring": true,
		"playerTLK": "TLK_PLAYER_TAUNT2`",
		"soundsOnUse": ["1000health.wav"],
	},
	"1 health": {
		"behaviour": function(params) {
			params.player.SetHealth(1);
		},
		"resetBehaviour": function(params) { }
		"requirementsCheck": function(player) { return true; },
		"duration": 10,
		"message": "and now has 1 HEALTH!",
		"canDisguiseDuring": true,
		"playerTLK": "TLK_PLAYER_HELP",
		"soundsOnUse": ["1health.wav"],
	},
	"overpowered": {
		"behaviour": function(params) {
			params.player.AddCondEx(TF_COND_CRITBOOSTED,  params.duration, params.player);
			params.player.AddCondEx(TF_COND_INVULNERABLE,  params.duration, params.player);
			params.player.AddCustomAttribute("refill_ammo", 1, params.duration);
			if (params.player.GetHealth() <= params.player.GetMaxHealth()) params.player.SetHealth(params.player.GetMaxHealth());
		},
		"resetBehaviour": function(params) { }
		"requirementsCheck": function(player) { return true; },
		"duration": 10,
		"message": "and is now OVERPOWERED!",
		"canDisguiseDuring": true,
		"playerTLK": "",
		"soundsOnUse": ["ui/mm_level_one_achieved.wav", "ui/mm_level_two_achieved.wav", "ui/mm_level_three_achieved.wav", "ui/mm_level_four_achieved.wav", "ui/mm_level_five_achieved.wav", "ui/mm_level_six_achieved.wav"],
	},
	"respawned": {
		"behaviour": function(params) { Entities.DispatchSpawn(params.player); },
		"resetBehaviour": function(params) { }
		"requirementsCheck": function(player) { return true; },
		"duration": 0,
		"message": "and has RESPAWNED!",
		"canDisguiseDuring": true,
		"playerTLK": "TLK_PLAYER_JEERS",
		"soundsOnUse": ["items/spawn_item.wav"],
	},
	"speed bonus": {
		"behaviour": function(params) { params.player.AddCustomAttribute("move speed bonus", 1.5, params.duration); },
		"resetBehaviour": function(params) { params.player.RemoveCustomAttribute("move speed bonus"); }
		"requirementsCheck": function(player) { return true; },
		"duration": 15,
		"message": "and has a SPEED BONUS!",
		"canDisguiseDuring": true,
		"playerTLK": "TLK_PLAYER_BATTLECRY",
		"soundsOnUse": ["weapons/discipline_device_power_up.wav"],
	},
	"mini crits": {
		"behaviour": function(params) { params.player.AddCondEx(TF_COND_OFFENSEBUFF, params.duration, params.player); },
		"resetBehaviour": function(params) { }
		"requirementsCheck": function(player) { return true; },
		"duration": 10,
		"message": "and has MINI CRITS!",
		"canDisguiseDuring": true,
		"playerTLK": "TLK_PLAYER_POSITIVE",
		"soundsOnUse": ["player/crit_hit_mini.wav", "player/crit_hit_mini2.wav", "player/crit_hit_mini3.wav", "player/crit_hit_mini4.wav", "player/crit_hit_mini5.wav"],
	},
	"midas": {
		"behaviour": function(params)
		{
			foreach (weapon in GetPlayerWeapons(params.player)) { weapon.AddAttribute("turn to gold", 1, params.duration); }
		},
		"resetBehaviour": function(params)
		{
			foreach (weapon in GetPlayerWeapons(params.player)) { weapon.RemoveAttribute("turn to gold"); }
		},
		"requirementsCheck": function(player) { return true; },
		"duration": 10,
		"message": "and has the MIDAS TOUCH!",
		"canDisguiseDuring": true,
		"playerTLK": "",
		"soundsOnUse": ["weapons/saxxy_impact_gen_03.wav", "weapons/saxxy_impact_gen_06.wav"],
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
///FUNCTIONS///
//////////////////////////////////////////////////////////////////////////////////////////////////////

::ROOT <- getroottable();
if (!("ConstantNamingConvention" in ROOT)) // make sure folding is only done once
{
	foreach (a,b in Constants)
		foreach (k1,v1 in b)
			ROOT[k1] <- v1 != null ? v1 : 0;
}

::GetPlayers <- function(team = null)
{
	local allPlayers = [];
	for (local i = 1; i <= MaxClients().tointeger(); i++)
	{
		local player = PlayerInstanceFromIndex(i);
		if (player && player.GetTeam() > 1 && (!team || player.GetTeam() == team))
		allPlayers.push(player);
	}
	return allPlayers;
}

function PlayerEntryExists(player) { return GetPlayerSteamID(player) in playersData; }

function CreatePlayerEntry(player)
{
	local entry = playersData[GetPlayerSteamID(player)] <- {
		"teamData": {
			[TF_TEAM_RED] = {
				[TF_CLASS_SCOUT] =			{"canteenCharges": 0, "refundableAmountSpent": 0, "nonRefundableAmountSpent": 0, "refundOnSpawn": true,
				"characterUpgrades": {[BLASTRESIST] = defCharacterUpgrades[BLASTRESIST], [BULLETSRESIST] = defCharacterUpgrades[BULLETSRESIST], [CRITRESIST] = defCharacterUpgrades[CRITRESIST], [FIRERESIST] = defCharacterUpgrades[FIRERESIST], [HEALTHREGEN] = defCharacterUpgrades[HEALTHREGEN], [METALREGEN] = defCharacterUpgrades[METALREGEN], [MOVESPEED] = defCharacterUpgrades[MOVESPEED], [JUMPHEIGHT] = defCharacterUpgrades[JUMPHEIGHT]}},
				[TF_CLASS_SOLDIER] = 		{"canteenCharges": 0, "refundableAmountSpent": 0, "nonRefundableAmountSpent": 0, "refundOnSpawn": true,
				"characterUpgrades": {[BLASTRESIST] = defCharacterUpgrades[BLASTRESIST], [BULLETSRESIST] = defCharacterUpgrades[BULLETSRESIST], [CRITRESIST] = defCharacterUpgrades[CRITRESIST], [FIRERESIST] = defCharacterUpgrades[FIRERESIST], [HEALTHREGEN] = defCharacterUpgrades[HEALTHREGEN], [METALREGEN] = defCharacterUpgrades[METALREGEN], [MOVESPEED] = defCharacterUpgrades[MOVESPEED], [JUMPHEIGHT] = defCharacterUpgrades[JUMPHEIGHT]}},
				[TF_CLASS_PYRO] = 			{"canteenCharges": 0, "refundableAmountSpent": 0, "nonRefundableAmountSpent": 0, "refundOnSpawn": true,
				"characterUpgrades": {[BLASTRESIST] = defCharacterUpgrades[BLASTRESIST], [BULLETSRESIST] = defCharacterUpgrades[BULLETSRESIST], [CRITRESIST] = defCharacterUpgrades[CRITRESIST], [FIRERESIST] = defCharacterUpgrades[FIRERESIST], [HEALTHREGEN] = defCharacterUpgrades[HEALTHREGEN], [METALREGEN] = defCharacterUpgrades[METALREGEN], [MOVESPEED] = defCharacterUpgrades[MOVESPEED], [JUMPHEIGHT] = defCharacterUpgrades[JUMPHEIGHT]}},
				[TF_CLASS_DEMOMAN] = 		{"canteenCharges": 0, "refundableAmountSpent": 0, "nonRefundableAmountSpent": 0, "refundOnSpawn": true,
				"characterUpgrades": {[BLASTRESIST] = defCharacterUpgrades[BLASTRESIST], [BULLETSRESIST] = defCharacterUpgrades[BULLETSRESIST], [CRITRESIST] = defCharacterUpgrades[CRITRESIST], [FIRERESIST] = defCharacterUpgrades[FIRERESIST], [HEALTHREGEN] = defCharacterUpgrades[HEALTHREGEN], [METALREGEN] = defCharacterUpgrades[METALREGEN], [MOVESPEED] = defCharacterUpgrades[MOVESPEED], [JUMPHEIGHT] = defCharacterUpgrades[JUMPHEIGHT]}},
				[TF_CLASS_HEAVYWEAPONS] = 	{"canteenCharges": 0, "refundableAmountSpent": 0, "nonRefundableAmountSpent": 0, "refundOnSpawn": true,
				"characterUpgrades": {[BLASTRESIST] = defCharacterUpgrades[BLASTRESIST], [BULLETSRESIST] = defCharacterUpgrades[BULLETSRESIST], [CRITRESIST] = defCharacterUpgrades[CRITRESIST], [FIRERESIST] = defCharacterUpgrades[FIRERESIST], [HEALTHREGEN] = defCharacterUpgrades[HEALTHREGEN], [METALREGEN] = defCharacterUpgrades[METALREGEN], [MOVESPEED] = defCharacterUpgrades[MOVESPEED], [JUMPHEIGHT] = defCharacterUpgrades[JUMPHEIGHT]}},
				[TF_CLASS_ENGINEER] = 		{"canteenCharges": 0, "refundableAmountSpent": 0, "nonRefundableAmountSpent": 0, "refundOnSpawn": true,
				"characterUpgrades": {[BLASTRESIST] = defCharacterUpgrades[BLASTRESIST], [BULLETSRESIST] = defCharacterUpgrades[BULLETSRESIST], [CRITRESIST] = defCharacterUpgrades[CRITRESIST], [FIRERESIST] = defCharacterUpgrades[FIRERESIST], [HEALTHREGEN] = defCharacterUpgrades[HEALTHREGEN], [METALREGEN] = defCharacterUpgrades[METALREGEN], [MOVESPEED] = defCharacterUpgrades[MOVESPEED], [JUMPHEIGHT] = defCharacterUpgrades[JUMPHEIGHT]}},
				[TF_CLASS_MEDIC] = 			{"canteenCharges": 0, "refundableAmountSpent": 0, "nonRefundableAmountSpent": 0, "refundOnSpawn": true,
				"characterUpgrades": {[BLASTRESIST] = defCharacterUpgrades[BLASTRESIST], [BULLETSRESIST] = defCharacterUpgrades[BULLETSRESIST], [CRITRESIST] = defCharacterUpgrades[CRITRESIST], [FIRERESIST] = defCharacterUpgrades[FIRERESIST], [HEALTHREGEN] = defCharacterUpgrades[HEALTHREGEN], [METALREGEN] = defCharacterUpgrades[METALREGEN], [MOVESPEED] = defCharacterUpgrades[MOVESPEED], [JUMPHEIGHT] = defCharacterUpgrades[JUMPHEIGHT]}},
				[TF_CLASS_SNIPER] = 		{"canteenCharges": 0, "refundableAmountSpent": 0, "nonRefundableAmountSpent": 0, "refundOnSpawn": true,
				"characterUpgrades": {[BLASTRESIST] = defCharacterUpgrades[BLASTRESIST], [BULLETSRESIST] = defCharacterUpgrades[BULLETSRESIST], [CRITRESIST] = defCharacterUpgrades[CRITRESIST], [FIRERESIST] = defCharacterUpgrades[FIRERESIST], [HEALTHREGEN] = defCharacterUpgrades[HEALTHREGEN], [METALREGEN] = defCharacterUpgrades[METALREGEN], [MOVESPEED] = defCharacterUpgrades[MOVESPEED], [JUMPHEIGHT] = defCharacterUpgrades[JUMPHEIGHT]}},
				[TF_CLASS_SPY] = 			{"canteenCharges": 0, "refundableAmountSpent": 0, "nonRefundableAmountSpent": 0, "refundOnSpawn": true,
				"characterUpgrades": {[BLASTRESIST] = defCharacterUpgrades[BLASTRESIST], [BULLETSRESIST] = defCharacterUpgrades[BULLETSRESIST], [CRITRESIST] = defCharacterUpgrades[CRITRESIST], [FIRERESIST] = defCharacterUpgrades[FIRERESIST], [HEALTHREGEN] = defCharacterUpgrades[HEALTHREGEN], [METALREGEN] = defCharacterUpgrades[METALREGEN], [MOVESPEED] = defCharacterUpgrades[MOVESPEED], [JUMPHEIGHT] = defCharacterUpgrades[JUMPHEIGHT]}},
			},
			[TF_TEAM_BLU] = {
				[TF_CLASS_SCOUT] =			{"canteenCharges": 0, "refundableAmountSpent": 0, "nonRefundableAmountSpent": 0, "refundOnSpawn": true,
				"characterUpgrades": {[BLASTRESIST] = defCharacterUpgrades[BLASTRESIST], [BULLETSRESIST] = defCharacterUpgrades[BULLETSRESIST], [CRITRESIST] = defCharacterUpgrades[CRITRESIST], [FIRERESIST] = defCharacterUpgrades[FIRERESIST], [HEALTHREGEN] = defCharacterUpgrades[HEALTHREGEN], [METALREGEN] = defCharacterUpgrades[METALREGEN], [MOVESPEED] = defCharacterUpgrades[MOVESPEED], [JUMPHEIGHT] = defCharacterUpgrades[JUMPHEIGHT]}},
				[TF_CLASS_SOLDIER] = 		{"canteenCharges": 0, "refundableAmountSpent": 0, "nonRefundableAmountSpent": 0, "refundOnSpawn": true,
				"characterUpgrades": {[BLASTRESIST] = defCharacterUpgrades[BLASTRESIST], [BULLETSRESIST] = defCharacterUpgrades[BULLETSRESIST], [CRITRESIST] = defCharacterUpgrades[CRITRESIST], [FIRERESIST] = defCharacterUpgrades[FIRERESIST], [HEALTHREGEN] = defCharacterUpgrades[HEALTHREGEN], [METALREGEN] = defCharacterUpgrades[METALREGEN], [MOVESPEED] = defCharacterUpgrades[MOVESPEED], [JUMPHEIGHT] = defCharacterUpgrades[JUMPHEIGHT]}},
				[TF_CLASS_PYRO] = 			{"canteenCharges": 0, "refundableAmountSpent": 0, "nonRefundableAmountSpent": 0, "refundOnSpawn": true,
				"characterUpgrades": {[BLASTRESIST] = defCharacterUpgrades[BLASTRESIST], [BULLETSRESIST] = defCharacterUpgrades[BULLETSRESIST], [CRITRESIST] = defCharacterUpgrades[CRITRESIST], [FIRERESIST] = defCharacterUpgrades[FIRERESIST], [HEALTHREGEN] = defCharacterUpgrades[HEALTHREGEN], [METALREGEN] = defCharacterUpgrades[METALREGEN], [MOVESPEED] = defCharacterUpgrades[MOVESPEED], [JUMPHEIGHT] = defCharacterUpgrades[JUMPHEIGHT]}},
				[TF_CLASS_DEMOMAN] = 		{"canteenCharges": 0, "refundableAmountSpent": 0, "nonRefundableAmountSpent": 0, "refundOnSpawn": true,
				"characterUpgrades": {[BLASTRESIST] = defCharacterUpgrades[BLASTRESIST], [BULLETSRESIST] = defCharacterUpgrades[BULLETSRESIST], [CRITRESIST] = defCharacterUpgrades[CRITRESIST], [FIRERESIST] = defCharacterUpgrades[FIRERESIST], [HEALTHREGEN] = defCharacterUpgrades[HEALTHREGEN], [METALREGEN] = defCharacterUpgrades[METALREGEN], [MOVESPEED] = defCharacterUpgrades[MOVESPEED], [JUMPHEIGHT] = defCharacterUpgrades[JUMPHEIGHT]}},
				[TF_CLASS_HEAVYWEAPONS] = 	{"canteenCharges": 0, "refundableAmountSpent": 0, "nonRefundableAmountSpent": 0, "refundOnSpawn": true,
				"characterUpgrades": {[BLASTRESIST] = defCharacterUpgrades[BLASTRESIST], [BULLETSRESIST] = defCharacterUpgrades[BULLETSRESIST], [CRITRESIST] = defCharacterUpgrades[CRITRESIST], [FIRERESIST] = defCharacterUpgrades[FIRERESIST], [HEALTHREGEN] = defCharacterUpgrades[HEALTHREGEN], [METALREGEN] = defCharacterUpgrades[METALREGEN], [MOVESPEED] = defCharacterUpgrades[MOVESPEED], [JUMPHEIGHT] = defCharacterUpgrades[JUMPHEIGHT]}},
				[TF_CLASS_ENGINEER] = 		{"canteenCharges": 0, "refundableAmountSpent": 0, "nonRefundableAmountSpent": 0, "refundOnSpawn": true,
				"characterUpgrades": {[BLASTRESIST] = defCharacterUpgrades[BLASTRESIST], [BULLETSRESIST] = defCharacterUpgrades[BULLETSRESIST], [CRITRESIST] = defCharacterUpgrades[CRITRESIST], [FIRERESIST] = defCharacterUpgrades[FIRERESIST], [HEALTHREGEN] = defCharacterUpgrades[HEALTHREGEN], [METALREGEN] = defCharacterUpgrades[METALREGEN], [MOVESPEED] = defCharacterUpgrades[MOVESPEED], [JUMPHEIGHT] = defCharacterUpgrades[JUMPHEIGHT]}},
				[TF_CLASS_MEDIC] = 			{"canteenCharges": 0, "refundableAmountSpent": 0, "nonRefundableAmountSpent": 0, "refundOnSpawn": true,
				"characterUpgrades": {[BLASTRESIST] = defCharacterUpgrades[BLASTRESIST], [BULLETSRESIST] = defCharacterUpgrades[BULLETSRESIST], [CRITRESIST] = defCharacterUpgrades[CRITRESIST], [FIRERESIST] = defCharacterUpgrades[FIRERESIST], [HEALTHREGEN] = defCharacterUpgrades[HEALTHREGEN], [METALREGEN] = defCharacterUpgrades[METALREGEN], [MOVESPEED] = defCharacterUpgrades[MOVESPEED], [JUMPHEIGHT] = defCharacterUpgrades[JUMPHEIGHT]}},
				[TF_CLASS_SNIPER] = 		{"canteenCharges": 0, "refundableAmountSpent": 0, "nonRefundableAmountSpent": 0, "refundOnSpawn": true,
				"characterUpgrades": {[BLASTRESIST] = defCharacterUpgrades[BLASTRESIST], [BULLETSRESIST] = defCharacterUpgrades[BULLETSRESIST], [CRITRESIST] = defCharacterUpgrades[CRITRESIST], [FIRERESIST] = defCharacterUpgrades[FIRERESIST], [HEALTHREGEN] = defCharacterUpgrades[HEALTHREGEN], [METALREGEN] = defCharacterUpgrades[METALREGEN], [MOVESPEED] = defCharacterUpgrades[MOVESPEED], [JUMPHEIGHT] = defCharacterUpgrades[JUMPHEIGHT]}},
				[TF_CLASS_SPY] = 			{"canteenCharges": 0, "refundableAmountSpent": 0, "nonRefundableAmountSpent": 0, "refundOnSpawn": true,
				"characterUpgrades": {[BLASTRESIST] = defCharacterUpgrades[BLASTRESIST], [BULLETSRESIST] = defCharacterUpgrades[BULLETSRESIST], [CRITRESIST] = defCharacterUpgrades[CRITRESIST], [FIRERESIST] = defCharacterUpgrades[FIRERESIST], [HEALTHREGEN] = defCharacterUpgrades[HEALTHREGEN], [METALREGEN] = defCharacterUpgrades[METALREGEN], [MOVESPEED] = defCharacterUpgrades[MOVESPEED], [JUMPHEIGHT] = defCharacterUpgrades[JUMPHEIGHT]}},
			},
		},
	};

	return entry;
}

function GetPlayerEntry(player) { return playersData[GetPlayerSteamID(player)]; }

function GetClassEntry(player, playerClass = -1, playerTeam = -1)
{
	if (playerTeam == -1) { playerTeam = player.GetTeam(); }
	if (playerClass == -1) { playerClass = player.GetPlayerClass(); }
	return GetPlayerEntry(player)["teamData"][playerTeam][playerClass];
}

function GetPlayerCanteen(player)
{
	for (local item = player.FirstMoveChild(); item != null; item = item.NextMovePeer()) { if (item.GetClassname() == "tf_powerup_bottle") { return item; }; }
	return null;
}

function GetCanteenCharges(canteen)
{
	if (canteen != null) { return NetProps.GetPropInt(canteen, "m_usNumCharges"); }
	else { return 0; }
}

function SetCanteenCharges(canteen, amount)
{
	if (canteen == null) { return; }
	if (amount < 0) amount = 0;
	if (amount > 3) amount = 3;
	NetProps.SetPropInt(canteen, "m_usNumCharges", amount);
}

function GetPlayerName(player){ return NetProps.GetPropString(player, "m_szNetname") }

function GetPlayerSteamID(player) //If the player doesn't have a steamid stored in their script scope
{
	if (!("steamid" in player.GetScriptScope()))
	{
		local steamid = NetProps.GetPropString(player, "m_szNetworkIDString");
		if (steamid == "BOT") { steamid = "BOT" + (playersData.len() + 1); }
		player.GetScriptScope()["steamid"] <- steamid;
	}

	return player.GetScriptScope()["steamid"];
}

function CreatePlayerScriptScopeAndVariables(player)
{
	player.ValidateScriptScope();
	player.GetScriptScope().currentClass <- 0;
	player.GetScriptScope().currentTeam <- 0;
	player.GetScriptScope().currency <- 0;
	player.GetScriptScope().isFullySpawned <- false;
	player.GetScriptScope().isRefunding <- false;
	player.GetScriptScope().weaponIds <- [];

	player.GetScriptScope().buttonsLast <- 0;
	player.GetScriptScope().buttons <- 0;
	player.GetScriptScope().isInMvmUpgradeStationTrigger <- false;
	player.GetScriptScope().timeLastPlayedUpgradeVoiceline <- 0;
	player.GetScriptScope().currentEffect <- "none";
	player.GetScriptScope().isInAnEffect <- false;

	player.GetScriptScope().busterWearable <- null;
	player.GetScriptScope().busterProp <- null;
	player.GetScriptScope().bustingSequenceActive <- false;

	player.GetScriptScope().timeLastSpooked <- 0;
}

::GetPlayerWeapons <- function(player)
{
	local weapons = [];
	for (local i = 0; i < MAX_WEAPONS; i++)
	{
		local weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
		if (weapon == null) continue
		weapons.push(weapon);
	}
	return weapons;
}

::GetPlayerWearables <- function(player)
{
	local wearables = [];
	for (local wearable = player.FirstMoveChild(); wearable != null; wearable = wearable.NextMovePeer())
	{
		if (wearable.GetClassname() == "tf_wearable" || wearable.GetClassname() == "tf_powerup_bottle" || wearable.GetClassname() == "tf_wearable_demoshield" || wearable.GetClassname() == "tf_wearable_razorback") { wearables.push(wearable); }
	}
	return wearables;
}

function GetCanteenHandshakeAttribute(canteen, specificAttribute = "")
{
	if (specificAttribute == "") { foreach(upgrade, value in canteenTable)
	{
		if (canteen.GetAttribute(upgrade, 0)) { return upgrade; }
	}}

	return canteen.GetAttribute(specificAttribute, 0);
}

function Chance(percent)
{
	if (RandomInt(0, 100) <= percent) { return true; }
	else { return false; }
}

function RefundPlayerUpgrades(player)
{
	local playerEntry = GetPlayerEntry(player);
	local classEntry = GetClassEntry(player);
	player.GetScriptScope().isRefunding = true;
	classEntry["canteenCharges"] = 0;
	classEntry["refundableAmountSpent"] = 0;

	player.GrantOrRemoveAllUpgrades(true, false);
	local params = {"player": player, "classEntry": classEntry}
	player.SetCurrency(CalculateClassCurrencyLevel(player));
	SetCanteenCharges(GetPlayerCanteen(player), classEntry["canteenCharges"]);
	player.GetScriptScope().isRefunding = false;
}

function SetPlayerCurrencyToCalculatedLevel() { activator.SetCurrency(CalculateClassCurrencyLevel(activator)); }
::SetPlayerWeaponsVisible <- function(player, state) { foreach(weapon in GetPlayerWeapons(player)) if (state) weapon.EnableDraw(); else weapon.DisableDraw(); }
::SetPlayerCosmeticsVisible <- function(player, state) { foreach(wearable in GetPlayerWearables(player)) { if (state) wearable.EnableDraw(); else wearable.DisableDraw(); } }

::SetPlayerIsASentryBuster <- function(player, state)
{
	if (state)
	{
		player.AddCustomAttribute("damage force reduction", 0.6, duration)
		player.AddCustomAttribute("override footstep sound set", 7, duration)
		player.AddCustomAttribute("no_attack", 1, duration)
		player.AddCustomAttribute("voice pitch scale", 0, duration)
		player.AddCustomAttribute("disable weapon switch", 1, duration)
		player.AddCustomAttribute("max health additive bonus", BUSTERHEALTH - player.GetMaxHealth(), duration - 0.01)

		SetPlayerCosmeticsVisible(player, false);
		SetPlayerWeaponsVisible(player, false);
		player.SetHealth(BUSTERHEALTH);
		player.SetForcedTauntCam(1);
		NetProps.SetPropInt(player, "m_nRenderMode", Constants.ERenderMode.kRenderNone);
		EmitAmbientSoundOn(BUSTERIDLESOUND, 100, 110, 100, player);

		player.GetScriptScope().busterWearable <- CreateBusterWearable(player);
	}
	else
	{
		player.SetMoveType(MOVETYPE_WALK, MOVECOLLIDE_DEFAULT)
		player.GetScriptScope().bustingSequenceActive = false;

		player.RemoveCustomAttribute("damage force reduction")
		player.RemoveCustomAttribute("override footstep sound set")
		player.RemoveCustomAttribute("no_attack")
		player.RemoveCustomAttribute("voice pitch scale")
		player.RemoveCustomAttribute("disable weapon switch")
		player.RemoveCustomAttribute("max health additive bonus")

		SetPlayerCosmeticsVisible(player, true);
		SetPlayerWeaponsVisible(player, true);
		if (player.IsAlive()){ player.SetHealth(player.GetMaxHealth()); }
		player.SetForcedTauntCam(0);
		NetProps.SetPropInt(player, "m_nRenderMode", Constants.ERenderMode.kRenderNormal);
		StopAmbientSoundOn(BUSTERIDLESOUND, player);

		if (player.GetScriptScope().busterWearable != null) {  player.GetScriptScope().busterWearable.Kill(); player.GetScriptScope().busterWearable = null; }
		if (player.GetScriptScope().busterProp != null) {  player.GetScriptScope().busterProp.Kill(); player.GetScriptScope().busterProp = null; }
	}
}

::CreateBusterWearable <- function(player)
{
	local wearable = Entities.CreateByClassname("tf_wearable")
	NetProps.SetPropInt(wearable, "m_nModelIndex", PrecacheModel(BUSTERMODEL))
	NetProps.SetPropBool(wearable, "m_bValidatedAttachedEntity", true)
	wearable.SetOwner(player)
	wearable.SetTeam(player.GetTeam())
	wearable.DispatchSpawn()
	wearable.KeyValueFromString("classname", "sentrybuster_wearable")
	wearable.AcceptInput("SetParent", "!activator", player, player)
	NetProps.SetPropInt(wearable, "m_fEffects", 129)
	return wearable;
}

::CreateBusterProp <- function(player)
{
	return SpawnEntityFromTable("prop_dynamic", {
		"angles": player.GetAbsAngles(),
		"skin": player.GetTeam() == TF_TEAM_RED ? 0 : 1,
		"model": BUSTERMODEL,
		"DefaultAnim": "sentry_buster_preExplode",
		"origin": player.GetOrigin(),
	});
}

function AwardCreditsToTeam(team, amount)
{
	banks[team] += amount;
	foreach(player in GetPlayers(team))
	{
		if (!player.GetScriptScope().isInMvmUpgradeStationTrigger) { player.SetCurrency(CalculateClassCurrencyLevel(player)); }
		else { CalculateClassCurrencyLevel(player); }
	}
}

function CalculateClassCurrencyLevel(player, entryOverride = null)
{
	local classEntry = entryOverride == null ? GetClassEntry(player) : entryOverride;
	return banks[player.GetTeam()] - (classEntry["nonRefundableAmountSpent"] + classEntry["refundableAmountSpent"])
}

function CreditMath()
{
	local L = lobbySize;
	if (L < 4) { L = 4; }
	if (L > 24) { L = 24; }
	return 100 - ((L - 4) * CREDIT_MULTIPLIER);
}

function ApplyEffectOnPlayer(player, effect)
{
	local effectEntry = effectsTable[effect]
	local params = { "player": player, "duration": effectEntry["duration"] }

	if (!effectEntry["canDisguiseDuring"]) { player.AddCustomAttribute("cannot disguise", 1, effectEntry["duration"]); }
	effectEntry["behaviour"](params);

	local sound = effectEntry["soundsOnUse"].len() > 0 ? effectEntry["soundsOnUse"][RandomInt(0, effectEntry["soundsOnUse"].len() - 1)] : "";

	if (sound != "")
	{
		for(local noiseRecipient; noiseRecipient = Entities.FindByClassnameWithin(noiseRecipient, "player", player.GetOrigin(), POTIONNOISERANGE);)
		{
			EmitSoundEx({
			sound_name = sound,
			origin = player.GetCenter(),
			entity = noiseRecipient,
			filter_type = RECIPIENT_FILTER_SINGLE_PLAYER})
		}
	}
}


function GiveNegativeCanteenUseFeedback(player, canteen)
{
	if (effectEntry["playerTLK"] != "") { player.AcceptInput("SpeakResponseConcept", effectEntry["playerTLK"] + " randomnum:100", null, null) }

	player.GetScriptScope().isInAnEffect = true;
	EntFireByHandle(self, "RunScriptCode", "ResetEffectOnPlayer(" + @"""" + effect + @""")", effectEntry["duration"], player, null);
}

function ResetEffectOnPlayer(effect) //Secret usage of activator. Don't tell anyone.
{
	local effectEntry = effectsTable[effect]
	local params = { "player": activator, "duration": effectEntry["duration"] }
	effectEntry["resetBehaviour"](params);
	params.player.GetScriptScope().isInAnEffect = false;
}

function ResetAllEffectsOnPlayer(player)
{
	foreach(effect, effectEntry in effectsTable) { effectEntry["resetBehaviour"]({ "player": player, "duration": 0 }); }
	player.GetScriptScope().isInAnEffect = false;
}

::ApplySpellOnPlayer <- function(player, index)
{
	local spellbook = SpawnEntityFromTable("tf_weapon_spellbook", { origin = player.GetOrigin(), teamnum = player.GetTeam() })
	NetProps.SetPropInt(spellbook, "m_iSelectedSpellIndex", index)
	NetProps.SetPropInt(spellbook, "m_iSpellCharges", 1)
	spellbook.SetOwner(player)
	player.Weapon_Equip(spellbook)
	NetProps.SetPropFloat(spellbook, "m_flNextPrimaryAttack", Time())
	spellbook.PrimaryAttack()
}

function GiveNegativeCanteenUseFeedback(player, canteen)
{
	EmitSoundEx({
		sound_name = POTIONCANTBEUSEDSOUND,
		origin = player.GetCenter(),
		entity = player,
		filter_type = RECIPIENT_FILTER_SINGLE_PLAYER
	})

	SetCanteenCharges(canteen, GetCanteenCharges(canteen) + 1);
}

function GetPotionEffect(player, canteenType)
{
	local effectType = canteenType == "rtd" ? rtdEffects[RandomInt(0, rtdEffects.len() - 1)] : canteenType;

	if (effectsTable[effectType]["requirementsCheck"](player) == false)
	{
		if (canteenType == "rtd") { return GetPotionEffect(player, "rtd"); }
		else { return "none"; }
	}
	else { return effectType; }
}

function SetPlayerIsInMvmUpgradeStationTrigger(state) { activator.GetScriptScope().isInMvmUpgradeStationTrigger <- state; }

function ManuallyCalculatePlayerCurrencyDelta(player, entryOverride = null)
{
	local classEntry = entryOverride == null ? GetClassEntry(player) : entryOverride;
	local delta;
	if (entryOverride != null) { delta = CalculateClassCurrencyLevel(player) - player.GetCurrency(); }
	else { delta = CalculateClassCurrencyLevel(player, classEntry) - player.GetScriptScope().currency; }
	//delta =-300 - 0
	classEntry["refundableAmountSpent"] += delta;
}

function ManuallySetCurrencyLevelOnPlayer() { activator.SetCurrency(CalculateClassCurrencyLevel(activator)); }

function GetAllCharacterUpgradesOnPlayer(player)
{
	DebugPrint("GETTNG UPGRADES")
	local classEntry = GetClassEntry(player);

	foreach (upgrade, value in classEntry["characterUpgrades"])
	{
		local returnedValue = player.GetCustomAttribute(upgrade, SPOOFVALUE);
		local printValue = value;
		local printReturnedValue = returnedValue;
		if (value == defCharacterUpgrades[upgrade]) { printValue = "DEFAULT VALUE"}
		if (returnedValue == SPOOFVALUE) { printReturnedValue = "ATTRIB NOT ON PLAYER"}
		DebugPrint(GetShortenedPlayerAttributeName(upgrade) + " E " + printValue + " P " + printReturnedValue);

		if (returnedValue == SPOOFVALUE) { classEntry["characterUpgrades"][upgrade] = defCharacterUpgrades[upgrade]; continue; } //Player doesn't have this attribute. Record the default value. Leave this instance of the loop
		classEntry["characterUpgrades"][upgrade] = returnedValue; //Player has this attribute. Record its value
	}
}

function SetAllCharacterUpgradesOnPlayer(player = null) //Uses activator. Don't tell anyone.
{
	DebugPrint("SETTNG UPGRADES")
	local player = player == null ? activator : player;
	local classEntry = GetClassEntry(player);

	foreach (upgrade, value in classEntry["characterUpgrades"])
	{
		local returnedValue = player.GetCustomAttribute(upgrade, SPOOFVALUE);
		local printValue = value;
		local printReturnedValue = returnedValue;
		if (value == defCharacterUpgrades[upgrade]) { printValue = "DEFAULT VALUE"}
		if (returnedValue == SPOOFVALUE) { printReturnedValue = "ATTRIB NOT ON PLAYER"}
		DebugPrint(GetShortenedPlayerAttributeName(upgrade) + " E " + printValue + " P " + printReturnedValue);

		if (returnedValue == SPOOFVALUE) { classEntry["characterUpgrades"][upgrade] = defCharacterUpgrades[upgrade]; continue; } //Player doesn't have this attribute. Don't record any value for it. Leave this instance of the loop
		if (returnedValue == defCharacterUpgrades[upgrade]) { player.RemoveCustomAttribute(upgrade); continue } //If its set to the default of this value. Remove it as it might as well not be present on the player. Fixes hud stuff in menu. Leave this instance of the loop
		player.AddCustomAttribute(upgrade, value, -1); //If the player has the attribute and it's not the default value, set it to the value in the class entry
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
///GAME EVENTS///
//////////////////////////////////////////////////////////////////////////////////////////////////////
local EventsID = UniqueString()
getroottable()[EventsID] <-
{
	// Cleanup events on round restart. Do not remove this event.
	OnGameEvent_scorestats_accumulated_update = function(_) { ForceEnableUpgrades(2); firstSpawnOfInitialSpawnWaveisDueToHappen = true; delete getroottable()[EventsID] }

	//Every time it validates your inventory. Note that this happens BEFORE the player spawn event, as well as Round Start.
	OnGameEvent_post_inventory_application = function(params)  //FIRE ORDER ON NEW ROUND : 1 // FIRE ORDER ON PLAYER JOIN : 2
	{
		local eventMessage = "POST INVENTORY APPLICATION EVENT - " + Time() + " - " + GetRoundStateNameFromIndex(GetRoundState());
		if (GetRoundState() == GR_STATE_PREGAME) { eventMessage += " - SKIPPED!"; }
		if (printEventDetails) { DebugPrint(eventMessage); }
		if (GetRoundState() == GR_STATE_PREGAME) return; //If this is being called before the game starts, return
		if (GetRoundState() == GR_STATE_PREROUND) //If this is being called before the round starts
		{
			if (firstSpawnOfInitialSpawnWaveisDueToHappen) //Only called once per round starting
			{
				playersData.clear();
				firstSpawnOfInitialSpawnWaveisDueToHappen = false;
				banks[TF_TEAM_RED] = STARTINGCREDITS; banks[TF_TEAM_BLU] = STARTINGCREDITS;
				ForceEnableUpgrades(2)
			}
		}

		local player = GetPlayerFromUserID(params.userid);
		if (!PlayerEntryExists(player)) { CreatePlayerEntry(player); }
		local canteen = GetPlayerCanteen(player);
		local playerEntry = GetPlayerEntry(player);
		local classEntry = GetClassEntry(player);
		local playerIsSameClassAsLastInventoryUpdate = player.GetPlayerClass() == player.GetScriptScope().currentClass;
		local playerHasDifferentWeaponsThanLastTime = false;
		local weaponIds = [];

		foreach (weapon in GetPlayerWeapons(player)) { weaponIds.push(NetProps.GetPropInt(weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex")); }
		if (playerIsSameClassAsLastInventoryUpdate) { for (local i = 0; i < weaponIds.len(); i++) { if (player.GetScriptScope().weaponIds[i] != weaponIds[i]) { playerHasDifferentWeaponsThanLastTime = true; break; } } }
		if (playerHasDifferentWeaponsThanLastTime && playerIsSameClassAsLastInventoryUpdate) { RefundPlayerUpgrades(player); }

		player.GetScriptScope().weaponIds = weaponIds;

		local playerIsExchangingMoneyNormally = player.GetScriptScope().isFullySpawned && !player.GetScriptScope().isRefunding //Fully Spawned, Not Refunding

		if (playerIsExchangingMoneyNormally)
		{
			DebugPrint("----------------------------------------")
			DebugPrint("PLAYER EXCHANGING MONEY IN A REGULAR WAY")
			DebugPrint("----------------------------------------")
			local classEntry = GetClassEntry(player);
			local delta = CalculateClassCurrencyLevel(player) - player.GetCurrency();
			classEntry["refundableAmountSpent"] += delta; //Record the amount just spent/refunded as the amount added/removed from the refundable balance

			local voicelineShouldBePlayed = player.GetScriptScope().isInMvmUpgradeStationTrigger && Chance(UPGRADEVOICELINECHANCE) && delta > 0 && (Time() - player.GetScriptScope().timeLastPlayedUpgradeVoiceline > VOICELINECOOLDOWN)

			if (voicelineShouldBePlayed)
			{
				local canteenWasBought = canteen != null ? classEntry["canteenCharges"] < GetCanteenCharges(canteen) : false;
				local soundName = "MoneyMap.Upgraded" + (canteenWasBought ? "Canteen." : ".") + GetClassNameFromIndex(player.GetPlayerClass());

				EmitSoundEx({
					sound_name = soundName,
					origin = player.GetCenter(),
					entity = player,
					speaker_entity = player
				})

				player.GetScriptScope().timeLastPlayedUpgradeVoiceline <- Time();
			}

			if (canteen != null) { classEntry["canteenCharges"] = GetCanteenCharges(canteen) } //Update the canteen charges to the new value. If the player has a canteen, it will be set to the canteen's charges. If not, it will be set to whatever their current listing is.
		}

		if (player.GetScriptScope().isFullySpawned) { GetAllCharacterUpgradesOnPlayer(player); }

		player.GetScriptScope().currency = player.GetCurrency();
	}

	OnGameEvent_player_changeclass = function(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		player.RemoveCustomAttribute("disable weapon switch") //For when the player was a buster and they change class. Makes them able to switch to their weapon immediately, so civilianing doesn't occur after being a sentry buster
		if (player.GetScriptScope().isFullySpawned)
		{
			ManuallyCalculatePlayerCurrencyDelta(player,  GetClassEntry(player, player.GetScriptScope().currentClass, player.GetScriptScope().currentTeam));
		}
	}

	OnGameEvent_player_spawn = function(params) //FIRE ORDER ON NEW ROUND : 2 // FIRE ORDER ON PLAYER JOIN : 1, 3 // FIRE ORDER ON PLAYER RESPAWN
	{
		local eventMessage = "PLAYER SPAWN EVENT - " + Time() + " - " + GetRoundStateNameFromIndex(GetRoundState());
		if (GetRoundState() == GR_STATE_PREGAME) { eventMessage += " - SKIPPED!"; }
		if (printEventDetails) { DebugPrint(eventMessage); }
		if (GetRoundState() == GR_STATE_PREGAME || params.team == 0) { CreatePlayerScriptScopeAndVariables(GetPlayerFromUserID(params.userid)); return; } //If this is being called before the game starts, OR if the player hasn't been assigned a team. return

		local player = GetPlayerFromUserID(params.userid);
		if (!PlayerEntryExists(player)) { return; } //If the player doesn't have an entry, return. THIS OCCURS WHEN A PLAYER JOINS AN EXISTENT ROUND. IT'S THEN CREATED IN THE POST INV EVENT
		local playerEntry = GetPlayerEntry(player);
		local classEntry = GetClassEntry(player);
		local canteen = GetPlayerCanteen(player);
		local playerIsADifferentClass = player.GetScriptScope().currentClass != params["class"];

		ResetAllEffectsOnPlayer(player);
		EntFireByHandle(self, "RunScriptCode", "SetAllCharacterUpgradesOnPlayer()", 0, player, null)

		player.GetScriptScope().currentTeam = params["team"];
		player.GetScriptScope().currentClass = params["class"];
		player.GetScriptScope().isFullySpawned = true;

		if (classEntry["refundOnSpawn"]) { RefundPlayerUpgrades(player); classEntry["refundOnSpawn"] = false; return; }

		player.SetCurrency(CalculateClassCurrencyLevel(player));
		SetCanteenCharges(GetPlayerCanteen(player), classEntry["canteenCharges"]);
	}

	OnGameEvent_scorestats_accumulated_update = function(params)
	{
		if (printEventDetails) { DebugPrint("SCORESTATS ACCUMULATED UPDATE - " + Time() + " - " + GetRoundStateNameFromIndex(GetRoundState())); }
		firstSpawnOfInitialSpawnWaveisDueToHappen = true;
	}

	OnGameEvent_player_team = function(params)
	{
		if (printEventDetails) { DebugPrint("PLAYER TEAM EVENT - " + Time() + " - " + GetRoundStateNameFromIndex(GetRoundState())); }
		if (params.disconnect) { lobbySize--; return; } //If they're disconnecting
		if (params.oldteam <= 1 && params.team > 1) { lobbySize++; } //If their old team is spectator/unassigned, and their new team is Red or Blu
		if (params.oldteam > 1 && params.team <= 1) { lobbySize--; } //If their old team is Red or Blu, and their new team is spectator/unassigned
	}

	OnGameEvent_player_used_powerup_bottle = function(params)
	{
		if (printEventDetails) { DebugPrint("PLAYER USED POWERUP BOTTLE EVENT"); }
		local player = PlayerInstanceFromIndex(params.player);
		local playerCanUsePotions = !player.InCond(TF_COND_STEALTHED) && !player.InCond(TF_COND_STEALTHED_BLINK) && !player.InCond(TF_COND_SHIELD_CHARGE) && player.GetScriptScope().isInAnEffect == false && NetProps.GetPropBool(player, "m_Shared.m_bFeignDeathReady") == false;
		if (!playerCanUsePotions) { GiveNegativeCanteenUseFeedback(player, GetPlayerCanteen(player)); return;}
		local canteen = GetPlayerCanteen(player);
		local canteenType = canteenTable[GetCanteenHandshakeAttribute(canteen)]["potionType"];
		local effect = GetPotionEffect(player, canteenType);
		if (effect == "none") { GiveNegativeCanteenUseFeedback(player, canteen); return; }

		if (player.InCond(TF_COND_DISGUISED) || player.InCond(TF_COND_DISGUISING) || player.InCond(TF_COND_DISGUISE_WEARINGOFF)) { player.RemoveDisguise() }
		ApplyEffectOnPlayer(player, effect);
		local PLAYERPRINTCOLOUR = player.GetTeam() == TF_TEAM_RED ? REDPRINTCOLOUR : BLUPRINTCOLOUR;
		local printedMessage = (PLAYERPRINTCOLOUR + GetPlayerName(player) + DEFAULTPRINTCOLOUR + " " + canteenTable[GetCanteenHandshakeAttribute(canteen)]["message"] + " " + effectsTable[effect]["message"]);
		ClientPrint(null, HUD_PRINTTALK, printedMessage);
		local classEntry = GetClassEntry(player);
		local potionEntry = canteenTable[GetCanteenHandshakeAttribute(canteen)];
		classEntry["nonRefundableAmountSpent"] += potionEntry["cost"];
		classEntry["refundableAmountSpent"] -= potionEntry["cost"];
		classEntry["canteenCharges"]--;
	}

	OnGameEvent_player_death = function(params)
	{
		if (printEventDetails) { DebugPrint("PLAYER DEATH EVENT"); }
		if ((params.attacker == null && !params.attacker.IsPlayer()) || params.death_flags & 32) { DebugPrint("returning inside death event"); return; }
		local player = GetPlayerFromUserID(params.userid);
		local playerEntry = GetPlayerEntry(player);
		local killerTeam = GetPlayerFromUserID(params.attacker).GetTeam();

		SetPlayerIsASentryBuster(player, false);
		player.GetScriptScope().isFullySpawned = false;

		if (killerTeam > 1 && killerTeam != player.GetTeam()) //check that the killer isnt spectate, and that the killer isn't from their own team
		{
			AwardCreditsToTeam(killerTeam, CreditMath()); //award credits to killer's team members
			DispatchParticleEffect("env_grinder_oilspray_cash", player.GetLocalOrigin(), Vector(0,90,0) );
			player.EmitSound("MVM.MoneyPickup");
		}

		ManuallyCalculatePlayerCurrencyDelta(player, GetClassEntry(player,  player.GetScriptScope().currentClass, player.GetScriptScope().currentTeam));
	}

	OnScriptHook_OnTakeDamage = function(params) { if (params.inflictor != null && params.inflictor.GetClassname() == "entity_medigun_shield") { params.damage <- 0; } }
}

local EventsTable = getroottable()[EventsID]
__CollectGameEventCallbacks(EventsTable)
foreach (name, callback in EventsTable) EventsTable[name] = callback.bindenv(this)

::GhostThink <- function()
{
	local player = self;
	local buttonsLast = buttons ? buttons != null : 0;
	local buttons = NetProps.GetPropInt(self, "m_nButtons")
	local buttonsChanged = buttonsLast ^ buttons
	local buttonsPressed = buttonsChanged & buttons
	local buttonsReleased = buttonsChanged & (~buttons)

	local playerIsToInitateASpookingSequence = Time() - player.GetScriptScope().timeLastSpooked >= GHOSTSPOOKDELAY;

	if (playerIsToInitateASpookingSequence) { InitiatePlayerSpookingSequence(player); }

	return -1;
}

::InitiatePlayerSpookingSequence <- function(player)
{
	player.GetScriptScope().timeLastSpooked = Time();

	EmitSoundEx({
		sound_name = GHOSTSOUNDS[RandomInt(0, GHOSTSOUNDS.len() - 1)],
		origin = player.GetCenter(),
		entity = player,
		speaker_entity = player
	})

	local spookAttackTargetTeam = player.GetTeam() == TF_TEAM_RED ? TF_TEAM_BLU : TF_TEAM_RED;

	local enemyPlayersInRange = []; local playerInRange = null;
	while (playerInRange = Entities.FindByClassnameWithin(playerInRange, "player", player.GetOrigin(), GHOSTSPOOKRANGE))
		if (playerInRange.GetTeam() == spookAttackTargetTeam) { enemyPlayersInRange.push(playerInRange); }

	foreach (enemyPlayer in enemyPlayersInRange)
	{
		enemyPlayer.StunPlayer(1.5, 0.4, 64 | 128, player);

		EmitSoundEx({
			sound_name = SCREAMSOUNDS[RandomInt(0, SCREAMSOUNDS.len() - 1)],
			origin = enemyPlayer.GetCenter(),
			entity = enemyPlayer,
			speaker_entity = enemyPlayer
		})

	}
}

::BusterThink <- function() //The 'self' of this function is the same as player.GetScriptScope() elsewhere
{
	local player = self;
	local buttonsLast = buttons ? buttons != null : 0;
	local buttons = NetProps.GetPropInt(self, "m_nButtons")
	local buttonsChanged = buttonsLast ^ buttons
	local buttonsPressed = buttonsChanged & buttons
	local buttonsReleased = buttonsChanged & (~buttons)

	local playerCanInitiateBustingSequence = !bustingSequenceActive && player.GetFlags() & FL_ONGROUND && !player.InCond(TF_COND_STEALTHED) && !player.InCond(TF_COND_STEALTHED_BLINK);
	local playerIsTriggeringBustingSequence = buttonsPressed & IN_ATTACK || buttonsPressed & IN_ATTACK2 || player.InCond(TF_COND_TAUNTING);

	player.RemoveInvisibility();
	NetProps.SetPropFloat(player, "m_flMaxspeed", 400)
	player.RemoveCondEx(TF_COND_INVULNERABLE, true)
	player.RemoveCondEx(TF_COND_PHASE, true)

	if (playerCanInitiateBustingSequence && playerIsTriggeringBustingSequence) { InitiatePlayerBustingSequence(player); }

	return -1
}


::InitiatePlayerBustingSequence <- function(player)
{
	StopAmbientSoundOn(BUSTERIDLESOUND, player);
	player.GetScriptScope().bustingSequenceActive = true;
	player.GetScriptScope().busterWearable.Kill();
	player.GetScriptScope().busterWearable = null;
	player.GetScriptScope().busterProp = CreateBusterProp(player);
	player.SetMoveType(MOVETYPE_NONE, MOVECOLLIDE_DEFAULT)
	player.Taunt(TAUNT_BASE_WEAPON, 0)
	player.EmitSound(BUSTERSPINSOUND)

	EntFireByHandle(player, "RunScriptCode", "BusterExplode()", BUSTEREXPLODEDELAY, player, null);
}

::BusterExplode <- function() //Uses activator. Don't tell anyone.
{
	local player = activator;
	if (player.GetScriptScope().bustingSequenceActive == false) { return; }
	SetPlayerIsASentryBuster(player, false)

	player.EmitSound(BUSTEREXPLODESOUND);
	DispatchParticleEffect("explosionTrail_seeds_mvm", player.GetOrigin(), player.GetAngles())
	DispatchParticleEffect("fluidSmokeExpl_ring_mvm", player.GetOrigin(), player.GetAngles())
	ScreenShake(player.GetOrigin(), 25, 5, 5, 1000, 0, true)

	local busterAttackTargetTeam = player.GetTeam() == TF_TEAM_RED ? TF_TEAM_BLU : TF_TEAM_RED;

	local enemyPlayersInRange = []; local playerInRange = null;
	while (playerInRange = Entities.FindByClassnameWithin(playerInRange, "player", player.GetOrigin(), BUSTEREXPLOSIONRANGE))
		if (playerInRange.GetTeam() == busterAttackTargetTeam) enemyPlayersInRange.push(playerInRange);

	local enemyBuildingsInRange = []; local buildingInRange = null;
	while (buildingInRange = Entities.FindByClassnameWithin(buildingInRange, "obj_*", player.GetOrigin(), BUSTEREXPLOSIONRANGE))
		if (buildingInRange.GetTeam() == busterAttackTargetTeam) enemyBuildingsInRange.push(buildingInRange);

	foreach (enemyPlayer in enemyPlayersInRange) enemyPlayer.TakeDamage(5000, DMG_ALWAYSGIB, player);
	foreach (enemyBuilding in enemyBuildingsInRange) enemyBuilding.TakeDamage(5000, DMG_ALWAYSGIB, player);
	player.TakeDamage(5000, DMG_GENERIC, player)
}

function GetClassNameFromIndex(index)
{
	switch(index)
	{
		case TF_CLASS_UNDEFINED: return "UNDEFINED";
		case TF_CLASS_SCOUT: return "Scout";
		case TF_CLASS_SNIPER: return "Sniper";
		case TF_CLASS_SOLDIER: return "Soldier";
		case TF_CLASS_DEMOMAN: return "Demo";
		case TF_CLASS_MEDIC: return "Medic";
		case TF_CLASS_HEAVYWEAPONS: return "Heavy";
		case TF_CLASS_PYRO: return "Pyro";
		case TF_CLASS_SPY: return "Spy";
		case TF_CLASS_ENGINEER: return "Engie";
		case TF_CLASS_CIVILIAN: return "CIVILIAN";
		case TF_CLASS_COUNT_ALL: return "COUNT_ALL";
		case TF_CLASS_RANDOM: return "RANDOM";
		default: return "Unknown";
	}
}

function GetTeamNameFromIndex(index)
{
	switch (index) {
		case null: return "TEAM_UNASSIGNED";
		case 1: return "TEAM_SPECTATOR";
		case 2: return "RED TEAM";
		case 3: return "BLU TEAM";
		case 4: return "TF_TEAM_COUNT";
		case -2: return "TEAM_ANY";
		case -1: return "TEAM_INVALID";
		default: break;
	}
}

function GetRoundStateNameFromIndex(index)
{
	switch (index) {
		case 0: return "INIT";
		case 1: return "PREGAME";
		case 2: return "STARTGAME";
		case 3: return "PREROUND";
		case 4: return "RND_RUNNING";
		case 5: return "TEAM_WIN";
		case 6: return "RESTART";
		case 7: return "STALEMATE";
		case 8: return "GAME_OVER";
		case 9: return "BONUS";
		case 10: return "BETWEEN_RNDS";
		case 11: return "GR_NUM_ROUND_STATES";
		default: return "Unknown";
	}
}

function GetShortenedPlayerAttributeName(attribute)
{
	switch (attribute)
	{
		case BLASTRESIST: return "BLAST";
		case BULLETSRESIST: return "BULLET";
		case CRITRESIST: return "CRIT";
		case FIRERESIST: return "FIRE";
		case HEALTHREGEN: return "HEALTH";
		case METALREGEN: return "METAL";
		case MOVESPEED: return "SPEED";
		case JUMPHEIGHT: return "JUMP";
		default: return "Unknown";
	}
}

function PrintAllPlayerEntries(sourceMessage = "")
{
	ClientPrint(null, HUD_PRINTCONSOLE, "--------------------------------------------------");
	ClientPrint(null, HUD_PRINTCONSOLE, "PRINTING ALL PLAYER ENTRIES " + sourceMessage.toupper());
	ClientPrint(null, HUD_PRINTCONSOLE, "--------------------------------------------------");
	foreach(player in GetPlayers()) { PrintPlayerEntry(player, sourceMessage); }
	ClientPrint(null, HUD_PRINTCONSOLE, "");
	ClientPrint(null, HUD_PRINTCONSOLE, "--------------------------------------------------");
}

function PrintPlayerEntry(player, sourceMessage = "")
{
	ClientPrint(null, HUD_PRINTCONSOLE, "Player team: " + GetTeamNameFromIndex(player.GetScriptScope().currentTeam));
	ClientPrint(null, HUD_PRINTCONSOLE, "Current Player Class: " + GetClassNameFromIndex(player.GetScriptScope().currentClass));
	PrintPlayerTeamEntry(GetPlayerEntry(player)["teamData"][TF_TEAM_RED], "TF_TEAM_RED - " + banks[TF_TEAM_RED], player.GetScriptScope().currentClass, player.GetScriptScope().currentTeam == TF_TEAM_RED);
	PrintPlayerTeamEntry(GetPlayerEntry(player)["teamData"][TF_TEAM_BLU], "TF_TEAM_BLU - " + banks[TF_TEAM_BLU], player.GetScriptScope().currentClass, player.GetScriptScope().currentTeam == TF_TEAM_BLU);
}

function PrintPlayerTeamEntry(teamEntry, sourceMessage = "", currentClass = -1, isPlayersCurrentTeam = false)
{
	ClientPrint(null, HUD_PRINTCONSOLE, "");
	ClientPrint(null, HUD_PRINTCONSOLE, sourceMessage);

	foreach(classNum, entry in teamEntry)
	{
		local currencyMessage = "";
		currencyMessage += GetClassNameFromIndex(classNum).tostring();
		currencyMessage += "		";
		currencyMessage += " CURRENCY DELTA = " + (entry["refundableAmountSpent"] + entry["nonRefundableAmountSpent"])
		currencyMessage += "	";
		currencyMessage += " canteenCharges: " + entry["canteenCharges"];
		currencyMessage += " refundable: " + entry["refundableAmountSpent"];
		currencyMessage += " nonRefundable: " + entry["nonRefundableAmountSpent"];
		currencyMessage += " refundOnSpawn: " + entry["refundOnSpawn"];

		if (isPlayersCurrentTeam && currentClass == classNum) { currencyMessage += "<---------------"; }

		ClientPrint(null, HUD_PRINTCONSOLE, currencyMessage)
		ClientPrint(null, HUD_PRINTCONSOLE, "")
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
//Initial Setup Per-Server//
//////////////////////////////////////////////////////////////////////////////////////////////////////

function PrecacheStep()
{
	PrecacheModel(REDGHOSTMODEL);
	PrecacheModel(BLUGHOSTMODEL);
	PrecacheModel(BUSTERMODEL);
	PrecacheSound(BUSTEREXPLODESOUND);
	PrecacheSound(BUSTERSPINSOUND);
	PrecacheSound(BUSTERIDLESOUND);
	PrecacheSound(POTIONCANTBEUSEDSOUND);
	PrecacheScriptSound("Announcer.MVM_Bonus");
	PrecacheScriptSound("Announcer.MVM_Bonus");
	PrecacheScriptSound("MVM.MoneyPickup");
	PrecacheScriptSound("MVM.SentryBusterStep");

	for (local i = 1; i <= 9; i++)
	{
		PrecacheScriptSound("MoneyMap.Upgraded." + GetClassNameFromIndex(i));
		PrecacheScriptSound("MoneyMap.UpgradedCanteen." + GetClassNameFromIndex(i));
	}

	foreach (sound in SCREAMSOUNDS) { PrecacheSound(sound); }

	foreach (effect, effectEntry in effectsTable) { foreach (sound in effectEntry["soundsOnUse"])
		{
			PrecacheSound(sound);
		}
	}
}

PrecacheStep();

local statsEntity = Entities.FindByClassname(null, "tf_mann_vs_machine_stats");
if (statsEntity != null) statsEntity.Destroy();
Convars.SetValue("tf_mvm_respec_enabled", 1);
Convars.SetValue("tf_mvm_respec_limit", 0);
Convars.SetValue("tf_mvm_respec_credit_goal", 1);
Convars.SetValue("tf_dropped_weapon_lifetime", 0);
