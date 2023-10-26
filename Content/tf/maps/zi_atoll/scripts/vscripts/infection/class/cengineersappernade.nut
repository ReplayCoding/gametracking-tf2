// --------------------------------------------------------------------------------------- //
// Infection - Prototype v0.5.1 - Last Edited: 29/08/2023                                  //
// --------------------------------------------------------------------------------------- //
// Code By: Harry Colquhoun (https://steamcommunity.com/profiles/76561198025795825)        //
// Assets/Game Design by: Diva Dan (https://steamcommunity.com/profiles/76561198072146551) //
// --------------------------------------------------------------------------------------- //
// engie's sapper nade ability                                                             //
// --------------------------------------------------------------------------------------- //

class CEngineerSapperNade extends CZombieAbility
{
    constructor( hAbilityOwner )
    {
        this.m_hAbilityOwner     =  hAbilityOwner;
        this.m_iAbilityType      =  ZABILITY_THROWABLE;
        this.m_fAbilityCooldown  =  MIN_TIME_BETWEEN_ENGIE_EMP_THROW;
        this.m_szAbilityName     =  ENGIE_EMP_NAME;
        this.m_szAbilityDesc     =  ENGIE_EMP_DESC;
    };

    function AbilityCast()
    {
        if ( this.m_hAbilityOwner == null || !this.m_hAbilityOwner.ValidateScriptScope() )
            return;

        local _d = this.m_hAbilityOwner.GetScriptScope();

        SetPropFloat( _d.m_hZombieWep, "m_flNextPrimaryAttack",   FLT_MAX );
        SetPropFloat( _d.m_hZombieWep, "m_flNextSecondaryAttack", FLT_MAX );

        this.m_hAbilityOwner.AddCond        ( TF_COND_AIMING );
        this.m_hAbilityOwner.RemoveCond     ( TF_COND_SPEED_BOOST );

        EmitSoundOnClient( "Weapon_GrenadeLauncher.DrumStop", m_hAbilityOwner );

        this.m_hAbilityOwner.AddEventToQueue( EVENT_ENGIE_THROW_NADE, INSTANT );
        return;
    };

    function ThrowNadeProjectile()
    {
        if ( this.m_hAbilityOwner == null || !this.m_hAbilityOwner.ValidateScriptScope() )
            return;

        local _d = this.m_hAbilityOwner.GetScriptScope();

        local _hPlayerVM    =  GetPropEntity( this.m_hAbilityOwner, "m_hViewModel" );

        // random numbers for angles so the nade spins
        local _fPitch       =  RandomFloat( -360, 360 );
        local _fYaw         =  RandomFloat( -360, 360 );
        local _fRoll        =  RandomFloat( -360, 360 );

        local _iDist        =  ENGIE_EMP_THROW_DIST_FROM_EYES;
        local _iThrowForce  =  ENGIE_EMP_THROW_FORCE;

        local _vecPlayerVel =  GetPropVector( m_hAbilityOwner, "m_vecVelocity" );

        local _vecFwd    =  m_hAbilityOwner.EyeAngles().Forward();
        local _vecThrow  =  ( ( _vecFwd * _iThrowForce ) + _vecPlayerVel );
        local _angPos    =  ( m_hAbilityOwner.EyePosition() + ( _vecFwd * _iDist ) );
        local _nadeEnt   =  Entities.CreateByClassname( "prop_physics_override" );

        SetPropFloat( _d.m_hZombieWep, "m_flNextPrimaryAttack", FLT_MAX );

        _nadeEnt.SetModel  ( MDL_WORLD_MODEL_ENGIE_NADE );
        _nadeEnt.SetOrigin ( _angPos );

        _nadeEnt.SetModelScale( 1.2, 0.0 ); // todo - const
        _nadeEnt.SetSize ( ( _nadeEnt.GetBoundingMins() * 1.2 ), ( _nadeEnt.GetBoundingMaxs() * 1.2 ) ); // todo - const

        SetPropInt    ( _nadeEnt, "m_CollisionGroup", COLLISION_GROUP_PROJECTILE );
        SetPropVector ( _nadeEnt, "m_vInitialVelocity ", _vecThrow );

        _nadeEnt.DispatchSpawn();

        local _hPfxEnt = SpawnEntityFromTable( "info_particle_system",
        {
            effect_name  = FX_EMP_FLASH,
            start_active = "0",
            targetname   = "ZombieEngie_EMP_Grenade_particle",
            origin       = _angPos
        });

        EntFireByHandle( _hPfxEnt,  "SetParent", "!activator",  0, _nadeEnt, _nadeEnt );

        _nadeEnt.SetAngles           ( _fPitch, _fYaw, _fRoll );
        _nadeEnt.SetAngularVelocity  ( _fPitch, _fYaw, _fRoll );
        _nadeEnt.SetPhysVelocity     ( _vecThrow );

        _nadeEnt.ValidateScriptScope();

        local _sc = _nadeEnt.GetScriptScope();

        _sc.m_fTimeStart      <-  ( Time() ).tofloat();
        _sc.m_fNextFlashTime  <-  ( Time() + ENGIE_EMP_INITIAL_FLASH_RATE ).tofloat();
        _sc.m_fExplodeTime    <-  ( Time() + ENGIE_EMP_LIFETIME ).tofloat();

        _sc.m_fFlashRate      <-  ENGIE_EMP_INITIAL_FLASH_RATE;

        _sc.m_hOwner          <-  this.m_hAbilityOwner;
        _sc.m_hPfx            <-  _hPfxEnt;

        this.m_hAbilityOwner.ViewPunch ( QAngle( -3, 0, 0 ) ); // todo - const

        local _iSpecialSeq = _hPlayerVM.LookupSequence( "special" );
        _hPlayerVM.SetSequence( _iSpecialSeq );

        this.m_hAbilityOwner.AddEventToQueue ( EVENT_ENGIE_EXIT_MINIROOT, 0.25 );
        AddThinkToEnt   ( _nadeEnt, "EngieEMPThink" );
        return;
    };

    function ExitRoot()
    {
        m_hAbilityOwner.RemoveCond ( TF_COND_AIMING );
        m_hAbilityOwner.AddCond    ( TF_COND_SPEED_BOOST );
        this.PutAbilityOnCooldown();

        return;
    };

};