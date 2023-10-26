// --------------------------------------------------------------------------------------- //
// Infection - Prototype v0.5.1 - Last Edited: 29/08/2023                                  //
// --------------------------------------------------------------------------------------- //
// Code By: Harry Colquhoun (https://steamcommunity.com/profiles/76561198025795825)        //
// Assets/Game Design by: Diva Dan (https://steamcommunity.com/profiles/76561198072146551) //
// --------------------------------------------------------------------------------------- //
// This config file provides access to constants that are used for gameplay values         //
// Please edit with caution!                                                               //
/////////////////////////////////////////////////////////////////////////////////////////////
// Config Info |-------------------------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
// Name   : Vanilla Infection Config                                                       //
// Author : Harry Colquhoun & Diva Dan                                                     //
// Date   : 29/08/2023                                                                     //
// Map(s) : Any                                                                            //
// --------------------------------------------------------------------------------------- //
// Description:                                                                            //
// This is the default configuration for Infection mode, Intended for all maps.            //
// --------------------------------------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
// The Dreaded Bulletin |----------------------------------------------------------------- //
// there are a lot of ability values here that are missing.                                //
// these will be added in a later release.                                                 //
// --------------------------------------------------------------------------------------- //
////////////////////////////////////////////////
// Ability Name |---------------------------- //
////////////////////////////////////////////////
const SCOUT_PASSIVE_NAME  = "Speed Demon";    //
const PYRO_PASSIVE_NAME   = "Suit From Hell"; //
const HEAVY_PASSIVE_NAME  = "The Tank";       //
const ENGIE_EMP_NAME      = "EMP Grenade";    //
const DEMO_CHARGE_NAME    = "Charge";         //
const MEDIC_HEAL_NAME     = "Heal";           //
const SNIPER_SPIT_NAME    = "Spit";           //
const SOLDIER_POUNCE_NAME = "Pounce";         //
const SPY_REVEAL_NAME     = "Reveal";         //
// ------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////////////////////////////////
// Ability Description |------------------------------------------------------------------------------- //
//////////////////////////////////////////////////////////////////////////////////////////////////////////
// ---------------------------------------------------------------------------------------------------- //
// For Passive Abilities, this description shows with the prefix "You: "                                //
// ---------------------------------------------------------------------------------------------------- //
// For Active Abilities, this description shows with the prefix "Press RIGHT-CLICK To: "                //
// ---------------------------------------------------------------------------------------------------- //
const SCOUT_PASSIVE_DESC  = "Move much faster, but take much more damage.";                             //
const PYRO_PASSIVE_DESC   = "Are immune to fire and afterburn.";                                        //
const HEAVY_PASSIVE_DESC  = "Have a lot of health and can't be knocked back, but move very slowly.";    //
const ENGIE_EMP_DESC      = "Throw an EMP Grenade that disables buildings.";                            //
const DEMO_CHARGE_DESC    = "CHAAAARGE!!!!";                                                            //
const MEDIC_HEAL_DESC     = "Heal players in an area around you.";                                      //
const SNIPER_SPIT_DESC    = "Spit toxic acid that creates an area of damage.";                          //
const SOLDIER_POUNCE_DESC = "Leap in to the air.";                                                      //
const SPY_REVEAL_DESC     = "See players near you through the walls.";                                  //
// ---------------------------------------------------------------------------------------------------- //
//////////////////////////////////////////////////////////////////////////////////////////////////////////
// Cooldowns (in seconds) |--------------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
const MIN_TIME_BETWEEN_VIEWPUNCH       = 3;     // Internal Cooldown - viewpunch           //
const MIN_TIME_BETWEEN_VO              = 1;     // Internal Cooldown - zombie vo emit      //
const MIN_TIME_BETWEEN_CONVERT         = 0.1;   // Internal Cooldown - Apply zombie ents   //
// --------------------------------------------------------------------------------------- //
const MIN_TIME_BETWEEN_ENGIE_EMP_THROW = 10;    // Ability Cooldown  - Engie EMP Cast      //
// --------------------------------------------------------------------------------------- //
const MIN_TIME_BETWEEN_SPIT_START_END  = 1.5;   // Ability Delay     - Sniper Spit Channel //
const MIN_TIME_BETWEEN_SPIT_CAST       = 5;     // Ability Cooldown  - Sniper Spit Cast    //
// --------------------------------------------------------------------------------------- //
const MIN_TIME_BETWEEN_SPY_REVEAL      = 10;    // Ability Cooldown  - Spy Reveal Cast     //
// --------------------------------------------------------------------------------------- //
const MIN_TIME_BETWEEN_SOLDIER_POUNCE  = 10;    // Ability Cooldown  - Soldier Pounce Cast //
// --------------------------------------------------------------------------------------- //
const MIN_TIME_BETWEEN_MEDIC_HEAL      = 11;    // Ability Cooldown  - Medic Heal Cast     //
// --------------------------------------------------------------------------------------- //
const MIN_TIME_BETWEEN_DEMO_CHARGE     = 6;     // Ability Cooldown  - Demo Charge Cast    //
/////////////////////////////////////////////////////////////////////////////////////////////
// Game mode values |--------------------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
const ADDITIONAL_SEC_PER_PLAYER        = 10;    // Additional time added per player        //
const ROUND_TIMER_NAME   = "infection_timer"    // targetname of round timer entity        //
/////////////////////////////////////////////////////////////////////////////////////////////
// Zombie Stats |------------------------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
// --------------------------------------------------------------------------------------- //
// Damage Multiplier values for Zombie weapons                                             //
// --------------------------------------------------------------------------------------- //
const ZSCOUT_DMG_MULTI                 = 2;    // Scout    Zombie Damage Multiplier        //
const ZSNIPER_DMG_MULTI                = 1.5;  // Sniper   Zombie Damage Multiplier        //
const ZSOLDIER_DMG_MULTI               = 1.5;  // Soldier  Zombie Damage Multiplier        //
const ZDEMOMAN_DMG_MULTI               = 1.5;  // Demoman  Zombie Damage Multiplier        //
const ZMEDIC_DMG_MULTI                 = 1.5;  // Medic    Zombie Damage Multiplier        //
const ZHEAVY_DMG_MULTI                 = 2;    // Heavy    Zombie Damage Multiplier        //
const ZPYRO_DMG_MULTI                  = 1.5;  // Pyro     Zombie Damage Multiplier        //
const ZSPY_DMG_MULTI                   = 1.5;  // Spy      Zombie Damage Multiplier        //
const ZENGINEER_DMG_MULTI              = 1.5;  // Engineer Zombie Damage Multiplier        //
// --------------------------------------------------------------------------------------- //
// Item Definition Index (IDX) for each class' Zombie weapon                               //
// --------------------------------------------------------------------------------------- //
ZOMBIE_WEAPON_IDX <-[                           //                                         //
    30758,                                      // scout                                   //
    30758,                                      // scout                                   //
    30758,                                      // sniper                                  //
    30758,                                      // soldier                                 //
    30758,                                      // demoman                                 //
    30758,                                      // medic                                   //
    30758,                                      // heavyweapons                            //
    30758,                                      // pyro                                    //
    30758,                                      // spy                                     //
    30758,                                      // engineer                                //
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
["melee range multiplier", 1.5, -1 ],           // Increase melee range for zombie         //
["melee bounds multiplier", 1.5, -1 ],          // Increase melee range for zombie         //
["crit mod disabled hidden", 0, -1],            // No crits                                //
],                                              //                                         //
[// attributes for scout zombie weapon --------------------------------------------------- //
["damage bonus", ZSCOUT_DMG_MULTI, -1 ],        // set class specific damage multi         //
["move speed bonus", 1.75, -1 ],                // extra movement speed for scout passive  //
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
[// attributes for heavyweapons zombie weapon -------------------------------------------- //
["damage bonus", ZHEAVY_DMG_MULTI, -1 ],        // set class specific damage multi         //
["increased jump height from weapon", 2, -1],   // give zombie heavy a higher jump for qol //
],                                              //                                         //
[// attributes for pyro zombie weapon ---------------------------------------------------- //
["damage bonus", ZPYRO_DMG_MULTI, -1 ],         // set class specific damage multi         //
["dmg taken from fire reduced", 100, -1 ],      // zombie pyro cannot be damaged by fire   //
["afterburn immunity", 1, -1 ],                 // zombie pyro cannot be damaged by fire   //
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
    TF_COND_SPEED_BOOST,                        // Speed lines make you go faster          //
],                                              //                                         //
[// TF_CONDs applied to scout zombie ----------------------------------------------------- //
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
    TF_COND_NO_KNOCKBACK,                       // heavy zombie can't be knocked back      //
],                                              //                                         //
[// TF_CONDs applied to pyro zombie ------------------------------------------------------ //
],                                              //                                         //
[// TF_CONDs applied to spy zombie ------------------------------------------------------- //
],                                              //                                         //
[// TF_CONDs applied to engy zombie ------------------------------------------------------ //
],                                              //                                         //
];                                              //                                         //
// --------------------------------------------------------------------------------------- //
// Zombie Player Attributes - Player type attributes for each class when playing as zombie //
// --------------------------------------------------------------------------------------- //
// TF_ATTRIB Array | [string condition, fl value, fl duration (-1 for infinite )]          //
// (https://wiki.teamfortress.com/wiki/List_of_item_attributes)                            //
// --------------------------------------------------------------------------------------- //
ZOMBIE_PLAYER_ATTRIBS <- [ //////////////////////////////////////////////////////////////////
[// attributes applied to all zombie weps ------------------------------------------------ //
["SPELL: set Halloween footstep type", 4552221, -1 ], // corrupted green footsteps         //
["crit mod disabled hidden", 0, -1],            // No crits                                //
["cancel falling damage", 1, -1],               // No fall damage                          //
//voice pitch scale", 0, -1],                   // Makes player voice inaudible            //
["health from packs decreased", 0, -1],         // Cannot pick up health packs             //
["zombiezombiezombiezombie", 1.0, -1],          //
],                                              //                                         //
[// attributes for scout zombie  --------------------------------------------------------- //
[ "no double jump", 0.1, -1 ],                  //                                         //
[ "max health additive penalty", 45, -1 ],      // set max health to value. default 45.    //
],                                              //                                         //
[// attributes for sniper zombie  -------------------------------------------------------- //
[],                                             //                                         //
],                                              //                                         //
[// attributes for soldier zombie  ------------------------------------------------------- //
[],                                             //                                         //
],                                              //                                         //
[// attributes for demo zombie  ---------------------------------------------------------- //
[],                                             //                                         //
],                                              //                                         //
[// attributes for medic zombie  --------------------------------------------------------- //
[],                                             //                                         //
],                                              //                                         //
[// attributes for heavyweapons zombie  -------------------------------------------------- //
[ "max health additive penalty", 550, -1 ],     //                                         //
[ "move speed penalty", 0.45, -1 ],             //                                         //
[ "dmg bonus vs buildings", 100, -1 ],          //                                         //
],                                              //                                         //
[// attributes for pyro zombie  ---------------------------------------------------------- //
[ "dmg taken from fire reduced", 85, -1 ],      //                                         //
[ "afterburn immunity", 1, -1 ],                //                                         //
],                                              //                                         //
[// attributes for spy zombie  ----------------------------------------------------------- //
[],                                             //                                         //
],                                              //                                         //
[// attributes for engy zombie  ---------------------------------------------------------- //
[],                                             //                                         //
],                                              //                                         //
];                                              //                                         //
// --------------------------------------------------------------------------------------- //
// Zombie voice over pool.                                                                 //
// --------------------------------------------------------------------------------------- //
::ZOMBIE_VOICE_SFX <- [                         //                                         //
"Taunt.YetiRoarBeginning",                      // yeti taunt roar sound                   //
"Taunt.YetiRoarFirst",                          // yeti taunt roar sound                   //
"Taunt.YetiRoadSecond"                          // yeti taunt roar sound                   //
];                                              //                                         //
/////////////////////////////////////////////////////////////////////////////////////////////
// Zombie Win Condition |----------------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
const MAX_SURVIVORS_FOR_ZOMBIE_WIN     = 0;     // if less than x red alive, zombies win   //
/////////////////////////////////////////////////////////////////////////////////////////////
// Entity Think Function Rethink Times |-------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
// --------------------------------------------------------------------------------------- //
const PLAYER_RETHINK_TIME              = 0.0;   // How often the player thinks             //
const ENGIE_EMP_RETHINK_TIME           = 0.1;   // How often the EMP grenade thinks        //
const SNIPER_SPIT_RETHINK_TIME         = 0.03;  // How often the sniper spit thinks        //
const SNIPER_SPIT_ZONE_RETHINK_TIME    = 0.5;   // How often the sniper spit ZONE thinks   //
const ENGIE_EMP_BUILDING_RETHINK_TIME  = 0.1;   // How often the EMP'd building thimax_nks     //
// --------------------------------------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
// ZombieEngie EMP Grenade Abiltiy |------------------------------------------------------ //
/////////////////////////////////////////////////////////////////////////////////////////////
const ENGIE_EMP_LIFETIME               = 5;     // How long the EMP lasts for once thrown  //
// --------------------------------------------------------------------------------------- //
const ENGIE_EMP_BUILDING_DISABLE_TIME  = 5;     // how long is a hit buildable disabled    //
const ENGIE_EMP_BUILDING_DISABLE_RANGE = 500;   // range from grenade explode to disable   //
// --------------------------------------------------------------------------------------- //
const ENGIE_EMP_THROW_DIST_FROM_EYES   = -20;   // distance from eyes to spawn grenade     //
const ENGIE_EMP_THROW_FORCE            = 1500;  // initial force to apply to nade          //
// --------------------------------------------------------------------------------------- //
const ENGIE_EMP_INITIAL_FLASH_RATE     = 0.85;  // initial delay between each flash        //
const ENGIE_EMP_FLASH_RATE_DECAY_FAC   = 0.75;  // amnt delay reduced between flashes      //
// --------------------------------------------------------------------------------------- //
const ENGIE_EMP_SCREENSHAKE_AMP        = 500;   // amplitude of grenade screenshake        //
const ENGIE_EMP_SCREENSHAKE_FREQ       = 500;   // frequency of grenade screenshake        //
const ENGIE_EMP_SCREENSHAKE_DUR        = 1;     // duration of grenade screenshake         //
const ENGIE_EMP_SCREENSHAKE_RAD        = 1000;  // duration of grenade screenshake         //
// --------------------------------------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
// ZombieSniper Spit Abiltiy |------------------------------------------------------------ //
/////////////////////////////////////////////////////////////////////////////////////////////
const SNIPER_SPIT_THROW_DIST           = 50;    // distance from eyes to spawn spit ball   //
const SNIPER_SPIT_THROW_FORCE          = 2000;  // initial force to apply to spit ball     //
const SNIPER_SPIT_HIT_PLAYER_Z_DIST    = 300;   // initial force to apply to spit ball     //
const SNIPER_SPIT_HIT_WORLD_Z_DIST     = 15;    // initial force to apply to spit ball     //
// --------------------------------------------------------------------------------------- //
const SNIPER_SPIT_MASS                 = 0.1;   // spit ball mass (for base physprop)      //
// --------------------------------------------------------------------------------------- //
const SNIPER_SPIT_ZONE_DAMAGE          = 10.0;  // damage per tick from spit zone          //
const SNIPER_SPIT_POP_DAMAGE           = 20.0;  // dmg to players in zone when first pop   //
const SNIPER_SPIT_MIN_SURFACE_PERCENT  = 35;    // min surface hit % for spit zone to form //
const SNIPER_SPIT_HITBOX_SIZE          = 10;    // size in hu of spitball hitbox           //
// --------------------------------------------------------------------------------------- //
const SNIPER_SPIT_OVERLOAD_START_TIME  = 3.5;   // how many seconds til overload           //
const SNIPER_SPIT_LIFETIME             = 2.5;   // how many seconds til overload           //
const SNIPER_SPIT_MAX_CHANNEL_TIME     = 5;     // max time spitball can be held for       //
const SPIT_ZONE_LIFETIME               = 5;     // how many seconds the zone stays down    //
const SPIT_ZONE_RADIUS                 = 125;   // hammer units radius of spit zone damage //
// --------------------------------------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
// ZombieSpy Reveal Abiltiy |------------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
const SPY_REVEAL_RANGE                 = 1000;  // Maximum distance for player to be hit   //
const SPY_REVEAL_LENGTH                = 20;    // how long players are revealed for (sec) //
// --------------------------------------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
// ZombieMedic Heal Abiltiy |------------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
const MEDIC_HEAL_RANGE                 = 1000;  // Maximum distance for player to be hit   //
const MEDIC_HEAL_RATE                  = 1.5;   // time in sec between each heal tick      //
// --------------------------------------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
// --------------------------------------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
// ZombieHeavy Passive Values |----------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
const HEAVY_KNOCK_BACK_FORCE           = 125;   // knock back force on heavy punch         //
// --------------------------------------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////