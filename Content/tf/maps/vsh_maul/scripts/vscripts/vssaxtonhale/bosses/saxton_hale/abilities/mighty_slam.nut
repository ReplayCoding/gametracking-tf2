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

PrecacheArbitrarySound("vsh_sfx.boss_slam_impact");
PrecacheArbitrarySound("vsh_sfx.slam_ready");

class MightySlamTrait extends BossTrait
{
    meter = 0;
    inUse = false;
    lastFrameDownVelocity = 0;

    function OnApply()
    {
        if (!(player in hudAbilityInstances))
            hudAbilityInstances[player] <- [];
        hudAbilityInstances[player].push(this);
    }

    function OnTickAlive(timeDelta)
    {
        if (meter < 0)
        {
            meter += timeDelta;
            if (meter > 0)
            {
                EmitSoundOnClient("vsh_sfx.slam_ready", boss);
                EmitSoundOnClient("TFPlayer.ReCharged", boss);
                meter = 0;
            }
        }
        if (!boss.IsOnGround() && (boss.GetFlags() & FL_DUCKING))
            Weightdown();
        else if (inUse && !(boss.GetFlags() & FL_DUCKING))
        {
            inUse = false;
            SetItemId(boss.GetActiveWeapon(), 5);
            boss.SetGravity(1);
            BossPlayViewModelAnim(boss, "f_idle");
        }
        else if (inUse && boss.IsOnGround())
        {
            inUse = false;
            SetItemId(boss.GetActiveWeapon(), 5);
            boss.SetGravity(1);
            if (meter >= 0 && lastFrameDownVelocity < (braveJumpCharges > 0 ? -300 : -500))
                Perform();
            else
                BossPlayViewModelAnim(boss, "f_idle");
        }
    }

    function Weightdown()
    {
        local origin = player.GetOrigin();
        local fraction = TraceLine(origin, origin + Vector(0, 0, -150), null);
        if (fraction < 1)
            return;
        inUse = true;
        boss.SetGravity(3);
        lastFrameDownVelocity = boss.GetAbsVelocity().z;
        if (meter >= 0)
        {
            BossPlayViewModelAnim(boss, "vsh_slam_fall");
            boss.AddCustomAttribute("no_attack", 1, 0.25);
            SetItemId(boss.GetActiveWeapon(), 264); //Frying Pan
        }
    }

    function Perform()
    {
        DispatchParticleEffect("vsh_mighty_slam", boss.GetOrigin() + Vector(0,0,20), Vector(0,0,0));
        EmitSoundOn("vsh_sfx.boss_slam_impact", boss);
        EmitSoundOn("Parachute_close", boss);
        EmitSoundOn("xmas.jingle_noisemaker", boss);
        lastFrameDownVelocity = 0;
        meter = -15;

        local bossLocal = boss;
        BossPlayViewModelAnim(boss, "vsh_slam_land");
        local weapon = boss.GetActiveWeapon();
        SetItemId(weapon, 444); //Mantreads
        CreateAoE(boss.GetCenter(), 500,
            function (target, deltaVector, distance) {
                local percentage = (1 - distance / 500);
                if (percentage > 0.75)
                    percentage = 0.75;
                local damage = target.GetMaxHealth() * percentage;
                if (!target.IsPlayer())
                    damage *= 2;
                if (damage <= 30 && target.GetHealth() <= 30)
                    return; // We don't want to have people on low health die because Hale just Slammed a mile away.
                custom_dmg_slam_collateral.SetAbsOrigin(bossLocal.GetOrigin());
                target.TakeDamageEx(
                    custom_dmg_slam_collateral,
                    bossLocal,
                    weapon,
                    deltaVector * 1250,
                    bossLocal.GetOrigin(),
                    damage,
                    DMG_BLAST);
            }
            function (target, deltaVector, distance) {
                local pushForce = distance < 100 ? 1 : 100 / distance;
                deltaVector.x = deltaVector.x * 1250 * pushForce;
                deltaVector.y = deltaVector.y * 1250 * pushForce;
                deltaVector.z = 950 * pushForce;
                target.Yeet(deltaVector);
            });

        SetItemId(weapon, 5);
        ScreenShake(boss.GetCenter(), 10, 2.5, 1, 1000, 0, true);
    }

    function MeterAsPercentage()
    {
        if (meter < 0)
            return (15 + meter) * 90 / 15;
        return inUse ? 200 : 100
    }

    function MeterAsNumber()
    {
        local mapped = -meter+0.99;
        if (mapped <= 1)
            return "r";
        if (mapped < 10)
            return format(" %d", mapped);
        else
            return format("%d", mapped);
    }
};