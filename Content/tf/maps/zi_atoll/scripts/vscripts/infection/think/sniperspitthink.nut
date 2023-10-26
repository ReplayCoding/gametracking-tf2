// --------------------------------------------------------------------------------------- //
// Infection - Version 1.0  - Last Edited: 01/09/2023                                      //
// --------------------------------------------------------------------------------------- //
// All Code By: Harry Colquhoun (https://steamcommunity.com/profiles/76561198025795825)    //
// Assets/Game Design by: Diva Dan (https://steamcommunity.com/profiles/76561198072146551) //
// --------------------------------------------------------------------------------------- //
// sniper spit think script                                                                //
// --------------------------------------------------------------------------------------- //

::SniperSpitThink <- function()
{
    // flying through the air
    if ( m_iState == SPIT_STATE_IN_TRANSIT )
    {
        // tracehull to check if we hit the world
        local _tblTrace =
        {
            start   = self.GetOrigin(),
            end     = self.GetOrigin(),
            hullmin = Vector( -12, -12, -12 ),
            hullmax = Vector( 12, 12, 12 ),
            filter  = self,
        };

        if ( _Debug > 2 )
        {
            DebugDrawBox( self.GetOrigin(), Vector( -12, -12, -12 ), Vector( 12, 12, 12 ), 0, 255, 0, 0, 5.0 )
        };

        TraceHull( _tblTrace );

        if ( "hit" in _tblTrace && "enthit" in _tblTrace )
        {
            // can't hit ourself
            if ( _tblTrace.enthit == m_hOwner )
                return SNIPER_SPIT_RETHINK_TIME;

            // handle hitting objects that aren't the world
            if ( _tblTrace.enthit.GetClassname() != "worldspawn" )
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
                    SetPropInt( m_hOwner.GetActiveWeapon(), "m_AttributeManager.m_Item.m_iItemDefinitionIndex", 1152 );
                    _tblTrace.enthit.TakeDamage( SNIPER_SPIT_POP_DAMAGE, DMG_BURN, m_hOwner );
                    SetPropInt( m_hOwner.GetActiveWeapon(), "m_AttributeManager.m_Item.m_iItemDefinitionIndex", 30758 );

                    // if the player is standing on the ground
                    if ( _tblTrace.enthit.GetFlags() & FL_ONGROUND )
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
            else if ( _tblTrace.enthit.GetClassname() == "worldspawn" )
            {
                // we hit the world, store pos and seek ground
                m_iDistanceToGround <- SNIPER_SPIT_HIT_WORLD_Z_DIST;
                m_vecHitPosition    <- _tblTrace.pos;
                m_bHasHitSolid      <- true;
                m_iState            <- SPIT_STATE_FINDING_GROUND;

                return SNIPER_SPIT_RETHINK_TIME;
            };
        };

        // hit nothing, still in transit
        return SNIPER_SPIT_RETHINK_TIME;
    }
    else if ( m_iState == SPIT_STATE_FINDING_GROUND )
    {
        EmitSoundOn( SFX_SPIT_POP, self );

        local _flSafezone  =   SNIPER_SPIT_HITBOX_SIZE; // hu - size of spitball hitbox
        local _vecVel      =   self.GetVelocity();
        local _flSafeX     =   ( _vecVel.x * _flSafezone );
        local _flSafeY     =   ( _vecVel.y * _flSafezone );
        local _start       =   m_vecHitPosition;

        _start.x += _flSafeX;
        _start.y += _flSafeY;

        local _iZDistToGround = m_iDistanceToGround;

        local _end = Vector( _start.x, _start.y, _start.z - _iZDistToGround );

        if ( _Debug > 2 )
        {
            DebugDrawLine( _start, _end, 0, 255, 0, true, 5.0 )
        };

        // traceline for finding the ground
        local _tblTraceLine = { start = _start, end = _end, ignore = self, };

        // find the ground position to use as our splatter zone
        if( TraceLineEx( _tblTraceLine ) && _tblTraceLine.hit )
        {
            m_vecSpitZone   <- _tblTraceLine.pos;
            m_vecSpitZone.z += 5; // add some z height so the splat isnt in the ground

            if ( _Debug > 2 )
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

                if( _Debug > 2 )
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

        Assert( _iNumChecks != 0 );

        // if the percent of hits that came back empty is lower than the failure threshold
        if ( ( ( _iTimesHitEmpty.tofloat() / _iNumChecks ) * 100.0 ) <= SNIPER_SPIT_MIN_SURFACE_PERCENT )
        {
            DispatchParticleEffect( "zombie_spit_impact_splat", m_vecSpitZone, Vector( 0, 0, 0 ) );
            DispatchParticleEffect( "zombie_spit_impact", m_vecSpitZone, Vector( 0, 0, 0 ) );

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

        local _iPlayerCount  =  0;
        local _arrPlayers    =  [ ];

        local _hNextPlayer        =  null;
        local _hNextTargetEntity  =  null;

        if ( _Debug > 1 ) { DebugDrawCircle( m_vecSpitZone, Vector( 255, 0, 0 ), 0, SPIT_ZONE_RADIUS, true, 1.0 ) };

        // process a table of entities that the spit zone should fire inputs on
        // for example, key "tf_pumpkin_bomb" has val "ignite" which will pop the pumpkin
        foreach( _szClass, _szInput in SNIPER_SPIT_ZONE_ENTS )
        {
            while ( _hNextTargetEntity = Entities.FindByClassnameWithin( _hNextTargetEntity,
                                                                         _szClass,
                                                                         m_vecSpitZone,
                                                                         SPIT_ZONE_RADIUS ) )
            {
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
                    SetPropInt( m_hOwner.GetActiveWeapon(), STRING_NETPROP_ITEMDEF, GRAPPLING_HOOK_IDX );
                    _hNextPlayer.TakeDamage( SNIPER_SPIT_POP_DAMAGE, DMG_BURN, m_hOwner );
                    SetPropInt( m_hOwner.GetActiveWeapon(), STRING_NETPROP_ITEMDEF, ZOMBIE_WEAPON_IDX[ TF_CLASS_SNIPER ] );

                    DispatchParticleEffect  ( FX_SPIT_HIT_PLAYER, _vecPlayerOrigin, Vector( 0, 0, 0 ) );
                    continue;
                };

                // swap the IDX of the player's weapon to grappling hook before dealing damage (for kill icon)
                SetPropInt( m_hOwner.GetActiveWeapon(), STRING_NETPROP_ITEMDEF, GRAPPLING_HOOK_IDX );
                _hNextPlayer.TakeDamage( SNIPER_SPIT_ZONE_DAMAGE, DMG_BURN, m_hOwner );
                SetPropInt( m_hOwner.GetActiveWeapon(), STRING_NETPROP_ITEMDEF, ZOMBIE_WEAPON_IDX[ TF_CLASS_SNIPER ] );

                DispatchParticleEffect( FX_SPIT_HIT_PLAYER, _vecPlayerOrigin, Vector( 0, 0, 0 ) );
            };
        };

        m_bDealtPopDmg <- true;
        return SNIPER_SPIT_ZONE_RETHINK_TIME;
    }
    else if ( m_iState == SPIT_STATE_REJECTED ) // spit couldn't deploy zone, burst harmlessly and die
    {
        DispatchParticleEffect( "zombie_spit_impact", self.GetOrigin(), Vector( 0, 0, 0 ) );

        EmitSoundOn( SFX_SPIT_MISS, self );
        m_hPfx.Destroy();
        self.Destroy();

        return FLT_MAX; // no rethink
    };
};
