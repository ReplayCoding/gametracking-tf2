//=========================================================================
//Copyright LizardOfOz.
//=========================================================================

::KRAMPUS_HEALTH_BASE <- 3000;
::KRAMPUS_HEALTH_ADD_PER_PLAYER <- 350;
::KRAMPUS_MODEL <- "models/bots/krampus.mdl";
::KRAMPUS_SCALE <- 1.4;
::KRAMPUS_FIRST_SPAWN_DELAY <- 20;
::KRAMPUS_ANIM_RATE <- 0.8;
::COAL_MODEL <- "models/krampus_coal.mdl";

::KRAMPUS_ARENA_MIN <- Vector(-1050, -1500, -9999);
::KRAMPUS_ARENA_MAX <- Vector(1050, 1000, 9999);
::KRAMPUS_COAL_THROW_AREA_MIN <- Vector(-850, -1300, -9999);
::KRAMPUS_COAL_THROW_AREA_MAX <- Vector(850, 450, 9999);

PrecacheModel(KRAMPUS_MODEL);
PrecacheModel(COAL_MODEL);

::VO_COAL_BARRAGE <- [ "mvm/krampus_coal_barrage_01.mp3", "mvm/krampus_coal_barrage_02.mp3", "mvm/krampus_coal_barrage_03.mp3", "mvm/krampus_coal_barrage_04.mp3" ];
::VO_COAL_THROW <- [ "mvm/krampus_coal_throw_01.mp3", "mvm/krampus_coal_throw_02.mp3", "mvm/krampus_coal_throw_03.mp3", "mvm/krampus_coal_throw_04.mp3", "mvm/krampus_coal_throw_05.mp3", "mvm/krampus_coal_throw_06.mp3" ];
::VO_DEATH <- [ "mvm/krampus_death_01.mp3", "mvm/krampus_death_02.mp3", "mvm/krampus_death_03.mp3", "mvm/krampus_death_04.mp3", "mvm/krampus_death_05.mp3", "mvm/krampus_death_06.mp3" ];
::VO_ISEEYOU <- [ "mvm/krampus_iseeyou_01.mp3", "mvm/krampus_iseeyou_02.mp3", "mvm/krampus_iseeyou_03.mp3", "mvm/krampus_iseeyou_04.mp3", "mvm/krampus_iseeyou_05.mp3", "mvm/krampus_iseeyou_06.mp3", "mvm/krampus_iseeyou_07.mp3", "mvm/krampus_iseeyou_08.mp3", "mvm/krampus_iseeyou_09.mp3" ];
::VO_ONKILL <- [ "mvm/krampus_onkill_01.mp3", "mvm/krampus_onkill_02.mp3", "mvm/krampus_onkill_03.mp3", "mvm/krampus_onkill_04.mp3", "mvm/krampus_onkill_05.mp3", "mvm/krampus_onkill_06.mp3", "mvm/krampus_onkill_07.mp3", "mvm/krampus_onkill_08.mp3", "mvm/krampus_onkill_09.mp3", "mvm/krampus_onkill_10.mp3", "mvm/krampus_onkill_11.mp3", "mvm/krampus_onkill_12.mp3", "mvm/krampus_onkill_13.mp3", "mvm/krampus_onkill_14.mp3" ];
::VO_SPAWN_1 <- [ "mvm/krampus_spawn1_01.mp3", "mvm/krampus_spawn1_02.mp3", "mvm/krampus_spawn1_03.mp3", "mvm/krampus_spawn1_04.mp3", "mvm/krampus_spawn1_05.mp3", "mvm/krampus_spawn1_06.mp3", "mvm/krampus_spawn1_07.mp3", "mvm/krampus_spawn1_08.mp3", "mvm/krampus_spawn1_09.mp3", "mvm/krampus_spawn1_10.mp3" ];
::VO_SPAWN_2 <- [ "mvm/krampus_spawn1_01.mp3", "mvm/krampus_spawn2_02.mp3", "mvm/krampus_spawn2_03.mp3", "mvm/krampus_spawn2_04.mp3", "mvm/krampus_spawn2_05.mp3", "mvm/krampus_spawn2_06.mp3", "mvm/krampus_spawn2_07.mp3" ];
::VO_SPAWN_3 <- [ "mvm/krampus_spawn1_01.mp3", "mvm/krampus_spawn3_02.mp3", "mvm/krampus_spawn3_03.mp3", "mvm/krampus_spawn3_04.mp3", "mvm/krampus_spawn3_05.mp3", "mvm/krampus_spawn3_06.mp3", "mvm/krampus_spawn3_07.mp3", "mvm/krampus_spawn3_08.mp3", "mvm/krampus_spawn3_09.mp3" ];

foreach (vo in [VO_COAL_BARRAGE, VO_COAL_THROW, VO_DEATH, VO_ISEEYOU, VO_ONKILL, VO_SPAWN_1, VO_SPAWN_2, VO_SPAWN_3])
    foreach (sound in vo)
        PrecacheSound(sound);

PrecacheScriptSound("Weapon_PickAxe.Swing");
PrecacheSound("ambient/fire/ignite.wav");
PrecacheSound("ambient/fireball.wav");
PrecacheScriptSound("xmas.jingle_noisemaker");
PrecacheScriptSound("Halloween.TeleportVortex.EyeballMovedVortex");

PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = "kr_death_parent" });
PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = "kr_coaltrail_parent" });
PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = "kr_eruption_parent" });
PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = "kr_landing_parent" });
PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = "eyeboss_tp_vortex" });