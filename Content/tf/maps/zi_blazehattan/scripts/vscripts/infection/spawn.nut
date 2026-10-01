// --------------------------------------------------------------------------------------- //
// Zombie Infection                                                                        //
// --------------------------------------------------------------------------------------- //
// All Code By: netmuck (https://steamcommunity.com/profiles/76561198025795825)            //
// Assets/Game Design by: Diva Dan (https://steamcommunity.com/profiles/76561198072146551) //
// --------------------------------------------------------------------------------------- //
// spawn picker                                                                            //
// --------------------------------------------------------------------------------------- //
// a respawning zombie is frozen in third person while it cycles spawn points with        //
// LMB/RMB and confirms with jump. confirming starts the rise out of the ground, and       //
// only when that finishes is the zombie released into first person play.                  //
// --------------------------------------------------------------------------------------- //

// every BLU info_player_teamspawn, sorted by entity index. rebuilt each round
::arrZombieSpawnPoints <- [];

// gather all BLU map spawn points (mirrors the iteration in payload_logic.nut)
BuildZombieSpawnPointArray <- function()
{
    ::arrZombieSpawnPoints.clear();

    local _hSpawn = null;
    while ( _hSpawn = Entities.FindByClassname( _hSpawn, "info_player_teamspawn" ) )
    {
        if ( _hSpawn != null && _hSpawn.GetTeam() == TF_TEAM_BLUE )
            ::arrZombieSpawnPoints.append( _hSpawn );
    };

    ::arrZombieSpawnPoints.sort( function( a, b )
    {
        return a.entindex() - b.entindex();
    } );

    return;
};

// one flat queue - built beacons first, then map spawns

// every currently-built, still-alive engineer beacon, in build order
BuildPickerBeaconList <- function()
{
    local _list = [];

    foreach ( _hBeacon in ::arrZombieBeacons )
    {
        if ( _hBeacon != null && _hBeacon.IsValid() )
            _list.append( _hBeacon );
    };

    return _list;
};

// BLU map spawns, minus any payload_logic has disabled
BuildPickerMapSpawnList <- function()
{
    local _list = [];

    foreach ( _hSpawn in ::arrZombieSpawnPoints )
    {
        if ( _hSpawn == null || !_hSpawn.IsValid() )
            continue;

        if ( ::bIsPayload )
        {
            // guarded read - if the prop isn't exposed we include the spawn anyway
            local _bDisabled = false;
            try { _bDisabled = GetPropBool( _hSpawn, "m_bDisabled" ); } catch ( e ) {}

            if ( _bDisabled )
                continue;
        };

        _list.append( _hSpawn );
    };

    return _list;
};

// the combined queue the picking zombie actually cycles through
BuildPickerSpawnList <- function()
{
    local _list = BuildPickerBeaconList();

    _list.extend( BuildPickerMapSpawnList() );

    return _list;
};

// --------------------------------------------------------------------------------------- //
// spawn body - the stand-in model for the picker preview and the emerge                    //
// --------------------------------------------------------------------------------------- //
// for the picker and the rise the real player is alpha'd out and a prop_dynamic wearing
// the same model stands in for it. the player is still what moves and what the camera is
// anchored to - the split just means the stand-in can be posed and buried freely.

// stash an entity's render state the first time we hide it, then alpha it out. keyed by
// entindex, handle checked too so a reused index re-stashes instead of inheriting
CTFPlayer_StashAndHideRender <- function( _hEnt )
{
    local _sc  = this.GetScriptScope();
    local _idx = _hEnt.entindex();

    if ( !( _idx in _sc.m_tblSpawnBodyRender ) || _sc.m_tblSpawnBodyRender[ _idx ].ent != _hEnt )
    {
        local _iMode    = kRenderNormal;
        local _iColor   = 0xFFFFFFFF;
        local _iEffects = 0;

        try
        {
            _iMode    = GetPropInt( _hEnt, "m_nRenderMode" );
            _iColor   = GetPropInt( _hEnt, "m_clrRender" );
            _iEffects = GetPropInt( _hEnt, "m_fEffects" );
        }
        catch ( _e )
        {
            ZIDebug.Warn( "spawn body could not read render state off " + _hEnt.GetClassname() );
        };

        _sc.m_tblSpawnBodyRender[ _idx ] <- { ent = _hEnt, mode = _iMode, color = _iColor,
                                              effects = _iEffects };
    };

    // EF_NODRAW is what actually hides it - alpha alone leaves a half-visible player
    if ( SPAWN_BODY_USE_NODRAW )
        SetPropInt ( _hEnt, "m_fEffects", ( GetPropInt( _hEnt, "m_fEffects" ) | EF_NODRAW ) );

    SetPropInt ( _hEnt, "m_nRenderMode", kRenderTransAlpha );
    SetPropInt ( _hEnt, "m_clrRender",   SPAWN_BODY_HIDDEN_ALPHA );
    return;
};

CTFPlayer_RestoreSpawnBodyRender <- function()
{
    local _sc = this.GetScriptScope();

    if ( ( "m_tblSpawnBodyRender" in _sc ) && _sc.m_tblSpawnBodyRender != null )
    {
        foreach ( _idx, _tblSaved in _sc.m_tblSpawnBodyRender )
        {
            if ( _tblSaved.ent == null || !_tblSaved.ent.IsValid() )
                continue;

            SetPropInt ( _tblSaved.ent, "m_nRenderMode", _tblSaved.mode );
            SetPropInt ( _tblSaved.ent, "m_clrRender",   _tblSaved.color );
            SetPropInt ( _tblSaved.ent, "m_fEffects",    _tblSaved.effects );
        };
    };

    _sc.m_tblSpawnBodyRender <- {};
    return;
};

// hide/show the real player, weapons and wearables included - they don't inherit the
// player's render mode. the restore replays each entity's own saved state, since plenty
// of them are deliberately not opaque
CTFPlayer_SetSpawnBodyHidden <- function( _bHidden, _bIncludeWearables = true )
{
    local _sc = this.GetScriptScope();

    if ( !( "m_tblSpawnBodyRender" in _sc ) || _sc.m_tblSpawnBodyRender == null )
        _sc.m_tblSpawnBodyRender <- {};

    if ( !_bHidden )
    {
        this.RestoreSpawnBodyRender();
        return;
    };

    this.StashAndHideRender( this );

    for ( local i = 0; i < TF_WEAPON_COUNT; i++ )
    {
        local _hWeapon = GetPropEntityArray( this, "m_hMyWeapons", i );

        if ( _hWeapon == null || !_hWeapon.IsValid() )
            continue;

        this.StashAndHideRender( _hWeapon );
    };

    if ( !_bIncludeWearables )
        return;

    local _hWearable = null;

    while ( _hWearable = Entities.FindByClassname( _hWearable, "tf_wearable*" ) )
    {
        if ( _hWearable == null || _hWearable.GetOwner() != this )
            continue;

        this.StashAndHideRender( _hWearable );
    };

    return;
};

// find the first sequence whose name contains _szNeedle. GetSequenceName isn't on every
// build, so a throw means "no scan available" rather than an error
SpawnBodyFindSequenceNamed <- function( _hBody, _szNeedle )
{
    if ( _hBody == null || !_hBody.IsValid() || _szNeedle.len() < 1 )
        return -1;

    for ( local _i = 0; _i < SPAWN_BODY_SEQUENCE_SCAN_MAX; _i++ )
    {
        local _szName = null;

        try { _szName = _hBody.GetSequenceName( _i ); } catch ( _e ) { return -1; };

        if ( _szName == null || typeof( _szName ) != "string" || _szName.len() < 1 )
            continue;

        // source hands back "Unknown" once you walk off the end of the list
        if ( _szName.tolower() == "unknown" )
            return -1;

        if ( _szName.tolower().find( _szNeedle ) != null )
        {
            ZIDebug.Log( "[spawnbody] scan for \"" + _szNeedle + "\" matched \"" + _szName + "\" (" + _i + ")" );
            return _i;
        };
    };

    return -1;
};

// play a resolved sequence on the stand-in. _bHold pins the last frame at the end
CTFPlayer_PlaySpawnBodySequence <- function( _iSeq, _flRate, _bHold )
{
    local _sc = this.GetScriptScope();

    if ( !( "m_hSpawnBody" in _sc ) || _sc.m_hSpawnBody == null || !_sc.m_hSpawnBody.IsValid() )
        return;

    local _hBody = _sc.m_hSpawnBody;

    _hBody.ResetSequence ( _iSeq );

    SetPropFloat ( _hBody, "m_flCycle",        0.0 );
    SetPropFloat ( _hBody, "m_flPlaybackRate", _flRate );

    _sc.m_iSpawnBodySequence   <- _iSeq;
    _sc.m_flSpawnBodyCycleLast <- 0.0;
    _sc.m_bSpawnBodyHold       <- _bHold;
    _sc.m_bSpawnBodyHeld       <- false;
    return;
};

// change the stand-in's playback rate without disturbing the sequence or the cycle it is
// sitting on. 0 freezes it where it stands, which is how a windup pose is held
CTFPlayer_SetSpawnBodyPlaybackRate <- function( _flRate )
{
    local _sc = this.GetScriptScope();

    if ( !( "m_hSpawnBody" in _sc ) || _sc.m_hSpawnBody == null || !_sc.m_hSpawnBody.IsValid() )
        return;

    SetPropFloat ( _sc.m_hSpawnBody, "m_flPlaybackRate", _flRate );
    return;
};

// prop_dynamic drops to its default animation when a one-shot ends, snapping the stand-in
// back to its bind pose - catch the end and freeze on the last frame instead. spotted two
// ways since either can happen first: the cycle wrapping, or m_nSequence being swapped
CTFPlayer_UpdateSpawnBodyAnim <- function()
{
    local _sc = this.GetScriptScope();

    if ( !( "m_hSpawnBody" in _sc ) || _sc.m_hSpawnBody == null || !_sc.m_hSpawnBody.IsValid() )
        return;

    if ( !( "m_bSpawnBodyHold" in _sc ) || !_sc.m_bSpawnBodyHold || _sc.m_bSpawnBodyHeld )
        return;

    local _hBody     = _sc.m_hSpawnBody;
    local _flCycle   = GetPropFloat ( _hBody, "m_flCycle" );
    local _bSwapped  = ( GetPropInt( _hBody, "m_nSequence" ) != _sc.m_iSpawnBodySequence );
    local _bWrapped  = ( ( _flCycle + SPAWN_BODY_CYCLE_EPSILON ) < _sc.m_flSpawnBodyCycleLast );

    if ( !_bSwapped && !_bWrapped )
    {
        _sc.m_flSpawnBodyCycleLast <- _flCycle;
        return;
    };

    // put our sequence back if it was swapped away, then pin the far end of it
    if ( _bSwapped )
        _hBody.ResetSequence( _sc.m_iSpawnBodySequence );

    SetPropFloat ( _hBody, "m_flCycle",        1.0 );
    SetPropFloat ( _hBody, "m_flPlaybackRate", 0.0 );

    _sc.m_flSpawnBodyCycleLast <- 1.0;
    _sc.m_bSpawnBodyHeld       <- true;

    ZIDebug.Log( "[spawnbody] sequence " + _sc.m_iSpawnBodySequence + " finished (" +
                 ( _bSwapped ? "swapped out" : "cycle wrapped" ) + ") - holding last frame" );
    return;
};

// resolve and play a sequence: configured name, fallbacks, name scan, idle list, then
// sequence 0 - a wrong-looking pose is a better failure than a t-pose
CTFPlayer_SetSpawnBodySequence <- function( _szWanted, _flRate, _arrFallbacks, _szScanFor = "", _bHold = false )
{
    local _sc = this.GetScriptScope();

    if ( !( "m_hSpawnBody" in _sc ) || _sc.m_hSpawnBody == null || !_sc.m_hSpawnBody.IsValid() )
        return;

    local _hBody = _sc.m_hSpawnBody;
    local _iSeq  = -1;

    if ( _szWanted.len() > 0 )
        _iSeq = _hBody.LookupSequence( _szWanted );

    if ( _iSeq < 0 )
    {
        foreach ( _szFallback in _arrFallbacks )
        {
            _iSeq = _hBody.LookupSequence( _szFallback );

            if ( _iSeq >= 0 )
            {
                ZIDebug.Log( "[spawnbody] using fallback sequence \"" + _szFallback + "\" (" + _iSeq + ")" );
                break;
            };
        };
    };

    if ( _iSeq < 0 )
        _iSeq = SpawnBodyFindSequenceNamed( _hBody, _szScanFor );

    if ( _iSeq < 0 )
    {
        foreach ( _szFallback in arrSpawnBodyIdleFallbackSeqs )
        {
            _iSeq = _hBody.LookupSequence( _szFallback );

            if ( _iSeq >= 0 )
                break;
        };
    };

    if ( _iSeq < 0 )
    {
        ZIDebug.Log( "[spawnbody] no sequence resolved at all, settling for sequence 0" );
        _iSeq = 0;
    };

    this.PlaySpawnBodySequence( _iSeq, _flRate, _bHold );
    return;
};

// build the stand-in already playing _szSeq, replacing any existing one. the sequence is
// a parameter because the prop has to be born on its final animation - see DefaultAnim
CTFPlayer_CreateSpawnBody <- function( _szSeq, _arrFallbacks, _flRate = 1.0,
                                       _bHold = false, _szScanFor = "",
                                       _iSkin = SPAWN_BODY_SKIN )
{
    local _sc = this.GetScriptScope();

    this.DestroySpawnBody();

    local _hBody = Entities.CreateByClassname( SPAWN_BODY_CLASSNAME );

    if ( _hBody == null )
    {
        // no stand-in - unhide so the picker still shows the player something
        ZIDebug.Warn( "spawn body could not be created - showing the real player instead" );
        this.SetSpawnBodyHidden( false );
        return null;
    };

    _hBody.SetModel  ( szArrZombiePlayerModels[ this.GetPlayerClass() ] );
    _hBody.SetOrigin ( this.GetOrigin() );

    _hBody.KeyValueFromString ( "targetname", SPAWN_BODY_TARGETNAME );
    _hBody.KeyValueFromString ( "solid", "0" ); // never blocks a player or a trace

    // set before DispatchSpawn - an unconfigured prop spawns on sequence 0, and the client
    // receives it t-posed and visibly blends out of it. DefaultAnim avoids that
    if ( _szSeq.len() > 0 )
        _hBody.KeyValueFromString ( "DefaultAnim", _szSeq );

    _hBody.DispatchSpawn();

    SetPropInt ( _hBody, "m_nSkin",    _iSkin );
    SetPropInt ( _hBody, "m_iTeamNum", this.GetTeam() );

    _hBody.ValidateScriptScope();
    _hBody.GetScriptScope().m_hOwner <- this;

    _sc.m_hSpawnBody <- _hBody;

    // re-apply through the normal path so the fallback chain and hold bookkeeping run
    this.SetSpawnBodySequence ( _szSeq, _flRate, _arrFallbacks, _szScanFor, _bHold );
    this.SyncSpawnBody        ();

    // safety net for owners that leave the picker without running the teardown
    AddThinkToEnt ( _hBody, "SpawnBodyThink" );
    return _hBody;
};

// park the stand-in on the real player, yaw tracking their view. _vecOrigin overrides
// that - the rise passes one, since there the body climbs while the player waits above
CTFPlayer_SyncSpawnBody <- function( _vecOrigin = null )
{
    local _sc = this.GetScriptScope();

    if ( !( "m_hSpawnBody" in _sc ) || _sc.m_hSpawnBody == null || !_sc.m_hSpawnBody.IsValid() )
        return;

    local _angEye = this.EyeAngles();

    _sc.m_hSpawnBody.SetAbsOrigin ( ( _vecOrigin == null ) ? this.GetOrigin() : _vecOrigin );
    _sc.m_hSpawnBody.SetAbsAngles ( QAngle( 0, _angEye.y, 0 ) );
    return;
};

CTFPlayer_DestroySpawnBody <- function()
{
    local _sc = this.GetScriptScope();

    if ( ( "m_hSpawnBody" in _sc ) && _sc.m_hSpawnBody != null && _sc.m_hSpawnBody.IsValid() )
    {
        // drop the think first - one already queued still fires on the freed handle
        AddThinkToEnt ( _sc.m_hSpawnBody, null );

        _sc.m_hSpawnBody.Destroy();
    };

    _sc.m_hSpawnBody <- null;
    return;
};

// --------------------------------------------------------------------------------------- //
// player picker methods (attached to CTFPlayer/CTFBot at the bottom of this file)          //
// --------------------------------------------------------------------------------------- //

// push every held weapon's next-attack time out, so attack inputs only drive the picker
CTFPlayer_LockAllWeapons <- function()
{
    for ( local i = 0; i < TF_WEAPON_COUNT; i++ )
    {
        local _hWeapon = GetPropEntityArray( this, "m_hMyWeapons", i );

        if ( _hWeapon == null || !_hWeapon.IsValid() )
            continue;

        SetPropFloat( _hWeapon, "m_flNextPrimaryAttack",   FLT_MAX );
        SetPropFloat( _hWeapon, "m_flNextSecondaryAttack", FLT_MAX );
    };

    return;
};

CTFPlayer_EnterSpawnPicker <- function()
{
    local _sc = this.GetScriptScope();

    _sc.m_iFlags <- ( _sc.m_iFlags | ZBIT_IN_SPAWN_PICKER );

    this.SetForcedTauntCam ( 1 );
    this.LockInPlace       ( true );
    this.SetAbsVelocity    ( Vector( 0, 0, 0 ) );

    // "no_attack" alone doesn't stop an already-deployed weapon, so push the times out
    // too. SpawnPickerThink keeps the zombie weapon locked from there
    this.LockAllWeapons();

    this.AddCondEx ( TF_COND_INVULNERABLE_USER_BUFF, -1, this );
    this.AddCondEx ( TF_COND_TEAM_GLOWS, -1, null );

    // placeholder overlay (swap MAT_SPAWN_PICKER_OVERLAY for real art later)
    this.SetScriptOverlayMaterial ( MAT_SPAWN_PICKER_OVERLAY );

    // nothing renders at the previewed spawn - the player is hidden and no stand-in is
    // built until the rise, so cycling spawns doesn't advertise where a zombie is coming
    this.SetSpawnBodyHidden ( true );

    _sc.m_iSpawnIndex  <- 0;
    // seed last-buttons with the current state so a held attack isn't read as a fresh press
    _sc.m_iButtonsLast <- GetPropInt( this, "m_nButtons" );

    this.SetNextActTime ( ZOMBIE_CAN_CYCLE_SPAWN,    SPAWN_PICKER_INPUT_GRACE );
    this.SetNextActTime ( ZOMBIE_AUTO_CONFIRM_SPAWN, SPAWN_PICKER_AUTO_CONFIRM_TIME );

    this.CreateSpawnPickerHUD();

    this.TeleportToSpawnIndex( 0 );
    return;
};

// picker game_text pair - a static controls block and a countdown line re-sent each
// second. channels 3/5 are free, the ability HUD owns 2/4 and the tooltip owns 1
CTFPlayer_CreateSpawnPickerHUD <- function()
{
    local _sc = this.GetScriptScope();

    // newlines in the message work when set from script (only Hammer can't input them)
    local _hControlsText = SpawnEntityFromTable( "game_text",
    {
        x          =  -1, // centered
        y          =  SPAWN_PICKER_HUD_CONTROLS_Y,
        effect     =  0,
        color      =  "255 255 255",
        color2     =  "0 0 0",
        fadein     =  0.1,
        fadeout    =  0.1,
        holdtime   =  SPAWN_PICKER_AUTO_CONFIRM_TIME + 2, // outlive the longest possible pick
        fxtime     =  0,
        channel    =  3,
        message    =  STRING_UI_SPAWN_PICKER_CONTROLS,
        spawnflags =  0,
    });

    local _hCountdownText = SpawnEntityFromTable( "game_text",
    {
        x          =  -1, // centered
        y          =  SPAWN_PICKER_HUD_COUNTDOWN_Y,
        effect     =  0,
        color      =  "255 255 255",
        color2     =  "0 0 0",
        fadein     =  0,
        fadeout    =  0.1,
        holdtime   =  2, // refreshed every second while picking, so this only matters on leaks
        fxtime     =  0,
        channel    =  5,
        message    =  "",
        spawnflags =  0,
    });

    _sc.m_hSpawnPickerControlsText  <- _hControlsText;
    _sc.m_hSpawnPickerCountdownText <- _hCountdownText;
    _sc.m_iSpawnCountdownLast       <- -1; // force the first countdown re-send

    EntFireByHandle( _hControlsText, "Display", "", 0.0, this, this );
    return;
};

// blank both channels first - a sent HudMsg outlives its entity - then kill them
CTFPlayer_DestroySpawnPickerHUD <- function()
{
    local _sc = this.GetScriptScope();

    foreach ( _szHandle in [ "m_hSpawnPickerControlsText", "m_hSpawnPickerCountdownText" ] )
    {
        if ( !( _szHandle in _sc ) || _sc[ _szHandle ] == null || !_sc[ _szHandle ].IsValid() )
            continue;

        _sc[ _szHandle ].KeyValueFromString ( "message", "" );
        EntFireByHandle ( _sc[ _szHandle ], "Display", "",  0.0, this, this );
        EntFireByHandle ( _sc[ _szHandle ], "Kill",    "",  0.1, this, this );

        _sc[ _szHandle ] <- null;
    };

    return;
};

// teleport the picking player to the spawn entity at _idx in the picker queue.
CTFPlayer_TeleportToSpawnIndex <- function( _idx )
{
    local _list = BuildPickerSpawnList();

    if ( _list.len() == 0 )
        return false;

    if ( _idx < 0 || _idx >= _list.len() )
        _idx = 0;

    local _hSpawn = _list[ _idx ];

    if ( _hSpawn == null || !_hSpawn.IsValid() )
        return false;

    local _sc        = this.GetScriptScope();
    local _vecOrigin = _hSpawn.GetOrigin();
    local _angSpawn  = _hSpawn.GetAbsAngles();

    // confirming at a beacon grants a short spawn uber, see FinishSpawnEmerge
    _sc.m_bPreviewAtBeacon <- ( _hSpawn.GetClassname() != "info_player_teamspawn" );

    if ( _sc.m_bPreviewAtBeacon )
    {
        // lift clear of the beacon model, and keep only its yaw so the view isn't tilted
        _vecOrigin = _vecOrigin + Vector( 0, 0, 16 );
        _angSpawn  = QAngle( 0, _angSpawn.y, 0 );
    };

    this.SetAbsOrigin   ( _vecOrigin );
    this.SetAbsVelocity ( Vector( 0, 0, 0 ) );

    try { this.SnapEyeAngles( _angSpawn ); } catch ( e ) { this.SetAbsAngles( _angSpawn ); }

    return true;
};

// step the preview through the queue; _iDir is +1 (next) or -1 (previous)
CTFPlayer_CycleSpawnPreview <- function( _iDir )
{
    local _sc   = this.GetScriptScope();
    local _list = BuildPickerSpawnList();

    if ( _list.len() == 0 )
        return;

    // squirrel's % keeps the dividend's sign, so re-add len() to make the -1 wrap safe
    _sc.m_iSpawnIndex <- ( ( ( _sc.m_iSpawnIndex + _iDir ) % _list.len() ) + _list.len() ) % _list.len();
    this.TeleportToSpawnIndex( _sc.m_iSpawnIndex );
    return;
};
// tear down the picker state. called at the end of the emerge, not on confirm - the
// rise keeps the freeze, camera and invuln
CTFPlayer_ExitSpawnPicker <- function()
{
    local _sc = this.GetScriptScope();

    _sc.m_iFlags <- ( _sc.m_iFlags & ~ZBIT_IN_SPAWN_PICKER );

    this.SetForcedTauntCam ( 0 );
    this.LockInPlace       ( false );

    // LockInPlace(false) strips "move speed penalty" - put the zombie attribs back
    if ( _sc.m_iFlags & ZBIT_ZOMBIE )
        this.AddZombieAttribs();

    // release the attack lock. secondary stays locked - RMB is the ability cast
    if ( ( "m_hZombieWep" in _sc ) && _sc.m_hZombieWep != null && _sc.m_hZombieWep.IsValid() )
    {
        SetPropFloat( _sc.m_hZombieWep, "m_flNextPrimaryAttack",   Time() );
        SetPropFloat( _sc.m_hZombieWep, "m_flNextSecondaryAttack", FLT_MAX );
    };

    this.RemoveCond ( TF_COND_INVULNERABLE_USER_BUFF );
    // TF_COND_TEAM_GLOWS is re-applied by the zombie conversion, so we leave it on

    this.SetScriptOverlayMaterial ( "" );

    this.DestroySpawnBody   ();
    this.SetSpawnBodyHidden ( false );

    this.DestroySpawnPickerHUD();

    this.SetNextActTime ( ZOMBIE_CAN_CYCLE_SPAWN,    ACT_LOCKED );
    this.SetNextActTime ( ZOMBIE_AUTO_CONFIRM_SPAWN, ACT_LOCKED );
    return;
};

// lock in the previewed spawn and start the climb out of the ground
CTFPlayer_ConfirmSpawn <- function()
{
    local _sc = this.GetScriptScope();

    // the spawn cooldown clock starts here, not at conversion - manual confirm and the
    // auto-confirm timeout both come through this function
    if ( ( "m_hZombieAbility" in _sc ) && _sc.m_hZombieAbility != null &&
         _sc.m_hZombieAbility.m_fSpawnCooldown > 0 )
        this.SetNextActTime( ZOMBIE_ABILITY_CAST, _sc.m_hZombieAbility.m_fSpawnCooldown );

    this.TeleportToSpawnIndex ( _sc.m_iSpawnIndex );
    this.BeginSpawnEmerge     ();
    return;
};

// start the rise. the freeze, camera and invuln stay - only the picker's screen
// furniture and the translucent preview go away, so the choice visibly takes
CTFPlayer_BeginSpawnEmerge <- function()
{
    local _sc = this.GetScriptScope();

    _sc.m_iFlags <- ( ( _sc.m_iFlags & ~ZBIT_IN_SPAWN_PICKER ) | ZBIT_EMERGING_FROM_GROUND );

    this.DestroySpawnPickerHUD();
    this.SetScriptOverlayMaterial ( "" );

    this.SetNextActTime ( ZOMBIE_CAN_CYCLE_SPAWN,    ACT_LOCKED );
    this.SetNextActTime ( ZOMBIE_AUTO_CONFIRM_SPAWN, ACT_LOCKED );

    // only the stand-in is buried, which keeps the camera above the floor. copied
    // component-wise so the stored target can't track the player
    local _vecHere = this.GetOrigin();
    local _vecEnd  = Vector( _vecHere.x, _vecHere.y, _vecHere.z );

    _sc.m_vecEmergeEnd   <- _vecEnd;
    _sc.m_vecEmergeStart <- _vecEnd - Vector( 0, 0, SPAWN_EMERGE_SINK_DEPTH );

    // the picker runs with no stand-in at all, so the rise is where the body is born. it
    // keeps it from there to the end of the emerge. the sequence is per class - the same
    // name is a different animation on every model
    local _iClass   = this.GetPlayerClass();
    local _szRiseSeq = ( _iClass >= 0 && _iClass < szArrSpawnBodyRiseSeq.len() )
                       ? szArrSpawnBodyRiseSeq[ _iClass ]
                       : "";

    this.CreateSpawnBody( _szRiseSeq, arrSpawnBodyRiseFallbackSeqs,
                          SPAWN_BODY_RISE_RATE, true, SPAWN_BODY_RISE_SCAN_FOR );

    this.SetAbsVelocity ( Vector( 0, 0, 0 ) );

    // born at the player's feet - put it underground before the client ever sees it
    this.SyncSpawnBody  ( _sc.m_vecEmergeStart );

    local _hRiseSoundOn = ( ( "m_hSpawnBody" in _sc ) &&
                            _sc.m_hSpawnBody != null && _sc.m_hSpawnBody.IsValid() )
                          ? _sc.m_hSpawnBody
                          : this;

    EmitSoundOn ( SFX_ZOMBIE_EMERGE_RISE, _hRiseSoundOn );

    this.SetNextActTime ( ZOMBIE_FINISH_EMERGE, SPAWN_EMERGE_TIME );
    return;
};

// per-tick rise, driven from PlayerThink while ZBIT_EMERGING_FROM_GROUND is set
CTFPlayer_SpawnEmergeThink <- function()
{
    local _sc = this.GetScriptScope();

    this.SetForcedTauntCam  ( 1 );
    this.SetAbsVelocity     ( Vector( 0, 0, 0 ) );
    this.SetSpawnBodyHidden ( true, false );

    local _hActiveWeapon = this.GetActiveWeapon();

    if ( _hActiveWeapon != null )
    {
        SetPropFloat( _hActiveWeapon, "m_flNextPrimaryAttack",   FLT_MAX );
        SetPropFloat( _hActiveWeapon, "m_flNextSecondaryAttack", FLT_MAX );
    };

    local _fFrac = 1.0 - ( this.HowLongUntilAct( ZOMBIE_FINISH_EMERGE ) / SPAWN_EMERGE_TIME );

    if ( _fFrac < 0.0 ) _fFrac = 0.0;
    if ( _fFrac > 1.0 ) _fFrac = 1.0;

    if ( _fFrac >= 1.0 )
    {
        this.FinishSpawnEmerge();
        return;
    };

    // ease out so the zombie settles onto the spawn instead of popping to a stop
    local _fEased = 1.0 - ( ( 1.0 - _fFrac ) * ( 1.0 - _fFrac ) );

    this.SyncSpawnBody( _sc.m_vecEmergeStart + ( ( _sc.m_vecEmergeEnd - _sc.m_vecEmergeStart ) * _fEased ) );
    this.UpdateSpawnBodyAnim();
    return;
};

// fully out of the ground - release the (already converted) zombie into play.
CTFPlayer_FinishSpawnEmerge <- function()
{
    local _sc = this.GetScriptScope();

    _sc.m_iFlags <- ( _sc.m_iFlags & ~ZBIT_EMERGING_FROM_GROUND );

    this.SetAbsOrigin   ( _sc.m_vecEmergeEnd );
    this.SetAbsVelocity ( Vector( 0, 0, 0 ) );

    this.SetNextActTime ( ZOMBIE_FINISH_EMERGE, ACT_LOCKED );

    this.ExitSpawnPicker();

    // "no_jump" was just stripped, so a still-held jump would launch the player -
    // keep it suppressed for a beat
    this.AddCustomAttribute ( "no_jump", 1, SPAWN_PICKER_CONFIRM_NO_JUMP_TIME );

    // the conversion normally ran long before this, but if not, ZBIT_PENDING_ZOMBIE is
    // still set and the next think handles it
    if ( !( _sc.m_iFlags & ZBIT_ZOMBIE ) )
        return;

    this.PlayZombieVO();

    // beacon spawns get a moment of uber - applied after the picker's own invuln is gone
    if ( _sc.m_bPreviewAtBeacon )
        this.AddCondEx( TF_COND_INVULNERABLE_USER_BUFF, SPAWN_PICKER_BEACON_UBER_TIME, this );

    if ( this.GetPlayerClass() == TF_CLASS_SPY )
        this.AddCondEx( TF_COND_STEALTHED_USER_BUFF, -1, null );

    local _szAbilityTooltip = ( _sc.m_iCurrentAbilityType == ZABILITY_PASSIVE ) ?
                                STRING_UI_ZOMBIE_INSTRUCTION_PASSIVE :
                                STRING_UI_ZOMBIE_INSTRUCTION;

    local _hTooltip = this.ZombieInitialTooltip();

    _hTooltip.KeyValueFromString( "message", _szAbilityTooltip );

    EntFireByHandle ( _hTooltip, "Display", "", 0.0,  this, this );
    EntFireByHandle ( _hTooltip, "Kill",    "", 15.5, this, this );
    return;
};

// per-tick picker logic, driven from PlayerThink while ZBIT_IN_SPAWN_PICKER is set
CTFPlayer_SpawnPickerThink <- function()
{
    local _sc      = this.GetScriptScope();
    local _buttons = GetPropInt( this, "m_nButtons" );
    local _bReady  = this.CanDoAct( ZOMBIE_CAN_CYCLE_SPAWN );

    // the engine re-stamps these each tick. the hide is re-applied too, since the
    // conversion hands over a zombie weapon mid-picker at full opacity. there is no
    // stand-in during the picker, so there is nothing to sync or animate
    this.SetSpawnBodyHidden   ( true, false );
    this.SetAbsVelocity       ( Vector( 0, 0, 0 ) );

    // CTFPlayer::Spawn() zeroes m_nForceTauntCam after firing player_spawn, stomping the
    // cam set in EnterSpawnPicker. the client polls it every frame, so a late set works
    this.SetForcedTauntCam ( 1 );

    // the zombie model gets stomped the same way - re-assert it
    local _szZombieModel = szArrZombiePlayerModels[ this.GetPlayerClass() ];

    if ( GetPropString( this, "m_PlayerClass.m_iszCustomModel" ) != _szZombieModel )
        this.SetCustomModelWithClassAnimations( _szZombieModel );

    // LMB/RMB belong to the picker. also catches the weapon the conversion hands over
    local _hActiveWeapon = this.GetActiveWeapon();

    if ( _hActiveWeapon != null )
    {
        SetPropFloat( _hActiveWeapon, "m_flNextPrimaryAttack",   FLT_MAX );
        SetPropFloat( _hActiveWeapon, "m_flNextSecondaryAttack", FLT_MAX );
    };

    if ( this.CanDoAct( ZOMBIE_AUTO_CONFIRM_SPAWN ) )
    {
        this.ConfirmSpawn();
        _sc.m_iButtonsLast <- _buttons;
        return;
    };

    // auto-spawn countdown - only re-send the message when the displayed second changes
    local _iSecondsLeft = ceil( this.HowLongUntilAct( ZOMBIE_AUTO_CONFIRM_SPAWN ) ).tointeger();

    if ( _iSecondsLeft != _sc.m_iSpawnCountdownLast &&
         _sc.m_hSpawnPickerCountdownText != null && _sc.m_hSpawnPickerCountdownText.IsValid() )
    {
        _sc.m_iSpawnCountdownLast <- _iSecondsLeft;

        _sc.m_hSpawnPickerCountdownText.KeyValueFromString( "message", format( STRING_UI_SPAWN_PICKER_COUNTDOWN, _iSecondsLeft ) );
        EntFireByHandle( _sc.m_hSpawnPickerCountdownText, "Display", "", 0.0, this, this );
    };

    // jump rising edge - not gated on _bReady, confirming must respond instantly
    if ( ( _buttons & IN_JUMP ) && !( _sc.m_iButtonsLast & IN_JUMP ) )
    {
        this.ConfirmSpawn();
    }
    else if ( ( _buttons & IN_ATTACK ) && _bReady )
    {
        this.CycleSpawnPreview( 1 );
        this.SetNextActTime( ZOMBIE_CAN_CYCLE_SPAWN, SPAWN_PICKER_CYCLE_COOLDOWN );
    }
    else if ( ( _buttons & IN_ATTACK2 ) && _bReady )
    {
        // RMB - cycle backward, wrapping from the top to the bottom of the queue
        this.CycleSpawnPreview( -1 );
        this.SetNextActTime( ZOMBIE_CAN_CYCLE_SPAWN, SPAWN_PICKER_CYCLE_COOLDOWN );
    };

    _sc.m_iButtonsLast <- _buttons;
    return;
};

// --------------------------------------------------------------------------------------- //
// Attach the CTFPlayer_* helpers to CTFPlayer/CTFBot, mirroring functions.nut             //
// --------------------------------------------------------------------------------------- //

foreach ( key, value in this )
{
    if ( typeof( value ) == "function" && startswith( key, "CTFPlayer_" ) )
    {
        local func_name = key.slice(10);
        CTFPlayer[ func_name ] <- value;
        CTFBot[ func_name ] <- value;
        delete this[ key ];
    }
}
