// --------------------------------------------------------------------------------------- //
// Perks - Version 1.4                                                                     //
// --------------------------------------------------------------------------------------- //
// Game Design and Scripting by: Le Codex (https://steamcommunity.com/id/lecodex)          //
// Assets by: Diva Dan (https://steamcommunity.com/profiles/76561198072146551)             //
// and Tianes (https://steamcommunity.com/id/_tianes)                                      //
// --------------------------------------------------------------------------------------- //

class PerkManager {
    Team = null

    PerkPool = null
    RolledPerks = null
    ActivePerks = null

    constructor(team) {
        Team = team;

        PerkPool = clone PERK_LIST;
        RolledPerks = [];
        ActivePerks = [];
    }

    function RollPerks() {
        local amount = 3;
        
        for (local i = 1; i <= amount; i++) {
            local cls = PerkPool.remove(rand() % PerkPool.len());
            local perk = cls(Team);

            local perkInfo = {perk = perk};
            local suffix = TeamName(Team)+i;
            
            EntFireByHandle(perk.ModelTemplate, "ForceSpawnAtEntityOrigin", "perk_spawnpoint_"+suffix, 0, null, null);

            local nameOrigin = Entities.FindByName(null, "perk_name_"+suffix);
            local nameAngles = nameOrigin.GetAbsAngles();
            local nameText = SpawnEntityFromTable("point_worldtext", {
                message = perk.Name, textsize = 30, color = "255 255 255", font = 1, orientation = 1,
                origin = nameOrigin.GetOrigin() // + nameAngles.Left() * 10 * MaxLineLength(perk.Name)
            });
            perkInfo.name <- nameText;
            // nameText.SetAbsAngles(nameAngles);

            local descriptionOrigin = Entities.FindByName(null, "perk_description_"+suffix);
            local descriptionAngles = descriptionOrigin.GetAbsAngles()
            local descriptionText = SpawnEntityFromTable("point_worldtext", {
                message = perk.Description, textsize = 20, color = DESCRIPTION_COLORS[i-1], font = 0, orientation = 1,
                origin = descriptionOrigin.GetOrigin() // + descriptionAngles.Left() * 7 * MaxLineLength(perk.Description)
            });
            perkInfo.description <- descriptionText;
            // descriptionText.SetAbsAngles(descriptionOrigin.GetAbsAngles());

            RolledPerks.push(perkInfo);
        }
    }

    function Collect(index) {
        local chosenPerk = RolledPerks[index].perk;
        ActivePerks.push(chosenPerk);

        local spotName = "display_spot_"+TeamName(Team)+ActivePerks.len();
        EntFireByHandle(chosenPerk.DisplayTemplate, "ForceSpawnAtEntityOrigin", spotName, 0, null, null);
        SpawnEntityFromTable("point_worldtext", {
            message = chosenPerk.Name, textsize = 5, color = "255 255 255", font = 1, orientation = 1,
            origin = Entities.FindByName(null, spotName).GetOrigin() + Vector(0, 0, -24)
        });
        DispatchParticleEffect("pumpkin_explode", Entities.FindByName(null, spotName).GetOrigin(), Vector(0, 0, 0));

        chosenPerk.OnCollect();

        foreach (i, perkInfo in RolledPerks) {
            local prop = Entities.FindByName(null, "p_"+perkInfo.perk.Identifier+"_"+TeamName(Team)+"_prop");
            if (index == i) DispatchParticleEffect("pumpkin_explode", prop.GetOrigin(), Vector(0, 0, 0));

            EntFireByHandle(prop, "Kill", "", 0, null, null);
            perkInfo.name.Destroy();
            perkInfo.description.Destroy();
        }
        RolledPerks.clear();

        return chosenPerk;
    }

    function OnRoundStart() {
        foreach (perk in ActivePerks) perk.OnRoundStart(Team);
    }

    function OnSpawn(player) {
        foreach (perk in ActivePerks) perk.OnSpawn(player);
    }

    function OnEnemySpawn(player) {
        foreach (perk in ActivePerks) perk.OnEnemySpawn(player);
    }

    function OnDeath(player, attacker) {
        foreach (perk in ActivePerks) perk.OnDeath(player, attacker);
    }

    function OnKill(player, victim) {
        foreach (perk in ActivePerks) perk.OnKill(player, victim);
    }

    function OnPointUnlocked() {
        foreach (perk in ActivePerks) perk.OnPointUnlocked();
    }

    function OnRoundEnd() {
        foreach (perk in ActivePerks) perk.OnRoundEnd();
    }
}

::PerkManager <- PerkManager