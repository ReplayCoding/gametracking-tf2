// --------------------------------------------------------------------------------------- //
// Written by: Harry Colquhoun (https://steamcommunity.com/profiles/76561198025795825)     //
// --------------------------------------------------------------------------------------- //
// Enforces a banlist on spells by rerolling them automatically                            //
// --------------------------------------------------------------------------------------- //
const FIRST_RARE_SPELL     = 7;
const MAX_SPELLS           = 11;

const SPELL_FIREBALL       = 0;
const SPELL_BATS           = 1;
const SPELL_OVERHEAL       = 2;
const SPELL_PUMPKIN_BOMBS  = 3;
const SPELL_BLASTJUMP      = 4;
const SPELL_STEALTH        = 5;
const SPELL_TELEPORT       = 6;
const SPELL_LIGHTNING_BALL = 7;
const SPELL_ATHLETIC       = 8;
const SPELL_METEOR         = 9;
const SPELL_MONOCULUS      = 10;
const SPELL_SKELETON       = 11;

// allow the teleport spell to be used as a substitute for a banlisted non-rare spell
EnableTeleportSpell <- false;

// -------------------------------------- //
// pick which spells you want to ban here //
// -------------------------------------- //
BannedSpells <-
[
    // ------------- //
    // normal spells //
    // ------------- //
//  SPELL_FIREBALL,
//  SPELL_BATS,
//  SPELL_OVERHEAL,
//  SPELL_PUMPKIN_BOMBS,
//  SPELL_BLASTJUMP,
//  SPELL_STEALTH,
//  SPELL_TELEPORT,

    // ------------- //
    // rare spells   //
    // ------------- //
 // SPELL_LIGHTNING_BALL,
    SPELL_ATHLETIC,
 // SPELL_METEOR,
 // SPELL_MONOCULUS,
 // SPELL_SKELETON
];

if ( !( "SpellCheckLoaded" in getroottable() ) )
{
    AllowedRegularSpells  <- [];
    AllowedRareSpells     <- [];

    // if the teleport spell is enabled and not in the ban list
    if ( EnableTeleportSpell && !BannedSpells.find( SPELL_TELEPORT ) )
    {
        AllowedRegularSpells.append( SPELL_TELEPORT );
    };

    // fill an array with indexes of acceptable spells
    // to use as replacements for banned ones.
    for ( local i = 1; i < MAX_SPELLS; i++ )
    {
        if ( i == SPELL_TELEPORT )
            continue; // already handled above

        if ( !BannedSpells.find( i ) )
        {
            if ( i >= FIRST_RARE_SPELL && i <= MAX_SPELLS )
            {
                AllowedRareSpells.append( i );
            }
            else
            {
                AllowedRegularSpells.append( i );
            };
        };
    };

    OnTick <- function()
    {
        local _nextSpellbook = null;
        while ( _nextSpellbook = Entities.FindByClassname( _nextSpellbook, "tf_weapon_spellbook" ) )
        {
            foreach ( _spell in BannedSpells )
            {
                if ( NetProps.GetPropInt( _nextSpellbook, "m_iSelectedSpellIndex" ) == _spell )
                {
                    local bRareSpell        = false;
                    local iSpellCharge      = 1;
                    local iReplacementSpell = -1;

                    local iNumRegularSpells = ( AllowedRegularSpells.len() );
                    local iNumRareSpells    = ( AllowedRareSpells.len() );

                    // check if the spell is rare
                    if( ( _spell >= FIRST_RARE_SPELL ) && ( _spell <= MAX_SPELLS ) )
                    {
                        bRareSpell = true;
                    };

                    // check and filter extreme conditions
                    if ( iNumRegularSpells == 0 || iNumRareSpells == 0  )
                    {
                        // both pools banned
                        if ( iNumRegularSpells == 0 && iNumRareSpells == 0 )
                        {
                            // don't need to do anything special, just strip the spell and return
                            NetProps.SetPropInt( _nextSpellbook, "m_iSelectedSpellIndex", -1 );
                            NetProps.SetPropInt( _nextSpellbook, "m_iSpellCharges", 0 );
                            continue;
                        }
                        else if ( iNumRegularSpells == 0 )
                        {
                            // no regular spells but there are rares
                            // force all spells to rare.
                            bRareSpell = true;
                        }
                        else
                        {
                            // no rare spells but there are regulars
                            // force all spells to regular
                            bRareSpell = false;
                        };
                    };

                    // if the teleport spell is enabled, use it as a replacement every 1 in x banned spells times
                    // Note: this means banning one spell with replace it exclusively with the teleport
                    if ( EnableTeleportSpell && RandomFloat( 0.0, 1.0 ) < ( 1.0 / BannedSpells.len() ) )
                    {
                        iReplacementSpell = SPELL_TELEPORT;
                    };

                    // if all rare spells are banned, get a random regular spell instead
                    if ( iReplacementSpell == -1 ) // this is where we roll a new spell
                    {
                        if ( bRareSpell ) // if the spell is rare, use a rare spell as a replacement
                        {
                            iReplacementSpell = AllowedRareSpells[ RandomInt( 0, iNumRareSpells - 1 ) ];
                        }
                        else // otherwise just a regular spell will do thanks
                        {
                            iReplacementSpell = AllowedRegularSpells[ RandomInt( 0, iNumRegularSpells - 1  ) ];
                        };
                    };

                    // finally, set the actual spell index
                    NetProps.SetPropInt( _nextSpellbook, "m_iSelectedSpellIndex", iReplacementSpell );

                    // these spells start with 2 charges.
                    if ( iReplacementSpell == SPELL_FIREBALL  ||
                         iReplacementSpell == SPELL_BATS      ||
                         iReplacementSpell == SPELL_BLASTJUMP ||
                         iReplacementSpell == SPELL_TELEPORT   )
                    {
                        iSpellCharge = 2;
                    };

                    // set spell charges
                    NetProps.SetPropInt( _nextSpellbook, "m_iSpellCharges", iSpellCharge );
                };
            };
        };

        return 0.0;
    };

    SpellCheckLoaded <- true;
};