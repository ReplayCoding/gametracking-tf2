// --------------------------------------------------------------------------------------- //
// Perks - Version 1.4                                                                     //
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

::GetAllPlayers <- function() {
    for (local i = 0; i < MaxClients(); i++) {
        local player = PlayerInstanceFromIndex(i);
        if (!IsValidPlayer(player)) continue;

        yield player;
    }

    return null;
}

::GetAliveTeamPlayerCount <- function(team)
{
    local aliveCount = 0;
    foreach (player in GetAllPlayers()) {
        if (IsPlayerAlive(player) && player.GetTeam() == team) aliveCount++;
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

::StunPlayer <- function(player, time) {
    local trigger_stun = SpawnEntityFromTable("trigger_stun", {
        targetname = "trigger_stun",
        stun_type = 2,
        stun_duration = time,
        move_speed_reduction = 0,
        trigger_delay = 0,
        ///filtername = "filter_team_blu",
        StartDisabled = 0,
        spawnflags = 1,
        solid = 2,
        "OnStunPlayer#1": "!self,Kill,0,0.01,-1",
    });
    EntFireByHandle(trigger_stun, "EndTouch", "", 0.0, player, player);
}