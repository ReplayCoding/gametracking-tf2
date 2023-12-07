//=========================================================================
//Copyright LizardOfOz.
//=========================================================================

BOT_MODELS <- [
    "models/bots/scout/bot_scout.mdl",
    "models/bots/scout/bot_scout.mdl",
    "models/bots/sniper/bot_sniper.mdl",
    "models/bots/soldier/bot_soldier.mdl",
    "models/bots/demo/bot_demo.mdl",
    "models/bots/medic/bot_medic.mdl",
    "models/bots/heavy/bot_heavy.mdl",
    "models/bots/pyro/bot_pyro.mdl",
    "models/bots/spy/bot_spy.mdl",
    "models/bots/engineer/bot_engineer.mdl"
];

GIBS_HUMAN <- [
    ["models/player/gibs/gibs_can.mdl"],
    ["models/player/gibs/scoutgib001.mdl", "models/player/gibs/scoutgib002.mdl", "models/player/gibs/scoutgib003.mdl", "models/player/gibs/scoutgib004.mdl", "models/player/gibs/scoutgib005.mdl", "models/player/gibs/scoutgib006.mdl", "models/player/gibs/scoutgib007.mdl", "models/player/gibs/scoutgib008.mdl", "models/player/gibs/scoutgib009.mdl"],
    ["models/player/gibs/snipergib001.mdl", "models/player/gibs/snipergib002.mdl", "models/player/gibs/snipergib003.mdl", "models/player/gibs/snipergib004.mdl", "models/player/gibs/snipergib005.mdl", "models/player/gibs/snipergib006.mdl", "models/player/gibs/snipergib007.mdl"],
    ["models/player/gibs/soldiergib001.mdl", "models/player/gibs/soldiergib002.mdl", "models/player/gibs/soldiergib003.mdl", "models/player/gibs/soldiergib004.mdl", "models/player/gibs/soldiergib005.mdl", "models/player/gibs/soldiergib006.mdl", "models/player/gibs/soldiergib007.mdl", "models/player/gibs/soldiergib008.mdl"],
    ["models/player/gibs/demogib001.mdl", "models/player/gibs/demogib002.mdl", "models/player/gibs/demogib003.mdl", "models/player/gibs/demogib004.mdl", "models/player/gibs/demogib005.mdl", "models/player/gibs/demogib006.mdl"],
    ["models/player/gibs/medicgib001.mdl", "models/player/gibs/medicgib002.mdl", "models/player/gibs/medicgib003.mdl", "models/player/gibs/medicgib004.mdl", "models/player/gibs/medicgib005.mdl", "models/player/gibs/medicgib006.mdl", "models/player/gibs/medicgib007.mdl", "models/player/gibs/medicgib008.mdl"],
    ["models/player/gibs/heavygib001.mdl", "models/player/gibs/heavygib002.mdl", "models/player/gibs/heavygib003.mdl", "models/player/gibs/heavygib004.mdl", "models/player/gibs/heavygib005.mdl", "models/player/gibs/heavygib006.mdl", "models/player/gibs/heavygib007.mdl"],
    ["models/player/gibs/pyrogib001.mdl", "models/player/gibs/pyrogib002.mdl", "models/player/gibs/pyrogib003.mdl", "models/player/gibs/pyrogib004.mdl", "models/player/gibs/pyrogib005.mdl", "models/player/gibs/pyrogib006.mdl", "models/player/gibs/pyrogib007.mdl", "models/player/gibs/pyrogib008.mdl"],
    ["models/player/gibs/spygib001.mdl", "models/player/gibs/spygib002.mdl", "models/player/gibs/spygib003.mdl", "models/player/gibs/spygib004.mdl", "models/player/gibs/spygib005.mdl", "models/player/gibs/spygib006.mdl", "models/player/gibs/spygib007.mdl"],
    ["models/player/gibs/engineergib001.mdl", "models/player/gibs/engineergib002.mdl", "models/player/gibs/engineergib003.mdl", "models/player/gibs/engineergib004.mdl", "models/player/gibs/engineergib005.mdl", "models/player/gibs/engineergib006.mdl", "models/player/gibs/engineergib007.mdl"]
];

GIBS_BOTS <- [
    ["models/player/gibs/gibs_can.mdl"],
    ["models/bots/gibs/scoutbot_gib_boss_arm1.mdl", "models/bots/gibs/scoutbot_gib_boss_arm2.mdl", "models/bots/gibs/scoutbot_gib_boss_chest.mdl", "models/bots/gibs/scoutbot_gib_boss_head.mdl", "models/bots/gibs/scoutbot_gib_boss_leg1.mdl", "models/bots/gibs/scoutbot_gib_boss_leg2.mdl", "models/bots/gibs/scoutbot_gib_boss_pelvis.mdl"],
    ["models/bots/gibs/scoutbot_gib_boss_arm1.mdl", "models/bots/gibs/scoutbot_gib_boss_arm2.mdl", "models/bots/gibs/scoutbot_gib_boss_chest.mdl", "models/bots/gibs/sniperbot_gib_head.mdl", "models/bots/gibs/scoutbot_gib_boss_leg1.mdl", "models/bots/gibs/scoutbot_gib_boss_leg2.mdl", "models/bots/gibs/scoutbot_gib_boss_pelvis.mdl"],
    ["models/bots/gibs/soldierbot_gib_boss_arm1.mdl", "models/bots/gibs/soldierbot_gib_boss_arm2.mdl", "models/bots/gibs/soldierbot_gib_boss_chest.mdl", "models/bots/gibs/soldierbot_gib_boss_head.mdl", "models/bots/gibs/soldierbot_gib_boss_leg1.mdl", "models/bots/gibs/soldierbot_gib_boss_leg2.mdl", "models/bots/gibs/soldierbot_gib_boss_pelvis.mdl"],
    ["models/bots/gibs/demobot_gib_boss_arm1.mdl", "models/bots/gibs/demobot_gib_boss_arm2.mdl", "models/bots/gibs/demobot_gib_boss_leg3.mdl", "models/bots/gibs/demobot_gib_boss_head.mdl", "models/bots/gibs/demobot_gib_boss_leg1.mdl", "models/bots/gibs/demobot_gib_boss_leg2.mdl", "models/bots/gibs/demobot_gib_boss_pelvis.mdl"],
    ["models/bots/gibs/scoutbot_gib_boss_arm1.mdl", "models/bots/gibs/scoutbot_gib_boss_arm2.mdl", "models/bots/gibs/scoutbot_gib_boss_chest.mdl", "models/bots/gibs/medicbot_gib_head.mdl", "models/bots/gibs/scoutbot_gib_boss_leg1.mdl", "models/bots/gibs/scoutbot_gib_boss_leg2.mdl", "models/bots/gibs/scoutbot_gib_boss_pelvis.mdl"],
    ["models/bots/gibs/heavybot_gib_boss_arm.mdl", "models/bots/gibs/heavybot_gib_boss_arm2.mdl", "models/bots/gibs/heavybot_gib_boss_chest.mdl", "models/bots/gibs/heavybot_gib_boss_head.mdl", "models/bots/gibs/heavybot_gib_boss_leg.mdl", "models/bots/gibs/heavybot_gib_boss_leg2.mdl", "models/bots/gibs/heavybot_gib_boss_pelvis.mdl"],
    ["models/bots/gibs/pyrobot_gib_boss_arm1.mdl", "models/bots/gibs/pyrobot_gib_boss_arm2.mdl","models/bots/gibs/pyrobot_gib_boss_arm3.mdl","models/bots/gibs/pyrobot_gib_boss_chest.mdl","models/bots/gibs/pyrobot_gib_boss_chest2.mdl","models/bots/gibs/pyrobot_gib_boss_head.mdl","models/bots/gibs/pyrobot_gib_boss_leg.mdl","models/bots/gibs/pyrobot_gib_boss_pelvis.mdl",],
    ["models/bots/gibs/scoutbot_gib_boss_arm1.mdl", "models/bots/gibs/scoutbot_gib_boss_arm2.mdl", "models/bots/gibs/scoutbot_gib_boss_chest.mdl", "models/bots/gibs/spybot_gib_head.mdl", "models/bots/gibs/scoutbot_gib_boss_leg1.mdl", "models/bots/gibs/scoutbot_gib_boss_leg2.mdl", "models/bots/gibs/scoutbot_gib_boss_pelvis.mdl"],
    ["models/bots/gibs/scoutbot_gib_boss_arm1.mdl", "models/bots/gibs/scoutbot_gib_boss_arm2.mdl", "models/bots/gibs/scoutbot_gib_boss_chest.mdl", "models/bots/gibs/scoutbot_gib_boss_head.mdl", "models/bots/gibs/scoutbot_gib_boss_leg1.mdl", "models/bots/gibs/scoutbot_gib_boss_leg2.mdl", "models/bots/gibs/scoutbot_gib_boss_pelvis.mdl"]
];

foreach (gibArray in GIBS_HUMAN)
    foreach (gib in gibArray)
        PrecacheModel(gib);
foreach (gibArray in GIBS_BOTS)
    foreach (gib in gibArray)
        PrecacheModel(gib);
foreach (robotModel in BOT_MODELS)
    PrecacheModel(robotModel);

HUMAN_SCREAM <- [
    "Scout.CritDeath",
    "Scout.CritDeath",
    "Sniper.CritDeath",
    "Soldier.CritDeath",
    "Demoman.CritDeath",
    "Medic.CritDeath",
    "Heavy.CritDeath",
    "Pyro.CritDeath",
    "Spy.CritDeath",
    "Engineer.CritDeath"
];

BOMB_ALERT_RED <- [ "vo/announcer_cart_defender_finalwarning4.mp3", "vo/mvm_bomb_alerts03.mp3", "vo/mvm_bomb_alerts04.mp3", "vo/mvm_bomb_alerts05.mp3", "vo/mvm_bomb_alerts08.mp3", "vo/mvm_bomb_alerts09.mp3", "vo/mvm_bomb_alerts10.mp3", "vo/mvm_bomb_alerts11.mp3", "vo/mvm_bomb_alerts12.mp3", "vo/mvm_bomb_alerts13.mp3", "vo/mvm_bomb_alerts14.mp3" ];
BOMB_ALERT_BLU <- [ "vo/announcer_cart_attacker_warning1.mp3", "vo/announcer_cart_attacker_warning2.mp3", "vo/announcer_cart_attacker_warning4.mp3", "vo/mvm_bomb_alerts03.mp3", "vo/mvm_bomb_alerts05.mp3", "vo/mvm_bomb_alerts14.mp3" ];
CARRIER_DIED_RED <- [ "vo/mvm_bomb_back01.mp3", "vo/mvm_bomb_back02.mp3", "vo/mvm_bomb_reset01.mp3", "vo/mvm_bomb_reset02.mp3", "vo/mvm_bomb_reset03.mp3" ];

foreach (sound in HUMAN_SCREAM)
    PrecacheSound(sound);
foreach (sound in BOMB_ALERT_RED)
    PrecacheSound(sound);
foreach (sound in BOMB_ALERT_BLU)
    PrecacheSound(sound);
foreach (sound in CARRIER_DIED_RED)
    PrecacheSound(sound);

PrecacheSound("ambient/alarms/klaxon1.wav");
PrecacheSound("ambient/explosions/explode_2.wav");
PrecacheSound("^mvm/sentrybuster/mvm_sentrybuster_step_01.wav");
PrecacheSound("^mvm/sentrybuster/mvm_sentrybuster_step_02.wav");
PrecacheSound("^mvm/sentrybuster/mvm_sentrybuster_step_03.wav");
PrecacheSound("^mvm/sentrybuster/mvm_sentrybuster_step_04.wav");