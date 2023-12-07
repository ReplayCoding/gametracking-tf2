//=========================================================================
//Copyright LizardOfOz.
//=========================================================================

IncludeScript("koth_krampus/krampus/krampus_nav.nut");
IncludeScript("koth_krampus/krampus/krampus_states.nut");
IncludeScript("koth_krampus/krampus/krampus_target.nut");
IncludeScript("koth_krampus/krampus/krampus_coal.nut");

self.KeyValueFromFloat("speed", 321);
EntFireByHandle(self, "SetStepHeight", "1", -1, null, null);
SetPropVector(self, "m_vecViewOffset", Vector(0, 0, 175));

prevKrampusOrigin <- self.GetOrigin();
::krampusOrigin <- self.GetOrigin();
::krampusForwardVector <- self.GetForwardVector();

::krampusTarget <- null;
::targetOrigin <- null;

stuckTicks <- 0;
targetPickTicks <- 0;
::lpvoTimeStamps <- player_collection(Time() + 19);
lastThrowTimeStamp <- Time() + 19;

krampusCoalTossCounter <- 0;
krampusBarrageCounter <- 0;

::krampusLauncher <- SpawnEntityFromTable("tf_point_weapon_mimic",
{
    WeaponType = 0,
    SpeedMin = 300,
    SpeedMax = 300,
    Damage = 50,
    SplashRadius = 100,
    teamnum = self.GetTeam(),
    ModelOverride = COAL_MODEL,
    Crits = false
})
krampusLauncher.SetOwner(self);
krampusLauncher.SetTeam(self.GetTeam());

function KrampusThink()
{
    if (!krampus || !krampus.IsValid())
        return -1;

    if (!IsDying() && krampus.GetHealth() <= 1000)
        krampus.GetScriptScope().SetState(DeathState());

    krampusOrigin = self.GetOrigin();
    krampusForwardVector = self.GetForwardVector();
    targetOrigin = null;
    if (IsValidPlayer(krampusTarget))
        targetOrigin = krampusTarget.GetOrigin();
    else
        SetNewTarget(null);
    state.ThinkInner();
    if (!krampus || !krampus.IsValid())
        return -1;
    self.StudioFrameAdvance();

    //try
    //{
        if (IsActive())
        {
            ProcessBeingStuck();
            local hpBar = clamp(255.0 * GetKrampusHealth() / GetKrampusMaxHealth(), 1, 255);
            SetPropInt(monster_resource, "m_iBossHealthPercentageByte", hpBar);
            if (targetPickTicks++ > 66)
            {
                targetPickTicks = 0;
                LookForTarget();
            }
            if (targetPickTicks % 11 == 0)
                ProcessScreenShake();
        }
    //}
    //catch(e) { }

    TickAllCoalProjectiles();

    return -1;
}

function ProcessBeingStuck()
{
    if (!krampusTarget)
        return;
    if ((krampusOrigin - prevKrampusOrigin).Length2D() < 1)
    {
        if (stuckTicks++ > 100 && (targetOrigin - krampusOrigin).Length() > 200)
        {
            stuckTicks = 0;
            SetNewTarget(PickTarget());
        }
    }
    else
    {
        prevKrampusOrigin = krampusOrigin;
        stuckTicks = 0;
    }
}

function GetKrampusHealth()
{
    return krampus && krampus.IsValid() ? krampus.GetHealth() - 1000 : 0;
}

function GetKrampusMaxHealth()
{
    return krampus && krampus.IsValid() ? krampus.GetMaxHealth() - 1000 : 0;
}

function ProcessScreenShake()
{
    ScreenShake(krampusOrigin, 2, 5, 0.5, 1700, 0, true);
    ScreenShake(krampusOrigin, 4, 5, 0.5, 1200, 0, true);
}