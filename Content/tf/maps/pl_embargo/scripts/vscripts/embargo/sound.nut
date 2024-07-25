PrecacheSound(")embargo/embargo_helicopter_intro.mp3");
PrecacheSound(")embargo/embargo_helicopter_loop.wav");
PrecacheSound(")embargo/embargo_helicopter_outro.mp3");

//These 3 functions are used by map I/O
function PlayMusic(path)
{
    path = "#" + path;
    PrecacheSound(path);
    EmitSoundEx({
        sound_name = path,
        filter_type = 5,
        channel = -2,
        volume = 0.6
    });
}

function StopMusic(path)
{
    path = "#" + path;
    PrecacheSound(path);
    EmitSoundEx({
        sound_name = path,
        filter_type = 5,
        flags = 4,
        channel = -2,
        volume = 0
    });
}

function PlayHeliSounds()
{
    local entHeli = Entities.FindByName(null, "propellor_hurt_1");
    for (local i = 1; i < 3; i ++)
        EmitSoundEx({
            sound_name = ")embargo/embargo_helicopter_intro.mp3",
            filter_type = 5,
            channel = i,
            volume = 1,
            sound_level = 150,
            entity = entHeli
        });
    RunWithDelay(5.7, function() {
        EmitSoundEx({
            sound_name = ")embargo/embargo_helicopter_loop.wav",
            filter_type = 5,
            channel = 1,
            volume = 0.7,
            sound_level = 150,
            entity = self
        });
    }, entHeli);
    RunWithDelay(23, function() {
        EmitSoundEx({
            sound_name = ")embargo/embargo_helicopter_outro.mp3",
            filter_type = 5,
            channel = 6,
            volume = 1,
            sound_level = 150,
            entity = self
        });
    }, entHeli);
    RunWithDelay(23.2, function() {
        EmitSoundEx({
            sound_name = ")embargo/embargo_helicopter_loop.wav",
            filter_type = 5,
            channel = 1,
            volume = 0,
            flags = 4,
            sound_level = 150,
            entity = self
        });
    }, entHeli);
}

//"Play" the SND_STOP sound for the heli loop in case the round restarts during setup
EmitSoundEx({
    sound_name = ")embargo/embargo_helicopter_loop.wav",
    filter_type = 5,
    channel = 1,
    volume = 0,
    flags = 4,
    sound_level = 150,
    entity = Entities.FindByName(null, "propellor_hurt_1")
});