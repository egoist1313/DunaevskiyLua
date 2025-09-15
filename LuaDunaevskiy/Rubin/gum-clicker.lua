script_name('GUM-Clicker')
script_author("Serhiy_Rubin")
local sampev = require('lib.samp.events')
local clicker = false
local clicker_wait = 100
local spac_id_green = -1
local spac_id_white = -1
local debug = false

function main()
	if not isSampfuncsLoaded() or not isSampLoaded() then return end
	while not isSampAvailable() do wait(100) end
	sampRegisterChatCommand("gum", gum_cmd)
	sampRegisterChatCommand("gumdebug", function() debug = not debug end)
	while true do
		wait(0)
		doDialogCheck()
		doTextdrawCheck()
		doPunchbagnuCheck()
	end
end

function gum_cmd(param)
	clicker = not clicker
	if clicker and param:find('%d+') then
		clicker_wait = tonumber(param)
	end

	local text = string.format("%sGUM CLICKER %s~n~CLICK WAIT - %s",
		(clicker and "~g~" or "~r~"),
		(clicker and "ON" or "OFF"),
		clicker_wait
	)
	printStringNow(text, 1000)
end

function doDialogCheck()
	if sampIsDialogActive() then 
		local dialog_text = sampGetDialogText()
		if dialog_text:find("мини игра") then
			local mode = (dialog_text:find('"D"') and 0 or 1) --[[ WSAD - 0 | WS - 1 ]]
			if not clicker_mode or mode ~= clicker_mode then
				clicker_mode = mode
			end
		end
	end
end

function doTextdrawCheck()
	if not clicker then return end
	if not clicker_mode then return end
	local isShowTextdraw = false
    for texdrawId = 0, 2304 do
        if sampTextdrawIsExists(texdrawId) then
            local x, y = sampTextdrawGetPos(texdrawId)
            local x, y = math.ceil(x), math.ceil(y)
            local textdrawText = sampTextdrawGetString(texdrawId)
            local letSizeX, letSizeY, color = sampTextdrawGetLetterSizeAndColor(texdrawId)
            if clicker_mode == 0 then
	            if x == 313 and y == 305 then
	            	if textdrawText:find('up') then
	            		setGameKeyState(1, -128)
	            	elseif textdrawText:find('down') then
	            		setGameKeyState(1, 128)
	            	elseif textdrawText:find('left') then
	            		setGameKeyState(0, -128)
	            	elseif textdrawText:find('right') then
	            		setGameKeyState(0, 128)
	            	end
	            	wait(clicker_wait)
	            end 
	        else
	        	if textdrawText:find("LD_SPAC:WHITE") then
	        		if color == 4278225664 then
	        			isShowTextdraw = true
	        			spac_id_green = texdrawId
	        			spac_coord_green = { x = x, y = y }
	        			renderBox(x, y)
	        		end
	        		if color == 4294967295 then
	        			isShowTextdraw = true
	        			spac_id_white = texdrawId
	        			spac_coord_white = { x = x, y = y }
	        			renderBox(x, y)
	        		end
	        	end
	        end
        end
    end
    if isShowTextdraw and clicker_mode == 1 and spac_id_white ~= -1 and spac_id_green ~= -1 then
    	if spac_coord_white.y > (spac_coord_green.y + 10) then
    		setGameKeyState(1, -128)
    	else
    		setGameKeyState(1, 128)
    	end
    	wait(clicker_wait)
    end
end

function doPunchbagnuCheck()
	if not clicker then return end
	local x, y, z = 0.0, 0.0, 0.0
	local min_dist = 100000
	for _, v in pairs(getAllObjects()) do
		local model = getObjectModel(v)
		if model == 1985 then
			local char_x, char_y, char_z = getCharCoordinates(PLAYER_PED)
			local _, obj_x, obj_y, obj_z = getObjectCoordinates(v)
			local distance = getDistanceBetweenCoords3d(obj_x, obj_y, obj_z, char_x, char_y, char_z)
			if distance < min_dist and distance <= 3.0 then
				min_dist = distance
				x, y, z = obj_x, obj_y, char_z
				renderBox(x, y)
			end
		end
	end
	if min_dist ~= 100000 and sampIsChatInputActive() then
		renderBox(x, y)
    	local cX, cY, cZ = getActiveCameraCoordinates()
    	setCameraPositionUnfixed(0.0, (getHeadingFromVector2d(x - cX, y - cY) - 90.0) / 57.2957795)
    	setGameKeyState(6, 255)
    	setGameKeyState(15, 255)
	end
end

function renderBox(x, y)
	if not debug then return end
	local x, y = convertGameScreenCoordsToWindowScreenCoords(x, y)
	renderDrawBox(x, y, 10, 10, -1)
end