//By LizardOfOz
//Feel free to use

CRUMPKIN_INDEX <- PrecacheModel("models/props_halloween/pumpkin_loot.mdl");
CRUMPKIN_COND <- Constants.ETFCond.TF_COND_CRITBOOSTED_PUMPKIN;
MAX_PLAYERS <- MaxClients().tointeger();
GetPropInt <- ::NetProps.GetPropInt.bindenv(::NetProps);
FindByClassname <- ::Entities.FindByClassname.bindenv(::Entities);

function Think()
{
    local crumpkins = [];

    for (local tf_ammo_pack = null; tf_ammo_pack = FindByClassname(tf_ammo_pack, "tf_ammo_pack");)
        if (GetPropInt(tf_ammo_pack, "m_nModelIndex") == CRUMPKIN_INDEX)
            crumpkins.push(tf_ammo_pack);

    foreach(crumpkin in crumpkins)
        crumpkin.Kill();

    for (local i = 1; i <= MAX_PLAYERS; i++)
    {
        local player = PlayerInstanceFromIndex(i);
        if (player)
            player.RemoveCond(CRUMPKIN_COND);
    }

    return 0;
}