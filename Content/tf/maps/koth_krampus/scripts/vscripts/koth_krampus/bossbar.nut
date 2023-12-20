//=========================================================================
//Copyright LizardOfOz.
//=========================================================================

::pd_logic <- Entities.FindByClassname(null, "tf_gamerules");
::isHudVisible <- false;
Convars.SetValue("tf_rd_points_per_approach", "25");

function SpawnBossBar()
{
    pd_logic = SpawnEntityFromTable("tf_logic_player_destruction", {
        blue_respawn_time = 0,
        finale_length = 999999,
        flag_reset_delay = 0,
        heal_distance = 0,
        min_points = 255,
        points_per_player = 0,
        red_respawn_time = 0,
        targetname = "pd_logic",
        res_file = "resource/ui/krampus_boss_bar.res"
    });
    SetPropInt(pd_logic, "m_nBlueScore", 0);
    SetPropInt(pd_logic, "m_nBlueTargetPoints", 0);
    SetPropInt(pd_logic, "m_nMaxPoints", 255);
    EntFireByHandle(pd_logic, "SetPointsOnPlayerDeath", "0", -1, null, null);
    EntFireByHandle(pd_logic, "SetPointsOnPlayerDeath", "0", 0.1, null, null);
    EntFireByHandle(pd_logic, "SetPointsOnPlayerDeath", "0", 1, null, null);
    EntFireByHandle(pd_logic, "EnableMaxScoreUpdating", "", -1, null, null);
    EntFireByHandle(pd_logic, "DisableMaxScoreUpdating", "", 5, null, null);
}
SpawnBossBar();

::SetBossBarValue <- function(barValue)
{
    SetPropInt(pd_logic, "m_nBlueScore", barValue);
    SetPropInt(pd_logic, "m_nBlueTargetPoints", barValue);
    SetPropInt(pd_logic, "m_nMaxPoints", 255);
    if (floor(barValue) <= 0)
    {
        EntFireByHandle(pd_logic, "setcountdowntimer", "0", 0, null, null);
        isHudVisible = false;
    }
    else if (!isHudVisible)
    {
        EntFireByHandle(pd_logic, "setcountdowntimer", "99999", 0, null, null);
        isHudVisible = true;
    }
}