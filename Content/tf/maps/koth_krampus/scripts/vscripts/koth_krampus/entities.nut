//=========================================================================
//Copyright LizardOfOz.
//=========================================================================

::main_script <- this;

::krampus <- null;
::krampusScript <- null;

::spawn_point <- Entities.FindByName(null, "boss_spawn_pre");

::tf_gamerules <- Entities.FindByClassname(null, "tf_gamerules");
::team_control_point <- Entities.FindByClassname(null, "team_control_point");
::zz_red_koth_timer <- tf_gamerules;
::zz_blue_koth_timer <- tf_gamerules;
EntFireByHandle(self, "RunScriptCode", "::zz_red_koth_timer <- Entities.FindByName(null, `zz_red_koth_timer`); ::zz_blue_koth_timer <- Entities.FindByName(null, `zz_blue_koth_timer`)", 0.1, null, null);

::black_forest_winner <- Entities.FindByName(null, "black_forest_winner");
::black_forest_loser <- Entities.FindByName(null, "black_forest_loser");
