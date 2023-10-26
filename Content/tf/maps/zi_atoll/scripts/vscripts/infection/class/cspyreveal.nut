// --------------------------------------------------------------------------------------- //
// Infection - Prototype v0.5.1 - Last Edited: 29/08/2023                                  //
// --------------------------------------------------------------------------------------- //
// Code By: Harry Colquhoun (https://steamcommunity.com/profiles/76561198025795825)        //
// Assets/Game Design by: Diva Dan (https://steamcommunity.com/profiles/76561198072146551) //
// --------------------------------------------------------------------------------------- //
// sniper spitball think script                                                            //
// --------------------------------------------------------------------------------------- //

class CSpyReveal extends CZombieAbility
{
    constructor( hAbilityOwner )
    {
        this.m_hAbilityOwner     =  hAbilityOwner;
        this.m_iAbilityType      =  ZABILITY_EMITTER;
        this.m_fAbilityCooldown  =  MIN_TIME_BETWEEN_SPY_REVEAL;
        this.m_szAbilityName     =  SPY_REVEAL_NAME;
        this.m_szAbilityDesc     =  SPY_REVEAL_DESC;
    };

    function AbilityCast()
    {
        if ( this.m_hAbilityOwner == null || !this.m_hAbilityOwner.ValidateScriptScope() )
            return;

        local _d = this.m_hAbilityOwner.GetScriptScope();

        this.m_hAbilityOwner.AddCond( TF_COND_TAUNTING );

        if ( _d.m_hTempEntity != null && _d.m_hTempEntity.IsValid() )
            _d.m_hTempEntity.Destroy();

        _d.m_hTempEntity <- SpawnEntityFromTable( "info_particle_system",
        {
            effect_name  = FX_EMITTER_FX,
            start_active = "0",
            targetname   = "ZombieSpy_Revealer_pfx",
            origin       = this.m_hAbilityOwner.GetOrigin(),
        } );

        if ( _d.m_hTempEntity == null )
            return;

        EmitSoundOn     ( SFX_SPY_REVEAL_ONCAST, _d.m_hTempEntity );
        EntFireByHandle ( _d.m_hTempEntity , "SetParent", "!activator", 0, this.m_hAbilityOwner, this.m_hAbilityOwner );

        SetPropFloat( _d.m_hZombieWep, "m_flNextPrimaryAttack", FLT_MAX );

        this.m_hAbilityOwner.AddCustomAttribute ( "move speed penalty", 0.001, -1 );
        this.m_hAbilityOwner.AddCustomAttribute ( "no_jump", 1, -1 );
        this.m_hAbilityOwner.SetForcedTauntCam  ( 1 );

        local _tauntSeq = this.m_hAbilityOwner.LookupSequence( "taunt06" );
        this.m_hAbilityOwner.SetSequence( _tauntSeq );

        _d.m_iFlags = ( _d.m_iFlags | ZBIT_SPY_IN_REVEAL );

        this.m_hAbilityOwner.AddEventToQueue( EVENT_ENTER_SPY_REVEAL, 1 );

        EntFireByHandle ( _d.m_hTempEntity , "Start", "",  0, null, null );
        return;
    };

    function CreateReveal()
    {
        if ( this.m_hAbilityOwner == null || !this.m_hAbilityOwner.ValidateScriptScope() )
            return;

        local _d = this.m_hAbilityOwner.GetScriptScope();

        local _angAngles    =   this.m_hAbilityOwner.GetAbsAngles();
        local _vecAngles    =   Vector( _angAngles.x, _angAngles.y, _angAngles.z );
        local _playerArr    =   [];
        local _player       =   null;
        local _playerCount  =   0;

        EntFireByHandle( _d.m_hTempEntity , "Start", "",  0, null, null );

        while ( _player = Entities.FindByClassnameWithin( _player, "player", this.m_hAbilityOwner.GetOrigin(), SPY_REVEAL_RANGE ) )
        {
            if ( _player != null && _player.GetTeam() != TF_TEAM_BLUE )
            {
                _playerArr.append(_player);
                _playerCount++;
            };
        };

        if ( _playerCount != 0 )
        {
            for ( local i = 0; i < _playerArr.len(); i++ )
            {
                local _player = _playerArr[ i ];

                if ( _player == this.m_hAbilityOwner || !_player.ValidateScriptScope() )
                    continue;

                local _nextD = _player.GetScriptScope();

                SetPropBool( _player, "m_bGlowEnabled", true );

                _player.SetNextActTime ( ZOMBIE_KILL_GLOW, 5.0 );

                _nextD.m_iFlags = ( _nextD.m_iFlags | ZBIT_REVEALED_BY_SPY );
            };
        }
        else
        {
            this.m_hAbilityOwner.AddEventToQueue( EVENT_EXIT_SPY_REVEAL, 2.5 );
            return;
        };
    };

    function ExitReveal()
    {
        if ( this.m_hAbilityOwner == null || !this.m_hAbilityOwner.ValidateScriptScope() )
            return;

        local _d = this.m_hAbilityOwner.GetScriptScope();

        this.m_hAbilityOwner.RemoveCond( TF_COND_TAUNTING );

        _d.m_hTempEntity.Destroy();
        _d.m_hZombieFXWearable.Destroy();

        this.m_hAbilityOwner.SetForcedTauntCam( 0 );

        this.m_hAbilityOwner.RemoveCustomAttribute( "move speed penalty" );
        this.m_hAbilityOwner.RemoveCustomAttribute( "no_jump" );
        this.m_hAbilityOwner.RemoveCustomAttribute( "no_attack" );

        this.m_hAbilityOwner.GiveZombieFXWearable();

        _d.m_iFlags = ( _d.m_iFlags & ~ZBIT_SPY_IN_REVEAL );
        return;
    };
};
