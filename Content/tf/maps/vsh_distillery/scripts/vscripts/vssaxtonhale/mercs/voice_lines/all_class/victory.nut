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

PrecacheClassVoiceLines("win")

AddListener("round_end", 0, function (winnerTeam)
{
    if (winnerTeam == TF_TEAM_MERCS)
        foreach (player in GetAliveMercs())
            if (RandomInt(0, 4) == 0)
                EmitPlayerVODelayed(player, "win", RandomInt(5, 6));
});