local script_name = 'set-id'
local script_author = 'Serhiy_Rubin'
local script_version = '28.01.2024'
require 'lib.moonloader'
require 'lib.sampfuncs'

local dlstatus = require("moonloader").download_status
local inicfg = require "inicfg"
local sampev = require 'lib.samp.events'
local ffi = require("ffi")
local user32 = ffi.load("user32")   -- Load User32 DLL handle

ffi.cdef [[ bool SetCursorPos(int X, int Y); ]]
ffi.cdef([[
enum{
    MB_OK = 0x00000000L,
    MB_ICONINFORMATION = 0x00000040L
};

typedef void* HANDLE;
typedef HANDLE HWND;
typedef const char* LPCSTR;
typedef unsigned UINT;

int MessageBoxA(HWND, LPCSTR, LPCSTR, UINT);
]])
ffi.cdef [[
    typedef int BOOL;
    typedef unsigned long HANDLE;
    typedef HANDLE HWND;
    typedef int bInvert;
    HWND GetActiveWindow(void);

    BOOL FlashWindow(HWND hWnd, BOOL bInvert);

    HWND GetForegroundWindow();
]]

local setid, id1, id2 = false, 0, 0
local timeconnect = 0

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	while not isSampAvailable() do wait(100) end
    --lua_thread.create(script_update.main)
	sampRegisterChatCommand('setid', function(param)
		if not setid then
			if param:find('(%d+) (%d+)') then
				setid = true
				WorkInBackground(true)
				if setid then
					local S1, S2 = param:match('(%d+) (%d+)')
					id1 = tonumber(S1) ; id2 = tonumber(S2)
					local _, my_id = sampGetPlayerIdByCharHandle(PLAYER_PED)
					for i = id1, id2 do
						if i == my_id then
							setid = false
							WorkInBackground(false)
							sampAddChatMessage('У вас уже ID: '..i..'. Поиск отключен.', -1)
						end
					end
					if setid then reconnect() end
					return
				end
			end
		else
			setid = false
			WorkInBackground(false)
			sampAddChatMessage('Поиск ID отключен', -1)
			return
		end
		sampAddChatMessage(' /setid [0] [999] - Укажите диапазон поиска ID', -1)
	end)

	while true do
		wait(0)
        if setid then
        	local chatstring = sampGetChatString(99)
        	if chatstring == "Server closed the connection." then reconnect() end
        	if chatstring == "You are banned from this server." then reconnect() end
        	if chatstring == 'The server is restarting..' then reconnect() end
        end
	end
end

function reconnect()
	if (os.time() - timeconnect) > 6 then
		sampAddChatMessage('Запущен поиск ID в диапазоне от '..id1..' до '..id2, -1)
		lua_thread.create(function()
			local bs = raknetNewBitStream()
			raknetBitStreamWriteInt8(bs, PACKET_DISCONNECTION_NOTIFICATION)
			raknetSendBitStream(bs)
			raknetDeleteBitStream(bs)

			local bs = raknetNewBitStream()
			raknetEmulPacketReceiveBitStream(PACKET_DISCONNECTION_NOTIFICATION, bs)
			raknetDeleteBitStream(bs)

			timeconnect = os.time()
			wait(5000+math.random(100, 500))
			sampSetGamestate(1)
		end)
	end
end

function sampev.onInitGame(playerId, hostName, settings, vehicleModels, unknown)
	lua_thread.create(function(playerId)
		for i = id1, id2 do
			if i == playerId then
				setid = false
				sampAddChatMessage('Получен ID: '..i..'. Поиск отключен.', -1)
				isAFK_Message('Получен ID: '..i..'. Поиск отключен.')
				WorkInBackground(false)
				if ffi.C.GetActiveWindow() ~= nil then
					lua_thread.create(function()
			        	repeat wait(0) until sampIsCursorActive()
						local X, Y = convertGameScreenCoordsToWindowScreenCoords(317.65740966797, 404.25)
						ffi.C.SetCursorPos(X, Y)
						setVirtualKeyDown(1, true)
						setVirtualKeyDown(1, false)
					end)
				end
			end
		end
		if setid then sampAddChatMessage('Получен ID: '..playerId..'. Ищем дальше.', -1) ; reconnect() end
	end, playerId)
end

function isAFK_Message(text)
	if ffi.C.GetActiveWindow() == nil then
		user32.MessageBoxA(nil, text, "SetID", 0x00010000)
	end
end

function WorkInBackground(work)
    local memory = require 'memory'
    if work then -- on
        memory.setuint8(7634870, 1)
        memory.setuint8(7635034, 1)
        memory.fill(7623723, 144, 8)
        memory.fill(5499528, 144, 6)
        memory.fill(0x00531155, 0x90, 5, true)
    else -- off
        memory.setuint8(7634870, 0)
        memory.setuint8(7635034, 0)
        memory.hex2bin('5051FF1500838500', 7623723, 8)
        memory.hex2bin('0F847B010000', 5499528, 6)
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
    version_url = "http://git.deadpoo.net/rubin/set-id/raw/branch/master/version",
    script_url = "http://git.deadpoo.net/rubin/set-id/raw/branch/master/set-id.lua",
    changelog_url = "http://git.deadpoo.net/rubin/set-id/raw/branch/master/changelog",
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