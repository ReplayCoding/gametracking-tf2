// --------------------------------------------------------------------------------------- //
// Perks - Version 1.4                                                                     //
// --------------------------------------------------------------------------------------- //
// Game Design and Scripting by: Le Codex (https://steamcommunity.com/id/lecodex)          //
// Assets by: Diva Dan (https://steamcommunity.com/profiles/76561198072146551)             //
// and Tianes (https://steamcommunity.com/id/_tianes)                                      //
// --------------------------------------------------------------------------------------- //

ClearGameEventCallbacks();

function OnGameEvent_player_spawn(params) {
    RunWithDelay(function(params) {
        ::PerkGamemode.OnSpawn(params);
    }, 0.1, [this, params]);
}

function OnGameEvent_player_death(params) {
    // printl("OH NO SOMEONE DIED");
    ::PerkGamemode.OnDeath(params);
}

function OnGameEvent_player_disconnect(params) {
    ::PerkGamemode.OnLeave(params);
}

__CollectGameEventCallbacks(this);
__CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);