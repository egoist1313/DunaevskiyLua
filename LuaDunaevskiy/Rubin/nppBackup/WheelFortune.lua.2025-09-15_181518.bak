script_name('WheelFortune')
script_author("Serhiy_Rubin")
script_version("30.08.2023")
require 'lib.sampfuncs'
require 'lib.moonloader'
local sampev = require 'lib.samp.events'
local inicfg = require 'inicfg'
local dlstatus = require("moonloader").download_status
local bet, stavka = 0, 0
local wheel = {
	['  [Wheel 1000-10000] '] = {x = 2271.682373, y = 1584.642212, z = 1006.176208 },
	['  [Wheel 2000-20000] '] = {x = 2261.659180, y = 1584.642090, z = 1006.176453 },
	['  [Wheel 3000-30000] '] = {x = 2251.997559, y = 1584.642090, z = 1006.176453 },
	['  [Wheеl 1000-10000] '] = {x = 1943.601318, y = 986.384949, z = 992.474487 },
	['  [Wheеl 2000-20000] '] = {x = 1940.732666, y = 989.606995, z = 992.460938 },
	['  [Wheеl 3000-30000] '] = {x = 1937.847778, y = 986.565613, z = 992.474487 },
}
local multiplier, cost, mouse, gamer, plus = 2, 3000, false, 0, 100000
local auto, mode1, bet, stavka_me  = 0, 0, 0, 0
local text_stats = { ['0'] = ' Без тактики', ['1'] = ' Тактика: Цель', ['2'] = ' Тактика: +1000' }

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	while not isSampAvailable() do wait(0) end
	lua_thread.create(script_update.main)
	repeat
		wait(0)
		_, my_id = sampGetPlayerIdByCharHandle(PLAYER_PED)
		my_name = sampGetPlayerNickname(my_id)
		if _ then score = sampGetPlayerScore(my_id) end
	until score > 0
	local magicChar = { ":", "|" }
	local server = getSampRpServerName()
    if server == "" then
        thisScript():unload()
    end
	local posX, posY = convertGameScreenCoordsToWindowScreenCoords(500.0, 240.0)
	iniKey = my_name..'-'..server
	ini = inicfg.load({
		profit = {
			[iniKey] = 0,
		},
		settings = {
			posX = posX,
			posY = posY,
		},
		font = {
			name = 'Segoe UI',
			size = 10,
			flag = 13,
		}
	}, thisScript().name)
	inicfg.save(ini, thisScript().name)
	font = renderCreateFont(ini.font.name, ini.font.size, ini.font.flag)
	sampRegisterChatCommand('fortune_clear', function()
		ini.profit[iniKey] = 0
		mode1 = 0
		inicfg.save(ini, thisScript().name)
		end)
	while true do
		wait(0)
		local casino = false
		for k,v in pairs(wheel) do
			local dist = math.floor(getDistanceBetweenCoords3d(v.x, v.y, v.z, getCharCoordinates(playerPed)))
			local x, y = convert3DCoordsToScreen(v.x, v.y, v.z)
			if dist <= 1 then
				casino = true
				if wasKeyPressed(VK_RBUTTON) then
					mouse = not mouse
					sampSetCursorMode((mouse and 0 or 3))
				end
				local posX, posY = convertGameScreenCoordsToWindowScreenCoords(500.0, 240.0)
				local down = (renderGetFontDrawHeight(font) + (renderGetFontDrawHeight(font) / 15))
				renderDrawBox(posX, posY, renderGetFontDrawTextLength(font, k) + 3, renderGetFontDrawHeight(font), 0x90000000)
				local string = k
				false0_move1_click2(string, posX, posY)
				posY = posY + down
				renderDrawBox(posX, posY, renderGetFontDrawTextLength(font, k) + 3, renderGetFontDrawHeight(font), 0x90000000)
				local string = string.format(' Множитель: %d', multiplier)
				if false0_move1_click2(string, posX, posY) == 1 then
					local delta = getMousewheelDelta()
					if delta ~= 0 then
						if delta > 0 then -- Плюс
							multiplier = (multiplier == 2 and 4 or (multiplier == 4 and 8 or (multiplier == 8 and 16 or (multiplier == 16 and 32 or (multiplier == 32 and 32 or 2)))))
						else -- Минус
							multiplier = (multiplier == 2 and 2 or (multiplier == 4 and 2 or (multiplier == 8 and 4 or (multiplier == 16 and 8 or (multiplier == 32 and 16 or 2)))))
						end
					end
				end
				posY = posY + down
				renderDrawBox(posX, posY, renderGetFontDrawTextLength(font, k) + 3, renderGetFontDrawHeight(font), 0x90000000)
				min, max = k:match('(%d+)-(%d+)')
				if cost < tonumber(min) then cost = tonumber(min) end
				if cost > tonumber(max) then cost = tonumber(max) end
				if auto == 1 and cost < (mode1 + plus + tonumber(cost)) / tonumber(multiplier) then
					local S1 = (mode1 + plus + tonumber(cost)) / tonumber(multiplier)
					if S1 <= tonumber(max) then
						cost = S1
					end
				end
				local string = string.format(' Ставка: %d', cost)
				if false0_move1_click2(string, posX, posY) == 1 and sampIsCursorActive() then
					local delta = getMousewheelDelta()
					if delta ~= 0 then
						if delta > 0 then -- Плюс
							if cost < tonumber(max) then
								cost = cost + 1000
							end
						else -- Минус
							if cost > tonumber(min) then
								cost = cost - 1000
							end
						end
					end
				end
				posY = posY + down
				renderDrawBox(posX, posY, renderGetFontDrawTextLength(font, k) + 3, renderGetFontDrawHeight(font), 0x90000000)
				local string = string.format(' Приз: %d$', tonumber(cost) * tonumber(multiplier))
				false0_move1_click2(string, posX, posY)
				posY = posY + down
				renderDrawBox(posX, posY, renderGetFontDrawTextLength(font, k) + 3, renderGetFontDrawHeight(font), 0x90000000)
				local string = string.format(' Общая прибыль: %d$', ini.profit[iniKey])
				false0_move1_click2(string, posX, posY)
				posY = posY + down
				renderDrawBox(posX, posY, renderGetFontDrawTextLength(font, k) + 3, renderGetFontDrawHeight(font), 0x90000000)
				if false0_move1_click2(text_stats[tostring(auto)], posX, posY) == 1 then
					local delta = getMousewheelDelta()
					if delta ~= 0 then
						if delta > 0 then
							auto = (auto == 0 and 1 or (auto == 1 and 2 or (auto == 2 and 0 or 0)))
						else
							auto = (auto == 2 and 1 or (auto == 1 and 0 or (auto == 0 and 2 or 2)))
						end
					end
				end
				if auto ~= 0 then
					if auto == 1 then
						posY = posY + down
						renderDrawBox(posX, posY, renderGetFontDrawTextLength(font, k) + 3, renderGetFontDrawHeight(font), 0x90000000)
						local string = string.format(' Цель: %d$', plus)
						if false0_move1_click2(string, posX, posY) == 1 and sampIsCursorActive() then
							local delta = getMousewheelDelta()
							if delta ~= 0 then
								if delta > 0 then -- Плюс
									plus = plus + 1000
								else -- Минус
									plus = plus - 1000
								end
							end
						end
					end
					posY = posY + down
					renderDrawBox(posX, posY, renderGetFontDrawTextLength(font, k) + 3, renderGetFontDrawHeight(font), 0x90000000)
					local string = string.format(' Потрачено: -%d$', mode1)
					false0_move1_click2(string, posX, posY)
					posY = posY + down
					renderDrawBox(posX, posY, renderGetFontDrawTextLength(font, k) + 3, renderGetFontDrawHeight(font), 0x90000000)
					if false0_move1_click2('List', (posX + (renderGetFontDrawTextLength(font, k) / 2) - (renderGetFontDrawTextLength(font, 'List') / 2)), posY - 1) == 2 then
						local mnoj, stavk, cel_ = multiplier, cost, plus
						local trat, kolvo = 0, 0
						local text = '[#] Ставка\tПотрачено\tПриз\tПрофит\n'
						repeat
							kolvo = kolvo + 1
							trat = trat + stavk
							priz = stavk * tonumber(mnoj)
							vine = math.ceil(priz - trat)
							text = string.format('%s[%d] %d\t%d\t%d\t%d\n', text, kolvo, stavk, trat, priz, vine)
							if auto == 2 then
								stavk = tonumber(stavk) + 1000
							else
								stavk = (trat + plus + tonumber(stavk)) / tonumber(mnoj)
							end
						until stavk >= 30000 or vine < 0
						sampShowDialog(5, (auto == 1 and 'Цель '..plus or 'List'), text, 'Enter', 'Close', 5)
					end
				end
				posY = posY + down
				posY = posY + down
				renderDrawBox(posX, posY, renderGetFontDrawTextLength(font, k) + 3, renderGetFontDrawHeight(font), 0x90000000)
				if false0_move1_click2('Start', (posX + (renderGetFontDrawTextLength(font, k) / 2) - (renderGetFontDrawTextLength(font, 'Start') / 2)), posY - 1) == 2 then
					gamer = 1
					sendKey(16)
				end
			end
		end
		if mouse and not casino then
			sampSetCursorMode(0)
			mouse = false
		end
	end
end

function sampev.onServerMessage(color, message)
	message = AnsiToUtf8(message)
	if message:find(' Вы поставили (%d+) вирт на x(%d+)') then
		bet, stavka = message:match(' Вы поставили (%d+) вирт на x(%d+)')
		stavka_me = stavka
		return { color, Utf8ToAnsi(message) }
	end
	if message:find(' Поздравляем! Вы выиграли (%d+) вирт') then
		vin = message:match(' Поздравляем! Вы выиграли (%d+) вирт')
		ini.profit[iniKey] = ini.profit[iniKey] + tonumber(vin) - tonumber(bet)
		inicfg.save(ini, thisScript().name)
		local S2 = mode1
		mode1 = 0
		return { color, Utf8ToAnsi(message) }
	end
	if message:find(' К сожалению, вы проиграли, выпал множитель: x(%d+)') then
		stavka = message:match(' К сожалению, вы проиграли, выпал множитель: x(%d+)')
		mode1 = mode1 + tonumber(bet)
		ini.profit[iniKey] = ini.profit[iniKey] - tonumber(bet)
		inicfg.save(ini, thisScript().name)
		if auto ~= 0 then
			if auto == 1 then
				SetBet = (mode1 + plus + tonumber(bet)) / tonumber(stavka_me)
			end
			if auto == 2 then
				SetBet = tonumber(bet) + 1000
			end
			if cost < SetBet and SetBet <= tonumber(max) then
				cost = SetBet
				gamer = 1
				sendKey(16)
			end
		end
		return { color, Utf8ToAnsi(message) }
	end
end

function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
	title = AnsiToUtf8(title)
	text = AnsiToUtf8(text)
	if gamer == 1 and string.find(title, 'Выбор множителя') then
		lua_thread.create(function(dialogId)
			wait(300)
			local sendList = { [2] = 0, [4] = 1, [8] = 2, [16] = 3, [32] = 4 }
			sampSendDialogResponse(dialogId, 1, sendList[multiplier], string.format('[%d] x%d', sendList[multiplier], multiplier))
			gamer = 2
		end, dialogId)
		return false
	end
	if gamer == 2 and title:find('Ввод параметра') and text:find('Укажите ставку') then
		lua_thread.create(function(dialogId)
			wait(300)
			sampSendDialogResponse(dialogId, 1, 0, math.ceil(cost))
			gamer = 0
		end, dialogId)
		return false
	end
end

function false0_move1_click2(text, posX, posY)
	renderFontDrawText(font, text, posX, posY, 0xFFFFFFFF)
	local textLenght = renderGetFontDrawTextLength(font, text)
	local textHeight = renderGetFontDrawHeight(font)
	local curX, curY = getCursorPos()
	if curX >= posX and curX <= posX + textLenght and curY >= posY and curY <= posY + textHeight then
		renderFontDrawText(font, text, posX, posY, 0xFFbababa)
		if isKeyJustPressed(1) then
			return 2
		else
			return 1
		end
	else
		return 0
	end
end

function sendKey(key)
    local _, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
    local data = allocateMemory(68)
    sampStorePlayerOnfootData(myId, data)
    setStructElement(data, 4, 2, key, false)
    sampSendOnfootData(data)
    freeMemory(data)
end

function getSampRpServerName()
    local result = ""
    local server = sampGetCurrentServerName():gsub("|", "")
    local server_find = { "02", "Two", "Revo", "Legacy", "Classic", "Under" }
    for i = 1, #server_find do
        if server:find(server_find[i]) then
            result = server_find[i]
        end
    end
    return result
end

-->> UPDATE MODULE

function openURL(url, fpath)
    local text = ""
    local file_download = false
    local download_final = false


    if doesFileExist(fpath) then
        os.remove(fpath)
    end

    downloadUrlToFile(url, fpath, function(id, status, p1, p2)
        if status == dlstatus.STATUS_ENDDOWNLOADDATA then
            file_download = true
        end
        if status == dlstatus.STATUSEX_ENDDOWNLOAD then
            download_final = true
        end
    end
    )

    repeat
        wait(1000)
    until download_final or file_download

    if file_download then
        local f = io.open(fpath, "r")
        if f then
            text = f:read("*a")
            io.close(f)
        end
        os.remove(fpath)
    end

    if (text:find("Not found") and not text:find('"Not found"')) or text == "" then
        text = ""
        addChatMessage("Не удалось скачать обновление по ссылке:")
        addChatMessage(url)
    end

    return text
end


function addChatMessage(text)
    local tag = string.format("{667dff}[%s]{FFFFFF} ", thisScript().name)
    sampAddChatMessage(tag..text, 0xFFFFFFFF)
end

script_update = {
    version_url = "http://git.deadpoo.net/rubin/WheelFortune/raw/branch/master/version",
    script_url = "http://git.deadpoo.net/rubin/WheelFortune/raw/branch/master/WheelFortune.lua",
    changelog_url = "http://git.deadpoo.net/rubin/WheelFortune/raw/branch/master/changelog",
    address_ini = string.format("rubin-mods-updates\\%s.ini", thisScript().name),
    main = function()
        if not doesDirectoryExist("moonloader\\config\\rubin-mods-updates") then
            createDirectory("moonloader\\config\\rubin-mods-updates")
        end
        local ini = inicfg.load({
            settings = {
                check_update = true,
                auto_update = true,
                server_version = ""
            }
        }, script_update.address_ini)
        ini.settings.version_url = script_update.version_url
        ini.settings.script_url = script_update.script_url
        ini.settings.changelog_url = script_update.changelog_url
        ini.settings.version = thisScript().version
        ini.settings.script_name = thisScript().name
        local command = (thisScript().name:gsub(" ", "").."-update"):lower()
        sampRegisterChatCommand(command, script_update.command)
        if ini.settings.check_update or ini.settings.auto_update then
            local fpath = os.tmpname()
            local result, text = pcall(openURL, script_update.version_url, fpath)
            if result then
                ini.settings.server_version = text
                if text ~= "" and text ~= thisScript().version then
                    addChatMessage( string.format("Вышла новая версия '%s'. Текущая: '%s'", text, thisScript().version) )
                    if ini.settings.auto_update then
                        addChatMessage( string.format("Автообновление скрипта включено. Процесс запущен!") )
                        script_update.command()
                    else
                        addChatMessage( string.format("Автообновление скрипта выключено. Обновить самому: /%s", command) )
                    end
                end
            end
        end
        inicfg.save(ini, script_update.address_ini)
        script_update.menu.init()
    end,
    command = function()
        lua_thread.create(function()
            local fpath = os.tmpname()
            local result, text = pcall(openURL, script_update.version_url, fpath)
            if result then
                if text ~= "" and text ~= thisScript().version then
                    addChatMessage( string.format("Вышла новая версия '%s'. Текущая: '%s'", text, thisScript().version) )
                    local fpath = os.tmpname()
                    local result, text = pcall(openURL, script_update.script_url, fpath)
                    if result and text ~= "" and text:find(thisScript().name:gsub("%-", "%%-")) then
                        local file, error = io.open(thisScript().path, "w")
                        if file ~= nil then
                            file:write(text)
                            file:flush()
                            io.close(file)
                            addChatMessage("Обновление завершено, скрипт перезагружен!")
                            wait(500)
                            thisScript():reload()
                        end
                    end
                else
                    addChatMessage("У Вас установлена последняя версия!")
                end
            end
        end)
    end,
    menu = {
        dialog = {},
        ini = {},
        init = function()
            if not sampIsChatCommandDefined("rubin-mods") then
                sampAddChatMessage("{667dff}[RUBIN MODS]{FFFFFF} Управление обновлениями скриптов: /rubin-mods", 0xFFFFFFFF)
                sampRegisterChatCommand("rubin-mods",script_update.menu.show)
                while true do
                    wait(0)
                    local result, button, list, input = sampHasDialogRespond(2160)
                    if result and button == 1 then
                        if script_update.menu.ini[list+1] ~= nil and script_update.menu.dialog[list+1] ~= nil then
                            script_update.menu.dialog[list+1](script_update.menu.ini[list+1])
                        end
                    end
                    local result, button, list, input = sampHasDialogRespond(2162)
                    if result then
                        if button == 1 then
                            if script_update.menu2.text[list+1] ~= nil and script_update.menu2.dialog[list+1] ~= nil then
                                script_update.menu2.dialog[list+1]()
                            end
                        else
                            script_update.menu.show()
                        end
                    end
                    local result, button, list, input = sampHasDialogRespond(2161)
                    if result then
                        script_update.menu2.show(script_update.menu2.data)
                    end
                end
            end
        end,
        show = function()
            script_update.menu.dialog = {}
            script_update.menu.ini = {}
            local text = ""
            if doesDirectoryExist("moonloader\\config\\rubin-mods-updates") then
                local FileHandle, FileName = findFirstFile("moonloader\\config\\rubin-mods-updates\\*")
                while FileName ~= nil do
                    if FileName ~= nil and FileName ~= ".." and FileName ~= "." and FileName:find("%.ini") then
                        local address = string.format("moonloader\\config\\rubin-mods-updates\\%s", FileName)
                        if doesFileExist(address) then
                            local ini = inicfg.load({}, address)
                            script_update.menu.ini[#script_update.menu.ini+1] = address
                            text = string.format("%s%s\n", text, string.format("%s\t%s%s", ini.settings.script_name, (ini.settings.version == ini.settings.server_version and "{59fc30}" or "{ff0000}"),ini.settings.version))
                            script_update.menu.dialog[#script_update.menu.dialog+1] = function(data)
                            	script_update.menu2.show(data)
                            end
                        end
                    end
                    FileName = findNextFile(FileHandle)
                end
                findClose(FileHandle)
            else
                text = "Не найдена директория:\t\n    moonloader\\config\\rubin-mods-updates\t"
            end
            sampShowDialog(2160,"Обновление скриптов: Rubin Mods","Скрипт\tВерсия\n"..text,"Выбрать","Закрыть",5)
        end
    },
    menu2 = {
        data = {},
        text = {},
        dialog = {},
        show = function(data)
            script_update.menu2.data = data
            script_update.menu2.text = {}
            script_update.menu2.dialog = {}
            if doesFileExist(data) then
                local ini = inicfg.load({}, data)
                script_update.menu2.text[#script_update.menu2.text+1] = string.format("Автообновление %s", (ini.settings.auto_update and "{59fc30}ON" or "{ff0000}OFF"))
                script_update.menu2.dialog[#script_update.menu2.dialog+1] = function()
                    ini.settings.auto_update = not ini.settings.auto_update
                    inicfg.save(ini, data)
                    script_update.menu2.show(data)
                end
                if not ini.settings.auto_update then
                    script_update.menu2.text[#script_update.menu2.text+1] = string.format("Проверять обновления %s", (ini.settings.check_update and "{59fc30}ON" or "{ff0000}OFF"))
                    script_update.menu2.dialog[#script_update.menu2.dialog+1] = function()
                        ini.settings.check_update = not ini.settings.check_update
                        inicfg.save(ini, data)
                        script_update.menu2.show(data)
                    end
                end
                script_update.menu2.text[#script_update.menu2.text+1] = string.format("Последние изменения")
                script_update.menu2.dialog[#script_update.menu2.dialog+1] = function()
                    script_update.changelog(ini.settings.changelog_url, ini.settings.script_name)
                end
                script_update.menu2.text[#script_update.menu2.text+1] = string.format("Удалить из списка")
                script_update.menu2.dialog[#script_update.menu2.dialog+1] = function()
                    os.remove(data)
                    script_update.menu.show()
                end
                local text = ""
                for i = 1, #script_update.menu2.text do
                    text = text..script_update.menu2.text[i].."\n"
                end
                sampShowDialog(2162,"Настройки обновления для "..ini.settings.script_name,text,"Выбрать","Назад",2)
            end
        end
    },
    changelog = function(url, name)
        local fpath = os.tmpname()
        local result, text = pcall(openURL, url, fpath)
        if result then
            sampShowDialog(2161,"Changelog - "..name,text,"Выбрать","Назад",4)
        end
    end
}

-->> SCRIPT UTF-8
-->> utf8(table path, incoming variables encoding, outcoming variables encoding)
-->> table path example { "sampev", "onShowDialog" }
-->> encoding options nil | AnsiToUtf8 | Utf8ToAnsi
_utf8 = load([=[return function(utf8_func, in_encoding, out_encoding); if encoding == nil then; encoding = require("encoding"); encoding.default = "CP1251"; u8 = encoding.UTF8; end; if type(utf8_func) ~= "table" then; return false; end; if AnsiToUtf8 == nil or Utf8ToAnsi == nil then; AnsiToUtf8 = function(text); return u8(text); end; Utf8ToAnsi = function(text); return u8:decode(text); end; end; if _UTF8_FUNCTION_SAVE == nil then; _UTF8_FUNCTION_SAVE = {}; end; local change_var = "_G"; for s = 1, #utf8_func do; change_var = string.format('%s["%s"]', change_var, utf8_func[s]); end; if _UTF8_FUNCTION_SAVE[change_var] == nil then; _UTF8_FUNCTION = function(...); local pack = table.pack(...); readTable = function(t, enc); for k, v in next, t do; if type(v) == 'table' then; readTable(v, enc); else; if enc ~= nil and (enc == "AnsiToUtf8" or enc == "Utf8ToAnsi") then; if type(k) == "string" then; k = _G[enc](k); end; if type(v) == "string" then; t[k] = _G[enc](v); end; end; end; end; return t; end; return table.unpack(readTable({_UTF8_FUNCTION_SAVE[change_var](table.unpack(readTable(pack, in_encoding)))}, out_encoding)); end; local text = string.format("_UTF8_FUNCTION_SAVE['%s'] = %s; %s = _UTF8_FUNCTION;", change_var, change_var, change_var); load(text)(); _UTF8_FUNCTION = nil; end; return true; end]=])

function utf8(...)
    pcall(_utf8(), ...)
end

utf8({ "sampShowDialog" }, "Utf8ToAnsi")
utf8({ "sampSendChat" }, "Utf8ToAnsi")
utf8({ "sampAddChatMessage" }, "Utf8ToAnsi")
utf8({ "print" }, "Utf8ToAnsi")
utf8({ "renderGetFontDrawTextLength" }, "Utf8ToAnsi")
utf8({ "renderFontDrawText" }, "Utf8ToAnsi")
utf8({ "sampSetCurrentDialogEditboxText" }, "Utf8ToAnsi")
utf8({ "sampCreate3dTextEx" }, "Utf8ToAnsi")
utf8({ "sampCreate3dText" }, "Utf8ToAnsi")
utf8({ "sampSet3dTextString" }, "Utf8ToAnsi")
utf8({ "sampGetDialogText" }, nil, "AnsiToUtf8")
utf8({ "sampGetDialogCaption" }, nil, "AnsiToUtf8")
utf8({ "sampHasDialogRespond" }, nil, "AnsiToUtf8")