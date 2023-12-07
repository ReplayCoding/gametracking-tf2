local DEBUG_MODE = false;


::ROOT <- getroottable(); //Fetch global variables and add them to the global scope
::MaxPlayers <- MaxClients().tointeger();

local canPlay = false;

local PLAY_HIT_SOUND_CHANCE = 0.4;
local VO_ENABLE_DELAY = 10.0; //Length of longest open voiceline + leeway
local VO_DISABLE_DELAY = 50.0 - 10.5; //Length of capzone opening minus longest hit sound (10s + leeway)
local SOUND_REPLAY_DELAY = 10.5;

local SOUND_TIMER = -1.0;
local lastPlayedTime = -100.0;

function hitPlayer(player) {

    if(canPlay) {
        console("Attempting to play...");
    }
    if(DEBUG_MODE) {
        local v = SOUND_TIMER - lastPlayedTime;
        if(v < SOUND_REPLAY_DELAY) {
            console("Not enough time has passed!");
            console(v);
        }

    }

    if(canPlay && SOUND_TIMER >= lastPlayedTime + SOUND_REPLAY_DELAY && RandomFloat(0.0, 1.0) <= PLAY_HIT_SOUND_CHANCE) {
        
        console("Play Success");

        lastPlayedTime = SOUND_TIMER;
    
        local soundGuy = Entities.FindByClassname(null, "tf_gamerules");
        //EntFireByHandle(soundGuy, "PlayVO", "Intercom.IceMachineHitGeneric", -1, null, null);

        if(RandomFloat(0.0, 1.0) <= 0.25) {
            //Team-specific Sound

            if(player.GetTeam() == 3) {
                //BLU
                EntFireByHandle(soundGuy, "PlayVO", "Intercom.IceMachineHitBlu", -1, null, null);
            }
            else {
                //RED
                EntFireByHandle(soundGuy, "PlayVO", "Intercom.IceMachineHitRed", -1, null, null);
            }

        }
        else {
            //Generic Sound

            EntFireByHandle(soundGuy, "PlayVO", "Intercom.IceMachineHitGeneric", -1, null, null);
        }


    }

}

function startSoundTimer() {
    SOUND_TIMER = 0.0;
    console("startSoundTimer()");
}

function enableSounds() {
    canPlay = true;
    console("enableSounds()");
}

function disableSounds() {
    SOUND_TIMER = -1.0;
    canPlay = false;
    lastPlayedTime = -100.0;
    console("disableSounds()");
}


function think() {
    if(SOUND_TIMER >= 0.0) {
        SOUND_TIMER += FrameTime();
        if(SOUND_TIMER >= VO_ENABLE_DELAY && !canPlay && SOUND_TIMER < VO_DISABLE_DELAY) {
            enableSounds();
        }
        else if(SOUND_TIMER >= VO_DISABLE_DELAY) {
            disableSounds();
        }
    }


    return -1;
}


function console(str) {
    if(DEBUG_MODE) {
        printl(str);
    }
}

