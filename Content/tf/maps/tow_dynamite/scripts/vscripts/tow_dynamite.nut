PrecacheSound(")player/fall_damage_indicator.wav");
PrecacheScriptSound("Halloween.PumpkinDrop");
PrecacheModel("bootsModels/workshop/player/items/soldier/mantreads/mantreads.mdl");

::dynamiteEvents <- {};

//=========================================================================
//Jump Spell Pickup
//=========================================================================

::tf_player_manager <- Entities.FindByClassname(null, "tf_player_manager");

function SpawnSpell(location)
{
    local pickupEnt = SpawnEntityFromTable("item_armor", {
        origin = location,
        spawnflags = 1 << 30,
        effects = EF_NOSHADOW,
        OnCacheInteraction = "!self,RunScriptCode,PickUp(activator),-1,-1"
    })
    pickupEnt.SetMoveType(MOVETYPE_FLYGRAVITY, MOVECOLLIDE_FLY_BOUNCE);
    pickupEnt.SetAbsVelocity(Vector(RandomFloat(-50, 50), RandomFloat(-50, 50), 250));
    pickupEnt.SetSize(Vector(-23, -23, -25), Vector(23, 23, 35));
    pickupEnt.SetSolid(SOLID_BBOX);
    pickupEnt.DisableDraw();
    pickupEnt.ValidateScriptScope();
    pickupEnt.GetScriptScope().pickupTime <- Time() + 1;
    SetPropBool(pickupEnt, "m_bForcePurgeFixedupStrings", true);
    EntFireByHandle(pickupEnt, "Kill", "", 30, null, null);


    local bootsModel = Entities.CreateByClassname("prop_dynamic");
    bootsModel.SetAbsOrigin(location);
    bootsModel.SetModel("models/workshop/player/items/soldier/mantreads/mantreads.mdl");
    bootsModel.SetModelScale(1.6, -1);
    SetPropInt(bootsModel, "m_fEffects", EF_NOSHADOW);
    SetPropBool(bootsModel, "m_bForcePurgeFixedupStrings", true);
    EntFireByHandle(bootsModel, "SetParent", "!activator", 0, pickupEnt, pickupEnt);
    bootsModel.ValidateScriptScope();
    bootsModel.GetScriptScope().Think <- function()
    {
        local angles = format("0 %d 0", self.GetAbsAngles().Yaw() + 1);
        self.KeyValueFromString("angles", angles);
        return -1;
    }
    AddThinkToEnt(bootsModel, "Think");


    local particle = SpawnEntityFromTable("info_particle_system", {
        effect_name = "spellbook_major_burning",
        origin = location - Vector(0, 0, 2),
        start_active = 1
    });
    SetPropBool(particle, "m_bForcePurgeFixedupStrings", true);
    EntFireByHandle(particle, "SetParent", "!activator", 0, pickupEnt, pickupEnt);

    pickupEnt.EmitSound("Halloween.PumpkinDrop");
}

::PickUp <- function(player)
{
    if (Time() < pickupTime)
        return;
	for (local weapon, i = 0; i < 7; i++)
	{
		weapon = GetPropEntityArray(player, "m_hMyWeapons", i);
        if (weapon && weapon.IsValid())
        {
            SetPropBool(weapon, "m_bForcePurgeFixedupStrings", true);
            if (weapon.GetClassname() == "tf_weapon_spellbook")
            {
                SendGlobalGameEvent("halloween_pumpkin_grab", {
                    userid = GetPropIntArray(tf_player_manager, "m_iUserID", player.entindex())
                });
                SetPropInt(weapon, "m_iSelectedSpellIndex", 4);
                SetPropInt(weapon, "m_iSpellCharges", 2);
                EmitSoundOnClient("Halloween.spelltick_set", player);
                caller.Kill();
                return;
            }
        }
    }
}

//=========================================================================
//Rooftop Ignite Ramp-up
//=========================================================================

lastIgniteTS <- []; lastIgniteTS.resize(MAX_CLIENTS + 1, Time() + 99999);
lastIgniteTicks <- []; lastIgniteTicks.resize(MAX_CLIENTS + 1, 3);

for (local trigger_ignite = null; trigger_ignite = Entities.FindByClassname(trigger_ignite, "trigger_ignite");)
{
    SetPropBool(trigger_ignite, "m_bForcePurgeFixedupStrings", true);

    //trigger_ignite.RemoveSolidFlags(4);
    //trigger_ignite.SetCollisionGroup(COLLISION_GROUP_BREAKABLE_GLASS);

    SetPropBool(SpawnEntityFromTable("func_nobuild", {
        origin = trigger_ignite.GetOrigin(),
        angles = trigger_ignite.GetAbsAngles(),
        spawnflags = 1,
        model = GetPropString(trigger_ignite, "m_ModelName")
    }), "m_bForcePurgeFixedupStrings", true);
}

dynamiteEvents.OnScriptHook_OnTakeDamage <- function(params)
{
    local player = params.const_entity;
    if (!player.IsPlayer())
        return;
    if (("inflictor" in params) && params.inflictor && params.inflictor.GetClassname() == "trigger_ignite")
    {
        local playerIndex = player.entindex();
        local time = Time();
        if (time - lastIgniteTS[playerIndex] > 1)
            lastIgniteTicks[playerIndex] = 3;
        lastIgniteTicks[playerIndex] = clampCeiling(20, lastIgniteTicks[playerIndex] + 1.01);
        params.damage *= lastIgniteTicks[playerIndex];
        lastIgniteTS[playerIndex] = time;
    }
    OnScriptHook_OnTakeDamage2(player, params);
}.bindenv(this);

//=========================================================================
//Jump Pad Buffs
//=========================================================================

custom_dmg_stomp <- SpawnEntityFromTable("point_template", { classname = "mantreads" });
::isUsingJumpPad <- [];
::isUsingJumpPad.resize(MAX_CLIENTS + 1, false);

::ApplyFallDamageResistance <- function()
{
    local entIndex = self.entindex();
    isUsingJumpPad[entIndex] = true;
    self.AddCustomAttribute("mod_air_control_blast_jump", 3, -1);
    EmitAmbientSoundOn("TFPlayer.AirBlastImpact", 5, 1, 100, self);

    EntFireByHandle(self,
        "RunScriptCode",
        "EmitSoundEx({sound_name = `)player/fall_damage_indicator.wav`, filter_type = 1, volume = 0.5, channel = 6, sound_level = 120, entity = self, speaker_entity = self });",
        0.3, null, null);
}

function OnScriptHook_OnTakeDamage2(player, params)
{
    if ((params.damage_type & DMG_FALL) && isUsingJumpPad[player.entindex()] && !player.InCond(TF_COND_ROCKETPACK))
    {
        params.damage *= 0.3;

        local groundEnt = GetPropEntity(player, "m_hGroundEntity");
        if (!groundEnt || !groundEnt.IsValid() || !groundEnt.IsPlayer())
            return;

        groundEnt.TakeDamageCustom(
            custom_dmg_stomp,
            player,
            custom_dmg_stomp,
            Vector(0,0,0),
            player.GetOrigin(),
            10 + params.damage * 9,
            DMG_FALL,
            0);
        EmitAmbientSoundOn("Weapon_Mantreads.Impact", 8, 1, 100, groundEnt);
        EmitAmbientSoundOn("Player.FallDamageDealt", 4, 1, 100, groundEnt);

        local particle = SpawnEntityFromTable("info_particle_system", {
            effect_name = "stomp_text",
            origin = player.GetOrigin(),
            start_active = 1
        });
        SetPropBool(particle, "m_bForcePurgeFixedupStrings", true);
        EntFireByHandle(particle, "Kill", "", 3, null, null);
    }
}

//=========================================================================
//Replace Crumpkins with the Jump Spell
//=========================================================================

CRUMPKIN_INDEX <- PrecacheModel("models/props_halloween/pumpkin_loot.mdl");

dynamiteEvents.OnGameEvent_player_death <- function(params)
{
    local crumpkins = [];
    for (local ent = null; ent = Entities.FindByClassname(ent, "tf_ammo_pack");)
    {
        SetPropBool(ent, "m_bForcePurgeFixedupStrings", true);
        if (GetPropInt(ent, "m_nModelIndex") == CRUMPKIN_INDEX)
            crumpkins.push(ent);
    }
    foreach(crumpkin in crumpkins)
    {
        if (!RandomInt(0, 1))
            SpawnSpell(crumpkin.GetOrigin());
        crumpkin.Kill();
    }
}.bindenv(this);

//=========================================================================
//Util
//=========================================================================

local thinker = Entities.CreateByClassname("point_template");
thinker.ValidateScriptScope();
thinker.GetScriptScope().Think <- function()
{
    for (local player, weapon, playerIndex = 1; playerIndex <= MAX_CLIENTS; playerIndex++)
    {
        player = PlayerInstanceFromIndex(playerIndex);
        if (!player)
            continue;

        if (isUsingJumpPad[playerIndex] && GetPropEntity(player, "m_hGroundEntity"))
        {
            isUsingJumpPad[playerIndex] = false;
            player.RemoveCustomAttribute("mod_air_control_blast_jump");
        }

        weapon = player.GetActiveWeapon();
        if (!weapon || weapon.GetClassname() != "tf_weapon_spellbook")
            continue;

        if (GetPropFloat(weapon, "m_flTimeNextSpell") - Time() > 0)
        {
            SetPropEntity(player, "m_hGroundEntity", null);
            player.ApplyAbsVelocityImpulse(player.EyeAngles().Forward() * 10);
            player.RemoveFlag(FL_ONGROUND);
            isUsingJumpPad[playerIndex] = true;
        }
    }
    return -1;
}.bindenv(this);
AddThinkToEnt(thinker, "Think");

__CollectGameEventCallbacks(dynamiteEvents);