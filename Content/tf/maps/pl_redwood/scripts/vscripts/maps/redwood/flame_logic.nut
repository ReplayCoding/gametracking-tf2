// VScript Fireplace logic (extreme edition), for pl_redwood
// by Sarexicus

local lit = false;
local rocket = null;
local bomb = null;
local bomb2 = null;

local particle = null;
local arrow_trigger = null;
local ignite_trigger = null;

local round_timer = null;
local particle_ent_name = "fireplace_particle";

local particle_name = "buildingdamage_dispenser_fire1";

FIRE_AMBIENT_SOUND <- "ambient/fire/fire_small1.wav";

CLASS_HEAVY <- Constants.ETFClass.TF_CLASS_HEAVYWEAPONS;
CLASS_PYRO <- Constants.ETFClass.TF_CLASS_PYRO;

COND_AIMING <- Constants.ETFCond.TF_COND_AIMING;
COND_SPEED_BOOST <- Constants.ETFCond.TF_COND_SPEED_BOOST;
COND_CRITS <- Constants.ETFCond.TF_COND_CRITBOOSTED;
COND_TAUNTING <- Constants.ETFCond.TF_COND_TAUNTING;

function Precache() {
	PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = particle_name });
    PrecacheScriptSound("Fire.Engulf");
    PrecacheScriptSound("Weapon_FlameThrower.AirBurstAttackDeflect");
    PrecacheScriptSound(FIRE_AMBIENT_SOUND);
}

function CreateTrigger(classname, targetname, size) {
    local trigger = SpawnEntityFromTable(classname, {
        "targetname": targetname,
        "origin": self.GetOrigin(),
        "spawnflags": 1,
        "burn_duration": 5,
        "damage_percent_per_second": 5,
        "StartDisabled": 1
    });
    trigger.SetSize(Vector(-size, -size, -size), Vector(size, size, size));
    trigger.SetSolid(Constants.ESolidType.SOLID_BBOX);
    return trigger;
}


function OnPostSpawn() {
    bomb = CreateBomb();
    FindTimer();

    particle = Entities.FindByName(null, particle_ent_name);
    if(particle == null) particle = CreateParticle();

    arrow_trigger = CreateTrigger("trigger_ignite_arrows", "_temp_fire_arrow_igniter", 80);
    ignite_trigger = CreateTrigger("trigger_ignite", "_temp_fire_player_igniter", 24);
}

function Think() {
    if (lit) {
        CheckAirblasted();
        JarCheck();
        ManmelterCheck();
    }
    else {
        HeaterAndTauntCheck();
    }

    local isInSetup = (round_timer != null && NetProps.GetPropInt(round_timer, "m_nState") == 0);
    return isInSetup ? 0 : 0.25;
}

function FindTimer() {
    round_timer = Entities.FindByClassname(null, "team_round_timer");
}

function Distance(a, b) { return (b-a).Length(); }
function JarCheck() {
    for (local entity; entity = Entities.FindByClassname(entity, "tf_projectile_jar*");) {
		local e_origin = entity.GetOrigin();
		local p_origin = self.GetOrigin();
		if (Distance(e_origin, p_origin) > 64) continue;
        printl("jar!!")

        Extinguish(true);
	}
}

function AngleBetween(angle, start, end) {
    local vec1 = angle;
    local vec2 = end - start;
    vec2.Norm();
    return acos(vec1.Dot(vec2) / (vec1.Norm() * vec2.Norm()));
}

function HeaterAndTauntCheck() {
    local or = self.GetOrigin();
    for (local i = 1; i <= MaxPlayers; i++) {
        local player = PlayerInstanceFromIndex(i);
        if (player == null) continue;
        local p = player.GetPlayerClass();
        if(!player.IsAlive() || (p != CLASS_HEAVY && p != CLASS_PYRO)) continue;
        if(Distance(player.GetOrigin(), or) > 192) continue;

        if(player.InCond(COND_AIMING)) {
            local weapon = player.GetActiveWeapon();
            if(!weapon || !weapon.IsValid()) continue;
            local itemIndex = NetProps.GetPropInt(weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex");
            if(itemIndex != 811 && itemIndex != 832) continue;

            local weaponState = NetProps.GetPropInt(weapon, "m_iWeaponState");
            if(weaponState <= 1) continue;

            Ignite(true);
            return;
        }

        if(player.InCond(COND_TAUNTING)) {
            // check this is a tauntkill
            local tauntTime = player.GetTauntAttackTime();
            if(tauntTime == 0) continue;

            local timeLeftInTaunt = player.GetTauntAttackTime() - Time();
            if(timeLeftInTaunt > 0.2) continue;

            // check the player is facing the fire, except rainblower, which is 360deg
            local eyePos = player.GetOrigin() + player.GetClassEyeHeight();
            local angle = AngleBetween(player.EyeAngles().Forward(), eyePos, self.GetOrigin());
            if(angle > 1.0472) { // = 60deg
                local weapon = player.GetActiveWeapon();
                if(!weapon || !weapon.IsValid()) continue;
                local itemIndex = NetProps.GetPropInt(weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex");
                if(itemIndex != 741) continue;
            }

            Ignite(true);
        }
    }
}

function ManmelterCheck() {
    local or = self.GetOrigin();
    for (local i = 1; i <= MaxPlayers; i++) {
        local player = PlayerInstanceFromIndex(i);
        if (player == null) continue;
        if(!player.IsAlive() || player.GetPlayerClass() != CLASS_PYRO) continue;
        if(Distance(player.GetOrigin(), or) > 96) continue;

        local scope = player.GetScriptScope();
        if(scope.buttons_last & Constants.FButtons.IN_ATTACK2) {
            local weapon = player.GetActiveWeapon();
            if(!weapon || !weapon.IsValid()) continue;

            local itemIndex = NetProps.GetPropInt(weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex");
            if(itemIndex != 595) continue;

            Extinguish(true);

            SendGlobalGameEvent("player_healonhit", {
                entindex = player.entindex(),
                amount = 20
            });

            local hp = player.GetHealth();
            local max_hp = player.GetMaxHealth();
            hp = (hp + 20 > max_hp) ? max_hp : hp + 20;
            player.SetHealth(hp);

            return;
        }
    }
}

function CheckAirblasted() {
    if (rocket == null || !rocket.IsValid()) {
        Extinguish();
        return false;
    }
    // if rocket angle is not Up, it's extinguished
    local angle_var = rocket.GetAbsAngles().x + 90;
    if (angle_var > 0.1 || angle_var < -0.1) {
        Extinguish();
    }
}

function CreateParticle() {
    local p = SpawnEntityFromTable("info_particle_system", {
        "targetname": particle_ent_name,
        "classname": "info_teleport_destination", // unpreserve
        "effect_name": particle_name,
        "origin": self.GetOrigin()
    });
    return p;
}

function OnBombExplode(activator) {
    Ignite();
}

function CreateBomb(scale = 0.5) {
    local b = SpawnEntityFromTable("tf_generic_bomb", {
        "damagefilter": "filter_pyro_primary",
        "targetname": "_temp_fireplace_bomb",
        "origin": self.GetOrigin(),
        "model": "models/props_badlands/barrel01.mdl",
        "modelscale": scale,
        "rendermode": 10,
        "disableshadows": 1,
        "sound": "Fire.Engulf",
        "damage": 0,
        "health": 1
    });
    // collide with fire but not players
    b.SetSolid(6);
    b.SetCollisionGroup(23);

    b.ValidateScriptScope();
    local scope = b.GetScriptScope();
    scope.owner <- this;
    scope.OnExploded <- function() {
        owner.OnBombExplode(activator);
    }
    b.ConnectOutput("OnDetonate", "OnExploded");

    return b;
}

function CreateRocket() {
    rocket = SpawnEntityFromTable("tf_projectile_rocket", {
        "targetname": "_temp_fireplace_rocket",
        "angles": QAngle(-90, 0, 0),
        "origin": self.GetOrigin(),
        "modelscale": 0,
        "rendermode": 10
    });
    rocket.AcceptInput("DispatchEffect", "ParticleEffectStop", null, null);
    rocket.SetCollisionGroup(Constants.ECollisionGroup.COLLISION_GROUP_DEBRIS);
}

function Ignite(play_sound = false) {
    lit = true;
    arrow_trigger.AcceptInput("Enable", "", null, null);
    ignite_trigger.AcceptInput("Enable", "", null, null);
    StartLoopingSound(FIRE_AMBIENT_SOUND);
    particle.AcceptInput("Start", "", null, null);
    CreateRocket();
    if (bomb != null && bomb.IsValid()) bomb.Destroy();
    bomb2 = CreateBomb(0.3);
    bomb2.SetOrigin(bomb2.GetOrigin() + Vector(0, 0, 16));

    if(play_sound) {
        PlaySoundAt(self.GetOrigin(), "Fire.Engulf", 1);
    }
}

function Extinguish(play_sound = false) {
    lit = false;
    arrow_trigger.AcceptInput("Disable", "", null, null);
    ignite_trigger.AcceptInput("Disable", "", null, null);
    StopLoopingSound(FIRE_AMBIENT_SOUND);
    if (rocket != null && rocket.IsValid()) rocket.Destroy();
    particle.AcceptInput("Stop", "", null, null);
    rocket = null;

    if (bomb2 != null && bomb2.IsValid()) bomb2.Destroy();
    bomb = CreateBomb();

    if(play_sound) {
        PlaySoundAt(self.GetOrigin(), "Weapon_FlameThrower.AirBurstAttackDeflect", 1);
    }
}

function CollectEventsInScope(events)
{
	local events_id = "flame_logic"
	getroottable()[events_id] <- events

	foreach (name, callback in events)
		events[name] = callback.bindenv(this)

	local cleanup_user_func, cleanup_event = "OnGameEvent_scorestats_accumulated_update"
	if (cleanup_event in events)
		cleanup_user_func = events[cleanup_event]

	events[cleanup_event] <- function(params)
	{
		if (cleanup_user_func)
			cleanup_user_func(params)

		delete getroottable()[events_id]
	}
	__CollectGameEventCallbacks(events)
}

function ResetBomb(params) {
    params.early_out <- true;
    params.damage <- 0;
}

// filter flame bomb damage to fire-types
function ProcessIgnite(params) {
    local attacker = params.attacker;
    if (!attacker) return ResetBomb(params);

    local weapon = params.weapon;
    if(!weapon) {
        // detect flaming arrows
        local inflictor = params.inflictor;
        if(inflictor != null && inflictor.GetClassname() == "tf_projectile_arrow" && NetProps.GetPropBool(inflictor, "m_bArrowAlight")) {
            return;
        }
        return ResetBomb(params);
    }

    // is it doing ignite-type damage
    local is_burn_damage = (params.damage_type & Constants.FDmgType.DMG_PLASMA);
    if(is_burn_damage) return;

    // is it being hit by the Sharpened Volcano Fragment
    local itemIndex = NetProps.GetPropInt(weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex");
    local is_fire_weapon = (itemIndex == 348);
    if(is_fire_weapon) return;

    return ResetBomb(params);
}

function PlaySoundAt(origin, sound, channel = 6, volume = 1.0, pitch = 100) {
    EmitSoundEx({
        sound_name = sound,
        channel = channel,
        origin = origin,
        pitch = pitch,
        flags = 3,
        volume = volume,
        filter_type = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_GLOBAL,
        entity = this
    });
}

function StartLoopingSound(sound, channel = 6, volume = 1.0, pitch = 100) {
    EmitSoundEx({
        sound_name = sound,
        origin = self.GetOrigin(),
        pitch = pitch,
        sound_level = 80,
        flags = 3,
        volume = volume,
        channel = channel,
        entity = this,
        filter_type = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_GLOBAL
    });
}

function StopLoopingSound(sound, channel = 6) {
    EmitSoundEx({
        sound_name = sound,
        channel = channel,
        entity = this,
        flags = 4 // SND_STOP
    });
}

function ProcessSecrets(params) {
    local attacker = params.attacker;
    if (!attacker) return ResetBomb(params);

    local weapon = params.weapon;
    if(!weapon) return ResetBomb(params);

    local itemIndex = NetProps.GetPropInt(weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex");

    if(itemIndex == 349) {
        attacker.AddCondEx(COND_CRITS, 0.5, null);
        attacker.AcceptInput("SpeakResponseConcept", "TLK_PLAYER_CHEERS", null, null);
    }

    if(itemIndex == 38 || itemIndex == 1000 || itemIndex == 457) {
        attacker.AddCondEx(COND_SPEED_BOOST, 2, null);
        Extinguish(true);
    }

    return ResetBomb(params);
}

CollectEventsInScope
({
    function OnGameEvent_recalculate_holidays(params){
        StopLoopingSound(FIRE_AMBIENT_SOUND);
    }

	function OnScriptHook_OnTakeDamage(params)
	{
        local victim = params.const_entity;
        if(victim == bomb) return ProcessIgnite(params);
        if(victim == bomb2) return ProcessSecrets(params);
	}
})