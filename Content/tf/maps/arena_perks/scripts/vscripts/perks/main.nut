// --------------------------------------------------------------------------------------- //
// Perks - Version 1.3                                                                     //
// --------------------------------------------------------------------------------------- //
// Game Design and Scripting by: Le Codex (https://steamcommunity.com/id/lecodex)          //
// Assets by: Diva Dan (https://steamcommunity.com/profiles/76561198072146551)             //
// and Tianes (https://steamcommunity.com/id/_tianes)                                      //
// --------------------------------------------------------------------------------------- //

::mainLogic <- this;
::mainLogicEntity <- self;


// IncludeScript("perks/util/listeners.nut");
IncludeScript("perks/util/constants.nut");
IncludeScript("perks/util/utils.nut");
IncludeScript("perks/util/player_util.nut");

// IncludeScript("perks/gamemode/states.nut");
IncludeScript("perks/gamemode/manager.nut");
IncludeScript("perks/gamemode/perks.nut");
IncludeScript("perks/gamemode/main.nut");
IncludeScript("perks/util/game_events.nut");


// No respawn
EntFireByHandle(GAMERULES, "SetRedTeamRespawnWaveTime", "99999", -1, null, null);
EntFireByHandle(GAMERULES, "SetBlueTeamRespawnWaveTime", "99999", -1, null, null);


// Callbacks
EntityOutputs.AddOutput(PLAYER_DESTRUCTION_LOGIC, "OnRedHitMaxPoints", "!self", "RunScriptFile", "perks/callback/game_end.nut", 0, -1);
EntityOutputs.AddOutput(PLAYER_DESTRUCTION_LOGIC, "OnBlueHitMaxPoints", "!self", "RunScriptFile", "perks/callback/game_end.nut", 0, -1);

EntityOutputs.AddOutput(CENTRAL_CP, "OnCapTeam1", "!self", "RunScriptFile", "perks/callback/red_capture.nut", 0, -1);
EntityOutputs.AddOutput(CENTRAL_CP, "OnCapTeam2", "!self", "RunScriptFile", "perks/callback/blu_capture.nut", 0, -1);
EntityOutputs.AddOutput(CENTRAL_CP, "OnUnlocked", "!self", "RunScriptFile", "perks/callback/point_unlock.nut", 0, -1);


// Initial state change
::PerkGamemode.ChangeState("vote");

// function Think() {
//     FireListeners("think");
// }