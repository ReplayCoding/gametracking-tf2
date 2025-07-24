function BuildSpeedThink() {
    // only affect buildings not being redeployed
    if (NetProps.GetPropInt(self, "m_bCarryDeploy")) {
        self.GetScriptScope().Think <- null;
        NetProps.SetPropString(self, "m_iszScriptThinkFunction", "");
        return;
    }

    if (!("dhealth" in this)) {
        this.dhealth <- NetProps.GetPropInt(self, "m_iMaxHealth");
    }

    // change this to change the health gain rate (it's a percentage, must be > 1.0)
    // ------------------------------------------------
    local build_health_increase = 2.0;
    // ------------------------------------------------

    local build_percent = NetProps.GetPropFloat(self, "m_flPercentageConstructed");
    if (build_percent >= 1.0) {
        self.GetScriptScope().Think <- null;
        NetProps.SetPropString(self, "m_iszScriptThinkFunction", "");
        return;
    }

    local health = NetProps.GetPropInt(self, "m_iHealth");
    if (health < this.dhealth) {
        NetProps.SetPropInt(self, "m_iMaxHealth", build_health_increase * this.dhealth);
    }
    else {
        NetProps.SetPropInt(self, "m_iMaxHealth", this.dhealth);
        self.GetScriptScope().Think <- null;
        NetProps.SetPropString(self, "m_iszScriptThinkFunction", "");
    }
}