local DEBUG_MODE = false;


::ROOT <- getroottable(); //Fetch global variables and add them to the global scope
::MaxPlayers <- MaxClients().tointeger();

local JOKE_CHANCE = 0.15;
local canPlayJoke = true;
//Joke delay after cap zone opens: 10 seconds

function tryJokeAnnouncement() {
    console("Attempting to play joke...");
    if(canPlayJoke) {

        local soundGuy = Entities.FindByClassname(null, "tf_gamerules");

        if(RandomFloat(0.0, 1.0) <= JOKE_CHANCE) {
            console("Playing joke!");
            EntFireByHandle(soundGuy, "PlayVO", "Intercom.Joke", -1, null, null);
        }
    }
    
}

function disableJokes() {
    canPlayJoke = false;
}


function console(str) {
    if(DEBUG_MODE) {
        printl(str);
    }
}

