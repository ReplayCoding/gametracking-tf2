// Written by CanadianBill (https://steamcommunity.com/id/canadianbill/)
// for "Cowerhouse" - cp_powerhouse_event (https://steamcommunity.com/sharedfiles/filedetails/?id=3028277335)

SetPropFloat <- ::NetProps.SetPropFloat.bindenv(::NetProps);
GetPropFloat <- ::NetProps.GetPropFloat.bindenv(::NetProps);
GetPropInt <- ::NetProps.GetPropInt.bindenv(::NetProps);
GetPropBool <- ::NetProps.GetPropBool.bindenv(::NetProps);

logic_pd <- Entities.FindByClassname(null, "tf_logic_player_destruction");
logic_underground_stage_proxy <- Entities.FindByName(null, "global_underground_stage_proxy");
logic_underground_timer <- Entities.FindByName(null, "global_underground_timer");
logic_hud_enabled <- Entities.FindByName(null, "global_gamemode_pd_hud_visible");

STAGE_3_TOTAL_TIME_IN_SECONDS <- 20;

lastEndtime <- -1;

function markUndergroundTimerExpectedEnd() {
    // Hijack random unused float variable "m_flRobotScoreInterval" to store the time
    SetPropFloat(logic_pd, "m_flRobotScoreInterval", Time() + GetPropFloat(logic_underground_timer, "m_flRefireTime"));
}

function Think() {

    stage <- GetPropFloat(logic_underground_stage_proxy, "m_flCompareValue");
    endtime <- GetPropFloat(logic_pd, "m_flRobotScoreInterval");

    if (!GetPropBool(logic_hud_enabled, "m_bDisabled")) {

        // Stage 0 (idle) N/A
        // Stage 1 (harm - awaiting open) timer should show time until open
        // Stage 2 (open - awaiting warn) timer should be endtime plus total time in stage 3
        if (stage >=  2 && stage < 3) {
            endtime = endtime + STAGE_3_TOTAL_TIME_IN_SECONDS;
        }
        // Stage 3 (warn - awaiting close) timer should be endtime
        // Stage 4 (closed - awaiting harm) timer should stay at zero (keep the timer above zero to keep it from disappearing)
        else if (stage >= 4) {
            endtime = Time() + 0.9;
        }
        // Leave timer at zero for the few ticks/ms before the timer is refired to the next stage's time
        // so it doesn't look like it goes: 20, 19, 18, (...), 1, 0, 20 (briefly), 90 (next stage's time)
        else if (endtime == lastEndtime && endtime < Time()) {
            endtime = Time() + 0.9;
        }

        SetPropFloat(logic_pd, "m_flCountdownEndTime", endtime);
        lastEndtime = endtime;
    }
    else {
        SetPropFloat(logic_pd, "m_flCountdownEndTime", -1);
    }

    return 0.8; // Higher number is more performant, but needs to be less than 1 second, otherwise arbitrary choice AS LONG AS Think is additionally executed when the timer may change.
}