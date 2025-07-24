//Credits
//Alien31 - Sounds minor tweaks
//lite_flame - AIM code

self.SetModelSimple("models/props_interactive/posable/camera_security1.mdl")
self.SetPlaybackRate(1.0)


local TargetList = {
	"player" : 1
	"obj_sentrygun" : 1
	"obj_dispenser" : 1
	"obj_teleporter" : 1
	"tank_boss" : 1
	"merasmus" : 1
	"headless_hatman" : 1
	"eyeball_boss" : 1
	"tf_zombie" : 1
	"prop_vehicle_driveable" : 1
}
const MASK_SHOT_HULL = 100679691
const RAD2DEG = 57.295779513
enum states {
OFF, 
ON, 
LOOK,
STOP,
DEAD,
};
local iPosePitch = self.LookupPoseParameter("aim_pitch")
local iPoseYaw = self.LookupPoseParameter("aim_yaw")

function Precache() 
{
	name <- self.GetName()
	team <- self.GetTeam()
	YawClamp   <- [-100.0, 100.0]
	IsClamped <- true
	angCurrent <- QAngle()
	angGoal    <- QAngle()
	flTurnRate <- 0
	iDirLast   <- 1
	state <- states.OFF
	snd_move <- "npc/turret_wall/turret_loop1.wav"
	PrecacheSound(snd_move)
	if (team == 0) {
		if (name.find("red") != null) {
			team = 2
		} else if (name.find("blu") != null) {
			team = 3
		} else {
			team = 0
	}

	self.SetTeam(team)

}

//Stop on restart failsafe
self.StopSound(snd_move)

}
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
function Think()
{
    self.StudioFrameAdvance()
	if(self.GetCycle() == 1.0)
		self.SetCycle(0.0)

	local vecOrigin = self.GetOrigin() + Vector(0,0,5)
	local angRotation = self.GetAbsAngles()

	local hTarget
	local flTargetDist = 800.0
	foreach(sTargets,value in TargetList)
	{
		for(local hPlayer; hPlayer = Entities.FindByClassnameWithin(hPlayer, sTargets, vecOrigin, 800.0);)
		{
			if(!hPlayer.IsAlive()) continue
			if(hPlayer.IsPlayer())
			{
				if(hPlayer.IsStealthed() || !hPlayer.InCond(3) && hPlayer.InCond(22) && hPlayer.InCond(24) && hPlayer.InCond(9) && hPlayer.InCond(25) ) continue
				if(self.GetTeam() != 0 && hPlayer.GetDisguiseTeam() == self.GetTeam() ) continue
			}
			if(hPlayer.GetTeam() == self.GetTeam()) continue
			if(!hPlayer.GetClassname() == "prop_vehicle_driveable" && !hPlayer.GetScriptScope.driver) continue
			local flDist = (vecOrigin - hPlayer.GetOrigin()).Length()
			local SightLine =
			{
				start = self.GetCenter(),
				end = hPlayer.GetCenter(),
				ignore = self
				mask = MASK_SHOT_HULL
			} 
			TraceLineEx(SightLine);	
			if (SightLine.hit && SightLine.enthit.GetClassname() in TargetList)
			{
				if(flDist < flTargetDist)
				{
					hTarget = hPlayer
					flTargetDist = flDist
				}
			}
		}
	}
	
	if (self.GetHealth() < 0 && state != states.DEAD)
	{
		Death()
	}

	local bClamp = false
	if(IsClamped) bClamp = true
	

	if(hTarget)
	{
		local vecDirToEnemy = hTarget.GetOrigin() - vecOrigin
		vecDirToEnemy = RotatePosition(Vector(), angRotation * -1, vecDirToEnemy)
		local angToTarget = VectorToQAngle(vecDirToEnemy)

		angToTarget.y = 360.0 - angToTarget.y

		if(bClamp)
		{
			if(angToTarget.y > 180.0) angToTarget.y -= 360.0
			if(angToTarget.y > YawClamp[1]) angToTarget.y = YawClamp[1]
			else if(angToTarget.y < YawClamp[0]) angToTarget.y = YawClamp[0]
		}

		angToTarget.x = -Clamp(angToTarget.x - (angToTarget.x > 180.0 ? 360.0 : 0.0), -50.0, 50.0)
		angGoal = angToTarget
		if (state == states.OFF)
			state = states.ON
	}
	else
	{
		if (state != states.OFF)
		{
			state = states.OFF
			EmitSoundEx({ sound_name = snd_move, volume = 0.5, flags = 4, sound_level = 80, filter_type = 5, entity = self });;
		}
	}


	//ClientPrint(null, 4, angCurrent + "\n" + angGoal)

	local bMoving = false

	if(fabs(angCurrent.x - angGoal.x) > 0.001) // the wonders of floating point imprecision
	{
		local iDir = angGoal.x > angCurrent.x ? 1 : -1
		angCurrent.x += iDir * flTurnRate

		if(iDir == 1 ? angCurrent.x > angGoal.x : angCurrent.x < angGoal.x)
			angCurrent.x = angGoal.x

		bMoving = true
	}
	self.SetPoseParameter(iPosePitch, angCurrent.x)

	if(angCurrent.y != angGoal.y)
	{
		local iDir = angGoal.y > angCurrent.y ? 1 : -1
		local flDist = fabs(angGoal.y - angCurrent.y)
		local bReversed = false
		if(!bClamp && flDist > 180.0)
		{
			flDist = 360.0 - flDist
			iDir = -iDir
			bReversed = true
		}

		if(iDir != iDirLast) flTurnRate = 0.0
		iDirLast = iDir

		angCurrent.y += iDir * flTurnRate

		if(iDir == -1 ? bReversed ? angGoal.y < angCurrent.y : angGoal.y > angCurrent.y : bReversed ? angGoal.y > angCurrent.y : angGoal.y < angCurrent.y)
			angCurrent.y = angGoal.y

		if(!bClamp)
		{
			if(angCurrent.y < 0.0)
				angCurrent.y += 360.0
			else if(angCurrent.y >= 360.0)
				angCurrent.y -= 360.0
		}
		else if(angCurrent.y > 180.0)
			angCurrent.y -= 360.0

		bMoving = true
	}
	self.SetPoseParameter(iPoseYaw, -angCurrent.y)

	bMoving ? flTurnRate >= 1 ? flTurnRate = 1 : flTurnRate += 0.1 : flTurnRate = 0
	
	//Stop Code
	if(angCurrent.x == angGoal.x && angCurrent.y == angGoal.y && state != states.OFF)
	{
		EmitSoundEx({ sound_name = snd_move, volume = 0.5, flags = 4, sound_level = 80, filter_type = 5, entity = self });;
		state = states.STOP
	}
	else if (state == states.STOP)
	{
		//If Stopped, resume sound
		EmitSoundEx({ sound_name = snd_move, volume = 0.5, sound_level = 80, pitch = 90, entity = self, filter_type = 5});
		state = states.LOOK
	}
	if (state == states.ON && state != states.LOOK)
	{
		//First Moving Sound
		EmitSoundEx({ sound_name = snd_move, volume = 0.5, sound_level = 80, pitch = 90, entity = self, filter_type = 5});
		state = states.LOOK
	}

    return -1
}
AddThinkToEnt(self, "Think")