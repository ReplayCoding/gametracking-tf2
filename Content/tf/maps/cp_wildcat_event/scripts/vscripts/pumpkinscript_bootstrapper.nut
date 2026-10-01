::CONST <- getconsttable()
::ROOT <- getroottable()
if (!("ConstantNamingConvention" in ROOT)) // make sure folding is only done once
{
	foreach (enum_table in Constants)
	{
		foreach (name, value in enum_table)
		{
			if (value == null)
				value = 0

			CONST[name] <- value
			ROOT[name] <- value
		}
	}
}

::CollectEventsInScope <- function(events, source = "")
{
	local events_id = UniqueString()
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
	if (source != "") {printl("Collecting Events In Scope - " + source)}
}

IncludeScript("pumpkinscript_consts")
IncludeScript("pumpkinscript_precache")
IncludeScript("pumpkinscript")
