ClearGameEventCallbacks();

tf_player_manager <- Entities.FindByClassname(null, "tf_player_manager");

function GetUserID(player)
{
    return NetProps.GetPropIntArray(tf_player_manager, "m_iUserID", player.entindex());
}

function OnScriptHook_OnTakeDamage(params)
{
    local inflictor = params.inflictor;
    local victim = params.const_entity;
    local attacker = params.attacker;

    if (inflictor == null || victim == null)
        return;

    if (victim.GetClassname() == "tf_zombie" && attacker.IsPlayer())
    {
        victim.EmitSound("Flesh.BulletImpact");
        SendGlobalGameEvent("npc_hurt", {
            entindex = victim.entindex(),
            health = victim.GetHealth(),
            attacker_player = GetUserID(attacker),
            weaponid = 0,
            damageamount = params.damage,
            crit = false,
            boss = 0
        });
    }

    if (!victim.IsPlayer())
        return;

    local inflictorClass = inflictor.GetClassname();

    if (inflictorClass == "tf_generic_bomb" && attacker != null && (victim == attacker || attacker.GetTeam() != victim.GetTeam()))
    {
        ApplySlime(victim, victim.entindex(), BOMB_EFFECT_DURATION, attacker);
    }
    else if (inflictorClass == "tf_zombie" && NetProps.GetPropFloat(inflictor, "m_flNextAttack") > 0.5)
    {
        params.damage = 0;
        params.early_out = true;
    }
}

__CollectGameEventCallbacks(this);
__CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);