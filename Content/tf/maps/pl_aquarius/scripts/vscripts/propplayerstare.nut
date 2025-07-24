//Credits
//Alien31 - V1 of the code, shark stare idea
//lite_flame - Rewrite of the code, helping the guy above

//Move to map script
::shark_custom_dmg <- SpawnEntityFromTable("info_target", { classname = "shark" });
//----

function Precache() 
{
	self.SetModelSimple("models/props_megalodon/megalodon.mdl")
	self.SetSequence(self.LookupSequence("swim"))
	self.SetPlaybackRate(1.0)
	StopCycling <- false
}


const RAD2DEG = 57.295779513

function VectorToQAngle(Vector) {
	local yaw, pitch;
	if ( Vector.y == 0.0 && Vector.x == 0.0 )
	{
		yaw = 0.0;
		if (Vector.z > 0.0)
			pitch = 270.0;
		else
			pitch = 90.0;
	}
	else
	{
		yaw = (::atan2(Vector.y, Vector.x) * RAD2DEG);
		if (yaw < 0.0)
			yaw += 360.0;
		pitch = (::atan2(-Vector.z, Vector.Length2D()) * RAD2DEG);
		if (pitch < 0.0)
			pitch += 360.0;
	}
	return ::QAngle(pitch, yaw, 0.0);
}
function Clamp(value, low, high) {
	if (value < low)
		return low;
	if (value > high)
		return high;
	return value;
}
function NormalizeAngle(angle) {
	foreach(type, degree in angle)
	{
		degree %= 360.0;
		if(degree > 180.0)
			degree -= 360.0;
		angle[type] = degree;
	}
}
local Shark_Yaw = self.LookupPoseParameter("look_horizontal");
local Shark_Pitch = self.LookupPoseParameter("look_vertical");
currentPitch <- 0
currentYaw <- 0
function StareAtTarget(target) {
	if (target == null) {
		printl("Error: Target not found.\n");
		return;
	}

	local direction = VectorToQAngle(target.GetOrigin() - self.GetOrigin());
	local rotation = self.GetAbsAngles();
	NormalizeAngle(rotation);
	direction -= rotation;
	NormalizeAngle(direction);

	local targetPitch = Clamp(direction.x, -45.0, 45.0);
	local targetYaw = Clamp(-direction.y, -45.0, 45.0);

	local belowTargetPitch = targetPitch > currentPitch;
	currentPitch += belowTargetPitch ? 1 : -1;
	if(belowTargetPitch ? currentPitch > targetPitch : currentPitch < targetPitch)
		currentPitch = targetPitch;

	local belowTargetYaw = targetYaw > currentYaw;
	currentYaw += belowTargetYaw ? 1 : -1;
	if(belowTargetYaw ? currentYaw > targetYaw : currentYaw < targetYaw)
		currentYaw = targetYaw;

	self.SetPoseParameter(Shark_Pitch, currentPitch);
	self.SetPoseParameter(Shark_Yaw, currentYaw);

}
//self.SetSequence(self.LookupSequence("swimbite"))
//self.SetSequence(self.LookupSequence("swim"))
// Example usage: Make prop "prop_example" stare at target "target_example"``

::StopCycle <- function()
{
	StopCycling = true
}

function Think() {
	self.StudioFrameAdvance();
	if (!StopCycling)
	{
		if(self.GetCycle() == 1.0)
			self.SetCycle(0.0)
	}

	local target = Entities.FindByClassnameNearest("player", self.GetOrigin(), 1024.0);
	if(target) StareAtTarget(target);

	return -1
}

AddThinkToEnt(self, "Think");
