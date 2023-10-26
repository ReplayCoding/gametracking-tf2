// --------------------------------------------------------------------------------------- //
// Perks - Version 1.4                                                                     //
// --------------------------------------------------------------------------------------- //
// Game Design and Scripting by: Le Codex (https://steamcommunity.com/id/lecodex)          //
// Assets by: Diva Dan (https://steamcommunity.com/profiles/76561198072146551)             //
// and Tianes (https://steamcommunity.com/id/_tianes)                                      //
// --------------------------------------------------------------------------------------- //

enum LIFE_STATE
{
    ALIVE = 0,
    DYING = 1,
    DEAD = 2,
    RESPAWNABLE = 3,
    DISCARDBODY = 4
}

::DESCRIPTION_COLORS <- [
    "180 255 180",
    "255 230 180",
    "255 190 255"
];

::GAMERULES <- Entities.FindByClassname(null, "tf_gamerules");
::GAME_TIMER <- Entities.FindByClassname(null, "team_round_timer");
::PLAYER_DESTRUCTION_LOGIC <- Entities.FindByClassname(null, "tf_logic_player_destruction");
::CENTRAL_CP <- Entities.FindByName(null, "cp_1");
::TRIGGER_STUN_MAKER <- Entities.FindByName(null, "mak_trigger_stun");

::PERKS_NAMES <- {
    precision = "Precision"
    haste = "Haste"
    skeleton = "Gravedigging"
    minitofull = "Conversion"
    reveal = "Reveal"
    mark = "Haunting"
    resistance = "Resistance"
    healing = "Extra Provisions"
    focus = "Stronghold"
    quickfingers = "Quickdraw"
    killcrits = "Bloodlust"
    honorable = "Honorable Combat"
    reserve = "Ammo Reserve"
    revive = "Second Chance"
    cloak = "Cloaking"
    patience = "Patience"
}

::PERKS_DESCRIPTIONS <- {
    skeleton = "When you die, you\nsummon a friendly\nskeleton!"
    haste = "You gain +10% movement speed"
    precision = "You gain +50% projectile\nspeed and reduced spread"
    minitofull = "Your mini-crits are\nnow full crits"
    reveal = "Whenever you kill an\nenemy, reveal the three\nclosest ones for 5 seconds"
    mark = "When you die, the killer\nis marked for death\nfor 6 seconds"
    resistance = "You take 10% less damage"
    healing = "All healing is 40%\nmore effective"
    focus = "Once the point unlocks,\nyou get +1 capture rate\nand +20% damage resistance"
    quickfingers = "You gain +15% faster\nfiring, reloading, and\nswitching speed"
    killcrits = "Whenever you kill an\nenemy, you gain 2\nseconds of mini-crits!"
    honorable = "Your melee weapons\ndeal double damage"
    reserve = "You gain +50% clip size\nand regenerating\nammo and metal"
    revive = "Once per round, you can\nbe revived by a Medic"
    cloak = "You start with 15\nseconds of invisibility\n(ends if you shoot)"
    patience = "You gain up to 7 health/s"
}