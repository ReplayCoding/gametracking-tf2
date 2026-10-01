// --------------------------------------------------------------------------------------- //
// Zombie Infection                                                                        //
// --------------------------------------------------------------------------------------- //
// All Code By: netmuck (https://steamcommunity.com/profiles/76561198025795825)            //
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
            if ( endswith( _value, ".wav" ) )
                PrecacheSound( _value );
            else
                PrecacheScriptSound( _value );
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

GetZombieQuota <- function( _iPlayerCount )
{
    if ( _iPlayerCount <= 4 )
        return 1;

    if ( _iPlayerCount <= 7 )
        return 2;

    if ( _iPlayerCount <= 12 )
        return 3;

    if ( _iPlayerCount < 18 )
        return 4;

    if ( _iPlayerCount <= 24 )
        return RoundUp( _iPlayerCount / STARTING_ZOMBIE_FAC );

    // 25+ players use a sqrt curve so big servers don't flood
    return RoundUp( sqrt( _iPlayerCount - 1 ) );
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

    // a corpse re-armed to 1hp and re-killed here fires a second player_death
    local _bDeadPlayer = ( _hInflictor.IsPlayer() && GetPropInt( _hInflictor, "m_lifeState" ) != ALIVE );

    if ( _hInflictor.IsPlayer() && !_bDeadPlayer )
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

    if ( !_bDeadPlayer )
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

GetRandomPlayers <- function( _howMany = 1, _tblExclude = null )
{
    local _playerArr   = [];
    local _fallbackArr = [];

    foreach ( _hPlayer in GetAllPlayers() )
    {
        // living survivors only
        if ( _hPlayer == null /* ||  ( _hPlayer.GetFlags() & FL_FAKECLIENT ) != 0 */ )
            continue;

        if ( _hPlayer.GetTeam() != TF_TEAM_RED ||
             GetPropInt( _hPlayer, "m_lifeState" ) != ALIVE )
            continue;

        if ( _tblExclude != null && _tblExclude.rawin( GetPlayerUserID( _hPlayer ) ) )
            _fallbackArr.append( _hPlayer );
        else
            _playerArr.append( _hPlayer );
    };

    local _selectedPlayers = [];

    for ( local i = 0; i < _howMany; i++ )
    {
        if ( _playerArr.len() == 0 )
        {
            // out of fresh players - draw from last round's wave
            if ( _fallbackArr.len() == 0 )
                break;

            _playerArr   = _fallbackArr;
            _fallbackArr = [];
        };

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

    _hDroppedHealthkit.GetScriptScope().m_flKillTime <- ( Time() + 20.0 );

    _hDroppedHealthkit.SetMoveType( MOVETYPE_FLYGRAVITY, MOVECOLLIDE_FLY_BOUNCE );

    AddThinkToEnt( _hDroppedHealthkit, "KillMeThink" );
}

CreateMediumAmmoPack <- function( _vecLocation )
{
    local _hDroppedAmmoPack = SpawnEntityFromTable( "item_ammopack_medium",
    {
        origin          = _vecLocation,
        AutoMaterialize = false,
        StartDisabled   = false,
    } );

    _hDroppedAmmoPack.ValidateScriptScope();

    _hDroppedAmmoPack.GetScriptScope().m_flKillTime <- ( Time() + 20.0 );

    _hDroppedAmmoPack.SetMoveType( MOVETYPE_FLYGRAVITY, MOVECOLLIDE_FLY_BOUNCE );

    AddThinkToEnt( _hDroppedAmmoPack, "KillMeThink" );
}

CreateSmallAmmoPack <- function( _vecLocation )
{
    local _hDroppedAmmoPack = SpawnEntityFromTable( "item_ammopack_small",
    {
        origin          = _vecLocation,
        AutoMaterialize = false,
        StartDisabled   = false,
    } );

    _hDroppedAmmoPack.ValidateScriptScope();

    _hDroppedAmmoPack.GetScriptScope().m_flKillTime <- ( Time() + 20.0 );

    _hDroppedAmmoPack.SetMoveType( MOVETYPE_FLYGRAVITY, MOVECOLLIDE_FLY_BOUNCE );

    AddThinkToEnt( _hDroppedAmmoPack, "KillMeThink" );
}

CreateZombieDeathDrop <- function( _vecLocation )
{
    CreateSmallHealthKit ( _vecLocation + Vector(  ZOMBIE_DEATH_DROP_SPREAD, 0, 0 ) );
    CreateSmallAmmoPack  ( _vecLocation + Vector( -ZOMBIE_DEATH_DROP_SPREAD, 0, 0 ) );
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

CTFPlayer_EndSpitCharge <- function()
{
    local _sc = this.GetScriptScope();

    if ( ( "m_hSpitSlowWep" in _sc ) && _sc.m_hSpitSlowWep != null && _sc.m_hSpitSlowWep.IsValid() )
        _sc.m_hSpitSlowWep.RemoveAttribute( "move speed penalty" );

    _sc.m_hSpitSlowWep <- null;
    _sc.m_iFlags       <- ( _sc.m_iFlags & ~ZBIT_SNIPER_CHARGING_SPIT );

    if ( _sc.m_hZombieWep != null && _sc.m_hZombieWep.IsValid() )
        SetPropFloat( _sc.m_hZombieWep, "m_flNextPrimaryAttack", 0.0 );
};

CTFPlayer_EndSoldierFall <- function()
{
    local _sc = this.GetScriptScope();

    _sc.m_bSoldierFallSfx <- false;
    StopSoundOn( SFX_SOLDIER_FALL, this );
};

CTFPlayer_GiveZombieAbility <- function()
{
    local _sc = this.GetScriptScope();

    _sc.m_hZombieAbility <- null;
    _sc.m_fTimeNextCast  <- 0.0;

    switch ( this.GetPlayerClass() )
    {
        case TF_CLASS_ENGINEER:
            _sc.m_hZombieAbility <- CEngineerBeacon( this );
            break;
        case TF_CLASS_SNIPER:
            _sc.m_hZombieAbility <- CSniperSpitball( this );
            break;
        case TF_CLASS_SPY:
            _sc.m_hZombieAbility <- CSpyEMP( this );
            break;
        case TF_CLASS_MEDIC:
            _sc.m_hZombieAbility <- CMedicHeal( this );
            break;
        case TF_CLASS_HEAVYWEAPONS:
            _sc.m_hZombieAbility <- CHeavyRockThrow( this );
            break;
        case TF_CLASS_PYRO:
            _sc.m_hZombieAbility <- CPyroSpew( this );
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
    foreach ( _szClass in [ "tf_wearable*", "tf_powerup_bottle", "tf_weapon_spellbook" ] )
    {
        local _wearable = null;
        while ( _wearable = Entities.FindByClassname( _wearable, _szClass ) )
        {
            if (  _wearable != null && _wearable.GetOwner() == this )
            {
                _wearable.Destroy();
            };
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
        case ZOMBIE_CAN_CYCLE_SPAWN:
            _temp = _sc.m_fTimeCanCycleSpawn;
            break;
        case ZOMBIE_AUTO_CONFIRM_SPAWN:
            _temp = _sc.m_fTimeAutoConfirmSpawn;
            break;
        case ZOMBIE_FINISH_EMERGE:
            _temp = _sc.m_fTimeFinishEmerge;
            break;
        case ZOMBIE_HEAVY_FOOTSTEP:
            _temp = _sc.m_fTimeNextFootstep;
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
        // burst does), and deleting afterwards would eat that re-queue
        _sc.m_tblEventQueue.rawdelete( _nearestEvent );

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

            case EVENT_ENGIE_THROW_BEACON:
                _sc.m_hZombieAbility.ThrowBeaconProjectile();
                break;

            case EVENT_PYRO_SPEW_NEXT_BLOB:
                _sc.m_hZombieAbility.ThrowSpewBlob();
                break;

            case EVENT_ENGIE_BEACON_EXIT_ROOT:
                SetPropFloat( _sc.m_hZombieWep, "m_flNextPrimaryAttack", 0.0 );
                _sc.m_hZombieAbility.ExitRoot();
                break;

            case EVENT_HEAVY_THROW_ROCK:
                _sc.m_hZombieAbility.ThrowRockProjectile();
                break;

            case EVENT_HEAVY_END_THROW:
                SetPropFloat( _sc.m_hZombieWep, "m_flNextPrimaryAttack", 0.0 );
                _sc.m_hZombieAbility.EndThrowWindup();
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

            case EVENT_KILL_TEMP_ENTITY: // todo mess

                if ( "m_hTempEntity" in _sc && _sc.m_hTempEntity != null && _sc.m_hTempEntity.IsValid() )
                    _sc.m_hTempEntity.Destroy();

                this.SetForcedTauntCam ( 0 );
                this.RemoveCond        ( TF_COND_TAUNTING );

                _sc.m_hZombieAbility.PutAbilityOnCooldown();
                this.RemoveCustomAttribute ( "no_attack" );
                break;

            case EVENT_SPY_RECLOAK:

                this.AddCondEx( TF_COND_STEALTHED, 0.3, null );
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
                return;
        };
    };

    return;
};

CreateBeaconRespawnRoom <- function( _vecOrigin )
{
    local _hRoom = Entities.CreateByClassname( "func_respawnroom" );

    if ( _hRoom == null )
        return null;

    _hRoom.KeyValueFromString ( "targetname", "engie_beacon_respawnroom" );
    _hRoom.KeyValueFromInt    ( "TeamNum",    TF_TEAM_BLUE );
    _hRoom.KeyValueFromInt    ( "spawnflags", 1 ); // clients
    _hRoom.SetOrigin          ( _vecOrigin );

    _hRoom.DispatchSpawn();

    _hRoom.SetSolid ( 2 ); // SOLID_BBOX
    _hRoom.SetSize  ( Vector( -ENGIE_BEACON_ROOM_HALF_WIDTH, -ENGIE_BEACON_ROOM_HALF_WIDTH, 0 ),
                      Vector(  ENGIE_BEACON_ROOM_HALF_WIDTH,  ENGIE_BEACON_ROOM_HALF_WIDTH,
                               ENGIE_BEACON_ROOM_HEIGHT ) );

    SetPropInt ( _hRoom, "m_Collision.m_usSolidFlags", 12 ); // FSOLID_NOT_SOLID | FSOLID_TRIGGER
    SetPropInt ( _hRoom, "m_iTeamNum", TF_TEAM_BLUE );

    EntFireByHandle ( _hRoom, "Enable", "", 0, null, null );
    return _hRoom;
};

UnstickPlayersFromBeacon <- function( _vecBeaconPos )
{
    local _vecBoxMins = ( _vecBeaconPos + Vector( -ENGIE_BEACON_HULL_HALF, -ENGIE_BEACON_HULL_HALF, 0 ) );
    local _vecBoxMaxs = ( _vecBeaconPos + Vector(  ENGIE_BEACON_HULL_HALF,  ENGIE_BEACON_HULL_HALF,
                                                   ENGIE_BEACON_HULL_HEIGHT ) );

    local _hPlayer = null;

    while ( _hPlayer = Entities.FindByClassnameWithin( _hPlayer, "player", _vecBeaconPos,
                                                       ENGIE_BEACON_UNSTICK_RADIUS ) )
    {
        if ( _hPlayer == null || GetPropInt( _hPlayer, "m_lifeState" ) != 0 )
            continue;

        local _vecOrg  = _hPlayer.GetOrigin();
        local _vecMins = ( _vecOrg + _hPlayer.GetBoundingMins() );
        local _vecMaxs = ( _vecOrg + _hPlayer.GetBoundingMaxs() );

        if ( _vecMins.x > _vecBoxMaxs.x || _vecMaxs.x < _vecBoxMins.x ||
             _vecMins.y > _vecBoxMaxs.y || _vecMaxs.y < _vecBoxMins.y ||
             _vecMins.z > _vecBoxMaxs.z || _vecMaxs.z < _vecBoxMins.z )
            continue;

        local _vecLift = Vector( _vecOrg.x, _vecOrg.y,
                                 ( _vecBoxMaxs.z + ENGIE_BEACON_UNSTICK_CLEARANCE ) );

        local _tblRoom =
        {
            start    =  _vecLift,
            end      =  _vecLift,
            hullmin  =  _hPlayer.GetBoundingMins(),
            hullmax  =  _hPlayer.GetBoundingMaxs(),
            mask     =  MASK_PLAYERSOLID_BRUSHONLY,
            ignore   =  _hPlayer,
        };

        TraceHull( _tblRoom );

        if ( ( "startsolid" in _tblRoom ) && _tblRoom.startsolid )
            continue;

        _hPlayer.SetOrigin( _vecLift );
    };

    return;
};

RemoveBeaconFromArray <- function( _hBeacon )
{
    for ( local i = ::arrZombieBeacons.len() - 1; i >= 0; i-- )
    {
        local _hStored = ::arrZombieBeacons[ i ];

        if ( _hStored == _hBeacon || _hStored == null || !_hStored.IsValid() )
            ::arrZombieBeacons.remove( i );
    };

    return;
};

BreakHeavyRockVisual <- function( _hVisual, _hShell = null )
{
    local _vecOrigin  =  null;
    local _vecVel     =  Vector( 0, 0, 0 );

    if ( _hVisual != null && _hVisual.IsValid() )
    {
        _vecOrigin = _hVisual.GetOrigin();
        _hVisual.Destroy();
    };

    if ( _hShell != null && _hShell.IsValid() )
    {
        if ( _vecOrigin == null )
            _vecOrigin = _hShell.GetOrigin();

        _vecVel = ( _hShell.GetPhysVelocity() * HEAVY_ROCK_GIB_VEL_SCALE );
    };

    if ( _vecOrigin == null )
        return;

    SpawnHeavyRockGibs( _vecOrigin, _vecVel );

    return;
};

SpawnHeavyRockGibs <- function( _vecOrigin, _vecVel = null )
{
    if ( _vecVel == null )
        _vecVel = Vector( 0, 0, 0 );

    foreach ( _szGibModel in ARR_MDL_HEAVY_ROCK_GIBS )
    {
        local _hGib = Entities.CreateByClassname( "prop_physics_override" );

        _hGib.SetModel  ( _szGibModel );
        _hGib.SetOrigin ( _vecOrigin );
        _hGib.SetAngles ( RandomFloat( 0, 360 ), RandomFloat( 0, 360 ), RandomFloat( 0, 360 ) );

        SetPropInt ( _hGib, "m_CollisionGroup", COLLISION_GROUP_DEBRIS );

        _hGib.DispatchSpawn();
        _hGib.SetModelScale ( HEAVY_ROCK_MODEL_SCALE, 0.0 );

        _hGib.SetPhysVelocity ( _vecVel + Vector( RandomFloat( -HEAVY_ROCK_GIB_SCATTER, HEAVY_ROCK_GIB_SCATTER ),
                                                  RandomFloat( -HEAVY_ROCK_GIB_SCATTER, HEAVY_ROCK_GIB_SCATTER ),
                                                  RandomFloat( 0, HEAVY_ROCK_GIB_LIFT ) ) );

        _hGib.SetPhysAngularVelocity ( Vector( RandomFloat( -HEAVY_ROCK_GIB_SPIN, HEAVY_ROCK_GIB_SPIN ),
                                               RandomFloat( -HEAVY_ROCK_GIB_SPIN, HEAVY_ROCK_GIB_SPIN ),
                                               RandomFloat( -HEAVY_ROCK_GIB_SPIN, HEAVY_ROCK_GIB_SPIN ) ) );

        EntFireByHandle ( _hGib, "Kill", "", HEAVY_ROCK_GIB_LIFETIME, null, null );
    };

    return;
};

SpawnBeaconGibs <- function( _vecOrigin )
{
    foreach ( _szGibModel in ARR_MDL_BEACON_GIBS )
    {
        local _hGib = Entities.CreateByClassname( "prop_physics_override" );

        _hGib.SetModel  ( _szGibModel );
        _hGib.SetOrigin ( _vecOrigin + Vector( 0, 0, 12 ) );

        SetPropInt ( _hGib, "m_CollisionGroup", COLLISION_GROUP_DEBRIS );

        _hGib.DispatchSpawn();

        SetPropInt ( _hGib, "m_nSkin", ENGIE_BEACON_SKIN );

        _hGib.SetPhysVelocity    ( Vector( RandomFloat( -150, 150 ),
                                           RandomFloat( -150, 150 ),
                                           RandomFloat( 150, 300 ) ) );
        _hGib.SetAngularVelocity ( RandomFloat( -360, 360 ),
                                   RandomFloat( -360, 360 ),
                                   RandomFloat( -360, 360 ) );

        EntFireByHandle ( _hGib, "Kill", "", 10.0, null, null );
    };

    return;
};

HeavyRockScreenShake <- function( _vecOrigin )
{
    local _hShake = SpawnEntityFromTable( "env_shake",
    {
        origin      =  _vecOrigin,
        amplitude   =  HEAVY_ROCK_SHAKE_AMPLITUDE,
        radius      =  HEAVY_ROCK_SHAKE_RADIUS,
        duration    =  HEAVY_ROCK_SHAKE_DURATION,
        frequency   =  HEAVY_ROCK_SHAKE_FREQUENCY,
        spawnflags  =  4,
    } );

    if ( _hShake == null || !_hShake.IsValid() )
        return;

    EntFireByHandle ( _hShake, "StartShake", "", 0, null, null );
    EntFireByHandle ( _hShake, "Kill", "", ( HEAVY_ROCK_SHAKE_DURATION + 0.5 ), null, null );

    return;
};

IsDenyVolumeActive <- function( _hEnt )
{
    if ( !( GetPropInt( _hEnt, "m_Collision.m_usSolidFlags" ) & 8 ) )
        return false;

    local _bDisabled = false;
    try { _bDisabled = GetPropBool( _hEnt, "m_bDisabled" ); } catch ( e ) {};

    return !_bDisabled;
};

IsPointInEntityBounds <- function( _vecPoint, _szClassname, _iTeam = 0, _hIgnore = null )
{
    local _hEnt = null;

    while ( _hEnt = Entities.FindByClassname( _hEnt, _szClassname ) )
    {
        if ( _iTeam != 0 && _hEnt.GetTeam() != _iTeam )
            continue;

        if ( !IsDenyVolumeActive( _hEnt ) )
            continue;

        local _vecMins = ( _hEnt.GetOrigin() + _hEnt.GetBoundingMins() );
        local _vecMaxs = ( _hEnt.GetOrigin() + _hEnt.GetBoundingMaxs() );

        if ( _vecPoint.x < _vecMins.x || _vecPoint.x > _vecMaxs.x ||
             _vecPoint.y < _vecMins.y || _vecPoint.y > _vecMaxs.y ||
             _vecPoint.z < _vecMins.z || _vecPoint.z > _vecMaxs.z )
            continue;

        local _iSolidFlags = GetPropInt( _hEnt, "m_Collision.m_usSolidFlags" );

        SetPropInt( _hEnt, "m_Collision.m_usSolidFlags", ( _iSolidFlags & ~12 ) );

        local _tblTrace =
        {
            start  =  _vecPoint,
            end    =  ( _vecPoint + Vector( 0, 0, 1 ) ),
            mask   =  -1, // every contents bit - trigger brushes carry odd contents
        };

        if ( _hIgnore != null )
            _tblTrace.ignore <- _hIgnore;

        TraceLineEx( _tblTrace );

        SetPropInt( _hEnt, "m_Collision.m_usSolidFlags", _iSolidFlags );

        if ( ( "enthit" in _tblTrace ) && _tblTrace.enthit == _hEnt &&
             ( ( ( "startsolid" in _tblTrace ) && _tblTrace.startsolid ) || _tblTrace.hit ) )
        {
            return true;
        };
    };

    return false;
};

IsPointInNoBuild <- function( _vecPoint, _hIgnore = null )
{
    return IsPointInEntityBounds( _vecPoint, "func_nobuild", 0, _hIgnore );
};

IsPointInRespawnRoom <- function( _vecPoint, _iTeam = 0, _hIgnore = null )
{
    return IsPointInEntityBounds( _vecPoint, "func_respawnroom", _iTeam, _hIgnore );
};

SweepVsTriggerHurt <- function( _vecStart, _vecEnd, _flRadius = 0.0 )
{
    local _arrS = [ _vecStart.x, _vecStart.y, _vecStart.z ];
    local _arrD = [ ( _vecEnd.x - _vecStart.x ),
                    ( _vecEnd.y - _vecStart.y ),
                    ( _vecEnd.z - _vecStart.z ) ];

    local _bHit      = false;
    local _flBest    = 1.0;
    local _iBestAxis = -1;
    local _flBestSgn = 0.0;

    local _hEnt = null;

    while ( _hEnt = Entities.FindByClassname( _hEnt, "trigger_hurt" ) )
    {
        if ( !IsDenyVolumeActive( _hEnt ) )
            continue;

        local _vecOrg  = _hEnt.GetOrigin();
        local _vecMins = ( _vecOrg + _hEnt.GetBoundingMins() );
        local _vecMaxs = ( _vecOrg + _hEnt.GetBoundingMaxs() );

        local _arrMn = [ ( _vecMins.x - _flRadius ),
                         ( _vecMins.y - _flRadius ),
                         ( _vecMins.z - _flRadius ) ];
        local _arrMx = [ ( _vecMaxs.x + _flRadius ),
                         ( _vecMaxs.y + _flRadius ),
                         ( _vecMaxs.z + _flRadius ) ];

        local _flEnter = 0.0;
        local _flExit  = 1.0;
        local _iAxis   = -1;
        local _flSgn   = 0.0;
        local _bMiss   = false;

        for ( local i = 0; i < 3; i++ )
        {
            if ( fabs( _arrD[ i ] ) < 0.000001 )
            {
                if ( _arrS[ i ] < _arrMn[ i ] || _arrS[ i ] > _arrMx[ i ] )
                {
                    _bMiss = true;
                    break;
                };

                continue;
            };

            local _flT1 = ( ( _arrMn[ i ] - _arrS[ i ] ) / _arrD[ i ] );
            local _flT2 = ( ( _arrMx[ i ] - _arrS[ i ] ) / _arrD[ i ] );
            local _flN  = -1.0;

            if ( _flT1 > _flT2 )
            {
                local _flTmp = _flT1;
                _flT1 = _flT2;
                _flT2 = _flTmp;
                _flN  = 1.0;
            };

            if ( _flT1 > _flEnter )
            {
                _flEnter = _flT1;
                _iAxis   = i;
                _flSgn   = _flN;
            };

            if ( _flT2 < _flExit )
                _flExit = _flT2;

            if ( _flEnter > _flExit )
            {
                _bMiss = true;
                break;
            };
        };

        if ( _bMiss )
            continue;

        if ( !_bHit || _flEnter < _flBest )
        {
            _bHit      = true;
            _flBest    = _flEnter;
            _iBestAxis = _iAxis;
            _flBestSgn = _flSgn;
        };
    };

    if ( !_bHit )
        return null;

    local _vecNormal = Vector( 0, 0, 0 );

    if ( _iBestAxis == 0 )
        _vecNormal = Vector( _flBestSgn, 0, 0 );
    else if ( _iBestAxis == 1 )
        _vecNormal = Vector( 0, _flBestSgn, 0 );
    else if ( _iBestAxis == 2 )
        _vecNormal = Vector( 0, 0, _flBestSgn );

    return {
        fraction    =  _flBest,
        pos         =  ( _vecStart + ( ( _vecEnd - _vecStart ) * _flBest ) ),
        normal      =  _vecNormal,
        startsolid  =  ( _iBestAxis == -1 ),
    };
};

IsPointInTriggerHurt <- function( _vecPoint, _hIgnore = null )
{
    return ( SweepVsTriggerHurt( _vecPoint, _vecPoint, 0.0 ) != null );
};

RefundBeaconCooldown <- function( _hOwner, _flFraction )
{
    if ( _hOwner == null || !_hOwner.IsValid() )
        return;

    local _flLeft = _hOwner.HowLongUntilAct( ZOMBIE_ABILITY_CAST );

    if ( _flLeft <= 0 )
        return;

    _hOwner.SetNextActTime( ZOMBIE_ABILITY_CAST, _flLeft * ( 1.0 - _flFraction ) );
    return;
};

// --------------------------------------------------------------------------------------- //
// splat stuff                                                                             //
// --------------------------------------------------------------------------------------- //
SplatUnitVector <- function( _vecIn, _vecFallback )
{
    if ( _vecIn == null )
        return _vecFallback;

    local _flLen = _vecIn.Length();

    if ( _flLen < 0.001 )
        return _vecFallback;

    return Vector( ( _vecIn.x / _flLen ), ( _vecIn.y / _flLen ), ( _vecIn.z / _flLen ) );
};

SplatPlaneZAt <- function( _vecOn, _vecNormal, _flDX, _flDY )
{
    local _flNz = _vecNormal.z;

    if ( _flNz < SPLAT_NORMAL_Z_FLOOR )
        _flNz = SPLAT_NORMAL_Z_FLOOR;

    return ( _vecOn.z - ( ( ( _vecNormal.x * _flDX ) + ( _vecNormal.y * _flDY ) ) / _flNz ) );
};

SplatLinkClear <- function( _vecA, _vecANormal, _vecB, _vecBNormal, _hIgnore )
{
    local _tblWall =
    {
        start  =  ( _vecA + ( _vecANormal * SPLAT_FILL_WALL_Z ) ),
        end    =  ( _vecB + ( _vecBNormal * SPLAT_FILL_WALL_Z ) ),
        mask   =  MASK_SOLID_BRUSHONLY,
        ignore =  _hIgnore,
    };

    TraceLineEx( _tblWall );

    return ( !_tblWall.hit );
};

SplatStepTo <- function( _vecFrom, _vecFromNormal, _flX, _flY, _flStepLen, _hIgnore )
{
    local _flDX = ( _flX - _vecFrom.x );
    local _flDY = ( _flY - _vecFrom.y );

    local _flPredict = SplatPlaneZAt( _vecFrom, _vecFromNormal, _flDX, _flDY );
    local _flCap     = ( _flStepLen * SPLAT_PREDICT_CAP_MULT );

    if ( _flPredict > ( _vecFrom.z + _flCap ) ) { _flPredict = ( _vecFrom.z + _flCap ) };
    if ( _flPredict < ( _vecFrom.z - _flCap ) ) { _flPredict = ( _vecFrom.z - _flCap ) };

    local _flHigh = ( ( _flPredict > _vecFrom.z ) ? _flPredict : _vecFrom.z );
    local _flLow  = ( ( _flPredict < _vecFrom.z ) ? _flPredict : _vecFrom.z );
    local _flBottom = ( _flLow - SPLAT_STEP_DOWN - _flStepLen );
    local _arrStarts = [ ( _flHigh + ( _flStepLen * SPLAT_PROBE_UP_MULT ) ), ( _flHigh + SPLAT_STEP_UP ) ];

    foreach ( _flStart in _arrStarts )
    {
        local _tblDrop =
        {
            start  =  Vector( _flX, _flY, _flStart ),
            end    =  Vector( _flX, _flY, _flBottom ),
            mask   =  MASK_SOLID_BRUSHONLY,
            ignore =  _hIgnore,
        };

        TraceLineEx( _tblDrop );

        if ( ( "startsolid" in _tblDrop ) && _tblDrop.startsolid )
            continue;

        // no hit! we didn't get a hit!
        if ( !_tblDrop.hit )
            break;

        local _vecNormal = SplatUnitVector( _tblDrop.plane_normal, Vector( 0, 0, 1 ) );

        // too steep bro
        if ( _vecNormal.z < SPLAT_MIN_SURFACE_Z )
            continue;

        local _flZ    = _tblDrop.pos.z;
        local _flRise = ( _flZ - _flPredict );

        if ( _flRise > SPLAT_STEP_UP )
        {
            if ( _vecNormal.z > SPLAT_SLOPE_NORMAL_Z )
                continue;

            local _flBack     = SplatPlaneZAt( Vector( _flX, _flY, _flZ ), _vecNormal, -_flDX, -_flDY );
            local _flRiseBack = ( _vecFrom.z - _flBack );

            if ( ( _flRiseBack > SPLAT_STEP_UP ) || ( _flRiseBack < -SPLAT_STEP_DOWN ) )
                continue;
        }
        else if ( _flRise < -SPLAT_STEP_DOWN )
        {
            break;
        };

        return { pos = Vector( _flX, _flY, _flZ ), normal = _vecNormal };
    };

    return null;
};

SplatCascadeTo <- function( _vecFrom, _vecFromNormal, _flX, _flY, _flStepLen, _hIgnore )
{
    local _flSubLen   = ( _flStepLen.tofloat() / SPLAT_CASCADE_STEPS );
    local _vecCur     = _vecFrom;
    local _vecCurN    = _vecFromNormal;
    local _arrBridge  = [];

    for ( local _i = 1; _i <= SPLAT_CASCADE_STEPS; _i++ )
    {
        local _flFrac = ( _i.tofloat() / SPLAT_CASCADE_STEPS );
        local _flSubX = ( _vecFrom.x + ( ( _flX - _vecFrom.x ) * _flFrac ) );
        local _flSubY = ( _vecFrom.y + ( ( _flY - _vecFrom.y ) * _flFrac ) );

        local _tblStep = SplatStepTo( _vecCur, _vecCurN, _flSubX, _flSubY, _flSubLen, _hIgnore );

        if ( _tblStep == null )
            return null;

        if ( !SplatLinkClear( _vecCur, _vecCurN, _tblStep.pos, _tblStep.normal, _hIgnore ) )
            return null;

        _vecCur  = _tblStep.pos;
        _vecCurN = _tblStep.normal;

        if ( _i < SPLAT_CASCADE_STEPS )
            _arrBridge.append( { pos = _vecCur, normal = _vecCurN } );
    };

    return { pos = _vecCur, normal = _vecCurN, bridge = _arrBridge };
};

SplatNormalToAngles <- function( _vecNormal )
{
    local _flZ = _vecNormal.z;

    if ( _flZ >  1.0 ) { _flZ =  1.0 };
    if ( _flZ < -1.0 ) { _flZ = -1.0 };

    return QAngle( ( acos( _flZ ) * SPLAT_RAD_TO_DEG ),
                   ( atan2( _vecNormal.y, _vecNormal.x ) * SPLAT_RAD_TO_DEG ),
                   0 );
};

SplatNormalToAnglesKV <- function( _vecNormal )
{
    local _ang = SplatNormalToAngles( _vecNormal );

    return format( "%f %f %f", _ang.x, _ang.y, _ang.z );
};

FormSplatCells <- function( _tblShape )
{
    local _iCellSize   =  _tblShape.cellsize;
    local _flConeLen   =  _tblShape.conelength;
    local _flSplashRad =  _tblShape.splashradius;
    local _hIgnore     =  _tblShape.ignore;

    local _vecNormal = Vector( 0, 0, 1 );

    if ( ( "normal" in _tblShape ) && ( _tblShape.normal != null ) )
        _vecNormal = SplatUnitVector( _tblShape.normal, Vector( 0, 0, 1 ) );

    local _vecApex = Vector( _tblShape.apex.x, _tblShape.apex.y, _tblShape.apex.z );

    // landed on something too steep to hold goop - run down it and pool below
    if ( _vecNormal.z < SPLAT_MIN_SURFACE_Z )
    {
        local _vecOff = ( _vecApex + ( _vecNormal * SPLAT_SLIDE_OFFSET ) );

        local _tblSlide =
        {
            start  =  _vecOff,
            end    =  Vector( _vecOff.x, _vecOff.y, ( _vecOff.z - SPLAT_SLIDE_DIST ) ),
            mask   =  MASK_SOLID_BRUSHONLY,
            ignore =  _hIgnore,
        };

        TraceLineEx( _tblSlide );

        if ( _tblSlide.hit && !( ( "startsolid" in _tblSlide ) && _tblSlide.startsolid ) )
        {
            local _vecSlideN = SplatUnitVector( _tblSlide.plane_normal, Vector( 0, 0, 1 ) );

            if ( _vecSlideN.z >= SPLAT_MIN_SURFACE_Z )
            {
                _vecApex   = _tblSlide.pos;
                _vecNormal = _vecSlideN;
            };
        };
    };

    _vecApex = Vector( _vecApex.x, _vecApex.y, ( _vecApex.z + SPLAT_Z_EPSILON ) );

    local _vecDir = SplatUnitVector( _tblShape.dir, Vector( 1, 0, 0 ) );

    local _flDot = ( ( _vecDir.x * _vecNormal.x ) + ( _vecDir.y * _vecNormal.y ) + ( _vecDir.z * _vecNormal.z ) );

    local _vecDirS = SplatUnitVector( Vector( ( _vecDir.x - ( _vecNormal.x * _flDot ) ),
                                              ( _vecDir.y - ( _vecNormal.y * _flDot ) ),
                                              ( _vecDir.z - ( _vecNormal.z * _flDot ) ) ),
                                      null );

    // travel dead along the normal
    if ( _vecDirS == null )
    {
        _vecDirS   = Vector( 1, 0, 0 );
        _flConeLen = 0;
    };

    local _vecPerpS = Vector( ( ( _vecNormal.y * _vecDirS.z ) - ( _vecNormal.z * _vecDirS.y ) ),
                              ( ( _vecNormal.z * _vecDirS.x ) - ( _vecNormal.x * _vecDirS.z ) ),
                              ( ( _vecNormal.x * _vecDirS.y ) - ( _vecNormal.y * _vecDirS.x ) ) );

    // coarse bound on the fill - past the shape's longest x/y reach needs no trace
    local _flMaxReach = _flSplashRad;

    if ( _flConeLen > 0 )
    {
        local _flEndHalfW = ( _tblShape.coneapexhalfw + ( _flConeLen * _tblShape.conespread ) );
        local _flConeMax  = sqrt( ( _flConeLen * _flConeLen ) + ( _flEndHalfW * _flEndHalfW ) );

        if ( _flConeMax > _flMaxReach )
            _flMaxReach = _flConeMax;
    };

    local _arrCells   =  [ { pos = _vecApex, normal = _vecNormal } ];
    local _tblFilled  =  {};
    local _tblOutside =  {};
    local _tblBridged =  {};
    local _flBridgeGrid = ( _iCellSize.tofloat() / SPLAT_CASCADE_STEPS );

    _tblFilled[ "0,0" ] <- true;

    local _arrOffsets = [ [ 1, 0 ], [ -1, 0 ], [ 0, 1 ], [ 0, -1 ] ];
    local _arrQueue   = [ [ 0, 0, _vecApex, _vecNormal ] ];

    while ( _arrQueue.len() > 0 )
    {
        local _arrFrom      = _arrQueue.remove( 0 );
        local _vecParent    = _arrFrom[ 2 ];
        local _vecParentN   = _arrFrom[ 3 ];

        foreach ( _arrOff in _arrOffsets )
        {
            local _iGX = ( _arrFrom[ 0 ] + _arrOff[ 0 ] );
            local _iGY = ( _arrFrom[ 1 ] + _arrOff[ 1 ] );

            local _szKey = format( "%d,%d", _iGX, _iGY );

            if ( ( _szKey in _tblFilled ) || ( _szKey in _tblOutside ) )
                continue;

            local _flOffX = ( _iGX * _iCellSize );
            local _flOffY = ( _iGY * _iCellSize );

            if ( ( ( _flOffX * _flOffX ) + ( _flOffY * _flOffY ) ) > ( _flMaxReach * _flMaxReach ) )
                continue;

            local _flX = ( _vecApex.x + _flOffX );
            local _flY = ( _vecApex.y + _flOffY );

            local _arrBridge = null;
            local _tblStep   = SplatStepTo( _vecParent, _vecParentN, _flX, _flY, _iCellSize, _hIgnore );

            if ( _tblStep == null )
            {
                local _tblCascade = SplatCascadeTo( _vecParent, _vecParentN, _flX, _flY, _iCellSize, _hIgnore );

                if ( _tblCascade == null )
                    continue;

                local _flPredict = SplatPlaneZAt( _vecParent, _vecParentN,
                                                  ( _flX - _vecParent.x ), ( _flY - _vecParent.y ) );

                if ( ( _tblCascade.pos.z > ( _flPredict + SPLAT_STEP_UP ) ) &&
                     ( _tblCascade.normal.z > SPLAT_SLOPE_NORMAL_Z ) )
                    continue;

                _tblStep   = { pos = _tblCascade.pos, normal = _tblCascade.normal };
                _arrBridge = _tblCascade.bridge;
            }
            else if ( !SplatLinkClear( _vecParent, _vecParentN, _tblStep.pos, _tblStep.normal, _hIgnore ) )
            {
                continue;
            };

            local _vecOff = ( _tblStep.pos - _vecApex );
            local _flOut2 = ( ( _vecOff.x * _vecOff.x ) + ( _vecOff.y * _vecOff.y ) + ( _vecOff.z * _vecOff.z ) );
            local _bIn    = ( _flOut2 <= ( _flSplashRad * _flSplashRad ) );

            if ( !_bIn && ( _flConeLen > 0 ) )
            {
                local _flAlong = ( ( _vecOff.x * _vecDirS.x ) + ( _vecOff.y * _vecDirS.y ) + ( _vecOff.z * _vecDirS.z ) );

                if ( ( _flAlong >= 0 ) && ( _flAlong <= _flConeLen ) )
                {
                    local _flPerp = fabs( ( _vecOff.x * _vecPerpS.x ) + ( _vecOff.y * _vecPerpS.y ) + ( _vecOff.z * _vecPerpS.z ) );

                    _bIn = ( _flPerp <= ( _tblShape.coneapexhalfw + ( _flAlong * _tblShape.conespread ) ) );
                };
            };

            if ( !_bIn )
            {
                _tblOutside[ _szKey ] <- true;
                continue;
            };

            local _vecCell = Vector( _tblStep.pos.x, _tblStep.pos.y, ( _tblStep.pos.z + SPLAT_Z_EPSILON ) );

            _tblFilled[ _szKey ] <- true;
            _arrCells.append( { pos = _vecCell, normal = _tblStep.normal } );
            _arrQueue.append( [ _iGX, _iGY, _vecCell, _tblStep.normal ] );

            if ( _arrBridge != null )
            {
                foreach ( _tblBridge in _arrBridge )
                {
                    local _szBKey = format( "%d,%d", ( _tblBridge.pos.x / _flBridgeGrid ).tointeger(),
                                                     ( _tblBridge.pos.y / _flBridgeGrid ).tointeger() );

                    if ( _szBKey in _tblBridged )
                        continue;

                    _tblBridged[ _szBKey ] <- true;

                    _arrCells.append( { pos = Vector( _tblBridge.pos.x, _tblBridge.pos.y,
                                                      ( _tblBridge.pos.z + SPLAT_Z_EPSILON ) ),
                                        normal = _tblBridge.normal } );
                };
            };
        };
    };

    local _flHalfCell = ( _iCellSize * 0.5 );

    local _vecMins = Vector(  FLT_MAX,  FLT_MAX, 0 );
    local _vecMaxs = Vector( -FLT_MAX, -FLT_MAX, 0 );

    foreach ( _tblCell in _arrCells )
    {
        if ( _tblCell.pos.x < _vecMins.x ) { _vecMins.x = _tblCell.pos.x };
        if ( _tblCell.pos.y < _vecMins.y ) { _vecMins.y = _tblCell.pos.y };
        if ( _tblCell.pos.x > _vecMaxs.x ) { _vecMaxs.x = _tblCell.pos.x };
        if ( _tblCell.pos.y > _vecMaxs.y ) { _vecMaxs.y = _tblCell.pos.y };
    };

    _vecMins.x -= _flHalfCell;
    _vecMins.y -= _flHalfCell;
    _vecMaxs.x += _flHalfCell;
    _vecMaxs.y += _flHalfCell;

    return { cells = _arrCells, mins = _vecMins, maxs = _vecMaxs, cellsize = _iCellSize,
             apex = _vecApex, normal = _vecNormal };
};

IsPointInSplat <- function( _vecPoint, _tblSplat )
{
    if ( _tblSplat == null )
        return false;

    if ( ( _vecPoint.x < _tblSplat.mins.x ) || ( _vecPoint.x > _tblSplat.maxs.x ) )
        return false;

    if ( ( _vecPoint.y < _tblSplat.mins.y ) || ( _vecPoint.y > _tblSplat.maxs.y ) )
        return false;

    local _flHalfCell = ( _tblSplat.cellsize * 0.5 );

    foreach ( _tblCell in _tblSplat.cells )
    {
        local _flDX = ( _vecPoint.x - _tblCell.pos.x );
        local _flDY = ( _vecPoint.y - _tblCell.pos.y );

        if ( fabs( _flDX ) > _flHalfCell )
            continue;

        if ( fabs( _flDY ) > _flHalfCell )
            continue;

        local _flDeltaZ = ( _vecPoint.z - SplatPlaneZAt( _tblCell.pos, _tblCell.normal, _flDX, _flDY ) );

        if ( ( _flDeltaZ < -SPLAT_ZONE_Z_BELOW ) || ( _flDeltaZ > SPLAT_ZONE_Z_ABOVE ) )
            continue;

        return true;
    };

    return false;
};

DrawSplatCells <- function( _tblSplat, _iR, _iG, _iB, _iAlpha, _iBoxHeight, _flLifetime )
{
    if ( _tblSplat == null || _flLifetime <= 0 )
        return;

    local _flHalfCell = ( _tblSplat.cellsize * 0.5 );
    local _flMinCos   = ( 1.0 / SPLAT_DRAW_STRETCH_MAX );
    local _vecColor   = Vector( _iR, _iG, _iB );

    foreach ( _tblCell in _tblSplat.cells )
    {
        local _flCos = _tblCell.normal.z;

        if ( _flCos < _flMinCos )
            _flCos = _flMinCos;

        local _flHalfX = ( _flHalfCell / _flCos );

        try
        {
            DebugDrawBoxAngles( _tblCell.pos,
                                Vector( -_flHalfX, -_flHalfCell, 0 ),
                                Vector(  _flHalfX,  _flHalfCell, _iBoxHeight ),
                                SplatNormalToAngles( _tblCell.normal ),
                                _vecColor,
                                _iAlpha,
                                _flLifetime );
        }
        catch ( _e )
        {
            DebugDrawBox( _tblCell.pos,
                          Vector( -_flHalfCell, -_flHalfCell, 0 ),
                          Vector(  _flHalfCell,  _flHalfCell, _iBoxHeight ),
                          _iR, _iG, _iB,
                          _iAlpha,
                          _flLifetime );
        };
    };

    return;
};

SpawnSplatFireFX <- function( _tblSplat, _szEffect, _flLifetime )
{
    if ( _tblSplat == null || _tblSplat.cells.len() == 0 || _flLifetime <= 0 )
        return null;

    local _iMax = SPLAT_FIRE_MAX_CP;

    if ( _iMax > ( SPLAT_FIRE_ENGINE_MAX_CP + 1 ) )
        _iMax = ( SPLAT_FIRE_ENGINE_MAX_CP + 1 );

    local _arrCells = _tblSplat.cells;
    local _iCells   = _arrCells.len();

    local _flStride = 1.0;

    if ( _iCells > _iMax )
        _flStride = ( _iCells.tofloat() / _iMax );

    local _arrPicked = [];

    for ( local _i = 0; _arrPicked.len() < _iMax; _i++ )
    {
        local _iIdx = ( _i * _flStride ).tointeger();

        if ( _iIdx >= _iCells )
            break;

        _arrPicked.append( _arrCells[ _iIdx ] );
    };

    ::iSplatFireSerial <- ( ( ::iSplatFireSerial + 1 ) % 10000 );

    local _szPrefix = ( SPLAT_FIRE_ENT_PREFIX + ::iSplatFireSerial + "_" );

    local _arrTargets = [];
    local _tblKeys    =
    {
        effect_name   =  _szEffect,
        start_active  =  "0",
        targetname    =  ( _szPrefix + "fx" ),
        origin        =  _arrPicked[ 0 ].pos,
        angles        =  SplatNormalToAnglesKV( _arrPicked[ 0 ].normal ),
    };

    for ( local _i = 1; _i < _arrPicked.len(); _i++ )
    {
        local _szName  = ( _szPrefix + _i );

        local _hTarget = SpawnEntityFromTable( "info_target",
        {
            targetname  =  _szName,
            origin      =  _arrPicked[ _i ].pos,
            angles      =  SplatNormalToAnglesKV( _arrPicked[ _i ].normal ),
            spawnflags  =  SPLAT_FIRE_TARGET_TRANSMIT,
        } );

        if ( _hTarget == null )
            break;

        _arrTargets.append( _hTarget );

        _tblKeys[ ( "cpoint" + _i ) ] <- _szName;
    };

    local _hFX = SpawnEntityFromTable( "info_particle_system", _tblKeys );

    if ( _hFX == null )
    {
        foreach ( _hTarget in _arrTargets )
            _hTarget.Destroy();

        return null;
    };

    _hFX.ValidateScriptScope();

    local _sc = _hFX.GetScriptScope();

    _sc.m_arrCPEnts   <-  _arrTargets;
    _sc.m_bStopped    <-  false;
    _sc.m_flStopTime  <-  ( Time() + _flLifetime ).tofloat();
    _sc.m_flKillTime  <-  ( Time() + _flLifetime + SPLAT_FIRE_FADE_TIME ).tofloat();

    AddThinkToEnt( _hFX, "SplatFireThink" );

    EntFireByHandle( _hFX, "Start", "", -1, null, null );


    return _hFX;
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

    if ( !( "m_hOwnedBeacon" in _sc ) )
        _sc.m_hOwnedBeacon <- null;

    if ( ( "m_iFlags" in _sc ) && ( _sc.m_iFlags & ZBIT_SPEWED ) )
        this.RemoveSpewDebuff();

    this.SpoofZombieBuffFX( false );

    if ( ( "m_hTempEntity" in _sc ) && _sc.m_hTempEntity != null && _sc.m_hTempEntity.IsValid() )
        _sc.m_hTempEntity.Destroy();

    // unwind anything a death mid-windup/picker left behind - the event queue that
    // was going to clean these up gets wiped right below, and the handles get nulled
    this.LockInPlace          ( false );
    this.SetForcedTauntCam    ( 0 );
    this.DestroySpawnPickerHUD();
    this.DestroySpawnBody     ();
    this.SetSpawnBodyHidden   ( false );

    _sc.m_iFlags                <- ZBIT_SURVIVOR;
    _sc.m_tblEventQueue         <- { };
    _sc.m_szCurrentHUDString    <- "";

    _sc.m_bCanPlay              <- false;
    _sc.m_bDeathWasModified     <- false;
    _sc.m_bLastManStanding      <- false;
    _sc.m_bZombieHUDInitialized <- false;
    _sc.m_bLastThree            <- false;
    _sc.m_bStandingOnSpit       <- false;
    _sc.m_bPreviewAtBeacon      <- false;

    _sc.m_hZombieWep            <- null;
    _sc.m_hSpitSlowWep          <- null;
    _sc.m_hZombieArms           <- null;
    _sc.m_hZombieWearable       <- null;
    _sc.m_hZombieFXWearable     <- null;
    _sc.m_hZombieAbility        <- null;
    _sc.m_hTempEntity           <- null;
    _sc.m_bSoldierFallSfx       <- false;
    _sc.m_hHUDText              <- null;
    _sc.m_hHUDTextAbilityName   <- null;
    _sc.m_hLinkedSpitPool       <- null;
    _sc.m_hSpawnPickerControlsText  <- null;
    _sc.m_hSpawnPickerCountdownText <- null;
    _sc.m_hSpawnPreviewEnt          <- null;
    _sc.m_hSpawnBody                <- null;
    _sc.m_tblSpawnBodyRender        <- {};
    _sc.m_iSpawnBodySequence        <- -1;
    _sc.m_flSpawnBodyCycleLast      <- 0.0;
    _sc.m_bSpawnBodyHold            <- false;
    _sc.m_bSpawnBodyHeld            <- false;
    _sc.m_fSpitVMReleaseTime        <- 0.0;

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
    _sc.m_fTimeCanCycleSpawn    <- 0.0;
    _sc.m_fTimeAutoConfirmSpawn <- 0.0;
    _sc.m_fTimeFinishEmerge     <- 0.0;
    _sc.m_fSpewEndTime           <- 0.0;
    _sc.m_fSpewDrainEndTime      <- 0.0;
    _sc.m_fTimeNextSpewTick      <- 0.0;
    _sc.m_fTimeNextFootstep     <- 0.0;

    _sc.m_vecEmergeStart        <- Vector( 0, 0, 0 );
    _sc.m_vecEmergeEnd          <- Vector( 0, 0, 0 );

    _sc.m_iCurrentAbilityType   <- 0;
    _sc.m_iAbilityState         <- 0;
    _sc.m_iSpawnIndex           <- 0;
    _sc.m_iButtonsLast          <- 0;
    _sc.m_iSpawnCountdownLast   <- -1;

    AddThinkToEnt( this, "PlayerThink" );

    return true;
};

CTFPlayer_ModifyJumperWeapons <- function()
{
    return; // we dont do this no more
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

        case ZOMBIE_CAN_CYCLE_SPAWN:
            return ( _sc.m_fTimeCanCycleSpawn < 0 ? 0 : _sc.m_fTimeCanCycleSpawn - Time() );

        case ZOMBIE_AUTO_CONFIRM_SPAWN:
            return ( _sc.m_fTimeAutoConfirmSpawn < 0 ? 0 : _sc.m_fTimeAutoConfirmSpawn - Time() );

        case ZOMBIE_FINISH_EMERGE:
            return ( _sc.m_fTimeFinishEmerge < 0 ? 0 : _sc.m_fTimeFinishEmerge - Time() );

        default:
            return false;
    };
};

CTFPlayer_PlayZombieVO <- function()
{
    local _iClass = this.GetPlayerClass();

    if ( _iClass == TF_CLASS_SPY )
        return;

    if ( bZombieVOUseMoan )
    {
        EmitSoundOn( SFX_ZOMBIE_VO_MOAN, this );
        return;
    };

    if ( _iClass < 0 || _iClass >= szArrZombieVOEvilLaugh.len() )
        return;

    EmitSoundOn( szArrZombieVOEvilLaugh[ _iClass ], this );
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
        case ZOMBIE_CAN_CYCLE_SPAWN:
            _sc.m_fTimeCanCycleSpawn <- ( _nextTime );
            break;
        case ZOMBIE_AUTO_CONFIRM_SPAWN:
            _sc.m_fTimeAutoConfirmSpawn <- ( _nextTime );
            break;
        case ZOMBIE_FINISH_EMERGE:
            _sc.m_fTimeFinishEmerge <- ( _nextTime );
            break;
        case ZOMBIE_HEAVY_FOOTSTEP:
            _sc.m_fTimeNextFootstep <- ( _nextTime );
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

// the deferred inventory application can strip the held weapon and leave the hands
// empty (a-pose) - resettle onto whatever survived
CTFPlayer_FixNullActiveWeapon <- function()
{
    if ( GetPropInt( this, "m_lifeState" ) != ALIVE )
        return;

    if ( this.GetActiveWeapon() != null )
        return;

    for ( local i = 0; i < TF_WEAPON_COUNT; i++ )
    {
        local _hWeapon = GetPropEntityArray( this, "m_hMyWeapons", i );

        if ( _hWeapon != null )
        {
            this.Weapon_Switch( _hWeapon );
            return;
        };
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

CTFPlayer_DestroyMedicDispenser <- function()
{
    local _sc = this.GetScriptScope();

    if ( _sc == null )
        return;

    foreach ( _szHandle in [ "m_hMedicDispenser", "m_hMedicDispenserTouchTrigger" ] )
    {
        if ( ( _szHandle in _sc ) && _sc[ _szHandle ] != null && _sc[ _szHandle ].IsValid() )
            _sc[ _szHandle ].Destroy();

        _sc[ _szHandle ] <- null;
    };

    local _hDispenser = null;
    while ( _hDispenser = Entities.FindByClassname( _hDispenser, "pd_dispenser" ) )
    {
        if ( _hDispenser.GetOwner() == this )
        {
            _hDispenser.Destroy();
        };
    };

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

// _bWithDamage: direct blob hits drain hp, ground goop is movement-only
CTFPlayer_ApplySpewDebuff <- function( _hAttacker, _bWithDamage = true )
{
    local _sc = this.GetScriptScope();

    local _bWasSpewed = ( ( _sc.m_iFlags & ZBIT_SPEWED ) != 0 );

    // a drain already running means this is a re-application, not a fresh blob hit
    local _bDrainWasLive = ( ( "m_fSpewDrainEndTime" in _sc ) &&
                             Time() < _sc.m_fSpewDrainEndTime );

    _sc.m_iFlags       <- ( _sc.m_iFlags | ZBIT_SPEWED );
    _sc.m_fSpewEndTime  <- ( Time() + PYRO_SPEW_DEBUFF_DURATION ).tofloat();
    _sc.m_hSpewAttacker <- _hAttacker;

    // the drain runs on its own clock so goop refreshes never extend it
    if ( _bWithDamage )
        _sc.m_fSpewDrainEndTime <- ( Time() + PYRO_SPEW_DEBUFF_DURATION ).tofloat();
    else if ( !( "m_fSpewDrainEndTime" in _sc ) )
        _sc.m_fSpewDrainEndTime <- 0.0;

    _sc.m_hSpewWeapon   <- ( _hAttacker != null && _hAttacker.IsValid() ) ? _hAttacker.GetActiveWeapon() : null;

    if ( !_bWasSpewed )
        _sc.m_fTimeNextSpewTick <- ( Time() + PYRO_SPEW_TICK_INTERVAL ).tofloat();

    // a fresh blob hit drains on contact so the victim gets a damage number right
    // away instead of waiting out the first interval
    if ( _bWithDamage && !_bDrainWasLive )
        _sc.m_fTimeNextSpewTick <- 0.0;

    _sc.m_bSpewHasJetpack <- false;

    for ( local i = 0; i < TF_WEAPON_COUNT; i++ )
    {
        local _hWeapon = GetPropEntityArray( this, "m_hMyWeapons", i );

        if ( _hWeapon == null || !_hWeapon.IsValid() )
            continue;

        if ( _hWeapon.GetClassname() == "tf_weapon_rocketpack" )
        {
            _sc.m_bSpewHasJetpack <- true;
            break;
        };
    };

    if ( !( "m_hSpewDripFX" in _sc ) || _sc.m_hSpewDripFX == null || !_sc.m_hSpewDripFX.IsValid() )
    {
        local _hDripFX = SpawnEntityFromTable( "info_particle_system",
        {
            effect_name  = FX_SPEW_DRIP,
            start_active = "1",
            origin       = this.GetOrigin(),
        });

        EntFireByHandle( _hDripFX, "SetParent", "!activator", 0, this, this );

        _sc.m_hSpewDripFX <- _hDripFX;
    };

    // silence movement abilities - timed attribs clean themselves up
    this.AddCustomAttribute( "damage force reduction",        PYRO_SPEW_KNOCKBACK_MULT, PYRO_SPEW_DEBUFF_DURATION );

    this.SetSpewSelfPushOnWeapons( true );
    this.AddCustomAttribute( "air dash count",                -1,                      PYRO_SPEW_DEBUFF_DURATION );
    this.RemoveCond        ( TF_COND_PARACHUTE_ACTIVE );

    SetPropInt( this, "m_nRenderMode", kRenderTransColor );
    SetPropInt( this, "m_clrRender",   PYRO_SPEW_TINT );

    this.SetSpewTintOnWearables( true );

    if ( !::bSpewNoScreenOverlay )
        this.SetScriptOverlayMaterial( MAT_SPEW_OVERLAY );

    StopSoundOn       ( SFX_PYRO_SPEW_SONG, this );
    EmitSoundOnClient ( SFX_PYRO_SPEW_SONG, this );

    return;
}

// while the under-quota buff is up every zombie wears the mini-crit swirl, so a
// spy disguised as one stands out by not having it. paint a matching blu swirl on
// them - purely cosmetic, they get no buff out of it. giving them the real cond
// wouldn't work: the effect is coloured off the wearer's actual team, so it would
// hang a red swirl on a "zombie"
CTFPlayer_SpoofZombieBuffFX <- function( _bWanted )
{
    local _sc = this.GetScriptScope();

    if ( !( "m_hZombieBuffSpoofFX" in _sc ) )
        _sc.m_hZombieBuffSpoofFX <- null;

    local _hFX = _sc.m_hZombieBuffSpoofFX;

    if ( _bWanted )
    {
        if ( _hFX != null && _hFX.IsValid() )
            return;

        _hFX = SpawnEntityFromTable( "info_particle_system",
        {
            effect_name   =  FX_ZOMBIE_BUFF_SPOOF,
            start_active  =  "1",
            targetname    =  "zombie_buff_spoof_fx",
            origin        =  this.GetOrigin(),
        });

        EntFireByHandle( _hFX, "SetParent", "!activator", 0, this, this );

        _sc.m_hZombieBuffSpoofFX <- _hFX;
        return;
    };

    if ( _hFX != null && _hFX.IsValid() )
        _hFX.Destroy();

    _sc.m_hZombieBuffSpoofFX <- null;
    return;
};

CTFPlayer_SetSpewSelfPushOnWeapons <- function( _bOn )
{
    for ( local i = 0; i < TF_WEAPON_COUNT; i++ )
    {
        local _hWeapon = GetPropEntityArray( this, "m_hMyWeapons", i );

        if ( _hWeapon == null || !_hWeapon.IsValid() )
            continue;

        if ( _bOn )
        {
            _hWeapon.AddAttribute( "self dmg push force decreased", PYRO_SPEW_SELF_PUSH_MULT,
                                   PYRO_SPEW_DEBUFF_DURATION );
        }
        else
            _hWeapon.RemoveAttribute( "self dmg push force decreased" );
    };

    return;
};

CTFPlayer_RemoveSpewDebuff <- function()
{
    local _sc = this.GetScriptScope();

    _sc.m_iFlags           <- ( _sc.m_iFlags & ~ZBIT_SPEWED );
    _sc.m_fSpewEndTime      <- 0.0;
    _sc.m_fSpewDrainEndTime <- 0.0;

    if ( ( "m_hSpewDripFX" in _sc ) && _sc.m_hSpewDripFX != null && _sc.m_hSpewDripFX.IsValid() )
        _sc.m_hSpewDripFX.Destroy();

    if ( ( "m_hSpewDripFX" in _sc ) )
        _sc.m_hSpewDripFX <- null;

    this.RemoveCustomAttribute( "damage force reduction" );
    this.SetSpewSelfPushOnWeapons( false );
    this.RemoveCustomAttribute( "air dash count" );

    SetPropInt( this, "m_nRenderMode", kRenderNormal );
    SetPropInt( this, "m_clrRender",   0xFFFFFFFF );

    this.SetSpewTintOnWearables( false );

    if ( this.GetScriptOverlayMaterial() == MAT_SPEW_OVERLAY )
        this.SetScriptOverlayMaterial( "" );

    return;
}

CTFPlayer_SetSpewTintOnWearables <- function( _bEnable )
{
    local _iMode  =  ( _bEnable ? kRenderTransColor : kRenderNormal );
    local _iTint  =  ( _bEnable ? PYRO_SPEW_TINT    : 0xFFFFFFFF );

    foreach ( _szClass in ARR_SPEW_TINT_WEARABLES )
    {
        local _hWearable = null;

        while ( _hWearable = Entities.FindByClassname( _hWearable, _szClass ) )
        {
            if ( _hWearable == null || _hWearable.GetOwner() != this )
                continue;

            SetPropInt( _hWearable, "m_nRenderMode", _iMode );
            SetPropInt( _hWearable, "m_clrRender",   _iTint );
        };
    };

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

::arrZombieSpawnPoints <- [];

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

BuildPickerMapSpawnList <- function()
{
    local _list = [];

    foreach ( _hSpawn in ::arrZombieSpawnPoints )
    {
        if ( _hSpawn == null || !_hSpawn.IsValid() )
            continue;

        local _bDisabled = false;
        try { _bDisabled = GetPropBool( _hSpawn, "m_bDisabled" ); } catch ( e ) {}

        if ( _bDisabled )
            continue;

        _list.append( _hSpawn );
    };

    return _list;
};

BuildPickerSpawnList <- function()
{
    local _list = BuildPickerBeaconList();

    _list.extend( BuildPickerMapSpawnList() );

    return _list;
};

// beacons sit at the front of the picker list and always win the default slot -
// past them the map spawns are picked at random so a wave doesn't all pile in
// at the same door
CTFPlayer_PickDefaultSpawnIndex <- function()
{
    local _iBeacons = BuildPickerBeaconList().len();

    if ( _iBeacons > 0 )
        return RandomInt( 0, _iBeacons - 1 );

    local _iMapSpawns = BuildPickerMapSpawnList().len();

    if ( _iMapSpawns < 1 )
        return 0;

    return RandomInt( 0, _iMapSpawns - 1 );
};

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
        };

        _sc.m_tblSpawnBodyRender[ _idx ] <- { ent = _hEnt, mode = _iMode, color = _iColor,
                                              effects = _iEffects };
    };

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

// hide/show the real player
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

        // end of list
        if ( _szName.tolower() == "unknown" )
            return -1;

        if ( _szName.tolower().find( _szNeedle ) != null )
        {
            return _i;
        };
    };

    return -1;
};

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

CTFPlayer_SetSpawnBodyPlaybackRate <- function( _flRate )
{
    local _sc = this.GetScriptScope();

    if ( !( "m_hSpawnBody" in _sc ) || _sc.m_hSpawnBody == null || !_sc.m_hSpawnBody.IsValid() )
        return;

    SetPropFloat ( _sc.m_hSpawnBody, "m_flPlaybackRate", _flRate );
    return;
};

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

    if ( _bSwapped )
        _hBody.ResetSequence( _sc.m_iSpawnBodySequence );

    SetPropFloat ( _hBody, "m_flCycle",        1.0 );
    SetPropFloat ( _hBody, "m_flPlaybackRate", 0.0 );

    _sc.m_flSpawnBodyCycleLast <- 1.0;
    _sc.m_bSpawnBodyHeld       <- true;

    return;
};

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
        _iSeq = 0;
    };

    this.PlaySpawnBodySequence( _iSeq, _flRate, _bHold );
    return;
};

CTFPlayer_CreateSpawnBody <- function( _szSeq, _arrFallbacks, _flRate = 1.0,
                                       _bHold = false, _szScanFor = "",
                                       _iSkin = SPAWN_BODY_SKIN, _iBodygroup = 0 )
{
    local _sc = this.GetScriptScope();

    this.DestroySpawnBody();

    local _hBody = Entities.CreateByClassname( SPAWN_BODY_CLASSNAME );

    if ( _hBody == null )
    {
        this.SetSpawnBodyHidden( false );
        return null;
    };

    _hBody.SetModel  ( szArrZombiePlayerModels[ this.GetPlayerClass() ] );
    _hBody.SetOrigin ( this.GetOrigin() );

    _hBody.KeyValueFromString ( "targetname", SPAWN_BODY_TARGETNAME );
    _hBody.KeyValueFromString ( "solid", "0" );

    if ( _szSeq.len() > 0 )
        _hBody.KeyValueFromString ( "DefaultAnim", _szSeq );

    _hBody.DispatchSpawn();

    SetPropInt ( _hBody, "m_nSkin",    _iSkin );
    SetPropInt ( _hBody, "m_iTeamNum", this.GetTeam() );
    SetPropInt ( _hBody, "m_nBody",    _iBodygroup );

    _hBody.ValidateScriptScope();
    _hBody.GetScriptScope().m_hOwner <- this;

    _sc.m_hSpawnBody <- _hBody;

    this.SetSpawnBodySequence ( _szSeq, _flRate, _arrFallbacks, _szScanFor, _bHold );
    this.SyncSpawnBody        ();

    AddThinkToEnt ( _hBody, "SpawnBodyThink" );
    return _hBody;
};

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
        AddThinkToEnt ( _sc.m_hSpawnBody, null );

        _sc.m_hSpawnBody.Destroy();
    };

    _sc.m_hSpawnBody <- null;
    return;
};

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

    this.LockAllWeapons();

    // no visible/audible uber - plain damage immunity instead
    SetPropInt ( this, "m_takedamage", 0 );

    // sentries shouldn't track a preview, and nobody should be shoved around by one
    this.AddFlag ( FL_NOTARGET );
    this.AddSolidFlags ( FSOLID_NOT_SOLID );
    SetPropInt ( this, "m_CollisionGroup", COLLISION_GROUP_DEBRIS );

    this.AddCondEx ( TF_COND_TEAM_GLOWS, -1, null );

    this.SetScriptOverlayMaterial ( MAT_SPAWN_PICKER_OVERLAY );
    this.SetSpawnBodyHidden ( true );

    // translucent stand-in so the preview isn't a disembodied camera
    local _hPreviewBody = this.CreateSpawnBody( SPAWN_BODY_IDLE_SEQUENCE,
                                                arrSpawnBodyIdleFallbackSeqs,
                                                SPAWN_BODY_IDLE_RATE, false, "",
                                                SPAWN_BODY_SKIN_PLAIN );

    if ( _hPreviewBody != null )
    {
        SetPropInt ( _hPreviewBody, "m_nRenderMode", kRenderTransAlpha );
        SetPropInt ( _hPreviewBody, "m_clrRender",   SPAWN_PICKER_RENDER_ALPHA );
    };

    _sc.m_iSpawnIndex  <- this.PickDefaultSpawnIndex();

    _sc.m_iButtonsLast <- GetPropInt( this, "m_nButtons" );

    this.SetNextActTime ( ZOMBIE_CAN_CYCLE_SPAWN,    SPAWN_PICKER_INPUT_GRACE );
    this.SetNextActTime ( ZOMBIE_AUTO_CONFIRM_SPAWN, SPAWN_PICKER_AUTO_CONFIRM_TIME );

    this.CreateSpawnPickerHUD();

    this.TeleportToSpawnIndex( _sc.m_iSpawnIndex );
    return;
};

CTFPlayer_CreateSpawnPickerHUD <- function()
{
    local _sc = this.GetScriptScope();

    local _hControlsText = SpawnEntityFromTable( "game_text",
    {
        x          =  -1,
        y          =  SPAWN_PICKER_HUD_CONTROLS_Y,
        effect     =  0,
        color      =  "255 255 255",
        color2     =  "0 0 0",
        fadein     =  0.1,
        fadeout    =  0.1,
        holdtime   =  SPAWN_PICKER_AUTO_CONFIRM_TIME + 2,
        fxtime     =  0,
        channel    =  3,
        message    =  STRING_UI_SPAWN_PICKER_CONTROLS,
        spawnflags =  0,
    });

    local _hCountdownText = SpawnEntityFromTable( "game_text",
    {
        x          =  -1,
        y          =  SPAWN_PICKER_HUD_COUNTDOWN_Y,
        effect     =  0,
        color      =  "255 255 255",
        color2     =  "0 0 0",
        fadein     =  0,
        fadeout    =  0.1,
        holdtime   =  2,
        fxtime     =  0,
        channel    =  5,
        message    =  "",
        spawnflags =  0,
    });

    _sc.m_hSpawnPickerControlsText  <- _hControlsText;
    _sc.m_hSpawnPickerCountdownText <- _hCountdownText;
    _sc.m_iSpawnCountdownLast       <- -1;

    // small delay so this always lands after any blanking Display a teardown
    // queued on the same channel this tick
    EntFireByHandle( _hControlsText, "Display", "", 0.05, this, this );
    return;
};

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

CTFPlayer_GetGroundSnapPos <- function( _vecOrigin )
{
    local _tblGround =
    {
        start    =  _vecOrigin + Vector( 0, 0, 8 ),
        end      =  _vecOrigin - Vector( 0, 0, SPAWN_GROUND_SNAP_DIST ),
        hullmin  =  Vector( -24, -24, 0 ),
        hullmax  =  Vector( 24, 24, 82 ),
        mask     =  MASK_PLAYERSOLID_BRUSHONLY,
        ignore   =  this,
    };

    TraceHull( _tblGround );

    if ( _tblGround.hit && !( ( "startsolid" in _tblGround ) && _tblGround.startsolid ) )
        return _tblGround.pos;

    return _vecOrigin;
};

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

    _sc.m_bPreviewAtBeacon <- ( _hSpawn.GetClassname() != "info_player_teamspawn" );
    _sc.m_hSpawnPreviewEnt <- _hSpawn;

    if ( _sc.m_bPreviewAtBeacon )
    {
        _vecOrigin = _vecOrigin + Vector( 0, 0, 16 );
        _angSpawn  = QAngle( 0, _angSpawn.y, 0 );
    }
    else
    {
        _vecOrigin = this.GetGroundSnapPos( _vecOrigin );
    };

    this.SetAbsOrigin   ( _vecOrigin );
    this.SetAbsVelocity ( Vector( 0, 0, 0 ) );

    try { this.SnapEyeAngles( _angSpawn ); } catch ( e ) { this.SetAbsAngles( _angSpawn ); }

    return true;
};

CTFPlayer_CycleSpawnPreview <- function( _iDir )
{
    local _sc   = this.GetScriptScope();
    local _list = BuildPickerSpawnList();

    if ( _list.len() == 0 )
        return;

    _sc.m_iSpawnIndex <- ( ( ( _sc.m_iSpawnIndex + _iDir ) % _list.len() ) + _list.len() ) % _list.len();
    this.TeleportToSpawnIndex( _sc.m_iSpawnIndex );
    return;
};

// browsing spawns gives a little auto-confirm time back, capped at the default
CTFPlayer_RefundSpawnPickerTime <- function()
{
    local _sc     = this.GetScriptScope();
    local _flLeft = ( this.HowLongUntilAct( ZOMBIE_AUTO_CONFIRM_SPAWN ) +
                      SPAWN_PICKER_CYCLE_REFUND );

    if ( _flLeft > SPAWN_PICKER_AUTO_CONFIRM_TIME )
        _flLeft = SPAWN_PICKER_AUTO_CONFIRM_TIME;

    this.SetNextActTime( ZOMBIE_AUTO_CONFIRM_SPAWN, _flLeft );

    _sc.m_iSpawnCountdownLast <- -1; // force a countdown redraw
    return;
};

// being placed inside another player sticks both of you - shove ourselves clear
CTFPlayer_UnstickFromPlayers <- function()
{
    foreach ( _hOther in GetAllPlayers() )
    {
        if ( _hOther == this || _hOther.GetHealth() <= 0 )
            continue;

        local _vecDelta = ( this.GetOrigin() - _hOther.GetOrigin() );

        if ( fabs( _vecDelta.z ) > 80 )
            continue;

        local _flHzDist = Vector( _vecDelta.x, _vecDelta.y, 0 ).Length();

        if ( _flHzDist > 48 )
            continue;

        local _vecAway = null;

        if ( _flHzDist > 1.0 )
        {
            _vecAway = Vector( ( _vecDelta.x / _flHzDist ), ( _vecDelta.y / _flHzDist ), 0 );
        }
        else
        {
            // dead-centre overlap - fall back to shoving out along our view yaw
            local _vecFwd = this.EyeAngles().Forward();
            _vecAway = Vector( _vecFwd.x, _vecFwd.y, 0 );

            if ( _vecAway.Length() < 0.1 )
                _vecAway = Vector( 1, 0, 0 );
        };

        // walls (and playerclip) stop the shove - the blocker itself is a player,
        // so trace against brushes only
        local _tblTrace =
        {
            start    =  this.GetOrigin() + Vector( 0, 0, 1 ),
            end      =  this.GetOrigin() + Vector( 0, 0, 1 ) + ( _vecAway * ( 49.0 - _flHzDist ) ),
            hullmin  =  Vector( -24, -24, 0 ),
            hullmax  =  Vector( 24, 24, 82 ),
            mask     =  MASK_PLAYERSOLID_BRUSHONLY,
            ignore   =  this,
        };

        TraceHull( _tblTrace );

        this.SetAbsOrigin( ( _tblTrace.hit && ( "pos" in _tblTrace ) ) ? _tblTrace.pos
                                                                       : _tblTrace.end );
    };

    return;
};

// loud HHH footfalls - shared by real zombie heavies and humans disguised as one
CTFPlayer_DoHeavyFootsteps <- function()
{
    if ( !( this.GetFlags() & FL_ONGROUND ) )
        return;

    local _vecVel = this.GetVelocity();

    // horizontal speed only
    local _flGroundSpeed = sqrt( ( _vecVel.x * _vecVel.x ) + ( _vecVel.y * _vecVel.y ) );

    if ( _flGroundSpeed < HEAVY_FOOTSTEP_MIN_SPEED )
    {
        this.SetNextActTime( ZOMBIE_HEAVY_FOOTSTEP, INSTANT );
    }
    else if ( this.CanDoAct( ZOMBIE_HEAVY_FOOTSTEP ) )
    {
        local _flGap = ( HEAVY_FOOTSTEP_STRIDE / _flGroundSpeed );

        if ( _flGap < HEAVY_FOOTSTEP_MIN_GAP )
            _flGap = HEAVY_FOOTSTEP_MIN_GAP;
        else if ( _flGap > HEAVY_FOOTSTEP_MAX_GAP )
            _flGap = HEAVY_FOOTSTEP_MAX_GAP;

        EmitAmbientSoundOn  ( SFX_HEAVY_FOOTSTEP, HEAVY_FOOTSTEP_VOLUME, 1, 100, this );
        this.SetNextActTime ( ZOMBIE_HEAVY_FOOTSTEP, _flGap );
    };

    return;
};

CTFPlayer_ExitSpawnPicker <- function()
{
    local _sc = this.GetScriptScope();

    _sc.m_iFlags <- ( _sc.m_iFlags & ~ZBIT_IN_SPAWN_PICKER );

    this.SetForcedTauntCam ( 0 );
    this.LockInPlace       ( false );

    if ( _sc.m_iFlags & ZBIT_ZOMBIE )
        this.AddZombieAttribs();

    if ( ( "m_hZombieWep" in _sc ) && _sc.m_hZombieWep != null && _sc.m_hZombieWep.IsValid() )
    {
        SetPropFloat( _sc.m_hZombieWep, "m_flNextPrimaryAttack",   Time() );
        SetPropFloat( _sc.m_hZombieWep, "m_flNextSecondaryAttack", FLT_MAX );
    };

    SetPropInt ( this, "m_takedamage", 2 ); // DAMAGE_YES

    this.RemoveFlag ( FL_NOTARGET );
    this.RemoveSolidFlags ( FSOLID_NOT_SOLID );
    SetPropInt ( this, "m_CollisionGroup", COLLISION_GROUP_PLAYER );

    this.SetScriptOverlayMaterial ( "" );

    this.DestroySpawnBody   ();
    this.SetSpawnBodyHidden ( false );

    this.DestroySpawnPickerHUD();

    this.SetNextActTime ( ZOMBIE_CAN_CYCLE_SPAWN,    ACT_LOCKED );
    this.SetNextActTime ( ZOMBIE_AUTO_CONFIRM_SPAWN, ACT_LOCKED );
    return;
};

CTFPlayer_ConfirmSpawn <- function()
{
    local _sc = this.GetScriptScope();

    if ( ( "m_hZombieAbility" in _sc ) && _sc.m_hZombieAbility != null &&
         _sc.m_hZombieAbility.m_fSpawnCooldown > 0 )
        this.SetNextActTime( ZOMBIE_ABILITY_CAST, _sc.m_hZombieAbility.m_fSpawnCooldown );

    local _hPreview = ( ( "m_hSpawnPreviewEnt" in _sc ) ? _sc.m_hSpawnPreviewEnt : null );

    if ( _hPreview != null && _hPreview.IsValid() )
    {
        foreach ( _i, _hSpawn in BuildPickerSpawnList() )
        {
            if ( _hSpawn == _hPreview )
            {
                _sc.m_iSpawnIndex <- _i;
                break;
            };
        };
    };

    this.TeleportToSpawnIndex ( _sc.m_iSpawnIndex );
    this.BeginSpawnEmerge     ();
    return;
};

CTFPlayer_BeginSpawnEmerge <- function()
{
    local _sc = this.GetScriptScope();

    _sc.m_iFlags <- ( ( _sc.m_iFlags & ~ZBIT_IN_SPAWN_PICKER ) | ZBIT_EMERGING_FROM_GROUND );

    this.DestroySpawnPickerHUD();
    this.SetScriptOverlayMaterial ( "" );

    this.SetNextActTime ( ZOMBIE_CAN_CYCLE_SPAWN,    ACT_LOCKED );
    this.SetNextActTime ( ZOMBIE_AUTO_CONFIRM_SPAWN, ACT_LOCKED );

    local _vecHere = this.GetOrigin();
    local _vecEnd  = Vector( _vecHere.x, _vecHere.y, _vecHere.z );

    _sc.m_vecEmergeEnd   <- _vecEnd;
    _sc.m_vecEmergeStart <- _vecEnd - Vector( 0, 0, SPAWN_EMERGE_SINK_DEPTH );

    local _iClass   = this.GetPlayerClass();
    local _szRiseSeq = ( _iClass >= 0 && _iClass < szArrSpawnBodyRiseSeq.len() )
                       ? szArrSpawnBodyRiseSeq[ _iClass ]
                       : "";

    this.CreateSpawnBody( _szRiseSeq, arrSpawnBodyRiseFallbackSeqs,
                          SPAWN_BODY_RISE_RATE, true, SPAWN_BODY_RISE_SCAN_FOR );

    this.SetAbsVelocity ( Vector( 0, 0, 0 ) );

    this.SyncSpawnBody  ( _sc.m_vecEmergeStart );

    local _hRiseSoundOn = ( ( "m_hSpawnBody" in _sc ) &&
                            _sc.m_hSpawnBody != null && _sc.m_hSpawnBody.IsValid() )
                          ? _sc.m_hSpawnBody
                          : this;

    EmitSoundOn ( SFX_ZOMBIE_EMERGE_RISE, _hRiseSoundOn );

    this.SetNextActTime ( ZOMBIE_FINISH_EMERGE, SPAWN_EMERGE_TIME + SPAWN_EMERGE_SPAWN_DELAY );
    return;
};

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

    this.SyncSpawnBody     ( _sc.m_vecEmergeEnd );
    this.UpdateSpawnBodyAnim();
    return;
};

CTFPlayer_FinishSpawnEmerge <- function()
{
    local _sc = this.GetScriptScope();

    _sc.m_iFlags <- ( _sc.m_iFlags & ~ZBIT_EMERGING_FROM_GROUND );

    this.SetAbsOrigin   ( _sc.m_vecEmergeEnd );
    this.SetAbsVelocity ( Vector( 0, 0, 0 ) );

    this.SetNextActTime ( ZOMBIE_FINISH_EMERGE, ACT_LOCKED );

    // clear of anyone standing on the spawn point before solidity comes back
    this.UnstickFromPlayers();

    this.ExitSpawnPicker();

    this.AddCustomAttribute ( "no_jump", 1, SPAWN_PICKER_CONFIRM_NO_JUMP_TIME );

    if ( !( _sc.m_iFlags & ZBIT_ZOMBIE ) )
        return;

    this.PlayZombieVO();

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

CTFPlayer_SpawnPickerThink <- function()
{
    local _sc      = this.GetScriptScope();
    local _buttons = GetPropInt( this, "m_nButtons" );
    local _bReady  = this.CanDoAct( ZOMBIE_CAN_CYCLE_SPAWN );

    this.SetSpawnBodyHidden   ( true, false );
    this.SetAbsVelocity       ( Vector( 0, 0, 0 ) );
    this.SyncSpawnBody        ();

    this.SetForcedTauntCam ( 1 );

    local _szZombieModel = szArrZombiePlayerModels[ this.GetPlayerClass() ];

    if ( GetPropString( this, "m_PlayerClass.m_iszCustomModel" ) != _szZombieModel )
        this.SetCustomModelWithClassAnimations( _szZombieModel );

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

    local _iSecondsLeft = ceil( this.HowLongUntilAct( ZOMBIE_AUTO_CONFIRM_SPAWN ) ).tointeger();

    if ( _iSecondsLeft != _sc.m_iSpawnCountdownLast &&
         _sc.m_hSpawnPickerCountdownText != null && _sc.m_hSpawnPickerCountdownText.IsValid() )
    {
        _sc.m_iSpawnCountdownLast <- _iSecondsLeft;

        _sc.m_hSpawnPickerCountdownText.KeyValueFromString( "message", format( STRING_UI_SPAWN_PICKER_COUNTDOWN, _iSecondsLeft ) );
        EntFireByHandle( _sc.m_hSpawnPickerCountdownText, "Display", "", 0.0, this, this );

        // the controls hint is fire-and-forget otherwise - re-show it on the same
        // tick so nothing on this channel can permanently blank it
        if ( _sc.m_hSpawnPickerControlsText != null && _sc.m_hSpawnPickerControlsText.IsValid() )
            EntFireByHandle( _sc.m_hSpawnPickerControlsText, "Display", "", 0.0, this, this );
    };

    if ( ( _buttons & IN_JUMP ) && !( _sc.m_iButtonsLast & IN_JUMP ) )
    {
        this.ConfirmSpawn();
    }
    else if ( ( _buttons & IN_ATTACK ) && _bReady )
    {
        this.CycleSpawnPreview( 1 );
        this.SetNextActTime( ZOMBIE_CAN_CYCLE_SPAWN, SPAWN_PICKER_CYCLE_COOLDOWN );
        this.RefundSpawnPickerTime();
    }
    else if ( ( _buttons & IN_ATTACK2 ) && _bReady )
    {
        this.CycleSpawnPreview( -1 );
        this.SetNextActTime( ZOMBIE_CAN_CYCLE_SPAWN, SPAWN_PICKER_CYCLE_COOLDOWN );
        this.RefundSpawnPickerTime();
    };

    _sc.m_iButtonsLast <- _buttons;
    return;
};

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

KnockbackPlayer <-  function( _hInflictor, _hVictim, _flForceMultiplier = 500.0, _flUpwardForce =  0.25, _bRemoveOnGround = false, _vecDirOverride = null )
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
    local _vecDirection     = ( _vecDirOverride != null )
                              ? Vector( _vecDirOverride.x, _vecDirOverride.y, _vecDirOverride.z )
                              : ( _vecVictimPos - _vecInflictorPos );

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