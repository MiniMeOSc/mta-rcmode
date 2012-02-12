function showDummyName()
	local players = getElementsByType("player")
	for i = 0, #players do
		if players[i] then
			local rcDummy = getElementData(players[i], "rcDummy")
			if isElement(rcDummy) then
				local worldX, worldY, worldZ = getElementPosition(rcDummy)
				local posX, posY, posZ = getElementPosition(getLocalPlayer())
				local distance = getDistanceBetweenPoints3D(posX, posY, posZ, worldX, worldY, worldZ)
				if distance < 29 and isLineOfSightClear(posX, posY, posZ, worldX, worldY, worldZ, true, false, false) then
					local screenX, screenY = getScreenFromWorldPosition(worldX, worldY, worldZ + .34)
					if screenX and screenY then
						dxDrawText(getPlayerName(players[i]), screenX+1, screenY+1, screenX+1, screenY+1, tocolor(0, 0, 0), 1, "default", "center", "top")
						dxDrawText(getPlayerName(players[i]), screenX, screenY, screenX, screenY, tocolor(getPlayerNametagColor(players[i])), 1, "default", "center", "top")
						dxDrawRectangle(screenX-28, screenY+14, 54, 10, tocolor(0, 0, 0, 180-180*distance/30))
						dxDrawRectangle(screenX-26, screenY+16, 50*getElementHealth(rcDummy)/100, 6, tocolor(230-230*getElementHealth(rcDummy)/100, 230*getElementHealth(rcDummy)/100, 0, 180-180*distance/30))
					end
				end
			end
		end
	end
end
addEventHandler("onClientRender", getRootElement(), showDummyName)