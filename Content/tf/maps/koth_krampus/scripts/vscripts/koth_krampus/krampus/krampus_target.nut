//=========================================================================
//Copyright LizardOfOz.
//=========================================================================

function LookForTarget()
{
    if (!IsValidPlayer(krampusTarget) || !krampusTarget.IsAlive() || pathFailed || pathDistance > 800)
        SetNewTarget(PickTarget());
}

function SetNewTarget(target)
{
    local lastTarget = krampusTarget;
    krampusTarget = IsValidPlayer(target) ? target : null;
    if (krampusTarget && lastTarget != krampusTarget)
        EmitSoundLP(target, krampus, PickRandomSound(VO_ISEEYOU));
}

function PickTarget()
{
    local maxScore = -100;
    local targetPlayer = null;
    foreach (player in GetAlivePlayers())
    {
        local playerPos = player.GetOrigin();
        if (inside(playerPos, KRAMPUS_ARENA_MIN, KRAMPUS_ARENA_MAX))
        {
            local score = 0;
            local deltaVector = krampus.GetCenter() - playerPos;
            local distance = deltaVector.Norm();
            if (player.EyeAngles().Forward().Dot(deltaVector) >= 0.82)
                score += 5;
            score -= 10 * clamp(krampusForwardVector.Dot(deltaVector), -1, 0);
            score += clamp(800 - distance, 200, 600) * 0.02;

            playerPos.z += 12;
            local endArea = NavMesh.GetNavArea(playerPos, 512);
            if (!endArea)
                endArea = NavMesh.GetNearestNavArea(playerPos, 512, false, true);
            if (!endArea)
                continue;
            if (score > maxScore)
            {
                targetPlayer = player;
                maxScore = score;
            }
        }
    }
    return targetPlayer;
}

function PickRandomTarget()
{
    local players = [];
    foreach (player in GetAlivePlayers())
        if (inside(player.GetOrigin(), KRAMPUS_ARENA_MIN, KRAMPUS_ARENA_MAX))
            players.push(player);
    local len = players.len();
    if (len == 0)
        return null;
    return players[RandomInt(0, len - 1)];
}

function PickTargetInSight()
{
    local players = [];
    foreach (player in GetAlivePlayers())
        if (TraceLine(krampus.EyePosition(), player.GetCenter(), krampus) > 0.95)
            players.push(player);
    local len = players.len();
    if (len == 0)
        return PickRandomTarget();
    return players[RandomInt(0, len - 1)];
}