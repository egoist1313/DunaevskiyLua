script_name("srp-theft-tools")
script_author("RuBin")
script_version("25.11.2023")
local sampev = require("samp.events")
local inicfg = require "inicfg"
local dlstatus = require("moonloader").download_status

function main()
    while not isSampfuncsLoaded() do wait(100) end
    repeat wait(0) until isSampAvailable()
    lua_thread.create(script_update.main)
    lua_thread.create(pick.loop)
    lua_thread.create(arrow.loop)
    while true do
        wait(0)
    end
end

pick = {}
pick.list = {}
pick.td_id = -1
pick.loop = function()
    while true do
        wait(0)
        pick_counter = 0
        check_all_textdraw(function(id, x, y, text)
            if text:find("LD_POOL:ball") then
                pick_counter = pick_counter + 1
                if pick.list[pick_counter] == nil then
                    pick.list[pick_counter] = {
                        id = id,
                        status = false
                    }
                end
            end
        end)
        if pick_counter > 2 then
            local result = 0
            local start = os.time()
            repeat
                wait(0)
                local randInt = math.random(1, #pick.list)
                if not pick.list[randInt]["status"] then
                    result = pick.list[randInt]["id"]
                    pick.list[randInt]["status"] = true
                end
            until result > 0 or os.time() - start > 0
            if result > 0 then
                check_all_textdraw(function(id, x, y, text)
                    local dist = getDistanceBetweenCoords2d(320.0,250.0,x,y)
                    if dist < 0.1 and text:find("Pick") then
                        sampSendClickTextdraw(result)
                        wait(500)
                        sampSendClickTextdraw(id)
                    end
                end)
            end
            wait(1000)
        end
    end
end
check_all_textdraw = function(func)
    for a = 0, 2304 do
        if sampTextdrawIsExists(a) then
            local x, y = sampTextdrawGetPos(a)
            local text = sampTextdrawGetString(a)
            func(a, x, y, text)
        end
    end
end

arrow = {}
arrow.loop = function()
    while true do
        wait(0)
        for i = 1, #txd_keys do
			if txd_keys[i][2] ~= -1 and wasKeyPressed(txd_keys[i][2]) then
				sampSendClickTextdraw(txd_keys[i][3])
			end
		end
    end
end
txd_keys = {
    { "LD_BEAT:up", 38, -1 },
	{ "LD_BEAT:down", 40, -1 },
	{ "LD_BEAT:left", 37, -1 },
	{ "LD_BEAT:right", 39, -1 }
}

-->> events
function sampev.onShowTextDraw(id, data)
	if data.text:find("LD_BEAT") then
		for i = 1, #txd_keys do
			if data.text:find(txd_keys[i][1]) then
				txd_keys[i][3] = id
			end
		end
	end
    if data.text:find("LD_SPAC:white") then
        local dist = getDistanceBetweenCoords2d(318.0,212.50,data.position.x,data.position.y)
        if dist < 0.1 then
            pick.td_id = id
            pick.list = {}
        end
    end
end
function sampev.onTextDrawSetString(id, text)
	if text:find("LD_BEAT") then
		for i = 1, #txd_keys do
			if id == txd_keys[i][3] then
				if text:find(txd_keys[i][1]) then
					txd_keys[i][3] = id
				else
					txd_keys[i][3] = -1
				end
			end
		end
	end
end
function sampev.onTextDrawHide(id)
	for i = 1, #txd_keys do
		if id == txd_keys[i][3] then
			txd_keys[i][3] = -1
		end
	end
    if pick.td_id == id then
        pick.td_id = -1
        pick.list = {}
    end
end

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
script_update = {
    version_url = "http://git.deadpoo.net/rubin/srp-theft-tools/raw/branch/master/version",
    script_url = "http://git.deadpoo.net/rubin/srp-theft-tools/raw/branch/master/srp-theft-tools.lua",
    changelog_url = "http://git.deadpoo.net/rubin/srp-theft-tools/raw/branch/master/changelog",
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
function addChatMessage(text)
    local tag = string.format("{667dff}[%s]{FFFFFF} ", thisScript().name)
    sampAddChatMessage(tag..text, 0xFFFFFFFF)
end