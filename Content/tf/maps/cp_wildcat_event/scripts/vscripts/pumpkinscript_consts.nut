const TEAM_UNASSIGNED = 0

::PUMPKINMODELS <- {
	"models/player/player_jackolantern_01.mdl" : {chance = 49.9, centre = Vector(0, 0, 22)},
	"models/player/player_jackolantern_02.mdl" : {chance = 49.9, centre = Vector(0, 0, 26)},
	"models/player/player_jackolantern_03.mdl" : {chance = 0.1, centre = Vector(0, 0, 22)},
	"models/player/player_jackolantern_04.mdl" : {chance = 0.1, centre = Vector(0, 0, 22)}
}

const PUMPKINEXPLODEMODEL = "models/props_halloween/pumpkin_explode.mdl"
const PUMPKINPICKUPPOTIONMODEL = "models/wildcat_event/hwn_flask_vial_pumpkin.mdl"
const PUMPKINAPPEARSOUND = "misc/halloween/merasmus_appear.wav"
const PUMPKINAPPEARPARTICLE = "jackolantern_transform"
const PUMPKINEXPLODESOUND = "items/pumpkin_explode1.wav"
const PUMPKINSOUNDSRANGE = 512
const PUMPKINSPEED = 320
const PUMPKINSPEEDBOOSTSPEED = 448
const PUMPKINHEALTHDECREASETHRESHOLD = 50
const PUMPKINTRANSFORMATIONRANGE = 128

::WEAPONIDSTOSWITCHFROMWHENTRANSFORMING <- [239, 426, 1084, 1100]

::SKELETONGIGGLESOUNDS <- [
	"misc/halloween/skeletons/skelly_medium_01.wav",
	"misc/halloween/skeletons/skelly_medium_02.wav",
	"misc/halloween/skeletons/skelly_medium_03.wav",
	"misc/halloween/skeletons/skelly_medium_04.wav",
	"misc/halloween/skeletons/skelly_medium_05.wav",
	"misc/halloween/skeletons/skelly_medium_06.wav",
	"misc/halloween/skeletons/skelly_medium_07.wav",
	"misc/halloween/skeletons/skelly_small_01.wav",
	"misc/halloween/skeletons/skelly_small_02.wav",
	"misc/halloween/skeletons/skelly_small_03.wav",
	"misc/halloween/skeletons/skelly_small_04.wav",
	"misc/halloween/skeletons/skelly_small_05.wav",
	"misc/halloween/skeletons/skelly_small_06.wav",
	"misc/halloween/skeletons/skelly_small_07.wav",
	"misc/halloween/skeletons/skelly_small_08.wav",
	"misc/halloween/skeletons/skelly_small_09.wav",
	"misc/halloween/skeletons/skelly_small_10.wav",
	"misc/halloween/skeletons/skelly_small_11.wav",
	"misc/halloween/skeletons/skelly_small_12.wav",
	"misc/halloween/skeletons/skelly_small_13.wav",
	"misc/halloween/skeletons/skelly_small_14.wav",
	"misc/halloween/skeletons/skelly_small_15.wav",
	"misc/halloween/skeletons/skelly_small_16.wav",
	"misc/halloween/skeletons/skelly_small_17.wav",
	"misc/halloween/skeletons/skelly_small_18.wav",
	"misc/halloween/skeletons/skelly_small_19.wav",
	"misc/halloween/skeletons/skelly_small_20.wav",
	"misc/halloween/skeletons/skelly_small_21.wav",
	"misc/halloween/skeletons/skelly_small_22.wav",
]

::CRUMPKIN_INDEX <- PrecacheModel("models/props_halloween/pumpkin_loot.mdl")
::PlayerManager <- Entities.FindByClassname(null, "tf_player_manager")
