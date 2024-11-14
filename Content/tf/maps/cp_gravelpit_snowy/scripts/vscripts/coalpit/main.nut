/////////////////////
// Coal Pit Script //
/////////////////////

ClearGameEventCallbacks();

local statue = null
while (statue = Entities.FindByClassname(statue, "entity_soldier_statue"))
{
	DoEntFire("entity_soldier_statue", "Kill", "0", 0, null, null);					//prevent duplicate statues from taking up edicts
}

function checkHolidays()
{
	local timetable = {}
	LocalTime(timetable)

	// Rick May ///////////////////////////////////////////////////
	if(timetable.day == 8 && timetable.month == 4)
	{
		DoEntFire("relay_rickmay", "Trigger", "0", 0, null, null);
		printl("Enabled Rick May tribute");
	}
	///////////////////////////////////////////////////////////////

	// Invasion ///////////////////////////////////////////////////
	if(timetable.day == 6 && timetable.month == 10)
	{
		DoEntFire("invasion*", "Enable", "0", 0, null, null);
		printl("Enabled Invasion anniversary references");
	}
	///////////////////////////////////////////////////////////////

	// Halloween //////////////////////////////////////////////////
	if(IsHolidayActive(2) || IsHolidayActive(9))
	{
		DoEntFire("relay_halloween", "Trigger", "0", 0, null, null);
		printl("Enabled Halloween/Full Moon props");
	}
	///////////////////////////////////////////////////////////////

	// End of the Line ////////////////////////////////////////////
	if(timetable.day == 8 && timetable.month == 12)
	{
		DoEntFire("relay_eotl", "Trigger", "0", 0, null, null);
		printl("Enabled End of the Line anniversary reference");
	}
	///////////////////////////////////////////////////////////////
}

checkHolidays();

__CollectGameEventCallbacks(this);