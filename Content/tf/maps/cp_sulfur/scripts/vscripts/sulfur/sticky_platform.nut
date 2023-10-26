// Stickybomb Sticker
// By Sarexicus, for CP_Sulfur

// Stickybombs hate sticking to moving objects, so this script will
//  parent them while the final point is moving, and then decouple them afterwards
//  to allow them to be airblasted.

sticker_active <- false;

function StartStick() {
    sticker_active = true;
}

function EndStick() {
    sticker_active = false;
    UnstickStickies();
}

function Within(a, mins, maxs) {
    return (a.x > mins.x && a.y > mins.y && a.z > mins.z
        && a.x < maxs.x && a.y < maxs.y && a.z < maxs.z);
}

function StickStickies() {
    local ent = null;
    while(ent = Entities.FindByName(ent, "sticky_sticker")) {
        local parent = ent.GetMoveParent();

        ent.ValidateScriptScope();
        local scope = ent.GetScriptScope();
        scope.stickies <- [];

        local eorg = ent.GetOrigin();
        local mins = eorg + ent.GetBoundingMins();
        local maxs = eorg + ent.GetBoundingMaxs();

        local sticky = null;
        while(sticky = Entities.FindByClassname(sticky, "tf_projectile_pipe_remote")) {

            local org = sticky.GetOrigin();
            if(Within(org, mins, maxs)) {
                scope.stickies.push(sticky);
                EntFireByHandle(sticky, "SetParent", "!activator", 0, parent, parent);
            }

        }
    }
}

function Think() {
    if(sticker_active) {
        StickStickies();
    }
    return 0.1;
}

function UnstickStickies() {
    local ent = null;
    while(ent = Entities.FindByName(ent, "sticky_sticker")) {
        ent.ValidateScriptScope();
        local scope = ent.GetScriptScope();
        if(!scope.rawin("stickies")) continue;

        foreach(sticky in scope.stickies) {
            if(sticky == null || !sticky.IsValid()) continue;
            sticky.SetAbsVelocity(Vector(0,0,0));
            EntFireByHandle(sticky, "ClearParent", "", 0, null, null);
        }

        scope.stickies <- [];
    }
}