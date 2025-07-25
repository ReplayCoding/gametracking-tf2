function Bump()
{
	local radius = NetProps.GetPropFloat(caller, "m_radius");
	local origin = NetProps.GetPropVector(caller, "m_vecAbsOrigin");
	for(local ent; ent=Entities.FindByClassnameWithin(ent, "tf_projectile_pipe_remote", origin, radius);)
	{
		ent.TakeDamageEx(null, caller, null, Vector(0,0,-10001), Vector(0,0,0), 1, 64)
		ent.SetAbsVelocity(Vector(0,0,0))
	}
}

function BumpUp()
{
	local radius = NetProps.GetPropFloat(caller, "m_radius");
	local origin = NetProps.GetPropVector(caller, "m_vecAbsOrigin");
	for(local ent; ent=Entities.FindByClassnameWithin(ent, "tf_projectile_pipe_remote", origin, radius);)
	{
		ent.TakeDamageEx(null, caller, null, Vector(0,0, 10001), Vector(0,0,0), 1, 64)
		ent.SetAbsVelocity(Vector(0,0,0))
	}
}


function SoundCacher()
{
	PrecacheScriptSound("Player.AmbientUnderWater")
	PrecacheScriptSound("Rubber.StepLeft")
	PrecacheScriptSound("Rubber.StepRight")
	PrecacheSound("aquarius/water_whoosh02.mp3")
	PrecacheSound("aquarius/water_whoosh04.mp3")
	PrecacheSound("aquarius/water_whoosh06.mp3")
	PrecacheSound("aquarius/water_whoosh08.mp3")
	PrecacheSound("aquarius/water_whoosh10.mp3")
	PrecacheSound("aquarius/water_whoosh12.mp3")
	PrecacheSound("aquarius/water_flow01.mp3")
	PrecacheSound("aquarius/water_flow02.mp3")
	PrecacheSound("aquarius/water_flow03.mp3")
	PrecacheSound("aquarius/water_flow04.mp3")
	PrecacheSound("aquarius/water_flow05.mp3")	
	PrecacheSound("aquarius/deep01_loop.wav")
}