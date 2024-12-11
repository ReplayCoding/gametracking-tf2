//Script by MilkMaster72
local cameraEntity = Entities.FindByName(null, "f_camera")
local cameraFollower = Entities.FindByName(null, "f_camera_follower")
local cameraBase = Entities.FindByName(null, "f_camera_base")
local cameraIdleTarget = Entities.FindByName(null, "f_camera_idle_target")
local cameraTarget = null
local cameraFollowerSmooth = 0.25
local cameraIdleSmooth = 0.1
local fovMin = 30
local fovMax = 90
local fovSmooth = 0.2
local camFov = 1


function SetNewTarget(target)
{
    cameraTarget = target
}

function ResetTarget()
{
    cameraTarget = null
}

function Think() //EyePosition()
{
    if (cameraTarget != null)
    {
        FollowTarget()
    }
    else
    {
        Idle()
    }
}

function FollowTarget()
{
    local dir = (cameraTarget.EyePosition() - (cameraBase.GetOrigin()))
    cameraBase.SetForwardVector(dir)
    cameraFollower.SetAbsAngles(cameraFollower.GetAbsAngles() + (cameraBase.GetAbsAngles() - cameraFollower.GetAbsAngles()) * cameraFollowerSmooth)

    camFov = (camFov + (fovMin - camFov) * fovSmooth)
    cameraEntity.KeyValueFromFloat("FOV", (camFov))
}

function Idle()
{
    local dir = cameraIdleTarget.GetOrigin() - (cameraBase.GetOrigin())
    cameraBase.SetForwardVector(dir)
    cameraFollower.SetAbsAngles(cameraFollower.GetAbsAngles() + (cameraBase.GetAbsAngles() - cameraFollower.GetAbsAngles()) * cameraIdleSmooth)

    camFov = (camFov + (fovMax - camFov) * fovSmooth)
    cameraEntity.KeyValueFromFloat("FOV", (camFov))
}