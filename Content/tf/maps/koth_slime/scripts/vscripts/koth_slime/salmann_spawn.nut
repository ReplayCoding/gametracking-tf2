spawnPoints <- [];

local spawnPoint = null;
while (spawnPoint = Entities.FindByName(spawnPoint, "spawn_salmann"))
    spawnPoints.push(spawnPoint);

function SpawnSalmannWave(min = 5, max = 8)
{
    local random = RandomInt(min, max);
    ShuffleArray(spawnPoints);
    for(local i = 0; i < random; i++)
        EntFireByHandle(self, "RunScriptCode", "SpawnSalmann(activator)", i * 0.5 + RandomFloat(0, 2), spawnPoints[i], spawnPoints[i]);
}

function SpawnSalmann(spawnPoint, team = 5)
{
	local tf_zombie = SpawnEntityFromTable("tf_zombie",
	{
		origin = spawnPoint.GetOrigin(),
        angles = spawnPoint.GetAbsAngles(),
        vscripts = "koth_slime/salmann.nut",
        thinkfunction = "SalmannThink",
		playbackrate = 1.0,
        TeamNum = team,
        "OnDeath": "!self,RunScriptCode,main_script.AttemptToDropHealthCan(lastPos),-1,-1",
	});
    tf_zombie.SetHealth(1234);
    tf_zombie.SetModelSimple(SALMANN_MODEL);
    tf_zombie.SetAbsAngles(spawnPoint.GetAbsAngles());
    NetProps.SetPropFloat(tf_zombie, "m_flNextAttack", 1);
    return tf_zombie;
}

function ShuffleArray(array)
{
    local currentIndex = array.len() - 1;
    local swap;
    local randomIndex;

    while (currentIndex > 0)
    {
        randomIndex = RandomInt(0, currentIndex);
        currentIndex -= 1;

        swap = array[currentIndex];
        array[currentIndex] = array[randomIndex];
        array[randomIndex] = swap;
    }

    return array;
}