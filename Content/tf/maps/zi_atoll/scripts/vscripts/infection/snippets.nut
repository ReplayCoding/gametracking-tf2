
// todo - mama mia
// ::MedicDispenserThink <- function()
// {
//     local playersInRange = [];
//     local _hPlayer = null;

//     while ( _hPlayer = Entities.FindByClassnameWithin( _hPlayer, "player", m_hOwner.GetOrigin(), MEDIC_HEAL_RANGE ) )
//     {
//         if ( _hPlayer != null && _hPlayer.GetTeam() == TF_TEAM_BLUE && _hPlayer != m_hOwner )
//         {
//             playersInRange.append( _hPlayer );
//             if ( m_arrHealTargets.find(_hPlayer) == -1 )
//             {
//                 m_arrHealTargets.append(_hPlayer);
//             }
//         }
//     }

//     local removedCount = 0;
//     foreach ( player in m_arrHealTargets )
//     {
//         if ( playersInRange.find( player ) == -1 )
//         {
//             m_arrHealTargets.remove( m_arrHealTargets.find( player ) );
//             removedCount++;
//         }
//     }

//     for ( local i = 0; i < m_arrHealTargets.len(); i++ )
//     {
//         local _hNextPlayer = m_arrHealTargets[ i ];
//         if ( _hNextPlayer == null || !_hNextPlayer.ValidateScriptScope() )
//         {
//             continue;
//         }

//         SetPropEntityArray( self, "\x22healing_array\x22", _hNextPlayer, i );
//     }

//     local _bLoopOver = false;
//     local j = 0;
//     while ( !_bLoopOver )
//     {
//         j++;
//         local _nextP = GetPropEntityArray( self, "\x22healing_array\x22", j );
//         if ( _nextP == null )
//         {
//             _bLoopOver = true;
//             continue;
//         }
//         if ( !(_nextP in m_arrHealTargets) || _nextP == null || !_nextP.ValidateScriptScope() )
//         {
//             SetPropEntityArray( self, "\x22healing_array\x22", null, j );
//         }
//     }

//     return 1;
// };


// ::PDLogic <- SpawnEntityFromTable( "tf_logic_player_destruction", { StartDisabled = true, res_file = "resource/UI/HudArenaLives.res" });

// EntFireByHandle( PDLogic, "DisableMaxScoreUpdating", null, 0.00, null, null );
// EntFireByHandle( PDLogic, "SetPointsOnPlayerDeath", "0", 0.00, null, null );

// local _gamerules = Entities.FindByClassname(null, "tf_gamerules");

// if ( _gamerules != null )
// {
//     SetPropBool( _gamerules, "m_bPlayingRobotDestructionMode", true )
// };

// ::PlayerCountSet <- function( _iNewPlayerCount, _iTeamNum = -1 )
// {
//     if ( PDLogic == null || !PDLogic.IsValid() )
//         return;

//     if ( _iTeamNum == -1 ) // -1 is both teams (for resetting etc)
//     {
//         SetPropInt( PDLogic, "m_nRedPlayers", _iNewPlayerCount );
//         SetPropInt( PDLogic, "m_nBluePlayers", _iNewPlayerCount );
//     }
//     else
//     {
//         if ( _iTeamNum == TF_TEAM_RED )
//         {
//             SetPropInt( PDLogic, "m_nRedPlayers", _iNewPlayerCount );
//         }
//         else if ( _iTeamNum == TF_TEAM_BLUE )
//         {
//             SetPropInt( PDLogic, "m_nBluePlayers", _iNewPlayerCount );
//         };
//     };

//     return;
// };
