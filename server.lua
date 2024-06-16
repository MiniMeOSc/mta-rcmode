--[[
------------------------------
--	Script wide used variables
------------------------------
]]
local rcDummy = {}
local isRcCameraOnPlayer = {}

--[[
------------------------------
--	Exported functions
------------------------------
]]

--[[
-- void enterRcMode(player, vehicle)
-- Puts the player in RC Mode in the vehicle.
]]
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
											local posX, posY, posZ = getElementPosition(player)
											local rotX, rotY, rotZ = getElementRotation(player)
											local playerCar = getPedOccupiedVehicle(player)
											local seat = getPedOccupiedVehicleSeat(player)
											local dimension = getElementDimension(player)
											local playerModel = getElementModel(player)
											local health = getElementHealth(player)
											local armor = getPedArmor(player)
											setPlayerNametagShowing(player, false)
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
											local driver = getVehicleOccupant(rcVehicle, 0)
											local passenger = getVehicleOccupant(rcVehicle, 1)
											if driver and not passenger then
												if isPlayerInRcMode(driver) then
													exitRcMode(driver)
												else
													warpPedIntoVehicle(driver, rcVehicle, 1)
												end
											end
											setElementAlpha(player, 0)
											giveWeapon(player, 0, 0, true)
											rcDummy[player] = createPed(playerModel, posX, posY, posZ)
											setElementRotation(rcDummy[player], rotX, rotY, rotZ)
											setElementDimension(rcDummy[player], dimension)
											setElementHealth(rcDummy[player], health)
											setPedArmor(rcDummy[player], armor)
											giveWeapon(rcDummy[player], 40, 0, true)
											observeRcDummy(rcDummy[player], player)
											if r and g and b and a then
												createBlipAttachedTo(rcDummy[player], 0, 2, r, g, b, a)
											end
											if isElement(playerCar) then
												removePedFromVehicle(player)
												warpPedIntoVehicle(rcDummy[player], playerCar, seat)
											end
											warpPedIntoVehicle(player, rcVehicle, 0)
											isRcCameraOnPlayer[player] = true
											setElementData(player, "rcDummy", rcDummy[player])
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

--[[
-- bool isPlayerInRcMode(player)
-- Returns if the player is in RC Mode.
]]
function isPlayerInRcMode(player)
	if isElement(player) then
		if (getElementType(player) == "player") then
			if isElement(rcDummy[player]) then
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

--[[
-- void exitRcMode(player)
-- Ends RC Mode for the player.
]]
function exitRcMode(player)
	if isElement(player) then
		if (getElementType(player) == "player") then
			if isPlayerInRcMode(player) then
				local posX, posY, posZ = getElementPosition(getPlayerRcDummy(player))
				local rotX, rotY, rotZ = getElementRotation(getPlayerRcDummy(player))
				local playerCar = getPedOccupiedVehicle(getPlayerRcDummy(player))
				local seat = getPedOccupiedVehicleSeat(getPlayerRcDummy(player))
				local dimension = getElementDimension(getPlayerRcDummy(player))
				local health = getElementHealth(getPlayerRcDummy(player))
				local armor = getPedArmor(player)
				local r, g, b, a
				local elements = getAttachedElements(getPlayerRcDummy(player))
				if elements then
					for k,v in ipairs(elements) do
						if (getElementType(v) == "blip") then
							r, g, b, a = getBlipColor(v)
							destroyElement(v)
						end
					end
				end
				destroyElement(getPlayerRcDummy(player))
				rcDummy[player] = nil
				removePedFromVehicle(player)
				if isElement(playerCar) then
					setCameraTarget(player, player) -- to fix an MTA bug: It appears that the camera is not set back on the player when he's put in a passenger seat
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
				isRcCameraOnPlayer[player] = nil
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

--[[
-- bool isCameraOnRcDummy(player)
-- Returns true if the camera is on the dummy of the player, returns false if it is on the player itself.
]]
function isCameraOnRcDummy(player)
	if isElement(player) then
		if (getElementType(player) == "player") then
			return isRcCameraOnPlayer[player]
		else
			outputDebugString(string.format("RC Mode: isCameraOnRcDummy expects parameter 1 to be a player, %s given.", getElementType(player)), 2)
		end
	else
		outputDebugString(string.format("RC Mode: isCameraOnRcDummy expects parameter 1 to be a player, %s given.", type(player)), 2)
	end
end

--[[
-- void setCameraOnRcDummy(player, bool)
-- Sets the camera on the dummy if onDummy is true, otherwise sets it on the player.
]]
function setCameraOnRcDummy(player, onDummy)
	if isElement(player) then
		if (getElementType(player) == "player") then
			if isPlayerInRcMode(player) then
				if (onDummy == true) then
					setCameraTarget(player, getPlayerRcDummy(player))
					isRcCameraOnPlayer[player] = true
					outputDebugString("isRcCameraOnPlayer["..getPlayerName(player).."] = true")
				elseif (onDummy == false) then
					setCameraTarget(player, player)
					isRcCameraOnPlayer[player] = false
					outputDebugString("isRcCameraOnPlayer["..getPlayerName(player).."] = false")
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

--[[
-- ped getPlayerRcDummy(player)
-- Returns the ped that is used as RC dummy for the player.
]]
function getPlayerRcDummy(player)
	if isElement(player) then
		if (getElementType(player) == "player") then
			if isPlayerInRcMode(player) then
				return rcDummy[player]
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

--[[
------------------------------
--	Internal functions
------------------------------
]]

function observeRcDummy(theRcDummy, assignedPlayer)
	if isElement(theRcDummy) and isElement(assignedPlayer) then
		-- outputDebugString("dummyHealth = "..getElementHealth(theRcDummy))
		-- outputDebugString("playerHealth = "..getElementHealth(assignedPlayer))
		setElementHealth(assignedPlayer, getElementHealth(theRcDummy))
		setPedArmor(assignedPlayer, getPedArmor(theRcDummy))
		setTimer(observeRcDummy, 1000, 1, theRcDummy, assignedPlayer)
	end
end

function abortExitingVehicle(player)
	if isPlayerInRcMode(player) and not wasEventCancelled() then
		exitRcMode(player)
		cancelEvent(true, "rcmode.preventPlayerExitingVehicleOnEnd")
	end
end
addEventHandler("onVehicleStartExit", getRootElement(), abortExitingVehicle)

function checkIfToAbortRcMode(enteringPlayer, seat, jacked)
	if isElement(jacked) then
		if isPlayerInRcMode(jacked) and not get("*RcMode.preventRcPlayerFromGettingJacked") then
			exitRcMode(jacked)
		end
	end
end
addEventHandler("onVehicleStartEnter", getRootElement(), checkIfToAbortRcMode)

function preventRcPlayerFromDieng()
	if isPlayerInRcMode(source) then
		local posX, posY, posZ = getElementPosition(getPlayerRcDummy(source))
		spawnPlayer(source, posX, posY, posZ)
		-- setElementHealth(source, getElementHealth(getPlayerRcDummy(source)))
		exitRcMode(source)
	end
end
addEventHandler("onPlayerWasted", getRootElement(), preventRcPlayerFromDieng)

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