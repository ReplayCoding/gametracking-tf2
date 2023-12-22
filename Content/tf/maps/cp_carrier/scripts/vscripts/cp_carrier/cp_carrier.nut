//=========================================================================
//Copyright LizardOfOz.
//=========================================================================

::carrier <- null;

IncludeScript("cp_carrier/util.nut");
IncludeScript("cp_carrier/entities.nut");
IncludeScript("cp_carrier/config.nut");
IncludeScript("cp_carrier/events.nut");
IncludeScript("cp_carrier/bossbar.nut");

::bombDropTimeStamp <- Time();
::bombArertTimeStamp <- Time();
::carrierDownTimeStamp <- Time();
::tauntFlag <- false;

DoEntFire("taunt_fix_cosmetic", "Kill", "", 0, null, null);

function TryMakingIntoRobot(player)
{
    if (IsValidPlayer(carrier) && player != carrier)
    {
        player.Teleport(true, boss_pit_exit, false, QAngle(), true, Vector(0, 0, 0));
        return;
    }
    player.SetCustomModelWithClassAnimations(BOT_MODELS[clamp(activator.GetPlayerClass(), 0, 9)]);
    local delay = player.GetAbsVelocity().z < -400 ? 0.2 : 0.5;
    RunWithDelay(this, delay, function() {
        if (carrier != player)
        {
            player.SetCustomModelWithClassAnimations("");
            player.Teleport(true, boss_pit_exit, false, QAngle(), true, Vector(0, 0, 0));
        }
    });
}

function TurnIntoFlagCarrier(player)
{
    carrier = player;
    local playerClass = player.GetPlayerClass();
    local classIndex = clamp(playerClass, 0, 9);
    player.KeyValueFromString("targetname", "carrier");
    player.SetModelScale(3, -1);
    player.Teleport(true, boss_tele_dest.GetOrigin(), false, QAngle(), true, Vector(0, 0, 0));

    player.AddCustomAttribute("patient overheal penalty", 1, -1);
    player.AddCustomAttribute("override footstep sound set", 7, -1);
    player.AddCustomAttribute("damage force reduction", 0.25, -1);
    player.AddCustomAttribute("health from packs decreased", 0.05, -1);
    player.AddCustomAttribute("cloak consume rate increased", 9999, -1);
    player.AddCustomAttribute("voice pitch scale", 0.6, -1);
    player.AddCustomAttribute("cannot be backstabbed", 1, -1);
    player.AddCustomAttribute("airblast vulnerability multiplier", 0, -1);
    player.AddCustomAttribute("move speed penalty", 0.5, -1);
    player.AddCustomAttribute("taunt force weapon slot", 1, -1);
    player.AddCustomAttribute("cancel falling damage", 1, -1);
    player.AddCustomAttribute("reduced_healing_from_medics", 0.25, -1);
    player.AddCustomAttribute("patient overheal penalty", 0, -1);
    player.AddCustomAttribute("ammo regen", 1, -1);
    player.AddCustomAttribute("dmg taken from crit reduced", 0.75, -1);
    player.AddCond(Constants.ETFCond.TF_COND_OFFENSEBUFF);
    player.SetGravity(playerClass == Constants.ETFClass.TF_CLASS_MEDIC ? 3 : 2);

    local classStockHP = player.GetHealth();
    local carrierMaxHP = 3000 + 125 * GetREDPlayerCounter();

    player.SetHealth(carrierMaxHP);
    player.SetMaxHealth(carrierMaxHP);
    player.RemoveCustomAttribute("max health additive bonus");
    player.AddCustomAttribute("max health additive bonus", carrierMaxHP - classStockHP, -1);

    local itemsToKill = [];
    for (local item = player.FirstMoveChild(); item != null; item = item.NextMovePeer())
        if (item.GetClassname() == "tf_wearable")
            itemsToKill.push(item);
    foreach (item in itemsToKill)
        item.Kill();

    ShootGibs(player.GetCenter(), classIndex, true);

    for(local i = 0; i <= 6; i+=6)
        EmitSoundEx({
            sound_name = "ambient/alarms/klaxon1.wav",
            volume = 1,
            filter = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_GLOBAL
            soundlevel = 150,
            flags = 1,
            channel = i
        });

    EmitSoundEx({
        sound_name = HUMAN_SCREAM[classIndex],
        volume = 1,
        soundlevel = 150,
        flags = 1,
        channel = 0,
        origin = player.GetOrigin()
    });

    UpdateBossBarClass(player);
    DoEntFire("bomb_sprite", "HideSprite", "", -1, null, null);
    DoEntFire("boss_elevator_train", "StartForward", "", 0.5, null, null);
    DoEntFire("boss_exit_door", "Open", "", 1, null, null);
    RunWithDelay(this, 4, function(player)
    {
        if (player == carrier)
        {
            DoEntFire("stuck_fix", "Enable", "", -1, null, null);
            DoEntFire("stuck_fix", "Disable", "", 1, null, null);
        }
    }, player);
    DoEntFire("flag_picked", "Trigger", "", 0, null, null);
}

function PreventCarrierFromTele()
{
    local carrierPos = carrier.GetOrigin();
    for(local teleporter = null; teleporter = Entities.FindByClassname(teleporter, "obj_teleporter");)
    {
        if (teleporter.GetTeam() != Constants.ETFTeam.TF_TEAM_BLUE || NetProps.GetPropInt(teleporter, "m_iObjectMode") == 1)
            continue;
        if ((carrierPos - teleporter.GetOrigin()).Length() < 180)
            EntFireByHandle(teleporter, "Disable", "", 0, null, null);
        else if (NetProps.GetPropBool(teleporter, "m_bDisabled"))
            EntFireByHandle(teleporter, "Enable", "", 0, null, null);
    }
}

function ProcessCarrierTaunts()
{
    local isTaunting = carrier.InCond(Constants.ETFCond.TF_COND_TAUNTING) || carrier.GetActiveWeapon().GetClassname() == "tf_weapon_rocketpack";
    if (isTaunting && !tauntFlag)
    {
        tauntFlag = true;
        item_teamflag.SetModelScale(0.01, -1);
        carrier.SetCustomModelWithClassAnimations("");
        NetProps.SetPropInt(carrier, "m_nRenderMode", 1);
        NetProps.SetPropInt(carrier, "m_clrRender", 1);

        local cosmetic = SpawnEntityFromTable("tf_wearable", {
            targetname = "taunt_fix_cosmetic"
        });
        cosmetic.SetModel(BOT_MODELS[clamp(carrier.GetPlayerClass(), 0, 9)]);
        EntFireByHandle(cosmetic, "SetParent", "!activator", 0, carrier, carrier);
        NetProps.SetPropEntity(cosmetic, "m_hOwnerEntity", carrier);

        cosmetic = SpawnEntityFromTable("prop_dynamic", {
            targetname = "taunt_fix_cosmetic"
        });
        cosmetic.SetModel(item_teamflag.GetModelName());
        cosmetic.SetModelScale(3, -1);
        EntFireByHandle(cosmetic, "SetParent", "!activator", 0, carrier, carrier);
        EntFireByHandle(cosmetic, "SetParentAttachment", "flag", 0, carrier, carrier);
        NetProps.SetPropEntity(cosmetic, "m_hOwnerEntity", carrier);
    }
    else if (!isTaunting && tauntFlag)
    {
        tauntFlag = false;
        DoEntFire("taunt_fix_cosmetic", "Kill", "", 0, null, null);
        carrier.SetCustomModelWithClassAnimations(BOT_MODELS[clamp(carrier.GetPlayerClass(), 0, 9)]);
        item_teamflag.SetModelScale(3, -1);
        NetProps.SetPropInt(carrier, "m_nRenderMode", 0);
        NetProps.SetPropInt(carrier, "m_clrRender", 0xFFFFFFFF);
    }
}

function CarrierDied(player, isPlayerDeath)
{
    tauntFlag = false;
    DoEntFire("taunt_fix_cosmetic", "Kill", "", 0, null, null);
    item_teamflag.SetModelScale(3, -1);

    DispatchParticleEffect("fireSmokeExplosion_track", player.GetCenter(), Vector(0, 180, 0));
    carrier = null;
    bombDropTimeStamp = Time();
    player.KeyValueFromString("targetname", "");
    player.SetCustomModelWithClassAnimations("");
    EntFireByHandle(self, "RunScriptCode", "local ragdoll = NetProps.GetPropEntity(activator, `m_hRagdoll`); if (ragdoll) ragdoll.Kill();", -1, player, player);
    SetBossBarValue(0);
    ShootGibs(player.GetOrigin(), clamp(player.GetPlayerClass(), 0, 9), false);

    EmitSoundEx({
        sound_name = "ambient/explosions/explode_2.wav",
        volume = 1,
        filter = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_GLOBAL,
        soundlevel = 150,
        flags = 1,
        channel = 0
    });
    if (isPlayerDeath)
        EntFireByHandle(self, "RunScriptCode", "PlayCarrierDownVO()", 0.1, null, null);

    EntFireByHandle(item_teamflag, "ForceReset", "", -1, null, null);
    DoEntFire("bomb_sprite", "ShowSprite", "", -1, null, null);
    DoEntFire("boss_exit_door", "Close", "", 1, null, null);
    DoEntFire("boss_elevator_train", "StartBackward", "", 1, null, null);
    DoEntFire("flag_dropped", "Trigger", "", 0, null, null);
}

function PlayerRespawn(player)
{
    NetProps.SetPropInt(player, "m_nRenderMode", 0);
    NetProps.SetPropInt(player, "m_clrRender", 0xFFFFFFFF);
    player.SetGravity(1);
    player.RemoveCustomAttribute("max health additive bonus");
    player.SetHealth(player.GetMaxHealth());
    player.KeyValueFromString("targetname", "");
    player.SetCustomModelWithClassAnimations("");
}

function ShootGibs(origin, classIndex, humanGibs)
{
    local gibSpawner = SpawnEntityFromTable("env_shooter",
    {
        spawnflags = 5,
        m_iGibs = 1,
        m_flVelocity = humanGibs ? 1009 : 200,
        scale = humanGibs ? 1 : 10,
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

    local gibArray = humanGibs ? GIBS_HUMAN[classIndex] : GIBS_BOTS[classIndex];
    local gibLength = gibArray.len();
    for(local i = 0; i < gibLength; i++)
    {
        EntFireByHandle(gibSpawner, "AddOutput", "shootmodel "+gibArray[i], 0.1 * i, null, null);
        EntFireByHandle(gibSpawner, "Shoot", "", 0.1 * i, null, null);
    }
}

function PlayBombAlertVO()
{
    if (Time() - bombArertTimeStamp < 20)
        return;
    bombArertTimeStamp = Time();
    local redLine = BOMB_ALERT_RED[RandomInt(0, BOMB_ALERT_RED.len() - 1)];
    local bluLine = BOMB_ALERT_BLU[RandomInt(0, BOMB_ALERT_BLU.len() - 1)];
    foreach (player in GetAllPlayers())
        EmitSoundEx({
            sound_name = player.GetTeam() == Constants.ETFTeam.TF_TEAM_RED ? redLine : bluLine,
            filter_type = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_SINGLE_PLAYER,
            volume = 1,
            soundlevel = 150,
            flags = 1,
            channel = 7,
            entity = player
        });
}

function PlayCarrierDownVO()
{
    if (Time() - carrierDownTimeStamp < 20 || NetProps.GetPropInt(tf_gamerules, "m_iRoundState") >= 5)
        return;
    carrierDownTimeStamp = Time();
    local line = CARRIER_DIED_RED[RandomInt(0, CARRIER_DIED_RED.len() - 1)];
    foreach (player in GetAllPlayers())
        if (player.GetTeam() == Constants.ETFTeam.TF_TEAM_RED)
            EmitSoundEx({
                sound_name = line,
                filter_type = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_SINGLE_PLAYER,
                volume = 1,
                soundlevel = 150,
                flags = 1,
                channel = 7,
                entity = player
            });
}