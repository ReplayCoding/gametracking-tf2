// --------------------------------------------------------------------------------------- //
// Infection - Prototype v0.5.1 - Last Edited: 29/08/2023                                  //
// --------------------------------------------------------------------------------------- //
// Code By: Harry Colquhoun (https://steamcommunity.com/profiles/76561198025795825)        //
// Assets/Game Design by: Diva Dan (https://steamcommunity.com/profiles/76561198072146551) //
// --------------------------------------------------------------------------------------- //
// Infection specific player functions                                                     //
// these functions are added to the base player class                                      //
// usage: _playerHandle.<functionName>( _args );                                           //
// --------------------------------------------------------------------------------------- //

::CTFPlayer.GiveZombieAbility <- function()
{
    local _sc = this.GetScriptScope();

    _sc.m_hZombieAbility <- null;

    switch ( this.GetPlayerClass() )
    {
        case TF_CLASS_ENGINEER:
            _sc.m_hZombieAbility <- CEngineerSapperNade( this );
            break;
        case TF_CLASS_SNIPER:
            _sc.m_hZombieAbility <- CSniperSpitball( this );
            break;
        case TF_CLASS_SPY:
            _sc.m_hZombieAbility <- CSpyReveal( this );
            break;
        case TF_CLASS_MEDIC:
            _sc.m_hZombieAbility <- CMedicHeal( this );
            break;
        case TF_CLASS_HEAVYWEAPONS:
            _sc.m_hZombieAbility <- CHeavyPassive( this );
            break;
        case TF_CLASS_PYRO:
            _sc.m_hZombieAbility <- CPyroPassive( this );
            break;
        case TF_CLASS_SCOUT:
            _sc.m_hZombieAbility <- CScoutPassive( this );
            break;
        case TF_CLASS_DEMOMAN:
            _sc.m_hZombieAbility <- CDemoCharge( this );
            break;
        case TF_CLASS_SOLDIER:
            _sc.m_hZombieAbility <- CSoldierJump( this );
            break;
        default:
            _sc.m_hZombieAbility <- CMedicHeal( this );
            break;
    };

    _sc.m_iCurrentAbilityType <- _sc.m_hZombieAbility.GetAbilityType();
}

::CTFPlayer.RemovePlayerWearables <- function()
{

    local _wearable = null;
    while ( _wearable = Entities.FindByClassname( _wearable, "tf_wearable*" ) )
    {
        if ( _wearable.GetOwner() == this && _wearable != null )
        {
            _wearable.Destroy();
        };
    };

    return;
};

::CTFPlayer.SpawnEffect <- function()
{
    local _angPlayer     =  this.GetLocalAngles();
    local _vecAngPlayer  =  Vector( _angPlayer.x, _angPlayer.y, _angPlayer.z );

    EmitSoundOn            ( "Halloween.spell_lightning_cast",   this );
    EmitSoundOn            ( "Halloween.spell_lightning_impact", this );

    DispatchParticleEffect ( "zombie_spawn_parent", this.GetLocalOrigin(), _vecAngPlayer );
    return;
};

::CTFPlayer.GiveZombieCosmetics <- function()
{
    local _sc = this.GetScriptScope();

    SetPropBool ( this, "m_bForcedSkin ",      true );
    SetPropInt  ( this, "m_iPlayerSkinOverride",  1 );

    if ( _sc.m_hZombieWearable != null && _sc.m_hZombieWearable.IsValid() )
        _sc.m_hZombieWearable.Destroy();

    local _zombieCosmetic  =  Entities.CreateByClassname( "tf_wearable" );
    local _soulIDX         =  arrZombieCosmeticIDX[ this.GetPlayerClass() ];

    _zombieCosmetic.AddAttribute ( "player skin override", 1, -1 );
    Entities.DispatchSpawn       ( _zombieCosmetic );

    _zombieCosmetic.SetAbsOrigin ( this.GetLocalOrigin() );
    _zombieCosmetic.SetAbsAngles ( this.GetLocalAngles() );

    // Zombie Cosmetics NetProps // ------------------------------------------------------------------ //
    SetPropInt     ( _zombieCosmetic, "m_iTeamNum",                                     this.GetTeam() );
    SetPropInt     ( _zombieCosmetic, "m_AttributeManager.m_Item.m_iItemDefinitionIndex",     _soulIDX );
    SetPropBool    ( _zombieCosmetic, "m_bValidatedAttachedEntity",                               true );
    SetPropBool    ( _zombieCosmetic, "m_AttributeManager.m_Item.m_bInitialized",                 true );
    SetPropEntity  ( _zombieCosmetic, "m_hOwnerEntity",                                           this );
    SetPropInt     ( _zombieCosmetic, "m_Collision.m_usSolidFlags",                                  4 );
    SetPropInt     ( _zombieCosmetic, "m_nModelIndex", arrZombieCosmeticModel[ this.GetPlayerClass() ] );
    // ----------------------------------------------------------------------------------------------- //

    _zombieCosmetic.SetOwner( this );

    SetPropInt      ( _zombieCosmetic, "m_fEffects", ( EF_BONEMERGE | EF_BONEMERGE_FASTCULL ) );
    EntFireByHandle ( _zombieCosmetic, "SetParent",  "!activator", 0.0, this, this );

    _sc.m_hZombieWearable <- _zombieCosmetic;
    return;
};

::CTFPlayer.GiveZombieFXWearable <- function()
{
    local _sc = this.GetScriptScope();

    if ( _sc.m_hZombieFXWearable != null && _sc.m_hZombieFXWearable.IsValid() )
        _sc.m_hZombieFXWearable.Destroy();

    local _zombieFXWearable = Entities.CreateByClassname( "tf_wearable" );

    Entities.DispatchSpawn         ( _zombieFXWearable );
    _zombieFXWearable.SetAbsOrigin ( this.GetLocalOrigin() );
    _zombieFXWearable.SetAbsAngles ( this.GetLocalAngles() );

    // Zombie FX Wearable NetProps
    SetPropBool   ( _zombieFXWearable,  "m_bValidatedAttachedEntity", true );
    SetPropBool   ( _zombieFXWearable,  "m_AttributeManager.m_Item.m_bInitialized", true );
    SetPropEntity ( _zombieFXWearable,  "m_hOwnerEntity",  this );
    SetPropInt    ( _zombieFXWearable,  "m_Collision.m_usSolidFlags", 4 );
    SetPropInt    ( _zombieFXWearable,  "m_nModelIndex", arrZombieFXWearable[ this.GetPlayerClass() ] );

    _zombieFXWearable.SetOwner( this );

    SetPropInt      ( _zombieFXWearable, "m_fEffects", ( EF_BONEMERGE | EF_BONEMERGE_FASTCULL ) );
    EntFireByHandle ( _zombieFXWearable, "SetParent", "!activator", 0.0, this, this );

    _sc.m_hZombieFXWearable  <-  _zombieFXWearable;
    return;
}

::CTFPlayer.GiveZombieWeapon <- function()
{
    local _sc = this.GetScriptScope();

    if ( _sc.m_hZombieWep != null && _sc.m_hZombieWep.IsValid() )
        _sc.m_hZombieWep.Destroy();

    if ( _sc.m_hZombieArms != null && _sc.m_hZombieArms.IsValid() )
        _sc.m_hZombieArms.Destroy();

    local _playerClass  =  this.GetPlayerClass();
    local _hPlayerVM    =  GetPropEntity( this, "m_hViewModel" );
    local _zombieWep    =  Entities.CreateByClassname( ZOMBIE_WEAPON_CLASSNAME[ _playerClass ] );
    local _idx          =  ZOMBIE_WEAPON_IDX[ _playerClass ];

    SetPropInt  ( _zombieWep, "m_AttributeManager.m_Item.m_iItemDefinitionIndex",   _idx );
    SetPropBool ( _zombieWep, "m_AttributeManager.m_Item.m_bOnlyIterateItemViewAttributes", true );
    SetPropBool ( _zombieWep, "m_bValidatedAttachedEntity", true );

    foreach( _attrib in ZOMBIE_WEP_ATTRIBS[ 0 ] ) // default attribs
    {
        _zombieWep.AddAttribute( _attrib[ 0 ], _attrib[ 1 ], _attrib[ 2 ] );
    };

    foreach( _attrib in ZOMBIE_WEP_ATTRIBS[ _playerClass ] ) // class specific attribs
    {
        _zombieWep.AddAttribute( _attrib[ 0 ], _attrib[ 1 ], _attrib[ 2 ] );
    };

    _zombieWep.DispatchSpawn();

    this.Weapon_Equip( _zombieWep );

    local _zombieArms = Entities.CreateByClassname( "tf_wearable_vm" );

    _zombieArms.SetAbsOrigin  ( this.GetLocalOrigin() );
    _zombieArms.SetAbsAngles  ( this.GetLocalAngles() );
    _zombieArms.DispatchSpawn ();

    // Zombie Arm Viewmodel Netprops // ------------------------------------------------- //
    SetPropEntity ( _zombieArms, "m_hWeaponAssociatedWith",                    _zombieWep );
    SetPropInt    ( _zombieArms, "m_iViewModelIndex",  arrZombieArmVMPath[ _playerClass ] );
    SetPropInt    ( _zombieArms, "m_nModelIndex",      arrZombieArmVMPath[ _playerClass ] );
    SetPropBool   ( _zombieArms, "m_bValidatedAttachedEntity",                       true );
    SetPropBool   ( _zombieArms, "m_AttributeManager.m_Item.m_bInitialized",         true );
    SetPropEntity ( _zombieArms, "m_hOwnerEntity",                                   this );
    // ---------------------------------------------------------------------------------- //

    // Zombie Weapon Netprops // -------------------------------------------------------- //
    SetPropEntity ( _zombieWep,  "m_hExtraWearableViewModel",                 _zombieArms );
    SetPropInt    ( _zombieWep,  "m_iViewModelIndex",  arrZombieArmVMPath[ _playerClass ] );
    SetPropInt    ( _zombieWep,  "m_nModelIndex",      arrZombieArmVMPath[ _playerClass ] );
    SetPropInt    ( _zombieWep,  "m_nRenderMode",                       kRenderTransColor );
    SetPropInt    ( _zombieWep,  "m_clrRender",                                         0 );
    SetPropBool   ( _zombieWep,  "m_AttributeManager.m_Item.m_bInitialized",         true );
    SetPropEntity ( _zombieWep,  "m_hOwnerEntity",                                   this );
    // ---------------------------------------------------------------------------------- //

    this.EquipWearableViewModel( _zombieArms );

    _sc.m_hZombieWep  <- _zombieWep;
    _sc.m_hZombieArms <- _zombieArms;

    _hPlayerVM.SetModelSimple  ( arrZombieViewModelPath[ _playerClass ] );
    this.Weapon_Switch         ( _zombieWep );
    return;
}

::CTFPlayer.AddZombieAttribs <- function()
{
    local _iClassNum = this.GetPlayerClass();

    if ( ZOMBIE_PLAYER_CONDS[ 0 ].len() > 0 )
    {
        foreach ( _cond in ZOMBIE_PLAYER_CONDS[ 0 ] ) // default conds
        {
            this.AddCondEx( _cond, -1, null );
        };
    };

    if ( ZOMBIE_PLAYER_CONDS[ _iClassNum ].len() > 0 )
    {
        foreach ( _cond in ZOMBIE_PLAYER_CONDS[ _iClassNum ] )  // class specific conds
        {
            this.AddCondEx( _cond, -1, null );
        };
    };

    if ( ZOMBIE_PLAYER_ATTRIBS[ 0 ].len() > 1 )
    {
        foreach ( _attrib in ZOMBIE_PLAYER_ATTRIBS[ 0 ]  ) // default attribs
        {
            this.AddCustomAttribute( _attrib[ 0 ], _attrib[ 1 ], _attrib[ 2 ] );
        };
    };

    if ( ZOMBIE_PLAYER_ATTRIBS[ _iClassNum ].len() > 1 )
    {
        foreach ( _attrib in ZOMBIE_PLAYER_ATTRIBS[ _iClassNum ]  ) // class specific attribs
        {
            this.AddCustomAttribute( _attrib[ 0 ], _attrib[ 1 ], _attrib[ 2 ] );
        };
    };

    return;
}

::CTFPlayer.CanDoAct <- function( _iAct )
{
    local _sc   = this.GetScriptScope();
    local _temp = ACT_LOCKED;

    switch ( _iAct )
    {
        case ZOMBIE_ABILITY_CAST:
            _temp = _sc.m_fTimeNextCast;
            break;
        case ZOMBIE_TALK:
            _temp = _sc.m_fTimeNextTalk;
            break;
        case ZOMBIE_DO_ATTACK1:
            _temp = _sc.m_fTimeNextViewpunch;
            break;
        case ZOMBIE_BECOME_ZOMBIE:
            return true; // hack
            break;
        case ZOMBIE_BECOME_SURVIVOR:
            _temp = _sc.m_fTimeRemoveZombie;
            break;
        case ZOMBIE_NEXT_QUEUED_EVENT:
            _temp = _sc.m_fTimeNextQueuedEvent;
            break;
        case ZOMBIE_KILL_GLOW:
            _temp = _sc.m_fKillGlowTime;
            break;
        default:
            return false;
    };

    if ( _temp == ACT_LOCKED )
        return false;

    if ( _temp <= Time() )
    {
        return true;
    }
    else
    {
        return false;
    };
}

::CTFPlayer.ProcessEventQueue <- function()
{
    local _sc = this.GetScriptScope();

    if ( _sc.m_tblEventQueue.len() == 0 )
        return;

    local _nearestEvent    = null;
    local _nearestFireTime = null;

    foreach ( _event, _fireTime in _sc.m_tblEventQueue )
    {
        if ( _nearestEvent == null || _fireTime < _nearestFireTime )
        {
            _nearestEvent = _event;
            _nearestFireTime = _fireTime;
        };
    };

    if ( _nearestEvent && ( Time() > _nearestFireTime ) )
    {
        switch ( _nearestEvent )
        {
            case EVENT_SNIPER_SPITBALL:
                SetPropFloat( _sc.m_hZombieWep, "m_flNextPrimaryAttack", 0.0 );
                _sc.m_hZombieAbility.CreateSpitball();
                break;
            case EVENT_ENTER_SPY_REVEAL:
                _sc.m_hZombieAbility.CreateReveal();
                break;
            case EVENT_EXIT_SPY_REVEAL:
                SetPropFloat( _sc.m_hZombieWep, "m_flNextPrimaryAttack", 0.0 );
                _sc.m_hZombieAbility.ExitReveal();
                break;
            case EVENT_ENTER_MEDIC_HEAL:
                _sc.m_hZombieAbility.CreateHealEmitter();
                break;
            case EVENT_EXIT_MEDIC_HEAL:
                SetPropFloat( _sc.m_hZombieWep, "m_flNextPrimaryAttack", 0.0 );
                _sc.m_hZombieAbility.ExitHealEmitter();
                break;
            case EVENT_ENGIE_EXIT_MINIROOT:
                SetPropFloat( _sc.m_hZombieWep, "m_flNextPrimaryAttack", 0.0 );
                _sc.m_hZombieAbility.ExitRoot();
                break;
            case EVENT_ENGIE_THROW_NADE:
                _sc.m_hZombieAbility.ThrowNadeProjectile();
                break;
            case EVENT_DEMO_CHARGE_START:
                _sc.m_hZombieAbility.StartDemoCharge();
                break;
            case EVENT_DEMO_CHARGE_EXIT:
                SetPropFloat( _sc.m_hZombieWep, "m_flNextPrimaryAttack", 0.0 );
                _sc.m_hZombieAbility.ExitDemoCharge();
                break;
            case EVENT_PUT_ABILITY_ON_CD:
                SetPropFloat( _sc.m_hZombieWep, "m_flNextPrimaryAttack", 0.0 );
                _sc.m_hZombieAbility.PutAbilityOnCooldown();
                break;
            case EVENT_DOWNWARDS_VIEWPUNCH:
                local _angSecondViewPunch = QAngle( 3, 0, 0 );
                this.ViewPunch( _angSecondViewPunch );
                break;
            default:
                VScriptError( ERROR_BAD_EVENT_IN_QUEUE, ELVL_ERROR );
                _sc.m_tblEventQueue.rawdelete( _nearestEvent );
                return;
        };

        _sc.m_tblEventQueue.rawdelete( _nearestEvent );
    };

    return;
};

::CTFPlayer.RemoveEventFomQueue <- function( _event )
{
    local _sc = this.GetScriptScope();

    if ( _event == -1 )
    {
        _removedCount = _sc.m_tblEventQueue.len();
        _sc.m_tblEventQueue.clear();
    }
    else
    {
        while ( _sc.m_tblEventQueue.rawin( _event ) )
        {
            _sc.m_tblEventQueue.rawdelete( _event );
        };
    };

    return;
};

::CTFPlayer.AddEventToQueue <- function( _event, _delay )
{
    local _sc       = this.GetScriptScope();
    local _fireTime = ( Time() + _delay );

    if ( _sc.m_tblEventQueue.rawin( _event ) )
    {
        _sc.m_tblEventQueue[ _event ] = _fireTime;
    }
    else
    {
        _sc.m_tblEventQueue.rawset( _event, _fireTime );
    };

    return;
};

::CTFPlayer.ResetInfectionVars <- function()
{
    // not sure if we need to do this if we ARE the player?
    if ( !this.ValidateScriptScope() )
        return false;

    AddThinkToEnt( this, null );

    local _sc = this.GetScriptScope();

    _sc.m_iFlags               <- ZBIT_SURVIVOR;
    _sc.m_tblEventQueue        <- { };

    _sc.m_hZombieWep           <- null;
    _sc.m_hZombieArms          <- null;
    _sc.m_hZombieWearable      <- null;
    _sc.m_hZombieFXWearable    <- null;
    _sc.m_hZombieAbility       <- null;
    _sc.m_hTempEntity          <- null;

    _sc.m_fTimeNextCast        <- 0.0;
    _sc.m_fTimeNextTalk        <- 0.0;
    _sc.m_fTimeNextViewpunch   <- 0.0;
    _sc.m_fTimeRemoveZombie    <- 0.0;
    _sc.m_fTimeBecomeZombie    <- 0.0;
    _sc.m_fTimeNextQueuedEvent <- 0.0;
    _sc.m_fKillGlowTime        <- 0.0;
    _sc.m_fTimeRemoveHeal      <- 0.0;
    _sc.m_fTimeNextHealTick    <- 0.0;

    _sc.m_iCurrentAbilityType  <- 0;

    AddThinkToEnt( this, "PlayerThink" );
    return true;
};

::CTFPlayer.MakeHuman <- function()
{
    local _hPlayerVM = GetPropEntity( this, "m_hViewModel" );

    SetPropBool( this, "m_bForcedSkin ", false );
    _hPlayerVM.SetModelSimple( arrTFClassDefaultArmPath[ this.GetPlayerClass() ] );

    return;
};

::CTFPlayer.HowLongUntilAct <- function( _iAct )
{
    local _sc = this.GetScriptScope();

    switch ( _iAct )
    {
        case ZOMBIE_ABILITY_CAST:
            return ( _sc.m_fTimeNextCast      < 0 ? 0 : _sc.m_fTimeNextCast      - Time() );
        case ZOMBIE_TALK:
            return ( _sc.m_fTimeNextTalk      < 0 ? 0 : _sc.m_fTimeNextTalk      - Time() );
        case ZOMBIE_DO_ATTACK1:
            return ( _sc.m_fTimeNextViewpunch < 0 ? 0 : _sc.m_fTimeNextViewpunch - Time() );
        case ZOMBIE_BECOME_ZOMBIE:
            return ( _sc.m_fTimeBecomeZombie  < 0 ? 0 : _sc.m_fTimeBecomeZombie  - Time() );
        case ZOMBIE_BECOME_SURVIVOR:
            return ( _sc.m_fTimeRemoveZombie  < 0 ? 0 : _sc.m_fTimeRemoveZombie  - Time() );
        case ZOMBIE_KILL_GLOW:
            return ( _sc.m_fKillGlowTime      < 0 ? 0 : _sc.m_fKillGlowTime      - Time() );
        case ZOMBIE_REMOVE_HEALRING:
            return ( _sc.m_fTimeRemoveHeal    < 0 ? 0 : _sc.m_fKillGlowTime      - Time() );
        default:
            return false;
    };
};

::CTFPlayer.PlayZombieVO <- function()
{
    if ( this.CanPlayerDoAct( _playerID, ZOMBIE_TALK ) )
    {
        local _rand = RandomInt( 0, ZOMBIE_VOICE_SFX.len() );
        EmitSoundOn( ZOMBIE_VOICE_SFX[ _rand ], _d.m_hPlayer );
    };
};

::CTFPlayer.SetNextActTime <- function( _iAct, _fTime )
{
    local _sc = this.GetScriptScope();
    local _nextTime = ( _fTime == ACT_LOCKED ? ACT_LOCKED : ( Time() + _fTime ).tofloat() );

    switch ( _iAct )
    {
        case ZOMBIE_ABILITY_CAST:
            _sc.m_fTimeNextCast        <- ( _nextTime );
            break;
        case ZOMBIE_TALK:
            _sc.m_fTimeNextTalk        <- ( _nextTime );
            break;
        case ZOMBIE_DO_ATTACK1:
            SetPropFloat( _sc.m_hZombieWep, "m_flNextPrimaryAttack", _nextTime );
            _sc.m_fTimeNextViewpunch   <- ( _nextTime );
            break;
        case ZOMBIE_BECOME_ZOMBIE:
            _sc.m_fTimeBecomeZombie    <- ( _nextTime );
            break;
        case ZOMBIE_BECOME_SURVIVOR:
            _sc.m_fTimeRemoveZombie    <- ( _nextTime );
            break;
        case ZOMBIE_NEXT_QUEUED_EVENT:
            _sc.m_fTimeNextQueuedEvent <- ( _nextTime );
            break;
        case ZOMBIE_KILL_GLOW:
            _sc.m_fKillGlowTime        <- ( _nextTime );
            break;
        default:
            return false;
    };

    return;
};

::CTFPlayer.DestroyAllWeapons <- function()
{
    // local _tfwep = null;
    // while ( _tfwep = Entities.FindByClassname( _tfwep, "tf_weapon*" ) )
    // {
    //     if ( _tfwep.GetOwner() == this && _tfwep != null )
    //     {
    //         _tfwep.Destroy();
    //     };
    // };

    // for ( local i = 0; i < TF_WEAPON_COUNT; i++ )
    // {
    //     local _hNextWeapon = GetPropEntityArray( this, "m_hMyWeapons", i);

    //     if ( _hNextWeapon != null && _hNextWeapon != _sc.m_hZombieWep )
    //     {
    //         SetPropEntityArray( this, "m_hMyWeapons", null, i );
    //     };
    // };

    return;
}