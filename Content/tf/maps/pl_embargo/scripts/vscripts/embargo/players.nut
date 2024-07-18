//==========================================
//Caching alive players
//==========================================

::alive_player_cache <- [];

::GetAlivePlayers <- function()
{
    return alive_player_cache;
}

for (local i = 1; i <= MAX_PLAYERS; i++)
{
    local player = PlayerInstanceFromIndex(i);
    if (player && player.GetTeam() > 1 && GetPropInt(player, "m_lifeState") == 0)
        alive_player_cache.push(player);
}

function OnGameEvent_player_spawn(params)
{
	local player = GetPlayerFromUserID(params.userid);
    if (player && alive_player_cache.find(player) == null)
        alive_player_cache.push(player);
}

function OnGameEvent_player_death(params)
{
    local index;
	local player = GetPlayerFromUserID(params.userid);
    if (player && (index = alive_player_cache.find(player)) != null)
        alive_player_cache.remove(index);
}
OnGameEvent_player_disconnect <- OnGameEvent_player_death;

//==========================================
//Player stuff
//==========================================

::IsValidClient <- function(player)
{
    try
    {
        return player && player.IsValid() && player.IsPlayer();
    }
    catch(e)
    {
        return false;
    }
}

::CTFPlayer.GetItems <- function()
{
    local items = [];
    for (local item = this.FirstMoveChild(); item != null; item = item.NextMovePeer())
        if (item && item.IsValid() && item.GetClassname() != "tf_viewmodel")
            items.push(item);
    return items;
}
::CTFBot.GetItems <- CTFPlayer.GetItems;

::CTFPlayer.Heal <- function(healing, dispalyOnHud = true)
{
    local oldHP = this.GetHealth();
    local maxHP = this.GetMaxHealth();
    local newHP = oldHP + healing;
    if (newHP > maxHP) newHP = maxHP;
    if (oldHP > newHP) newHP = oldHP;
    this.SetHealth(newHP);
    if (dispalyOnHud && newHP - oldHP > 0)
        SendGlobalGameEvent("player_healonhit", {
            entindex = this.entindex(),
            amount = newHP - oldHP
        });
}
::CTFBot.Heal <- CTFPlayer.Heal;