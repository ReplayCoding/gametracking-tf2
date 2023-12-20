//=========================================================================
//Copyright LizardOfOz.
//=========================================================================

ClearGameEventCallbacks();

IncludeScript("koth_krampus/__lizardlib/util.nut");
IncludeScript("koth_krampus/config.nut");
IncludeScript("koth_krampus/entities.nut");
IncludeScript("koth_krampus/bossbar.nut");

SetPropInt(tf_gamerules, "m_nGameType", 2);
EntFireByHandle(self, "RunScriptCode", "SpawnKrampus()", KRAMPUS_FIRST_SPAWN_DELAY, null, null);
EntFireByHandle(team_control_point, "SetLocked", "1", -1, null, null);

::krampusLauncher <- null;
::krampusDeathTimeStamp <- -120;
::krampusSpawnCounter <- 0;
::shouldKrampusBePresent <- false;

function Think()
{
    if (krampusSpawnCounter >= 3)
        return 999999;
    KrampusFailsafe();
    local timer = GetActiveTimer();
    if (GetPropBool(timer, "m_bTimerPaused"))
        return 0.5;
    EntFireByHandle(timer, "pause", "", -1, null, null);
    EntFireByHandle(timer, "resume", "", -1, null, null);
    local timeRemaining = GetPropFloat(timer, "m_flTimeRemaining");
    if (timeRemaining <= 106 && timeRemaining >= 103 && (krampusSpawnCounter == 1 || Time() - krampusDeathTimeStamp > 100))
        SpawnKrampus();
    return 0.5;
}

function GetActiveTimer()
{
    if (team_control_point.GetTeam() == TF_TEAM_RED)
        return zz_red_koth_timer;
    if (team_control_point.GetTeam() == TF_TEAM_BLUE)
        return zz_blue_koth_timer;
    return tf_gamerules;
}

function SpawnKrampus()
{
    if (IsInWaitingForPlayers() || krampusSpawnCounter++ >= 3 || krampus)
        return;

	krampus = SpawnEntityFromTable("base_boss",
	{
		origin = spawn_point.GetOrigin(),
        angles = spawn_point.GetAbsAngles(),
        vscripts = "koth_krampus/krampus/krampus.nut",
        thinkfunction = "KrampusThink",
		playbackrate = 1.0,
        targetname = "krampus",
        TeamNum = 5
	});
    local health = 1000 + KRAMPUS_HEALTH_BASE + KRAMPUS_HEALTH_ADD_PER_PLAYER * GetAllPlayers().len();
    krampus.SetHealth(health);
    krampus.SetModelScale(KRAMPUS_SCALE, -1);
    krampus.SetMaxHealth(health);
    krampus.SetModelSimple(KRAMPUS_MODEL);
    krampus.ResetSequence(krampus.LookupSequence("krampus_idle"));
    krampus.SetPlaybackRate(1.0);
    krampusScript = krampus.GetScriptScope();

    krampusDeathTimeStamp = Time();
    shouldKrampusBePresent = true;

    return krampus;
}

function KrampusFailsafe()
{
    if (shouldKrampusBePresent && (!krampus || !krampus.IsValid()))
    {
        shouldKrampusBePresent = false;
        krampus = null;
        EntFireByHandle(team_control_point, "SetLocked", "0", -1, null, null);
        EntFireByHandle(GetActiveTimer(), "resume", "", -1, null, null);
        SetBossBarValue(0);
    }
}

function OnScriptHook_OnTakeDamage(params)
{
    if (params.const_entity == krampus)
    {
        if (!krampusScript.IsActive())
        {
            params.damage = 0;
            params.early_out = true;
            return;
        }
        if (params.damage >= params.const_entity.GetHealth() - 1000)
        {
            krampusScript.SetState(DeathState());
            params.damage = 0;
            params.early_out = true;
        }
        if (IsValidPlayer(params.attacker))
        {
            local playerClass = params.attacker.GetPlayerClass();
            if (playerClass == TF_CLASS_HEAVYWEAPONS || (playerClass == TF_CLASS_ENGINEER && params.inflictor != params.attacker))
                params.damage *= 0.6;
        }

        return;
    }

    //In other words, it's a Krampus' coal projectile
	if (params.inflictor && params.inflictor != krampus && params.attacker.GetTeam() == 5 && IsValidPlayer(params.const_entity))
        params.const_entity.IgnitePlayer();

    //Anti-crush measures
	if (params.damage == 99999.9 && (params.damage_type & DMG_CRUSH) && IsValidPlayer(params.const_entity))
	{
		params.damage = 0;
		params.early_out = true;
	}
}

function OnGameEvent_player_death(params)
{
    local inflictor = EntIndexToHScript(params.inflictor_entindex)
    if (inflictor && krampus && (inflictor == krampus || inflictor.GetOwner() == krampusLauncher))
    {
        local player = GetPlayerFromUserID(params.userid);
        if (player)
            SetPropEntity(player, "m_hObserverTarget", null);

        if (RandomInt(1, 4) == 1)
            EmitGlobalSound(PickRandomSound(VO_ONKILL));
    }
}

__CollectGameEventCallbacks(this);
__CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);