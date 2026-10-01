// --------------------------------------------------------------------------------------- //
// Zombie Infection                                                                        //
// --------------------------------------------------------------------------------------- //
// All Code By: netmuck (https://steamcommunity.com/profiles/76561198025795825)            //
// Assets/Game Design by: Diva Dan (https://steamcommunity.com/profiles/76561198072146551) //
// --------------------------------------------------------------------------------------- //
// zombie abilites                                                                         //
// --------------------------------------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
// ZombieEngie EMP Grenade Ability |------------------------------------------------------ //
/////////////////////////////////////////////////////////////////////////////////////////////
ENGIE_EMP_LIFETIME               <- 1.75;  // How long the EMP lasts for once thrown       //
// --------------------------------------------------------------------------------------- //
ENGIE_EMP_BUILDING_DISABLE_TIME  <- 5.5;   // how long is a hit buildable disabled         //
ENGIE_EMP_BUILDING_DISABLE_RANGE <- 450;   // range from grenade explode to disable        //
// --------------------------------------------------------------------------------------- //
ENGIE_EMP_THROW_DIST_FROM_EYES   <- -20;   // distance from eyes to spawn grenade          //
ENGIE_EMP_THROW_FORCE            <- 1500;  // initial force to apply to nade               //
// --------------------------------------------------------------------------------------- //
ENGIE_EMP_INITIAL_FLASH_RATE     <- 0.425; // initial delay between each flash - halved    //
                                           // alongside the lifetime so the beep still     //
                                           // ramps up over the whole fuse                 //
ENGIE_EMP_FLASH_RATE_DECAY_FAC   <- 0.7;   // amnt delay reduced between flashes           //
// --------------------------------------------------------------------------------------- //
ENGIE_EMP_SCREENSHAKE_AMP        <- 500;   // amplitude of grenade screenshake             //
ENGIE_EMP_SCREENSHAKE_FREQ       <- 500;   // frequency of grenade screenshake             //
ENGIE_EMP_SCREENSHAKE_DUR        <- 1;     // duration of grenade screenshake              //
ENGIE_EMP_SCREENSHAKE_RAD        <- 1000;  // duration of grenade screenshake              //
ENGIE_EMP_MINIROOT_LEN           <- 0.25;  //                                              //
ENGIE_EMP_FIRST_HIT_RANGE        <- 88;    //                                              //
ENGIE_EMP_FIRST_HIT_DMG_PERCENT  <- 0.25;  //                                              //
// --------------------------------------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
// ZombieEngie Beacon Ability |----------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
ENGIE_BEACON_THROW_DIST_FROM_EYES <- -20;   // distance from eyes to spawn beacon           //
ENGIE_BEACON_THROW_FORCE          <- 750;   // initial force - half the emp nade's throw    //
// --------------------------------------------------------------------------------------- //
ENGIE_BEACON_MODEL_SCALE          <- 1.0;   // model scale of the thrown beacon             //
ENGIE_BEACON_SKIN                 <- 1;     // buildable skins are 0 red / 1 blu            //
ENGIE_BEACON_MINIROOT_LEN         <- 0.25;  // root duration after throwing the beacon      //
// --------------------------------------------------------------------------------------- //
ENGIE_BEACON_HEALTH               <- 150;   // beacon hp (lvl 1 tele) humans can destroy    //
ENGIE_BEACON_BUILD_TIME           <- 4.0;   // secs of building before becoming a beacon    //
// --------------------------------------------------------------------------------------- //
ENGIE_BEACON_BUILD_ANIM           <- "build";   // tele unfold sequence played on landing   //
ENGIE_BEACON_IDLE_ANIM            <- "running"; // looping sequence once fully built        //
// --------------------------------------------------------------------------------------- //
ENGIE_BEACON_SETTLE_NORMAL_Z      <- 0.90;  // min ground normal z to sprout - ~25 deg; the tele is forced upright on deploy anyway //
ENGIE_BEACON_GROUND_TRACE_DIST    <- 20;    // downward trace length to find ground         //
ENGIE_BEACON_SPAWN_CLEARANCE      <- 82;    // clear space above the beacon a spawner needs //
// --------------------------------------------------------------------------------------- //
ENGIE_BEACON_LIFETIME             <- 8.0;   // secs before a beacon that never rested gives up //
ENGIE_BEACON_DESTROY_TIME         <- 2.0;   // secs from first invalid contact to give up   //
ENGIE_BEACON_FAIL_REFUND          <- 0.5;   // fraction of remaining cd back on a bad spot  //
ENGIE_BEACON_CLIP_BOUNCE          <- 0.65;  // speed kept when bouncing off playerclip      //
ENGIE_BEACON_HURT_HULL_RADIUS     <- 12;    // half-width used for the trigger_hurt sweep   //
ENGIE_BEACON_HULL_HALF            <- 24;    // solid bbox half-width of the built tele      //
ENGIE_BEACON_HULL_HEIGHT          <- 12;    // its height - flat, players step onto it      //
ENGIE_BEACON_UNSTICK_RADIUS       <- 72;    // player search around a beacon as it builds   //
ENGIE_BEACON_UNSTICK_CLEARANCE    <- 1;     // gap left above the lid when stepping them up //
ENGIE_BEACON_ROOM_HALF_WIDTH      <- 48;    // half-width of the respawn room over the tele //
ENGIE_BEACON_ROOM_HEIGHT          <- 96;    // its height above the tele base               //
// --------------------------------------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
// Surface Splat - shared by spit + spew |--------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
SPLAT_STEP_UP                    <- 18;    // max step up between cells                    //
SPLAT_STEP_DOWN                  <- 40;    // max step down between cells                  //
SPLAT_FILL_WALL_Z                <- 24;    // height of the cell-to-cell wall trace        //
SPLAT_Z_EPSILON                  <- 2;     // lift cells off the ground plane              //
// --------------------------------------------------------------------------------------- //
SPLAT_MIN_SURFACE_Z              <- 0.34;  // min ground normal z a cell can hold goop on  //
SPLAT_SLOPE_NORMAL_Z             <- 0.98;  // above this a surface counts as flat          //
SPLAT_NORMAL_Z_FLOOR             <- 0.2;   // divide guard when reading a plane's z        //
SPLAT_PREDICT_CAP_MULT           <- 3.0;   // cap on the slope prediction per step         //
SPLAT_PROBE_UP_MULT              <- 1.5;   // ground probe start height above prediction   //
SPLAT_CASCADE_STEPS              <- 3;     // sub-steps for the stair cascade walk         //
SPLAT_SLIDE_OFFSET               <- 8;     // nudge off a too-steep impact face            //
SPLAT_SLIDE_DIST                 <- 512;   // max drop to the floor after the nudge        //
SPLAT_DRAW_STRETCH_MAX           <- 3.0;   // cap on the tilted cell box stretch           //
SPLAT_RAD_TO_DEG                 <- 57.295779513;
// --------------------------------------------------------------------------------------- //
SPLAT_ZONE_Z_BELOW               <- 45;    // containment window below a cell's plane      //
SPLAT_ZONE_Z_ABOVE               <- 60;    // containment window above a cell's plane      //
// --------------------------------------------------------------------------------------- //
SPLAT_FIRE_ENT_PREFIX            <- "zi_splatfire_"; // shared name for one splat's fire fx //
SPLAT_FIRE_ENGINE_MAX_CP         <- 63;    // engine max particle control points           //
SPLAT_FIRE_MAX_CP                <- 32;    // edict budget for control points              //
SPLAT_FIRE_TARGET_TRANSMIT       <- 1;     // info_target spawnflag 1, transmit to client  //
SPLAT_FIRE_FADE_TIME             <- 2.0;   // grace before freeing the fx ents             //
SPLAT_FIRE_RETHINK_TIME          <- 0.1;   // cadence of the teardown think                //
// --------------------------------------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
// ZombieSniper Spit Ability |------------------------------------------------------------ //
/////////////////////////////////////////////////////////////////////////////////////////////
SNIPER_SPIT_THROW_DIST           <- 50;    // distance from eyes to spawn spit ball        //
SNIPER_SPIT_THROW_FORCE          <- 2000;  // initial force to apply to spit ball          //
SNIPER_SPIT_HIT_PLAYER_Z_DIST    <- 300;   // initial force to apply to spit ball          //
SNIPER_SPIT_HIT_WORLD_Z_DIST     <- 100;   // initial force to apply to spit ball          //
// --------------------------------------------------------------------------------------- //
SNIPER_SPIT_MASS                 <- 0.1;   // spit ball mass (for base physprop)           //
// --------------------------------------------------------------------------------------- //
SNIPER_SPIT_ZONE_DAMAGE          <- 25.0;  // damage per tick from spit zone               //
SNIPER_SPIT_POP_DAMAGE           <- 45.0;  // dmg to players in zone when first pop        //
// --------------------------------------------------------------------------------------- //
SNIPER_SPIT_VM_FREEZE_FRAME      <- 4.0;   // special-anim frame the channel holds on      //
SNIPER_SPIT_VM_FPS               <- 30.0;  // special-anim framerate, for frame -> secs    //
// --------------------------------------------------------------------------------------- //
SNIPER_SPIT_OVERLOAD_START_TIME  <- 3.5;   // how many seconds til overload                //
SNIPER_SPIT_LIFETIME             <- 2.5;   // how many seconds til overload                //
SNIPER_SPIT_MAX_CHANNEL_TIME     <- 5;     // max time spitball can be held for            //
SNIPER_SPIT_CHARGE_SLOW          <- 0.5;   // move speed while the charge is held          //
SPIT_ZONE_LIFETIME               <- 5;     // how many seconds the zone stays down         //
SPIT_ZONE_RADIUS                 <- 130;   // reach of the puddle fill from the impact     //
SPIT_CELL_SIZE                   <- 50;    // width of one puddle grid cell                //
// --------------------------------------------------------------------------------------- //
SPIT_ZONE_BOX_HEIGHT             <- 8;     // z extent of the drawn zone box               //
SPIT_ZONE_COLOR_R                <- 0;     // zone box rgb                                 //
SPIT_ZONE_COLOR_G                <- 255;   //                                              //
SPIT_ZONE_COLOR_B                <- 0;     //                                              //
SPIT_ZONE_ALPHA                  <- 30;    // zone box alpha                               //
// --------------------------------------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
// ZombieSpy EMP Ability |---------------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
SPY_REVEAL_RANGE                 <- 900;   // Maximum distance for player to be hit        //
SPY_REVEAL_LENGTH                <- 20;    // how long players are revealed for (sec)      //
SPY_RECLOAK_TIME                 <- 3;     // how long before spy becomes cloaked again    //
SPY_EMP_BUILDING_GLOW_LEN        <- 5.5;   // how long buildings stay outlined (sec)       //
SPY_REVEAL_SNDLVL                <- 135;   // reveal sfx soundlevel (db), higher = louder  //
// --------------------------------------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
// ZombieMedic Heal Ability |------------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
MEDIC_HEAL_RANGE                 <- 275;   // Maximum distance for player to be hit        //
MEDIC_HEAL_RATE                  <- 0.5;   // time in sec between each heal tick           //
/////////////////////////////////////////////////////////////////////////////////////////////
// ZombieDemo Charge Ability |------------------------------------------------------------ //
/////////////////////////////////////////////////////////////////////////////////////////////
DEMOMAN_CHARGE_DAMAGE            <- 275;   //                                              //
DEMOMAN_CHARGE_RADIUS            <- 150;   //                                              //
/////////////////////////////////////////////////////////////////////////////////////////////
// ZombiePyro Spew Ability |--------------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
PYRO_SPEW_THROW_FORCE             <- 1200;  // physics throw force of the spew glob          //
PYRO_SPEW_GLOB_LIFETIME           <- 5.0;   // max seconds in flight before fizzling        //
PYRO_SPEW_DEBUFF_DURATION         <- 6.0;   // seconds the spew debuff lasts on a survivor   //
// --------------------------------------------------------------------------------------- //
PYRO_SPEW_ZONE_LIFETIME           <- 8.0;   // seconds the spew zone stays active            //
PYRO_SPEW_REFRESH_SLACK           <- 0.5;   // debuff re-apply cadence while standing in    //
// --------------------------------------------------------------------------------------- //
PYRO_SPEW_HIT_WORLD_Z_DIST        <- 100;   // ground search below a world/building impact  //
// --------------------------------------------------------------------------------------- //
PYRO_SPEW_BURST_COUNT             <- 4;     // blobs fired per cast                         //
PYRO_SPEW_BURST_INTERVAL          <- 0.175; // secs between blobs in the burst              //
PYRO_SPEW_SPIT_PITCH              <- 50;    // per-blob splash wav pitch - 100 stock        //
// --------------------------------------------------------------------------------------- //
PYRO_SPEW_CELL_SIZE               <- 50;    // width of one goop tile                       //
PYRO_SPEW_TILE_RADIUS             <- 1;     // splat reach - below CELL_SIZE = exactly the  //
                                           // one tile the blob lands on                   //
// --------------------------------------------------------------------------------------- //
PYRO_SPEW_KNOCKBACK_MULT          <- 0.5;   // incoming damage-force mult while spewed      //
PYRO_SPEW_SELF_PUSH_MULT          <- 0.25;  // own blast-jump push kept while spewed - 75% cut        //
PYRO_SPEW_CHARGE_SPEED_MULT       <- 0.4;   // demo shield charge speed kept (60% cut)      //
PYRO_SPEW_CHARGE_BASE_SPEED       <- 750;   // stock charge speed the cap derives from      //
PYRO_SPEW_TICK_DAMAGE             <- 1;     // hp drained per tick while spewed             //
PYRO_SPEW_TICK_INTERVAL           <- 1.0;   // seconds between drain ticks                  //
// --------------------------------------------------------------------------------------- //
PYRO_SPEW_TINT                    <- 0xFF9B6487; // packed abgr model tint - muted purple      //
PYRO_SPEW_ZONE_BOX_HEIGHT         <- 6;     // z extent of the drawn zone box               //
PYRO_SPEW_ZONE_COLOR_R            <- 140;   // zone box rgb                                 //
PYRO_SPEW_ZONE_COLOR_G            <- 110;   //                                              //
PYRO_SPEW_ZONE_COLOR_B            <- 160;   //                                              //
PYRO_SPEW_ZONE_ALPHA              <- 40;    // zone box alpha                               //
// --------------------------------------------------------------------------------------- //
ARR_SPEW_TINT_WEARABLES <-
[
    "tf_wearable*",
    "tf_powerup_bottle",
    "tf_weapon_spellbook",
];
::bSpewNoScreenOverlay          <- false;
// --------------------------------------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
// ZombieHeavy Rock Throw Ability |-------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
HEAVY_ROCK_THROW_DELAY           <- 1.9;   // secs into the animation the rock leaves      //
HEAVY_ROCK_THROW_ANIM_TIME       <- 3.4;   // secs of animation                             //
// --------------------------------------------------------------------------------------- //
HEAVY_ROCK_WINDUP_SEQUENCE       <- "rock_throw";
HEAVY_ROCK_WINDUP_RATE           <- 1.0;
HEAVY_ROCK_WINDUP_BODYGROUP      <- 1;     // rock bodygroup on the stand-in body          //
// --------------------------------------------------------------------------------------- //
arrHeavyRockWindupFallbackSeqs <-
[
    "taunt_yetipunch",
    "throw_fire",
    "taunt01",
    "stand_MELEE",
];
// --------------------------------------------------------------------------------------- //
// flight + blast visualisers, only drawn in debug mode                                    //
::bHeavyRockDebug                <- true;
HEAVY_ROCK_DBG_TRAIL_TIME        <- 8.0;   // how long the flight trail lingers             //
HEAVY_ROCK_DBG_IMPACT_TIME       <- 10.0;  // how long the impact diagram lingers           //
HEAVY_ROCK_DBG_RINGS             <- 5;     // stacked circles used to draw the blast sphere //
HEAVY_ROCK_DBG_TRAIL_STEP        <- 48;    // min travel between drawn trail segments       //
// --------------------------------------------------------------------------------------- //
HEAVY_ROCK_THROW_FORCE           <- 1100;  // forward force of the throw                   //
HEAVY_ROCK_THROW_LIFT            <- 350;   // upward force on top of it                    //
HEAVY_ROCK_THROW_DIST            <- 40;    // spawn distance ahead of the eyes             //
HEAVY_ROCK_THROW_Z_OFFSET        <- -10;   // spawn height below them                      //
// --------------------------------------------------------------------------------------- //
HEAVY_ROCK_MODEL_SCALE           <- 1.0;   // model scale of the thrown rock               //
HEAVY_ROCK_LIFETIME              <- 6.0;   // secs before an untouched rock vanishes       //
HEAVY_ROCK_ENT_NAME              <- "heavy_rock_physprop"; // invisible physics shell      //
HEAVY_ROCK_FX_NAME               <- "heavy_rock_fx";       // the rock model riding it     //
// --------------------------------------------------------------------------------------- //
HEAVY_ROCK_DIRECT_DAMAGE         <- 70;    // damage to the player the rock hits square    //
HEAVY_ROCK_STUN_DURATION         <- 2.5;   // secs of bonk on that direct hit              //
HEAVY_ROCK_STUN_SLOWDOWN         <- 1.0;   // stun reduction amount, 0-1                   //
HEAVY_ROCK_STUN_FLAGS            <- ( TF_STUN_CONTROLS ); // bonk, no sandman ding         //
// --------------------------------------------------------------------------------------- //
HEAVY_ROCK_SPLASH_RADIUS         <- 150;   // reach of the blast                           //
HEAVY_ROCK_SPLASH_DAMAGE         <- 48;    // splash damage at the impact point            //
HEAVY_ROCK_SPLASH_DAMAGE_MIN     <- 18;    // splash damage at the rim                     //
HEAVY_ROCK_SPLASH_FORCE          <- 800;   // knockback impulse at the impact point        //
HEAVY_ROCK_SPLASH_RIM_FRAC       <- 0.5;   // knockback fraction at the rim                //
HEAVY_ROCK_SPLASH_LIFT           <- 0.45;  // upward share of that impulse                 //
HEAVY_ROCK_SPLASH_LOS_Z_OFF      <- 16;    // lift on the blast line-of-sight trace        //
HEAVY_ROCK_SPLASH_AIM_Z          <- 40;    // aim height up the victim, chest not feet     //
HEAVY_ROCK_HULL_SIZE             <- 12;    // half-width of the in-flight contact hull     //
// --------------------------------------------------------------------------------------- //
HEAVY_ROCK_BUILDING_DAMAGE       <- 70;    // flat damage to every building in the blast   //
HEAVY_ROCK_BUILDING_DISABLE_TIME <- 2.5;   // brief emp-style knockout, shorter than the   //
                                           // spy nade's 6.5                               //
// --------------------------------------------------------------------------------------- //
// brush-only so a player in the way doesn't absorb the blast for everyone behind them     //
HEAVY_ROCK_LOS_MASK              <- MASK_SOLID_BRUSHONLY;
::bHeavyRockBlastLOS             <- true;
// --------------------------------------------------------------------------------------- //
HEAVY_ROCK_CONCRETE_VOLUME       <- 1.0;   // concrete break layered over the thud         //
HEAVY_ROCK_CONCRETE_SNDLVL       <- 110;   // soundlevel (db), stock script is too quiet   //
HEAVY_ROCK_CONCRETE_PITCH        <- 100;   //                                              //
// --------------------------------------------------------------------------------------- //
HEAVY_ROCK_SHAKE_AMPLITUDE       <- 6.0;   // screenshake strength at the centre           //
HEAVY_ROCK_SHAKE_RADIUS          <- 450;   // reaches well past the blast                  //
HEAVY_ROCK_SHAKE_DURATION        <- 0.6;   // secs it rattles for                          //
HEAVY_ROCK_SHAKE_FREQUENCY       <- 40.0;  // high = a sharp jolt, low = a slow roll       //
// --------------------------------------------------------------------------------------- //
HEAVY_ROCK_GIB_VEL_SCALE         <- 1.5;   // gibs carry this x the rock's flight speed    //
HEAVY_ROCK_GIB_SCATTER           <- 600;   // random per-gib velocity on top, each axis    //
HEAVY_ROCK_GIB_LIFT              <- 550;   // upward kick added so the burst fans out      //
HEAVY_ROCK_GIB_SPIN              <- 1800;  // random per-gib spin, deg/sec each axis       //
HEAVY_ROCK_GIB_LIFETIME          <- 10.0;  // secs before the gibs are removed             //
// --------------------------------------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////
// generic zombie stuff      |------------------------------------------------------------ //
/////////////////////////////////////////////////////////////////////////////////////////////
ZOMBIE_BOOST_SPEED_DEBUFF        <- 0.85;  //                                              //
// --------------------------------------------------------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////

class CZombieAbility
{
    m_iAbilityType       =   0;
    m_hAbilityOwner      =   null;
    m_fAbilityCooldown   =   0.0;
    m_fSpawnCooldown     =   0.0;  // secs unavailable after spawning, 0 = ready instantly

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
// --------------------------------- //
//            SPY ABILITY            //
// --------------------------------- //
class CSpyEMP extends CZombieAbility
{
    constructor( hAbilityOwner )
    {
        this.m_hAbilityOwner     =  hAbilityOwner;
        this.m_iAbilityType      =  ZABILITY_THROWABLE;
        this.m_fAbilityCooldown  =  MIN_TIME_BETWEEN_SPY_EMP;
        this.m_szAbilityName     =  SPY_EMP_NAME;
    };

    function AbilityCast()
    {
        if ( this.m_hAbilityOwner == null )
            return;

        local _d = this.m_hAbilityOwner.GetScriptScope();

        EmitSoundOn ( SFX_GENERIC_THROW, this.m_hAbilityOwner );

        SetPropFloat ( _d.m_hZombieWep, "m_flNextPrimaryAttack",   FLT_MAX );
        SetPropFloat ( _d.m_hZombieWep, "m_flNextSecondaryAttack", FLT_MAX );

        this.m_hAbilityOwner.GetActiveWeapon().AddAttribute( "move speed penalty", 0.5, -1 );

        EmitSoundOnClient ( "Weapon_GrenadeLauncher.DrumStop", m_hAbilityOwner );

        local _hPlayerVM = GetPropEntity( this.m_hAbilityOwner, "m_hViewModel" );

        _hPlayerVM.ResetSequence( _hPlayerVM.LookupSequence( "special" ) );

        this.m_hAbilityOwner.AddEventToQueue ( EVENT_ENGIE_THROW_NADE, INSTANT );
        this.m_hAbilityOwner.AddEventToQueue ( EVENT_ENGIE_EXIT_MINIROOT, ENGIE_EMP_MINIROOT_LEN );
        return;
    };

    function ThrowNadeProjectile()
    {
        if ( this.m_hAbilityOwner == null )
            return;

        local _d = this.m_hAbilityOwner.GetScriptScope();

        local _fPitch        =  RandomFloat( -360, 360 );
        local _fYaw          =  RandomFloat( -360, 360 );
        local _fRoll         =  RandomFloat( -360, 360 );

        local _iDist         =  ENGIE_EMP_THROW_DIST_FROM_EYES;
        local _iThrowForce   =  ENGIE_EMP_THROW_FORCE;

        local _vecPlayerVel  =  GetPropVector( m_hAbilityOwner, "m_vecVelocity" );

        local _vecFwd        =  m_hAbilityOwner.EyeAngles().Forward();
        local _vecThrow      =  ( ( _vecFwd * _iThrowForce ) + _vecPlayerVel );
        local _angPos        =  ( m_hAbilityOwner.EyePosition() + ( _vecFwd * _iDist ) );
        local _nadeEnt       =  Entities.CreateByClassname( "prop_physics_override" );

        SetPropFloat( _d.m_hZombieWep, "m_flNextPrimaryAttack", FLT_MAX );

        _nadeEnt.SetModel  ( MDL_WORLD_MODEL_ENGIE_NADE );
        _nadeEnt.SetOrigin ( _angPos );

        _nadeEnt.SetModelScale ( 1.4, 0.0 ); // todo - const
        _nadeEnt.SetSize       ( ( _nadeEnt.GetBoundingMins() * 1 ),
                                 ( _nadeEnt.GetBoundingMaxs() * 1 ) ); // todo - const

        SetPropInt      ( _nadeEnt, "m_CollisionGroup", COLLISION_GROUP_PROJECTILE );
        SetPropVector   ( _nadeEnt, "m_vInitialVelocity ", _vecThrow );
        SetPropInt      ( _nadeEnt, "m_takedamage", 1 );
        _nadeEnt.KeyValueFromString ( "targetname", "engie_nade_physprop" );

        _nadeEnt.DispatchSpawn();

        _nadeEnt.SetAngles           ( _fPitch, _fYaw, _fRoll );
        _nadeEnt.SetAngularVelocity  ( _fPitch, _fYaw, _fRoll );
        _nadeEnt.SetPhysVelocity     ( _vecThrow );

        _nadeEnt.ValidateScriptScope();

        local _sc = _nadeEnt.GetScriptScope();

        _sc.m_fTimeStart       <-  ( Time() ).tofloat();
        _sc.m_fNextFlashTime   <-  ( Time() + ENGIE_EMP_INITIAL_FLASH_RATE ).tofloat();
        _sc.m_fExplodeTime     <-  ( Time() + ENGIE_EMP_LIFETIME ).tofloat();

        _sc.m_fFlashRate   <-  ENGIE_EMP_INITIAL_FLASH_RATE;
        _sc.m_hOwner       <-  this.m_hAbilityOwner;
        _sc.m_bMustFizzle  <-  false;

        this.m_hAbilityOwner.ViewPunch( QAngle( -3, 0, 0 ) ); // todo - const

        this.m_hAbilityOwner.AddEventToQueue ( EVENT_PUT_ABILITY_ON_CD, 2 );
        AddThinkToEnt                        ( _nadeEnt, "EngieEMPThink" );
        return;
    };

    function ExitRoot()
    {
        this.m_hAbilityOwner.GetActiveWeapon().RemoveAttribute( "move speed penalty" );
        this.PutAbilityOnCooldown();
        return;
    };
};
// --------------------------------- //
//          SOLDIER ABILITY          //
// --------------------------------- //
class CSoldierJump extends CZombieAbility
{
    constructor( hAbilityOwner )
    {
        this.m_hAbilityOwner     =  hAbilityOwner;
        this.m_iAbilityType      =  ZABILITY_THROWABLE;
        this.m_fAbilityCooldown  =  MIN_TIME_BETWEEN_SOLDIER_POUNCE;
        this.m_szAbilityName     =  SOLDIER_POUNCE_NAME;
    };

    function AbilityCast()
    {
        if ( this.m_hAbilityOwner == null )
            return;

        local _sc = this.m_hAbilityOwner.GetScriptScope();

        EmitAmbientSoundOn( "Infection.SoldierPounce", 9, 1, 100, this.m_hAbilityOwner );

        DispatchParticleEffect( FX_SOLDIER_LIFTOFF, this.m_hAbilityOwner.GetOrigin(),
                                Vector( 0, 0, 0 ) );

        local _hPlayerVM    =   GetPropEntity( this.m_hAbilityOwner, "m_hViewModel" );
        local _iSpecialSeq  =  _hPlayerVM.LookupSequence( "special" );

        SetPropEntity( this.m_hAbilityOwner, "m_hGroundEntity", null );

        _hPlayerVM.ResetSequence        ( _iSpecialSeq );
        this.m_hAbilityOwner.AddCond    ( TF_COND_BLASTJUMPING );
        this.m_hAbilityOwner.RemoveFlag ( FL_ONGROUND );

        _sc.m_iFlags <- (_sc.m_iFlags | ZBIT_SOLDIER_IN_POUNCE );

        local _vecVelocity = this.m_hAbilityOwner.GetAbsVelocity();

        SetPropEntity( this.m_hAbilityOwner, "m_hGroundEntity", null );

        this.m_hAbilityOwner.ApplyAbsVelocityImpulse( this.m_hAbilityOwner.EyeAngles().Forward() +
                                                      _vecVelocity + Vector( 0, 0, 850 ) ); // todo - const

        this.m_hAbilityOwner.AddEventToQueue ( EVENT_PUT_ABILITY_ON_CD, INSTANT );
        return;
    };
};
// --------------------------------- //
//           MEDIC ABILITY           //
// --------------------------------- //
class CMedicHeal extends CZombieAbility
{
    constructor( hAbilityOwner )
    {
        this.m_hAbilityOwner     =  hAbilityOwner;
        this.m_iAbilityType      =  ZABILITY_EMITTER;
        this.m_fAbilityCooldown  =  MIN_TIME_BETWEEN_MEDIC_HEAL;
        this.m_szAbilityName     =  MEDIC_HEAL_NAME;
    };

    function AbilityCast()
    {
        if ( this.m_hAbilityOwner == null )
            return;

        local _d = this.m_hAbilityOwner.GetScriptScope();

        _d.m_hTempEntity <- SpawnEntityFromTable( "info_particle_system",
        {
            effect_name   =  FX_MEDIC_HEAL,
            start_active  =  "0",
            targetname    =  "ZombieSpy_Revealer_pfx",
            origin        =  this.m_hAbilityOwner.GetOrigin(),
        });

        if ( _d.m_hZombieFXWearable != null && _d.m_hZombieFXWearable.IsValid() )
            _d.m_hZombieFXWearable.Destroy();

        if ( _d.m_hZombieWearable != null && _d.m_hZombieWearable.IsValid() )
            _d.m_hZombieWearable.Destroy();

        this.m_hAbilityOwner.GiveZombieFXWearable();
        this.m_hAbilityOwner.GiveZombieCosmetics();

        this.m_hAbilityOwner.SetForcedTauntCam  ( 1 );
        this.m_hAbilityOwner.AddCustomAttribute ( "no_attack", 1, -1 );
        this.m_hAbilityOwner.AddEventToQueue    ( EVENT_KILL_TEMP_ENTITY, 2 ); // todo - const
        this.m_hAbilityOwner.AddEventToQueue    ( EVENT_PUT_ABILITY_ON_CD, INSTANT );
        this.m_hAbilityOwner.AddCondEx          ( TF_COND_INVULNERABLE_USER_BUFF, 1, this.m_hAbilityOwner );
        this.m_hAbilityOwner.AddCondEx          ( TF_COND_HALLOWEEN_QUICK_HEAL, 2, this.m_hAbilityOwner  );
        EmitSoundOn                             ( SFX_ZMEDIC_HEAL, this.m_hAbilityOwner );

        EntFireByHandle    ( _d.m_hTempEntity, "SetParent", "!activator", 0, this.m_hAbilityOwner, this.m_hAbilityOwner );
        EntFireByHandle    ( _d.m_hTempEntity, "Start", "", 0.2, null, null );
       // EmitSoundOnClient  ( "WeaponMedigun.HealingWorld", this.m_hAbilityOwner );

        local _hPlayer            = null;
        local _arrPlayersInRange  = [];

        // get all of the players in range
        while ( _hPlayer = Entities.FindByClassnameWithin( _hPlayer, "player", this.m_hAbilityOwner.GetOrigin(), MEDIC_HEAL_RANGE ) )
        {
            // blue (zombie) team only
            if ( _hPlayer != null && _hPlayer.GetTeam() == TF_TEAM_BLUE && _hPlayer != this.m_hAbilityOwner )
            {
                _arrPlayersInRange.append( _hPlayer );
            };
        };

        if ( _arrPlayersInRange.len() == 0 )
            return;

        // apply heal effect
        for ( local i = 0; i < _arrPlayersInRange.len(); i++ )
        {
            local _hNextPlayer   =  _arrPlayersInRange[ i ];
            local _angPlayer     =  _hNextPlayer.GetLocalAngles();
            local _vecAngPlayer  =  Vector( _angPlayer.x, _angPlayer.y, _angPlayer.z );

            if ( _hNextPlayer == null || _hNextPlayer == this.m_hAbilityOwner )
                break;

            local _scNext = _hNextPlayer.GetScriptScope();

            _hNextPlayer.SpawnEffect();

            _hNextPlayer.AddCondEx ( TF_COND_INVULNERABLE_USER_BUFF, 1, this.m_hAbilityOwner );
            _hNextPlayer.AddCondEx ( TF_COND_HALLOWEEN_QUICK_HEAL,   2, this.m_hAbilityOwner );
        };

        return;
    };

};
// --------------------------------- //
//          SNIPER ABILITY           //
// --------------------------------- //
class CSniperSpitball extends CZombieAbility
{
    constructor( hAbilityOwner )
    {
        this.m_hAbilityOwner     =  hAbilityOwner;
        this.m_iAbilityType      =  ZABILITY_PROJECTILE;
        this.m_fAbilityCooldown  =  MIN_TIME_BETWEEN_ENGIE_EMP_THROW;
        this.m_szAbilityName     =  SNIPER_SPIT_NAME;
    };

    function AbilityCast()
    {
        if ( this.m_hAbilityOwner == null )
            return;

        local _d = this.m_hAbilityOwner.GetScriptScope();

        if ( ( _d.m_iFlags & ZBIT_SNIPER_CHARGING_SPIT ) != 0 )
            return;

        this.m_hAbilityOwner.AddEventToQueue( EVENT_SNIPER_SPITBALL, MIN_TIME_BETWEEN_SPIT_START_END );

        _d.m_fTimeAbilityCastStarted <- Time();

        _d.m_iFlags = ( _d.m_iFlags | ZBIT_SNIPER_CHARGING_SPIT );
        EmitSoundOn   ( SFX_ZOMBIE_SPIT_START, m_hAbilityOwner );

        local _hSlowWep = this.m_hAbilityOwner.GetActiveWeapon();

        if ( _hSlowWep != null )
            _hSlowWep.AddAttribute( "move speed penalty", SNIPER_SPIT_CHARGE_SLOW,
                                    SNIPER_SPIT_MAX_CHANNEL_TIME + 1.0 );

        _d.m_hSpitSlowWep <- _hSlowWep;

        local _hPlayerVM = GetPropEntity( this.m_hAbilityOwner, "m_hViewModel" );

        if ( _hPlayerVM != null )
        {
            _hPlayerVM.ResetSequence( _hPlayerVM.LookupSequence( "special" ) );
            SetPropFloat( _hPlayerVM, "m_flPlaybackRate", 1.0 );
        };

        _d.m_fSpitVMReleaseTime <- 0.0;
        return;
    };

    function CreateSpitball( _bPlayerDead = false )
    {
        if ( this.m_hAbilityOwner == null )
            return;

        local _d = this.m_hAbilityOwner.GetScriptScope();

        this.m_hAbilityOwner.EndSpitCharge();

        local _hPlayerVM = GetPropEntity( this.m_hAbilityOwner, "m_hViewModel" );

        if ( _bPlayerDead )
        {
            if ( _hPlayerVM != null )
                SetPropFloat( _hPlayerVM, "m_flPlaybackRate", 1.0 );

            _d.m_fSpitVMReleaseTime <- 0.0;
        }
        else
        {
            _d.m_fSpitVMReleaseTime <- Time();
        };

        // if the player is dead when the spitball is thrown, drop straight down
        local _iThrowForce   =  SNIPER_SPIT_THROW_FORCE;
        local _iDist         =  SNIPER_SPIT_THROW_DIST;
        local _vecPlayerVel  =  GetPropVector( this.m_hAbilityOwner, "m_vecVelocity" );

        local _vecFwd    =  this.m_hAbilityOwner.EyeAngles().Forward();
        local _vecThrow  =  ( ( _vecFwd * _iThrowForce ) + _vecPlayerVel );

        local _angPos    =  ( this.m_hAbilityOwner.EyePosition() + ( _vecFwd * _iDist ) );
        local _spitEnt   =  Entities.CreateByClassname( "prop_physics_override" );

        if ( _bPlayerDead )
        {
            _vecThrow = Vector( 0, 0, -100 );
        }

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
        _spitEnt.SetPhysVelocity ( _vecThrow );

        SetPropInt( _spitEnt, "m_nRenderMode", kRenderTransColor );
        SetPropInt( _spitEnt, "m_clrRender", 0 );

        _spitEnt.ValidateScriptScope();

        local _sc = _spitEnt.GetScriptScope();

        _sc.m_hOwner        <-   this.m_hAbilityOwner;
        _sc.m_iState        <-   SPIT_STATE_IN_TRANSIT;
        _sc.m_hPfx          <-   _hPfxEnt;
        _sc.m_bDealtPopDmg  <-   false;
        _sc.m_bHasHitSolid  <-   false;

        _sc.m_fTimeStart    <-   ( Time() ).tofloat();
        _sc.m_flKillMeTime  <-   ( Time() + SNIPER_SPIT_LIFETIME ).tofloat();

        _sc.m_iDistanceToGround  <- 0;
        _sc.m_vecHitPosition     <- Vector( 0, 0, 0 );
        _sc.m_vecPlaneNormal     <- Vector( 0, 0, 0 );
        _sc.m_vecSpitZone        <- Vector( 0, 0, 0 );
        _sc.m_tblSplat           <- null;  // puddle cells, filled at landing

        EmitSoundOn( SFX_ZOMBIE_SPIT_END, m_hAbilityOwner );

        this.PutAbilityOnCooldown();

        AddThinkToEnt( _spitEnt, "SniperSpitThink" );
        return;
    };
};

// --------------------------------- //
//      ENGINEER ABILITY (BEACON)    //
// --------------------------------- //
class CEngineerBeacon extends CZombieAbility
{
    constructor( hAbilityOwner )
    {
        this.m_hAbilityOwner     =  hAbilityOwner;
        this.m_iAbilityType      =  ZABILITY_THROWABLE;
        this.m_fAbilityCooldown  =  MIN_TIME_BETWEEN_ENGIE_BEACON;
        this.m_szAbilityName     =  ENGIE_BEACON_NAME;
    };

    function AbilityCast()
    {
        if ( this.m_hAbilityOwner == null )
            return;

        local _d = this.m_hAbilityOwner.GetScriptScope();

        EmitSoundOn ( SFX_GENERIC_THROW, this.m_hAbilityOwner );

        // one beacon per engineer
        this.DestroyOwnedBeacon();

        SetPropFloat ( _d.m_hZombieWep, "m_flNextPrimaryAttack",   FLT_MAX );
        SetPropFloat ( _d.m_hZombieWep, "m_flNextSecondaryAttack", FLT_MAX );

        this.m_hAbilityOwner.GetActiveWeapon().AddAttribute( "move speed penalty", 0.5, -1 );

        EmitSoundOnClient ( "Weapon_GrenadeLauncher.DrumStop", m_hAbilityOwner );

        this.m_hAbilityOwner.AddEventToQueue ( EVENT_ENGIE_THROW_BEACON,     INSTANT );
        this.m_hAbilityOwner.AddEventToQueue ( EVENT_ENGIE_BEACON_EXIT_ROOT, ENGIE_BEACON_MINIROOT_LEN );
        return;
    };

    function ThrowBeaconProjectile()
    {
        if ( this.m_hAbilityOwner == null )
            return;

        local _d = this.m_hAbilityOwner.GetScriptScope();

        local _hPlayerVM     =  GetPropEntity( this.m_hAbilityOwner, "m_hViewModel" );

        local _fPitch        =  RandomFloat( -360, 360 );
        local _fYaw          =  RandomFloat( -360, 360 );
        local _fRoll         =  RandomFloat( -360, 360 );

        local _iDist         =  ENGIE_BEACON_THROW_DIST_FROM_EYES;
        local _iThrowForce   =  ENGIE_BEACON_THROW_FORCE;

        local _vecPlayerVel  =  GetPropVector( m_hAbilityOwner, "m_vecVelocity" );

        local _vecFwd        =  m_hAbilityOwner.EyeAngles().Forward();
        local _vecThrow      =  ( ( _vecFwd * _iThrowForce ) + _vecPlayerVel );
        local _angPos        =  ( m_hAbilityOwner.EyePosition() + ( _vecFwd * _iDist ) );
        local _beaconEnt     =  Entities.CreateByClassname( "prop_physics_override" );

        SetPropFloat( _d.m_hZombieWep, "m_flNextPrimaryAttack", FLT_MAX );

        _beaconEnt.SetModel  ( MDL_WORLD_MODEL_ENGIE_NADE );
        _beaconEnt.SetOrigin ( _angPos );

        _beaconEnt.SetModelScale ( 1.4, 0.0 );
        _beaconEnt.SetSize       ( _beaconEnt.GetBoundingMins(),
                                   _beaconEnt.GetBoundingMaxs() );

        SetPropInt      ( _beaconEnt, "m_CollisionGroup", COLLISION_GROUP_PROJECTILE );
        SetPropVector   ( _beaconEnt, "m_vInitialVelocity ", _vecThrow );
        SetPropInt      ( _beaconEnt, "m_takedamage", 1 );
        _beaconEnt.KeyValueFromString ( "targetname", "engie_beacon_physprop" );

        _beaconEnt.DispatchSpawn();

        SetPropInt ( _beaconEnt, "m_fEffects", EF_NODRAW );

        // toolbox visual rides the physics shell
        local _hVisual = Entities.CreateByClassname( "prop_dynamic_override" );

        _hVisual.SetModel  ( MDL_ENGIE_BEACON_TOOLBOX );
        _hVisual.SetOrigin ( _angPos );

        _hVisual.KeyValueFromString ( "targetname", "engie_beacon_fx" );
        _hVisual.KeyValueFromString ( "solid", "0" );

        _hVisual.DispatchSpawn();

        SetPropInt ( _hVisual, "m_nSkin", ENGIE_BEACON_SKIN );

        EntFireByHandle ( _hVisual, "SetParent", "!activator", 0, _beaconEnt, _beaconEnt );

        _beaconEnt.SetAngles           ( _fPitch, _fYaw, _fRoll );
        _beaconEnt.SetAngularVelocity  ( _fPitch, _fYaw, _fRoll );
        _beaconEnt.SetPhysVelocity     ( _vecThrow );

        _beaconEnt.ValidateScriptScope();

        local _sc = _beaconEnt.GetScriptScope();

        _sc.m_fTimeStart    <-  ( Time() ).tofloat();
        _sc.m_fBuiltTime    <-  0.0;
        _sc.m_flKillMeTime  <-  ( Time() + ENGIE_BEACON_LIFETIME ).tofloat();
        _sc.m_flDestroyTime <-  0.0; // armed by the first invalid contact
        _sc.m_vecTraceFrom  <-  Vector( _angPos.x, _angPos.y, _angPos.z ); // playerclip sweep
        _sc.m_hOwner        <-  this.m_hAbilityOwner;
        _sc.m_iHealth       <-  ENGIE_BEACON_HEALTH;
        _sc.m_bSettled      <-  false;
        _sc.m_bBuilt        <-  false;
        _sc.m_bMustDie      <-  false;
        _sc.m_hVisual       <-  _hVisual;
        _sc.m_hRespawnRoom  <-  null;
        _sc.m_hBeaconFX     <-  null;

        // track the live beacon for the next throw
        _d.m_hOwnedBeacon <- _beaconEnt;

        this.m_hAbilityOwner.ViewPunch( QAngle( -3, 0, 0 ) );

        local _iSpecialSeq = _hPlayerVM.LookupSequence( "special" );
        _hPlayerVM.ResetSequence ( _iSpecialSeq );

        AddThinkToEnt ( _beaconEnt, "BeaconThink" );
        return;
    };

    function ExitRoot()
    {
        this.m_hAbilityOwner.GetActiveWeapon().RemoveAttribute( "move speed penalty" );
        this.PutAbilityOnCooldown();
        return;
    };

    // blow up the previous beacon when a new one is thrown
    function DestroyOwnedBeacon()
    {
        if ( this.m_hAbilityOwner == null )
            return;

        local _d = this.m_hAbilityOwner.GetScriptScope();

        if ( ( "m_hOwnedBeacon" in _d ) &&
             _d.m_hOwnedBeacon != null && _d.m_hOwnedBeacon.IsValid() )
        {
            _d.m_hOwnedBeacon.GetScriptScope().m_bMustDie <- true;
        };

        _d.m_hOwnedBeacon <- null;
        return;
    };
};

// --------------------------------- //
//           DEMO ABILITY            //
// --------------------------------- //
class CDemoCharge extends CZombieAbility
{
    constructor( hAbilityOwner )
    {
        this.m_hAbilityOwner     =  hAbilityOwner;
        this.m_iAbilityType      =  ZABILITY_THROWABLE;
        this.m_fAbilityCooldown  =  MIN_TIME_BETWEEN_DEMO_CHARGE;
        this.m_szAbilityName     =  DEMO_CHARGE_NAME;
    };

    function AbilityCast()
    {
        if ( this.m_hAbilityOwner == null )
            return;

        local _d = this.m_hAbilityOwner.GetScriptScope();

        this.m_hAbilityOwner.SetForcedTauntCam( 1 );

        SetPropFloat ( _d.m_hZombieWep, "m_flNextPrimaryAttack",   FLT_MAX );
        SetPropFloat ( _d.m_hZombieWep, "m_flNextSecondaryAttack", FLT_MAX );

        if ( _d.m_hZombieFXWearable != null && _d.m_hZombieFXWearable.IsValid() )
            _d.m_hZombieFXWearable.Destroy();

        if ( _d.m_hZombieWearable != null && _d.m_hZombieWearable.IsValid() )
            _d.m_hZombieWearable.Destroy();

        // create new ones now that the player can see themselves
        this.m_hAbilityOwner.GiveZombieFXWearable();
        this.m_hAbilityOwner.GiveZombieCosmetics();

        EmitSoundOn( SFX_DEMO_CHARGE_RAMP, this.m_hAbilityOwner );

        // todo - array
        this.m_hAbilityOwner.AddCond   ( TF_COND_CRITBOOSTED_PUMPKIN );
        this.m_hAbilityOwner.AddCond   ( TF_COND_TAUNTING );
        this.m_hAbilityOwner.AddCondEx ( TF_COND_INVULNERABLE_USER_BUFF, 1.76, this.m_hAbilityOwner );
        this.m_hAbilityOwner.AddCond   ( TF_COND_RADIUSHEAL ); // just the heal ring

        this.m_hAbilityOwner.RemoveOutOfCombat ( true );

        this.m_hAbilityOwner.AddCustomAttribute ( "no_jump", 1, -1 );
        this.m_hAbilityOwner.AddCustomAttribute ( "no_duck", 1, -1 );
        this.m_hAbilityOwner.AddCustomAttribute ( "no_attack", 1, -1 );
        this.m_hAbilityOwner.AddCustomAttribute ( "move speed penalty", 0.001, -1 );

        this.m_hAbilityOwner.AddEventToQueue   ( EVENT_DEMO_CHARGE_START, 1.75 );

        _d.m_iFlags <- ( _d.m_iFlags | ZBIT_DEMOCHARGE );

        this.m_hAbilityOwner.SetSpawnBodyHidden ( true );
        this.m_hAbilityOwner.CreateSpawnBody    ( DEMO_CHARGE_WINDUP_SEQUENCE,
                                                  arrDemoChargeWindupFallbackSeqs,
                                                  DEMO_CHARGE_WINDUP_RATE, true );
        return;
    };

    function StartDemoCharge()
    {
        if ( this.m_hAbilityOwner == null )
            return;

        local _sc = this.m_hAbilityOwner.GetScriptScope();

        EmitAmbientSoundOn ( "Infection.DemoCharge", 10, 1, 100, this.m_hAbilityOwner );

        _sc.m_iFlags  <- ( _sc.m_iFlags | ZBIT_MUST_EXPLODE );

        this.m_hAbilityOwner.AddCond    ( TF_COND_SHIELD_CHARGE );
        this.m_hAbilityOwner.RemoveCond ( TF_COND_RADIUSHEAL );
        this.m_hAbilityOwner.AddCondEx  ( TF_COND_INVULNERABLE_USER_BUFF, 0.298, this.m_hAbilityOwner );
        this.m_hAbilityOwner.AddEventToQueue   ( EVENT_DEMO_CHARGE_EXIT, 1.5 );

        this.m_hAbilityOwner.RemoveCustomAttribute ( "no_jump" );
        this.m_hAbilityOwner.RemoveCustomAttribute ( "no_duck" );
        this.m_hAbilityOwner.RemoveCustomAttribute ( "no_attack" );
        this.m_hAbilityOwner.RemoveCustomAttribute ( "move speed penalty" );

        this.m_hAbilityOwner.DestroySpawnBody   ();
        this.m_hAbilityOwner.SetSpawnBodyHidden ( false );

        this.m_hAbilityOwner.RemoveCond ( TF_COND_TAUNTING );
        return;
    };

    function ExitDemoCharge()
    {
        if ( this.m_hAbilityOwner == null )
            return;

        local _d = this.m_hAbilityOwner.GetScriptScope();

        this.m_hAbilityOwner.DestroySpawnBody   ();
        this.m_hAbilityOwner.SetSpawnBodyHidden ( false );

        this.m_hAbilityOwner.RemoveCond  ( TF_COND_SHIELD_CHARGE );
        this.m_hAbilityOwner.RemoveCond  ( TF_COND_INVULNERABLE_USER_BUFF );
        this.m_hAbilityOwner.RemoveCond  ( TF_COND_TAUNTING );

        this.PutAbilityOnCooldown();

        _d.m_iFlags            <- ( _d.m_iFlags & ~ZBIT_MUST_EXPLODE );
        _d.m_iFlags            <- ( _d.m_iFlags & ~ZBIT_DEMOCHARGE );
        _d.m_tblEventQueue     <- { };

        DemomanExplosionPreCheck( this.m_hAbilityOwner.GetOrigin(),
                                  DEMOMAN_CHARGE_DAMAGE,
                                  DEMOMAN_CHARGE_RADIUS,
                                  this.m_hAbilityOwner );

        this.m_hAbilityOwner.AddEventToQueue( EVENT_DEMO_CHARGE_RESET, 0.1 );
        return;
    };
};

class CPassiveAbility extends CZombieAbility
{
    function AbilityCast()
    {
        return;
    };

    // ------------------------------------------------------------------- //
    // passive abilities are now handled through zombie attrib/cond system //
    // this is still here because it's used for name/desc                  //
    // todo - remove this                                                  //
    // ------------------------------------------------------------------- //
    function ApplyPassive()
    {
        return;
    };

    function StripPassive()
    {
        return;
    };
};

class CPyroPassive extends CPassiveAbility
{
    constructor( hAbilityOwner )
    {
        this.m_hAbilityOwner     =  hAbilityOwner;
        this.m_iAbilityType      =  ZABILITY_PASSIVE;
        this.m_fAbilityCooldown  =  ACT_LOCKED;
        this.m_szAbilityName     =  PYRO_BLAST_NAME;
     // this.m_arrAttribs        =  PYRO_PASSIVE_ATTRIBUTES;
     // this.m_arrTFConds        =  PYRO_PASSIVE_CONDS;
    };
};

// heavy passive stats live in the weapon attribs + damage hook, not here
class CHeavyPassive extends CPassiveAbility
{
    constructor( hAbilityOwner )
    {
        this.m_hAbilityOwner     =  hAbilityOwner;
        this.m_iAbilityType      =  ZABILITY_PASSIVE;
        this.m_fAbilityCooldown  =  ACT_LOCKED;
        this.m_szAbilityName     =  HEAVY_PASSIVE_NAME;
     // this.m_arrAttribs        =  HEAVY_PASSIVE_ATTRIBUTES;
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
     // this.m_arrAttribs        =  SCOUT_PASSIVE_ATTRIBUTES;
     // this.m_arrTFConds        =  SCOUT_PASSIVE_CONDS;
    };
};

class CMedicPassive extends CPassiveAbility
{
    constructor( hAbilityOwner )
    {
        this.m_hAbilityOwner     =  hAbilityOwner;
        this.m_iAbilityType      =  ZABILITY_PASSIVE;
        this.m_fAbilityCooldown  =  ACT_LOCKED;
        this.m_szAbilityName     =  MEDIC_PASSIVE_NAME;
     // this.m_arrAttribs        =  SCOUT_PASSIVE_ATTRIBUTES;
     // this.m_arrTFConds        =  SCOUT_PASSIVE_CONDS;
    };
};

class CPyroSpew extends CZombieAbility
{
    constructor( hAbilityOwner )
    {
        this.m_hAbilityOwner     =  hAbilityOwner;
        this.m_iAbilityType      =  ZABILITY_THROWABLE;
        this.m_fAbilityCooldown  =  MIN_TIME_BETWEEN_PYRO_SPEW;
        this.m_szAbilityName     =  PYRO_SPEW_NAME;
    };

    function AbilityCast()
    {
        if ( this.m_hAbilityOwner == null )
            return;

        local _d         = this.m_hAbilityOwner.GetScriptScope();
        local _hPlayerVM = GetPropEntity( this.m_hAbilityOwner, "m_hViewModel" );

        _hPlayerVM.ResetSequence( _hPlayerVM.LookupSequence( "special" ) );

        EmitSoundOn( SFX_PYRO_SPEW_CAST, this.m_hAbilityOwner );

        // rapid-fire burst - first blob now, the rest re-queue themselves
        _d.m_iSpewBlobsLeft <- PYRO_SPEW_BURST_COUNT;

        this.m_hAbilityOwner.AddEventToQueue ( EVENT_PUT_ABILITY_ON_CD, INSTANT );

        this.ThrowSpewBlob();
        return;
    };

    function ThrowSpewBlob()
    {
        if ( this.m_hAbilityOwner == null )
            return;

        local _vecFwd        =  this.m_hAbilityOwner.EyeAngles().Forward();
        local _vecPlayerVel  =  GetPropVector( this.m_hAbilityOwner, "m_vecVelocity" );
        local _vecThrow      =  ( ( _vecFwd * PYRO_SPEW_THROW_FORCE ) + _vecPlayerVel );
        local _vecPos        =  ( this.m_hAbilityOwner.EyePosition() + ( _vecFwd * 32 ) );

        // horizontal aim - seeds the splat cone direction
        local _vecAimHz      =  Vector( _vecFwd.x, _vecFwd.y, 0.0 );

        if ( _vecAimHz.Length() < 0.001 )
            _vecAimHz = Vector( 1, 0, 0 );

        local _flAimLen      =  _vecAimHz.Length();

        _vecAimHz = Vector( ( _vecAimHz.x / _flAimLen ), ( _vecAimHz.y / _flAimLen ), 0.0 );

        EmitSoundEx(
        {
            sound_name  =  ARR_SFX_SPEW_SPIT_WAVS[ RandomInt( 0, ARR_SFX_SPEW_SPIT_WAVS.len() - 1 ) ],
            entity      =  this.m_hAbilityOwner,
            pitch       =  PYRO_SPEW_SPIT_PITCH,
        } );

        local _hGlobEnt      =  Entities.CreateByClassname( "prop_physics_override" );

        _hGlobEnt.SetModel  ( MDL_WORLD_MODEL_ENGIE_NADE );
        _hGlobEnt.SetOrigin ( _vecPos );

        SetPropInt ( _hGlobEnt, "m_nRenderMode", kRenderTransColor );
        SetPropInt ( _hGlobEnt, "m_clrRender", 0 );
        SetPropInt ( _hGlobEnt, "m_CollisionGroup", COLLISION_GROUP_DEBRIS );

        local _hPfxEnt = SpawnEntityFromTable( "info_particle_system",
        {
            effect_name  = FX_SPEW_TRAIL,
            start_active = "1",
            origin       = _vecPos
        } );

        EntFireByHandle( _hPfxEnt, "SetParent", "!activator", 0, _hGlobEnt, _hGlobEnt );

        _hGlobEnt.DispatchSpawn   ();
        _hGlobEnt.SetPhysVelocity ( _vecThrow );

        _hGlobEnt.ValidateScriptScope();

        local _sc = _hGlobEnt.GetScriptScope();

        _sc.m_hOwner            <-  this.m_hAbilityOwner;
        _sc.m_hPfx              <-  _hPfxEnt;
        _sc.m_iState            <-  PYRO_SPEW_STATE_IN_TRANSIT;
        _sc.m_flKillMeTime      <-  ( Time() + PYRO_SPEW_GLOB_LIFETIME ).tofloat();
        _sc.m_fZoneEndTime      <-  0.0;
        _sc.m_vecHitPosition    <-  Vector( 0, 0, 0 );
        _sc.m_iDistanceToGround <-  0;
        _sc.m_vecSpewDir         <-  _vecAimHz;
        _sc.m_tblSplat          <-  null;

        AddThinkToEnt( _hGlobEnt, "PyroSpewGlobThink" );

        local _d = this.m_hAbilityOwner.GetScriptScope();

        _d.m_iSpewBlobsLeft <- ( _d.m_iSpewBlobsLeft - 1 );

        if ( _d.m_iSpewBlobsLeft > 0 )
            this.m_hAbilityOwner.AddEventToQueue( EVENT_PYRO_SPEW_NEXT_BLOB,
                                                  PYRO_SPEW_BURST_INTERVAL );

        return;
    };
}

class CHeavyRockThrow extends CZombieAbility
{
    constructor( hAbilityOwner )
    {
        this.m_hAbilityOwner     =  hAbilityOwner;
        this.m_iAbilityType      =  ZABILITY_THROWABLE;
        this.m_fAbilityCooldown  =  MIN_TIME_BETWEEN_HEAVY_ROCK;
        this.m_fSpawnCooldown    =  HEAVY_ROCK_SPAWN_COOLDOWN;
        this.m_szAbilityName     =  HEAVY_ROCK_NAME;
    };

    function AbilityCast()
    {
        if ( this.m_hAbilityOwner == null )
            return;

        local _d = this.m_hAbilityOwner.GetScriptScope();

        // no swinging mid-windup
        SetPropFloat ( _d.m_hZombieWep, "m_flNextPrimaryAttack",   FLT_MAX );
        SetPropFloat ( _d.m_hZombieWep, "m_flNextSecondaryAttack", FLT_MAX );

        this.PlayThrowWindup();

        this.m_hAbilityOwner.AddEventToQueue ( EVENT_HEAVY_THROW_ROCK,
                                               HEAVY_ROCK_THROW_DELAY );

        this.m_hAbilityOwner.AddEventToQueue ( EVENT_HEAVY_END_THROW,
                                               HEAVY_ROCK_THROW_ANIM_TIME );
        return;
    };

    function PlayThrowWindup()
    {
        local _d = this.m_hAbilityOwner.GetScriptScope();

        _d.m_iFlags <- ( _d.m_iFlags | ZBIT_HEAVY_ROCK_WINDUP );

        this.m_hAbilityOwner.SetForcedTauntCam ( 1 );
        this.m_hAbilityOwner.LockInPlace       ( true );

        EmitSoundOn ( SFX_HEAVY_GRAB, this.m_hAbilityOwner );

        this.m_hAbilityOwner.SetSpawnBodyHidden ( true );
        this.m_hAbilityOwner.CreateSpawnBody    ( HEAVY_ROCK_WINDUP_SEQUENCE,
                                                  arrHeavyRockWindupFallbackSeqs,
                                                  HEAVY_ROCK_WINDUP_RATE, true, "",
                                                  SPAWN_BODY_SKIN_PLAIN,
                                                  HEAVY_ROCK_WINDUP_BODYGROUP );
        return;
    };

    function EndThrowWindup()
    {
        local _d = this.m_hAbilityOwner.GetScriptScope();

        _d.m_iFlags <- ( _d.m_iFlags & ~ZBIT_HEAVY_ROCK_WINDUP );

        this.m_hAbilityOwner.DestroySpawnBody   ();
        this.m_hAbilityOwner.SetSpawnBodyHidden ( false );

        this.m_hAbilityOwner.SetForcedTauntCam ( 0 );
        this.m_hAbilityOwner.RemoveCond        ( TF_COND_TAUNTING );
        this.m_hAbilityOwner.LockInPlace       ( false );

        if ( _d.m_iFlags & ZBIT_ZOMBIE )
            this.m_hAbilityOwner.AddZombieAttribs();

        return;
    };

    function ThrowRockProjectile()
    {
        if ( this.m_hAbilityOwner == null )
            return;

        EmitSoundOn ( SFX_HEAVY_THROW, this.m_hAbilityOwner );

        local _vecFwd        =  this.m_hAbilityOwner.EyeAngles().Forward();
        local _vecPlayerVel  =  GetPropVector( this.m_hAbilityOwner, "m_vecVelocity" );

        local _vecThrow      =  ( ( _vecFwd * HEAVY_ROCK_THROW_FORCE ) +
                                  Vector( 0, 0, HEAVY_ROCK_THROW_LIFT ) + _vecPlayerVel );

        local _vecPos        =  ( this.m_hAbilityOwner.EyePosition() +
                                  ( _vecFwd * HEAVY_ROCK_THROW_DIST ) +
                                  Vector( 0, 0, HEAVY_ROCK_THROW_Z_OFFSET ) );

        local _fPitch  =  RandomFloat( -360, 360 );
        local _fYaw    =  RandomFloat( -360, 360 );
        local _fRoll   =  RandomFloat( -360, 360 );

        local _hRockEnt = Entities.CreateByClassname( "prop_physics_override" );

        _hRockEnt.SetModel  ( MDL_WORLD_MODEL_ENGIE_NADE );
        _hRockEnt.SetOrigin ( _vecPos );

        _hRockEnt.SetModelScale ( 1.4, 0.0 ); // match the emp nade's physics exactly
        _hRockEnt.SetSize       ( _hRockEnt.GetBoundingMins(),
                                  _hRockEnt.GetBoundingMaxs() );

        SetPropInt    ( _hRockEnt, "m_CollisionGroup", COLLISION_GROUP_PROJECTILE );
        SetPropVector ( _hRockEnt, "m_vInitialVelocity ", _vecThrow );

        _hRockEnt.KeyValueFromString ( "targetname", HEAVY_ROCK_ENT_NAME );

        _hRockEnt.DispatchSpawn();

        SetPropInt ( _hRockEnt, "m_fEffects", EF_NODRAW );

        local _hVisual = Entities.CreateByClassname( "prop_dynamic_override" );

        _hVisual.SetModel  ( MDL_HEAVY_ROCK );
        _hVisual.SetOrigin ( _vecPos );

        _hVisual.KeyValueFromString ( "targetname", HEAVY_ROCK_FX_NAME );
        _hVisual.KeyValueFromString ( "solid", "0" );

        _hVisual.DispatchSpawn();
        _hVisual.SetModelScale ( HEAVY_ROCK_MODEL_SCALE, 0.0 );

        EntFireByHandle ( _hVisual, "SetParent", "!activator", 0, _hRockEnt, _hRockEnt );

        _hRockEnt.SetAngles          ( _fPitch, _fYaw, _fRoll );
        _hRockEnt.SetAngularVelocity ( _fPitch, _fYaw, _fRoll );
        _hRockEnt.SetPhysVelocity    ( _vecThrow );

        _hRockEnt.ValidateScriptScope();

        local _sc = _hRockEnt.GetScriptScope();

        _sc.m_hOwner        <-  this.m_hAbilityOwner;
        _sc.m_hVisual       <-  _hVisual;
        _sc.m_flKillMeTime  <-  ( Time() + HEAVY_ROCK_LIFETIME ).tofloat();
        _sc.m_vecLastPos    <-  Vector( _vecPos.x, _vecPos.y, _vecPos.z ); // flight trail
        _sc.m_vecTraceFrom  <-  Vector( _vecPos.x, _vecPos.y, _vecPos.z ); // swept collision

        AddThinkToEnt( _hRockEnt, "HeavyRockThink" );

        // release point and the throw vector it left on
        if ( DEBUG_MODE && bHeavyRockDebug )
        {
            DebugDrawBox  ( _vecPos, Vector( -4, -4, -4 ), Vector( 4, 4, 4 ),
                            0, 255, 255, 200, HEAVY_ROCK_DBG_IMPACT_TIME );
            DebugDrawLine ( _vecPos, ( _vecPos + _vecThrow * 0.15 ),
                            0, 255, 255, true, HEAVY_ROCK_DBG_IMPACT_TIME );
            DebugDrawText ( _vecPos, "THROW", false, HEAVY_ROCK_DBG_IMPACT_TIME );
        };

        this.m_hAbilityOwner.AddEventToQueue ( EVENT_PUT_ABILITY_ON_CD, INSTANT );
        return;
    };
}