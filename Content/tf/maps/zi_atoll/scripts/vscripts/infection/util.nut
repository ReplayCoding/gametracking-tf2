// --------------------------------------------------------------------------------------- //
// Infection - Prototype v0.5.1 - Last Edited: 29/08/2023                                  //
// --------------------------------------------------------------------------------------- //
// Code By: Harry Colquhoun (https://steamcommunity.com/profiles/76561198025795825)        //
// Assets/Game Design by: Diva Dan (https://steamcommunity.com/profiles/76561198072146551) //
// --------------------------------------------------------------------------------------- //
// utility functions                                                                       //
// --------------------------------------------------------------------------------------- //

function PlayerCount( _team = -1 )
{
    local _playerCount   = 0;
    local _targTeamCount = 0;

    for ( local i = 1; i <= MaxPlayers; i++ )
    {
        local _player = PlayerInstanceFromIndex( i );

        if ( _player != null )
        {
            if ( _player.GetTeam() == _team || _team == -1 )
            {
                _playerCount++;
            }
            else
            {
               continue;
            };
        }
        else
        {
            continue;
        };
    };

    return _playerCount;
};

function GetAllPlayers()
{
    for ( local i = 1; i <= MaxPlayers; i++ )
    {
        local _player = PlayerInstanceFromIndex( i );

        if ( PlayerIsValid( _player ) )
        {
            yield _player;
        }
        else
        {
            break;
        };
    };

    return;
};


function GetRandomPlayers( _howMany = 1 )
{
    local _playerArr = [];

    foreach ( _player in GetAllPlayers() )
    {
        if ( PlayerIsValid( _player ) )
            _playerArr.append( _player );
    };

    _howMany = ( _howMany <= _playerArr.len() ) ? _howMany : _playerArr.len();

    local _selectedPlayers = [];

    for ( local i = 0; i < _howMany; i++ )
    {
        local _randomID = RandomInt( 0, _playerArr.len() - 1 );
        _selectedPlayers.append( _playerArr[ _randomID ] );
        _playerArr.remove( _randomID );
    };

    return _selectedPlayers;
};


function VScriptError( _szMessage, _errLvl = ELVL_INFO, _szIdentifier = "" )
{
    local _szMsg = "";

    switch ( _errLvl )
    {
        case ELVL_DEBUG:
            if ( _Debug < 3 ) { return; }
            _szMsg = format( "%f - %s - [DEBUG] - %s [%s]", Time().tofloat(), STRING_GAMEMODE_NAME, _szMessage, _szIdentifier );
            break;
        case ELVL_INFO:
            if ( _Debug < 2 ) { return; }
            _szMsg = format( "%f - %s - [INFO] - %s [%s]",  Time().tofloat(), STRING_GAMEMODE_NAME, _szMessage, _szIdentifier );
            break;
        case ELVL_ERROR:
            if ( _Debug < 1 ) { return; }
            _szMsg = format( "%f - %s - [ERROR] - %s [%s]", Time().tofloat(), STRING_GAMEMODE_NAME, _szMessage, _szIdentifier );
            break;
        default:
            _szMsg = format( "%f - %s - [INFO] - %s [%s]",  Time().tofloat(), STRING_GAMEMODE_NAME, _szMessage, _szIdentifier );
            break;
    };

    printl( _szMsg );
    return;
};

function ChangeTeamSafe( _hPlayer, _iTeamNum, _bForce = false )
{
    if ( !PlayerIsValid( _hPlayer ) )
        return;

    if ( typeof _iTeamNum != "integer" || _iTeamNum < 0 || _iTeamNum > 3 )
        return;

    if ( _hPlayer.GetTeam() == _iTeamNum )
        return;

    // m_bIsCoaching trick to change team even if player is in a duel (source: vdc)
    SetPropBool( _hPlayer, "m_bIsCoaching", true );
    _hPlayer.ForceChangeTeam( _iTeamNum, _bForce );
    SetPropBool( _hPlayer, "m_bIsCoaching", false );

    return;
};

function NetName( _hPlayer )
{
    if ( !PlayerIsValid( _hPlayer ) )
        return "[UNKNOWN/INVALID PLAYER]";

    local _szNetname = GetPropString( _hPlayer, "m_szNetname" );

    if ( typeof _szNetname != "string" || _szNetname == "" || _szNetname == null )
        return "[BAD NETNAME]";

    return _szNetname
};

function PlayerIsValid( _hPlayer )
{
    if ( _hPlayer == null || !_hPlayer.ValidateScriptScope() )
        return false;

    return true;
};


function ShouldZombiesWin()
{
    local _iValidSurvivors = 0;
    local _iValidPlayers   = 0;

    // count all valid survivors to see if the game should end
    for ( local i = 1; i <= MaxPlayers; i++ )
    {
        local _player = PlayerInstanceFromIndex( i );

        if ( _player != null )
        {
            _iValidPlayers++;
            // if the player is valid, on survivor (red) team, alive, and not the player who just died
            if ( ( _player != null ) &&
                 ( _player.GetTeam() == TF_TEAM_RED ) &&
                 ( GetPropInt( _player, "m_lifeState" ) == ALIVE ) )
            {
                 _iValidSurvivors++;
            };
        }
        else
        {
            break;
        };
    };

    if ( _iValidPlayers == 0 ) // GetAllPlayers didn't find any players, should never happen
    {
        VScriptError( ERROR_NO_PLAYER_FOUND, ELVL_INFO, "OnGameEvent_player_death" );
        return;
    };

    // check if zombies have killed enough survivors to win
    if ( _iValidSurvivors <= MAX_SURVIVORS_FOR_ZOMBIE_WIN )
    {
        local _hGameWin = SpawnEntityFromTable( "game_round_win",
        {
            win_reason = "0",
            force_map_reset = "1",
            TeamNum = "3", // TF_TEAM_BLUE
            switch_teams = "0"
        } );

        // the zombies have won the round.
        VScriptError    ( INFO_ZOMBIES_WIN, ELVL_INFO, "OnGameEvent_player_death" );
        EntFireByHandle ( _hGameWin, "RoundWin", "", 0, null, null );
    };

    return;
};

function PrintToChat( _szMessage )
{
    if ( typeof _szMessage != "string" || _szMessage == "" || _szMessage == null )
        return;

    ClientPrint( null, HUD_PRINTTALK, _szMessage );
    return;
}