/////////////////////
// Coal Pit Script //
/////////////////////

function checkCoalPitHolidays()
{
	local timetable = {}
	LocalTime(timetable)

	// Rick May / Soldier /////////////////////////////////////////
	if(IsHolidayActive( Constants.EHoliday.kHoliday_Soldier ))
	{
		DoEntFire("tf_gamerules", "RunScriptFile", "coalpit/holiday/soldier.nut", 0.3, null, null);
		printl("Coal Pit: enabled Soldier holiday event");
	}
	///////////////////////////////////////////////////////////////

	// Invasion ///////////////////////////////////////////////////
	if(timetable.day == 6 && timetable.month == 10)
	{
		DoEntFire("tf_gamerules", "RunScriptFile", "coalpit/holiday/invasion.nut", 0.3, null, null);
		printl("Coal Pit: enabled Invasion anniversary event");
	}
	///////////////////////////////////////////////////////////////

	// Halloween //////////////////////////////////////////////////
	if(IsHolidayActive( Constants.EHoliday.kHoliday_Halloween ) || IsHolidayActive( Constants.EHoliday.kHoliday_FullMoon ))
	{
		DoEntFire("relay_halloween", "Trigger", "0", 0, null, null);
		DoEntFire("tf_gamerules", "RunScriptFile", "coalpit/holiday/halloween.nut", 0.3, null, null);
		printl("Coal Pit: enabled Halloween/Full Moon holiday event");
	}
	///////////////////////////////////////////////////////////////

	// End of the Line ////////////////////////////////////////////
	if(timetable.day == 8 && timetable.month == 12 || IsHolidayActive( Constants.EHoliday.kHoliday_EOTL ))
	{
		DoEntFire("relay_eotl", "Trigger", "0", 0, null, null);
		printl("Coal Pit: enabled End of the Line anniversary event");
	}
	///////////////////////////////////////////////////////////////
	
	// Summer /////////////////////////////////////////////////////
	if(IsHolidayActive( Constants.EHoliday.kHoliday_Summer ))
	{
		DoEntFire("tf_gamerules", "RunScriptFile", "coalpit/holiday/summer.nut", 0.3, null, null);
		printl("Coal Pit: enabled Summer holiday event");
	}
	///////////////////////////////////////////////////////////////
}

checkCoalPitHolidays();
