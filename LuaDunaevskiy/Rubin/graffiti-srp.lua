local script_name = 'graffiti-srp'
local script_author = 'Serhiy_Rubin'
local script_version = '1.00'
script_properties("work-in-pause")
local inicfg = require 'inicfg'
local samp = require 'samp.events'
local gang_color = { [18663] = 782269354, [18665] = -2218838, [18661] = 233701290, [18659] = 161743018, [18664] = -988414038 }	 
local gang_names = { [18663] = '{2EA07B}Rifa', [18665] = '{FFDE24}Vagos', [18661] = '{0DEDFF}Aztec', [18659] = '{09A400}Grove', [18664] = '{C515FF}Ballas' }
local OBJECT, time, obj_beside = {}, os.time(), -1

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	while not isSampAvailable() do wait(0) end
	repeat wait(0) until sampGetCurrentServerName() ~= 'SA-MP'
	local _, my_id = sampGetPlayerIdByCharHandle(PLAYER_PED)
	my_name = sampGetPlayerNickname(my_id)
	server = sampGetCurrentServerName(  )
    server =
        (server:find("02") and "Two" or
        (server:find("Revo") and "Revolution" or
            (server:find("Legacy") and "Legacy" or (server:find("Classic") and "Classic" or
        (server:find("Two") and "Two" or 
        (server:find("TEST") and "TEST" or 
        (server:find("Underground") and "Underground" or "" )))))))
	iniKey = string.format('%s-%s', server, my_name )
	ini = inicfg.load({
		[iniKey] = {
			render = false,
			map = false,
			bot = false
		},
		font = {
			name = 'Segoe UI',
			size = 10,
			flag = 13
		}
	}, 'Graffiti-SRP')
	inicfg.save(ini, 'Graffiti-SRP')
	DIR = string.format('%s\\moonloader\\config\\%s-Graffiti', getGameDirectory(), server)
	local t = table_read(DIR)
	if t ~= nil then OBJECT = t end
	font = renderCreateFont(ini.font.name, ini.font.size, ini.font.flag)
	sampRegisterChatCommand('graffiti', function()
		ShowDialog(1)
	end)
	while true do
		wait(0)
        local objects = getAllObjects()
        local object_search = {}
        if isKeyDown(119) or isKeyDown(154) then time = os.time() end
        local clear_scr = (os.time() - time > 5 and true or false)
        local obj_b = -1
        for k, i in ipairs(objects) do
            if doesObjectExist(i) then
                local result, x, y, z = getObjectCoordinates(i)
                if result then
                    local model = getObjectModel(i)
                    local dist = math.floor(getDistanceBetweenCoords3d(x, y, z, getCharCoordinates(playerPed)))
  					for k,v in pairs(gang_color) do
  						if k == model then
  							object_search[string.format('%d%d%d', x, y, z)] = true
  							local find = findObject(OBJECT, x, y)
  							local key = ( find ~= false and find or #OBJECT + 1 )
  							if not OBJECT[key] then OBJECT[key] = {} end
  							if OBJECT[key].color == nil or OBJECT[key].color ~= gang_color[model] then save_time = os.time() end
  							OBJECT[key].x, OBJECT[key].y, OBJECT[key].z, OBJECT[key].color = x, y, z, gang_color[model]
  							local posX, posY = convert3DCoordsToScreen(x, y, z)
  							if isObjectOnScreen(i) and ini[iniKey].render and not isPauseMenuActive() and clear_scr then
  								renderFontDrawText(font, string.format('  %s\nDist: %d m', gang_names[model], dist), posX, posY, -1)
  							end
							if OBJECT[key].handle ~= nil then
								removeBlip(OBJECT[key].handle)
								OBJECT[key].handle = nil
							end
  							if dist <= 3 then
  								obj_b = key
  							end
  						end
  					end
                end
            end
        end
        obj_beside = ( obj_b ~= -1 and obj_b or obj_beside)
		for k,v in pairs(OBJECT) do
			local dist = math.ceil(getDistanceBetweenCoords3d(v.x, v.y, v.z, getCharCoordinates(playerPed)))
			local int = (getActiveInterior() == 0 and true or false)
			if v.handle == nil then
				local color = (v.color ~= nil and v.color or 0xFFFFFFFF )
				local size = 1
				if v.time ~= nil then
					if (v.time - os.time()) > 0 then
						size = 2
					end
				end
				if isPauseMenuActive() then
					if ini[iniKey].map and clear_scr then
						v.handle = addBlipForCoord(v.x, v.y, v.z)
						changeBlipScale(v.handle, size)
						changeBlipColour(v.handle, color)
					end
				else
					if dist < 250 and int and ini[iniKey].map then
						if object_search[string.format('%d%d%d', v.x, v.y, v.z)] == nil and not isCharDead(PLAYER_PED) then
							OBJECT[k] = nil
							save_time = os.time()
						end
						if OBJECT[k] ~= nil and clear_scr then
							v.handle = addBlipForCoord(v.x, v.y, v.z)
							changeBlipScale(v.handle, size)
							changeBlipColour(v.handle, color)
						end
					end
				end
			else
				if not isPauseMenuActive() then
					if dist > 250 or not ini[iniKey].map or int or not clear_scr then 
						removeBlip(v.handle)
						v.handle = nil
					end
				end
			end
		end
		if save_time ~= nil and (os.time() - save_time) > 3 then
			table_write(DIR, OBJECT)
			save_time = nil
		end
			local caption = sampGetDialogCaption()
			local result, button, list, input = sampHasDialogRespond(0)
			if caption == 'Graffiti_SRP: Настройки' then
				if result and button == 1 then
					if dialogLine[list + 1] ==  ' Graffiti-WH\t'..(ini[iniKey].render and '{06940f}ON' or '{d10000}OFF') then
						ini[iniKey].render = not ini[iniKey].render
						inicfg.save(ini, 'Graffiti-SRP')	
						ShowDialog(1)
					elseif dialogLine[list + 1] ==  ' Graffiti-MAP\t'..(ini[iniKey].map and '{06940f}ON' or '{d10000}OFF') then
						ini[iniKey].map = not ini[iniKey].map
						inicfg.save(ini, 'Graffiti-SRP')
						ShowDialog(1)
					elseif dialogLine[list + 1] ==  ' Graffiti-BOT\t'..(ini[iniKey].bot and '{06940f}ON' or '{d10000}OFF') then
						ini[iniKey].bot = not ini[iniKey].bot
						inicfg.save(ini, 'Graffiti-SRP')
						ShowDialog(1)
					elseif dialogLine[list + 1] ==  ' Шрифт\t'..ini.font.name then
						ShowDialog(2, dialogTextToList[list + 1], input, true, 'font', 'name')
					elseif dialogLine[list + 1] ==  ' Размер\t'..ini.font.size then
						ShowDialog(2, dialogTextToList[list + 1], input, false, 'font', 'size')
					elseif dialogLine[list + 1] ==  ' Стиль\t'..ini.font.flag then
						ShowDialog(2, dialogTextToList[list + 1], input, false, 'font', 'flag')
					elseif dialogLine[list + 1] ==  '{59fc30}Контакты автора\t' then
						ShowDialog(3)
					else
						ShowDialog(1)
					end
				end
			end
			if caption == "Graffiti_SRP: Изменение параметров" then
				if d[7] then
					d[7] = false
					sampSetCurrentDialogEditboxText(ini[d[5]][d[6]])
				end
				if result then
					if button == 1 then
						local gou = ( d[4] and (#input > 0 and true or false) or (input:find("^%d+$") and true or false))
						if gou then
							d[3] = (d[4] and tostring(input) or tonumber(input))
							ini[d[5]][d[6]] = d[3]
							inicfg.save(ini, 'Graffiti-SRP')
							if d[5]:find('font') then
								renderReleaseFont(font)
								font = renderCreateFont(ini.font.name, ini.font.size, ini.font.flag)
							end
							ShowDialog(1)
						else
							ShowDialog(d[1], d[2], d[3], d[4], d[5], d[6])
						end
					end
				end
			end
			if caption == "Graffiti_SRP: Контакты автора" then
				if result then
					if button == 1 then
						if list == 0 then setClipboardText("Serhiy_Rubin") end
						if list == 1 then setClipboardText("https://vk.com/id353828351") end
						if list == 2 then setClipboardText("https://vk.com/club161589495") end
						if list == 3 then setClipboardText("serhiyrubin") end
						if list == 4 then setClipboardText("Serhiy_Rubin#3391") end
						ShowDialog(3)
					else
						ShowDialog(1)
					end
				end
			end
	end
end

function findObject(table, x, y)
	for i, v in pairs(table) do
		if string.format('%.8f', x) == string.format('%.8f', v.x) and string.format('%.8f', y) == string.format('%.8f', v.y) then 
			return i
		end
	end
	return false
end

function table_read(adress)
	local f = io.open(adress, 'r')
	if f then
		local func = load(f:read('*a'))
	    local data = select(2, pcall(func))
		f:close()
		return data
	else
		data = {}
		return data
	end
end

function table_write(adress, table)
	local text = 'return {\n';
	for i, v in ipairs(table) do
		text = text .. '{'
		for k, v in pairs(v) do
			if k ~= 'handle' then
				text = text .. k .. ' = ' .. v ..';'
			end
		end
		text = text .. '};\n'
	end
	text = text .. '}'
	local filese = io.open(adress, 'w')
	filese:write(text)
	filese:flush()
	io.close(filese)
end

function ShowDialog(int, dtext, dinput, string_or_number, ini1, ini2)
	d = {}
	d[1], d[2], d[3], d[4], d[5], d[6] = int, dtext, dinput, string_or_number, ini1, ini2
	if int == 1 then
		dialogLine, dialogTextToList = {}, {}
		dialogLine[#dialogLine + 1] = '{59fc30}> Настройки\t'..iniKey
		dialogLine[#dialogLine + 1] = ' Graffiti-WH\t'..(ini[iniKey].render and '{06940f}ON' or '{d10000}OFF')
		dialogLine[#dialogLine + 1] = ' Graffiti-BOT\t'..(ini[iniKey].bot and '{06940f}ON' or '{d10000}OFF')
		dialogLine[#dialogLine + 1] = ' Graffiti-MAP\t'..(ini[iniKey].map and '{06940f}ON' or '{d10000}OFF')
		dialogLine[#dialogLine + 1] = '{59fc30}> Настройки рендера'
		dialogLine[#dialogLine + 1] = ' Шрифт\t'..ini.font.name 
			dialogTextToList[#dialogLine] = "{FFFFFF}Введите название шрифта"
		dialogLine[#dialogLine + 1] = ' Размер\t'..ini.font.size 
			dialogTextToList[#dialogLine] = "{FFFFFF}Введите размер шрифта"
		dialogLine[#dialogLine + 1] = ' Стиль\t'..ini.font.flag
			dialogTextToList[#dialogLine] = "{FFFFFF}Устанавливайте стиль путем сложения.\n\nТекст без особенностей = 0\nЖирный текст = 1\nНаклонность(Курсив) = 2\nОбводка текста = 4\nТень текста = 8\nПодчеркнутый текст = 16\nЗачеркнутый текст = 32\n\nСтандарт: 13"
		dialogLine[#dialogLine + 1] = '{59fc30}Контакты автора\t'
		local text = ""
		for k,v in pairs(dialogLine) do
			text = text..v.."\n"
		end
		sampShowDialog(0, 'Graffiti_SRP: Настройки', text, "Выбрать", "Закрыть", 4)
	end
	if int == 2 then
		d[7] = true
		sampShowDialog(0, "Graffiti_SRP: Изменение параметров", dtext, "Выбрать", "Назад", 1)
	end
	if int == 3 then
		sampShowDialog(0, "Graffiti_SRP: Контакты автора", "{FFFFFF}Выбери что скопировать\t\nНик на Samp-Rp\tSerhiy_Rubin\nСтраничка {4c75a3}VK{FFFFFF}\tvk.com/id353828351\nГруппа {4c75a3}VK{FFFFFF} с модами\tvk.com/club161589495\n{10bef2}Skype{FFFFFF}\tserhiyrubin\n{7289da}Discord{FFFFFF}\tSerhiy_Rubin#3391", "Копировать", "Назад", 5)
	end
end

function samp.onServerMessage(color, message)
	if message:find(' Граффити можно будет изменить через (%d+):(%d+):(%d+)') then
		if obj_beside ~= -1 then
			local H, M, S = message:match(' Граффити можно будет изменить через (%d+):(%d+):(%d+)')
			local time = os.time() + (tonumber(H) * 3600) + (tonumber(M) * 60) + tonumber(S)
			OBJECT[obj_beside].time = time
			save_time = os.time()
			if OBJECT[obj_beside].handle ~= nil then
				removeBlip(OBJECT[obj_beside].handle)
				OBJECT[obj_beside].handle = nil
			end
		end
	end
	if message == ' Вы перекрасили граффити' then
		if obj_beside ~= -1 then
			local time = os.time() + 3600
			OBJECT[obj_beside].time = time
			save_time = os.time()
			if OBJECT[obj_beside].handle ~= nil then
				removeBlip(OBJECT[obj_beside].handle)
				OBJECT[obj_beside].handle = nil
			end
		end
	end
end

function samp.onShowTextDraw(id, data)
	if data.modelId == 365 then
		if ini[iniKey].bot then
			lua_thread.create(function(id)
				wait(math.random(400, 1000))
				sampSendClickTextdraw(id)
			end, id)
		end
	end
end