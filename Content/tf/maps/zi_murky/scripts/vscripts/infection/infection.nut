// --------------------------------------------------------------------------------------- //
// Zombie Infection                                                                        //
// --------------------------------------------------------------------------------------- //
// All Code By: netmuck (https://steamcommunity.com/profiles/76561198025795825)            //
// Assets/Game Design by: Diva Dan (https://steamcommunity.com/profiles/76561198072146551) //
// --------------------------------------------------------------------------------------- //
// infection mode main script                                                              //
// --------------------------------------------------------------------------------------- //
zi <- this;
function Main()
{
    if ( !( "InfectionLoaded" in getroottable() ) )
    {
        ::root <- getroottable();

        // from valve developer wiki - bring all constants in to global scope
        foreach (a,b in Constants)
        foreach (k,v in b)
        if (v == null)
        root[k] <- 0;
        else
        root[k] <- v;

        IncludeScript ( "infection/const.nut", root);
        IncludeScript ( "infection/strings.nut", root);
        IncludeScript ( "infection/functions.nut", root);
        IncludeScript ( "infection/think.nut", root);
        IncludeScript ( "infection/ability.nut", root);
        IncludeScript ( "infection/_init.nut", root);


    };

    return true;
};

// changes ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// 11/08/2026 - v4 BETA 2 ---------------------------------------------------------------------------------------------- //
// -- Fixed a bug where dying during setup did not instantly respawn players
// -- Fixed a bug where players would sometimes respawn with 0 ammo
// -- Fixed a bug where Zombies could get stuck inside of each other when spawning in the same position
// -- Fixed a bug where Zombies were not correctly given Mini-Crits when shorthanded
// -- Removed green footsteps from Zombies
// -- Fixed a bug where Zombies could nudge/push each other while picking spawns
// -- Fixed a bug where unspawned Zombies could be targeted by Sentry Guns
// -- Cycling spawn points now allows bonus time before auto respawn
// -- Fixed a bug where elements of the spawn picker UI were not displayed correctly
// -- Spies disguised as Zombie Heavy now emit loud footsteps
// -- Spies disguised as a Zombie now show the Mini-Crit buff effect while Zombies are shorthanded
// -- The spawn picker now starts on a random spawn point, Beacons still take priority
// -- Zombie Heavy
// -- -- Throw cooldown reduced to 10 seconds (from 30 seconds)
// -- -- Throw is now available immediately after respawn (from 30 seconds)
// -- -- Throw deals slightly more damage to Survivors
// -- -- Throw now deals heavy damage to buildings, and briefly disables them like the EMP Grenade
// -- -- Fixed a bug where dying while casting Zombie Heavy's Throw would permanently prevent jumping, ducking and attacking
// -- Zombie Pyro
// -- -- Spew Blob now fires 4 blobs rapidly
// -- -- Blobs leave a much smaller spew puddle on the ground
// -- -- Spew puddle now hinders movement of players who walk through it, but does not deal damage to them
// -- -- Spew reduces the speed of charging Demoman by 40%
// -- -- Spew now deals its first damage tick the moment a blob lands
// -- -- Spew now uses the correct particle effects
// -- Zombie Spy
// -- -- EMP Grenade now detonates in half the time
// -- -- EMP Grenade no longer plays a Zombie Engineer voice line when thrown
// -- Zombie Engineer
// -- -- Beacon is now BLU instead of RED
//
// 08/08/2026 - v4 BETA ------------------------------------------------------------------------------------------------ //
// -- General
// -- -- The B.A.S.E Jumper can now be deployed at any point in the round
// -- -- Players can no longer be selected as a starting Zombie two rounds in a row
// -- -- Players who are dead when the round begins now count as already infected
// -- -- Dying during setup now respawns you instantly
// -- -- New Feature: Zombie Spawn Picker
// -- -- -- Zombies can now select their spawn point
// -- -- -- On respawn, Zombies will be shown available spawn points and can select one to respawn at
// -- -- -- Zombies are no longer Ubered when respawning
// -- -- -- Zombies can change class while picking a spawn point
// -- -- Zombie Changes
// -- -- -- Zombies now drop a small health kit and a small ammo pack on death
// -- -- -- Zombies now recieve Mini-Crits when there are not enough Zombies
// -- -- -- Removed first person view punch on Zombie melee attacks
// -- -- -- Zombie Engineer
// -- -- -- -- Zombie Engineer has a new ability - "Beacon"
// -- -- -- -- -- Placing a beacon creates a spawn point for Zombies to respawn at
// -- -- -- -- -- Beacons can be destroyed by Survivors
// -- -- -- -- -- Each Zombie Engineer can only have one beacon active at a time
// -- -- -- Zombie Spy
// -- -- -- -- Zombie Spy has a new ability - "EMP Grenade"
// -- -- -- -- -- Functions the same as the Engineer's previous ability "EMP Grenade"
// -- -- -- -- -- Additionally, the EMP Grenade blast now reveals Survivors and buildings
// -- -- -- -- Max Health lowered to 125
// -- -- -- Zombie Pyro
// -- -- -- -- Zombie Pyro has a new ability - "Spew Blob"
// -- -- -- -- -- Coats Survivors in spew causing them to be slowed and unable to perform movement abilities
// -- -- -- -- No longer drops a medium health kit on death
// -- -- -- Zombie Heavy
// -- -- -- -- Zombie Heavy has a new ability - "Throw"
// -- -- -- -- -- Throws a chunk of concrete
// -- -- -- -- -- Survivors in the radius of the concrete get knocked back and take damage
// -- -- -- -- -- Survivors directly hit by the concrete get stunned and takes additional damage
// -- -- -- -- Zombie Heavy now has loud footsteps
// -- -- -- -- No longer drops a medium health kit on death
// -- -- -- Zombie Sniper
// -- -- -- -- Re-worked Zombie Sniper's Spit ability
// -- -- -- -- -- Spit can now settle on slopes, staircases and rooftops
// -- -- Bug Fixes
// -- -- -- Fixed a bug where Zombie Sniper's Spit would not create a puddle on impact with a building
// -- -- -- Fixed Zombie Heavy's knockback applying through Bonk! Atomic Punch and ÜberCharge
// -- -- -- Fixed Zombie Medic leaving dispensers behind when changing class, spectating or disconnecting
// -- -- -- Fixed "game_text" entities leaking when a player disconnects or changes class mid-respawn
// -- -- -- Fixed the starting Zombie draw being able to select a spectator or a dead player
// 24/10/2024 - v3.0.4 ------------------------------------------------------------------------------------------------- //
// -- General
// -- -- Re-encoded all Zombie Infection sound effects as .WAV
// -- -- -- This fixes issues with sound effects not playing correctly and spewing errors in the console
// -- Bug fixes
// -- -- Fixed a bug that caused Sniper's Spit Pool to deal much more damage than intended
// -- -- Fixed a bug that caused team names to not display correctly when playing on mp_tournament mode
// -- -- Fixed a bug where Engineer would sometimes scream like a charging Demoman while throwing an EMP Grenade
// -- Zombie Changes
// -- -- Sniper's Spit Pool damage vs Survivors no longer stacks when standing in multiple zones
// -- -- Zombie Heavy is no longer immune to Critical Hits
// -- -- Zombie Heavy's max health raised to 525 (from 450)
// -- -- Zombie Pyro's max health raised to 250 (from 175)
// -- -- Zombie Pyro now drops a medium health kit on death
// -- Survivor Changes
// -- -- Crossbow weapons no longer have a flat damage multiplier against Zombies
// -- -- The B.A.S.E Jumper can no longer be deployed if you are one of the last three survivors
// -- -- Jumper Weapons can no longer store reserve ammunition
// 14/10/2024 - v3.0.3 ------------------------------------------------------------------------------------------------- //
// -- Reduced Zombie Engineer's EMP Grenade Cooldown from 10 seconds to 9 seconds                                        //
// -- Adjusted Zombie Pyro's death explosion to briefly ignite players hit by the blast                                  //
// -- Fixed a bug that allowed Zombie Medic to spawn infinite dispenser entities (Thanks Psychicpie!)                    //
// -- Fixed Zombie Heavy's ability appearing as an active instead of a passive on the HUD (Thanks NeoDement!)            //
// -- Fixed a bug that caused Zombie Heavy's knockback to trigger on afterburn when quickly swapping from Pyro to Heavy  //
// 11/10/2024 - v3.0.2 ------------------------------------------------------------------------------------------------- //
// -- Fixed missing overlay material for Sniper's Spit ability                                                           //
// -- Fixed missing particle effects for Pyro's Dragon's Breath ability                                                  //
// -- Fixed a bug that would cause players to get stuck in spectate mode when attempting to join a game in progress      //
// 22/09/2024 - v3.0.1 ------------------------------------------------------------------------------------------------- //
// -- Added unique kill icons for Zombie arms and Zombie abilities                                                       //
// -- Updated localization strings for Zombie abilities                                                                  //
// 19/09/2024 - v3.0.0 BETA -------------------------------------------------------------------------------------------- //
// -- General Changes                                                                                                    //
// -- -- Removed "mp_respawnwavetime" from Infection convars, respawn wave time will now depend on map configuration     //
// -- -- Changed team names to "Survivors" and "Zombies" (Instead of "RED" and "BLU")                                    //
// -- -- -- Note: this change is only visible in casual mode or servers with mp_tournament set to 1                      //
// -- -- Survivor Spies can now disguise as Zombie players                                                               //
// -- -- Human Spy can now disguise as a Zombie and will be seen as a Zombie by the enemy team                           //
// -- -- The Pomson 6000 now puts Zombie abilities on cooldown on hit                                                    //
// -- -- Human Pyro can now destroy Zombie Engineer's EMP Grenade by hitting it with the Homewrecker                     //
// -- -- Walking in to Sniper's Spit now consumes the Spycicle and prevents initial damage                               //
// -- -- Standing in Sniper's Spit now emits additional sound effects on the players for better feedback                 //
// -- Zombie Changes                                                                                                     //
// -- -- Removed Out of combat speed buff from all Zombies                                                               //
// -- -- Zombie Pyro                                                                                                     //
// -- -- -- Zombie Pyro has a new ability - "Dragon's Breath"                                                            //
// -- -- -- -- Fires a fireball in a line that explodes on impact                                                        //
// -- -- -- -- The initial cast of the fireball can reflect projectiles and airblast enemies                             //
// -- -- -- Zombie Pyro now deals mini-crits to burning players on melee hit                                             //
// -- -- -- Zombie Pyro now creates a small explosion on death, knocking back enemies in a 125 hu radius                 //
// -- -- Zombie Demoman                                                                                                  //
// -- -- -- Added new sound effects to Zombie Demoman's Blast Charge ability                                             //
// -- -- Zombie Heavy                                                                                                    //
// -- -- -- Zombie Heavy's health reduced to 450 (from 600)                                                              //
// -- -- -- Zombie Heavy now drops a Medium Health Kit on death                                                          //
// -- -- Zombie Sniper                                                                                                   //
// -- -- -- Zombie Sniper's Spit damage vs buildables is now reduced by half                                             //
// -- -- -- Zombie Sniper's Spit now applies a screen overlay to players standing in the pool                            //
// -- -- Zombie Medic                                                                                                    //
// -- -- -- Zombie Medic now emits health like a dispenser to nearby Zombies                                             //
// -- -- -- Zombie Medic can no longer attack while using Heal                                                           //
// -- -- -- Added a new sound effect for Zombie Medic's Heal ability                                                     //
// -- -- Zombie Spy                                                                                                      //
// -- -- -- Zombie Spy no longer emits particle effects while cloaked                                                    //
// -- Bug Fixes                                                                                                          //
// -- -- Fixed a bug that allowed Zombie Demoman to survive his own Blast Charge (Thanks gasous nebule!)                 //
// -- -- Fixed a bug that caused Zombie Demoman to not receive kill credit when killing players with Blast Charge        //
// -- -- Fixed a bug that caused Zombies to not gib correctly                                                            //
// -- -- Fixed a bug that caused Zombie cosmetics to persist on RED players after the round restarts                     //
// -- -- Fixed a bug that caused Zombie Sniper's Spit Pool to nudge players slightly in certain circumstances            //
// -- -- Fixed a bug that caused players to have the incorrect player skin when respawning at round start                //
// -- -- Fixed a bug that would cause players to get stuck in spectate mode when attempting to join a game in progress   //
// -- -- Fixed an issue with "game_text" entities not being correctly cleared after round reset                          //
// -- -- -- Note: this was originally an issue on MacOS, which is no longer supported by Team Fortress 2                 //
// -- -- Fixed various other bugs with performance, entity management, stability, visuals and sound.                     //
// 22/06/2024 - v2.2.2 ------------------------------------------------------------------------------------------------- //
// -- Added experimental Payload logic to Infection mode                                                                 //
// -- -- Payload logic is automatically enabled when the PL hud is detected                                              //
// -- -- Zombie spawns are enabled/disabled by proximity to the payload cart                                             //
// -- -- Humans dying no longer adds time to the clock in payload mode                                                   //
//                                                                                                                       //
// 14/10/2023 - v2.2.1 ------------------------------------------------------------------------------------------------- //
// -- If a game is in progress and there are no players on BLU team or RED team the game will now end.                   //
// -- Fixed a bug that allowed Dead Ringer spies to die without triggering a round loss                                  //
// -- Fixed a bug that caused Zombies to not see combat text correctly                                                   //
// -- Fixed a bug that caused Rocket Launchers and Sticky Bomb Launchers to start with a low ammo                        //
// -- Fixed a bug that caused changing player loadout to kill human players (particularly on Murky)                      //
// -- Fixed an issue with missing particle effects for Medic's Heal ability                                              //
// -- Adjusted the number of Zombies selected at round start for low player counts                                       //
//                                                                                                                       //
// -- Corrected unintended changes in the last update:                                                                   //
// -- -- Changed the damage dealt by Zombie Soldier's Stomp                                                              //
// -- -- -- In the previous update, Soldier would instantly kill his stomp target. This was not intended                 //
// -- -- -- The new damage calculation is (10 + fall damage x 3). This is the same as the Mantreads                      //
// -- -- Changed the Sentry Gun to deal 40% damage to Zombies                                                            //
// -- -- -- In the previous update, this was 35%. This was not intended                                                  //
// -- -- Added a sound effect to Pyro's explosion of flames on death                                                     //
// -- -- Removed some debug print statements                                                                             //
//                                                                                                                       //
// -- Reworked Demoman's Blast Charge to fix several exploits and bugs                                                   //
// -- These changes should also make Blast Charge more reliable and less frustrating to use                              //
// -- -- Blast Charge is now triggered based on the player's velocity                                                    //
// -- -- When player's speed drops below a threshold while charging, they explode                                        //
// -- -- Additionally, anything that would usually interrupt a shield charge will now trigger the explosion              //
// -- -- Fixed a bug that caused ÜberCharge applied by Blast Charge to persist longer than intended                      //
// -- -- Fixed a bug that caused Blast Charge to fail to kill the player in situations where the player should be killed //
// -- -- Fixed a bug that caused Blast Charge to briefly display the player's first person view before detonation        //
// -- -- Fixed a bug that caused the player to be unable to attack, jump or duck after surviving Blast Charge            //
// -- -- Fixed many bugs that caused Blast Charge to fail to detonate                                                    //
// -- -- Fixed many bugs related to Blast Charge being cast at the same time as being converted to Zombie                //
//                                                                                                                       //
// 12/10/2023 - v2.2 --------------------------------------------------------------------------------------------------- //
// -- All Zombies (except for Scout, Heavy and Spy) have 25 bonus HP (up from 10)                                        //
// -- Starting Zombie Factor is now 1/5 of all players (previous 1/6)                                                    //
// -- -- The game will also now always round up the number of starting zombies                                           //
// -- Added additional HIDEHUD bits to remove irrelevant HUD elements when playing Zombie                                //
// -- Reduce damage dealt to Zombies by sentry guns by 60% (previously 40%)                                              //
// -- Removed damage reduction for Human Demoman wearing a shield                                                        //
// -- Zombie Scout now has an additional 25% jump height                                                                 //
// -- Zombie Heavy now has Battalion's Backup effect                                                                     //
// -- Zombie Heavy has an additional 20% melee damage                                                                    //
// -- Zombie Medic Heal cooldown reduced to 7 seconds (previously 11)                                                    //
// -- Zombie Spy is now cloaked on spawn                                                                                 //
// -- -- Attacking or using an ability will remove the cloak                                                             //
// -- -- Cloak will be restored after 3 seconds of not attacking or using an ability                                     //
// -- Zombie Pyro no longer drops a small health pack on death                                                           //
// -- Zombie Pyro now bursts in to a firey explosion on death                                                            //
// -- -- All enemies within 256 hu of a dying Zombie Pyro are set on fire                                                //
// -- Zombie Engineer's EMP Grenade no longer slides on sloped surfaces                                                  //
// -- Zombie Engineer's EMP Grenade now deals 110 damage to all buildings hit                                            //
// -- Zombie Engineer's EMP Grenade can now kill buildings                                                               //
// -- Zombie Sniper's Spit now deals damage to sentry guns, teleporters and dispensers                                   //
// -- Zombie Sniper now drops a spit pool on death                                                                       //
// -- Zombie Soldier's Pounce has been adjusted to feel more like a blast jump                                           //
// -- Zombie Soldier's Pounce cooldown reduced to 5 seconds (previously 10)                                              //
// -- Fixed a bug where Zombie Demo could detonate himself before the charge had started                                 //
// -- Fixed a bug where Bonk! Atomic Punch could persist through Zombie conversion                                       //
// -- Fixed a bug where Crit-a-Cola could persist through Zombie conversion                                              //
// -- Fixed various issues caused by Zombie Demo surviving his own charge                                                //
// -- Fixed issues with the Zombie HUD not correctly displaying certain strings                                          //
// -- Fixed autoteam exploit                                                                                             //
// --------------------------------------------------------------------------------------------------------------------- //

if ( Main() )
{
    ::bGameStarted       <- false;
    ::bZombieQuotaBuffOn <- false;
};

try {
    _CONST;
} catch(e) {
    return;
};

ClearGameEventCallbacks();

function OnPostSpawn()
{
    AddThinkToEnt( self, "GameStateThink" );
}

function OnGameEvent_teamplay_round_win( params )
{
    return;
};

function OnGameEvent_player_spawn( params )
{
    local _hPlayer     = GetPlayerFromUserID( params.userid );
    local _iRoundState = GetPropInt( GameRules, "m_iRoundState" );

    if ( _hPlayer == null )
        return;

    _hPlayer.ValidateScriptScope(); // only do this once, for ficool's sake

    local _sc = _hPlayer.GetScriptScope();

    local _bWasPicking      = ( ( "m_iFlags" in _sc ) && ( ( _sc.m_iFlags & ZBIT_IN_SPAWN_PICKER ) != 0 ) );
    local _iKeptSpawnIndex  = ( _bWasPicking ? _sc.m_iSpawnIndex : 0 );
    local _fKeptConfirmTime = ( _bWasPicking ? _hPlayer.HowLongUntilAct( ZOMBIE_AUTO_CONFIRM_SPAWN ) : 0.0 );

    if ( _bWasPicking )
        _hPlayer.DestroySpawnPickerHUD();

    local _bWasEmerging = ( ( "m_iFlags" in _sc ) && ( ( _sc.m_iFlags & ZBIT_EMERGING_FROM_GROUND ) != 0 ) );

    if ( _bWasEmerging )
        _hPlayer.SetMoveType( MOVETYPE_WALK, 0 );

    // stand-in and its hide go before ResetInfectionVars nulls the handle
    _hPlayer.DestroySpawnBody   ();
    _hPlayer.SetSpawnBodyHidden ( false );

    // we use the script overlay material for zombie ability hud
    // so let's make sure it's cleared whenever a player has respawned
    _hPlayer.SetScriptOverlayMaterial( "" );

    if ( ( "m_iFlags" in _sc ) && ( _sc.m_iFlags & ZBIT_SPEWED ) )
        _hPlayer.RemoveSpewDebuff();

    // also set their playermodel back to normal
    _hPlayer.SetCustomModelWithClassAnimations( arrTFClassPlayerModels[ _hPlayer.GetPlayerClass() ] );

    // and reset infection specific vars
    _hPlayer.ResetInfectionVars();

    if ( (_hPlayer.GetPlayerClass() ==  TF_CLASS_DEMOMAN || _hPlayer.GetPlayerClass() == TF_CLASS_SOLDIER) && _hPlayer.GetTeam() == TF_TEAM_RED )
    {
        _hPlayer.ModifyJumperWeapons();
    }

    // the engine places players exactly on the spawn point - drop floaters to
    // the floor (the spawn point entity itself is never moved)
    _hPlayer.SetAbsOrigin( _hPlayer.GetGroundSnapPos( _hPlayer.GetOrigin() ) );

    // game hasn't started, player should be a survivor
    if ( !::bGameStarted )
    {
        // force the player to red team and then respawn them
        if ( _hPlayer.GetTeam() == TF_TEAM_BLUE )
        {
            // remove all conditions/attribs that could linger from previous round
            _hPlayer.ClearZombieAttribs();

            // Clean up the player's stuff before respawn
            _hPlayer.RemovePlayerWearables();
            _hPlayer.ResetInfectionVars();
            _hPlayer.ClearZombieEntities();

            ChangeTeamSafe( _hPlayer, TF_TEAM_RED, false );
            _hPlayer.ForceRegenerateAndRespawn();
            return;
        };

        // reset all gamemode specific variables
        _hPlayer.ResetInfectionVars();

        // remove all zombie cosmetics/weapons
        _hPlayer.ClearZombieEntities();

        // replaces arm viewmodels and disables zombie skins
        _hPlayer.MakeHuman();

        // make sure the players have the correct amnt of health
        // since we modify all classes' health values when zombie
        _hPlayer.SetHealth( _hPlayer.GetMaxHealth() );

        // the strip lands after this event via the deferred inventory application
        EntFireByHandle( _hPlayer, "RunScriptCode",
                         "self.FixNullActiveWeapon()", 0.2, null, null );
        return;
    }
    else // game has started, player should be a zombie
    {
        if ( _hPlayer.GetTeam() == TF_TEAM_RED )
        {
            ChangeTeamSafe( _hPlayer, TF_TEAM_BLUE, false );
            _hPlayer.ForceRegenerateAndRespawn();
            return;
        };

        // remove all of the player's existing items
        _hPlayer.RemovePlayerWearables();
        _hPlayer.GiveZombieCosmetics();
        _hPlayer.GiveZombieFXWearable();

        SendGlobalGameEvent( "post_inventory_application", { userid = GetPlayerUserID(_hPlayer) });

        _hPlayer.SetHealth ( _hPlayer.GetMaxHealth() );

        _sc.m_iFlags <- ( _sc.m_iFlags | ZBIT_PENDING_ZOMBIE );
        _hPlayer.SetNextActTime( ZOMBIE_BECOME_ZOMBIE, INSTANT );

        _hPlayer.EnterSpawnPicker();

        if ( _bWasPicking )
        {
            if ( _iKeptSpawnIndex >= BuildPickerSpawnList().len() )
                _iKeptSpawnIndex = 0;

            _sc.m_iSpawnIndex <- _iKeptSpawnIndex;
            _hPlayer.TeleportToSpawnIndex ( _iKeptSpawnIndex );
            _hPlayer.SetNextActTime       ( ZOMBIE_AUTO_CONFIRM_SPAWN, _fKeptConfirmTime );
        };

        return;
    };

    _hPlayer.ResetInfectionVars();
    return;
};

function OnGameEvent_teamplay_setup_finished( params )
{
    ::bGameStarted <- true;

    BuildZombieSpawnPointArray();

    local _iPlayerCountRed    = PlayerCount( TF_TEAM_RED );
    local _numStartingZombies = -1;

    // -------------------------------------------------- //
    // select players to become zombies                   //
    // -------------------------------------------------- //

    if ( !bNewFirstWaveBehaviour )
    {
        if ( ( _iPlayerCountRed <= 1 ) && ( DEBUG_MODE < 1 ) )
        {
            // not enough players, force game over
            local _hGameWin = SpawnEntityFromTable( "game_round_win",
            {
                win_reason      = "0",
                force_map_reset = "1",
                TeamNum         = "2", // TF_TEAM_RED
                switch_teams    = "0"
            });

            EntFireByHandle( _hGameWin, "RoundWin", "", 0, null, null );
            ::bGameStarted <- false;
            return;
        }
        else if ( _numStartingZombies == -1 )
        {
            _numStartingZombies = GetZombieQuota( _iPlayerCountRed );
        }

        local _szZombieNetNames  =  "";

        local _arrDeadSurvivors = [];

        foreach ( _hDeadSurvivor in GetAllPlayers() )
        {
            if ( _hDeadSurvivor != null &&
                 _hDeadSurvivor.GetTeam() == TF_TEAM_RED &&
                 GetPropInt( _hDeadSurvivor, "m_lifeState" ) != ALIVE )
            {
                _arrDeadSurvivors.append( _hDeadSurvivor );
            };
        };

        local _iLivePicks = ( _numStartingZombies - _arrDeadSurvivors.len() );

        if ( _iLivePicks < 0 )
            _iLivePicks = 0;

        local _zombieArr = _arrDeadSurvivors;

        _zombieArr.extend( GetRandomPlayers( _iLivePicks, ::tblLastRoundZombies ) );

        if ( _zombieArr.len() == 0 )
            return;

        ::tblLastRoundZombies <- {};

        foreach ( _hInfected in _zombieArr )
        {
            if ( _hInfected != null )
                ::tblLastRoundZombies[ GetPlayerUserID( _hInfected ) ] <- true;
        };

        // ------------------------------------------ //
        // convert the picked players to zombies      //
        // ------------------------------------------ //

        for ( local i = 0; i < _zombieArr.len(); i++ )
        {
            local _id          =  GetPlayerUserID     ( _zombieArr[ i ] );
            local _nextPlayer  =  GetPlayerFromUserID ( _id );

            if ( _nextPlayer == null )
                continue;

            local _sc = _nextPlayer.GetScriptScope();

            // a corpse only needs the team change - the respawn takes the normal
            // zombie route from OnGameEvent_player_spawn
            if ( GetPropInt( _nextPlayer, "m_lifeState" ) != ALIVE )
            {
                _nextPlayer.ResetInfectionVars();
                ChangeTeamSafe( _nextPlayer, TF_TEAM_BLUE, false );
            }
            else
            {
                // ------------------------------------------------------- //
                // make sure heavy/pyro don't get stuck in a t-pose/a-pose //
                // ------------------------------------------------------- //
                // the minigun and flamethrower carry a firing state that
                // survives the model swap and breaks the anim state

                local _hActiveWep = _nextPlayer.GetActiveWeapon();

                if ( _hActiveWep != null &&
                     ( _hActiveWep.GetClassname() == "tf_weapon_minigun" ||
                       _hActiveWep.GetClassname() == "tf_weapon_flamethrower" ) )
                {
                    SetPropInt( _hActiveWep, "m_iWeaponState", 0 );
                };

                // remove player conditions that will cause problems
                // when switching to zombie
                _nextPlayer.ClearProblematicConds();

                // reset all gamemode specific variables
                _nextPlayer.ResetInfectionVars();

                ChangeTeamSafe( _nextPlayer, TF_TEAM_BLUE, false );

                // remove all of the player's existing items
                _nextPlayer.RemovePlayerWearables();

                // add the zombie cosmetics/skin modifications
                _nextPlayer.GiveZombieCosmetics();
                _nextPlayer.GiveZombieFXWearable();

                SendGlobalGameEvent( "post_inventory_application", { userid = GetPlayerUserID(_nextPlayer) });

                // add the pending zombie flag
                // the actual zombie conversion is handled in the player's think script
                // the initial infection bit keeps the lightning fx for this wave only
                _sc.m_iFlags <- ( ( _sc.m_iFlags | ZBIT_PENDING_ZOMBIE | ZBIT_INITIAL_INFECTION ) );

                // don't delay zombie conversion when the player is alive.
                _nextPlayer.SetNextActTime ( ZOMBIE_BECOME_ZOMBIE, INSTANT );
                _nextPlayer.SetNextActTime ( ZOMBIE_ABILITY_CAST, 0.1 );
            };

            // ------------------------------------------- //
            // build string for chat notification          //
            // ------------------------------------------- //

            if ( i == 0 ) // first player in the message
            {
                _szZombieNetNames = "\x07FF3F3F" + NetName( _nextPlayer ) + "\x07FBECCB";
            }
            else if ( i ==  ( _zombieArr.len() - 1 ) ) // last player in the message
            {
                if ( _zombieArr.len() > 1 )
                {
                    _szZombieNetNames += ( "\x07FBECCB " + STRING_UI_AND + " \x07FF3F3F" );
                }
                else
                {
                    _szZombieNetNames += ( "\x07FBECCB, \x07FF3F3F" );
                };

                _szZombieNetNames += ( NetName( _nextPlayer ) + "\x07FBECCB" );
            }
            else // players in the middle get commas
            {
                _szZombieNetNames += ( "\x07FBECCB, \x07FF3F3F" + NetName( _nextPlayer ) + "\x07FBECCB" );
            };
        };

        local _szFirstInfectedAnnounceMSG = "";

        if ( _zombieArr.len() > 1 ) // set the first infected announce message
        {
            _szFirstInfectedAnnounceMSG = format( _szZombieNetNames +
                                                STRING_UI_CHAT_FIRST_WAVE_MSG_PLURAL );
        }
        else
        {
            _szFirstInfectedAnnounceMSG = format( _szZombieNetNames +
                                                STRING_UI_CHAT_FIRST_WAVE_MSG );
        };

        local _hNextRespawnRoom = null;
        while ( _hNextRespawnRoom = Entities.FindByClassname( _hNextRespawnRoom, "func_respawnroom" ) )
        {
            if ( _hNextRespawnRoom && _hNextRespawnRoom.GetTeam() == TF_TEAM_RED )
            {
                EntFireByHandle( _hNextRespawnRoom, "SetInactive", "", 0.0, null, null );
            };
        };

        PlayGlobalBell( false );

        // show the first infected announce message to all players
        PrintToChat( _szFirstInfectedAnnounceMSG );
    }
};

function OnGameEvent_teamplay_broadcast_audio( params )
{
    return;
};

function OnGameEvent_player_disconnect( params )
{
    // the player is still valid here - take their script entities with them
    local _hPlayer = GetPlayerFromUserID( params.userid );

    if ( _hPlayer == null )
        return;

    _hPlayer.DestroyMedicDispenser();

    // per-player game_text entities (ability HUD + spawn picker HUD)
    local _sc = _hPlayer.GetScriptScope();

    if ( _sc == null )
        return;

    foreach ( _szHandle in [ "m_hHUDText", "m_hHUDTextAbilityName",
                             "m_hSpawnPickerControlsText", "m_hSpawnPickerCountdownText" ] )
    {
        if ( ( _szHandle in _sc ) && _sc[ _szHandle ] != null && _sc[ _szHandle ].IsValid() )
            _sc[ _szHandle ].Destroy();
    };

    return;
};

function OnGameEvent_teamplay_restart_round( params )
{
    ::bGameStarted <- false;

    local _hNextPlayer = null;

    // --------------------------- //
    // set all players to survivor //
    // --------------------------- //

    foreach ( _hNextPlayer in GetAllPlayers() )
    {
        if ( _hNextPlayer == null )
            continue;

        local _id = GetPlayerUserID( _hNextPlayer );

        _hNextPlayer.ResetInfectionVars();
        _hNextPlayer.ClearZombieEntities();

        _hNextPlayer.MakeHuman();
        _hNextPlayer.SetHealth( _hNextPlayer.GetMaxHealth() );
    };

    local _hGameTextEntity = null;
    while ( _hGameTextEntity = Entities.FindByClassname( _hGameTextEntity, "game_text" ) )
    {
        _hGameTextEntity.Destroy();
    };

    local _hDispenserEntity = null;
    while ( _hDispenserEntity = Entities.FindByClassname( _hDispenserEntity, "pd_dispenser" ) )
    {
        _hDispenserEntity.Destroy();
    };

    local _hDispenserTrigger = null;
    while ( _hDispenserTrigger = Entities.FindByClassname( _hDispenserTrigger, "dispenser_touch_trigger" ) )
    {
        _hDispenserTrigger.Destroy();
    };

    local _hBeaconEntity = null;
    while ( _hBeaconEntity = Entities.FindByName( _hBeaconEntity, "engie_beacon_physprop" ) )
    {
        _hBeaconEntity.Destroy();
    };

    local _hBeaconFXEntity = null;
    while ( _hBeaconFXEntity = Entities.FindByName( _hBeaconFXEntity, "engie_beacon_fx" ) )
    {
        _hBeaconFXEntity.Destroy();
    };

    local _hBeaconRoomEntity = null;
    while ( _hBeaconRoomEntity = Entities.FindByName( _hBeaconRoomEntity, "engie_beacon_respawnroom" ) )
    {
        _hBeaconRoomEntity.Destroy();
    };

    local _hSplatFireEntity = null;
    while ( _hSplatFireEntity = Entities.FindByName( _hSplatFireEntity, ( SPLAT_FIRE_ENT_PREFIX + "*" ) ) )
    {
        _hSplatFireEntity.Destroy();
    };

    local _hNadeEntity = null;
    while ( _hNadeEntity = Entities.FindByName( _hNadeEntity, "engie_nade_physprop" ) )
    {
        _hNadeEntity.Destroy();
    };

    ::arrZombieBeacons.clear();
    ::arrZombieSpawnPoints.clear();

    return;
};

function OnGameEvent_player_death( params )
{
    local _hPlayer      =  GetPlayerFromUserID ( params.userid );
    local _hKiller      =  GetPlayerFromUserID ( params.attacker );
    local _iDamageType  =  params.damagebits;
    local _iWeaponIDX   =  params.weapon_def_index;

    if ( _hPlayer == null )
        return;

    local _sc                  =  _hPlayer.GetScriptScope();
    local _iClassNum           =  _hPlayer.GetPlayerClass();
    local _hPlayerTeam         =  _hPlayer.GetTeam();

    SetPropIntArray( _hPlayer, "m_nModelIndexOverrides", 0, 3 );

    if ( _sc != null && ( "m_iFlags" in _sc ) && ( _sc.m_iFlags & ZBIT_SPEWED ) )
        _hPlayer.RemoveSpewDebuff();

    if ( _sc != null )
        _hPlayer.SpoofZombieBuffFX( false );

    if ( _sc != null && ( "m_iFlags" in _sc ) && ( _sc.m_iFlags & ZBIT_SOLDIER_IN_POUNCE ) )
    {
        _sc.m_iFlags <- ( _sc.m_iFlags & ~ZBIT_SOLDIER_IN_POUNCE );
        _hPlayer.EndSoldierFall();
    };

    // a death mid-picker/emerge leaks locked state - the exit path is otherwise
    // only reachable from FinishSpawnEmerge, which a corpse never gets to
    if ( _sc != null && ( "m_iFlags" in _sc ) )
    {
        if ( _sc.m_iFlags & ( ZBIT_IN_SPAWN_PICKER | ZBIT_EMERGING_FROM_GROUND ) )
        {
            _sc.m_iFlags <- ( _sc.m_iFlags & ~ZBIT_EMERGING_FROM_GROUND );
            _hPlayer.SetNextActTime( ZOMBIE_FINISH_EMERGE, ACT_LOCKED );
            _hPlayer.ExitSpawnPicker();
        }
        else if ( _sc.m_iFlags & ZBIT_HEAVY_ROCK_WINDUP )
        {
            _sc.m_iFlags <- ( _sc.m_iFlags & ~ZBIT_HEAVY_ROCK_WINDUP );
            _hPlayer.DestroySpawnBody   ();
            _hPlayer.SetSpawnBodyHidden ( false );
            _hPlayer.SetForcedTauntCam  ( 0 );
            _hPlayer.LockInPlace        ( false );
        };
    };

    // crumpkin catch - on a halloween-flagged map the engine rolls 30% to turn the
    // death ammo pack into a crit pumpkin (tf_ammo_pack.cpp InitAmmoPack). its
    // AP_HALLOWEEN state isn't a netprop and can't be reverted, so swap the pack
    // for the medium ammo it was going to be. zombie packs are all culled below
    if ( !( ::bGameStarted && _hPlayerTeam == TF_TEAM_BLUE ) )
    {
        local _iPumpkinModel = GetModelIndex( "models/props_halloween/pumpkin_loot.mdl" );
        local _hDroppedAmmo  = null;

        while ( _hDroppedAmmo = Entities.FindByClassname( _hDroppedAmmo, "tf_ammo_pack" ) )
        {
            if ( _hDroppedAmmo.GetOwner() != _hPlayer ||
                 GetPropInt( _hDroppedAmmo, "m_nModelIndex" ) != _iPumpkinModel )
                continue;

            CreateMediumAmmoPack( _hDroppedAmmo.GetOrigin() );
            _hDroppedAmmo.Destroy();
        };
    };

    // deaths during setup don't cost you the round start. deferred a frame -
    // respawning inside the death event gets undone when the rest of the engine's
    // kill sequence runs on the freshly respawned player (it also ate their ammo)
    if ( !::bGameStarted &&
         GetPropInt( GameRules, "m_iRoundState" ) != GR_STATE_TEAM_WIN &&
         !( params.death_flags & TF_DEATH_FEIGN_DEATH ) )
        EntFireByHandle( _hPlayer, "RunScriptCode",
                         "self.ForceRegenerateAndRespawn()", 0.1, null, null );

    if ( ::bGameStarted && _hPlayerTeam == TF_TEAM_BLUE ) // zombie has died
    {

        // any class - the class may have changed since the dispenser was made
        _hPlayer.DestroyMedicDispenser();

        // valve's dropped-weapon pack is always culled - we drop our own below
        local _hDroppedAmmo = null;
        while ( _hDroppedAmmo = Entities.FindByClassname( _hDroppedAmmo, "tf_ammo_pack" ) )
        {
            if ( _hDroppedAmmo.GetOwner() == _hPlayer )
            {
                _hDroppedAmmo.Destroy();
            };
        };

        // every zombie leaves a small health pack and a small ammo pack
        CreateZombieDeathDrop( _hPlayer.GetOrigin() );

        // ability is null if death lands before conversion (e.g. a killbind in the picker)
        if ( _hPlayer.GetPlayerClass() == TF_CLASS_SNIPER && _sc.m_hZombieAbility != null )
        {
            _sc.m_hZombieAbility.CreateSpitball( true );
        };

        // the heavy is made of the same stuff he throws - burst him into rock gibs
        if ( _hPlayer.GetPlayerClass() == TF_CLASS_HEAVYWEAPONS )
        {
            SpawnHeavyRockGibs( ( _hPlayer.GetOrigin() + Vector( 0, 0, ZHEAVY_DEATH_GIB_Z_OFF ) ) );
        };

         if ( _hPlayer.GetPlayerClass() == TF_CLASS_PYRO )
         {
            local _hNextPlayer = null;
            local _hKillicon = KilliconInflictor( KILLICON_PYRO_BREATH );

            if ( !::bNoPyroExplosionMod )
            {
                while ( _hNextPlayer = Entities.FindByClassnameWithin( _hNextPlayer, "player", _hPlayer.GetOrigin(), 125 ) )
                {
                    if ( _hNextPlayer != null && _hNextPlayer.GetTeam() == TF_TEAM_RED && _hNextPlayer != _hPlayer )
                    {
                        KnockbackPlayer           ( _hPlayer, _hNextPlayer, 210, 0.85, true );
                        _hNextPlayer.TakeDamageEx ( _hKillicon, _hPlayer, _hPlayer.GetActiveWeapon(), Vector(0, 0, 0), _hPlayer.GetOrigin(), 10, ( DMG_CLUB | DMG_PREVENT_PHYSICS_FORCE ) );
                    };
                };

                _hKillicon.Destroy();

                EmitSoundOn            ( SFX_PYRO_FIREBOMB, _hPlayer );
                DispatchParticleEffect ( "fireSmokeExplosion_track", _hPlayer.GetLocalOrigin(), Vector( 0, 0, 0 ) );
            }

        };

        // ------------------------------------- //
        // remove zombie "vgui"                  //
        // ------------------------------------- //
        // we use the script overlay material for zombie ability hud
        // so let's make sure it's cleared whenever a player has respawned
        _hPlayer.SetScriptOverlayMaterial ( "" );

        // same thing for the HUD text channels. these are only created on the first think
        // tick after the emerge, so a death in the picker/emerge window finds them null
        if ( _sc.m_hHUDText != null && _sc.m_hHUDText.IsValid() )
        {
            _sc.m_hHUDText.KeyValueFromString ( "message", "" );
            EntFireByHandle( _sc.m_hHUDText,  "Display", "", 0.0, _hPlayer, _hPlayer );
        };

        if ( _sc.m_hHUDTextAbilityName != null && _sc.m_hHUDTextAbilityName.IsValid() )
        {
            _sc.m_hHUDTextAbilityName.KeyValueFromString ( "message", "" );
            EntFireByHandle( _sc.m_hHUDTextAbilityName,  "Display", "", 0.0, _hPlayer, _hPlayer );
        };

        // ------------------------------------- //
        // Zombie Gib Hack                       //
        // ------------------------------------- //
        // when a player has the zombie skin override, they are hard coded to never gib
        // if we remove this skin here it creates gibs for the player
        if ( ::bZombieGibsOn )
        {
            SetPropInt ( _hPlayer, "m_iPlayerSkinOverride", 0 );

            // we set custom model on the player afterwards because otherwise the gibs come out red
            _hPlayer.SetCustomModelWithClassAnimations( arrTFClassPlayerModels[ _iClassNum ] );
        };

        // ------------------------------------- //
        // Check if Need Demoman Explosion       //
        // ------------------------------------- //

        if ( ( _sc.m_iFlags & ZBIT_MUST_EXPLODE ) )
        {
            _sc.m_iFlags <- ( _sc.m_iFlags & ~ZBIT_MUST_EXPLODE );
            _sc.m_tblEventQueue <- { };

            // ---------------------------------------- //
            // check for buildings and find the nearest //
            // to become the explosion origin           //
            // ---------------------------------------- //

            DemomanExplosionPreCheck( _hPlayer.GetOrigin(),
                                      DEMOMAN_CHARGE_DAMAGE,
                                      DEMOMAN_CHARGE_RADIUS,
                                      _hPlayer );
        };

        // hide our fx wearable to stop the particles from generating. the handle is null
        // whenever GiveZombieFXWearable is stubbed out, so guard it
        if ( _sc.m_hZombieFXWearable != null && _sc.m_hZombieFXWearable.IsValid() )
        {
            SetPropInt( _sc.m_hZombieFXWearable, "m_nRenderMode", kRenderNone );

            _sc.m_hZombieFXWearable.Destroy();
        };

        // _sc.m_hZombieWearable.Kill();
        // SendGlobalGameEvent( "post_inventory_application", { userid = GetPlayerUserID(_hPlayer) });

        return; // zombie death event ends here
    }

    if ( ::bGameStarted ) // if the game is started, a dying survivor becomes a zombie
    {
        // player was survivor, killed by a zombie and wasn't suicide
        if ( _hKiller && _hKiller.GetClassname() == "player" && _hKiller.GetTeam() == TF_TEAM_BLUE && _hPlayerTeam == TF_TEAM_RED )
        {
            if ( _hKiller == null || _hPlayer == _hKiller )
                return;

            // show a notifcation to all players in chat.
            local _szDeathMsg = format( STRING_UI_CHAT_INFECT_MSG,
                                        NetName( _hPlayer ),
                                        NetName( _hKiller ) );

            ClientPrint( null, HUD_PRINTTALK, _szDeathMsg );
        }
        else // player died to enviro/other, announce they were infected with no killer name
        {
            local _szDeathMsg = format ( STRING_UI_CHAT_INFECT_SOLO_MSG,
                                         NetName( _hPlayer ) );

            ClientPrint( null, HUD_PRINTTALK, _szDeathMsg );
        };

        // dead ringer deaths exit here
        if ( ( params.death_flags & TF_DEATH_FEIGN_DEATH ) )
        {
            PlayGlobalBell( true );
            return;
        };

        // evaluate win condition when a player dies
        ShouldZombiesWin ( _hPlayer );

        // make sure players can only add time once per round
        if ( ( !_sc.m_bCanAddTime ) )
        {
            return;
        }
        else
        {
            _sc.m_bCanAddTime <- false;
        };

        PlayGlobalBell( false );

        local _hRoundTimer = Entities.FindByClassname( null, "team_round_timer" );

        // no round timer on the level, let's make one
        if ( _hRoundTimer == null )
        {
            // create an infection specific timer
            _hRoundTimer = SpawnEntityFromTable( "team_round_timer",
            {
                auto_countdown       = "0",
                max_length           = "360",
                reset_time           = "1",
                setup_length         = "30",
                show_in_hud          = "1",
                show_time_remaining  = "1",
                start_paused         = "0",
                timer_length         = "360",
                StartDisabled        = "0",
            } );
        }
        else
        {
            EntFireByHandle( _hRoundTimer, "auto_countdown", "0", 0, null, null );
        }

        EntFireByHandle( _hRoundTimer, "AddTime", ADDITIONAL_SEC_PER_PLAYER.tostring(), 0, null, null );
    };
};

function OnGameEvent_player_changeclass( params )
{
    local _hPlayer = GetPlayerFromUserID ( params.userid );
    if ( _hPlayer == null )
        return;

    local _sc = _hPlayer.GetScriptScope();
    if ( _sc == null )
        return;

    // a class change mid-pounce skips the landing, leaving the fall whistle looping
    if ( ( "m_iFlags" in _sc ) && ( _sc.m_iFlags & ZBIT_SOLDIER_IN_POUNCE ) )
    {
        _sc.m_iFlags <- ( _sc.m_iFlags & ~ZBIT_SOLDIER_IN_POUNCE );
        _hPlayer.EndSoldierFall();
    };

    if ( _hPlayer.GetTeam() != TF_TEAM_BLUE )
        return;

    if ( ( "m_hOwnedBeacon" in _sc ) && _sc.m_hOwnedBeacon != null &&
         _sc.m_hOwnedBeacon.IsValid() )
    {
        _sc.m_hOwnedBeacon.GetScriptScope().m_bMustDie <- true;
    };

    _sc.m_hOwnedBeacon <- null;
    return;
};

function OnScriptHook_OnTakeDamage( params )
{
    if ( params.const_entity == null || params.inflictor == null || params.attacker == null )
        return;

    local _hVictim        =   params.const_entity;
    local _hAttacker      =   params.attacker;
    local _hInflictor     =   params.inflictor;
    local _sc             =   _hVictim.GetScriptScope();
    local _iWeaponIDX     =   0;
    local _szWeaponName   =   "none";
    local _iForceGibDmg   =   ( _hVictim.GetMaxHealth() + 20 );
    local _szKillicon     =   "";

    if ( _hVictim.GetName() == "engie_nade_physprop" )
    {
        if ( _hAttacker.GetClassname() == "player" ) // must check before trying to access active weapon
        {
            if ( _hAttacker.GetPlayerClass() == TF_CLASS_PYRO && _hAttacker.GetActiveWeapon().GetPropInt( STRING_NETPROP_ITEMDEF ) == 153 ) // homewrecker
            {
                _hVictim.GetScriptScope().m_bMustFizzle <- true;
            }
        }
    }

    if ( _hVictim.GetName() == "engie_beacon_physprop" )
    {
        local _bsc = _hVictim.GetScriptScope();

        if ( ( "m_bSettled" in _bsc ) && _bsc.m_bSettled )
        {
            local _flReal = ( params.damage_type & DMG_ACID ) ?
                            ( params.damage * 3 ) : params.damage;

            if ( _hAttacker != null && _hAttacker.GetTeam() == TF_TEAM_RED &&
                 !_bsc.m_bMustDie && _flReal >= _hVictim.GetHealth() )
            {
                params.damage <- 0;
                _bsc.m_bMustDie <- true;
            };
        }
        else if ( ( "m_iHealth" in _bsc ) && _hAttacker != null &&
                  _hAttacker.GetClassname() == "player" && _hAttacker.GetTeam() == TF_TEAM_RED )
        {
            _bsc.m_iHealth <- ( _bsc.m_iHealth - params.damage );

            if ( _bsc.m_iHealth <= 0 && !_bsc.m_bMustDie )
            {
                RefundBeaconCooldown( _bsc.m_hOwner, ENGIE_BEACON_FAIL_REFUND );

                _bsc.m_bMustDie <- true;
            };
        };
    }

    // the thrown nade/beacon are physics props - vphysics crush impacts hurt players
    if ( _hVictim.GetClassname() == "player" &&
         ( _hInflictor.GetName() == "engie_nade_physprop" ||
           _hInflictor.GetName() == "engie_beacon_physprop" ) )
    {
        params.damage <- 0;
        return;
    };

    if ( _hVictim.GetClassname().find( "obj_" ) == 0 &&
         _hAttacker.GetClassname() == "player" && _hAttacker.GetTeam() == TF_TEAM_BLUE &&
         _hAttacker.GetPlayerClass() == TF_CLASS_HEAVYWEAPONS && ( params.damage_type & DMG_CLUB ) &&
         params.damage > ZHEAVY_MELEE_BUILDING_DMG_CAP )
    {
        params.damage <- ZHEAVY_MELEE_BUILDING_DMG_CAP;
    };
    if ( _hVictim.GetClassname() != "player" || _hVictim.GetClassname() == "player" && _hVictim.GetHealth() <= 0 )
        return;

    // nasty stuff here //
    try{ _szWeaponName = params.weapon.GetClassname() }
    catch( e ){};

    if ( _hAttacker.GetClassname() == "obj_sentrygun" || _hInflictor.GetClassname() == "obj_sentrygun" )
    {
        _szWeaponName = "obj_sentrygun";
    };

    if ( _hAttacker == worldspawn || _hInflictor == worldspawn )
    {
        _szWeaponName = "worldspawn";
    };

    if ( _sc.m_iFlags & ZBIT_MUST_EXPLODE )
    {
        // the demo's own bomb must always be lethal - this is the suicide, not a gib
        if ( _hVictim == _hAttacker && _hInflictor.GetClassname() == "tf_generic_bomb" )
            params.damage <- ( _iForceGibDmg );

        // the overkill inflation is only there to force the gib
        if ( ::bZombieGibsOn && params.damage >= ( _hVictim.GetHealth() ) )
            params.damage <- ( _iForceGibDmg );

        return;
    };

    local _iOriginalDmgBits = params.damage_type;

    if ( _hVictim.GetTeam() == TF_TEAM_BLUE )
    {
        if ( ::bZombieGibsOn && ( params.damage_type & ~DMG_BLAST ) )
        {
            params.damage_type <- ( _iOriginalDmgBits | DMG_BLAST | DMG_PREVENT_PHYSICS_FORCE );
        }

        if ( _szWeaponName != "worldspawn" )
        {
            _sc.m_fTimeLastHit <- Time();
        }

        // ---------------------------------------------------------------------- //
        // make sure we're not modifying a weapon with a special kill attribute   //
        // ---------------------------------------------------------------------- //

        try{ _iWeaponIDX = GetPropInt( _hAttacker.GetActiveWeapon(), STRING_NETPROP_ITEMDEF ); }
        catch( e ){};

        if (  _iWeaponIDX == TF_IDX_GWRENCH   ||
              _iWeaponIDX == TF_IDX_SAXXY     ||
              _iWeaponIDX == TF_IDX_SPYCICLE  ||
              _iWeaponIDX == TF_IDX_GOLDENPAN  )
        {
            params.damage_type <- ( _iOriginalDmgBits );
        };

        if ( _hVictim.GetPlayerClass() == TF_CLASS_PYRO && ( params.damage_type & DMG_BURN ) )
        {
            params.damage <- ( params.damage * ZPYRO_FIRE_DMG_MULT );
            return;
        };

        // base weapon adjustments
        if ( _hAttacker.GetClassname() == "player" && _szWeaponName != "none" )
        {
            switch ( _hAttacker.GetPlayerClass() )
            {
                case TF_CLASS_SNIPER:

                    if ( _szWeaponName == "tf_weapon_compound_bow" )
                    {
                        // no longer modified
                        params.damage <- ( params.damage );
                    };

                    break;

                case TF_CLASS_MEDIC:

                    if ( _szWeaponName == "tf_weapon_crossbow" )
                    {
                        // no longer modified
                        params.damage <- ( params.damage );
                    };

                    break;

                case TF_CLASS_HEAVYWEAPONS:

                    if ( _szWeaponName == "tf_weapon_minigun" )
                    {
                        params.damage <- ( params.damage * TF_NERF_MINIGUN_Z_DMG );
                    };

                    break;

                case TF_CLASS_PYRO:
                    if ( _hVictim.GetPlayerClass() != TF_CLASS_PYRO )
                        return;

                    if ( _szWeaponName == "tf_weapon_flamethrower" ||
                         _szWeaponName == "tf_weapon_flamethrower_rocket" ||
                         _szWeaponName == "tf_weapon_flaregun"  )
                    {
                        params.damage <- ( params.damage * 0 );
                    };

                    break;

                default:
                    break;
            };

        };

        if ( _szWeaponName == "obj_sentrygun" )
        {
           params.damage <- ( params.damage * ( ( _hVictim.GetPlayerClass() == TF_CLASS_HEAVYWEAPONS )
                                                ? TF_NERF_SENTRY_Z_DMG_HEAVY
                                                : TF_NERF_SENTRY_Z_DMG ) );
        };

        if ( params.damage_type & DMG_FALL && _szWeaponName == "worldspawn" )
        {
            // solider can mantreads stomp when jumping
            if ( _hVictim.GetPlayerClass() == TF_CLASS_SOLDIER && _hVictim.InCond( TF_COND_BLASTJUMPING ) )
            {
                local _flDamage = params.damage;
                local _hGroundEnt = GetPropEntity( _hVictim, "m_hGroundEntity" );

                if ( _hGroundEnt.GetClassname() == "player" )
                {
                    _flDamage = ( _flDamage * 3 ) + 10;
                    if ( _hGroundEnt.GetTeam() == TF_TEAM_BLUE || !( _sc.m_iFlags & ZBIT_SOLDIER_IN_POUNCE ) )
                        return;

                    local _hWeapon = _hVictim.GetActiveWeapon();

                    SetPropInt( _hWeapon, STRING_NETPROP_ITEMDEF, 444 ); // mantreads, obviously

               //     ScreenShake            ( _hGroundEnt.GetOrigin(), 12.5, 145.0, 1.0, 490, 0, false );
               //     DispatchParticleEffect ( FX_TF_STOMP_TEXT, _hVictim.GetOrigin(), Vector( 0, 0, 0 ) );

                    _hGroundEnt.TakeDamageCustom( _hVictim, _hVictim, _hWeapon,
                                                  Vector( 0, 0, 0 ), _hVictim.GetOrigin(),
                                                  _flDamage, DMG_FALL, TF_DMG_CUSTOM_BOOTS_STOMP );

                    SetPropInt          ( _hWeapon, STRING_NETPROP_ITEMDEF, arrZombieCosmeticIDX[ TF_CLASS_SOLDIER ] );
                    EmitAmbientSoundOn  ( "Weapon_Mantreads.Impact", 10, 1, 100, _hGroundEnt );
                    EmitAmbientSoundOn  ( "Player.FallDamageDealt", 10, 1, 100, _hGroundEnt );

                    _sc.m_iFlags = (  _sc.m_iFlags & ~ZBIT_SOLDIER_IN_POUNCE );
                    _hVictim.EndSoldierFall();
                };
            };

            params.damage <- ( 0 );
        }
    };

    // ----------------------------------------------------------- //
    // zombie applies damage to survivors                          //
    // ----------------------------------------------------------- //

    if ( _hAttacker.GetClassname() == "player" &&
         _hVictim.GetTeam() == TF_TEAM_RED &&
         _hAttacker.GetTeam() == TF_TEAM_BLUE )
    {

        local _sc = _hAttacker.GetScriptScope();

        // ----------------------------------------------------------- //
        // zombie heavy knock up effect                                //
        // ----------------------------------------------------------- //

        if ( _hAttacker.GetPlayerClass() == TF_CLASS_HEAVYWEAPONS && _hAttacker.GetTeam() == TF_TEAM_BLUE && params.damage_type & DMG_CLUB )
        {
            if ( !_hVictim || _hVictim.GetClassname() != "player" )
                return;

            // no knock up through uber or bonk
            if ( _hVictim.InCond( TF_COND_INVULNERABLE ) ||
                 _hVictim.InCond( TF_COND_INVULNERABLE_USER_BUFF ) ||
                 _hVictim.InCond( TF_COND_PHASE ) )
                return;

            local _iPushForce  =  HEAVY_KNOCK_BACK_FORCE;
            local _vecFwd      =  _hAttacker.EyeAngles().Forward();
            local _vecBump     =  Vector( 0, 0, _iPushForce * 2 );
            local _vecThrow    =  ( ( _vecFwd * _iPushForce ) + _vecBump );

            SetPropEntity         ( _hVictim, "m_hGroundEntity", null );
            _hVictim.AddCond      ( TF_COND_KNOCKED_INTO_AIR );
            _hVictim.RemoveFlag   ( FL_ONGROUND );

            _hVictim.ApplyAbsVelocityImpulse ( _vecThrow );
            EmitSoundOn( "DemoCharge.HitFlesh", _hVictim ); // todo - const
        };

        // ----------------------------------------------------------- //
        // hitting an already-burning survivor buffs the zombie        //
        // ----------------------------------------------------------- //

        if ( _hVictim.InCond( TF_COND_BURNING ) && params.damage_type & DMG_CLUB )
        {
            _hAttacker.AddCondEx( TF_COND_OFFENSEBUFF, 0.1, _hAttacker )
        }

        // ----------------------------------------------------------- //
        // zombie deals fatal damage with arms                         //
        // ----------------------------------------------------------- //

        if ( ( params.damage > _hVictim.GetHealth() ) &&
             ( params.damage_type & DMG_CLUB ) )
        {
            // killicon switch
            switch ( _hAttacker.GetPlayerClass() ) {
                case TF_CLASS_SCOUT:
                    _szKillicon = KILLICON_SCOUT_MELEE;
                    break;
                case TF_CLASS_SOLDIER:
                    _szKillicon = KILLICON_SOLDIER_MELEE;
                    break;
                case TF_CLASS_PYRO:
                    _szKillicon = KILLICON_PYRO_MELEE;
                    break;
                case TF_CLASS_DEMOMAN:
                    _szKillicon = KILLICON_DEMOMAN_MELEE;
                    break;
                case TF_CLASS_HEAVYWEAPONS:
                    _szKillicon = KILLICON_HEAVY_MELEE;
                    break;
                case TF_CLASS_ENGINEER:
                    _szKillicon = KILLICON_ENGIE_MELEE;
                    break;
                case TF_CLASS_MEDIC:
                    _szKillicon = KILLICON_MEDIC_MELEE;
                    break;
                case TF_CLASS_SNIPER:
                    _szKillicon = KILLICON_SNIPER_MELEE;
                    break;
                case TF_CLASS_SPY:
                    _szKillicon = KILLICON_SPY_MELEE;
                    break;
                default:
                    _szKillicon = "unarmed_combat";
                    break;
            };

            SlayPlayerWithSpoofedIDX( _hAttacker,
                                      _hVictim,
                                      _hAttacker.GetActiveWeapon(),
                                      params.damage_force,
                                      params.damage_position,
                                      ZOMBIE_SPOOF_WEAPON_IDX,
                                      _szKillicon );

            params.early_out <- true;
        };

        // register the time we hit someone
        // and remove out of combat buff
        _sc.m_fTimeLastHit <- Time();
        _hAttacker.RemoveOutOfCombat();
        return;
    };
};

function OnGameEvent_player_hurt( params )
{
    local _hPlayer   = GetPlayerFromUserID ( params.userid );
    local _hAttacker = GetPlayerFromUserID ( params.attacker );
    local _sc        = _hPlayer.GetScriptScope();

    local _iTeamNum  = _hPlayer.GetTeam();

    if ( _iTeamNum == TF_TEAM_BLUE )
    {
        // on zombie death
        if ( params.health <= 0 )
        {
            // force gibs on zombie death. with gibs off the infected model stays
            // on so the ragdoll wears it
            if ( ::bZombieGibsOn )
            {
                SetPropInt          ( _hPlayer, "m_iPlayerSkinOverride", 0 );
                _hPlayer.SetHealth  ( -20 ); // force overkill threshhold

                _hPlayer.SetCustomModelWithClassAnimations( arrTFClassPlayerModels[ _hPlayer.GetPlayerClass() ] );
            };
        }
        else if ( params.health >=  0 )
        {
            if ( _hAttacker == null )
                return;

            if ( _hAttacker.GetClassname() == "player" )
            {
                if ( _hAttacker.GetActiveWeapon().GetClassname() == "tf_weapon_drg_pomson" )
                {
                    local _flCooldownMod = DRG_RAYGUN_ZOMBIE_COOLDOWN_MOD;

                    if ( _flCooldownMod == -1 )
                    {
                        _flCooldownMod = _sc.m_hZombieAbility.m_fAbilityCooldown;
                    }

                    _hPlayer.SetNextActTime( ZOMBIE_ABILITY_CAST, _flCooldownMod );
                }
            }
        }
    }
    else if ( _iTeamNum == TF_TEAM_RED )
    {
        // on survivor death
        if ( params.health <=  0 )
        {
            // clear script overlay material (probably imcookin green)
            _hPlayer.SetScriptOverlayMaterial( "" );
        }
    }
};

function OnGameEvent_localplayer_pickup_weapon( params ) {};

__CollectGameEventCallbacks( this );