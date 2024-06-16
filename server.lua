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
	if isElement(player) then
		if (getElementType(player) == "player") then
			if isElement(rcVehicle) then
				if (getElementType(rcVehicle) == "vehicle") then
					if not isPedDead(player) then
						if not isVehicleBlown(rcVehicle) then
							if not isPlayerInRcMode(player) then
								if (getPedOccupiedVehicleSeat(player) == 0 and rcVehicle ~= getPedOccupiedVehicle(player)) or (getPedOccupiedVehicleSeat(player) ~= 0) then
									if (getElementInterior(player) == getElementInterior(rcVehicle)) then
										if(getElementDimension(player) == getElementDimension(rcVehicle)) then
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
										else
											outputDebugString(string.format("RC Mode: enterRcMode: Player %s and vehicle are not in the same dimension.", getPlayerName(player)), 2)
										end
									else
										outputDebugString(string.format("RC Mode: enterRcMode: Player %s and vehicle are not in the same interior.", getPlayerName(player)), 2)
									end
								else
									outputDebugString(string.format("RC Mode: enterRcMode: Player %s cannot remote control the vehicle he is currently driving.", getPlayerName(player)), 2)
								end
							else
								outputDebugString(string.format("RC Mode: enterRcMode: The player %s already is in RC mode.", getPlayerName(player)), 2)
							end
						else
							outputDebugString("RC Mode: enterRcMode: The vehicle is blown and cannot be remote controled.", 2)
						end
					else
						outputDebugString("RC Mode: enterRcMode: the player is dead and cannot control an RC vehicle.", 2)
					end
				else
					outputDebugString(string.format("RC Mode: enterRcMode expects parameter 1 to be a vehicle, %s given.", getElementType(rcVehicle)), 2)
				end
			else
				outputDebugString(string.format("RC Mode: enterRcMode expects parameter 1 to be a vehicle, %s given.", type(rcVehicle)), 2)
			end
		else
			outputDebugString(string.format("RC Mode: enterRcMode expects parameter 1 to be a player, %s given.", getElementType(player)), 2)
		end
	else
		outputDebugString(string.format("RC Mode: enterRcMode expects parameter 1 to be a player, %s given.", type(player)), 2)
	end
end

-- bool isPlayerInRcMode(player)
-- Returns if the player is in RC Mode.
function isPlayerInRcMode(player)
	if isElement(player) then
		if (getElementType(player) == "player") then
			if isElement(g_rcDummy[player]) then
				return true
			end
			return false
		else
			outputDebugString(string.format("RC Mode: isPlayerInRcMode expects parameter 1 to be a player, %s given.", getElementType(player)), 2)
		end
	else
		outputDebugString(string.format("RC Mode: isPlayerInRcMode expects parameter 1 to be a player, %s given.", type(player)), 2)
	end
end

-- void exitRcMode(player)
-- Ends RC mode for the player:
--   * make the player visible again
--   * remove them from the car and put them in the position of their dummy
--   * destroy their dummy
--   * remove the map blip from the dummy ped
--   * add a blip for the player back
function exitRcMode(player)
	if isElement(player) then
		if (getElementType(player) == "player") then
			if isPlayerInRcMode(player) then
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
				getElementRotation(player, rotX, rotY, rotZ)
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
			else
				outputDebugString(string.format("RC Mode: exitRcMode: Player %s is not in RC Mode.", getPlayerName(player)), 2)
			end
		else
			outputDebugString(string.format("RC Mode: exitRcMode expects parameter 1 to be a player, %s given.", getElementType(player)), 2)
		end
	else
		outputDebugString(string.format("RC Mode: exitRcMode expects parameter 1 to be a player, %s given.", type(player)), 2)
	end
end

-- bool isCameraOnRcDummy(player)
-- Returns true if the camera is on the dummy of the player, returns false if it is on the player itself.
function isCameraOnRcDummy(player)
	if isElement(player) then
		if (getElementType(player) == "player") then
			return g_isRcCameraOnPlayer[player]
		else
			outputDebugString(string.format("RC Mode: isCameraOnRcDummy expects parameter 1 to be a player, %s given.", getElementType(player)), 2)
		end
	else
		outputDebugString(string.format("RC Mode: isCameraOnRcDummy expects parameter 1 to be a player, %s given.", type(player)), 2)
	end
end

-- void setCameraOnRcDummy(player, bool)
-- Sets the camera on the dummy if onDummy is true, otherwise sets it on the player.
function setCameraOnRcDummy(player, onDummy)
	if isElement(player) then
		if (getElementType(player) == "player") then
			if isPlayerInRcMode(player) then
				if (onDummy == true) then
					local rcDummy = getPlayerRcDummy(player)
					setCameraTarget(player, rcDummy)
					g_isRcCameraOnPlayer[player] = true
					outputDebugString("g_isRcCameraOnPlayer["..getPlayerName(player).."] = true")
				elseif (onDummy == false) then
					setCameraTarget(player, player)
					g_isRcCameraOnPlayer[player] = false
					outputDebugString("g_isRcCameraOnPlayer["..getPlayerName(player).."] = false")
				else
					outputDebugString(string.format("RC Mode: setCameraOnRcDummy expects parameter 2 to be a boolean, %s given.", type(onDummy)), 2)
				end
			else
				outputDebugString(string.format("RC Mode: setCameraOnRcDummy: Player %s is not in RC Mode.", getPlayerName(player)), 2)
			end
		else
			outputDebugString(string.format("RC Mode: setCameraOnRcDummy expects parameter 1 to be a player, %s given.", getElementType(player)), 2)
		end
	else
		outputDebugString(string.format("RC Mode: setCameraOnRcDummy expects parameter 1 to be a player, %s given.", type(player)), 2)
	end
end

-- ped getPlayerRcDummy(player)
-- Returns the ped that is used as RC dummy for the player.
function getPlayerRcDummy(player)
	if isElement(player) then
		if (getElementType(player) == "player") then
			if isPlayerInRcMode(player) then
				return g_rcDummy[player]
			else
				outputDebugString(string.format("RC Mode: Player %s is not in RC Mode.", getPlayerName(player)), 2)
			end
		else
			outputDebugString(string.format("RC Mode: getPlayerRcDummy expects parameter 1 to be a player, %s given.", getElementType(player)), 2)
		end
	else
		outputDebugString(string.format("RC Mode: getPlayerRcDummy expects parameter 1 to be a player, %s given.", type(player)), 2)
	end
end

------------------------------
--	Internal functions
------------------------------

-- Update the health of a player if their dummy gets hurt.
function observeRcDummy(rcDummy, assignedPlayer)
	if isElement(rcDummy) and isElement(assignedPlayer) then
		-- outputDebugString("dummyHealth = "..getElementHealth(rcDummy))
		-- outputDebugString("playerHealth = "..getElementHealth(assignedPlayer))
		setElementHealth(assignedPlayer, getElementHealth(rcDummy))
		setPedArmor(assignedPlayer, getPedArmor(rcDummy))
		setTimer(observeRcDummy, 1000, 1, rcDummy, assignedPlayer)
	end
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
	if isElement(jacked) then
		if isPlayerInRcMode(jacked) and not get("*RcMode.preventRcPlayerFromGettingJacked") then
			exitRcMode(jacked)
		end
	end
end
addEventHandler("onVehicleStartEnter", getRootElement(), checkIfToAbortRcMode)

-- If the invisible player driving the car has been killed, respawn them where their dummy ped is.
function preventRcPlayerFromDieing()
	if isPlayerInRcMode(source) then
		local posX, posY, posZ = getElementPosition(getPlayerRcDummy(source))
		spawnPlayer(source, posX, posY, posZ)
		-- setElementHealth(source, getElementHealth(getPlayerRcDummy(source)))
		exitRcMode(source)
	end
end
addEventHandler("onPlayerWasted", getRootElement(), preventRcPlayerFromDieing)

-- When the player quits the game, only destroy their dummy (don't try to put them in the position of the dummy).
function onlyDestroyRcDummy()
	if isPlayerInRcMode(source) then
		local elements = getAttachedElements(getPlayerRcDummy(source))
		if elements then
			for k,v in ipairs(elements) do
				if (getElementType(v) == "blip") then
					destroyElement(v)
				end
			end
		end	
		destroyElement(getPlayerRcDummy(source))
	end
end
addEventHandler("onPlayerQuit", getRootElement(), onlyDestroyRcDummy)