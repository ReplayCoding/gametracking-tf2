// --------------------------------------------------------------------------------------- //
// Zombie Infection                                                                        //
// --------------------------------------------------------------------------------------- //
// All Code By: netmuck (https://steamcommunity.com/profiles/76561198025795825)            //
// Assets/Game Design by: Diva Dan (https://steamcommunity.com/profiles/76561198072146551) //
// --------------------------------------------------------------------------------------- //
// think scripts                                                                           //
// --------------------------------------------------------------------------------------- //

PlayerThink <- function()
{
    if ( GetPropInt( self, "m_lifeState" ) != 0 )
        return; // no need to think when we're dead

    if ( self.GetPlayerClass() == 0 )
    {
        self.SetPlayerClass( TF_CLASS_SCOUT );
        self.ForceRegenerateAndRespawn();
    };

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

    // spy garbage
    if ( self.GetPlayerClass() == TF_CLASS_SPY )
    {
        if ( self.GetTeam() == TF_TEAM_RED )
        {
            // --------------------------------------------------------------------- //
            // spoofing disguises for zombie players                                 //
            // --------------------------------------------------------------------- //
            // here we use romevision so we can let red players disguise as zombies  //
            // and be seen correctly as zombies on the pov of other zombies.         //
            // as far as i can figure out, the "m_Shared.m_nModelIndexOverrides" 3 is//
            // the index of the model the player will be seen as by enemy players    //
            // in romevision specifically. so we set that to the appropriate zombie  //
            // model index if the player is disguised as a zombie.                   //
            // --------------------------------------------------------------------- //
            if ( self.InCond( TF_COND_DISGUISED ) )
            {
                local _iDisguiseClass = GetPropInt     ( self, "m_Shared.m_nDisguiseClass" );
                local _iDisguiseTeam  = GetPropInt     ( self, "m_Shared.m_nDisguiseTeam" );

                if (_iDisguiseTeam == TF_TEAM_BLUE && GetPropIntArray( self, "m_nModelIndexOverrides", 3 ) != idxArrZombiePlayerModels[ _iDisguiseClass ] )
                {
                    SetPropIntArray( self, "m_nModelIndexOverrides", idxArrZombiePlayerModels[ _iDisguiseClass ], 3 );
                }

                // a "zombie heavy" that walks silently is a spy tell - fake the footfalls
                if ( _iDisguiseTeam == TF_TEAM_BLUE && _iDisguiseClass == TF_CLASS_HEAVYWEAPONS )
                {
                    self.DoHeavyFootsteps();
                }

                // a "zombie" without the mini-crit swirl is the same kind of tell
                self.SpoofZombieBuffFX( ( _iDisguiseTeam == TF_TEAM_BLUE ) &&
                                        ::bZombieQuotaBuffOn );
            }
            else
            {
                if ( GetPropIntArray( self, "m_nModelIndexOverrides", 3 ) != 0 )
                {
                    SetPropIntArray( self, "m_nModelIndexOverrides", 0, 3 );
                }

                self.SpoofZombieBuffFX( false );
            }
        }

        // for blue spies we set their model to the regular spy model when they're invisible
        // this prevents them from emitting a bunch of particles
        if ( self.GetTeam() == TF_TEAM_BLUE )
        {
            if ( self.IsFullyInvisible() )
            {
                if ( !( m_iFlags & ZBIT_PARTICLE_HACK ) )
                {
                    self.SetCustomModelWithClassAnimations( "models/player/spy.mdl" );
                    m_iFlags = ( m_iFlags | ZBIT_PARTICLE_HACK );
                }
            }
            else
            {
                if ( m_iFlags & ( ZBIT_PARTICLE_HACK ) )
                {
                    self.SetCustomModelWithClassAnimations( "models/player/spy_infected.mdl" );
                    m_iFlags = ( m_iFlags & ~ZBIT_PARTICLE_HACK );
                };
            }
        }
    }

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

                // lightning fx only on the initial wave
                local _bInitialInfection = ( ( m_iFlags & ZBIT_INITIAL_INFECTION ) != 0 );

                if ( m_iFlags & ZBIT_SPEWED )
                    self.RemoveSpewDebuff();

                m_iFlags  = ( ( m_iFlags & ~ZBIT_PENDING_ZOMBIE & ~ZBIT_SURVIVOR & ~ZBIT_INITIAL_INFECTION ) );
                SetPropInt  ( self, "m_Local.m_iHideHUD", ( HIDEHUD_WEAPONSELECTION  |
                                                            HIDEHUD_BUILDING_STATUS  |
                                                            HIDEHUD_CLOAK_AND_FEIGN  |
                                                            HIDEHUD_PIPES_AND_CHARGE ));

                // applying romevision to all zombie players
                // allows us to spoof disguises for human spies (from the pov of zombies)
                self.AddCustomAttribute( "vision opt in flags", 4, -1 );

                self.DestroyAllWeapons();
                self.GiveZombieWeapon();
                self.AddZombieAttribs();

                if ( _bInitialInfection )
                    self.SpawnEffect();

                self.RemoveAmmo();

                self.DestroyMedicDispenser();

                if ( self.GetPlayerClass() == TF_CLASS_MEDIC )
                {
                    local _me = self;

                    local _hDispenserTouchTrigger = SpawnEntityFromTable( "dispenser_touch_trigger", {
                        origin = _me.GetOrigin(),
                        spawnflags = 1,
                    });

                    _hDispenserTouchTrigger.KeyValueFromString( "targetname", "zmedic_dispenser_trigger" );

                    _hDispenserTouchTrigger.SetSize   ( Vector( -ZOMBIE_MEDIC_DISPENSER_RANGE,
                                                                -ZOMBIE_MEDIC_DISPENSER_RANGE,
                                                                -ZOMBIE_MEDIC_DISPENSER_RANGE ),
                                                        Vector( ZOMBIE_MEDIC_DISPENSER_RANGE,
                                                                ZOMBIE_MEDIC_DISPENSER_RANGE,
                                                                ZOMBIE_MEDIC_DISPENSER_RANGE ) )
                    _hDispenserTouchTrigger.SetSolid( 2 )

                    local _hDispenser = SpawnEntityFromTable( "pd_dispenser", {
                        origin = _me.GetOrigin() + Vector( 0, 0, 55 ),
                        spawnflags = 4,
                        teamnum = _me.GetTeam(),
                        touch_trigger = "zmedic_dispenser_trigger",
                    })

                    _hDispenser.KeyValueFromString              ( "targetname", "" );
                    _hDispenserTouchTrigger.KeyValueFromString  ( "targetname", "" );
                    _hDispenser.AcceptInput                     ( "SetParent", "!activator", self, self );
                    _hDispenserTouchTrigger.AcceptInput         ( "SetParent", "!activator", self, self );
                    _hDispenser.SetOwner( _me );

                    m_hMedicDispenser             <- _hDispenser;
                    m_hMedicDispenserTouchTrigger <- _hDispenserTouchTrigger;
                }

                if ( self.GetPlayerClass() ==  TF_CLASS_PYRO )
                {
                //     local _hBomb = SpawnEntityFromTable( "tf_generic_bomb",
                //     {
                //         explode_particle = "fireSmokeExplosion_track"
                //         sound            = SFX_PYRO_FIREBOMB,
                //         damage           = 10,
                //         radius           = 256,
                //         friendlyfire     = "0",
                //     });

                //     _hBomb.SetOwner     ( self );
                //     _hBomb.SetAbsOrigin ( self.GetOrigin() );
                //     _hBomb.AcceptInput  ( "SetParent", "!activator", self, self );

                //     AddThinkToEnt( _hBomb, "PyroBombThink" );

                //    m_hPyroBomb <- _hBomb;
                }

                SetPropFloat        ( m_hZombieWep, "m_flNextSecondaryAttack", FLT_MAX );
                SetPropBool         ( self, "m_Shared.m_bShieldEquipped", false );
                SendGlobalGameEvent ( "localplayer_pickup_weapon", self );

                // cloak deferred while spawn picking/emerging
                if ( self.GetPlayerClass() == TF_CLASS_SPY && !( m_iFlags & ( ZBIT_IN_SPAWN_PICKER | ZBIT_EMERGING_FROM_GROUND ) ) )
                {
                    self.AddCondEx( TF_COND_STEALTHED_USER_BUFF, -1, null );
                };

                m_vecVelocityPrevious <- self.GetVelocity();

                if ( !( m_iFlags & ( ZBIT_IN_SPAWN_PICKER | ZBIT_EMERGING_FROM_GROUND ) ) )
                {
                    // converting in place while overlapping someone sticks both players
                    self.UnstickFromPlayers();

                    local _hTooltip = self.ZombieInitialTooltip();

                    _hTooltip.KeyValueFromString( "message", _szAbilityTooltip );

                    EntFireByHandle     ( _hTooltip,  "Display", "", 0.0, self, self );
                    EntFireByHandle     ( _hTooltip,  "Kill", "", 15.5, self, self );
                };

                self.SetHealth      ( self.GetMaxHealth() );
                self.SetNextActTime ( ZOMBIE_BECOME_ZOMBIE, ACT_LOCKED );

                self.GiveZombieAbility();

                if ( m_hZombieAbility.m_fSpawnCooldown > 0 && !( m_iFlags & ZBIT_IN_SPAWN_PICKER ) )
                    self.SetNextActTime( ZOMBIE_ABILITY_CAST, m_hZombieAbility.m_fSpawnCooldown );

                if ( m_hZombieAbility.m_iAbilityType == ZABILITY_PASSIVE )
                {
                    m_hZombieAbility.ApplyPassive();
                    _szAbilityTooltip = STRING_UI_ZOMBIE_INSTRUCTION_PASSIVE;
                };

                m_iFlags = ( m_iFlags | ZBIT_ZOMBIE | ZBIT_HASNT_HEARD_READY_SFX | ZBIT_HASNT_HEARD_DENY_SFX | ZBIT_HAS_HUD );

                if ( m_iFlags & ( ZBIT_IN_SPAWN_PICKER | ZBIT_EMERGING_FROM_GROUND ) )
                {
                    self.LockInPlace( true );
                };
            };
        };

        if ( m_iFlags & ZBIT_IN_SPAWN_PICKER )
        {
            self.SpawnPickerThink();
            return PLAYER_RETHINK_TIME;
        };

        if ( m_iFlags & ZBIT_EMERGING_FROM_GROUND )
        {
            self.SpawnEmergeThink();
            return PLAYER_RETHINK_TIME;
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

            local _bAttack2Pressed       =   ( _bPressingAttack2 &&
                                               !( m_iButtonsLast & IN_ATTACK2 ) );

            m_iButtonsLast <- _buttons;

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

            if ( _bAttack2Pressed && !_bCanCast )
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
            // heavy zombie footfalls                                                          //
            // ------------------------------------------------------------------------------ //

            if ( _iClassnum == TF_CLASS_HEAVYWEAPONS )
            {
                self.DoHeavyFootsteps();
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
                    // horizontal speed, not one axis - a y-only check missed walls hit
                    // travelling along x, so impact detonation depended on map bearing
                    local _vecVelNow     = self.GetVelocity();
                    local _flSpeedNow    = sqrt( ( _vecVelNow.x * _vecVelNow.x ) +
                                                 ( _vecVelNow.y * _vecVelNow.y ) );
                    local _flSpeedBefore = sqrt( ( m_vecVelocityPrevious.x * m_vecVelocityPrevious.x ) +
                                                 ( m_vecVelocityPrevious.y * m_vecVelocityPrevious.y ) );

                    if ( ( !self.InCond( TF_COND_SHIELD_CHARGE ) ) || ( _flSpeedNow < ( _flSpeedBefore - 100 ) ) )
                    {
                        m_hZombieAbility.ExitDemoCharge ();
                        m_tblEventQueue.rawdelete       ( EVENT_DEMO_CHARGE_EXIT );
                    };
                }

            }
            else if ( self.GetPlayerClass() == TF_CLASS_DEMOMAN && ( m_iFlags & ZBIT_DEMOCHARGE ) )
            {
                self.AddCustomAttribute ( "move speed penalty", 0.001, -1 );

                // stand-in holds the windup pose until ZBIT_MUST_EXPLODE goes up
                self.SetSpawnBodyHidden   ( true, false );
                self.SyncSpawnBody        ();
                self.UpdateSpawnBodyAnim  ();
            };

            // ------------------------------------------------------------------------------ //
            // heavy rock throw windup                                                        //
            // ------------------------------------------------------------------------------ //

            if ( m_iFlags & ZBIT_HEAVY_ROCK_WINDUP )
            {
                self.SetSpawnBodyHidden   ( true, false );
                self.SyncSpawnBody        ();
                self.UpdateSpawnBodyAnim  ();
            };

            m_vecVelocityPrevious = self.GetVelocity();

            // ------------------------------------------------------------------------------ //
            // passive self healing                                                           //
            // ------------------------------------------------------------------------------ //

            if (1 == 0 && m_fTimeLastHit < (Time() - 5.0) && !(m_iFlags & ZBIT_MUST_EXPLODE))
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
            //     // destroy current particle/cosmetic to avoid duplicates on other player's view
            // if ( m_hZombieFXWearable != null && m_hZombieFXWearable.IsValid() )
            //      m_hZombieFXWearable.Destroy();

            // if ( m_hZombieWearable != null && m_hZombieWearable.IsValid() )
            //     m_hZombieWearable.Destroy();

            //     // create new ones now that the player can see themselves
            //     self.GiveZombieFXWearable();
            //     self.GiveZombieCosmetics();

                m_iFlags = ( m_iFlags | ZBIT_PARTICLE_HACK );
            };

            // ------------------------------------------------------------------------------ //

            if ( m_iFlags & ZBIT_SOLDIER_IN_POUNCE )
            {
                if ( !m_bSoldierFallSfx && self.GetAbsVelocity().z < 0 )
                {
                    m_bSoldierFallSfx = true;
                    EmitSoundOn( SFX_SOLDIER_FALL, self );
                };

                if ( self.GetFlags() & FL_ONGROUND )
                {
                    m_iFlags = ( m_iFlags & ~ZBIT_SOLDIER_IN_POUNCE );
                    self.EndSoldierFall();
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

                    _bAttackedThisTick  =  true;
                    local _attackSeq    =  _hPlayerVM.LookupSequence ( "attack" );

                    _hPlayerVM.ResetSequence ( _attackSeq );
                    self.SetNextActTime      ( ZOMBIE_DO_ATTACK1, arrClassAttackSpeed[ _iClassnum ] );

                    // m_fTimeNextViewpunch is the attack cooldown despite the name
                    SetPropFloat( m_hZombieWep, "m_flNextPrimaryAttack", m_fTimeNextViewpunch );
                };
            };

            // ------------------------------------------------------------------------------ //
            // sniper spit charge behaviour                                                   //
            // ------------------------------------------------------------------------------ //

            if ( ( m_iFlags & ZBIT_SNIPER_CHARGING_SPIT ) &&
                 !m_tblEventQueue.rawin( EVENT_SNIPER_SPITBALL ) &&
                 ( Time() - m_fTimeAbilityCastStarted ) > ( SNIPER_SPIT_MAX_CHANNEL_TIME + 1.0 ) )
            {
                self.EndSpitCharge();
            };

            if ( ( m_iFlags & ( ZBIT_SNIPER_CHARGING_SPIT ) ) )
            {
                // gets unlocked in spitball event
                SetPropFloat( m_hZombieWep, "m_flNextPrimaryAttack", FLT_MAX );

                local _flElapsed = ( Time() - m_fTimeAbilityCastStarted );
                local _flHold    = ( SNIPER_SPIT_VM_FREEZE_FRAME / SNIPER_SPIT_VM_FPS );

                if ( _flElapsed > _flHold )
                    SetPropFloat( _hPlayerVM, "m_flPlaybackRate", ( _flHold / _flElapsed ) );

                if ( self.GetPlayerClass() != TF_CLASS_SNIPER || m_iFlags & ZBIT_SURVIVOR )
                {
                    self.EndSpitCharge();
                    SetPropFloat( _hPlayerVM, "m_flPlaybackRate", 1.0 );
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

                    if ( !m_tblEventQueue.rawin( EVENT_SNIPER_SPITBALL ) )
                    {
                        self.AddEventToQueue( EVENT_SNIPER_SPITBALL, 0.0 );
                    }
                    // make sure we never cast the spitball early no matter what
                    else if ( _flMinTime < Time() )
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
            // sniper spit release playout                                                    //
            // ------------------------------------------------------------------------------ //

            if ( _iClassnum == TF_CLASS_SNIPER && m_fSpitVMReleaseTime != 0.0 )
            {
                local _iSpitSpecialSeq = _hPlayerVM.LookupSequence( "special" );
                local _flElapsed       = ( Time() - m_fTimeAbilityCastStarted );
                local _flPlayed        = ( SNIPER_SPIT_VM_FREEZE_FRAME / SNIPER_SPIT_VM_FPS ) +
                                         ( Time() - m_fSpitVMReleaseTime );

                if ( _hPlayerVM.GetSequence() != _iSpitSpecialSeq ||
                     _flPlayed >= _hPlayerVM.GetSequenceDuration( _iSpitSpecialSeq ) )
                {
                    SetPropFloat( _hPlayerVM, "m_flPlaybackRate", 1.0 );
                    m_fSpitVMReleaseTime = 0.0;
                }
                else if ( _flElapsed > 0.01 )
                {
                    SetPropFloat( _hPlayerVM, "m_flPlaybackRate", ( _flPlayed / _flElapsed ) );
                };
            };

            // ------------------------------------------------------------------------------ //
            // generic zombie ability cast behaviour                                          //
            // ------------------------------------------------------------------------------ //

            if ( _bAttack2Pressed && _bCanCast )
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

        if ( self.GetScriptOverlayMaterial() != "" && m_iFlags & ( ZBIT_SURVIVOR ) &&
             !( m_iFlags & ZBIT_SPEWED ) &&
             self.CanDoAct( SURVIVOR_CAN_CLEAR_SCRIPT_SCREEN_OVERLAY ))
        {
            self.SetScriptOverlayMaterial( "" );
            self.ClearSpitStatus();
        };

        if ( m_iFlags & ( ZBIT_SPEWED ) )
        {
            if ( Time() > m_fSpewEndTime )
            {
                self.RemoveSpewDebuff();
            }
            else
            {
                if ( self.InCond( TF_COND_PARACHUTE_ACTIVE ) )
                    self.RemoveCond( TF_COND_PARACHUTE_ACTIVE );

                if ( m_bSpewHasJetpack )
                    SetPropFloatArray( self, "m_Shared.m_flItemChargeMeter", 0.0, 1 );

                if ( self.InCond( TF_COND_SHIELD_CHARGE ) )
                {
                    local _vecVel  = self.GetAbsVelocity();
                    local _flHzCap = ( PYRO_SPEW_CHARGE_BASE_SPEED * PYRO_SPEW_CHARGE_SPEED_MULT );
                    local _flHzLen = sqrt( ( _vecVel.x * _vecVel.x ) + ( _vecVel.y * _vecVel.y ) );

                    if ( _flHzLen > _flHzCap )
                    {
                        local _flScale = ( _flHzCap / _flHzLen );

                        self.SetAbsVelocity( Vector( ( _vecVel.x * _flScale ),
                                                     ( _vecVel.y * _flScale ),
                                                     _vecVel.z ) );
                    };
                };

                if ( Time() < m_fSpewDrainEndTime && Time() > m_fTimeNextSpewTick )
                {
                    m_fTimeNextSpewTick = ( Time() + PYRO_SPEW_TICK_INTERVAL ).tofloat();

                    local _hAttacker = ( m_hSpewAttacker != null && m_hSpewAttacker.IsValid() ) ? m_hSpewAttacker : null;
                    local _hWeapon   = ( m_hSpewWeapon   != null && m_hSpewWeapon.IsValid()   ) ? m_hSpewWeapon   : null;
                    local _hKillIcon = KilliconInflictor( KILLICON_PYRO_SPEW );

                    self.TakeDamageCustom( _hKillIcon, _hAttacker, _hWeapon,
                                           Vector( 0, 0, 0 ), self.GetOrigin(),
                                           PYRO_SPEW_TICK_DAMAGE,
                                           ( DMG_BURN | DMG_PREVENT_PHYSICS_FORCE ),
                                           TF_DMG_CUSTOM_BURNING );

                    _hKillIcon.Destroy();
                };
            };
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

        // debug draw the in-flight hull
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
                    m_vecHitPosition    <- _tblTrace.enthit.GetOrigin();
                    m_iDistanceToGround <- SNIPER_SPIT_HIT_WORLD_Z_DIST;
                    m_iState            <- SPIT_STATE_FINDING_GROUND;
                    m_bHasHitSolid      <- true;

                    return SNIPER_SPIT_RETHINK_TIME;
                }
                else if ( _szHitEntClass == "player" )
                {
                    // return if we hit a zombie
                    if ( _tblTrace.enthit.GetTeam() == TF_TEAM_BLUE )
                        return SNIPER_SPIT_RETHINK_TIME;

                    local _hKillIcon = KilliconInflictor( KILLICON_SNIPER_SPIT );

                    // swap the IDX of the player's weapon to grappling hook before dealing damage (for kill icon)
                    //SetPropInt                   ( m_hOwner.GetActiveWeapon(), "m_AttributeManager.m_Item.m_iItemDefinitionIndex", 1152 );
                    _tblTrace.enthit.TakeDamageEx( _hKillIcon, m_hOwner, m_hOwner.GetActiveWeapon(), Vector(0, 0, 0), Vector(0, 0, 0), SNIPER_SPIT_POP_DAMAGE, DMG_BURN );
                    //SetPropInt                   ( m_hOwner.GetActiveWeapon(), "m_AttributeManager.m_Item.m_iItemDefinitionIndex", 30758 );

                    _hKillIcon.Destroy();

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

                    // long drop distance so a mid-air player hit still finds ground
                    m_iDistanceToGround <- SNIPER_SPIT_HIT_PLAYER_Z_DIST;
                    m_iState        <-  SPIT_STATE_FINDING_GROUND;
                    m_bHasHitSolid  <-  true;

                    return SNIPER_SPIT_RETHINK_TIME;
                }
                else if ( startswith( _szHitEntClass, "obj_" ) )
                {
                    // direct building hits splat at the building's base
                    m_vecHitPosition    <- ( _tblTrace.enthit.GetOrigin() + Vector( 0, 0, 8 ) );
                    m_iDistanceToGround <- SNIPER_SPIT_HIT_WORLD_Z_DIST;
                    m_iState            <- SPIT_STATE_FINDING_GROUND;
                    m_bHasHitSolid      <- true;

                    return SNIPER_SPIT_RETHINK_TIME;
                };

                // if we hit an unhandled case we just try find ground
                m_vecHitPosition    <- _tblTrace.pos;
                m_iDistanceToGround <- SNIPER_SPIT_HIT_WORLD_Z_DIST;
                m_iState            <- SPIT_STATE_FINDING_GROUND;
                m_bHasHitSolid      <- true;

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

        local _start = Vector( m_vecHitPosition.x, m_vecHitPosition.y, m_vecHitPosition.z );
        local _end   = Vector( _start.x, _start.y, ( _start.z - m_iDistanceToGround ) );

        if ( DEBUG_MODE )
        {
            DebugDrawLine( _start, _end, 0, 255, 0, true, 5.0 );
        };

        local _tblTraceLine = { start = _start, end = _end, mask = MASK_SOLID_BRUSHONLY, ignore = self, };

        if ( !( TraceLineEx( _tblTraceLine ) && _tblTraceLine.hit ) )
        {
            m_iState <- SPIT_STATE_REJECTED;
            return SNIPER_SPIT_RETHINK_TIME;
        };

        m_tblSplat <- FormSplatCells(
        {
            apex          =  _tblTraceLine.pos,
            normal        =  _tblTraceLine.plane_normal,
            dir           =  Vector( 1, 0, 0 ),
            conelength    =  0,
            conespread    =  0,
            coneapexhalfw =  0,
            splashradius  =  SPIT_ZONE_RADIUS,
            cellsize      =  SPIT_CELL_SIZE,
            ignore        =  self,
        } );

        m_vecSpitZone <- m_tblSplat.apex;


        local _angSpitImpact = SplatNormalToAngles( m_tblSplat.normal );

        DispatchParticleEffect( FX_SPIT_IMPACT, m_vecSpitZone,
                                Vector( _angSpitImpact.x, _angSpitImpact.y, _angSpitImpact.z ) );

        EmitSoundOn( SFX_SPIT_SPLATTER, self );

        if ( bSpitDebugBoxes )
        {
            DrawSplatCells( m_tblSplat,
                            SPIT_ZONE_COLOR_R, SPIT_ZONE_COLOR_G, SPIT_ZONE_COLOR_B,
                            SPIT_ZONE_ALPHA, SPIT_ZONE_BOX_HEIGHT,
                            ( ( m_fTimeStart + SPIT_ZONE_LIFETIME ) - Time() ) );
        };

        SpawnSplatFireFX( m_tblSplat, FX_SPIT_GROUND,
                          ( ( m_fTimeStart + SPIT_ZONE_LIFETIME ) - Time() ) );

        m_iState <- SPIT_STATE_ZONE;
        m_hPfx.Destroy();

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

        local _hNextTargetEntity   =   null;

        if ( DEBUG_MODE ) { DebugDrawCircle( m_vecSpitZone, Vector( 255, 0, 0 ), 0, SPIT_ZONE_RADIUS, true, 1.0 ) };

        // process a table of entities that the spit zone should fire inputs on
        // for example, key "tf_pumpkin_bomb" has val "ignite" which will pop the pumpkin.
        foreach( _szClass, _szInput in SNIPER_SPIT_ZONE_ENTS )
        {
            while ( _hNextTargetEntity = Entities.FindByClassnameWithin( _hNextTargetEntity,
                                                                         _szClass,
                                                                         m_vecSpitZone,
                                                                         SPIT_ZONE_RADIUS ) )
            {
                if ( _szInput == "building" )
                {
                    _hNextTargetEntity.TakeDamage( ( SNIPER_SPIT_ZONE_DAMAGE / 2 ) , DMG_BURN, m_hOwner);
                    continue;
                };

                if ( _hNextTargetEntity != null )
                {
                    EntFireByHandle( _hNextTargetEntity, _szInput, "", -1, null, null );
                };
            };
        };

        foreach ( _hNextPlayer in GetAllPlayers() )
        {
            if ( _hNextPlayer.GetTeam() != TF_TEAM_RED || _hNextPlayer.GetHealth() <= 0 )
                continue;

            if ( !IsPointInSplat( _hNextPlayer.GetOrigin(), m_tblSplat ) )
                continue;

            if ( _hNextPlayer.AlreadyInSpit() )
            {
                local _playerExistingSpitEnt = _hNextPlayer.GetLinkedSpitPoolEnt();

                if ( _playerExistingSpitEnt != self )
                {
                    // printl("player is already standing in spit, ignoring this player")
                    continue;
                }
            }
            else
            {
               // printl("Player has no linked spit ent, this ent is now their linked spit" );
                _hNextPlayer.SetLinkedSpitPoolEnt( self );
            }

            local _vecPlayerOrigin = _hNextPlayer.GetOrigin();

            if ( _hNextPlayer.GetScriptOverlayMaterial() == "" && GetPropInt( _hNextPlayer, "m_lifeState" ) == 0)
            {
                _hNextPlayer.SetScriptOverlayMaterial( MAT_SPIT_OVERLAY );
            }

            EmitSoundOnClient( "TFPlayer.FirePain", _hNextPlayer );

            // set the overlay clear time to slightly longer than zone rethink so it doesn't flicker
            _hNextPlayer.SetNextActTime( SURVIVOR_CAN_CLEAR_SCRIPT_SCREEN_OVERLAY, ( SNIPER_SPIT_ZONE_RETHINK_TIME + 0.15 ) );

            local _hKillIcon = KilliconInflictor( KILLICON_SNIPER_SPITPOOL );

            _hNextPlayer.TakeDamageEx( _hKillIcon, m_hOwner, m_hOwner.GetActiveWeapon(), Vector(0, 0, 0), Vector(0, 0, 0), SNIPER_SPIT_ZONE_DAMAGE, ( DMG_BURN | DMG_PREVENT_PHYSICS_FORCE ) );

            _hKillIcon.Destroy();

            DispatchParticleEffect  ( FX_SPIT_HIT_PLAYER, _vecPlayerOrigin, Vector( 0, 0, 0 ) );
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
    if ( m_bMustFizzle )
    {
        SetPropInt             ( self, "m_takedamage", 0 );
        DispatchParticleEffect ( FX_EMP_SPARK, self.GetOrigin(), self.GetAngles() );
        EmitSoundOn            ( SFX_EMP_EXPLODE, self );
        self.Destroy();
        return -1;
    }

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

        // reveal pulse at the explosion point - the temp ent below only anchors sounds
        DispatchParticleEffect ( FX_EMITTER_FX, self.GetOrigin(), Vector( 0, 0, 0 ) );

        local _hRevealPfx = SpawnEntityFromTable( "info_particle_system",
        {
            effect_name   =  FX_EMITTER_FX,
            start_active  =  "0",
            targetname    =  "spy_emp_reveal_pfx",
            origin        =  self.GetOrigin(),
        });

        EntFireByHandle    ( _hRevealPfx, "Kill",  "", 2, null, null ); // todo - const

        EmitSoundOn        ( "WeaponMedigun.HealingWorld", _hRevealPfx );

        // raw wave so the soundlevel we pass is respected
        EmitAmbientSoundOn ( ARR_SFX_SPY_REVEAL_WAVS[ RandomInt( 0, ARR_SFX_SPY_REVEAL_WAVS.len() - 1 ) ],
                             1.0, SPY_REVEAL_SNDLVL, 100, _hRevealPfx );

        // strip disguise/cloak from every survivor in range and outline them
        local _hPlayer = null;

        while ( _hPlayer = Entities.FindByClassnameWithin( _hPlayer, "player", self.GetOrigin(), ( SPY_REVEAL_RANGE ) ) )
        {
            // red (survivor) team only
            if ( _hPlayer == null || _hPlayer.GetTeam() == TF_TEAM_BLUE )
                continue;

            _hPlayer.RemoveCond(  TF_COND_DISGUISED   );
            _hPlayer.RemoveCond(  TF_COND_DISGUISING  );
            _hPlayer.RemoveCond(  TF_COND_STEALTHED   );

            local _scNext = _hPlayer.GetScriptScope();

            if ( _scNext == null )
                continue;

            // spy reveal simply enables m_bGlowEnabled on players
            SetPropBool ( _hPlayer, "m_bGlowEnabled", true );

            // stagger glow removal times so the players blink out at random times (looks cool)
            _hPlayer.SetNextActTime ( ZOMBIE_KILL_GLOW, RandomFloat( 5, 7.5 ) );
            _scNext.m_iFlags        <- ( _scNext.m_iFlags | ZBIT_REVEALED_BY_SPY );
        };

        // the pulse also outlines buildings
        local _hGlowBuildable = null;

        while ( _hGlowBuildable = Entities.FindByClassnameWithin( _hGlowBuildable, "obj_*", self.GetOrigin(), ( SPY_REVEAL_RANGE ) ) )
        {
            if ( _hGlowBuildable == null )
                continue;

            if ( _hGlowBuildable.GetClassname() != "obj_sentrygun"  &&
                 _hGlowBuildable.GetClassname() != "obj_teleporter" &&
                 _hGlowBuildable.GetClassname() != "obj_dispenser" )
                continue;

            if ( !HasProp( _hGlowBuildable, "m_bGlowEnabled" ) )
                continue;

            if ( !_hGlowBuildable.ValidateScriptScope() )
                continue;

            local _scGlow = _hGlowBuildable.GetScriptScope();

            SetPropBool ( _hGlowBuildable, "m_bGlowEnabled", true );
            _scGlow.m_fGlowKillTime <- ( Time() + SPY_EMP_BUILDING_GLOW_LEN );

            if ( !( "m_fReactivateTime" in _scGlow ) )
                _scGlow.m_fReactivateTime <- 0.0;

            AddThinkToEnt ( _hGlowBuildable, "BuildableEMPThink" );
        };

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

                // make sure the glow slot exists
                if ( !( "m_fGlowKillTime" in _buildableScope ) )
                    _buildableScope.m_fGlowKillTime <- 0.0;

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
            };
        };

        self.Destroy();
        return -1;
    };

    return 0.0;
};

BeaconBossKilled <- function()
{
    RemoveBeaconFromArray( self );

    if ( m_hRespawnRoom != null && m_hRespawnRoom.IsValid() )
        m_hRespawnRoom.Destroy();

    if ( m_hBeaconFX != null && m_hBeaconFX.IsValid() )
        m_hBeaconFX.Destroy();

    if ( m_bBuilt )
        SpawnBeaconGibs( m_vecBeaconPos );

    DispatchParticleEffect ( FX_BEACON_DESTROY, m_vecBeaconPos, Vector( 0, 0, 0 ) );

    try
    {
        EmitSoundEx( { sound_name = SFX_BEACON_DESTROY, origin = m_vecBeaconPos } );
    }
    catch ( _e ) { };

    local _hPack = null;
    while ( _hPack = Entities.FindByClassname( _hPack, "item_currencypack*" ) )
        EntFireByHandle( _hPack, "Kill", "", 0, null, null );

    return;
};

BeaconThink <- function ()
{
    if ( !m_bMustDie && ( m_hOwner == null || !m_hOwner.IsValid() ) )
        m_bMustDie = true;

    if ( m_bMustDie )
    {
        StopSoundOn( SFX_BEACON_BUILD, self );

        RemoveBeaconFromArray  ( self );

        if ( m_hRespawnRoom != null && m_hRespawnRoom.IsValid() )
            m_hRespawnRoom.Destroy();

        if ( m_hBeaconFX != null && m_hBeaconFX.IsValid() )
            m_hBeaconFX.Destroy();

        if ( m_hVisual != null && m_hVisual.IsValid() )
            m_hVisual.Destroy();

        if ( m_bBuilt )
            SpawnBeaconGibs( self.GetOrigin() );

        DispatchParticleEffect ( FX_BEACON_DESTROY, self.GetOrigin(), self.GetAngles() );
        EmitSoundOn            ( SFX_BEACON_DESTROY, self );
        SetPropInt             ( self, "m_takedamage", 0 );
        self.Destroy();
        return -1;
    };

    if ( !m_bSettled )
    {
        if ( Time() > m_flKillMeTime )
        {
            RefundBeaconCooldown( m_hOwner, ENGIE_BEACON_FAIL_REFUND );
            m_bMustDie = true;
            return ENGIE_BEACON_RETHINK_TIME;
        };

        if ( m_flDestroyTime != 0.0 && Time() > m_flDestroyTime )
        {
            RefundBeaconCooldown( m_hOwner, ENGIE_BEACON_FAIL_REFUND );
            m_bMustDie = true;
            return ENGIE_BEACON_RETHINK_TIME;
        };

        local _vecNow = self.GetOrigin();

        if ( SweepVsTriggerHurt( m_vecTraceFrom, _vecNow, ENGIE_BEACON_HURT_HULL_RADIUS ) != null )
        {
            RefundBeaconCooldown( m_hOwner, ENGIE_BEACON_FAIL_REFUND );
            m_bMustDie = true;
            return ENGIE_BEACON_RETHINK_TIME;
        };

        local _tblSweep =
        {
            start    =  m_vecTraceFrom,
            end      =  _vecNow,
            hullmin  =  Vector( -12, -12, -12 ),
            hullmax  =  Vector( 12, 12, 12 ),
            mask     =  MASK_PLAYERSOLID_BRUSHONLY,
            ignore   =  self,
        };

        TraceHull( _tblSweep );

        if ( _tblSweep.hit && !( ( "startsolid" in _tblSweep ) && _tblSweep.startsolid ) &&
             ( "surface_name" in _tblSweep ) && _tblSweep.surface_name != null &&
             _tblSweep.surface_name.tolower().find( "clip" ) != null )
        {
            local _vecVel    = self.GetAbsVelocity();
            local _vecNormal = _tblSweep.plane_normal;
            local _flDot     = ( ( _vecVel.x * _vecNormal.x ) +
                                 ( _vecVel.y * _vecNormal.y ) +
                                 ( _vecVel.z * _vecNormal.z ) );

            self.SetAbsOrigin    ( _tblSweep.pos + ( _vecNormal * 2 ) );
            self.SetPhysVelocity ( ( _vecVel - ( _vecNormal * ( 2 * _flDot ) ) ) *
                                   ENGIE_BEACON_CLIP_BOUNCE );

            m_vecTraceFrom = self.GetOrigin();
            return ENGIE_BEACON_RETHINK_TIME;
        };

        m_vecTraceFrom = Vector( _vecNow.x, _vecNow.y, _vecNow.z );

        local _tblContact =
        {
            start    =  _vecNow,
            end      =  _vecNow,
            hullmin  =  Vector( -12, -12, -12 ),
            hullmax  =  Vector( 12, 12, 12 ),
            mask     =  MASK_SOLID_BRUSHONLY,
            ignore   =  self,
        };

        TraceHull( _tblContact );

        if ( !_tblContact.hit )
            return ENGIE_BEACON_RETHINK_TIME;

        local _tblTrace =
        {
            start   =  _vecNow,
            end     =  _vecNow + Vector( 0, 0, -ENGIE_BEACON_GROUND_TRACE_DIST ),
            mask    =  MASK_SOLID_BRUSHONLY,
            ignore  =  self,
        };

        TraceLineEx( _tblTrace );

        local _bBadSpot = ( !_tblTrace.hit || _tblTrace.plane_normal.z < ENGIE_BEACON_SETTLE_NORMAL_Z );

        if ( !_bBadSpot && ( "surface_name" in _tblTrace ) && _tblTrace.surface_name != null )
        {
            local _szSurf = _tblTrace.surface_name.tolower();

            _bBadSpot = ( _szSurf.find( "nodraw" ) != null || _szSurf.find( "clip" ) != null ||
                          _szSurf.find( "sky" )    != null );
        };

        if ( !_bBadSpot )
        {
            local _vecProbe = ( _tblTrace.pos + Vector( 0, 0, 8 ) );

            local _tblClip =
            {
                start   =  _vecProbe,
                end     =  _vecProbe + Vector( 0, 0, 1 ),
                mask    =  CONTENTS_PLAYERCLIP,
                ignore  =  self,
            };

            TraceLineEx( _tblClip );

            local _bInClip = ( ( "startsolid" in _tblClip ) && _tblClip.startsolid );

            if ( _bInClip || IsPointInNoBuild( _vecProbe, self ) )
            {
                RefundBeaconCooldown( m_hOwner, ENGIE_BEACON_FAIL_REFUND );
                m_bMustDie = true;
                return ENGIE_BEACON_RETHINK_TIME;
            };

            if ( IsPointInRespawnRoom( _vecProbe, TF_TEAM_BLUE, self ) )
            {
                RefundBeaconCooldown( m_hOwner, 1.0 );
                m_bMustDie = true;
                return ENGIE_BEACON_RETHINK_TIME;
            };

            _bBadSpot = ( IsPointInTriggerHurt( _vecProbe, self ) ||
                          IsPointInTriggerHurt( ( _tblTrace.pos + Vector( 0, 0, 48 ) ), self ) );
        };

        if ( !_bBadSpot )
        {
            local _tblClearance =
            {
                start    =  _tblTrace.pos + Vector( 0, 0, 18 ),
                end      =  _tblTrace.pos + Vector( 0, 0, 18 ),
                hullmin  =  Vector( -24, -24, 0 ),
                hullmax  =  Vector( 24, 24, ENGIE_BEACON_SPAWN_CLEARANCE ),
                ignore   =  self,
            };

            TraceHull( _tblClearance );

            _bBadSpot = ( _tblClearance && ( "enthit" in _tblClearance ) &&
                          _tblClearance.enthit == worldspawn );
        };

        if ( _bBadSpot )
        {
            if ( m_flDestroyTime == 0.0 )
                m_flDestroyTime = ( Time() + ENGIE_BEACON_DESTROY_TIME ).tofloat();

            return ENGIE_BEACON_RETHINK_TIME;
        };

        {
            local _angRest = self.GetAngles();
            local _hTele = SpawnEntityFromTable( "base_boss",
            {
                targetname     = "engie_beacon_physprop",
                model          = MDL_ENGIE_BEACON,
                health         = ENGIE_BEACON_HEALTH,
                speed          = 0,
                start_disabled = 1,
                origin         = _tblTrace.pos,
            } );

            SetPropInt ( _hTele, "m_iTeamNum", TF_TEAM_BLUE );

            _hTele.SetResolvePlayerCollisions( false );

            _hTele.SetSize ( Vector( -ENGIE_BEACON_HULL_HALF, -ENGIE_BEACON_HULL_HALF, 0 ),
                             Vector(  ENGIE_BEACON_HULL_HALF,  ENGIE_BEACON_HULL_HALF,
                                      ENGIE_BEACON_HULL_HEIGHT ) );

            UnstickPlayersFromBeacon( _tblTrace.pos );

            _hTele.SetModelScale ( ENGIE_BEACON_MODEL_SCALE, 0.0 );

            {
                local _flPi    =  3.141592653589793;
                local _vecUp   =  _tblTrace.plane_normal;
                local _flYaw   =  ( _angRest.y * _flPi / 180.0 );
                local _vecF0   =  Vector( cos( _flYaw ), sin( _flYaw ), 0 );

                local _vecFwd  =  ( _vecF0 - ( _vecUp * _vecF0.Dot( _vecUp ) ) );
                _vecFwd.Norm();

                local _vecLeft =  _vecUp.Cross( _vecFwd );

                _hTele.SetAngles ( ( asin( -_vecFwd.z )            * 180.0 / _flPi ),
                                   ( atan2( _vecFwd.y, _vecFwd.x ) * 180.0 / _flPi ),
                                   ( atan2( _vecLeft.z, _vecUp.z ) * 180.0 / _flPi ) );
            };

            SetPropInt ( _hTele, "m_nSkin", ENGIE_BEACON_SKIN );

            _hTele.ValidateScriptScope();

            local _tsc = _hTele.GetScriptScope();

            _tsc.m_fTimeStart    <-  m_fTimeStart;
            _tsc.m_fBuiltTime    <-  ( Time() + ENGIE_BEACON_BUILD_TIME );
            _tsc.m_hOwner        <-  m_hOwner;
            _tsc.m_bSettled      <-  true;
            _tsc.m_bBuilt        <-  false;
            _tsc.m_bMustDie      <-  false;
            _tsc.m_hVisual       <-  null;
            _tsc.m_hRespawnRoom  <-  null;
            _tsc.m_vecBeaconPos  <-  Vector( _tblTrace.pos.x, _tblTrace.pos.y,
                                             _tblTrace.pos.z );

            _tsc.m_hBeaconFX     <-  null;

            if ( m_hOwner != null && m_hOwner.IsValid() )
                m_hOwner.GetScriptScope().m_hOwnedBeacon <- _hTele;

            local _iBuildSeq = _hTele.LookupSequence( ENGIE_BEACON_BUILD_ANIM );

            if ( _iBuildSeq >= 0 )
            {
                _hTele.ResetSequence ( _iBuildSeq );

                local _flSeqLen = _hTele.GetSequenceDuration( _iBuildSeq );
                local _flRate   = ( _flSeqLen > 0 ) ? ( _flSeqLen / ENGIE_BEACON_BUILD_TIME ) : 1.0;

                SetPropFloat ( _hTele, "m_flPlaybackRate", _flRate );
            };

            EmitSoundOn ( SFX_BEACON_BUILD, _hTele );

            _tsc.BeaconBossKilled <- ::BeaconBossKilled;
            _hTele.ConnectOutput ( "OnKilled", "BeaconBossKilled" );

            AddThinkToEnt ( _hTele, "BeaconThink" );

            if ( m_hVisual != null && m_hVisual.IsValid() )
                m_hVisual.Destroy();

            self.Destroy();
            return -1;
        };
    };

    self.StudioFrameAdvance();

    if ( !m_bBuilt && Time() >= m_fBuiltTime )
    {
        m_bBuilt = true;

        StopSoundOn( SFX_BEACON_BUILD, self );

        ::arrZombieBeacons.append( self );

        m_hRespawnRoom = CreateBeaconRespawnRoom( self.GetOrigin() );

        local _iIdleSeq = self.LookupSequence( ENGIE_BEACON_IDLE_ANIM );

        if ( _iIdleSeq >= 0 )
        {
            self.ResetSequence ( _iIdleSeq );
            SetPropFloat ( self, "m_flPlaybackRate", 1.0 );
        };

        m_hBeaconFX = SpawnEntityFromTable( "info_particle_system",
        {
            effect_name  = FX_BEACON_EXIT,
            start_active = "1",
            targetname   = "engie_beacon_fx",
            origin       = ( self.GetOrigin() + Vector( 0, 0, 0.1 ) ),
        });

        EmitSoundOn ( SFX_BEACON_READY, self );
    };

    return ENGIE_BEACON_RETHINK_TIME;
};

BuildableEMPThink <- function()
{
    if ( m_fReactivateTime != 0 )
    {
        local _angAngles  =  self.GetAbsAngles();
        local _vecAngles  =  Vector( _angAngles.x, _angAngles.y, _angAngles.z );

        DispatchParticleEffect( FX_EMP_ELECTRIC, self.GetOrigin() + Vector( 0, 0, 20 ), _vecAngles );

        if ( Time() >= m_fReactivateTime )
        {
            SetPropBool ( self, "m_bHasSapper", false );
            SetPropBool ( self, "m_bDisabled",  false );
            m_fReactivateTime = 0.0;
        };
    };

    if ( m_fGlowKillTime != 0 && Time() >= m_fGlowKillTime )
    {
        SetPropBool ( self, "m_bGlowEnabled", false );
        m_fGlowKillTime = 0.0;
    };

    if ( m_fReactivateTime == 0 && m_fGlowKillTime == 0 )
    {
        SetPropString ( self, "m_iszScriptThinkFunction", "" );
        AddThinkToEnt ( self, null );
        return;
    };

    return ENGIE_EMP_BUILDING_RETHINK_TIME;
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

SplatFireThink <- function()
{
    if ( !m_bStopped && ( Time() >= m_flStopTime ) )
    {
        EntFireByHandle( self, "Stop", "", -1, null, null );
        m_bStopped = true;
    };

    if ( Time() < m_flKillTime )
        return SPLAT_FIRE_RETHINK_TIME;

    foreach ( _hCPEnt in m_arrCPEnts )
    {
        if ( _hCPEnt != null && _hCPEnt.IsValid() )
            _hCPEnt.Destroy();
    };

    m_arrCPEnts.clear();

    self.Destroy();
    return;
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

    if ( ::bGameStarted )
    {
        local _bUnderQuota = ( _iNumBluPlayers < GetZombieQuota( _iNumRedPlayers + _iNumBluPlayers ) );

        if ( _bUnderQuota )
        {
            if ( !::bZombieQuotaBuffOn )
                ClientPrint( null, HUD_PRINTTALK, format( STRING_UI_CHAT_ZOMBIE_QUOTA, STRING_UI_MINI_CRITS ) );

            foreach ( _hNextPlayer in GetAllPlayers() )
            {
                if ( _hNextPlayer.GetTeam() == TF_TEAM_BLUE && IsPlayerAlive( _hNextPlayer ) &&
                     !_hNextPlayer.InCond( TF_COND_DISGUISED ) )
                    _hNextPlayer.AddCondEx( TF_COND_OFFENSEBUFF, ZOMBIE_QUOTA_BUFF_REFRESH, null );
            };
        };

        ::bZombieQuotaBuffOn <- _bUnderQuota;
    }
    else if ( ::bZombieQuotaBuffOn )
    {
        ::bZombieQuotaBuffOn <- false;
    };

    return 0.5;
}

PyroSpewGlobThink <- function()
{
    if ( m_iState == PYRO_SPEW_STATE_IN_TRANSIT )
    {
        if ( Time() > m_flKillMeTime )
        {
            m_hPfx.Destroy();
            self.Destroy();
            return;
        };

        local _vecOrigin = self.GetOrigin();

        local _tblTrace =
        {
            start    =  _vecOrigin,
            end      =  _vecOrigin,
            hullmin  =  Vector( -12, -12, -12 ),
            hullmax  =  Vector( 12, 12, 12 ),
            filter   =  self,
        };

        TraceHull( _tblTrace );

        if ( _tblTrace.hit && ( "enthit" in _tblTrace ) )
        {
            if ( _tblTrace.enthit == m_hOwner &&
                 !( ( "m_bCanHitOwner" in this ) && m_bCanHitOwner ) )
                return PYRO_SPEW_RETHINK_TIME;

            local _szHitEntClass = _tblTrace.enthit.GetClassname();

            if ( _szHitEntClass == "player" )
            {
                if ( _tblTrace.enthit.GetTeam() == TF_TEAM_RED &&
                     !_tblTrace.enthit.InCond( TF_COND_INVULNERABLE ) &&
                     !_tblTrace.enthit.InCond( TF_COND_INVULNERABLE_USER_BUFF ) &&
                     !_tblTrace.enthit.InCond( TF_COND_PHASE ) )
                {
                    _tblTrace.enthit.ApplySpewDebuff( m_hOwner );
                };

                return PYRO_SPEW_RETHINK_TIME;
            }
            else if ( startswith( _szHitEntClass, "obj_" ) )
            {
                m_vecHitPosition    <- ( _tblTrace.enthit.GetOrigin() + Vector( 0, 0, 8 ) );
                m_iDistanceToGround <- PYRO_SPEW_HIT_WORLD_Z_DIST;
            }
            else
            {
                // world
                m_vecHitPosition    <- _tblTrace.pos;
                m_iDistanceToGround <- PYRO_SPEW_HIT_WORLD_Z_DIST;
            };

            self.SetPhysVelocity( Vector( 0, 0, 0 ) );
            m_iState <- PYRO_SPEW_STATE_FINDING_GROUND;
        };

        return PYRO_SPEW_RETHINK_TIME;
    }
    else if ( m_iState == PYRO_SPEW_STATE_FINDING_GROUND )
    {
        m_hPfx.Destroy();

        local _start = Vector( m_vecHitPosition.x, m_vecHitPosition.y, m_vecHitPosition.z );
        local _end   = Vector( _start.x, _start.y, ( _start.z - m_iDistanceToGround ) );

        local _tblTraceLine = { start = _start, end = _end, mask = MASK_SOLID_BRUSHONLY, ignore = self, };

        if ( !( TraceLineEx( _tblTraceLine ) && _tblTraceLine.hit ) )
        {
            // >it's over
            self.Destroy();
            return;
        };

        m_tblSplat <- FormSplatCells(
        {
            apex          =  _tblTraceLine.pos,
            normal        =  _tblTraceLine.plane_normal,
            dir           =  m_vecSpewDir,
            conelength    =  0,
            conespread    =  0,
            coneapexhalfw =  0,
            splashradius  =  PYRO_SPEW_TILE_RADIUS,
            cellsize      =  PYRO_SPEW_CELL_SIZE,
            ignore        =  self,
        } );


        local _angSpewImpact = SplatNormalToAngles( m_tblSplat.normal );

        DispatchParticleEffect( FX_SPEW_IMPACT, m_tblSplat.apex,
                                Vector( _angSpewImpact.x, _angSpewImpact.y, _angSpewImpact.z ) );

        EmitSoundOn( SFX_SPEW_IMPACT_WAV, self );

        if ( bSpitDebugBoxes )
        {
            DrawSplatCells( m_tblSplat,
                            PYRO_SPEW_ZONE_COLOR_R, PYRO_SPEW_ZONE_COLOR_G, PYRO_SPEW_ZONE_COLOR_B,
                            PYRO_SPEW_ZONE_ALPHA, PYRO_SPEW_ZONE_BOX_HEIGHT,
                            PYRO_SPEW_ZONE_LIFETIME );
        };

        SpawnSplatFireFX( m_tblSplat, FX_SPEW_GROUND, PYRO_SPEW_ZONE_LIFETIME );

        m_fZoneEndTime <- ( Time() + PYRO_SPEW_ZONE_LIFETIME ).tofloat();
        m_iState       <- PYRO_SPEW_STATE_ZONE;

        return PYRO_SPEW_ZONE_RETHINK_TIME;
    }
    else if ( m_iState == PYRO_SPEW_STATE_ZONE )
    {
        if ( Time() >= m_fZoneEndTime )
        {
            self.Destroy();
            return;
        };

        foreach ( _hNextPlayer in GetAllPlayers() )
        {
            if ( _hNextPlayer.GetTeam() != TF_TEAM_RED || _hNextPlayer.GetHealth() <= 0 )
                continue;

            if ( _hNextPlayer.InCond( TF_COND_INVULNERABLE ) ||
                 _hNextPlayer.InCond( TF_COND_INVULNERABLE_USER_BUFF ) ||
                 _hNextPlayer.InCond( TF_COND_PHASE ) )
                continue;

            local _psc = _hNextPlayer.GetScriptScope();

            if ( _psc != null && ( "m_iFlags" in _psc ) && ( _psc.m_iFlags & ZBIT_SPEWED ) &&
                 ( _psc.m_fSpewEndTime - Time() ) >
                 ( PYRO_SPEW_DEBUFF_DURATION - PYRO_SPEW_REFRESH_SLACK ) )
                continue;

            if ( !IsPointInSplat( _hNextPlayer.GetOrigin(), m_tblSplat ) )
                continue;

            if ( DEBUG_MODE )

            _hNextPlayer.ApplySpewDebuff( m_hOwner, false );
        };

        return PYRO_SPEW_ZONE_RETHINK_TIME;
    };

    return PYRO_SPEW_RETHINK_TIME;
}

HeavyRockThink <- function()
{
    if ( Time() > m_flKillMeTime )
    {
        BreakHeavyRockVisual( m_hVisual, self );
        m_hVisual = null;

        self.Destroy();
        return;
    };

    local _vecOrigin = self.GetOrigin();

    local _bDbg = ( DEBUG_MODE && bHeavyRockDebug );

    if ( _bDbg && ( "m_vecLastPos" in this ) &&
         ( ( _vecOrigin - m_vecLastPos ).Length() >= HEAVY_ROCK_DBG_TRAIL_STEP ) )
    {
        DebugDrawLine ( m_vecLastPos, _vecOrigin, 0, 200, 255, true, HEAVY_ROCK_DBG_TRAIL_TIME );

        DebugDrawBox ( _vecOrigin,
                       Vector( -HEAVY_ROCK_HULL_SIZE, -HEAVY_ROCK_HULL_SIZE, -HEAVY_ROCK_HULL_SIZE ),
                       Vector(  HEAVY_ROCK_HULL_SIZE,  HEAVY_ROCK_HULL_SIZE,  HEAVY_ROCK_HULL_SIZE ),
                       255, 255, 255, 25, HEAVY_ROCK_DBG_TRAIL_TIME );

        m_vecLastPos = Vector( _vecOrigin.x, _vecOrigin.y, _vecOrigin.z );
    };

    local _vecFrom = ( "m_vecTraceFrom" in this ) ? m_vecTraceFrom : _vecOrigin;

    local _tblTrace =
    {
        start    =  _vecFrom,
        end      =  _vecOrigin,
        hullmin  =  Vector( -HEAVY_ROCK_HULL_SIZE, -HEAVY_ROCK_HULL_SIZE, -HEAVY_ROCK_HULL_SIZE ),
        hullmax  =  Vector(  HEAVY_ROCK_HULL_SIZE,  HEAVY_ROCK_HULL_SIZE,  HEAVY_ROCK_HULL_SIZE ),
        ignore   =  self,
    };

    TraceHull( _tblTrace );

    m_vecTraceFrom = Vector( _vecOrigin.x, _vecOrigin.y, _vecOrigin.z );

    if ( !_tblTrace.hit )
        return HEAVY_ROCK_RETHINK_TIME;

    local _hHit = ( "enthit" in _tblTrace ) ? _tblTrace.enthit : null;

    local _hDirectVictim = null;

    if ( _hHit != null )
    {
        if ( _hHit == self )
            return HEAVY_ROCK_RETHINK_TIME;

        if ( _hHit == m_hOwner )
            return HEAVY_ROCK_RETHINK_TIME;

        if ( m_hVisual != null && _hHit == m_hVisual )
            return HEAVY_ROCK_RETHINK_TIME;

        if ( _hHit.GetClassname() == "player" )
        {
            // rock passes through zombies
            if ( _hHit.GetTeam() == TF_TEAM_BLUE )
                return HEAVY_ROCK_RETHINK_TIME;

            _hDirectVictim = _hHit;
        };
    };

    local _szHitName = ( _hHit != null ) ? _hHit.GetClassname() : "static geometry";


    if ( "pos" in _tblTrace )
        _vecOrigin = _tblTrace.pos;

    if ( _bDbg )
    {
        DebugDrawBox  ( _vecOrigin, Vector( -8, -8, -8 ), Vector( 8, 8, 8 ),
                        255, 255, 0, 200, HEAVY_ROCK_DBG_IMPACT_TIME );
        DebugDrawText ( _vecOrigin,
                        ( "IMPACT " + _szHitName +
                          ( _hDirectVictim != null ? " (DIRECT)" : "" ) ),
                        false, HEAVY_ROCK_DBG_IMPACT_TIME );

        for ( local _i = 0; _i < HEAVY_ROCK_DBG_RINGS; _i++ )
        {
            local _flT = ( ( 2.0 * _i / ( HEAVY_ROCK_DBG_RINGS - 1.0 ) ) - 1.0 );
            local _flR = ( HEAVY_ROCK_SPLASH_RADIUS * sqrt( 1.0 - ( _flT * _flT ) ) );

            DebugDrawCircle( ( _vecOrigin + Vector( 0, 0, ( _flT * HEAVY_ROCK_SPLASH_RADIUS ) ) ),
                             Vector( 255, 80, 0 ), 20, _flR, true, HEAVY_ROCK_DBG_IMPACT_TIME );
        };
    };

    local _bOwnerOk   =  ( m_hOwner != null && m_hOwner.IsValid() );
    local _hKillIcon  =  _bOwnerOk ? KilliconInflictor( KILLICON_HEAVY_ROCK ) : null;

    if ( _hDirectVictim != null )
    {
        if ( _bOwnerOk )
        {
            _hDirectVictim.TakeDamageEx( _hKillIcon, m_hOwner, m_hOwner.GetActiveWeapon(),
                                         Vector( 0, 0, 0 ), _vecOrigin,
                                         HEAVY_ROCK_DIRECT_DAMAGE,
                                         ( DMG_CLUB | DMG_PREVENT_PHYSICS_FORCE ) );

            if ( !_hDirectVictim.InCond( TF_COND_INVULNERABLE ) &&
                 !_hDirectVictim.InCond( TF_COND_INVULNERABLE_USER_BUFF ) &&
                 !_hDirectVictim.InCond( TF_COND_PHASE ) )
            {
                try
                {
                    _hDirectVictim.StunPlayer( HEAVY_ROCK_STUN_DURATION,
                                               HEAVY_ROCK_STUN_SLOWDOWN,
                                               HEAVY_ROCK_STUN_FLAGS,
                                               m_hOwner );
                }
                catch ( e )
                {
                };
            };
        };

        EmitSoundOn( SFX_HEAVY_ROCK_FLESH, _hDirectVictim );
    };

    local _hNextPlayer = null;

    while ( _hNextPlayer = Entities.FindByClassnameWithin( _hNextPlayer, "player", _vecOrigin, HEAVY_ROCK_SPLASH_RADIUS ) )
    {
        if ( _hNextPlayer == null )
            continue;

        if ( _hNextPlayer.GetTeam() != TF_TEAM_RED || _hNextPlayer.GetHealth() <= 0 )
            continue;

        local _bIsDirectVictim = ( _hNextPlayer == _hDirectVictim );

        local _vecAim = ( _hNextPlayer.GetOrigin() + Vector( 0, 0, HEAVY_ROCK_SPLASH_AIM_Z ) );

        if ( !_bIsDirectVictim && bHeavyRockBlastLOS )
        {
            local _tblLOS =
            {
                start   =  _vecOrigin + Vector( 0, 0, HEAVY_ROCK_SPLASH_LOS_Z_OFF ),
                end     =  _vecAim,
                mask    =  HEAVY_ROCK_LOS_MASK,
                ignore  =  self,
            };

            TraceLineEx( _tblLOS );

            local _bBlocked = _tblLOS.hit;

            if ( _bDbg )
            {
                DebugDrawLine( _tblLOS.start, _vecAim,
                               ( _bBlocked ? 255 : 0 ), ( _bBlocked ? 0 : 255 ), 0,
                               true, HEAVY_ROCK_DBG_IMPACT_TIME );

                if ( _bBlocked )
                    DebugDrawText( _vecAim, "BLOCKED by geometry", false, HEAVY_ROCK_DBG_IMPACT_TIME );
            };

            if ( _bBlocked )
                continue;
        };

        local _flDist = ( _hNextPlayer.GetOrigin() - _vecOrigin ).Length();
        local _flFrac = ( 1.0 - ( _flDist / HEAVY_ROCK_SPLASH_RADIUS.tofloat() ) );

        if ( _flFrac < 0.0 ) _flFrac = 0.0;
        if ( _flFrac > 1.0 ) _flFrac = 1.0;

        local _flForce = ( HEAVY_ROCK_SPLASH_FORCE *
                           ( HEAVY_ROCK_SPLASH_RIM_FRAC + ( ( 1.0 - HEAVY_ROCK_SPLASH_RIM_FRAC ) * _flFrac ) ) );

        KnockbackPlayer( self, _hNextPlayer, _flForce, HEAVY_ROCK_SPLASH_LIFT, true,
                         ( _vecAim - _vecOrigin ) );

        local _flDamage = ( HEAVY_ROCK_SPLASH_DAMAGE_MIN +
                            ( ( HEAVY_ROCK_SPLASH_DAMAGE - HEAVY_ROCK_SPLASH_DAMAGE_MIN ) * _flFrac ) );

        if ( _bOwnerOk && !_bIsDirectVictim )
        {
            _hNextPlayer.TakeDamageEx( _hKillIcon, m_hOwner, m_hOwner.GetActiveWeapon(),
                                       Vector( 0, 0, 0 ), _vecOrigin,
                                       _flDamage,
                                       ( DMG_CLUB | DMG_PREVENT_PHYSICS_FORCE ) );
        };

        if ( _bDbg )
        {

        };
    };

    local _arrBuildings  =  [ ];
    local _hNextBuilding =  null;

    while ( _hNextBuilding = Entities.FindByClassnameWithin( _hNextBuilding, "obj_*", _vecOrigin, HEAVY_ROCK_SPLASH_RADIUS ) )
    {
        if ( _hNextBuilding == null )
            continue;

        local _szClass = _hNextBuilding.GetClassname();

        if ( _szClass != "obj_sentrygun"  &&
             _szClass != "obj_teleporter" &&
             _szClass != "obj_dispenser" )
            continue;

        _arrBuildings.append( _hNextBuilding );
    };

    foreach ( _hBuilding in _arrBuildings )
    {
        if ( _hBuilding == null || !_hBuilding.IsValid() )
            continue;

        local _vecBuildAim = ( _hBuilding.GetOrigin() + Vector( 0, 0, HEAVY_ROCK_SPLASH_LOS_Z_OFF ) );

        if ( bHeavyRockBlastLOS )
        {
            local _tblBuildLOS =
            {
                start   =  _vecOrigin + Vector( 0, 0, HEAVY_ROCK_SPLASH_LOS_Z_OFF ),
                end     =  _vecBuildAim,
                mask    =  HEAVY_ROCK_LOS_MASK,
                ignore  =  self,
            };

            TraceLineEx( _tblBuildLOS );

            if ( _tblBuildLOS.hit )
            {
                if ( _bDbg )
                    DebugDrawText( _vecBuildAim, "BUILDING BLOCKED by geometry", false,
                                   HEAVY_ROCK_DBG_IMPACT_TIME );

                continue;
            };
        };

        EmitSoundOn( SFX_EMP_BUILDING_DMGED, _hBuilding );

        if ( _bOwnerOk )
            _hBuilding.TakeDamageEx( _hKillIcon, m_hOwner, null,
                                     Vector( 0, 0, 0 ), _vecOrigin,
                                     HEAVY_ROCK_BUILDING_DAMAGE,
                                     ( DMG_CLUB | DMG_PREVENT_PHYSICS_FORCE ) );

        // the hit may well have destroyed it
        if ( !_hBuilding.IsValid() || !_hBuilding.ValidateScriptScope() )
            continue;

        local _scBuilding = _hBuilding.GetScriptScope();

        // BuildableEMPThink drives both jobs off these two slots
        if ( !( "m_fGlowKillTime" in _scBuilding ) )
            _scBuilding.m_fGlowKillTime <- 0.0;

        if ( !( "m_fReactivateTime" in _scBuilding ) )
            _scBuilding.m_fReactivateTime <- 0.0;

        // never re-disable one that's already down - that would stretch a spy's emp
        if ( GetPropBool( _hBuilding, "m_bDisabled" ) )
            continue;

        _scBuilding.m_fReactivateTime <- ( Time() + HEAVY_ROCK_BUILDING_DISABLE_TIME );

        SetPropBool   ( _hBuilding, "m_bHasSapper", true );
        SetPropBool   ( _hBuilding, "m_bDisabled",  true );
        AddThinkToEnt ( _hBuilding, "BuildableEMPThink" );
    };

    if ( _hKillIcon != null )
        _hKillIcon.Destroy();

    foreach ( _szFX in [ FX_HEAVY_ROCK_LAND_DUST,
                         FX_HEAVY_ROCK_LAND_DEBRIS,
                         FX_HEAVY_ROCK_LAND_DUST2,
                         FX_HEAVY_ROCK_LAND_DUST3,
                         FX_HEAVY_ROCK_LAND ] )
    {
        DispatchParticleEffect( _szFX, _vecOrigin, Vector( 0, 0, 0 ) );
    };

    HeavyRockScreenShake ( _vecOrigin );

    try
    {
        EmitSoundEx(
        {
            sound_name   =  SFX_HEAVY_ROCK_CONCRETE,
            origin       =  _vecOrigin,
            volume       =  HEAVY_ROCK_CONCRETE_VOLUME,
            sound_level  =  HEAVY_ROCK_CONCRETE_SNDLVL,
            pitch        =  HEAVY_ROCK_CONCRETE_PITCH,
        } );
    }
    catch ( e )
    {
        EmitSoundOn( SFX_HEAVY_ROCK_CONCRETE, self );
    };

    if ( _hDirectVictim == null )
        EmitSoundOn( SFX_HEAVY_ROCK_WORLD, self );

    BreakHeavyRockVisual( m_hVisual, self );
    m_hVisual = null;

    self.Destroy();
    return;
}

function SpawnBodyThink()
{
    // the prop may already be gone
    if ( !self.IsValid() )
        return;

    if ( m_hOwner == null || !m_hOwner.IsValid() )
    {
        self.Destroy();
        return;
    };

    local _sc = m_hOwner.GetScriptScope();

    local _bWanted = false;

    if ( _sc != null && ( "m_iFlags" in _sc ) )
    {
        _bWanted = ( ( _sc.m_iFlags & ( ZBIT_IN_SPAWN_PICKER |
                                        ZBIT_EMERGING_FROM_GROUND |
                                        ZBIT_HEAVY_ROCK_WINDUP ) ) != 0 ) ||
                   ( ( ( _sc.m_iFlags & ZBIT_DEMOCHARGE ) != 0 ) &&
                     ( ( _sc.m_iFlags & ZBIT_MUST_EXPLODE ) == 0 ) );
    };

    if ( !_bWanted || !IsPlayerAlive( m_hOwner ) )
    {
        m_hOwner.SetSpawnBodyHidden( false );

        if ( _sc != null && ( "m_hSpawnBody" in _sc ) && _sc.m_hSpawnBody == self )
            _sc.m_hSpawnBody <- null;

        self.Destroy();
        return;
    };

    return SPAWN_BODY_THINK_TIME;
}