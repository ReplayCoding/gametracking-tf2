function VortexThink()
{
    local vertexPos = self.GetCenter();
    foreach (player in GetAlivePlayers())
    {
        local playerPos = player.GetCenter();
        local deltaVector = vertexPos - playerPos;
        local distance = deltaVector.Norm();
        if (distance < 100)
            SendToBlackForest(player);
        else if (distance < 500
            && !(player.GetFlags() & FL_ONGROUND)
            && player.EyeAngles().Forward().Dot(deltaVector) >= 0.85
            && TraceLine(playerPos, vertexPos, krampus) > 0.95)
        {
            player.ApplyAbsVelocityImpulse(deltaVector * 30);
        }
    }
    return -1;
}

function SendToBlackForest(player)
{
    local target = player.GetTeam() == TF_TEAM_RED ? black_forest_winner : black_forest_loser;
    player.Teleport(true, target.GetOrigin(), true, target.GetAbsAngles(), true, Vector(0, 0, 0));
}

function PlaySounds()
{
    for(local i = 0; i <= 6; i += 6)
        EmitSoundEx({
            sound_name = "xmas.jingle_noisemaker",
            filter = RECIPIENT_FILTER_GLOBAL,
            entity = self,
            volume = 1,
            soundlevel = 150,
            flags = 1,
            channel = i
        });

    EmitSoundEx({
        sound_name = "Halloween.TeleportVortex.EyeballMovedVortex",
        filter = RECIPIENT_FILTER_GLOBAL,
        entity = self,
        volume = 0.35,
        soundlevel = 150,
        flags = 1,
        channel = 1
    });
}