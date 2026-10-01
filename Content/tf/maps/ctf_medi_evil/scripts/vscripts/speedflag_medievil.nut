::FlagSpeedConfig <- { [1] = 0.75, [4] = 0.93, [5] = 0.94, [8] = 0.94 }

function OnGameEvent_teamplay_flag_event(params) {
    if (!("player" in params)) return

    local player = EntIndexToHScript(params.player)
    
    if (!player || !player.IsValid()) {
        player = GetPlayerFromUserID(params.player)
        if (!player || !player.IsValid()) return
    }

    if (params.eventtype == 1) {
        local pclass = player.GetPlayerClass()
        if (pclass in ::FlagSpeedConfig) {
            player.AddCustomAttribute("move speed penalty", ::FlagSpeedConfig[pclass], -1)
        }
    }
    else if (params.eventtype == 2 || params.eventtype == 4) {
        player.RemoveCustomAttribute("move speed penalty")
    }
}

__CollectGameEventCallbacks(this)