// --------------------------------------------------------------------------------------- //
// Zombie Infection                                                                        //
// --------------------------------------------------------------------------------------- //
// All Code By: netmuck (https://steamcommunity.com/profiles/76561198025795825)            //
// Assets/Game Design by: Diva Dan (https://steamcommunity.com/profiles/76561198072146551) //
// --------------------------------------------------------------------------------------- //
const _CONST                           = true;
const TF_COND_NO_KNOCKBACK             = 130;
// --------------------------------------------------------------------------------------- //
::DEBUG_MODE      <- 0;
::bSpitDebugBoxes <- false;
// --------------------------------------------------------------------------------------- //
// stun flags for CTFPlayer::StunPlayer                                                    //
// --------------------------------------------------------------------------------------- //
const TF_STUN_MOVEMENT                 = 1;                                                //
const TF_STUN_CONTROLS                 = 2;                                                //
const TF_STUN_MOVEMENT_FORWARD_ONLY    = 4;                                                //
const TF_STUN_SPECIAL_SOUND            = 8;                                                //
const TF_STUN_NO_EFFECTS               = 32;                                               //
const TF_STUN_SOUND                    = 256;                                              //
/////////////////////////////////////////////////////////////////////////////////////////////
// Cooldowns (in seconds) |--------------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
// --------------------------------------------------------------------------------------- //
const MIN_TIME_BETWEEN_VIEWPUNCH       = 3;     // Internal Cooldown - viewpunch           //
const MIN_TIME_BETWEEN_VO              = 1;     // Internal Cooldown - zombie vo emit      //
const MIN_TIME_BETWEEN_CONVERT         = 0.1;   // Internal Cooldown - Apply zombie ents   //
// --------------------------------------------------------------------------------------- //
const MIN_TIME_BETWEEN_ENGIE_EMP_THROW = 9;     // Ability Cooldown  - Engie EMP Cast      //
const MIN_TIME_BETWEEN_ENGIE_BEACON    = 15;    // Ability Cooldown  - Engie Beacon Cast   //
// --------------------------------------------------------------------------------------- //
const MIN_TIME_BETWEEN_SPIT_START_END  = 0.5;   // Ability Delay     - Sniper Spit Channel //
const MIN_TIME_BETWEEN_SPIT_CAST       = 5;     // Ability Cooldown  - Sniper Spit Cast    //
// --------------------------------------------------------------------------------------- //
const MIN_TIME_BETWEEN_SPY_EMP         = 10;    // Ability Cooldown  - Spy EMP Cast        //
// --------------------------------------------------------------------------------------- //
const MIN_TIME_BETWEEN_SOLDIER_POUNCE  = 5;     // Ability Cooldown  - Soldier Pounce Cast //
// --------------------------------------------------------------------------------------- //
const MIN_TIME_BETWEEN_MEDIC_HEAL      = 7;     // Ability Cooldown  - Medic Heal Cast     //
// --------------------------------------------------------------------------------------- //
const MIN_TIME_BETWEEN_DEMO_CHARGE     = 6;     // Ability Cooldown  - Demo Charge Cast    //
// --------------------------------------------------------------------------------------- //
const MIN_TIME_BETWEEN_PYRO_SPEW        = 10;    // Ability Cooldown  - Pyro Spew Cast       //
// --------------------------------------------------------------------------------------- //
const MIN_TIME_BETWEEN_HEAVY_ROCK      = 10;    // Ability Cooldown  - Heavy Rock Throw    //
const HEAVY_ROCK_SPAWN_COOLDOWN        = 0;     // available straight from spawn           //
// --------------------------------------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
// Game mode values |--------------------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
const ADDITIONAL_SEC_PER_PLAYER        = 8;     // Additional time added per player        //
const ROUND_TIMER_NAME                 = "infection_timer"    // targetname of round timer //
const STARTING_ZOMBIE_FAC              = 5;                                                //
const ZOMBIE_QUOTA_BUFF_REFRESH        = 1.0;   // under-quota minicrit buff duration      //
/////////////////////////////////////////////////////////////////////////////////////////////
// Zombie Stats |------------------------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
// --------------------------------------------------------------------------------------- //
// Damage Multiplier values for Zombie weapons                                             //
// --------------------------------------------------------------------------------------- //
const ZSCOUT_DMG_MULTI                 = 1;     // Scout    Zombie Damage Multiplier       //
const ZSNIPER_DMG_MULTI                = 1;     // Sniper   Zombie Damage Multiplier       //
const ZSOLDIER_DMG_MULTI               = 1;     // Soldier  Zombie Damage Multiplier       //
const ZDEMOMAN_DMG_MULTI               = 1;     // Demoman  Zombie Damage Multiplier       //
const ZMEDIC_DMG_MULTI                 = 1;     // Medic    Zombie Damage Multiplier       //
const ZHEAVY_DMG_MULTI                 = 2.2;   // Heavy    Zombie Damage Multiplier       //
const ZHEAVY_KNOCKBACK_MULT            = 0.15;  // Heavy    knockback + airblast kept      //
const ZHEAVY_MELEE_BUILDING_DMG_CAP    = 90;    // Heavy    punch vs buildings, 2 hits on  //
const ZHEAVY_DEATH_GIB_Z_OFF           = 40;    // Heavy    rock gib burst height on death //
const ZPYRO_FIRE_DMG_MULT              = 0.30;  // Pyro     zombie fire damage kept        //
const ZPYRO_DMG_MULTI                  = 0.7;   // Pyro     Zombie Damage Multiplier       //
const ZSPY_DMG_MULTI                   = 0.69;  // Spy      Zombie Damage Multiplier       //
const ZENGINEER_DMG_MULTI              = 1;     // Engineer Zombie Damage Multiplier       //
// --------------------------------------------------------------------------------------- //
// Item Definition Index (IDX) for each class' Zombie weapon                               //
// --------------------------------------------------------------------------------------- //
const ZOMBIE_SPOOF_WEAPON_IDX          = 572;   // idx for killicon for zombie melee       //
// --------------------------------------------------------------------------------------- //
ZOMBIE_WEAPON_IDX <-                            //                                         //
[                                               //                                         //
    5617,                                       // scout                                   //
    5617,                                       // scout                                   //
    5625,                                       // sniper                                  //
    5618,                                       // soldier                                 //
    5620,                                       // demoman                                 //
    5622,                                       // medic                                   //
    5619,                                       // heavyweapons                            //
    5624,                                       // pyro                                    //
    5623,                                       // spy                                     //
    5621,                                       // engineer                                //
];                                              //                                         //
// --------------------------------------------------------------------------------------- //
// tf_weapon* type of each class' Zombie weapon                                            //
// --------------------------------------------------------------------------------------- //
ZOMBIE_WEAPON_CLASSNAME <-[                     //                                         //
    "tf_weapon_fists",                          // scout                                   //
    "tf_weapon_fists",                          // scout                                   //
    "tf_weapon_fists",                          // sniper                                  //
    "tf_weapon_fists",                          // soldier                                 //
    "tf_weapon_fists",                          // demoman                                 //
    "tf_weapon_fists",                          // medic                                   //
    "tf_weapon_fists",                          // heavyweapons                            //
    "tf_weapon_fists",                          // pyro                                    //
    "tf_weapon_fists",                          // spy                                     //
    "tf_weapon_fists",                          // engineer                                //
];                                              //                                         //
// --------------------------------------------------------------------------------------- //
// Zombie Weapon Attributes - Weapon type attributes for each class when playing as zombie //
// --------------------------------------------------------------------------------------- //
// TF_ATTRIB Array | [string condition, fl value, fl duration (-1 for infinite )]          //
// (https://wiki.teamfortress.com/wiki/List_of_item_attributes)                            //
// --------------------------------------------------------------------------------------- //
ZOMBIE_WEP_ATTRIBS <- [ /////////////////////////////////////////////////////////////////////
[// attributes applied to all zombie weps ------------------------------------------------ //
["melee range multiplier",   1, -1],            // Increase melee range for zombie         //
["melee bounds multiplier",  1, -1],            // Increase melee range for zombie         //
["crit mod disabled hidden", 0, -1],            // No crits                                //
["zombiezombiezombiezombie", 1, -1],            // enable zombie cosmetic vo               //
],                                              //                                         //
[// attributes for scout zombie weapon --------------------------------------------------- //
["damage bonus", ZSCOUT_DMG_MULTI, -1 ],        // set class specific damage multi         //
["move speed bonus", 1.75, -1 ],                // extra movement speed for scout passive  //
["increased jump height from weapon", 1.25, -1] // additional jump height                  //
],                                              //                                         //
[// attributes for sniper zombie weapon -------------------------------------------------- //
["damage bonus", ZSNIPER_DMG_MULTI, -1 ],       // set class specific damage multi         //
],                                              //                                         //
[// attributes for soldier zombie weapon ------------------------------------------------- //
["damage bonus", ZSOLDIER_DMG_MULTI, -1 ],      // set class specific damage multi         //
],                                              //                                         //
[// attributes for demo zombie weapon ---------------------------------------------------- //
["damage bonus", ZDEMOMAN_DMG_MULTI, -1 ],      // set class specific damage multi         //
],                                              //                                         //
[// attributes for medic zombie weapon --------------------------------------------------- //
["damage bonus", ZMEDIC_DMG_MULTI, -1 ],        // set class specific damage multi         //
],                                              //                                         //
[// attributes for heavyweaponzombie weapon ---------------------------------------------- //
["damage bonus", ZHEAVY_DMG_MULTI, -1 ],        // set class specific damage multi         //
],                                              //                                         //
[// attributes for pyro zombie weapon ---------------------------------------------------- //
["damage bonus", ZPYRO_DMG_MULTI, -1 ],         // set class specific damage multi         //
["ragdolls become ash", 1, -1],                 //                                         //
],                                              //                                         //
[// attributes for spy zombie weapon ----------------------------------------------------- //
["damage bonus", ZSPY_DMG_MULTI, -1 ],          // set class specific damage multi         //
],                                              //                                         //
[// attributes for engy zombie weapon ---------------------------------------------------- //
["damage bonus", ZENGINEER_DMG_MULTI, -1 ],     // set class specific damage multi         //
],                                              //                                         //
];                                              //                                         //
// --------------------------------------------------------------------------------------- //
// Zombie TF_CONDs - TF Conditions for each class when playing as zombie                   //
// --------------------------------------------------------------------------------------- //
// TF_COND Array | [string TF_COND]                                                        //
// (https://developer.valvesoftware.com/wiki/Trigger_add_tf_player_condition)              //
// --------------------------------------------------------------------------------------- //
ZOMBIE_PLAYER_CONDS <- [ ////////////////////////////////////////////////////////////////////
[// TF_CONDs applied to all zombies  ----------------------------------------------------- //
    TF_COND_CANNOT_SWITCH_FROM_MELEE,           // For obvious reasons...                  //
    TF_COND_TEAM_GLOWS,                         // outlines for friendly players           //
],                                              //                                         //
[// TF_CONDs applied to scout zombie ----------------------------------------------------- //
    TF_COND_SPEED_BOOST,                        // Speed lines make you go faster          //
],                                              //                                         //
[// TF_CONDs applied to sniper zombie ---------------------------------------------------- //
],                                              //                                         //
[// TF_CONDs applied to soldier zombie --------------------------------------------------- //
],                                              //                                         //
[// TF_CONDs applied to demoman zombie --------------------------------------------------- //
],                                              //                                         //
[// TF_CONDs applied to medic zombie ----------------------------------------------------- //
],                                              //                                         //
[// TF_CONDs applied to heavyweapons zombie ---------------------------------------------- //
],                                              //                                         //
[// TF_CONDs applied to pyro zombie ------------------------------------------------------ //
],                                              //                                         //
[// TF_CONDs applied to spy zombie ------------------------------------------------------- //
],                                              //                                         //
[// TF_CONDs applied to engy zombie ------------------------------------------------------ //
],                                              //                                         //
];///////////////////////////////////////////////////////////////////////////////////////////
// --------------------------------------------------------------------------------------- //
// Zombie Player Attributes - Player type attributes for each class when playing as zombie //
// --------------------------------------------------------------------------------------- //
// TF_ATTRIB Array | [string condition, fl value, fl duration (-1 for infinite )]          //
// (https://wiki.teamfortress.com/wiki/List_of_item_attributes)                            //
// --------------------------------------------------------------------------------------- //
ZOMBIE_PLAYER_ATTRIBS <- [ //////////////////////////////////////////////////////////////////
[// attributes applied to all zombie weps ------------------------------------------------ //
["crit mod disabled hidden", 0, -1],                  // No crits                          //
["maxammo metal reduced", 0.0, -1],                   // Prevent picking up metal          //
["maxammo secondary reduced", 0.0, -1],               // Prevent picking up ammo           //
["maxammo primary reduced", 0.0, -1],                 // Prevent picking up ammo           //
["voice pitch scale", 0.7, -1],                       // Makes player voice funny          //
["health from packs decreased", 0, -1],               // Cannot pick up health packs       //
],                                                    //                                   //
[// attributes for scout zombie  --------------------------------------------------------- //
["hidden maxhealth non buffed", -50, -1 ],            //                                   //
],                                                    //                                   //
[// attributes for sniper zombie  -------------------------------------------------------- //
["hidden maxhealth non buffed", 25, -1 ],             //                                   //
],                                                    //                                   //
[// attributes for soldier zombie  ------------------------------------------------------- //
["hidden maxhealth non buffed", 25, -1 ],             //                                   //
],                                                    //                                   //
[// attributes for demo zombie  ---------------------------------------------------------- //
["hidden maxhealth non buffed", 25, -1 ],             //                                   //
],                                                    //                                   //
[// attributes for medic zombie  --------------------------------------------------------- //
["hidden maxhealth non buffed", 25, -1 ],             //                                   //
],                                                    //                                   //
[// attributes for heavyweapons zombie  -------------------------------------------------- //
["hidden maxhealth non buffed", 225, -1 ],            //                                   //
["move speed penalty", 0.90, -1 ],                    //                                   //
["dmg bonus vs buildings", 3.32, -1 ],                // ~216, clamped in OnTakeDamage     //
["dmg taken increased", 0.65, -1 ],                   // 35% damage resist                 //
["damage force reduction", ZHEAVY_KNOCKBACK_MULT, -1 ], // 90% knockback resist            //
["airblast vulnerability multiplier", ZHEAVY_KNOCKBACK_MULT, -1 ], // same vs airblast     //
],                                                    //                                   //
[// attributes for pyro zombie  ---------------------------------------------------------- //
["hidden maxhealth non buffed", 25, -1 ],            // 200 hp                             //
],                                                    //                                   //
[// attributes for spy zombie  ----------------------------------------------------------- //
["hidden maxhealth non buffed", 0, -1 ],              // 125 hp                            //
],                                                    //                                   //
[// attributes for engy zombie  ---------------------------------------------------------- //
["hidden maxhealth non buffed", 25, -1 ],             //                                   //
],                                                    //                                   //
];                                                    //                                   //
/////////////////////////////////////////////////////////////////////////////////////////////
// Zombie Win Condition |----------------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
const MAX_SURVIVORS_FOR_ZOMBIE_WIN     = 0;     // if =  x red alive, zombies win          //
/////////////////////////////////////////////////////////////////////////////////////////////
// Entity Think Function Rethink Times |-------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
// --------------------------------------------------------------------------------------- //
const PLAYER_RETHINK_TIME              = 0.0;   // How often the player thinks             //
const ENGIE_EMP_RETHINK_TIME           = 0.01;  // How often the EMP grenade thinks        //
const ENGIE_BEACON_RETHINK_TIME        = 0.01;  // How often the beacon ent thinks         //
const SNIPER_SPIT_RETHINK_TIME         = 0;     // How often the sniper spit thinks        //
const SNIPER_SPIT_ZONE_RETHINK_TIME    = 0.5;   // How often the sniper spit ZONE thinks   //
const PYRO_SPEW_RETHINK_TIME            = 0;     // How often the spew glob thinks           //
const PYRO_SPEW_ZONE_RETHINK_TIME       = 0.1;   // How often the spew ZONE thinks           //
const ENGIE_EMP_BUILDING_RETHINK_TIME  = 0.1;   // How often the EMP'd building thimax_nks //
const HEAVY_ROCK_RETHINK_TIME          = 0;     // How often the thrown rock thinks        //
// --------------------------------------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
// ZombieHeavy Passive Values |----------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
// --------------------------------------------------------------------------------------- //
const HEAVY_KNOCK_BACK_FORCE           = 125;   // knock back force on heavy punch         //
// --------------------------------------------------------------------------------------- //
const HEAVY_FOOTSTEP_MIN_SPEED         = 10;                                               //
const HEAVY_FOOTSTEP_STRIDE            = 85;    // hu of ground covered per footfall       //
const HEAVY_FOOTSTEP_MIN_GAP           = 0.35;                                             //
const HEAVY_FOOTSTEP_MAX_GAP           = 0.9;                                              //
const HEAVY_FOOTSTEP_VOLUME            = 10;                                               //
// --------------------------------------------------------------------------------------- //

const DRG_RAYGUN_ZOMBIE_COOLDOWN_MOD = 3; // 3 seconds, set to -1 for full ability cooldown

const ZOMBIE_DEATH_DROP_SPREAD = 12;

const ZOMBIE_MEDIC_DISPENSER_RANGE = 128;
const ROMEVISION_ATTRIBUTE_IDX = 4;

const MASK_SOLID_BRUSHONLY = 16395;
const MASK_PLAYERSOLID_BRUSHONLY = 81931; // MASK_SOLID_BRUSHONLY + CONTENTS_PLAYERCLIP
const CONTENTS_PLAYERCLIP        = 65536; // 0x10000 - playerclip volumes alone

SNIPER_SPIT_ZONE_ENTS <-
{
    "tf_pumpkin_bomb" : "ignite",
    "tf_generic_bomb" : "detonate",
    "obj_sentrygun"   : "building",
    "obj_dispenser"   : "building",
    "obj_teleporter"  : "building",
};

PROBLEMATIC_PLAYER_CONDS <-
[
    0,  // TF_COND_AIMING
    1,  // TF_COND_ZOOMED
    2,  // TF_COND_DISGUISING
    3,  // TF_COND_DISGUISED
    4,  // TF_COND_STEALTHED
    5,  // TF_COND_INVULNERABLE
    7,  // TF_COND_TAUNTING
    8,  // TF_COND_INVULNERABLE_WEARINGOFF
    9,  // TF_COND_STEALTHED_BLINK
    11, // TF_COND_CRITBOOSTED
    13, // TF_COND_FEIGN_DEATH
    14, // TF_COND_PHASE
 //   17, // TF_COND_SHIELD_CHARGE
    19, // TF_COND_ENERGY_BUFF
    47, // TF_COND_DISGUISE_WEARINGOFF
    64, // TF_COND_STEALTHED_USER_BUFF
    66, // TF_COND_STEALTHED_USER_BUFF_FADING
];

arrHUDTextClassXOffsets <-
[
    -0.010,  // scout
    -0.009,  // scout
    0.025,   // sniper
    0.016,   // soldier
    -0.0045, // demoman
    0.023,   // medic
    0.004,   // heavy
    -0.011,  // pyro
    -0.006,  // spy
    0.014,   // engineer
];

arrHUDTextClassYOffsets <-
[
    0.016, // scout
    0.016, // scout
    0.011, // sniper
    0.015, // soldier
    0.015, // demoman
    0.013, // medic
    0.009, // heavy
    0.009, // pyro
    0.016, // spy
    0.016, // engineer
];

::arrClassAttackSpeed <-
[
    0.85, // scout
    0.85, // scout
    0.85, // sniper
    0.85, // soldier
    0.85, // demoman
    0.85, // medic
    1.25, // heavyweapons
    0.85, // pyro
    0.85, // spy
    0.85, // engineer
];

szArrZombieAbilityUI <-
[
    "vgui/infection/zability_scout_",
    "vgui/infection/zability_scout_",
    "vgui/infection/zability_sniper_",
    "vgui/infection/zability_soldier_",
    "vgui/infection/zability_demo_",
    "vgui/infection/zability_medic_",
    "vgui/infection/zability_heavy_",
    "vgui/infection/zability_pyro_",
    "vgui/infection/zability_spy_",
    "vgui/infection/zability_engineer_",
];

idxArrZombiePlayerModels <-
[
    PrecacheModel("models/player/scout_infected.mdl"),
    PrecacheModel("models/player/scout_infected.mdl"),
    PrecacheModel("models/player/sniper_infected.mdl"),
    PrecacheModel("models/player/soldier_infected.mdl"),
    PrecacheModel("models/player/demo_infected.mdl"),
    PrecacheModel("models/player/medic_infected.mdl"),
    PrecacheModel("models/player/heavy_infected.mdl"),
    PrecacheModel("models/player/pyro_infected.mdl"),
    PrecacheModel("models/player/spy_infected.mdl"),
    PrecacheModel("models/player/engineer_infected.mdl"),
];

szArrZombiePlayerModels <-
[
    "models/player/scout_infected.mdl",
    "models/player/scout_infected.mdl",
    "models/player/sniper_infected.mdl",
    "models/player/soldier_infected.mdl",
    "models/player/demo_infected.mdl",
    "models/player/medic_infected.mdl",
    "models/player/heavy_infected.mdl",
    "models/player/pyro_infected.mdl",
    "models/player/spy_infected.mdl",
    "models/player/engineer_infected.mdl",
];

const MDL_ZOMBIE_VIEW_MODEL_SCOUT          = "models/player/infection/v_models/v_infected_scout.mdl";
const MDL_ZOMBIE_VIEW_MODEL_SNIPER         = "models/player/infection/v_models/v_infected_sniper.mdl";
const MDL_ZOMBIE_VIEW_MODEL_SOLDIER        = "models/player/infection/v_models/v_infected_soldier.mdl";
const MDL_ZOMBIE_VIEW_MODEL_DEMOMAN        = "models/player/infection/v_models/v_infected_demo.mdl";
const MDL_ZOMBIE_VIEW_MODEL_MEDIC          = "models/player/infection/v_models/v_infected_medic.mdl";
const MDL_ZOMBIE_VIEW_MODEL_HEAVY          = "models/player/infection/v_models/v_infected_heavy.mdl";
const MDL_ZOMBIE_VIEW_MODEL_PYRO           = "models/player/infection/v_models/v_infected_pyro.mdl";
const MDL_ZOMBIE_VIEW_MODEL_SPY            = "models/player/infection/v_models/v_infected_spy.mdl";
const MDL_ZOMBIE_VIEW_MODEL_ENGINEER       = "models/player/infection/v_models/v_infected_engineer.mdl";
const MDL_ZOMBIE_PLAYER_MODEL_SCOUT        = "models/player/items/scout/scout_zombie.mdl";
const MDL_ZOMBIE_PLAYER_MODEL_SNIPER       = "models/player/items/sniper/sniper_zombie.mdl";
const MDL_ZOMBIE_PLAYER_MODEL_SOLDIER      = "models/player/items/soldier/soldier_zombie.mdl";
const MDL_ZOMBIE_PLAYER_MODEL_DEMOMAN      = "models/player/items/demo/demo_zombie.mdl";
const MDL_ZOMBIE_PLAYER_MODEL_MEDIC        = "models/player/items/medic/medic_zombie.mdl";
const MDL_ZOMBIE_PLAYER_MODEL_HEAVY        = "models/player/items/heavy/heavy_zombie.mdl";
const MDL_ZOMBIE_PLAYER_MODEL_PYRO         = "models/player/items/pyro/pyro_zombie.mdl";
const MDL_ZOMBIE_PLAYER_MODEL_SPY          = "models/player/items/spy/spy_zombie.mdl";
const MDL_ZOMBIE_PLAYER_MODEL_ENGINEER     = "models/player/items/engineer/engineer_zombie.mdl";
const MDL_FX_WEARABLE_SCOUT                = "models/player/infection/scout_zombie_wearable.mdl";
const MDL_FX_WEARABLE_SNIPER               = "models/player/infection/sniper_zombie_wearable.mdl";
const MDL_FX_WEARABLE_SOLDIER              = "models/player/infection/soldier_zombie_wearable.mdl";
const MDL_FX_WEARABLE_DEMOMAN              = "models/player/infection/demo_zombie_wearable.mdl";
const MDL_FX_WEARABLE_MEDIC                = "models/player/infection/medic_zombie_wearable.mdl";
const MDL_FX_WEARABLE_HEAVY                = "models/player/infection/heavy_zombie_wearable.mdl";
const MDL_FX_WEARABLE_PYRO                 = "models/player/infection/pyro_zombie_wearable.mdl";
const MDL_FX_WEARABLE_SPY                  = "models/player/infection/spy_zombie_wearable.mdl";
const MDL_FX_WEARABLE_ENGINEER             = "models/player/infection/engineer_zombie_wearable.mdl";
const MDL_WORLD_MODEL_ENGIE_NADE           = "models/player/infection/w_grenade_emp.mdl";
const MDL_ENGIE_BEACON                     = "models/player/infection/ztele.mdl"; // custom zombie tele - build/idle/running sequences, vanilla naming
const MDL_ENGIE_BEACON_TOOLBOX             = "models/player/infection/ztele_toolbox.mdl";

ARR_MDL_BEACON_GIBS <-
[
    "models/buildables/gibs/teleporter_gib1.mdl",
    "models/buildables/gibs/teleporter_gib2.mdl",
    "models/buildables/gibs/teleporter_gib3.mdl",
    "models/buildables/gibs/teleporter_gib4.mdl",
];
const MDL_GUNSLINGER_PATH                  = "models/weapons/c_models/c_engineer_gunslinger.mdl";

const MDL_HEAVY_ROCK                       = "models/player/infection/w_heavy_rock.mdl";

ARR_MDL_HEAVY_ROCK_GIBS <-
[
    "models/player/infection/w_heavy_rock_gib001.mdl",
    "models/player/infection/w_heavy_rock_gib002.mdl",
    "models/player/infection/w_heavy_rock_gib003.mdl",
    "models/player/infection/w_heavy_rock_gib004.mdl",
    "models/player/infection/w_heavy_rock_gib005.mdl",
    "models/player/infection/w_heavy_rock_gib006.mdl",
    "models/player/infection/w_heavy_rock_gib007.mdl",
];

const FX_ZOMBIE_BODY          = "zombie_body_parent";
const FX_ZOMBIE_SPARKS        = "zombie_body_sparks";
const FX_EMP_FLASH            = "zombie_emp_flash";
const FX_EMP_ELECTRIC         = "zombie_emp_electric";
const FX_EMP_BURST            = "zombie_emp_burst";
const FX_EMP_GIBS             = "zombie_emp_gibs";
const FX_EMP_SPARK            = "halloween_boss_axe_hit_sparks";
const FX_SPIT_SMOKE           = "zombie_spit";
const FX_SPIT_TRAIL           = "zombie_spit_trail";
const FX_SPIT_HIT_PLAYER      = "zombie_spit_impact_cloud";
const FX_ABILITY_IN_USE       = "zombie_body_sparks";
const FX_EMITTER_FX           = "zombie_screech";
const FX_DEMOGUTS             = "zombie_demoguts_parent";
const FX_SPIT_SPLAT           = "zombie_spit_impact_splat";
const FX_SPIT_IMPACT          = "zombie_spit_impact";
const FX_SPIT_GROUND          = "zombie_spit_impact_ground_new";
const FX_SPEW_GROUND           = "zombie_tar_impact_ground";
const FX_SPEW_TRAIL            = "zombie_tar";
const FX_SPEW_IMPACT           = "zombie_tar_impact";
const FX_SPEW_DRIP             = "zombie_peejar_drips_tar";
const FX_SOLDIER_LIFTOFF      = "rocketjump_smoke";
const SFX_SOLDIER_FALL        = "BlastJump.Whistle";
const FX_ZOMBIE_SPAWN         = "zombie_spawn_parent";
const FX_TF_STOMP_TEXT        = "stomp_text";
const FX_MEDIC_HEAL           = "zombie_heal_parent";
const FX_FIREBALL_FIREBALL    = "zombie_fireball_fireball";
const FX_FIREBALL_SMOKEBALL   = "zombie_fireball_smokeball";
const FX_FIREBALL_SMOKEPUFF   = "zombie_fireball_smokepuff";
const FX_FIREBALL_TRAIL       = "zombie_fireball_trail";
const FX_ZOMBIE_FIREBALL      = "zombie_fireball";
const FX_FLAMER               = "flamethrower_blue";
const FX_BEACON_BUILD         = "teleporter_arms_circle_blue";
const FX_BEACON_READY         = "teleporter_blue_charged";
const FX_BEACON_DESTROY       = "halloween_boss_axe_hit_sparks";
const FX_BEACON_EXIT          = "zombie_teleporter_exit"; // looping ambient on the deployed tele, endless emitters by design
// stock buff banner swirl, blu - painted on disguised spies so the quota buff
// doesn't single them out
const FX_ZOMBIE_BUFF_SPOOF    = "soldierbuff_blue_soldier";

const FX_HEAVY_ROCK_LAND_DUST    = "taunt_heavy_flip_land_dust";
const FX_HEAVY_ROCK_LAND_DEBRIS  = "taunt_heavy_flip_land_debris";
const FX_HEAVY_ROCK_LAND_DUST2   = "taunt_flip_land_dust2";
const FX_HEAVY_ROCK_LAND_DUST3   = "taunt_flip_land_dust";
const FX_HEAVY_ROCK_LAND         = "taunt_flip_land";

const SFX_GENERIC_THROW       = "EvictionNotice.Swing";
const SFX_ZOMBIE_SPIT_START   = "Infection.SniperSpitStart";
const SFX_ZOMBIE_SPIT_END     = "Infection.SniperSpitEnd";
const SFX_EMP_EXPLODE         = "Infection.EMP_Grenade_Explode";
const SFX_EMP_BEEP            = "Weapon_Grenade_Det_Pack.Timer";
const SFX_EMP_BUILDING_DMGED  = "Building_Sentry.Damage";
const SFX_SPIT_POP            = "Underwater.BulletImpact";
const SFX_SPIT_SPLATTER       = "Halloween.PumpkinExplode";
const SFX_SPIT_MISS           = "Mud.StepRight";
const SFX_SPY_REVEAL_ONCAST   = "Infection.SpyReveal";
const SFX_ABILITY_USE         = "Halloween.Merasmus_Spell";
const SFX_PYRO_FIREBOMB       = "Halloween.spell_fireball_impact";
const SFX_DEMO_CHARGE_RAMP    = "Infection.DemoChargeRamp";
const SFX_ZMEDIC_HEAL         = "Infection.MedicZombieHeal";
const SFX_BEACON_BUILD        = "Building_Teleporter.SpinLevel1";
const SFX_BEACON_READY        = "Building_Teleporter.Ready";
const SFX_BEACON_DESTROY      = "Infection.EMP_Grenade_Explode";
const SFX_HEAVY_ROCK_WORLD    = "Infection.HeavyRockImpact";
const SFX_HEAVY_ROCK_FLESH    = "Halloween.HeadlessBossAxeHitFlesh";
const SFX_HEAVY_ROCK_CONCRETE = "Infection.HeavyRockImpact";
const SFX_HEAVY_FOOTSTEP      = "Halloween.HeadlessBossFootfalls";
const SFX_HEAVY_GRAB          = "Infection.HeavyRockGrab";
const SFX_HEAVY_THROW         = "Infection.HeavyRockThrow";

const DEMO_CHARGE_WINDUP_SEQUENCE = "charge_ready";
const DEMO_CHARGE_WINDUP_RATE     = 1.0;

arrDemoChargeWindupFallbackSeqs <-
[
    "taunt_yeti",
    "taunt_brutallegend",
    "taunt01",
    "stand_MELEE",
];

const SFX_ZOMBIE_EMERGE_RISE  = "Halloween.spell_skeleton_horde_rise";
const SFX_ZOMBIE_VO_MOAN      = "Halloween.GhostMoan";

::bZombieVOUseMoan <- false;

szArrZombieVOEvilLaugh <-
[
    "Scout.LaughEvil",
    "Scout.LaughEvil",
    "Sniper.LaughEvil",
    "Soldier.LaughEvil",
    "Demoman.LaughEvil",
    "Medic.LaughEvil",
    "Heavy.LaughEvil",
    "Pyro.LaughEvil",
    "Spy.LaughEvil",
    "Engineer.LaughEvil",
];

ARR_SFX_SPY_REVEAL_WAVS <-
[
    "infection/spy_reveal_01.wav",
    "infection/spy_reveal_02.wav",
    "infection/spy_reveal_03.wav",
];

ARR_SFX_SPEW_SPIT_WAVS <-
[
    "physics/surfaces/underwater_impact_bullet1.wav",
    "physics/surfaces/underwater_impact_bullet2.wav",
    "physics/surfaces/underwater_impact_bullet3.wav",
];

const SFX_SPEW_IMPACT_WAV = "physics/flesh/flesh_squishy_impact_hard2.wav";

const SFX_PYRO_SPEW_CAST = "Infection.PyroSpewCast"; // rndwave, once per cast
const SFX_PYRO_SPEW_SONG = "Infection.PyroSpewSong"; // personal, spewed client only

const KILLICON_SCOUT_MELEE      = "infection_scout";
const KILLICON_SOLDIER_MELEE    = "infection_soldier";
const KILLICON_PYRO_MELEE       = "infection_pyro";
const KILLICON_PYRO_BREATH      = "firedeath";
const KILLICON_PYRO_SPEW         = "firedeath";
const KILLICON_DEMOMAN_MELEE    = "infection_demoman";
const KILLICON_DEMOMAN_BOOM     = "soldier_taunt";
const KILLICON_HEAVY_MELEE      = "infection_heavy";
const KILLICON_HEAVY_ROCK       = "infection_heavy";
const KILLICON_ENGIE_MELEE      = "infection_engineer";
const KILLICON_ENGIE_EMP        = "infection_emp";
const KILLICON_MEDIC_MELEE      = "infection_medic";
const KILLICON_SNIPER_MELEE     = "infection_sniper";
const KILLICON_SNIPER_SPITPOOL  = "infection_acid_puddle";
const KILLICON_SNIPER_SPIT      = "infection_acid_ball";
const KILLICON_SPY_MELEE        = "unarmed_combat";

// debug icons
//const KILLICON_SCOUT_MELEE      = "megaton";
//const KILLICON_SOLDIER_MELEE    = "piranha";
//const KILLICON_PYRO_MELEE       = "helicopter";
//const KILLICON_PYRO_BREATH      = "firedeath";
//const KILLICON_DEMOMAN_MELEE    = "crocodile";
//const KILLICON_DEMOMAN_BOOM     = "taunt_soldier";
//const KILLICON_HEAVY_MELEE      = "krampus_ranged";
//const KILLICON_ENGIE_MELEE      = "krampus_melee";
//const KILLICON_ENGIE_EMP        = "resurfacer";
//const KILLICON_MEDIC_MELEE      = "salmann";
//const KILLICON_SNIPER_MELEE     = "shark";
//const KILLICON_SNIPER_SPITPOOL  = "gas_blast";
//const KILLICON_SNIPER_SPIT      = "hot_hand";
//const KILLICON_SPY_MELEE        = "unarmed_combat";

const MAT_SPIT_OVERLAY  = "effects/imcookin_green";
const MAT_SPEW_OVERLAY   = "effects/tar_overlay"; // screen tint while spewed - the gas cond used to do this

const MAT_SPAWN_PICKER_OVERLAY  = "effects/imcookin_green";

const SPAWN_PICKER_CYCLE_COOLDOWN   = 0.25;
const SPAWN_PICKER_AUTO_CONFIRM_TIME = 10.0;
const SPAWN_PICKER_CYCLE_REFUND     = 1.0;  // secs given back per cycle, capped at the default
const SPAWN_PICKER_INPUT_GRACE      = 0.4;
const SPAWN_PICKER_RENDER_ALPHA     = 0x80FFFFFF;
const SPAWN_PICKER_BEACON_UBER_TIME = 1.0;
const SPAWN_PICKER_CONFIRM_NO_JUMP_TIME = 0.5;

const SPAWN_BODY_CLASSNAME     = "prop_dynamic_override";
const SPAWN_BODY_TARGETNAME    = "zi_spawnbody";
const SPAWN_BODY_THINK_TIME    = 0.1;

const SPAWN_BODY_SKIN          = 3;
const SPAWN_BODY_SKIN_PLAIN    = 1;

const SPAWN_BODY_USE_NODRAW    = true;
const SPAWN_BODY_HIDDEN_ALPHA  = 0x00FFFFFF;

const SPAWN_BODY_IDLE_SEQUENCE = "stand_MELEE";
const SPAWN_BODY_IDLE_RATE     = 1.0;
const SPAWN_BODY_RISE_RATE     = 0.55;

const SPAWN_BODY_CYCLE_EPSILON = 0.05;

const SPAWN_BODY_RISE_SCAN_FOR      = "spawn";
const SPAWN_BODY_SEQUENCE_SCAN_MAX  = 1024;

szArrSpawnBodyRiseSeq <-
[
    "spawn_infected",   // unused
    "spawn_infected",   // scout
    "spawn_infected",   // sniper
    "spawn_infected",   // soldier
    "spawn_infected",   // demoman
    "spawn_infected",   // medic
    "spawn_infected",   // heavy
    "spawn_infected",   // pyro
    "spawn_infected",   // spy
    "spawn_infected",   // engineer
];

arrSpawnBodyRiseFallbackSeqs <-
[
    "spawn_infected",
    "taunt_yeti",
    "taunt_laugh",
    "taunt01",
    "stand_MELEE",
];

arrSpawnBodyIdleFallbackSeqs <-
[
    "stand_MELEE",
    "stand_PRIMARY",
    "Stand_MELEE",
    "idle",
    "ref",
];

const SPAWN_EMERGE_TIME        = 1.864; // length of spawn_infected at RISE_RATE 0.55
const SPAWN_EMERGE_SPAWN_DELAY = 0.2;  // extra hold on the last frame before the real spawn
const SPAWN_EMERGE_SINK_DEPTH  = 0.0;  // the body no longer slides up out of the floor - the anim does the rising

const SPAWN_GROUND_SNAP_DIST   = 128;  // how far below a floating spawn point we look for floor

const SPAWN_PICKER_HUD_COUNTDOWN_Y  = 0.62;
const SPAWN_PICKER_HUD_CONTROLS_Y   = 0.68;

const STRING_NETPROP_ITEMDEF  = "m_AttributeManager.m_Item.m_iItemDefinitionIndex";

const FLT_MAX     = 3.40282347e+38;
const ALIVE       = 0;
const ACT_LOCKED  = -2;
const INSTANT     = 0.0;

const ZHUD_X_POS  = 0.867;
const ZHUD_Y_POS  = 0.887;

const CLIENTPRINT_DELAY            = 0.5;
const MEDIC_HEAL_TICK_RATE         = 0.25;
const ENGIE_EMP_STATE_IN_TRANSIT   = 0;
const SPIT_STATE_IN_TRANSIT        = 0;
const SPIT_STATE_ZONE              = 1;
const SPIT_STATE_REJECTED          = 2;
const SPIT_STATE_FINDING_GROUND    = 3;

const PYRO_SPEW_STATE_IN_TRANSIT     = 0;
const PYRO_SPEW_STATE_FINDING_GROUND = 1;
const PYRO_SPEW_STATE_ZONE           = 2;

const ZOMBIE_ABILITY_CAST          = 1;
const ZOMBIE_TALK                  = 2;
const ZOMBIE_DO_ATTACK1            = 3;
const ZOMBIE_BECOME_ZOMBIE         = 4;
const ZOMBIE_BECOME_SURVIVOR       = 5;
const ZOMBIE_NEXT_QUEUED_EVENT     = 6;
const ZOMBIE_KILL_GLOW             = 7;
const ZOMBIE_REMOVE_HEALRING       = 8;
const ZOMBIE_CAN_CLIENTPRINT       = 9;
const ZOMBIE_CAN_SENTIENTDERGE     = 10;
const SURVIVOR_CAN_CLEAR_SCRIPT_SCREEN_OVERLAY = 11;
const ZOMBIE_CAN_CYCLE_SPAWN       = 12;
const ZOMBIE_AUTO_CONFIRM_SPAWN    = 13;
const ZOMBIE_FINISH_EMERGE         = 14;
const ZOMBIE_HEAVY_FOOTSTEP        = 15;

const EVENT_SNIPER_SPITBALL        = 1;
const EVENT_ENTER_SPY_REVEAL       = 2;
const EVENT_EXIT_SPY_REVEAL        = 3;
const EVENT_ENTER_MEDIC_HEAL       = 4;
const EVENT_EXIT_MEDIC_HEAL        = 5;
const EVENT_ENGIE_EXIT_MINIROOT    = 6;
const EVENT_ENGIE_THROW_NADE       = 7;
const EVENT_DEMO_CHARGE_START      = 8;
const EVENT_DEMO_CHARGE_EXIT       = 9;
const EVENT_PUT_ABILITY_ON_CD      = 10;
const EVENT_DOWNWARDS_VIEWPUNCH    = 11; // unused
const EVENT_KILL_TEMP_ENTITY       = 12;
const EVENT_DEMO_CHARGE_RESET      = 13;
const EVENT_SPY_RECLOAK            = 14;
const EVENT_SPY_SWAP_CLOAK         = 15;
const EVENT_RESET_ZOMBIE_WEP       = 16;
const EVENT_ENGIE_THROW_BEACON     = 17;
const EVENT_ENGIE_BEACON_EXIT_ROOT = 18;
const EVENT_HEAVY_END_THROW        = 19;
const EVENT_HEAVY_THROW_ROCK       = 20;
const EVENT_PYRO_SPEW_NEXT_BLOB     = 22;

const ZBIT_PARTICLE_HACK           = 0x1;
const ZBIT_PENDING_ZOMBIE          = 0x2;
const ZBIT_PENDING_UNZOMBIE        = 0x4;
const ZBIT_IS_UNJUMBLER            = 0x4;
const ZBIT_DEAD_ZOMBIE             = 0x8;
const ZBIT_ZOMBIE                  = 0x10;
const ZBIT_SURVIVOR                = 0x20;
const ZBIT_SNIPER_CHARGING_SPIT    = 0x40;
const ZBIT_SPY_IN_REVEAL           = 0x80;
const ZBIT_REVEALED_BY_SPY         = 0x100;
const ZBIT_INITIAL_INFECTION       = 0x200;
const ZBIT_HASNT_HEARD_READY_SFX   = 0x400;
const ZBIT_MEDIC_IN_HEAL           = 0x800;
const ZBIT_HEALING_FROM_ZMEDIC     = 0x1000;
const ZBIT_HASNT_HEARD_DENY_SFX    = 0x2000;
const ZBIT_IS_ULTING               = 0x4000;
const ZBIT_HAS_HUD                 = 0x8000;
const ZBIT_WAS_GIVEN_HUD_INFO      = 0x10000;
const ZBIT_HEAVY_ROCK_WINDUP       = 0x20000;
const ZBIT_MUST_EXPLODE            = 0x40000;
const ZBIT_OUT_OF_COMBAT           = 0x80000;
const ZBIT_THE_OMBUDSMAN           = 0x100000;
const ZBIT_SOLDIER_IN_POUNCE       = 0x400000;
const ZBIT_SCOUT_HAS_TRIPLE_JUMPED = 0x800000;
const ZBIT_DEMOCHARGE              = 0x1000000;
const ZBIT_IN_SPAWN_PICKER         = 0x2000000;
const ZBIT_SPEWED                  = 0x4000000;
const ZBIT_EMERGING_FROM_GROUND    = 0x8000000;

const ZABILITY_THROWABLE           = 0;
const ZABILITY_PROJECTILE          = 1;
const ZABILITY_EMITTER             = 2;
const ZABILITY_PASSIVE             = 3;
const ZABILITY_STATE_READY         = 0;
const ZABILITY_STATE_NOT_READY     = 1;

const ZHUD_X_READY_OFFSET          = 0.014;
const ZHUD_X_PASSIVE_OFFSET        = 0.006;

const TF_NERF_MINIGUN_Z_DMG        = 0.6;
const TF_NERF_SENTRY_Z_DMG         = 0.4;
const TF_NERF_SENTRY_Z_DMG_HEAVY   = 0.308;
const Z_NERF_SHIELD_TF_DMG         = 0.5;

const TF_IDX_UNDEFINED             = -1;
const TF_IDX_GWRENCH               = 169;
const TF_IDX_MEDIC_CROSSBOW        = 305;
const TF_IDX_SAXXY                 = 423;
const TF_IDX_SPYCICLE              = 649;
const TF_IDX_GOLDENPAN             = 1071;
const TF_IDX_GRAPPLING_HOOK        = 1152;

const TF_COND_SPEED_BOOST          = 32;
const TF_WEAPON_COUNT              = 7;
const TF_DEATH_FEIGN_DEATH         = 32;
const TF_DEATH_GIBBED              = 0x0080;

const HIDEHUD_BUILDING_STATUS     =  0x1000
const HIDEHUD_CLOAK_AND_FEIGN     =  0x2000
const HIDEHUD_PIPES_AND_CHARGE    =  0x4000
const HIDEHUD_METAL               =  0x8000