::main_script <- this;

IncludeScript("koth_slime/config.nut");
IncludeScript("koth_slime/player_tracker.nut");
IncludeScript("koth_slime/salmann_spawn.nut");
IncludeScript("koth_slime/slime_effect.nut");
IncludeScript("koth_slime/ontakedamage.nut");
IncludeScript("koth_slime/health_can.nut");

function Think()
{
    RecachePlayers();
    ThinkSlimeStatusEffect();
    NoSmallZombies();
    RerollSkeletonSpell();

    return 0;
}

function NoSmallZombies()
{
    local skullsToKill = [];
    local skull = null;
    while (skull = Entities.FindByClassname(skull, "tf_projectile_spellspawnzombie"))
        skullsToKill.push(skull);
    foreach (ent in skullsToKill)
        ent.Kill();
}

function RerollSkeletonSpell()
{
    local spellbook = null;
    while (spellbook = Entities.FindByClassname(spellbook, "tf_weapon_spellbook"))
    {
        if (NetProps.GetPropInt(spellbook, "m_iSelectedSpellIndex") == 11) //Skeletons
        {
            NetProps.SetPropInt(spellbook, "m_iSelectedSpellIndex", 0); //Fireball
            NetProps.SetPropInt(spellbook, "m_iSpellCharges", 2);
        }
    }
}