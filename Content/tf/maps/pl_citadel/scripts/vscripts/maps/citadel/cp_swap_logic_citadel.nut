// Payload Last Point CP-Swap + Sounds, for pl_citadel
// by Sarexicus (version 0.1)
// ----------------------------------

rotation_speed <- 5.0; // degrees per second that the saw will rotate

sounds <- {
    sound_capture_start = "ambient/medieval_thunder2.wav",      // sound when capture starts from zero
    sound_capture_progress = "Ambient.NucleusElectricity",      // looping sound while capture is progressing
    sound_capture_recede = "",                                  // looping sound while capture is receding
    sound_capture_stop = "",                                    // sound when capture stops progressing at any point
    sound_capture_reset = "",                                   // sound when capture progress hits zero
}

sound_source_entity <- Entities.FindByName(null, "sound_source");

// ----------------------------------

tf_gamerules <- Entities.FindByClassname(null, "tf_gamerules");
team_train_watcher <- Entities.FindByClassname(null, "team_train_watcher");
obj_res <- Entities.FindByClassname(null, "tf_objective_resource");

last_cap_progress <- 1;
control_point_count <- 5;

capture_progressing <- false;
capture_direction <- true;
last_capture_direction <- true;
disable_capture_updates <- false;

// ----------------------------------

function Precache() {
    foreach(sound_name, sound_file in sounds) {
        if (sound_file != "")
            PrecacheScriptSound(sound_file);
    }
}

// make sure everything's initialised before doing the setup
EntFireByHandle(self, "CallScriptFunction", "Setup", 0, null, null);

function Setup() {
    NetProps.SetPropInt(tf_gamerules, "m_nHudType", 3);
    team_train_watcher.AcceptInput("Enable", "", null, null);

    NetProps.SetPropInt(obj_res, "m_iNumControlPoints", 5);

    for (local i = 0; i < control_point_count; i++) {
        NetProps.SetPropBoolArray(obj_res, "m_bCPIsVisible", true, i);
    }
    NetProps.SetPropBoolArray(obj_res, "m_bCPIsVisible", false, control_point_count);

    last_cap_progress = 1;

    // PlaySawLoop();
    // StopSawLoopUp();
    // StopSawLoopDown();
}

// swaps the HUD from payload to control points.
// disables the train watcher (prevents spectating the cart)
function SwapHud() {
    NetProps.SetPropInt(tf_gamerules, "m_nHudType", 2);
    team_train_watcher.AcceptInput("Disable", "", null, null);

    for (local i = 0; i < control_point_count; i++) {
        NetProps.SetPropBoolArray(obj_res, "m_bCPIsVisible", false, i);
    }
    NetProps.SetPropBoolArray(obj_res, "m_bCPIsVisible", true, control_point_count);

    NetProps.SetPropInt(obj_res, "m_iNumControlPoints", 6);

    disable_capture_updates = false;
}

function SetCaptureProgress(index, value) { return NetProps.SetPropFloatArray(obj_res, "m_flCapPercentages", index, value); }
function GetCaptureProgress(index) { return NetProps.GetPropFloatArray(obj_res, "m_flCapPercentages", index); }

// Handles rotating the saw according to capture progress.
function Think() {
    local capping_team = NetProps.GetPropIntArray(obj_res, "m_iCappingTeam", control_point_count);
    if(capping_team != 3) {
        if (capture_progressing) {
            capture_progressing = false;
            StopSoundCaptureRecede();
            StopSoundCaptureProgress();
        }
        return;
    }

    local progress = 1 - GetCaptureProgress(4);
    local progress_diff = progress - last_cap_progress;

    if (disable_capture_updates) return;

    if(progress > 0.01) {
        if(!capture_progressing) {
            capture_progressing = true;
            PlaySoundCaptureStart();
            PlaySoundCaptureProgress();
        }
    } else if (capture_progressing) {
        capture_progressing = false;
        PlaySoundCaptureReset();
        StopSoundCaptureRecede();
        StopSoundCaptureProgress();
    }

    capture_direction = (progress > last_cap_progress);
    if (capture_progressing) {
        if (capture_direction != last_capture_direction) {
            if (!capture_direction) {
                StopSoundCaptureProgress();
                PlaySoundCaptureRecede();
            }
            else {
                StopSoundCaptureRecede();
                PlaySoundCaptureProgress();
            }
        }
    }
    last_capture_direction = capture_direction;
    return 0.1;
}

// Sound Management
// ----------------------------------

function PlayOneShotSound(sound_name) {
    if(sound_name == "") return;
    EmitSoundEx({
        sound_name = sound_name,
        entity = sound_source_entity,
        filter_type = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_GLOBAL
    });
}

function PlayLoopingSound(sound_name) {
    if(sound_name == "") return;
    EmitSoundEx({
        sound_name = sound_name,
        channel = 6,
        origin = sound_source_entity.GetOrigin(),
        filter_type = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_GLOBAL
    });
}

function StopLoopingSound(sound_name) {
    if(sound_name == "") return;
    EmitSoundEx({
        sound_name = sound_name,
        flags = 4,
        channel = 6,
        origin = sound_source_entity.GetOrigin(),
        filter_type = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_GLOBAL
    });
}

function PlaySoundCaptureStart()    { PlayOneShotSound(sounds["sound_capture_start"]); }
function PlaySoundCaptureStop()     { PlayOneShotSound(sounds["sound_capture_stop"]); }
function PlaySoundCaptureReset()    { PlayOneShotSound(sounds["sound_capture_reset"]); }
function PlaySoundCaptureRecede()   { PlayLoopingSound(sounds["sound_capture_recede"]); }
function PlaySoundCaptureProgress() { PlayLoopingSound(sounds["sound_capture_progress"]); }
function StopSoundCaptureRecede()   { StopLoopingSound(sounds["sound_capture_recede"]); }
function StopSoundCaptureProgress() { StopLoopingSound(sounds["sound_capture_progress"]); }

function StopAllLoopingSounds() {
    StopSoundCaptureRecede();
    StopSoundCaptureProgress();
}

// Events
// ----------------------------------
function CollectEventsInScope(events)
{
	local events_id = UniqueString()
	getroottable()[events_id] <- events
	local events_table = getroottable()[events_id]
	foreach (name, callback in events) events_table[name] = callback.bindenv(this)
	local cleanup_user_func, cleanup_event = "OnGameEvent_scorestats_accumulated_update"
    if (cleanup_event in events) cleanup_user_func = events[cleanup_event].bindenv(this)
	events_table[cleanup_event] <- function(params)
	{
		if (cleanup_user_func) cleanup_user_func(params)
		delete getroottable()[events_id]
	} __CollectGameEventCallbacks(events_table)
}

StopAllLoopingSounds();

CollectEventsInScope
({
    // stop looping the sounds in case the round restarts
    OnGameEvent_scorestats_accumulated_update = function(params) {
        StopAllLoopingSounds();
    }

    // stop looping the sounds when the round ends
    OnGameEvent_teamplay_round_win = function(params) {
        StopAllLoopingSounds();
        PlaySoundCaptureReset();
        disable_capture_updates = true;
    }
})