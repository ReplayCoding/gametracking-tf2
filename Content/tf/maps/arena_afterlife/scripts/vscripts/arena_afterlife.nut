//=================================================================
//Arena-Afterlife VScript
//Based on Arena VScript by Lizard Of Oz
//Modified by Piogre to add Afterlife mechanic
//=================================================================

if (!("ARENA_HUD_PATH" in getroottable()))
{
    ::ARENA_HUD_PATH <- "resource/ui/hudarenavscript.res";

    ::ARENA_AFTERLIFE_SPAWN_MESSAGE <- "#arena_afterlife_spawn";
    ::ARENA_AFTERLIFE_PICKUP_MESSAGE <- "#arena_afterlife_pickup";
    ::ARENA_AFTERLIFE_SOULLESS_MESSAGE <- "#arena_afterlife_soulless";
    ::ARENA_AFTERLIFE_LASTMAN_MESSAGE <- "#arena_afterlife_lastman";
    ::ARENA_AFTERLIFE_PITYSOUL_SPAWN_MESSAGE <- "#arena_afterlife_pitysoul_spawn";
    ::ARENA_FIRST_BLOOD_SMALLDISABLEMESSAGE <- "#arena_afterlife_nofb_small_teams";
    ::ARENA_FIRST_BLOOD_CONVARDISABLEMESSAGE <- "#arena_afterlife_nofb_disabled";
    ::ARENA_AFTERLIFE_PITYSOUL_PICKUP_MESSAGE <- " \x07FBECCBhas found the \x07A3FBA5ROGUE SOUL!"; //CAN'T TRANSLATE (current vscript limitation prevents localization of formatted strings)
    ::ARENA_AFTERLIFE_LASTMAN_ALL <- " \x07FBECCBis the \x07E7B53BLAST PLAYER STANDING!"; //CAN'T TRANSLATE (current vscript limitation prevents localization of formatted strings)
    //::ARENA_AFTERLIFE_RESURRECT_MESSAGE <- " \x07FBECCBhas been \x07E7B53BRESURRECTED!"; //CAN'T TRANSLATE //also this line is unused in the final version

    ::ARENA_AFTERLIFE_GLOW_RED <- "189 59 59 255";
    ::ARENA_AFTERLIFE_GLOW_BLU <- "125 168 196 255";
    ::ARENA_AFTERLIFE_SOUL_OVERLAY <- "effects/map_afterlife_soul_overlay";
    ::ARENA_AFTERLIFE_PARTICLE <- "map_afterlife_eyes";
    ::ARENA_AFTERLIFE_PITYSOUL_MODEL <- "models/items_afterlife/pitysoul_pickup.mdl";

    ::ARENA_AFTERLIFE_RESPAWNTIME <- 5; //respawnwavetime, can be overridden by trigger_player_respawn_override named afterlife_fastrespawner
    ::ARENA_AFTERLIFE_PITYSOUL_START_THRESHOLD <- 3; //Number of deaths with zero kills to get pitysouls; zero prevents them spawning
    ::ARENA_AFTERLIFE_PITYSOUL_INCREMENT <- 1; //Increment in threshold for pitysouls; zero means one will always spawn if above the start threshold

    ::ARENA_AFTERLIFE_LASTMAN_BUFFS <- [
        Constants.ETFCond.TF_COND_OFFENSEBUFF,
        Constants.ETFCond.TF_COND_REGENONDAMAGEBUFF
    ];//buffs granted to last player standing -- making this empty (setting it to []) will ALSO disable the lastman outline/text/audio -- add TF_COND_TMPDAMAGEBONUS if you want the outline with no buffs (that cond does nothing)

    ::ARENA_AFTERLIFE_HELLSPAWN_BUFFS <- [
        [Constants.ETFCond.TF_COND_INVULNERABLE_CARD_EFFECT,2,4]
    ];//buffs granted when someone respawns in hell -- first number is default, second number if they are outnumbered at least 2 to 1

    ::ARENA_AFTERLIFE_RESURRECT_BUFFS <- [
        [Constants.ETFCond.TF_COND_INVULNERABLE_CARD_EFFECT,3,5],
        [Constants.ETFCond.TF_COND_TEAM_GLOWS,3,3]
    ];//buffs granted when someone resurrects -- first number is default, second number if they are outnumbered at least 2 to 1 -- this in addition to  full resupply and 50% overheal (125% max health)

    ::ARENA_SETUP_LENGTH <- 15;
    ::ARENA_SCORE_LIMIT <- 2;
    ::ARENA_UNLOCK_TIME <- 60;

    ::ARENA_HUMILIATION_LENGTH <- 10;
    ::ARENA_FIRST_BLOOD_MINTEAMSIZE <- 7; //either team being less than this size means first blood is disabled
    ::ARENA_FIRST_BLOOD_BUFFS <- [
        [Constants.ETFCond.TF_COND_CRITBOOSTED_FIRST_BLOOD,5]
    ]; //empty this table entirely (set it to []) to SILENTLY disable first blood across the board
}

local overrideTime = Convars.GetInt("tf_arena_override_cap_enable_time");
if (overrideTime != -1)
    ARENA_UNLOCK_TIME = overrideTime;
if (ARENA_SETUP_LENGTH < 5)
    ARENA_SETUP_LENGTH = 5;

//===================================================================
//Don't edit past this point
//===================================================================

local CRUMPKIN_INDEX = PrecacheModel("models/props_halloween/pumpkin_loot.mdl");

/* Stock Arena has an extra HUD panel that displays the amount of players alive on each team.
   The only HUD that a map can edit is Player Destruction's bar at the bottom.
   So, Arena-VScript is secretly PD with a bespoke .res file that mimics stock Arena.
   The amount of points deposited is repurposed to display the mini - round won,
   and Escrow is repurposed to display the amount of players alive. */
pd_logic <- SpawnEntityFromTable("tf_logic_player_destruction", {
    min_points = ARENA_SCORE_LIMIT,
    finale_length = 0,
    res_file = ARENA_HUD_PATH
});
pd_logic.AcceptInput("SetPointsOnPlayerDeath", "0", null, null);
pd_logic.AcceptInput("EnableMaxScoreUpdating", "0", null, null);
pd_logic.AcceptInput("DisableMaxScoreUpdating", "0", null, null);

//establish a wrapper here for the lava response so we can bind it to the triggers; we'll write the actual function later
::LavaTriggered <- function()
{
    LavaEntered();
    return true;
}.bindenv(this);

//establish a wrapper here for a player entering entering the portal, to attempt resurrection
::PortalEntered <- function()
{
    CheckResurrect();
    return true;
}.bindenv(this);

//establish a wrapper here for a player entering entering the overworld, to check for eureka effect
::OverworldEntered <- function()
{
    OverworldCustoms();
    return true;
}.bindenv(this);

//establish a wrapper here for a player entering entering the underworld, to check for eureka effect
::UnderworldEntered <- function()
{
    UnderworldCustoms();
    return true;
}.bindenv(this);

::KillIfValid <- function(entity)
{
    if (entity && entity.IsValid())
        entity.Kill();
    return null;
}

::IsValidPlayer <- function(player)
{
    try
    {
        return player && player.IsValid() && player.IsPlayer() && player.GetTeam() > 1 && GetPropIntArray(tf_player_manager, "m_iConnectionState", player.entindex()) == 1;
    }
    catch(e)
    {
        return false;
    }
}

tf_gamerules <- Entities.FindByClassname(null, "tf_gamerules");
tf_player_manager <- Entities.FindByClassname(null, "tf_player_manager");

PrecacheScriptSound("Announcer.HellIntro");
PrecacheScriptSound("Announcer.SoulPickup");
PrecacheScriptSound("Announcer.AltarNoSoul");
PrecacheScriptSound("Announcer.LastManStanding");
PrecacheScriptSound("Announcer.LooseSoul");
PrecacheScriptSound("Halloween.PumpkinPickup");

/* During Waiting for Players stage, don't enable the Arena rules yet and open the doors.
   Special note about GR_STATE_PREGAME:
   For this script I wanted give mappers a way to change the ::ARENA_ constants with Entity I/O.
   Apparently, the game is guaranteed to run a GR_STATE_PREGAME round before the first "real" round starts.
   During pregame, some logic entities do fire their outputs.
   The one important for us if logic_relay's OnMapSpawn output.
   Mappers can use this output to change the rules of the gamemode for a particular map,
   And because we store them in the root table, they stay in memory not just between mini-rounds,
   but between real rounds as well. */
if (IsInWaitingForPlayers() || NetProps.GetPropEntity(tf_gamerules, "m_iRoundState") == Constants.ERoundState.GR_STATE_PREGAME)
{
    control_points <- [];
    Convars.SetValue("mp_respawnwavetime", 1);
    DoEntFire("arena_setup_finish*", "Trigger", "", 0, null, null);
    DoEntFire("arena_door*", "Open", "", 0, null, null);
    DoEntFire("arena_triggerdoor*", "Enable", "", 0, null, null);
    EntFireByHandle(self, "FireUser2", "", 0, null, null);
    return;
}

/* This script is absent by design to allow Community Servers to plug in their own code.
   IMPORTANT: This is NOT for CUSTOM MAPS to include additional scripts.
   If that's the mapper's goal, simply add the second script to the logic_script's "Entity Script" field.
   This is intended to be left vacant for Community Servers to fill. */
try { IncludeScript("arena_addons/preload.nut"); } catch(e) { }

Convars.SetValue("mp_disable_respawn_times", 0);
Convars.SetValue("mp_respawnwavetime", ARENA_AFTERLIFE_RESPAWNTIME);

::arenaListener <- {};

if (!("MAX_CLIENTS" in getroottable()))
{
    ::MAX_CLIENTS <- MaxClients().tointeger();
    local roottable = getroottable();

    foreach (k, v in ::NetProps.getclass())
        if (k != "IsValid")
            roottable[k] <- ::NetProps[k].bindenv(::NetProps);

    foreach (_, cGroup in Constants)
        foreach (k, v in cGroup)
            roottable[k] <- v != null ? v : 0;

    ::FindByName <- function(previous, name)
    {
        local entity = Entities.FindByName(previous, name);
        SetPropBool(entity, "m_bForcePurgeFixedupStrings", true);
        return entity;
    }

    ::FindByClassname <- function(previous, classname)
    {
        local entity = Entities.FindByClassname(previous, classname);
        SetPropBool(entity, "m_bForcePurgeFixedupStrings", true);
        return entity;
    }

    ::SpawnEntityFromTableOriginal <- ::SpawnEntityFromTable;
    ::SpawnEntityFromTable <- function(name, keyvalues)
    {
        local entity = SpawnEntityFromTableOriginal(name, keyvalues);
        SetPropBool(entity, "m_bForcePurgeFixedupStrings", true);
        return entity;
    }
}

//=================================================================
//Player Caching and Events
//=================================================================

/* Here's the table of cases for which we want to iterate over players
|---------------------------------------------------------------------------------------|
|                 | All players | Alive players only | All clients including spectators |
|---------------------------------------------------------------------------------------|
|  Both teams     |             |                    |                                  |
|---------------------------------------------------------------------------------------|
| A specific team |             |                    |                                  |
|---------------------------------------------------------------------------------------|
Fortunately for us, in this script we don't need to deal with Spectators - the third column will not be accounted for.
To make code streamlined, we use the team index (2 and 3) as an index in an array.
Since index 0 is otherwise unused, we use it to store all players regardless of the team. */
player_cache <- [ [], [], [], [], [], [] ];
alive_player_cache <- [ [], [], [], [], [], [] ];
hell_intro_cache <- [];
soulless_caged_cache <- [];

for (local i = 1; i <= MAX_CLIENTS; i++)
{
    local player = PlayerInstanceFromIndex(i);
    if (IsValidPlayer(player))
    {
        local team = player.GetTeam();

        player_cache[0].push(player);
        player_cache[team].push(player);
        if (player.GetPlayerClass() > 0)
        {
            alive_player_cache[0].push(player);
            alive_player_cache[team].push(player);
        }
    }
}

function GetPlayers(team = 0)
{
    return player_cache[team];
}

function GetAlivePlayers(team = 0)
{
    return alive_player_cache[team];
}

function IsPlayerAliveInArena(player)
{
    if (!player) return;
    return GetAlivePlayers(0).find(player) != null;
}

function AddPlayer(player, team = 0)
{
    if (!player) return;
    if (player_cache[team].find(player) == null)
        player_cache[team].push(player);
}

function AddAlivePlayer(player, team = 0)
{
    if (!player) return;
    if (alive_player_cache[team].find(player) == null)
        alive_player_cache[team].push(player);
}

function RemovePlayer(player, team = 0)
{
    local index;
    if (!player) return;
    if ((index = player_cache[team].find(player)) != null)
        player_cache[team].remove(index);
}

function RemoveAlivePlayer(player, team = 0)
{
    local index;
    if (!player) return;
    if ((index = alive_player_cache[team].find(player)) != null)
        alive_player_cache[team].remove(index);
}

function RebuildPlayerCache()
{
    try
    {
        player_cache <- [ [], [], [], [], [], [] ];
        alive_player_cache <- [ [], [], [], [], [], [] ];

        for (local i = 1; i <= MAX_CLIENTS; i++)
        {
            local player = PlayerInstanceFromIndex(i);
            if (IsValidPlayer(player))
            {
                local team = player.GetTeam();
                player_cache[0].push(player);
                player_cache[team].push(player);
                if (player.GetPlayerClass() > 0)
                {
                    alive_player_cache[0].push(player);
                    alive_player_cache[team].push(player);
                }
            }
        }
    }
    catch (e) { }
}

arenaListener.OnGameEvent_player_team <- function(params)
{
    local player = GetPlayerFromUserID(params.userid);
    if (!IsValidPlayer(player)) return;
    StripSoul(player);

    if (params.oldteam != null)
    {
        RemovePlayer(player, params.oldteam);
        RemoveAlivePlayer(player, params.oldteam);
    }
    if (params.team >= 2)
    {
        AddPlayer(player, 0);
        AddPlayer(player, params.team);
        if (isMiniRoundSetup && player.GetPlayerClass() > 0)
        {
            AddAlivePlayer(player, 0);
            AddAlivePlayer(player, params.team);
        }
    }
    if(!wasWaitingForPlayers && self && self.IsValid())
        EntFireByHandle(self, "RunScriptCode", "UpdatePlayerCounters()", 0.1, null, null);
}.bindenv(this);

arenaListener.OnGameEvent_player_spawn <- function(params)
{
    local player = GetPlayerFromUserID(params.userid);
    if (!player || !player.IsAlive()) return;
    StripSoul(player);

    AddPlayer(player, 0);
    AddPlayer(player, params.team);

    if (isMiniRoundSetup)
    {
        foreach(team in [0, player.GetTeam()])
            AddAlivePlayer(player, team);
    }
    else if ((player != null) && (!isMiniRoundOver) && (!wasWaitingForPlayers) && (!IsPlayerAliveInArena(player)) && (GetPlayers(0).len() > 1))
    {
        if (hell_intro_cache.find(player) == null)
        {
            hell_intro_cache.push(player);
            EmitSoundOnClient("Announcer.HellIntro", player);
            ClientPrint(player, HUD_PRINTCENTER, ARENA_AFTERLIFE_SPAWN_MESSAGE);
        }
        if(((GetPlayers(5-player.GetTeam()).len()) - (GetAlivePlayers(5-player.GetTeam()).len())) >= (2*((GetPlayers(player.GetTeam()).len()) - (GetAlivePlayers(player.GetTeam()).len()))))
        {
            foreach (cond in ARENA_AFTERLIFE_HELLSPAWN_BUFFS)
                player.AddCondEx(cond[0], cond[2], this);
        }
        else
        {
            foreach (cond in ARENA_AFTERLIFE_HELLSPAWN_BUFFS)
                player.AddCondEx(cond[0], cond[1], this);
        }
    }
    lava_tracker[player] <- player;
    if(!wasWaitingForPlayers && self && self.IsValid())
        EntFireByHandle(self, "RunScriptCode", "UpdatePlayerCounters()", 0, null, null);
}.bindenv(this);

//track last-damaged so players can get kill credit for lava kills
arenaListener.OnGameEvent_player_hurt <- function(params)
{
    local player = GetPlayerFromUserID(params.userid);
    if (!player || IsPlayerAliveInArena(player)) return;
    local attacker = GetPlayerFromUserID(params.attacker);
    if (!attacker) return;
    lava_tracker[player] <- attacker;
}.bindenv(this);

//if a pyro pushes someone in the lava we want that to count too
arenaListener.OnGameEvent_object_deflected <- function(params)
{
    local deflectee = GetPlayerFromUserID(params.weaponid);
    if (deflectee) return; //not a player being pushed

    local victim = GetPlayerFromUserID(params.ownerid);
    if (!victim || IsPlayerAliveInArena(victim)) return;

    local deflector = GetPlayerFromUserID(params.userid);
    if (!deflector) return;
    lava_tracker[victim] <- deflector;
}.bindenv(this);

arenaListener.OnGameEvent_player_death <- function(params)
{
    local player = GetPlayerFromUserID(params.userid);
    local killer = GetPlayerFromUserID(params.attacker);
    local assister = GetPlayerFromUserID(params.assister);
    if (!player)
    {
        RebuildPlayerCache();
        EntFireByHandle(self, "RunScriptCode", "UpdatePlayerCounters()", 0, null, null);
        EntFireByHandle(self, "RunScriptCode", "CheckAlivePlayers()", 0, null, null);
        return;
    }
    if (params.death_flags & 32) return; //Dead Ringer's fake death

    StripSoul(player);
    foreach(team in [0, player.GetTeam()])
        RemoveAlivePlayer(player, team);

    //prevent some preround bugs
    if((wasWaitingForPlayers) || !self || !self.IsValid())
        return;

    if (!isMiniRoundSetup)
    {
        TryProvideFirstBlood(params);
        EntFireByHandle(self, "RunScriptCode", "UpdatePlayerCounters()", 0, null, null);
        EntFireByHandle(self, "RunScriptCode", "CheckAlivePlayers()", 0, null, null);

        if ((killer != null) && (killer.IsAlive()) && !IsPlayerAliveInArena(killer) && (killer!=player) && !soul_cache.rawin(killer) && !isMiniRoundOver)
            GiveSoul(killer);
        if ((assister != null) && (assister.IsAlive()) && !IsPlayerAliveInArena(assister) && (assister!=player) && !soul_cache.rawin(assister) && !isMiniRoundOver)
            GiveSoul(assister);
    }
    else if (!(player in antiRespawnSpam))
    {
        antiRespawnSpam[player] <- true;
        EntFireByHandle(self, "RunScriptCode", "if (isMiniRoundSetup) activator.ForceRespawn()", 1, player, player);
    }

    local crumpkins = [];
    for (local tf_ammo_pack = null; tf_ammo_pack = FindByClassname(tf_ammo_pack, "tf_ammo_pack");)
        if (GetPropInt(tf_ammo_pack, "m_nModelIndex") == CRUMPKIN_INDEX)
            crumpkins.push(tf_ammo_pack);
    foreach(crumpkin in crumpkins)
        crumpkin.Kill();

}.bindenv(this);

arenaListener.OnGameEvent_player_disconnect <- function(params)
{
    local player = GetPlayerFromUserID(params.userid);
    if (!player)
    {
        RebuildPlayerCache();
        EntFireByHandle(self, "RunScriptCode", "UpdatePlayerCounters()", 0, null, null);
        EntFireByHandle(self, "RunScriptCode", "CheckAlivePlayers()", 0, null, null);
        return;
    }
    StripSoul(player);

    foreach(team in [0, player.GetTeam()])
    {
        RemovePlayer(player, team);
        RemoveAlivePlayer(player, team);
    }
    if(!wasWaitingForPlayers && self && self.IsValid())
    {
        EntFireByHandle(self, "RunScriptCode", "UpdatePlayerCounters()", 0, null, null);
        EntFireByHandle(self, "RunScriptCode", "CheckAlivePlayers()", 0, null, null);
    }
}.bindenv(this);

arenaListener.OnGameEvent_player_changeclass <- function(params)
{
    local player = GetPlayerFromUserID(params.userid);
    if (player)
        PreventSuicideOnClassChange(player);
}.bindenv(this);

//=================================================================
//Mini-Round Logic
//=================================================================

game_forcerespawn <- SpawnEntityFromTable("game_forcerespawn", {});
EntFireByHandle(tf_gamerules, "SetRedTeamRespawnWaveTime", (ARENA_AFTERLIFE_RESPAWNTIME).tostring(), 0, null, null);
EntFireByHandle(tf_gamerules, "SetBlueTeamRespawnWaveTime", (ARENA_AFTERLIFE_RESPAWNTIME).tostring(), 0, null, null);

isMiniRoundSetup <- true;
isMiniRoundOver <- false;
wasWaitingForPlayers <- false;

/* This handles resetting the state of the game between mini-rounds
   such as respawning players, closing spawn doors, etc. */
function ResetNewMiniRound()
{
    if (GetPropInt(tf_gamerules, "m_iRoundState") == GR_STATE_TEAM_WIN)
        return;

    EntFireByHandle(self, "RunScriptCode", "BeginMiniRound()", ARENA_SETUP_LENGTH, null, null);

    isMiniRoundOver = false;
    isMiniRoundSetup = true;
    wasWaitingForPlayers = false;
    overtimeTrigerred = false;
    firstBloodUsed = false;
    antiRespawnSpam = {};
    playerSpawnTauntPos = {};
    hell_intro_cache = [];
    soulless_caged_cache = [];
    rescount = 0;
    EntFireByHandle(tf_gamerules, "SetRedTeamRespawnWaveTime", "1", 0, null, null);
    EntFireByHandle(tf_gamerules, "SetBlueTeamRespawnWaveTime", "1", 0, null, null);

    foreach (overworld_spawn in overworld_spawns)
        EntFireByHandle(overworld_spawn, "Enable", "", 0, null, null);
    foreach (underworld_spawn in underworld_spawns)
        EntFireByHandle(underworld_spawn, "Disable", "", 0, null, null);

    EntFireByHandle(game_forcerespawn, "ForceRespawn", "", 0, null, null);
    DoEntFire("tf_dropped_weapon", "Kill", "", 0, null, null);
    DoEntFire("trigger_capture_area", "Enable", "", 0, null, null);

    foreach (control_point in control_points)
    {
        /* Before we set the points' owner to Team #0 Unassigned, we first need to set it to Team #1 Spectator
           to reset any unfinished capture progress in case a neutral point was mid-capture when the new mini-round began. */
        control_point.AcceptInput("SetOwner", "1", control_point, control_point);
        control_point.AcceptInput("SetOwner", "0", control_point, control_point);
        control_point.AcceptInput("SetLocked", "1", null, null);
        EntFireByHandle(control_point, "SetUnlockTime", "99999", 0, null, null);
    }
    foreach(trigger, location in spawn_triggers)
        trigger.SetAbsOrigin(location);

    try
    {
        pitysoulthresholds <- [ARENA_AFTERLIFE_PITYSOUL_START_THRESHOLD, ARENA_AFTERLIFE_PITYSOUL_START_THRESHOLD];
        PurgeSouls();
        PurgePitysoul();
    }
    catch (e) { }

    DoEntFire("arena_setup_start*", "Trigger", "", 0, null, null);
    DoEntFire("arena_door*", "Close", "", 0, null, null);
    DoEntFire("arena_triggerdoor*", "DisableAndEndTouch", "", 0, null, null);
    EntFireByHandle(self, "FireUser1", "", 0, null, null);

    DisplayCountdown();
    EntFireByHandle(self, "RunScriptCode", "ResetEscrowFlags()", 0, null, null);
}

function DisplayCountdown()
{
    local team_round_timer = SpawnEntityFromTable("team_round_timer", {
        auto_countdown = 0,
        max_length = 0,
        timer_length = ARENA_SETUP_LENGTH,
        reset_time = 1,
        setup_length = 0,
        show_in_hud = 1,
        show_time_remaining = 1,
        start_paused = 0,
        StartDisabled = 0
    });
    EntFireByHandle(team_round_timer, "Resume", "", 0, null, null);
    EntFireByHandle(team_round_timer, "Kill", "", ARENA_SETUP_LENGTH, null, null);

    EntFireByHandle(tf_gamerules, "PlayVO", "Announcer.RoundBegins10Seconds", ARENA_SETUP_LENGTH - 11, null, null);
    EntFireByHandle(tf_gamerules, "PlayVO", "Announcer.RoundBegins5Seconds", ARENA_SETUP_LENGTH - 6, null, null);
    EntFireByHandle(tf_gamerules, "PlayVO", "Announcer.RoundBegins4Seconds", ARENA_SETUP_LENGTH - 5, null, null);
    EntFireByHandle(tf_gamerules, "PlayVO", "Announcer.RoundBegins3Seconds", ARENA_SETUP_LENGTH - 4, null, null);
    EntFireByHandle(tf_gamerules, "PlayVO", "Announcer.RoundBegins2Seconds", ARENA_SETUP_LENGTH - 3, null, null);
    EntFireByHandle(tf_gamerules, "PlayVO", "Announcer.RoundBegins1Seconds", ARENA_SETUP_LENGTH - 2, null, null);
    EntFireByHandle(tf_gamerules, "PlayVO", "Announcer.AM_RoundStartRandom", ARENA_SETUP_LENGTH, null, null);
    EntFireByHandle(tf_gamerules, "PlayVO", "Ambient.Siren", ARENA_SETUP_LENGTH, null, null);
}

/* This is where the Setup ends and the fight starts.
   Here we open the setup doors, disable respawn triggers, etc. */
function BeginMiniRound()
{
    EntFireByHandle(tf_gamerules, "SetRedTeamRespawnWaveTime", (ARENA_AFTERLIFE_RESPAWNTIME).tostring(), 0, null, null);
    EntFireByHandle(tf_gamerules, "SetBlueTeamRespawnWaveTime", (ARENA_AFTERLIFE_RESPAWNTIME).tostring(), 0, null, null);
    DoEntFire("afterlife_fastrespawner*", "Enable", "", 0, null, null);
    game_forcerespawn.AcceptInput("ForceTeamRespawn", "2", null, null);
    game_forcerespawn.AcceptInput("ForceTeamRespawn", "3", null, null);

    try
    {
        PurgeSouls();
        PurgePitysoul();
    }
    catch (e) { }

    RebuildPlayerCache();

    //disable first blood if no first blood buffs, or if disabled by convar, or if teams are too small
    if(ARENA_FIRST_BLOOD_BUFFS.len() <= 0)
    {
        firstBloodUsed = true;
    }
    else if(!Convars.GetBool("tf_arena_first_blood"))
    {
        firstBloodUsed = true;
        ClientPrint(null, HUD_PRINTTALK, ARENA_FIRST_BLOOD_CONVARDISABLEMESSAGE);
    }
    else if (GetPlayers(TF_TEAM_RED).len() < ARENA_FIRST_BLOOD_MINTEAMSIZE || GetPlayers(TF_TEAM_BLUE).len() < ARENA_FIRST_BLOOD_MINTEAMSIZE)
    {
        firstBloodUsed = true;
        ClientPrint(null, HUD_PRINTTALK, ARENA_FIRST_BLOOD_SMALLDISABLEMESSAGE);
    }

    roundStartTS = Time();
    isMiniRoundSetup = false;

    /* Because Enable/Disable inputs of `func_respawnroom` are non-functioning,
       we simply teleport the triggers out of playable space, and teleport them back next mini-round. */
    foreach(trigger, location in spawn_triggers)
        trigger.SetAbsOrigin(location + Vector(0, 0, 9000));
    foreach (overworld_spawn in overworld_spawns)
        EntFireByHandle(overworld_spawn, "Disable", "", 0, null, null);
    foreach (underworld_spawn in underworld_spawns)
        EntFireByHandle(underworld_spawn, "Enable", "", 0, null, null);
    foreach (control_point in control_points)
        EntFireByHandle(control_point, "SetUnlockTime", ARENA_UNLOCK_TIME.tostring(), 0, null, null);

    DoEntFire("arena_setup_finish*", "Trigger", "", 0, null, null);
    DoEntFire("arena_door*", "Open", "", 0, null, null);
    DoEntFire("arena_triggerdoor*", "Enable", "", 0, null, null);
    EntFireByHandle(self, "RunScriptCode", "ResetEscrowFlags()", 0, null, null);
    EntFireByHandle(self, "FireUser2", "", 0, null, null);
}

function EndMiniRound(winnerTeam, wipeout = true)
{
    EntFireByHandle(self, "RunScriptCode", "ResetNewMiniRound()", ARENA_HUMILIATION_LENGTH, null, null);

    EntFireByHandle(self, "FireUser3", "", 0, null, null);
    DoEntFire("arena_win_any*", "Trigger", "", 0, null, null);
    if (winnerTeam == TF_TEAM_RED)
    {
        EntFireByHandle(pd_logic, "scoreredpoints", "", 1, null, null);
        DoEntFire("arena_win_red*", "Trigger", "", 0, null, null);
    }
    else if (winnerTeam == TF_TEAM_BLUE)
    {
        EntFireByHandle(pd_logic, "scorebluepoints", "", 1, null, null);
        DoEntFire("arena_win_blu*", "Trigger", "", 0, null, null);
    }
    else
        DoEntFire("arena_stalemate*", "Trigger", "", 0, null, null);

    DisplayVictoryMessage(winnerTeam, wipeout);

    isMiniRoundOver = true;
    overtimeTrigerred = false;

    game_forcerespawn.AcceptInput("ForceTeamRespawn", "2", null, null);
    game_forcerespawn.AcceptInput("ForceTeamRespawn", "3", null, null);

    EntFireByHandle(tf_gamerules, "SetRedTeamRespawnWaveTime", (ARENA_HUMILIATION_LENGTH+1).tostring(), 0, null, null);
    EntFireByHandle(tf_gamerules, "SetBlueTeamRespawnWaveTime", (ARENA_HUMILIATION_LENGTH+1).tostring(), 0, null, null);
    DoEntFire("afterlife_fastrespawner*", "Disable", "", 0, null, null);

    foreach(player in GetPlayers(winnerTeam))
        if (IsValidPlayer(player))
            player.AddCond(TF_COND_CRITBOOSTED_BONUS_TIME);

    local loserTeam = winnerTeam == TF_TEAM_RED ? TF_TEAM_BLUE : winnerTeam == TF_TEAM_BLUE ? TF_TEAM_RED: 0;
    foreach(player in GetPlayers(loserTeam))
        if (IsValidPlayer(player))
        {
            player.StunPlayer(ARENA_HUMILIATION_LENGTH + 1, 1, 96, null);
            player.StopSound("Halloween.PlayerScream");
        }

    for (local ent = null; ent = Entities.FindByClassname(ent, "obj_sentrygun");)
    {
        if (ent.GetTeam() != winnerTeam)
            EntFireByHandle(ent, "Disable", "", 0, null, null);
    }

    DoEntFire("trigger_capture_area", "DisableAndEndTouch", "", 0, null, null);
    if (ARENA_UNLOCK_TIME > 0)
        foreach (control_point in control_points)
            EntFireByHandle(control_point, "SetUnlockTime", "99999", 0, null, null);

    PurgeSouls();
    PurgePitysoul();
    LastManHandler();
}

//=================================================================
//Underworld/overworld zone functions
//=================================================================

//functions to handle eureka effect shenanigans -- if a living player enters hell or a dead player enters the overworld, TP them back to the correct spawn
//this will also prevent using teleporters across the areas, but map maker should block building teleporters in hell with a filtered func_nobuild anyway to prevent confusion
function OverworldCustoms()
{
    if (activator == null)
        return;
    if (!IsPlayerAliveInArena(activator))
    {
        if (activator.GetTeam() == TF_TEAM_RED)
            activator.Teleport(true, red_ee_under.GetOrigin(), true, red_ee_under.GetAbsAngles(), true, Vector(0, 0, 0));
        else if (activator.GetTeam() == TF_TEAM_BLUE)
            activator.Teleport(true, blu_ee_under.GetOrigin(), true, blu_ee_under.GetAbsAngles(), true, Vector(0, 0, 0));
    }
}
function UnderworldCustoms()
{
    if (activator == null)
        return;
    if (IsPlayerAliveInArena(activator))
    {
        if (activator.GetTeam() == TF_TEAM_RED)
            activator.Teleport(true, red_ee_over.GetOrigin(), true, red_ee_over.GetAbsAngles(), true, Vector(0, 0, 0));
        else if (activator.GetTeam() == TF_TEAM_BLUE)
            activator.Teleport(true, blu_ee_over.GetOrigin(), true, blu_ee_over.GetAbsAngles(), true, Vector(0, 0, 0));
    }
}

//=================================================================
//Soul handling for underworld
//=================================================================

try { PurgeSouls(); } catch(e) { }; //ALL soul particles must die
soul_cache <- {};
soulglowpartL <- null;
soulglowpartR <- null;
soulglowborder <- null;

//give or souls for underworld kills and assists
function GiveSoul(player)
{
    if (soul_cache.rawin(player)) return;

    player.SetScriptOverlayMaterial(ARENA_AFTERLIFE_SOUL_OVERLAY);
    ClientPrint(player, HUD_PRINTCENTER, ARENA_AFTERLIFE_PICKUP_MESSAGE);
    EmitSoundOnClient("Announcer.SoulPickup", player);

    soulglowpartR <- SpawnEntityFromTable("info_particle_system", {
        origin = Vector(100, 900, 0),
        angles = QAngle(0, 0, 0),
        targetname = "soulglowpartR",
        effect_name = ARENA_AFTERLIFE_PARTICLE,
        start_active = true
    });
    soulglowpartR.AcceptInput("SetParent", "!activator", player, null);
    soulglowpartR.AcceptInput("SetParentAttachment", "eyeglow_R", null, null);
    soulglowpartL <- SpawnEntityFromTable("info_particle_system", {
        origin = Vector(100, 900, 0),
        angles = QAngle(0, 0, 0),
        targetname = "soulglowpartL",
        effect_name = ARENA_AFTERLIFE_PARTICLE,
        start_active = true
    });
    soulglowpartL.AcceptInput("SetParent", "!activator", player, null);
    soulglowpartL.AcceptInput("SetParentAttachment", "eyeglow_L", null, null);

    soulglowborder <- SpawnEntityFromTable("tf_glow", {
        targetname = "soulglowborder",
        target = "bignet",
        Mode = 0,
        GlowColor = (player.GetTeam() == TF_TEAM_RED ? ARENA_AFTERLIFE_GLOW_RED : player.GetTeam() == TF_TEAM_BLUE ? ARENA_AFTERLIFE_GLOW_BLU : "255 255 255")
    });
    soulglowborder.DispatchSpawn();
    SetPropEntity(soulglowborder, "m_hTarget", player);

    soul_cache[player] <- [soulglowpartR, soulglowpartL, soulglowborder];

    //reduce feel-bads of dying with a soul in hell by full-healing when they pick one up (doesn't stack)
    if(player.GetHealth()<player.GetMaxHealth())
        player.SetHealth(player.GetMaxHealth());

    //in case player is already on the trigger
    foreach(trigger in underworld_portals){
        EntFireByHandle(trigger, "Disable", "", 0, null, null);
        EntFireByHandle(trigger, "Enable", "", 0.1, null, null);
    }
}

//strip a soul from a single player, if they exist and have one
function StripSoul(player)
{
    if (!soul_cache.rawin(player)) return;

    try
    {
        KillIfValid(soul_cache[player][0]);
        KillIfValid(soul_cache[player][1]);
        KillIfValid(soul_cache[player][2]);
    }
    catch (e) { }

    soul_cache.rawdelete(player);

    try { player.SetScriptOverlayMaterial(""); } catch(e){};
}

//this should decisively purge ALL particle effects for souls and reset ALL screens overlays
function PurgeSouls()
{
    foreach(player, soulpart in soul_cache)
    {
        try
        {
            KillIfValid(soul_cache[player][0]);
            KillIfValid(soul_cache[player][1]);
            KillIfValid(soul_cache[player][2]);
        }
        catch (e) { }
    }

    soul_cache <- {};

    foreach (player in GetPlayers())
        if (IsValidPlayer(player))
            try { player.SetScriptOverlayMaterial(""); } catch(e){};
}

//=================================================================
//Resurrection
//=================================================================

rescount <- 0;
function CheckResurrect()
{
    if (activator == null)
        return;
    if(soul_cache.rawin(activator))
    {
        Resurrect(activator);
    }
    else
    {
        ClientPrint(activator, HUD_PRINTCENTER, ARENA_AFTERLIFE_SOULLESS_MESSAGE);
        if ((soulless_caged_cache.find(activator) == null) && (!isMiniRoundOver))
        {
            soulless_caged_cache.push(activator);
            EmitSoundOnClient("Announcer.AltarNoSoul", activator);
        }
    }
}
//Resurrects the passed player
function Resurrect(player)
{
    local index;
    local respoint;
    //safety check but we shouldn't hit this
    if (player == null)
        return;

    foreach(team in [0, player.GetTeam()])
        AddAlivePlayer(player, team);
    try { UpdatePlayerCounters(); } catch (e) {}
    if (activator.GetTeam() == TF_TEAM_RED)
    {
        respoint = red_respawns[rescount%red_respawns.len()];
        activator.Teleport(true, respoint.GetOrigin(), true, respoint.GetAbsAngles(), true, Vector(0, 0, 0));
        //ClientPrint(null, HUD_PRINTTALK, "\x07FF3F3F"+GetPropString(player, "m_szNetname")+ARENA_AFTERLIFE_RESURRECT_MESSAGE); //removing from final version; too many testers found this annoying when it got spammy

        //shouldn't happen unless noclip shenanigans but if it does it breaks things
        if (player == last_man_red)
        {
            LastManRedStrip(player);
            last_man_red <- null;
        }
    }
    else if (activator.GetTeam() == TF_TEAM_BLUE)
    {
        respoint = blu_respawns[rescount%blu_respawns.len()];
        activator.Teleport(true, respoint.GetOrigin(), true, respoint.GetAbsAngles(), true, Vector(0, 0, 0));
        //ClientPrint(null, HUD_PRINTTALK, "\x0799CCFF"+GetPropString(player, "m_szNetname")+ARENA_AFTERLIFE_RESURRECT_MESSAGE); //removing from final version; too many testers found this annoying when it got spammy

        //shouldn't happen unless noclip shenanigans but if it does it breaks things
        if (player == last_man_blu)
        {
            LastManBluStrip(player);
            last_man_blu <- null;
        }
    }
    rescount++;
    EntFireByHandle(tf_gamerules, "PlayVO", "RD.TeamScoreCore", 0, null, null);
    player.Regenerate(true);
    if(player.GetHealth()<(player.GetMaxHealth()*1.25))
        player.SetHealth(player.GetMaxHealth()*1.25);
    if((GetAlivePlayers(5-player.GetTeam()).len()) >= (2*(GetAlivePlayers(player.GetTeam()).len())))
    {
        foreach (cond in ARENA_AFTERLIFE_RESURRECT_BUFFS)
            player.AddCondEx(cond[0], cond[2], this);
    }
    else
    {
        foreach (cond in ARENA_AFTERLIFE_RESURRECT_BUFFS)
            player.AddCondEx(cond[0], cond[1], this);
    }
    StripSoul(player);
    player.AcceptInput("SpeakResponseConcept", "TLK_RESURRECTED", null, null);
    player.AcceptInput("TriggerLootIslandAchievement", "", null, null); //this should allow for contract objective (condition 119)
}

//=================================================================
//Pity Souls (to prevent boredom in Hell during shutouts)
//=================================================================

pitysoul <- null;
pitysoulthresholds <- [ARENA_AFTERLIFE_PITYSOUL_START_THRESHOLD, ARENA_AFTERLIFE_PITYSOUL_START_THRESHOLD];

//called when counters are updated, see if we want to spawn a pitysoul
function CheckPitySoul()
{
    //several instances where we'd never want to spawn a pity soul -- not during round, no threshold set or no spawnpoints, and one already exists
    if (isMiniRoundOver || isMiniRoundSetup)
        return;
    if (ARENA_AFTERLIFE_PITYSOUL_START_THRESHOLD < 1 || pitysoul_spots.len() < 1)
        return;
    if (pitysoul != null)
        return;

    //if either team has fewer than 3 total players, or fewer than the starting threshold + 1, doesn't make sense to spawn one
    if ((GetPlayers(TF_TEAM_RED).len()<3) || (GetPlayers(TF_TEAM_RED).len()<=ARENA_AFTERLIFE_PITYSOUL_START_THRESHOLD)||(GetPlayers(TF_TEAM_BLUE).len()<3) || (GetPlayers(TF_TEAM_BLUE).len()<=ARENA_AFTERLIFE_PITYSOUL_START_THRESHOLD))
        return;

    //check if we qualify -- is this a shutout? IE does either team have zero non-alive players?
    if ((GetPlayers(TF_TEAM_RED).len() - GetAlivePlayers(TF_TEAM_RED).len()) * (GetPlayers(TF_TEAM_BLUE).len() - GetAlivePlayers(TF_TEAM_BLUE).len()) != 0)
        return;

    //check if we qualify -- has either team reached their threshold of non-alive players?  if so increment their threshold and spawn a pitysoul
    if (GetPlayers(TF_TEAM_RED).len() - GetAlivePlayers(TF_TEAM_RED).len() >= pitysoulthresholds[0])
    {
        pitysoulthresholds[0] += ARENA_AFTERLIFE_PITYSOUL_INCREMENT;
        SpawnPitysoul();
    }
    else if (GetPlayers(TF_TEAM_BLUE).len() - GetAlivePlayers(TF_TEAM_BLUE).len() >= pitysoulthresholds[1])
    {
        pitysoulthresholds[1] += ARENA_AFTERLIFE_PITYSOUL_INCREMENT;
        SpawnPitysoul();
    }
}

//picks a spot and spawns a pitysoul
function SpawnPitysoul()
{
    pitysoul <- SpawnEntityFromTable("item_teamflag", {
        targetname = "pitysoulflag",
        PointValue = 0,
        flag_model = ARENA_AFTERLIFE_PITYSOUL_MODEL,
        flag_trail = "soul_trail",
        origin = pitysoul_spots[RandomInt(0, (pitysoul_spots.len()-1))].GetOrigin(),
        GameType = 3
    });
    EntityOutputs.AddOutput(pitysoul, "OnPickup1", "!self", "RunScriptCode", "PickupPitySoul()", 0, -1);
    pitysoul.DispatchSpawn();
    ClientPrint(null, HUD_PRINTTALK, ARENA_AFTERLIFE_PITYSOUL_SPAWN_MESSAGE);
    foreach (player in GetPlayers())
    {
        if(IsValidPlayer(player) && (!IsPlayerAliveInArena(player)) && (!soul_cache.rawin(player)) && (hell_intro_cache.find(player) != null))
            EmitSoundOnClient("Announcer.LooseSoul", player);
    }
}

//executed on soul pickup, kills the soul and grants the player a soul
::PickupPitySoul <- function()
{
    activator.DropFlag(true);

    if (activator.GetTeam() == TF_TEAM_RED)
    {
        ClientPrint(null, HUD_PRINTTALK, "\x07FF3F3F"+GetPropString(activator, "m_szNetname")+ARENA_AFTERLIFE_PITYSOUL_PICKUP_MESSAGE);
    }
    else if (activator.GetTeam() == TF_TEAM_BLUE)
    {
        ClientPrint(null, HUD_PRINTTALK, "\x0799CCFF"+GetPropString(activator, "m_szNetname")+ARENA_AFTERLIFE_PITYSOUL_PICKUP_MESSAGE);
    }

    //check if something broke; this shouldn't happen
    if (pitysoul == null)
    {
        PurgePitysoul();
        GiveSoul(activator);
        EmitSoundOnClient("Halloween.PumpkinPickup", activator);
        return;
    }

    KillIfValid(pitysoul);
    pitysoul <- null;
    GiveSoul(activator);
    EmitSoundOnClient("Halloween.PumpkinPickup", activator);
}.bindenv(this);

//deletes the extant pitysoul
function PurgePitysoul()
{
    for (local ent = null; ent = FindByName(ent, "pitysoulflag");)
    {
        ent.Kill();
    }
    pitysoul <- null;
}

//=================================================================
//Last-Man-Standing (anti-C&D-abuse)
//=================================================================

last_man_red <- null;
last_man_blu <- null;
lastmanredglow <- null;
lastmanbluglow <- null;
lastmanredglowpart <- null;
lastmanbluglowpart <- null;

//give the last man standing some boosts and also an outline to prevent C&D abuse
function LastManHandler()
{
    if(ARENA_AFTERLIFE_LASTMAN_BUFFS.len() <= 0)
        return;

    if (isMiniRoundOver || isMiniRoundSetup || wasWaitingForPlayers)
    {
        if (last_man_red != null)
            LastManRedStrip(last_man_red);
        last_man_red <- null;
        if (last_man_blu != null)
            LastManBluStrip(last_man_blu);
        last_man_blu <- null;

        //safety purge in case an effect got missed
        for (local ent = null; ent = FindByName(ent, "lastmanredglow");)
            ent.Kill();
        for (local ent = null; ent = FindByName(ent, "lastmanredglowpart");)
            ent.Kill();
        for (local ent = null; ent = FindByName(ent, "lastmanbluglow");)
            ent.Kill();
        for (local ent = null; ent = FindByName(ent, "lastmanredglowpart");)
            ent.Kill();
        return;
    }

    if (last_man_red != null && GetAlivePlayers(TF_TEAM_RED).len() != 1)
    {
        LastManRedStrip(last_man_red);
        last_man_red <- null;
    }
    if (last_man_red != null && !IsPlayerAliveInArena(last_man_red))
    {
        LastManRedStrip(last_man_red);
        last_man_red <- null;
    }
    if (last_man_blu != null && GetAlivePlayers(TF_TEAM_BLUE).len() != 1)
    {
        LastManBluStrip(last_man_blu);
        last_man_blu <- null;
    }
    if (last_man_blu != null && !IsPlayerAliveInArena(last_man_blu))
    {
        LastManBluStrip(last_man_blu);
        last_man_blu <- null;
    }

    if(GetAlivePlayers(TF_TEAM_RED).len() == 1 && (last_man_red == null || GetAlivePlayers(TF_TEAM_RED)[0] != last_man_red))
    {
        last_man_red <- GetAlivePlayers(TF_TEAM_RED)[0];
        LastManRedBoost(last_man_red);
    }
    if(GetAlivePlayers(TF_TEAM_BLUE).len() == 1 && (last_man_blu == null || GetAlivePlayers(TF_TEAM_BLUE)[0] != last_man_blu))
    {
        last_man_blu <- GetAlivePlayers(TF_TEAM_BLUE)[0];
        LastManBluBoost(last_man_blu);
    }
}

//strips lastman boons
function LastManRedStrip(player)
{
    KillIfValid(lastmanredglow);
    KillIfValid(lastmanredglowpart);
    lastmanredglow <- null;
    lastmanredglowpart <- null;
    if (!IsValidPlayer(player)) return;
    foreach (cond in ARENA_AFTERLIFE_LASTMAN_BUFFS)
        player.RemoveCond(cond);
}
function LastManBluStrip(player)
{
    KillIfValid(lastmanbluglow);
    KillIfValid(lastmanbluglowpart);
    lastmanbluglow <- null;
    lastmanbluglowpart <- null;
    if (!IsValidPlayer(player)) return;
    foreach (cond in ARENA_AFTERLIFE_LASTMAN_BUFFS)
        player.RemoveCond(cond);
}

//grants lastman boons
function LastManRedBoost(player)
{
    if (!IsValidPlayer(player)) return;
    KillIfValid(lastmanredglow);
    KillIfValid(lastmanredglowpart);
    lastmanredglow <- SpawnEntityFromTable("tf_glow", {
        targetname = "lastmanredglow",
        target = "bignet",
        Mode = 0,
        GlowColor = ARENA_AFTERLIFE_GLOW_RED
    });
    lastmanredglow.DispatchSpawn();
    lastmanredglowpart <- SpawnEntityFromTable("info_particle_system", {
        targetname = "lastmanredglowpart",
        effect_name = "medic_healradius_red_buffed",
        start_active = "Yes"
    });
    lastmanredglowpart.AcceptInput("SetParent", "!activator", player, player);
    lastmanredglowpart.DispatchSpawn();
    SetPropEntity(lastmanredglow, "m_hTarget", player);
    foreach (cond in ARENA_AFTERLIFE_LASTMAN_BUFFS)
        player.AddCond(cond);
    ClientPrint(player, HUD_PRINTCENTER, ARENA_AFTERLIFE_LASTMAN_MESSAGE);
    ClientPrint(null, HUD_PRINTTALK, "\x07FF3F3F"+GetPropString(player, "m_szNetname")+ARENA_AFTERLIFE_LASTMAN_ALL);
    EmitSoundOnClient("Announcer.LastManStanding", player);
}
function LastManBluBoost(player)
{
    if (!IsValidPlayer(player)) return;
    KillIfValid(lastmanbluglow);
    KillIfValid(lastmanbluglowpart);
    lastmanbluglow <- SpawnEntityFromTable("tf_glow", {
        targetname = "lastmanbluglow",
        target = "bignet",
        Mode = 0,
        GlowColor = ARENA_AFTERLIFE_GLOW_BLU
    });
    lastmanbluglow.DispatchSpawn();
    lastmanbluglowpart <- SpawnEntityFromTable("info_particle_system", {
        targetname = "lastmanbluglowpart",
        effect_name = "medic_healradius_blue_buffed",
        start_active = "Yes"
    });
    lastmanbluglowpart.AcceptInput("SetParent", "!activator", player, player);
    lastmanbluglowpart.DispatchSpawn();
    SetPropEntity(lastmanbluglow, "m_hTarget", player);
    foreach (cond in ARENA_AFTERLIFE_LASTMAN_BUFFS)
        player.AddCond(cond);
    ClientPrint(player, HUD_PRINTCENTER, ARENA_AFTERLIFE_LASTMAN_MESSAGE);
    ClientPrint(null, HUD_PRINTTALK, "\x0799CCFF"+GetPropString(player, "m_szNetname")+ARENA_AFTERLIFE_LASTMAN_ALL);
    EmitSoundOnClient("Announcer.LastManStanding", player);
}

//=================================================================
//Lava handler
//=================================================================
//technically it's magma since its all underground but I'm not rewriting the code to reflect that at this stage

// Ensure only one of this entity is ever spawned
if (!("disintegrate_proxy_weapon" in getroottable()))
{
    ::disintegrate_proxy_weapon <- null;

    ::disintegrate_immune_conds <-
    [
        Constants.ETFCond.TF_COND_INVULNERABLE,
        Constants.ETFCond.TF_COND_PHASE,
        Constants.ETFCond.TF_COND_INVULNERABLE_HIDE_UNLESS_DAMAGED,
        Constants.ETFCond.TF_COND_INVULNERABLE_USER_BUFF,
        Constants.ETFCond.TF_COND_INVULNERABLE_CARD_EFFECT
    ];
}

// Create the fake weapon if one doesn't already exist
if (!disintegrate_proxy_weapon || !disintegrate_proxy_weapon.IsValid())
{
    disintegrate_proxy_weapon = Entities.CreateByClassname("tf_weapon_grapplinghook");
    SetPropInt(disintegrate_proxy_weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", 939);
    SetPropBool(disintegrate_proxy_weapon, "m_AttributeManager.m_Item.m_bInitialized", true);
    disintegrate_proxy_weapon.DispatchSpawn();
    disintegrate_proxy_weapon.DisableDraw();

    // Add the attribute that creates disintegration
    disintegrate_proxy_weapon.AddAttribute("ragdolls become ash", 1.0, -1.0);
}

//incinerates a player entering lava
function LavaEntered()
{

    if (!IsValidPlayer(activator)) return;

    // Remove conditions that give immunity to damage
    foreach (cond in disintegrate_immune_conds)
        activator.RemoveCondEx(cond, true);

    //set up lava cleaner to prevent camera falling
    EntFireByHandle(self, "RunScriptCode", "LavaCleaner()", 0.2, activator, null);

    // Set owner to last damager if there was one, so they can get the soul
    //assister e.g. medic should still get assist credit in this case
    //which counts for getting a soul too
    try {
        if(lava_tracker[activator] && IsValidPlayer(lava_tracker[activator]))
        {
            SetPropEntity(disintegrate_proxy_weapon, "m_hOwner", lava_tracker[activator]);
            // Deal the damage with the weapon
            activator.TakeDamageCustom(lava_tracker[activator], lava_tracker[activator], disintegrate_proxy_weapon,
                                        Vector(0,0,0), Vector(0,0,0),
                                        99999.0, 2056, Constants.ETFDmgCustom.TF_DMG_CUSTOM_BURNING);
            return;
        }
    } catch (e) {};
    SetPropEntity(disintegrate_proxy_weapon, "m_hOwner", activator);
    // Deal the damage with the weapon
    activator.TakeDamageCustom(activator, activator, disintegrate_proxy_weapon,
                                Vector(0,0,0), Vector(0,0,0),
                                99999.0, 2056, Constants.ETFDmgCustom.TF_DMG_CUSTOM_BURNING);
}

//Even incinerating the ragdoll, the player's camera follows where the ragdoll "would" go
//this means it falls deep into the lava (like falling in the slime in portal)
//this is ugly and the player can't see themselves being incinerated
//killing the ragdoll stops the camera where the player hit the lava so they can see the cool visuals instead of the ugly under-lava area
function LavaCleaner()
{
    local ragdoll = GetPropEntity(activator, "m_hRagdoll");
    if (ragdoll == null) return;
    SetPropBool(ragdoll, "m_bForcePurgeFixedupStrings", true);
    ragdoll.Kill();
}

//=================================================================
//Player-Related Arena Logic
//=================================================================

respawnRecursionFlag <- false;
antiRespawnSpam <- {};
playerSpawnTauntPos <- {};

function CheckAlivePlayers()
{
    if (isMiniRoundOver || isMiniRoundSetup)
        return;

    if (GetPlayers(TF_TEAM_RED).len() <= 0 || GetPlayers(TF_TEAM_BLUE).len() <= 0)
    {
        wasWaitingForPlayers = true;
        return;
    }
    else if (wasWaitingForPlayers)
    {
        ResetNewMiniRound();
        return;
    }

    local redAlive = GetAlivePlayers(TF_TEAM_RED).len();
    local bluAlive = GetAlivePlayers(TF_TEAM_BLUE).len();

    if (redAlive <= 0 && bluAlive <= 0)
        EndMiniRound(TEAM_UNASSIGNED);
    else if (redAlive <= 0)
        EndMiniRound(TF_TEAM_BLUE);
    else if (bluAlive <= 0)
        EndMiniRound(TF_TEAM_RED);
}

function PreventSuicideOnClassChange(player)
{
    local weapon = player.GetActiveWeapon();
    if (!weapon) return;
    if (player.IsTaunting()) return; // prevent abusing this QOL feature to taunt cancel

    player.StunPlayer(0.1, 1, 96, null); // prevent airjumping in the ghost mode frame
    player.StopSound("Halloween.PlayerScream");

    player.AddCond(TF_COND_HALLOWEEN_GHOST_MODE);
    EntFireByHandle(player, "RunScriptCode", "self.RemoveCond(TF_COND_HALLOWEEN_GHOST_MODE); self.Weapon_Switch(activator);", 0, weapon, weapon);
}

//=================================================================
//Point Capture Logic
//=================================================================

tf_objective_resource <- FindByClassname(null, "tf_objective_resource");
overtimeTrigerred <- false;
control_points <- [];
spawn_triggers <- {};

//adding the other map feature collection steps here too to keep them all together
overworld_spawns <- [];
underworld_spawns <- [];
red_respawns <- [];
blu_respawns <- [];
red_ee_over <- null;
red_ee_under <- null;
blu_ee_over <- null;
blu_ee_under <- null;
underworld_portals <- [];
lava_tracker <- {};
pitysoul_spots <- [];

/* 2-point Arena (e.g. Byre) has a unique victory condition:
   To win the round, it's not enough to merely own both points - no point should be contested.
   The point master does not account for this, so, we have to re-implement the win condition ourselves. */
function CollectControlPointsAndSpawnTriggers()
{
    local team_control_point_master = FindByClassname(null, "team_control_point_master");
    if (team_control_point_master)
        team_control_point_master.KeyValueFromInt("cpm_restrict_team_cap_win", 1);
    else
    {
        SpawnEntityFromTable("team_control_point_master", {
            cpm_restrict_team_cap_win = 1,
            custom_position_x = -1,
            custom_position_y = 0.83,
            score_style = 0,
            partial_cap_points_rate = 0,
            play_all_rounds = 0,
            StartDisabled = 0,
            switch_teams = 0
        });
    }

    for (local ent = null; ent = FindByClassname(ent, "team_control_point");)
        control_points.push(ent);
    for (local ent = null; ent = FindByClassname(ent, "func_respawnroom");)
        spawn_triggers[ent] <- ent.GetOrigin();
    for (local ent = null; ent = FindByClassname(ent, "info_player_teamspawn");){
        if (startswith(ent.GetName(), "afterlife_overworld_spawn"))
            overworld_spawns.push(ent);
        else if (startswith(ent.GetName(), "afterlife_underworld_spawn"))
            underworld_spawns.push(ent);
    }
    for (local ent = null; ent = FindByClassname(ent, "info_teleport_destination");){
        if (ent.GetName() == "afterlife_respawn_red")
            red_respawns.push(ent);
        else if (ent.GetName() == "afterlife_respawn_blu")
            blu_respawns.push(ent);
        else if (ent.GetName() == "afterlife_eureka_overworld_red")
            red_ee_over <- ent;
        else if (ent.GetName() == "afterlife_eureka_underworld_red")
            red_ee_under <- ent;
        else if (ent.GetName() == "afterlife_eureka_overworld_blu")
            blu_ee_over <- ent;
        else if (ent.GetName() == "afterlife_eureka_underworld_blu")
            blu_ee_under <- ent;
        else if (ent.GetName() == "afterlife_pitysoul_pickup")
            pitysoul_spots.push(ent);
    }

    for (local ent = null; ent = FindByClassname(ent, "trigger_multiple");)
    {
        if (ent.GetName() == "afterlife_overworld")
        {
            EntityOutputs.AddOutput(ent, "OnStartTouch", "!activator", "RunScriptCode", "OverworldEntered()", 0, -1);
        }
        else if (ent.GetName() == "afterlife_underworld")
        {
            EntityOutputs.AddOutput(ent, "OnStartTouch", "!activator", "RunScriptCode", "UnderworldEntered()", 0, -1);
        }
        else if (ent.GetName() == "afterlife_portal")
        {
            underworld_portals.push(ent);
            EntityOutputs.AddOutput(ent, "OnStartTouch", "!activator", "RunScriptCode", "PortalEntered()", 0, -1);
        }
    }
    for (local ent = null; ent = FindByClassname(ent, "trigger_hurt");)
    {
        if (ent.GetName() == "afterlife_lava")
        {
            EntityOutputs.AddOutput(ent, "OnStartTouch", "!activator", "RunScriptCode", "LavaTriggered()", 0, -1);
        }
    }
}
EntFireByHandle(self, "RunScriptCode", "CollectControlPointsAndSpawnTriggers()", 0, null, null);

/* If both points are owned by the same team, we need to monitor their capture progress status
   as to win the mini-round no point should be contested. */
::Arena_CheckPointStatus <- function()
{
    local team = control_points[0].GetTeam();
    foreach (control_point in control_points)
        if (control_point.GetTeam() != team)
            return;

    for (local i = 0; i < 8; i++)
        if (GetPropFloatArray(tf_objective_resource, "m_flCapPercentages", i) > Epsilon)
            return overtimeTrigerred = true;
    EndMiniRound(team, false);
}.bindenv(this);

function AddPointInput_CheckPointStatus()
{
    EntityOutputs.AddOutput(self, "OnUser1", "team_control_point", "HideModel", "", 0, -1);
    foreach (control_point in control_points)
    {
        EntityOutputs.AddOutput(control_point, "OnCapTeam1", "!self", "RunScriptCode", "Arena_CheckPointStatus()", 0, -1);
        EntityOutputs.AddOutput(control_point, "OnCapTeam2", "!self", "RunScriptCode", "Arena_CheckPointStatus()", 0, -1);
        EntityOutputs.AddOutput(control_point, "OnUnlocked", "!self", "ShowModel", "", 0, -1);
    }
}
EntFireByHandle(self, "RunScriptCode", "AddPointInput_CheckPointStatus()", 0, null, null);

//=================================================================
//HUD
//=================================================================

PrecacheModel("models/empty.mdl");
SetPropInt(tf_gamerules, "m_nHudType", 2);

redCounterFixer <- null;
worldspawn <- FindByClassname(null, "worldspawn");

/* The default vertical position of the point UI widget would overlap with the round counter.
   If the map uses default position, move it up a bit. */
function FixPointHUDLayout()
{
    for (local i = 0; i < 8; i++)
        if (GetPropFloatArray(tf_objective_resource, "m_flCustomPositionY", i) == -1)
            SetPropFloatArray(tf_objective_resource, "m_flCustomPositionY", 0.83, i)
}
EntFireByHandle(self, "RunScriptCode", "FixPointHUDLayout()", 0, null, null);

//called at start of round to prevent rare phantom escrow flags from previous round screwing with the player counters
function ResetEscrowFlags()
{
    for (local ent = null; ent = FindByClassname(ent, "item_teamflag");)
        ent.Kill();
    escrow_blue <- null;
    escrow_red <- null;

    for (local ent = null; ent = Entities.FindByTarget(ent, "red_counter_fixer");)
    {
        SetPropBool(ent, "m_bForcePurgeFixedupStrings", true);
        ent.Kill();
    }
    for (local ent = null; ent = FindByName(ent, "red_counter_fixer");)
        ent.Kill();
    redCounterFixer <- null;

    SpawnEscrowFlags();
}

/* Player Destruction calculates the Escrow points on the fly based on the existing item_teamflag entities.
   There is no netprop we can edit with VScript directly.
   Fortunately, a dropped flag shoved out-of-bounds still counts as long as its has an owner.
   Apparently, only players and worldspawn (for some reason) count as legit owners.
   So, for one team (BLU) worldspawn is the flag owner, and for the other (RED) it's one of the players. */
function SpawnEscrowFlags()
{
    escrow_blue <- SpawnEntityFromTable("item_teamflag", {
        PointValue = 1,
        flag_model = "models/empty.mdl",
        origin = Vector(0, 0, 9000),
        GameType = 6
    });
    SetPropEntity(escrow_blue, "m_hPrevOwner", worldspawn);

    SetPropInt(escrow_blue, "m_nFlagStatus", 1);
    escrow_red <- SpawnEntityFromTable("item_teamflag", {
        PointValue = 1,
        flag_model = "models/empty.mdl",
        origin = Vector(0, 0, 9000),
        GameType = 6
    });
    SetPropInt(escrow_red, "m_nFlagStatus", 1);

    try { UpdatePlayerCounters(); } catch (e) {}
}
EntFireByHandle(self, "RunScriptCode", "SpawnEscrowFlags()", 0, null, null);

function UpdatePlayerCounters()
{
    if (wasWaitingForPlayers)
    {
        SetPropInt(escrow_red,  "m_nPointValue", 0);
        SetPropInt(escrow_blue, "m_nPointValue", 0);
    }
    else if (isMiniRoundSetup)
    {
        SetPropInt(escrow_red,  "m_nPointValue", GetPlayers(TF_TEAM_RED).len());
        SetPropInt(escrow_blue, "m_nPointValue", GetPlayers(TF_TEAM_BLUE).len());
    }
    else
    {
        SetPropInt(escrow_red,  "m_nPointValue", GetAlivePlayers(TF_TEAM_RED).len());
        SetPropInt(escrow_blue, "m_nPointValue", GetAlivePlayers(TF_TEAM_BLUE).len());
    }
    FixRedPlayerCounter();
    CheckPitySoul();
    LastManHandler();
}

/* In order to display the Escrow count correctly, the flag owner needs to be "loaded" on your client,
   otherwise it will display 0.
   With worldspawn, it's simple, but for the other team we need to make sure that player is loaded
   across the entire map, but without making him actually visible to the enemy players.
   So, instead of giving the glow to the player entity itself,
   we attach a prop_dynamic to the player, give it an invisible model, and we give the glow to the prop.
   If either the player, the prop, or the glow are missing, we draw a new player to be the flag owner. */
function FixRedPlayerCounter()
{
    if (redCounterFixer && redCounterFixer.IsValid())
    {
        local parent = redCounterFixer.GetMoveParent();
        if (!parent || parent.GetTeam() != TF_TEAM_RED)
            redCounterFixer.Kill();
        else
            return;
    }
    local redPlayers = GetPlayers(TF_TEAM_RED);
    if (redPlayers.len() <= 0)
        return;
    local player = redPlayers[0];
    if (!IsValidPlayer(player))
        player = redPlayers[redPlayers.len() - 1];
    SetPropEntity(escrow_red, "m_hPrevOwner", player);

    redCounterFixer = Entities.CreateByClassname("prop_dynamic");
    redCounterFixer.KeyValueFromString("targetname", "red_counter_fixer");
    redCounterFixer.SetModel("models/empty.mdl");
    redCounterFixer.SetAbsOrigin(player.GetOrigin());
    SetPropBool(redCounterFixer, "m_bForcePurgeFixedupStrings", true);
    Entities.DispatchSpawn(redCounterFixer);
    EntFireByHandle(redCounterFixer, "SetParent", "!activator", 0, player, player);

    local tf_glow = SpawnEntityFromTable("tf_glow", {
        target = "red_counter_fixer",
        StartDisabled = 0,
        GlowColor = "0 0 0 0"
    });
    tf_glow.SetAbsOrigin(redCounterFixer.GetOrigin());
    EntFireByHandle(tf_glow, "SetParent", "!activator", 0, redCounterFixer, redCounterFixer);
}

function DisplayVictoryMessage(winnerTeam, wipeout)
{
    local message =
        winnerTeam == TF_TEAM_RED ? "#Winpanel_RedWins"
        : winnerTeam == TF_TEAM_BLUE ? "#Winpanel_BlueWins"
        : "#koth_undergrove_event_stalemate";
    local game_text = SpawnEntityFromTable("game_text", {
        color = (winnerTeam == TF_TEAM_RED ? "255 59 59" : winnerTeam == TF_TEAM_BLUE ? "125 168 255" : "255 255 255"),
        color2 = "0 0 0",
        effect = 0,
        fadein = 0.2,
        fadeout = 0.2,
        fxtime = 0,
        holdtime = 5,
        message = message,
        spawnflags = 1,
        channel = 1,
        x = -1,
        y = 0.7
    });
    EntFireByHandle(game_text, "Display", "", 0, null, null);
    EntFireByHandle(game_text, "Kill", "", 1, null, null);

    local winnerLine = wipeout ? "Announcer.TheirTeamWiped" : "Announcer.Success";
    local loserLine = wipeout  ? "Announcer.YourTeamWiped"  : "Announcer.Failure";

    EntFireByHandle(tf_gamerules, "PlayVO", "Hud.EndRoundScored", 0, null, null);
    if (winnerTeam == TF_TEAM_BLUE)
    {
        EntFireByHandle(tf_gamerules, "PlayVOBlue", winnerLine, 0, null, null);
        EntFireByHandle(tf_gamerules, "PlayVORed",  loserLine, 0, null, null);
    }
    else if (winnerTeam == TF_TEAM_RED)
    {
        EntFireByHandle(tf_gamerules, "PlayVORed",  winnerLine, 0, null, null);
        EntFireByHandle(tf_gamerules, "PlayVOBlue", loserLine, 0, null, null);
    }
    else
    {
        EntFireByHandle(tf_gamerules, "PlayVO", "Announcer.TieGame", 0, null, null);
    }
}

//=================================================================
//First Blood
//=================================================================

FIRST_BLOOD_FAST <- 15;
FIRST_BLOOD_SLOW <- 45;

roundStartTS <- Time();
firstBloodUsed <- false;

function TryProvideFirstBlood(params)
{
    if (firstBloodUsed || params.userid == params.attacker)
        return;
    local attacker = GetPlayerFromUserID(params.attacker);
    if (!attacker)
        return;
    foreach (cond in ARENA_FIRST_BLOOD_BUFFS)
        attacker.AddCondEx(cond[0], cond[1], attacker);
    firstBloodUsed = true;

    local deltaTS = Time() - roundStartTS;
    local msg = deltaTS <= FIRST_BLOOD_FAST ? "Announcer.AM_FirstBloodFast"
            : deltaTS >= FIRST_BLOOD_SLOW ? "Announcer.AM_FirstBloodFinally"
            : "Announcer.AM_FirstBloodRandom";
    EntFireByHandle(tf_gamerules, "PlayVO", msg, 0, null, null);
}

//===================================================================
//PostLoad
//===================================================================

function Think()
{
    if (overtimeTrigerred)
        Arena_CheckPointStatus();
    CheckAlivePlayers();
    return -1;
}
AddThinkToEnt(self, "Think");

/* This script is absent by design to allow Community Servers to plug in their own code.
   IMPORTANT: This is NOT for CUSTOM MAPS to include additional scripts.
   If that's the mapper's goal, simply add the second script to the logic_script's "Entity Script" field.
   This is intended to be left vacant for Community Servers to fill. */
try { IncludeScript("arena_addons/postload.nut"); } catch(e) { }

EntFireByHandle(self, "RunScriptCode", "ResetNewMiniRound()", 0, null, null);
__CollectGameEventCallbacks(arenaListener);
//!CompilePal::IncludeFile("resource/ui/hudarenavscript.res")