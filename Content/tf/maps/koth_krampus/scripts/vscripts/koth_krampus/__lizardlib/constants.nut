//=========================================================================
//Copyright LizardOfOz.
//=========================================================================

foreach (c in [
    Constants.ETFClass,
    Constants.ETFTeam,
    Constants.FDmgType,
    Constants.ETFDmgCustom,
    Constants.EScriptRecipientFilter,
    Constants.FPlayer,
    Constants.EHudNotify
])
    foreach (k, v in c)
        getroottable()[k] <- v;

::MAX_PLAYERS <- MaxClients().tointeger();