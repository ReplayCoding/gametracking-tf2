//=========================================================================
//Copyright LizardOfOz.
//=========================================================================

::main_script <- this;

::krampus <- null;
::krampusScript <- null;

::spawn_point <- Entities.FindByName(null, "boss_spawn_pre");
::krampus_cam <- Entities.FindByName(null, "krampus_cam");
EntFireByHandle(krampus_cam, "RunScriptCode", "if (self) self.KeyValueFromString(`classname`,`nope`)", -1, null, null);

::tf_gamerules <- Entities.FindByClassname(null, "tf_gamerules");
::monster_resource <- Entities.FindByClassname(null, "monster_resource")
::team_control_point <- Entities.FindByClassname(null, "team_control_point");
::zz_red_koth_timer <- tf_gamerules;
::zz_blue_koth_timer <- tf_gamerules;
EntFireByHandle(self, "RunScriptCode", "::zz_red_koth_timer <- Entities.FindByName(null, `zz_red_koth_timer`); ::zz_blue_koth_timer <- Entities.FindByName(null, `zz_blue_koth_timer`)", 0.1, null, null);