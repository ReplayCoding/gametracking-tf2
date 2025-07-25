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
    sentryDamageAccumulated = 0;
    lastHitSentry = null;
    usingMiniSentry = false;

    function CanApply()
    {
        if (player.GetPlayerClass() == TF_CLASS_ENGINEER)
        {
            local melee = player.GetWeaponBySlot(TF_WEAPONSLOTS.MELEE);
            usingMiniSentry = melee && melee.GetClassname() == "tf_weapon_robot_arm";
            return true;
        }
        return false;
    }

    function OnDamageDealt(victim, params)
    {
        if (params.inflictor != null && params.inflictor.GetClassname() == "obj_sentrygun" && player != victim)
        {
            //Nerfing damage and knockback by 50%.
            //There's an attribute that gives sentry resistance, but it doesn't give knockback res
            //Mini-sentries deal 80%.
            params.damage *= usingMiniSentry ? 0.8 : 0.5;
            lastHitSentry = params.inflictor;
        }
        else
            lastHitSentry = null;
    }

    function OnHurtDealtEvent(victim, params)
    {
        if (lastHitSentry != null)
        {
            //Frontier Justice crits.
            sentryDamageAccumulated += params.damageamount;
            while (sentryDamageAccumulated >= 200)
            {
                AddPropInt(lastHitSentry, "SentrygunLocalData.m_iAssists", 1);
                sentryDamageAccumulated -= 200;
            }
        }
    }

    //This is how we keep Engineer Buildings during Sudden Death - we turn Sudden Death off until the end of the frame.
    function OnDeath(attacker, params)
    {
        SetPropInt(tf_gamerules, "m_iRoundState", 0);
        RunWithDelay("SetPropInt(tf_gamerules, `m_iRoundState`, 7)", null, 0);
    }
});