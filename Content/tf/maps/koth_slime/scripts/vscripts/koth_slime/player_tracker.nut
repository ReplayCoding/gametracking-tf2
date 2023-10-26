MAX_PLAYERS <- MaxClients().tointeger();

::alivePlayers <- [];
::allPlayers <- [];

::RecachePlayers <- function()
{
    local alivePlayersL = [];
    local allPlayersL = [];
    for (local i = 1; i <= MAX_PLAYERS; i++)
    {
        local player = PlayerInstanceFromIndex(i);
        if (player != null)
        {
            allPlayersL.push(player);
            if (NetProps.GetPropInt(player, "m_lifeState") == 0)
                alivePlayersL.push(player);
        }
    }
    alivePlayers = alivePlayersL;
    allPlayers = allPlayersL;
}

::GetAllPlayers <- function()
{
    return allPlayers;
}

::GetAlivePlayers <- function()
{
    return alivePlayers;
}

::GetAlivePlayersInRange <- function(center, radius, eyeVector)
{
    local inRangePlayers = {};
    foreach (player in alivePlayers)
    {
        local deltaVector = player.GetCenter() - center;
        if (deltaVector.z <= 100 && deltaVector.Norm() <= radius)
            inRangePlayers[player] <- eyeVector.Dot(deltaVector);
    }
    return inRangePlayers;
}