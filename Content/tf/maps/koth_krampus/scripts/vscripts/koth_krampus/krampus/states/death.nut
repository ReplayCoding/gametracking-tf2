//=========================================================================
//Copyright LizardOfOz.
//=========================================================================

::DeathState <- class extends State
{
    name = "death";

    function Start()
    {
        krampus.SetCycle(0);
        krampus.ResetSequence(krampus.LookupSequence("krampus_death"));

        shouldKrampusBePresent = false;
        SetPropInt(monster_resource, "m_iBossHealthPercentageByte", 1);
        EmitGlobalSound(PickRandomSound(VO_DEATH));
        ClientPrint(null, HUD_PRINTTALK, "#koth_krampus_death");
        SendGlobalGameEvent("halloween_boss_killed", { })
    }

    function Think()
    {
        if (tick == 270)
        {
            krampusDeathTimeStamp = Time();
            local vortex = SpawnEntityFromTable("hightower_teleport_vortex",
            {
                target_base_name = "black_forest",
                origin = krampusOrigin + krampusForwardVector * 75 + Vector(0,0,80),
                lifetime = 12
            });
            EntFireByHandle(vortex, "SetAdvantageTeam", "red", -1, null, null);
            EntFireByHandle(vortex, "Disable", "", -1, null, null);
            EntFireByHandle(vortex, "Enable", "", 0.2, null, null);

            if (krampus_cam && krampus_cam.IsValid())
            {
                krampus_cam.SetAbsOrigin(team_control_point.GetOrigin() + Vector(0, 0, 120));
                EntFireByHandle(krampus_cam, "SetParent", "!activator", -1, team_control_point, team_control_point);
            }
        }

        if (tick == 308)
        {
            DispatchParticleEffect("kr_death_parent", krampusOrigin + krampusForwardVector * 100 + Vector(0, 0, 50), Vector(-90, 0, 0));
            EmitSoundEx({
                sound_name = "Parachute_open",
                origin = krampusOrigin,
                volume = 1,
                soundlevel = 150,
                flags = 1,
                channel = 0
            });

            EntFireByHandle(team_control_point, "SetLocked", "0", -1, null, null);
            EntFireByHandle(main_script.GetActiveTimer(), "resume", "", -1, null, null);

            SetPropInt(monster_resource, "m_iBossHealthPercentageByte", 0);

            krampus.Kill();
            krampus = null;
        }
    }
}