//=========================================================================
//Copyright LizardOfOz.
//=========================================================================

::RunState <- class extends State
{
    runAnim = true;
    name = "run";

    function Start()
    {
        krampus.ResetSequence(krampus.LookupSequence("krampus_run"));
        krampus.SetPlaybackRate(KRAMPUS_ANIM_RATE);
    }

    function Think()
    {
        local isMoving = krampus.GetLocomotionInterface().IsAttemptingToMove();
        if (!runAnim && isMoving)
        {
            runAnim = true;
            krampus.SetSequence(krampus.LookupSequence("krampus_run"));
            krampus.SetPlaybackRate(KRAMPUS_ANIM_RATE);
        }
        if (runAnim && !isMoving)
        {
            runAnim = false;
            krampus.SetSequence(krampus.LookupSequence("krampus_idle"));
        }

        if (tick % 100 == 0)
            krampusScript.needsNewPath = true;
        if (krampusScript.needsNewPath && tick % 10 == 0)
        {
            if (krampusTarget)
                krampusScript.SetNewPath(targetOrigin);
            else
                krampusScript.SetState(PatrolState());
        }
        if (!krampusTarget)
            return;
        krampusScript.MoveByCurrentPath();

        if (!runAnim)
            AnimCycleReset();
    }

    function AnimCycleReset()
    {
        if (!krampusTarget)
            return;

        local distanceToTarget = (krampusOrigin - targetOrigin).Length();
        if (distanceToTarget < 350)
        {
            krampusScript.SetState(AttackState());
        }
        else if (distanceToTarget > 450
            && Time() > krampusScript.lastThrowTimeStamp
            && inside(krampusOrigin, KRAMPUS_COAL_THROW_AREA_MIN, KRAMPUS_COAL_THROW_AREA_MAX))
        {
            krampusScript.lastThrowTimeStamp = Time() + RandomFloat(10, 15);
            if (krampusScript.krampusBarrageCounter < 2 && krampusSpawnCounter == 2 && RandomInt(0, 5) <= krampusScript.krampusCoalTossCounter)
                krampusScript.SetState(CoalBarrageState());
            else if (krampusScript.krampusBarrageCounter < 3 && krampusSpawnCounter == 3 && RandomInt(0, 2) <= krampusScript.krampusCoalTossCounter)
                krampusScript.SetState(CoalBarrageState());
            else
                krampusScript.SetState(CoalThrowState());
        }
    }
}

::PatrolState <- class extends State
{
    runAnim = true;
    nextTarget = 0;
    name = "patrol";

    function Start()
    {
        krampus.ResetSequence(krampus.LookupSequence("krampus_walk"));
        krampus.SetPlaybackRate(KRAMPUS_ANIM_RATE);
    }

    function Think()
    {
        local isMoving = krampus.GetLocomotionInterface().IsAttemptingToMove();
        if (!runAnim && isMoving)
        {
            runAnim = true;
            krampus.SetSequence(krampus.LookupSequence("krampus_walk"));
            krampus.SetPlaybackRate(KRAMPUS_ANIM_RATE);
        }
        if (runAnim && !isMoving)
        {
            runAnim = false;
            krampus.SetSequence(krampus.LookupSequence("krampus_idle"));
        }

        if (krampusScript.pathLen == 0)
        {
            if (++nextTarget == 5)
                nextTarget = 1;
            krampusScript.SetNewPath(Entities.FindByName(null, "boss_patrol_"+nextTarget).GetOrigin());
            tick = -100;
        }

        if (krampusTarget)
            krampusScript.SetState(RunState());

        if (tick > 100)
            krampusScript.MoveByCurrentPath(140);
    }
}