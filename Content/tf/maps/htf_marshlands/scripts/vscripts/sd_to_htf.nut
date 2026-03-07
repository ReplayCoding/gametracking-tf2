function OnPostSpawn()
{
    local gameRules = Entities.FindByClassname(null, "tf_gamerules");
    if (gameRules)
    {
        NetProps.SetPropBool(gameRules, "m_bPlayingSpecialDeliveryMode", true);
        NetProps.SetPropInt(gameRules, "m_nGameType", 1);
    }
}