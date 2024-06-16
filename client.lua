-- Render the player's name and health on their dummy ped
function showDummyName()
	-- loop through all players and see if they have a dummy ped assigned
	local players = getElementsByType("player")
	for i = 0, #players do
		if players[i] then
			-- get the dummy ped associated to this player
			local rcDummy = getElementData(players[i], "rcDummy")
			if isElement(rcDummy) then
				-- get the dummy ped's position and check if the player can currently see it
				local worldX, worldY, worldZ = getElementPosition(rcDummy)
				local posX, posY, posZ = getElementPosition(getLocalPlayer())
				local distance = getDistanceBetweenPoints3D(posX, posY, posZ, worldX, worldY, worldZ)
				if distance < 29 and isLineOfSightClear(posX, posY, posZ, worldX, worldY, worldZ, true, false, false) then
					local screenX, screenY = getScreenFromWorldPosition(worldX, worldY, worldZ + .34)
					if screenX and screenY then
						-- first, draw the player name slightly larger in black, then the player name itself.
						-- this will create a black outline around the name
						dxDrawText(getPlayerName(players[i]), screenX+1, screenY+1, screenX+1, screenY+1, tocolor(0, 0, 0), 1, "default", "center", "top")
						dxDrawText(getPlayerName(players[i]), screenX, screenY, screenX, screenY, tocolor(getPlayerNametagColor(players[i])), 1, "default", "center", "top")
						
						-- next, draw a rectangle as maximum value in the background, then draw a smaller ractangle representing the player's health.
						-- the lower the health the more the rectangle will change from a green color to a red one.
						dxDrawRectangle(screenX-28, screenY+14, 54, 10, tocolor(0, 0, 0, 180-180*distance/30))
						dxDrawRectangle(screenX-26, screenY+16, 50*getElementHealth(rcDummy)/100, 6, tocolor(230-230*getElementHealth(rcDummy)/100, 230*getElementHealth(rcDummy)/100, 0, 180-180*distance/30))
					end
				end
			end
		end
	end
end
addEventHandler("onClientRender", getRootElement(), showDummyName)