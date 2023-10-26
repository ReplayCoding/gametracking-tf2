lastSpitTime <- Time();
spitOrigin <- self.GetOrigin();
spitAngle <- self.EyeAngles();
state <- -2;
canSlimeAttack <- true;
partnerInSlime <- null;
idling <- false;
lastPos <- self.GetCenter();

function SalmannThink()
{
    lastPos <- self.GetCenter();
    if (idling && (state == 0 || state == 5) && self.GetLocomotionInterface().IsAttemptingToMove())
    {
        self.ResetSequence(self.LookupSequence("run_MELEE"));
        idling = false;
    }
    if (!idling && (state == 0 || state == 5) && !self.GetLocomotionInterface().IsAttemptingToMove())
    {
        self.ResetSequence(self.LookupSequence("stand_MELEE"));
        idling = true;
    }

    if (!canSlimeAttack)
    {
        state = 0;
        return 0.1;
    }

    local time = Time();
    local center = self.GetCenter();
    local eyeVector = self.EyeAngles().Forward();
    eyeVector.z = 0;

    if (state == -2) //Spawning
    {
        state = -1;
        return 2.8;
    }
    if (state == -1) //Spawned
    {
        self.SetHealth(SALMANN_HEALTH);
        NetProps.SetPropFloat(self, "m_flNextAttack", 0);
        state = 0;

        if (partnerInSlime == null)
            FindPartner();
    }
    if (state == 0) //Roaming
    {
        if (self.GetLocomotionInterface().IsOnGround())
            foreach (player, dot in GetAlivePlayersInRange(center, 200, eyeVector))
                if (dot >= 0.4)
                {
                    lastSpitTime = time;
                    self.ResetSequence(self.LookupSequence("attack_slime"));
                    self.SetCycle(0);
                    spitOrigin = self.GetOrigin();
                    spitAngle = self.EyeAngles();
                    state = 1;
                    NetProps.SetPropFloat(self, "m_flNextAttack", 1);
                    return 0;
                }
        return 0.1;
    }
    else if (state == 1) //Winding Up - Swap the model
    {
        if (time > lastSpitTime + 0.25)
        {
            self.SetModelSimple(SALMANN_MODEL_SLIME_ATTACK);
            self.SetSequence(self.LookupSequence("attack_slime"));
            state = 2;
        }

        self.SetAbsOrigin(spitOrigin);
        self.SetAbsAngles(spitAngle);
        return 0;
    }
    else if (state == 2) //Winding Up - Emit the particle
    {
        if (time > lastSpitTime + 1)
        {
            local particle = SpawnEntityFromTable("info_particle_system", {
                effect_name = SPEW_PARTICLE,
                origin = self.EyePosition(),
                angles = self.EyeAngles(),
                start_active = 1
            })
            EntFireByHandle(particle, "SetParent", "!activator", 0, self, self);
            EntFireByHandle(particle, "SetParentAttachment", "mouth", 0, null, null);
            EntFireByHandle(particle, "Kill", "", 2, null, null);
            state = 3;
        }

        self.SetAbsOrigin(spitOrigin);
        self.SetAbsAngles(spitAngle);
        return 0;
    }
    else if (state == 3) //Spewing out
    {
        local spitAngleF = spitAngle.Forward();
        spitAngleF.z = 0;
        local targetDot = SPEW_DOT_PRODUCT;

        if (time < lastSpitTime + 3)
            foreach (player, dot in GetAlivePlayersInRange(center, 300, spitAngleF))
                if (dot >= targetDot)
                    ApplySlime(player, player.entindex(), SALMANN_EFFECT_DURATION, null);

        if (time > lastSpitTime + 3.5)
        {
            self.SetModelSimple(SALMANN_MODEL);
            self.SetSequence(self.LookupSequence("attack_slime"));
            state = 4;
        }

        self.SetAbsOrigin(spitOrigin);
        self.SetAbsAngles(spitAngle);
        return 0;
    }
    else if (state == 4) //Spewing out - Anim Fix
    {
        if (time > lastSpitTime + 3.7)
        {
            self.ResetSequence(self.LookupSequence("run_MELEE"));
            NetProps.SetPropFloat(self, "m_flNextAttack", 0);
            state = 5;
        }

        self.SetAbsOrigin(spitOrigin);
        self.SetAbsAngles(spitAngle);
        return 0;
    }
    else if (state == 5) //Cooldown
    {
        if (time > lastSpitTime + 15)
            state = 0;
    }

    return 0.1;
}

function FindPartner()
{
    local salmann = null;
    while (salmann = Entities.FindByClassname(salmann, "tf_zombie"))
        if (salmann != self)
        {
            local scope = salmann.GetScriptScope();
            if (scope.partnerInSlime == null)
            {
                scope.partnerInSlime <- self;
                scope.canSlimeAttack = !canSlimeAttack;
                salmann.SetHealth(SALMANN_HEALTH);
                NetProps.SetPropFloat(salmann, "m_flNextAttack", 0);
                partnerInSlime <- salmann;
                return;
            }
        }
}