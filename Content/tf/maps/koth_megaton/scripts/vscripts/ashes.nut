// Ensure only one of this entity is ever spawned
if (!("disintegrate_proxy_weapon" in getroottable()))
{
    ::disintegrate_proxy_weapon <- null;
	
    ::disintegrate_immune_conds <- 
    [
        Constants.ETFCond.TF_COND_INVULNERABLE,
        Constants.ETFCond.TF_COND_PHASE,
        Constants.ETFCond.TF_COND_INVULNERABLE_HIDE_UNLESS_DAMAGED,
        Constants.ETFCond.TF_COND_INVULNERABLE_USER_BUFF,
        Constants.ETFCond.TF_COND_INVULNERABLE_CARD_EFFECT,
    ];
}

// Create the fake weapon if one doesn't already exist
if (!disintegrate_proxy_weapon || !disintegrate_proxy_weapon.IsValid())
{
    disintegrate_proxy_weapon = Entities.CreateByClassname("tf_weapon_bat");
    NetProps.SetPropInt(disintegrate_proxy_weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", 349);
    NetProps.SetPropBool(disintegrate_proxy_weapon, "m_AttributeManager.m_Item.m_bInitialized", true);
    disintegrate_proxy_weapon.DispatchSpawn();
	disintegrate_proxy_weapon.DisableDraw();
	
	// Add the attribute that creates disintegration
    disintegrate_proxy_weapon.AddAttribute("ragdolls become ash", 1.0, -1.0);
}

function Precache()
{
	// Add an output to deal damage when the trigger is touched
    self.ConnectOutput("OnStartTouch", "Disintegrate");
}

function Disintegrate()
{
	// Remove conditions that give immunity to damage
    foreach (cond in disintegrate_immune_conds)
        activator.RemoveCondEx(cond, true);
        
	// Set any owner on the weapon to prevent a crash
    NetProps.SetPropEntity(disintegrate_proxy_weapon, "m_hOwner", activator);
	
	// Deal the damage with the weapon
    activator.TakeDamageCustom(self, activator, disintegrate_proxy_weapon, 
                                Vector(0,0,0), Vector(0,0,0), 
                                99999.0, 2080, Constants.ETFDmgCustom.TF_DMG_CUSTOM_BURNING);
}