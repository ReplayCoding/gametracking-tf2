//=========================================================================
//Copyright LizardOfOz.
//
//Credits:
//  LizardOfOz - Programming, game design, promotional material and overall development. The original VSH Plugin from 2010.
//  Maxxy - Saxton Hale's model imitating Jungle Inferno SFM; Custom animations and promotional material.
//  Velly - VFX, animations scripting, technical assistance.
//  JPRAS - Saxton model development assistance and feedback.
//  MegapiemanPHD - Saxton Hale and Gray Mann voice acting.
//  James McGuinn - Mercenaries voice acting for custom lines.
//  Yakibomb - give_tf_weapon script bundle (used for Hale's first-person hands model).
//  Phe - game design assistance.
//=========================================================================

::IsPlayerAlive <- function(player)
{
    return GetPropInt(player, "m_lifeState") == LIFE_STATE.ALIVE;
}

::IsPlayerDead <- function(player)
{
    return GetPropInt(player, "m_lifeState") != LIFE_STATE.ALIVE;
}

::CTFPlayer.IsOnGround <- function()
{
    return GetPropEntity(this, "m_hGroundEntity") != null;
}

::CTFBot.IsOnGround <- CTFPlayer.IsOnGround;

::IsValidClient <- function(player)
{
    try
    {
        return player != null && player.IsValid() && player.IsPlayer();
    }
    catch(e)
    {
        return false;
    }
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

::IsValidPlayerOrBuilding <- function(entity)
{
    try
    {
        return entity != null
            && entity.IsValid()
            && entity.GetTeam() > 1
            && (entity.IsPlayer() || startswith(entity.GetClassname(), "obj_"));
    }
    catch(e)
    {
        return false;
    }
}

::IsValidBuilding <- function(building)
{
    try
    {
        return building != null
            && building.IsValid()
            && startswith(building.GetClassname(), "obj_")
            && building.GetTeam() > 1;
    }
    catch(e)
    {
        return false;
    }
}

::GetPlayerFromParams <- function(params, key = "userid")
{
    if (!(key in params))
        return null;
    local player = GetPlayerFromUserID(params[key]);
    if (IsValidPlayer(player))
        return player;
    return null;
}

::PlaySoundForAll <- function(soundScript)
{
    for (local i = 1; i <= MAX_PLAYERS; i++)
    {
        local player = PlayerInstanceFromIndex(i);
        if (IsValidPlayer(player))
            EmitSoundOnClient(soundScript, player);
    }
}

::CTFPlayer.Yeet <- function(vector)
{
    SetPropEntity(this, "m_hGroundEntity", null);
    this.ApplyAbsVelocityImpulse(vector);
    this.RemoveFlag(FL_ONGROUND);
}

::CTFBot.Yeet <- CTFPlayer.Yeet;

::CTFBot.SwitchTeam <- function(team)
{
    this.ForceChangeTeam(team, true);
    SetPropInt(this, "m_iTeamNum", team);
}

::CTFPlayer.SwitchTeam <- function(team)
{
    SetPropInt(this, "m_bIsCoaching", 1);
    this.ForceChangeTeam(team, true);
    SetPropInt(this, "m_bIsCoaching", 0);
}

::SwitchPlayerTeam <- function(player, team)
{
    if (IsValidPlayer(player))
    {
        player.SwitchTeam(team);
        if (!IsBoss(player) && IsRoundSetup())
        {
            player.ForceRegenerateAndRespawn();
            local ammoPack = null;
            while (ammoPack = FindByClassname(ammoPack, "tf_ammo_pack"))
                if (ammoPack.GetOwner() == player)
                {
                    ammoPack.Kill();
                    return;
                }
        }
    }
}