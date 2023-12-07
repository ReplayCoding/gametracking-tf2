//=========================================================================
//Copyright LizardOfOz.
//=========================================================================

IncludeScript("koth_krampus/__lizardlib/netprops.nut");
IncludeScript("koth_krampus/__lizardlib/constants.nut");
IncludeScript("koth_krampus/__lizardlib/player.nut");

::CreateAoE <- function(center, radius, applyFunc)
{
    for (local i = 1; i <= MAX_PLAYERS; i++)
    {
        local target = PlayerInstanceFromIndex(i);
        if (!target || !target.IsAlive())
            continue;
        local unitVector = target.GetCenter() - center;
        local height = unitVector.z;
        unitVector.z = 0;
        local distance = unitVector.Norm();
        if (distance > radius)
            continue;

        applyFunc(target, unitVector, distance, height);
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

::inside <- function(vector, min, max)
{
    return vector.x >= min.x && vector.x <= max.x
        && vector.y >= min.y && vector.y <= max.y
        && vector.z >= min.z && vector.z <= max.z;
}