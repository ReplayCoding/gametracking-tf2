//=========================================================================
//Copyright LizardOfOz.
//=========================================================================

::MAX_PLAYERS <- MaxClients().tointeger();

::GetAllPlayers <- function()
{
    local allPlayers = [];
    for (local i = 1; i <= MAX_PLAYERS; i++)
    {
        local player = PlayerInstanceFromIndex(i);
        if (player)
            allPlayers.push(player);
    }
    return allPlayers;
}

::GetREDPlayerCounter <- function()
{
    local counter = 0;
    for (local i = 1; i <= MAX_PLAYERS; i++)
    {
        local player = PlayerInstanceFromIndex(i);
        if (player && player.GetTeam() == Constants.ETFTeam.TF_TEAM_RED)
            counter++;
    }
    return counter;
}

::CTFPlayer.IsAlive <- function()
{
    return NetProps.GetPropInt(this, "m_lifeState") == 0;
}

::CTFBot.IsAlive <- CTFPlayer.IsAlive;

::IsValidPlayer <- function(player)
{
    try
    {
        return player && player.IsValid() && player.IsPlayer() && player.GetTeam() > 1;
    }
    catch(e)
    {
        return false;
    }
}

::clamp <- function(value, min, max)
{
    if (value < min)
        return min;
    if (value > max)
        return max;
    return value;
}

::RunWithDelay <- function (scope, delay, func, ...)
{
    local name = UniqueString();
    main_script[name] <- function()
    {
        try { func.acall([scope].extend(vargv)) }
        catch (e) { throw e; }
        delete main_script[name];
    }
    EntFireByHandle(main_script_entity, "RunScriptCode", name + "()", delay, null, null);
}

::GiveWeapon <- function(player, weaponClass, weaponId)
{
    local weapon = Entities.CreateByClassname(weaponClass);
    NetProps.SetPropInt(weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", weaponId);
    NetProps.SetPropBool(weapon, "m_AttributeManager.m_Item.m_bInitialized", true);
    NetProps.SetPropBool(weapon, "m_bValidatedAttachedEntity", true);
	NetProps.SetPropBool(weapon, "m_bClientSideAnimation", true);
    NetProps.SetPropBool(weapon, "m_bForcePurgeFixedupStrings", true);
    weapon.SetTeam(player.GetTeam());
    Entities.DispatchSpawn(weapon);
    player.Weapon_Equip(weapon);
    return weapon;
}