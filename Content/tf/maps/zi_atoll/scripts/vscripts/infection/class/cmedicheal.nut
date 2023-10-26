// --------------------------------------------------------------------------------------- //
// Infection - Prototype v0.5.1 - Last Edited: 29/08/2023                                  //
// --------------------------------------------------------------------------------------- //
// Code By: Harry Colquhoun (https://steamcommunity.com/profiles/76561198025795825)        //
// Assets/Game Design by: Diva Dan (https://steamcommunity.com/profiles/76561198072146551) //
// --------------------------------------------------------------------------------------- //
// sniper spitball think script                                                            //
// --------------------------------------------------------------------------------------- //

class CMedicHeal extends CZombieAbility
{
    constructor( hAbilityOwner )
    {
        this.m_hAbilityOwner     =  hAbilityOwner;
        this.m_iAbilityType      =  ZABILITY_EMITTER;
        this.m_fAbilityCooldown  =  MIN_TIME_BETWEEN_MEDIC_HEAL;
        this.m_szAbilityName     =  MEDIC_HEAL_NAME;
        this.m_szAbilityDesc     =  MEDIC_HEAL_DESC;
    };

    function AbilityCast()
    {
        if ( this.m_hAbilityOwner == null || !this.m_hAbilityOwner.ValidateScriptScope() )
            return;

        local _d = this.m_hAbilityOwner.GetScriptScope();

        this.m_hAbilityOwner.AddCond( TF_COND_TAUNTING );

        _d.m_hTempEntity <- SpawnEntityFromTable( "info_particle_system",
        {
            effect_name  = FX_EMITTER_FX,
            start_active = "0",
            targetname   = "ZombieSpy_Revealer_pfx",
            origin       = this.m_hAbilityOwner.GetOrigin(),
        });

        EmitSoundOn     ( "WeaponMedigun.HealingWorld", _d.m_hTempEntity ); // hacky workaround for now
        EntFireByHandle ( _d.m_hTempEntity , "SetParent", "!activator",  0, this.m_hAbilityOwner, this.m_hAbilityOwner );

        this.m_hAbilityOwner.AddCustomAttribute( "no_attack", 1, -1 );
        this.m_hAbilityOwner.AddCustomAttribute( "no_jump",   1, -1 );
        this.m_hAbilityOwner.AddCustomAttribute( "move speed penalty", 0.001, -1 );

        this.m_hAbilityOwner.SetForcedTauntCam( 1 );

        _d.m_iFlags = ( _d.m_iFlags | ZBIT_MEDIC_IN_HEAL );

        this.m_hAbilityOwner.AddEventToQueue( EVENT_ENTER_MEDIC_HEAL, 1 );

        EntFireByHandle( _d.m_hTempEntity , "Start", "",  0, null, null );
        return;
    };

    function CreateHealEmitter()
    {
        if ( this.m_hAbilityOwner == null || !this.m_hAbilityOwner.ValidateScriptScope() )
            return;

        local _d = this.m_hAbilityOwner.GetScriptScope();

        local _angAngles     =   this.m_hAbilityOwner.GetAbsAngles();
        local _vecAngles     =   Vector( _angAngles.x, _angAngles.y, _angAngles.z );
        local _playerArr     =   [];
        local _player        =   null;
        local _playerCount   =   0;

        EntFireByHandle( _d.m_hTempEntity , "Start", "",  0, null, null );

        while ( _player = Entities.FindByClassnameWithin( _player, "player", this.m_hAbilityOwner.GetOrigin(), MEDIC_HEAL_RANGE ) )
        {
            if ( _player != null && _player.GetTeam() != TF_TEAM_RED )
            {
                _playerArr.append(_player);
                _playerCount++;
            };
        };

        if ( _playerCount == 0 )
        {
            AddEventToQueue( GetPlayerUserID( this.m_hAbilityOwner ), EVENT_EXIT_MEDIC_HEAL, 3 );
            return;
        };

        for ( local i = 0; i < _playerArr.len(); i++ )
        {
            local _player = _playerArr[ i ];

            if ( _player == this.m_hAbilityOwner )
                continue;

            local _nextD = PlayerData._getplayerdata( GetPlayerUserID( _player ) );

            EmitSoundOnClient( "WeaponMedigun.HealingDetachTarget", this.m_hAbilityOwner ); // todo const

            _player.AddCond( TF_COND_RADIUSHEAL );
            this.m_hAbilityOwner.SetNextActTime( ZOMBIE_REMOVE_HEALRING, 5.0 );

            _nextD.m_iFlags = ( _nextD.m_iFlags | ZBIT_HEALING_FROM_ZMEDIC );
        };

        this.m_hAbilityOwner.AddEventToQueue( EVENT_EXIT_MEDIC_HEAL, 2.5 );
        return;
    };

    function ExitHealEmitter()
    {
        if ( this.m_hAbilityOwner == null || !this.m_hAbilityOwner.ValidateScriptScope() )
            return;

        local _d = this.m_hAbilityOwner.GetScriptScope();

        this.m_hAbilityOwner.RemoveCond( TF_COND_TAUNTING );

        if ( _d.m_hTempEntity != null && _d.m_hTempEntity.IsValid() )
            _d.m_hTempEntity.Destroy();

        if ( _d.m_hZombieFXWearable != null && _d.m_hZombieFXWearable.IsValid() )
            _d.m_hZombieFXWearable.Kill();

        this.m_hAbilityOwner.SetForcedTauntCam( 0 );

        this.m_hAbilityOwner.RemoveCustomAttribute  ( "move speed penalty" );
        this.m_hAbilityOwner.RemoveCustomAttribute  ( "no_jump" );
        this.m_hAbilityOwner.RemoveCustomAttribute  ( "no_attack" );

        this.m_hAbilityOwner.GiveZombieFXWearable();

        _d.m_iFlags = ( _d.m_iFlags & ~ZBIT_MEDIC_IN_HEAL );
        return;
    };
};
