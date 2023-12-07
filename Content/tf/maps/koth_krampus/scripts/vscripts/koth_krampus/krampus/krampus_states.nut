//=========================================================================
//Copyright LizardOfOz.
//=========================================================================

class State
{
    tick = 0;
    prevAnimCycle = 0;
    name = "error";

    function StartInner()
    {
        Start();
        prevAnimCycle = krampus.GetCycle();
    }

    function ThinkInner()
    {
        local animCycle = krampus.GetCycle();
        Think();
        tick++;
        if (tick == 1000)
            tick = 0;
        if (animCycle < prevAnimCycle)
            AnimCycleReset();
        prevAnimCycle = animCycle;
    }

    function Start() { }
    function Think() { }
    function AnimCycleReset() { }
}

IncludeScript("koth_krampus/krampus/states/enter.nut");
IncludeScript("koth_krampus/krampus/states/run.nut");
IncludeScript("koth_krampus/krampus/states/attack.nut");
IncludeScript("koth_krampus/krampus/states/death.nut");

state <- PreEnterState();

function SetState(newState)
{
    state = newState;
    newState.StartInner();
}

function IsActive()
{
    return krampus && krampus.IsValid() && state.name != "enter" && state.name != "death";
}

function IsDying()
{
    return krampus && krampus.IsValid() && state.name == "death";
}