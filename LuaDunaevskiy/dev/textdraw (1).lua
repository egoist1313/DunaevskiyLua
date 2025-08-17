function main() --main function must be in every script
	if not isSampfuncsLoaded() or not isSampLoaded() then return end --if no sampfuncs and samp loaded to game, close (or not lol)
	while not isSampAvailable() do wait(100) end --waiting for samp loaded
	local font = renderCreateFont("Arial", 8, 5) --creating font
	sampfuncsRegisterConsoleCommand("deletetd", del)    --registering command to sampfuncs console, this will call delete function
	sampfuncsRegisterConsoleCommand("showtdid", show)   --registering command to sampfuncs console, this will call function that shows textdraw id's
	while true do --inf loop
	wait(0) --this shit is important
		if toggle then --params that not declared has a nil value that same as false
			for a = 0, 2304	do --cycle trough all textdeaw id
				if sampTextdrawIsExists(a) then --if textdeaw exists then
					x, y = sampTextdrawGetPos(a) --we get it's position. value returns in game coords
					x1, y1 = convertGameScreenCoordsToWindowScreenCoords(x, y) --so we convert it to screen cuz render needs screen coords
					renderFontDrawText(font, a, x1, y1, 0xFFBEBEBE) --and then we draw it's id on textdeaw position
				end
			end
		end
	end
end

--functions can be declared at any part of code unlike it usually works in lua

function del(n) --this function simly delete textdeaw with a number that we give with command
sampTextdrawDelete(n)
end

function show() --this function sets toggle param from false to true and vise versa
toggle = not toggle
end