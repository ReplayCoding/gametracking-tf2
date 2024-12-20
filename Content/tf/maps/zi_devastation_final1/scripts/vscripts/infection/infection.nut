// --------------------------------------------------------------------------------------- //
// Zombie Infection                                                                        //
// --------------------------------------------------------------------------------------- //
// All Code By: Harry Colquhoun (https://steamcommunity.com/profiles/76561198025795825)    //
// Assets/Game Design by: Diva Dan (https://steamcommunity.com/profiles/76561198072146551) //
// --------------------------------------------------------------------------------------- //
// infection mode main script                                                              //
// --------------------------------------------------------------------------------------- //
zi <- this;
function Main()
{
    if ( !( "InfectionLoaded" in getroottable() ) )
    {
        printl("infection Mode Initliazing...");
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
        printl        ( "Infection Mode Loaded." );
    };

    return true;
};

// changes ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
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
    ::bGameStarted <- false;

try {
    _CONST;
} catch(e) {
    return;
};

ClearGameEventCallbacks();

function OnPostSpawn()
{
    AddThinkToEnt( self, "GameStateThink" );
    IncludeScript( "infection/payload_logic.nut", root);
}

function OnGameEvent_teamplay_round_win( params )
{
    return;
};

function OnGameEvent_player_spawn( params )
{
    local _hPlayer     = GetPlayerFromUserID( params.userid );
    local _iRoundState = GetPropInt( GameRules, "m_iRoundState" );

    _hPlayer.ValidateScriptScope(); // only do this once, for ficool's sake

    if ( _hPlayer == null )
        return;

    local _sc = _hPlayer.GetScriptScope();

    // we use the script overlay material for zombie ability hud
    // so let's make sure it's cleared whenever a player has respawned
    _hPlayer.SetScriptOverlayMaterial( "" );

    // also set their playermodel back to normal
    _hPlayer.SetCustomModelWithClassAnimations( arrTFClassPlayerModels[ _hPlayer.GetPlayerClass() ] );

    // and reset infection specific vars
    _hPlayer.ResetInfectionVars();

    if ( (_hPlayer.GetPlayerClass() ==  TF_CLASS_DEMOMAN || _hPlayer.GetPlayerClass() == TF_CLASS_SOLDIER) && _hPlayer.GetTeam() == TF_TEAM_RED )
    {
        _hPlayer.ModifyJumperWeapons();
    }

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

        // add the pending zombie flag
        // the actual zombie conversion is handled in the player's think script
        _sc.m_iFlags <- ( _sc.m_iFlags | ZBIT_PENDING_ZOMBIE );

        // remove all of the player's existing items
        _hPlayer.RemovePlayerWearables();

        // add the zombie cosmetics/skin modifications
        _hPlayer.GiveZombieCosmetics();
        _hPlayer.GiveZombieFXWearable();

        SendGlobalGameEvent( "post_inventory_application", { userid = GetPlayerUserID(_hPlayer) });

        // make sure their health is correct
        _hPlayer.SetHealth ( _hPlayer.GetMaxHealth() );

        // add a tiny delay to zombie conversion for safety
        _hPlayer.SetNextActTime ( ZOMBIE_BECOME_ZOMBIE, 0.1 );
        return;
    };

    _hPlayer.ResetInfectionVars();
    return;
};

function OnGameEvent_teamplay_setup_finished( params )
{
    ::bGameStarted <- true;

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
            if ( _iPlayerCountRed <= 4 )
            {
                _numStartingZombies = 1;
            }
            else if ( _iPlayerCountRed <= 8 )
            {
                _numStartingZombies = 2;
            }
            else if ( _iPlayerCountRed <= 12 )
            {
                _numStartingZombies = 3;
            }
            else if ( _iPlayerCountRed < 18 )
            {
                _numStartingZombies = 4;
            }
            else // 18 or more players
            {
                _numStartingZombies = RoundUp( _iPlayerCountRed / STARTING_ZOMBIE_FAC );
            }
        }

        local _szZombieNetNames  =  "";
        local _zombieArr         =  GetRandomPlayers( _numStartingZombies );

        if ( _zombieArr.len() == 0 )
            return;

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

            // ------------------------------------------- //
            // make sure heavy doesn't get stuck in t-pose //
            // ------------------------------------------- //

            if ( _nextPlayer.GetPlayerClass() == TF_CLASS_HEAVYWEAPONS )
            {
                if ( _nextPlayer.GetActiveWeapon().GetClassname() == "tf_weapon_minigun" )
                {
                    SetPropInt( _nextPlayer.GetActiveWeapon(), "m_iWeaponState", 0 );
                };
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
            _sc.m_iFlags <- ( ( _sc.m_iFlags | ZBIT_PENDING_ZOMBIE ) );

            // don't delay zombie conversion when the player is alive.
            _nextPlayer.SetNextActTime ( ZOMBIE_BECOME_ZOMBIE, INSTANT );
            _nextPlayer.SetNextActTime ( ZOMBIE_ABILITY_CAST, 0.1 );

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
    local _bIsEngineerWithEMP  =  ( _hPlayer.GetPlayerClass() == TF_CLASS_ENGINEER && _hPlayer.CanDoAct( ZOMBIE_ABILITY_CAST ) );

    SetPropIntArray( _hPlayer, "m_nModelIndexOverrides", 0, 3 );

    if ( ::bGameStarted && _hPlayerTeam == TF_TEAM_BLUE ) // zombie has died
    {

        if ( _iClassNum ==  TF_CLASS_MEDIC )
        {
            if ( _sc.m_hMedicDispenser )
                _sc.m_hMedicDispenser.Destroy();
        }

        // zombie engie with unused emp grenade drops a small ammo kit
        // so just use the one valve spawned for us
        if ( !_bIsEngineerWithEMP )
        {
            // if the player isn't an engineer, we want to cull the kit instead
            local _hDroppedAmmo = null;
            while ( _hDroppedAmmo = Entities.FindByClassname( _hDroppedAmmo, "tf_ammo_pack" ) )
            {
                if ( _hDroppedAmmo.GetOwner() == _hPlayer )
                {
                    _hDroppedAmmo.Destroy();
                };
            };
        };

        if ( _hPlayer.GetPlayerClass() == TF_CLASS_SNIPER )
        {
            _sc.m_hZombieAbility.CreateSpitball( true );
        };

         if ( _hPlayer.GetPlayerClass() == TF_CLASS_PYRO )
         {
            local _hNextPlayer = null;
            local _hKillicon = KilliconInflictor( KILLICON_PYRO_BREATH );

            CreateMediumHealthKit( _hPlayer.GetOrigin() );

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

        }
        else
        {
            if ( _hPlayer.GetPlayerClass() == TF_CLASS_HEAVYWEAPONS )
            {
                CreateMediumHealthKit( _hPlayer.GetOrigin() );
            }
            else
            {
                CreateSmallHealthKit( _hPlayer.GetOrigin() );
            }

        };

        // ------------------------------------- //
        // remove zombie "vgui"                  //
        // ------------------------------------- //
        // we use the script overlay material for zombie ability hud
        // so let's make sure it's cleared whenever a player has respawned
        _hPlayer.SetScriptOverlayMaterial ( "" );

        // same thing for the HUD text channels
        _sc.m_hHUDText.KeyValueFromString ( "message", "" );
        _sc.m_hHUDTextAbilityName.KeyValueFromString ( "message", "" );

        EntFireByHandle( _sc.m_hHUDText,  "Display", "", 0.0, _hPlayer, _hPlayer );
        EntFireByHandle( _sc.m_hHUDTextAbilityName,  "Display", "", 0.0, _hPlayer, _hPlayer );

        // ------------------------------------- //
        // Zombie Gib Hack                       //
        // ------------------------------------- //
        // when a player has the zombie skin override, they are hard coded to never gib
        // if we remove this skin here it creates gibs for the player
        SetPropInt ( _hPlayer, "m_iPlayerSkinOverride", 0 );

        // we set custom model on the player afterwards because otherwise the gibs come out red
        _hPlayer.SetCustomModelWithClassAnimations( arrTFClassPlayerModels[ _iClassNum ] );

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

        // hide our fx wearable to stop the particles from generating
        SetPropInt( _sc.m_hZombieFXWearable, "m_nRenderMode", kRenderNone );

        // _sc.m_hZombieWearable.Kill();
        // SendGlobalGameEvent( "post_inventory_application", { userid = GetPlayerUserID(_hPlayer) });

        try { _sc.m_hZombieFXWearable.Destroy() } catch ( e ) {}

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

        if ( bIsPayload )
            return; // don't add time to the round timer if it's a payload map

        EntFireByHandle( _hRoundTimer, "AddTime", ADDITIONAL_SEC_PER_PLAYER.tostring(), 0, null, null );
    };
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
        if ( _hVictim == _hAttacker && _hInflictor.GetClassname() == "tf_generic_bomb" )
            params.damage <- ( _iForceGibDmg );

        if ( params.damage >= ( _hVictim.GetHealth() ) )
            params.damage <- ( _iForceGibDmg );

        return;
    };

    local _iOriginalDmgBits = params.damage_type;

    if ( _hVictim.GetTeam() == TF_TEAM_BLUE )
    {
        // ---------------------------------------------------------------------- //
        // On Zombie receives damage from player                                  //
        // ---------------------------------------------------------------------- //
        // add DMG_BLAST to the damage bits
        // to force the zombie to explode in to gibs
        if ( params.damage_type & ~DMG_BLAST )
        {
            // if the damage isn't already blast we add blast
            params.damage_type <- ( _iOriginalDmgBits | DMG_BLAST | DMG_PREVENT_PHYSICS_FORCE );
        }

        if ( _szWeaponName != "worldspawn" )
        {
            // fall damage is caught and removed
            // so only set this if it's not world damage
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
            params.damage <- ( 0 );
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
           params.damage <- ( params.damage * TF_NERF_SENTRY_Z_DMG );
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

                    ScreenShake            ( _hGroundEnt.GetOrigin(), 12.5, 145.0, 1.0, 490, 0, false );
                    DispatchParticleEffect ( FX_TF_STOMP_TEXT, _hVictim.GetOrigin(), Vector( 0, 0, 0 ) );

                    _hGroundEnt.TakeDamageCustom( _hVictim, _hVictim, _hWeapon,
                                                  Vector( 0, 0, 0 ), _hVictim.GetOrigin(),
                                                  _flDamage, DMG_FALL, TF_DMG_CUSTOM_BOOTS_STOMP );

                    SetPropInt          ( _hWeapon, STRING_NETPROP_ITEMDEF, arrZombieCosmeticIDX[ TF_CLASS_SOLDIER ] );
                    EmitAmbientSoundOn  ( "Weapon_Mantreads.Impact", 10, 1, 100, _hGroundEnt );
                    EmitAmbientSoundOn  ( "Player.FallDamageDealt", 10, 1, 100, _hGroundEnt );

                    _sc.m_iFlags = (  _sc.m_iFlags & ~ZBIT_SOLDIER_IN_POUNCE );
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
        // zombie pyro on-hit fire effect                              //
        // ----------------------------------------------------------- //

        if ( _hVictim.InCond( TF_COND_BURNING ) && params.damage_type & DMG_CLUB )
        {
            _hAttacker.AddCondEx( TF_COND_OFFENSEBUFF, 0.1, _hAttacker )
        }

        if ( _hAttacker.GetPlayerClass() == TF_CLASS_PYRO &&
             _hAttacker.GetTeam() == TF_TEAM_BLUE && params.damage_type & DMG_CLUB )
        {
            local _hIgniteTrigger = SpawnEntityFromTable( "trigger_ignite",
            {
                burn_duration             = 3,
                damage_percent_per_second = 8,
                spawnflags                = 1,
                solid                     = 2,
            });

            _hIgniteTrigger.SetAbsOrigin  ( _hVictim.GetCenter() );

            EntFireByHandle ( _hIgniteTrigger, "StartTouch", "", -1, _hVictim, _hVictim );
            EntFireByHandle ( _hIgniteTrigger, "Kill", "", 0.01, null, null );
        };

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
            // force gibs on zombie death
            SetPropInt          ( _hPlayer, "m_iPlayerSkinOverride", 0 );
            _hPlayer.SetHealth  ( -20 ); // force overkill threshhold

            _hPlayer.SetCustomModelWithClassAnimations( arrTFClassPlayerModels[ _hPlayer.GetPlayerClass() ] );
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