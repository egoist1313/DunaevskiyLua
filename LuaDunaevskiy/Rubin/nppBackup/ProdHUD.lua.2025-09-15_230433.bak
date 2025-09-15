script_name('ProdHUD')
script_authors("rubin")
script_version("23.11.2024")
samp = require 'samp.events'
local inicfg = require 'inicfg'
dlstatus = require("moonloader").download_status

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	while not isSampAvailable() do wait(100) end
	iniLoad()
	font = renderCreateFont(ini.settings.font_name, ini.settings.font_size, ini.settings.font_flag)
    lua_thread.create(script_update.main)
    loadEvents()
	while true do
		wait(0)
		doRenderMenu()
		doBuyMode()
		doSendDialog()
		doCheckMonMode()
	end
end

function loadEvents()
	function samp.onServerMessage(color, message)
		if message:find("Вы должны находиться на складе, с выбранным вами типом бизнеса") or
		message:find("Неверно указано количество") or
		message:find("В фургоне нет места") or
		message:find("У вас нет продуктов") or
		message:find("Нужно находиться рядом с бизнесом, которому хотите продать") or
		message:find("У вас недостаточно денег") or
		(isCar() and message:find("Вы заработали %d+ вирт, из которых %d+ вирт будет добавлено к вашей зарплате")) then
			if buyMode ~= nil then scip = true end
			buyMode = nil
			if checkMon ~= nil then
				return false
			end
		end
		if string.find(message, " Еда: (%d+) / (%d+)") then
			prod.food, prod_count = string.match(message, " Еда: (%d+) / (%d+)")
			if prod_count == prod.food and buyMode then scip = true end
			if prod.food == "0" and buyMode then scip = true end
			buyMode = nil
		end
		if string.find(message, " Бензин: (%d+) / (%d+)") then
			prod.benz, prod_count = string.match(message, " Бензин: (%d+) / (%d+)")
			if prod_count == prod.benz and buyMode then scip = true end
			if prod.benz == "0" and buyMode then scip = true end
			buyMode = nil
		end
		if string.find(message, " Товары: (%d+) / (%d+)") then
			prod.products, prod_count = string.match(message, " Товары: (%d+) / (%d+)")
			if prod_count == prod.products and buyMode then scip = true end
			if prod.products == "0" and buyMode then scip = true end
			buyMode = nil
		end
		if string.find(message, " Алкоголь: (%d+) / (%d+)") then
			prod.alcohol, prod_count = string.match(message, " Алкоголь: (%d+) / (%d+)")
			if prod_count == prod.alcohol and buyMode then scip = true end
			if prod.alcohol == "0" and buyMode then scip = true end
			buyMode = nil
		end
	end

	function samp.onShowDialog(DdialogId, Dstyle, Dtitle, Dbutton1, Dbutton2, Dtext)
		dialogActiveTime = os.clock() * 1000
		if buyMode ~= nil or (buyMode == nil and scip ~= nil) then
			if Dtitle:find("Развозчик продуктов") then
				if scip == nil then
					send_dialog = { time = os.clock() * 1000, id = DdialogId, button = 1, listitem = (sell and 1 or 0), input = "" }
				end
				return false
			end
			if Dtext:find("Бары и клубы") and Dtext:find("Заправки") then
				if scip == nil then
					local list = { alcohol = 0, benz = 1, products = 3, food = 2 }
					send_dialog = { time = os.clock() * 1000, id = DdialogId, button = 1, listitem = list[buyMode], input = "" }
					exit_time = os.clock() * 1000
				end
				return false
			end
			if Dtitle:find("Ввод параметра") and Dtext:find("Введите количество продуктов от %d+ до (%d+)") then
				if scip == nil then
					local count = tonumber(Dtext:match("Введите количество продуктов от %d+ до (%d+)")) - prod[buyMode]
					send_dialog = { time = os.clock() * 1000, id = DdialogId, button = 1, listitem = 0, input = tostring(count) }
				end
				return false
			end
			if Dtitle:find("Сообщение") and Dtext:find("Стоимость")and Dtext:find("Количество") then
				if scip == nil then
					send_dialog = { time = os.clock() * 1000, id = DdialogId, button = 1, listitem = 0, input = "" }
				end
				return false
			end
		elseif exit_time ~= nil then
			if (Dtext:find("Бары и клубы") and Dtext:find("Заправки")) or Dtitle:find("Развозчик продуктов") then
				if os.clock() * 1000 - exit_time < 1000 then
					send_dialog = { time = os.clock() * 1000, id = DdialogId, button = 0, listitem = 0, input = "" }
				end
			end
		end
		if DdialogId == 22 and Dstyle == 0 and Dtitle == "Сообщение" and string.find(Dtext, "Бизнес") and string.find(Dtext, "Сколько может купить") then
			if string.find(Dtext, "Cluc") or string.find(Dtext, "Pizza") or string.find(Dtext, "Cluck") or string.find(Dtext, "Burger") then
				monArray["food"] = Dtext
			elseif string.find(Dtext, "24%-7") then
				monArray["products"] = Dtext
			elseif string.find(Dtext, "gas") or string.find(Dtext, "Gas") or string.find(Dtext, "Gsa") then
				monArray["benz"] = Dtext
			else
				monArray["alcohol"] = Dtext
			end
			if checkMon ~= nil then
				send_dialog = { time = os.clock() * 1000, id = DdialogId, button = 0, listitem = 0, input = "" }
				return false
			end
		end
		if checkMon ~= nil then
			if Dtitle:find("Развозчик продуктов") then
				if scip == nil then
					send_dialog = { time = os.clock() * 1000, id = DdialogId, button = 1, listitem = 2, input = "" }
				end
				return false
			end
			if Dtitle:find("Мониторинг") then
				if checkMon == "" then
					checkMon = nil
					return false
				end
				if scip == nil then
					local arr_sled = { alcohol = "benz", benz = "food", food = "products", products = "" }
					local arr_button = { alcohol = 0, benz = 1, food = 2, products = 3 }
					send_dialog = { time = os.clock() * 1000, id = DdialogId, button = 1, listitem = arr_button[checkMon], input = "" }
					checkMon = arr_sled[checkMon]
				end
				return false
			end
		end
		if Dtitle:find("GPS") and bizname ~= nil then
			local arr_sled = { alcohol = 2, benz = 8, food = 10, products = 9 }
			send_dialog = { time = os.clock() * 1000, id = DdialogId, button = 1, listitem = arr_sled[monMode], input = "" }
			return false
		end
		if (bizname ~= nil or ( bizname == nil and scip ~= nil)) and (Dtitle:find("Бензозаправки") or Dtitle:find("Магазины") or Dtitle:find("Бары") or Dtitle:find("Закусочные") ) then
			if scip ~= nil then
				scip = nil
				return false
			end
			local arr = split(Dtext, "\n")
			local result = -1
			for i = 1, #arr do
				local str = arr[i]:gsub("%-", " ")
				local findText = bizname:gsub("%-", " ")

				if monMode == "benz" and not findText:find("Emerald") and not findText:find("Tierra") then
					bizname = string.gsub(bizname, " ", "")
				end

				if str:gsub("%-", " "):find(findText) then
					result = i - 1
					break
				end
			end
			if result ~= -1 then
				scip = true
				send_dialog = { time = os.clock() * 1000, id = DdialogId, button = 1, listitem = result, input = "" }
			else
				sampAddChatMessage(bizname, -1)
			end
			bizname = nil
			return false
		end

		scip = nil
	end

	utf8({ "samp", "onShowDialog" }, "AnsiToUtf8", "Utf8ToAnsi")
	utf8({ "samp", "onServerMessage" }, "AnsiToUtf8", "Utf8ToAnsi")
end

function isCar()
	if isCharInModel(PLAYER_PED, 455) or isCharInModel(PLAYER_PED, 459) or isCharInModel(PLAYER_PED, 552) or isCharInModel(PLAYER_PED, 414) or isCharInModel(PLAYER_PED, 456) then
		return true
	end
end

-->> RENDER MENU
function doRenderMenu()
	if not isCar() or sampIsDialogActive() or sampIsChatInputActive() or not isKeyDown(2) then
		if control then
			sampSetCursorMode(0)
		end
		control = false
		return
	end
	if not control then
		control = true
	end
	sampSetCursorMode(3)
	-->> Render MENU
	local height = renderGetFontDrawHeight(font)
	local plus = height + (height / 4)
	local X, Y = getScreenResolution()
	Y = ((Y / 2.0) - (height * 3))
	local textLength = renderGetFontDrawTextLength(font, "Продать для Закусочной")
	renderDrawBox((X - textLength), Y, textLength, (plus * 11), 0x80000000)
	local x, y = (X - textLength) - 72, Y
	for i = 10, 80 do
		x = x + 1
		local color = string.format("0x%d000000", i)
		renderDrawBox(x, y, 1, (plus * 11), color)
	end
	string = "Купить для Бара"
	if drawClickableText(string, (X  - renderGetFontDrawTextLength(font, string.."  ")), Y) then
		sell = false
		buyMode = "alcohol"
	end
	Y = Y + plus
	string = "Продать для Бара"
	if drawClickableText(string, (X  - renderGetFontDrawTextLength(font, string.."  ")), Y) then
		sell = true
		buyMode = "alcohol"
	end
	Y = Y + plus + plus
	string = "Купить для Заправки"
	if drawClickableText(string, (X  - renderGetFontDrawTextLength(font, string.."  ")), Y) then
		sell = false
		buyMode = "benz"
	end
	Y = Y + plus
	string = "Продать для Заправки"
	if drawClickableText(string, (X  - renderGetFontDrawTextLength(font, string.."  ")), Y) then
		sell = true
		buyMode = "benz"
	end
	Y = Y + plus + plus
	string = "Купить для Магазина"
	if drawClickableText(string, (X  - renderGetFontDrawTextLength(font, string.."  ")), Y) then
		sell = false
		buyMode = "products"
	end
	Y = Y + plus
	string = "Продать для Магазина"
	if drawClickableText(string, (X  - renderGetFontDrawTextLength(font, string.."  ")), Y) then
		sell = true
		buyMode = "products"
	end
	Y = Y + plus + plus
	string = "Купить для Закусочной"
	if drawClickableText(string, (X  - renderGetFontDrawTextLength(font, string.."  ")), Y) then
		sell = false
		buyMode = "food"
	end
	Y = Y + plus
	string = "Продать для Закусочной"
	if drawClickableText(string, (X  - renderGetFontDrawTextLength(font, string.."  ")), Y) then
		sell = true
		buyMode = "food"
	end

	-->> Render Monitoring
	local X, Y = getScreenResolution()
	Y = ((Y / 2.2) - (height * 3))
	string = "[Обновить цены]"
	if drawClickableText(string, (X / 2  - (renderGetFontDrawTextLength(font, string.."  ") / 2 )), Y) then
		checkMon = "alcohol"
	end
	Y = Y + plus
	string = string.format("{%s}Алкоголь {%s}| {%s}Заправки {%s}| {%s}Магазины {%s}| {%s}Закусочные",
		(monMode == "alcohol" and ini.settings.color2 or ini.settings.color1),
		ini.settings.color1,
		(monMode == "benz" and ini.settings.color2 or ini.settings.color1),
		ini.settings.color1,
		(monMode == "products" and ini.settings.color2 or ini.settings.color1),
		ini.settings.color1,
		(monMode == "food" and ini.settings.color2 or ini.settings.color1)
	)
	if drawClickableText(string, (X / 2  - (renderGetFontDrawTextLength(font, string.."  ") / 2 )), Y) then
		local mode_sled = { alcohol = "benz", benz = "products", products = "food", food = "alcohol" }
		monMode = mode_sled[monMode]
	end
	local delta = getMousewheelDelta()
	if delta > 0 then
		local mode_sled = { alcohol = "food", benz = "alcohol", products = "benz", food = "products" }
		monMode = mode_sled[monMode]
	elseif delta < 0 then
		local mode_sled = { alcohol = "benz", benz = "products", products = "food", food = "alcohol" }
		monMode = mode_sled[monMode]
	end
	Y = Y + plus
	local arr = split(monArray[monMode], "\n")
	for i = 1, #arr do
		local string = arr[i]
		if drawClickableText(string, (X / 2  - (renderGetFontDrawTextLength(font, string.."  ") / 2 )), Y) then
			if string:find("{FFFFFF}(.+)  {6AB1FF}%d+  {00A86B}%d+") then
				bizname = string:match("{FFFFFF}(.+)  {6AB1FF}%d+  {00A86B}%d+")
				local replace = {
					[" Cluck"] = "",
					[" Pizza"] = "",
					[" Burger"] = "",
					[" 24%-7"] = "",
					[" Gas"] = "",
					[" Gsa"] = "",
					["Four dragon"] = "Склад бара 4Драконов",
					["Caligula"] = "Склад бара Калигулы",
					[" Bar"] = "",
					[" bar"] = "",
					["Quebrados"] = "Guebrabos"
				}
				for k,v in pairs(replace) do
					bizname = string.gsub(bizname, k, v)
				end
				sampSendChat("/gps")
			end
		end
		Y = Y + plus
	end
end

-->> BuyMode
function doBuyMode()
	if buyMode == nil or prod[buyMode] == nil then return end
	if dialogActiveTime == nil then dialogActiveTime = 0 end
	if sampIsDialogActive() then dialogActiveTime = os.clock() * 1000 return end

	if os.clock() * 1000 - dialogActiveTime > 500 then
		dialogActiveTime = os.clock() * 1000
		sampSendChat("/prodmenu")
	end
end

-->> CHECK MODE
function doCheckMonMode()
	if checkMon == nil then return end
	if dialogActiveTime == nil then dialogActiveTime = 0 end
	if sampIsDialogActive() then dialogActiveTime = os.clock() * 1000 return end

	if os.clock() * 1000 - dialogActiveTime > 500 then
		dialogActiveTime = os.clock() * 1000
		sampSendChat("/prodmenu")
	end
end

-->> SEND DIALOG
function doSendDialog()
	if send_dialog == nil then return end
	if os.clock() * 1000 - send_dialog.time < 300 then return end
	sampSendDialogResponse(send_dialog.id,send_dialog.button,send_dialog.listitem,send_dialog.input)
	send_dialog = nil
end

-->> INIFILES
function iniLoad()
    ini = inicfg.load({
    	settings = {
    		font_name = "SegoeUI",
			font_size = 10,
			font_flag = 13,
			color1 = "2f72f7",
			color2 = "ffffff"
    	}
    })
    inicfg.save(ini)

	prod = { alcohol = 0, benz = 0, products = 0, food = 0 }
	monMode = "alcohol"
	monArray = { alcohol = "Пусто", benz = "Пусто", products = "Пусто", food = "Пусто" }
end

-->> New Func
function drawClickableText(text, posX, posY)
	renderFontDrawText(font, text, posX, posY, '0xFF'..ini.settings.color1)
	local textLenght = renderGetFontDrawTextLength(font, text)
	local textHeight = renderGetFontDrawHeight(font)
	local curX, curY = getCursorPos()
	if curX >= posX and curX <= posX + textLenght and curY >= posY and curY <= posY + textHeight then
	  renderFontDrawText(font, text, posX, posY, '0x70'..ini.settings.color2)
	  if isKeyJustPressed(1) then
		return true
	  end
	end
 end

function split(str, delim, plain)
    local tokens, pos, plain = {}, 1, not (plain == false) --[[ delimiter is plain text by default ]]
    repeat
        local npos, epos = string.find(str, delim, pos, plain)
        table.insert(tokens, string.sub(str, pos, npos and npos - 1))
        pos = epos and epos + 1
    until not pos
    return tokens
end

function start_dialog(_menu, put) -- module by trefa & modify (put & list in [])
    function _dialog(_menu, id, outs, put)
        sampShowDialog(id, _menu.settings.title, tbl_split(_menu.settings.style, _menu, _menu.settings.forward ,_menu.settings.backwards ,_menu.settings.score), _menu.settings.btn1, (_menu.settings.btn2 ~= nil and _menu.settings.btn2 or _), _menu.settings.style)
        repeat
            wait(0)
            if put ~= nil and sampIsDialogActive() then
                sampSetCurrentDialogEditboxText(put)
                put = nil
            end
            local result, button, list, input = sampHasDialogRespond(id)
            if result then
                local out, outs = _menu[((_menu.settings.style == 0 or _menu.settings.style == 1 or _menu.settings.style == 3) and 1 or ((list + 1) > #_menu[1] and 2 or 1))][((_menu.settings.style == 0 or _menu.settings.style == 1 or _menu.settings.style == 3) and 1 or ((list + 1) > #_menu[1] and (list - #_menu[1]) + 1  or list + 1))].click(button, list, input, outs)
                if type(out) == "table" then
                    return _dialog(out, id - 1, outs, put)
                elseif type(out) == "boolean" then
                    if not out then
                        return out
                    end
                        return _dialog(_menu, id, outs, put)
                end
            end
        until result or menu.show[1]
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

    return _dialog(_menu, 1337, outs, put)
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
    version_url = "http://git.deadpoo.net/rubin/ProdHUD/raw/branch/master/version",
    script_url = "http://git.deadpoo.net/rubin/ProdHUD/raw/branch/master/ProdHUD.lua",
    changelog_url = "http://git.deadpoo.net/rubin/ProdHUD/raw/branch/master/changelog",
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
utf8({ "sampHasDialogRespond" }, nil, "AnsiToUtf8")
utf8({ "renderFontDrawText" }, "Utf8ToAnsi")
utf8({ "renderGetFontDrawTextLength" }, "Utf8ToAnsi")