//=========================================================================
//Script by LizardOfOz. Gamemode by LizardOfOz and Will Alfred.
//=========================================================================

//=========================================================================
//Config Values. Edit Here.
//=========================================================================

ROUND_TIMES <- [ //key - amount of players; value - timer length
    [0.0, 120.0],
    [12.0, 120.0],
    [24.0, 60.0],
    [50.0, 25.0],
    [100.0, 10.0],
    [1000.0, 10.0]
];

CART_ROLLBACK_DELAY <- 0; //Seconds until the cart starts rolling back. 0 = disabled.

CART_ROLLBACK_SPEED <- [
    0,    //UNASSIGNED
    0,    //SPECTATOR
    0.2,  //RED
    -0.2, //BLU
    0,    //TEAM4
    0     //BOSS
];

CART_SPEED <- [
    [],                     //UNASSIGNED
    [],                     //SPECTATOR
    [-0, -0.5, -0.75, -1],  //RED
    [0, 0.5, 0.75, 1],      //BLU
    [],                     //TEAM4
    []                      //BOSS
];

//=========================================================================
//Setting up the capture zones, capture points, and the cart
//Don't edit anything below unless you know what you're doing
//=========================================================================

//!CompilePal::IncludeDirectory("resource/tug_of_war")
//!CompilePal::IncludeDirectory("materials/tug_of_war")

::main_script <- this;

if (!("MAX_CLIENTS" in getroottable()))
{
    local root_table = getroottable();
    ::MAX_CLIENTS <- MaxClients().tointeger();

    //Thanks Ficool2 for the idea.
    foreach (k, v in ::NetProps.getclass())
        if (k != "IsValid")
            root_table[k] <- ::NetProps[k].bindenv(::NetProps);

    foreach (_, cGroup in Constants)
        foreach (k, v in cGroup)
            root_table[k] <- v != null ? v : 0;
}

try { IncludeScript("tug_of_war_addons/preload.nut"); } catch(e) { }

//=========================================================================
//Setting up the capture zones, capture points, and the cart.
//=========================================================================

tf_gamerules <- Entities.FindByClassname(null, "tf_gamerules");
tf_objective_resource <- Entities.FindByClassname(null, "tf_objective_resource");
team_train_watcher <- Entities.FindByClassname(null, "team_train_watcher");

cart_moving_point <- null;
cart_trucktrain <- null;

cartPointIndex <- 0;
rollBackTeam <- 0;
nextRollbackTS <- Time() + 999999;
prevSpeed <- 0;

function InitPayloadCart()
{
    cart_trucktrain = Entities.FindByName(null, GetPropString(team_train_watcher, "m_iszTrain"));

    for (local ent = null; ent = Entities.FindByClassname(ent, "trigger_capture_area");)
    {
        local pointName = GetPropString(ent, "m_iszCapPointName");
        local point = Entities.FindByName(null, pointName);
        if (GetPropInt(point, "m_iDefaultOwner") > 1)
            continue;

        cart_moving_point = point;
        cartPointIndex = GetPropInt(cart_moving_point, "m_iPointIndex");
    }
    CreateToWThinker();
}
EntFireByHandle(self, "RunScriptCode", "InitPayloadCart()", 0, null, null);

function ProcessSpeedAndRollback()
{
    local cartOwnerTeam = cart_moving_point.GetTeam();
    if (cartOwnerTeam == 0)
        return;

    local time = Time();

    local capSpeedBlue = GetPropIntArray(tf_objective_resource, "m_iNumTeamMembers", 24 + cartPointIndex);
    local capSpeedRed = GetPropIntArray(tf_objective_resource, "m_iNumTeamMembers", 16 + cartPointIndex);
    local capSpeed = clampCeiling(3, max(capSpeedRed, capSpeedBlue));

    if (CART_ROLLBACK_DELAY > Epsilon && (capSpeed > 0.1 || GetPropBoolArray(tf_objective_resource, "m_bBlocked", cartPointIndex)))
    {
        nextRollbackTS = time + CART_ROLLBACK_DELAY;
        rollBackTeam = 0;
    }
    local speed;
    if (nextRollbackTS < time)
    {
        rollBackTeam = cartOwnerTeam;
        speed = CART_ROLLBACK_SPEED[rollBackTeam];
    }
    else
    {
        local pushingTeam = capSpeedRed > capSpeedBlue ? TF_TEAM_RED : TF_TEAM_BLUE;
        speed = pushingTeam == cartOwnerTeam
            ? CART_SPEED[cartOwnerTeam][clampCeiling(3, capSpeed)]
            : 0;
    }
    if (prevSpeed != speed)
    {
        EntFireByHandle(cart_trucktrain, "SetSpeedDirAccel", speed.tostring(), 0, null, null);
        prevSpeed = speed;
    }
}

//=========================================================================
//KOTH Timer that scales with player count
//=========================================================================

function ScaleTimerWithPlayerCount()
{
    local playercount = 0;
    if (IsMatchTypeCasual() || IsInWaitingForPlayers())
        playercount = 24;
    else
        for (local i = 1; i <= MAX_CLIENTS; i++)
            if (PlayerInstanceFromIndex(i))
                playercount++;

    local i = 1;
    for (; playercount > ROUND_TIMES[i][0]; i++);

    local low = ROUND_TIMES[i - 1];
    local high = ROUND_TIMES[i];

    local timeLength = remap(playercount, low[0], high[0], low[1], high[1]).tostring();
    foreach(timer in [GetPropEntity(tf_gamerules, "m_hRedKothTimer"), GetPropEntity(tf_gamerules, "m_hBlueKothTimer")])
    {
        EntFireByHandle(timer, "SetTime", timeLength, 0, null, null);
        EntityOutputs.AddOutput(timer,
            "On10SecRemain",
            "WarningAlarm",
            "RefireTime",
            "2",
            0, -1);
    }
}
EntFireByHandle(self, "RunScriptCode", "ScaleTimerWithPlayerCount()", 0, null, null);

//=========================================================================
//HUD
//=========================================================================

Convars.SetValue("tf_rd_points_per_approach", "2525");

worldspawn <- Entities.FindByClassname(null, "worldspawn");
worldspawn.ValidateScriptScope();
worldspawn.SetTeam(TF_TEAM_BLUE);
SetPropInt(tf_gamerules, "m_nHudType", 0);
SetPropInt(tf_gamerules, "m_bOvertimeAllowedForCTF", 0);
water_lod_control <- SpawnEntityFromTable("water_lod_control", {});

pd_logic <- SpawnEntityFromTable("tf_logic_player_destruction", {
    min_points = 255,
    targetname = "pd_logic",
    finale_length = 9999,
    res_file = "resource/tug_of_war/tug_of_war_hud.res"
});
pd_logic.AcceptInput("SetPointsOnPlayerDeath", "0", null, null);
pd_logic.AcceptInput("EnableMaxScoreUpdating", "0", null, null);
pd_logic.AcceptInput("DisableMaxScoreUpdating", "0", null, null);
pd_logic.AcceptInput("setcountdowntimer", "99999", null, null);
SetPropInt(pd_logic, "m_nBluePoints", 128);
SetPropInt(pd_logic, "m_nBlueTargetPoints", 128);
SetPropInt(pd_logic, "m_nMaxPoints", 255);

prevCapSpeed <- 0;

function InitEscrowCounter()
{
    escrow_blue <- SpawnEntityFromTable("item_teamflag", {
        PointValue = 0,
        flag_model = "models/empty.mdl",
        origin = Vector(-9999, -9999, -9999),
        GameType = 6
    });
    SetPropEntity(escrow_blue, "m_hPrevOwner", worldspawn);
    SetPropInt(escrow_blue, "m_nFlagStatus", 1);

    UpdatePayloadHUD();
}
EntFireByHandle(self, "RunScriptCode", "InitEscrowCounter()", 0, null, null);

function UpdatePayloadHUD()
{
    local cartOwnerTeam = cart_moving_point.GetTeam();

    //Cart Position on the HUD
    local cartPos = GetPropFloat(team_train_watcher, "m_flTotalProgress");
    cartPos = ceil(cartPos * 254);
    SetPropInt(pd_logic, "m_nBlueTargetPoints", cartPos);

    //Set Cart's Team Color
    SetPropFloat(water_lod_control, "m_flCheapWaterStartDistance", [0, 0, 1, 2, 0, 0][cartOwnerTeam]);

    //Capture Progress Bars
    local capturingTeam = GetPropIntArray(tf_objective_resource, "m_iCappingTeam", cartPointIndex);
    local capProgressRaw = capturingTeam == 0 ? 0 : 1 - GetPropFloatArray(tf_objective_resource, "m_flCapPercentages", cartPointIndex);
    if (capProgressRaw > 0.1 && cartOwnerTeam > 1)
        capProgressRaw = capProgressRaw * capProgressRaw - 0.1 * capProgressRaw + 0.1;
    local capProgressRemapped = (capProgressRaw >= 1 || capProgressRaw <= 0.01) ? 0 : (capProgressRaw * 0.72 + 0.15);
    capProgressRemapped = ceil(capProgressRemapped * 255);

    if (capturingTeam == TF_TEAM_BLUE)
    {
        SetPropInt(escrow_blue, "m_nPointValue", capProgressRemapped - cartPos);
        SetPropInt(pd_logic, "m_nRedTargetPoints", 0);
    }
    else if (capturingTeam == TF_TEAM_RED)
    {
        SetPropInt(escrow_blue, "m_nPointValue", -cartPos);
        SetPropInt(pd_logic, "m_nRedTargetPoints", capProgressRemapped);
    }
    else
    {
        SetPropInt(escrow_blue, "m_nPointValue", -cartPos);
        SetPropInt(pd_logic, "m_nRedTargetPoints", 0);
    }

    //Capture Number Display
    //frac portion is U range from 0 to 1
    //int portion is V range from 0 to 1000
    //local texCoords = y.x
    //wait, why did I make it flipped?
    local texCoords = 1000.25;

    local capSpeedRed = GetPropIntArray(tf_objective_resource, "m_iNumTeamMembers", 16 + cartPointIndex);
    local capSpeedBlue = GetPropIntArray(tf_objective_resource, "m_iNumTeamMembers", 24 + cartPointIndex);
    local capSpeed = max(capSpeedRed, capSpeedBlue);

    if (GetPropBoolArray(tf_objective_resource, "m_bBlocked", cartPointIndex))
    {
        SetPropFloat(water_lod_control, "m_flCheapWaterEndDistance", 752.75);
        return;
    }

    if (capSpeed > 0.1)
    {
        local flag = (cartOwnerTeam == TF_TEAM_RED && capSpeedRed > 0.1) || (cartOwnerTeam == TF_TEAM_BLUE && capSpeedBlue > 0.1);
        if (flag || capturingTeam == GetPropIntArray(tf_objective_resource, "m_iTeamInZone", cartPointIndex))
        {
            texCoords = clampCeiling(8, capSpeed) - 1;
            texCoords *= 125.0;
            texCoords += capturingTeam && !flag ? 0.0 : 0.25;
        }
        if (prevCapSpeed < 0.1)
            SetPropFloat(water_lod_control, "m_flCheapWaterStartDistance", GetPropFloat(water_lod_control, "m_flCheapWaterStartDistance") + 0.1);
    }
    prevCapSpeed = capSpeed;

    local countdown = floor(Time() - nextRollbackTS + 10);
    if (countdown >= 0)
    {
        if (countdown < 7)
            texCoords = countdown * 125 + 0.5;
        else
            texCoords = (countdown - 6) * 125 + 0.75;
    }

    if (rollBackTeam == TF_TEAM_RED)
        texCoords = 620.75;
    else if (rollBackTeam == TF_TEAM_BLUE)
        texCoords = 502.75;

    SetPropFloat(water_lod_control, "m_flCheapWaterEndDistance", texCoords);
}

//=========================================================================
//Change Point Icons when the timer is ticking down
//=========================================================================
PrecacheSound("items/cart_warning_single.wav");

capture_base_blue <- null;
capture_base_red <- null;

function InitControlPoints()
{
    for (local ent = null; ent = Entities.FindByClassname(ent, "team_control_point");)
    {
        ent.KeyValueFromString("spawnflags", "4");
        if (ent.GetTeam() == TF_TEAM_BLUE)
            capture_base_blue = ent;
        else if (ent.GetTeam() == TF_TEAM_RED)
            capture_base_red = ent;

        EntityOutputs.AddOutput(ent,
            "OnCapTeam1",
            "!self",
            "RunScriptCode",
            "main_script.UpdatePointIcons()",
            0.1, -1);

        EntityOutputs.AddOutput(ent,
            "OnCapTeam2",
            "!self",
            "RunScriptCode",
            "main_script.UpdatePointIcons()",
            0.1, -1);
    }
}
EntFireByHandle(self, "RunScriptCode", "InitControlPoints()", 0, null, null);

function UpdatePointIcons()
{
    local bluePointOwner = capture_base_blue.GetTeam();
    local redPointOwner = capture_base_red.GetTeam();
    pd_logic.AcceptInput("SetCountdownImage",
        format("../tug_of_war/cart_track_%d%d", bluePointOwner, redPointOwner),
        null,
        null);
    if (bluePointOwner == redPointOwner)
    {
        EmitSoundEx({
            sound_name = "Hud.PointCaptured",
            filter_type = RECIPIENT_FILTER_GLOBAL,
            channel = 6
        });
        EmitSoundEx({
            sound_name = "items/cart_warning_single.wav",
            filter_type = RECIPIENT_FILTER_GLOBAL,
            channel = 6
        });
    }
}
EntFireByHandle(self, "RunScriptCode", "UpdatePointIcons()", 0, null, null);

//=========================================================================
//Unstucking players shoved into geometry by the cart
//=========================================================================

function LookForStuckPlayers()
{
    for (local player, i = 1; i <= MAX_CLIENTS; i++)
        if ((player = PlayerInstanceFromIndex(i)) && GetPropInt(player, "m_StuckLast") > 1)
            UnstuckPlayer(player);
}

function UnstuckPlayer(player)
{
    local myPos = player.GetOrigin() + Vector(0, 0, 12);
    local areas = {};
    NavMesh.GetNavAreasInRadius(myPos, 180, areas);
    local tpPos = null;
    local tpDist = 9999;
    foreach (area in areas)
    {
        local center = area.GetCenter() + Vector(0, 0, 32);
        if (IsSpaceFree(center, player))
        {
            local dist = (center - myPos).Length();
            if (dist < tpDist)
            {
                tpDist = dist;
                tpPos = center;
            }
        }
    }
    if (tpPos)
        player.Teleport(true, tpPos, false, QAngle(), true, Vector());
}

function IsSpaceFree(location, player)
{
    local traceTable = {
        start = location,
        end = location,
        hullmin = player.GetPlayerMins(),
        hullmax = player.GetPlayerMaxs(),
        ignore = player
    }
    TraceHull(traceTable);
    return !("enthit" in traceTable);
}

//=========================================================================
//Util
//=========================================================================

doStuck <- false;

function CreateToWThinker()
{
    local thinker = Entities.CreateByClassname("point_template");
    thinker.ValidateScriptScope();
    thinker.GetScriptScope().Think <- function()
    {
        ProcessSpeedAndRollback();
        UpdatePayloadHUD();
        if (doStuck = !doStuck)
            LookForStuckPlayers();
        return 0.1;
    }.bindenv(this);
    AddThinkToEnt(thinker, "Think");
}

clamp <- function(value, min, max)
{
    if (max < min)
    {
        local tmp = min;
        min = max;
        max = tmp;
    }
    if (value < min)
        return min;
    if (value > max)
        return max;
    return value;
}

clampCeiling <- function(valueA, valueB)
{
    return valueA < valueB ? valueA : valueB;
}
min <- clampCeiling;

clampFloor <- function(valueA, valueB)
{
    return valueA > valueB ? valueA : valueB;
}
max <- clampFloor;

remap <- function(value, low1, high1, low2, high2)
{
    return low2 + (value - low1) * (high2 - low2) / (high1 - low1);
}

//=========================================================================
//PostLoad
//=========================================================================

try { IncludeScript("tug_of_war_addons/postload.nut"); } catch(e) { }