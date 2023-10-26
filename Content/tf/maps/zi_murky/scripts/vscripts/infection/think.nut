// --------------------------------------------------------------------------------------- //
// Zombie Infection                                                                        //
// --------------------------------------------------------------------------------------- //
// All Code By: Harry Colquhoun (https://steamcommunity.com/profiles/76561198025795825)    //
// Assets/Game Design by: Diva Dan (https://steamcommunity.com/profiles/76561198072146551) //
// --------------------------------------------------------------------------------------- //
// think scripts                                                                           //
// --------------------------------------------------------------------------------------- //

PlayerThink <- function()
{
    if ( GetPropInt( self, "m_lifeState" ) != 0 )
        return; // no need to think when we're dead

    // make sure we always have crits as last man standing
    if ( m_bLastManStanding && !self.InCond( TF_COND_CRITBOOSTED ) && self.GetTeam() == TF_TEAM_RED )
    {
        self.AddCond( TF_COND_CRITBOOSTED );
    };

    // make sure we always have mini-crits as one of the last three
    if ( m_bLastThree && !self.InCond( TF_COND_OFFENSEBUFF ) && self.GetTeam() == TF_TEAM_RED )
    {
        self.AddCond( TF_COND_OFFENSEBUFF );
    };

    if ( m_iFlags != 0 || m_iFlags == ( ZBIT_SURVIVOR ) )
    {
        // ------------------------------------------------------------------------------ //
        // player become zombie                                                           //
        // ------------------------------------------------------------------------------ //

        if ( m_iFlags & ( ZBIT_PENDING_ZOMBIE ) )
        {
            if ( self.CanDoAct( ZOMBIE_BECOME_ZOMBIE ) )
            {
                local _szAbilityTooltip = STRING_UI_ZOMBIE_INSTRUCTION;

                m_iFlags  = ( ( m_iFlags & ~ZBIT_PENDING_ZOMBIE & ~ZBIT_SURVIVOR ) );
                SetPropInt  ( self, "m_Local.m_iHideHUD", ( HIDEHUD_WEAPONSELECTION  |
                                                            HIDEHUD_BUILDING_STATUS  |
                                                            HIDEHUD_CLOAK_AND_FEIGN  |
                                                            HIDEHUD_PIPES_AND_CHARGE ));
                self.DestroyAllWeapons();
                self.GiveZombieWeapon();
                self.AddZombieAttribs();
                self.SpawnEffect();
                self.RemoveAmmo();

                SetPropFloat        ( m_hZombieWep, "m_flNextSecondaryAttack", FLT_MAX );
                SetPropBool         ( self, "m_Shared.m_bShieldEquipped", false );
                SendGlobalGameEvent ( "localplayer_pickup_weapon", self );

                // zombie spy can cloak now
                if ( self.GetPlayerClass() == TF_CLASS_SPY )
                {
                    self.AddCondEx( TF_COND_STEALTHED_USER_BUFF, -1, null );
                };

                m_vecVelocityPrevious <- self.GetVelocity();

                local _hTooltip = self.ZombieInitialTooltip();

                _hTooltip.KeyValueFromString( "message", _szAbilityTooltip );

                EntFireByHandle     ( _hTooltip,  "Display", "", 0.0, self, self );
                EntFireByHandle     ( _hTooltip,  "Kill", "", 15.5, self, self );

                self.SetHealth      ( self.GetMaxHealth() );
                self.SetNextActTime ( ZOMBIE_BECOME_ZOMBIE, ACT_LOCKED );

                self.GiveZombieAbility();

                if ( m_hZombieAbility.m_iAbilityType == ZABILITY_PASSIVE )
                {
                    m_hZombieAbility.ApplyPassive();
                    _szAbilityTooltip = STRING_UI_ZOMBIE_INSTRUCTION_PASSIVE;
                };

                m_iFlags = ( m_iFlags | ZBIT_ZOMBIE | ZBIT_HASNT_HEARD_READY_SFX | ZBIT_HASNT_HEARD_DENY_SFX | ZBIT_HAS_HUD );
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
            local _bPressingAttack2      =   ( ( _buttons & IN_ATTACK2 ) != 0 );
            local _iClassnum             =   self.GetPlayerClass();
            local _bDeathQueued          =   false;

            // ------------------------------------------------------------------------------ //
            // zombie ability deny/ready sound handling                                       //
            // ------------------------------------------------------------------------------ //

            SetPropFloat( m_hZombieWep, "m_flNextSecondaryAttack", FLT_MAX );
            SetPropFloat( m_hZombieWep, "m_flNextPrimaryAttack", m_fTimeNextViewpunch );

            if ( self.InCond( TF_COND_CRITBOOSTED_PUMPKIN ) )
            {
                self.RemoveCond( TF_COND_CRITBOOSTED_PUMPKIN );
            };

            if ( self.GetPlayerClass() == TF_CLASS_PYRO )
            {
                local _bRemovedLiquid = false;

                if ( self.InCond( TF_COND_GAS ) )
                {
                    _bRemovedLiquid = true;
                    self.RemoveCond( TF_COND_GAS );
                };

                if ( self.InCond( TF_COND_URINE ) )
                {
                    _bRemovedLiquid = true;
                    self.RemoveCond( TF_COND_URINE );
                };

                if ( self.InCond( TF_COND_MAD_MILK ) )
                {
                    _bRemovedLiquid = true;
                    self.RemoveCond( TF_COND_MAD_MILK );
                };

                // probably safe to use the extinguish sound since
                // pyro zombies can't be on fire anyway
                if ( _bRemovedLiquid )
                    EmitSoundOnClient( "TFPlayer.FlameOut", self );
            };

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

            if ( self.GetPlayerClass() == TF_CLASS_SCOUT )
            {
                if ( ( GetPropInt( self, "m_Shared.m_iAirDash" ) > 0 )  && !( m_iFlags & ZBIT_SCOUT_HAS_TRIPLE_JUMPED ) )
                {
                    SetPropInt ( self, "m_Shared.m_iAirDash", 0 );
                    m_iFlags = ( m_iFlags | ZBIT_SCOUT_HAS_TRIPLE_JUMPED );
                };

                if ( ( m_iFlags & ZBIT_SCOUT_HAS_TRIPLE_JUMPED ) && GetPropEntity(self, "m_hGroundEntity") != null )
                {
                    m_iFlags = ( m_iFlags & ~ZBIT_SCOUT_HAS_TRIPLE_JUMPED );
                };
            };

            // ------------------------------------------------------------------------------ //
            // Zombie ability "vgui"                                                          //
            // ------------------------------------------------------------------------------ //

            if ( !( _buttons & IN_SCORE ) )
            {
                if ( self.GetScriptOverlayMaterial() != ( szArrZombieAbilityUI[ _iClassnum ] + self.AbilityStateToString() ) )
                    m_bZombieHUDInitialized = false;

                if ( !m_bZombieHUDInitialized )
                {
                    try { m_hHUDText.Destroy(); } catch ( e ) { }

                    local _szAbilityIconPath = ( szArrZombieAbilityUI[ _iClassnum ] + self.AbilityStateToString() );

                    self.SetScriptOverlayMaterial( _szAbilityIconPath );
                    m_bZombieHUDInitialized  = self.InitializeZombieHUD();

                    EntFireByHandle( m_hHUDText, "Display", "", 0.0, self, self );
                    EntFireByHandle( m_hHUDTextAbilityName,  "Display", "", 0.0, self, self );
                };

                if ( m_iCurrentAbilityType == ZABILITY_PASSIVE )
                {
                    if ( m_fTimeNextClientPrint <= Time() )
                    {
                        m_hHUDText.KeyValueFromString            ( "message", STRING_UI_PASSIVE );
                        m_hHUDTextAbilityName.KeyValueFromString ( "message", m_hZombieAbility.m_szAbilityName );

                        EntFireByHandle      ( m_hHUDText, "Display", "", 0.0, self, self );
                        EntFireByHandle      ( m_hHUDTextAbilityName, "Display", "", 0.0, self, self );
                        self.SetNextActTime  ( ZOMBIE_CAN_CLIENTPRINT, 1 );

                        m_hHUDText.KeyValueFromString            ( "x", ( ZHUD_X_POS + 0.015 ).tostring() );
                        m_hHUDText.KeyValueFromString            ( "y", ( ZHUD_Y_POS + 0.023 ).tostring() );
                        m_hHUDTextAbilityName.KeyValueFromString ( "x", ( ZHUD_X_POS + arrHUDTextClassXOffsets[ _iClassnum ] ).tostring() );
                        m_hHUDTextAbilityName.KeyValueFromString ( "y", ( ZHUD_Y_POS - arrHUDTextClassYOffsets[ _iClassnum ] ).tostring() );
                    };
                }
                else
                {
                    local _fNextActTime = self.HowLongUntilAct( ZOMBIE_ABILITY_CAST );

                    if ( self.GetScriptOverlayMaterial() != ( szArrZombieAbilityUI[ _iClassnum ] + self.AbilityStateToString() ) )
                        m_bZombieHUDInitialized = false;

                    if ( !m_bZombieHUDInitialized )
                    {
                        if ( m_hHUDText )
                            m_hHUDText.Destroy();

                        local _szAbilityIconPath = ( szArrZombieAbilityUI[ _iClassnum ] + self.AbilityStateToString() );

                        self.SetScriptOverlayMaterial( _szAbilityIconPath );
                        m_bZombieHUDInitialized  = self.InitializeZombieHUD();

                        EntFireByHandle( m_hHUDText, "Display", "", 0.0, self, self );
                    };

                    if ( !_bCanCast || _bCanCast && m_szCurrentHUDString != STRING_UI_READY )
                    {
                        self.BuildZombieHUDString()
                    };

                    if ( m_fTimeNextClientPrint <= Time() )
                    {
                        m_hHUDText.KeyValueFromString ( "message", m_szCurrentHUDString );
                        self.SetNextActTime           ( ZOMBIE_CAN_CLIENTPRINT, 0.1 );

                        if ( m_szCurrentHUDString == STRING_UI_READY )
                        {
                            m_hHUDText.KeyValueFromString ( "x", ( ZHUD_X_POS + 0.015 ).tostring() );
                            m_hHUDText.KeyValueFromString ( "y", ( ZHUD_Y_POS + 0.020 ).tostring() );

                            m_hHUDTextAbilityName.KeyValueFromString ( "message", m_hZombieAbility.m_szAbilityName );
                            m_hHUDTextAbilityName.KeyValueFromString ( "x", ( ZHUD_X_POS + arrHUDTextClassXOffsets[ _iClassnum ] ).tostring() );
                            m_hHUDTextAbilityName.KeyValueFromString ( "y", ( ZHUD_Y_POS - arrHUDTextClassYOffsets[ _iClassnum ] ).tostring() );
                            EntFireByHandle ( m_hHUDTextAbilityName, "Display", "", 0.0, self, self );
                            EntFireByHandle ( m_hHUDText,  "Display", "", 0.0, self, self );
                        }
                        else
                        {
                            m_hHUDTextAbilityName.KeyValueFromString ( "message", "" );
                            m_hHUDText.KeyValueFromString ( "x", ZHUD_X_POS.tostring() );
                            m_hHUDText.KeyValueFromString ( "y", ZHUD_Y_POS.tostring() );
                            EntFireByHandle ( m_hHUDTextAbilityName, "Display", "", 0.0, self, self );
                            EntFireByHandle ( m_hHUDText,  "Display", "", 0.0, self, self );
                        };
                    };
                };
            }
            else
            {
                self.SetScriptOverlayMaterial( "" );
            };

            // ------------------------------------------------------------------------------ //
            // demoman zombie charge ability collision check                                  //
            // ------------------------------------------------------------------------------ //

            if ( self.GetPlayerClass() == TF_CLASS_DEMOMAN && ( m_iFlags & ZBIT_MUST_EXPLODE ) )
            {
                if ( ( m_tblEventQueue.rawin( EVENT_DEMO_CHARGE_EXIT ) ) && !self.InCond( TF_COND_INVULNERABLE_USER_BUFF ) )
                {
                    if ( ( !self.InCond( TF_COND_SHIELD_CHARGE ) ) || ( abs( self.GetVelocity().y ) < ( abs( m_vecVelocityPrevious.y ) - 100 ) ) )
                    {
                        m_hZombieAbility.ExitDemoCharge ();
                        m_tblEventQueue.rawdelete       ( EVENT_DEMO_CHARGE_EXIT );
                    };
                }

            }
            else if ( self.GetPlayerClass() == TF_CLASS_DEMOMAN && ( m_iFlags & ZBIT_DEMOCHARGE ) )
            {
                self.AddCustomAttribute ( "move speed penalty", 0.001, -1 );
            };

            m_vecVelocityPrevious = self.GetVelocity();

            // ------------------------------------------------------------------------------ //
            // passive self healing                                                           //
            // ------------------------------------------------------------------------------ //

            if ( m_fTimeLastHit < ( Time() - 5.0 ) && !( m_iFlags & ZBIT_MUST_EXPLODE ) )
            {
                if ( ( m_fTimeNextHealTick <= Time() ) && ( self.GetHealth() < self.GetMaxHealth() ) )
                {
                    self.SetHealth        ( self.GetHealth() + 5 );
                    m_fTimeNextHealTick = ( Time() + 1.5 );
                };

                if ( _iClassnum != TF_CLASS_HEAVYWEAPONS || _iClassnum != TF_CLASS_SCOUT )
                {
                    self.ApplyOutOfCombat();
                };
            };

            // ------------------------------------------------------------------------------ //
            // third person hack for particle/cosmetic                                        //
            // ------------------------------------------------------------------------------ //

            if  ( self.InCond( TF_COND_TAUNTING ) && !( m_iFlags & ZBIT_PARTICLE_HACK ) )
            {
                // destroy current particle/cosmetic to avoid duplicates on other player's view
            if ( m_hZombieFXWearable != null && m_hZombieFXWearable.IsValid() )
                 m_hZombieFXWearable.Destroy();

            if ( m_hZombieWearable != null && m_hZombieWearable.IsValid() )
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

            if ( m_iFlags & ZBIT_SOLDIER_IN_POUNCE )
            {
                if ( self.GetFlags() & FL_ONGROUND )
                {
                    m_iFlags = ( m_iFlags & ~ZBIT_SOLDIER_IN_POUNCE );
                };
            };

            // ------------------------------------------------------------------------------ //
            // handle medic healring                                                          //
            // ------------------------------------------------------------------------------ //

            if ( m_iFlags & ( ZBIT_HEALING_FROM_ZMEDIC ) )
            {
                if ( !self.CanDoAct( ZOMBIE_REMOVE_HEALRING ) )
                {
                    if ( m_fTimeNextHealTick <= Time() )
                    {
                        self.SetHealth        ( self.GetHealth() + 20 );
                        m_fTimeNextHealTick = ( Time() + MEDIC_HEAL_RATE );
                    };
                }
                else
                {
                    self.RemoveCond     ( TF_COND_RADIUSHEAL );
                    self.SetNextActTime ( ZOMBIE_REMOVE_HEALRING, ACT_LOCKED );
                    m_iFlags =          ( m_iFlags & ~ZBIT_HEALING_FROM_ZMEDIC );
                };
            };

            // --------------------------------------------------------------------- //
            // zombie melee attack behaviour                                         //
            // --------------------------------------------------------------------- //

            local _hPlayerVM          =   GetPropEntity              ( self, "m_hViewModel" );
            local _attackSeq          =   _hPlayerVM.LookupSequence  ( "attack" );
            local _refSeq             =   _hPlayerVM.LookupSequence  ( "ref" );
            local _specialSeq         =   _hPlayerVM.LookupSequence  ( "special" );
            local _drawSeq            =   _hPlayerVM.LookupSequence  ( "draw" );
            local _idleSeq            =   _hPlayerVM.LookupSequence  ( "idle" );
            local _bAttackedThisTick  =   false;

            if ( ( _buttons & IN_ATTACK ) )
            {
                if ( _flNextPrimaryAttack == _flTimeWeaponIdle && self.CanDoAct( ZOMBIE_DO_ATTACK1 ) )
                {
                    // Make sure spy gets recloaked after attacking
                    if ( self.GetPlayerClass() == TF_CLASS_SPY )
                    {
                        self.AddEventToQueue( EVENT_SPY_RECLOAK, 3 );
                    };

                    local _angFirstViewPunch = QAngle( -2, RandomFloat( -3, 3 ), 0 );

                    _bAttackedThisTick  =  true;
                    local _attackSeq    =  _hPlayerVM.LookupSequence ( "attack" );

                    _hPlayerVM.ResetSequence ( _attackSeq );
                    self.ViewPunch           ( _angFirstViewPunch );
                    self.SetNextActTime      ( ZOMBIE_DO_ATTACK1, arrClassAttackSpeed[ _iClassnum ] );
                    self.AddEventToQueue     ( EVENT_DOWNWARDS_VIEWPUNCH, INSTANT );

                    SetPropFloat( m_hZombieWep, "m_flNextPrimaryAttack", m_fTimeNextViewpunch );
                };
            };

            // ------------------------------------------------------------------------------ //
            // sniper spit charge behaviour                                                   //
            // ------------------------------------------------------------------------------ //

            if ( ( m_iFlags & ( ZBIT_SNIPER_CHARGING_SPIT ) ) )
            {
                // gets unlocked in spitball event
                SetPropFloat( m_hZombieWep, "m_flNextPrimaryAttack", FLT_MAX );

                if ( self.GetPlayerClass() != TF_CLASS_SNIPER || m_iFlags & ZBIT_SURVIVOR )
                {
                    // shouldn't have flag if not sniper or a human
                    m_iFlags = ( m_iFlags & ~ZBIT_SNIPER_CHARGING_SPIT );
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
                        local _flMultiplier = 1 + ( _flOverloadTime / ( SNIPER_SPIT_MAX_CHANNEL_TIME -
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

            if ( _bPressingAttack2 && _bCanCast )
            {
                if ( m_hZombieAbility.m_iAbilityType == ZABILITY_PASSIVE )
                    return PLAYER_RETHINK_TIME;

                // Make sure spy gets uncloaked after casting ability
                if ( self.GetPlayerClass() == TF_CLASS_SPY )
                {
                    self.RemoveCond      ( TF_COND_STEALTHED )
                    self.RemoveCond      ( TF_COND_STEALTHED_USER_BUFF )
                    self.AddEventToQueue ( EVENT_SPY_RECLOAK, 3 );
                };

                m_iFlags  =  ( m_iFlags | ZBIT_HASNT_HEARD_READY_SFX );

                EmitSoundOnClient( SFX_ABILITY_USE, self );

                local _attackSeq   =   _hPlayerVM.LookupSequence( "attack" );
                _hPlayerVM.ResetSequence ( _attackSeq );

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
                _hPlayerVM.ResetSequence( _drawSeq );
            }
            else if ( _hPlayerVM.IsSequenceFinished() && _hPlayerVM.GetSequence() != _specialSeq )
            {
                local _idleSeq = _hPlayerVM.LookupSequence( "idle" );
                _hPlayerVM.ResetSequence( _idleSeq );
            };

        };

        // ------------------------------------------------------------------------------ //
        // remove glow applied by spy's ability                                           //
        // ------------------------------------------------------------------------------ //

        if ( m_iFlags & ( ZBIT_REVEALED_BY_SPY ) && self.CanDoAct( ZOMBIE_KILL_GLOW ) )
        {
            SetPropBool         ( self, "m_bGlowEnabled", false );
            self.SetNextActTime ( ZOMBIE_KILL_GLOW, ACT_LOCKED );
            m_iFlags          = ( m_iFlags & ~ZBIT_REVEALED_BY_SPY );
        };

    };

    self.ProcessEventQueue();
    return PLAYER_RETHINK_TIME;
};

SniperSpitThink <- function()
{
    // flying through the air
    if ( m_iState == SPIT_STATE_IN_TRANSIT )
    {
        // tracehull to check if we hit the world
        local _tblTrace =
        {
            start    =  self.GetOrigin(),
            end      =  self.GetOrigin(),
            hullmin  =  Vector( -12, -12, -12 ),
            hullmax  =  Vector( 12, 12, 12 ),
            filter   =  self,
        };

        if ( DEBUG_MODE )
        {
            DebugDrawBox( self.GetOrigin(), Vector( -12, -12, -12 ), Vector( 12, 12, 12 ), 0, 255, 0, 0, 5.0 )
        };

        TraceHull( _tblTrace );

        if ( _tblTrace.hit && "enthit" in _tblTrace )
        {
            // can't hit ourself
            if ( _tblTrace.enthit == m_hOwner )
                return SNIPER_SPIT_RETHINK_TIME;

            // handle hitting objects that aren't the world
            if ( _tblTrace.enthit != worldspawn )
            {
                if ( m_bHasHitSolid )
                    return;

                local _szHitEntClass = _tblTrace.enthit.GetClassname();

                self.SetAbsVelocity( self.GetAbsVelocity() * 0.1 );

                // handling pumpkin bombs is quite important because halloween
                if ( _szHitEntClass == "tf_generic_bomb" || _szHitEntClass == "tf_pumpkin_bomb" )
                {
                    // use ignite to deal damage to the pumpkin and set it off
                    EntFireByHandle( _tblTrace.enthit, "ignite", "", -1, null, null );

                    // use the pumpkin's z position as splatter
                    m_vecHitPosition <- _tblTrace.enthit.GetOrigin();
                    m_iState         <-  SPIT_STATE_FINDING_GROUND;
                    m_bHasHitSolid   <-  true;

                    return SNIPER_SPIT_RETHINK_TIME;
                }
                else if ( _szHitEntClass == "player" )
                {
                    // return if we hit a zombie
                    if ( _tblTrace.enthit.GetTeam() == TF_TEAM_BLUE )
                        return SNIPER_SPIT_RETHINK_TIME;

                    // swap the IDX of the player's weapon to grappling hook before dealing damage (for kill icon)
                    SetPropInt                   ( m_hOwner.GetActiveWeapon(), "m_AttributeManager.m_Item.m_iItemDefinitionIndex", 1152 );
                    _tblTrace.enthit.TakeDamage  ( SNIPER_SPIT_POP_DAMAGE, DMG_BURN, m_hOwner );
                    SetPropInt                   ( m_hOwner.GetActiveWeapon(), "m_AttributeManager.m_Item.m_iItemDefinitionIndex", 30758 );

                    // if the player is standing on the ground
                    // update: now does this whenever a player is hit (hence the 0==0)
                    if ( 0 == 0 )
                    {
                        // use the player's z position as splatter
                        m_vecHitPosition <- _tblTrace.enthit.GetOrigin();
                    }
                    else
                    {
                        // player is in the air, splatter rejected.
                        m_iState <- SPIT_STATE_REJECTED;
                        return SNIPER_SPIT_RETHINK_TIME;
                    };

                    m_iState        <-  SPIT_STATE_FINDING_GROUND;
                    m_bHasHitSolid  <-  true;

                    return SNIPER_SPIT_RETHINK_TIME;
                };

                // if we hit an unhandled case we just try find ground
                m_vecHitPosition <- _tblTrace.pos;
                m_iState         <-  SPIT_STATE_FINDING_GROUND;
                m_bHasHitSolid   <-  true;

                return SNIPER_SPIT_RETHINK_TIME;
            }
            else if ( _tblTrace.enthit == worldspawn )
            {
                // we hit the world, store pos and seek ground
                m_iDistanceToGround  <-  SNIPER_SPIT_HIT_WORLD_Z_DIST;
                m_vecHitPosition     <-  _tblTrace.pos;
                m_bHasHitSolid       <-  true;
                m_iState             <-  SPIT_STATE_FINDING_GROUND;

                return SNIPER_SPIT_RETHINK_TIME;
            };
        };

        // hit nothing, still in transit
        return SNIPER_SPIT_RETHINK_TIME;
    }
    else if ( m_iState == SPIT_STATE_FINDING_GROUND )
    {
        EmitSoundOn( SFX_SPIT_POP, self );

        local _flSafezone   =   SNIPER_SPIT_HITBOX_SIZE; // hu - size of spitball hitbox
        local _vecVel       =   self.GetVelocity();
        local _flSafeX      =   ( _vecVel.x * _flSafezone );
        local _flSafeY      =   ( _vecVel.y * _flSafezone );
        local _start        =   m_vecHitPosition;

        _start.x += _flSafeX;
        _start.y += _flSafeY;

        local _iZDistToGround = m_iDistanceToGround;

        local _end = Vector( _start.x, _start.y, _start.z - _iZDistToGround );

        if ( DEBUG_MODE )
        {
            DebugDrawLine( _start, _end, 0, 255, 0, true, 5.0 );
        };

        // traceline for finding the ground
        local _tblTraceLine = { start = _start, end = _end, ignore = self, };

        // find the ground position to use as our splatter zone
        if( TraceLineEx( _tblTraceLine ) && _tblTraceLine.hit )
        {
            m_vecSpitZone    <- _tblTraceLine.pos;
            m_vecSpitZone.z += 3; // add some z height so the splat isnt in the ground

            if ( DEBUG_MODE )
            {
                DebugDrawBox( _tblTraceLine.pos, Vector(-5, -5, -5), Vector(5, 5, 5), 0, 0, 255, 0, 5.0 );
            };
        }
        else
        {
            // rejected splatter because it hit a wall or something
            m_iState <- SPIT_STATE_REJECTED;
            return SNIPER_SPIT_RETHINK_TIME;
        };

        // start checking points in a grid around the impact point.
        local _iCheckInc       =  50;
        local _iTimesHitEmpty  =  0;
        local _iNumChecks      =  0;

        for( local x = -100; x <= 100; x += _iCheckInc )
        {
            for( local y = -100; y <= 100; y += _iCheckInc )
            {
                // set up the next cube trace
                local _vecCheckOrigin  =  Vector( m_vecSpitZone.x + x, m_vecSpitZone.y + y, m_vecSpitZone.z - 10 );
                local _vecHullMin      =  Vector( -_iCheckInc/2, -_iCheckInc/2, -_iCheckInc/2 );
                local _vecHullMax      =  Vector(  _iCheckInc/2,  _iCheckInc/2,  _iCheckInc/2 );

                local _tblCubeTrace =
                {
                    start   = _vecCheckOrigin,
                    end     = _vecCheckOrigin,
                    hullmin = _vecHullMin,
                    hullmax = _vecHullMax,
                    filter  = self
                };

                // do the trace...
                TraceHull( _tblCubeTrace );

                // count the number of traces
                _iNumChecks++;

                if( !_tblCubeTrace.hit )
                    _iTimesHitEmpty++; // count the traces that hit empty space

                if( DEBUG_MODE )
                {
                    if( !_tblCubeTrace.hit )
                    {
                        DebugDrawBox( _vecCheckOrigin, _vecHullMin, _vecHullMax, 255, 0, 0, 0, 5.0 );
                    }
                    else
                    {
                        DebugDrawBox( _vecCheckOrigin, _vecHullMin, _vecHullMax, 0, 255, 0, 0, 5.0 );
                    };
                };
            };
        };

        if ( DEBUG_MODE )
        {
            print( "num checks: " +
                   _iNumChecks +
                   " times hit empty: " +
                   _iTimesHitEmpty +
                   "\n\n HIT PERCENT: " +
                   ( ( _iTimesHitEmpty.tofloat() / _iNumChecks ) * 100.0 )
                 );
        };

        // if the percent of hits that came back empty is lower than the failure threshold
        if ( ( ( _iTimesHitEmpty.tofloat() / _iNumChecks ) * 100.0 ) <= SNIPER_SPIT_MIN_SURFACE_PERCENT )
        {
            local _hPfxEnt = SpawnEntityFromTable( "info_particle_system",
            {
                effect_name  = FX_SPIT_SPLAT,
                start_active = "1",
                origin       = m_vecSpitZone,
            } );

            // long delay to avoid weird flipping bug
            EntFireByHandle( _hPfxEnt, "Kill", "", 15, null, null )

            DispatchParticleEffect( FX_SPIT_IMPACT, m_vecSpitZone, Vector( 0, 0, 0 ) );

            EmitSoundOn( SFX_SPIT_SPLATTER, self );
            m_iState <- SPIT_STATE_ZONE;
            m_hPfx.Destroy();
        }
        else
        {
            // too many empty hits, splatter failed!
            m_iState <- SPIT_STATE_REJECTED;
        };

        return SNIPER_SPIT_RETHINK_TIME;
    }
    else if ( m_iState == SPIT_STATE_ZONE ) // spit has deployed a zone and zone is active this tick
    {
        // if the spit zone has expired
        if ( Time() >= ( m_fTimeStart + SPIT_ZONE_LIFETIME ) )
        {
            self.Destroy();
            return;
        };

        local _iPlayerCount        =   0;
        local _arrPlayers          =   [ ];
        local _hNextPlayer         =   null;
        local _hNextTargetEntity   =   null;

        if ( DEBUG_MODE ) { DebugDrawCircle( m_vecSpitZone, Vector( 255, 0, 0 ), 0, SPIT_ZONE_RADIUS, true, 1.0 ) };

        // process a table of entities that the spit zone should fire inputs on
        // for example, key "tf_pumpkin_bomb" has val "ignite" which will pop the pumpkin
        foreach( _szClass, _szInput in SNIPER_SPIT_ZONE_ENTS )
        {
            while ( _hNextTargetEntity = Entities.FindByClassnameWithin( _hNextTargetEntity,
                                                                         _szClass,
                                                                         m_vecSpitZone,
                                                                         SPIT_ZONE_RADIUS ) )
            {
                if ( _szInput == "building" )
                {
                    _hNextTargetEntity.TakeDamage( SNIPER_SPIT_ZONE_DAMAGE, DMG_BURN, m_hOwner );
                    continue;
                };

                if ( _hNextTargetEntity != null )
                {
                    EntFireByHandle( _hNextTargetEntity, _szInput, "", -1, null, null );
                };
            };
        };

        // get all the players in the zone area
        while ( _hNextPlayer = Entities.FindByClassnameWithin( _hNextPlayer, "player", m_vecSpitZone, SPIT_ZONE_RADIUS ) )
        {
            if ( _hNextPlayer != null && _hNextPlayer.GetTeam() != TF_TEAM_BLUE )
            {
                _arrPlayers.append( _hNextPlayer );
                _iPlayerCount++;
            };
        };

        if ( typeof _arrPlayers == "array" && _arrPlayers.len() > 0 && _iPlayerCount != 0 )
        {
            foreach ( _hNextPlayer in _arrPlayers )
            {
                if ( _hNextPlayer == null || _hNextPlayer.GetTeam() == TF_TEAM_BLUE )
                    continue; // redundant

                local _vecPlayerOrigin = _hNextPlayer.GetOrigin();

                // deal a bit more damage to players in the zone on impact
                if ( !m_bDealtPopDmg )
                {
                    // swap the IDX of the player's weapon to grappling hook before dealing damage (for kill icon)
                    SetPropInt( m_hOwner.GetActiveWeapon(), STRING_NETPROP_ITEMDEF, TF_IDX_GRAPPLING_HOOK );
                    _hNextPlayer.TakeDamage( SNIPER_SPIT_POP_DAMAGE, DMG_BURN, m_hOwner );
                    SetPropInt( m_hOwner.GetActiveWeapon(), STRING_NETPROP_ITEMDEF, ZOMBIE_WEAPON_IDX[ TF_CLASS_SNIPER ] );

                    EmitSoundOnClient("TFPlayer.FirePain", _hNextPlayer)

                    DispatchParticleEffect  ( FX_SPIT_HIT_PLAYER, _vecPlayerOrigin, Vector( 0, 0, 0 ) );
                    continue;
                };

                // swap the IDX of the player's weapon to grappling hook before dealing damage (for kill icon)
                SetPropInt              ( m_hOwner.GetActiveWeapon(), STRING_NETPROP_ITEMDEF, TF_IDX_GRAPPLING_HOOK );
                _hNextPlayer.TakeDamage ( SNIPER_SPIT_ZONE_DAMAGE, DMG_BURN, m_hOwner );
                SetPropInt              ( m_hOwner.GetActiveWeapon(), STRING_NETPROP_ITEMDEF, ZOMBIE_WEAPON_IDX[ TF_CLASS_SNIPER ] );

                DispatchParticleEffect  ( FX_SPIT_HIT_PLAYER, _vecPlayerOrigin, Vector( 0, 0, 0 ) );
            };
        };

        m_bDealtPopDmg <- true;
        return SNIPER_SPIT_ZONE_RETHINK_TIME;
    }
    else if ( m_iState == SPIT_STATE_REJECTED ) // spit couldn't deploy zone, burst harmlessly and die
    {
        DispatchParticleEffect( FX_SPIT_IMPACT, self.GetOrigin(), Vector( 0, 0, 0 ) );

        EmitSoundOn( SFX_SPIT_MISS, self );
        m_hPfx.Destroy();
        self.Destroy();

        return FLT_MAX; // no rethink
    };
};

EngieEMPThink <- function ()
{
    local _tblTraceLine =
    {
        start   = self.GetOrigin(),
        end     = self.GetOrigin() + Vector( 0,0,-5),
        ignore  = self,
    }

    TraceLineEx( _tblTraceLine)

    if ( _tblTraceLine.plane_normal.z < 0.86602 && _tblTraceLine.plane_normal.z != 0 && _tblTraceLine.plane_normal.z != 1 )
    {
        self.SetPhysVelocity( self.GetPhysVelocity() * 0.65 );
    }

    if ( !m_bHasHitSolid )
    {
        local _tblTrace =
        {
            start    =  self.GetOrigin(),
            end      =  self.GetOrigin(),
            hullmin  =  Vector( -12, -12, -12 ),
            hullmax  =  Vector( 12, 12, 12 ),
            filter   =  self,
        };

        if ( DEBUG_MODE )
        {
            DebugDrawBox( self.GetOrigin(), Vector( -12, -12, -12 ), Vector( 12, 12, 12 ), 0, 255, 0, 0, 5.0 )
        };

        TraceHull( _tblTrace );

        if ( _tblTrace && "enthit" in _tblTrace )
        {
            // can't hit ourself
            if ( _tblTrace.enthit == m_hOwner )
                return ENGIE_EMP_RETHINK_TIME;

            // handle hitting objects that aren't the world
            if ( _tblTrace.enthit == worldspawn )
            {
                m_bHasHitSolid = true;
            };
        };

        if ( m_bHasHitSolid )
            return;

        local _buildableArr    =  [ ];
        local _buildable       =  null;
        local _buildableCount  =  0;

        while ( _buildable = Entities.FindByClassnameWithin( _buildable, "obj_*", self.GetOrigin(), ENGIE_EMP_FIRST_HIT_RANGE ) )
        {
            if ( _buildable != null )
            {
                _buildableArr.append( _buildable );
                _buildableCount++;
            };
        };

        if ( _buildableCount != 0 )
        {
            for ( local i = 0; i < _buildableArr.len(); i++ )
            {
                local _buildable = _buildableArr[ i ];

                if ( _buildable.GetClassname() == "obj_sentrygun"  ||
                     _buildable.GetClassname() == "obj_teleporter" ||
                     _buildable.GetClassname() == "obj_dispenser" )
                {
                    // deal bonus damage to the first building hit
                    local _vecNearestBuildingOrigin = Entities.FindByClassnameNearest( "obj_*", self.GetOrigin(), ENGIE_EMP_FIRST_HIT_RANGE ).GetOrigin();
                    // _buildable.TakeDamage( 110, DMG_BLAST, m_hOwner ); // todo - const

                    m_fExplodeTime = 0.0; // explode now
                };
            };
        };
    };

    if ( Time() >= m_fNextFlashTime ) // on flash
    {
        DispatchParticleEffect ( FX_EMP_FLASH, self.GetOrigin(), self.GetAngles() );
        EmitSoundOn            ( SFX_EMP_BEEP, self );

        m_fFlashRate         = ( m_fFlashRate * ENGIE_EMP_FLASH_RATE_DECAY_FAC );
        m_fNextFlashTime     = ( Time() + m_fFlashRate );
    };

    if ( Time() >= m_fExplodeTime ) // on explode
    {
        ScreenShake( self.GetOrigin(),
                     ENGIE_EMP_SCREENSHAKE_AMP,
                     ENGIE_EMP_SCREENSHAKE_FREQ,
                     ENGIE_EMP_SCREENSHAKE_DUR,
                     ENGIE_EMP_SCREENSHAKE_RAD,
                     0,
                     true );

        DispatchParticleEffect ( FX_EMP_BURST, self.GetOrigin(), self.GetAngles() );
        DispatchParticleEffect ( FX_EMP_GIBS,  self.GetOrigin(), self.GetAngles() );
        DispatchParticleEffect ( FX_EMP_SPARK, self.GetOrigin(), self.GetAngles() );
        EmitSoundOn            ( SFX_EMP_EXPLODE, self );

        local _buildableArr    =  [ ];
        local _buildable       =  null;
        local _buildableCount  =  0;

        while ( _buildable = Entities.FindByClassnameWithin( _buildable, "obj_*", self.GetOrigin(), ENGIE_EMP_BUILDING_DISABLE_RANGE ) )
        {
            if ( _buildable != null )
            {
                _buildableArr.append( _buildable );
                _buildableCount++;
            };
        };

        if ( _buildableCount == 0 )
        {
            self.Destroy();
            return;
        };

        for ( local i = 0; i < _buildableArr.len(); i++ )
        {
            local _buildable = _buildableArr[ i ];

            if ( _buildable.GetClassname() == "obj_sentrygun"  ||
                 _buildable.GetClassname() == "obj_teleporter" ||
                 _buildable.GetClassname() == "obj_dispenser" )
            {
                // trace to make sure we don't stun through walls
                local _tblTraceLine =
                {
                    start   =  self.GetOrigin() + Vector( 0, 0, 45 ),
                    end     =  _buildable.GetOrigin() + Vector( 0, 0, 45 ),
                    ignore  =  self,
                };

                TraceLineEx   ( _tblTraceLine );

                if ( _tblTraceLine && "enthit" in _tblTraceLine )
                {
                    if ( DEBUG_MODE )
                        DebugDrawLine ( self.GetOrigin() + Vector( 0, 0, 45 ), _buildable.GetOrigin() + Vector( 0, 0, 45 ), 255, 0, 0, true, 10 );

                    if ( _tblTraceLine.enthit != _buildable )
                    {
                        if ( DEBUG_MODE )
                            DebugDrawText ( _buildable.GetOrigin(), "HIT FAILED! HIT WORLD", false, 10 );

                        continue;
                    }
                    else
                    {
                        if ( DEBUG_MODE )
                            DebugDrawText ( _buildable.GetOrigin(), "HIT BY EMP", false, 10 );
                    };
                };

                EmitSoundOn( SFX_EMP_BUILDING_DMGED, _buildable );

                if ( !_buildable.ValidateScriptScope() )
                    continue;

                local _buildableScope = _buildable.GetScriptScope();

                // there are no sappers or cowmanglers on blu in this mode so this is a
                // safe enough way to check if the sentry is already being emp'd.
                local _bDisabled = GetPropBool( _buildable, "m_bDisabled" );

                // if we hit a sentry that is already disabled we don't want to re-apply the disable
                if ( _bDisabled )
                    continue;

                _buildableScope.m_fReactivateTime <- ( Time() + ENGIE_EMP_BUILDING_DISABLE_TIME );

                SetPropBool   ( _buildable, "m_bHasSapper", true );
                SetPropBool   ( _buildable, "m_bDisabled",  true );
                AddThinkToEnt ( _buildable, "BuildableEMPThink" );

                _buildable.TakeDamage( 110, DMG_CLUB, m_hOwner );

            };
        };

        self.Destroy();
    };

    return 0.0;
};

BuildableEMPThink <- function()
{
    local _angAngles  =  self.GetAbsAngles();
    local _vecAngles  =  Vector( _angAngles.x, _angAngles.y, _angAngles.z );

    DispatchParticleEffect( FX_EMP_ELECTRIC, self.GetOrigin() + Vector( 0, 0, 20 ), _vecAngles );

    if ( Time() >= m_fReactivateTime )
    {
        SetPropBool   ( self, "m_bHasSapper", false );
        SetPropBool   ( self, "m_bDisabled",  false );
        SetPropString ( self, "m_iszScriptThinkFunction", "" );
        AddThinkToEnt ( self, null );
        return;
    };

    return 0.1;
};

KillMeThink <- function()
{
    if ( m_flKillTime < Time() )
    {
        self.Destroy();
        return;
    };

    return 0.01;
};

ZombieWearableThink <- function()
{
    if ( !IsPlayerAlive( this.GetOwner() ) )
    {
        SetPropInt( self, "m_nRenderMode", kRenderNone );
        return 1;
    }
    else
    {
        SetPropInt( self, "m_nRenderMode", kRenderNormal );
        return 5;
    };
};

DemomanBombThink <- function()
{
    // annoying think script to fix some stupid nonsense with sentries

    if ( m_flKillTime < Time() )
    {
        try
        {
            self.TakeDamage( 1, DMG_CLUB, m_hOwner );
        }
        catch (e)
        {
            self.Destroy();
        }

        return;
    };

    return 0.01;
};

GameStateThink <- function()
{
    local _iNumRedPlayers = PlayerCount( TF_TEAM_RED );
    local _iNumBluPlayers = PlayerCount( TF_TEAM_BLUE );

    if ( _iNumRedPlayers < 1 && ::bGameStarted )
    {
        ShouldZombiesWin( null );
    }
    else if ( _iNumBluPlayers < 1 && ::bGameStarted )
    {
        // no zombies, humans win
        local _hGameWin = SpawnEntityFromTable( "game_round_win",
        {
            win_reason      = "0",
            force_map_reset = "1",
            TeamNum         = "2", // TF_TEAM_RED
            switch_teams    = "0"
        });

        EntFireByHandle( _hGameWin, "RoundWin", "", 0, null, null );
        ::bGameStarted <- false;
        return FLT_MAX;
    };

    return 0.5;
}