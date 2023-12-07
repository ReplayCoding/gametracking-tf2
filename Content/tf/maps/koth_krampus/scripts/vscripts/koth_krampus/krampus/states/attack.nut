//=========================================================================
//Copyright LizardOfOz.
//=========================================================================

::AttackState <- class extends State
{
    runAnim = true;
    name = "attack";

    function Start()
    {
        krampus.ResetSequence(krampus.LookupSequence("krampus_run_attack"));
        krampus.SetPlaybackRate(KRAMPUS_ANIM_RATE);
    }

    function Think()
    {
        local isMoving = krampus.GetLocomotionInterface().IsAttemptingToMove();
        if (!runAnim && isMoving)
        {
            runAnim = true;
            krampus.SetSequence(krampus.LookupSequence("krampus_run_attack"));
        }
        if (runAnim && !isMoving)
        {
            runAnim = false;
            krampus.SetSequence(krampus.LookupSequence("krampus_idle_attack"));
        }

        if (tick % 100 == 0)
            krampusScript.needsNewPath = true;
        if (krampusTarget && krampusScript.needsNewPath && tick % 10 == 0)
            krampusScript.SetNewPath(targetOrigin);

        if (tick < 20 || tick > 35)
            krampusScript.MoveByCurrentPath();

        if (tick == 18)
            EmitSoundEx({
                sound_name = "Weapon_PickAxe.Swing",
                entity = krampus,
                volume = 1,
                soundlevel = 150,
                flags = 1,
                channel = 0
            });

        if (tick == 32)
        {
            local forwardVector = Vector(krampusForwardVector.x, krampusForwardVector.y, 0);
            local krampusCenter = krampus.GetCenter();
            CreateAoE(krampusCenter, 300,
                function (target, unitVector, distance, height) {
                    if (height < -150 || height > 200)
                        return;
                    if (forwardVector.Dot(unitVector) < 0.65 && (krampusCenter - target.GetOrigin()).Length2D() > 50)
                        return;
                    local maxHP = target.GetMaxHealth() * 0.33;
                    local isHealed = target.GetHealth() * 2 > maxHP && GetPropInt(target, "m_Shared.m_nNumHealers") > 0
                    target.TakeDamageCustom(
                        krampus,
                        krampus,
                        null,
                        Vector(),
                        Vector(),
                        maxHP * (isHealed ? 0.7 : 0.4),
                        DMG_BULLET | DMG_ACID,
                        0)
                    EmitSoundEx({
                        sound_name = "Wood.Break",
                        entity = target,
                        volume = 1,
                        soundlevel = 150,
                        flags = 1,
                        channel = 0
                    });
                    ScreenShake(target.GetCenter(), 140, 1, 1, 10, 0, true);
                    target.Yeet(Vector(unitVector.x * 300, unitVector.y * 300, 300));
                });
        }
        if (tick >= 50)
            AnimCycleReset();
    }

    function AnimCycleReset()
    {
        if (krampusTarget && (krampusOrigin - targetOrigin).Length() < 200)
            krampusScript.SetState(AttackState());
        else
            krampusScript.SetState(RunState());
    }
}

::CoalThrowState <- class extends State
{
    runAnim = true;
    name = "throw";

    function Start()
    {
        krampus.ResetSequence(krampus.LookupSequence("krampus_run_throw"));
        krampus.SetPlaybackRate(KRAMPUS_ANIM_RATE);
        krampusScript.krampusCoalTossCounter++;
    }

    function Think()
    {
        local isMoving = krampus.GetLocomotionInterface().IsAttemptingToMove();
        if (!runAnim && isMoving)
        {
            runAnim = true;
            krampus.SetSequence(krampus.LookupSequence("krampus_run_throw"));
        }
        if (runAnim && !isMoving)
        {
            runAnim = false;
            krampus.SetSequence(krampus.LookupSequence("krampus_idle_throw"));
        }

        krampusScript.MoveByCurrentPath();

        if (tick == 30)
        {
            krampusLauncher.SetAbsOrigin(
                krampus.EyePosition()
                + Vector(0, 0, 75)
                + krampusForwardVector * 100
                - krampus.GetRightVector() * 25
            );
            krampusLauncher.SetAbsAngles(krampus.EyeAngles());
            EntFireByHandle(krampusLauncher, "FireMultiple", "" + RandomInt(2, 5), -1, krampus, krampus);
        }

        if (tick >= 60)
            AnimCycleReset();
    }

    function AnimCycleReset()
    {
        krampusScript.SetState(RunState());
    }
}

::CoalBarrageState <- class extends State
{
    name = "barrage";

    function Start()
    {
        krampus.SetCycle(0);
        krampus.ResetSequence(krampus.LookupSequence("krampus_volcano_start"));
        krampus.SetPlaybackRate(KRAMPUS_ANIM_RATE);

        krampusScript.krampusBarrageCounter++;
        krampusScript.krampusCoalTossCounter = 0;
        EmitSoundEx({
            sound_name = "ambient/fire/ignite.wav",
            origin = krampusOrigin,
            volume = 1,
            soundlevel = 150,
            flags = 1,
            channel = 0
        });
        EntFireByHandle(krampus, "RunScriptCode", "InitiateCoalBarrage()", 1.1, null, null);
        EmitGlobalSound(PickRandomSound(VO_COAL_BARRAGE));
    }

    function AnimCycleReset()
    {
        if (tick > 150)
            krampusScript.SetState(RunState());
    }
}