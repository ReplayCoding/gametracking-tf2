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

PrecacheClassVoiceLines("point_enabled")

function SetConvars()
{
    Convars.SetValue("mp_tournament_redteamname", "HALE");
    Convars.SetValue("mp_tournament_blueteamname", "MERCS");
    Convars.SetValue("tf_weapon_criticals", 1);
    Convars.SetValue("mp_autoteambalance", 0);
    Convars.SetValue("mp_teams_unbalance_limit", 0);
    Convars.SetValue("mp_disable_respawn_times", 0);
    Convars.SetValue("mp_respawnwavetime", 999999);
    Convars.SetValue("tf_classlimit", 0);
    Convars.SetValue("cl_use_tournament_specgui", 0);
    Convars.SetValue("mp_forcecamera", 0);
    Convars.SetValue("sv_alltalk", 1);
    Convars.SetValue("tf_dropped_weapon_lifetime", 0);
    Convars.SetValue("mp_idledealmethod", 0);
    Convars.SetValue("mp_idlemaxtime", 9999);
    Convars.SetValue("mp_scrambleteams_auto", 0);
    Convars.SetValue("mp_stalemate_timelimit", 9999999);
    Convars.SetValue("mp_scrambleteams_auto_windifference", 0);
    Convars.SetValue("mp_humans_must_join_team", "blue");
    Convars.SetValue("tf_rd_points_per_approach", "500");
    Convars.SetValue("sv_vote_issue_autobalance_allowed", "0");
    Convars.SetValue("sv_vote_issue_scramble_teams_allowed", "0");
    Convars.SetValue("tf_stalematechangeclasstime", casti2f(0x7fa00000)); //NaN.
    if (GetPersistentVar("mp_bonusroundtime") == null)
        SetPersistentVar("mp_bonusroundtime", Convars.GetInt("mp_bonusroundtime"));
}
SetConvars();

function SpawnHelperEntities()
{
    SetPropString(tf_gamerules, "SetBlueTeamGoalString", "Kill all Mercenaries");
    SetPropString(tf_gamerules, "SetRedTeamGoalString", "Kill Saxton Hale");

    SpawnEntityFromTable("filter_activator_tfteam", {
        Negated = 0,
        TeamNum = TF_TEAM_BOSS,
        targetname = "filter_team_boss",
    })

    SpawnEntityFromTable("filter_activator_tfteam", {
        Negated = 0,
        TeamNum = TF_TEAM_MERCS,
        targetname = "filter_team_mercs",
    })

    local controlPoint = FindByClassname(null, "team_control_point");
    if (controlPoint != null)
    {
        controlPoint.KeyValueFromInt("point_index", 0);
        controlPoint.KeyValueFromInt("point_start_locked", 1);
        EntFireByHandle(controlPoint, "SetLocked", "1", 0, null, null);
        EntityOutputs.AddOutput(controlPoint,
            "OnUnlocked",
            "!self",
            "ShowModel",
            "",
            0, -1);
        EntityOutputs.AddOutput(controlPoint,
            "OnCapReset",
            "!self",
            "HideModel",
            "",
            0, -1);
        EntityOutputs.AddOutput(controlPoint,
            "OnCapTeam"+(TF_TEAM_MERCS-1),
            vsh_vscript_name,
            "RunScriptCode",
            "EndRound("+TF_TEAM_MERCS+")",
            0, -1);
        EntityOutputs.AddOutput(controlPoint,
            "OnCapTeam"+(TF_TEAM_BOSS-1),
            vsh_vscript_name,
            "RunScriptCode",
            "EndRound("+TF_TEAM_BOSS+")",
            0, -1);
    }

    local pointMaster = FindByClassname(null, "team_control_point_master");
    if (pointMaster == null)
        SpawnEntityFromTable("team_control_point_master", {
            caplayout = 0,
            cpm_restrict_team_cap_win = 1,
            custom_position_x = -1,
            custom_position_x = -1,
            partial_cap_points_rate = 0
        });

    pd_logic = SpawnEntityFromTable("tf_logic_player_destruction", {
        finale_length = 9999,
        min_points = 1024,
        targetname = "pd_logic",
        res_file = "resource/ui/vsh_hud_maul.res"
    });
    pd_logic.AddFlag(4194304);
    pd_logic.AcceptInput("SetPointsOnPlayerDeath", "0", null, null);
    pd_logic.AcceptInput("EnableMaxScoreUpdating", "0", null, null);
    pd_logic.AcceptInput("DisableMaxScoreUpdating", "0", null, null);
    SetPropInt(pd_logic, "m_nBlueScore", 0);
    SetPropInt(pd_logic, "m_nBlueTargetPoints", 0);
    SetPropInt(pd_logic, "m_nMaxPoints", 1024);

    team_round_timer = SpawnEntityFromTable("team_round_timer", {
        targetname = "team_round_timer",
        auto_countdown = 1,
        max_length = 0,
        reset_time = 1,
        setup_length = API_GetFloat("setup_length"),
        show_in_hud = 1,
        show_time_remaining = 1,
        start_paused = 0,
        timer_length = API_GetFloat("round_time"),
        StartDisabled = 0,
        "OnSetupFinished#1": vsh_vscript_name+",RunScriptCode,FinishSetup(),0,-1",
        "OnSetupFinished#2": "vsh_setup*,Trigger,,0,-1",
        "OnSetupFinished#3": "vsh_setup*,Open,,0,-1",
        "On1MinRemain": "vsh_1min*,Trigger,,0,-1",
        "OnFinished#1": vsh_vscript_name+",RunScriptCode,UnlockControlPoint(),0,-1"
        "OnFinished#2": vsh_vscript_name+",RunScriptCode,PrepareStalemate(),0,-1"
    });
    team_round_timer.ValidateScriptScope();
    team_round_timer.GetScriptScope().Tick <- function()
    {
        vsh_vscript.FireListeners("tick_frame");
        return 0;
    }
    AddThinkToEnt(team_round_timer, "Tick")
}
SpawnHelperEntities();

function UnlockControlPoint()
{
    local controlPoint = FindByClassname(null, "team_control_point");
    if (controlPoint != null)
        EntFireByHandle(controlPoint, "SetUnlockTime", "0", 0, null, null);
    PlayAnnouncerVO(GetRandomBossPlayer(), "point_enabled");
}

function PrepareStalemate()
{
    local boss = GetRandomBossPlayer();
    local delay = clampFloor(60, API_GetFloat("stalemate_time"));

    local text_tf = SpawnEntityFromTable("game_text_tf", {
        message = "#vsh_end_this",
        icon = "ico_notify_flag_moving_alt",
        background = 0,
        display_to_team = 0
    });
    EntFireByHandle(text_tf, "Display", "", delay - 60, null, null);
    EntFireByHandle(text_tf, "Kill", "", delay - 59, null, null);

    RunWithDelay("EntFireByHandle(team_round_timer, `SetTime`, `60`, 0, null, null)", null, delay - 60);

    PlayAnnouncerVODelayed(boss, "count5", delay - 6);
    PlayAnnouncerVODelayed(boss, "count4", delay - 5);
    PlayAnnouncerVODelayed(boss, "count3", delay - 4);
    PlayAnnouncerVODelayed(boss, "count2", delay - 3);
    PlayAnnouncerVODelayed(boss, "count1", delay - 2);

    RunWithDelay("EndRound(TF_TEAM_UNASSIGNED)", null, delay);
}