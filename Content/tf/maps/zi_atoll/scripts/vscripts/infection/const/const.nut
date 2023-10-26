// --------------------------------------------------------------------------------------- //
// Infection - Prototype v0.5.1 - Last Edited: 29/08/2023                                  //
// --------------------------------------------------------------------------------------- //
// Code By: Harry Colquhoun (https://steamcommunity.com/profiles/76561198025795825)        //
// Assets/Game Design by: Diva Dan (https://steamcommunity.com/profiles/76561198072146551) //
// --------------------------------------------------------------------------------------- //
// infection constants                                                                     //
// --------------------------------------------------------------------------------------- //

const _CONST = true;

const STRING_GAMEMODE_NAME         = "Infection";
const STRING_SURVIVOR_START        = "You are a Survivor. Fight off the zombie horde and survive to win.";
const STRING_SETUP_END             = "The infection is spreading... Find a safe location!";
const STRING_SURVIVOR_DIE          = " was infected by ";
const STRING_UI_ABILITY_READY      = "Your Ability is %s\n\nPress RIGHT-CLICK To: %s\n\nREADY TO CAST!"
const STRING_UI_ABILITY_CHARGING   = "Your Ability is %s\n\nPress RIGHT-CLICK To: %s\n\nNext Cast in %i"
const STRING_UI_ABILITY_PASSIVE    = "Your Passive is %s\n\nThis Means You: %s"
const STRING_UI_CHAT_INFECT_MSG    = "\x07FF3F3F%s\x07FBECCB was infected by \x0738F3AB%s\x07FBECCB!"

const ERROR_BAD_FLAG_SPITBALL      = "ZBIT_SNIPER_CHARGING_SPIT flag set on non-sniper player";
const ERROR_BAD_EVENT_IN_QUEUE     = "Event queue attempted to perform an undefined event";
const ERROR_CANT_CAST_PASSIVE      = "attempted to call AbilityCast() method on passive ability";
const ERROR_SPIT_CANT_FIND_WORLD   = "sniper spitball couldn't find world beneth to create zone! destroying...";
const ERROR_BAD_SETUP_ZOMBIE_PICKS = "GetRandomPlayers returned not an array or there are no players in the array. Choosing a random valid player as a fallback zombie";
const ERROR_BAD_MAPNAME            = "Map name must begin with correct prefix for game mode to load!! Aborting...";
const ERROR_NO_ROUND_TIMER         = "Entity team_round_timer not found on level. Please read the documentation!!!";
const ERROR_NO_PLAYER_FOUND        = "No players found when evaluating win condition. Game might be bricked!!!"

const DEBUG_REMOVED_EVENTS         = "Removed %i events from queue";

const INFO_APPLY_ATTRIBS           = "applied attrib %s to player %s with value %i";
const INFO_APPLY_CONDS             = "applied TF cond %i to player %s";
const INFO_REMOVE_ATTRIBS          = "removed attrib %s from player %s";
const INFO_REMOVE_CONDS            = "removed TF cond %i from player %s";
const INFO_FOUND_SURVIVOR          = "%s is valid survivor. found %i valid survivors";
const INFO_ZOMBIES_WIN             = "_iValidSurvivors is less than MAX_SURVIVORS_FOR_ZOMBIE_WIN. Ending round in favour of TF_TEAM_BLUE (zombies)";

const FLT_MAX                      = 3.40282347e+38;
const TF_COND_SPEED_BOOST          = 32; // no idea why the game doesn't recognise this single cond?
const TF_WEAPON_COUNT              = 7;
const TF_COND_NO_KNOCKBACK         = 130;

const ALIVE   = 0;
const INSTANT = 0.0;

const ELVL_DEBUG  = 0;
const ELVL_INFO   = 1;
const ELVL_WARN   = 2;
const ELVL_ERROR  = 3;
const ELVL_FATAL  = 4;

const ENGIE_EMP_STATE_IN_TRANSIT   = 0;

const SPIT_STATE_IN_TRANSIT        = 0;
const SPIT_STATE_ZONE              = 1;
const SPIT_STATE_REJECTED          = 2;

const ACT_LOCKED                   = -2;
const NO_RETHINK                   = -1;

const ZOMBIE_ABILITY_CAST          = 1;
const ZOMBIE_TALK                  = 2;
const ZOMBIE_DO_ATTACK1            = 3;
const ZOMBIE_BECOME_ZOMBIE         = 4;
const ZOMBIE_BECOME_SURVIVOR       = 5;
const ZOMBIE_NEXT_QUEUED_EVENT     = 6;
const ZOMBIE_KILL_GLOW             = 7;
const ZOMBIE_REMOVE_HEALRING       = 8;

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
const EVENT_DOWNWARDS_VIEWPUNCH    = 11;

const ZBIT_PARTICLE_HACK           = 0x1;
const ZBIT_PENDING_ZOMBIE          = 0x2;
const ZBIT_PENDING_UNZOMBIE        = 0x4;
const ZBIT_DEAD_ZOMBIE             = 0x8;
const ZBIT_ZOMBIE                  = 0x10;
const ZBIT_SURVIVOR                = 0x20;
const ZBIT_SNIPER_CHARGING_SPIT    = 0x40;
const ZBIT_SPY_IN_REVEAL           = 0x80;
const ZBIT_REVEALED_BY_SPY         = 0x100;
const ZBIT_HASNT_HEARD_READY_SFX   = 0x400;
const ZBIT_MEDIC_IN_HEAL           = 0x800;
const ZBIT_HEALING_FROM_ZMEDIC     = 0x1000;
const ZBIT_HASNT_HEARD_DENY_SFX    = 0x2000;

const ZABILITY_THROWABLE           = 0;
const ZABILITY_PROJECTILE          = 1;
const ZABILITY_EMITTER             = 2;
const ZABILITY_PASSIVE             = 3;
