local script_name = 'auto-ad'
local script_author = 'Serhiy_Rubin'
local script_version = '30.06.2023'
sampev = require("samp.events")
inicfg = require "inicfg"
dlstatus = require("moonloader").download_status
antiflood = 0

ad = {
    status = false,
    text = "1",
    radio = 0,
    radio_save = 0,
    mode = 1,
    one = false,
    af_5sec = 0,
    status_2_wait = false
}

function ad.sender()
    if not ad.status then return end

    if ad.mode == 1 then
        --> Переключает на нужное радио если пользователь выбрал такое в меню
        if ad.radio ~= 0 and ad.radio_save == 0 or (ad.radio_save ~= 0 and ad.radio_save ~= ad.radio) then
            if os.clock() * 1000 - antiflood > 750 then
                sampSendChat("/radio "..ad.radio)
            end
        end

        --> Отправка каждые 5 сек
        if os.clock() * 1000 - ad.af_5sec > 5000 and not ad.status_2_wait then
            if os.clock() * 1000 - antiflood > 750 then
                sampSendChat("/ad "..ad.text)
            end
        end
    end
end

function main()
    while not isSampfuncsLoaded() do wait(100) end
    repeat wait(0) until isSampAvailable()
    --lua_thread.create(script_update.main)
    sampRegisterChatCommand("aad", menu.show)
    while true do
        wait(0)
        menu.handler()
        ad.sender()
    end
end

--> Events
text_to_int = {
    ["SF"] = 1,
    ["LS"] = 2,
    ["LV"] = 3
}
function sampev.onServerMessage(color, message)
    if message:find("Волна переключена на News (.+)") then
        local text = message:match("Волна переключена на News (.+)")
        ad.radio = text_to_int[text]
        ad.radio_save = ad.radio
    end
    if message:find("Объявления можно дать через 5 секунд") then
        ad.af_5sec = os.clock() * 1000
    end
    if message:find("Редакция News (..)%. Отредактировал") then
        if ad.status then
            local text = message:match("Редакция News (..)%. Отредактировал")
            if ad.mode == 2 then
                lua_thread.create(function(radio)
                    wait(30)
                    if ad.radio_save ~= radio then
                        sampSendChat("/radio "..radio)
                        wait(300)
                    end
                    sampSendChat("/ad "..ad.text)
                end, text_to_int[text])
            elseif ad.mode == 1 and ad.status_2_wait then
                if text_to_int[text] == ad.radio or ad.radio == 0 then
                    lua_thread.create(function()
                        wait(30)
                        repeat
                            wait(0)
                        until os.clock() * 1000 - antiflood > 200
                        sampSendChat("/ad "..ad.text)
                    end)
                end
            end
        end
    end
    if message:find("Ваша очередь объявлений заполнена. Попробуйте позже") or message:find("Очередь объявлений заполнена. Попробуйте позже") then
        if ad.status and ad.mode == 1 then
            ad.status_2_wait = true
        end
    end
    if message:find("Вы не выбрали через какую радиостанцию подавать объявление") and ad.status then
        ad.status = false
    end
end
function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
    if title:find("Подтверждение") and text:find("Вы собираетесь отправить объявление") then
        if ad.status then
            sampSendDialogResponse(dialogId,1,0,"")
            if ad.one then
                ad.status = false
            end
            ad.af_5sec = os.clock() * 1000
            return false
        end
    end
end
function sampev.onSendChat()
    antiflood = os.clock() * 1000
end
function sampev.onSendCommand()
    antiflood = os.clock() * 1000
end

--> Menu
menu = {
    id = 1921,
    id_edit = 1922,
    list = {},
    func = {}
}

function menu.handler()
    local result, button, list, input = sampHasDialogRespond(menu.id)
    if result and button == 1 then
        if menu.func[list+1] ~= nil then
            menu.func[list+1](button, list, input)
        end
    end
    local result, button, list, input = sampHasDialogRespond(menu.id_edit)
    if result then
        if button == 1 then
            ad.text = input
            menu.show()
        end
        menu.show()
    end
end

function menu.show()
    menu.list = {}
    menu.func = {}

    menu.list[#menu.list+1] = string.format("Скрипт: %s", (ad.status and "{06940f}ON" or "{d10000}OFF"))
    menu.func[#menu.func+1] = function(button, list, input)
        ad.status = not ad.status
        ad.status_2_wait = false
        menu.show()
    end

    local mode_text = {
        [1] = "Каждые 5 секунд",
        [2] = "Переключать /radio + /ad"
    }
    menu.list[#menu.list+1] = string.format("Отправка: %s", mode_text[ad.mode])
    menu.func[#menu.func+1] = function(button, list, input)
        ad.mode = ad.mode + 1
        if ad.mode >= 3 then
            ad.mode = 1
        end
        ad.status_2_wait = false
        menu.show()
    end

    menu.list[#menu.list+1] = string.format("Отключить после подачи: %s", (ad.one and "{06940f}ON" or "{d10000}OFF"))
    menu.func[#menu.func+1] = function(button, list, input)
        ad.one = not ad.one
        menu.show()
    end

    local radio_list = {
        [0] = "Не выбрано",
        [1] = "SF",
        [2] = "LS",
        [3] = "LV"
    }
    menu.list[#menu.list+1] = string.format("Радиостанция: %s", radio_list[ad.radio])
    menu.func[#menu.func+1] = function(button, list, input)
        ad.radio = ad.radio + 1
        if ad.radio >= 4 then
            ad.radio = 1
        end
        menu.show()
    end

    menu.list[#menu.list+1] = string.format("Текст: %s", ad.text)
    menu.func[#menu.func+1] = function(button, list, input)
        sampShowDialog(menu.id_edit,"Auto-AD","Введите текст объявления без команды /ad","Выбрать","Назад",1)
        lua_thread.create(function()
            repeat
                wait(0)
            until sampIsDialogActive()
            sampSetCurrentDialogEditboxText(ad.text)
        end)
        return
    end

    local text = ""
    for i = 1, #menu.list do
        text = string.format("%s%s\n", text, menu.list[i])
    end
    sampShowDialog(menu.id,"Auto-AD",text,"Выбрать","Закрыть",2)
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

function addChatMessage(text)
    local tag = string.format("{667dff}[%s]{FFFFFF} ", thisScript().name)
    sampAddChatMessage(tag..text, 0xFFFFFFFF)
end

script_update = {
    version_url = "http://git.deadpoo.net/rubin/auto-ad/raw/branch/master/version",
    script_url = "http://git.deadpoo.net/rubin/auto-ad/raw/branch/master/auto-ad.lua",
    changelog_url = "http://git.deadpoo.net/rubin/auto-ad/raw/branch/master/changelog",
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
utf8({ "sampSetCurrentDialogEditboxText" }, "Utf8ToAnsi")
utf8({ "sampHasDialogRespond" }, nil, "AnsiToUtf8")
utf8({ "sampev", "onShowDialog" }, "AnsiToUtf8", "Utf8ToAnsi")
utf8({ "sampev", "onServerMessage" }, "AnsiToUtf8", "Utf8ToAnsi")