::hell_script <- this;

//==================================
//Randomized spawns
//==================================

local random = RandomInt(1, 4);

local spawn = null;
while (spawn = Entities.FindByClassname(spawn, "info_player_teamspawn"))
{
    NetProps.SetPropBool(spawn, "m_bForcePurgeFixedupStrings", true);
	local name = spawn.GetName();
	if (startswith(name, "spawn") && name != "spawn_" + random)
        spawn.Kill();
}

function SelectRandomSpawn()
{
    foreach (player in GetValidMercs())
		player.ForceRespawn();
}

EntFireByHandle(self, "RunScriptCode", "SelectRandomSpawn()", 0.01, null, null);

//==================================
//Healing ponds
//==================================

function TickHealingPond(player)
{
    player.ExtinguishPlayerBurning();
    local oldHealth = player.GetHealth();
    local maxHP = player.GetMaxHealth();

    if (oldHealth >= maxHP)
        return;

    local newHealth = oldHealth + maxHP * 0.1;
    newHealth = newHealth >= maxHP ? maxHP : newHealth;
    player.SetHealth(newHealth);

    SendGlobalGameEvent("player_healonhit", {
        entindex = player.entindex(),
        amount = newHealth - oldHealth
    });
}

//==================================
//Randomized portals
//==================================

PrecacheSound("vo/halloween_haunted1.mp3");
PrecacheEntityFromTable({ classname = "info_particle_system", effect_name = "vortex_appearation" });

activePortalA <- -1;
activePortalB <- -1;
portalCount <- 7;

function EnableRandomPortals()
{
    for (local i = 0; i < portalCount; i++)
        for (local ent = null; ent = Entities.FindByName(ent, "vortex" + i);)
        {
            NetProps.SetPropBool(ent, "m_bForcePurgeFixedupStrings", true);
            if (ent.GetClassname() != "trigger_teleport")
                continue;
            EntityOutputs.AddOutput(ent,
                "OnStartTouch",
                "!self",
                "RunScriptCode",
                "hell_script.OnPortalUsed(" + i + ")",
                -1, -1);
        }
    EnablePortal(PickRandomPortal());
    EnablePortal(PickRandomPortal());
}
EntFireByHandle(self, "RunScriptCode", "EnableRandomPortals()", 0, null, null);

function PickRandomPortal()
{
    local index;
    do
    {
        index = RandomInt(0, portalCount - 1);
    }
    while (index == activePortalA || index == activePortalB);
    return index;
}

function EnablePortal(index)
{
    if (activePortalA == -1)
        activePortalA = index;
    else if (activePortalB == -1)
        activePortalB = index;

    local name = "vortex" + index;
    DoEntFire(name, "Enable", "", 0, null, null);
    DoEntFire(name, "Start", "", 0, null, null);
    DoEntFire(name, "TurnOn", "", 0, null, null);
}

function DisablePortal(index)
{
    if (activePortalA == index)
        activePortalA = -1;
    if (activePortalB == index)
        activePortalB = -1;

    local name = "vortex" + index;
    DoEntFire(name, "Disable", "", 0, null, null);
    DoEntFire(name, "Stop", "", 0, null, null);
    DoEntFire(name, "TurnOff", "", 0, null, null);
}

function OnPortalUsed(index)
{
    local player = activator;
    local portal = caller;
    DispatchParticleEffect("vortex_appearation", player.GetOrigin(), Vector());
    player.SetAbsVelocity(player.EyeAngles().Forward() * player.GetAbsVelocity().Length());
    EmitSoundEx({
        entity = portal,
        sound_name = "vo/halloween_haunted1.mp3",
        channel = 6,
        sound_level = 85,
        volume = 1
    });
    EmitSoundEx({
        entity = player,
        speaker_entity = player,
        sound_name = "vo/halloween_haunted1.mp3",
        channel = 6,
        volume = 0.5
    });
    EntFireByHandle(self, "RunScriptCode", "EnablePortal(" + PickRandomPortal() + ")", 4, null, null);
    DisablePortal(index);
}

//==================================
//Rare Extra-Long Round Start
//==================================

function StartSetup()
{
    if (!vsh_vscript.IsValidRound())
        return;
    local delay = API_GetFloat("setup_length") < 20 ? 0 : 12;
    DoEntFire("explosion", "Trigger", "", delay, null, null);
}
EntFireByHandle(self, "RunScriptCode", "StartSetup()", 0.1, null, null);

//==================================
//No Crumpkins
//==================================

::no_crumpkins <- {
    CRUMPKIN_INDEX = PrecacheModel("models/props_halloween/pumpkin_loot.mdl"),
    OnGameEvent_player_death = function(params)
    {
        local crumpkins = [];
        for (local tf_ammo_pack = null; tf_ammo_pack = Entities.FindByClassname(tf_ammo_pack, "tf_ammo_pack");)
        {
            NetProps.SetPropBool(tf_ammo_pack, "m_bForcePurgeFixedupStrings", true);
            if (NetProps.GetPropInt(tf_ammo_pack, "m_nModelIndex") == CRUMPKIN_INDEX)
                crumpkins.push(tf_ammo_pack);
        }
        foreach(crumpkin in crumpkins)
            crumpkin.Kill();
    }
};
EntFireByHandle(self, "RunScriptCode", "::__CollectGameEventCallbacks(no_crumpkins)", 1, null, null);