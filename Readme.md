# MTA RC Mode
**MTA RC Mode** is a resource for [Multi Theft Auto](https://multitheftauto.com) that allows players to remote control a car. It's built as a library that exports functions so that another resource can start a player remote controlling a car.

## Features
* Remote control cars, helicopters and boats
* Remote control from the passenger seat of another car
* Retain the player in the world and render their nametag and map blip

## Exported Functions

### Server functions

#### *void* enterRcMode(*player* thePlayer, *vehicle* RcVehicle)
Puts the player in RC Mode in the vehicle.

#### *bool* isPlayerInRcMode(*player* thePlayer)
Returns true if the player is in RC Mode.

#### *void* exitRcMode(*player* thePlayer)
Ends RC Mode for the player.

#### *bool* isCameraOnRcDummy(*player* thePlayer)
Returns true if the camera is on the dummy of the player, returns false if it is on the player itself.

#### *void* setCameraOnRcDummy(*player* thePlayer, *bool* onDummy)
Sets the camera on the dummy if onDummy is true, otherwise sets it on the player.

#### *ped* getPlayerRcDummy(*player* thePlayer)
Returns the ped that is used as RC dummy for the player.

## Settings

### *bool* RcMode.preventRcPlayerFromGettingJacked
Configures whether a car that is currently being remote controlled can be jacked by another player.