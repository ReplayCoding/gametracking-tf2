local DEBUG_MODE = false;


::ROOT <- getroottable(); //Fetch global variables and add them to the global scope
::MaxPlayers <- MaxClients().tointeger();


local _INITIALIZED = false;

local LEAF_BONE_PREFIX = "bone_leaf_";

local LEAF_SOUND_THRESHOLD = 30.0;
local LEAF_SOUND_PERCENTAGE_THRESHOLD = 50;
local LEAF_SOUND_LEVEL = (40 + (20 * log10(/*radius in hu*/8192 / 36.0))).tointeger();
local IS_LAUNCHING = false;

local IS_RUMBLING = false;
local RUMBLE_INTENSITY = 0.0;
local RUMBLE_MAX_AMPLITUDE = 8;
local RUMBLE_TIMER = 0;
local RUMBLE_RAMPUP_TIME = 8.0 * (200/3);

local LEAF_DAMAGE_THRESHOLD = 10.0;
local LEAF_HURT_RADIUS = 200.0;

local LAUNCH_TIMER = 0;
local CRASH_TIME = 2.0 * (200/3); //Time until rocket hits the dome after launch
local HAS_CRASHED = false;

local particleNames = ["rocket_launch_particles", "rocket_launch_particles1", "rocket_launch_particles2", "rocket_launch_particles3", "rocket_launch_particles4"];
local particleAttachments = ["attachment_booster_main", "attachment_booster_small_1", "attachment_booster_small_2", "attachment_booster_small_3", "attachment_booster_smoke"];
local particleSystems = [];

local sparks1 = Entities.FindByName(null, "dome_sparks1");
local sparks2 = Entities.FindByName(null, "dome_sparks2");
local sparks3 = Entities.FindByName(null, "dome_sparks3");

local GLOW_NAME = "bright_bob";
local GLOW_START_DELAY = 1.5;
local GLOW_END_DELAY = 4.0;
local GLOW_RANDOMNESS = 2;
local GLOW_TIMER = 0.0;

local CRASH_SOUND = "Cart.Explode";
PrecacheScriptSound(CRASH_SOUND);
local METAL_SOUNDS = [ //Number indicates weight
    ["Bounce.Metal", 1],
    ["Breakable.MatMetal", 1],
    ["Metal_Barrel.BulletImpact", 1],
    ["Metal_Barrel.ImpactHard", 1],
    ["Metal_Barrel.ImpactSoft", 1],
    ["Metal_Box.BulletImpact", 1],
    ["Metal_Box.ImpactHard", 1],
    ["pyro_taunt_the_grilled_gunman_item_metal_pot_pickup", 1],
    ["SolidMetal.BulletImpact", 1],
    ["SolidMetal.ImpactHard", 1],
    ["SolidMetal.ImpactSoft", 1],
    
    //["FryingPan.HitFlesh", 1],
    ["FryingPan.HitWorld", 1],
    
    
    ["Halloween.HeadlessBossAxeHitWorld", 1],
    
    ["heavy_taunt_soviet_strongarm_demo_charge_hit_world1", 1],
    ["heavy_taunt_soviet_strongarm_demo_charge_hit_world3", 1],
    ["MVM_Weapon_3rd_degree.HitFlesh", 1],
    ["MVM_Weapon_BaseballBat.HitFlesh", 1],
    ["MVM_Weapon_Assassin_Knife.HitFlesh", 1],
    ["MVM_Weapon_Bat.HitFlesh", 1],
    ["Weapon_Bat.HitFlesh", 1],
    ["Weapon_Bat.HitWorld", 1],
    ["Weapon_3rd_degree.HitWorld", 1],
    ["Weapon_Crowbar.Melee_HitWorld", 1],
    ["Weapon_Katana.HitWorld", 1],
    ["Weapon_Sword.HitFlesh", 1],
    ["Weapon_Sword.HitWorld", 1],
    //["Weapon_Wrench.HitBuilding_Success", 1],
];

//Le Funny
//local METAL_SOUNDS = [["FryingPan.HitFlesh", 1], ["FryingPan.HitFlesh", 1], ["Scout.NeedDispenser01", 1], ["FryingPan.HitWorld", 1]];


for(local i = 0; i < METAL_SOUNDS.len(); i++) {
    PrecacheScriptSound(METAL_SOUNDS[i][0]);
}

local leafBones = [];

local prevLeafCoords = [];
local leafCoords = [];
local prevLeafVelocities = [];
local leafVelocities = [];
local leafVelDeltas = [];

local frame = 0;

function initialize() {
    for(local i = 0; i < 35; i++) {
        local boneIndex = self.LookupBone(LEAF_BONE_PREFIX + i);
    
        if(boneIndex != -1) { //Bone Exists
            console(boneIndex);
            leafBones.push(boneIndex);
            local coords = self.GetBoneOrigin(boneIndex);
            
            prevLeafCoords.push(coords);
            leafCoords.push(coords);
            prevLeafVelocities.push(Vector(0.0, 0.0, 0.0));
            leafVelocities.push(Vector(0.0, 0.0, 0.0));
            leafVelDeltas.push(Vector(0.0, 0.0, 0.0));
        }
    }
}


function think() {
    frame ++;
    if(!_INITIALIZED) {
        initialize();
        _INITIALIZED = true;
    }
    else {
        if(frame % 5 == 0) {
            updateBones();
            frame = 0;
        }

    }

    if(IS_RUMBLING) {
        RUMBLE_TIMER ++;
        RUMBLE_INTENSITY = clamp(RUMBLE_TIMER / RUMBLE_RAMPUP_TIME, 0, 1);
        ScreenShake(
            self.GetBoneOrigin(self.LookupBone("booster_main")),
            RUMBLE_MAX_AMPLITUDE * RUMBLE_INTENSITY, //Amplitude 
            4.0, //Frequency
            8, //Duration
            1600.0, //Radius
            0, //Start:0 Stop:1. Just don't touch this one
            true //AirShake
            );
    }
    //IS_RUMBLING = false;

    if(IS_LAUNCHING) {
        LAUNCH_TIMER ++;

        if(!HAS_CRASHED && LAUNCH_TIMER >= CRASH_TIME) {
            
            breakGlass();
            HAS_CRASHED = true;
        }


        handleLight(FrameTime());
        
    }

    return -1;
}


function breakGlass() {
    EmitSoundEx({
        flags = /*SND_CHANGE_PITCH*/ 2,
        sound_name = CRASH_SOUND,
        origin = self.GetBoneOrigin(self.LookupBone("rocket_base")),
        filter = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_GLOBAL,
        sound_level = LEAF_SOUND_LEVEL,
        volume = 1,
        pitch = 100,
        channel = 75
    });

    local glassCenter = Entities.FindByName(null, "dome_center");
    EntFireByHandle(glassCenter, "disable", "", -1, null, null);



    EntFireByHandle(sparks1, "SparkOnce", "", -1, null, null);
    EntFireByHandle(sparks2, "SparkOnce", "", 0.1, null, null);
    EntFireByHandle(sparks3, "SparkOnce", "", 0.25, null, null);
}


function updateBones() {
    for(local i = 0; i < leafBones.len(); i++) {
        
        prevLeafCoords[i] = leafCoords[i];
        leafCoords[i] = self.GetBoneOrigin(i);
        
        prevLeafVelocities[i] = leafVelocities[i];
        leafVelocities[i] = leafCoords[i] - prevLeafCoords[i];

        leafVelDeltas[i] = leafVelocities[i] - prevLeafVelocities[i];

        handleSounds(i, leafVelDeltas[i]);
        if(leafVelocities[i].Length() >= LEAF_DAMAGE_THRESHOLD) {
            damagePlayers(leafCoords[i], i);
        }
    }
}

function handleSounds(boneIndex, deltaV) {
    //console(deltaV);
    if(IS_LAUNCHING && max3(abs(deltaV.x), abs(deltaV.y), abs(deltaV.z)) >= LEAF_SOUND_THRESHOLD) {
        //console("[" + boneIndex + "] CLANK!");
        playRandomMetalSound(leafCoords[boneIndex], boneIndex);

        local sparkList = [sparks1, sparks2, sparks3];

        sparkList[boneIndex % 3].SetOrigin(leafCoords[boneIndex]);
        EntFireByHandle(sparkList[boneIndex % 3], "SparkOnce", "", -1, null, null);

        ScreenShake(
            leafCoords[boneIndex],
            7.0, //Amplitude 
            4.0, //Frequency
            2.0, //Duration
            1000.0, //Radius
            0, //Start:0 Stop:1. Just don't touch this one
            true //AirShake
            );
    }
}

function playRandomMetalSound(coords, boneIndex) {
    local soundIndex = RandomInt(0, METAL_SOUNDS.len() - 1);
    local soundPitch = 50;//RandomInt(45, 55); //50
    console("[" + soundIndex + "]!!!");
    EmitSoundEx({
        flags = /*SND_CHANGE_PITCH*/ 2,
        sound_name = METAL_SOUNDS[soundIndex][0],
        origin = coords,
        filter = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_GLOBAL,
        sound_level = LEAF_SOUND_LEVEL,//0.2,
        volume = 1,
        pitch = soundPitch,
        channel = 106 - boneIndex
    });
}

function damagePlayers(coords, boneIndex) {
    for (local i = 1; i <= MaxPlayers ; i++)
    {
        local player = PlayerInstanceFromIndex(i);
        if (player == null) continue;
        //console(player)
        local playerCoords = player.GetOrigin();

        if((playerCoords - coords).Length() <= LEAF_HURT_RADIUS) {
            
            //https://developer.valvesoftware.com/wiki/Team_Fortress_2/Scripting/Script_Functions/Constants#ETFDmgCustom

            local damageType = 0; //Bat tauntkill BONK! icon: 10
            
            local hitDamage = 500;
            player.TakeDamageCustom(self, null, null, (playerCoords - coords) * (playerCoords - coords).Norm() * 50.0, coords, hitDamage, damageType, damageType);
        }

        
    }
}

function enableParticles() {
    console("bleh");
    for(local i = 0; i < particleNames.len(); i++) {
        
        local particle = Entities.FindByName(null, particleNames[i]);
        local attachment = self.LookupAttachment(particleAttachments[i]);

        if(particle != null && attachment != -1) {
            console(particleNames[i]);
            particleSystems.push(particle);
            EntFireByHandle(particle, "SetParent", "rocket", -1, null, null);
            EntFireByHandle(particle, "SetParentAttachment", particleAttachments[i], 0.5, null, null);

            local d = 0;
            local repeatDelay = 1;
            local repeatCount = 10;
            for(local j = 0; j < repeatCount; j++) {
                EntFireByHandle(particle, "Stop", "", d - 0.02 + repeatDelay * j, null, null);
                EntFireByHandle(particle, "Start", "", d + repeatDelay * j, null, null);
            }
        }

    }
}


function handleLight(delta) {
    GLOW_TIMER += FrameTime();
    if(GLOW_TIMER >= GLOW_START_DELAY && GLOW_TIMER <= GLOW_END_DELAY) {
        local light = Entities.FindByName(null, GLOW_NAME);
        EntFireByHandle(light, "TurnOn", "", -1, null, null);

        // Light pattern brightness is controlled by letter strings. A (dimmest) -> Z (brightest). Default is M.
        // ABCDEFGFEDCBA: Fade in/out
        // Single letter means constant value, but setting it programmatically lets us fade it with MATH! Wow!
        local ALPHABET = "abcdefghijklmnopqrstuvwxyz";

        // Clamped lerp from glow start to end as input for sine function.
        local lerpedValue = clamp((GLOW_TIMER - GLOW_START_DELAY) / (GLOW_END_DELAY - GLOW_START_DELAY), 0, 1);

        //Sine function for fade in/out with random factor
        local lightStrength = clamp(ceil(sinInOut(lerpedValue) * 19) + RandomInt(-1 * ceil(GLOW_RANDOMNESS), ceil(GLOW_RANDOMNESS)), 0, 25);

        local alphabetPattern = ALPHABET.slice(lightStrength, lightStrength + 1);
        EntFireByHandle(light, "SetPattern", alphabetPattern, -1, null, null);

    } else if(GLOW_TIMER >= GLOW_END_DELAY) {
        local light = Entities.FindByName(null, GLOW_NAME);
        EntFireByHandle(light, "TurnOff", "", -1, null, null);
    }
}

function sinInOut(n) {
    return sin(n * 3.1415926535);
}


function startRumbling() {
    IS_RUMBLING = true;
}

function launch() {
    IS_LAUNCHING = true;
    EntFireByHandle(self, "SetAnimation", "launch", -1, null, null);
    enableParticles();
}



function max(n1, n2) {
    if(n1 > n2) {
        return n1;
    }
    return n2;
}

function max3(n1, n2, n3) {
    return max(max(n1, n2), n3);
}

function clamp(n, min, max) {
    if(n < min) {
        return min;
    }
    if(n > max) {
        return max;
    }
    return n;
}

function lerp(n, start, end) {
    return (start + (end - start) * n);
}

function deg2rad(deg) {
    return deg * PI / 180.0;
}

function rad2deg(rad) {
    return rad * 180 / PI;
}

function console(str) {
    if(DEBUG_MODE) {
        printl(str);
    }
}

