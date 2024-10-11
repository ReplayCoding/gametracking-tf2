local gamerules = Entities.FindByClassname(null, "tf_gamerules");
local game_timer = Entities.FindByClassname(null, "team_round_timer");
local pd_logic = Entities.FindByClassname(null, "tf_logic_player_destruction"); 

Convars.SetValue("tf_weapon_criticals", 0);

const string_become_ghost = "#arena_lumberyard_event_heal"
const string_last_player_standing = "\x07FBECCB is the \x07E7B53BLAST PLAYER STANDING!"
const string_spell_spawned = "#arena_lumberyard_event_spell"
//crumpkin_index = PrecacheModel("models/props_halloween/pumpkin_loot.mdl")

EntFireByHandle(gamerules, "SetRedTeamRespawnWaveTime", "0", -1, null, null);
EntFireByHandle(gamerules, "SetBlueTeamRespawnWaveTime", "0", -1, null, null);
EntFireByHandle(pd_logic, "SetPointsOnPlayerDeath", "0", -1, null, null);
EntFireByHandle(pd_logic, "EnableMaxScoreUpdating", "0", -1, null, null);
EntFireByHandle(pd_logic, "DisableMaxScoreUpdating", "0", 1, null, null);

NetProps.SetPropInt(pd_logic, "m_nRedTargetPoints", 999)
NetProps.SetPropInt(pd_logic, "m_nBlueTargetPoints", 999)

PrecacheScriptSound("Halloween.GhostMoan");
PrecacheScriptSound("Halloween.GhostBoo");
PrecacheScriptSound("Graveyard.YouDied");
PrecacheScriptSound("Graveyard.LastManAlly");
PrecacheScriptSound("Graveyard.LastManEnemy");

local ghost_model_blue = "models/props_graveyard/ghost_healing.mdl"
local ghost_model_red = "models/props_graveyard/ghost_healing_red.mdl"
local ghost_index_blue = PrecacheModel(ghost_model_blue)
local ghost_index_red = PrecacheModel(ghost_model_red)
local red_lockout = 0
local blue_lockout = 0
local invalid_entity = { IsValid = @() false }
local setup_finished = false

const TF_TEAM_RED = 2
const TF_TEAM_BLUE = 3

::CTFPlayer.RemovePlayerWearables <- function()
{
    local wearable = null;
    while ( wearable = Entities.FindByClassname( wearable, "tf_wearable*" ) )
    {
        if (  wearable != null && wearable.GetOwner() == this )
        {
            wearable.Destroy();
        };
    };

    return;
};

::CTFBot.RemovePlayerWearables <- function()
{
    local wearable = null;
    while ( wearable = Entities.FindByClassname( wearable, "tf_wearable*" ) )
    {
        if (  wearable != null && wearable.GetOwner() == this )
        {
            wearable.Destroy();
        };
    };

    return;
};


// "No Crumpkins" written by Lizard of Oz

::no_crumpkins <- {
    CRUMPKIN_INDEX = PrecacheModel("models/props_halloween/pumpkin_loot.mdl"),
    OnGameEvent_player_death = function(params)
    {
        local crumpkins = [];
        for (local tf_ammo_pack = null; tf_ammo_pack = Entities.FindByClassname(tf_ammo_pack, "tf_ammo_pack");)
        {
            NetProps.SetPropBool(tf_ammo_pack, "m_bForcePurgeFixedupStrings", true);
            if (NetProps.GetPropInt(tf_ammo_pack, "m_nModelIndex") == CRUMPKIN_INDEX)
                crumpkins.push(tf_ammo_pack);
        }
        foreach(crumpkin in crumpkins)
		{
            crumpkin.Kill();
			ClientPrint(null, 3, "killed crumpkin!")
		}
    }
};


function becomeGhost(player)
{
	//print("success")
	local team = player.GetTeam()
	
	//Give condition
	player.AddCond(77)
	player.AddCond(114)
	player.RemovePlayerWearables();
	
	//Change the player's model
	if (team == TF_TEAM_BLUE)
	{
		player.SetCustomModel(ghost_model_blue)
		for (local i = 0; i < 4; i++)
		{
			NetProps.SetPropIntArray(player, "m_nModelIndexOverrides", ghost_index_blue, i)
		}
	}
	else if(team == TF_TEAM_RED)
	{
		player.SetCustomModel(ghost_model_red)
		for (local i = 0; i < 4; i++)
		{
			NetProps.SetPropIntArray(player, "m_nModelIndexOverrides", ghost_index_red, i)
		}
	}
	
	player.SetModelScale(0.3, 0)									//Set model scale
	player.SetScriptOverlayMaterial("effects/ghost_overlay.vmt")	//Set screen overlay
	
	//Create dispenser trigger volume and parent it to the player	
	local dispenser_range = SpawnEntityFromTable("dispenser_touch_trigger", {
		origin = player.GetOrigin(), 
		spawnflags = 1,
	})
	dispenser_range.SetSize(Vector(-128, -128, -128), Vector(128, 128, 128))
	dispenser_range.SetSolid(2)
	dispenser_range.KeyValueFromString("targetname", "ghost_heal_trigger")
	
	player.GetScriptScope().dispenser_range <- dispenser_range
	
	//Create the dispenser entity and give it the aforementioned volume
	local dispenser = SpawnEntityFromTable("pd_dispenser", {
		origin = player.GetOrigin() + Vector(0, 0, 24), 
		spawnflags = 4,
		teamnum = team,
		touch_trigger = "ghost_heal_trigger"
	})
	dispenser_range.KeyValueFromString("targetname", "")
	dispenser.AcceptInput("SetParent", "!activator", player, player)
	dispenser_range.AcceptInput("SetParent", "!activator", player, player)
	player.GetScriptScope().dispenser <- dispenser
	ClientPrint(player, 3, string_become_ghost)
}

function unBecomeGhost(player)
{
	player.RemoveCond(77)
	player.RemoveCond(114)
	player.SetCustomModel("")
	for (local i = 0; i < 4; i++)
	{			
		NetProps.SetPropIntArray(player, "m_nModelIndexOverrides", 0, i)
	}
	player.SetModelScale(1, 0)
	player.SetScriptOverlayMaterial("")
	if(player.GetScriptScope().dispenser_range.IsValid())
	{
		player.GetScriptScope().dispenser_range.Kill()
		player.GetScriptScope().dispenser.Kill()
	}
}

function GetPlayers(team)
{
    local allPlayers = [];
    for (local i = 1; i <= MaxClients().tointeger(); i++)
    {
        local player = PlayerInstanceFromIndex(i);
		
		if (player == null)
			continue
		if (team != null && player.GetTeam() != team)
			continue
		if (!player.IsAlive())
			continue
		if (player.InCond(77))
			continue
		allPlayers.push(player);
    }
    return allPlayers;
}

function CheckWinState()		//checks win state and also for last men standing
{
	updatePlayerCounter()
	if(setup_finished == false)
		return
	local red_players = GetPlayers(TF_TEAM_RED)
	local blue_players = GetPlayers(TF_TEAM_BLUE)
	
	if(red_players.len() == 1 && red_lockout == 0)			//red has a last man standing
	{
		red_players[0].AddCond(19)			//award mini crits
		//red_players[0].RollRareSpell()		//award a rare 
		ClientPrint(null, 3, "\x07FF3F3F" + NetProps.GetPropString(red_players[0], "m_szNetname") + string_last_player_standing)
		gamerules.AcceptInput("PlayVOBlue", "Graveyard.LastManEnemy", null, null)
		gamerules.AcceptInput("PlayVORed", "Graveyard.LastManAlly", null, null)
		red_lockout = 1
	}
	if(blue_players.len() == 1 && blue_lockout == 0)			//blue has a last man standing
	{
		blue_players[0].AddCond(19)			//award mini crits
		//blue_players[0].RollRareSpell()		//award a rare spell
		ClientPrint(null, 3, "\x0799CCFF" + NetProps.GetPropString(blue_players[0], "m_szNetname") + string_last_player_standing)
		gamerules.AcceptInput("PlayVOBlue", "Graveyard.LastManAlly", null, null)
		gamerules.AcceptInput("PlayVORed", "Graveyard.LastManEnemy", null, null)
		blue_lockout = 1
	}
	if (red_players.len() == 0 && blue_players.len() == 0)		//both teams are dead at the same time 
	{
		local winner = SpawnEntityFromTable("game_round_win", {
		force_map_reset = 1,
		switch_team = 0,
		TeamNum = 1
		})
		winner.AcceptInput("RoundWin", "", null, null)
	}
	else if(red_players.len() == 0)								//red team has died
	{
		local winner = SpawnEntityFromTable("game_round_win", {
		force_map_reset = 1,
		switch_team = 0,
		TeamNum = 3
		})
		winner.AcceptInput("RoundWin", "", null, null)
	}
	else if(blue_players.len() == 0)							//blue team has died
	{
		local winner = SpawnEntityFromTable("game_round_win", {
		force_map_reset = 1,
		switch_team = 0,
		TeamNum = 2
		})
		winner.AcceptInput("RoundWin", "", null, null)
	}
}

function updatePlayerCounter()
{
	NetProps.SetPropInt(pd_logic, "m_nRedScore", GetPlayers(TF_TEAM_RED).len())
	//print("red playercount: " + NetProps.GetPropInt(pd_logic, "m_nRedScore"))
	NetProps.SetPropInt(pd_logic, "m_nBlueScore", GetPlayers(TF_TEAM_BLUE).len())
	//print(" blu playercount: " + NetProps.GetPropInt(pd_logic, "m_nBlueScore"))
}

function printSpellMessage()
{
	ClientPrint(null, 3, string_spell_spawned)
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///main game loop
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Every time a player dies, turn them into a ghost and destroy their crumpkin.
function OnGameEvent_player_death(params)
{
	if(setup_finished == false) //return if dead during setup
		return
	if(params.death_flags & 32)		//return if death is dead ringer
		return
	local player = GetPlayerFromUserID(params.userid)	
	becomeGhost(player)								//turn the dead guy into a ghost
	EmitSoundOnClient("Graveyard.YouDied", player)		//do the merasmus taunt voice
	CheckWinState()	
}


//If a player disconnects from the match, update the winstate to see if that would decide a victory.
function OnGameEvent_player_disconnect(params)
{
	if(setup_finished == false)
		return
	EntFireByHandle(self,"runscriptcode","CheckWinState()",0.1,null,null)	//delay the check for winstate
}

//A player joins a team. Detach any existing traits they may have. 
function OnGameEvent_player_spawn(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if(params.team == 0)
	{
		player.ValidateScriptScope()
		player.GetScriptScope().dispenser_range <- invalid_entity		//turn the dispensers invalid if the player is joining spectator
		player.GetScriptScope().dispenser <- invalid_entity
		updatePlayerCounter()
		return
	}
	unBecomeGhost(player)
	if(setup_finished == false)
	{
		updatePlayerCounter()
		return
	}
	if(params.team > 1)
	{
		becomeGhost(player)		//Joining after setup will turn you into a ghost
		updatePlayerCounter()	//Update the player counter AFTER the ghost has been made
	}
}

//Once setup has ended, give every player the condition that turns them into a ghost when they die.
function OnGameEvent_teamplay_setup_finished(params)
{
	local all_players = GetPlayers(null)
	setup_finished = true
	foreach(player in all_players)
	{
		player.AddCond(76)
	}
	CheckWinState()
}

ClearGameEventCallbacks()
__CollectGameEventCallbacks(this)