// --------------------------------------------------------------------------------------- //
// Zombie Infection                                                                        //
// --------------------------------------------------------------------------------------- //
// All Code By: netmuck (https://steamcommunity.com/profiles/76561198025795825)            //
// Assets/Game Design by: Diva Dan (https://steamcommunity.com/profiles/76561198072146551) //
// --------------------------------------------------------------------------------------- //
// debug system                                                                            //
// --------------------------------------------------------------------------------------- //

::ZI_DEBUG_CMD_PREFIX      <- "zi";

::ZI_DEBUG_CHAT_COLOR      <- "\x0870b04aFF";
::ZI_DEBUG_CHAT_ERR_COLOR  <- "\x08FF3F3FFF";
::ZI_DEBUG_CONSOLE_TAG     <- "[ZI/DEBUG] ";
::ZI_DEBUG_LOG_MAX         <- 64;
::ZI_DEBUG_DEFAULT_LEVEL   <- 1;
::ZI_DEBUG_HOLD_SPAWN_TIME <- 600;

::ZI_DEBUG_AUTHORIZED_IDS <-
{
    [ "[U:1:65530097]" ] = "netmuck",
};

::ZI_DEBUG_TOGGLES <-
{
    splat_cells = [ "bSpitDebugBoxes",
                    "Splat cell boxes",
                    "outline the spit/tar zone cells - the goop art shows the same footprint" ],

    vo_moan     = [ "bZombieVOUseMoan",
                    "Zombie VO: generic moan",
                    "swap the per-class evil laugh for one classless undead moan" ],

    rock_debug  = [ "bHeavyRockDebug",
                    "Heavy rock throw visualisers",
                    "flight hull + trail, blast sphere, per-victim line of sight and falloff (needs debug mode on)" ],

    rock_los    = [ "bHeavyRockBlastLOS",
                    "Heavy rock blast line of sight",
                    "off = the blast reaches everyone in radius, through walls and all" ],
};

::DEBUG_MODE      <- 0;

::bSpitDebugBoxes <- false;

::ZIDebugIsAllDigits <- function( _szIn )
{
    if ( _szIn.len() < 1 )
        return false;

    foreach ( _chChar in _szIn )
    {
        if ( _chChar < '0' || _chChar > '9' )
            return false;
    };

    return true;
};

::ZIDebugGetSteamID <- function( _hPlayer )
{
    if ( _hPlayer == null || !_hPlayer.IsValid() )
        return null;

    local _szID = null;

    try
    {
        _szID = GetPropString( _hPlayer, "m_szNetworkIDString" );
    }
    catch ( _e )
    {
        return null;
    };

    if ( _szID == null || typeof( _szID ) != "string" )
        return null;

    _szID = strip( _szID );

    if ( _szID.len() < 1 )
        return null;

    local _szUpper = _szID.toupper();

    if ( _szUpper == "BOT" || _szUpper == "UNKNOWN" ||
         _szUpper == "STEAM_ID_PENDING" || _szUpper == "STEAM_ID_LAN" )
        return null;

    return _szID;
};

class CZIDebugCommand
{
    m_szName          = "";
    m_szDesc          = "";
    m_szUsage         = "";
    m_iMinArgs        = 0;
    m_iMaxArgs        = -1;
    m_bRequiresDebug  = false;
    m_bRequiresAlive  = false;
    m_arrAliases      = null;
    m_funcExec        = null;

    constructor( _szName, _szDesc, _szUsage = "", _iMinArgs = 0, _iMaxArgs = -1, _funcExec = null )
    {
        this.m_szName      = _szName.tolower();
        this.m_szDesc      = _szDesc;
        this.m_szUsage     = _szUsage;
        this.m_iMinArgs    = _iMinArgs;
        this.m_iMaxArgs    = _iMaxArgs;
        this.m_funcExec    = _funcExec;
        this.m_arrAliases  = [];
    };

    function AddAlias( _szAlias )
    {
        this.m_arrAliases.append( _szAlias.tolower() );
        return this;
    };

    function RequireDebugMode( _bRequire = true )
    {
        this.m_bRequiresDebug = _bRequire;
        return this;
    };

    function RequireAlive( _bRequire = true )
    {
        this.m_bRequiresAlive = _bRequire;
        return this;
    };

    function GetName()  { return this.m_szName; };
    function GetDesc()  { return this.m_szDesc; };

    function GetUsageString()
    {
        local _szOut = ( ZI_DEBUG_CMD_PREFIX + " " + this.m_szName );

        if ( this.m_szUsage.len() > 0 )
            _szOut += ( " " + this.m_szUsage );

        return _szOut;
    };

    function OnExecute( _hPlayer, _arrArgs )
    {
        if ( this.m_funcExec == null )
        {
            ZIDebug.Reply( _hPlayer, ( "command \"" + this.m_szName + "\" has no handler" ), true );
            return false;
        };

        return this.m_funcExec.call( this, _hPlayer, _arrArgs );
    };

    function Execute( _hPlayer, _arrArgs )
    {
        if ( this.m_bRequiresDebug && !DEBUG_MODE )
        {
            ZIDebug.Reply( _hPlayer,
                           ( "\"" + this.m_szName + "\" needs debug mode - run \"" +
                             ZI_DEBUG_CMD_PREFIX + " debug 1\" first" ),
                           true );
            return false;
        };

        if ( _arrArgs.len() < this.m_iMinArgs ||
             ( this.m_iMaxArgs >= 0 && _arrArgs.len() > this.m_iMaxArgs ) )
        {
            ZIDebug.Reply( _hPlayer, ( "usage: " + this.GetUsageString() ), true );
            return false;
        };

        if ( this.m_bRequiresAlive && !IsPlayerAlive( _hPlayer ) )
        {
            ZIDebug.Reply( _hPlayer, ( "\"" + this.m_szName + "\" needs you to be alive" ), true );
            return false;
        };

        return this.OnExecute( _hPlayer, _arrArgs );
    };
};

class CZIDebugCmd_Toggle extends CZIDebugCommand
{
    constructor()
    {
        base.constructor( "toggle",
                          "flip a debug visual on or off",
                          "<name> [0|1]",
                          0, 2 );
    };

    function ListToggles( _hPlayer )
    {
        ZIDebug.Reply( _hPlayer, "toggles:" );

        foreach ( _szName, _arrToggle in ZI_DEBUG_TOGGLES )
        {
            local _bState = ( getroottable()[ _arrToggle[0] ] ) ? "ON" : "OFF";

            ZIDebug.Reply( _hPlayer, ( "  " + _szName + " = " + _bState + "  (" + _arrToggle[2] + ")" ) );
        };

        return true;
    };

    function OnExecute( _hPlayer, _arrArgs )
    {
        if ( _arrArgs.len() < 1 )
            return this.ListToggles( _hPlayer );

        local _szName = _arrArgs[0].tolower();

        if ( !( _szName in ZI_DEBUG_TOGGLES ) )
        {
            ZIDebug.Reply( _hPlayer, ( "no such toggle: " + _szName ), true );
            return false;
        };

        local _arrToggle = ZI_DEBUG_TOGGLES[ _szName ];
        local _szFlag    = _arrToggle[0];
        local _tblRoot   = getroottable();

        if ( !( _szFlag in _tblRoot ) )
        {
            ZIDebug.Reply( _hPlayer, ( "toggle \"" + _szName + "\" points at missing global " + _szFlag ), true );
            return false;
        };

        local _bWanted = !_tblRoot[ _szFlag ];

        if ( _arrArgs.len() > 1 )
            _bWanted = ( _arrArgs[1] != "0" );

        _tblRoot[ _szFlag ] = _bWanted;

        ZIDebug.Announce( _arrToggle[1] + ( _bWanted ? " ON" : " OFF" ) );
        return true;
    };
};

::ZIDebug <-
{
    m_tblCommands   = {},
    m_arrOrder      = [],
    m_tblAuthorized = {},
    m_arrLog        = [],

    function Log( _szMessage )
    {
        if ( !DEBUG_MODE )
            return;

        printl( ZI_DEBUG_CONSOLE_TAG + _szMessage );
        return;
    },

    function Warn( _szMessage )
    {
        printl( ZI_DEBUG_CONSOLE_TAG + "WARNING: " + _szMessage );
        return;
    },

    function Audit( _szSteamID, _szName, _szLine, _szResult )
    {
        local _tblEntry =
        {
            time     = Time(),
            steamid  = ( _szSteamID == null ) ? "<none>" : _szSteamID,
            name     = _szName,
            line     = _szLine,
            result   = _szResult,
        };

        this.m_arrLog.append( _tblEntry );

        while ( this.m_arrLog.len() > ZI_DEBUG_LOG_MAX )
            this.m_arrLog.remove( 0 );

        printl( format( "%s%.2f  %s (%s)  \"%s\"  -> %s",
                        ZI_DEBUG_CONSOLE_TAG,
                        _tblEntry.time, _tblEntry.name, _tblEntry.steamid,
                        _tblEntry.line, _tblEntry.result ) );
        return;
    },

    function Reply( _hPlayer, _szMessage, _bIsError = false )
    {
        if ( _hPlayer == null || !_hPlayer.IsValid() )
            return;

        local _szColor = _bIsError ? ZI_DEBUG_CHAT_ERR_COLOR : ZI_DEBUG_CHAT_COLOR;

        ClientPrint( _hPlayer, HUD_PRINTTALK, ( _szColor + _szMessage ) );
        return;
    },

    function Announce( _szMessage )
    {
        ClientPrint( null, HUD_PRINTTALK, ( ZI_DEBUG_CHAT_COLOR + _szMessage ) );
        return;
    },

    function IsEnabled()
    {
        return ( DEBUG_MODE != 0 );
    },

    function IsToggleOn( _szName )
    {
        if ( !( _szName in ZI_DEBUG_TOGGLES ) )
            return false;

        local _szFlag = ZI_DEBUG_TOGGLES[ _szName ][0];

        return ( ( _szFlag in getroottable() ) && getroottable()[ _szFlag ] ) ? true : false;
    },

    function SetDebugMode( _iLevel )
    {
        if ( _iLevel == DEBUG_MODE )
            return;

        ::DEBUG_MODE = _iLevel;

        if ( _iLevel )
        {
            local _hTimer = Entities.FindByClassname( null, "team_round_timer" );

            if ( _hTimer != null )
                _hTimer.Destroy();

            this.Announce( "Debug mode enabled (level " + _iLevel + ")." );
            return;
        };

        this.Announce( "Debug mode disabled. Restarting game..." );
        Convars.SetValue( "mp_restartgame_immediate", 1 );
        return;
    },

    function BuildAuthTable()
    {
        this.m_tblAuthorized = {};

        foreach ( _szID, _szLabel in ZI_DEBUG_AUTHORIZED_IDS )
        {
            local _szKey = strip( _szID ).toupper();

            if ( _szKey.len() < 6 || _szKey[0] != '[' || _szKey[ _szKey.len() - 1 ] != ']' )
            {
                this.Warn( "authorised steamid \"" + _szID +
                           "\" is not a steam3 id like [U:1:65530097] - entry ignored" );
                continue;
            };

            this.m_tblAuthorized[ _szKey ] <- _szLabel;
        };

        if ( this.m_tblAuthorized.len() < 1 )
            this.Warn( "no usable entries in ZI_DEBUG_AUTHORIZED_IDS - the debug console is closed" );

        return;
    },

    function IsAuthorized( _hPlayer )
    {
        local _szID = ZIDebugGetSteamID( _hPlayer );

        if ( _szID == null )
            return false;

        local _szKey = _szID.toupper();

        foreach ( _szPermitted, _szLabel in this.m_tblAuthorized )
        {
            if ( _szPermitted.len() == _szKey.len() && _szPermitted == _szKey )
                return true;
        };

        return false;
    },

    function RegisterCommand( _hCommand )
    {
        local _szName = _hCommand.GetName();

        if ( _szName in this.m_tblCommands )
        {
            this.Warn( "duplicate debug command \"" + _szName + "\" - keeping the first" );
            return _hCommand;
        };

        this.m_tblCommands[ _szName ] <- _hCommand;
        this.m_arrOrder.append( _szName );

        foreach ( _szAlias in _hCommand.m_arrAliases )
        {
            if ( _szAlias in this.m_tblCommands )
            {
                this.Warn( "duplicate debug alias \"" + _szAlias + "\" - ignored" );
                continue;
            };

            this.m_tblCommands[ _szAlias ] <- _hCommand;
        };

        return _hCommand;
    },

    function FindCommand( _szName )
    {
        local _szKey = _szName.tolower();

        return ( _szKey in this.m_tblCommands ) ? this.m_tblCommands[ _szKey ] : null;
    },

    function ParseCommandLine( _szText )
    {
        local _arrOut = [];

        if ( _szText == null || typeof( _szText ) != "string" )
            return _arrOut;

        foreach ( _szToken in split( strip( _szText ), " \t" ) )
        {
            local _szClean = strip( _szToken );

            if ( _szClean.len() > 0 )
                _arrOut.append( _szClean );
        };

        return _arrOut;
    },

    function IsCommandPrefix( _szToken )
    {
        local _szKey = _szToken.tolower();

        if ( _szKey.len() > 1 && ( _szKey[0] == '/' || _szKey[0] == '!' ) )
            _szKey = _szKey.slice( 1 );

        return ( _szKey == ZI_DEBUG_CMD_PREFIX );
    },

    function Dispatch( _hPlayer, _szCommand, _arrArgs, _szSteamID, _szLine )
    {
        local _hCommand = this.FindCommand( _szCommand );
        local _szName   = NetName( _hPlayer );

        if ( _hCommand == null )
        {
            this.Reply( _hPlayer, ( "no such command: " + _szCommand + " (try \"" +
                                    ZI_DEBUG_CMD_PREFIX + " help\")" ), true );
            this.Audit( _szSteamID, _szName, _szLine, "unknown command" );
            return;
        };

        local _bResult = false;

        try
        {
            _bResult = _hCommand.Execute( _hPlayer, _arrArgs );
        }
        catch ( _e )
        {
            this.Reply( _hPlayer, ( "command threw: " + _e ), true );
            this.Audit( _szSteamID, _szName, _szLine, ( "exception: " + _e ) );
            return;
        };

        this.Audit( _szSteamID, _szName, _szLine, ( _bResult ? "ok" : "refused" ) );
        return;
    },

    function OnPlayerSay( params )
    {
        if ( !( "text" in params ) || !( "userid" in params ) )
            return;

        local _arrTokens = this.ParseCommandLine( params.text );

        if ( _arrTokens.len() < 1 || !this.IsCommandPrefix( _arrTokens[0] ) )
            return;

        local _hPlayer = GetPlayerFromUserID( params.userid );

        if ( _hPlayer == null || !_hPlayer.IsValid() )
            return;

        local _szLine    = strip( params.text );
        local _szSteamID = ZIDebugGetSteamID( _hPlayer );

        if ( !this.IsAuthorized( _hPlayer ) )
        {
            this.Audit( _szSteamID, NetName( _hPlayer ), _szLine, "DENIED - not authorised" );
            return;
        };

        local _szCommand = ( _arrTokens.len() > 1 ) ? _arrTokens[1] : "help";
        local _arrArgs   = ( _arrTokens.len() > 2 ) ? _arrTokens.slice( 2 ) : [];

        this.Dispatch( _hPlayer, _szCommand, _arrArgs, _szSteamID, _szLine );
        return;
    },
};

ZIDebug.RegisterCommand( CZIDebugCommand(
    "help",
    "list the debug commands",
    "", 0, 0,
    function( _hPlayer, _arrArgs )
    {
        ZIDebug.Reply( _hPlayer, ( GAMEMODE_NAME + " " + VERSION + " - debug console" ) );

        foreach ( _szName in ZIDebug.m_arrOrder )
        {
            local _hCommand = ZIDebug.m_tblCommands[ _szName ];

            ZIDebug.Reply( _hPlayer, ( "  " + _hCommand.GetUsageString() + "  -  " + _hCommand.GetDesc() ) );
        };

        return true;
    } ).AddAlias( "?" ) );

ZIDebug.RegisterCommand( CZIDebugCommand(
    "debug",
    "read or set debug mode",
    "[level]", 0, 1,
    function( _hPlayer, _arrArgs )
    {
        if ( _arrArgs.len() < 1 )
        {
            ZIDebug.SetDebugMode( DEBUG_MODE ? 0 : ZI_DEBUG_DEFAULT_LEVEL );
            return true;
        };

        if ( !ZIDebugIsAllDigits( _arrArgs[0] ) )
        {
            ZIDebug.Reply( _hPlayer, "level must be a whole number, 0 = off", true );
            return false;
        };

        ZIDebug.SetDebugMode( _arrArgs[0].tointeger() );
        return true;
    } ) );

ZIDebug.RegisterCommand( CZIDebugCmd_Toggle() );

ZIDebug.RegisterCommand( CZIDebugCommand(
    "whoami",
    "print your steamid and permit entry",
    "", 0, 0,
    function( _hPlayer, _arrArgs )
    {
        local _szRaw   = ZIDebugGetSteamID( _hPlayer );
        local _szID    = ( _szRaw == null ) ? "<unreadable>" : _szRaw;
        local _szKey   = ( _szRaw == null ) ? "" : _szRaw.toupper();
        local _szLabel = ( _szKey in ZIDebug.m_tblAuthorized )
                         ? ZIDebug.m_tblAuthorized[ _szKey ]
                         : "<not in the permit table>";

        printl( ZI_DEBUG_CONSOLE_TAG + "steamid " + _szID );

        ZIDebug.Reply( _hPlayer, ( "steamid  " + _szID ) );
        ZIDebug.Reply( _hPlayer, ( "permit   " + _szLabel ) );
        return true;
    } ) );

ZIDebug.RegisterCommand( CZIDebugCommand(
    "players",
    "list connected players and their steamids",
    "", 0, 0,
    function( _hPlayer, _arrArgs )
    {
        ZIDebug.Reply( _hPlayer, "players (see console for the full list):" );

        for ( local _i = 1; _i <= MaxPlayers; _i++ )
        {
            local _hNext = PlayerInstanceFromIndex( _i );

            if ( _hNext == null || !_hNext.IsValid() )
                continue;

            local _szID  = ZIDebugGetSteamID( _hNext );
            local _szRow = format( "  %-24s team %d  %s",
                                   NetName( _hNext ),
                                   _hNext.GetTeam(),
                                   ( _szID == null ) ? "<no steamid>" : _szID );

            printl( ZI_DEBUG_CONSOLE_TAG + _szRow );
            ZIDebug.Reply( _hPlayer, _szRow );
        };

        return true;
    } ) );

ZIDebug.RegisterCommand( CZIDebugCommand(
    "log",
    "dump the recent command audit log to console",
    "[count]", 0, 1,
    function( _hPlayer, _arrArgs )
    {
        local _iCount = ZI_DEBUG_LOG_MAX;

        if ( _arrArgs.len() > 0 && ZIDebugIsAllDigits( _arrArgs[0] ) )
            _iCount = _arrArgs[0].tointeger();

        local _iStart = ZIDebug.m_arrLog.len() - _iCount;

        if ( _iStart < 0 )
            _iStart = 0;

        printl( ZI_DEBUG_CONSOLE_TAG + "---- audit log ----" );

        for ( local _i = _iStart; _i < ZIDebug.m_arrLog.len(); _i++ )
        {
            local _tblEntry = ZIDebug.m_arrLog[ _i ];

            printl( format( "%s%.2f  %s (%s)  \"%s\"  -> %s",
                            ZI_DEBUG_CONSOLE_TAG,
                            _tblEntry.time, _tblEntry.name, _tblEntry.steamid,
                            _tblEntry.line, _tblEntry.result ) );
        };

        printl( ZI_DEBUG_CONSOLE_TAG + "---- " + ZIDebug.m_arrLog.len() + " entries held ----" );

        ZIDebug.Reply( _hPlayer, ( ZIDebug.m_arrLog.len() + " entries written to console" ) );
        return true;
    } ) );

ZIDebug.RegisterCommand( CZIDebugCommand(
    "human",
    "put yourself back on the survivor team",
    "", 0, 0,
    function( _hPlayer, _arrArgs )
    {
        _hPlayer.RemoveCustomAttribute( "hidden maxhealth non buffed" );

        _hPlayer.RemovePlayerWearables();
        _hPlayer.ClearZombieEntities();

        _hPlayer.ForceChangeTeam ( TF_TEAM_RED, true );
        _hPlayer.SetHealth       ( _hPlayer.GetMaxHealth() );

        _hPlayer.MakeHuman();
        _hPlayer.ClearZombieEntities();
        _hPlayer.ResetInfectionVars();

        _hPlayer.SetHealth( _hPlayer.GetMaxHealth() );
        _hPlayer.ForceRegenerateAndRespawn();
        return true;
    } ).RequireDebugMode() );

ZIDebug.RegisterCommand( CZIDebugCommand(
    "zombie",
    "turn yourself into a zombie",
    "", 0, 0,
    function( _hPlayer, _arrArgs )
    {
        local _sc = _hPlayer.GetScriptScope();

        _hPlayer.ForceChangeTeam( TF_TEAM_BLUE, true );
        _sc.m_iFlags <- ( _sc.m_iFlags | ZBIT_PENDING_ZOMBIE );

        _hPlayer.RemovePlayerWearables();
        _hPlayer.GiveZombieCosmetics();
        _hPlayer.GiveZombieFXWearable();

        _hPlayer.SetHealth      ( _hPlayer.GetMaxHealth() );
        _hPlayer.SetNextActTime ( ZOMBIE_BECOME_ZOMBIE, 1 );
        return true;
    } ).RequireDebugMode().RequireAlive() );

ZIDebug.RegisterCommand( CZIDebugCommand(
    "noclip",
    "toggle noclip on yourself",
    "", 0, 0,
    function( _hPlayer, _arrArgs )
    {
        if ( _hPlayer.GetMoveType() == MOVETYPE_NOCLIP )
        {
            _hPlayer.SetMoveType( MOVETYPE_WALK, 0 );
            ZIDebug.Reply( _hPlayer, "noclip OFF" );
        }
        else
        {
            _hPlayer.SetMoveType( MOVETYPE_NOCLIP, 0 );
            ZIDebug.Reply( _hPlayer, "noclip ON" );
        };

        return true;
    } ).RequireDebugMode().RequireAlive() );

ZIDebug.RegisterCommand( CZIDebugCommand(
    "bodyseqlist",
    "dump your spawn stand-in's sequence names to console",
    "[max]", 0, 1,
    function( _hPlayer, _arrArgs )
    {
        local _sc = _hPlayer.GetScriptScope();

        if ( !( "m_hSpawnBody" in _sc ) || _sc.m_hSpawnBody == null || !_sc.m_hSpawnBody.IsValid() )
        {
            ZIDebug.Reply( _hPlayer, "no spawn stand-in right now - one only exists during the rise or a rock throw windup", true );
            return false;
        };

        local _hBody  = _sc.m_hSpawnBody;
        local _iMax   = ( _arrArgs.len() > 0 && ZIDebugIsAllDigits( _arrArgs[0] ) )
                        ? _arrArgs[0].tointeger()
                        : SPAWN_BODY_SEQUENCE_SCAN_MAX;
        local _iFound = 0;

        printl( ZI_DEBUG_CONSOLE_TAG + "---- sequences on " + _hBody.GetModelName() + " ----" );

        for ( local _i = 0; _i < _iMax; _i++ )
        {
            local _szName = null;

            try
            {
                _szName = _hBody.GetSequenceName( _i );
            }
            catch ( _e )
            {
                ZIDebug.Reply( _hPlayer,
                               "GetSequenceName is missing on this build - step indices with \"" +
                               ZI_DEBUG_CMD_PREFIX + " bodyseq <n>\" instead", true );
                return false;
            };

            if ( _szName == null || typeof( _szName ) != "string" || _szName.tolower() == "unknown" )
                break;

            printl( format( "%s  [%3d] %s", ZI_DEBUG_CONSOLE_TAG, _i, _szName ) );
            _iFound++;
        };

        printl( ZI_DEBUG_CONSOLE_TAG + "---- " + _iFound + " sequences ----" );

        ZIDebug.Reply( _hPlayer, ( _iFound + " sequences written to console" ) );
        return true;
    } ).RequireDebugMode() );

ZIDebug.RegisterCommand( CZIDebugCommand(
    "bodyseq",
    "play a sequence on your spawn stand-in",
    "<name|index>", 1, 1,
    function( _hPlayer, _arrArgs )
    {
        local _sc = _hPlayer.GetScriptScope();

        if ( !( "m_hSpawnBody" in _sc ) || _sc.m_hSpawnBody == null || !_sc.m_hSpawnBody.IsValid() )
        {
            ZIDebug.Reply( _hPlayer, "no spawn stand-in right now - one only exists during the rise or a rock throw windup", true );
            return false;
        };

        local _hBody = _sc.m_hSpawnBody;
        local _iSeq  = ZIDebugIsAllDigits( _arrArgs[0] )
                       ? _arrArgs[0].tointeger()
                       : _hBody.LookupSequence( _arrArgs[0] );

        if ( _iSeq < 0 )
        {
            ZIDebug.Reply( _hPlayer, ( "no sequence \"" + _arrArgs[0] + "\" on " + _hBody.GetModelName() ), true );
            return false;
        };

        _hPlayer.PlaySpawnBodySequence( _iSeq, 1.0, true );

        ZIDebug.Reply( _hPlayer, ( "playing sequence " + _iSeq + " (holds on its last frame)" ) );
        return true;
    } ).RequireDebugMode() );

ZIDebug.RegisterCommand( CZIDebugCommand(
    "holdspawn",
    "stop the spawn picker auto-confirming so you can test poses",
    "[seconds]", 0, 1,
    function( _hPlayer, _arrArgs )
    {
        local _sc = _hPlayer.GetScriptScope();

        if ( !( "m_iFlags" in _sc ) || !( _sc.m_iFlags & ZBIT_IN_SPAWN_PICKER ) )
        {
            ZIDebug.Reply( _hPlayer, "not in the spawn picker", true );
            return false;
        };

        local _flHold = ( _arrArgs.len() > 0 && ZIDebugIsAllDigits( _arrArgs[0] ) )
                        ? _arrArgs[0].tointeger()
                        : ZI_DEBUG_HOLD_SPAWN_TIME;

        _hPlayer.SetNextActTime( ZOMBIE_AUTO_CONFIRM_SPAWN, _flHold );

        ZIDebug.Reply( _hPlayer, ( "auto-confirm pushed out " + _flHold + "s - jump when you're done" ) );
        return true;
    } ).RequireDebugMode() );

ZIDebug.RegisterCommand( CZIDebugCommand(
    "beacon",
    "drop a test beacon just ahead of you - full settle/build/boss flow, you own it",
    "", 0, 0,
    function( _hPlayer, _arrArgs )
    {
        local _vecFwd = _hPlayer.EyeAngles().Forward();
        local _vecPos = ( _hPlayer.EyePosition() + ( _vecFwd * 96 ) );

        local _tblTrace =
        {
            start   =  _hPlayer.EyePosition(),
            end     =  _vecPos,
            ignore  =  _hPlayer,
        };

        TraceLineEx( _tblTrace );

        if ( _tblTrace.hit && ( "pos" in _tblTrace ) )
            _vecPos = ( _tblTrace.pos - ( _vecFwd * 24 ) );

        local _sc = _hPlayer.GetScriptScope();

        if ( ( "m_hOwnedBeacon" in _sc ) && _sc.m_hOwnedBeacon != null &&
             _sc.m_hOwnedBeacon.IsValid() )
        {
            _sc.m_hOwnedBeacon.GetScriptScope().m_bMustDie <- true;
        };

        local _hShell = Entities.CreateByClassname( "prop_physics_override" );

        _hShell.SetModel  ( MDL_WORLD_MODEL_ENGIE_NADE );
        _hShell.SetOrigin ( _vecPos );

        _hShell.SetModelScale ( 1.4, 0.0 );
        _hShell.SetSize       ( _hShell.GetBoundingMins(), _hShell.GetBoundingMaxs() );

        SetPropInt ( _hShell, "m_CollisionGroup", COLLISION_GROUP_PROJECTILE );
        SetPropInt ( _hShell, "m_takedamage", 1 );
        _hShell.KeyValueFromString ( "targetname", "engie_beacon_physprop" );

        _hShell.DispatchSpawn();

        SetPropInt ( _hShell, "m_fEffects", EF_NODRAW );

        local _hVisual = Entities.CreateByClassname( "prop_dynamic_override" );

        _hVisual.SetModel  ( MDL_ENGIE_BEACON_TOOLBOX );
        _hVisual.SetOrigin ( _vecPos );

        _hVisual.KeyValueFromString ( "targetname", "engie_beacon_fx" );
        _hVisual.KeyValueFromString ( "solid", "0" );

        _hVisual.DispatchSpawn();

        SetPropInt ( _hVisual, "m_nSkin", ENGIE_BEACON_SKIN );

        EntFireByHandle ( _hVisual, "SetParent", "!activator", 0, _hShell, _hShell );

        _hShell.ValidateScriptScope();

        local _bsc = _hShell.GetScriptScope();

        _bsc.m_fTimeStart    <-  ( Time() ).tofloat();
        _bsc.m_fBuiltTime    <-  0.0;
        _bsc.m_flKillMeTime  <-  ( Time() + ENGIE_BEACON_LIFETIME ).tofloat();
        _bsc.m_flDestroyTime <-  0.0;
        _bsc.m_vecTraceFrom  <-  Vector( _vecPos.x, _vecPos.y, _vecPos.z );
        _bsc.m_hOwner        <-  _hPlayer;
        _bsc.m_iHealth       <-  ENGIE_BEACON_HEALTH;
        _bsc.m_bSettled      <-  false;
        _bsc.m_bBuilt        <-  false;
        _bsc.m_bMustDie      <-  false;
        _bsc.m_hVisual       <-  _hVisual;
        _bsc.m_hRespawnRoom  <-  null;
        _bsc.m_hBeaconFX     <-  null;

        _sc.m_hOwnedBeacon <- _hShell;

        AddThinkToEnt( _hShell, "BeaconThink" );

        ZIDebug.Reply( _hPlayer, "test beacon dropped - it settles, builds and becomes the base_boss tele" );
        return true;
    } ).AddAlias( "tp" ).RequireDebugMode().RequireAlive() );

ZIDebug.RegisterCommand( CZIDebugCommand(
    "tar",
    "drop a tar glob a few units ahead of you, splat facing you - you own it",
    "[dist|hit]", 0, 1,
    function( _hPlayer, _arrArgs )
    {
        if ( _arrArgs.len() > 0 && _arrArgs[0].tolower() == "hit" )
        {
            _hPlayer.ApplyTarDebuff( _hPlayer, true );
            ZIDebug.Reply( _hPlayer, "direct-hit tar debuff applied - drain ticks until it expires" );
            return true;
        };

        local _flDist = ( _arrArgs.len() > 0 && ZIDebugIsAllDigits( _arrArgs[0] ) )
                        ? _arrArgs[0].tofloat()
                        : 96.0;

        local _vecFwd = _hPlayer.EyeAngles().Forward();
        local _vecPos = ( _hPlayer.EyePosition() + ( _vecFwd * _flDist ) );

        local _tblTrace =
        {
            start   =  _hPlayer.EyePosition(),
            end     =  _vecPos,
            ignore  =  _hPlayer,
        };

        TraceLineEx( _tblTrace );

        if ( _tblTrace.hit && ( "pos" in _tblTrace ) )
            _vecPos = ( _tblTrace.pos - ( _vecFwd * 24 ) );

        local _vecDir = Vector( -_vecFwd.x, -_vecFwd.y, 0.0 );
        local _flLen  = _vecDir.Length();

        if ( _flLen < 0.001 )
            _vecDir = Vector( 1, 0, 0 );
        else
            _vecDir = Vector( ( _vecDir.x / _flLen ), ( _vecDir.y / _flLen ), 0.0 );

        local _hGlobEnt = Entities.CreateByClassname( "prop_physics_override" );

        _hGlobEnt.SetModel  ( MDL_WORLD_MODEL_ENGIE_NADE );
        _hGlobEnt.SetOrigin ( _vecPos );

        SetPropInt ( _hGlobEnt, "m_nRenderMode", kRenderTransColor );
        SetPropInt ( _hGlobEnt, "m_clrRender", 0 );
        SetPropInt ( _hGlobEnt, "m_CollisionGroup", COLLISION_GROUP_DEBRIS );

        local _hPfxEnt = SpawnEntityFromTable( "info_particle_system",
        {
            effect_name  = FX_TAR_TRAIL,
            start_active = "1",
            origin       = _vecPos
        } );

        EntFireByHandle( _hPfxEnt, "SetParent", "!activator", 0, _hGlobEnt, _hGlobEnt );

        _hGlobEnt.DispatchSpawn   ();
        _hGlobEnt.SetPhysVelocity ( Vector( 0, 0, -50 ) );

        _hGlobEnt.ValidateScriptScope();

        local _bsc = _hGlobEnt.GetScriptScope();

        _bsc.m_hOwner            <-  _hPlayer;
        _bsc.m_hPfx              <-  _hPfxEnt;
        _bsc.m_iState            <-  PYRO_TAR_STATE_IN_TRANSIT;
        _bsc.m_flKillMeTime      <-  ( Time() + PYRO_TAR_GLOB_LIFETIME ).tofloat();
        _bsc.m_fZoneEndTime      <-  0.0;
        _bsc.m_vecHitPosition    <-  Vector( 0, 0, 0 );
        _bsc.m_iDistanceToGround <-  0;
        _bsc.m_vecTarDir         <-  _vecDir;
        _bsc.m_tblSplat          <-  null;
        _bsc.m_bCanHitOwner      <-  true; // walking into this glob direct-hits you

        AddThinkToEnt( _hGlobEnt, "PyroTarGlobThink" );

        ZIDebug.Reply( _hPlayer, "tar glob dropped " + _flDist.tointeger() + " units ahead - stand in the goop to test the debuff" );
        return true;
    } ).AddAlias( "splat" ).RequireDebugMode().RequireAlive() );

ZIDebug.BuildAuthTable();

printl( ZI_DEBUG_CONSOLE_TAG + "loaded - " + ZIDebug.m_arrOrder.len() + " commands, " +
        ZIDebug.m_tblAuthorized.len() + " authorised steamid(s)" );
