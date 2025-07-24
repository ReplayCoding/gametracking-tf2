/**
 * VScript by Mikusch
 * https://steamcommunity.com/profiles/76561198071478507
 */

IncludeScript("trace_filter")

const RAT_MOVE_SPEED = 75.0
const RAT_RUN_SPEED = 225.0
const RAT_TURN_SPEED = 180.0
const RAT_RUN_TURN_SPEED = 270.0
const RAT_IDLE_MIN_TIME = 15.0
const RAT_IDLE_MAX_TIME = 20.0
const RAT_IDLE_DURATION_MIN = 5.0
const RAT_IDLE_DURATION_MAX = 7.0
const RAT_PLAYER_DETECT_RADIUS = 300.0
const RAT_PATH_RECOMPUTE_TIME = 0.5
const RAT_WAYPOINT_TOLERANCE = 20.0
const RAT_WANDER_RADIUS = 500.0
const RAT_NAV_SEARCH_RADIUS = 100.0
const RAT_STUCK_THRESHOLD = 5.0
const RAT_STUCK_TIME = 0.5
const WALKABLE_SLOPE_THRESHOLD = 0.7
const RAT_MAX_CLIMB_HEIGHT = 72.0
const RAT_MAX_DROP_HEIGHT = 100.0
const RAT_CLIMB_CHECK_DIST = 30.0
const RAT_RUN_AFTER_PLAYER_DELAY = 3.0

const RAT_IDLE_PLAYBACKRATE = 1.0
const RAT_WALK_PLAYBACKRATE = 1.5
const RAT_RUN_PLAYBACKRATE = 1.5

const FLT_MAX = 0x7F7FFFFF
const LIFE_ALIVE = 0

::MASK_NPCSOLID <- (Constants.FContents.CONTENTS_SOLID | Constants.FContents.CONTENTS_MOVEABLE | Constants.FContents.CONTENTS_MONSTERCLIP | Constants.FContents.CONTENTS_WINDOW | Constants.FContents.CONTENTS_MONSTER | Constants.FContents.CONTENTS_GRATE)

::ai_network <- Entities.FindByClassname(null, "ai_network")
::ai_network.ValidateScriptScope()

enum ERatState
{
	IDLE,
	WALKING,
	RUNNING
}

if (!("rats" in getroottable()))
	::rats <- []

::CRat <- class
{
	constructor(entity)
	{
		self = entity
		spawn_position = entity.GetOrigin()
		move_direction = QAngle(0, RandomFloat(0, 360), 0).Forward()
		state = ERatState.WALKING
		stuck_check_position = self.GetOrigin()
		stuck_check_time = Time()

		walk_sequence = self.LookupSequence("walk")
		run_sequence = self.LookupSequence("run")
		idle_sequences = [
			self.LookupSequence("idle_1"),
			self.LookupSequence("idle_2"),
			self.LookupSequence("idle_stand"),
			self.LookupSequence("idle_stand_scratch")
		]

		TransitionToState(ERatState.IDLE)
		SetRandomWanderTarget()
	}

	function Update()
	{
		local current_time = Time()

		CheckIfStuck()

		player_nearby = FindNearbyPlayers().len() > 0
		if (player_nearby)
			player_last_seen_time = current_time

		local should_run = player_nearby || (current_time - player_last_seen_time < RAT_RUN_AFTER_PLAYER_DELAY)
		local next_state = state

		switch (state)
		{
			case ERatState.IDLE:
				if (player_nearby)
					next_state = ERatState.RUNNING
				else if (current_time >= state_end_time)
					next_state = ERatState.WALKING
				break

			case ERatState.WALKING:
				if (should_run)
					next_state = ERatState.RUNNING
				else if (current_time >= state_end_time)
					next_state = ERatState.IDLE
				break

			case ERatState.RUNNING:
				if (!should_run)
					next_state = (current_time >= state_end_time) ? ERatState.IDLE : ERatState.WALKING
				break
		}

		if (next_state != state)
			TransitionToState(next_state)

		if (state != ERatState.IDLE)
			PerformMovement()

		self.StudioFrameAdvance()
		self.DispatchAnimEvents(self)

		if (developer() > 0)
			DrawDebugInfo(current_time)

		return -1
	}

	function TransitionToState(new_state)
	{
		state = new_state
		local duration = RandomFloat(RAT_IDLE_MIN_TIME, RAT_IDLE_MAX_TIME)

		switch (state)
		{
			case ERatState.IDLE:
				duration = RandomFloat(RAT_IDLE_DURATION_MIN, RAT_IDLE_DURATION_MAX)
				self.ResetSequence(idle_sequences[RandomInt(0, idle_sequences.len() - 1)])
				self.SetPlaybackRate(RAT_IDLE_PLAYBACKRATE)
				break

			case ERatState.WALKING:
				self.ResetSequence(walk_sequence)
				self.SetPlaybackRate(RAT_WALK_PLAYBACKRATE)
				SetRandomWanderTarget()
				break

			case ERatState.RUNNING:
				self.ResetSequence(run_sequence)
				self.SetPlaybackRate(RAT_RUN_PLAYBACKRATE)
				SetRandomWanderTarget()
				break
		}

		state_end_time = Time() + duration
	}

	function PerformMovement()
	{
		if (!target_position || HasReachedTarget())
		{
			SetRandomWanderTarget()
		}
		else if (ShouldRecomputePath())
		{
			ComputePath(target_position)
		}

		if (path.len() > 0 && current_waypoint_index < path.len())
		{
			local my_pos = self.GetOrigin()
			local target_waypoint = path[current_waypoint_index]
			local tolerance = (state == ERatState.RUNNING) ? RAT_WAYPOINT_TOLERANCE * 2.5 : RAT_WAYPOINT_TOLERANCE

			if ((target_waypoint - my_pos).Length2D() < tolerance)
				current_waypoint_index++

			if (current_waypoint_index < path.len())
				target_waypoint = path[current_waypoint_index]
			else if (target_position)
				target_waypoint = target_position
			else
				return

			local direction = target_waypoint - my_pos
			direction.z = 0
			direction.Norm()
			move_direction = direction
		}

		UpdateMovement()
	}

	function SetRandomWanderTarget()
	{
		local my_pos = self.GetOrigin()
		local my_area = NavMesh.GetNearestNavArea(my_pos, RAT_NAV_SEARCH_RADIUS, false, true)

		if (!my_area)
		{
			target_position = my_pos + QAngle(0, RandomFloat(0, 360), 0).Forward() * RAT_WANDER_RADIUS
			ComputePath(target_position)
			return
		}

		local areas = {}
		NavMesh.GetNavAreasInRadius(my_pos, RAT_WANDER_RADIUS, areas)

		local valid_areas = []
		foreach (name, area in areas)
		{
			local height_diff = area.GetCenter().z - my_pos.z
			if (height_diff <= RAT_MAX_CLIMB_HEIGHT && height_diff >= -RAT_MAX_DROP_HEIGHT)
				valid_areas.append(area)
		}

		if (valid_areas.len() > 0)
		{
			local random_area = valid_areas[RandomInt(0, valid_areas.len() - 1)]
			target_position = random_area.FindRandomSpot()
		}
		else
		{
			target_position = my_pos + QAngle(0, RandomFloat(0, 360), 0).Forward() * RAT_WANDER_RADIUS
		}

		ComputePath(target_position)
	}

	function ComputePath(goal_pos)
	{
		local my_pos = self.GetOrigin()
		local start_area = NavMesh.GetNearestNavArea(my_pos, RAT_NAV_SEARCH_RADIUS, false, true)
		local goal_area = NavMesh.GetNearestNavArea(goal_pos, RAT_NAV_SEARCH_RADIUS, false, true)

		path = []
		current_waypoint_index = 0
		last_path_time = Time()

		if (!start_area || !goal_area || !NavMesh.NavAreaBuildPath(start_area, goal_area, goal_pos, FLT_MAX, 0, false))
		{
			path = [goal_pos]
			return
		}

		local area_list = []
		local area = goal_area

		while (area)
		{
			area_list.append(area)
			if (area == start_area)
				break
			area = area.GetParent()
		}

		area_list.reverse()

		local prev_area = null
		foreach (idx, nav_area in area_list)
		{
			if (prev_area)
			{
				local height_diff = nav_area.GetCenter().z - prev_area.GetCenter().z
				if (abs(height_diff) > RAT_MAX_CLIMB_HEIGHT)
				{
					path = [goal_pos]
					return
				}

				if (abs(height_diff) > Convars.GetFloat("sv_stepsize"))
				{
					local from_center = prev_area.GetCenter()
					local to_center = nav_area.GetCenter()
					path.append(Vector(
						(from_center.x + to_center.x) * 0.5,
						(from_center.y + to_center.y) * 0.5,
						from_center.z
					))
				}
			}

			path.append(nav_area.GetCenter())
			prev_area = nav_area
		}

		if (path.len() > 0 && (goal_pos - path[path.len() - 1]).Length() > RAT_WAYPOINT_TOLERANCE)
			path.append(goal_pos)
	}

	function UpdateMovement()
	{
		local frame_time = FrameTime()
		local current_speed = (state == ERatState.RUNNING) ? RAT_RUN_SPEED : RAT_MOVE_SPEED
		local current_turn_speed = (state == ERatState.RUNNING) ? RAT_RUN_TURN_SPEED : RAT_TURN_SPEED

		local target_yaw = atan2(move_direction.y, move_direction.x) * 180.0 / PI
		local current_angles = self.GetAbsAngles()
		local current_yaw = current_angles.y

		local yaw_diff = target_yaw - current_yaw
		while (yaw_diff > 180) yaw_diff -= 360
		while (yaw_diff < -180) yaw_diff += 360

		local max_turn = current_turn_speed * frame_time
		if (abs(yaw_diff) > max_turn)
			yaw_diff = (yaw_diff > 0) ? max_turn : -max_turn

		local new_yaw = current_yaw + yaw_diff
		self.SetAbsAngles(QAngle(0, new_yaw, 0))
		move_direction = QAngle(0, new_yaw, 0).Forward()

		local current_pos = self.GetOrigin()
		local new_pos = current_pos + move_direction * current_speed * frame_time

		local ground_trace = TraceGround(new_pos, RAT_MAX_DROP_HEIGHT + 10)

		if (ground_trace.fraction > 0 && ground_trace.fraction < 1)
		{
			local height_drop = current_pos.z - ground_trace.pos.z
			if (height_drop <= RAT_MAX_DROP_HEIGHT)
			{
				local slope_dot = ground_trace.plane_normal.Dot(Vector(0, 0, 1))
				if (slope_dot >= WALKABLE_SLOPE_THRESHOLD)
				{
					self.SetAbsOrigin(ground_trace.pos)
				}
				else
				{
					TryAlternateMovement(current_pos, current_speed, frame_time, slope_dot)
				}
			}
		}
	}

	function TryAlternateMovement(current_pos, speed, frame_time, current_slope)
	{
		local best_dir = null
		local best_slope = current_slope

		for (local angle = -90; angle <= 90; angle += 30)
		{
			if (angle == 0) continue

			local rad = angle * PI / 180.0
			local cos_a = cos(rad)
			local sin_a = sin(rad)
			local test_dir = Vector(
				move_direction.x * cos_a - move_direction.y * sin_a,
				move_direction.x * sin_a + move_direction.y * cos_a,
				move_direction.z
			)

			local test_pos = current_pos + test_dir * speed * frame_time
			local test_trace = TraceGround(test_pos)

			if (test_trace.fraction > 0 && test_trace.fraction < 1)
			{
				local test_slope = test_trace.plane_normal.Dot(Vector(0, 0, 1))
				if (test_slope > best_slope && test_slope >= WALKABLE_SLOPE_THRESHOLD)
				{
					best_slope = test_slope
					best_dir = test_dir
				}
			}
		}

		if (best_dir)
		{
			move_direction = best_dir
			local final_pos = current_pos + best_dir * speed * frame_time
			local final_trace = TraceGround(final_pos)
			if (final_trace.fraction > 0 && final_trace.fraction < 1)
				self.SetAbsOrigin(final_trace.pos)
		}
	}

	function TraceGround(position, drop_distance = 50.0)
	{
		local rat_self = self
		local trace = {
			start = position + Vector(0, 0, 10),
			end = position - Vector(0, 0, drop_distance),
			ignore = self,
			mask = MASK_NPCSOLID,
			filter = function(entity)
			{
				if (entity == rat_self || entity.IsPlayer() || rats.find(entity) != null)
					return TRACE_CONTINUE
				return TRACE_STOP
			}
		}
		TraceLineFilter(trace)
		return trace
	}

	function ShouldRecomputePath()
	{
		if (stuck_count > 1)
			return true

		if (Time() - last_path_time < RAT_PATH_RECOMPUTE_TIME)
			return false

		if (path.len() > 0 && current_waypoint_index > 0 && current_waypoint_index < path.len())
		{
			local my_pos = self.GetOrigin()
			local prev_waypoint = path[current_waypoint_index - 1]
			local next_waypoint = path[current_waypoint_index]

			local line_vec = next_waypoint - prev_waypoint
			local line_len = line_vec.Length()

			if (line_len > 0)
			{
				line_vec.Norm()
				local point_vec = my_pos - prev_waypoint
				local dot = point_vec.Dot(line_vec)

				local dist_to_line = 0
				if (dot < 0)
					dist_to_line = point_vec.Length()
				else if (dot > line_len)
					dist_to_line = (my_pos - next_waypoint).Length()
				else
					dist_to_line = (my_pos - (prev_waypoint + line_vec * dot)).Length()

				local tolerance = (state == ERatState.RUNNING) ? RAT_WAYPOINT_TOLERANCE * 7.5 : RAT_WAYPOINT_TOLERANCE * 3
				if (dist_to_line > tolerance)
					return true
			}
		}

		return false
	}

	function HasReachedTarget()
	{
		if (!target_position)
			return true
		local tolerance = (state == ERatState.RUNNING) ? RAT_WAYPOINT_TOLERANCE * 2.5 : RAT_WAYPOINT_TOLERANCE
		return (target_position - self.GetOrigin()).Length2D() < tolerance
	}

	function FindNearbyPlayers()
	{
		local my_pos = self.GetOrigin()
		local player = null
		local players = []

		while ((player = Entities.FindByClassnameWithin(player, "player", my_pos, RAT_PLAYER_DETECT_RADIUS)) != null)
		{
			if (NetProps.GetPropInt(player, "m_lifeState") == LIFE_ALIVE)
				players.append(player)
		}

		return players
	}

	function CheckIfStuck()
	{
		local current_pos = self.GetOrigin()
		local current_time = Time()

		if (current_time - stuck_check_time > RAT_STUCK_TIME)
		{
			if ((current_pos - stuck_check_position).Length() < RAT_STUCK_THRESHOLD && state != ERatState.IDLE)
			{
				stuck_count++
				if (stuck_count > 2)
				{
					SetRandomWanderTarget()
					stuck_count = 0
				}
			}
			else
			{
				stuck_count = 0
			}

			stuck_check_position = current_pos
			stuck_check_time = current_time
		}
	}

	function DrawDebugInfo(current_time)
	{
		local my_pos = self.GetOrigin()
		local duration = FrameTime() * 2

		local state_text = ["IDLE", "WALKING", "RUNNING"][state]
		if (state == ERatState.RUNNING)
		{
			if (player_nearby)
				state_text = "RUNNING (PLAYER NEARBY)"
			else
				state_text = format("RUNNING (FLEEING %.1fs)", RAT_RUN_AFTER_PLAYER_DELAY - (current_time - player_last_seen_time))
		}

		local state_color = [Vector(255, 255, 0), Vector(0, 255, 0), player_nearby ? Vector(255, 0, 0) : Vector(255, 128, 0)][state]

		DebugDrawText(my_pos + Vector(0, 0, 20), state_text, true, duration)
		DebugDrawText(my_pos + Vector(0, 0, 30), "Waypoint: " + current_waypoint_index + "/" + path.len(), true, duration)
		DebugDrawText(my_pos + Vector(0, 0, 40), "Stuck: " + stuck_count, true, duration)

		if (path.len() > 0)
		{
			local prev_pos = my_pos
			for (local i = current_waypoint_index; i < path.len(); i++)
			{
				local waypoint = path[i]
				local color = (i == current_waypoint_index) ? Vector(255, 255, 0) : Vector(0, 255, 255)
				DebugDrawLine(prev_pos, waypoint, color.x, color.y, color.z, false, duration)
				DebugDrawBox(waypoint, Vector(-5, -5, -5), Vector(5, 5, 5), color.x, color.y, color.z, 100, duration)
				prev_pos = waypoint
			}
		}

		if (target_position)
		{
			DebugDrawBox(target_position, Vector(-10, -10, -10), Vector(10, 10, 10), 255, 0, 255, 100, duration)
			DebugDrawLine(my_pos, target_position, 255, 0, 255, false, duration)
		}

		DebugDrawLine(my_pos, my_pos + move_direction * 30, 255, 255, 255, true, duration)
	}

	self = null
	spawn_position = null
	move_direction = null
	state = null
	state_end_time = 0
	walk_sequence = -1
	run_sequence = -1
	idle_sequences = []
	player_nearby = false
	player_last_seen_time = 0
	path = []
	current_waypoint_index = 0
	last_path_time = 0
	target_position = null
	stuck_check_position = null
	stuck_check_time = 0
	stuck_count = 0
}

function UpdateRats()
{
	for (local i = rats.len() - 1; i >= 0; i--)
	{
		local rat = rats[i]
		if (!rat.IsValid())
		{
			rats.remove(i)
			continue
		}

		if ("rat_brain" in rat.GetScriptScope())
			rat.GetScriptScope().rat_brain.Update()
	}

	return -1
}

function OnPostSpawn()
{
	self.GetScriptScope().rat_brain <- CRat(self)
	rats.append(self)

	if (!("UpdateRats" in ai_network.GetScriptScope()))
	{
		ai_network.GetScriptScope().UpdateRats <- UpdateRats
		AddThinkToEnt(ai_network, "UpdateRats")
	}
}