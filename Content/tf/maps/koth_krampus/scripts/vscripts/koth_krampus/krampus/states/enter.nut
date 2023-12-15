//=========================================================================
//Copyright LizardOfOz.
//=========================================================================

::PreEnterState <- class extends State
{
    name = "enter"; //not a bug, it IS intended to be called "enter" and not "preenter"
    bossSpawnOrigin = Entities.FindByName(null, "boss_spawn").GetOrigin();

    function Think()
    {
        if (tick == 0)
        {
            krampus.ResetSequence(krampus.LookupSequence("krampus_jump_loop"));
            krampus.SetPlaybackRate(KRAMPUS_ANIM_RATE);
            krampusScript.SetStraightPath(bossSpawnOrigin);
            krampusScript.krampusCoalTossCounter = 0;
            krampusScript.krampusBarrageCounter = 0;
        }
        if (tick > 50 && tick < 155)
        {
            krampus.SetAbsOrigin(krampusOrigin + Vector(0, -4.0, 16.5));
            krampusScript.MoveByCurrentPath(1);
        }
        if (tick == 143)
        {
            krampus.ResetSequence(krampus.LookupSequence("krampus_jump_end"));
            krampus.SetCycle(0.1);
            krampus.SetPlaybackRate(0.2);
        }
        if (tick == 165)
        {
            if ((krampusOrigin - bossSpawnOrigin).Length() > 150)
            {
                krampus.SetAbsOrigin(bossSpawnOrigin);
                krampus.SetAbsVelocity(Vector(0, 0, 0));
            }
            krampusScript.SetState(EnterState());
        }
    }
}

::EnterState <- class extends State
{
    name = "enter";
    bossJumpStartOrigin = Entities.FindByName(null, "boss_jump_start").GetOrigin();
    bossJumpEndOrigin = Entities.FindByName(null, "boss_jump_end").GetOrigin();

    function Think()
    {
        if (tick == 0)
        {
            krampus.ResetSequence(krampus.LookupSequence("krampus_walk"));
            krampus.SetPlaybackRate(KRAMPUS_ANIM_RATE);
            krampusScript.SetStraightPath(bossJumpStartOrigin);
        }
        if (tick < 420)
            krampusScript.MoveByCurrentPath(140);
        if (tick == 365)
        {
            local sound = krampusSpawnCounter == 1 ? VO_SPAWN_1 : krampusSpawnCounter == 2 ? VO_SPAWN_2 : VO_SPAWN_3;
            EmitGlobalSound(PickRandomSound(sound));
        }
        if (tick == 414)
        {
            krampus.ResetSequence(krampus.LookupSequence("krampus_idle"));
        }
        if (tick == 613)
        {
            if ((krampusOrigin - bossJumpStartOrigin).Length() > 150)
            {
                krampus.SetAbsOrigin(bossJumpStartOrigin);
                krampus.SetAbsVelocity(Vector(0, 0, 0));
            }

            EntFireByHandle(krampus, "SetStepHeight", "1", -1, null, null)
            krampus.ResetSequence(krampus.LookupSequence("krampus_jump_start"));
            krampusScript.SetStraightPath(bossJumpEndOrigin);
            krampus.SetCycle(0);
        }
        if (tick > 645 && tick < 790)
        {
            krampus.SetAbsOrigin(krampusOrigin + Vector(0, -2.7, 8));
            krampusScript.MoveByCurrentPath();
        }
        if (tick == 665)
            krampus.ResetSequence(krampus.LookupSequence("krampus_jump_loop"));
        if (tick == 788)
        {
            krampus.ResetSequence(krampus.LookupSequence("krampus_jump_end"));
            krampus.SetCycle(0);
        }
        if (tick == 795)
        {
            for(local i = 0; i <= 6; i += 6)
                EmitSoundEx({
                    sound_name = "Taunt.YetiLand",
                    filter = RECIPIENT_FILTER_GLOBAL
                    volume = 1,
                    soundlevel = 150,
                    flags = 1,
                    channel = i
                });
            EmitSoundEx({
                sound_name = "Taunt.YetiLand",
                filter = RECIPIENT_FILTER_GLOBAL
                entity = krampus,
                volume = 1,
                soundlevel = 150,
                flags = 1,
                channel = 0
            });
            ScreenShake(krampusOrigin, 10, 32, 1, 5500, 0, true);
            ScreenShake(krampusOrigin, 10, 32, 1, 5500, 0, true);
            DispatchParticleEffect("hammer_impact_button", krampusOrigin, Vector(0,0,0));
            CreateAoE(krampusOrigin, 500,
                function (target, unitVector, distance, height) {
                    local pushForce = distance < 100 ? 1 : 100 / distance;
                    target.Yeet(Vector(
                        unitVector.x * 1250 * pushForce,
                        unitVector.y * 1250 * pushForce,
                        pushForce));
                });
            local stickiesToKill = [];
            for(local sticky = null; sticky = Entities.FindByClassnameWithin(sticky, "tf_projectile_pipe_remote", krampusOrigin, 250);)
                stickiesToKill.push(sticky);
            foreach (sticky in stickiesToKill)
                sticky.Kill();

            EntFireByHandle(team_control_point, "SetLocked", "1", -1, null, null);
            EntFireByHandle(main_script.GetActiveTimer(), "pause", "", -1, null, null);
        }
        if (tick >= 795 && (krampusOrigin - bossJumpEndOrigin).Length() > 150)
        {
            krampus.SetAbsOrigin(bossJumpEndOrigin);
            krampus.SetAbsVelocity(Vector(0, 0, 0));
        }
        if (tick == 845)
        {
            krampusScript.SetNewTarget(krampusScript.PickTarget());
            EntFireByHandle(krampus, "SetStepHeight", "50", -1, null, null);
            krampusScript.SetState(RunState());
            ClientPrint(null, HUD_PRINTTALK, "#koth_krampus_spawn");
        }
    }
}