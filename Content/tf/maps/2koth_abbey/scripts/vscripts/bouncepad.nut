function sqrtAbs(value)
{
	if (value < 0)
	{
		value = (value)*(-1);
		//printl("returned " + (sqrt(value)*(-1)) + "from sqrtAbs")
		//printl("original value: " + value)
		return(sqrt(value)*(-1));
	}	
	//printl("returned " + sqrt(value) + "from sqrtAbs")
	//printl("original value: " + value)
	return(sqrt(value));
}

function bouncePlayer(player,speed)
{
	if (player == null)
	{
		return;
	}
	
	local _velPlayer     =  player.GetAbsVelocity();
	player.SetAbsVelocity( Vector((sqrtAbs(_velPlayer.x)*20),(sqrtAbs(_velPlayer.y)*20),speed));
}