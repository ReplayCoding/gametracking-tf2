CRUMPKIN_INDEX <- PrecacheModel("models/props_halloween/pumpkin_loot.mdl");
GetPropInt <- ::NetProps.GetPropInt.bindenv(::NetProps);
FindByClassname <- ::Entities.FindByClassname.bindenv(::Entities);

function Think()
{
    local tf_ammo_pack = null;
    local crumpkins = [];

    while (tf_ammo_pack = FindByClassname(tf_ammo_pack, "tf_ammo_pack"))
        if (GetPropInt(tf_ammo_pack, "m_nModelIndex") == CRUMPKIN_INDEX)
            crumpkins.push(tf_ammo_pack);

    foreach(crumpkin in crumpkins)
        crumpkin.Kill();

    return 0;
}