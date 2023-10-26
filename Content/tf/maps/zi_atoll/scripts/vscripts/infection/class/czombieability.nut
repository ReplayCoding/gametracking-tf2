// --------------------------------------------------------------------------------------- //
// Infection - Prototype v0.5.1 - Last Edited: 29/08/2023                                  //
// --------------------------------------------------------------------------------------- //
// Code By: Harry Colquhoun (https://steamcommunity.com/profiles/76561198025795825)        //
// Assets/Game Design by: Diva Dan (https://steamcommunity.com/profiles/76561198072146551) //
// --------------------------------------------------------------------------------------- //
// zombie ability base class                                                               //
// --------------------------------------------------------------------------------------- //

class CZombieAbility
{
    m_iAbilityType       =   0;
    m_hAbilityOwner      =   null;
    m_fAbilityCooldown   =   0.0;
    m_szAbilityName      =   " ";
    m_szAbilityDesc      =   " ";
    m_arrAttribs         =   [ ];
    m_arrTFConds         =   [ ];

    function GetAbilityType     ()  { return this.m_iAbilityType; };

    function GetAbilityOwner    ()  { return this.m_hAbilityOwner; };

    function GetAbilityCooldown ()  { return this.m_fAbilityCooldown; };

    function GetAbilityName     ()  { return this.m_szAbilityName; };

    function LockAbility()
    {
        this.m_hAbilityOwner.SetNextActTime( ZOMBIE_ABILITY_CAST, ACT_LOCKED );
    };

    function UnlockAbility()
    {
        this.m_hAbilityOwner.SetNextActTime( ZOMBIE_ABILITY_CAST, 0.01 );
    };

    function PutAbilityOnCooldown()
    {
        this.m_hAbilityOwner.SetNextActTime( ZOMBIE_ABILITY_CAST, this.m_fAbilityCooldown );
    };

};