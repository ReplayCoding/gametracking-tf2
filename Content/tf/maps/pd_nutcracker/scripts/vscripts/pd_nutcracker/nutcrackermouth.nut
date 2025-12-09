# Entities
NutcrackerSpeakCaseEntityName <- "NutcrackerSpeakCase"
NutcrackerVoicelineFinishedNotifierEntityName <- "NutcrackerVoicelineFinishedNotifier"
MultipleMercsEatenCase <- "16"

# State
VoicelinePlaying <- false
PlayerClassesEaten <- []

# Triggered from trigger_hurt whenever a player is eaten by the nutcracker, appends the array to keep track of count and class
function OnPlayerClassEaten() {
    printl("Player eaten: " + activator.GetPlayerClass().tostring())
    local PlayerClass = activator.GetPlayerClass()
    PlayerClassesEaten.push(PlayerClass)
}

# Triggered after nutcracker mouth closes, chooses appropriate voiceline to play
function ChooseAndPlayVoiceline() {
    if (PlayerClassesEaten.len() == 0) {
        return
    }

    if (PlayerClassesEaten.len() == 1) {
        PlayClassVoiceline(PlayerClassesEaten[0])
    } else if (PlayerClassesEaten.len() > 1) {
        PlayMultipleMercsEatenVoiceline()
    }

    PlayerClassesEaten.clear()
}

function PlayClassVoiceline(PlayerClass) {
    if (!VoicelinePlaying) {
        VoicelinePlaying = true
        EntFire(NutcrackerSpeakCaseEntityName, "InValue", PlayerClass.tostring(), 0, self)
        EntFire(NutcrackerVoicelineFinishedNotifierEntityName, "Trigger", null, 0, self)
    }
}

function PlayMultipleMercsEatenVoiceline() {
    if (!VoicelinePlaying) {
        VoicelinePlaying = true
        EntFire(NutcrackerSpeakCaseEntityName, "InValue", MultipleMercsEatenCase, 0, self)
        EntFire(NutcrackerVoicelineFinishedNotifierEntityName, "Trigger", null, 0, self)
    }
}

function SetVoicelineFinished() {
    VoicelinePlaying = false
}