::slimedPlayers <- [];

::ThinkSlimeStatusEffect <- function()
{
    local time = Time();
    foreach (player in GetAllPlayers())
    {
        local playerIndex = player.entindex();
        local value = slimedPlayers[playerIndex];
        if ((value > 0 && value < time) || NetProps.GetPropInt(player, "m_lifeState") != 0)
            ClearSlime(player, playerIndex);
    }
}

::GiveDripCosmetic <- function(player)
{
    local existingDripCosmetic = Entities.FindByName(null, "drips_" + player.entindex());
    if (existingDripCosmetic != null)
        existingDripCosmetic.Kill();

    local dripCosmetic = SpawnEntityFromTable("tf_wearable", {
        targetname = "drips_" + player.entindex()
    });

	dripCosmetic.SetModel(DRIP_COSMETIC_MODEL);
    EntFireByHandle(dripCosmetic, "SetParent", "!activator", 0, player, player);
	NetProps.SetPropEntity(dripCosmetic, "m_hOwnerEntity", player);

	return dripCosmetic;
}

::ApplySlime <- function(player, playerIndex, duration, inflictor)
{
    player.AddCondEx(Constants.ETFCond.TF_COND_MARKEDFORDEATH_SILENT, duration, inflictor);

    if (slimedPlayers[playerIndex] == 0)
    {
        EntFireByHandle(player, "SpeakResponseConcept", "TLK_JARATE_HIT", 1, null, null);
        player.SetScriptOverlayMaterial(SLIME_OVERLAY);

        SetEntityColor(player, SLIMED_COLOR);
        local wearable = null;
        while (wearable = Entities.FindByClassname(wearable, "tf_we*"))
            if (wearable.GetOwner() == player)
                SetEntityColor(wearable, SLIMED_COLOR);

        GiveDripCosmetic(player);
    }

    slimedPlayers[playerIndex] = Time() + duration;
}

::ClearSlime <- function(player, playerIndex)
{
    SetEntityColor(player, [255, 255, 255])
    local wearable = null;
    while (wearable = Entities.FindByClassname(wearable, "tf_we*"))
        if (wearable.GetOwner() == player)
            SetEntityColor(wearable, [255, 255, 255]);

    player.SetScriptOverlayMaterial("");
    slimedPlayers[playerIndex] = 0;
	DoEntFire("drips_" + playerIndex, "Kill", "", 0, null, null)
}

::SetEntityColor <- function(entity, rgb)
{
    local color = rgb[0] | (rgb[1] << 8) | (rgb[2] << 16);
    NetProps.SetPropInt(entity, "m_clrRender", color);
}

for(local i = 0; i <= MAX_PLAYERS; i++)
{
    slimedPlayers.push(0);
    local player = PlayerInstanceFromIndex(i);
    if (player != null)
        ClearSlime(player, i);
}
