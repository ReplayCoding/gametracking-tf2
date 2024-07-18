local gamerules = Entities.FindByClassname(null, "tf_gamerules");

//humiliation time length in seconds
const HUMILIATION_TIME = 20;

print("searched for gamerules");

ClearGameEventCallbacks();

function OnGameEvent_teamplay_win_panel(params)
{
	print("function called");
	NetProps.SetPropFloat(gamerules, "m_flStateTransitionTime", Time() + HUMILIATION_TIME)
}

__CollectGameEventCallbacks(this)