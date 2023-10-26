// --------------------------------------------------------------------------------------- //
// Perks - Version 1.4                                                                     //
// --------------------------------------------------------------------------------------- //
// Game Design and Scripting by: Le Codex (https://steamcommunity.com/id/lecodex)          //
// Assets by: Diva Dan (https://steamcommunity.com/profiles/76561198072146551)             //
// and Tianes (https://steamcommunity.com/id/_tianes)                                      //
// --------------------------------------------------------------------------------------- //

class BasePerk {
    Identifier = ""

    Name = null
    Description = null
    ModelTemplate = null
    DisplayTemplate = null
    
    Team = null

    constructor(team) {
        Team = team;

        // UNCOMMENT THIS ONCE LOCALIZATION HAS BEEN IMPLEMENTED FOR POINT_WORLDTEXT
        // Name = "#arena_perks_" + Identifier + "_name"
        // Description = "#arena_perks_" + Identifier + "_desc"
        
        // AND COMMENT THIS
        Name = PERKS_NAMES[Identifier]
        Description = PERKS_DESCRIPTIONS[Identifier]

        ModelTemplate = Entities.FindByName(null, "mak_perk_" + Identifier + "_" + TeamName(team));
        DisplayTemplate = Entities.FindByName(null, "mak_perk_" + Identifier + "_display_" + TeamName(team));
    }
    
    function OnCollect() {}

    function OnRoundStart(team) {}
    function OnSpawn(player) {}
    function OnEnemySpawn(player) {}
    function OnDeath(player, attacker) {}
    function OnKill(player, victim) {}
    function OnPointUnlocked() {}
    function OnRoundEnd() {}
}


// BLOODLUST - Mini crits on kill //
class BloodlustPerk extends BasePerk {
    Identifier = "killcrits"

    function OnKill(player, victim) {
        player.AddCondEx(Constants.ETFCond.TF_COND_ENERGY_BUFF, 2, player);
    }
}


// CLOAKING - Invisibility on spawn //
// UNUSED //
class CloakingPerk extends BasePerk {
    Identifier = "cloak"

    function OnSpawn(player) {
        player.AddCondEx(Constants.ETFCond.TF_COND_STEALTHED_USER_BUFF, 15, null);
    }
}


// CONVERSION - Mini crits to crits //
class ConversionPerk extends BasePerk {
    Identifier = "minitofull"

    function OnSpawn(player) {
        player.AddCustomAttribute("minicrits become crits", 1.0, -1);
    }
}


// GRAVEDIGGING - Skeleton on death //
class GravediggingPerk extends BasePerk {
    Identifier = "skeleton"

    function OnDeath(player, attacker) {
        EntFire("mak_skeleton_"+TeamName(Team), "ForceSpawnAtEntityOrigin", "!activator", 0, player);
    }

    function OnRoundEnd() {
        EntFire("tf_zombie", "Kill", "", 0, null);
    }
}


// HASTE - Increased movement speed //
class HastePerk extends BasePerk {
    Identifier = "haste"

    function OnSpawn(player) {
        player.AddCustomAttribute("move speed bonus", 1.1, -1);
    }
}


// HAUNTING - Mark for death on death //
class HauntingPerk extends BasePerk {
    Identifier = "mark"

    function OnDeath(player, attacker) {
        attacker.AddCondEx(Constants.ETFCond.TF_COND_MARKEDFORDEATH, 6, player);
    }
}


// HONOR - Increased melee damage //
class HonorPerk extends BasePerk {
    Identifier = "honorable"

    function OnEnemySpawn(player) {
        player.AddCustomAttribute("dmg from melee increased", 2.0, -1);
    }
}


// PATIENCE - Passive regeneration //
class PatiencePerk extends BasePerk {
    Identifier = "patience"

    function OnSpawn(player) {
        player.AddCustomAttribute("health regen", 7.0, -1);
    }
}


// PRECISION - Reduced spread and increased projectile speed //
class PrecisionPerk extends BasePerk {
    Identifier = "precision"

    function OnSpawn(player) {
        player.AddCustomAttribute("spread penalty", 0.5, -1);
        player.AddCustomAttribute("Projectile range increased", 1.5, -1);
        player.AddCustomAttribute("Projectile speed increased", 1.5, -1);
    }
}


// PROVISIONS - Increased healing //
class ExtraProvisionsPerk extends BasePerk {
    Identifier = "healing"

    function OnSpawn(player) {
        player.AddCustomAttribute("health from healers increased", 1.4, -1);
        player.AddCustomAttribute("health from packs increased", 1.4, -1);
        player.AddCustomAttribute("lunchbox healing decreased", 1.4, -1);
    }
}


// QUICKDRAW - Increased reloading, switching, and firing speed //
class QuickdrawPerk extends BasePerk {
    Identifier = "quickfingers"

    function OnSpawn(player) {
        player.AddCustomAttribute("faster reload rate", 0.85, -1);
        player.AddCustomAttribute("fire rate bonus", 0.85, -1);
        player.AddCustomAttribute("deploy time increased", 0.85, -1);
    }
}


// RESERVE - Increased ammo and regenerating ammo and metal //
class ReservePerk extends BasePerk {
    Identifier = "reserve"

    function OnRoundStart(team) {
        foreach (player in GetAllPlayers()) {
            if (player.GetTeam() != team) continue;

            for (local i = 0; i <= 7; i++)
            {
                local weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i);
                if (weapon == null) continue;
                
                weapon.AddAttribute("clip size bonus upgrade", 1.5, -1);
                weapon.AddAttribute("clip size upgrade atomic", 2, -1);
            }
        }
    }

    function OnSpawn(player) {
        player.AddCustomAttribute("ammo regen", 20, -1);
        player.AddCustomAttribute("metal regen", 50, -1);
    }
}


// RESISTANCE - Reduced damage taken //
class ResistancePerk extends BasePerk {
    Identifier = "resistance"

    function OnSpawn(player) {
        player.AddCustomAttribute("dmg taken increased", 0.9, -1);
    }
}


// REVEAL - Reveal enemies on kill //
class RevealPerk extends BasePerk {
    Identifier = "reveal"

    RevealDuration = 5;

    function OnKill(player, victim) {
        RunWithDelay(function(player) {
            local enemyPlayers = [];
            foreach (other in GetAllPlayers()) {
                if (!IsPlayerAlive(other) || other.GetTeam() != 5 - player.GetTeam()) continue;

                enemyPlayers.push({
                    player = other,
                    distance = (other.GetOrigin() - player.GetOrigin()).Length()
                });
            }

            enemyPlayers = enemyPlayers.sort(@(a,b) a.distance - b.distance);
            local amount = 3;
            if (amount > enemyPlayers.len()) amount = enemyPlayers.len();

            for (local i = 0; i < amount; i++) {
                local other = enemyPlayers[i].player;

                // "Prop" that will be glowing
                local proxy_entity = Entities.CreateByClassname("obj_sentrygun");
                proxy_entity.SetAbsOrigin(other.GetOrigin());
                proxy_entity.DispatchSpawn();
                proxy_entity.SetModel(other.GetModelName());
                proxy_entity.AddEFlags(Constants.FEntityEFlags.EFL_NO_THINK_FUNCTION);
                NetProps.SetPropString(proxy_entity, "m_iName", UniqueString("glow_target"));
                NetProps.SetPropBool(proxy_entity, "m_bPlacing", true);
                NetProps.SetPropInt(proxy_entity, "m_fObjectFlags", 2);

                // Bonemerging
                proxy_entity.SetSolid(0);
                proxy_entity.SetMoveType(0, 0);
                NetProps.SetPropInt(proxy_entity, "m_fEffects", 129);
                NetProps.SetPropInt(proxy_entity, "m_nNextThinkTick", 0x7FFFFFFF);
                EntFireByHandle(proxy_entity, "SetParent", "!activator", -1, other, other);

                NetProps.SetPropEntity(proxy_entity, "m_hBuilder", player);
                EntFireByHandle(proxy_entity, "Kill", "", RevealDuration, null, null);

                // Tf_glow entity
                local glow = SpawnEntityFromTable("tf_glow", {
                    target = proxy_entity.GetName(), GlowColor = "255 255 255 255"
                });
                EntFireByHandle(glow, "Kill", "", RevealDuration, null, null);
            }
        }, 0.1, [this, player])
    }
}


// REVIVE - Revive on first death //
class RevivePerk extends BasePerk {
    Identifier = "revive"

    function OnRoundStart(team) {
        foreach (player in GetAllPlayers()) {
            player.ValidateScriptScope();
            if ("revive_marker" in player.GetScriptScope()) delete player.GetScriptScope().revive_marker;
        }
    }

    function OnDeath(player, attacker) {
        if ("revive_marker" in player.GetScriptScope()) return;

        local reviveMarker = SpawnEntityFromTable("entity_revive_marker", {
            targetname = "revive_marker"
            origin = player.GetOrigin() + Vector(0, 0, 50)
            angles = player.GetAbsAngles()
        });

        NetProps.SetPropEntity(reviveMarker, "m_hOwner", player);
        NetProps.SetPropInt(reviveMarker, "m_iTeamNum", player.GetTeam());
        reviveMarker.SetBodygroup(1, player.GetPlayerClass() - 1);
        reviveMarker.SetModelSimple("models/props_mvm/mvm_revive_tombstone_teamcolor.mdl");
        reviveMarker.SetSkin(player.GetTeam() == Constants.ETFTeam.TF_TEAM_RED ? 0 : 1);

        player.GetScriptScope().revive_marker <- reviveMarker;
    }

    function OnSpawn(player) {
        if ("revive_marker" in player.GetScriptScope() && player.GetScriptScope().revive_marker) {
            player.GetScriptScope().revive_marker.Destroy();
            player.AddCondEx(Constants.ETFCond.TF_COND_INVULNERABLE, 1.5, null);

            local state = ::PerkGamemode.GetActiveState()
            RunWithDelay(state.CountAlivePlayers, 0.1, [state, false]);
        }
    }

    function OnRoundEnd() {
        EntFire("revive_marker", "Kill", "", 0, null);
    }

    function DoOldRevive(player) {
        local pos = player.GetOrigin();
        local ang = player.EyeAngles();

        RunWithDelay(function(player, pos, ang) {
            NetProps.SetPropInt(player, "m_lifeState", LIFE_STATE.ALIVE);

            // Force people not to change classes
            local classIndex = player.GetPlayerClass();
            NetProps.SetPropInt(player, "m_Shared.m_iDesiredPlayerClass", classIndex);

            player.ForceRespawn();

            player.SetAbsOrigin(pos);
            player.SnapEyeAngles(ang);

            DispatchParticleEffect("ghost_appearation", pos, Vector(0, 0, 0));

            RunWithDelay(function(player) {
                player.AddCustomAttribute("max health additive penalty", -75, -1);
                player.AddCondEx(Constants.ETFCond.TF_COND_PHASE, 1.5, null);
                player.AddCondEx(Constants.ETFCond.TF_COND_MEDIGUN_DEBUFF, -1, null);

                player.SetHealth(player.GetMaxHealth());
            }, 0.1, [this, player]);
        }, 0.1, [this, player, pos, ang]);
    }
}


// STRONGHOLD - Bonuses when the point unlocks //
class StrongholdPerk extends BasePerk {
    Identifier = "focus"

    function OnPointUnlocked() {
        foreach (player in GetAllPlayers()) {
            if (player.GetTeam() != Team) continue;

            player.AddCustomAttribute("dmg taken increased", 0.8, -1);
            player.AddCustomAttribute("increase player capture value", 1, -1);
        }
    }
}


::PERK_LIST <- [
    BloodlustPerk,
    PatiencePerk,
    ConversionPerk,
    GravediggingPerk,
    HastePerk,
    HauntingPerk,
    HonorPerk,
    PrecisionPerk,
    ExtraProvisionsPerk,
    QuickdrawPerk,
    ReservePerk,
    ResistancePerk,
    RevealPerk,
    RevivePerk,
    StrongholdPerk
];

