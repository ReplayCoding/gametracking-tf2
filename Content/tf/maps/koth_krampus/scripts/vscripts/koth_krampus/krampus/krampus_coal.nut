//=========================================================================
//Copyright LizardOfOz.
//=========================================================================

barrageTargetSpots <- [];

function InitiateCoalBarrage()
{
    EntFireByHandle(self, "RunScriptCode", "FindCoalBarrageSpots()", 1, null, null);

    EmitSoundEx({
        sound_name = "ambient/fireball.wav",
        origin = krampusOrigin,
        volume = 1,
        soundlevel = 150,
        flags = 1,
        channel = 6
    });

    local particle = SpawnEntityFromTable("info_particle_system", {
        effect_name = "kr_eruption_parent",
        origin = krampusOrigin - krampusForwardVector * 40 + Vector(0, 0, 170),
        start_active = 1
    })
    EntFireByHandle(particle, "SetParent", "!activator", -1, krampus, krampus);
    EntFireByHandle(particle, "Kill", "", 2.5, krampus, krampus);
}

function FindCoalBarrageSpots()
{
    EntFireByHandle(self, "RunScriptCode", "RainCoalBarrage()", 2, null, null);

    barrageTargetSpots = [];
    for(local i = 0; i < 50 ; i++)
    {
        local coalPieceOrigin = Vector(
            RandomFloat(KRAMPUS_ARENA_MIN.x,KRAMPUS_ARENA_MAX.x),
            RandomFloat(KRAMPUS_ARENA_MIN.y,KRAMPUS_ARENA_MAX.y),
            1000);

        local fraction = TraceLine(coalPieceOrigin, coalPieceOrigin - Vector(0, 0, 1100), null);
        if (fraction < 0.8)
            continue;
        barrageTargetSpots.push(coalPieceOrigin);

        local loc = coalPieceOrigin - Vector(0, 0, 1095 * fraction);
        if (loc.z < -32)
            loc.z = -32;
        EntFireByHandle(SpawnEntityFromTable("info_particle_system", {
            effect_name = "kr_landing_parent",
            origin = loc,
            angles = "180 0 0",
            start_active = 1,
        }), "Kill", "", 5, null, null);
    }
}

function RainCoalBarrage()
{
    krampusLauncher.SetAbsAngles(QAngle(90, 0, 0));
    foreach (targetSpot in barrageTargetSpots)
    {
        krampusLauncher.SetAbsOrigin(targetSpot);

        local delay = RandomFloat(0, 1);
        EntFireByHandle(krampusLauncher, "AddOutput", "origin "+targetSpot.x+" "+targetSpot.y+" 1000", delay, krampus, krampus);
        EntFireByHandle(krampusLauncher, "FireOnce", "", delay, krampus, krampus);
    }
}

function TickAllCoalProjectiles()
{
    try
    {
        for(local rocket = null; rocket = Entities.FindByClassname(rocket, "tf_projectile_rocket");)
            if (GetPropEntity(rocket, "m_hOriginalLauncher") == krampusLauncher)
                TickCoalProjectile(rocket);
    }
    catch(e) { }
}

function TickCoalProjectile(rocket)
{
    local skin = rocket.GetSkin();
    if (skin == 10) //Coal Barrage Projectiles have skin 10 after being initialized
        return;
    skin = GetPropInt(rocket, "m_iDeflected") ? 4 : skin;
    if (skin == 3)
        return;
    if (skin == 4)
        SetPropInt(rocket, "m_bCritical", 1);

    //When a coal projectile spawns, it has skin 0. So, this is an "init a projectile" sequence
    if (skin == 0)
    {
        rocket.SetTeam(5);
        rocket.SetSkin(3);
        rocket.SetModelScale(3, -1);

        if (rocket.GetOrigin().z > 900)
        {
            local forward = Vector(0, 0, RandomInt(-600, -450));
            rocket.SetForwardVector(forward);
            rocket.SetAbsVelocity(forward);
            rocket.SetSkin(10);
        }
        else
        {
            local target = PickTargetInSight();
            if (!target)
            {
                rocket.Kill();
                return;
            }

            rocket.SetAbsOrigin(rocket.GetOrigin() + Vector(RandomInt(-25, 25), RandomInt(-25, 25), RandomInt(25, 25)));
            rocket.ValidateScriptScope();
            rocket.GetScriptScope().target <- target;

            local forward = krampusForwardVector * 100 + Vector(RandomInt(-50, 50), RandomInt(-50, 50), RandomInt(100, 200));
            rocket.SetForwardVector(forward);
            rocket.SetAbsVelocity(forward);

            EntFireByHandle(rocket, "RunScriptCode", "if (self && self.IsValid()) self.SetSkin(1)", 0.1, null, null);
            EntFireByHandle(rocket, "RunScriptCode", "if (self && self.IsValid()) self.SetSkin(2)", 2, null, null);

            EmitSoundLP(target, krampus, PickRandomSound(VO_COAL_THROW));
        }
        return;
    }

    local target = skin == 4 ? krampus : rocket.GetScriptScope().target;
    if (!IsValidPlayer(target) && (target != krampus || !krampus))
    {
        EntFireByHandle(rocket, "Kill", "", -1, null, null);
        return;
    }

    local deltaVector = target.EyePosition() - rocket.GetOrigin();
    if (deltaVector.Norm() < 200)
    {
        rocket.SetSkin(3);
        return;
    }

    //This makes a coal piece have a limited turn speed
    local forward = rocket.GetForwardVector();
    local newForward = forward + (deltaVector - forward) * (0.04 * skin);
    newForward.Norm();
    rocket.SetForwardVector(newForward);
    rocket.SetAbsVelocity(newForward * 450);
}