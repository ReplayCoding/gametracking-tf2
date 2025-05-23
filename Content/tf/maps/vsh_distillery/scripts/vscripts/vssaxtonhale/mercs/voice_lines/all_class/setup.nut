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

PrecacheClassVoiceLines("setup")

characterTraitsClasses.push(class extends CustomVoiceLine
{
    timesPlayedGlobal = [0];

    function OnApply()
    {
        if (timesPlayedGlobal[0] > 3 || RandomInt(0, 7) != 0)
            return;
        timesPlayedGlobal[0]++;
        EmitPlayerVODelayed(player, "setup", RandomInt(13, 15));
    }
});