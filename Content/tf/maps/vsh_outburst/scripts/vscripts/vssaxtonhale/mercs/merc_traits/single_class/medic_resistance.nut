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
        return player.GetPlayerClass() == TF_CLASS_MEDIC;
    }

    function OnDamageTaken(attacker, params)
    {
        if (IsValidBoss(attacker))
        {
            params.damage *= 0.7;
            local deltaVector = player.GetOrigin() - attacker.GetOrigin();
            deltaVector.z = 0;
            deltaVector.Norm();
            player.Yeet(deltaVector * 600 + Vector(0, 0, 450));
            params.damage_type = params.damage_type | DMG_PREVENT_PHYSICS_FORCE;
        }
    }
});