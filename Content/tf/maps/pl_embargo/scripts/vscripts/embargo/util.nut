//==========================================
//Constants stuff
//==========================================

::main_script_entity <- self;
::MAX_PLAYERS <- MaxClients().tointeger();

local root_table = getroottable();
foreach (k, v in ::NetProps.getclass())
    if (k != "IsValid")
        root_table[k] <- ::NetProps[k].bindenv(::NetProps);

//==========================================
//Delayed Scheduling
//==========================================

::delays <- {};

//If you pass one more parameter than the executed function takes,
//  that parameter will be taken as the scope.
//Also, thanks Mr.Burguers and Ficool2 for help.
::RunWithDelay <- function(delay, delayedFunc, ...)
{
    local scope = delayedFunc.getinfos().parameters.len() - 1 < vargv.len()
        ? vargv.pop()
        : null;

    if (scope == null)
        scope = this;
    else if ("IsValid" in scope)
    {
        scope.ValidateScriptScope();
        scope = scope.GetScriptScope();
    }

    local tmpEnt = Entities.CreateByClassname("point_template");
    local name = tmpEnt.GetScriptId();
    local code = format("::delays.%s[0](\"%s\")", name, name);
    ::delays[name] <- [function(name)
    {
        local entry = delete ::delays[name];
        local scope = entry[3];
        if (!scope || ("self" in scope && (!scope.self || !scope.self.IsValid())))
            return;
        entry[1].acall([scope].extend(entry[2]));
    }, delayedFunc, vargv, scope.weakref()];
    SetPropBool(tmpEnt, "m_bForcePurgeFixedupStrings", true);
    SetPropString(tmpEnt, "m_iName", code);
    EntFireByHandle(main_script_entity, "RunScriptCode", code, delay, null, null);
    EntFireByHandle(tmpEnt, "Kill", null, delay, null, null);
}