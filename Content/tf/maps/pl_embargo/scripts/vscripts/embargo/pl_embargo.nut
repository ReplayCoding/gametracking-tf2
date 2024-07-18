ClearGameEventCallbacks();
IncludeScript("embargo/util.nut");
IncludeScript("embargo/players.nut");
IncludeScript("embargo/paint_effect.nut");
IncludeScript("embargo/sound.nut");
IncludeScript("embargo/botlers.nut");
IncludeScript("embargo/ent_fixes.nut");
__CollectGameEventCallbacks(this);

ForceEscortPushLogic(2);

function Think()
{
    ThinkBotlers();
    return ThinkTruckFix();
}
AddThinkToEnt(self, "Think");