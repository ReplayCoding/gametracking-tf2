//=========================================================================
//Copyright LizardOfOz.
//=========================================================================

::main_script_entity <- self;
::main_script <- this;

::tf_gamerules <- Entities.FindByClassname(null, "tf_gamerules");
::item_teamflag <- Entities.FindByClassname(null, "item_teamflag");
::boss_pit_exit <- Entities.FindByName(null, "boss_pit_exit").GetOrigin();
::boss_tele_dest <- Entities.FindByName(null, "boss_tele_dest");

item_teamflag.SetSize(Vector(-1,-1,-1), Vector(1,1,1));