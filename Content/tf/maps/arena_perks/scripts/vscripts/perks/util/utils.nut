// --------------------------------------------------------------------------------------- //
// Perks - Version 1.4                                                                     //
// --------------------------------------------------------------------------------------- //
// Game Design and Scripting by: Le Codex (https://steamcommunity.com/id/lecodex)          //
// Assets by: Diva Dan (https://steamcommunity.com/profiles/76561198072146551)             //
// and Tianes (https://steamcommunity.com/id/_tianes)                                      //
// --------------------------------------------------------------------------------------- //

::RunWithDelay <- function(next, delay, args=clone [mainLogic]) {
    local callbackName = UniqueString("callback");
    mainLogicEntity.ValidateScriptScope()
    mainLogicEntity.GetScriptScope()[callbackName] <- function() {
        next.acall(args);
    }

    EntFireByHandle(mainLogicEntity, "RunScriptCode", callbackName + "()", delay, null, null);
    EntFireByHandle(mainLogicEntity, "RunScriptCode", "delete " + callbackName, delay+0.1, null, null);
}

::TeamName <- function(team, natural=false) {
    return natural ? 
        (team == Constants.ETFTeam.TF_TEAM_RED ? "Red" : "Blue") : 
        (team == Constants.ETFTeam.TF_TEAM_RED ? "red" : "blu")
}

::MaxLineLength <- function(str) {
    local max = 0;

    foreach (line in split(str, "\n")) {
        if (line.len() > max) max = line.len();
    }

    return max;
}

::randomlyChoose <- function(list) {
    return list[rand() % list.len()];
}
