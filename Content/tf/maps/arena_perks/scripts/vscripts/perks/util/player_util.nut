// --------------------------------------------------------------------------------------- //
// Perks - Version 1.3                                                                     //
// --------------------------------------------------------------------------------------- //
// Game Design and Scripting by: Le Codex (https://steamcommunity.com/id/lecodex)          //
// Assets by: Diva Dan (https://steamcommunity.com/profiles/76561198072146551)             //
// and Tianes (https://steamcommunity.com/id/_tianes)                                      //
// --------------------------------------------------------------------------------------- //

::IsPlayerAlive <- function(player)
{
    return NetProps.GetPropInt(player, "m_lifeState") == LIFE_STATE.ALIVE;
}

::IsValidPlayer <- function(player)
{
    try
    {
        return player != null && player.IsValid() && player.IsPlayer() && player.GetTeam() > 1;
    }
    catch(e)
    {
        return false;
    }
}

::GetAliveTeamPlayerCount <- function(team)
{
    local aliveCount = 0;
    for (local i = 1; i <= Constants.Server.MAX_PLAYERS; i++) {
        local player = PlayerInstanceFromIndex(i);
        if (IsValidPlayer(player) && IsPlayerAlive(player) && player.GetTeam() == team) aliveCount++;
    }
    return aliveCount;
}

::ClearWeaponCache <- function(player)
{
    for (local i = 0; i <= 7; i++)
    {
        local weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i);
        if (weapon == null) continue;
        
        weapon.AddAttribute("throwable recharge time", 0.0, -1);

        weapon.RemoveAttribute("clip size penalty");
        weapon.RemoveAttribute("clip size bonus upgrade");
        weapon.RemoveAttribute("clip size upgrade atomic");
        weapon.RemoveAttribute("throwable recharge time");
    }
}

::GetAllPlayers <- function() {
    for (local i = 0; i < MaxClients(); i++) {
        local player = PlayerInstanceFromIndex(i);
        if (!IsValidPlayer(player)) continue;

        yield player;
    }

    return null;
}
