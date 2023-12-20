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
        SetBossBarValue(1);
        EmitGlobalSound(PickRandomSound(VO_DEATH));
        ClientPrint(null, HUD_PRINTTALK, "#koth_krampus_death");
        SendGlobalGameEvent("halloween_boss_killed", { })
        DoEntFire("krampus_death", "Trigger", "", 0, null, null);
    }

    function Think()
    {
        if (tick == 270)
        {
            krampusDeathTimeStamp = Time();

            local particle = SpawnEntityFromTable("info_particle_system", {
                effect_name = "eyeboss_tp_vortex",
                origin = krampusOrigin + krampusForwardVector * 75 + Vector(0,0,80),
                start_active = 1,
                vscripts = "koth_krampus/krampus/vortex.nut",
                thinkfunction = "VortexThink",
            })
            EntFireByHandle(particle, "Kill", "", 12, null, null);
            EntFireByHandle(particle, "RunScriptCode", "PlaySounds()", 0.5, null, null);
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
            SetBossBarValue(0);

            krampus.Kill();
            krampus = null;
        }
    }
}