PrecacheModel("models/props_embargo/paint_drips.mdl");

paintCovered <- []; paintCovered.resize(MAX_PLAYERS + 1, false);
point_clientcommand <- SpawnEntityFromTable("point_clientcommand", { });

for (local i = 1; i <= MAX_PLAYERS; i++)
{
    local player = PlayerInstanceFromIndex(i);
    if (!player)
        continue;

    SetPropInt(player, "m_clrRender", 0xFFFFFF);
    foreach(ent in player.GetItems())
        SetPropInt(ent, "m_clrRender", 0xFFFFFF);

    player.SetScriptOverlayMaterial("");
    EntFireByHandle(point_clientcommand, "Command", "r_screenoverlay ``", -1, player, player);
}
DoEntFire("paint_drips", "Kill", "", -1, null, null);

//The block above gets executed when the round starts.
//The function below gets executed when a player touches the paint explosion trigger at the end.

function ApplyPaint(player)
{
    if (!IsValidClient(player) || paintCovered[player.entindex()])
        return;
    paintCovered[player.entindex()] = true;

    EntFireByHandle(player, "SpeakResponseConcept", "TLK_JARATE_HIT", 1, null, null);
    player.SetScriptOverlayMaterial("hud/embargo/embargo_splishsplash2");
    EntFireByHandle(point_clientcommand, "Command", "r_screenoverlay hud/embargo/embargo_splishsplash", -1, player, player);

    SetPropInt(player, "m_clrRender", 0xFFC811);
    foreach(ent in player.GetItems())
        SetPropInt(ent, "m_clrRender", 0xFFC811);

    local dripModel = SpawnEntityFromTable("tf_wearable", {
        targetname = "paint_drips"
    });
	dripModel.SetModel("models/props_embargo/paint_drips.mdl");
    dripModel.SetAbsOrigin(player.GetOrigin());
    SetPropBool(dripModel, "m_bForcePurgeFixedupStrings", true);
	SetPropEntity(dripModel, "m_hOwnerEntity", player);
    EntFireByHandle(dripModel, "SetParent", "!activator", 0, player, player);
}