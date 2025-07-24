// set this to the animation you want
animation_name <- "open";

// idle animation (if available. leave as empty otherwise)
animation_name_idle <- "idle";

animation_seq <- 0;
animation_idle <- 0;
animation_length <- 0;

animate <- false;

function Init() {
	NetProps.SetPropBool(self, "m_bClientSideAnimation", false);
	if(!("LookupSequence" in self)) return;
	animation_seq = self.LookupSequence(animation_name);
	animation_idle = self.LookupSequence(animation_name_idle);
	animation_length = self.GetSequenceDuration(animation_seq);

    self.AddEFlags(131072)	
    self.ResetSequence(animation_idle);
    self.SetCycle(0);
}

function StartAnimation() {
    self.ResetSequence(animation_seq);
    self.SetCycle(0);
	animate = true;
}

function Think() {
	if(animate && self.GetCycle() < 1.0) {
		self.StudioFrameAdvance();
	}
	return -1;
}

EntFireByHandle(self, "CallScriptFunction", "Init", 1, null, null);