/////////////////////
// Holidays Script //
/////////////////////

local timetable = {}
LocalTime(timetable)

// Smissmas /////////
if(timetable.month == 12)
{
	DoEntFire("SantaHat", "Enable", "0", 0, null, null);
	printl("Merry Smissmas!");
}
/////////////////////