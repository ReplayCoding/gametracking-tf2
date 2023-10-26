// --------------------------------------------------------------------------------------- //
// Infection - Prototype v0.5.1 - Last Edited: 29/08/2023                                  //
// --------------------------------------------------------------------------------------- //
// Code By: Harry Colquhoun (https://steamcommunity.com/profiles/76561198025795825)        //
// Assets/Game Design by: Diva Dan (https://steamcommunity.com/profiles/76561198072146551) //
// --------------------------------------------------------------------------------------- //
// Since CTFBot inherits from CTFPlayer before VScripts run, we need to manually put these //
// functions in to the CTFBot class to make them functional. Mostly for debugging/testing. //
// --------------------------------------------------------------------------------------- //

::CTFBot.GiveZombieAbility      <- CTFPlayer.GiveZombieAbility;
::CTFBot.RemovePlayerWearables  <- CTFPlayer.RemovePlayerWearables;
::CTFBot.SpawnEffect            <- CTFPlayer.SpawnEffect;
::CTFBot.GiveZombieCosmetics    <- CTFPlayer.GiveZombieCosmetics;
::CTFBot.GiveZombieFXWearable   <- CTFPlayer.GiveZombieFXWearable;
::CTFBot.GiveZombieWeapon       <- CTFPlayer.GiveZombieWeapon;
::CTFBot.AddZombieAttribs       <- CTFPlayer.AddZombieAttribs;
::CTFBot.CanDoAct               <- CTFPlayer.CanDoAct;
::CTFBot.ProcessEventQueue      <- CTFPlayer.ProcessEventQueue;
::CTFBot.RemoveEventFomQueue    <- CTFPlayer.RemoveEventFomQueue;
::CTFBot.AddEventToQueue        <- CTFPlayer.AddEventToQueue;
::CTFBot.ResetInfectionVars     <- CTFPlayer.ResetInfectionVars;
::CTFBot.MakeHuman              <- CTFPlayer.MakeHuman;
::CTFBot.HowLongUntilAct        <- CTFPlayer.HowLongUntilAct;
::CTFBot.PlayZombieVO           <- CTFPlayer.PlayZombieVO;
::CTFBot.SetNextActTime         <- CTFPlayer.SetNextActTime;
::CTFBot.DestroyAllWeapons      <- CTFPlayer.DestroyAllWeapons;