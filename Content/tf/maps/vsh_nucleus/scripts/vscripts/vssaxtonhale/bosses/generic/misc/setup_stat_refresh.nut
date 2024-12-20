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

::CalcBossMaxHealth <- function(enemyCount)
{
    //Thanks Megascatterbomb for the new health formula!
    local linearCutoff = 23;
    if (enemyCount < 2)
        return 1000;
    local unrounded;
    if (enemyCount <= linearCutoff)
    {
        local constant = 2800 * clampCeiling(1.0, 0.3 + (enemyCount / 10.0));
        unrounded = enemyCount * enemyCount * 45 + constant;
    }
    else
    {
        local baseHealth = 26600;
        local increment = 2000;
        unrounded = baseHealth + (increment * (enemyCount - linearCutoff));
    }
    return floor(unrounded / 100) * 100;
}

::RefreshBossSetup <- function(boss)
{
    local maxHealth = CalcBossMaxHealth(GetValidPlayerCount() - 1);
    boss.SetHealth(maxHealth);
    boss.SetMaxHealth(maxHealth);
    boss.RemoveCustomAttribute("max health additive bonus");
    boss.AddCustomAttribute("max health additive bonus", maxHealth - 300, -1);
    bosses[boss].startingHealth = maxHealth;
    ::startMercCount <- GetAliveMercCount();
}

class SetupStatRefreshTrait extends BossTrait
{
    function OnDamageTaken(attacker, params)
    {
        if (IsRoundSetup())
        {
            params.damage = 0;
            params.early_out = true;
        }
    }

	function OnTickAlive(timeDelta)
    {
        if (!IsRoundSetup())
            return;

        RefreshBossSetup(boss);
	}
};