// VScript Zipline logic, for pl_redwood
// by Sarexicus. Only use with permission!

::ZIPLINE_SCRIPT_VERSION <- "1.9.0";

// attachment
::latch_tolerance_angle <- 20;      // angle (in degrees) that the player can be looking away from an endpoint to attach
::max_dist <- 128; 			        // maximum distance player can be from line to still be able to use line
::latch_dist <- 128;		        // distance from player to the visual point the zipline indicator will show
::hang_dist <- 32;                  // distance below the zipline the player will hang
::offset_dist_vertical <- 32;       // distance from a vertical zipline a player will be positioned

// speed
::zipline_speed <- 900;		        // speed player travels along horizontal ziplines
::zipline_speed_vertical <- 500;	// speed player travels along vertical ziplines
::zipline_inertia <- 1.0;           // "snapping factor" for zipline movement
::distance_threshold <- 32;         // distance to the end of a path before the player is dismounted

// dismount
::dismount_boost_mult_min <- 1.1;   // multiple of a player's maximum move speed applied when jumping to dismount at max speed
::dismount_boost_mult_max <- 1.8;   // multiple of a player's maximum move speed applied when jumping to dismount at min speed
::dismount_str <- 0.66;             // force a player is launched by when the zipline concludes (as mult of zip speed)
::jump_up_height <- 350;            // height a player "jumps" when jumping to dismount
::hook_cooldown_jump <- 0.25; 	    // time between attaching and being allowed to dismount by jumping
::hook_velocity_ramp_jump <- 0.7;   // time upon which the maximum zipline dismount strength is attained
::hook_cooldown_crouch <- 0.1; 	    // time between attaching and being allowed to dismount by crouching
::zipline_cooldown <- 1.25;         // time between dismount and being allowed to reattach

// visuals & sound
::indicator_model <- "models/props_hydro/cap_point_arrow_small.mdl";
::attachment_model <- "models/propper/redwood/zipline_pulley_01.mdl";
::hook_model <- "models/props_mining/cranehook001.mdl";
::zipline_volume <- 0.7;            // default zipline sound volume
::spy_zipline_volume_mult <- 0.3;   // invisible spies taking ziplines have the zipline volume multiplied by this value

// ---------------------------------------------------------------
// #region constants + util + math
// ---------------------------------------------------------------
zipline_tracks <- [];
zipline_endpoints <- [];

Convars.SetValue("tf_grapplinghook_prevent_fall_damage", "1");
Convars.SetValue("tf_resolve_stuck_players", "0");
::MaxPlayers <- MaxClients().tointeger();

// constants
CONTENTS_PLAYERS <- Constants.FContents.CONTENTS_MONSTER;
CONTENTS_WORLD <- Constants.FContents.CONTENTS_SOLID
CONTENTS_PLAYERS_AND_WORLD <- CONTENTS_PLAYERS | CONTENTS_WORLD;
CONTENTS_TEAM1 <- Constants.FContents.CONTENTS_TEAM1;
CONTENTS_TEAM2 <- Constants.FContents.CONTENTS_TEAM2;

BUTTONS_JUMP <- Constants.FButtons.IN_JUMP;
BUTTONS_CROUCH <- Constants.FButtons.IN_DUCK;
RAD2DEG <- 360.0 / (PI * 2);

function CheckSpaceFree(player, loc, mask = null) {
    local trace_table = {
        start = loc,
        end = loc,
        hullmin = player.GetBoundingMins(),
        hullmax = player.GetBoundingMaxs(),
        ignore = player
    }
    if(mask != null) trace_table.mask <- mask;
    TraceHull(trace_table);
    return !trace_table.hit;
}

function CheckHitboxOverlapAtLocation(loc, player1, player2)
{
    local xmins = loc + player1.GetBoundingMins();
    local xmaxs = loc + player1.GetBoundingMaxs();
    local ymins = player2.GetOrigin() + player2.GetBoundingMins();
    local ymaxs = player2.GetOrigin() + player2.GetBoundingMaxs();
    return (xmins.x <= ymaxs.x && xmaxs.x >= ymins.x) && (xmins.y <= ymaxs.y && xmaxs.y >= ymins.y) && (xmins.z <= ymaxs.z && xmaxs.z >= ymins.z);
}

function CheckHitEnemyTeam(player, loc) {
    local team = player.GetTeam() == 2 ? 3 : 2;
    for (local i = 1; i <= MaxPlayers; i++)
    {
        local pl = PlayerInstanceFromIndex(i);
        if (pl == null || pl.GetTeam() != team) continue;
        if(NetProps.GetPropInt(pl, "m_lifeState") != 0) continue;
        if(CheckHitboxOverlapAtLocation(loc, player, pl)) return pl;
    }

    return null;
}


function max(a, b) { return a > b ? a : b; }
function min(a, b) { return a < b ? a : b; }
function vectriple(a) { return Vector(a, a, a); }
function clamp(v, min, max) { return (v < min) ? min : (v > max) ? max : v; }

function Distance(a, b) { return (b-a).Length(); }
function DistanceFlat(a, b) {
    local c = Vector(a.x, a.y, b.z);
    return (b-c).Length();
}

function Lerp(a, b, t) { return a + ((b-a) * t); }
function MoveTowards(a, b, amount) {
    local dir = (b-a);
    dir.Norm();
    return a + (dir * amount);
}

function VectorAngles(forward)
{
	local yaw, pitch;
	if (forward.y == 0.0 && forward.x == 0.0)
	{
		yaw = 0.0;
		if (forward.z > 0.0)
			pitch = 270.0;
		else
			pitch = 90.0;
	}
	else
	{
		yaw = (atan2(forward.y, forward.x) * 180.0 / PI);
		if (yaw < 0.0) yaw += 360.0;

		pitch = (atan2(-forward.z, forward.Length2D()) * 180.0 / PI);
		if (pitch < 0.0) pitch += 360.0;
	}

	return QAngle(pitch, yaw, 0.0);
}

function PointClosestToLine(point, start, end) {
    local D = (end - start) * (1/Distance(end, start));
    local V = point - start;

    local t = V.Dot(D);

    local P = start + (D * t);
    return P;
}

function AngleBetween(angle, start, end) {
    local vec1 = angle;
    local vec2 = end - start;
    vec2.Norm();
    return acos(vec1.Dot(vec2) / (vec1.Norm() * vec2.Norm()));
}

function LineProximity(point, angle, start, end) {
    local A = point;
    local B = point + (angle * 2048);
    local C = start;
    local D = end;

    local U = B - A;
    local V = D - C;
    local W = A - C;

    local a = U.Dot(U);
    local b = U.Dot(V);
    local c = V.Dot(V);
    local d = U.Dot(W);
    local e = V.Dot(W);

    local denominator = (a * c) - (b * b);
    if(denominator <= 0.01) return 0;

    local s = ((b * e) - (c * d)) / denominator;
    local t = ((a * e) - (b * d)) / denominator;
    s = clamp(s, 0.0, 1.0);
    t = clamp(t, 0.0, 1.0);

    local c1 = A + (U*s);
    local c2 = C + (V*t);
    return (c1-c2).Length();
}

function AngleToLine(point, angle, start, end) {
    local EPSILON = 0.0001;
    local L = end - start;
    local B = start - point;

    local vl = angle.Dot(L);
    local vb = angle.Dot(B);

    local bb = B.Dot(B);
    local bl = B.Dot(L);
    local ll = L.Dot(L);

    local de = (vl * bl) - (vb - ll);
    local c = [0.0, 1.0];

    if(abs(de) > EPSILON) {
        local ts = ((vb * bl) - (vl * bb)) / de;
        if(ts >= 0 && ts <= 1) {
            c.push(ts);
        }
    }
}


function ClampToLine(point, start, end) {
    if(Distance(start, point) > Distance(start, end)) {
        return end;
    }
    if(Distance(end, point) > Distance(start, end)) {
        return start;
    }
    return point;
}

function SafeDeleteFromScope(scope, value) {
    if(value in scope && scope[value] != null && scope[value].IsValid()) {
        scope[value].Destroy();
    }
    scope[value] <- null;
}

function CreateAndParentModelToPlayer(player, worldModelIndex)
{
    local parented_model = Entities.CreateByClassname("tf_wearable");
    parented_model.Teleport(true, player.GetOrigin(), true, player.GetAbsAngles(), false, Vector());
    NetProps.SetPropInt(parented_model, "m_nModelIndex", GetModelIndex(worldModelIndex));
    NetProps.SetPropBool(parented_model, "m_bValidatedAttachedEntity", true);
    NetProps.SetPropBool(parented_model, "m_AttributeManager.m_Item.m_bInitialized", true);
    NetProps.SetPropEntity(parented_model, "m_hOwnerEntity", player);
    NetProps.SetPropBool(parented_model, "m_bForcePurgeFixedupStrings", true);
    parented_model.SetOwner(player);
    parented_model.DispatchSpawn();
    parented_model.AcceptInput("SetParent", "!activator", player, player);
    NetProps.SetPropString(parented_model, "m_iClassname", "non_preserved");
    return parented_model;
}

// #endregion
// ---------------------------------------------------------------

// ---------------------------------------------------------------
// #region attach
// ---------------------------------------------------------------

function CreateZiplineIndicator(player, attachment_point) {
    local proxy_entity = Entities.CreateByClassname("obj_teleporter");
    proxy_entity.SetAbsOrigin(attachment_point);
    proxy_entity.DispatchSpawn();

    NetProps.SetPropBool(proxy_entity, "m_bForcePurgeFixedupStrings", true);
    NetProps.SetPropInt(proxy_entity, "m_fEffects", Constants.FEntityEffects.EF_NOSHADOW); // disable shadow
    proxy_entity.SetModel(indicator_model);
    proxy_entity.SetSkin(player.GetTeam() == 2 ? 0 : 1);
    proxy_entity.SetModelScale(0.5, 0.0);
    NetProps.SetPropInt(proxy_entity, "m_nRenderMode", 1);
    proxy_entity.AcceptInput("Alpha", "200", null, null);


    // prevents the entity from disappearing
    proxy_entity.AddEFlags(Constants.FEntityEFlags.EFL_NO_THINK_FUNCTION);
    proxy_entity.SetSolid(Constants.ESolidType.SOLID_NONE);

    // "blueprint" so it doesn't show for other players
    NetProps.SetPropBool(proxy_entity, "m_bPlacing", true);

    // sets "attachment" flag, prevents entity being snapped to player feet
    NetProps.SetPropInt(proxy_entity, "m_fObjectFlags", 2);

    NetProps.SetPropEntity(proxy_entity, "m_hBuilder", player);

    return proxy_entity;
}

function RopeSyntax(slack, width, texture_width = 4, preserved = false, texture = "cable/cable.vmt") {
    return {
        "Slack": slack,
        "Width": width,
        "Type": 0,
        "TextureScale": texture_width,
        "RopeMaterial": texture,
        "Subdiv": 2,
        "spawnflags": 0,
        "Type": 0,
        "Collide": 0,
        "Dangling": 0,
        "NoWind": 0,
        "PositionInterpolator": 2,
        "classname": "info_teleport_destination"
    }
}

function CreateRopeGroup(targetname_start, origins, looped = false, syntax = null) {
    local ids = "abcdefghijklmnopqrstuvwxyz";

    local rope_output = {};
    if (syntax == null) {
        syntax = RopeSyntax(0, 1, 1, false);
    }

    for (local i = 0; i < origins.len(); i++) {
        local out = {};
        foreach(k, v in syntax) { out[k] <- v; }

        out["targetname"] <- targetname_start + i.tostring();
        if(i > 0) out["NextKey"] <- targetname_start + (i-1).tostring();
        out["origin"] <- origins[i];

        rope_output[ids.slice(i, i + 1)] <- {
            "keyframe_rope": out
        };
    }

    return SpawnEntityGroupFromTable(rope_output);
}

function CreateRopes(scope, parentA, parentB) {
    local tgtn = UniqueString("zipline_rope");
    CreateRopeGroup(tgtn, [parentA.GetOrigin(), parentB.GetOrigin()]);
    local ropeA = Entities.FindByName(null, tgtn + "0");
    local ropeB = Entities.FindByName(null, tgtn + "1");
    ropeA.AcceptInput("SetParent", "!activator", parentA, null);
    NetProps.SetPropBool(ropeA, "m_bForcePurgeFixedupStrings", true);

    ropeB.AcceptInput("SetParent", "!activator", parentB, null);
    NetProps.SetPropBool(ropeB, "m_bForcePurgeFixedupStrings", true);

    scope.zipline_ropes.push(ropeA);
    scope.zipline_ropes.push(ropeB);

    return [ropeA, ropeB];
}

function CreateZiplineAttachment(player, attachment_point, path, next_path) {
    // don't do zip attachments for high-player-count servers (for edict / perf reasons)
    if(MaxPlayers > 32) return;

    local isInvisibleSpy = (player.GetPlayerClass() == Constants.ETFClass.TF_CLASS_SPY && player.IsFullyInvisible());
    if(isInvisibleSpy) return;

    local scope = player.GetScriptScope();
    if(scope.zipline_is_vertical) return;

    local dir = (path.GetOrigin() - next_path.GetOrigin());
    dir.Norm();

    local zipline_pulley = SpawnEntityFromTable("prop_dynamic", {
        "targetname": "test_attach",
        "origin": attachment_point,
        "angles": VectorAngles(dir),
        "model": attachment_model,
        "solid": 0
    });
    NetProps.SetPropBool(zipline_pulley, "m_bForcePurgeFixedupStrings", true);


    local zip_parent = CreateAndParentModelToPlayer(player, "models/empty.mdl");
    zip_parent.AcceptInput("SetParent", "!activator", player, player);
    zip_parent.AcceptInput("SetParentAttachment", "flag", null, null);

    if(!scope.zipline_is_vertical) {
        local ropesA = CreateRopes(scope, zip_parent, zipline_pulley);
        local ropesB = CreateRopes(scope, zip_parent, zipline_pulley);

        local dir_2 = scope.zipline_is_forward ? -1 : 1;
        ropesA[0].SetLocalOrigin(Vector(-0, 0, 32));
        ropesB[0].SetLocalOrigin(Vector(-0, 0, 32));
        ropesA[1].SetLocalOrigin(Vector(dir_2 * 3, 0, 0));
        ropesB[1].SetLocalOrigin(Vector(dir_2 * 13, 0, 0));
    }

    scope.zipline_model_parent <- zip_parent;
    scope.zipline_model_pulley <- zipline_pulley;
}

function PlayZiplineAttachStartEnd(player, path, next_path) {
    PlaySoundAt(player, path.GetOrigin(), "ChainLink.ImpactSoft", 6, 0.2, 80);
    PlaySoundAt(player, next_path.GetOrigin(), "ChainLink.ImpactSoft", 6, 0.2, 80);
}

function SetupZiplineAndAttach(player, path, next_path, nearest_point, attachment_point, move_forward, is_vertical) {
    player.SetMoveType(Constants.EMoveType.MOVETYPE_NONE, Constants.EMoveCollide.MOVECOLLIDE_DEFAULT);

    local scope = player.GetScriptScope();

    // set offset if possible
    if(is_vertical) {
        local o_type1 = NetProps.GetPropInt(path, "m_eOrientationType");
        local o_type2 = NetProps.GetPropInt(next_path, "m_eOrientationType");
        local dir = Vector(0, 0, 0);

        if(o_type1 == 2) { dir = path.GetAbsAngles().Forward(); }
        if(o_type2 == 2) { dir = next_path.GetAbsAngles().Forward(); }

        scope.zipline_offset <- dir * -offset_dist_vertical;
    }

    local pclass = player.GetPlayerClass();
    local volume = (pclass == Constants.ETFClass.TF_CLASS_SPY && player.IsFullyInvisible()) ? spy_zipline_volume_mult * zipline_volume : zipline_volume;

    StartLoopingSoundForPlayer(player, "WeaponGrapplingHook.ReelStart", 1, volume);
    StartLoopingSoundForPlayer(player, "WeaponGrapplingHook.Wind", 1, 0.2, 110);

    scope.zipline_velocity <- player.GetAbsVelocity() + (player.GetOrigin() - nearest_point);
    player.SetAbsVelocity(vectriple(0));

    scope.prev_path <- path;
    scope.next_path <- next_path;
    scope.attachment_point <- nearest_point;
    scope.zipline_is_forward <- move_forward;

    CreateZiplineAttachment(player, nearest_point, path, next_path);
    PlayZiplineAttachStartEnd(player, path, next_path);

    // player should be counted as grappling
    player.AddCondEx(Constants.ETFCond.TF_COND_GRAPPLINGHOOK, 20, null);
    player.AddCondEx(Constants.ETFCond.TF_COND_GRAPPLINGHOOK_SAFEFALL, 20, null);
}

function CheckZiplineHooks(player) {
    local scope = player.GetScriptScope();
    local delta = Time() - scope.last_detach;

    if (NetProps.GetPropEntity(player, "m_hGroundEntity") != null && scope.attached_airborne) {
        scope.attached_airborne <- false;

        // if grounded, halve zipline cooldown
        if(delta < (zipline_cooldown/2)) scope.last_detach = Time() - (zipline_cooldown / 2);
    }

    if(delta < zipline_cooldown) return;

    local player_pos = player.GetCenter();
    local player_eye_height = player.GetClassEyeHeight();
    local hitbox_size = 8;
    local half_max_dist = max_dist * 0.5;

    foreach (track in zipline_tracks)
    {
        local next = NetProps.GetPropEntity(track, "m_pnext");
        if(!next) continue;

        local prev_pos = track.GetOrigin();
        local dist_path_to_player = Distance(prev_pos, player_pos);
        if(dist_path_to_player > 2048) continue;

        local next_pos = next.GetOrigin();
        local dist_next_to_player = Distance(next_pos, player_pos);
        if(dist_next_to_player > 2048) continue;


        local isVertical = (DistanceFlat(prev_pos, next_pos) < 64);
        if(isVertical && (dist_path_to_player > 512 && dist_next_to_player > 512)) continue;

        local P = PointClosestToLine(player_pos, prev_pos, next_pos);

        local dist_path_to_P = Distance(prev_pos, P);
        local dist_next_to_P = Distance(next_pos, P);
        local dist_path_to_next = Distance(prev_pos, next_pos);
        local max_dist_from_endpoints = dist_path_to_next + half_max_dist;

        // clamp attachment point between start and end of line segment
        if(dist_path_to_P > max_dist_from_endpoints || dist_next_to_P > max_dist_from_endpoints) continue;

        local adjusted_pos = P - player_eye_height;
        if(Distance(adjusted_pos, player_pos) > max_dist) continue;

        // determine whether the player's looking towards the start or end of this path segment
        local eyeAngle = player.EyeAngles().Forward();
        local eyePos = player.GetOrigin() + player.GetClassEyeHeight();

        local look_prev = AngleBetween(eyeAngle, eyePos, prev_pos) * RAD2DEG;
        local look_next = AngleBetween(eyeAngle, eyePos, next_pos) * RAD2DEG;

        local looking_point = (look_prev < look_next) ? prev_pos : next_pos;
        local move_forward = !(look_prev < look_next);

        // if you're close *enough* to an endpoint, go the opposite way
        local prev_is_endpoint = NetProps.GetPropEntity(track, "m_pprevious") == null || NetProps.GetPropEntity(track, "m_pnext") == null;
        local next_is_endpoint = NetProps.GetPropEntity(next, "m_pprevious") == null || NetProps.GetPropEntity(next, "m_pnext") == null;
        if(Distance(player_pos, prev_pos) < 192 && prev_is_endpoint) {
            move_forward = true;
            looking_point = next_pos;
        }
        if(Distance(player_pos, next_pos) < 192 && next_is_endpoint) {
            move_forward = false;
            looking_point = prev_pos;
        }

        local furtherPoint = MoveTowards(P, looking_point, latch_dist);
        furtherPoint = ClampToLine(furtherPoint, prev_pos, next_pos);

        local lookThreshold = latch_tolerance_angle;

        // if they're close, give a higher tolerance
        local right_next_to_endpoint = dist_path_to_player < (max_dist * 0.75) || dist_next_to_player < (max_dist * 0.75);
        if(right_next_to_endpoint) lookThreshold = latch_tolerance_angle * 1.25;

        // check if player is looking directly at or close to one of the endpoints
        local primaryLookCheck = (look_prev < lookThreshold) || (look_next < lookThreshold);

        if(!primaryLookCheck) {
            // more variation from line is allowed for verticals (harder to "look along" them)
            local lookThreshold2 = isVertical ? 30 : 10;

            // check if player is looking at somewhere on the line generally
            local prox = LineProximity(eyePos, eyeAngle, prev_pos, next_pos) / (Distance(player_pos, P) / 4) * 10;
            local secondaryLookCheck = (prox < lookThreshold2);
            if(!secondaryLookCheck) continue;
        }

        // if too close to one of the ends, don't attach
        if(Distance(furtherPoint, player_pos) < max_dist / 2 || Distance(furtherPoint, prev_pos) < 32 || Distance(furtherPoint, next_pos) < 32) continue;

        // place the zipline indicator
        //  (skip for high player counts to save edicts)
        if(MaxPlayers <= 32) {
            if(isVertical) {
                if(Distance(player_pos, P) > 40) {
                    local dest = (move_forward) ? next_pos : prev_pos;
                    local src  = (move_forward) ? prev_pos : next_pos;
                    local is_upwards = src.z > dest.z;

                    local closer = MoveTowards(P, eyePos, 16);
                    closer.z += (is_upwards) ? -0 : 32;

                    PositionZiplineIndicator(player, scope, closer, is_upwards);
                } else {
                    RemoveZiplineMarker(player, scope);
                }
            }
            else {
                PositionZiplineIndicator(player, scope, furtherPoint + Vector(0, 0, -30));
            }
        }

        scope.can_attach = true;
        local is_attaching = scope.buttons_last & BUTTONS_JUMP;
        local is_not_grounded = NetProps.GetPropEntity(player, "m_hGroundEntity") == null;

        if(!scope.attached && is_attaching && is_not_grounded) {
            scope.attached = true;

            // midair jump will engage parachute; forgivingly reset the first time
            player.RemoveCond(Constants.ETFCond.TF_COND_PARACHUTE_ACTIVE);
            if(!scope.attached_airborne) {
                player.RemoveCond(Constants.ETFCond.TF_COND_PARACHUTE_DEPLOYED);
            }

            scope.attached_airborne = true;
            scope.can_attach = false;
            scope.attach_location <- player.GetOrigin();
            scope.zipline_is_vertical <- isVertical;
            scope.last_hook <- Time();

            SetupZiplineAndAttach(player, track, next, P, furtherPoint, move_forward, isVertical);

            FireScriptEvent("zipline_attach", {
                "player": player,
                "track_prev": track,
                "track_next": next,
                "move_forward": move_forward,
                "attachment_point": P,
                "zipline_is_vertical": isVertical
            });
            return;
        }
    }
}

function PositionZiplineIndicator(player, scope, attachment_point, rotate = false) {
    if(scope.zipline_indicator == null || !scope.zipline_indicator.IsValid()) {
        scope.zipline_indicator <- CreateZiplineIndicator(player, attachment_point);
    }
    scope.zipline_indicator.SetOrigin(attachment_point);

    // rotate by model to face the right direction
    local rot = VectorAngles((player.GetOrigin() + player.GetClassEyeHeight()) - scope.zipline_indicator.GetOrigin());
    rot.z += (rotate) ? -90 : 90;
    scope.zipline_indicator.SetAbsAngles(rot);
}

// ---------------------------------------------------------------
// #endregion
// ---------------------------------------------------------------

function Think() {
    for (local i = 1; i <= MaxPlayers; i++)
    {
        local player = PlayerInstanceFromIndex(i);
        if (player == null) continue;

        // make sure they're alive first
        if(NetProps.GetPropInt(player, "m_lifeState") != 0) continue;

        local scope = player.GetScriptScope();

        if(!scope.attached) {
            scope.analysed_attach <- false;
            scope.can_attach <- false;
            CheckZiplineHooks(player);

            if(!scope.can_attach) {
                RemoveZiplineMarker(player, scope);
            }

            continue;
        }

        if(!scope.analysed_attach && (Time() - scope.last_hook > hook_cooldown_jump)) {
            scope.analysed_attach = true;
            local is_holding_jump = (scope.buttons_last & BUTTONS_JUMP);
            scope.holding_jump_to_attach <- (is_holding_jump) ? true : false;
        }

        player.AddCondEx(Constants.ETFCond.TF_COND_GRAPPLINGHOOK, 20, null);
        player.AddCondEx(Constants.ETFCond.TF_COND_GRAPPLINGHOOK_SAFEFALL, 20, null);

        ProcessZiplineMovement(player, scope);
        if(!scope.attached) continue;

        CheckZiplineReachEndpoint(player, scope);
        if(!scope.attached) continue;

        CheckPlayerDetach(player, scope);
    }

    return -1;
}


function ProcessZiplineMovement(player, scope) {
    local dest = (scope.zipline_is_forward) ? scope.next_path : scope.prev_path;
    local start = (scope.zipline_is_forward) ? scope.prev_path : scope.next_path;
    local speed = (scope.zipline_is_vertical) ? zipline_speed_vertical : zipline_speed;

    local last_point = scope.attachment_point;
    scope.attachment_point = MoveTowards(scope.attachment_point, dest.GetOrigin(), speed * FrameTime());

    local offset = scope.zipline_offset;

    local desired_pos = scope.attachment_point - player.GetClassEyeHeight() + (Vector(0, 0, -hang_dist)) + offset;
    local current_pos = player.GetOrigin();

    local pulley_point = MoveTowards(last_point, start.GetOrigin(), speed * 0.075);

    if(scope.zipline_is_vertical) {
        pulley_point = Vector(scope.attachment_point.x, scope.attachment_point.y, current_pos.z + (player.GetClassEyeHeight().z));
    }
    if(scope.zipline_model_pulley != null) scope.zipline_model_pulley.SetOrigin(pulley_point);

    local v = vectriple(0);
    if(scope.zipline_velocity.Length() > 2) {
        v = scope.zipline_velocity * FrameTime() * 4;
        scope.zipline_velocity -= v * 2;
    }
    else scope.zipline_velocity = vectriple(0);

    local alt_pos = (desired_pos - current_pos) * (FrameTime() * zipline_inertia * 12);
    local new_pos = current_pos + alt_pos + v;

    local too_recent = Time() - scope.last_hook < 0.75;
    local player_collide = CheckHitEnemyTeam(player, new_pos);
    if(player_collide == null) {
        // smooth interpolation
        // local frame = NetProps.GetPropInt(player, "m_ubInterpolationFrame");
        player.SetOrigin(new_pos);
        // NetProps.SetPropInt(player, "m_ubInterpolationFrame", frame);
    }
    else {
        // collided with an enemy player!
        PlaySoundAt(player, player.GetOrigin(), "Flesh.StepRight", 6, 0.9, 100);
        PlaySoundAt(player, scope.attachment_point, "MetalVent.ImpactHard", 6, 0.4, 120);

        FireScriptEvent("zipline_player_collide", {
            "player": player,
            "other_player": player_collide,
            "collision_point": new_pos
        })

        DetachPlayerHook(player, scope, false);
    }
}

// ---------------------------------------------------------------
// #region detach
// ---------------------------------------------------------------

function CheckZiplineReachEndpoint(player, scope) {
    local not_too_recent = Time() - scope.last_hook > 0.5;
    local vert = scope.zipline_is_vertical;

    // if(!not_too_recent || Distance(player.GetOrigin(), scope.attach_location) < distance_threshold * 0.75) return;
    local is_forward = scope.zipline_is_forward;

    local dest = (is_forward) ? scope.next_path : scope.prev_path;
    local src  = (is_forward) ? scope.prev_path : scope.next_path;
    local collection_distance = distance_threshold;

    local is_upwards = src.GetOrigin().z < dest.GetOrigin().z;
    local is_vert_downwards = (vert && !is_upwards);
    if(vert && !is_vert_downwards) collection_distance = 12;

    local endpoint_distance = Distance(dest.GetOrigin(), scope.attachment_point);
    local desired_pos = scope.attachment_point - player.GetClassEyeHeight() + (Vector(0, 0, -hang_dist));
    local origin_endpoint_distance = Distance(dest.GetOrigin(), desired_pos);

    local current_zip_duration = Time() - scope.last_hook;
    if(endpoint_distance < 128 || current_zip_duration < 0.4) {
        if(!CheckSpaceFree(player, player.GetOrigin(), CONTENTS_WORLD)) {
            // don't continue to visually clip into the world where possible
            scope.zipline_velocity = vectriple(0);

            // check if you're near the end but stuck in the world based on velocity or something
            if(current_zip_duration > 1.0) {
                DismountVelocity(player, scope, dest, src);
                DetachPlayerHook(player, scope, false);
            }
            return;
        }
    }

    if(is_vert_downwards && origin_endpoint_distance > collection_distance) return;
    if(!is_vert_downwards && endpoint_distance > collection_distance) return;

    // transfer to track along path if available
    local dest_next = NetProps.GetPropEntity(dest, "m_pnext");
    if(is_forward && (dest_next != null)) {
        scope.prev_path = dest;
        scope.next_path = dest_next;
        RealignPulley(scope);
        return;
    }
    local dest_prev = NetProps.GetPropEntity(dest, "m_pprevious");
    if(!is_forward && (dest_prev != null)) {
        scope.prev_path = dest_prev;
        scope.next_path = dest;
        RealignPulley(scope);
        return;
    }

    DismountVelocity(player, scope, dest, src);

    // actually do the detach
    DetachPlayerHook(player, scope, false);
}

function RealignPulley(scope) {
    if(scope.zipline_model_pulley == null || !scope.zipline_model_pulley.IsValid()) return;
    local dir = (scope.prev_path.GetOrigin() - scope.next_path.GetOrigin());
    dir.Norm();
    scope.zipline_model_pulley.SetAbsAngles(VectorAngles(dir));
}

function DismountVelocity(player, scope, dest, src) {
    local vert = scope.zipline_is_vertical;
    local is_upwards = src.GetOrigin().z < dest.GetOrigin().z;
    local is_vert_downwards = (vert && !is_upwards);

    // determine which way to send player
    local orientation_type = NetProps.GetPropInt(dest, "m_eOrientationType");
    local dir = Vector(0, 0, 0);

    if(orientation_type == 2) {
        dir = dest.GetAbsAngles().Forward();
    }
    else if(!vert) {
        dir = dest.GetOrigin() - src.GetOrigin();
        dir.Norm();
    }

    // suppress air control to make dismounts easier
    player.AddCustomAttribute("increased air control", 0.01, 0.5);
    player.StunPlayer(0.25, 1, 1, null);

    // give them a boost if they need it
    local player_speed = NetProps.GetPropFloat(player, "m_flMaxspeed");
    local speed = vert ? scope.zipline_speed_vertical : scope.zipline_speed;
    local dismount_vel = dir * (dismount_str * speed);

    // if particularly far down, move the player to the right spot (making sure to prevent stuck)
    if(vert && is_upwards) {
        local tracestart = dest.GetOrigin() - player.GetClassEyeHeight() - Vector(0, 0, 32);
        if(CheckSpaceFree(player, tracestart, CONTENTS_WORLD)) {
            player.SetOrigin(tracestart);
        }
    }

    player.SetAbsVelocity(dismount_vel);
}

function CheckPlayerDetach(player, scope) {
    local attach_time = Time() - scope.last_hook;

    local jump_disengage = (scope.holding_jump_to_attach) ?
        (scope.buttons_released & BUTTONS_JUMP) :
        (scope.buttons_pressed & BUTTONS_JUMP);
    local is_jump_disengaging = (scope.analysed_attach && jump_disengage && attach_time > hook_cooldown_jump);

    local crouch_disengage = (scope.buttons_pressed & Constants.FButtons.IN_DUCK);
    local is_crouch_disengaging = (crouch_disengage && attach_time > hook_cooldown_crouch);

    if(is_jump_disengaging || is_crouch_disengaging) {
        local vert = scope.zipline_is_vertical;
        local dest = (scope.zipline_is_forward) ? scope.next_path : scope.prev_path;
        local src  = (scope.zipline_is_forward) ? scope.prev_path : scope.next_path;

        // manually recreate grapple jump
        if(jump_disengage) {
            local T = (attach_time - hook_cooldown_jump) / (hook_velocity_ramp_jump - hook_cooldown_jump);
            T = clamp(T, 0.0, 1.0);
            local jump_strength = Lerp(dismount_boost_mult_min, dismount_boost_mult_max, T);

            if(jump_up_height > 0) {
                local zip_dir = dest.GetOrigin() - src.GetOrigin();
                zip_dir.Norm();
                local player_speed =  NetProps.GetPropFloat(player, "m_flMaxspeed");

                // use mult of player speed as "existing speed" to allow a balanced boost when dismounting
                local preserved_vel = zip_dir * (player_speed * jump_strength);

                local eye_dir = player.EyeAngles().Forward();
                local vel = Vector(0, 0, jump_up_height) + (eye_dir * (player_speed * 0.25 * jump_strength));

                // prioritise forward movement when zipline is vertical
                if(vert) {
                    vel = eye_dir * (player_speed * jump_strength);
                    preserved_vel = zip_dir * (player_speed / 2);
                }

                player.SetAbsVelocity(preserved_vel + vel);
            }
        } else if(crouch_disengage) {
            local zip_dir = dest.GetOrigin() - src.GetOrigin();
            zip_dir.Norm();
            local player_speed =  NetProps.GetPropFloat(player, "m_flMaxspeed");

            // use mult of player speed as "existing speed" to allow a balanced boost when dismounting
            local preserved_vel = zip_dir * (player_speed * dismount_boost_mult_max);
            player.SetAbsVelocity(preserved_vel);
        }

        DetachPlayerHook(player, scope, true);
    }
}

function RemoveZiplineMarker(player, scope) {
    if(scope.zipline_indicator != null && scope.zipline_indicator.IsValid()) {
        scope.zipline_indicator.Destroy();
        scope.zipline_indicator <- null;
    }
}

function NudgePlayer(player) {
    local ang = player.EyeAngles();
    local up = ang.Up();
    local right = ang.Left();
    local forward = ang.Forward();
    local nudge_dirs =
    [
        up * 48.0, forward * 48.0, forward * -48.0, right * 48.0, right * -48.0,
        up * 64.0, forward * 64.0, forward * -64.0, right * 64.0, right * -64.0
    ];

    foreach(dir in nudge_dirs) {
        local newSpace = player.GetOrigin() + dir;
        if(CheckSpaceFree(player, newSpace, CONTENTS_WORLD)) {
            player.SetOrigin(newSpace);
            return true;
        }
    }
    return false;
}

function CheckUnstickPlayer(player, scope) {
    if(CheckSpaceFree(player, player.GetOrigin(), CONTENTS_WORLD)) return;

    // try put the player at the end of the zip
    if(scope.zipline_is_forward != null && scope.prev_path != null && scope.next_path != null) {
        local is_forward = scope.zipline_is_forward;
        local dest = (is_forward) ? scope.next_path : scope.prev_path;
        local src  = (is_forward) ? scope.prev_path : scope.next_path;
        local is_upwards = src.GetOrigin().z < dest.GetOrigin().z;

        local newSpace = dest.GetOrigin();
        if(!scope.zipline_is_vertical || is_upwards) newSpace = newSpace - player.GetClassEyeHeight() - Vector(0, 0, -hang_dist);
        else newSpace += Vector(0, 0, 8);

        if(CheckSpaceFree(player, newSpace, CONTENTS_WORLD)) {
            player.SetOrigin(newSpace);
            return;
        }

        if(NudgePlayer(player)) {
            return;
        }
    }
    // whoops. stuck no matter what. good bye.
    player.TakeDamageCustom(null, null, null, vectriple(0), vectriple(0), 999, Constants.FDmgType.DMG_CRUSH, Constants.ETFDmgCustom.TF_DMG_CUSTOM_TELEFRAG);
}

function RemoveZiplineAttachments(player, scope) {
    if(scope.zipline_ropes.len() > 0) {
        for(local i = scope.zipline_ropes.len(); i > 0; --i) {
            local a = scope.zipline_ropes[i-1];
            if(a != null && a.IsValid()) a.Destroy();
        }
    }
    scope.zipline_ropes = [];
    SafeDeleteFromScope(scope, "zipline_model_pulley");
    SafeDeleteFromScope(scope, "zipline_model_parent");
}

function DetachPlayerHook(player, scope, is_manual_detach = false) {
    StopLoopingSoundForPlayer(player, "WeaponGrapplingHook.ReelStart");
    StopLoopingSoundForPlayer(player, "WeaponGrapplingHook.Wind");

    if(scope.prev_path && scope.next_path) {
        PlayZiplineAttachStartEnd(player, scope.prev_path, scope.next_path);
    }

    CheckUnstickPlayer(player, scope);

    local pclass = player.GetPlayerClass();
    local volume = (pclass == Constants.ETFClass.TF_CLASS_SPY && player.IsFullyInvisible()) ? spy_zipline_volume_mult * zipline_volume : zipline_volume;

    PlaySoundForPlayer(player, "WeaponGrapplingHook.ReelStop", 6, volume);

    player.RemoveCond(Constants.ETFCond.TF_COND_GRAPPLINGHOOK);
    player.AddCondEx(Constants.ETFCond.TF_COND_GRAPPLINGHOOK_SAFEFALL, 20, player);

    FireScriptEvent("zipline_detach", {
        "player": player,
        "is_manual_detach": is_manual_detach,
        "track_prev": scope.prev_path,
        "track_next": scope.next_path,
        "move_forward": scope.zipline_is_forward,
        "detachment_point": scope.attachment_point,
        "zipline_is_vertical": scope.zipline_is_vertical
    });

    scope.attached <- false;
    scope.can_attach <- false;
    scope.zipline_is_vertical <- false;
    scope.zipline_is_forward <- false;
    scope.attach_location <- null;

    scope.prev_path <- null;
    scope.next_path <- null;
    scope.attachment_point <- null;

    RemoveZiplineAttachments(player, scope);

    scope.zipline_offset <- Vector(0,0,0);
    RemoveZiplineMarker(player, scope);

    player.SetMoveType(Constants.EMoveType.MOVETYPE_WALK, Constants.EMoveCollide.MOVECOLLIDE_DEFAULT);
    scope.last_detach <- Time();
}

// ---------------------------------------------------------------
// #endregion
// ---------------------------------------------------------------

// -----------------------------------------------------
// #region player input
// -----------------------------------------------------

function PlayerThink()
{
    // store pressed keys
	local buttons = NetProps.GetPropInt(self, "m_nButtons");
	buttons_changed = buttons_last ^ buttons;
	buttons_pressed = buttons_changed & buttons;
	buttons_released = buttons_changed & (~buttons);
	buttons_last = buttons;

	return -1;
}

// ---------------------------------------------------------------
// #endregion
// ---------------------------------------------------------------

// -----------------------------------------------------
// #region events
// -----------------------------------------------------

function CollectEventsInScope(events)
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
}

function SetupPlayer(player) {
    player.ValidateScriptScope();
    local scope = player.GetScriptScope();

    // initialise input setup early to pass to player think
    scope.buttons_last <- 0;
    scope.buttons_changed <- 0;
    scope.buttons_pressed <- 0;
    scope.buttons_released <- 0;
    scope.PlayerThink <- PlayerThink;
    AddThinkToEnt(player, "PlayerThink");

    ResetPlayer(player);
}

function ResetPlayer(player) {
    local scope = player.GetScriptScope();

    // entities
    scope.zipline_model_pulley <- null;
    scope.zipline_model_hook <- null;
    scope.zipline_ropes <- [];
    scope.zipline_indicator <- null;

    // ability
    scope.attached <- false;
    scope.can_attach <- false;
    scope.attached_airborne <- false;

    // locations
    scope.attach_location <- null;
    scope.attachment_point <- null;

    // timing
    scope.last_hook <- Time();
    scope.last_detach <- Time();

    // input
    scope.buttons_last <- 0;
    scope.buttons_changed <- 0;
    scope.buttons_pressed <- 0;
    scope.buttons_released <- 0;
    scope.analysed_attach <- false;
    scope.holding_jump_to_attach <- false;

    // status
    scope.zipline_is_vertical <- false;
    scope.zipline_is_forward <- false;
    scope.prev_path <- null;
    scope.next_path <- null;
    scope.zipline_velocity <- null;
    scope.zipline_offset <- Vector(0,0,0);

    // interactions
    scope.remove_forced_minicrit <- false;
}

function RemoveForcedMinicrit(player)
{
	local scope = player.GetScriptScope();
	if ("remove_forced_minicrit" in scope && scope.remove_forced_minicrit)
	{
		player.RemoveCond(Constants.ETFCond.TF_COND_OFFENSEBUFF);
		scope.remove_forced_minicrit = false;
	}
}

CollectEventsInScope
({
    // gamemode-defined script events
    // function OnScriptEvent_zipline_attach(params) {}
    // function OnScriptEvent_zipline_detach(params) {}
    // function OnScriptEvent_zipline_player_collide(params) {}

    function OnGameEvent_player_spawn(params)
    {
        local player = GetPlayerFromUserID(params.userid);
        if (player == null) return;

        if(params.team == 0) {
            SetupPlayer(player);
            return;
        }
    }

    function OnGameEvent_player_team(params){
        local player = GetPlayerFromUserID(params.userid);
        if (player == null) return;

        local scope = player.GetScriptScope();
        if (params.team != params.oldteam && scope.attached) {
            DetachPlayerHook(player, player.GetScriptScope(), false);
        }
        ResetPlayer(player);
    }


    function OnGameEvent_player_disconnect(params){
        local player = GetPlayerFromUserID(params.userid);
        if (player == null) return;

        local scope = player.GetScriptScope();
        if (scope.attached) {
            DetachPlayerHook(player, scope, false);
        }
    }

    function OnGameEvent_player_death(params){
        local player = GetPlayerFromUserID(params.userid);
        if (player == null) return;

        local scope = player.GetScriptScope();
        if(!scope.attached) return;

        // don't detach dead ringer procs, but act like we did
        if (params.death_flags & 32) {
            RemoveZiplineAttachments(player, scope)
            return;
        }

        DetachPlayerHook(player, scope, false);
    }

    function OnGameEvent_teamplay_round_start(params) {
        Setup();

        for (local i = 1; i <= MaxPlayers; i++) {
            local player = PlayerInstanceFromIndex(i);
            if (player == null) continue;
            ResetPlayer(player);

        }
    }

    // Force Direct Hit / Reserve Shooter interactions to work (zipline should count as "airborne")
    function OnScriptHook_OnTakeDamage(params)
	{
		local attacker = params.attacker;
		if (!attacker) return;

        local victim = params.const_entity;
        if(victim == null || !victim.IsValid()) return;
        local victim_scope = victim.GetScriptScope();
		if (!("attached" in victim_scope) || !victim_scope.attached_airborne) return;

        // if already going to minicrit, don't bother
		if (attacker.InCond(Constants.ETFCond.TF_COND_OFFENSEBUFF)) return;

        local weapon = params.weapon;
        if(weapon == null) return;
        local itemIndex = NetProps.GetPropInt(weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex");

        // hardcoded IDs for Reserve Shooter (all classes) and Direct Hit
        if(itemIndex != 415 && itemIndex != 127) return;

        // force damage to be minicrit
		if (victim.IsPlayer() || victim instanceof NextBotCombatCharacter)
		{
            local attacker_scope = attacker.GetScriptScope();
			attacker.AddCond(Constants.ETFCond.TF_COND_OFFENSEBUFF);
			attacker_scope.remove_forced_minicrit <- true;
		}
	}

    // if forced minicrit, remove it
	function OnGameEvent_player_hurt(params)
	{
		local attacker = GetPlayerFromUserID(params.attacker)
		if (!attacker) return;
		RemoveForcedMinicrit(attacker);
	}

    // if forced minicrit, remove it
	function OnGameEvent_npc_hurt(params)
	{
		local attacker = GetPlayerFromUserID(params.attacker_player)
		if (!attacker) return;
		RemoveForcedMinicrit(attacker);
	}
})

// -----------------------------------------------------
// #endregion
// -----------------------------------------------------

// -----------------------------------------------------
// #region sounds
// -----------------------------------------------------

function StartLoopingSoundForPlayer(player, sound, channel = 6, volume = 1.0, pitch = 100) {
    EmitSoundEx({
        sound_name = sound,
        origin = player.GetOrigin(),
        pitch = pitch,
        flags = 3,
        volume = volume,
        channel = channel,
        entity = player,
        filter_type = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_GLOBAL
    });
}

function StopLoopingSoundForPlayer(player, sound, channel = 6) {
    EmitSoundEx({
        sound_name = sound,
        channel = channel,
        entity = player,
        flags = 4 // SND_STOP
    });
}

function PlaySoundAt(emitting_player, origin, sound, channel = 6, volume = 1.0, pitch = 100) {
    EmitSoundEx({
        sound_name = sound,
        channel = channel,
        origin = origin,
        pitch = pitch,
        flags = 3,
        volume = volume,
        filter_type = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_GLOBAL,
        entity = emitting_player
    });
}

function PlaySoundForPlayer(player, sound, channel = 6, volume = 1.0) {
    EmitSoundEx({
        sound_name = sound,
        channel = channel,
        origin = player.GetOrigin(),
        flags = 1,
        volume = volume,
        filter_type = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_GLOBAL,
        entity = player
    });
}

// -----------------------------------------------------
// #endregion
// -----------------------------------------------------

function OnPostSpawn() {
    printl("[Zipline] Loaded zipline script v" + ZIPLINE_SCRIPT_VERSION);
}

function Precache() {
    // zipline sounds
    PrecacheScriptSound("ChainLink.ImpactSoft");

    PrecacheScriptSound("Flesh.StepRight");
    PrecacheScriptSound("MetalVent.ImpactHard");

    PrecacheScriptSound("WeaponGrapplingHook.ReelStart");
    PrecacheScriptSound("WeaponGrapplingHook.ReelStop");
    PrecacheScriptSound("WeaponGrapplingHook.Wind");

    // models
    PrecacheModel(indicator_model);
    PrecacheModel(attachment_model);
    PrecacheModel(hook_model);
}

function Setup() {
    for (local track; track = Entities.FindByName(track, "zip_*");) {
        local isEndpoint = NetProps.GetPropEntity(track, "m_pnext") == null || NetProps.GetPropEntity(track, "m_pprevious") == null;
        if (isEndpoint) {
            zipline_endpoints.push(track);
        }
        zipline_tracks.push(track);
        NetProps.SetPropBool(track, "m_bForcePurgeFixedupStrings", true);
    }
}
