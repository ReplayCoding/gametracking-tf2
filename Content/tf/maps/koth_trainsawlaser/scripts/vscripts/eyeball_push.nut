function OnPostSpawn()
{
	for (local brush; brush = Entities.FindByClassname(brush, "func_brush");)
	{
		local parent = brush.GetMoveParent()
		if (parent && parent.GetName() == "TrainRain")
		{
			brush.SetCollisionGroup(25) // TFCOLLISION_GROUP_RESPAWNROOMS
		}
	}
}