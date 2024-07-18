// Payload Last Point CP + Saw Rotation, for pl_odyssey
// by Sarexicus! (version 1.1)
// ----------------------------------

rotation_speed <- 5.0; // degrees per second that the saw will rotate

sound_saw_start <- "Odyssey.ArmStart";          // sound when the control point first starts getting captured
sound_saw_loop_up <- "Odyssey.ArmMoveRecede";   // looping sound when the saw is receding away from the cart
sound_saw_loop <- "Odyssey.SpinLP";             // looping sound for sawblade at all times
sound_saw_loop_down <- "Odyssey.ArmMoveLP";     // looping sound when the saw is moving towards the cart
sound_saw_end <- "Odyssey.ArmStop";             // sound when the control point capture progress fully recedes

// ----------------------------------

tf_gamerules <- Entities.FindByClassname(null, "tf_gamerules");
team_train_watcher <- Entities.FindByClassname(null, "team_train_watcher");
obj_res <- Entities.FindByClassname(null, "tf_objective_resource");
saw_rotator <- Entities.FindByName(null, "saw_rotator");
saw_rotate_sound_entity <- Entities.FindByName(null, "saw_blade");
last_cap_progress <- 1;
control_point_count <- 4;

saw_rotating <- false;
saw_direction <- true;
last_saw_direction <- true;
disable_saw <- false;

// ----------------------------------

ClearGameEventCallbacks();

function Precache() {
    PrecacheScriptSound(sound_saw_start);
    PrecacheScriptSound(sound_saw_loop);
    PrecacheScriptSound(sound_saw_loop_up);
    PrecacheScriptSound(sound_saw_loop_down);
    PrecacheScriptSound(sound_saw_end);
}

// make sure everything's initialised before doing the setup
EntFireByHandle(self, "CallScriptFunction", "Setup", 0, null, null);

function Setup() {
    NetProps.SetPropInt(tf_gamerules, "m_nHudType", 3);
    EntFireByHandle(team_train_watcher, "Enable", "", 0, null, null);

    NetProps.SetPropInt(obj_res, "m_iNumControlPoints", 4);

    for (local i = 0; i < control_point_count; i++) {
        NetProps.SetPropBoolArray(obj_res, "m_bCPIsVisible", true, i);
    }
    NetProps.SetPropBoolArray(obj_res, "m_bCPIsVisible", false, control_point_count);

    last_cap_progress = 1;
    EntFireByHandle(saw_rotator, "SetPosition", "0", 0, null, null);

    PlaySawLoop();
    StopSawLoopUp();
    StopSawLoopDown();
}

// swaps the HUD from payload to control points.
// disables the train watcher (prevents spectating the cart)
function SwapHud() {
    NetProps.SetPropInt(tf_gamerules, "m_nHudType", 2);
    EntFireByHandle(team_train_watcher, "Disable", "", 0, null, null);

    for (local i = 0; i < control_point_count; i++) {
        NetProps.SetPropBoolArray(obj_res, "m_bCPIsVisible", false, i);
    }
    NetProps.SetPropBoolArray(obj_res, "m_bCPIsVisible", true, control_point_count);

    NetProps.SetPropInt(obj_res, "m_iNumControlPoints", 5);
}

function SetCaptureProgress(index, value) { return NetProps.SetPropFloatArray(obj_res, "m_flCapPercentages", index, value); }
function GetCaptureProgress(index) { return NetProps.GetPropFloatArray(obj_res, "m_flCapPercentages", index); }

// Handles rotating the saw according to capture progress.
function Think() {
    local capping_team = NetProps.GetPropIntArray(obj_res, "m_iCappingTeam", 4);
    if(capping_team != 3) return;

    local progress = 1 - GetCaptureProgress(4);
    local progress_diff = progress - last_cap_progress;

    if (disable_saw) return;

    if(progress > 0.01) {
        if(!saw_rotating) {
            saw_rotating = true;
            PlaySawRotateStart();
            PlaySawLoopDown();
        }
    } else if (saw_rotating) {
        saw_rotating = false;
        PlaySawRotateEnd();
        StopSawLoopUp();
        StopSawLoopDown();
    }

    saw_direction = (progress > last_cap_progress);
    if (saw_rotating) {
        if (saw_direction != last_saw_direction) {
            if (!saw_direction) {
                StopSawLoopDown();
                PlaySawLoopUp();
            }
            else {
                StopSawLoopUp();
                PlaySawLoopDown();
            }
        }
    }
    last_saw_direction = saw_direction;

    if(progress != last_cap_progress) {
        // saw rotation is doubled if it's behind what it should be. this helps prevent jitter
        local speedvar = (progress_diff > 0.1) ? (rotation_speed * 2) : rotation_speed;
        if (progress < last_cap_progress) speedvar /= 2;
        NetProps.SetPropFloat(saw_rotator, "m_flSpeed", speedvar);

        last_cap_progress = progress;
        EntFireByHandle(saw_rotator, "SetPosition", progress.tostring(), 0, null, null);
    }

    return 0.1;
}

// Sound Management
// ----------------------------------

function PlayOneShotSound(sound_name) {
    EmitSoundEx({
        sound_name = sound_name,
        entity = saw_rotate_sound_entity,
        filter_type = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_GLOBAL
    });
}

function PlayLoopingSound(sound_name) {
    EmitSoundEx({
        sound_name = sound_name,
        channel = 6,
        origin = saw_rotate_sound_entity.GetOrigin(),
        filter_type = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_GLOBAL
    });
}

function StopLoopingSound(sound_name) {
    EmitSoundEx({
        sound_name = sound_name,
        flags = 4,
        channel = 6,
        origin = saw_rotate_sound_entity.GetOrigin(),
        filter_type = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_GLOBAL
    });
}

function PlaySawRotateStart() { PlayOneShotSound(sound_saw_start); }
function PlaySawRotateEnd() { PlayOneShotSound(sound_saw_end); }
function PlaySawLoopUp() { PlayLoopingSound(sound_saw_loop_up); }
function PlaySawLoopDown() { PlayLoopingSound(sound_saw_loop_down); }
function StopSawLoopUp() { StopLoopingSound(sound_saw_loop_up); }
function StopSawLoopDown() { StopLoopingSound(sound_saw_loop_down); }
function PlaySawLoop() { PlayLoopingSound(sound_saw_loop);}
function StopSawLoop() { StopLoopingSound(sound_saw_loop);}

// Events
// ----------------------------------

// stop looping the saw sounds in case the round restarts
function OnGameEvent_scorestats_accumulated_update(params) {
    StopSawLoopUp();
    StopSawLoopDown();
    StopSawLoop();
}

// stop looping the saw sounds when the round ends
function OnGameEvent_teamplay_round_win(params) {
    StopSawLoopUp();
    StopSawLoopDown();
    StopSawLoop();
    PlaySawRotateEnd();
    disable_saw = true;
}

__CollectGameEventCallbacks(this);