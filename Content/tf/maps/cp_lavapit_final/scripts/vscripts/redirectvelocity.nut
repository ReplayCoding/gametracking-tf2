function RedirectVelocity(new_yaw)
{
	local velocity = activator.GetVelocity()
	
	//find amount of rotation between current and target
	local angles = activator.GetAngles()
	local rotation = QAngle(0, new_yaw - angles.y, 0)
	
	local new_velocity = RotatePosition(Vector(), rotation, velocity)
	
	activator.SetVelocity(new_velocity)
}
