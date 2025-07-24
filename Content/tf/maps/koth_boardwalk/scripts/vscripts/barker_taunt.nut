ClassVoicelines <-
{
    [Constants.ETFClass.TF_CLASS_SCOUT] = "Barker.Taunt_Scout",
    [Constants.ETFClass.TF_CLASS_ENGINEER] = "Barker.Taunt_Engie",
    [Constants.ETFClass.TF_CLASS_HEAVYWEAPONS] = "Barker.Taunt_Heavy",
    [Constants.ETFClass.TF_CLASS_SNIPER] = "Barker.Taunt_Sniper",
    [Constants.ETFClass.TF_CLASS_SPY] = "Barker.Taunt_Spy",
    [Constants.ETFClass.TF_CLASS_PYRO] = "Barker.Taunt_Pyro",
    // add more entries here
}

speaker <- null

function OnPostSpawn()
{
	local speaker_name = NetProps.GetPropString(self, "m_iszResponseContext")
    speaker = Entities.FindByName(null, speaker_name)
    self.ConnectOutput("OnStartTouch", "PlayVoiceline")
}

function PlayVoiceline()
{
    if (activator.IsPlayer())
    {
        if (RandomInt(1, 6) == 1)
        {
            local player_class = activator.GetPlayerClass()
            if (player_class in ClassVoicelines)
                speaker.EmitSound(ClassVoicelines[player_class])
        }
    }
}

function Precache()
{
    foreach (player_class, sound_name in ClassVoicelines)
        PrecacheScriptSound(sound_name)
        
    PrecacheScriptSound("Barker.Damage")
    PrecacheScriptSound("Barker.Idle")
    PrecacheScriptSound("Barker.Win")
    PrecacheScriptSound("Barker.Lose")
    PrecacheScriptSound("Barker.Taunt_Engie")
    PrecacheScriptSound("Barker.Taunt_Heavy")
    PrecacheScriptSound("Barker.Taunt_Scout")
    PrecacheScriptSound("Barker.Taunt_Pyro")
    PrecacheScriptSound("Barker.Taunt_Sniper")
    PrecacheScriptSound("Barker.Taunt_Spy")
}