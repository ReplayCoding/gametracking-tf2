// --------------------------------------------------------------------------------------- //
// Infection - Prototype v0.5.1 - Last Edited: 29/08/2023                                  //
// --------------------------------------------------------------------------------------- //
// Code By: Harry Colquhoun (https://steamcommunity.com/profiles/76561198025795825)        //
// Assets/Game Design by: Diva Dan (https://steamcommunity.com/profiles/76561198072146551) //
// --------------------------------------------------------------------------------------- //
// engie's sapper nade ability                                                             //
// --------------------------------------------------------------------------------------- //

class CDemoCharge extends CZombieAbility
{
    constructor( hAbilityOwner )
    {
        this.m_hAbilityOwner     =  hAbilityOwner;
        this.m_iAbilityType      =  ZABILITY_THROWABLE;
        this.m_fAbilityCooldown  =  MIN_TIME_BETWEEN_DEMO_CHARGE;
        this.m_szAbilityName     =  DEMO_CHARGE_NAME;
        this.m_szAbilityDesc     =  DEMO_CHARGE_DESC;
    };

    function AbilityCast()
    {
        if ( this.m_hAbilityOwner == null || !this.m_hAbilityOwner.ValidateScriptScope() )
            return;

        local _d = this.m_hAbilityOwner.GetScriptScope();

        SetPropFloat( _d.m_hZombieWep, "m_flNextPrimaryAttack",   FLT_MAX );
        SetPropFloat( _d.m_hZombieWep, "m_flNextSecondaryAttack", FLT_MAX );

        this.m_hAbilityOwner.AddEventToQueue( EVENT_DEMO_CHARGE_START, INSTANT );
        return;
    };

    function StartDemoCharge()
    {
        if ( this.m_hAbilityOwner == null )
            return;

        local _sc = this.m_hAbilityOwner.GetScriptScope();

        this.m_hAbilityOwner.AddCond( TF_COND_SHIELD_CHARGE );
        this.m_hAbilityOwner.AddEventToQueue( EVENT_DEMO_CHARGE_EXIT, 1.5 );
        return;
    };

    function ExitDemoCharge()
    {
        if ( this.m_hAbilityOwner == null || !this.m_hAbilityOwner.ValidateScriptScope() )
            return;

        local _d = this.m_hAbilityOwner.GetScriptScope();

        this.m_hAbilityOwner.RemoveCond ( TF_COND_SHIELD_CHARGE );
        SetPropFloat( _d.m_hZombieWep, "m_flNextPrimaryAttack", 0 );

        this.PutAbilityOnCooldown();
        return;
    };

};