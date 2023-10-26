// --------------------------------------------------------------------------------------- //
// Infection - Prototype v0.5.1 - Last Edited: 29/08/2023                                  //
// --------------------------------------------------------------------------------------- //
// Code By: Harry Colquhoun (https://steamcommunity.com/profiles/76561198025795825)        //
// Assets/Game Design by: Diva Dan (https://steamcommunity.com/profiles/76561198072146551) //
// --------------------------------------------------------------------------------------- //
// player think script                                                                     //
// --------------------------------------------------------------------------------------- //

::PlayerThink <- function()
{
    if ( GetPropInt( self, "m_lifeState" ) != 0 )
        return;

    if ( m_iFlags != 0 || m_iFlags == ( ZBIT_SURVIVOR ) )
    {
        // ------------------------------------------------------------------------------ //
        // player become zombie                                                           //
        // ------------------------------------------------------------------------------ //
        if ( m_iFlags & ( ZBIT_PENDING_ZOMBIE ) )
        {
            if ( self.CanDoAct( ZOMBIE_BECOME_ZOMBIE ) )
            {
                m_iFlags =  ( m_iFlags & ( ~ZBIT_PENDING_ZOMBIE ) & ( ~ZBIT_SURVIVOR ) );

                SetPropInt( self, "m_Local.m_iHideHUD", ( HIDEHUD_WEAPONSELECTION ) );

                self.GiveZombieWeapon();
                self.GiveZombieAbility();
                self.AddZombieAttribs();
                self.SpawnEffect();

                SetPropFloat( m_hZombieWep, "m_flNextSecondaryAttack", FLT_MAX );

                if ( m_hZombieAbility.m_iAbilityType == ZABILITY_PASSIVE )
                    m_hZombieAbility.ApplyPassive();

                self.SetHealth      ( self.GetMaxHealth() );
                self.SetNextActTime ( ZOMBIE_BECOME_ZOMBIE, ACT_LOCKED );

                m_iFlags = ( m_iFlags | ZBIT_ZOMBIE | ZBIT_HASNT_HEARD_READY_SFX | ZBIT_HASNT_HEARD_DENY_SFX );
            };
        };
        // ------------------------------------------------------------------------------ //
        // zombie behaviours                                                              //
        // ------------------------------------------------------------------------------ //
        if ( m_iFlags & ZBIT_ZOMBIE )
        {
            local _flNextPrimaryAttack   =   GetPropFloat  ( m_hZombieWep, "m_flNextPrimaryAttack" );
            local _flTimeWeaponIdle      =   GetPropFloat  ( m_hZombieWep, "m_flTimeWeaponIdle" );
            local _buttons               =   GetPropInt    ( self, "m_nButtons" );
            local _bCanCast              =   self.CanDoAct ( ZOMBIE_ABILITY_CAST );
            local _bPressingAttack2      =   ( (_buttons & IN_ATTACK2) != 0 );
            // ------------------------------------------------------------------------------ //
            // zombie ability deny/ready sound handling                                       //
            // ------------------------------------------------------------------------------ //
            if ( _bPressingAttack2 && !_bCanCast )
            {
                if ( ( m_iFlags & ZBIT_HASNT_HEARD_DENY_SFX ) &&
                     ( m_iCurrentAbilityType != ZABILITY_PASSIVE ) )
                {
                    EmitSoundOnClient( "Player.UseDeny", self );
                    m_iFlags = ( m_iFlags & ~ZBIT_HASNT_HEARD_DENY_SFX );
                };
            }
            else if ( !_bPressingAttack2 && !_bCanCast )
            {
                m_iFlags = ( m_iFlags | ZBIT_HASNT_HEARD_DENY_SFX );
            };
            if ( self.CanDoAct( ZOMBIE_ABILITY_CAST ) && ( m_iFlags & ZBIT_HASNT_HEARD_READY_SFX ) )
            {
                EmitSoundOnClient( "TFPlayer.ReCharged", self );
                m_iFlags = ( m_iFlags & ~ZBIT_HASNT_HEARD_READY_SFX );
            };
            // ------------------------------------------------------------------------------ //
            // zombie ability ui prompts | currently using ClientPrint as placeholder         //
            // ------------------------------------------------------------------------------ //
            if ( m_iCurrentAbilityType != ZABILITY_PASSIVE )
            {
                local _fNextActTime = self.HowLongUntilAct( ZOMBIE_ABILITY_CAST );

                if ( _fNextActTime < 0.2  && _fNextActTime != ACT_LOCKED )
                {
                    ClientPrint( self, 4, format( STRING_UI_ABILITY_READY,
                                                  m_hZombieAbility.m_szAbilityName, m_hZombieAbility.m_szAbilityDesc ) );
                }
                else
                {
                    ClientPrint( self, 4, format( STRING_UI_ABILITY_CHARGING,
                                                  m_hZombieAbility.m_szAbilityName, m_hZombieAbility.m_szAbilityDesc,
                                                  _fNextActTime ) );
                };
            };
            // ------------------------------------------------------------------------------ //
            // third person hack for particle/cosmetic                                        //
            // ------------------------------------------------------------------------------ //
            if  ( self.InCond( TF_COND_TAUNTING ) && !( m_iFlags & ZBIT_PARTICLE_HACK ) )
            {
                // destroy current particle/cosmetic to avoid duplicates on other player's view
                m_hZombieFXWearable.Destroy();
                m_hZombieWearable.Destroy();

                // create new ones now that the player can see themselves
                self.GiveZombieFXWearable();
                self.GiveZombieCosmetics();

                m_iFlags = ( m_iFlags | ZBIT_PARTICLE_HACK );
            };
            // ------------------------------------------------------------------------------ //
            if ( m_iFlags & ( ZBIT_PARTICLE_HACK ) && !( self.InCond( TF_COND_TAUNTING ) ) )
            {
                // destroy current particle/cosmetic to avoid pfx showing in first person
                m_hZombieFXWearable.Destroy();
                self.GiveZombieFXWearable();

                m_iFlags = ( m_iFlags & ~ZBIT_PARTICLE_HACK );
            };
            // ------------------------------------------------------------------------------ //
            // remove glow applied by spy's ability                                           //
            // ------------------------------------------------------------------------------ //
            if ( m_iFlags & ( ZBIT_REVEALED_BY_SPY ) && self.CanDoAct( ZOMBIE_KILL_GLOW ) )
            {
                SetPropBool    ( self, "m_bGlowEnabled", false );
                self.SetNextActTime( ZOMBIE_KILL_GLOW, ACT_LOCKED );
                m_iFlags =  ( m_iFlags & ~ZBIT_REVEALED_BY_SPY );
            };
            // ------------------------------------------------------------------------------ //
            // handle medic healring                                                          //
            // ------------------------------------------------------------------------------ //
            if ( m_iFlags & ( ZBIT_HEALING_FROM_ZMEDIC ) )
            {
                if ( !self.CanDoAct( ZOMBIE_REMOVE_HEALRING ) )
                {
                    if ( m_fTimeNextHealTick < Time() )
                    {
                        self.SetHealth( self.GetHealth() + 1 );
                        m_fTimeNextHealTick = Time() + MEDIC_HEAL_RATE;
                    };
                }
                else
                {
                    self.RemoveCond     ( TF_COND_RADIUSHEAL );
                    self.SetNextActTime ( ZOMBIE_REMOVE_HEALRING, ACT_LOCKED );
                    m_iFlags =   ( m_iFlags & ~ZBIT_HEALING_FROM_ZMEDIC );
                };
            };
            // ------------------------------------------------------------------------------ //
            // zombie melee attack behaviour                                                  //
            // ------------------------------------------------------------------------------ //
            local _hPlayerVM          =   GetPropEntity( self, "m_hViewModel" );
            local _attackSeq          =   _hPlayerVM.LookupSequence( "attack" );
            local _refSeq             =   _hPlayerVM.LookupSequence( "ref" );
            local _specialSeq         =   _hPlayerVM.LookupSequence( "special" );
            local _drawSeq            =   _hPlayerVM.LookupSequence( "draw" );
            local _idleSeq            =   _hPlayerVM.LookupSequence( "idle" );
            local _bAttackedThisTick  =   false;
            // ------------------------------------------------------------------------------ //
            if ( ( _buttons & IN_ATTACK ) )
            {
                if ( _flNextPrimaryAttack == _flTimeWeaponIdle && self.CanDoAct( ZOMBIE_DO_ATTACK1 ) )
                {
                    local _angFirstViewPunch = QAngle( -2, RandomFloat( -3, 3 ), 0 );

                    _bAttackedThisTick = true; // so we can do an appropriate voice response if cooldown allows

                    local _attackSeq   =   _hPlayerVM.LookupSequence( "attack" );
                    _hPlayerVM.SetSequence( _attackSeq );

                    self.ViewPunch( _angFirstViewPunch );

                    self.SetNextActTime  ( ZOMBIE_DO_ATTACK1, 1 );        // todo - const
                    self.AddEventToQueue ( EVENT_DOWNWARDS_VIEWPUNCH, INSTANT ); // todo - const
                };
            };
            // ------------------------------------------------------------------------------ //
            // sniper spit charge behaviour                                                   //
            // ------------------------------------------------------------------------------ //
            if ( ( m_iFlags & ( ZBIT_SNIPER_CHARGING_SPIT ) ) )
            {
                SetPropFloat( m_hZombieWep, "m_flNextPrimaryAttack", FLT_MAX ); // gets unlocked in spitball event

                if ( self.GetPlayerClass() != TF_CLASS_SNIPER || m_iFlags & ZBIT_SURVIVOR )
                {
                    // shouldn't have flag if not sniper or a human
                    m_iFlags = ( m_iFlags & ~ZBIT_SNIPER_CHARGING_SPIT );
                    VScriptError( ERROR_BAD_FLAG_SPITBALL, ELVL_ERROR, _szNetName );
                }
                else if ( _bPressingAttack2 ) // if we're holding right click while charging spit
                {
                    if ( !m_tblEventQueue.rawin( EVENT_SNIPER_SPITBALL ) )
                    {
                        // make sure we have the event queued
                        self.AddEventToQueue( EVENT_SNIPER_SPITBALL, MIN_TIME_BETWEEN_SPIT_START_END );
                    }
                    else if ( Time() - m_fTimeAbilityCastStarted >= SNIPER_SPIT_MAX_CHANNEL_TIME )
                    {
                        // we've been charging for too long, release the spitball
                        m_tblEventQueue[ EVENT_SNIPER_SPITBALL ] = 0.0;
                    }
                    else if ( Time() - m_fTimeAbilityCastStarted >= SNIPER_SPIT_OVERLOAD_START_TIME )
                    {
                        // calculate how long we've been in the overload state
                        local _flOverloadTime = Time() - ( m_fTimeAbilityCastStarted +
                                                           SNIPER_SPIT_OVERLOAD_START_TIME );

                        // use that as viewpunch modifier // todo - const
                        local _flMultiplier = 1 + ( _flOverloadTime / (SNIPER_SPIT_MAX_CHANNEL_TIME -
                                                                       SNIPER_SPIT_OVERLOAD_START_TIME ) );

                        // camera wobbles all over the shop while overloading
                        local _randArr = [ RandomFloat( -1, 1 ) * _flMultiplier,
                                           RandomFloat( -1, 1 ) * _flMultiplier,
                                           RandomFloat( -1, 1 ) * _flMultiplier ];

                        self.ViewPunch( QAngle( _randArr[ 0 ], _randArr[ 1 ], _randArr[ 2 ] ) );

                        m_tblEventQueue[ EVENT_SNIPER_SPITBALL ] += 0.1;
                    }
                    else
                    {
                        // normal spitball charging, push event back a bit
                        m_tblEventQueue[ EVENT_SNIPER_SPITBALL ] += 0.1;
                    };
                }
                else if ( !_bPressingAttack2 ) // right click released while charging
                {
                    local _flMinTime = ( m_fTimeAbilityCastStarted + MIN_TIME_BETWEEN_SPIT_START_END );

                    // make sure we never cast the spitball early no matter what
                    if ( _flMinTime < Time() )
                    {
                        m_tblEventQueue[ EVENT_SNIPER_SPITBALL ] = 0.0;
                    }
                    else
                    {
                        m_tblEventQueue[ EVENT_SNIPER_SPITBALL ] = _flMinTime;
                    };
                };
            };
            // ------------------------------------------------------------------------------ //
            // generic zombie ability cast behaviour                                          //
            // ------------------------------------------------------------------------------ //
            if ( _bPressingAttack2 )
            {
                if ( m_hZombieAbility.m_iAbilityType == ZABILITY_PASSIVE || !_bCanCast )
                     return;

                    m_iFlags  =  ( m_iFlags | ZBIT_HASNT_HEARD_READY_SFX );

                    EmitSoundOnClient( SFX_ABILITY_USE, self );

                    local _attackSeq   =   _hPlayerVM.LookupSequence( "attack" );
                    _hPlayerVM.SetSequence ( _attackSeq );

                    m_hZombieAbility.AbilityCast();
                    m_hZombieAbility.LockAbility();

                    SetPropFloat( m_hZombieWep, "m_flNextSecondaryAttack", FLT_MAX );
            };
            // ------------------------------------------------------------------------------ //
            // generic zombie viewmodel behaviour                                             //
            // ------------------------------------------------------------------------------ //
            if ( _hPlayerVM.GetSequence() == _refSeq )
            {
                local _drawSeq = _hPlayerVM.LookupSequence( "draw" );
                _hPlayerVM.SetSequence( _drawSeq );
            }
            else if ( _hPlayerVM.IsSequenceFinished()  && _hPlayerVM.GetSequence() != _specialSeq )
            {
                local _idleSeq = _hPlayerVM.LookupSequence( "idle" );
                _hPlayerVM.SetSequence( _idleSeq );
            };
            // ------------------------------------------------------------------------------ //
            // zombie voice override                                                          //
            // ------------------------------------------------------------------------------ //
            // setting player's voice pitch to 0 with attribute "voice pitch scale" means     //
            // the sound system will skip playing it, so we are free to play sfx manually     //
            // ------------------------------------------------------------------------------ //s
            if ( self.GetTimeSinceCalledForMedic() < PLAYER_RETHINK_TIME ||
                 self.InCond( TF_COND_BURNING )  ||
                 self.InCond( TF_COND_URINE )    ||
                 self.InCond( TF_COND_BLEEDING ) ||
                 self.InCond( TF_COND_MAD_MILK ) ||
                 self.InCond( TF_COND_GAS )      ||
                 _bAttackedThisTick )
            {
                if ( self.CanDoAct( ZOMBIE_TALK ) )
                {
                    local _rand = RandomInt( 0, ZOMBIE_VOICE_SFX.len() - 1 );

                    EmitSoundOn( ZOMBIE_VOICE_SFX[ _rand ], self );

                    self.SetNextActTime( ZOMBIE_TALK, 1.0 );
                };
            };
        };
    };

    self.ProcessEventQueue();
    return PLAYER_RETHINK_TIME;
};