//======================================================================================================
//This section prevents the truck and the truckbed from detaching from each other.
//If the truck is too far ahead, we temporarily disable the capture zone and put the truck in reverse.
//If the truckbed is clipping into the truck too much, we move the truck forward a bit
//and also temporarily disable the capture zone.
//======================================================================================================

truck_car <- Entities.FindByName(null, "truck_train");
truck_bed <- Entities.FindByName(null, "flatbed_tracktrain");
blockedTS <- 0;
blockedTS2 <- 0;

function ThinkTruckFix()
{
    local distSquare = (truck_car.GetCenter() - truck_bed.GetCenter()).Length2DSqr();
    if (distSquare > 122500) //350^2
    {
        if (blockedTS < 1)
            blockedTS = Time() + 10;
        DoEntFire("flatbed_tracktrain", "setspeeddiraccel", "0.4", 0.5, null, null);
        DoEntFire("truck_city_capzone", "DisableAndEndTouch", "", 0, null, null);
    }
    else if (distSquare < 40000) //200^2
    {
        if (blockedTS2 < 1)
            blockedTS2 = Time() + 10;
        DoEntFire("truck_train", "setspeeddiraccel", "0.4", 0.5, null, null);
        DoEntFire("truck_city_capzone", "DisableAndEndTouch", "", 0, null, null);
    }
    else if (blockedTS > 1 && (distSquare < 90000 || Time() > blockedTS) //300^2
        || (blockedTS2 > 1 && (distSquare > 75000 || Time() > blockedTS2))) //275^2
    {
        blockedTS = 0;
        blockedTS2 = 0;
        DoEntFire("flatbed_tracktrain", "setspeeddiraccel", "0", 0, null, null);
        DoEntFire("truck_train", "setspeeddiraccel", "0", 0, null, null);
        DoEntFire("truck_city_capzone", "Enable", "", 0.5, null, null);
    }
    return blockedTS + blockedTS2 > 0 ? 0.2 : 1;
}

//====================================================================================================
//Because helicopter's arrival sequence is an animation,
//its collision doesn't work well against certain projectiles unless we do some fixes.
//====================================================================================================

function FixChopperPhysics()
{
    for (local ent = null; ent = Entities.FindByName(ent, "chopper_physics");)
        ent.SetAbsOrigin(ent.GetOrigin() - Vector(0, 0, 1024));
    for (local ent = null; ent = Entities.FindByName(ent, "propellor_physic");)
        ent.SetAbsOrigin(ent.GetOrigin() - Vector(0, 0, 1024));
}

//===========================================================================================
//Here we make the tanks near B tilt so that both tracks stay connected to the ground.
//===========================================================================================

function MakeTankTilt()
{
    activator.ValidateScriptScope();
    activator.GetScriptScope().TankTiltThink <- TankTiltThink;
    activator.GetScriptScope().heightDiff <- 0;
    AddThinkToEnt(activator, "TankTiltThink");
}

function TankTiltThink()
{
    local right = self.GetRightVector() * 80;
    local origin = self.GetOrigin();
    local wheels = [];
    foreach (sample in [
        origin + right + Vector(0, 0, 10),
        origin - right
    ])
    {
        local trace = {
            start = sample + Vector(0, 0, 20),
            end = sample - Vector(0, 0, 200),
            mask = 1
        };
        TraceLineEx(trace);
        wheels.push(trace.pos.z);
    }
    heightDiff += ((wheels[1] - wheels[0]) * 0.5 - heightDiff) * 0.05;
    local angles = self.GetAbsAngles();
    self.KeyValueFromVector("angles", Vector(angles.Pitch(), angles.Yaw(), heightDiff));

    return -1;
}