//=========================================================================
//Copyright LizardOfOz.
//=========================================================================

IncludeScript("cp_carrier/util.nut");
IncludeScript("cp_carrier/entities.nut");
IncludeScript("cp_carrier/config.nut");
IncludeScript("cp_carrier/events.nut");

::carrier <- null;

::bombDropTimeStamp <- Time();
::bombArertTimeStamp <- Time();
::carrierDownTimeStamp <- Time();

::CARRIER_HP <- [
    2000,
    2000,
    2000,
    3000,
    3000,
    2000,
    3000,
    2500,
    2000,
    2500
];

function TryMakingIntoRobot(player)
{
    if (IsValidPlayer(carrier) && player != carrier)
    {
        player.Teleport(true, boss_pit_exit, false, QAngle(), true, Vector(0, 0, 0));
        return;
    }
    player.SetCustomModelWithClassAnimations(BOT_MODELS[clamp(activator.GetPlayerClass(), 0, 9)]);
    RunWithDelay(this, 0.2, function() {
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
    player.AddCustomAttribute("damage force reduction", 0.2, -1);
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
    player.AddCond(Constants.ETFCond.TF_COND_ENERGY_BUFF);

    local classStockHP = player.GetHealth();
    local carrierMaxHP = CARRIER_HP[classIndex] + 125 * GetREDPlayerCounter();

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

    if (playerClass == Constants.ETFClass.TF_CLASS_PYRO)
        for (local item = player.FirstMoveChild(); item != null; item = item.NextMovePeer())
            if (item.GetClassname() == "tf_weapon_rocketpack")
            {
                local wasActive = player.GetActiveWeapon() == item;
                item.Kill();
                local newWeapon = GiveWeapon(player, "tf_weapon_shotgun_pyro", 12);
                if (wasActive)
                    player.Weapon_Switch(newWeapon);
                break;
            }
    if (playerClass == Constants.ETFClass.TF_CLASS_SOLDIER || playerClass == Constants.ETFClass.TF_CLASS_DEMOMAN)
        for (local item = player.FirstMoveChild(); item != null; item = item.NextMovePeer())
            if (NetProps.GetPropInt(item, "m_AttributeManager.m_Item.m_iItemDefinitionIndex") == 154) // Pain Train
            {
                local wasActive = player.GetActiveWeapon() == item;
                item.Kill();
                local newWeapon = playerClass == Constants.ETFClass.TF_CLASS_SOLDIER
                    ? GiveWeapon(player, "tf_weapon_shovel", 196)
                    : GiveWeapon(player, "tf_weapon_bottle", 191);
                if (wasActive)
                    player.Weapon_Switch(newWeapon);
                break;
            }

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

function CarrierDied(player, isPlayerDeath)
{
    DispatchParticleEffect("fireSmokeExplosion_track", player.GetCenter(), Vector(0, 180, 0));
    carrier = null;
    bombDropTimeStamp = Time();
    player.KeyValueFromString("targetname", "");
    player.SetCustomModelWithClassAnimations("");
    EntFireByHandle(self, "RunScriptCode", "local ragdoll = NetProps.GetPropEntity(activator, `m_hRagdoll`); if (ragdoll) ragdoll.Kill();", -1, player, player);
    NetProps.SetPropInt(monster_resource, "m_iBossHealthPercentageByte", 0);
    ShootGibs(player.GetOrigin(), clamp(player.GetPlayerClass(), 0, 9), false);

    EmitSoundEx({
        sound_name = "ambient/explosions/explode_2.wav",
        volume = 1,
        filter = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_GLOBAL
        soundlevel = 150,
        flags = 1,
        channel = 0
    });
    if (isPlayerDeath)
        PlayCarrierDownVO();

    EntFireByHandle(item_teamflag, "ForceReset", "", -1, null, null);
    DoEntFire("bomb_sprite", "ShowSprite", "", -1, null, null);
    DoEntFire("boss_exit_door", "Close", "", 1, null, null);
    DoEntFire("boss_elevator_train", "StartBackward", "", 1, null, null);
    DoEntFire("flag_dropped", "Trigger", "", 0, null, null);
}

function PlayerRespawn(player)
{
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
    if (Time() - carrierDownTimeStamp < 20)
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