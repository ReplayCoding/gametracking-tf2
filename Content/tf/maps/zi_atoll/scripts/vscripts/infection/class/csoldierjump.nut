// --------------------------------------------------------------------------------------- //
// Infection - Prototype v0.5.1 - Last Edited: 29/08/2023                                  //
// --------------------------------------------------------------------------------------- //
// Code By: Harry Colquhoun (https://steamcommunity.com/profiles/76561198025795825)        //
// Assets/Game Design by: Diva Dan (https://steamcommunity.com/profiles/76561198072146551) //
// --------------------------------------------------------------------------------------- //
// engie's sapper nade ability                                                             //
// --------------------------------------------------------------------------------------- //

class CSoldierJump extends CZombieAbility
{
    constructor( hAbilityOwner )
    {
        this.m_hAbilityOwner     =  hAbilityOwner;
        this.m_iAbilityType      =  ZABILITY_THROWABLE;
        this.m_fAbilityCooldown  =  MIN_TIME_BETWEEN_SOLDIER_POUNCE;
        this.m_szAbilityName     =  SOLDIER_POUNCE_NAME;
        this.m_szAbilityDesc     =  SOLDIER_POUNCE_DESC;
    };

    function AbilityCast()
    {
        if ( this.m_hAbilityOwner == null )
            return;

        local _hPlayerVM    =   GetPropEntity( this.m_hAbilityOwner, "m_hViewModel" );
        local _iSpecialSeq  =  _hPlayerVM.LookupSequence( "special" );

        _hPlayerVM.SetSequence( _iSpecialSeq );

        local _vecVelocity = this.m_hAbilityOwner.GetAbsVelocity();

        SetPropEntity( this.m_hAbilityOwner, "m_hGroundEntity", null );

        this.m_hAbilityOwner.AddEventToQueue ( EVENT_PUT_ABILITY_ON_CD, INSTANT ); // todo - const
        this.m_hAbilityOwner.ApplyAbsVelocityImpulse( _vecVelocity + Vector( -450, 0, 850 ) );

        this.PutAbilityOnCooldown();
        return;
    };

};