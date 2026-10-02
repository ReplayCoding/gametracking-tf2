function Precache()
{
	foreach(model, table in PUMPKINMODELS) { PrecacheModel(model) }

	PrecacheModel(PUMPKINEXPLODEMODEL)
	PrecacheModel(PUMPKINPICKUPPOTIONMODEL)

	PrecacheSound(PUMPKINAPPEARSOUND)
	PrecacheSound(PUMPKINEXPLODESOUND)

	PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = PUMPKINAPPEARPARTICLE })

	foreach (sound in PUMPKINGIGGLESOUNDS) { PrecacheSound(sound) }
}

Precache()
