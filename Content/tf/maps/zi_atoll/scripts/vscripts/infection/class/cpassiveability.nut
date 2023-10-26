// --------------------------------------------------------------------------------------- //
// Infection - Prototype v0.5.1 - Last Edited: 29/08/2023                                  //
// --------------------------------------------------------------------------------------- //
// Code By: Harry Colquhoun (https://steamcommunity.com/profiles/76561198025795825)        //
// Assets/Game Design by: Diva Dan (https://steamcommunity.com/profiles/76561198072146551) //
// --------------------------------------------------------------------------------------- //
// passive ability base class and abilities                                                //
// --------------------------------------------------------------------------------------- //

class CPassiveAbility extends CZombieAbility
{
    function AbilityCast()
    {
        VScriptError( ERROR_CANT_CAST_PASSIVE_ABILITY,
                      ELVL_ERROR,
                      this.m_hAbilityOwner.tostring() );
        return;
    };

    // ------------------------------------------------------------------- //
    // passive abilities are now handled through zombie attrib/cond system //
    // this is still here because it's used for name/desc                  //
    // todo - remove this                                                  //
    // ------------------------------------------------------------------- //

    function ApplyPassive()
    {
        // local _d = PlayerData._getplayerdata( GetPlayerUserID( this.m_hAbilityOwner ) );

        // if ( _d == null || this.m_arrAttribs == null || this.m_arrAttribs == null )
        //     return;

        // local _szNetName = NetName( this.m_hAbilityOwner );

        // foreach ( _attrib in this.m_arrAttribs )
        // {
        //     this.m_hAbilityOwner.AddCustomAttribute( _attrib[ 0 ],
        //                                              _attrib[ 1 ],
        //                                              _attrib[ 2 ] );

        //     VScriptError( format( INFO_APPLY_ATTRIBS,
        //                           _attrib[ 0 ],
        //                           _szNetName,
        //                           _attrib[ 1 ] ),
        //                   ELVL_INFO,
        //                   this.m_szAbilityName );
        // };

        // foreach ( _cond in this.m_arrTFConds )
        // {
        //     this.m_hAbilityOwner.AddCondEx( _cond, -1, null );

        //     VScriptError( format( INFO_APPLY_CONDS,
        //                          _cond,
        //                         _szNetName ),
        //                  ELVL_INFO,
        //                  this.m_szAbilityName );
        // };
    };

    function StripPassive()
    {
    //     local _d = PlayerData._getplayerdata( GetPlayerUserID( this.m_hAbilityOwner ) );

    //     if ( _d == null || this.m_arrAttribs == null || this.m_arrAttribs == null )
    //         return;

    //     local _szNetName = NetName( this.m_hAbilityOwner );

    //     foreach ( _attrib in this.m_arrAttribs )
    //     {
    //         this.m_hAbilityOwner.RemoveAttribute( _attrib[ 0 ] );

    //         VScriptError( format( INFO_REMOVE_ATTRIBS,
    //                               _attrib[ 0 ],
    //                               _szNetName ),
    //                       ELVL_INFO,
    //                       this.m_szAbilityName );
    //     };

    //     foreach ( _cond in this.m_arrTFConds )
    //     {
    //         this.m_hAbilityOwner.RemoveCond( _cond );

    //         VScriptError( format( INFO_REMOVE_CONDS,
    //                               _cond,
    //                               _szNetName),
    //                       ELVL_INFO,
    //                       this.m_szAbilityName );
    //     };
    };
};

class CPyroPassive extends CPassiveAbility
{
    constructor( hAbilityOwner )
    {
        this.m_hAbilityOwner     =  hAbilityOwner;
        this.m_iAbilityType      =  ZABILITY_PASSIVE;
        this.m_fAbilityCooldown  =  ACT_LOCKED;
        this.m_szAbilityName     =  PYRO_PASSIVE_NAME;
        this.m_szAbilityDesc     =  PYRO_PASSIVE_DESC;
        //this.m_arrAttribs        =  PYRO_PASSIVE_ATTRIBUTES;
        //this.m_arrTFConds        =  PYRO_PASSIVE_CONDS;
    };
};

class CHeavyPassive extends CPassiveAbility
{
    constructor( hAbilityOwner )
    {
        this.m_hAbilityOwner     =  hAbilityOwner;
        this.m_iAbilityType      =  ZABILITY_PASSIVE;
        this.m_fAbilityCooldown  =  ACT_LOCKED;
        this.m_szAbilityName     =  HEAVY_PASSIVE_NAME;
        this.m_szAbilityDesc     =  HEAVY_PASSIVE_DESC;
        //this.m_arrAttribs        =  HEAVY_PASSIVE_ATTRIBUTES;
       // this.m_arrTFConds        =  HEAVY_PASSIVE_CONDS;
    };
};

class CScoutPassive extends CPassiveAbility
{
    constructor( hAbilityOwner )
    {
        this.m_hAbilityOwner     =  hAbilityOwner;
        this.m_iAbilityType      =  ZABILITY_PASSIVE;
        this.m_fAbilityCooldown  =  ACT_LOCKED;
        this.m_szAbilityName     =  SCOUT_PASSIVE_NAME;
        this.m_szAbilityDesc     =  SCOUT_PASSIVE_DESC;
        //this.m_arrAttribs        =  SCOUT_PASSIVE_ATTRIBUTES;
       // this.m_arrTFConds        =  SCOUT_PASSIVE_CONDS;
    };
};