local samp = require 'samp.events'
local ffi = require 'ffi'
local encoding = require 'encoding'
local vkeys = require 'vkeys'
local font_flag = require('moonloader').font_flag
local MessageSender = require 'lib.messagesender' -- Ïîäêëş÷àåì áèáëèîòåêó
encoding.default = 'CP1251'
local u8 = encoding.UTF8
-- Çàãğóæàåì json â íà÷àëå ñêğèïòà
local json
do
    local success, result = pcall(function() return require 'json' end)
    if not success then
        json = nil
    else
        json = result
    end
end
local script_name = 'VoskChat'
local script_version = '02/25/2025'
local config_path = getGameDirectory() .. '/moonloader/config/VoskChat.json'
local exe_path = getWorkingDirectory() .. '\VoskBladwin'
local lua_to_python_file_path = exe_path .. "\lua_to_python.json"
local python_to_lua_file_path = exe_path .. "\python_to_lua.json"
local voice_dun_file_path = exe_path .. "\VoiceDun.txt"
local default_ini = {
    buttons = {
        {key = "VK_MULTIPLY", prefix = "/do "},
        {key = "VK_U", prefix = "/u "},
        {key = "VK_4", prefix = "/me "},
        {key = "VK_B", prefix = "/b "},
        {key = "VK_E", prefix = ""},
        {key = "VK_1", prefix = "/f "}
    },
    textPositions = {
        status = {x = 10, y = 668, color = 0xFFFFFFFF, visible = true},
        indicators = {x = 10, y = 505, color = 0xFF8A2BE2, lineSpacing = 20, visible = true},
        clipboardText = {x = 65, y = 668, color = 0xFF00FFFF, visible = true}
    },
    fonts = {
        status = {size = 13, name = "Arial", flags = font_flag.SHADOW + font_flag.BORDER},
        indicators = {size = 14, name = "Courier New", flags = font_flag.SHADOW + font_flag.BORDER},
        clipboardText = {size = 10, name = "Verdana", flags = font_flag.SHADOW + font_flag.BORDER}
    },
    settings = {activationKey = "VK_F4", cmd = "vosk", dragEnabled = false, model_type = 0}
}
local colorOptions = {
    {name = "Êğàñíûé", color = 0xFFFF0000},
    {name = "Îğàíæåâûé", color = 0xFFFFA500},
    {name = "Æåëòûé", color = 0xFFFFFF00},
    {name = "Çåëåíûé", color = 0xFF00FF00},
    {name = "Ãîëóáîé", color = 0xFF00FFFF},
    {name = "Ñèíèé", color = 0xFF0000FF},
    {name = "Ôèîëåòîâûé", color = 0xFF8A2BE2},
    {name = "Áåëûé", color = 0xFFFFFFFF}
}
local fontOptions = {
    "Arial", "Times New Roman", "Verdana", "Tahoma", "Courier New", "Georgia",
    "Palatino Linotype", "Comic Sans MS", "Trebuchet MS", "Arial Black", "Impact", "Default"
}
local modelOptions = {"Ìàëåíüêàÿ", "Ñğåäíÿÿ", "Áîëüøàÿ"}
local function logError(message)
    sampAddChatMessage('[Vosk] Îøèáêà: ' .. tostring(message), 0xFF0000)
end
local function mergeTables(default, custom)
    local result = {}
    for k, v in pairs(default) do
        if type(v) == "table" and custom[k] and type(custom[k]) == "table" then
            result[k] = mergeTables(v, custom[k])
        else
            result[k] = custom[k] or v
        end
    end
    return result
end
local function checkAndDownloadJsonLibrary()
    if json then return true end
    local libPath = getWorkingDirectory() .. '\lib'
    local jsonPath = libPath .. '\json.lua'
    if not doesDirectoryExist(libPath) then
        local success = createDirectory(libPath)
        if not success then
            logError("Íå óäàëîñü ñîçäàòü äèğåêòîğèş lib")
            return false
        end
    end
    if not doesFileExist(jsonPath) then
        sampAddChatMessage('[Vosk] Áèáëèîòåêà json.lua íå íàéäåíà. Íà÷èíàş ñêà÷èâàíèå...', 0xFF0000)
        local success = os.execute('start /B cmd.exe /c curl -o "' .. jsonPath .. '" https://raw.githubusercontent.com/rxi/json.lua/master/json.lua')
        wait(2000)
        if doesFileExist(jsonPath) then
            sampAddChatMessage('[Vosk] Áèáëèîòåêà json.lua óñïåøíî ñêà÷àíà.', 0x71c8dd)
            local success, result = pcall(function() return require 'json' end)
            if success then
                json = result
                return true
            else
                logError("Îøèáêà çàãğóçêè json.lua ïîñëå ñêà÷èâàíèÿ: " .. tostring(result))
                return false
            end
        else
            logError("Îøèáêà ïğè ñêà÷èâàíèè json.lua")
            return false
        end
    end
    local success, result = pcall(function() return require 'json' end)
    if success then
        json = result
        return true
    else
        logError("Îøèáêà çàãğóçêè json.lua: " .. tostring(result))
        return false
    end
end
local function setupMimgui()
    local libPath = getWorkingDirectory() .. '\lib'
    local mimguiPath = libPath .. '\mimgui'
    local tempPath = getWorkingDirectory() .. '\temp'
    local zipPath = tempPath .. '\mimgui-v1.7.1.zip'
    if not doesDirectoryExist(mimguiPath) then
        sampAddChatMessage('[Vosk] mimgui íå íàéäåí. Íà÷èíàş àâòîìàòè÷åñêóş óñòàíîâêó...', 0xFF0000)
        if not doesDirectoryExist(tempPath) then
            createDirectory(tempPath)
        end
        local releaseUrl = "https://github.com/THE-FYP/mimgui/releases/latest/download/mimgui-v1.7.1.zip"
        sampAddChatMessage('[Vosk] Ñêà÷èâàş mimgui-v1.7.1.zip...', 0x71c8dd)
        os.execute('start /B cmd.exe /c curl -o "' .. zipPath .. '" "' .. releaseUrl .. '"')
        wait(2000)
        if doesFileExist(zipPath) then
            sampAddChatMessage('[Vosk] mimgui-v1.7.1.zip óñïåøíî ñêà÷àí. Ğàñïàêîâûâàş...', 0x71c8dd)
            os.execute('powershell -Command "Expand-Archive -Path \"' .. zipPath .. '\" -DestinationPath \"' .. tempPath .. '\" -Force"')
            local extractedPath = tempPath .. '\mimgui'
            if doesDirectoryExist(extractedPath) then
                os.execute('move "' .. extractedPath .. '" "' .. libPath .. '"')
                sampAddChatMessage('[Vosk] Ïàïêà mimgui óñïåøíî óñòàíîâëåíà â moonloader/lib.', 0x71c8dd)
                os.execute('rd /s /q "' .. tempPath .. '"')
            else
                logError("Îøèáêà: àğõèâ íå ñîäåğæèò ïàïêè mimgui")
                return false, nil
            end
        else
            logError("Îøèáêà ïğè ñêà÷èâàíèè mimgui-v1.7.1.zip")
            return false, nil
        end
    end
    local success, imgui = pcall(function() return require('mimgui') end)
    if not success then
        logError("Îøèáêà çàãğóçêè mimgui: " .. tostring(imgui))
        return false, nil
    end
    return true, imgui
end
local function saveSettings(data)
    if not json then
        logError("Ábibîòåêà json íå çàãğóæåíà")
        return false
    end
    local file = io.open(config_path, 'w')
    if not file then
        logError("Íå óäàëîñü îòêğûòü ôàéë íàñòğîåê äëÿ çàïèñè")
        return false
    end
    local success, err = pcall(function()
        for _, pos in pairs(data.textPositions) do
            if pos.color and type(pos.color) == "number" then
                pos.color = string.format("0x%08X", pos.color)
            end
        end
        file:write(json.encode(data))
        file:close()
    end)
    if not success then
        logError("Îøèáêà ïğè ñîõğàíåíèè íàñòğîåê: " .. tostring(err))
        if file then file:close() end
        return false
    end
    return true
end
local function loadSettings()
    if not json then
        logError("Áèáëèîòåêà json íå çàãğóæåíà")
        return default_ini
    end
    local config_dir = getGameDirectory() .. '/moonloader/config'
    if not doesDirectoryExist(config_dir) then
        createDirectory(config_dir)
    end
    local file = io.open(config_path, 'r')
    if not file then
        file = io.open(config_path, 'w')
        if file then
            local success, err = pcall(function()
                file:write(json.encode(default_ini))
                file:close()
            end)
            if success then
                sampAddChatMessage('[Vosk] Ñîçäàí ôàéë íàñòğîåê ñ íàñòğîéêàìè ïî óìîë÷àíèş.', 0x71c8dd)
            else
                logError("Íå óäàëîñü ñîçäàòü ôàéë íàñòğîåê: " .. tostring(err))
            end
            return default_ini
        else
            logError("Êğèòè÷åñêàÿ îøèáêà: Íå óäàëîñü ñîçäàòü ôàéë íàñòğîåê")
            return default_ini
        end
    end
    local content = file:read('a')
    file:close()
    if not content or content:match("^%s$") then
        logError("Ôàéë íàñòğîåê ïóñò. Èñïîëüçóşòñÿ íàñòğîéêè ïî óìîë÷àíèş.")
        return default_ini
    end
    local success, loaded = pcall(json.decode, content)
    if not success then
        logError("Îøèáêà äåêîäèğîâàíèÿ VoskChat.json: " .. tostring(loaded))
        return default_ini
    end
    local function normalizeColor(color)
        if type(color) == "string" then
            if color:match("^0x%x+$") then
                return tonumber(color, 16)
            elseif color:match("^%d+$") then
                return tonumber(color)
            end
        elseif type(color) == "number" then
            return color
        end
        return 0xFFFFFFFF
    end
    if loaded.textPositions then
        for _, pos in pairs(loaded.textPositions) do
            if pos.color then
                pos.color = normalizeColor(pos.color)
            end
        end
    end
    return mergeTables(default_ini, loaded or {})
end
local function readVoiceDunText()
    local file = io.open(voice_dun_file_path, "r")
    if not file then
        return ""
    end
    local success, data = pcall(function()
        local content = file:read("a")
        file:close()
        return content
    end)
    if not success then
        logError("Îøèáêà ÷òåíèÿ VoiceDun.txt: " .. tostring(data))
        if file then file:close() end
        return ""
    end
    return data and data:gsub('\n', ' '):gsub('\r', '') or ""
end
local function areDevicesEqual(devices1, devices2)
    if #devices1 ~= #devices2 then return false end
    for i, dev1 in ipairs(devices1) do
        local dev2 = devices2[i]
        if not dev2 or dev1.index ~= dev2.index or dev1.name ~= dev2.name then
            return false
        end
    end
    return true
end
local cached_status = nil
local last_status_check = 0
local status_check_interval = 100 -- Èíòåğâàë ïğîâåğêè â ìèëëèñåêóíäàõ
local function readStatus()
    if not json then
        logError("Áèáëèîòåêà json íå çàãğóæåíà")
        return {ready = 0, ModelError = 0, ErrorMessage = "", devices = {}, voice_active = false,
                waiting_for_model_choice = false, download_progress = 0, mic_enabled = true, requested_device_index = nil, requested_model = nil}
    end
    local current_time = os.clock() * 1000
    if current_time - last_status_check < status_check_interval then
        return cached_status or {ready = 0, ModelError = 0, ErrorMessage = "", devices = {}, voice_active = false,
                                 waiting_for_model_choice = false, download_progress = 0, mic_enabled = true, requested_device_index = nil, requested_model = nil}
    end
    last_status_check = current_time
    local file = io.open(python_to_lua_file_path, "r")
    local content = ""
    if file then
        local success, result = pcall(function()
            content = file:read("a")
            file:close()
        end)
        if not success then
            logError("Îøèáêà ÷òåíèÿ python_to_lua.json: " .. tostring(result))
            if file then file:close() end
            return cached_status or {ready = 0, ModelError = 0, ErrorMessage = "", devices = {}, voice_active = false,
                                     waiting_for_model_choice = false, download_progress = 0, mic_enabled = true, requested_device_index = nil, requested_model = nil}
        end
    end
    if not content or content:match("^%s$") then
        return cached_status or {ready = 0, ModelError = 0, ErrorMessage = "", devices = {}, voice_active = false,
                                 waiting_for_model_choice = false, download_progress = 0, mic_enabled = true, requested_device_index = nil, requested_model = nil}
    end
    local success, config = pcall(json.decode, content)
    if not success or not config or not config.STATUS then
        logError("Îøèáêà äåêîäèğîâàíèÿ python_to_lua.json: " .. tostring(config))
        return cached_status or {ready = 0, ModelError = 0, ErrorMessage = "", devices = {}, voice_active = false,
                                 waiting_for_model_choice = false, download_progress = 0, mic_enabled = true, requested_device_index = nil, requested_model = nil}
    end
    local function decode_cp1251(str)
        return type(str) == "string" and str or tostring(str)
    end
    local new_status = {
        ready = config.STATUS.ready or 0,
        ModelError = config.STATUS.ModelError or 0,
        ErrorMessage = decode_cp1251(config.STATUS.ErrorMessage) or "",
        devices = config.STATUS.devices or {},
        voice_active = config.STATUS.voice_active or false,
        waiting_for_model_choice = config.STATUS.waiting_for_model_choice or false,
        download_progress = config.STATUS.download_progress or 0,
        requested_device_index = config.STATUS.requested_device_index,
        mic_enabled = config.STATUS.mic_enabled or true,
        requested_model = config.STATUS.requested_model or nil
    }
    if not cached_status or not areDevicesEqual(new_status.devices, cached_status.devices) or
       new_status.ready ~= cached_status.ready or
       new_status.ModelError ~= cached_status.ModelError or
       new_status.ErrorMessage ~= cached_status.ErrorMessage or
       new_status.voice_active ~= cached_status.voice_active or
       new_status.waiting_for_model_choice ~= cached_status.waiting_for_model_choice or
       new_status.download_progress ~= cached_status.download_progress or
       new_status.mic_enabled ~= cached_status.mic_enabled or
       new_status.requested_device_index ~= cached_status.requested_device_index or
       new_status.requested_model ~= cached_status.requested_model then
        cached_status = new_status
    end
    return cached_status
end
ffi.cdef[[
    void OpenProcess(uint32_t dwDesiredAccess, bool bInheritHandle, uint32_t dwProcessId);
    bool CloseHandle(void hObject);
    bool TerminateProcess(void hProcess, uint32_t uExitCode);
    typedef struct {
        uint32_t dwSize;
        uint32_t cntUsage;
        uint32_t th32ProcessID;
        uintptr_t th32DefaultHeapID;
        uint32_t th32ModuleID;
        uint32_t cntThreads;
        uint32_t th32ParentProcessID;
        int32_t pcPriClassBase;
        uint32_t dwFlags;
        char szExeFile[260];
    } PROCESSENTRY32;
    void CreateToolhelp32Snapshot(uint32_t dwFlags, uint32_t th32ProcessID);
    bool Process32First(void* hSnapshot, PROCESSENTRY32* lppe);
    bool Process32Next(void* hSnapshot, PROCESSENTRY32* lppe);
]]
local function isProcessRunning(processName)
    local snapshot = ffi.C.CreateToolhelp32Snapshot(0x2, 0)
    if snapshot == ffi.cast("void*", -1) then return false end
    local pe = ffi.new("PROCESSENTRY32")
    pe.dwSize = ffi.sizeof(pe)
    if ffi.C.Process32First(snapshot, pe) then
        repeat
            if ffi.string(pe.szExeFile):lower() == processName:lower() then
                ffi.C.CloseHandle(snapshot)
                return true
            end
        until not ffi.C.Process32Next(snapshot, pe)
    end
    ffi.C.CloseHandle(snapshot)
    return false
end
local function killProcess(processName)
    local snapshot = ffi.C.CreateToolhelp32Snapshot(0x2, 0)
    if snapshot == ffi.cast("void*", -1) then return false end
    local pe = ffi.new("PROCESSENTRY32")
    pe.dwSize = ffi.sizeof(pe)
    if ffi.C.Process32First(snapshot, pe) then
        repeat
            if ffi.string(pe.szExeFile):lower() == processName:lower() then
                local processHandle = ffi.C.OpenProcess(1, false, pe.th32ProcessID)
                if processHandle ~= nil then
                    ffi.C.TerminateProcess(processHandle, 0)
                    ffi.C.CloseHandle(processHandle)
                    ffi.C.CloseHandle(snapshot)
                    return true
                end
            end
        until not ffi.C.Process32Next(snapshot, pe)
    end
    ffi.C.CloseHandle(snapshot)
    return false
end
local function initializeVosk(ini)
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end
    if not isProcessRunning("VoskBladwin.exe") then
        killProcess("VoskBladwin.exe")
        wait(1000)
        if doesFileExist(python_to_lua_file_path) then
            os.remove(python_to_lua_file_path)
        end
        local success = os.execute('cd /d "' .. exe_path .. '" && start /min "" VoskBladwin.exe')
        if not success then
            logError("Íå óäàëîñü çàïóñòèòü VoskBladwin.exe")
            return
        end
        wait(1000)
        sampAddChatMessage('[Vosk] Èä¸ò çàãğóçêà ìîäåëè...', 0x71c8dd)
        if not json then
            logError("Áèáëèîòåêà json íå çàãğóæåíà, íåâîçìîæíî èíèöèàëèçèğîâàòü Vosk")
            return
        end
        local settings = {
            requested_model = ({[0] = "small", [1] = "medium", [2] = "large"})[ini.settings.model_type or 0],
            mic_enabled = true,
            requested_device_index = nil
        }
        local file = io.open(lua_to_python_file_path, "w")
        if file then
            local success, err = pcall(function()
                file:write(json.encode({SETTINGS = settings}))
                file:close()
            end)
            if not success then
                logError("Îøèáêà çàïèñè â lua_to_python.json: " .. tostring(err))
            end
        end
        sampAddChatMessage('[Vosk] Çàïóùåí ïğîöåññ VoskBladwin.exe. Îæèäàéòå çàãğóçêè ìîäåëè...', 0x71c8dd)
    else
        sampAddChatMessage('[Vosk] VoskBladwin.exe óæå çàïóùåí. Ïğîäîëæàş ğàáîòó.', 0x71c8dd)
    end
end
local error_message_shown = false
local function handleStatusMessages()
    local status = readStatus()
    if status.ModelError == 1 and not error_message_shown then
        sampAddChatMessage("Ïîæàëóéñòà, ïğîâåğüòå ìîäåëü: https://alphacephei.com/vosk/models", 0xFF0000)
        error_message_shown = true
    end
    if status.ErrorMessage ~= "" and not error_message_shown then
        local error_msg = type(status.ErrorMessage) == "string" and status.ErrorMessage or "Íåèçâåñòíàÿ îøèáêà"
        sampAddChatMessage("[Vosk]: " .. error_msg, 0xFFFF00)
        error_message_shown = true
    end
end
local uppercaseMap = {
    ["à"] = "À", ["á"] = "Á", ["â"] = "Â", ["ã"] = "Ã", ["ä"] = "Ä", ["å"] = "Å", ["¸"] = "¨", ["æ"] = "Æ", ["ç"] = "Ç",
    ["è"] = "È", ["é"] = "É", ["ê"] = "Ê", ["ë"] = "Ë", ["ì"] = "Ì", ["í"] = "Í", ["î"] = "Î", ["ï"] = "Ï", ["ğ"] = "Ğ",
    ["ñ"] = "Ñ", ["ò"] = "Ò", ["ó"] = "Ó", ["ô"] = "Ô", ["õ"] = "Õ", ["ö"] = "Ö", ["÷"] = "×", ["ø"] = "Ø", ["ù"] = "Ù",
    ["ú"] = "Ú", ["û"] = "Û", ["ü"] = "Ü", ["ı"] = "İ", ["ş"] = "Ş", ["ÿ"] = "ß"
}
local function capitalizeFirstLetter(str)
    if not str or str == "" then return "" end
    local firstChar = str:sub(1, 1)
    local upperChar = uppercaseMap[firstChar] or firstChar:upper()
    return upperChar .. str:sub(2)
end
local function createFont(name, size, flags)
    local font = renderCreateFont(name, size, flags)
    if not font then
        font = renderCreateFont("Default", size, flags) or renderCreateFont("Arial", size, flags)
        if not font then
            logError("Íå óäàëîñü ñîçäàòü øğèôò: " .. tostring(name))
        end
    end
    return font
end
local function ClickTheText(font, text, posX, posY, color, blockType, settings)
    if not font or not settings then return false end
    local originalColor = color
    renderFontDrawText(font, text, posX, posY, originalColor)
    local textLength = renderGetFontDrawTextLength(font, text)
    local textHeight = renderGetFontDrawHeight(font)
    local curX, curY = getCursorPos()
    if curX >= posX and curX <= posX + textLength and curY >= posY and curY <= posY + textHeight then
        if settings.settings.dragEnabled then
            renderFontDrawText(font, text, posX, posY, 0xFFFF0000)
            if isKeyJustPressed(VK_LBUTTON) then
                local offsetX, offsetY = curX - posX, curY - posY
                local isDragging = true
                while isDragging do
                    wait(0)
                    curX, curY = getCursorPos()
                    if blockType == "status" then
                        settings.textPositions.status.x, settings.textPositions.status.y = curX - offsetX, curY - offsetY
                    elseif blockType == "indicators" then
                        settings.textPositions.indicators.x, settings.textPositions.indicators.y = curX - offsetX, curY - offsetY
                    elseif blockType == "clipboardText" then
                        settings.textPositions.clipboardText.x, settings.textPositions.clipboardText.y = curX - offsetX, curY - offsetY
                    end
                    renderFontDrawText(font, text, curX - offsetX, curY - offsetY, 0xFFFF0000)
                    if not isKeyDown(VK_LBUTTON) then
                        isDragging = false
                        renderFontDrawText(font, text, posX, posY, originalColor)
                        saveSettings(settings)
                    end
                end
                return true
            end
        end
    end
    return false
end
local ini = loadSettings() or default_ini
local settingsWindow = nil
local cmdBuffer = nil
local editingButton = nil
local editingActivationKey = false
local prefixBuffers = {}
local isActive = true
local fonts = {}
local justAssigned = false
local last_devices = {}
local selected_device_message = ""
local model_loaded_message_shown = false
local imgui = nil
local vosk_ready = false
function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end
    -- Èíèöèàëèçèğóåì MessageSender
    MessageSender:init()
    if not checkAndDownloadJsonLibrary() then
        logError("Íå óäàëîñü óñòàíîâèòü json.lua. Ñêğèïò îñòàíîâëåí")
        return
    end
    if not json then
        logError("Áèáëèîòåêà json íå çàãğóçèëàñü. Ñêğèïò îñòàíîâëåí")
        return
    end
    local mimguiSuccess, imguiLoaded = setupMimgui()
    if not mimguiSuccess or not imguiLoaded then
        logError("Íå óäàëîñü íàñòğîèòü mimgui. Ñêğèïò îñòàíîâëåí")
        return
    end
    imgui = imguiLoaded
    sampAddChatMessage('[Vosk] Íà÷èíàş çàãğóçêó íàñòğîåê...', 0x71c8dd)
    -- Èíèöèàëèçèğóåì ini äî âûçîâà initializeVosk
    ini = loadSettings() or default_ini
    cmdBuffer = imgui.new.char[32](u8(ini.settings.cmd or "vosk"))
    settingsWindow = imgui.new.bool(false)
    fonts.status = createFont(ini.fonts.status.name, ini.fonts.status.size, ini.fonts.status.flags)
    fonts.indicators = createFont(ini.fonts.indicators.name, ini.fonts.indicators.size, ini.fonts.indicators.flags)
    fonts.clipboardText = createFont(ini.fonts.clipboardText.name, ini.fonts.clipboardText.size, ini.fonts.clipboardText.flags)
    for i, button in ipairs(ini.buttons) do
        prefixBuffers[i] = imgui.new.char[10](u8(button.prefix or ""))
    end
    -- Ïåğåäà¸ì ini â initializeVosk
    initializeVosk(ini)
    -- Ïğîâåğÿåì ñòàòóñ ñğàçó ïîñëå initializeVosk
    local status = readStatus()
    local model_folder = exe_path .. "\model_" .. (ini.settings.model_type and ({[0] = "small", [1] = "medium", [2] = "large"})[ini.settings.model_type] or "small")
    if status.ready == 1 and doesDirectoryExist(model_folder) then
        sampAddChatMessage('[Vosk] Ìîäåëü óñïåøíî çàãğóæåíà.', 0x71c8dd)
        vosk_ready = true
    elseif status.ModelError == 1 then
        sampAddChatMessage('[Vosk] Îøèáêà çàãğóçêè ìîäåëè. Ïîæàëóéñòà, ïğîâåğüòå ìîäåëü: https://alphacephei.com/vosk/models', 0xFF0000)
        vosk_ready = true -- Ñ÷èòàåì ãîòîâûì, ÷òîáû ïğîäîëæèòü, íî ñ îøèáêîé
    end
    imgui.OnFrame(
        function() return settingsWindow[0] end,
        function()
            if not ini or not ini.settings or not cmdBuffer then
                logError("Íàñòğîéêè èëè áóôåğû íå èíèöèàëèçèğîâàíû")
                settingsWindow[0] = false
                return
            end
            imgui.Begin(u8"VoskChat Íàñòğîéêè", settingsWindow)
            imgui.Text(u8"Íàñòğîéêè VoskChat")
            local status = readStatus()
            local mic_name = "Íåèçâåñòíî"
            if status.requested_device_index ~= nil then
                for , device in ipairs(status.devices) do
                    if device.index == status.requested_device_index then
                        mic_name = device.name or "Íåèçâåñòíî"
                        break
                    end
                end
            elseif selected_device_message ~= "" then
                mic_name = selected_device_message:gsub("Âûáğàíî óñòğîéñòâî: ", "")
            end
            imgui.Text(u8("Òåêóùèé ìèêğîôîí: " .. mic_name))
            local model_name = ini.settings.model_type and modelOptions[ini.settings.model_type + 1] or "Íå âûáğàíà"
            imgui.Text(u8("Òåêóùàÿ ìîäåëü: " .. model_name))
            local error_message = status.ErrorMessage or "Íåò îøèáîê"
            if error_message ~= "" then
                imgui.TextColored(imgui.ImVec4(1, 1, 0, 1), u8("[VoskPy]: " .. error_message))
            end
            local status_text = type(isActive) == "boolean" and (isActive and "Àêòèâåí" or "Íåàêòèâåí") or "Íåèçâåñòíî"
            imgui.Text(u8("Ñîñòîÿíèå: " .. status_text))
            imgui.SameLine()
            if imgui.Button(u8"Ïåğåêëş÷èòü##toggle") then
                isActive = not isActive
                local settings = {
                    mic_enabled = isActive,
                    requested_device_index = status.requested_device_index,
                    requested_model = status.requested_model
                }
                local file = io.open(lua_to_python_file_path, "w")
                if file then
                    file:write(json.encode({SETTINGS = settings}))
                    file:close()
                end
            end
            imgui.Text(u8"Êîìàíäà âûçîâà:")
            if imgui.InputText("##cmd", cmdBuffer, 32) then
                ini.settings.cmd = u8:decode(ffi.string(cmdBuffer))
                saveSettings(ini)
            end
            local activation_key = type(ini.settings.activationKey) == "string" and ini.settings.activationKey:gsub("VK", "") or "Íåèçâåñòíî"
            imgui.Text(u8("Êëàâèøà àêòèâàöèè: " .. activation_key))
            imgui.SameLine()
            if imgui.Button(u8"Èçìåíèòü##activation") then
                editingActivationKey = true
                sampAddChatMessage('[Vosk] Íàæìèòå êëàâèøó äëÿ àêòèâàöèè ñêğèïòà.', 0xFF0000)
            end
            imgui.Text(u8"Êíîïêè:")
            imgui.BeginChild("ButtonsSection", imgui.ImVec2(0, 150), true)
            for i, button in ipairs(ini.buttons) do
                imgui.Columns(3, "ButtonColumns" .. i, false)
                imgui.SetColumnWidth(0, 100)
                local button_key = type(button.key) == "string" and button.key:gsub("VK_", "") or "Íåèçâåñòíî"
                local button_text = string.format("Êíîïêà %d: %s", i, button_key)
                imgui.Text(u8(button_text))
                imgui.NextColumn()
                imgui.SetColumnWidth(1, 100)
                if imgui.InputText("##prefix" .. i, prefixBuffers[i], 10) then
                    button.prefix = u8:decode(ffi.string(prefixBuffers[i]))
                    saveSettings(ini)
                end
                imgui.NextColumn()
                imgui.SetColumnWidth(2, 150)
                if imgui.Button(u8"Èçìåíèòü##key" .. i) then
                    editingButton = i
                    sampAddChatMessage('[Vosk] Íàæìèòå êëàâèøó äëÿ êíîïêè ' .. i .. '.', 0xFF0000)
                end
                imgui.SameLine()
                if imgui.Button(u8"Óäàëèòü##del" .. i) then
                    table.remove(ini.buttons, i)
                    table.remove(prefixBuffers, i)
                    saveSettings(ini)
                end
                imgui.Columns(1)
            end
            imgui.EndChild()
            if imgui.Button(u8"Äîáàâèòü íîâóş êíîïêó") then
                table.insert(ini.buttons, {key = "VK_NONE", prefix = ""})
                table.insert(prefixBuffers, imgui.new.char10)
                saveSettings(ini)
                sampAddChatMessage('[Vosk] Äîáàâëåíà íîâàÿ êíîïêà.', 0x71c8dd)
            end
            if imgui.CollapsingHeader(u8"Íàñòğîéêà ìèêğîôîíà") then
                local status = readStatus()
                if vosk_ready and status.ready == 1 then
                    local devices = status.devices or {}
                    local selected_device = imgui.new.int(-1)
                    if #devices == 0 then
                        imgui.TextColored(imgui.ImVec4(1, 0, 0, 1), u8"Óñòğîéñòâà ââîäà íå íàéäåíû")
                    else
                        local combo_label = selected_device[0] == -1 and "Âûáğàòü óñòğîéñòâî" or (devices[selected_device[0] + 1] and devices[selected_device[0] + 1].name or "Íåèçâåñòíî")
                        if imgui.BeginCombo(u8"Âûáîğ ìèêğîôîíà", u8(combo_label)) then
                            for i, device in ipairs(devices) do
                                local device_name = device.name or "Óñòğîéñòâî " .. i
                                if imgui.Selectable(u8(device_name), selected_device[0] == device.index) then
                                    selected_device[0] = device.index
                                    local settings = {
                                        requested_device_index = device.index,
                                        mic_enabled = status.mic_enabled,
                                        requested_model = status.requested_model
                                    }
                                    local file = io.open(lua_to_python_file_path, "w")
                                    if file then
                                        file:write(json.encode({SETTINGS = settings}))
                                        file:close()
                                    end
                                    selected_device_message = u8("Âûáğàíî óñòğîéñòâî: " .. device_name)
                                end
                            end
                            imgui.EndCombo()
                        end
                        if selected_device_message ~= "" then
                            imgui.TextColored(imgui.ImVec4(1, 0, 0, 1), selected_device_message)
                        end
                    end
                else
                    imgui.TextColored(imgui.ImVec4(1, 1, 0, 1), u8"Îæèäàíèå çàãğóçêè ìîäåëè...")
                end
            end
            if imgui.CollapsingHeader(u8"Íàñòğîéêà ìîäåëè") then
                local status = readStatus()
                local current_model = ini.settings.model_type and modelOptions[ini.settings.model_type + 1] or "Âûáğàòü ìîäåëü"
                if imgui.BeginCombo(u8"Òèï ìîäåëè", u8(current_model)) then
                    for i, model_name in ipairs(modelOptions) do
                        if imgui.Selectable(u8(model_name), ini.settings.model_type == (i - 1)) then
                            ini.settings.model_type = i - 1
                            local model_value = ({[0] = "small", [1] = "medium", [2] = "large"})[i - 1]
                            local settings = {
                                requested_model = model_value,
                                waiting_for_model_choice = true,
                                download_progress = 0,
                                mic_enabled = status.mic_enabled,
                                requested_device_index = status.requested_device_index
                            }
                            local file = io.open(lua_to_python_file_path, "w")
                            if file then
                                file:write(json.encode({SETTINGS = settings}))
                                file:close()
                            end
                            sampAddChatMessage('[Vosk] Âûáğàíà ìîäåëü: ' .. model_name .. '. Ïåğåçàïóñê Vosk...', 0x71c8dd)
                            killProcess("VoskBladwin.exe")
                            if doesFileExist(python_to_lua_file_path) then
                                os.remove(python_to_lua_file_path)
                                sampAddChatMessage('[Vosk] Óäàë¸í ñòàğûé ñòàòóñ python_to_lua.json.', 0x71c8dd)
                            end
                            os.execute('cd /d "' .. exe_path .. '" && start /min "" VoskBladwin.exe')
                            error_message_shown = false
                            model_loaded_message_shown = false
                            vosk_ready = false
                        end
                    end
                    imgui.EndCombo()
                end
                if status.download_progress > 0 then
                    imgui.ProgressBar(status.download_progress / 100, imgui.ImVec2(-1, 0), u8"Çàãğóçêà...")
                end
            end
            if imgui.CollapsingHeader(u8"Íàñòğîéêà âèäèìîñòè òåêñòà") then
                if imgui.Checkbox(u8"Ñòàòóñ (ON/OFF)", imgui.new.bool(ini.textPositions.status.visible)) then
                    ini.textPositions.status.visible = not ini.textPositions.status.visible
                    saveSettings(ini)
                end
                if imgui.Checkbox(u8"Èíäèêàòîğû êíîïîê", imgui.new.bool(ini.textPositions.indicators.visible)) then
                    ini.textPositions.indicators.visible = not ini.textPositions.indicators.visible
                    saveSettings(ini)
                end
                if imgui.Checkbox(u8"Òåêñò èç áóôåğà", imgui.new.bool(ini.textPositions.clipboardText.visible)) then
                    ini.textPositions.clipboardText.visible = not ini.textPositions.clipboardText.visible
                    saveSettings(ini)
                end
            end
            if imgui.CollapsingHeader(u8"Íàñòğîéêà öâåòà òåêñòà") then
                if imgui.BeginCombo(u8"Öâåò èíäèêàòîğîâ", u8"Âûáğàòü öâåò") then
                    for , option in ipairs(colorOptions) do
                        local r = bit.band(bit.rshift(option.color, 16), 0xFF) / 255.0
                        local g = bit.band(bit.rshift(option.color, 8), 0xFF) / 255.0
                        local b = bit.band(option.color, 0xFF) / 255.0
                        local a = bit.band(bit.rshift(option.color, 24), 0xFF) / 255.0
                        imgui.ColorButton("##color" .. option.name, imgui.ImVec4(r, g, b, a), 0, imgui.ImVec2(20, 20))
                        imgui.SameLine()
                        if imgui.Selectable(u8(option.name)) then
                            ini.textPositions.indicators.color = option.color
                            saveSettings(ini)
                        end
                    end
                    imgui.EndCombo()
                end
                if imgui.BeginCombo(u8"Öâåò òåêñòà èç áóôåğà", u8"Âûáğàòü öâåò") then
                    for , option in ipairs(colorOptions) do
                        local r = bit.band(bit.rshift(option.color, 16), 0xFF) / 255.0
                        local g = bit.band(bit.rshift(option.color, 8), 0xFF) / 255.0
                        local b = bit.band(option.color, 0xFF) / 255.0
                        local a = bit.band(bit.rshift(option.color, 24), 0xFF) / 255.0
                        imgui.ColorButton("##color" .. option.name, imgui.ImVec4(r, g, b, a), 0, imgui.ImVec2(20, 20))
                        imgui.SameLine()
                        if imgui.Selectable(u8(option.name)) then
                            ini.textPositions.clipboardText.color = option.color
                            saveSettings(ini)
                        end
                    end
                    imgui.EndCombo()
                end
            end
            if imgui.CollapsingHeader(u8"Íàñòğîéêà øğèôòà") then
                if imgui.BeginCombo(u8"Øğèôò èíäèêàòîğîâ", u8(ini.fonts.indicators.name)) then
                    for , fontName in ipairs(fontOptions) do
                        if imgui.Selectable(u8(fontName)) then
                            ini.fonts.indicators.name = fontName
                            fonts.indicators = createFont(fontName, ini.fonts.indicators.size, ini.fonts.indicators.flags)
                            saveSettings(ini)
                        end
                    end
                    imgui.EndCombo()
                end
                local sizeIndicators = imgui.new.int(ini.fonts.indicators.size)
                if imgui.SliderInt(u8"Ğàçìåğ øğèôòà èíäèêàòîğîâ", sizeIndicators, 8, 72, "%d") then
                    ini.fonts.indicators.size = sizeIndicators[0]
                    fonts.indicators = createFont(ini.fonts.indicators.name, ini.fonts.indicators.size, ini.fonts.indicators.flags)
                    ini.textPositions.indicators.lineSpacing = ini.fonts.indicators.size + 5
                    saveSettings(ini)
                end
                if imgui.BeginCombo(u8"Øğèôò òåêñòà èç áóôåğà", u8(ini.fonts.clipboardText.name)) then
                    for , fontName in ipairs(fontOptions) do
                        if imgui.Selectable(u8(fontName)) then
                            ini.fonts.clipboardText.name = fontName
                            fonts.clipboardText = createFont(fontName, ini.fonts.clipboardText.size, ini.fonts.clipboardText.flags)
                            saveSettings(ini)
                        end
                    end
                    imgui.EndCombo()
                end
                local sizeClipboard = imgui.new.int(ini.fonts.clipboardText.size)
                if imgui.SliderInt(u8"Ğàçìåğ øğèôòà òåêñòà èç áóôåğà", sizeClipboard, 8, 72, "%d") then
                    ini.fonts.clipboardText.size = sizeClipboard[0]
                    fonts.clipboardText = createFont(ini.fonts.clipboardText.name, ini.fonts.clipboardText.size, ini.fonts.clipboardText.flags)
                    saveSettings(ini)
                end
            end
            if imgui.CollapsingHeader(u8"Íàñòğîéêà ïîçèöèé") then
                imgui.Text(u8"Ïåğåòàùèòå òåêñòîâûå ıëåìåíòû ìûøêîé äëÿ èçìåíåíèÿ èõ ïîçèöèé (åñëè ïåğåòàñêèâàíèå âêëş÷åíî).")
                imgui.Text(u8("Ğåæèì ïåğåòàñêèâàíèÿ: " .. (ini.settings.dragEnabled and "Âêëş÷¸í" or "Îòêëş÷¸í")))
                imgui.SameLine()
                if imgui.Button(u8"Ïåğåêëş÷èòü ïåğåòàñêèâàíèå##toggleDrag") then
                    ini.settings.dragEnabled = not ini.settings.dragEnabled
                    saveSettings(ini)
                end
            end
            if imgui.Button(u8"Ïåğåçàïóñòèòü Vosk") then
                killProcess("VoskBladwin.exe")
                if doesFileExist(python_to_lua_file_path) then
                    os.remove(python_to_lua_file_path)
                    sampAddChatMessage('[Vosk] Óäàë¸í ñòàğûé ñòàòóñ python_to_lua.json.', 0x71c8dd)
                end
                os.execute('cd /d "' .. exe_path .. '" && start /min "" VoskBladwin.exe')
                sampAddChatMessage('[Vosk] Ïåğåçàïóñê Vosk...', 0x71c8dd)
                error_message_shown = false
                model_loaded_message_shown = false
                vosk_ready = false
            end
            if imgui.Button(u8"Ñáğîñèòü íàñòğîéêè ïî óìîë÷àíèş") then
                ini = default_ini
                saveSettings(ini)
                for i, button in ipairs(ini.buttons) do
                    prefixBuffers[i] = imgui.new.char10
                end
                cmdBuffer = imgui.new.char32
                fonts.status = createFont(ini.fonts.status.name, ini.fonts.status.size, ini.fonts.status.flags)
                fonts.indicators = createFont(ini.fonts.indicators.name, ini.fonts.indicators.size, ini.fonts.indicators.flags)
                fonts.clipboardText = createFont(ini.fonts.clipboardText.name, ini.fonts.clipboardText.size, ini.fonts.clipboardText.flags)
                sampAddChatMessage('[Vosk] Íàñòğîéêè ñáğîøåíû.', 0x71c8dd)
            end
            imgui.End()
            if editingButton then
                for k, v in pairs(vkeys) do
                    if isKeyJustPressed(v) and k ~= "VK_LBUTTON" and k ~= "VK_ESCAPE" and k ~= "VK_RETURN" then
                        ini.buttons[editingButton].key = k
                        sampAddChatMessage('[Vosk] Êëàâèøà äëÿ êíîïêè ' .. editingButton .. ' èçìåíåíà íà ' .. k:gsub("VK", "") .. '.', 0x71c8dd)
                        editingButton = nil
                        justAssigned = true
                        saveSettings(ini)
                        break
                    end
                end
            end
            if editingActivationKey then
                for k, v in pairs(vkeys) do
                    if isKeyJustPressed(v) and k ~= "VK_LBUTTON" and k ~= "VK_ESCAPE" and k ~= "VK_RETURN" then
                        ini.settings.activationKey = k
                        sampAddChatMessage('[Vosk] Êëàâèøà àêòèâàöèè èçìåíåíà íà ' .. k:gsub("VK", "") .. '.', 0x71c8dd)
                        editingActivationKey = false
                        justAssigned = true
                        saveSettings(ini)
                        break
                    end
                end
            end
        end
    )
    while true do
        wait(0)
        if not ini or not ini.settings or not ini.textPositions or not ini.fonts or not fonts.status or not fonts.indicators or not fonts.clipboardText then
            logError("Íå óäàëîñü èíèöèàëèçèğîâàòü íåîáõîäèìûå êîìïîíåíòû")
            wait(1000)
            ini = loadSettings() or default_ini
            fonts.status = createFont(ini.fonts.status.name, ini.fonts.status.size, ini.fonts.status.flags)
            fonts.indicators = createFont(ini.fonts.indicators.name, ini.fonts.indicators.size, ini.fonts.indicators.flags)
            fonts.clipboardText = createFont(ini.fonts.clipboardText.name, ini.fonts.clipboardText.size, ini.fonts.clipboardText.flags)
        else
            if isKeyJustPressed(vkeys[ini.settings.activationKey]) then
                isActive = not isActive
                local status = readStatus()
                local settings = {
                    mic_enabled = isActive,
                    requested_device_index = status.requested_device_index,
                    requested_model = status.requested_model
                }
                local file = io.open(lua_to_python_file_path, "w")
                if file then
                    file:write(json.encode({SETTINGS = settings}))
                    file:close()
                end
            end
            handleStatusMessages()
            local isWindowActive = sampIsDialogActive() or sampIsChatInputActive() or sampIsScoreboardOpen() or isSampfuncsConsoleActive()
            local status = readStatus()
            local model_folder = exe_path .. "\model" .. (ini.settings.model_type and ({[0] = "small", [1] = "medium", [2] = "large"})[ini.settings.model_type] or "small")
            if not vosk_ready then
                if status.ready == 1 and doesDirectoryExist(model_folder) then
                    sampAddChatMessage('[Vosk] Ìîäåëü óñïåøíî çàãğóæåíà.', 0x71c8dd)
                    vosk_ready = true
                elseif status.ModelError == 1 then
                    sampAddChatMessage('[Vosk] Îøèáêà çàãğóçêè ìîäåëè. Ïîæàëóéñòà, ïğîâåğüòå ìîäåëü: https://alphacephei.com/vosk/models', 0xFF0000)
                    vosk_ready = true
                end
            end
            if not areDevicesEqual(status.devices, last_devices) then
                last_devices = status.devices
            end
            if ini.textPositions.status.visible then
                local statusText = (isActive and not isWindowActive and status.ready == 1) and "[ON]" or "[OFF]"
                local statusColor = (isActive and not isWindowActive and status.ready == 1) and 0xFF00FF00 or 0xFFFF0000
                if status.voice_active then
                    statusText = statusText .. " ·"
                end
                renderFontDrawText(fonts.status, statusText, ini.textPositions.status.x, ini.textPositions.status.y, statusColor)
                if ini.settings.dragEnabled then
                    ClickTheText(fonts.status, statusText, ini.textPositions.status.x, ini.textPositions.status.y, statusColor, "status", ini)
                end
            end
            if ini.textPositions.indicators.visible then
                for i, button in ipairs(ini.buttons) do
                    local text = string.format("%s (%s)", button.key:gsub("VK", ''), (button.prefix ~= '' and button.prefix or 'Îñíîâíîé'))
                    local x, y = ini.textPositions.indicators.x, ini.textPositions.indicators.y + (i - 1) * (ini.textPositions.indicators.lineSpacing or 20)
                    renderFontDrawText(fonts.indicators, text, x, y, ini.textPositions.indicators.color)
                    if i == 1 and ini.settings.dragEnabled then
                        ClickTheText(fonts.indicators, text, x, y, ini.textPositions.indicators.color, "indicators", ini)
                    end
                end
            end
            if ini.textPositions.clipboardText.visible then
                local voiceDunText = readVoiceDunText()
                if #voiceDunText > 0 then
                    local text = ' òåêñò: ' .. voiceDunText
                    renderFontDrawText(fonts.clipboardText, text, ini.textPositions.clipboardText.x, ini.textPositions.clipboardText.y, ini.textPositions.clipboardText.color)
                    if ini.settings.dragEnabled then
                        ClickTheText(fonts.clipboardText, text, ini.textPositions.clipboardText.x, ini.textPositions.clipboardText.y, ini.textPositions.clipboardText.color, "clipboardText", ini)
                    end
                end
            end
            if isActive and not isWindowActive and not justAssigned and vosk_ready and status.ready == 1 then
                for _, button in ipairs(ini.buttons) do
                    if button.key and vkeys[button.key] and isKeyJustPressed(vkeys[button.key]) then
                        local voiceDunText = readVoiceDunText()
                        if voiceDunText and #voiceDunText > 0 then
                            if not (button.prefix == "/me " or button.prefix == "/seeme ") then
                                voiceDunText = capitalizeFirstLetter(voiceDunText)
                            end
                            local message = button.prefix .. (button.prefix ~= "" and " " or "") .. voiceDunText
                            MessageSender:sendChatMessage(message)
                        end
                    end
                end
            end
            if justAssigned then
                wait(100)
                justAssigned = false
            end
        end
    end
end
function samp.onSendCommand(cmd)
    if not imgui then
        logError("mimgui íå èíèöèàëèçèğîâàí")
        return false
    end
    if not ini or not ini.settings or not settingsWindow then
        logError("Íàñòğîéêè èëè îêíî íå èíèöèàëèçèğîâàíû")
        return false
    end
    if cmd:lower() == "/" .. (ini.settings.cmd or "vosk") then
        settingsWindow[0] = not settingsWindow[0]
        return false
    end
end