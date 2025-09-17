local script_name = 'corn-hud'
local script_author = 'Serhiy_Rubin'
local script_version = '30.06.2023'
require 'lib.sampfuncs'
require 'lib.moonloader'
dlstatus = require("moonloader").download_status
vkeys = require "lib.vkeys"
sampev, inicfg = require 'lib.samp.events', require 'inicfg'
render, antiflood = false, 0
zerno, urojai, narko, priceZerno, priceUrojai, priceNarko, finfoCheck = 0, 0, 0, 0, 0, 0, 0
coord = {
	['Farm 0'] = {x = -379.220367, y = -1425.855591, z = 25.862316 },
	['Farm 1'] = {x = -116.514381, y = 2.906076, z = 3.227722 },
	['Farm 2'] = {x = -1055.663330, y = -1203.198486, z = 129.136978 },
	['Farm 3'] = {x = -0.693013, y = 74.493423, z = 3.231136 },
	['Farm 4'] = {x = 1912.754150, y = 176.559540, z = 37.375542 },
	['Narko'] = {x = 2182.483887, y = -1657.505615, z = 15.201279 },
	['Zerno'] = {x = 2206.272949, y = -2245.668457, z = 13.661810 },
	['Urojai'] = {x = 972.86, y = 2105.53, z = 10.94 }
}

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	while not isSampAvailable() do wait(0) end
    --lua_thread.create(script_update.main)
    repeat wait(0) until sampGetCurrentServerName() ~= "SA-MP"
    repeat wait(0) until sampGetCurrentServerName():find("Samp%-Rp.Ru") or sampGetCurrentServerName():find("SRP")
    server = sampGetCurrentServerName():gsub("|", "")
    server =
        (server:find("02") and "Two" or
        (server:find("Revo") and "Revolution" or
            (server:find("Legacy") and "Legacy" or (server:find("Classic") and "Classic" or
        (server:find("Two") and "Two" or 
        (server:find("TEST") and "TEST" or 
        (server:find("Underground") and "Underground" or "" )))))))
    if server == "" then
        thisScript():unload()
    end
	iniName = string.format("corn-%s", server)
	local x1, y1 = convertGameScreenCoordsToWindowScreenCoords(14.992679595947, 274.75)
	ini = inicfg.load({
		['Farm 0'] = {
			corn = 0,
			cornPrice = 0,
			product = 0,
			productPrice = 0,
			bank = 0
		},
		['Farm 1'] = {
			corn = 0,
			cornPrice = 0,
			product = 0,
			productPrice = 0,
			bank = 0
		},
		['Farm 2'] = {
			corn = 0,
			cornPrice = 0,
			product = 0,
			productPrice = 0,
			bank = 0
		},
		['Farm 3'] = {
			corn = 0,
			cornPrice = 0,
			product = 0,
			productPrice = 0,
			bank = 0
		},
		['Farm 4'] = {
			corn = 0,
			cornPrice = 0,
			product = 0,
			productPrice = 0,
			bank = 0
		},
		price = {
			zerno = 0,
			urojai = 0,
			narko = 0
		},
		Render = {
			FontName='Segoe UI',
			FontSize=10,
			FontFlag=15,
			Color1='2f72f7',
			Color2='FFFFFF'
		},
		Settings = {
			Key1='VK_RBUTTON',
			Key2='VK_MENU',
			X=x1,
			Y=y1
		},
	}, iniName)
	inicfg.save(ini, iniName)
	sampfuncsLog(' {FFFFFF}corn-hud loaded. CMD: /corn | /corn hud. | Key combo: '..ini.Settings.Key1:gsub("VK_", '')..' + '..ini.Settings.Key2:gsub("VK_", ''))
	font = renderCreateFont(ini.Render.FontName, ini.Render.FontSize, ini.Render.FontFlag)
	lua_thread.create(menu.loop)
	while true do
		wait(0)
		points = ''
		for k,v in pairs(coord) do
			local dist = math.floor(getDistanceBetweenCoords3d(v.x, v.y, v.z, getCharCoordinates(playerPed)))
			if dist <= 30 then
				points = k
			end
		end
		if finfoCheck == 1 then
			if points:find('Farm') then
				if math.ceil(os.clock() * 1000 - antiflood) > 999 then
					finfoCheck = 2
					sampSendChat('/finfo')
				end
			else
				finfoCheck = 0
			end
		end
		if render then
			renderText = {
				[1] = '{00D900}Цена покупки зерна: '..ini.price.zerno..'$',
				[2] = '{00D900}Цена продажи урожая: '..ini.price.urojai..'$',
				[3] = '{00D900} ',
				[4] = string.format('{00D900}Ферма №0 | Баланс: %d$ | Зерно: %d [%d$] | Урожай: %d [%d$]', ini['Farm 0'].bank,  ini['Farm 0'].corn, ini['Farm 0'].cornPrice, ini['Farm 0'].product, ini['Farm 0'].productPrice),
				[5] = string.format('{00D900}Ферма №1 | Баланс: %d$ | Зерно: %s [%s$] | Урожай: %s [%s$]', ini['Farm 1'].bank,  ini['Farm 1'].corn, ini['Farm 1'].cornPrice, ini['Farm 1'].product, ini['Farm 1'].productPrice),
				[6] = string.format('{00D900}Ферма №2 | Баланс: %d$ | Зерно: %s [%s$] | Урожай: %s [%s$]', ini['Farm 2'].bank,  ini['Farm 2'].corn, ini['Farm 2'].cornPrice, ini['Farm 2'].product, ini['Farm 2'].productPrice),
				[7] = string.format('{00D900}Ферма №3 | Баланс: %d$ | Зерно: %s [%s$] | Урожай: %s [%s$]', ini['Farm 3'].bank,  ini['Farm 3'].corn, ini['Farm 3'].cornPrice, ini['Farm 3'].product, ini['Farm 3'].productPrice),
				[8] = string.format('{00D900}Ферма №4 | Баланс: %d$ | Зерно: %s [%s$] | Урожай: %s [%s$]', ini['Farm 4'].bank, ini['Farm 4'].corn, ini['Farm 4'].cornPrice, ini['Farm 4'].product, ini['Farm 4'].productPrice),
			}
			local X, Y = ini.Settings.X, ini.Settings.Y
			for i = 1, #renderText do
				renderFontDrawText(font, renderText[i], X, Y, -1)
				if i ~= 3 then
					Y = Y + (renderGetFontDrawHeight(font) - (renderGetFontDrawHeight(font) / 5))
				else
					Y = Y + (renderGetFontDrawHeight(font) / 5)
				end
			end
		end
		if isKeyDown(vkeys[ini.Settings.Key1]) and (isCharInModel(PLAYER_PED, 440) or isKeyDown(vkeys[ini.Settings.Key2])) then
			sampSetCursorMode(3)
			mouse = 1
			local posX, posY = getScreenResolution()
			local plus = (renderGetFontDrawHeight(font) + (renderGetFontDrawHeight(font) / 10))
			posX = posX / 2
			posY = ((posY / 2.2) - (renderGetFontDrawHeight(font) * 3))
			renderText = {
				[1] = (render and 'Corn-HUD: ON' or 'Corn-HUD: OFF'),
				[2] = 'Загрузить',
				[3] = 'Разгрузить',
				[4] = 'Информация о ферме',
				[5] = 'Обновить информацию о ферме'
			}
			for i = 1, #renderText do
				if drawClickableText(renderText[i], posX - (renderGetFontDrawTextLength(font, renderText[i]) / 2), posY, 0xFF00D900, 0xFFFFFFFF) then
					if i == 1 then
						render = not render
					end
					if i == 2 then
						if points ~= '' then
							if points:find('Farm') then
								local warecorn = urojai
								local corn = ( (1500 - warecorn) < tonumber(ini[points].product) and (1500 - warecorn) or tonumber(ini[points].product) )
								sampSendChat('/cornmenu 2 '..corn)
								finfoCheck = 1
							end
							if points:find('Zerno') then
								sampSendChat('/cornmenu 0 '..(1500 - zerno))
							end
						end
					end
					if i == 3 then
						if points ~= '' then
							if points:find('Farm') then
								sampSendChat('/cornmenu 1 '..(zerno > (10000 - ini[points].corn) and (10000 - ini[points].corn) or zerno))
								finfoCheck = 1
							end
							if points:find('Narko') then
								sampSendChat('/cornmenu 4 '..narko)
							end
							if points:find('Urojai') then
								sampSendChat('/cornmenu 4 '..urojai)
							end
						end
					end
					if i == 4 then
						sampSendChat('/finfo')
					end
					if i == 5 then
						finfoCheck = 1
					end
				end

				posY = posY + plus
			end
		else
			if mouse ~= nil and mouse == 1 then
				sampSetCursorMode(0)
				mouse = nil
			end
		end
	end
end

function sampev.onServerMessage(color, message)
	if message:find(' Зерно: (%d+) / 1500') then
		zerno = tonumber(message:match(' Зерно: (%d+) / 1500'))
	end
	if message:find(' Урожай: (%d+) / 1500') then
		urojai = tonumber(message:match(' Урожай: (%d+) / 1500'))
	end
	if message:find(' Наркотики: (%d+) / 1500') then
		narko = tonumber(message:match(' Наркотики: (%d+) / 1500'))
	end
end

function sampev.onCreate3DText(id, color, position, distance, testLOS, attachedPlayerId, attachedVehicleId, text)
	if text:find('{FF8000}Разгрузка наркотиков.*Стоимость наркотиков (%d+) вирт') then
		ini.price.narko = text:match('{FF8000}Разгрузка наркотиков.*Стоимость наркотиков (%d+) вирт')
		inicfg.save(ini, iniName)
	end
	if text:find('{FF8000}Загрузка зерна.*Стоимость зерна (%d+) вирт.+') then
		ini.price.zerno = text:match('{FF8000}Загрузка зерна.*Стоимость зерна (%d+) вирт.+')
		inicfg.save(ini, iniName)
	end
	if text:find('{FF8000}Разгрузка урожая.*Стоимость урожая (%d+) вирт') then
		ini.price.urojai = text:match('{FF8000}Разгрузка урожая.*Стоимость урожая (%d+) вирт')
		inicfg.save(ini, iniName)
	end
end

function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
	if text:find(".FBDD7E.Баланс фермы:.FFFFFF.\t\t\t(%d+).+FBDD7E.Семена в амбаре:.FFFFFF.\t\t\t(%d+) / %d+.+FBDD7E.Урожая на поле:{FFFFFF}\t\t\t(%d+) / %d+.+FBDD7E.Продукции в амбаре:.FFFFFF.\t\t\t(%d+) / %d+.+FBDD7E.Цена за семена:.FFFFFF.\t\t\t(%d+).+FBDD7E.Цена на продукцию:.FFFFFF.\t\t\t(%d+)") then
		local S0 = CheckCoord()
		if S0 ~= '' then
			ini[S0].bank, ini[S0].corn, ini[S0].product, ini[S0].cornPrice, ini[S0].productPrice = text:match(".FBDD7E.Баланс фермы:.FFFFFF.\t\t\t(%d+).+FBDD7E.Семена в амбаре:.FFFFFF.\t\t\t(%d+) / %d+.+FBDD7E.Урожая на поле:{FFFFFF}\t\t\t%d+ / %d+.+FBDD7E.Продукции в амбаре:.FFFFFF.\t\t\t(%d+) / %d+.+FBDD7E.Цена за семена:.FFFFFF.\t\t\t(%d+).+FBDD7E.Цена на продукцию:.FFFFFF.\t\t\t(%d+)")
			inicfg.save(ini, iniName)
			if finfoCheck ~= 0 then
				finfoCheck = 0
				return false
			end
		end
	end
	if text:find('{FFFFFF}Зерна куплено: {0289CC}(%d+).*{FFFFFF}Цена: {0289CC}%d+ вирт.*{FFFFFF}Скидка: {0289CC}%d+ вирт') then
		zerno = zerno + tonumber(text:match('{FFFFFF}Зерна куплено: {0289CC}(%d+).*{FFFFFF}Цена: {0289CC}%d+ вирт.*{FFFFFF}Скидка: {0289CC}%d+ вирт'))
		print(zerno)
	end
	if text:find('{FFFFFF}Зерна продано: {0289CC}(%d+).*{FFFFFF}Цена: {0289CC}%d+ вирт.*{FFFFFF}Добавлено к ЗП: {0289CC}%d+ вирт') then
		zerno = zerno - tonumber(text:match('{FFFFFF}Зерна продано: {0289CC}(%d+).*{FFFFFF}Цена: {0289CC}%d+ вирт.*{FFFFFF}Добавлено к ЗП: {0289CC}%d+ вирт'))
		print(zerno)
	end
	if text:find('{FFFFFF}Урожая куплено: {0289CC}(%d+).*{FFFFFF}Цена: {0289CC}%d+ вирт') then
		urojai = urojai + tonumber(text:match('{FFFFFF}Урожая куплено: {0289CC}(%d+).*{FFFFFF}Цена: {0289CC}%d+ вирт'))
		print(urojai)
	end
	if text:find('Урожая продано: {0289CC}(%d+).*{FFFFFF}Цена: {0289CC}%d+ вирт') then
		urojai = urojai - tonumber(text:match('Урожая продано: {0289CC}(%d+).*{FFFFFF}Цена: {0289CC}%d+ вирт'))
		print(urojai)
	end
	if text:find('{FFFFFF}Наркотиков куплено: {0289CC}(%d+).*{FFFFFF}Цена: {0289CC}%d+ вирт') then
		narko = narko + tonumber(text:match('{FFFFFF}Наркотиков куплено: {0289CC}(%d+).*{FFFFFF}Цена: {0289CC}%d+ вирт'))
	end
	if text:find('Наркотиков продано: {0289CC}(%d+)') then
		narko = narko - tonumber(text:match('Наркотиков продано: {0289CC}(%d+)'))
	end
end

function sampev.onSendChat(message) antiflood = os.clock() * 1000 end
function sampev.onSendCommand(cmd) antiflood = os.clock() * 1000 end

function CheckCoord()
	for k,v in pairs(coord) do
		local dist = math.floor(getDistanceBetweenCoords3d(v.x, v.y, v.z, getCharCoordinates(playerPed)))
		if dist <= 30 then
			return k
		end
	end
	return ''
end

function drawClickableText(text, posX, posY, Color1, Color2)
    if text ~= nil and posX ~= nil and posY ~= nil then
        renderFontDrawText(font, text, posX, posY, Color1)
        local textLenght = renderGetFontDrawTextLength(font, text)
        local textHeight = renderGetFontDrawHeight(font)
        local curX, curY = getCursorPos()
        if curX >= posX and curX <= posX + textLenght and curY >= posY and curY <= posY + textHeight then
			renderFontDrawText(font, text, posX, posY, Color2)
			if isKeyJustPressed(1) then
				return true
			else
				return false
			end
        end
    else
        return false
    end
end

-->> MENU
menu = {}

function menu.get()
	return {
		{
			settings = {title = "corn-hud" ,style = 4 ,btn1 = "Выбрать" ,btn2 = "Закрыть" ,forward =  "{ffffff}" ,backwards = "\n" ,score = true},
			{
				{
					title = 'HUD\t'..(render and "ON" or "OFF"),
					click = function(button, list, input , outs)
						if button ~= 1 then return end
						render = not render
						showMenu = true
					end
				},
				{
					title = 'Сменить позицию\t',
					click = function(button, list, input , outs)
						if button ~= 1 then return end
						if not render then
							render = true
						end
						wait(200)
						repeat
							wait(0)
							sampSetCursorMode(3)
							local X, Y = getCursorPos()
							ini.Settings.X = X
							ini.Settings.Y = Y
						until isKeyJustPressed(1)
							inicfg.save(ini, iniName)
						sampSetCursorMode(0)
						showMenu = true
					end
				},
				{
					title = 'Клавиша №1\t'..ini.Settings.Key1:gsub("VK_", ""),
					click = function(button, list, input , outs)
						if button ~= 1 then return end
						wait(200)
						local key = ""
						repeat
							wait(0)
							if not sampIsDialogActive() then
								sampShowDialog(0, "Смена активации", "Нажмите на любую клавишу", "Выбрать", "Закрыть", 0)
							end
							for k, v in pairs(vkeys) do
								if wasKeyPressed(v) and k ~= "VK_ESCAPE" and k ~= "VK_RETURN" then
									key = k
								end
							end
						until key ~= ""
						ini.Settings.Key1 = key
						inicfg.save(ini, iniName)
						showMenu = true
					end
				},
				{
					title = 'Клавиша №2\t'..ini.Settings.Key2:gsub("VK_", ""),
					click = function(button, list, input , outs)
						if button ~= 1 then return end
						wait(200)
						local key = ""
						repeat
							wait(0)
							if not sampIsDialogActive() then
								sampShowDialog(0, "Смена активации", "Нажмите на любую клавишу", "Выбрать", "Закрыть", 0)
							end
							for k, v in pairs(vkeys) do
								if wasKeyPressed(v) and k ~= "VK_ESCAPE" and k ~= "VK_RETURN" then
									key = k
								end
							end
						until key ~= ""
						ini.Settings.Key2 = key
						inicfg.save(ini, iniName)
						showMenu = true
					end
				},
			}
		}
	}
end

function menu.loop()
	showMenu = false
	sampRegisterChatCommand('corn', function(param)
		showMenu = true
	end)
	while true do
		wait(0)
		if showMenu then
			showMenu = false
			menu.dialog = menu.get()
			start_dialog(menu.dialog[1])
		end
	end
end

function start_dialog(menu) -- module by trefa
    function _dialog(menu, id,  outs)
        sampShowDialog(id, menu.settings.title, tbl_split(menu.settings.style, menu, menu.settings.forward ,menu.settings.backwards ,menu.settings.score), menu.settings.btn1, (menu.settings.btn2 ~= nil and menu.settings.btn2 or _), menu.settings.style)
            repeat
                wait(0)
                local result, button, list, input = sampHasDialogRespond(id)
                if result then
                    local out, outs = menu[((menu.settings.style == 0 or menu.settings.style == 1 or menu.settings.style == 3) and 1 or ((list + 1) > #menu[1] and 2 or 1))][((menu.settings.style == 0 or menu.settings.style == 1 or menu.settings.style == 3) and 1 or ((list + 1) > #menu[1] and (list - #menu[1]) + 1  or list + 1))].click(button, list, input, outs)
                    if type(out) == "table" then
                        return _dialog(out, id - 1, outs)
                    elseif type(out) == "boolean" then
                        if not out then
                            return out
                        end
                            return _dialog(menu, id, outs)
                    end
                end
            until result
    end

    function tbl_split(style, tbl, forward ,backwards ,score)
        if style == 2 or style == 4 or style == 5 then
            text = (style == 5 and tbl[1].text.."\n" or "")
            for i, val in ipairs(tbl[1]) do
                text = text..""..forward..""..(score and "["..(i-1).."] " or "")..""..val.title..""..backwards
            end
            if tbl[2] ~= nil then
                for _, val in ipairs(tbl[2]) do
                    text = text..""..forward..""..val.title..""..backwards
                end
            end
            return text
        end
        return tbl[1].text
    end

    return _dialog(menu, 1337, outs)
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
    version_url = "http://git.deadpoo.net/rubin/corn-hud/raw/branch/master/version",
    script_url = "http://git.deadpoo.net/rubin/corn-hud/raw/branch/master/corn-hud.lua",
    changelog_url = "http://git.deadpoo.net/rubin/corn-hud/raw/branch/master/changelog",
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
utf8({ "sampHasDialogRespond" }, nil, "AnsiToUtf8")
utf8({ "sampev", "onShowDialog" }, "AnsiToUtf8", "Utf8ToAnsi")
utf8({ "sampev", "onServerMessage" }, "AnsiToUtf8", "Utf8ToAnsi")
utf8({ "sampev", "onCreate3DText" }, "AnsiToUtf8", "Utf8ToAnsi")