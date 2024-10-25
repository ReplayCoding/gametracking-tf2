//////////////////////////////////////////////////////////////////////////////////////////////////////
///											BLOOD MONEY											   ///
///								Script and assets created by Diva Dan				               ///
///   This script enables MVM style potionType stations, with kills giving a team money to spend.	   ///
//////////////////////////////////////////////////////////////////////////////////////////////////////

ForceEnableUpgrades(2)
local GameRules = Entities.FindByClassname(null, "tf_gamerules")
local MAX_CLIENTS = MaxClients().tointeger()

::DebugPrint <- function(message) { if (developer() > 0) {printl(message)} }
::DebugClientPrint <- function(message) { if (developer() > 0) { ClientPrint(null, HUD_PRINTTALK, message); } }

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

"dmg taken from blast reduced";
"dmg taken from bullets reduced";
"dmg taken from crit reduced";
"dmg taken from fire reduced";
"health regen";
"metal regen";
"move speed bonus";
"increased jump height";

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

::UPGRADEABLEWEAPONATTRIBS <- [
	"damage bonus",
	"fire rate bonus",
	"melee attack rate bonus",
	"clip size bonus upgrade",
	"maxammo primary increased",
	"maxammo secondary increased",
	"maxammo grenades1 increased",
	"maxammo metal increased",
	"bleeding duration",
	"heal on kill",
	"projectile penetration",
	"projectile penetration heavy",
	"bidirectional teleport",
	"SRifle Charge rate increased",
	"effect bar recharge rate increased",
	"ubercharge rate bonus",
	"engy building health bonus",
	"engy sentry fire rate increased",
	"engy dispenser radius increased",
	"engy disposable sentries",
	"airblast pushback scale",
	"applies snare effect",
	"charge recharge rate increased",
	"uber duration bonus",
	"weapon burn dmg increased",
	"weapon burn time increased",
	"increase buff duration",
	"Projectile speed increased",
	"faster reload rate",
	"tag__eotlearlysupport",
	"attack projectiles",
	"generate rage on damage",
	"explosive sniper shot",
	"mark for death",
	"clip size upgrade atomic",
	"overheal expert",
	"mad milk syringes",
	"rocket specialist",
	"healing mastery",
	"generate rage on heal",
	"damage force reduction",
	"falling_impact_radius_stun",
	"thermal_thruster_air_launch",
	"mult_item_meter_charge_rate",
	"tag__eotlearlysupport",
	"freaky fair kritz potion",
	"freaky fair uber potion",
	"freaky fair giant potion",
	"freaky fair buster potion",
	"freaky fair healing potion",
	"freaky fair ghost potion",
	"freaky fair ammo potion",
	"freaky fair rtd potion",
	"dmg taken from fire reduced",
	"dmg taken from blast reduced",
	"dmg taken from bullets reduced",
	"dmg taken from crit reduced",
	"move speed bonus",
	"health regen",
	"metal regen",
	"increased jump height",
]

::CHARACTERUPGRADESATTRIBS <- {
	"dmg taken from blast reduced" :	1,
	"dmg taken from bullets reduced" :	1,
	"dmg taken from crit reduced" :		1,
	"dmg taken from fire reduced" :		1,
	"health regen" :					0,
	"metal regen" :						0,
	"move speed bonus" :				1,
	"increased jump height" :			1,
}


local encounteredWeaponsTrackedDefaultAttributes = {}

local banks = { [TF_TEAM_RED] = 0, [TF_TEAM_BLU] = 0 }
local lobbySize = 0; //amount of players currently in the lobby
local playersData = {};

local canteenTable = {
	"freaky fair kritz potion" : 				{"potionType": "kritz", 		"cost": 400,	"message": "has used a " + EFFECTPRINTCOLOUR + "KRITZ" + DEFAULTPRINTCOLOUR + " Potion"},
	"freaky fair uber potion" : 				{"potionType": "uber", 			"cost": 400,	"message": "has used a " + EFFECTPRINTCOLOUR + "UBER" + DEFAULTPRINTCOLOUR + " Potion"},
	"freaky fair giant potion" :	 			{"potionType": "giant", 		"cost": 300,	"message": "has used a " + EFFECTPRINTCOLOUR + "GIANT" + DEFAULTPRINTCOLOUR + " Potion and is now HUGE!"},
	"freaky fair buster potion" :				{"potionType": "buster", 		"cost": 300,	"message": "has used a " + EFFECTPRINTCOLOUR + "PUMPKIN BUSTER" + DEFAULTPRINTCOLOUR + " Potion"},
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

			DebugPrint("table.hit: " + table.hit)

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
		"duration": 5,
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
			foreach (weapon in GetPlayerWeapons(params.player, true)) { weapon.AddAttribute("turn to gold", 1, params.duration); }
		},
		"resetBehaviour": function(params)
		{ 
			foreach (weapon in GetPlayerWeapons(params.player, true)) { weapon.RemoveAttribute("turn to gold"); }
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
				[TF_CLASS_SCOUT] =			{"canteenCharges": 0, "refundableAmountSpent": 0, "nonRefundableAmountSpent": 0, "characterUpgrades": {}, "weaponsUsedSinceLastRefund": {}, "spawnedAsThisYetThisRound": false},
				[TF_CLASS_SOLDIER] = 		{"canteenCharges": 0, "refundableAmountSpent": 0, "nonRefundableAmountSpent": 0, "characterUpgrades": {}, "weaponsUsedSinceLastRefund": {}, "spawnedAsThisYetThisRound": false},
				[TF_CLASS_PYRO] = 			{"canteenCharges": 0, "refundableAmountSpent": 0, "nonRefundableAmountSpent": 0, "characterUpgrades": {}, "weaponsUsedSinceLastRefund": {}, "spawnedAsThisYetThisRound": false},
				[TF_CLASS_DEMOMAN] = 		{"canteenCharges": 0, "refundableAmountSpent": 0, "nonRefundableAmountSpent": 0, "characterUpgrades": {}, "weaponsUsedSinceLastRefund": {}, "spawnedAsThisYetThisRound": false},
				[TF_CLASS_HEAVYWEAPONS] = 	{"canteenCharges": 0, "refundableAmountSpent": 0, "nonRefundableAmountSpent": 0, "characterUpgrades": {}, "weaponsUsedSinceLastRefund": {}, "spawnedAsThisYetThisRound": false},
				[TF_CLASS_ENGINEER] = 		{"canteenCharges": 0, "refundableAmountSpent": 0, "nonRefundableAmountSpent": 0, "characterUpgrades": {}, "weaponsUsedSinceLastRefund": {}, "spawnedAsThisYetThisRound": false},
				[TF_CLASS_MEDIC] = 			{"canteenCharges": 0, "refundableAmountSpent": 0, "nonRefundableAmountSpent": 0, "characterUpgrades": {}, "weaponsUsedSinceLastRefund": {}, "spawnedAsThisYetThisRound": false},
				[TF_CLASS_SNIPER] = 		{"canteenCharges": 0, "refundableAmountSpent": 0, "nonRefundableAmountSpent": 0, "characterUpgrades": {}, "weaponsUsedSinceLastRefund": {}, "spawnedAsThisYetThisRound": false},
				[TF_CLASS_SPY] = 			{"canteenCharges": 0, "refundableAmountSpent": 0, "nonRefundableAmountSpent": 0, "characterUpgrades": {}, "weaponsUsedSinceLastRefund": {}, "spawnedAsThisYetThisRound": false},
			},
			[TF_TEAM_BLU] = {
				[TF_CLASS_SCOUT] = 			{"canteenCharges": 0, "refundableAmountSpent": 0, "nonRefundableAmountSpent": 0, "characterUpgrades": {}, "weaponsUsedSinceLastRefund": {}, "spawnedAsThisYetThisRound": false},
				[TF_CLASS_SOLDIER] = 		{"canteenCharges": 0, "refundableAmountSpent": 0, "nonRefundableAmountSpent": 0, "characterUpgrades": {}, "weaponsUsedSinceLastRefund": {}, "spawnedAsThisYetThisRound": false},
				[TF_CLASS_PYRO] = 			{"canteenCharges": 0, "refundableAmountSpent": 0, "nonRefundableAmountSpent": 0, "characterUpgrades": {}, "weaponsUsedSinceLastRefund": {}, "spawnedAsThisYetThisRound": false},
				[TF_CLASS_DEMOMAN] = 		{"canteenCharges": 0, "refundableAmountSpent": 0, "nonRefundableAmountSpent": 0, "characterUpgrades": {}, "weaponsUsedSinceLastRefund": {}, "spawnedAsThisYetThisRound": false},
				[TF_CLASS_HEAVYWEAPONS] = 	{"canteenCharges": 0, "refundableAmountSpent": 0, "nonRefundableAmountSpent": 0, "characterUpgrades": {}, "weaponsUsedSinceLastRefund": {}, "spawnedAsThisYetThisRound": false},
				[TF_CLASS_ENGINEER] = 		{"canteenCharges": 0, "refundableAmountSpent": 0, "nonRefundableAmountSpent": 0, "characterUpgrades": {}, "weaponsUsedSinceLastRefund": {}, "spawnedAsThisYetThisRound": false},
				[TF_CLASS_MEDIC] = 			{"canteenCharges": 0, "refundableAmountSpent": 0, "nonRefundableAmountSpent": 0, "characterUpgrades": {}, "weaponsUsedSinceLastRefund": {}, "spawnedAsThisYetThisRound": false},
				[TF_CLASS_SNIPER] = 		{"canteenCharges": 0, "refundableAmountSpent": 0, "nonRefundableAmountSpent": 0, "characterUpgrades": {}, "weaponsUsedSinceLastRefund": {}, "spawnedAsThisYetThisRound": false},
				[TF_CLASS_SPY] = 			{"canteenCharges": 0, "refundableAmountSpent": 0, "nonRefundableAmountSpent": 0, "characterUpgrades": {}, "weaponsUsedSinceLastRefund": {}, "spawnedAsThisYetThisRound": false},
			},
		},
		"currentClass": player.GetPlayerClass(),
		"currentTeam": player.GetTeam(),
		"isFullySpawned": false,
		"isRefunding": false,
	};
	
	return entry;
}

function GetAllDroppedWeapons()
{
	local droppedWeapons = [];
	for (local droppedWeapon; droppedWeapon = Entities.FindByClassname(droppedWeapon, "tf_dropped_weapon");)
	{
		droppedWeapons.push(droppedWeapon);
	}
	return droppedWeapons;
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
	for (local item = player.FirstMoveChild(); item != null; item = item.NextMovePeer())
	{
		if (item.GetClassname() == "tf_powerup_bottle") { return item; };
	}
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

function GetPlayerName(player){ return NetProps.GetPropString(player, "m_szNetname") }

::GetPlayerWeapons <- function(player, includeWearables = false)
{
	local weapons = [];
	for (local i = 0; i < MAX_WEAPONS; i++)
	{
		local weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
		if (weapon == null) continue
		weapons.push(weapon);
	}

	if (includeWearables)
	{
		for (local wearable = player.FirstMoveChild(); wearable != null; wearable = wearable.NextMovePeer()) { if (wearable.GetClassname() == "tf_wearable_demoshield" || wearable.GetClassname() == "tf_wearable_razorback") { weapons.push(wearable); } }
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
	playerEntry["isRefunding"] = true;
	
	classEntry["canteenCharges"] = 0; SetCanteenCharges(GetPlayerCanteen(player), classEntry["canteenCharges"]);
	classEntry["refundableAmountSpent"] = 0; player.SetCurrency(CalculateClassCurrencyLevel(player));
	classEntry["weaponsUsedSinceLastRefund"].clear();
	classEntry["characterUpgrades"].clear();
	
	foreach (weapon in GetPlayerWeapons(player, true)) { SetWeaponToDefaultAttributes(weapon); classEntry["weaponsUsedSinceLastRefund"][GetWeaponId(weapon)] <- {}; }
	SetPlayerToDefaultAttributes(player, false);
	
	playerEntry["isRefunding"] = false;
}

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
	foreach(player in GetPlayers(team)) { player.SetCurrency(CalculateClassCurrencyLevel(player)); }
}

function CalculateClassCurrencyLevel(player)
{ 
	local classEntry = GetClassEntry(player);
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

function PlayUpgradeVoiceline(player, canteenWasBought)
{
	DebugClientPrint("VOICELINE PLAYING " + Time() + " - " + GetRoundStateNameFromIndex(GetRoundState()));
	local soundName = "MoneyMap.Upgraded" + (canteenWasBought ? "Canteen." : ".") + GetClassNameFromIndex(player.GetPlayerClass());
				
	DebugPrint(soundName)
	
	EmitSoundEx({
		sound_name = soundName,
		origin = player.GetCenter(),
		entity = player,
		speaker_entity = player
	})
	
	player.GetScriptScope().timeLastPlayedUpgradeVoiceline <- Time();
}

function GetAttributesIncludedInUpgradeFileOnWeapon(weapon, compareAgainstDefaultValues)
{
	local attribValues = {}
	local weaponId = GetWeaponId(weapon);
	foreach (attribute in UPGRADEABLEWEAPONATTRIBS) //Only get the attributes that are upgradeable in the MVM trigger
	{
		local grabbedValue = weapon.GetAttribute(attribute, SPOOFVALUE);
		if (grabbedValue != SPOOFVALUE) //If there's something there.
		{
			if (compareAgainstDefaultValues) //If you're comparing against default values
			{ 
				local attributeExistsInDefaultAttribs = attribute in encounteredWeaponsTrackedDefaultAttributes[weaponId]; 
				if (!attributeExistsInDefaultAttribs || grabbedValue != encounteredWeaponsTrackedDefaultAttributes[weaponId][attribute]) { attribValues[attribute] <- grabbedValue; } //If the attribute doesn't exist in the default attribs list, or the value is different, record it
			}
			else { attribValues[attribute] <- grabbedValue; }
		}
	}
	return attribValues;
}

function SetWeaponToDefaultAttributes(weapon) { foreach (attribute in UPGRADEABLEWEAPONATTRIBS) { weapon.RemoveAttribute(attribute); } }

function SetWeaponToAttributes(weapon, attributes) //Specific attributes list
{
	foreach (attribute in UPGRADEABLEWEAPONATTRIBS) //General attributes list
	{
		if (!(attribute in attributes)) { weapon.RemoveAttribute(attribute); }
		else { weapon.AddAttribute(attribute, attributes[attribute], -1); }
	}
}

function GetAttributesIncludedInUpgradeFileOnPlayer(player)
{
	local attribValues = {}
	local classEntry = GetClassEntry(player);
	foreach (attrib, value in CHARACTERUPGRADESATTRIBS)
	{
		local returnedValue = player.GetCustomAttribute(attrib, SPOOFVALUE);
		if (returnedValue != SPOOFVALUE) { classEntry["characterUpgrades"][attrib] <- returnedValue; } //If the player has an attrib applied. Record it
		else if (attrib in classEntry["characterUpgrades"]) { delete classEntry["characterUpgrades"][attrib]; } //If the player doesn't have the attrib applied, but it's in their attribs list, remove it
	}
	return attribValues;
}

function SetPlayerToDefaultAttributes(player, tickDelay)
{
	if (tickDelay)
	{
		foreach (attrib, value in CHARACTERUPGRADESATTRIBS)
		{
			EntFireByHandle(self, "RunScriptCode", "activator.AddCustomAttribute(" + @"""" + attrib + @""", " + value + ", 0)", 0, player, null);
			EntFireByHandle(self, "RunScriptCode", "activator.RemoveCustomAttribute(" + @"""" + attrib + @""")", 0, player, null);
		}
	}
	else
	{
		foreach (attrib, value in CHARACTERUPGRADESATTRIBS)
		{
			player.AddCustomAttribute(attrib, value, 0);
			player.RemoveCustomAttribute(attrib);
		}
	}
	
}

function SetPlayerToAttributes(player, attributes, tickDelay)
{
	if (tickDelay)
	{
		foreach (attrib, value in CHARACTERUPGRADESATTRIBS) //CLEAR UPGRADES BEFORE ADDING 
		{
			EntFireByHandle(self, "RunScriptCode", "activator.AddCustomAttribute(" + @"""" + attrib + @""", " + value + ", 0)", 0, player, null);
			EntFireByHandle(self, "RunScriptCode", "activator.RemoveCustomAttribute(" + @"""" + attrib + @""")", 0, player, null);
		}

		foreach (attrib, value in attributes)
		{
			EntFireByHandle(self, "RunScriptCode", "activator.AddCustomAttribute(" + @"""" + attrib + @""", " + value + ", 0)", -1, player, null);
		}
	}
	else
	{
		foreach (attrib, value in CHARACTERUPGRADESATTRIBS) //CLEAR UPGRADES BEFORE ADDING 
		{
			player.AddCustomAttribute(attrib, value, 0);
			player.RemoveCustomAttribute(attrib);
		}

		foreach (attrib, value in attributes)
		{
			player.AddCustomAttribute(attrib, value, -1);
		}
	}
}

function GetWeaponId(weapon) { return NetProps.GetPropInt(weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex"); }

function PrintPlayerWeaponInfo(player)
{
	local classEntry = GetClassEntry(player);
	foreach (weaponId, weaponEntry in classEntry["weaponsUsedSinceLastRefund"])
	{
		DebugClientPrint("WEAPON " + weaponId);
		foreach (attrib, value in classEntry["weaponsUsedSinceLastRefund"][weaponId])
		{
			DebugClientPrint("--ATTRIB " + attrib + ": " + value);
		}
	}
}

::ForceKillPlayer <- function(player)
{
	player.AddCond(75)
	local brush = Entities.CreateByClassname("func_brush")
	brush.DispatchSpawn()
	brush.SetAbsOrigin(player.GetOrigin())
	brush.SetSolid(2)
	player.RemoveCond(75)
	brush.Kill()
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
///GAME EVENTS///
//////////////////////////////////////////////////////////////////////////////////////////////////////
local EventsID = UniqueString()
getroottable()[EventsID] <-
{
	// Cleanup events on round restart. Do not remove this event.
	OnGameEvent_scorestats_accumulated_update = function(_)
	{ 
		DebugClientPrint("ROUND RESET " + Time() + " - " + GetRoundStateNameFromIndex(GetRoundState()));
		if (printEventDetails) { DebugPrint("SCORESTATS ACCUMULATED UPDATE - " + Time() + " - " + GetRoundStateNameFromIndex(GetRoundState())); }
		banks[TF_TEAM_BLU] = STARTINGCREDITS;
		banks[TF_TEAM_RED] = STARTINGCREDITS;
		playersData.clear();
		ForceEnableUpgrades(2)
	}
	
	//Every time it validates your inventory. Note that this happens BEFORE the player spawn event, as well as Round Start.
	OnGameEvent_post_inventory_application = function(params)  //FIRE ORDER ON NEW ROUND : 1 // FIRE ORDER ON PLAYER JOIN : 2
	{
		//#region PREAMBLE
		DebugClientPrint("POST INV APP " + Time() + " - " + GetRoundStateNameFromIndex(GetRoundState()));
		local player = GetPlayerFromUserID(params.userid); 	
		local eventMessage = "POST INVENTORY APPLICATION EVENT - " + Time() + " - " + GetRoundStateNameFromIndex(GetRoundState());
		if (GetRoundState() == GR_STATE_PREGAME) { eventMessage += " - SKIPPED!"; }
		if (printEventDetails) { DebugPrint(eventMessage); }
		if (GetRoundState() == GR_STATE_PREGAME) return; //If this is being called before the game starts, return
		if (!PlayerEntryExists(player)) { CreatePlayerEntry(player); DebugClientPrint("--CREATING PLAYER ENTRY " + Time() + " - " + GetRoundStateNameFromIndex(GetRoundState()));  } //If the player doesn't have an entry, return. THIS OCCURS WHEN A PLAYER JOINS AN EXISTENT ROUND. IT'S THEN CREATED IN THE POST INV EVENT
		local canteen = GetPlayerCanteen(player);
		local playerEntry = GetPlayerEntry(player);
		local classEntry = GetClassEntry(player); 
		//#endregion

		foreach (weapon in GetPlayerWeapons(player, true))
		{ 
			local weaponId = GetWeaponId(weapon);
			if (!(weaponId in encounteredWeaponsTrackedDefaultAttributes))
			{ 
				DebugClientPrint("--ENCOUNTERED NEW WEAPON " + weaponId);
				encounteredWeaponsTrackedDefaultAttributes[weaponId] <- GetAttributesIncludedInUpgradeFileOnWeapon(weapon, false); //Put the default attributes of any weapon not yet encountered in a big database that gets conserved across rounds	
			} 

			if (!(weaponId in classEntry["weaponsUsedSinceLastRefund"])) //If the weapon hasn't been used since the last refund, add it to the list of weapons used since the last refund by the player. And reset it. 
			{
				DebugClientPrint("--SETTING WEAPON TO DEFAULT ATTRIBUTES " + weaponId);
				SetWeaponToDefaultAttributes(weapon);
				classEntry["weaponsUsedSinceLastRefund"][weaponId] <- {};
			}
		}

		local playerHasInteractedWithMvmTrigger = false;
		local playerIsExchangingMoneyInTrigger = playerEntry["isFullySpawned"] && !playerEntry["isRefunding"] && player.GetScriptScope().isInMvmUpgradeStationTrigger
		if (playerIsExchangingMoneyInTrigger) //THIS EXISTS SO THAT NOTHING HAPPENS IF THE PLAYER HAS JUST SPAWNED. AS THIS EVENT IS USED ALONGSIDE THE PLAYER SPAWNING
		{
			DebugClientPrint("--MVM TRIGGER PURCHASE " + Time() + " - " + GetRoundStateNameFromIndex(GetRoundState()));
			local delta = CalculateClassCurrencyLevel(player) - player.GetCurrency();
			local canteenWasBought = canteen != null ? classEntry["canteenCharges"] < GetCanteenCharges(canteen) : false;
			local voicelineShouldPlay = delta > 0 && Chance(UPGRADEVOICELINECHANCE) && (Time() - player.GetScriptScope().timeLastPlayedUpgradeVoiceline > VOICELINECOOLDOWN)
			classEntry["refundableAmountSpent"] += delta; //Record the amount just spent/refunded as the amount added/removed from the refundable balance

			if (voicelineShouldPlay) { PlayUpgradeVoiceline(player, canteenWasBought) }
			if (canteen != null) { classEntry["canteenCharges"] = GetCanteenCharges(canteen) } //Update the canteen charges to the new value. If the player has a canteen, it will be set to the canteen's charges. If not, it will be set to whatever their current listing is.
			playerHasInteractedWithMvmTrigger = true;
		}
		
		local playerIsLeavingMvmTriggerWithoutHavingAcceptedChanges = CalculateClassCurrencyLevel(player) - player.GetCurrency() != 0 && !player.GetScriptScope().isInMvmUpgradeStationTrigger && playerEntry["isFullySpawned"] && !playerEntry["isRefunding"];
		if (playerIsLeavingMvmTriggerWithoutHavingAcceptedChanges)
		{
			local delta = CalculateClassCurrencyLevel(player) - player.GetCurrency();
			classEntry["refundableAmountSpent"] += delta;
			DebugClientPrint("--MVM TRIGGER NONPURCHASE " + Time() + " - " + GetRoundStateNameFromIndex(GetRoundState()));
			if (canteen != null) { classEntry["canteenCharges"] = GetCanteenCharges(canteen) } //Update the canteen charges to the new value. If the player has a canteen, it will be set to the canteen's charges. If not, it will be set to whatever their current listing is.
			playerHasInteractedWithMvmTrigger = true;
		}
		
		if (playerHasInteractedWithMvmTrigger)
		{
			GetAttributesIncludedInUpgradeFileOnPlayer(player);
			foreach (weapon in GetPlayerWeapons(player, true)) { classEntry["weaponsUsedSinceLastRefund"][GetWeaponId(weapon)] = GetAttributesIncludedInUpgradeFileOnWeapon(weapon, true); }
		}
		else 
		{
			DebugClientPrint("--SETTING WEAPON + PLAYER ATTRIBUTES INSIDE OF POST INV APP " + Time() + " - " + GetRoundStateNameFromIndex(GetRoundState()));
			SetPlayerToAttributes(player, classEntry["characterUpgrades"], true);
			foreach (weapon in GetPlayerWeapons(player, true)) { SetWeaponToAttributes(weapon, classEntry["weaponsUsedSinceLastRefund"][GetWeaponId(weapon)]); }
			SetCanteenCharges(canteen, classEntry["canteenCharges"]);
		}

		DebugClientPrint("--Calc " + CalculateClassCurrencyLevel(player));
		DebugClientPrint("--Get " + player.GetCurrency());
		DebugClientPrint("--isInMvmStation " + player.GetScriptScope().isInMvmUpgradeStationTrigger);
		DebugClientPrint("--isFullySpawned " + playerEntry["isFullySpawned"]);
		DebugClientPrint("--canteenCharges " + classEntry["canteenCharges"]);
	}
	
	OnGameEvent_player_spawn = function(params) //FIRE ORDER ON NEW ROUND : 2 // FIRE ORDER ON PLAYER JOIN : 1, 3
	{
		//#region PREAMBLE
		local eventMessage = "PLAYER SPAWN EVENT - " + Time() + " - " + GetRoundStateNameFromIndex(GetRoundState());
		if (GetRoundState() == GR_STATE_PREGAME) { eventMessage += " - SKIPPED!"; }
		if (printEventDetails) { DebugPrint(eventMessage); }
		if (GetRoundState() == GR_STATE_PREGAME || params.team == 0) { CreatePlayerScriptScopeAndVariables(GetPlayerFromUserID(params.userid)); return; } //If this is being called before the game starts, OR if the player hasn't been assigned a team. return
		local player = GetPlayerFromUserID(params.userid);
		local playerEntry = GetPlayerEntry(player);
		local classEntry = GetClassEntry(player);
		local canteen = GetPlayerCanteen(player);
		//#endregion

		ResetAllEffectsOnPlayer(player);

		playerEntry["currentTeam"] = params["team"];
		playerEntry["currentClass"] = params["class"];
		playerEntry["isFullySpawned"] = true;
		
		player.SetCurrency(CalculateClassCurrencyLevel(player));
		SetCanteenCharges(canteen, classEntry["canteenCharges"]);
	}

	OnGameEvent_player_changeclass = function(params) //For when the player was a buster and they change class. Makes them able to switch to their weapon so civilianing doesn't occur after being a sentry buster
	{ 
		local player = GetPlayerFromUserID(params.userid);
		if (!(PlayerEntryExists(player))) { return; } //Before players initally spawn, they 'change class'. Nullify this situation
		local playerEntry = GetPlayerEntry(player);
		playerEntry["isFullySpawned"] = false;
		player.RemoveCustomAttribute("disable weapon switch") //For being a sentry buster. If you switch class while a sentry buster the attrib has to be unapplied.
	} 
	
	OnGameEvent_teamplay_round_start = function(params) //FIRE ORDER ON NEW ROUND : 3
	{
		if (printEventDetails) { DebugPrint("ROUND START EVENT - " + Time() + " - " + GetRoundStateNameFromIndex(GetRoundState())); }
		local statsEntity = Entities.FindByClassname(null, "tf_mann_vs_machine_stats");
		if (statsEntity != null) statsEntity.Destroy();

		Convars.SetValue("tf_mvm_respec_enabled", 1);
		Convars.SetValue("tf_mvm_respec_limit", 0);
		Convars.SetValue("tf_mvm_respec_credit_goal", 1);
		Convars.SetValue("tf_dropped_weapon_lifetime", 0);
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
		//#region PREAMBLE
		if (printEventDetails) { DebugPrint("PLAYER USED POWERUP BOTTLE EVENT"); }
		local player = PlayerInstanceFromIndex(params.player);
		local classEntry = GetClassEntry(player);
		local canteen = GetPlayerCanteen(player);
		local canteenType = canteenTable[GetCanteenHandshakeAttribute(canteen)]["potionType"];	
		local effect = GetPotionEffect(player, canteenType);
		local playerCantUsePotion = player.InCond(TF_COND_STEALTHED) || player.InCond(TF_COND_STEALTHED_BLINK) || player.InCond(TF_COND_SHIELD_CHARGE) || player.GetScriptScope().isInAnEffect || NetProps.GetPropBool(player, "m_Shared.m_bFeignDeathReady") || effect == "none" || player.GetScriptScope().bustingSequenceActive;
		//If the player is cloaked, or is in an effect, or is feigning death, or the effect is none, or the player is a sentry buster. They cannot use a potiion
		
		//#endregion

		if (playerCantUsePotion) { GiveNegativeCanteenUseFeedback(player, GetPlayerCanteen(player)); return;}
		if (player.InCond(TF_COND_DISGUISED) || player.InCond(TF_COND_DISGUISING) || player.InCond(TF_COND_DISGUISE_WEARINGOFF)) { player.RemoveDisguise() }
		ApplyEffectOnPlayer(player, effect);
		local PLAYERPRINTCOLOUR = player.GetTeam() == TF_TEAM_RED ? REDPRINTCOLOUR : BLUPRINTCOLOUR;
		local printedMessage = (PLAYERPRINTCOLOUR + GetPlayerName(player) + DEFAULTPRINTCOLOUR + " " + canteenTable[GetCanteenHandshakeAttribute(canteen)]["message"] + " " + effectsTable[effect]["message"]); 
		ClientPrint(null, HUD_PRINTTALK, printedMessage);
		local potionEntry = canteenTable[GetCanteenHandshakeAttribute(canteen)];
		classEntry["nonRefundableAmountSpent"] += potionEntry["cost"];
		classEntry["refundableAmountSpent"] -= potionEntry["cost"];
		classEntry["canteenCharges"]--;
	}

	OnGameEvent_player_death = function(params)
	{
		//#region PREAMBLE
		if (printEventDetails) { DebugPrint("PLAYER DEATH EVENT"); }
		if ((params.attacker == null && !params.attacker.IsPlayer()) || params.death_flags & 32 || params.weapon == "worldspawn") { DebugPrint("returning inside death event"); return; }
		local player = GetPlayerFromUserID(params.userid);
		local playerEntry = GetPlayerEntry(player);
		local killerTeam = GetPlayerFromUserID(params.attacker).GetTeam(); 
		//#endregion

		SetPlayerIsASentryBuster(player, false);
		playerEntry["isFullySpawned"] = false;

		if (killerTeam > 1 && killerTeam != player.GetTeam()) //check that the killer isnt spectate, and that the killer isn't from their own team
		{
			AwardCreditsToTeam(killerTeam, CreditMath()); //award credits to killer's team members
			DispatchParticleEffect("env_grinder_oilspray_cash", player.GetLocalOrigin(), Vector(0,90,0) );
			player.EmitSound("MVM.MoneyPickup");
		}
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
	if (player.GetScriptScope().busterWearable != null) { player.GetScriptScope().busterWearable.Kill();}
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
	ForceKillPlayer(player);
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
	foreach(playerEntry in playersData) { PrintPlayerEntry(playerEntry, sourceMessage); }
	ClientPrint(null, HUD_PRINTCONSOLE, "");
	ClientPrint(null, HUD_PRINTCONSOLE, "--------------------------------------------------");
}

function PrintPlayerEntry(playerEntry, sourceMessage = "")
{
	ClientPrint(null, HUD_PRINTCONSOLE, "Player team: " + GetTeamNameFromIndex(playerEntry["currentTeam"]));
	ClientPrint(null, HUD_PRINTCONSOLE, "Current Player Class: " + GetClassNameFromIndex(playerEntry["currentClass"]));
	PrintPlayerTeamEntry(playerEntry["teamData"][TF_TEAM_RED], "TF_TEAM_RED - " + banks[TF_TEAM_RED], playerEntry["currentClass"], playerEntry["currentTeam"] == TF_TEAM_RED);
	PrintPlayerTeamEntry(playerEntry["teamData"][TF_TEAM_BLU], "TF_TEAM_BLU - " + banks[TF_TEAM_BLU], playerEntry["currentClass"], playerEntry["currentTeam"] == TF_TEAM_BLU);
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
		
		if (isPlayersCurrentTeam && currentClass == classNum)
		{ 
			currencyMessage += "<---------------";
		}
		ClientPrint(null, HUD_PRINTCONSOLE, currencyMessage)
		ClientPrint(null, HUD_PRINTCONSOLE, "")
	}
}

PrecacheStep();
ForceEnableUpgrades(2);