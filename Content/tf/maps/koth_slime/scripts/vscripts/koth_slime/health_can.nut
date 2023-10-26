HEALTHCAN_MODEL_INDEX <- PrecacheModel(HEALTHCAN_MODEL);
PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = "salmann_blood_explode" })

healthCans <- [];

function AttemptToDropHealthCan(center)
{
    DispatchParticleEffect("salmann_blood_explode", center + Vector(0, 0, 25), Vector(0, 0, 0));
	
    if (RandomFloat(0, 1) > HEALTHCAN_BASE_DROP_CHANCE || !ShouldSpawnHealthCan(center, 900, 450))
        return;

    local healthCan = SpawnEntityFromTable("item_healthkit_small", {
        "OnPlayerTouch": "!self,Kill,,0,-1"
    });
    EntFireByHandle(self, "RunScriptCode", "TryKillHealthCan(activator, 0)", 25, healthCan, healthCan);
    healthCan.SetModelSimple(HEALTHCAN_MODEL)
    NetProps.SetPropInt(healthCan, "m_nModelIndex", HEALTHCAN_MODEL_INDEX);
    NetProps.SetPropInt(healthCan, "m_nModelIndexOverrides.000", HEALTHCAN_MODEL_INDEX);
    NetProps.SetPropInt(healthCan, "m_nModelIndexOverrides.001", HEALTHCAN_MODEL_INDEX);
    NetProps.SetPropInt(healthCan, "m_nModelIndexOverrides.002", HEALTHCAN_MODEL_INDEX);
    NetProps.SetPropInt(healthCan, "m_nModelIndexOverrides.003", HEALTHCAN_MODEL_INDEX);
    healthCan.SetMoveType(Constants.EMoveType.MOVETYPE_FLYGRAVITY, Constants.EMoveCollide.MOVECOLLIDE_FLY_BOUNCE);
    healthCan.SetAbsOrigin(center);
    healthCan.SetVelocity(Vector(RandomFloat(-50, 50), RandomFloat(-50, 50), 250));
    healthCans.push(healthCan);
}

function ShouldSpawnHealthCan(sphereCenter, playerRadius, canRadius)
{
    local playersToHeal = 0;
    foreach (player in alivePlayers)
        if ((player.GetOrigin() - sphereCenter).Length() <= playerRadius && player.GetMaxHealth() - player.GetHealth() > 40)
        {
            if (playersToHeal++ >= 3)
                break;
        }

    local canCounter = 0;
    local len = healthCans.len();
    local healthCan;
    for(local i = 0; i < len; i++)
    {
        healthCan = healthCans[i];
        if (!healthCan.IsValid())
        {
            healthCans.remove(i);
            i--;
            len--;
            continue;
        }
        local distance = (healthCan.GetOrigin() - sphereCenter).Length();
        if (distance < 75)
            return false;
        if (distance <= canRadius)
            canCounter++;
    }
    if (playersToHeal > canCounter)
        return true;
    return false;
}

function TryKillHealthCan(healthCan, attempt)
{
    if (!healthCan || !healthCan.IsValid())
        return;
    local sphereCenter = healthCan.GetOrigin();
    if (attempt < 10)
        foreach (player in alivePlayers)
            if ((player.GetOrigin() - sphereCenter).Length() <= 900 && player.GetMaxHealth() - player.GetHealth() > 10)
            {
                EntFireByHandle(self, "RunScriptCode", format("TryKillHealthCan(activator, %d)", attempt+1), 5, healthCan, healthCan);
                return;
            }
    healthCan.Kill();
}