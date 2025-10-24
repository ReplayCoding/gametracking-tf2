//By LizardOfOz
//Feel free to use

//0 Fireball
//1 Ball of Bats
//2 Overheal / Short Uber
//3 Pumpkin M.I.R.V.
//4 Super Jump
//5 Invisibility
//6 Teleport
//7 Tesla Bolt
//8 Minify
//9 Summon Monoculus
//10 Meteor Shower
//11 Summon Skeletons

//Modify these
SPELL_TO_REPLACE <- 8;
REPLACEMENT_SPELL <- 6;
REPLACEMENT_CHARGES <- 1;

//Don't modify these
GetPropInt <- ::NetProps.GetPropInt.bindenv(::NetProps);
SetPropInt <- ::NetProps.SetPropInt.bindenv(::NetProps);
FindByClassname <- ::Entities.FindByClassname.bindenv(::Entities);

function Think()
{
    for (local spellbook = null; spellbook = FindByClassname(spellbook, "tf_weapon_spellbook");)
    {
        if (GetPropInt(spellbook, "m_iSelectedSpellIndex") == SPELL_TO_REPLACE)
        {
            SetPropInt(spellbook, "m_iSelectedSpellIndex", REPLACEMENT_SPELL);
            SetPropInt(spellbook, "m_iSpellCharges", REPLACEMENT_CHARGES);
        }
    }

    return -1;
}