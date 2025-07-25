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

PrecacheArbitrarySound("vsh_sfx.shield_break");
PrecacheArbitrarySound("demo.shield")
PrecacheArbitrarySound("demo.shield_lowhp")

characterTraitsClasses.push(class extends CharacterTrait
{
    wasDestroyed = false;
    function CanApply()
    {
        if (player.GetPlayerClass() != TF_CLASS_DEMOMAN)
            return false;
        local wearable = null;
        while (wearable = FindByClassname(wearable, "tf_wearable_demo*"))
            if (wearable.GetOwner() == player)
            {
                wearable.EnableDraw();
                return true;
            }
        return false;
    }

    function OnDamageTaken(attacker, params)
    {
        if (wasDestroyed || !IsValidBoss(attacker) || player.InCond(TF_COND_INVULNERABLE))
            return;

        if ((params.damage_type == 1 || params.damage_type == DMG_BLAST) && params.damage < player.GetHealth())
            return;

        local isSaxtonPunch = params.inflictor == custom_dmg_saxton_punch;
        wasDestroyed = true;
        player.AddCondEx(TF_COND_PREVENT_DEATH, 0, null);
        //Note: Saxton Punch!'s collateral will NOT be resisted. Adding extra-extra resistance to make up for it.
        params.damage *= isSaxtonPunch ? 0.2 : 0.5;

        local wearable = null;
        while (wearable = FindByClassname(wearable, "tf_wearable_demo*"))
            if (wearable.GetOwner() == player)
            {
                wearable.DisableDraw();
                break;
            }

        local deltaVector = player.GetCenter() - attacker.GetCenter();
        deltaVector.z = 0;
        deltaVector.Norm();
        player.Yeet(deltaVector * 600 + Vector(0, 0, 450));

        EmitSoundOn("vsh_sfx.shield_break", player);

        if (isSaxtonPunch)
            EmitPlayerVODelayed(player, "shield_lowhp", 1);
        else
            EmitPlayerVODelayed(player, "shield", 1);
    }
});