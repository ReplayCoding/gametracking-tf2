//Taken from the VScript examples page at https://developer.valvesoftware.com/wiki/Team_Fortress_2/Scripting/VScript_Examples#Using_the_TakeDamageCustom_function

// Ensure only one of this entity is ever spawned
if (!("freeze_proxy_weapon" in getroottable()))
{
	::freeze_proxy_weapon <- null

	::freeze_immune_conds <-
	[
		Constants.ETFCond.TF_COND_INVULNERABLE,
		Constants.ETFCond.TF_COND_PHASE,
		Constants.ETFCond.TF_COND_INVULNERABLE_HIDE_UNLESS_DAMAGED,
		Constants.ETFCond.TF_COND_INVULNERABLE_USER_BUFF,
		Constants.ETFCond.TF_COND_INVULNERABLE_CARD_EFFECT,
	]
}

// Create the fake weapon if one doesn't already exist
if (!freeze_proxy_weapon || !freeze_proxy_weapon.IsValid())
{
	freeze_proxy_weapon = Entities.CreateByClassname("tf_weapon_knife")
	NetProps.SetPropInt(freeze_proxy_weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", 649)
	NetProps.SetPropBool(freeze_proxy_weapon, "m_AttributeManager.m_Item.m_bInitialized", true)
	freeze_proxy_weapon.DispatchSpawn()
	freeze_proxy_weapon.DisableDraw()

	// Add the attribute that creates ice statues
	freeze_proxy_weapon.AddAttribute("freeze backstab victim", 1.0, -1.0)
}

function Precache()
{
	// Add an output to deal damage when the trigger is touched
	self.ConnectOutput("OnStartTouch", "Freeze")
}

function Freeze()
{
	// Remove conditions that give immunity to damage
	foreach (cond in freeze_immune_conds)
		activator.RemoveCondEx(cond, true)

	// Set any owner on the weapon to prevent a crash
	NetProps.SetPropEntity(freeze_proxy_weapon, "m_hOwner", activator)

	// Deal the damage with the weapon
	activator.TakeDamageCustom(activator, activator, freeze_proxy_weapon,
								Vector(0,0,-9999999), Vector(0,0,0),
								99999.0, Constants.FDmgType.DMG_FALL, Constants.ETFDmgCustom.TF_DMG_CUSTOM_BACKSTAB)

	// I don't remember why this is needed but it's important
	local ragdoll = NetProps.GetPropEntity(activator, "m_hRagdoll")
	if (ragdoll)
		NetProps.SetPropInt(ragdoll, "m_iDamageCustom", 0)
}