// --------------------------------------------------------------------------------------- //
// Infection - Prototype v0.5.1 - Last Edited: 29/08/2023                                  //
// --------------------------------------------------------------------------------------- //
// Code By: Harry Colquhoun (https://steamcommunity.com/profiles/76561198025795825)        //
// Assets/Game Design by: Diva Dan (https://steamcommunity.com/profiles/76561198072146551) //
// --------------------------------------------------------------------------------------- //
// sniper spit ability                                                                     //
// --------------------------------------------------------------------------------------- //

class CSniperSpitball extends CZombieAbility
{
    constructor( hAbilityOwner )
    {
        this.m_hAbilityOwner     =  hAbilityOwner;
        this.m_iAbilityType      =  ZABILITY_PROJECTILE;
        this.m_fAbilityCooldown  =  MIN_TIME_BETWEEN_ENGIE_EMP_THROW;
        this.m_szAbilityName     =  SNIPER_SPIT_NAME;
        this.m_szAbilityDesc     =  SNIPER_SPIT_DESC;
    };

    function AbilityCast()
    {
        if ( this.m_hAbilityOwner == null || !this.m_hAbilityOwner.ValidateScriptScope() )
            return;

        local _d = this.m_hAbilityOwner.GetScriptScope();

        if ( ( _d.m_iFlags & ZBIT_SNIPER_CHARGING_SPIT ) != 0 )
            return;

        this.m_hAbilityOwner.AddEventToQueue( EVENT_SNIPER_SPITBALL, MIN_TIME_BETWEEN_SPIT_START_END );

        _d.m_fTimeAbilityCastStarted <- Time();

        _d.m_iFlags = ( _d.m_iFlags | ZBIT_SNIPER_CHARGING_SPIT );

        m_hAbilityOwner.AddCond    ( TF_COND_AIMING );
        m_hAbilityOwner.RemoveCond ( TF_COND_SPEED_BOOST );

        EmitSoundOn( SFX_ZOMBIE_SPIT_START, m_hAbilityOwner );
        return;
    };

    function CreateSpitball()
    {
        if ( this.m_hAbilityOwner == null || !this.m_hAbilityOwner.ValidateScriptScope() )
            return;

        local _d = this.m_hAbilityOwner.GetScriptScope();

        // if the player is dead when the spitball is thrown, drop straight down
        local _iThrowForce  =  ( IsPlayerAlive( this.m_hAbilityOwner ) ? SNIPER_SPIT_THROW_FORCE : 0 );

        local _iDist        =  SNIPER_SPIT_THROW_DIST;
        local _vecPlayerVel =  GetPropVector( m_hAbilityOwner, "m_vecVelocity" );
        local _vecFwd       =  m_hAbilityOwner.EyeAngles().Forward();
        local _vecThrow     =  ( ( _vecFwd * _iThrowForce ) + _vecPlayerVel );

        local _angPos       =  ( m_hAbilityOwner.EyePosition() + ( _vecFwd * _iDist ) );
        local _spitEnt      =  Entities.CreateByClassname( "prop_physics_override" );

        // spit projectile is just an engie nade
        _spitEnt.SetModel  ( MDL_WORLD_MODEL_ENGIE_NADE );
        _spitEnt.SetOrigin ( _angPos );

        // not sure if this does anything
        SetPropVector ( _spitEnt, "m_vInitialVelocity ", _vecThrow );

        // make it invisible
        SetPropInt    ( _spitEnt, "m_nRenderMode", kRenderTransColor );
        SetPropInt    ( _spitEnt, "m_clrRendder", 0 );

        SetPropInt    ( _spitEnt, "m_CollisionGroup", COLLISION_GROUP_PROJECTILE );

        local _hPfxEnt = SpawnEntityFromTable( "info_particle_system",
        {
            effect_name  = FX_SPIT_TRAIL,
            start_active = "1",
            origin       = _angPos
        } );

        EntFireByHandle( _hPfxEnt, "SetParent", "!activator",  0, _spitEnt, _spitEnt );

        _spitEnt.DispatchSpawn();
        _spitEnt.SetPhysVelocity     ( _vecThrow );

        SetPropInt( _spitEnt, "m_nRenderMode", kRenderTransColor );
        SetPropInt( _spitEnt, "m_clrRender", 0 );

        _spitEnt.ValidateScriptScope();

        local _sc = _spitEnt.GetScriptScope();

        _sc.m_hOwner          <-   this.m_hAbilityOwner;
        _sc.m_iState          <-   SPIT_STATE_IN_TRANSIT;
        _sc.m_hPfx            <-   _hPfxEnt;
        _sc.m_fTimeStart      <-   ( Time() ).tofloat();
        _sc.m_bDealtPopDmg    <-   false;
        _sc.m_flKillMeTime    <-   ( Time() + SNIPER_SPIT_LIFETIME ).tofloat();
        _sc.m_bHasHitPlayer   <-   false;

        m_hAbilityOwner.RemoveCond ( TF_COND_AIMING );
        m_hAbilityOwner.AddCond    ( TF_COND_SPEED_BOOST );

        EmitSoundOn( SFX_ZOMBIE_SPIT_END, m_hAbilityOwner );

        _d.m_iFlags = ( _d.m_iFlags & ~ZBIT_SNIPER_CHARGING_SPIT );

        this.PutAbilityOnCooldown();

        AddThinkToEnt( _spitEnt, "SniperSpitThink" );
        return;
    };
};