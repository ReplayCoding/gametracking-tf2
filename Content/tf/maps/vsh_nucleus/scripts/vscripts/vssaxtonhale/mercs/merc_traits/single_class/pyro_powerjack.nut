//=========================================================================
//Copyright LizardOfOz.
//
//Credits:
//  LizardOfOz - Programming, game design, promotional material and overall development. The original VSH Plugin from 2010.
//  Maxxy - Saxton Hale's model imitating Jungle Inferno SFM; Custom animations and promotional material.
//  Velly - VFX, animations scripting, technical assistance.
//  JPRAS - Saxton model development assistance and feedback.
//  MegapiemanPHD - Saxton Hale and Gray Mann voice acting.
//  James McGuinn - Mercenaries voice acting for custom lines.
//  Yakibomb - give_tf_weapon script bundle (used for Hale's first-person hands model).
//  Phe - game design assistance.
//=========================================================================

characterTraitsClasses.push(class extends CharacterTrait
{
    function CanApply()
    {
        return player.GetPlayerClass() == TF_CLASS_PYRO
            && WeaponIs(player.GetWeaponBySlot(TF_WEAPONSLOTS.MELEE), "powerjack");
    }

    function OnDamageDealt(victim, params)
    {
        if (params.damage_type & 128 && player.GetHealth() < player.GetMaxHealth())
            player.SetHealth(clampCeiling(player.GetHealth() + 25, player.GetMaxHealth()));
    }
});