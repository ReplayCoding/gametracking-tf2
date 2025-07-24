//simple manager for the seagull minigame


::SeagullCounter <- Entities.FindByName(null,"counter_seagull")
::SeagullSpawn <- function() {
   local Plushie = Entities.CreateByClassname("base_boss");
    Plushie.SetOrigin(self.GetOrigin());
    Plushie.SetAbsAngles(self.GetAbsAngles());
    Plushie.SetModel("models/props_pressure/seagull_plushie.mdl");
    Plushie.SetMaxHealth(999999);
    Plushie.SetHealth(999999);
    Plushie.SetSolid(2);
    NetProps.SetPropInt(Plushie, "m_bloodColor", -1)
	NetProps.SetPropInt(Plushie, "m_takedamage", 1);
    Plushie.SetBodygroup(RandomInt(0,1),RandomInt(0,1))
    Plushie.ResetSequence(Plushie.LookupSequence("ragdoll_sit" + RandomInt(1,3)))
	NetProps.SetPropBool(Plushie, "m_bForcePurgeFixedupStrings", true)
	NetProps.SetPropBool(self, "m_bForcePurgeFixedupStrings", true)
    self.Kill()
}

//Make bread reward the player :D - LazerSofa
local BreadMDLS = [
	"models/weapons/c_models/c_bread/c_bread_cornbread.mdl" 
	"models/weapons/c_models/c_bread/c_bread_crumpet.mdl" 
	"models/weapons/c_models/c_bread/c_bread_burnt.mdl"
	"models/weapons/w_models/w_breadmonster/w_breadmonster.mdl"
]

const SND_Breadshoot = "weapons/dumpster_rocket_reload.wav"
const SND_BreadVol = 95
PrecacheSound(SND_Breadshoot)

::BreadReward <- function() {

	local RareBread = false
	local RandomOriginName = "vfx_winfetti_b" + RandomInt(1,2)
	local RandomOrigin = Entities.FindByName(null, RandomOriginName)
	local RandomAngles = RandomOrigin.GetAbsAngles()
	local Flipped = false
	if (RandomOriginName == "vfx_winfetti_b1")
		Flipped = true
	local BreadFinalMDL = BreadMDLS[RandomInt(0,BreadMDLS.len() - 1)]
	if ( BreadFinalMDL == "models/weapons/w_models/w_breadmonster/w_breadmonster.mdl")
		RareBread = true

	local Bread = SpawnEntityFromTable("prop_physics_override", {
		origin       = RandomOrigin.GetOrigin() + Vector(10,0,0)
		angles 		 = RareBread ? RandomAngles : Vector(0,0,0),
		model 		 = BreadFinalMDL,
		physdamagescale = 0.1,
	})
	NetProps.SetPropBool(Bread, "m_bForcePurgeFixedupStrings", true)
	Bread.SetCollisionGroup(1)
	Bread.SetMaxHealth(5000)
	Bread.SetHealth(5000)
	NetProps.SetPropInt(Bread, "m_takedamage", 2);
	Bread.SetPhysVelocity(Vector(0, Flipped ? 150 : -150,0))
	EmitSoundEx({ sound_name = SND_Breadshoot, volume = 1, sound_level = SND_BreadVol, pitch = RandomInt(120,150), entity = Bread, filter_type = 5});
	if ( RareBread )
	{
		EmitSoundEx({ sound_name = "weapons/breadmonster/sapper/bm_sapper_scream_0" + RandomInt(1,2) + ".wav", volume = 1, sound_level = SND_BreadVol, pitch = RandomInt(90,160), entity = Bread, filter_type = 5});	
		Bread.SetModelScale( RandomFloat(1.5,3.5), 0)
	}
	EntFireByHandle(Bread, "Addoutput", "renderfx 5" , 6.1, null, null);
	EntFireByHandle(Bread, "Kill", "" , 7.1, null, null);
}


if (!("Seagullgame_Events" in getroottable()))
	::Seagullgame_Events <- {};
::Seagullgame_Events.clear();
::Seagullgame_Events =
{
	OnScriptHook_OnTakeDamage = function(params)
	{
		local victim = params.const_entity;
		local inflictor = params.inflictor;
		if ( victim.GetClassname() == "base_boss" && victim.GetModelName() == "models/props_pressure/seagull_plushie.mdl") 
		{
			params.damage = 0
			NetProps.SetPropInt(victim, "m_takedamage", 0);
			victim.BecomeRagdollOnClient(params.damage_force)
			SeagullCounter.AcceptInput("Add", "1", null, null);
		}
	}
}
__CollectGameEventCallbacks(Seagullgame_Events)