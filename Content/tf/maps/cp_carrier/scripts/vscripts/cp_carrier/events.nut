//=========================================================================
//Copyright LizardOfOz.
//=========================================================================

ClearGameEventCallbacks();

function Think()
{
    if (IsValidPlayer(carrier) && carrier.IsAlive())
    {
        local hpBar = clamp(255.0 * carrier.GetHealth() / carrier.GetMaxHealth(), 1, 255);
        NetProps.SetPropInt(monster_resource, "m_iBossHealthPercentageByte", hpBar);
        if (carrier.InCond(Constants.ETFCond.TF_COND_TAUNTING))
            carrier.RemoveCond(Constants.ETFCond.TF_COND_TAUNTING);
    }
    return -1;
}

function OnGameEvent_player_spawn(params)
{
    local player = "userid" in params ? GetPlayerFromUserID(params.userid) : null;
    if (IsValidPlayer(player))
        PlayerRespawn(player);
}

function OnGameEvent_teamplay_flag_event(params)
{
    if (Time() - bombDropTimeStamp < 0.1)
        return;
    local player = "player" in params ? PlayerInstanceFromIndex(params.player) : null;
    if (!IsValidPlayer(player))
        return;
    if (params.eventtype == 4)
        player.TakeDamageCustom(player, player, null, Vector(), Vector(), 99999, 0, Constants.ETFDmgCustom.TF_DMG_CUSTOM_TELEFRAG);
    if (params.eventtype == 1)
        TurnIntoFlagCarrier(player);
}

function OnGameEvent_player_death(params)
{
    local player = "userid" in params ? GetPlayerFromUserID(params.userid) : null;
    if (carrier && player == carrier && IsValidPlayer(player))
    {
        local inflictor = "inflictor_entindex" in params ? params.inflictor_entindex : 0;
        CarrierDied(player, inflictor != player.entindex() && inflictor > 0 && inflictor < MAX_PLAYERS);
    }
}

__CollectGameEventCallbacks(this);
__CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);