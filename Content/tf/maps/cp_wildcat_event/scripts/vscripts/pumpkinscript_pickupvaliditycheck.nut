::ValidityThink <- function()
{
	foreach(player in GetPlayers())
	{
		if (player.GetPlayerClass() != TF_CLASS_SPY) continue //Only do this check for spy to reduce potential perf cost
		local validPickupConditions = !(player.InCond(TF_COND_DISGUISED) || player.InCond(TF_COND_STEALTHED) || GetPlayerScope(player).isAPumpkin)

		//If in a condition NOT VALID to pick up item_armor + armor value is set so you CAN pick up armor. Set player to be NOT ABLE to pick up armor
		if (!validPickupConditions && NetProps.GetPropInt(player, "m_ArmorValue") == -2147483648)
		{
			SetPlayerCanPickUpItemArmor(player, false); continue
		}

		//If in a condition VALID to pick up item_armor + armor value is set so you CAN NOT pick up armor. Set player to be ABLE to pick up armor
		if (validPickupConditions && NetProps.GetPropInt(player, "m_ArmorValue") == 0)
		{
			SetPlayerCanPickUpItemArmor(player, true); continue
		}
	}

	return -1
}

AddThinkToEnt(self, "ValidityThink")
