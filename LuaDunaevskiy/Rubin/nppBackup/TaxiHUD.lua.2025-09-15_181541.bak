script_name('TaxiHUD')
script_author("Serhiy_Rubin")
script_version("21.01.03.1")

function try(f, catch_f)
  local status, exception = pcall(f)
  if not status then
    catch_f(exception)
  end
end

try(function()
 sampev, inicfg, dlstatus, vkeys, ffi =
    require "lib.samp.events",
    require "inicfg",
    require("moonloader").download_status,
    require "lib.vkeys",
    require("ffi")
	
  end, function(e)
    sampAddChatMessage(">> Произошла ошибка на этапе загрузки библиотек. Возможно у вас нет SAMP.Lua", 0xff0000)
    sampAddChatMessage(">> Официальная страница Taxi HUD: https://vk.com/rubin.mods",0xff0000)
	sampAddChatMessage(e, -1)
	thisScript():unload()
  end)

ffi.cdef [[ bool SetCursorPos(int X, int Y); ]]
local id, antiflood, checkSkill, payCheck, count, passajir, chai, driver, hud, checkGPS, farm, GPS, GPStime, passj = 0, 0, 1, 1, 0, {}, 0, false, false, 1,{}, false, 0, 0
local noobQuest, QuestRead = {}, 0
local call_coord = { x = 0.0, y = 0.0, z = 0.0 }


function check_server_name()
	local result = ""
	local server = sampGetCurrentServerName()
	local servers = { "Two", "Revo", "Legacy", "Classic", "Underground" }
	if server:find("Samp%-Rp%.Ru") then
		result = "NONE"
	end
	for k,v in pairs(servers) do
		if server:find(v) then
			result = v
		end
	end
	return result
end

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	while not isSampAvailable() do wait(100) end

	repeat wait(0) until sampGetCurrentServerName() ~= 'SA-MP'

	local _, my_id = sampGetPlayerIdByCharHandle(PLAYER_PED)
	server = check_server_name()
    if server == "" then thisScript():unload() end
	nickname = sampGetPlayerNickname(my_id)
	adress = { 
		player = string.format("TaxiHUD\\%s-%s.ini", server, nickname),
		binder = string.format("%s\\moonloader\\config\\TaxiHUD\\Binder.txt", getGameDirectory()),
		general = string.format("TaxiHUD\\Settings.ini"),
	}
	local x1, y1 = convertGameScreenCoordsToWindowScreenCoords(14.992679595947, 274.75)
    local x2, y2 = convertGameScreenCoordsToWindowScreenCoords(146.17861938477, 345.91665649414)
    ini1 =
        inicfg.load(
        {
            Settings = {
               Key1 = 'VK_RBUTTON',
               Key2 = 'VK_X',
               FontName = 'Segoe UI',
               FontSize = 10,
               FontFlag = 13,
               X = x1,
               Y = y1,
               XX = x2,
               YY = y2,
               GPSkd = 30000,
               check_update = true
            }
        },
        adress.general
    )
    inicfg.save(ini1, adress.general)
    ini2 =
        inicfg.load(
        {
            Settings = {
               Skill = 1,
               SkillPrc = 1.1,
               Rank = 1,
               RankPrc = 1.1,
               OgranZP = 0
            }
        },
        adress.player
    )
    inicfg.save(ini1, adress.player)
	if not doesFileExist(adress.binder) then
		local text = "/service\nКуда?\nУдачи\n/t !id Ваш вызов актуален? Мне до вас !dist км\n/t !id Еду, мне до вас !dist км\n/t !id К сожалению я не могу приехать\n"
		file = io.open(adress.binder, "a")	
		file:write(text)
		file:flush()
		io.close(file)
	end
    if ini1.Settings.check_update then
        local fpath = os.getenv("TEMP") .. "\\TaxiHUD-version.txt"
        downloadUrlToFile("https://raw.githubusercontent.com/Serhiy-Rubin/TaxiHUD/master/version", fpath,
            function(id, status, p1, p2)
                if status == dlstatus.STATUS_ENDDOWNLOADDATA then
                    local f = io.open(fpath, "r")
                    if f then
                        local text = f:read("*a")
                        if text ~= nil then
                            if not string.find(text, tostring(thisScript().version)) then
                                sampAddChatMessage(
                                    ">> Вышло обновление для Taxi HUD, версия от " ..
                                        text .. ". Текущая версия от " .. thisScript().version,
                                    0xFF2f72f7
                                )
                                sampAddChatMessage(
                                    ">> Посмотреть список изменений: /taxi up. Включить/Выключить уведомления: /taxi ad",
                                    0xFF2f72f7
                                )
                                sampAddChatMessage(
                                    ">> Официальная страница Taxi HUD: https://vk.com/rubin.mods",
                                    0xFF2f72f7
                                )
                            end
                        end
                        io.close(f)
                    end
                end
            end
        )
    end
	font = renderCreateFont(ini1.Settings.FontName, ini1.Settings.FontSize, ini1.Settings.FontFlag)
	lua_thread.create(menu)
	while true do
		wait(0)
			ms = math.ceil(os.clock() * 1000 - antiflood)
			msGPS = math.ceil(os.clock() * 1000 - GPStime)
			if (now_upd ~= nil or (hud or control)) and ms > 2000 and not sampIsDialogActive() and not sampIsChatInputActive() then
				now_upd = 1
				if checkSkill == 1 then
					checkSkill = 2
					sampSendChat("/jskill")
				end
				if checkSkill == 0 and payCheck == 1 then
					payCheck = 2
					sampSendChat("/paycheck")
				end
				if checkSkill == 0 and payCheck == 0 and GPS and checkGPS == 1 then
					checkGPS = 2
					sampSendChat("/taxigps")
				end
				if GPS and checkGPS == 0 then
					if tonumber(msGPS) > tonumber(ini1.Settings.GPSkd) then
						checkGPS = 1
					end
				end
			end
	end
end

function menu()
	lua_thread.create(function()
		while true do
			wait(0)
			Noob = 0
			if hud or control then
				local Noobs = 0
				for id = 0, 999 do
					if sampIsPlayerConnected(id) then
						local score = sampGetPlayerScore(id)
						if score == 1 then 
							Noobs = Noobs + 1
						end
					end
				end
				if Noob ~= Noobs then Noob = Noobs end
			end
		end
	end)
	while true do
		wait(0)
		if sampIsChatVisible() and sampGetChatInputText() == "/q" and wasKeyPressed(13) then off = 1 end
		if off == nil and (hud or control) and not sampIsScoreboardOpen() and sampIsChatVisible() and not isKeyDown(116) and not isKeyDown(121) then
			local text = string.format("Скилл: %s (%s) (%s)\nРанг: %s (%s)\nЗарплата: %s / %s\nЧаевые: %s$", ini2.Settings.Skill, ini2.Settings.SkillPrc, passj, ini2.Settings.Rank, ini2.Settings.RankPrc, count, ini2.Settings.OgranZP, chai)
			local X = ini1.Settings.X
			local Y = ini1.Settings.Y
			if Click(font, string.format("Скилл: %s (%s) (%s)", ini2.Settings.Skill, ini2.Settings.SkillPrc, passj), X, Y) then
				if checkSkill == 0 then checkSkill = 1 end
			end
			Y = Y + renderGetFontDrawHeight(font)
			Click(font, string.format("Ранг: %s (%s)", ini2.Settings.Rank, ini2.Settings.RankPrc), X, Y)
			Y = Y + renderGetFontDrawHeight(font)
			if Click(font, string.format("Зарплата: %s$ / %s$", count, ini2.Settings.OgranZP), X, Y) then
				if payCheck == 0 then payCheck = 1 end
			end
			Y = Y + renderGetFontDrawHeight(font)
			if Click(font, string.format("Чаевые: %s$", chai), X, Y) then
				if payCheck == 0 then payCheck = 1 end
			end
			Y = Y + renderGetFontDrawHeight(font)
			if control and Click(font, "[Сменить позицию]", X, Y) then
				lua_thread.create(function() 
					wait(100)
					repeat
						wait(0)
						sampSetCursorMode(1)
						local X, Y = getCursorPos()
						ini1.Settings.X = X
						ini1.Settings.Y = Y
					until wasKeyPressed(1) 
					wait(100)
					inicfg.save(ini1, adress.general)
					sampSetCursorMode(0)
				end)
			end
			if GPS and #farm > 0 then
				local X = ini1.Settings.XX
				local Y = ini1.Settings.YY
				local ind = 0
				for k,string in pairs(farm) do
					local color = ""
					if msGPS < 1000 then color = "{12a61a}" end
					if msGPS > 2000 and msGPS < 3000 then color = "{12a61a}" end
					if Click(font, color..string, X, Y) and (GPSpos == nil or not GPSpos) then
						sampSendChat(string)
					end
					ind = ind + 1
					Y = Y + renderGetFontDrawHeight(font)
				end
				if control then
					if Click(font, "[Сменить позицию]", X, Y) then
						lua_thread.create(function() 
							wait(100)
							GPSpos = true
							repeat
								wait(0)
								sampToggleCursor(false)
								local X, Y = getCursorPos()
								ini1.Settings.XX = X
								ini1.Settings.YY = Y
								inicfg.save(ini1, adress.general)
							until wasKeyPressed(1) 
							wait(100)
							GPSpos = false
							sampToggleCursor(false)
						end)
					end
					Y = Y + renderGetFontDrawHeight(font)
					if Click(font, "[Обновить]", X, Y) then
						checkGPS = 1
					end
				end
			end
		end
		if isKeyDown(vkeys[ini1.Settings.Key1]) and (isTaxi() or isKeyDown(vkeys[ini1.Settings.Key2])) and not sampIsScoreboardOpen() and sampIsChatVisible() and not sampIsDialogActive() and not isKeyDown(116) and not isKeyDown(121) then
			sampSetCursorMode(3)
			local X, Y = getScreenResolution()
			if not control then 
				ffi.C.SetCursorPos((X / 2), (Y / 2)) 
				local f = io.open(adress.binder, 'r')
				if f then
					BindText = bind_read()
				end
			end
			control = true
			local ind = (renderGetFontDrawHeight(font) + (renderGetFontDrawHeight(font) / 10))
			Y = ((Y / 2.2) - (renderGetFontDrawHeight(font) * 3))
			if hud then string = "TaxiHUD: {12a61a}ON" else string = "TaxiHUD: {ff0000}OFF" end
			if Click(font, string, ((X / 2) - (renderGetFontDrawTextLength(font, string) / 2)), Y) then
				hud = not hud
			end
			Y = Y + ind
			if GPS then string = "TaxiGPS: {12a61a}ON" else string = "TaxiGPS: {ff0000}OFF" end
			if Click(font, string, ((X / 2) - (renderGetFontDrawTextLength(font, string) / 2)), Y) then
				GPS = not GPS
			end
			Y = Y + ind
			string = "Новички сервера ("..(Noob ~= nil and Noob or "0")..")"
			if Click(font, string, ((X / 2) - (renderGetFontDrawTextLength(font, string) / 2)), Y) then
				DialogNoob(1)
			end
			Y = Y + ind
			string = string.format("Настройки")
			if Click(font, string, ((X / 2) - (renderGetFontDrawTextLength(font, string) / 2)), Y) then
				DialogText(0)
			end
			Y = Y + ind + ind
			if Click(font, "{12a61a} Добавить строку", ((X / 2) - (renderGetFontDrawTextLength(font, "Добавить строку") / 2)), Y) then
				DialogText(2)
			end
			for i = 1, #BindText do
				Y = Y + ind
				local strings = BindText[i]:gsub("!id", id)
				local distance = getDistanceBetweenCoords3d(call_coord.x, call_coord.y, call_coord.z, getCharCoordinates(playerPed))
				local strings = strings:gsub("!dist", math.ceil(distance) / 1000)
				if Click(font, strings, ((X / 2) - (renderGetFontDrawTextLength(font, strings) / 2)), Y) then
					sampSendChat(strings)
				end
				if Click(font, "{ff0000}х", ((X / 2) + (renderGetFontDrawTextLength(font, strings.."  ") / 2)), Y) then
					DialogText(3, BindText[i])
				end
				if Click(font, "{12a61a}/", ((X / 2) + (renderGetFontDrawTextLength(font, strings.."        ") / 2)), Y) then
					DialogText(4, BindText[i])
				end
			end
		end
		if control and not isKeyDown(vkeys[ini1.Settings.Key1]) then
			control = false 
			sampSetCursorMode(0)
		end
	end
end

function sampev.onShowDialog(DdialogId, Dstyle, Dtitle, Dbutton1, Dbutton2, Dtext)
	if Dstyle == 2 and string.find(Dtitle, "Управление квестами") then
		if QuestRead ~= nil and QuestRead == 1 then
			QuestRead = 2
			sampSendDialogResponse(DdialogId, 1, 3, "")
			return false
		end
		if QuestRead ~= nil and QuestRead == 3 then
			QuestRead = 0
			DialogNoob(1)
			return false
		end
	end
	if Dstyle == 0 and Dtitle == 'Статистика' and QuestRead == 3 then
		local name, sl, qn, etap, progress = string.match(Dtext, '	Имя: {FFCC00}(.+){996633}.*================================.*.*{CC9933}%[Выполняется%].*{FFFFFF}	С.линия:{FFCC00} (.+){FFFFFF}.*	Квест:{FFCC00} (.+){FFFFFF}.*	Этап:{FFCC00} (.+){FFFFFF}.*	Прогресс:{FFCC00} (.+){FFFFFF}')
		if name ~= nil then
			local result = ''
			if sl:find('Гость') then
				local quest_list = {
					['1 / 5'] = 'Грузчики: '..progress,
					['2 / 5'] = 'Автошкола',
					['3 / 5'] = 'Ферма: '..progress,
					['4 / 5'] = 'Одежда',
					['5 / 5'] = 'Мэрия',
				}
				if quest_list[qn] ~= nil then
					result = 'Квест: '..quest_list[qn]
				end
			end
			noobQuest[name] = result
		end
		sampSendDialogResponse(DdialogId, 1, 0, '')
		return false
	end
	if Dstyle == 1 and string.find(Dtext, "Введите ID или Ник игрока") and string.find(Dtitle, "Ввод ID") then
		if QuestRead ~= nil and QuestRead == 2 then
			sampSendDialogResponse(DdialogId, 1, 0, NdialogID)
			QuestRead = 3
			return false
		end
	end
	if Dstyle == 0 and string.find(Dtext, "{00AB06}Таксист{CECECE}") then
		local line = 0
		for string in string.gmatch(Dtext, '[^\n]+') do
			line = line + 1
			if line == 5 then
				ini2.Settings.Skill, ini2.Settings.SkillPrc = string.match(string, "Скилл: (%d+)	Опыт: .+ (%d+%.%d+)%%")
				passj = math.ceil((100 - ini2.Settings.SkillPrc) / (((9600 / 100 * (1.1 ^ (50 - ini2.Settings.Skill))) * 100) / (10000 * (1.1 ^ ini2.Settings.Skill))))
			end
			if line == 6 then
				ini2.Settings.Rank, ini2.Settings.RankPrc = string.match(string, "{CECECE}Ранг: (%d+)  	Опыт: .+ (%d+%.%d+)%%")
			end
		end
		ini2.Settings.OgranZP = math.ceil(15000 + (500 * (1.1 ^ ini2.Settings.Skill)) + (500 * (1.1 ^ ini2.Settings.Rank)))
		inicfg.save(ini2, adress.player)
		if checkSkill == 2 then
			checkSkill = 0
			return false
		end
	end
	if Dstyle == 2 and string.find(Dtext, "{00AB06}Фермеров") and string.find(Dtext, "{00AB06}Прорабов") then
		local line = 0
		farm = {}
		for string in string.gmatch(Dtext, '[^\n]+') do
			line = line + 1
			if line == 1 then
				Prorab, Gruzchik = string.match(string, "%[0%] {FFFFFF}%[Грузчики%]  {00AB06}Прорабов (.+)  Рабочих (.+)")
				farm[#farm + 1] = string.format("Прорабов %s | Рабочих %s\n", Prorab, Gruzchik)
			else
				local numb, rab, cost = string.match(string, "%[.+%] {FFFFFF}%[Ферма №(.+)%]  {00AB06}Фермеров (.+)  {FFFF00}Цена за куст (.+)$")
				farm[#farm + 1] = string.format("Ферма №%s | Куст %s | Рабочих %s\n", numb, cost, rab)
			end
		end
		if checkGPS == 2 then
			checkGPS = 0
			GPStime = os.clock() * 1000
			return false
		end
	end
end
function sampev.onSendChat(message) antiflood = os.clock() * 1000 end
function sampev.onSendCommand(cmd)  antiflood = os.clock() * 1000 
	if cmd:lower() == "/taxi" then
		lua_thread.create(function() DialogText(0) end)
		return false
	elseif cmd:lower() == "/taxi up" then
            lua_thread.create(
                function()
                    local fpath = os.getenv("TEMP") .. "\\TaxiHUD-up.txt"
                    downloadUrlToFile(
                        "https://raw.githubusercontent.com/Serhiy-Rubin/TaxiHUD/master/changelog",
                        fpath,
                        function(id, status, p1, p2)
                            if status == dlstatus.STATUS_ENDDOWNLOADDATA then
                                local f = io.open(fpath, "r")
                                if f then
                                    local text = f:read("*a")
                                    if text ~= nil then
                                        sampShowDialog(222, "Changelog", "{FFFFFF}"..text, "Закрыть", "", 0)
                                    end
                                    io.close(f)
                                end
                            end
                        end
                    )
                end
            )
	elseif cmd:lower() == "/taxi ad" then
		ini1.Settings.check_update = not ini1.Settings.check_update
		printString((ini1.Settings.check_update and 'Check Update - ON' or 'Check Update - OFF'), 1000)
		inicfg.save(ini1, adress.general)
	end
end

function sampev.onSetRaceCheckpoint(type, position)
	call_coord = position
end

function sampev.onServerMessage(color, message) 
	if string.find(message, " Диспетчер: .+ принял вызов от .+") and string.find(message, nickname) then
		id = string.match(message, " Диспетчер: .+ принял вызов от .+%[(%d+)%]")
	end
	if message == " Не флуди!" then
		if checkSkill == 2 then checkSkill = 1 end
		if payCheck == 2 then payCheck = 1 end
		if checkGPS == 2 then checkGPS = 1 end
		if QuestRead ~= 0 then DialogNoob(1) QuestRead = 0 end
	end
	if string.find(message, " Вы заработали (.+) вирт%. Деньги будут зачислены на ваш банковский счет в .+") then
		local string = string.match(message, " Вы заработали (.+) вирт%. Деньги будут зачислены на ваш банковский счет в .+")
		count = string:find('/') and string:match('(%d+) /') or string
		if payCheck == 2 then
			payCheck = 0
			return false
		end 
	end
	if string.find(message, "Пассажир вышел из такси") then
		if checkSkill == 0 then checkSkill = 1 end
		if payCheck == 0 then payCheck = 1 end
	end
	if string.find(message, " Пассажир .+ сел в ваше Такси. Довезите его и государство заплатит вам") then
		local name = string.match(message, " Пассажир (.+) сел в ваше Такси. Довезите его и государство заплатит вам")
		passajir[name] = 1
	end
	if string.find(message, " Вы получили .+ вирт, от .+") then
		local money, name = string.match(message, " Вы получили (.+) вирт, от (.+)%[.+")
		if passajir[name] ~= nil then
			chai = chai + money
		end
	end
	if string.find(message, " Сейчас времени: (%d+):(%d+) часов") then 
		chai = 0
		count = 0
	end 
	if message == " Вы не таксист или не на службе" then
		if GPS then GPS = false end
		checkGPS = 0
	end
	if string.find(message, " Поздравляем! Ваш навык таксиста повышен до .+") then
		checkSkill = 1
	end
end

function DialogText(A1, A2)
	wait(100)
	if A1 == 0 then
		dialogText = string.format("Настройки активации\n- Кнопка отображения меню: %s\n- Кнопка для работы меню без такси: %s\nИнтервал обновления TaxiGPS: %s\n \nНастройки шрифта\n- Название шрифта: %s\n- Размер шрифта: %s\n- Стиль шрифта: %s", ini1.Settings.Key1:gsub("VK_", ''), ini1.Settings.Key2:gsub("VK_", ''), ini1.Settings.GPSkd, ini1.Settings.FontName, ini1.Settings.FontSize, ini1.Settings.FontFlag)
		ShowDialog("Настройки TAXI HUD", dialogText, "Выбрать", "Закрыть", 2, A1)
	end
	if A1 == 1 then
		if string.find(A2, "Key") then 
			ShowDialog("Настройки TAXI HUD", "{FFFFFF}Нажмите на нужную клавишу", "Выбрать", "Назад", 0, A1, A2)
			lua_thread.create(function() 
				stopThread = true
				wait(100)
				stopThread = false
				local key = ""
				repeat
					wait(0)
					for k, v in pairs(vkeys) do
						if wasKeyPressed(v) and k ~= "VK_ESCAPE" and k ~= "VK_RETURN" then 
							key = k 
						end
					end
				until key ~= "" 
				ini1.Settings[A2] = key
				inicfg.save(ini1, adress.general)
				wait(100)
				DialogText(0)
			end)
		else 
			local text = " "
			if A2 == "GPSkd" then text = "{FFFFFF}Введите интервал в МС!\n1 секунда это 1000 мс" end
			ShowDialog("Настройки TAXI HUD", text, "Выбрать", "Назад", 1, A1, A2)
		end
	end
	if A1 == 2 then
		ShowDialog("Биндер TAXI HUD", "{FFFFFF}Введите текст для биндера\n!id - заменится на ID человека чей вызов Вы приняли\n!dist - заменится на дистанцию до метки вызова", "Выбрать", "Закрыть", 1, A1)
	end
	if A1 == 3 then
		local file = io.open(adress.binder, "r")
		local fileText = ""
		if file ~= nil then
			for line in file:lines() do
				if line ~= A2 then
					fileText = fileText..line.."\n"
				end
			end	
			io.close(file)
		end
		file = io.open(adress.binder, "w") 
		file:write(fileText)
		file:flush()
		io.close(file)
		local f = io.open(adress.binder, 'r')
		if f then
			BindText = bind_read()
		end
	end
	if A1 == 4 then
		ShowDialog("Биндер TAXI HUD", " ", "Выбрать", "Закрыть", 1, A1, A2)
	end
end

function bind_read()
	local f = io.open(adress.binder, 'r')
	local array = {}
	if f then
		for line in f:lines() do
			array[#array + 1] = line
		end
		io.close(f)
	end
	return array
end

function ShowDialog(Caption, dialogText, button1, button2, style, A1, A2, A3)
	sampShowDialog(0, Caption, dialogText, button1, button2, style)
	lua_thread.create(function() 
		stopThread = true
		wait(100)
		stopThread = false
		if A1 == 1 then sampSetCurrentDialogEditboxText(ini1.Settings[A2]) end
		if A1 == 4 then sampSetCurrentDialogEditboxText(A2) end
		repeat
			wait(0)
			local result, button, list, input = sampHasDialogRespond(0)
			if result then
				if A1 == 0 then
					if button == 1 then
						Key = { [1] = "Key1", [2] = "Key2", [3] = "GPSkd", [6] = "FontName", [7] = "FontSize", [8] = "FontFlag" }
						if Key[list] ~= nil then
							DialogText(1, Key[list])
						else
							DialogText(0)
						end
					end
				end
				if A1 == 1 then
					if button == 1 and #input > 0 and A2 ~= nil then 
						ini1.Settings[A2] = input
						inicfg.save(ini1, adress.general)
						font = renderCreateFont(ini1.Settings.FontName, ini1.Settings.FontSize, ini1.Settings.FontFlag)
					end
					DialogText(0)
				end
				if A1 == 2 then
					if button == 1 and #input > 0 then
						local file = io.open(adress.binder, "a")	
						file:write(input.."\n")
						file:flush()
						io.close(file)
					end
				end
				if A1 == 4 then
					if button == 1 and #input > 0 then
						local file = io.open(adress.binder, "r")
						local fileText = ""
						if file ~= nil then
							for line in file:lines() do
								if line == A2 then
									line = input
								end
								fileText = fileText..line.."\n"
							end	
							io.close(file)
						end
						file = io.open(adress.binder, "w") 
						file:write(fileText)
						file:flush()
						io.close(file)
					end
				end
			end
		until not sampIsDialogActive() or stopThread
	end)
end

function DialogNoob(int)
	if int == 1 then
		stopThread = true
		local text = ""
		Ndialog = {}
		NdialogInput = {}
		for id = 0, 999 do
			if sampIsPlayerConnected(id) then
				local score = sampGetPlayerScore(id)
				if score == 1 then
					local name = sampGetPlayerNickname(id)
					NdialogInput[#NdialogInput + 1] = id
					text = text..name.."("..id..")\t"..(noobQuest[name] ~= nil and noobQuest[name] or ' ')..'\n'
				end
			end
		end
		sampShowDialog(2894, "Новички сервера", text, "Выбрать", "Закрыть", 4)
		lua_thread.create(function()
			wait(100)
			stopThread = false
			repeat
				wait(0)
				local result, button, list, input = sampHasDialogRespond(2894)
				if result and sampGetDialogCaption() == "Новички сервера"  then
					if button == 1 and NdialogInput[list + 1] ~= nil then
						NdialogID = NdialogInput[list + 1]
						QuestRead = 1
						sampSendChat("/quest")
					end
				end
			until not sampIsDialogActive() or stopThread
		end)
	end
end

function Click(font, text, posX, posY)
   renderFontDrawText(font, "{e4ed3e}"..text, posX, posY, 0xFFFFFFFF)
   local textLenght = renderGetFontDrawTextLength(font, text)
   local textHeight = renderGetFontDrawHeight(font)
   local curX, curY = getCursorPos()
   if curX >= posX and curX <= posX + textLenght and curY >= posY and curY <= posY + textHeight and control then
   	 renderFontDrawText(font, text, posX, posY, 0xFFFFFFFF)	
     if isKeyJustPressed(1) then
       return true
     end
   end
end

function isTaxi()
	if (isCharInModel(PLAYER_PED, 420) or isCharInModel(PLAYER_PED, 438) or isCharInModel(PLAYER_PED, 405) or isCharInModel(PLAYER_PED, 560) or isCharInModel(PLAYER_PED, 402)) and getDriverOfCar(getCarCharIsUsing(playerPed)) == playerPed then 
		local Vehicle = storeCarCharIsInNoSave(PLAYER_PED)
		local Color1, Color2 = getCarColours(Vehicle)
		if Color1 == 6 then
			return true
		else
			return false
		end
	else 
		return false 
	end
end