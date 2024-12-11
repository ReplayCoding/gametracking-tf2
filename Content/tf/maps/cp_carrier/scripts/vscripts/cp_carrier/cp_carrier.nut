if (!("MAX_CLIENTS" in getroottable()))
{
    local root_table = getroottable();
    ::MAX_CLIENTS <- MaxClients().tointeger();

    foreach (k, v in ::NetProps.getclass())
        if (k != "IsValid")
            root_table[k] <- ::NetProps[k].bindenv(::NetProps);

    foreach (_, cGroup in Constants)
        foreach (k, v in cGroup)
            root_table[k] <- v != null ? v : 0;
}

carrier <- null;

//=================================================================
//Carrier Conversion
//=================================================================

carrierSpawnPos <- Entities.FindByName(null, "boss_tele_dest").GetOrigin();

function ConvertToCarrier(player)
{
    carrier = player;

    local playerClass = clamp(player.GetPlayerClass(), 0, 9);
    player.SetCustomModelWithClassAnimations(BOT_MODELS[playerClass]);
    player.SetModelScale(3, -1);
    player.Teleport(true, carrierSpawnPos, false, QAngle(), true, Vector(0, 0, 0));
    player.KeyValueFromString("targetname", "carrier");
    player.AddCond(TF_COND_CRITBOOSTED_ON_KILL);
    player.SetGravity(playerClass == TF_CLASS_MEDIC ? 3 : 2);

    player.AddCustomAttribute("patient overheal penalty", 1, -1);
    player.AddCustomAttribute("override footstep sound set", 2, -1);
    player.AddCustomAttribute("damage force reduction", 0.25, -1);
    player.AddCustomAttribute("health from packs decreased", 0.05, -1);
    player.AddCustomAttribute("cloak consume rate increased", 9999, -1);
    player.AddCustomAttribute("voice pitch scale", 0, -1);
    player.AddCustomAttribute("cannot be backstabbed", 1, -1);
    player.AddCustomAttribute("airblast vulnerability multiplier", 0, -1);
    player.AddCustomAttribute("move speed penalty", 0.5, -1);
    player.AddCustomAttribute("taunt force weapon slot", 1, -1);
    player.AddCustomAttribute("cancel falling damage", 1, -1);
    player.AddCustomAttribute("reduced_healing_from_medics", 0.25, -1);
    player.AddCustomAttribute("patient overheal penalty", 0, -1);
    player.AddCustomAttribute("ammo regen", 1, -1);
    player.AddCustomAttribute("dmg taken from crit reduced", 0.75, -1);

    local classStockHP = player.GetMaxHealth();
    local carrierMaxHP = 3000 + 125 * GetREDPlayerCounter();
    player.SetHealth(carrierMaxHP);
    player.SetMaxHealth(carrierMaxHP);
    player.RemoveCustomAttribute("max health additive bonus");
    player.AddCustomAttribute("max health additive bonus", carrierMaxHP - classStockHP, -1);

    local itemsToKill = [];
    local extraWearables = [];
    for (local item = player.FirstMoveChild(), extraWearable; item != null; item = item.NextMovePeer())
    {
        SetPropBool(item, "m_bForcePurgeFixedupStrings", true);
        if (extraWearable = GetPropEntity(item, "m_hExtraWearable"))
            extraWearables.push(extraWearable);
        if (item.GetClassname() == "tf_wearable" && !GetPropEntity(item, "m_hWeaponAssociatedWith"))
            itemsToKill.push(item);
    }
    foreach (item in itemsToKill)
        if (extraWearables.find(item) == null)
            item.Kill();

    DoEntFire("boss_flag", "SetParentAttachment", "flag", 0, null, null);
    UpdateBossBarClass(playerClass);
    ShootGibs(player.GetCenter(), playerClass, true);

    for(local i = 0; i <= 6; i += 6)
        EmitSoundEx({
            sound_name = "ambient/alarms/klaxon1.wav",
            volume = 1,
            filter = RECIPIENT_FILTER_GLOBAL,
            soundlevel = 150,
            flags = 1,
            channel = i
        });

    EmitSoundEx({
        sound_name = HUMAN_SCREAM[playerClass],
        volume = 1,
        soundlevel = 150,
        flags = 1,
        channel = 0,
        origin = player.GetOrigin()
    });

    DoEntFire("bomb_sprite", "HideSprite", "", 0, null, null);
    DoEntFire("boss_elevator_train", "StartForward", "", 0.8, null, null);
    DoEntFire("boss_exit_door", "Open", "", 2, null, null);
    DoEntFire("flag_picked", "Trigger", "", 0, null, null);
    for (local i = 1; i < 6; i++)
        EntFireByHandle(self, "RunScriptCode", "ProcessCarrierBeingStuck()", i, null, null);
}

//=================================================================
//Carrier Death
//=================================================================

function CarrierDied(isPlayerDeath)
{
    tauntRobotModel = KillIfValid(tauntRobotModel);

    DispatchParticleEffect("fireSmokeExplosion_track", carrier.GetCenter(), Vector(0, 180, 0));
    carrier.KeyValueFromString("targetname", "");
    carrier.SetCustomModelWithClassAnimations("");
    EntFireByHandle(self, "RunScriptCode", "local ragdoll = GetPropEntity(activator, `m_hRagdoll`); if (ragdoll) ragdoll.Kill();", 0, carrier, carrier);
    ShootGibs(carrier.GetOrigin(), clamp(carrier.GetPlayerClass(), 0, 9), false);
    RevertCarrierConversion(carrier);

    EmitSoundEx({
        sound_name = "ambient/explosions/explode_2.wav",
        volume = 1,
        filter = RECIPIENT_FILTER_GLOBAL,
        soundlevel = 150,
        flags = 1,
        channel = 0
    });

    if (isPlayerDeath)
        EntFireByHandle(self, "RunScriptCode", "PlayCarrierDownVO()", 0.1, null, null);

    DoEntFire("boss_flag", "ForceReset", "", -1, null, null);
    DoEntFire("bomb_sprite", "ShowSprite", "", -1, null, null);
    DoEntFire("boss_exit_door", "Close", "", 1, null, null);
    DoEntFire("boss_elevator_train", "StartBackward", "", 1.1, null, null);
    DoEntFire("flag_dropped", "Trigger", "", 0, null, null);

    carrier = null;
}

function RevertCarrierConversion(player)
{
    if (player.GetGravity() < 1.1)
        return;
    player.KeyValueFromString("targetname", "");
    SetPropInt(player, "m_nRenderMode", 0);
    SetPropInt(player, "m_clrRender", 0xFFFFFFFF);
    player.SetGravity(1);
    player.RemoveCustomAttribute("max health additive bonus");
    player.SetHealth(player.GetMaxHealth());
    player.SetCustomModelWithClassAnimations("");
}

//=================================================================
//Carrier Taunt Animation Fix
//=================================================================

tauntRobotModel <- null;
DoEntFire("carrier_taunt_robot_model", "Kill", "", -1, null, null);

function ProcessCarrierTaunts()
{
    local weapon = carrier.GetActiveWeapon();
    local isTaunting = carrier.InCond(TF_COND_TAUNTING)
        || (weapon && weapon.GetClassname() == "tf_weapon_rocketpack")
        || (weapon && weapon.GetClassname() == "tf_weapon_pipebomblauncher" && weapon.GetSlot() == 1);
    if (isTaunting && !tauntRobotModel)
    {
        carrier.SetCustomModelWithClassAnimations("");
        SetPropInt(carrier, "m_nRenderMode", 1);
        SetPropInt(carrier, "m_clrRender", 1);
        DoEntFire("boss_flag", "SetParentAttachment", "flag", 0, null, null);

        tauntRobotModel = SpawnEntityFromTable("tf_wearable", {
            targetname = "carrier_taunt_robot_model"
         });
        tauntRobotModel.SetModel(BOT_MODELS[clamp(carrier.GetPlayerClass(), 0, 9)]);
        tauntRobotModel.Teleport(true, carrier.GetCenter(), true, carrier.GetAbsAngles(), false, Vector());
        SetPropBool(tauntRobotModel, "m_bForcePurgeFixedupStrings", true);
        SetPropBool(tauntRobotModel, "m_bValidatedAttachedEntity", true);
        SetPropBool(tauntRobotModel, "m_AttributeManager.m_Item.m_bInitialized", true);
        SetPropEntity(tauntRobotModel, "m_hOwnerEntity", carrier);
        EntFireByHandle(tauntRobotModel, "SetParent", "!activator", 0, carrier, carrier);

    }
    else if (!isTaunting && tauntRobotModel)
    {
        carrier.SetCustomModelWithClassAnimations(BOT_MODELS[clamp(carrier.GetPlayerClass(), 0, 9)]);
        SetPropInt(carrier, "m_nRenderMode", 0);
        SetPropInt(carrier, "m_clrRender", 0xFFFFFFFF);
        DoEntFire("boss_flag", "SetParentAttachment", "flag", 0, null, null);
        tauntRobotModel = KillIfValid(tauntRobotModel);
    }
}

//=================================================================
//Carrier Robot Voice
//=================================================================

if (!("VCDTable" in getroottable()))
    IncludeScript("cp_carrier/vcd_table.nut");

function ProcessCarrierRobotVoice()
{
    for (local scene = null, speaker, path; scene = Entities.FindByClassname(scene, "instanced_scripted_scene");)
    {
        SetPropBool(scene, "m_bForcePurgeFixedupStrings", true);
        scene.KeyValueFromString("classname", "discarded");
        speaker = GetPropEntity(scene, "m_hOwner");
        if (!speaker || speaker != carrier)
            continue;

        path = GetPropString(scene, "m_szInstanceFilename").tolower();
        if (!(path in VCDTable))
            continue;

        local params = PlayDistantSound(carrier, {
            sound_name = VCDTable[path],
            entity = speaker,
            filter_type = RECIPIENT_FILTER_PAS_ATTENUATION,
            sound_level = 150,
            channel = 6,
            volume = 1,
            pitch = BOT_VOICE_PITCH[clamp(speaker.GetPlayerClass(), 0, 9)]
        });
        params.filter_type = RECIPIENT_FILTER_SINGLE_PLAYER;
        EmitSoundEx(params);
        params.volume = 0.3;
        EmitSoundEx(params);
    }
}

//=================================================================
//Carrier Boss Bar
//=================================================================

Convars.SetValue("tf_rd_points_per_approach", "35");
pd_logic <- null;
water_lod_control <- SpawnEntityFromTable("water_lod_control", {});
isHudVisible <- false;

function SpawnBossBar()
{
    pd_logic = SpawnEntityFromTable("tf_logic_player_destruction", {
        finale_length = 9999,
        min_points = 1024,
        res_file = "resource/ui/carrier_boss_bar2.res"
    });
    pd_logic.AddFlag(EFL_NO_THINK_FUNCTION);
    SetPropInt(pd_logic, "m_nBlueScore", 0);
    SetPropInt(pd_logic, "m_nBlueTargetPoints", 0);
    SetPropInt(pd_logic, "m_nMaxPoints", 1024);
    SetPropBool(pd_logic, "m_bForcePurgeFixedupStrings", true);
    pd_logic.AcceptInput("SetPointsOnPlayerDeath", "0", null, null);
    pd_logic.AcceptInput("EnableMaxScoreUpdating", "0", null, null);
    pd_logic.AcceptInput("DisableMaxScoreUpdating", "0", null, null);
}
SpawnBossBar();

function UpdateBossBarClass(classIndex)
{
    EntFireByHandle(pd_logic, "setcountdownimage", BOSS_ICONS[classIndex], 0, null, null);
}

function ProcessBossBar()
{
    local barValue = 0;
    if (IsValidPlayer(carrier) && carrier.IsAlive())
        barValue = floor(clamp(1024.0 * carrier.GetHealth() / carrier.GetMaxHealth(), 1, 1024));
    if (barValue <= 0 && isHudVisible)
    {
        EntFireByHandle(pd_logic, "setcountdowntimer", "0", 0, null, null);
        SetPropFloat(water_lod_control, "m_flCheapWaterStartDistance", 0);
        isHudVisible = false;
    }
    else if (barValue > 0 && !isHudVisible)
    {
        EntFireByHandle(pd_logic, "setcountdowntimer", "99999", 0, null, null);
        SetPropFloat(water_lod_control, "m_flCheapWaterStartDistance", 1);
        isHudVisible = true;
    }
    SetPropInt(pd_logic, "m_nBlueTargetPoints", barValue);
}

//=================================================================
//Carrier Misc
//=================================================================

denyEjectPos <- Entities.FindByName(null, "boss_pit_exit").GetOrigin();
carrierUnstuckPos <- Entities.FindByName(null, "boss_tele_unstuck").GetOrigin();
lastFootstepTS <- Time();

function EjectInvalidCarrier(player)
{
    if (player == carrier)
        return;
    if (IsValidPlayer(carrier))
        player.Teleport(true, denyEjectPos, false, QAngle(), true, Vector(0, 0, 0));
    else
        EntFireByHandle(self, "RunScriptCode", "if (activator != carrier) activator.Teleport(true, denyEjectPos, false, QAngle(), true, Vector(0, 0, 0));", 0.2, player, player);
}

function ProcessFootSteps()
{
    local time = Time();
    if (carrier.GetPlayerClass() != TF_CLASS_MEDIC && time > lastFootstepTS && carrier.GetAbsVelocity().Length() > 100)
    {
        lastFootstepTS = time + 0.45;
        local params = PlayDistantSound(carrier, {
            sound_name = "MVM.GiantHeavyStep2",
            entity = carrier,
            filter_type = RECIPIENT_FILTER_PAS_ATTENUATION,
            sound_level = 150,
            channel = 6,
            volume = 0.7,
            pitch = 1.0
        });
        params.sound_name = "MVM.GiantHeavyStep3";
        params.filter_type = RECIPIENT_FILTER_SINGLE_PLAYER;
        params.sound_level = 100;
        EmitSoundEx(params);
    }
}

function PreventCarrierFromTele()
{
    local carrierPos = carrier.GetOrigin();
    for(local teleporter = null; teleporter = Entities.FindByClassname(teleporter, "obj_teleporter");)
    {
        SetPropBool(teleporter, "m_bForcePurgeFixedupStrings", true);
        if (teleporter.GetTeam() != TF_TEAM_BLUE || GetPropInt(teleporter, "m_iObjectMode") == 1)
            continue;
        if ((carrierPos - teleporter.GetOrigin()).Length() < 180)
            EntFireByHandle(teleporter, "Disable", "", 0, null, null);
        else if (GetPropBool(teleporter, "m_bDisabled"))
            EntFireByHandle(teleporter, "Enable", "", 0, null, null);
    }
}

function ProcessCarrierBeingStuck()
{
    if (IsValidPlayer(carrier) && GetPropInt(carrier, "m_StuckLast") > 1)
        carrier.Teleport(true, carrierUnstuckPos, false, QAngle(), true, Vector());
}

function ShootGibs(origin, classIndex, humanGibs)
{
    local gibSpawner = SpawnEntityFromTable("env_shooter",
    {
        spawnflags = 5,
        m_iGibs = 1,
        m_flVelocity = humanGibs ? 1009 : 200,
        m_flVariance = 1,
        m_flGibLife = 5,
        shootsounds = 3,
        simulation = 1,
        skin = 1,
        nogibshadows = true
    })
    gibSpawner.SetAbsOrigin(origin);
    gibSpawner.SetAbsAngles(QAngle(-90, 0, 0));
    EntFireByHandle(gibSpawner, "Kill", "", 2, null, null);
    SetPropBool(gibSpawner, "m_bForcePurgeFixedupStrings", true);

    local gibArray = humanGibs ? GIBS_HUMAN[classIndex] : GIBS_BOTS[classIndex];
    for (local i = 0, len = gibArray.len(); i < len; i++)
    {
        EntFireByHandle(gibSpawner, "AddOutput", "shootmodel " + gibArray[i], 0.1 * i, null, null);
        EntFireByHandle(gibSpawner, "Shoot", "", 0.1 * i, null, null);
    }
}

//=================================================================
//Gamemode Stuff
//=================================================================

if (IsInWaitingForPlayers())
    DoEntFire("blu_spawn_door_*", "Open", "", 1, null, null);

DoEntFire("boss_flag", "RunScriptCode", "self.SetSize(Vector(-60, -60, -60), Vector(60, 60, 10))", 1, null, null);

tf_gamerules <- Entities.FindByClassname(null, "tf_gamerules");
bombArertTimeStamp <- 0;
carrierDownTimeStamp <- 0;
ForceEscortPushLogic(2);

function PlayBombAlertVO()
{
    if (Time() - bombArertTimeStamp < 20)
        return;
    bombArertTimeStamp = Time();
    EntFireByHandle(tf_gamerules, "PlayVORed", "Announcer.Carrier_Alert_Red", 0, null, null);
    EntFireByHandle(tf_gamerules, "PlayVOBlue", "Announcer.Carrier_Alert_Blue", 0, null, null);
}

function PlayCarrierDownVO()
{
    if (Time() - carrierDownTimeStamp < 20 || GetPropInt(tf_gamerules, "m_iRoundState") >= 5)
        return;
    carrierDownTimeStamp = Time();
    EntFireByHandle(tf_gamerules, "PlayVORed", "Announcer.Carrier_Destroyed", 0, null, null);
}

function PlayDistantSound(speaker, params)
{
    local restore = {};
    local origin = carrier.GetOrigin();
    for (local listener = null; listener = Entities.FindByClassnameWithin(listener, "player", origin, 1700);)
    {
        SetPropBool(listener, "m_bForcePurgeFixedupStrings", true);
        restore[listener] <- GetPropVector(listener, "m_vecViewOffset");
        SetPropVector(listener, "m_vecViewOffset", listener != speaker ? origin - listener.GetOrigin() : Vector(9999, 9999, 9999));
    }
    EmitSoundEx(params);
    params.volume *= 0.5;
    EmitSoundEx(params);
    foreach (listener, offset in restore)
        SetPropVector(listener, "m_vecViewOffset", offset);
    return params;
}

//=================================================================
//Misc
//=================================================================

function GetREDPlayerCounter()
{
    local counter = 0;
    for (local i = 1; i <= MAX_CLIENTS; i++)
    {
        local player = PlayerInstanceFromIndex(i);
        if (player && player.GetTeam() == TF_TEAM_RED)
            counter++;
    }
    return counter;
}

function IsValidPlayer(player)
{
    try
    {
        return player && player.IsValid() && player.IsPlayer() && player.GetTeam() > 1;
    }
    catch(e)
    {
        return false;
    }
}

function clamp(value, min, max)
{
    if (value < min)
        return min;
    if (value > max)
        return max;
    return value;
}

function KillIfValid(entity)
{
    if (entity && entity.IsValid())
        entity.Kill();
    return null;
}

function Think()
{
    ProcessBossBar();
    if (IsValidPlayer(carrier) && carrier.IsAlive())
    {
        ProcessCarrierTaunts();
        ProcessCarrierRobotVoice();
        ProcessFootSteps();
        PreventCarrierFromTele();
    }
    return -1;
}

::carrierListener <- {};

carrierListener.OnGameEvent_teamplay_flag_event <- function(params)
{
    local player = "player" in params ? PlayerInstanceFromIndex(params.player) : null;
    if (!IsValidPlayer(player))
        return;
    if (params.eventtype == 4)
        player.TakeDamageCustom(player, player, null, Vector(), Vector(), 99999, 0, TF_DMG_CUSTOM_TELEFRAG);
    if (params.eventtype == 1)
        ConvertToCarrier(player);
}.bindenv(this);

carrierListener.OnGameEvent_player_death <- function(params)
{
    local player = "userid" in params ? GetPlayerFromUserID(params.userid) : null;
    if (carrier && player == carrier && IsValidPlayer(player))
        CarrierDied("attacker" in params && params.attacker != params.userid);
}.bindenv(this);

carrierListener.OnGameEvent_player_spawn <- function(params)
{
    local player = "userid" in params ? GetPlayerFromUserID(params.userid) : null;
    if (IsValidPlayer(player))
        RevertCarrierConversion(player);
}.bindenv(this);

__CollectGameEventCallbacks(carrierListener);

//=================================================================
//Constants
//=================================================================

BOSS_ICONS <- [
    "../hud/leaderboard_class_scout",
    "../hud/leaderboard_class_scout",
    "../hud/leaderboard_class_sniper",
    "../hud/leaderboard_class_soldier",
    "../hud/leaderboard_class_demo",
    "../hud/leaderboard_class_medic",
    "../hud/leaderboard_class_heavy",
    "../hud/leaderboard_class_pyro",
    "../hud/leaderboard_class_spy",
    "../hud/leaderboard_class_engineer"
];

BOT_MODELS <- [
    "models/bots/scout/bot_scout.mdl",
    "models/bots/scout/bot_scout.mdl",
    "models/bots/sniper/bot_sniper.mdl",
    "models/bots/soldier/bot_soldier.mdl",
    "models/bots/demo/bot_demo.mdl",
    "models/bots/medic/bot_medic.mdl",
    "models/bots/heavy/bot_heavy.mdl",
    "models/bots/pyro/bot_pyro.mdl",
    "models/bots/spy/bot_spy.mdl",
    "models/bots/engineer/bot_engineer.mdl",
];

BOT_VOICE_PITCH <- [
    100  //GENERIC
    100  //SCOUT
    85   //SNIPER
    100  //SOLDIER
    100  //DEMO
    75   //MEDIC
    100  //HEAVY
    100  //PYRO
    85   //SPY
    75   //ENGINEER
];

GIBS_HUMAN <- [
    ["models/player/gibs/gibs_can.mdl"],
    ["models/player/gibs/scoutgib001.mdl", "models/player/gibs/scoutgib002.mdl", "models/player/gibs/scoutgib003.mdl", "models/player/gibs/scoutgib004.mdl", "models/player/gibs/scoutgib005.mdl", "models/player/gibs/scoutgib006.mdl", "models/player/gibs/scoutgib007.mdl", "models/player/gibs/scoutgib008.mdl", "models/player/gibs/scoutgib009.mdl"],
    ["models/player/gibs/snipergib001.mdl", "models/player/gibs/snipergib002.mdl", "models/player/gibs/snipergib003.mdl", "models/player/gibs/snipergib004.mdl", "models/player/gibs/snipergib005.mdl", "models/player/gibs/snipergib006.mdl", "models/player/gibs/snipergib007.mdl"],
    ["models/player/gibs/soldiergib001.mdl", "models/player/gibs/soldiergib002.mdl", "models/player/gibs/soldiergib003.mdl", "models/player/gibs/soldiergib004.mdl", "models/player/gibs/soldiergib005.mdl", "models/player/gibs/soldiergib006.mdl", "models/player/gibs/soldiergib007.mdl", "models/player/gibs/soldiergib008.mdl"],
    ["models/player/gibs/demogib001.mdl", "models/player/gibs/demogib002.mdl", "models/player/gibs/demogib003.mdl", "models/player/gibs/demogib004.mdl", "models/player/gibs/demogib005.mdl", "models/player/gibs/demogib006.mdl"],
    ["models/player/gibs/medicgib001.mdl", "models/player/gibs/medicgib002.mdl", "models/player/gibs/medicgib003.mdl", "models/player/gibs/medicgib004.mdl", "models/player/gibs/medicgib005.mdl", "models/player/gibs/medicgib006.mdl", "models/player/gibs/medicgib007.mdl", "models/player/gibs/medicgib008.mdl"],
    ["models/player/gibs/heavygib001.mdl", "models/player/gibs/heavygib002.mdl", "models/player/gibs/heavygib003.mdl", "models/player/gibs/heavygib004.mdl", "models/player/gibs/heavygib005.mdl", "models/player/gibs/heavygib006.mdl", "models/player/gibs/heavygib007.mdl"],
    ["models/player/gibs/pyrogib001.mdl", "models/player/gibs/pyrogib002.mdl", "models/player/gibs/pyrogib003.mdl", "models/player/gibs/pyrogib004.mdl", "models/player/gibs/pyrogib005.mdl", "models/player/gibs/pyrogib006.mdl", "models/player/gibs/pyrogib007.mdl", "models/player/gibs/pyrogib008.mdl"],
    ["models/player/gibs/spygib001.mdl", "models/player/gibs/spygib002.mdl", "models/player/gibs/spygib003.mdl", "models/player/gibs/spygib004.mdl", "models/player/gibs/spygib005.mdl", "models/player/gibs/spygib006.mdl", "models/player/gibs/spygib007.mdl"],
    ["models/player/gibs/engineergib001.mdl", "models/player/gibs/engineergib002.mdl", "models/player/gibs/engineergib003.mdl", "models/player/gibs/engineergib004.mdl", "models/player/gibs/engineergib005.mdl", "models/player/gibs/engineergib006.mdl", "models/player/gibs/engineergib007.mdl"]
];

GIBS_BOTS <- [
    ["models/player/gibs/gibs_can.mdl"],
    ["models/bots/gibs/scoutbot_gib_boss_arm1.mdl", "models/bots/gibs/scoutbot_gib_boss_arm2.mdl", "models/bots/gibs/scoutbot_gib_boss_chest.mdl", "models/bots/gibs/scoutbot_gib_boss_head.mdl", "models/bots/gibs/scoutbot_gib_boss_leg1.mdl", "models/bots/gibs/scoutbot_gib_boss_leg2.mdl", "models/bots/gibs/scoutbot_gib_boss_pelvis.mdl"],
    ["models/bots/gibs/scoutbot_gib_boss_arm1.mdl", "models/bots/gibs/scoutbot_gib_boss_arm2.mdl", "models/bots/gibs/scoutbot_gib_boss_chest.mdl", "models/bots/gibs/sniperbot_gib_head.mdl", "models/bots/gibs/scoutbot_gib_boss_leg1.mdl", "models/bots/gibs/scoutbot_gib_boss_leg2.mdl", "models/bots/gibs/scoutbot_gib_boss_pelvis.mdl"],
    ["models/bots/gibs/soldierbot_gib_boss_arm1.mdl", "models/bots/gibs/soldierbot_gib_boss_arm2.mdl", "models/bots/gibs/soldierbot_gib_boss_chest.mdl", "models/bots/gibs/soldierbot_gib_boss_head.mdl", "models/bots/gibs/soldierbot_gib_boss_leg1.mdl", "models/bots/gibs/soldierbot_gib_boss_leg2.mdl", "models/bots/gibs/soldierbot_gib_boss_pelvis.mdl"],
    ["models/bots/gibs/demobot_gib_boss_arm1.mdl", "models/bots/gibs/demobot_gib_boss_arm2.mdl", "models/bots/gibs/demobot_gib_boss_leg3.mdl", "models/bots/gibs/demobot_gib_boss_head.mdl", "models/bots/gibs/demobot_gib_boss_leg1.mdl", "models/bots/gibs/demobot_gib_boss_leg2.mdl", "models/bots/gibs/demobot_gib_boss_pelvis.mdl"],
    ["models/bots/gibs/scoutbot_gib_boss_arm1.mdl", "models/bots/gibs/scoutbot_gib_boss_arm2.mdl", "models/bots/gibs/scoutbot_gib_boss_chest.mdl", "models/bots/gibs/medicbot_gib_head.mdl", "models/bots/gibs/scoutbot_gib_boss_leg1.mdl", "models/bots/gibs/scoutbot_gib_boss_leg2.mdl", "models/bots/gibs/scoutbot_gib_boss_pelvis.mdl"],
    ["models/bots/gibs/heavybot_gib_boss_arm.mdl", "models/bots/gibs/heavybot_gib_boss_arm2.mdl", "models/bots/gibs/heavybot_gib_boss_chest.mdl", "models/bots/gibs/heavybot_gib_boss_head.mdl", "models/bots/gibs/heavybot_gib_boss_leg.mdl", "models/bots/gibs/heavybot_gib_boss_leg2.mdl", "models/bots/gibs/heavybot_gib_boss_pelvis.mdl"],
    ["models/bots/gibs/pyrobot_gib_boss_arm1.mdl", "models/bots/gibs/pyrobot_gib_boss_arm2.mdl","models/bots/gibs/pyrobot_gib_boss_arm3.mdl","models/bots/gibs/pyrobot_gib_boss_chest.mdl","models/bots/gibs/pyrobot_gib_boss_chest2.mdl","models/bots/gibs/pyrobot_gib_boss_head.mdl","models/bots/gibs/pyrobot_gib_boss_leg.mdl","models/bots/gibs/pyrobot_gib_boss_pelvis.mdl",],
    ["models/bots/gibs/scoutbot_gib_boss_arm1.mdl", "models/bots/gibs/scoutbot_gib_boss_arm2.mdl", "models/bots/gibs/scoutbot_gib_boss_chest.mdl", "models/bots/gibs/spybot_gib_head.mdl", "models/bots/gibs/scoutbot_gib_boss_leg1.mdl", "models/bots/gibs/scoutbot_gib_boss_leg2.mdl", "models/bots/gibs/scoutbot_gib_boss_pelvis.mdl"],
    ["models/bots/gibs/scoutbot_gib_boss_arm1.mdl", "models/bots/gibs/scoutbot_gib_boss_arm2.mdl", "models/bots/gibs/scoutbot_gib_boss_chest.mdl", "models/bots/gibs/scoutbot_gib_boss_head.mdl", "models/bots/gibs/scoutbot_gib_boss_leg1.mdl", "models/bots/gibs/scoutbot_gib_boss_leg2.mdl", "models/bots/gibs/scoutbot_gib_boss_pelvis.mdl"]
];

foreach (gibArray in GIBS_HUMAN)
    foreach (gib in gibArray)
        PrecacheModel(gib);
foreach (gibArray in GIBS_BOTS)
    foreach (gib in gibArray)
        PrecacheModel(gib);
foreach (robotModel in BOT_MODELS)
    PrecacheModel(robotModel);

HUMAN_SCREAM <- [
    "Scout.CritDeath",
    "Scout.CritDeath",
    "Sniper.CritDeath",
    "Soldier.CritDeath",
    "Demoman.CritDeath",
    "Medic.CritDeath",
    "Heavy.CritDeath",
    "Pyro.CritDeath",
    "Spy.CritDeath",
    "Engineer.CritDeath"
];

foreach (sound in HUMAN_SCREAM)
    PrecacheScriptSound(sound);

PrecacheScriptSound("Announcer.Carrier_Destroyed");
PrecacheScriptSound("Announcer.Carrier_Alert_Red");
PrecacheScriptSound("Announcer.Carrier_Alert_Blue");
PrecacheScriptSound("MVM.GiantHeavyStep2");
PrecacheScriptSound("MVM.GiantHeavyStep3");
PrecacheSound("ambient/alarms/klaxon1.wav");
PrecacheSound(")ambient/explosions/explode_2.wav");
PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = "fireSmokeExplosion_track" });