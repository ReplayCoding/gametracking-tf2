// --------------------------------------------------------------------------------------- //
// Perks - Version 1.4                                                                     //
// --------------------------------------------------------------------------------------- //
// Game Design and Scripting by: Le Codex (https://steamcommunity.com/id/lecodex)          //
// Assets by: Diva Dan (https://steamcommunity.com/profiles/76561198072146551)             //
// and Tianes (https://steamcommunity.com/id/_tianes)                                      //
// --------------------------------------------------------------------------------------- //

// ---------------- //
// STATE CLASSES    //
// ---------------- //
class PerkGameStateBase {
    function OnEnter() {}
    function OnExit() {}

    function OnSpawn(params) {}
    function OnDeath(params) {}
    function OnLeave(params) {}
    function OnPointUnlocked() {}
}


class PerkGameStateVote extends PerkGameStateBase {
    TextPerkNameRed = null;
    TextPerkDescRed = null;
    TextPerkNameBlu = null;
    TextPerkDescBlu = null;

    constructor() {
        TextPerkNameRed = Entities.FindByName(null, "text_perk_red_name");
        TextPerkDescRed = Entities.FindByName(null, "text_perk_red_desc");
        TextPerkNameBlu = Entities.FindByName(null, "text_perk_blu_name");
        TextPerkDescBlu = Entities.FindByName(null, "text_perk_blu_desc");
    }

    function OnEnter() {
        // NetProps.SetPropInt(GAMERULES, "m_iRoundState", Constants.ERoundState.GR_STATE_RND_RUNNING);

        EntFireByHandle(GAME_TIMER, "Enable", "", -1, null, null);
        EntFireByHandle(GAME_TIMER, "RoundSpawn", "", 0, null, null);
        EntityOutputs.AddOutput(GAME_TIMER, "OnSetupFinished", "!self", "RunScriptFile", "perks/callback/setup_end", 0, 1);

        EntFire("arena_spawnpoints", "Disable", "", -1, null);
        EntFire("music_perk_phase", "PlaySound", "", 0, null);
        EntFire("perk_glow", "ShowSprite", "", 0, null);
        EntFire("perk_beam", "Enable", "", 0, null);
        EntFire("perk_particles", "Start", "", 0, null);
        EntFire("t_waiting_regenerate", "ForceSpawn", "", 0, null);

        foreach (manager in ::PerkGamemode.PerkManagers) {
            manager.RollPerks();
        }
    }

    function OnExit() {
        EntFire("music_perk_phase", "StopSound", "", 0, null);
        EntFire("perk_glow", "HideSprite", "", 0, null);
        EntFire("perk_beam", "Disable", "", 0, null);
        EntFire("perk_particles", "Stop", "", 0, null);
        EntFire("waiting_regenerate", "Kill", "", 0, null);

        // Count the votes
        local teamVotes = {};

        teamVotes[Constants.ETFTeam.TF_TEAM_RED] <- {};
        teamVotes[Constants.ETFTeam.TF_TEAM_BLUE] <- {};
        for (local i=1; i <= 3; i++) {
            teamVotes[Constants.ETFTeam.TF_TEAM_RED][i] <- 0;
            teamVotes[Constants.ETFTeam.TF_TEAM_BLUE][i] <- 0;
        }

        foreach (player in GetAllPlayers()) {
            local res = CountVote(player);
            if (!res) continue;

            teamVotes[res.team][res.index]++;
        }

        // Collect the perks
        local chosenPerks = {}
        foreach (team, votes in teamVotes) {
            local maxVotes = 0;
            foreach (index, voteCount in votes) if (voteCount > maxVotes) maxVotes = voteCount;

            local topIndexes = [];
            foreach (index, voteCount in votes) if (voteCount == maxVotes) topIndexes.push(index);

            local index = randomlyChoose(topIndexes);
            chosenPerks[team] <- ::PerkGamemode.PerkManagers[team].Collect(index-1);
        }

        // Show everyone which perks have been chosen
        local redPerk = chosenPerks[Constants.ETFTeam.TF_TEAM_RED];
        NetProps.SetPropString(TextPerkNameRed, "m_iszMessage", redPerk.Name);
        NetProps.SetPropString(TextPerkDescRed, "m_iszMessage", redPerk.Description);
        EntFire("text_perk_red_title", "Display", "", 0, null);
        EntFireByHandle(TextPerkNameRed, "Display", "", 0, null, null);
        EntFireByHandle(TextPerkDescRed, "Display", "", 0, null, null);

        local bluPerk = chosenPerks[Constants.ETFTeam.TF_TEAM_BLUE];
        NetProps.SetPropString(TextPerkNameBlu, "m_iszMessage", bluPerk.Name);
        NetProps.SetPropString(TextPerkDescBlu, "m_iszMessage", bluPerk.Description);
        EntFire("text_perk_blu_title", "Display", "", 0, null);
        EntFireByHandle(TextPerkNameBlu, "Display", "", 0, null, null);
        EntFireByHandle(TextPerkDescBlu, "Display", "", 0, null, null);
    }

    function CountVote(player) {
        local team = player.GetTeam();
        local baseName = "trigger_votes_"+TeamName(team);
        
        for (local ent; ent = Entities.FindInSphere(ent, player.GetOrigin(), 1);) {
            for (local i = 1; i <= 3; i++) {
                // printl("FOUND ENTITY for " + player + ": " + ent.GetName())
                if (ent.GetName() == baseName+i) return {team = team, index = i};
            }
        }

        return null;
    }
}


class PerkGameStateTransition extends PerkGameStateBase {
    function OnEnter() {
        EntityOutputs.AddOutput(GAME_TIMER, "OnFinished", "!self", "RunScriptFile", "perks/callback/round_start.nut", 0, 1);
    }
}


class PerkGameStateRound extends PerkGameStateBase {
    TextPlayerCounterRed = null;
    TextPlayerCounterBlu = null;

    constructor() {
        TextPlayerCounterRed = Entities.FindByName(null, "text_playercounter_red");
        TextPlayerCounterBlu = Entities.FindByName(null, "text_playercounter_blu");
    }

    function OnEnter() {
        EntFire("arena_spawnpoints", "Enable", "", -1, null);
        EntFire("vote_spawnpoints", "Disable", "", -1, null);
        
        EntFireByHandle(GAME_TIMER, "Disable", "", 0, null, null);

        foreach (player in GetAllPlayers()) {
            ClearWeaponCache(player);
        }

        foreach (manager in ::PerkGamemode.PerkManagers) {
            manager.OnRoundStart();
        }

        // RunWithDelay(function() { 
        //     foreach (player in GetAllPlayers()) {

        //         player.Regenerate(true);
        //         player.ForceRespawn(); 
        //     }
        // }, 0.1);

        EntFire("game_forcerespawn", "ForceRespawn", "", 0.3, null);
        EntFire("arena_spawnpoints", "Disable", "", 1, null);
        EntFire("trap_spawnpoint", "Enable", "", 1, null);

        // NetProps.SetPropInt(GAMERULES, "m_iRoundState", Constants.ERoundState.GR_STATE_STALEMATE);

        EntFireByHandle(CENTRAL_CP, "SetLocked", "1", 0, null, null);
        EntFireByHandle(CENTRAL_CP, "SetUnlockTime", "50", 0, null, null);
        EntFireByHandle(CENTRAL_CP, "HideModel", "", 0, null, null);

        RunWithDelay(CountAlivePlayers, 0.5, [this, false]);
    }

    function OnSpawn(params) {
        local player = GetPlayerFromUserID(params.userid);
        local team = player.GetTeam();
        if (team != Constants.ETFTeam.TF_TEAM_RED && team != Constants.ETFTeam.TF_TEAM_BLUE) return;

        ::PerkGamemode.PerkManagers[team].OnSpawn(player);
        ::PerkGamemode.PerkManagers[5-team].OnEnemySpawn(player);
    }

    function OnDeath(params) {
        // printl("CHECKIG FOR STATE");
        local victim = GetPlayerFromUserID(params.userid);
        local vteam = victim.GetTeam();
        if (vteam != Constants.ETFTeam.TF_TEAM_RED && vteam != Constants.ETFTeam.TF_TEAM_BLUE) return;
        
        local attacker = GetPlayerFromUserID(params.attacker);

        ::PerkGamemode.PerkManagers[vteam].OnDeath(victim, attacker);
        if (attacker) {
            local ateam = attacker.GetTeam();
            ::PerkGamemode.PerkManagers[ateam].OnKill(attacker, victim);
        }

        RunWithDelay(CountAlivePlayers, 0.1, [this, true]);
    }

    function OnLeave(params) {
        RunWithDelay(CountAlivePlayers, 0.1, [this, true]);
    }

    function OnPointUnlocked() {
        foreach (manager in ::PerkGamemode.PerkManagers) {
            manager.OnPointUnlocked();
        }
    }

    function CountAlivePlayers(checkForGameEnd=false)
    {
        // printl("CHECKIG FOR GAME END");
        local redAlive = GetAliveTeamPlayerCount(Constants.ETFTeam.TF_TEAM_RED);
        local bluAlive = GetAliveTeamPlayerCount(Constants.ETFTeam.TF_TEAM_BLUE);

        NetProps.SetPropString(TextPlayerCounterRed, "m_iszMessage", redAlive.tostring());
        NetProps.SetPropString(TextPlayerCounterBlu, "m_iszMessage", bluAlive.tostring());
        EntFireByHandle(TextPlayerCounterRed, "Display", "", 0, null, null);
        EntFireByHandle(TextPlayerCounterBlu, "Display", "", 0, null, null);

        if (checkForGameEnd) {
            local redTeamDead = redAlive == 0;
            local bluTeamDead = bluAlive == 0;

            if (redTeamDead && bluTeamDead) return WinRound(0);
            if (redTeamDead) return WinRound(Constants.ETFTeam.TF_TEAM_BLUE);
            if (bluTeamDead) return WinRound(Constants.ETFTeam.TF_TEAM_RED);
        }
    }

    function WinRound(winnerTeam) {
        if (winnerTeam) {
            EntFireByHandle(PLAYER_DESTRUCTION_LOGIC, "Score"+TeamName(winnerTeam, true)+"Points", "", 0, null, null);
            EntFire("text_win_"+TeamName(winnerTeam), "Display", "", 0, null);
        } else {
            EntFireByHandle(PLAYER_DESTRUCTION_LOGIC, "ScoreRedPoints", "", 0, null, null);
            EntFireByHandle(PLAYER_DESTRUCTION_LOGIC, "ScoreBluePoints", "", 0, null, null);
            EntFire("text_win_none", "Display", "", 0, null);
        }

       foreach (player in GetAllPlayers()) {
            local team = player.GetTeam();
            if (!winnerTeam || team != winnerTeam) {
                StunPlayer(player, 9999);
            } else {
                player.AddCondEx(Constants.ETFCond.TF_COND_CRITBOOSTED_FIRST_BLOOD, 9999, null);
            }
        }

        EntFire("trigger_stun", "Kill", "", 0.1, null);
        ::PerkGamemode.ChangeState("round_end");
    }
}


class PerkGameStateRoundEnd extends PerkGameStateBase {
    function OnEnter() {
        RunWithDelay(function() {
            if (GetRoundState() == Constants.ERoundState.GR_STATE_RND_RUNNING) ::PerkGamemode.ChangeState("vote");
        }, 5);

        // NetProps.SetPropIntArray(Entities.FindByClassname(null, "tf_objective_resource"), "m_iOwner", 0, 0);
        EntFireByHandle(CENTRAL_CP, "SetOwner", "0", 3, mainLogicEntity, mainLogicEntity);
        EntFire("cp_1_prop", "Skin", "0", 3, null);
        EntFireByHandle(CENTRAL_CP, "SetLocked", "1", 0, null, null);

        foreach (manager in ::PerkGamemode.PerkManagers) {
            manager.OnRoundEnd();
        }
    }

    function OnExit() {
        EntFire("vote_spawnpoints", "Enable", "", -1, null);
        EntFire("trap_spawnpoint", "Disable", "", -1, null);
        EntFire("game_forcerespawn", "ForceRespawn", "", 0.3, null);
    }
}


class PerkGameStateFeedback extends PerkGameStateBase {
    function OnEnter() {
        EntFire("arena_spawnpoints", "Enable", "", -1, null);
        EntFire("vote_spawnpoints", "Disable", "", -1, null);
        EntFire("trap_spawnpoint", "Disable", "", -1, null);
        EntFire("game_timer", "Kill", "", 0, null);
        EntFire("game_forcerespawn", "ForceRespawn", "", 0, null);
    }

    function OnDeath(params) {
        local victim = GetPlayerFromUserID(params.userid);
        EntFire("game_forcerespawn", "ForceTeamRespawn", victim.GetTeam(), 0, null);
    }
}


// ---------------- //
// GAMEMODE CLASS   //
// ---------------- //
class PerkGamemode {
    PerkManagers = {}
    PlayerDestructionLogic = null
    
    GameStates = {
        vote = PerkGameStateVote()
        transition = PerkGameStateTransition()
        round = PerkGameStateRound()
        round_end = PerkGameStateRoundEnd()
        feedback = PerkGameStateFeedback()
    }
    CurrentState = ""
    
    constructor() {
        foreach (team in [Constants.ETFTeam.TF_TEAM_RED, Constants.ETFTeam.TF_TEAM_BLUE]) {
            PerkManagers[team] <- PerkManager(team);
        }
    }

    function GetActiveState() {
        if (CurrentState in GameStates) return GameStates[CurrentState];
        return null;
    }

    function ChangeState(state) {
        if (CurrentState == state) return;

        if (GetActiveState()) GetActiveState().OnExit();
        CurrentState = state;
        GetActiveState().OnEnter();
    }

    function OnSpawn(params) {
        local state = GetActiveState();
        if (state) state.OnSpawn(params);
    }

    function OnDeath(params) {
        // printl("CHECKIG FOR DEATH");
        local state = GetActiveState();
        if (state) state.OnDeath(params);
    }

    function OnLeave(params) {
        local state = GetActiveState();
        if (state) state.OnLeave(params);
    }

    function OnPointUnlocked() {
        local state = GetActiveState();
        if (state) state.OnPointUnlocked();
    }
}

::PerkGamemode <- PerkGamemode();