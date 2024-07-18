::BOTLER_MODEL_PACK <- "models/bots/bot_worker/robot_butler_worker3.mdl";
::BOTLER_MODEL_NOPACK <- "models/bots/bot_worker/robot_butler_worker4.mdl";
::BOTLER_MODEL_DRINK <- "models/bots/bot_worker/robot_butler_worker.mdl";
::BOTLER_MODEL_PROP <- "models/bots/bot_worker/robot_butler_worker2.mdl";

PrecacheScriptSound("Embargo.RobotDown.RED");
PrecacheScriptSound("Embargo.RobotDown.BLU");
PrecacheScriptSound("Robot.Idle");
PrecacheScriptSound("Robot.Heal");

PrecacheModel(BOTLER_MODEL_PACK);
PrecacheModel(BOTLER_MODEL_NOPACK);
PrecacheModel(BOTLER_MODEL_DRINK);
propModelId <- PrecacheModel(BOTLER_MODEL_PROP);

function ThinkBotlers()
{
    local anyNewBots = false;
    for (local bot = null; bot = Entities.FindByClassname(bot, "tf_robot_destruction_robot");)
    {
        anyNewBots = true;
        bot.KeyValueFromString("classname", "tf_robot_botler");
        SetPropBool(bot, "m_bForcePurgeFixedupStrings", true);
        bot.AddFlag(Constants.FPlayer.FL_NOTARGET);
        bot.DisableDraw();

        RunWithDelay(3, function(bot)
        {
            bot.EnableDraw();
            if (bot.GetMaxHealth() >= 2000)
            {
                bot.SetModel(BOTLER_MODEL_DRINK);
                bot.SetSkin(1);
            }
            else if (bot.GetMaxHealth() >= 1000)
            {
                bot.SetModel(BOTLER_MODEL_DRINK);
                bot.SetSkin(0);
            }
            else
            {
                bot.SetModel(BOTLER_MODEL_PACK);
                bot.SetSkin(0);
                SetPropBool(bot, "m_bClientSideAnimation", false);

                bot.ValidateScriptScope();
                local botScope = bot.GetScriptScope();

                botScope.TickBotler <- TickBotler;
                botScope.ThinkSmoothMovement <- ThinkSmoothMovement;

                botScope.hasPack <- true;
                botScope.packTimerTS <- 0;
                botScope.voTimerTS <- 0;

                botScope.targetPos <- bot.GetOrigin();
                botScope.targetPos2 <- botScope.targetPos;
                botScope.targetYaw <- bot.GetAbsAngles().Yaw();
                botScope.targetYaw2 <- botScope.targetYaw;

                AddThinkToEnt(bot, "TickBotler");
            }
            bot.ResetSequence(bot.LookupSequence("idle"));
            bot.SetMaxHealth(1150);
            bot.SetHealth(1150);
        }, bot);
    }

    if (anyNewBots)
    {
        local ents = [];
        for (local ent = null; ent = Entities.FindByClassname(ent, "rd_robot_dispenser");)
            if (ent && ent.IsValid())
            {
                SetPropBool(ent, "m_bForcePurgeFixedupStrings", true);
                ents.push(ent);
            }
        foreach (ent in ents)
            ent.Kill();
    }
}

function TickBotler()
{
    ThinkSmoothMovement();

    local time = Time();

    if (time >= packTimerTS)
    {
        local minDistanceSqr = 9999999;
        local center = self.GetCenter();
        foreach(player in GetAlivePlayers())
        {
            local distanceSqr = (player.GetCenter() - center).LengthSqr();
            if (distanceSqr > 6400) //80^2
            {
                if (distanceSqr < minDistanceSqr)
                    minDistanceSqr = distanceSqr;
                continue;
            }
            if (player.GetHealth() < player.GetMaxHealth())
            {
                player.Heal(player.GetMaxHealth() * 0.5);
                EmitSoundOnClient("HealthKit.Touch", player);

                self.EmitSound("Robot.Heal");
                voTimerTS = time + RandomInt(5, 10);
                self.SetModel(BOTLER_MODEL_NOPACK);
                self.ResetSequence(self.LookupSequence("idle"));

                hasPack = false;
                RunWithDelay(10, function() {
                    self.SetModel(BOTLER_MODEL_PACK);
                    self.ResetSequence(self.LookupSequence("idle"));
                    self.EmitSound("Item.Materialize");
                    hasPack = true;
                });
                packTimerTS = time + 10;
            }
        }

        if (minDistanceSqr < 250000) //500^2
        {
            if (time >= voTimerTS && !RandomInt(0, 15))
            {
                self.EmitSound("Robot.Idle");
                voTimerTS = time + RandomInt(5, 10);
            }
            packTimerTS = time + 0.1;
        }
        else
            packTimerTS = time + 0.5;
    }

    return -1;
}

function ThinkSmoothMovement()
{
    //RD Robot NPC move at 0.1s tickrate.
    //For many players interpolation isn't configured correctly
    //resulting in stock NPC having visible jitter.
    //In this function, we fix this issue.
    self.StudioFrameAdvance();

    local origin = self.GetOrigin();
    if ((targetPos - origin).LengthSqr() > 0.001)
    {
        local newOrigin = origin;
        origin = targetPos;
        targetPos = newOrigin;
        targetPos2 = newOrigin;
    }
    local diff = targetPos2 - origin;
    diff.Norm();
    targetPos = origin + diff;

    local angles = self.GetAbsAngles();
    local yaw = angles.Yaw();
    if (abs(targetYaw - yaw) > 0.01)
    {
        local newYaw = yaw;
        yaw = targetYaw;
        targetYaw = newYaw;
        targetYaw2 = newYaw;
    }
    local diff = targetYaw2 - yaw;
    targetYaw = yaw + diff * (diff < 5 ? 0.1 : 0.2);

    self.KeyValueFromVector("origin", targetPos);
    self.KeyValueFromVector("angles", Vector(angles.Pitch(), targetYaw, angles.Roll()));
}

function OnScriptHook_OnTakeDamage(params)
{
    local bot = params.const_entity;

    //Prop dynamics with the botler model
    if (GetPropInt(bot, "m_nModelIndex") == propModelId)
    {
        if (!GetPropBool(bot, "m_bForcePurgeFixedupStrings"))
        {
            SetPropBool(bot, "m_bForcePurgeFixedupStrings", true);
            bot.KeyValueFromString("classname", "tf_robot_botler");
            bot.SetMaxHealth(1150);
            bot.SetHealth(1150);
        }
        local time = Time();
        if (time > GetPropFloat(bot, "m_flEncodedController.000"))
        {
            SetPropFloat(bot, "m_flEncodedController.000", time + 3);
            bot.EmitSound("Robot.Pain");
        }
    }

    //Both the actual RD robots and prop dynamics
    if (bot.GetClassname() == "tf_robot_botler")
    {
        local hp = bot.GetHealth();
        local newHP = hp - params.damage;
        if (newHP <= 0) newHP = 500;
        bot.SetHealth(newHP);

        if (hp > 1120 && newHP <= 1120)
        {
            local smoke = SpawnEntityFromTable("info_particle_system", {
                effect_name = "sentrydamage_4",
                origin = bot.GetOrigin() + Vector(0, 0, 42),
                start_active = 1
            })
            SetPropBool(smoke, "m_bForcePurgeFixedupStrings", true);
            EntFireByHandle(smoke, "SetParent", "!activator", -1, bot, bot);
        }

        if (newHP <= 1000)
        {
            local scope = bot.GetScriptScope();
            if (scope && scope.hasPack)
            {
                local healthKit = SpawnEntityFromTable("item_healthkit_medium", {
                    "OnPlayerTouch": "!self,Kill,,-1,-1",
                });
                healthKit.SetMoveType(5, 1);
                local forward = bot.GetForwardVector();
                healthKit.SetAbsOrigin(bot.GetCenter() + forward * 20);
                healthKit.SetVelocity(Vector(RandomFloat(-50, 50), RandomFloat(-50, 50), 250) + forward * 60);
                EntFireByHandle(healthKit, "Kill", "", 15, null, null);
            }
            ExplodeBotler(bot, params.attacker, GetPropInt(bot, "m_nModelIndex") != propModelId);
        }
    }
}

function ExplodeBotler(bot, attacker, armGib)
{
    bot.EmitSound("RD.BotDeathExplosion");
    bot.EmitSound("Robot.Death");
    DispatchParticleEffect("rd_robot_explosion", bot.GetOrigin(), Vector(0, 90, 0));
    ShootGibs(bot.GetOrigin(), bot.GetAbsAngles(), bot.GetSkin(), armGib);

    if (IsValidClient(attacker))
        RunWithDelay(1.2, function() {
            EmitSoundOnClient(self.GetTeam() == Constants.ETFTeam.TF_TEAM_RED ? "Embargo.RobotDown.RED": "Embargo.RobotDown.BLU", self);
        }, attacker);

    bot.Kill();
}

//==========================================
//Gibbing the Botlers
//==========================================

gibs <- [
    ["models/props_embargo/robot_butler_worker8.mdl", Vector(0, 0, 25), 0],
    ["models/props_embargo/robot_butler_worker6.mdl", Vector(0, 0, 18), 0],
    ["models/props_embargo/robot_butler_worker7.mdl", Vector(0, 0, 5), 0],
    ["models/props_embargo/robot_butler_worker9.mdl", Vector(0, 0, 40), 1],
    ["models/player/gibs/gibs_gear3.mdl", Vector(0, 0, 25), 2],
    ["models/player/gibs/gibs_gear3.mdl", Vector(0, 0, 25), 2]
];
foreach (gib in gibs)
    PrecacheModel(gib[0]);

function ShootGibs(origin, angles, skin, armGib)
{
    local gibSpawner, gib;
    for (local i = armGib ? 0 : 1; i < gibs.len(); i++)
    {
        gib = gibs[i];
        gibSpawner = SpawnEntityFromTable("env_shooter",
        {
            spawnflags = 5,
            m_iGibs = 1,
            m_flVelocity = gib[2] ? 800 : 300,
            scale = 1,
            m_flVariance = gib[2] == 1 ? 0.3 : 3,
            m_flGibLife = 8,
            shootsounds = 3,
            simulation = 1,
            skin = skin,
            nogibshadows = true,
            origin = origin + gib[1],
            angles = "-80 -80 -80",
            gibangles = angles + QAngle(10, 180, 10),
            shootmodel = gib[0]
        });
        SetPropBool(gibSpawner, "m_bForcePurgeFixedupStrings", true);
        EntFireByHandle(gibSpawner, "Shoot", "", -1, null, null);
        EntFireByHandle(gibSpawner, "Kill", "", 0.2, null, null);
    }
}