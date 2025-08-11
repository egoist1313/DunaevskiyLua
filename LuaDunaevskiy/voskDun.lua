-- Глобальные переменные
local script_name = 'VoskChat'
local script_version = '01/09/2024'

-- Зависимости
local vkeys = require 'vkeys'
local ffi = require 'ffi'
local samp = require 'samp.events'
local encoding = require("encoding")
encoding.default = "CP1251"
local u8 = encoding.UTF8

local font_flag = require('moonloader').font_flag
local config_path = getGameDirectory() .. '/moonloader/config/VoskChat.json'
local exe_path = getWorkingDirectory() .. '\\VoskBladwin'
local status_file_path = exe_path .. "\\prints.json"
local voice_dun_file_path = exe_path .. "\\VoiceDun.txt"

-- Конфигурации и настройки по умолчанию
local defaultPositions = {
    status = {x = 15, y = 600, color = 0xFFFFFFFF, visible = true},
    indicators = {x = 5, y = 265, color = 0xFFFFFF00, lineSpacing = 20, visible = true},
    clipboardText = {x = 70, y = 600, color = 0xFFFFFFFF, visible = true}
}

local textPositions = {
    status = {x = 15, y = 600, color = 0xFFFFFFFF, visible = true},
    indicators = {x = 5, y = 265, color = 0xFFFFFF00, lineSpacing = 20, visible = true},
    clipboardText = {x = 70, y = 600, color = 0xFFFFFFFF, visible = true}
}

local default_ini = {
    buttons = {
        {key = "VK_E", prefix = ""},
        {key = "VK_C", prefix = "/do "},
        {key = "VK_U", prefix = "/u "},
        {key = "VK_4", prefix = "/seeme "}
    },
    textPositions = {
        status = {x = 15, color = "0xFFFFFFFF", y = 510, visible = true},
        indicators = {x = 13, color = "0xFF00FF00", y = 293, visible = true, lineSpacing = 17},
        clipboardText = {x = 70, color = "0xFF00FFFF", y = 510, visible = true}
    },
    fonts = {
        status = {size = 13, name = "Arial", flags = 3},
        indicators = {size = 12, name = "Arial", flags = 3},
        clipboardText = {size = 13, name = "Arial", flags = 3}
    },
    settings = {activationKey = "VK_F4", cmd = "vosk"}
}

local function checkAndDownloadJsonLibrary()
    local libPath = getWorkingDirectory() .. '\\lib'
    local jsonPath = libPath .. '\\json.lua'
    
    if not doesDirectoryExist(libPath) then
        createDirectory(libPath)
    end
    
    local file = io.open(jsonPath, 'r')
    
    if not file then
        sampAddChatMessage('[Vosk] Библиотека json.lua не найдена. Начинаю скачивание...', 0xFF0000)
        os.execute('start /B cmd.exe /c curl -o "' .. jsonPath .. '" https://raw.githubusercontent.com/rxi/json.lua/master/json.lua')
        sampAddChatMessage('[Vosk] Библиотека json.lua успешно скачана.', 0x00FF00)
        return true
    else
        file:close()
        return true
    end
end

-- Функция для сохранения настроек в файл
local function saveSettings(data)
    if type(data) ~= "table" then
        sampAddChatMessage('[Vosk] Ошибка: data не является таблицей.', 0xFF0000)
        return
    end
    if type(data.textPositions) ~= "table" then
        sampAddChatMessage('[Vosk] Ошибка: data.textPositions не является таблицей.', 0xFF0000)
        return
    end

    for _, pos in pairs(data.textPositions) do
        if pos.color then
            pos.color = string.format("0x%08X", pos.color)
        end
    end

    local json_content = json.encode(data)
    sampAddChatMessage('[Vosk] Сохраняемые настройки:\n' .. json_content, 0x71c8dd)
    
    local file = io.open(config_path, 'w')
    if file then
        file:write(json_content)
        file:close()
    else
        sampAddChatMessage('[Vosk] Не удалось открыть файл настроек для записи.', 0xFF0000)
    end
end

local function loadSettings()
    local file, err = io.open(config_path, 'r')
    
    if not file then
        sampAddChatMessage('[Vosk] Не удалось открыть файл настроек: ' .. err, 0xFF0000)
        saveSettings(default_ini)
        file = io.open(config_path, 'r')
    end

    if not file then
        sampAddChatMessage('[Vosk] Не удалось создать файл настроек.', 0xFF0000)
        return default_ini
    end

    local content, err = file:read('*a')
    file:close()

    if not content or content:match("^%s*$") then
        sampAddChatMessage('[Vosk] Файл настроек пуст. Используются настройки по умолчанию.', 0xFF0000)
        saveSettings(default_ini)
        return default_ini
    end

    local success, loaded = pcall(json.decode, content)
    if not success then
        sampAddChatMessage('[Vosk] Ошибка при десериализации JSON-файла настроек: ' .. loaded, 0xFF0000)
        saveSettings(default_ini)
        return default_ini
    end


    if loaded.textPositions then
        for _, pos in pairs(loaded.textPositions) do
            if pos.color then
                pos.color = tonumber(pos.color)
            end
        end
    end

    local mergedSettings = {
        settings = loaded.settings or default_ini.settings,
        buttons = loaded.buttons or default_ini.buttons,
        fonts = loaded.fonts or default_ini.fonts,
        textPositions = loaded.textPositions or defaultPositions
    }

    for key, defaultPos in pairs(defaultPositions) do
        local pos = mergedSettings.textPositions[key]
        if pos then
            pos.x = pos.x or defaultPos.x
            pos.y = pos.y or defaultPos.y
            pos.color = pos.color or defaultPos.color
            pos.lineSpacing = pos.lineSpacing or defaultPos.lineSpacing
            pos.visible = pos.visible or defaultPos.visible
        else
            mergedSettings.textPositions[key] = {
                x = defaultPos.x,
                y = defaultPos.y,
                color = defaultPos.color,
                lineSpacing = defaultPos.lineSpacing,
                visible = defaultPos.visible
            }
        end
    end

    return mergedSettings
end

-- Функция для применения настроек без сохранения
local function applySettings(newSettings)
    for key, value in pairs(newSettings) do
        ini[key] = value
    end
end

-- Флаг для контроля записи настроек
local shouldSaveSettings = false

-- Функция для перезагрузки настроек
local function reloadSettings()
    ini = loadSettings()
    sampAddChatMessage('Настройки VoskChat перезагружены', 0x71c8dd)
end

ffi.cdef[[
    void* OpenProcess(uint32_t dwDesiredAccess, bool bInheritHandle, uint32_t dwProcessId);
    bool CloseHandle(void* hObject);
    bool TerminateProcess(void* hProcess, uint32_t uExitCode);
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
    void* CreateToolhelp32Snapshot(uint32_t dwFlags, uint32_t th32ProcessID);
    bool Process32First(void* hSnapshot, PROCESSENTRY32* lppe);
    bool Process32Next(void* hSnapshot, PROCESSENTRY32* lppe);
]]

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

local tableEqual = function(t1, t2)
    if #t1 ~= #t2 then return false end
    for i = 1, #t1 do
        if t1[i] ~= t2[i] then return false end
    end
    return true
end

local lastIndicators = {}
local lastIndicatorsX = textPositions.indicators.x
local lastIndicatorsY = textPositions.indicators.y

local function renderIndicators(table, x, y, color, font, lineSpacing, visible)
    if not visible then return end

    for i, button in ipairs(table) do
        local text = string.format("%s (%s)", button.key:gsub("VK_", ''), (button.prefix ~= '' and button.prefix or 'Основной'))
        renderFontDrawText(font, text, x, y + (i - 1) * lineSpacing, color)
    end
end

local lastStatusText = ""
local lastStatusColor = 0xFFFFFFFF
local lastClipboardText = ""
local lastClipboardTextX = textPositions.clipboardText.x
local lastClipboardTextY = textPositions.clipboardText.y

local function handleClipboardText(fonts)
    local maxLength = 50
    local text = ""
    local file = io.open(voice_dun_file_path, "r")
    if file then
        local data = file:read("*a")
        file:close()
        if data and data:match("%S") then
            text = data
            recognizedText = data
            recognitionStarted = true
        end
    end
    text = text:gsub('\n', ' '):gsub('\r', '')
    if #text > maxLength then
        text = text:sub(1, maxLength) .. "..."
    end
    
    if textPositions.clipboardText.visible then
        renderFontDrawText(fonts.clipboardText, ' текст: ' .. text, textPositions.clipboardText.x, textPositions.clipboardText.y, textPositions.clipboardText.color)
    end
    return text
end

function ClickTheText(font, text, posX, posY, color, colorHover)
   renderFontDrawText(font, text, posX, posY, color)
   local textLength = renderGetFontDrawTextLength(font, text)
   local textHeight = renderGetFontDrawHeight(font)
   local curX, curY = getCursorPos()
   if curX >= posX and curX <= posX + textLength and curY >= posY and curY <= posY + textHeight then
     renderFontDrawText(font, text, posX, posY, colorHover)
     if isKeyJustPressed(1) then
       return true
     end
   end
   return false
end

local isActive = true
local isSettingsActive = false
local recognitionStarted = false
local recognizedText = ""
local status = {ready = 0, ModelError = 0, ErrorMessage = ""}

local statusReadyChecked = false

local function readStatus()
    if statusReadyChecked then return end

    local file = io.open(status_file_path, "r")
    
    if not file then
        sampAddChatMessage("[Vosk] Не удалось открыть файл статуса. Создаю новый файл.", 0xFF0000)
        file = io.open(status_file_path, "w")
        if file then
            file:write(json.encode({STATUS = status}))
            file:close()
        else
            sampAddChatMessage("[Vosk] Не удалось создать файл статуса.", 0xFF0000)
        end
        return
    end

    local content = file:read("*a")
    file:close()

    if not content or content:match("^%s*$") then
        sampAddChatMessage("[Vosk] Файл статуса пуст. Создаю новый файл.", 0xFF0000)
        file = io.open(status_file_path, "w")
        if file then
            file:write(json.encode({STATUS = status}))
            file:close()
        else
            sampAddChatMessage("[Vosk] Не удалось создать файл статуса.", 0xFF0000)
        end
        return
    end
    local success, config = pcall(json.decode, content)
    if not success or not config then
        sampAddChatMessage("[Vosk] Ошибка при десериализации JSON-файла статуса. Создаю новый файл.", 0xFF0000)
        file = io.open(status_file_path, "w")
        if file then
            file:write(json.encode({STATUS = status}))
            file:close()
        else
            sampAddChatMessage("[Vosk] Не удалось создать файл статуса.", 0xFF0000)
        end
        return
    end

    status.ready = config.STATUS.ready or 0
    status.ModelError = config.STATUS.ModelError or 0
    status.ErrorMessage = config.STATUS.ErrorMessage or ""

    if status.ready == 1 then
        statusReadyChecked = true
    end
end

local function initialize()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end

    killProcess("VoskBladwin.exe")
    wait(1000)

    os.execute('cd /d "' .. exe_path .. '" && start /min "" VoskBladwin.exe')
    wait(1000)

    sampAddChatMessage('[Vosk] Идет загрузка модели... ', 0x71c8dd)

    status.ready = 0
    local file = io.open(status_file_path, "w")
    if file then
        file:write(json.encode({STATUS = status}))
        file:close()
    end

    while status.ready ~= 1 do
        readStatus()
        wait(500)
    end

    sampAddChatMessage('[Vosk] Модель успешно загружена, можете говорить. Для настроек используйте команду / /'..ini.settings.cmd, 0x71c8dd)

    local fonts = {
        status = renderCreateFont(ini.fonts.status.name, ini.fonts.status.size, ini.fonts.status.flags),
        indicators = renderCreateFont(ini.fonts.indicators.name, ini.fonts.indicators.size, ini.fonts.indicators.flags),
        clipboardText = renderCreateFont(ini.fonts.clipboardText.name, ini.fonts.clipboardText.size, ini.fonts.clipboardText.flags)
    }

    return fonts
end

local previousModelErrorMessage = nil
local previousErrorMessage = nil

local function handleStatusMessages(fonts)
    if not fonts then
        error("Fonts are not initialized")
    end

    if not textPositions then
        sampAddChatMessage('[Vosk] Ошибка: textPositions не инициализирован.', 0xFF0000)
        return
    end

    local file, err = io.open(status_file_path, "r")
    
    if not file then
        sampAddChatMessage("[Vosk] Не удалось открыть файл статуса: " .. err, 0xFF0000)
        return
    end

    local content, err = file:read("*a")
    if not content then
        sampAddChatMessage("[Vosk] Ошибка при чтении файла статуса: " .. err, 0xFF0000)
        file:close()
        return
    end

    file:close()

    if content:match("^%s*$") then
        sampAddChatMessage("[Vosk] Файл статуса пуст.", 0xFF0000)
        return
    end

    local success, config = pcall(json.decode, content)
    if not success or not config then
        sampAddChatMessage("[Vosk] Ошибка при десериализации JSON-файла статуса.", 0xFF0000)
        return
    end

    status.ready = config.STATUS.ready or 0
    status.ModelError = config.STATUS.ModelError or 0
    status.ErrorMessage = config.STATUS.ErrorMessage or ""

    if status.ModelError == 1 and previousModelErrorMessage ~= "Пожалуйста, скачайте модель с https://alphacephei.com/vosk/models и распакуйте в папку 'model'" then
        sampAddChatMessage("Пожалуйста, скачайте модель с https://alphacephei.com/vosk/models и распакуйте в папку 'model'", 0xFF0000)
        previousModelErrorMessage = "Пожалуйста, скачайте модель с https://alphacephei.com/vosk/models и распакуйте в папку 'model'"
    end
    if status.ErrorMessage ~= "" and previousErrorMessage ~= status.ErrorMessage then
        sampAddChatMessage("Ошибка: " .. status.ErrorMessage, 0xFF0000)
        previousErrorMessage = status.ErrorMessage
    end
    
    local isWindowActive = sampIsDialogActive() or sampIsChatInputActive() or sampIsScoreboardOpen() or isSampfuncsConsoleActive()
    local statusText = (isActive and not isWindowActive) and "[ON]" or "[OFF]"
    local statusColor = (isActive and not isWindowActive) and 0xFF00FF00 or 0xFFFF0000

    local file = io.open(voice_dun_file_path, "r")
    if file then
        local data = file:read("*a")
        file:close()
        if data and data:match("%S") then
            statusText = (isActive and not isWindowActive) and "(ON)" or "(OFF)"
            statusColor = (isActive and not isWindowActive) and 0xFF00FF00 or 0xFFFF0000
        end
    end
    
    if textPositions.status.visible then
        renderFontDrawText(fonts.status, statusText, textPositions.status.x, textPositions.status.y, statusColor)
    end
end

local uppercaseMap = {
    ["а"] = "А", ["б"] = "Б", ["в"] = "В", ["г"] = "Г", ["д"] = "Д", ["е"] = "Е", ["ё"] = "Ё", ["ж"] = "Ж", ["з"] = "З",
    ["и"] = "И", ["й"] = "Й", ["к"] = "К", ["л"] = "Л", ["м"] = "М", ["н"] = "Н", ["о"] = "О", ["п"] = "П", ["р"] = "Р",
    ["с"] = "С", ["т"] = "Т", ["у"] = "У", ["ф"] = "Ф", ["х"] = "Х", ["ц"] = "Ц", ["ч"] = "Ч", ["ш"] = "Ш", ["щ"] = "Щ",
    ["ъ"] = "Ъ", ["ы"] = "Ы", ["ь"] = "Ь", ["э"] = "Э", ["ю"] = "Ю", ["я"] = "Я"
}
local function capitalizeFirstLetter(str)
    local firstChar = str:sub(1, 1)
    local upperChar = uppercaseMap[firstChar] or firstChar:upper()
    return upperChar .. str:sub(2)
end
local function handleButtonPresses()
    if isActive then
        for _, button in ipairs(ini.buttons) do
            if button.key and vkeys[button.key] and isKeyJustPressed(vkeys[button.key]) then 
                local voiceDunText = readVoiceDunText()
                if voiceDunText then
                    if not (button.prefix == "/me " or button.prefix == "/seeme ") then
                        voiceDunText = capitalizeFirstLetter(voiceDunText)
                    end
                    sampSendChat((button.prefix or "") .. voiceDunText)
                end
            end
        end
    end
end

local function handleSettingsDragging(fonts)
    local curX, curY = getCursorPos()
    for blockType, pos in pairs(textPositions) do
        if blockType ~= "status" then
            if ClickTheText(fonts[blockType], "Перетащите " .. blockType, pos.x, pos.y - 20, 0xFFFFFFFF, 0xFFFF0000) then
                local offsetX, offsetY = curX - pos.x, curY - pos.y
                local isDragging = true
                while isDragging do
                    wait(0)
                    curX, curY = getCursorPos()
                    pos.x, pos.y = curX - offsetX, curY - offsetY

                    if blockType == "clipboardText" then
                        textPositions.status.x = pos.x - 55
                        textPositions.status.y = pos.y
                    end
                    
                    local wheel = getMousewheelDelta()
                    if wheel ~= 0 then
                        local newSize = math.max(8, math.min(72, ini.fonts[blockType].size + wheel))
                        ini.fonts[blockType].size = newSize
                        fonts[blockType] = renderCreateFont(ini.fonts[blockType].name, newSize, ini.fonts[blockType].flags)
                        sampAddChatMessage('[Vosk] Новый размер шрифта для ' .. blockType .. ': ' .. newSize, 0x71c8dd)
                        if blockType == "indicators" then
                            textPositions.indicators.lineSpacing = newSize + 5 
                        end
                    end
                    
                    renderFontDrawText(fonts[blockType], "Перетащите " .. blockType, pos.x, pos.y - 20, 0xFFFF0000)
                    
                    if not isKeyDown(1) then
                        isDragging = false
                    end
                end
                applySettings({textPositions = textPositions, fonts = ini.fonts})
            end
        end
    end
end

function main()
    if not checkAndDownloadJsonLibrary() then
        return
    end

    json = require('json')

    ini = loadSettings()
    if not ini or not ini.textPositions then
        sampAddChatMessage('[Vosk] Ошибка: ini или ini.textPositions не инициализированы.', 0xFF0000)
        return
    end
    textPositions = ini.textPositions
    local fonts = initialize()
    local lastDialogState = false

    handleStatusMessages(fonts)

    while true do
        wait(0)

        -- Проверка на активные диалоги, открытый чат, таблицу результатов или консоль
        local isWindowActive = sampIsDialogActive() or sampIsChatInputActive() or sampIsScoreboardOpen() or isSampfuncsConsoleActive()
        local currentlyActive = isActive and not isWindowActive

        if status.ready == 1 then
            handleStatusMessages(fonts)
            renderIndicators(ini.buttons, textPositions.indicators.x, textPositions.indicators.y, textPositions.indicators.color, fonts.indicators, textPositions.indicators.lineSpacing, textPositions.indicators.visible)
            local clipboardText = handleClipboardText(fonts)

            if currentlyActive then
                handleButtonPresses()
            end

            if isKeyJustPressed(vkeys[ini.settings.activationKey]) then
                isActive = not isActive
                sampAddChatMessage(isActive and "VoskChat активирован" or "VoskChat деактивирован", 0x71c8dd)
            end

            local currentDialogState = sampIsDialogActive(2898) or sampIsDialogActive(2894)
            if currentDialogState ~= lastDialogState then
                sampToggleCursor(currentDialogState)
                lastDialogState = currentDialogState
            end

            if isSettingsActive then
                handleSettingsDragging(fonts)
            end
        else
            readStatus()
            wait(500)
        end

        processDialogQueue()
    end
end

function readVoiceDunText()
    local file = io.open(voice_dun_file_path, "r")
    if file then
        local data = file:read("*a")
        file:close()
        return data
    end
    return nil
end

function samp.onSendCommand(cmd)
    if cmd:lower() == "/"..ini.settings.cmd then
        shouldSaveSettings = true
        isSettingsActive = true
        ShowDialog(1)
        return false
    end
end

local colorOptions = {
    {name = "Красный", color = 0xFFFF0000},
    {name = "Оранжевый", color = 0xFFFFA500},
    {name = "Желтый", color = 0xFFFFFF00},
    {name = "Зеленый", color = 0xFF00FF00},
    {name = "Голубой", color = 0xFF00FFFF},
    {name = "Синий", color = 0xFF0000FF},
    {name = "Фиолетовый", color = 0xFF8A2BE2},
    {name = "Белый", color = 0xFFFFFFFF},
}

local fontOptions = {
    {name = "Arial"},
    {name = "Times New Roman"},
    {name = "Verdana"},
    {name = "Tahoma"},
    {name = "Courier New"},
    {name = "Georgia"},
    {name = "Palatino Linotype"},
    {name = "Comic Sans MS"},
    {name = "Trebuchet MS"},
    {name = "Arial Black"},
    {name = "Impact"}
}

local dialogQueue = {}

function ShowDialog(int)
    if int == 1 then
        local lines = {}
        for i, button in ipairs(ini.buttons) do
            lines[i] = string.format("Кнопка %d\t%s (%s)", i, button.key:gsub("VK_", ''), (button.prefix ~= '' and button.prefix or 'Основной'))
        end
        table.insert(lines, "Добавить новую кнопку")
        table.insert(lines, "Удалить кнопку")
        table.insert(lines, "Команда вызова настроек\t"..ini.settings.cmd)
        table.insert(lines, "Клавиша активации скрипта\t"..ini.settings.activationKey:gsub("VK_", ''))
        table.insert(lines, "Сбросить позицию текста по умолчанию")
        table.insert(lines, "Настроить цвет текста")
        table.insert(lines, "Настроить видимость текста")
        table.insert(lines, "Настроить шрифт текста")  -- Добавлен пункт для выбора шрифта
        table.insert(lines, "Сохранить настройки")
        local text = table.concat(lines, "\n")
        sampShowDialog(2894, "LUA VoskChat", text, "Выбрать", "Закрыть", 4)
        
        table.insert(dialogQueue, function()
            while sampIsDialogActive(2894) do
                wait(0)
            end
            local result, button, list = sampHasDialogRespond(2894)
            if result and button == 1 then
                if list < #ini.buttons then
                    ChangeKeyDialog(list + 1)
                elseif list == #ini.buttons then
                    AddNewButton()
                elseif list == #ini.buttons + 1 then
                    DeleteButton()
                elseif list == #ini.buttons + 2 then
                    ShowDialog(2)
                elseif list == #ini.buttons + 3 then
                    ChangeActivationKey()
                elseif list == #ini.buttons + 4 then
                    ResetToDefaultPositions()
                    ShowDialog(1) 
                elseif list == #ini.buttons + 5 then
                    ShowColorMenu()
                elseif list == #ini.buttons + 6 then
                    ShowTextVisibilityMenu()
                elseif list == #ini.buttons + 7 then
                    ShowFontMenu()  -- Добавлен вызов меню выбора шрифта
                elseif list == #ini.buttons + 8 then
                    saveSettings(ini)
                    sampAddChatMessage('Настройки сохранены.', 0x71c8dd)
                    ShowDialog(1)
                end
            end
            
            shouldSaveSettings = false
            isSettingsActive = false
        end)
    elseif int == 2 then
        sampShowDialog(2895, "LUA VoskChat", "{FFFFFF}Введите новую команду для вызова настроек", "Выбрать", "Закрыть", 1)
        
        table.insert(dialogQueue, function()
            while sampIsDialogActive(2895) do
                wait(0)
            end
            local result, button, _, input = sampHasDialogRespond(2895)
            if result and button == 1 then
                ini.settings.cmd = input
                applySettings({settings = ini.settings})
            end
            ShowDialog(1)
        end)
    end
end

function ShowColorMenu()
    local items = {
        "Индикаторы кнопок",
        "Текст из буфера обмена"
    }
    sampShowDialog(2899, "Выберите текстовый блок для изменения цвета", table.concat(items, "\n"), "Выбрать", "Назад", 4)
    
    table.insert(dialogQueue, function()
        while sampIsDialogActive(2899) do
            wait(0)
        end
        local result, button, list = sampHasDialogRespond(2899)
        if result and button == 1 then
            local blockTypes = {"indicators", "clipboardText"}
            local selectedBlock = blockTypes[list + 1]
            if selectedBlock then
                ChangeTextColor(selectedBlock)
            end
        else
            ShowDialog(1)
        end
    end)
end

function ChangeTextColor(blockType)
    local colorMenu = {}
    for i, option in ipairs(colorOptions) do
        table.insert(colorMenu, string.format("{%06X}%s", bit.band(option.color, 0xFFFFFF), option.name))
    end
    
    sampShowDialog(2900, "Выберите цвет", table.concat(colorMenu, "\n"), "Выбрать", "Назад", 4)
    
    table.insert(dialogQueue, function()
        while sampIsDialogActive(2900) do
            wait(0)
        end
        local result, button, list = sampHasDialogRespond(2900)
        if result and button == 1 and colorOptions[list + 1] then
            textPositions[blockType].color = colorOptions[list + 1].color
            applySettings({textPositions = textPositions})
        end
        ShowColorMenu()
    end)
end

function ShowTextVisibilityMenu()
    local items = {
        "Статус (ON/OFF)",
        "Индикаторы кнопок",
        "Текст из буфера обмена"
    }
    sampShowDialog(2898, "Настройка видимости текста", table.concat(items, "\n"), "Выбрать", "Назад", 4)
    
    table.insert(dialogQueue, function()
        while sampIsDialogActive(2898) do
            wait(0)
        end
        local result, button, list = sampHasDialogRespond(2898)
        if result and button == 1 then
            if list == 0 then
                ToggleTextVisibility("status")
            elseif list == 1 then
                ToggleTextVisibility("indicators")
            elseif list == 2 then
                ToggleTextVisibility("clipboardText")
            end
        else
            ShowDialog(1)
        end
    end)
end

function ToggleTextVisibility(blockType)
    textPositions[blockType].visible = not textPositions[blockType].visible
    applySettings({textPositions = textPositions})
    ShowTextVisibilityMenu()
end

function ResetToDefaultPositions()
    for blockType, defaultPos in pairs(defaultPositions) do
        textPositions[blockType] = {x = defaultPos.x, y = defaultPos.y, color = defaultPos.color, lineSpacing = defaultPos.lineSpacing, visible = defaultPos.visible}
    end
    applySettings({textPositions = textPositions})
end

function ChangeKeyDialog(buttonIndex)
    sampAddChatMessage('[Vosk]Нажмите клавишу для кнопки', 0xFF0000)
    
    local function waitForKeyPress()
        while true do
            wait(0)
            for k, v in pairs(vkeys) do
                if isKeyJustPressed(v) and k ~= "VK_LBUTTON" and k ~= "VK_ESCAPE" and k ~= "VK_RETURN" then
                    ini.buttons[buttonIndex].key = k
                    sampShowDialog(2896, "LUA VoskChat", "{FFFFFF}Введите префикс для кнопки. Если префикс пустой, то будет 'Основной'", "Выбрать", "Закрыть", 1)
                    
                    local function waitForPrefixInput()
                        while sampIsDialogActive(2896) do
                            wait(100)
                        end
                        local result, button, _, input = sampHasDialogRespond(2896)
                        if result and button == 1 then
                            ini.buttons[buttonIndex].prefix = input ~= "" and input .. ' ' or ""
                        end
                        applySettings({buttons = ini.buttons})
                        ShowDialog(1)
                    end
                    
                    table.insert(dialogQueue, waitForPrefixInput)
                    return
                end
            end
        end
    end
    
    table.insert(dialogQueue, waitForKeyPress)
end

function ChangeActivationKey()
    sampAddChatMessage('[Vosk]Нажмите клавишу для активации', 0xFF0000)
    
    local function waitForKeyPress()
        while true do
            wait(0)
            for k, v in pairs(vkeys) do
                if isKeyJustPressed(v) and k ~= "VK_LBUTTON" and k ~= "VK_ESCAPE" and k ~= "VK_RETURN" then
                    ini.settings.activationKey = k
                    applySettings({settings = ini.settings})
                    sampAddChatMessage("Клавиша активации скрипта изменена на " .. k:gsub("VK_", ''), 0x71c8dd)
                    ShowDialog(1)
                    return
                end
            end
        end
    end
    
    table.insert(dialogQueue, waitForKeyPress)
end

function AddNewButton()
    table.insert(ini.buttons, {key = "VK_NONE", prefix = ""})
    sampAddChatMessage("Новая кнопка добавлена. Нажмите, чтобы изменить клавишу и префикс.", 0x71c8dd)
    ChangeKeyDialog(#ini.buttons)
end

function DeleteButton()
    sampShowDialog(2897, "LUA VoskChat", "{FFFFFF}Введите номер кнопки, которую хотите удалить", "Удалить", "Отмена", 1)
    
    table.insert(dialogQueue, function()
        while sampIsDialogActive(2897) do
            wait(100)
        end
        local result, button, _, input = sampHasDialogRespond(2897)
        if result and button == 1 then
            local index = tonumber(input)
            if index and index > 0 and index <= #ini.buttons then
                table.remove(ini.buttons, index)
                applySettings({buttons = ini.buttons})
                sampAddChatMessage('Кнопка удалена', 0x71c8dd)
            else
                sampAddChatMessage('Неверный номер кнопки', 0xFF0000)
            end
        end
        ShowDialog(1)
    end)
end

function onScriptTerminate(script, quitGame)
    if script == thisScript() then
        killProcess("VoskBladwin.exe")
    end
end

function ShowFontMenu()
    local items = {}
    for i, font in ipairs(fontOptions) do
        table.insert(items, font.name)
    end
    sampShowDialog(2901, "Выберите шрифт", table.concat(items, "\n"), "Выбрать", "Назад", 4)
    
    table.insert(dialogQueue, function()
        while sampIsDialogActive(2901) do
            wait(0)
        end
        local result, button, list = sampHasDialogRespond(2901)
        if result and button == 1 and fontOptions[list + 1] then
            local selectedFont = fontOptions[list + 1].name
            ChangeTextFont(selectedFont)
        else
            ShowDialog(1)
        end
    end)
end

function ChangeTextFont(fontName)
    local items = {
        "Индикаторы кнопок",
        "Текст из буфера обмена"
    }
    sampShowDialog(2902, "Выберите текстовый блок для изменения шрифта", table.concat(items, "\n"), "Выбрать", "Назад", 4)
    
    table.insert(dialogQueue, function()
        while sampIsDialogActive(2902) do
            wait(0)
        end
        local result, button, list = sampHasDialogRespond(2902)
        if result and button == 1 then
            local blockTypes = {"indicators", "clipboardText"}
            local selectedBlock = blockTypes[list + 1]
            if selectedBlock then
                ini.fonts[selectedBlock].name = fontName
                applySettings({fonts = ini.fonts})
                sampAddChatMessage('Шрифт для ' .. selectedBlock .. ' изменен на ' .. fontName, 0x71c8dd)
            end
        end
        ShowDialog(1)
    end)
end

-- Обработка очереди диалогов
function processDialogQueue()
    if #dialogQueue > 0 and not sampIsDialogActive() then
        local dialogFunc = table.remove(dialogQueue, 1)
        dialogFunc()
    end
end