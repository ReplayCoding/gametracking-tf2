// Relaxing Bath!!
// By Sarexicus, for CP_Sulfur

overheal_amount <- 15;

bath_enjoyers <- []

function OnStartTouch() {
    bath_enjoyers.push(activator);
}

function OnEndTouch() {
    bath_enjoyers.remove(bath_enjoyers.find(activator));
}

function Think() {
    foreach (player in bath_enjoyers) {
        local health = player.GetHealth()
        if(health < player.GetMaxHealth() + overheal_amount) {
            player.SetHealth(health + 1);
        }
    }
    return 0;
}