------------------------------
--	Script wide used variables
------------------------------

-- When the player enters RC mode, we make them invisible and seat them in the car.
-- In their position, we spawn a ped with their skin that will keep facing the car
-- as if they were looking at it while remotely driving it.
-- This global variable is a list that stores the ped for each player.
local g_rcDummy = {}

-- The player can switch the camera between the car they're remote controlling 
-- or the dummy ped representing them.
-- This global variable is a list that stores the selection for each player.
local g_isRcCameraOnPlayer = {}

------------------------------
--	Exported functions
------------------------------

-- void enterRcMode(player, vehicle)
-- Puts the player in RC Mode in the vehicle.
function enterRcMode(player, rcVehicle)
	-- check all prerequisites for entering rc mode
	-- is arg1 an mta element?
	if not isElement(player) then
		outputDebugString(string.format("RC Mode: enterRcMode expects parameter 1 to be a player, %s given.", type(player)), 2)
		return
	end

	-- is the type of the mta element given as arg1 a player?
	if getElementType(player) ~= "player" then
		outputDebugString(string.format("RC Mode: enterRcMode expects parameter 1 to be a player, %s given.", getElementType(player)), 2)
		return
	end

	-- is arg2 an mta element?
	if not isElement(rcVehicle) then
		outputDebugString(string.format("RC Mode: enterRcMode expects parameter 1 to be a vehicle, %s given.", type(rcVehicle)), 2)
		return
	end
			
	-- is the type of the mta element given as arg2 a vehicle?
	if getElementType(rcVehicle) ~= "vehicle" then
		outputDebugString(string.format("RC Mode: enterRcMode expects parameter 1 to be a vehicle, %s given.", getElementType(rcVehicle)), 2)
		return
	end

	-- is the player given as arg1 alive?
	if isPedDead(player) then
		outputDebugString("RC Mode: enterRcMode: the player is dead and cannot control an RC vehicle.", 2)
		return
	end

	-- is the vehicle given as arg2 intact?
	if isVehicleBlown(rcVehicle) then
		outputDebugString("RC Mode: enterRcMode: The vehicle is blown and cannot be remote controled.", 2)
		return
	end

	-- is the player given as arg1 already in rc mode?
	if isPlayerInRcMode(player) then
		outputDebugString(string.format("RC Mode: enterRcMode: The player %s already is in RC mode.", getPlayerName(player)), 2)
		return
	end
	
	-- is the player given as arg1 already in the driver seat of another car or are they in the passenger seat of the vehicle given as arg2?
	if getPedOccupiedVehicleSeat(player) == 0 or rcVehicle == getPedOccupiedVehicle(player) then
		outputDebugString(string.format("RC Mode: enterRcMode: Player %s cannot remote control the vehicle they are currently driving.", getPlayerName(player)), 2)
		return
	end

	-- is the player given as arg1 in the same interior as the vehicle given in arg2?
	if getElementInterior(player) ~= getElementInterior(rcVehicle) then
		outputDebugString(string.format("RC Mode: enterRcMode: Player %s and vehicle are not in the same interior.", getPlayerName(player)), 2)
		return
	end

	-- is the player given as arg1 in the same dimension as the vehicle given in arg2?
	if getElementDimension(player) ~= getElementDimension(rcVehicle) then
		outputDebugString(string.format("RC Mode: enterRcMode: Player %s and vehicle are not in the same dimension.", getPlayerName(player)), 2)
		return
	end

	-- remember all the information on the player
	local posX, posY, posZ = getElementPosition(player)
	local rotX, rotY, rotZ = getElementRotation(player)
	local playerCar = getPedOccupiedVehicle(player)
	local seat = getPedOccupiedVehicleSeat(player)
	local dimension = getElementDimension(player)
	local playerModel = getElementModel(player)
	local health = getElementHealth(player)
	local armor = getPedArmor(player)
	
	-- remember their map blip's color and remove it
	local r, g, b, a
	local elements = getAttachedElements(player)
	if elements then
		for k,v in ipairs(elements) do
			if (getElementType(v) == "blip") then
				r, g, b, a = getBlipColor(v)
				destroyElement(v)
			end
		end
	end

	-- hide the player's name tag so it isn't obvious they're sitting in the car
	setPlayerNametagShowing(player, false)

	-- if someone else is remote controlling the car, end their remote control session or 
	-- if someone else is in the driver seat, put them in the passenger seat
	local driver = getVehicleOccupant(rcVehicle, 0)
	local passenger = getVehicleOccupant(rcVehicle, 1)
	if driver and not passenger then
		if isPlayerInRcMode(driver) then
			exitRcMode(driver)
		else
			warpPedIntoVehicle(driver, rcVehicle, 1)
		end
	end

	-- hide the player and put them in the driver seat
	setElementAlpha(player, 0)
	giveWeapon(player, 0, 0, true)

	-- create a dummy ped and apply the player's information
	local rcDummy = createPed(playerModel, posX, posY, posZ)
	g_rcDummy[player] = rcDummy
	setElementRotation(rcDummy, rotX, rotY, rotZ)
	setElementDimension(rcDummy, dimension)
	setElementHealth(rcDummy, health)
	setPedArmor(rcDummy, armor)
	giveWeapon(rcDummy, 40, 0, true)
	if r and g and b and a then
		createBlipAttachedTo(rcDummy, 0, 2, r, g, b, a)
	end

	-- if the player that enters rc mode is sitting in the passenger seat of another car, 
	-- put their dummy in that seat
	if isElement(playerCar) then
		removePedFromVehicle(player)
		warpPedIntoVehicle(rcDummy, playerCar, seat)
	end
	
	-- put the invisible player into the vehicle
	warpPedIntoVehicle(player, rcVehicle, 0)

	-- start a timer that'll update the palyer's health when their dummy gets hurt
	observeRcDummy(rcDummy, player)
	g_isRcCameraOnPlayer[player] = true

	-- store a reference to the rcDummy on the player so that the client can use it to render a nametag on it
	setElementData(player, "rcDummy", rcDummy)
end

-- bool isPlayerInRcMode(player)
-- Returns if the player is in RC Mode.
function isPlayerInRcMode(player)
	-- is arg1 an mta element?
	if not isElement(player) then
		outputDebugString(string.format("RC Mode: isPlayerInRcMode expects parameter 1 to be a player, %s given.", type(player)), 2)
		return
	end

	-- is the type of the mta element given as arg1 a player?
	if getElementType(player) ~= "player" then
		outputDebugString(string.format("RC Mode: isPlayerInRcMode expects parameter 1 to be a player, %s given.", getElementType(player)), 2)
		return
	end

	-- does a dummy ped exist for this player?
	return isElement(g_rcDummy[player])
end

-- void exitRcMode(player)
-- Ends RC mode for the player:
--   * make the player visible again
--   * remove them from the car and put them in the position of their dummy
--   * destroy their dummy
--   * remove the map blip from the dummy ped
--   * add a blip for the player back
function exitRcMode(player)
	-- is arg1 an mta element?
	if not isElement(player) then
		outputDebugString(string.format("RC Mode: exitRcMode expects parameter 1 to be a player, %s given.", type(player)), 2)
		return
	end

	-- is the type of the mta element given as arg1 a player?
	if getElementType(player) ~= "player" then
		outputDebugString(string.format("RC Mode: exitRcMode expects parameter 1 to be a player, %s given.", getElementType(player)), 2)
		return
	end

	-- is the player in rc mode? if not, we don't need to end rc mode for them
	if not isPlayerInRcMode(player) then
		outputDebugString(string.format("RC Mode: exitRcMode: Player %s is not in RC Mode.", getPlayerName(player)), 2)
		return
	end

	local rcDummy = getPlayerRcDummy(player)

	-- remember all information on the dummy ped
	local posX, posY, posZ = getElementPosition(rcDummy)
	local rotX, rotY, rotZ = getElementRotation(rcDummy)
	local playerCar = getPedOccupiedVehicle(rcDummy)
	local seat = getPedOccupiedVehicleSeat(rcDummy)
	local dimension = getElementDimension(rcDummy)
	local health = getElementHealth(rcDummy)
	local armor = getPedArmor(rcDummy)

	-- remember their map blip's color and remove it
	local r, g, b, a
	local elements = getAttachedElements(rcDummy)
	if elements then
		for k,v in ipairs(elements) do
			if (getElementType(v) == "blip") then
				r, g, b, a = getBlipColor(v)
				destroyElement(v)
			end
		end
	end
	
	-- remove the dummy ped
	destroyElement(rcDummy)

	-- apply the information to the player
	removePedFromVehicle(player)
	if isElement(playerCar) then
		-- manually set the camera target to fix an MTA bug: 
		-- It appears that the camera is not set back on the player when they're put in a passenger seat
		setCameraTarget(player, player)
		warpPedIntoVehicle(player, playerCar, seat)
	end
	setElementRotation(player, rotX, rotY, rotZ)
	setElementPosition(player, posX, posY, posZ)
	setElementDimension(player, dimension)
	setElementHealth(player, health)
	setPedArmor(player, armor)
	setElementAlpha(player, 255)
	setPlayerNametagShowing(player, true)
	if r and g and b and a then
		createBlipAttachedTo(player, 0, 2, r, g, b, a)
	end

	-- remove data stored on the dummy ped from global arrays
	g_rcDummy[player] = nil
	g_isRcCameraOnPlayer[player] = nil
	setElementData(player, "rcDummy", nil)
end

-- bool isCameraOnRcDummy(player)
-- Returns true if the camera is on the dummy of the player, returns false if it is on the player itself.
function isCameraOnRcDummy(player)
	-- is arg1 an mta element?
	if not isElement(player) then
		outputDebugString(string.format("RC Mode: isCameraOnRcDummy expects parameter 1 to be a player, %s given.", type(player)), 2)
		return
	end

	-- is the type of the mta element given as arg1 a player?
	if getElementType(player) ~= "player" then
		outputDebugString(string.format("RC Mode: isCameraOnRcDummy expects parameter 1 to be a player, %s given.", getElementType(player)), 2)
		return
	end

	return g_isRcCameraOnPlayer[player]
end

-- void setCameraOnRcDummy(player, bool)
-- Sets the camera on the dummy if onDummy is true, otherwise sets it on the player.
function setCameraOnRcDummy(player, onDummy)
	-- is arg1 an mta element?
	if not isElement(player) then
		outputDebugString(string.format("RC Mode: setCameraOnRcDummy expects parameter 1 to be a player, %s given.", type(player)), 2)
		return
	end
	
	-- is the type of the mta element given as arg1 a player?
	if getElementType(player) ~= "player" then
		outputDebugString(string.format("RC Mode: setCameraOnRcDummy expects parameter 1 to be a player, %s given.", getElementType(player)), 2)
		return
	end
			
	-- is the player in rc mode? if not, we don't have to switch the camera
	if not isPlayerInRcMode(player) then
		outputDebugString(string.format("RC Mode: setCameraOnRcDummy: Player %s is not in RC Mode.", getPlayerName(player)), 2)
		return
	end

	-- is arg2 a boolean?
	if type(onDummy) ~= "boolean" then
		outputDebugString(string.format("RC Mode: setCameraOnRcDummy expects parameter 2 to be a boolean, %s given.", type(onDummy)), 2)
		return
	end

	-- update the camera target and remember the current target
	if onDummy then
		local rcDummy = getPlayerRcDummy(player)
		setCameraTarget(player, rcDummy)
		g_isRcCameraOnPlayer[player] = true
		outputDebugString("g_isRcCameraOnPlayer["..getPlayerName(player).."] = true")
	else
		setCameraTarget(player, player)
		g_isRcCameraOnPlayer[player] = false
		outputDebugString("g_isRcCameraOnPlayer["..getPlayerName(player).."] = false")		
	end
end

-- ped getPlayerRcDummy(player)
-- Returns the ped that is used as RC dummy for the player.
function getPlayerRcDummy(player)
	-- is arg1 an mta element?
	if not isElement(player) then
		outputDebugString(string.format("RC Mode: getPlayerRcDummy expects parameter 1 to be a player, %s given.", type(player)), 2)
		return
	end 

	-- is the type of the mta element given as arg1 a player?
	if getElementType(player) ~= "player" then
		outputDebugString(string.format("RC Mode: getPlayerRcDummy expects parameter 1 to be a player, %s given.", getElementType(player)), 2)
		return
	end
	
	-- is the player in rc mode? If not then we don't have a dummy to return
	if not isPlayerInRcMode(player) then
		outputDebugString(string.format("RC Mode: Player %s is not in RC Mode.", getPlayerName(player)), 2)
		return
	end

	return g_rcDummy[player]
end

------------------------------
--	Internal functions
------------------------------

-- Update the health of a player if their dummy gets hurt.
function observeRcDummy(rcDummy, assignedPlayer)
	-- exit the "loop" if either the player or dummy are gone
	if not isElement(rcDummy) or not isElement(assignedPlayer) then
		return
	end
	
	-- outputDebugString("dummyHealth = "..getElementHealth(rcDummy))
	-- outputDebugString("playerHealth = "..getElementHealth(assignedPlayer))
	setElementHealth(assignedPlayer, getElementHealth(rcDummy))
	setPedArmor(assignedPlayer, getPedArmor(rcDummy))
	setTimer(observeRcDummy, 1000, 1, rcDummy, assignedPlayer)
end

-- If the player is being made to leave the car (i.e. from a different resource) while remote controlling a car
-- abort this, as they're not really driving the car
function abortExitingVehicle(player)
	if isPlayerInRcMode(player) and not wasEventCancelled() then
		exitRcMode(player)
		cancelEvent(true, "rcmode.preventPlayerExitingVehicleOnEnd")
	end
end
addEventHandler("onVehicleStartExit", getRootElement(), abortExitingVehicle)

-- If the setting to allow stealing a car from someone that's currently remote controlling it is enabled
-- and another player attempts to get into a car that's being remote controlled stop the remote control session.
function checkIfToAbortRcMode(enteringPlayer, seat, jacked)
	-- is arg1 an mta element?
	if not isElement(jacked) then
		return
	end

	-- is the player in rc mode or is the setting configured that players in rc mode can't have their car stolen?
	if not isPlayerInRcMode(jacked) or get("*RcMode.preventRcPlayerFromGettingJacked") then
		return
	end

	exitRcMode(jacked)
end
addEventHandler("onVehicleStartEnter", getRootElement(), checkIfToAbortRcMode)

-- If the invisible player driving the car has been killed, respawn them where their dummy ped is.
function preventRcPlayerFromDieing()
	-- is the player in rc mode?
	if not isPlayerInRcMode(source) then
		return 
	end

	local posX, posY, posZ = getElementPosition(getPlayerRcDummy(source))
	spawnPlayer(source, posX, posY, posZ)
	-- setElementHealth(source, getElementHealth(getPlayerRcDummy(source)))
	exitRcMode(source)
end
addEventHandler("onPlayerWasted", getRootElement(), preventRcPlayerFromDieing)

-- When the player quits the game, only destroy their dummy (don't try to put them in the position of the dummy).
function onlyDestroyRcDummy()
	-- is the player in rc mode?
	if not isPlayerInRcMode(source) then
		return
	end

	-- destroy the map blip on the dummy ped
	local elements = getAttachedElements(getPlayerRcDummy(source))
	if elements then
		for k,v in ipairs(elements) do
			if (getElementType(v) == "blip") then
				destroyElement(v)
			end
		end
	end

	-- destroy the dummy ped itself
	destroyElement(getPlayerRcDummy(source))
end
addEventHandler("onPlayerQuit", getRootElement(), onlyDestroyRcDummy)