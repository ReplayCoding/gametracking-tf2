// --------------------------------------------------------------------------------------- //
// Zombie Infection                                                                        //
// --------------------------------------------------------------------------------------- //
// All Code By: Harry Colquhoun (https://steamcommunity.com/profiles/76561198025795825)    //
// Assets/Game Design by: Diva Dan (https://steamcommunity.com/profiles/76561198072146551) //
// --------------------------------------------------------------------------------------- //
// utility functions                                                                       //
// --------------------------------------------------------------------------------------- //

PrecacheResources <- function()
{
    foreach ( _key, _value in getconsttable() )
    {
        if ( startswith( _key, "SFX" ) )
        {
            PrecacheSound( _value );
        }
        else if ( startswith( _key, "FX" ) )
        {
            PrecacheEntityFromTable( { classname = "info_particle_system", effect_name = _value } );
        }
        else if ( startswith( _key, "MDL" ) )
        {
            PrecacheModel( _value );
        };
    };

    return;
};

RoundUp <- function( _fValue ) {

    local _iPart = _fValue.tointeger();

    if( _fValue > _iPart )
    {
        return _iPart + 1;
    };

    return _iPart;
}

GetPlayerUserID <- function( _hPlayer )
{
    return ( GetPropIntArray( TFPlayerManager, "m_iUserID", _hPlayer.entindex() ) );
};

IsPlayerAlive <- function( _hPlayer )
{
    return ( GetPropInt( _hPlayer, "m_lifeState" ) == 0 );
};

PlayerCount <- function( _team = -1 )
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
            };
        };
    };

    return _playerCount;
};

PlayGlobalBell <- function( _bForce )
{
    if ( !_bForce && ( Time() - flTimeLastBell ) < 0.75 )
        return;

    local _tblSfxEvent =
    {
        team  = 255,
        sound = "Halloween.PlayerEscapedUnderworld"
    };

    SendGlobalGameEvent ( "teamplay_broadcast_audio", _tblSfxEvent );
    flTimeLastBell <- Time();
};

DemomanExplosionPreCheck <- function( _vecLocation, _flDmg, _flRange, _hInflictor, _iTeamnum = TF_TEAM_BLUE )
{
    local _buildableArr    =  [ ];
    local _buildable       =  null;
    local _buildableCount  =  0;

    while ( _buildable = Entities.FindByClassnameWithin( _buildable, "obj_*", _vecLocation, ( DEMOMAN_CHARGE_RADIUS ) ) )
    {
        if ( _buildable != null )
        {
            _buildableArr.append( _buildable );
            _buildableCount++;
        };

        if ( _buildableArr.len() >= 3 )
            break;
    };

    if ( _buildableCount == 0 )
    {
        CreateExplosion( _vecLocation,
                         _flDmg,
                         _flRange,
                         _hInflictor );
        return;
    };

    local _vecNearestBuildingOrigin = Entities.FindByClassnameNearest( "obj_*", _vecLocation, ( DEMOMAN_CHARGE_RADIUS ) ).GetOrigin();

    foreach ( i, _buildable in _buildableArr )
    {
        local _buildable = _buildableArr[ i ];

        if ( _buildable.GetClassname() == "obj_sentrygun"  ||
             _buildable.GetClassname() == "obj_teleporter" ||
             _buildable.GetClassname() == "obj_dispenser" )
        {
            _buildable.TakeDamage( 999, DMG_BLAST, _hInflictor );
        };
    };

    CreateExplosion( _vecNearestBuildingOrigin,
                     _flDmg,
                     _flRange,
                     _hInflictor );
    return;
};

CreateExplosion <- function( _vecLocation, _flDmg, _flRange, _hInflictor, _iTeamnum = TF_TEAM_BLUE )
{
    ScreenShake ( _vecLocation, 5000, 5000, 4, 350, 0, true );

    if ( _hInflictor.IsPlayer() )
    {
        _hInflictor.SetHealth( 1 );
    }

    local _hBomb = SpawnEntityFromTable( "tf_generic_bomb",
    {
        explode_particle = "mvm_loot_explosion",
        sound            = "Halloween.Merasmus_Hiding_Explode",
        damage           = DEMOMAN_CHARGE_DAMAGE.tostring(),
        radius           = DEMOMAN_CHARGE_RADIUS.tostring(),
        friendlyfire     = "0",
    });

    local _hPfxEnt = SpawnEntityFromTable( "info_particle_system",
    {
        effect_name  = FX_DEMOGUTS,
        start_active = "0",
        targetname   = "ZombieDemo_Explosion_PFX_Ent",
        origin       = _vecLocation,
    });

    _hPfxEnt.ValidateScriptScope();
    _hPfxEnt.GetScriptScope     ().m_flKillTime <- ( Time() + 2.0 ).tofloat();

    AddThinkToEnt( _hPfxEnt, "KillMeThink" );

    _hBomb.ValidateScriptScope();
    _hBomb.GetScriptScope     ().m_flKillTime <- ( Time() + 0.1 ).tofloat();
    _hBomb.GetScriptScope     ().m_hOwner     <- _hInflictor;

    _hPfxEnt.DispatchSpawn();

    EntFireByHandle ( _hPfxEnt, "Start",    "", -1, null, null )

    SetPropInt      ( _hBomb, "m_iTeamNum", TF_TEAM_BLUE );
    EmitSoundOn     ( "Breakable.MatFlesh", _hBomb );
    EmitSoundOn     ( "Halloween.Merasmus_Hiding_Explode", _hBomb );

    _hBomb.DispatchSpawn();

    _hBomb.SetTeam       ( TF_TEAM_BLUE );
    _hBomb.SetOrigin     ( _vecLocation );
    _hBomb.SetOwner      ( _hInflictor );

    // EntFireByHandle ( _hBomb,   "Detonate", "", -1, _hInflictor, _hInflictor )
    _hBomb.KeyValueFromString( "classname", KILLICON_DEMOMAN_BOOM );
    _hBomb.TakeDamage(1, DMG_CLUB, _hInflictor)
    _hInflictor.TakeDamage(1, DMG_NEVERGIB, _hInflictor)
    return;
};

GetAllPlayers <- function()
{
    for ( local i = 1; i <= MaxPlayers; i++ )
    {
        local _player = PlayerInstanceFromIndex( i );

        if ( _player != null )
        {
            yield _player;
        };
    };

    return;
};

GetRandomPlayers <- function( _howMany = 1 )
{
    local _playerArr = [];

    foreach ( _hPlayer in GetAllPlayers() )
    {
        if ( _hPlayer != null /* &&  ( _hPlayer.GetFlags() & FL_FAKECLIENT ) == 0 */  )
            _playerArr.append( _hPlayer );
    };

    _howMany = ( _howMany <= _playerArr.len() ) ? _howMany : _playerArr.len();

    local _selectedPlayers = [];

    for ( local i = 0; i < _howMany; i++ )
    {
        local _randomID = RandomInt ( 0, _playerArr.len() - 1 );
        _selectedPlayers.append     ( _playerArr[ _randomID ] );
        _playerArr.remove           ( _randomID );
    };

    return _selectedPlayers;
};

ChangeTeamSafe <- function( _hPlayer, _iTeamNum, _bForce = false )
{
    if ( _hPlayer == null || _iTeamNum < 0 || _iTeamNum > 3 || _hPlayer.GetTeam() == _iTeamNum )
        return;

    // m_bIsCoaching trick to change team even if player is in a duel (source: vdc)
    SetPropBool( _hPlayer, "m_bIsCoaching", true  );
    _hPlayer.ForceChangeTeam( _iTeamNum, _bForce  );
    SetPropBool( _hPlayer, "m_bIsCoaching", false );

    return;
};

NetName <- function( _hPlayer )
{
    if ( _hPlayer == null )
        return "[UNKNOWN/INVALID PLAYER]";

    local _szNetname = GetPropString( _hPlayer, "m_szNetname" );

    if ( typeof _szNetname != "string" || _szNetname == "" || _szNetname == null )
        return "[BAD NETNAME]";

    return _szNetname;
};

PlayerIsValid <- function( _hPlayer )
{
    if ( _hPlayer == null )
        return false;

    return true;
};

ShouldZombiesWin <- function( _hPlayer )
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
                 ( GetPropInt( _player, "m_lifeState" ) == ALIVE ) && _player != _hPlayer )
            {
                 _iValidSurvivors++;
            };
        };
    };

    if ( _iValidPlayers == 0 ) // GetAllPlayers didn't find any players, should never happen
    {
        return;
    };

    if ( _iValidSurvivors == 3 )
    {
        ClientPrint( null, HUD_PRINTTALK, format( STRING_UI_CHAT_LAST_SURV_YELLOW, _iValidSurvivors, STRING_UI_MINI_CRITS ) );
    };

    // check if zombies have killed enough survivors to win
    if ( _iValidSurvivors <= MAX_SURVIVORS_FOR_ZOMBIE_WIN )
    {
        local _hGameWin = SpawnEntityFromTable( "game_round_win",
        {
            win_reason      = "0",
            force_map_reset = "1",
            TeamNum         = "3", // TF_TEAM_BLUE
            switch_teams    = "0"
        } );

        // the zombies have won the round.
        ::bGameStarted <- false;
        EntFireByHandle ( _hGameWin, "RoundWin", "", 0, null, null );
    }
    else
    {
        if ( _iValidSurvivors == 1 ) // last guy
        {
            foreach( _hNextPlayer in GetAllPlayers() )
            {
                if ( _hNextPlayer.GetTeam() == TF_TEAM_RED && GetPropInt( _hNextPlayer, "m_lifeState" ) == ALIVE )
                {
                    if ( _hNextPlayer == null || _hNextPlayer == _hPlayer )
                        continue;

                    ClientPrint( null, HUD_PRINTTALK, format( STRING_UI_CHAT_LAST_SURV_GREEN, NetName( _hNextPlayer ), STRING_UI_CRITS ) );

                    _hNextPlayer.GetScriptScope().m_bLastManStanding <- true;
                    _hNextPlayer.GetScriptScope().m_bLastThree       <- false;

                    if (_hNextPlayer.GetPlayerClass() == TF_CLASS_SOLDIER || _hNextPlayer.GetPlayerClass() == TF_CLASS_DEMOMAN)
                    {
                        local _bDestroyedParachuteResult = _hNextPlayer.HasThisWeapon( 1101, true );
                    }

                    _hNextPlayer.AddCond( TF_COND_CRITBOOSTED );
                };
            };
        }
        else if ( ( _iValidSurvivors < 4 ) && ( _iValidSurvivors > 1 ) ) // last 3 get minicrits
        {
            foreach( _hNextPlayer in GetAllPlayers() )
            {
                if ( _hNextPlayer.GetTeam() == TF_TEAM_RED && GetPropInt( _hNextPlayer, "m_lifeState" ) == ALIVE )
                {
                    if ( _hNextPlayer == null )
                        continue;

                    _hNextPlayer.GetScriptScope().m_bLastThree <- true;
                    _hNextPlayer.AddCond( TF_COND_OFFENSEBUFF );
                    continue;
                };
            };
        };
    };

    return;
};

CreateSmallHealthKit <- function( _vecLocation )
{
    local _hDroppedHealthkit = SpawnEntityFromTable( "item_healthkit_small",
    {
        origin          = _vecLocation,
        AutoMaterialize = false,
        StartDisabled   = false,
    } );

    _hDroppedHealthkit.ValidateScriptScope();

    // zombie dropped health kits last for 20 seconds
    _hDroppedHealthkit.GetScriptScope().m_flKillTime <- ( Time() + 20.0 );

    _hDroppedHealthkit.SetMoveType( MOVETYPE_FLYGRAVITY, MOVECOLLIDE_FLY_BOUNCE );

    AddThinkToEnt( _hDroppedHealthkit, "KillMeThink" );
}

CreateMediumHealthKit <- function( _vecLocation )
{
    local _hDroppedHealthkit = SpawnEntityFromTable( "item_healthkit_medium",
    {
        origin          = _vecLocation,
        AutoMaterialize = false,
        StartDisabled   = false,
    } );

    _hDroppedHealthkit.ValidateScriptScope();

    // zombie dropped health kits last for 20 seconds
    _hDroppedHealthkit.GetScriptScope().m_flKillTime <- ( Time() + 20.0 );

    _hDroppedHealthkit.SetMoveType( MOVETYPE_FLYGRAVITY, MOVECOLLIDE_FLY_BOUNCE );

    AddThinkToEnt( _hDroppedHealthkit, "KillMeThink" );
}

PrintToChat <- function( _szMessage )
{
    if ( typeof _szMessage != "string" || _szMessage == "" || _szMessage == null )
        return;

    ClientPrint( null, HUD_PRINTTALK, _szMessage );
    return;
};

SlayPlayerWithSpoofedIDX <-  function(_hAttacker, _hVictim, _hAttackerWep, _vecDmgForce, _vecDmgPosition, _iIDX = ZOMBIE_SPOOF_WEAPON_IDX, _szKillicon = "" )
{
    if ( _hAttacker == null || _hVictim == null || _hAttackerWep == null )
        return;

    local _hKillicon    = KilliconInflictor( _szKillicon );

    // --------------------------------------------------------------------------------------------- //
    // hacky function for technically killing a player with a different weapon to spoof the killicon //
    // this function should only be used when the player has already received lethal damage.         //
    // --------------------------------------------------------------------------------------------- //

    if ( _hVictim.GetClassname() == "obj_sentrygun" ||
         _hVictim.GetClassname() == "obj_dispenser" ||
         _hVictim.GetClassname() == "obj_teleporter" )
    {
        // get the existing IDX of the given weapon, so we can swap it back
     //   local _iPreviousIDX = GetPropInt( _hAttacker.GetActiveWeapon(), STRING_NETPROP_ITEMDEF );


        // hack in the IDX of the weapon we want to steal the killicon from
     //   SetPropInt( _hAttackerWep, STRING_NETPROP_ITEMDEF, _iIDX );

        _hVictim.TakeDamageEx( _hKillicon, _hAttacker,
                               _hAttackerWep, _vecDmgForce,
                               _vecDmgPosition, 999, DMG_CLUB ); // using a goofy number is ok
                                                                 // because we've already removed
                                                                 // the player's actual weapons
                                                                 // nobody's stranges will be ruined

        // set the IDX back
     //   SetPropInt( _hAttackerWep, STRING_NETPROP_ITEMDEF, _iPreviousIDX );
    }
    else if ( _hVictim.GetClassname() == "player" )
    {
        _hVictim.SetHealth( 1 ); // prep the player to be slain

        // get the existing IDX of the given weapon, so we can swap it back
      //  local _iPreviousIDX = GetPropInt( _hAttacker.GetActiveWeapon(), STRING_NETPROP_ITEMDEF );

        // hack in the IDX of the weapon we want to steal the killicon from
        SetPropInt( _hAttackerWep, STRING_NETPROP_ITEMDEF, _iIDX );

        _hVictim.TakeDamageEx( _hKillicon, _hAttacker,
                               _hAttackerWep, _vecDmgForce,
                               _vecDmgPosition, 1, DMG_CLUB | DMG_ALWAYSGIB );

        // set the IDX back
      //  SetPropInt( _hAttackerWep, STRING_NETPROP_ITEMDEF, _iPreviousIDX );
    };

    _hKillicon.Destroy();
    return;
};

// --------------------------------------------------------------------------------------- //
// Infection specific player functions                                                     //
// these functions are added to the player class                                           //
// usage: _playerHandle.<functionName>( _args );                                           //
// --------------------------------------------------------------------------------------- //

CTFPlayer_HasThisWeapon <-  function( _WeaponIndentity, _bDeleteItemOnFind = false )
{
    for ( local i = 0; i < TF_WEAPON_COUNT; i++ )
    {
        local _hNextWeapon = GetPropEntityArray( this, "m_hMyWeapons", i )

        if ( _hNextWeapon == null )
            continue;

        if ( typeof _WeaponIndentity == "string" )
        {
            if ( _hNextWeapon.GetClassname() == _WeaponIndentity )
            {
                if ( _bDeleteItemOnFind )
                {
                    _hNextWeapon.Destroy();
                }

                return true;
            };
        }
        else if ( typeof _WeaponIndentity == "integer" )
        {
            if ( GetPropInt( _hNextWeapon, STRING_NETPROP_ITEMDEF ) == _WeaponIndentity )
            {
                if ( _bDeleteItemOnFind )
                {
                    _hNextWeapon.Destroy();
                }

                return true;
            };
        };
    };

	return false
};

CTFPlayer_HasThisWearable <- function( _WearableClassname )
{
    local _wearable = null;
    while ( _wearable = Entities.FindByClassname( _wearable, "tf_wearable*" ) )
    {
        if (  _wearable != null && _wearable.GetOwner() == this )
        {
            if ( _wearable.GetClassname() == _WearableClassname )
            {
                return true;
            };
        };
    };

	return false
};

CTFPlayer_LockInPlace <- function( _bEnable = true )
{
    if ( _bEnable )
    {
        this.AddCustomAttribute( "no_jump", 1, -1 );
        this.AddCustomAttribute( "no_duck", 1, -1 );
        this.AddCustomAttribute( "no_attack", 1, -1 );
        this.AddCustomAttribute( "move speed penalty", 0.01, -1 );
    }
    else
    {
        this.RemoveCustomAttribute( "no_jump" );
        this.RemoveCustomAttribute( "no_duck" );
        this.RemoveCustomAttribute( "no_attack" );
        this.RemoveCustomAttribute( "move speed penalty" );
    };
};

CTFPlayer_GiveZombieAbility <- function()
{
    local _sc = this.GetScriptScope();

    _sc.m_hZombieAbility <- null;
    _sc.m_fTimeNextCast  <- 0.0;

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
            _sc.m_hZombieAbility <- CPyroBlast( this );
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
            _sc.m_hZombieAbility <- CHeavyPassive( this );
            break;
    };

    _sc.m_iCurrentAbilityType <- _sc.m_hZombieAbility.GetAbilityType();
}

CTFPlayer_RemovePlayerWearables <- function()
{
    local _wearable = null;
    while ( _wearable = Entities.FindByClassname( _wearable, "tf_wearable*" ) )
    {
        if (  _wearable != null && _wearable.GetOwner() == this )
        {
            _wearable.Destroy();
        };
    };

    return;
};

CTFPlayer_SpawnEffect <- function()
{
    local _angPlayer     =  this.GetLocalAngles();
    local _vecAngPlayer  =  Vector( _angPlayer.x, _angPlayer.y, _angPlayer.z );

    EmitSoundOn            ( "Halloween.spell_lightning_cast",   this );
    EmitSoundOn            ( "Halloween.spell_lightning_impact", this );

    DispatchParticleEffect ( FX_ZOMBIE_SPAWN, this.GetLocalOrigin(), _vecAngPlayer );
    return;
};

CTFPlayer_GiveZombieCosmetics <- function()
{

    local _iClassnum = this.GetPlayerClass();

    this.SetCustomModelWithClassAnimations(szArrZombiePlayerModels[ _iClassnum ]);

    // local _sc = this.GetScriptScope();

    // if ( "m_hZombieWearable" in _sc && _sc.m_hZombieWearable != null && _sc.m_hZombieWearable.IsValid() )
    // _sc.m_hZombieWearable.Destroy();

    // local _zombieCosmetic  =  Entities.CreateByClassname( "tf_wearable" );
    // local _soulIDX         =  arrZombieCosmeticIDX[ this.GetPlayerClass() ];

    // _zombieCosmetic.AddAttribute ( "player skin override", 1, -1 );
    // SetPropInt                   ( this, "m_iPlayerSkinOverride", 1 );

    // Entities.DispatchSpawn       ( _zombieCosmetic );
    // _zombieCosmetic.SetAbsOrigin ( this.GetLocalOrigin() );
    // _zombieCosmetic.SetAbsAngles ( this.GetLocalAngles() );

    // // Zombie Cosmetics NetProps // ----------------------------------------------------------------- //
    // SetPropInt    ( _zombieCosmetic, "m_iTeamNum",                                     this.GetTeam() );
    // SetPropInt    ( _zombieCosmetic, "m_AttributeManager.m_Item.m_iItemDefinitionIndex",     _soulIDX );
    // SetPropBool   ( _zombieCosmetic, "m_bValidatedAttachedEntity",                               true );
    // SetPropBool   ( _zombieCosmetic, "m_AttributeManager.m_Item.m_bInitialized",                 true );
    // SetPropEntity ( _zombieCosmetic, "m_hOwnerEntity",                                           this );
    // SetPropInt    ( _zombieCosmetic, "m_Collision.m_usSolidFlags",                                  4 );
    // SetPropInt    ( _zombieCosmetic, "m_nModelIndex", arrZombieCosmeticModel[ this.GetPlayerClass() ] );
    // // ---------------------------------------------------------------------------------------------- //

    // _zombieCosmetic.SetOwner( this );

    // SetPropInt      ( _zombieCosmetic, "m_fEffects", ( EF_BONEMERGE ) );
    // EntFireByHandle ( _zombieCosmetic, "SetParent",  "!activator", 0.0, this, this );
}


CTFPlayer_GiveZombieFXWearable <- function()
{
  // local _sc = this.GetScriptScope();

  // if ( _sc.m_hZombieFXWearable != null && _sc.m_hZombieFXWearable.IsValid() )
  //     _sc.m_hZombieFXWearable.Destroy();

  // local _zombieFXWearable = Entities.CreateByClassname( "tf_wearable" );

  // Entities.DispatchSpawn         ( _zombieFXWearable );
  // _zombieFXWearable.SetAbsOrigin ( this.GetLocalOrigin() );
  // _zombieFXWearable.SetAbsAngles ( this.GetLocalAngles() );

  // // Zombie FX Wearable NetProps
  // SetPropBool   ( _zombieFXWearable,  "m_bValidatedAttachedEntity", true );
  // SetPropBool   ( _zombieFXWearable,  "m_AttributeManager.m_Item.m_bInitialized", true );
  // SetPropEntity ( _zombieFXWearable,  "m_hOwnerEntity",  this );
  // SetPropInt    ( _zombieFXWearable,  "m_Collision.m_usSolidFlags", 4 );
  // SetPropInt    ( _zombieFXWearable,  "m_nModelIndex", arrZombieFXWearable[ this.GetPlayerClass() ] );

  // _zombieFXWearable.SetOwner( this );

  // SetPropInt      ( _zombieFXWearable, "m_fEffects", ( EF_BONEMERGE | EF_BONEMERGE_FASTCULL ) );
  // EntFireByHandle ( _zombieFXWearable, "SetParent", "!activator", 0.0, this, this );

  // _sc.m_hZombieFXWearable  <-  _zombieFXWearable;
    return;
};

CTFPlayer_ApplyOutOfCombat <- function()
{
    return;

    if ( this.InCond( TF_COND_SHIELD_CHARGE ) ) // todo - hacky demoman fix
        return;

    local _sc = this.GetScriptScope();

    _sc.m_iFlags <- ( _sc.m_iFlags | ZBIT_OUT_OF_COMBAT );

    if ( this.GetPlayerClass() == TF_CLASS_HEAVYWEAPONS || this.GetPlayerClass() == TF_CLASS_SCOUT )
        return;

    this.AddCond             ( TF_COND_SPEED_BOOST );
    this.AddCustomAttribute  ( "move speed penalty", ZOMBIE_BOOST_SPEED_DEBUFF, -1 );
};

CTFPlayer_RemoveOutOfCombat <- function( _bForceCooldown = false )
{
    local _sc = this.GetScriptScope();

    if ( _bForceCooldown )
    {
        _sc.m_fTimeLastHit <- Time();
    };

    if ( _sc.m_iFlags & ZBIT_MUST_EXPLODE )
        return;

    if ( this.GetPlayerClass() == TF_CLASS_HEAVYWEAPONS || this.GetPlayerClass() == TF_CLASS_SCOUT )
        return;

    _sc.m_iFlags            <- ( _sc.m_iFlags & ~ZBIT_OUT_OF_COMBAT );
    this.RemoveCond            ( TF_COND_SPEED_BOOST )

    this.RemoveCustomAttribute ( "move speed penalty" );
};

CTFPlayer_RemoveAmmo <- function()
{
    for ( local i = 0; i < 32; i++ )
    {
        SetPropIntArray( this, "m_iAmmo", 0, i );
    };
};

CTFPlayer_GiveZombieWeapon <- function()
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

    SetPropInt  ( _zombieWep, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", _idx );
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

    this.EquipWearableViewModel  ( _zombieArms );

    _sc.m_hZombieWep  <- _zombieWep;
    _sc.m_hZombieArms <- _zombieArms;

    _hPlayerVM.SetModelSimple           ( arrZombieViewModelPath[ _playerClass ] );
    _sc.m_hZombieWep.SetCustomViewModel ( arrZombieViewModelPath[ _playerClass ] );

    this.Weapon_Switch ( _zombieWep );
    return;
};

CTFPlayer_AddZombieAttribs <- function()
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

    if ( ZOMBIE_PLAYER_ATTRIBS[ _iClassNum ].len() > 0 )
    {
        foreach ( _attrib in ZOMBIE_PLAYER_ATTRIBS[ _iClassNum ]  ) // class specific attribs
        {
            this.AddCustomAttribute( _attrib[ 0 ], _attrib[ 1 ], _attrib[ 2 ] );
        };
    };

    return;
};

CTFPlayer_ClearZombieAttribs <- function()
{
    local _iClassNum = this.GetPlayerClass();

    if ( ZOMBIE_PLAYER_CONDS[ 0 ].len() > 0 )
    {
        foreach ( _cond in ZOMBIE_PLAYER_CONDS[ 0 ] ) // default conds
        {
            this.RemoveCondEx( _cond, true );
        };
    };

    if ( ZOMBIE_PLAYER_CONDS[ _iClassNum ].len() > 0 )
    {
        foreach ( _cond in ZOMBIE_PLAYER_CONDS[ _iClassNum ] )  // class specific conds
        {
            this.RemoveCondEx( _cond, true );
        };
    };

    if ( ZOMBIE_PLAYER_ATTRIBS[ 0 ].len() > 1 )
    {
        foreach ( _attrib in ZOMBIE_PLAYER_ATTRIBS[ 0 ]  ) // default attribs
        {
            this.RemoveCustomAttribute( _attrib[ 0 ]);
        };
    };

    if ( ZOMBIE_PLAYER_ATTRIBS[ _iClassNum ].len() > 0 )
    {
        foreach ( _attrib in ZOMBIE_PLAYER_ATTRIBS[ _iClassNum ]  ) // class specific attribs
        {
            this.RemoveCustomAttribute( _attrib[ 0 ]);
        };
    };

    return;
};

CTFPlayer_AbilityStateToString <- function()
{
    local _sc = this.GetScriptScope();

    if ( !IsPlayerAlive( this ) || _sc.m_fTimeNextCast == ACT_LOCKED )
        return "off.vtf";

    local _bCanCast = ( _sc.m_fTimeNextCast <= Time() );

    switch ( _bCanCast )
    {
        case true:
            return "on.vtf";
            break;
        default:
            return "off.vtf";
            break;
    };

    return "off.vtf";
};

CTFPlayer_BuildZombieHUDString <- function()
{
    local _sc = this.GetScriptScope();

    if ( _sc.m_hZombieAbility == null )
    {
        _sc.m_szCurrentHUDString = "";
        return;
    }

    if ( _sc.m_fTimeNextCast == ACT_LOCKED )
    {
        if ( _sc.m_hZombieAbility.m_iAbilityType == ZABILITY_PASSIVE )
        {
            _sc.m_szCurrentHUDString = STRING_UI_PASSIVE;
            return;
        }
        else
        {
            _sc.m_szCurrentHUDString = STRING_UI_CASTING;
        };

        return;
    };

    local _flSecondsUntilAbility = ( _sc.m_fTimeNextCast - Time() );
    local _szMessage             = "";

    if ( _flSecondsUntilAbility < 0 )
    {
        _sc.m_szCurrentHUDString = STRING_UI_READY;
    }
    else
    {
        local _nWholeSeconds = _flSecondsUntilAbility.tointeger();
        local _nDecimalPart  = ( _flSecondsUntilAbility - floor( _flSecondsUntilAbility ) );

        // todo: need to figure out localized strings and rewrite this
        _szMessage += format( "%s %d", "Ready in", _nWholeSeconds );

        if ( _nDecimalPart <= 0.8 )
        {
            _szMessage += ".";
        };

        if ( _nDecimalPart <= 0.6 )
        {
            _szMessage += ".";
        };

        if ( _nDecimalPart <= 0.2 )
        {
            _szMessage += ".";
        };

        _sc.m_szCurrentHUDString = _szMessage;
        return;
    };
};

CTFPlayer_ZombieInitialTooltip <- function()
{
    local _hAbilityHUDText = SpawnEntityFromTable( "game_text",
    {
        x          =  0.287,
        y          =  0.85,
        effect     =  2,
        color      =  "255 255 255",
        color2     =  "127 111 32",
        fadein     =  0.009,
        fadeout    =  0.9,
        holdtime   =  10,
        fxtime     =  0.008,
        channel    =  1,
        message    =  "",
        spawnflags =  0,
    });

    return _hAbilityHUDText;
};

CTFPlayer_InitializeZombieHUD <- function()
{
    local _sc = this.GetScriptScope();

    local _hAbilityHUDText = SpawnEntityFromTable( "game_text",
    {
        x          =  ZHUD_X_POS,
        y          =  0.895,
        effect     =  0,
        color      =  "255 255 255",
        color2     =  "0 0 0",
        fadein     =  0,
        fadeout    =  0,
        holdtime   =  10,
        fxtime     =  0,
        channel    =  2,
        message    =  "",
        spawnflags =  0,
    });

    local _hAbilityNameHUDText = SpawnEntityFromTable( "game_text",
    {
        x          =  ZHUD_X_POS,
        y          =  0.80,
        effect     =  0,
        color      =  "255 255 255",
        color2     =  "0 0 0",
        fadein     =  0,
        fadeout    =  0,
        holdtime   =  10,
        fxtime     =  0,
        channel    =  4,
        message    =  "",
        spawnflags =  0,
    });

    _sc.m_hHUDText             <- _hAbilityHUDText;
    _sc.m_hHUDTextAbilityName  <- _hAbilityNameHUDText;

    if ( _sc.m_hHUDText )
    {
        return true;
    }
    else
    {
        return false;
    };

    return false;
};

CTFPlayer_CheckIfLoser <- function()
{
    local _iRoundState = GetPropInt( GameRules, "m_iRoundState" );

    if ( _iRoundState != GR_STATE_TEAM_WIN )
        return false;

    if ( GetWinningTeam() != this.GetTeam() )
        return true;

    // if ( you are reading this )
        // return true;

    return false;
};

CTFPlayer_CanDoAct <- function( _iAct )
{
    local _sc    =  this.GetScriptScope();
    local _temp  =  ACT_LOCKED;

    switch ( _iAct )
    {
        case ZOMBIE_ABILITY_CAST:

            if ( this.CheckIfLoser() )
                return false;

            _temp = _sc.m_fTimeNextCast;
            break;

        case ZOMBIE_TALK:
            _temp = _sc.m_fTimeNextTalk;
            break;
        case ZOMBIE_DO_ATTACK1:
            _temp = _sc.m_fTimeNextViewpunch;
            break;
        case ZOMBIE_BECOME_ZOMBIE:
            _temp = _sc.m_fTimeBecomeZombie;
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
        case ZOMBIE_REMOVE_HEALRING:
            _temp = _sc.m_fTimeRemoveHeal;
            break;
        case ZOMBIE_CAN_CLIENTPRINT:
            _temp = _sc.m_fTimeNextClientPrint;
            break;
        case SURVIVOR_CAN_CLEAR_SCRIPT_SCREEN_OVERLAY:
            _temp = _sc.m_fTimeRemoveScreenOverlay;
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
};

CTFPlayer_ProcessEventQueue <- function(  )
{
    local _sc = this.GetScriptScope();

    if ( _sc.m_tblEventQueue.len() == 0 )
        return;

    local _nearestEvent     =  null;
    local _nearestFireTime  =  null;

    foreach ( _event, _fireTime in _sc.m_tblEventQueue )
    {
        if ( _nearestEvent == null || ( _fireTime < _nearestFireTime ) )
        {
            _nearestEvent     =  _event;
            _nearestFireTime  =  _fireTime;
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

            case EVENT_KILL_TEMP_ENTITY: // todo mess

                if ( "m_hTempEntity" in _sc && _sc.m_hTempEntity != null && _sc.m_hTempEntity.IsValid() )
                    _sc.m_hTempEntity.Destroy();

                this.SetForcedTauntCam ( 0 );
                this.RemoveCond        ( TF_COND_TAUNTING );

                _sc.m_hZombieAbility.PutAbilityOnCooldown();
                this.RemoveCustomAttribute ( "no_attack" );
                break;

            case EVENT_SPY_RECLOAK:

                // start with standard cloak for spawn fx
                this.AddCondEx( TF_COND_STEALTHED, 0.3, null );

                // then swap to TF_COND_STEALTHED_USER_BUFF for the rest of the duration
                this.AddEventToQueue( EVENT_SPY_SWAP_CLOAK, 0.2 );
                break;

            case EVENT_SPY_SWAP_CLOAK:
                this.AddCondEx( TF_COND_STEALTHED_USER_BUFF, -1, null );
                break;

            case EVENT_DEMO_CHARGE_RESET:

                if ( _sc.m_hZombieFXWearable != null && _sc.m_hZombieFXWearable.IsValid() )
                    _sc.m_hZombieFXWearable.Destroy();

                if ( _sc.m_hZombieWearable != null && _sc.m_hZombieWearable.IsValid() )
                    _sc.m_hZombieWearable.Destroy();

                this.GiveZombieFXWearable();
                this.GiveZombieCosmetics();

                this.SetForcedTauntCam ( 0 );

                this.RemoveCond ( TF_COND_CRITBOOSTED_PUMPKIN );
                this.RemoveCond ( TF_COND_TAUNTING );
                this.RemoveCond ( TF_COND_INVULNERABLE_USER_BUFF );
                this.RemoveCond ( TF_COND_RADIUSHEAL );

                _sc.m_iFlags <- ( _sc.m_iFlags & ~ZBIT_DEMOCHARGE );
                _sc.m_iFlags <- ( _sc.m_iFlags & ~ZBIT_MUST_EXPLODE );
                break;

            case EVENT_RESET_ZOMBIE_WEP:

                this.DestroyAllWeapons();
                this.GiveZombieWeapon();
                this.RemoveAmmo();
                break;

            default:
                _sc.m_tblEventQueue.rawdelete( _nearestEvent );
                return;
        };

        _sc.m_tblEventQueue.rawdelete( _nearestEvent );
    };

    return;
};

CTFPlayer_RemoveEventFomQueue <- function( _event )
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

CTFPlayer_AddEventToQueue <- function( _event, _delay )
{
    local _sc        =  this.GetScriptScope();
    local _fireTime  =  ( Time() + _delay );

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

CTFPlayer_ResetInfectionVars <- function()
{
    AddThinkToEnt( this, null );

    local _sc = this.GetScriptScope();

    if ( ( "m_iUserConfigFlags" in _sc ) )
    {
        _sc.m_iUserConfigFlags <- ( _sc.m_iUserConfigFlags );
    }
    else
    {
        _sc.m_iUserConfigFlags <- ZBIT_HAS_HUD;
    };

    if ( !::bGameStarted )
        _sc.m_bCanAddTime <- true;

    _sc.m_iFlags                <- ZBIT_SURVIVOR;
    _sc.m_tblEventQueue         <- { };
    _sc.m_szCurrentHUDString    <- "";

    _sc.m_bCanPlay              <- false;
    _sc.m_bDeathWasModified     <- false;
    _sc.m_bLastManStanding      <- false;
    _sc.m_bZombieHUDInitialized <- false;
    _sc.m_bLastThree            <- false;
    _sc.m_bStandingOnSpit       <- false;

    _sc.m_hZombieWep            <- null;
    _sc.m_hZombieArms           <- null;
    _sc.m_hZombieWearable       <- null;
    _sc.m_hZombieFXWearable     <- null;
    _sc.m_hZombieAbility        <- null;
    _sc.m_hTempEntity           <- null;
    _sc.m_hHUDText              <- null;
    _sc.m_hHUDTextAbilityName   <- null;
    _sc.m_hLinkedSpitPool       <- null;

    _sc.m_fTimeNextCast         <- 0.0;
    _sc.m_fTimeNextTalk         <- 0.0;
    _sc.m_fTimeNextViewpunch    <- 0.0;
    _sc.m_fTimeRemoveZombie     <- 0.0;
    _sc.m_fTimeBecomeZombie     <- 0.0;
    _sc.m_fTimeNextQueuedEvent  <- 0.0;
    _sc.m_fKillGlowTime         <- 0.0;
    _sc.m_fTimeRemoveHeal       <- 0.0;
    _sc.m_fTimeNextHealTick     <- 0.0;
    _sc.m_fTimeNextClientPrint  <- 0.0;
    _sc.m_fTimeLastHit          <- 0.0;
    _sc.m_fTimeRemoveScreenOverlay <- 0.0;

    _sc.m_iCurrentAbilityType   <- 0;
    _sc.m_iAbilityState         <- 0;

    AddThinkToEnt( this, "PlayerThink" );

    return true;
};

CTFPlayer_ModifyJumperWeapons <- function()
{
    if ( this.GetPlayerClass() == TF_CLASS_SOLDIER )
    {
        if ( this.HasThisWeapon( 237 ) ) // rocket jumper
        {
            /*local _hWeapon = GetPropEntityArray( this, "m_hMyWeapons", 1 );

            _hWeapon.AddAttribute ( "maxammo primary reduced", 0.0, -1 );
            SetPropIntArray       ( this, "m_iAmmo", 0, 1 );

            _hWeapon.ReapplyProvision();
            return;*/
			for ( local i = 0; i < TF_WEAPON_COUNT; i++ )
            {
                local _hWeapon = GetPropEntityArray( this, "m_hMyWeapons", i )
                
                if ( _hWeapon == null )
                    return;
                    
                if ( GetPropInt( _hWeapon, STRING_NETPROP_ITEMDEF ) != 237 )
                    continue;
    
                _hWeapon.AddAttribute ( "maxammo primary reduced", 0.01, -1 );
                SetPropIntArray       ( this, "m_iAmmo", 0, 1 );
    
                _hWeapon.ReapplyProvision();
                return;
            }
        };
    };

    if ( this.GetPlayerClass() == TF_CLASS_DEMOMAN )
    {
        if ( this.HasThisWeapon( 265 ) ) // sticky jumper
        {			
            /*local _hWeapon = GetPropEntityArray( this, "m_hMyWeapons", 2 );

            _hWeapon.AddAttribute ( "hidden secondary max ammo penalty", 0.02, -1 );
            SetPropIntArray       ( this, "m_iAmmo", 0, 2 );

            _hWeapon.ReapplyProvision();
            return;*/
			for ( local i = 0; i < TF_WEAPON_COUNT; i++ )
            {
                local _hWeapon = GetPropEntityArray( this, "m_hMyWeapons", i )
                
                if ( _hWeapon == null )
                    return;
            
                if ( GetPropInt( _hWeapon, STRING_NETPROP_ITEMDEF ) != 265 )
                    continue;

                _hWeapon.AddAttribute ( "hidden secondary max ammo penalty", 0.02, -1 );
                SetPropIntArray       ( this, "m_iAmmo", 0, 2 );

                _hWeapon.ReapplyProvision();
                return;
            }
        };
    };
};

CTFPlayer_MakeHuman <- function()
{
    local _hPlayerVM = GetPropEntity( this, "m_hViewModel" );

    SetPropBool( this, "m_bForcedSkin", false );

    if ( this.GetPlayerClass() == TF_CLASS_ENGINEER )
    {
        // make sure we give the correct view model to the gun slinger engineers
        if ( this.HasThisWeapon( "tf_weapon_robot_arm" ) )
        {
            _hPlayerVM.SetModelSimple( MDL_GUNSLINGER_PATH );
            return;
        };
    };

    _hPlayerVM.SetModelSimple( arrTFClassDefaultArmPath[ this.GetPlayerClass() ] );
    return;
};

CTFPlayer_HowLongUntilAct <- function( _iAct )
{
    local _sc = this.GetScriptScope();

    switch ( _iAct )
    {
        case ZOMBIE_ABILITY_CAST:
            return ( _sc.m_fTimeNextCast < 0 ? 0 : _sc.m_fTimeNextCast - Time() );

        case ZOMBIE_TALK:
            return ( _sc.m_fTimeNextTalk < 0 ? 0 : _sc.m_fTimeNextTalk - Time() );

        case ZOMBIE_DO_ATTACK1:
            return ( _sc.m_fTimeNextViewpunch < 0 ? 0 : _sc.m_fTimeNextViewpunch - Time() );

        case ZOMBIE_BECOME_ZOMBIE:
            return ( _sc.m_fTimeBecomeZombie < 0 ? 0 : _sc.m_fTimeBecomeZombie - Time() );

        case ZOMBIE_BECOME_SURVIVOR:
            return ( _sc.m_fTimeRemoveZombie < 0 ? 0 : _sc.m_fTimeRemoveZombie - Time() );

        case ZOMBIE_KILL_GLOW:
            return ( _sc.m_fKillGlowTime < 0 ? 0 : _sc.m_fKillGlowTime - Time() );

        case ZOMBIE_REMOVE_HEALRING:
            return ( _sc.m_fTimeRemoveHeal < 0 ? 0 : _sc.m_fTimeRemoveHeal - Time() );

        case ZOMBIE_CAN_CLIENTPRINT:
            return ( _sc.m_fTimeNextClientPrint < 0 ? 0 : _sc.m_fTimeNextClientPrint - Time() );

        case SURVIVOR_CAN_CLEAR_SCRIPT_SCREEN_OVERLAY:
            return ( _sc.m_fTimeRemoveScreenOverlay < 0 ? 0 : _sc.m_fTimeRemoveScreenOverlay - Time() );

        default:
            return false;
    };
};

CTFPlayer_PlayZombieVO <- function()
{
    return;
};

CTFPlayer_ClearProblematicConds <- function()
{
    foreach ( _iCond in PROBLEMATIC_PLAYER_CONDS )
    {
        this.RemoveCond( _iCond );
    };

    return;
}

CTFPlayer_SetNextActTime <- function( _iAct, _fTime )
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
        case ZOMBIE_REMOVE_HEALRING:
            _sc.m_fTimeRemoveHeal      <- ( _nextTime );
            break;
        case ZOMBIE_CAN_CLIENTPRINT:
            _sc.m_fTimeNextClientPrint <- ( _nextTime );
            break;
        case SURVIVOR_CAN_CLEAR_SCRIPT_SCREEN_OVERLAY:
            _sc.m_fTimeRemoveScreenOverlay <- ( _nextTime );
            break;
        default:
            return false;
    };

    return;
};

CTFPlayer_DestroyAllWeapons <- function()
{
    local _tfwep;

    // for ( local _hWearable = this.FirstMoveChild(); _hWearable != null; _hWearable = _hWearable.NextMovePeer() )
    // {
    //     if ( _hWearable.GetClassname() == "tf_weapon*" || _hWearable.GetClassname() == "tf_wearable*" )
    //     {
    //         _hWearable.Destroy();
    //     };
    // };

    for ( local i = 0; i < TF_WEAPON_COUNT; i++ )
    {
        local _hNextWeapon = GetPropEntityArray( this, "m_hMyWeapons", i )

        if ( _hNextWeapon == null )
            continue;

        _hNextWeapon.Destroy();
        _hNextWeapon = null;
    };

    return;
};

CTFPlayer_ClearZombieEntities <- function()
{
    local _sc = this.GetScriptScope();

    if ( "m_hZombieWep" in _sc && _sc.m_hZombieWep != null && _sc.m_hZombieWep.IsValid() )
        _sc.m_hZombieWep.Destroy();

    if ( "m_hZombieFXWearable" in _sc && _sc.m_hZombieFXWearable != null && _sc.m_hZombieFXWearable.IsValid() )
        _sc.m_hZombieFXWearable.Destroy();

    if ( "m_hZombieWearable" in _sc && _sc.m_hZombieWearable != null && _sc.m_hZombieWearable.IsValid() )
        _sc.m_hZombieWearable.Destroy();

    if ( "m_hZombieWearable" in _sc && _sc.m_hZombieWearable != null && _sc.m_hZombieWearable.IsValid() )
        _sc.m_hZombieWearable.Destroy();

    return;
};

CTFPlayer_AlreadyInSpit <-  function()
{
    local _sc = this.GetScriptScope();

    return _sc.m_bStandingOnSpit;
}

CTFPlayer_GetLinkedSpitPoolEnt <- function()
{
   // printl("Getting linked spit pool entity from player...")
    local _sc = this.GetScriptScope();

    if ( !_sc.m_bStandingOnSpit )
        return null;

    if ( _sc.m_hLinkedSpitPool != null && _sc.m_hLinkedSpitPool.IsValid() )
        return _sc.m_hLinkedSpitPool;

    return null;
}

CTFPlayer_SetLinkedSpitPoolEnt <- function( _hSpitPool )
{
    local _sc = this.GetScriptScope();

    if ( _hSpitPool == null || !_hSpitPool.IsValid() )
        return;

   // printl("Setting linked spit pool entity for player...")

    _sc.m_bStandingOnSpit = true;
    _sc.m_hLinkedSpitPool = _hSpitPool;
    return;
}

CTFPlayer_ClearSpitStatus <- function()
{
    local _sc = this.GetScriptScope();

   // printl("Clearing spit status for player...")

    _sc.m_bStandingOnSpit = false;
    _sc.m_hLinkedSpitPool = null;
    return;
}

CTFPlayer_GetWeaponHandle <- function( _szWeaponClassname )
{
    for ( local i = 0; i < TF_WEAPON_COUNT; i++ )
    {
        local _hNextWeapon = GetPropEntityArray( this, "m_hMyWeapons", i )

        if ( _hNextWeapon == null )
            continue;

        if ( _hNextWeapon.GetClassname() == _szWeaponClassname )
            return _hNextWeapon;
    };

    return null;
}

// --------------------------------------------------------------------------------------- //
// Since CTFBot inherits from CTFPlayer_ before VScripts run, we need to manually put these //
// functions in to the CTFBot class to make them functional.                               //
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

KnockbackPlayer <-  function( _hInflictor, _hVictim, _flForceMultiplier = 500.0, _flUpwardForce =  0.25, _bRemoveOnGround = false )
{
    if ( _hInflictor == null || _hVictim == null )
         return;

    if ( _bRemoveOnGround )
    {
        _hVictim.RemoveFlag ( FL_ONGROUND );
        SetPropEntity       ( _hVictim, "m_hGroundEntity", null );
        _hVictim.AddCond    ( TF_COND_KNOCKED_INTO_AIR );
    }

    local _vecInflictorPos  = _hInflictor.GetOrigin();
    local _vecVictimPos     = _hVictim.GetOrigin();
    local _vecDirection     = _vecVictimPos - _vecInflictorPos;

    local _vecLength = sqrt(( _vecDirection.x * _vecDirection.x ) +
                            ( _vecDirection.y * _vecDirection.y ) +
                            ( _vecDirection.z * _vecDirection.z ) );

    if ( _vecLength > 0 )
    {
        _vecDirection.x /= _vecLength;
        _vecDirection.y /= _vecLength;
        _vecDirection.z /= _vecLength;
    }

    _vecDirection.z += _flUpwardForce;

    local _vecImpulse = _vecDirection * _flForceMultiplier;

    _hVictim.ApplyAbsVelocityImpulse( _vecImpulse );

    local _vecAngularImpulse = Vector( RandomFloat( -50.0, 50.0 ), RandomFloat( -50.0, 50.0 ), RandomFloat( -50.0, 50.0 ) );
    _hVictim.ApplyLocalAngularVelocityImpulse( _vecAngularImpulse );

    return;
};

KilliconInflictor <-  function( _szKillIconName )
{
    local _hKillIcon = SpawnEntityFromTable( "point_template", {
        classname = _szKillIconName
    });

    return _hKillIcon;
}