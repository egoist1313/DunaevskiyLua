local script_name = 'squad-mats'
local script_author = 'Serhiy_Rubin'
local script_version = '18.02.2023'
sampev = require 'samp.events'
inicfg = require "inicfg"
dlstatus = require("moonloader").download_status

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	while not isSampAvailable() do wait(0) end
    lua_thread.create(script_update.main)
    repeat wait(0) until sampGetCurrentServerName() ~= "SA-MP"
    repeat wait(0) until sampGetCurrentServerName():find("Samp%-Rp.Ru") or sampGetCurrentServerName():find("SRP")
    local server = getSampRpServerName()
    if server == "" then
        thisScript():unload()
    end
    config.init()
    sampRegisterChatCommand("squadid",function(para)
        if para:find("%d+") then
            config.data.squad_id = tonumber(para:match("(%d+)"))
            config.save(config.data)
            addChatMessage("Установлен новый ID сквада: "..config.data.squad_id)
        end
    end)
    wait(-1)
end

-->> CONFIG
config = {}
config.data = {}
local x1, y1 = convertGameScreenCoordsToWindowScreenCoords(14, 310)
config.default = {
    squad_id = -1,
    mats = 0,
    mats_price = 8
}
config.directory = string.format("%s\\moonloader\\config\\%s\\", getGameDirectory(), thisScript().name)
config.init = function()
    if not doesDirectoryExist("moonloader\\config") then
        createDirectory("moonloader\\config")
    end
    if not doesDirectoryExist(config.directory) then
        createDirectory(config.directory)
    end
    config.address = string.format("%s\\%s-%s.json", config.directory, getSampRpServerName(), getLocalPlayerNickname())
    if not doesFileExist(config.address) then
        config.save(config.default)
    end
    config.read()
    for k,v in pairs(config.default) do
        if config.data[k] == nil then
            config.data[k] = v
        end
    end
    config.save(config.data)
end
config.save = function(data)
    local file, error = io.open(config.address, "w")
    if file == nil then
        addChatMessage(error)
    end
    file:write(encodeJson(data))
    file:flush()
    io.close(file)
end
config.read = function()
    local readJson = function()
        local file, error = io.open(config.address, "r")
        if file then
            config.data = decodeJson(file:read("*a"))
            io.close(file)
            if config.data == nil then
                addChatMessage("Ошибка чтения конфига! Сбрасываю конфиг!")
                config.save(config.default)
            end
        end
    end
    local result = pcall(readJson)
    if not result then
        addChatMessage("Ошибка чтения конфига! Сбрасываю конфиг!")
        config.save(config.default)
    end
    if config.data == nil then
        config.error = true
        addChatMessage("Ошибка чтения конфига! Пробую ещё раз прочесть")
        config.read()
    else
        if config.error then
            addChatMessage("Конфиг был успешно загружен!")
            config.error = false
        end
    end
end

-->> COUNTER
counter = {}
counter.reset = 0
counter.weapon = {
    ["SD Pistol"] = 34,
    ["Desert Eagle"] = 63,
    ["Shotgun"] = 90,
    ["MP5"] = 180,
    ["AK-47"] = 180,
    ["M4"] = 300,
    ["Rifle"] = 300
}

dialog = {}
dialog.id = -1
dialog.text = [[[0] SD Pistol [34 п. 34 м.]
[1] Desert Eagle [21 п. 63 м.]
[2] Shotgun [30 п. 90 м.]
[3] MP5 [90 п. 180 м.]
[4] AK-47 [90 п. 180 м.]
[5] M4 [100 п. 300 м.]
[6] Rifle [30 п. 300 м.]
]]
dialog.convertText = function(text)
    text = string.format("%s\n \nВсего потрачено: %d матов\nСтоимость: %d вирт\n> Оплатить сейчас", text, config.data.mats, (config.data.mats * config.data.mats_price))
    return text
end

-->> EVENTS
function sampev.onServerMessage(color, message)
    if message:find("%[Офис%]{FFFFFF} Вы взяли {00FFBF}(.+) %(%d+ .+%) {FFFFFF}с оружейного шкафа офиса!") then
        local weapon = message:match("%[Офис%]{FFFFFF} Вы взяли {00FFBF}(.+) %(%d+ .+%) {FFFFFF}с оружейного шкафа офиса!")
        config.data.mats = config.data.mats + counter.weapon[weapon]
        config.save(config.data)
    end
    if message:find(" Операция выполнена") and os.time() - counter.reset <= 2 then
        addChatMessage("Счетчик материалов обнулен!")
        config.data.mats = 0
        config.save(config.data)
    end
    if message:find(" Вы не в сообществе") and os.time() - counter.reset <= 2 then
        addChatMessage("Укажите ID сообщества командой /squadid [ID]")
    end
end
function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
    if title == "Меню" and text == dialog.text then
        dialog.id = dialogId
        text = dialog.convertText(text)
        return { dialogId, style, title, button1, button2, text }
    end
end
function sampev.onSendDialogResponse(dialogId, button, listboxId, input)
    if dialog.id == dialogId and listboxId == 10 and button == 1 then
        counter.reset = os.time()
        sampSendChat("/squad bank "..config.data.squad_id.." "..(config.data.mats * config.data.mats_price))
        return false
    end
    dialog.id = -1
end

-->> NEW FUNCTION
function getLocalPlayerNickname()
    return sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))
end
function getServerAddress()
    local ip, port = sampGetCurrentServerAddress()
    return string.format("%s:%s", ip, port)
end
function getSampRpServerName()
    local result = ""
    local server = sampGetCurrentServerName():gsub("|", "")
    local server_find = { "02", "Two", "Revo", "Legacy", "Classic" }
    for i = 1, #server_find do
        if server:find(server_find[i]) then
            result = server_find[i]
        end
    end
    return result
end
function convertTableToString(table)
    local result = ""
    for i = 1, #table do
        result = string.format("%s%s\n", result, table[i])
    end
    return result
end
function start_dialog(menu, put) -- module by trefa & modify (put & list in [])
    function _dialog(menu, id, outs, put)
        sampShowDialog(id, menu.settings.title, tbl_split(menu.settings.style, menu, menu.settings.forward ,menu.settings.backwards ,menu.settings.score), menu.settings.btn1, (menu.settings.btn2 ~= nil and menu.settings.btn2 or _), menu.settings.style)
            repeat
                wait(0)
                if put ~= nil and sampIsDialogActive() then
                    sampSetCurrentDialogEditboxText(put)
                    put = nil
                end
                local result, button, list, input = sampHasDialogRespond(id)
                if result then
                    local out, outs = menu[((menu.settings.style == 0 or menu.settings.style == 1 or menu.settings.style == 3) and 1 or ((list + 1) > #menu[1] and 2 or 1))][((menu.settings.style == 0 or menu.settings.style == 1 or menu.settings.style == 3) and 1 or ((list + 1) > #menu[1] and (list - #menu[1]) + 1  or list + 1))].click(button, list, input, outs)
                    if type(out) == "table" then
                        return _dialog(out, id - 1, outs, put)
                    elseif type(out) == "boolean" then
                        if not out then
                            return out
                        end
                            return _dialog(menu, id, outs, put)
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

    return _dialog(menu, 1337, outs, put)
end
function getNicknamesOnline()
    local result = {}
    for i = 0, sampGetMaxPlayerId(false) do
        if sampIsPlayerConnected(i) or select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)) == i then
            result[sampGetPlayerNickname(i)] = i
        end
    end
    return result
end
function addChatMessage(text)
    local tag = string.format("{667dff}[%s]{FFFFFF} ", thisScript().name)
    sampAddChatMessage(tag..text, 0xFFFFFFFF)
end

-->> UPDATE
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
    version_url = "http://git.deadpoo.net/rubin/squad-mats/raw/branch/master/version",
    script_url = "http://git.deadpoo.net/rubin/squad-mats/raw/branch/master/squad-mats.lua",
    changelog_url = "http://git.deadpoo.net/rubin/squad-mats/raw/branch/master/changelog",
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
                if text ~= "" and not string.find(text, thisScript().version) then
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
                if text ~= "" and not string.find(text, thisScript().version) then
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
utf8({ "sampev", "onServerMessage" }, "AnsiToUtf8", "Utf8ToAnsi")
utf8({ "sampev", "onShowDialog" }, "AnsiToUtf8", "Utf8ToAnsi")
utf8({ "sampev", "onSendDialogResponse" }, "AnsiToUtf8", "Utf8ToAnsi")