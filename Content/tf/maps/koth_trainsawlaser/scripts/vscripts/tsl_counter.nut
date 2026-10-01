// by ficool2

COUNTER_REFRESH_DELAY   <- 1.5
COUNTER_UPDATE_INTERVAL <- 0.05
COUNTER_DIGIT_SOUND     <- "TSL.Counter"
COUNTER_SPELLBOOK_LIMIT <- 100

TF_DEATH_FEIGN_DEATH <- 32

m_pairs          	 <- []
m_counter        	 <- 0
m_last_counter       <- 0
m_spell_counter      <- 0
m_refresh_queued 	 <- false
m_refresh_pair   	 <- 0

function Precache()
{
	PrecacheScriptSound("TSL.Counter")
	PrecacheScriptSound("TSL_VO.Intro")
	PrecacheScriptSound("TSL_VO.TrainRain")
	PrecacheScriptSound("TSL_VO.TrainRainRare")
	PrecacheScriptSound("TSL_VO.OnKillRare")
	PrecacheScriptSound("TSL_VO.SpellSpawn")
	PrecacheScriptSound("TSL_VO.Outro")
	PrecacheScriptSound("TSL_VO.DeadRinger")
	PrecacheScriptSound("TSL_VO.ScoutKilled")
	PrecacheScriptSound("TSL_VO.HellIntro")
}

function OnPostSpawn()
{
	local prefix = self.GetName()
	for (local i = 0; i < 4; i++)
	{
		local name_a = format("%s_%d_a", prefix, i)
		local name_b = format("%s_%d_b", prefix, i)
		
		local counters_a = []
		local counters_b = []

		for (local counter; counter = Entities.FindByName(counter, name_a);)
			counters_a.append(counter)

		for (local counter; counter = Entities.FindByName(counter, name_b);)
			counters_b.append(counter)			

		if (counters_a.len() == 0 && counters_b.len() == 0)
			break
			
		m_pairs.append
		({
			a     = counters_a
			b     = counters_b
			digit = 0
		})
	}
}

function SetCounter(counter)
{
	m_counter = counter
	QueueRefresh()
}

function AddCounter(amount)
{
	SetCounter(m_counter + amount)
}

function QueueRefresh()
{
	if (m_refresh_queued)
		return
	
	m_refresh_queued = true
	EntFireByHandle(self, "CallScriptFunction", "Refresh", COUNTER_REFRESH_DELAY, null, null)
}

function Refresh()
{
	m_refresh_queued = false
	m_refresh_pair = 0
	
	local counter = m_counter
	foreach (i, pair in m_pairs)
	{
		local digit = counter % 10
		pair.digit = digit
		counter = counter / 10
	}
	
	m_spell_counter += m_counter - m_last_counter
	if (m_spell_counter >= COUNTER_SPELLBOOK_LIMIT)
	{
		m_spell_counter = 0
		SetUsingSpells(true)
		EntFire("Spells", "Enable")
		EntFire("killcounter_spells_vo", "Trigger")
	}
	
	m_last_counter = m_counter
	
	local delay = 0.0
	foreach (pair in m_pairs)
	{
		EntFireByHandle(self, "CallScriptFunction", "RefreshPairA", delay, null, null)
		delay += COUNTER_UPDATE_INTERVAL
		EntFireByHandle(self, "CallScriptFunction", "RefreshPairB", delay, null, null)
		delay += COUNTER_UPDATE_INTERVAL
	}
}

function RefreshPairA()
{
	local pair = m_pairs[m_refresh_pair]
	foreach (counter in pair.a)
	{
		if (counter.GetSkin() != pair.digit)
		{
			counter.SetSkin(pair.digit)
			counter.EmitSound(COUNTER_DIGIT_SOUND)
		}
	}
}

function RefreshPairB()
{
	local pair = m_pairs[m_refresh_pair]
	foreach (counter in pair.b)
	{
		if (counter.GetSkin() != pair.digit)
		{
			counter.SetSkin(pair.digit)
			counter.EmitSound(COUNTER_DIGIT_SOUND)
		}
	}
	m_refresh_pair++
}

local events_id = UniqueString()
local last_feign_death = 0.0
__CollectGameEventCallbacks(getroottable()[events_id] <- 
{
	function OnGameEvent_player_death[this](params)
	{
		if (params.death_flags & TF_DEATH_FEIGN_DEATH)
		{
			local time = Time()
			if (last_feign_death < time)
			{
				if (RandomInt(1, 100) <= 20)
				{
					EntFire(self.GetName() + "_feigndeath", "Trigger")
					last_feign_death = time + 10.0
				}
			}
		}
		else
		{
			EntFire(self.GetName() + "_death", "Trigger")
			
			AddCounter(1)
		}
	}

	function OnGameEvent_scorestats_accumulated_update[this](params)
	{
		SetUsingSpells(false)
		
		last_feign_death = Time() + 10.0
		
		delete getroottable()[events_id]
	}
})