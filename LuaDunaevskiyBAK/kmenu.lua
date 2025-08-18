
local script_name = 'AlexKmenu'
local script_version = '2.0.0'
require "lib.moonloader"
require "lib.sampfuncs"
local sampev = require "lib.samp.events"
local imgui = require "imgui"
local encoding = require "encoding"
local json = require "json"
local key = require "vkeys"
local fa = require('fAwesome5')
local inspect = require "inspect"
local MessageSender = require 'lib.messagesender' -- Подключаем библиотеку

encoding.default = 'CP1251'
local u8 = encoding.UTF8

print("Проверка ImGui: " .. tostring(imgui))
if imgui == nil then
    print("Ошибка: ImGui не загружен")
    return
end
local scriptInitiatedDialog = false
local inviteInProgress = false
local RADIUS = 2.0
local RADIUSPOHIT = 5.0
local STREAM_DISTANCE = 190.0
local MESSAGE_DELAY = 1.5
local settings_file = getWorkingDirectory() .. "\\LuaDunaevskiy\\config\\kmenu_settings.json"
local passport_file = getWorkingDirectory() .. "\\LuaDunaevskiy\\config\\passport_values.txt"
local loggingEnabled = false -- Логи включены по умолчанию
local showWindow = imgui.ImBool(false)
local timerWindowVisible = imgui.ImBool(false)

local fa_font = nil
local fa_glyph_ranges = imgui.ImGlyphRanges({ fa.min_range, fa.max_range })
local showKey = imgui.ImInt(key.VK_F3) -- Новая клавиша для показа/скрытия окна
local showKeySelecting = imgui.ImBool(false)
local showKeyEnabled = imgui.ImBool(true) -- Включена ли клавиша показа
local targetKey = imgui.ImInt(key.VK_F4) -- Клавиша для запоминания цели
local targetKeySelecting = imgui.ImBool(false)
local lockedTargetId = nil -- ID запомненной цели
local targetInputBuffer = imgui.ImBuffer("", 5) -- Буфер для ввода ID цели
local kidnappingStarted = false --для цифры 6
local kidnappingDialogInitiated = false -- Флаг для обработки диалога при начале похищения через клавишу 6
local InvertoryDialog = false  -- Флаг инвентаря
local InvertoryVerevka = false -- Наличие веревки
local InvertoryTrapka = false -- Наличие тряпки
local teamMembers = {} -- Таблица для хранения членов команды
local inventoryWindowVisible = imgui.ImBool(true) 

local systemMessages = {
    {before = {u8"/me снял веревку с бронежилета"}, after = {u8"/me туго затянул веревки на руках $name"}},
    {before = {u8"/me прицелился в $name"}, after = {u8"/me ударил $name $gan"}},
    {before = {u8"/me достал кляп из кармана"}, after = {u8"/me заткнул рот $name кляпом"}},
    {before = {u8"/me открыл дверь $car"}, after = {u8"/me затолкал $name в $car"}},
    {before = {u8"/me подошел к $car"}, after = {u8"/me выкинул $name из $car"}},
    {before = {u8"/me схватил $name за руку"}, after = {u8"/me повел $name за собой", u8"Не дергайся"}}
}
local systemMessageBuffers = {}
for i = 1, 6 do
    systemMessageBuffers[i] = {before = {}, after = {}}
    for j, msg in ipairs(systemMessages[i].before) do
        systemMessageBuffers[i].before[j] = imgui.ImBuffer(msg, 256)
    end
    for j, msg in ipairs(systemMessages[i].after) do
        systemMessageBuffers[i].after[j] = imgui.ImBuffer(msg, 256)
    end
end

local rpMessages = {
    {u8"/me cнял верёвку и связал руки $name"},
    {u8"/me ударил $name $gan"},
    {u8"/me заткнул $name рот кляпом"},
    {u8"/me затащил $name в $car"},
    {u8"/me вытащил $name из $car"},
    {u8"/me повёл $name за собой"}
}
local rpMessageBuffers = {}
for i = 1, 6 do
    rpMessageBuffers[i] = {}
    for j, msg in ipairs(rpMessages[i]) do
        rpMessageBuffers[i][j] = imgui.ImBuffer(msg, 256)
    end
end

local messageEnabled = {}
for i = 1, 6 do
    messageEnabled[i] = imgui.ImBool(true)
end

local timerEventMessages = {}
local timerEventMessageBuffers = {}
local timerMessageEnabled = {} -- Новые галочки для таймеров

for i = 1, 6 do
    timerEventMessages[i] = {
        before = {u8"/me ввел пароль от бомбы и установил таймер на $time"},
        during = {u8"/do Таймер отсчитывает: $time"},
        after = {u8"/do Таймер завершился!"},
        interval = 120
    }
    timerEventMessageBuffers[i] = {
        before = {},
        during = {},
        after = {},
        intervalBuffer = imgui.ImInt(timerEventMessages[i].interval)
    }
    timerMessageEnabled[i] = {
        before = imgui.ImBool(true),
        during = imgui.ImBool(true),
        after = imgui.ImBool(true)
    }
    for j, msg in ipairs(timerEventMessages[i].before) do
        timerEventMessageBuffers[i].before[j] = imgui.ImBuffer(msg, 256)
    end
    for j, msg in ipairs(timerEventMessages[i].during) do
        timerEventMessageBuffers[i].during[j] = imgui.ImBuffer(msg, 256)
    end
    for j, msg in ipairs(timerEventMessages[i].after) do
        timerEventMessageBuffers[i].after[j] = imgui.ImBuffer(msg, 256)
    end
end

local hideKey = imgui.ImInt(key.VK_F2)
local keySelecting = imgui.ImBool(false)
local keyUpdated = false
local mode = imgui.ImInt(1)
local modeNames = {u8"Системой", u8"По РП"}

local weaponMappings = {
    [0] = u8"кулаком",
    [1] = u8"кастетом",
    [2] = u8"клюшкой для гольфа",
    [5] = u8"битой",
    [7] = u8"кием",
    [8] = u8"катаной",
    [10] = u8"дилдо",
    [14] = u8"букетом цветов",
    [23] = u8"рукояткой Glock с глушителем",
    [24] = u8"рукояткой Desert Eagle",
    [25] = u8"дробовиком",
    [29] = u8"прикладом MP5",
    [30] = u8"прикладом АК-47",
    [31] = u8"прикладом винтовки M4",
    [33] = u8"прикладом охотничьего ружья"
}


local carTypeNames = {
    [1] = u8"Машину",
    [2] = u8"Вертолёт",
    [3] = u8"Лодку",
    [4] = u8"Самолёт"
}

local ganTypeNames = {
    [0] = u8"Кулак",
    [1] = u8"Кастет",
    [2] = u8"Клюшка для гольфа",
    [5] = u8"Бита",
    [7] = u8"Кий",
    [8] = u8"Катана",
    [10] = u8"Дилдо",
    [14] = u8"Букет цветов",
    [24] = u8"Desert Eagle",
    [23] = u8"Glock с глушителем",
    [25] = u8"Дробовик",
    [29] = u8"MP5",
    [31] = u8"Винтовка M4",
    [33] = u8"Охотничье ружьё",
    [30] = u8"АК-47"
}

local endings = {}
for i = 1, 6 do
    endings[i] = {
        system = {before = {}, after = {}}, -- Для системного режима
        rp = {}                             -- Для РП-режима
    }
    -- Инициализация для системного режима
    for j = 1, #systemMessages[i].before do
        endings[i].system.before[j] = {
            car = {u8"машину", u8"вертолёт", u8"лодку", u8"самолёт"},
            gan = weaponMappings
        }
    end
    for j = 1, #systemMessages[i].after do
        endings[i].system.after[j] = {
            car = {u8"машину", u8"вертолёт", u8"лодку", u8"самолёт"},
            gan = weaponMappings
        }
    end
    -- Инициализация для РП-режима
    for j = 1, #rpMessages[i] do
        endings[i].rp[j] = {
            car = {u8"машину", u8"вертолёт", u8"лодку", u8"самолёт"},
            gan = weaponMappings
        }
    end
end

local endingBuffers = {}
for i = 1, 6 do
    endingBuffers[i] = {
        system = {before = {}, after = {}},
        rp = {}
    }
    -- Буферы для системного режима
    for j = 1, #systemMessages[i].before do
        endingBuffers[i].system.before[j] = {car = {}, gan = {}}
        for k, ending in ipairs(endings[i].system.before[j].car) do
            endingBuffers[i].system.before[j].car[k] = imgui.ImBuffer(ending, 256)
        end
        for id, ending in pairs(endings[i].system.before[j].gan) do
            endingBuffers[i].system.before[j].gan[id] = imgui.ImBuffer(ending, 256)
        end
    end
    for j = 1, #systemMessages[i].after do
        endingBuffers[i].system.after[j] = {car = {}, gan = {}}
        for k, ending in ipairs(endings[i].system.after[j].car) do
            endingBuffers[i].system.after[j].car[k] = imgui.ImBuffer(ending, 256)
        end
        for id, ending in pairs(endings[i].system.after[j].gan) do
            endingBuffers[i].system.after[j].gan[id] = imgui.ImBuffer(ending, 256)
        end
    end
    -- Буферы для РП-режима
    for j = 1, #rpMessages[i] do
        endingBuffers[i].rp[j] = {car = {}, gan = {}}
        for k, ending in ipairs(endings[i].rp[j].car) do
            endingBuffers[i].rp[j].car[k] = imgui.ImBuffer(ending, 256)
        end
        for id, ending in pairs(endings[i].rp[j].gan) do
            endingBuffers[i].rp[j].gan[id] = imgui.ImBuffer(ending, 256)
        end
    end
end

local timers = {}
local timerWindows = {}
local lastCommandTime = nil
local lastCommandIndex = nil
local lastTargetIdForMessage = nil
local lastWeaponId = nil
local commandConfirmed = false
local messageQueue = {}
local lastSendTime = nil
local floodDetected = false
local lastSentMessage = nil
local passportData = {}
local passportValues = {}
local awaitingPassport = false
local currentPassportName = nil
local passportUpdated = false
local activeText = nil
local lastTargetId = nil
local lastColor = nil
local lastColorPohit = nil
local function log(message)
    if loggingEnabled then
        print("[AlexKmenu Debug] " .. message)
    end
end

local function formatNumber(number)
    local formatted = tostring(number):reverse():gsub("(%d%d%d)", "%1."):reverse()
    if formatted:sub(1, 1) == "." then formatted = formatted:sub(2) end
    return formatted
end

local function loadPassportValues()
    if doesFileExist(passport_file) then
        local file = io.open(passport_file, "r")
        if file then
            for line in file:lines() do
                local fullKey, value = line:match("(.+)=(%d+)")
                if fullKey and value then
                    passportValues[fullKey] = "$" .. value
                    log("Загружено значение паспорта: " .. fullKey .. " = " .. passportValues[fullKey])
                end
            end
            file:close()
        end
    end
end

function getVehicleType(target)
    if isCharInAnyCar(target) then
        local vehicle = getCarCharIsUsing(target)
        local modelId = getCarModel(vehicle)
        local airplanes = {592, 577, 511, 512, 593, 520, 553, 476, 519, 460, 513}
        local helicopters = {548, 425, 417, 487, 488, 497, 563, 447, 469}
        local boats = {472, 473, 493, 595, 484, 430, 453, 452, 446}
        
        for _, id in ipairs(airplanes) do 
            if modelId == id then 
                log("Цель в самолёте, модель: " .. modelId)
                return 4 
            end 
        end
        for _, id in ipairs(helicopters) do 
            if modelId == id then 
                log("Цель в вертолёте, модель: " .. modelId)
                return 2 
            end 
        end
        for _, id in ipairs(boats) do 
            if modelId == id then 
                log("Цель в лодке, модель: " .. modelId)
                return 3 
            end 
        end
        log("Цель в машине, модель: " .. modelId)
        return 1
    else
        -- Получаем координаты цели
        local targetX, targetY, targetZ = getCharCoordinates(target)
        local minDistance = 30.0 -- Радиус поиска
        local nearestVehicle = nil
        local nearestModelId = nil
        
        for _, vehicleHandle in ipairs(getAllVehicles()) do
            if doesVehicleExist(vehicleHandle) then
                local vehX, vehY, vehZ = getCarCoordinates(vehicleHandle)
                local distance = getDistanceBetweenCoords3d(targetX, targetY, targetZ, vehX, vehY, vehZ)
                log("Транспорт handle " .. vehicleHandle .. ": модель " .. getCarModel(vehicleHandle) .. ", расстояние " .. distance)
                if distance <= minDistance then
                    minDistance = distance
                    nearestVehicle = vehicleHandle
                    nearestModelId = getCarModel(vehicleHandle)
                end
            end
        end
        
        if nearestVehicle then
            local airplanes = {592, 577, 511, 512, 593, 520, 553, 476, 519, 460, 513}
            local helicopters = {548, 425, 417, 487, 488, 497, 563, 447, 469}
            local boats = {472, 473, 493, 595, 484, 430, 453, 452, 446}
            
            for _, id in ipairs(airplanes) do 
                if nearestModelId == id then 
                    log("Найден ближайший самолёт, модель: " .. nearestModelId .. ", расстояние: " .. minDistance)
                    return 4 
                end 
            end
            for _, id in ipairs(helicopters) do 
                if nearestModelId == id then 
                    log("Найден ближайший вертолёт, модель: " .. nearestModelId .. ", расстояние: " .. minDistance)
                    return 2 
                end 
            end
            for _, id in ipairs(boats) do 
                if nearestModelId == id then 
                    log("Найден ближайшая лодка, модель: " .. nearestModelId .. ", расстояние: " .. minDistance)
                    return 3 
                end 
            end
            log("Найден ближайшая машина, модель: " .. nearestModelId .. ", расстояние: " .. minDistance)
            return 1
        else
            log("Ближайший транспорт не найден в радиусе " .. minDistance .. " единиц от цели")
            return 0 -- Нейтральное значение
        end
    end
end

local function getCarDescription(commandIndex, messageIndex, targetHandle, isBefore)
    local typeIndex = getVehicleType(targetHandle)
    if mode.v == 0 then
        local endingsTable = isBefore and endings[commandIndex].system.before[messageIndex].car or endings[commandIndex].system.after[messageIndex].car
        if typeIndex == 0 then 
            log("Транспорт не найден, используется нейтральное значение")
            return u8"транспорт" 
        end
        return endingsTable[typeIndex] or endingsTable[1]
    else
        if typeIndex == 0 then 
            log("Транспорт не найден, используется нейтральное значение")
            return u8"транспорт" 
        end
        return endings[commandIndex].rp[messageIndex].car[typeIndex] or endings[commandIndex].rp[messageIndex].car[1]
    end
end

local function formatTimeComponent(value, max)
    value = tonumber(value) or 0
    if value < 0 then value = 0 end
    if value > max then value = max end
    return string.format("%02d", value)
end

local function parseTimeString(timer)
    return (tonumber(timer.hours) or 0) * 3600 + 
           (tonumber(timer.minutes) or 0) * 60 + 
           (tonumber(timer.seconds) or 0)
end

local function formatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

local function processMessageQueue(message)
    if message then
        table.insert(messageQueue, message)
        log("Добавлено в очередь: " .. message)
    end
    
    if sampIsChatInputActive() or sampIsDialogActive(-1) then
        return
    end
    
    if #messageQueue > 0 and (not lastSendTime or (os.clock() - lastSendTime >= MESSAGE_DELAY)) then
        if floodDetected and lastSentMessage then
            MessageSender:sendChatMessage(lastSentMessage) -- Заменяем sampSendChat
            log("Переотправка после флуда: " .. lastSentMessage)
            lastSendTime = os.clock()
            floodDetected = false
            return
        end
        
        local msg = table.remove(messageQueue, 1)
        local decodedMsg = u8:decode(msg, 'CP1251')
        MessageSender:sendChatMessage(decodedMsg) -- Заменяем sampSendChat
        log("Отправлено из очереди: " .. msg .. " (декодировано: " .. decodedMsg .. ")")
        lastSentMessage = decodedMsg
        lastSendTime = os.clock()
    end
end

function saveSettings()
    local configDir = getWorkingDirectory() .. "/LuaDunaevskiy/config"
    if not doesDirectoryExist(configDir) then
        createDirectory(configDir)
    end

    -- Сохранение клавиш
    local keys = {
        mode = mode.v,
        hideKey = hideKey.v,
        showKey = showKey.v,
        showKeyEnabled = showKeyEnabled.v,
        targetKey = targetKey.v,
        lockedTargetId = lockedTargetId,
        inventoryPosition = inventoryPosition
    }
    local keysFile = io.open(configDir .. "/AlexKmenukeys.json", "w")
    if keysFile then
        keysFile:write(json.encode(keys))
        keysFile:close()
        log("Клавиши сохранены в " .. configDir .. "/AlexKmenukeys.json")
    else
        log("Ошибка: Не удалось сохранить клавиши")
    end

    -- Сохранение сообщений
    local messages = {
        system = {},
        rp = {},
        messageEnabled = {},
        endings = {},
        timerEventMessages = {},
        timerMessageEnabled = {}
    }
    for i = 1, 6 do
        messages.messageEnabled[i] = messageEnabled[i].v
        
        -- Системные сообщения (только изменённые)
        if not table.equals(systemMessages[i], systemMessagesDefault[i]) then
            messages.system[i] = {before = systemMessages[i].before, after = systemMessages[i].after}
        end
        
        -- RP-сообщения (только изменённые)
        if not table.equals(rpMessages[i], rpMessagesDefault[i]) then
            messages.rp[i] = rpMessages[i]
        end
        
        -- Окончания (сохраняем всегда, преобразуем gan в массив пар)
        messages.endings[i] = {system = {before = {}, after = {}}, rp = {}}
        for j = 1, #systemMessages[i].before do
            messages.endings[i].system.before[j] = {
                car = endings[i].system.before[j].car,
                gan = sparseToPairs(endings[i].system.before[j].gan)
            }
        end
        for j = 1, #systemMessages[i].after do
            messages.endings[i].system.after[j] = {
                car = endings[i].system.after[j].car,
                gan = sparseToPairs(endings[i].system.after[j].gan)
            }
        end
        for j = 1, #rpMessages[i] do
            messages.endings[i].rp[j] = {
                car = endings[i].rp[j].car,
                gan = sparseToPairs(endings[i].rp[j].gan)
            }
        end
        
        -- Сообщения таймеров
        messages.timerEventMessages[i] = {
            before = timerEventMessages[i].before,
            during = timerEventMessages[i].during,
            after = timerEventMessages[i].after,
            interval = timerEventMessages[i].interval
        }
        messages.timerMessageEnabled[i] = {
            before = timerMessageEnabled[i].before.v,
            during = timerMessageEnabled[i].during.v,
            after = timerMessageEnabled[i].after.v
        }
    end
    -- Логируем данные перед сохранением для отладки
    log("Сохраняемые сообщения: " .. inspect(messages))
    local messagesFile = io.open(configDir .. "/AlexKmenumessages.json", "w")
    if messagesFile then
        messagesFile:write(json.encode(messages))
        messagesFile:close()
        log("Сообщения сохранены в " .. configDir .. "/AlexKmenumessages.json")
    else
        log("Ошибка: Не удалось сохранить сообщения")
    end

    -- Сохранение таймеров
    local timersData = {}
    for i, timer in ipairs(timers) do
        timersData[i] = {
            label = timer.label,
            hours = timer.hours,
            minutes = timer.minutes,
            seconds = timer.seconds,
            enabled = timer.enabled,
            paused = timer.paused,
            elapsed = timer.elapsed or 0,
            position = timer.position
        }
    end
    local timersFile = io.open(configDir .. "/AlexKmenutimers.json", "w")
    if timersFile then
        timersFile:write(json.encode(timersData))
        timersFile:close()
        log("Таймеры сохранены в " .. configDir .. "/AlexKmenutimers.json")
    else
        log("Ошибка: Не удалось сохранить таймеры")
    end
end

-- Преобразование разреженного массива в массив пар {key, value}
function sparseToPairs(sparseTable)
    local pairsArray = {}
    for k, v in pairs(sparseTable) do
        table.insert(pairsArray, {key = k, value = v})
    end
    return pairsArray
end
-- Вспомогательная функция для преобразования разреженного массива в объект
function convertSparseToObject(sparseTable)
    local obj = {}
    for k, v in pairs(sparseTable) do
        obj[tostring(k)] = v -- Преобразуем числовые ключи в строки
    end
    return obj
end


function loadSettings()
    local configDir = getWorkingDirectory() .. "/LuaDunaevskiy/config"

    -- Инициализация значений по умолчанию
    initDefaultSettings()

    -- Загрузка клавиш
    local keysFile = configDir .. "/AlexKmenukeys.json"
    if doesFileExist(keysFile) then
        local file = io.open(keysFile, "r")
        if file then
            local content = file:read("*a")
            file:close()
            local success, keys = pcall(json.decode, content)
            if success and keys then
                mode.v = keys.mode or mode.v
                hideKey.v = keys.hideKey or hideKey.v
                showKey.v = keys.showKey or showKey.v
                showKeyEnabled.v = keys.showKeyEnabled ~= nil and keys.showKeyEnabled or showKeyEnabled.v
                targetKey.v = keys.targetKey or targetKey.v
                lockedTargetId = keys.lockedTargetId
                inventoryPosition = keys.inventoryPosition or inventoryPosition
                if lockedTargetId then targetInputBuffer.v = tostring(lockedTargetId) end
                log("Клавиши загружены из " .. keysFile)
            else
                log("Ошибка разбора AlexKmenukeys.json: " .. tostring(keys))
            end
        else
            log("Ошибка: Не удалось открыть " .. keysFile)
        end
    end

    -- Загрузка сообщений
    local messagesFile = configDir .. "/AlexKmenumessages.json"
    if doesFileExist(messagesFile) then
        local file = io.open(messagesFile, "r")
        if file then
            local content = file:read("*a")
            file:close()
            local success, messages = pcall(json.decode, content)
            if success and messages then
                for i = 1, 6 do
                    messageEnabled[i].v = messages.messageEnabled[i] or messageEnabled[i].v
                    
                    -- Системные сообщения
                    if messages.system[i] then
                        systemMessages[i] = messages.system[i]
                    end
                    for j, msg in ipairs(systemMessages[i].before) do
                        systemMessageBuffers[i].before[j] = imgui.ImBuffer(msg, 256)
                    end
                    for j, msg in ipairs(systemMessages[i].after) do
                        systemMessageBuffers[i].after[j] = imgui.ImBuffer(msg, 256)
                    end
                    
                    -- RP-сообщения
                    if messages.rp[i] then
                        rpMessages[i] = messages.rp[i]
                    end
                    for j, msg in ipairs(rpMessages[i]) do
                        rpMessageBuffers[i][j] = imgui.ImBuffer(msg, 256)
                    end
                    
                    -- Окончания (восстанавливаем gan из массива пар)
                    if messages.endings[i] then
                        for j = 1, #systemMessages[i].before do
                            if messages.endings[i].system.before[j] then
                                endings[i].system.before[j] = {
                                    car = messages.endings[i].system.before[j].car,
                                    gan = pairsToSparse(messages.endings[i].system.before[j].gan)
                                }
                                endingBuffers[i].system.before[j] = {car = {}, gan = {}}
                                for k, car in ipairs(endings[i].system.before[j].car) do
                                    endingBuffers[i].system.before[j].car[k] = imgui.ImBuffer(car, 256)
                                end
                                for id, gan in pairs(endings[i].system.before[j].gan) do
                                    endingBuffers[i].system.before[j].gan[id] = imgui.ImBuffer(gan, 256)
                                end
                            end
                        end
                        for j = 1, #systemMessages[i].after do
                            if messages.endings[i].system.after[j] then
                                endings[i].system.after[j] = {
                                    car = messages.endings[i].system.after[j].car,
                                    gan = pairsToSparse(messages.endings[i].system.after[j].gan)
                                }
                                endingBuffers[i].system.after[j] = {car = {}, gan = {}}
                                for k, car in ipairs(endings[i].system.after[j].car) do
                                    endingBuffers[i].system.after[j].car[k] = imgui.ImBuffer(car, 256)
                                end
                                for id, gan in pairs(endings[i].system.after[j].gan) do
                                    endingBuffers[i].system.after[j].gan[id] = imgui.ImBuffer(gan, 256)
                                end
                            end
                        end
                        for j = 1, #rpMessages[i] do
                            if messages.endings[i].rp[j] then
                                endings[i].rp[j] = {
                                    car = messages.endings[i].rp[j].car,
                                    gan = pairsToSparse(messages.endings[i].rp[j].gan)
                                }
                                endingBuffers[i].rp[j] = {car = {}, gan = {}}
                                for k, car in ipairs(endings[i].rp[j].car) do
                                    endingBuffers[i].rp[j].car[k] = imgui.ImBuffer(car, 256)
                                end
                                for id, gan in pairs(endings[i].rp[j].gan) do
                                    endingBuffers[i].rp[j].gan[id] = imgui.ImBuffer(gan, 256)
                                end
                            end
                        end
                    end
                    
                    -- Сообщения таймеров
                    if messages.timerEventMessages[i] then
                        timerEventMessages[i] = messages.timerEventMessages[i]
                        timerEventMessageBuffers[i] = {
                            before = {},
                            during = {},
                            after = {},
                            intervalBuffer = imgui.ImInt(timerEventMessages[i].interval)
                        }
                        for j, msg in ipairs(timerEventMessages[i].before) do
                            timerEventMessageBuffers[i].before[j] = imgui.ImBuffer(msg, 256)
                        end
                        for j, msg in ipairs(timerEventMessages[i].during) do
                            timerEventMessageBuffers[i].during[j] = imgui.ImBuffer(msg, 256)
                        end
                        for j, msg in ipairs(timerEventMessages[i].after) do
                            timerEventMessageBuffers[i].after[j] = imgui.ImBuffer(msg, 256)
                        end
                    end
                    if messages.timerMessageEnabled[i] then
                        timerMessageEnabled[i].before.v = messages.timerMessageEnabled[i].before
                        timerMessageEnabled[i].during.v = messages.timerMessageEnabled[i].during
                        timerMessageEnabled[i].after.v = messages.timerMessageEnabled[i].after
                    end
                end
                log("Сообщения загружены из " .. messagesFile)
            else
                log("Ошибка разбора AlexKmenumessages.json: " .. tostring(messages))
            end
        else
            log("Ошибка: Не удалось открыть " .. messagesFile)
        end
    end

    -- Загрузка таймеров
    local timersFile = configDir .. "/AlexKmenutimers.json"
    if doesFileExist(timersFile) then
        local file = io.open(timersFile, "r")
        if file then
            local content = file:read("*a")
            file:close()
            local success, timersData = pcall(json.decode, content)
            if success and timersData then
                timers = {}
                timerWindows = {}
                local screenX, screenY = getScreenResolution()
                for i, data in ipairs(timersData) do
                    timers[i] = {
                        label = data.label or "Таймер " .. i,
                        hours = data.hours or "00",
                        minutes = data.minutes or "01",
                        seconds = data.seconds or "00",
                        durationStr = data.hours .. ":" .. data.minutes .. ":" .. data.seconds,
                        enabled = data.enabled or false,
                        paused = data.paused or false,
                        elapsed = data.elapsed or 0,
                        labelBuffer = imgui.ImBuffer(u8(data.label or "Таймер " .. i), 256),
                        hoursBuffer = imgui.ImBuffer(u8(data.hours or "00"), 3),
                        minutesBuffer = imgui.ImBuffer(u8(data.minutes or "01"), 3),
                        secondsBuffer = imgui.ImBuffer(u8(data.seconds or "00"), 3),
                        enabledBuffer = imgui.ImBool(data.enabled or false),
                        position = data.position or {x = screenX * 0.1, y = screenY * 0.1 + (i - 1) * 50},
                        lastDuringMessageTime = nil
                    }
                    timerWindows[i] = imgui.ImBool(data.enabled or false)
                end
                log("Таймеры загружены из " .. timersFile)
            else
                log("Ошибка разбора AlexKmenutimers.json: " .. tostring(timersData))
            end
        else
            log("Ошибка: Не удалось открыть " .. timersFile)
        end
    end
end

-- Восстановление разреженного массива из массива пар
function pairsToSparse(pairsArray)
    local sparseTable = {}
    for _, pair in ipairs(pairsArray) do
        sparseTable[pair.key] = pair.value
    end
    return sparseTable
end
-- Инициализация значений по умолчанию
function initDefaultSettings()
    -- Основные переменные
    mode = imgui.ImInt(1)
    hideKey = imgui.ImInt(key.VK_F2)
    showKey = imgui.ImInt(key.VK_F3)
    showKeyEnabled = imgui.ImBool(true)
    targetKey = imgui.ImInt(key.VK_F4)
    lockedTargetId = nil
    targetInputBuffer = imgui.ImBuffer("", 5)
    local screenX, screenY = getScreenResolution()
    inventoryPosition = {x = screenX * 0.1, y = screenY * 0.1}

    -- Значения по умолчанию для сообщений
    systemMessagesDefault = {
        [1] = {before = {u8"/me снял веревку с бронежилета"}, after = {u8"/me туго затянул веревки на руках $name"}},
        [2] = {before = {u8"/me прицелился в $name"}, after = {u8"/me ударил $name $gan"}},
        [3] = {before = {u8"/me достал кляп из кармана"}, after = {u8"/me заткнул рот $name кляпом"}},
        [4] = {before = {u8"/me открыл дверь $car"}, after = {u8"/me затолкал $name в $car"}},
        [5] = {before = {u8"/me подошел к $car"}, after = {u8"/me выкинул $name из $car"}},
        [6] = {before = {u8"/me схватил $name за руку"}, after = {u8"/me повел $name за собой", u8"Не дергайся"}}
    }
    rpMessagesDefault = {
        [1] = {u8"/me cнял верёвку и связал руки $name"},
        [2] = {u8"/me ударил $name $gan"},
        [3] = {u8"/me заткнул $name рот кляпом"},
        [4] = {u8"/me затащил $name в $car"},
        [5] = {u8"/me вытащил $name из $car"},
        [6] = {u8"/me повёл $name за собой"}
    }
    systemMessages = table.clone(systemMessagesDefault)
    rpMessages = table.clone(rpMessagesDefault)

    -- Инициализация буферов сообщений
    systemMessageBuffers = {}
    rpMessageBuffers = {}
    messageEnabled = {}
    for i = 1, 6 do
        messageEnabled[i] = imgui.ImBool(true)
        systemMessageBuffers[i] = {before = {}, after = {}}
        rpMessageBuffers[i] = {}
        for j, msg in ipairs(systemMessages[i].before) do
            systemMessageBuffers[i].before[j] = imgui.ImBuffer(msg, 256)
        end
        for j, msg in ipairs(systemMessages[i].after) do
            systemMessageBuffers[i].after[j] = imgui.ImBuffer(msg, 256)
        end
        for j, msg in ipairs(rpMessages[i]) do
            rpMessageBuffers[i][j] = imgui.ImBuffer(msg, 256)
        end
    end

    -- Значения по умолчанию для окончаний
    endingsDefault = {}
    for i = 1, 6 do
        endingsDefault[i] = {system = {before = {}, after = {}}, rp = {}}
        for j = 1, #systemMessagesDefault[i].before do
            endingsDefault[i].system.before[j] = {
                car = {u8"машину", u8"вертолёт", u8"лодку", u8"самолёт"},
                gan = weaponMappings
            }
        end
        for j = 1, #systemMessagesDefault[i].after do
            endingsDefault[i].system.after[j] = {
                car = {u8"машину", u8"вертолёт", u8"лодку", u8"самолёт"},
                gan = weaponMappings
            }
        end
        for j = 1, #rpMessagesDefault[i] do
            endingsDefault[i].rp[j] = {
                car = {u8"машину", u8"вертолёт", u8"лодку", u8"самолёт"},
                gan = weaponMappings
            }
        end
    end
    endings = table.clone(endingsDefault)
    
    -- Инициализация буферов окончаний
    endingBuffers = {}
    for i = 1, 6 do
        endingBuffers[i] = {system = {before = {}, after = {}}, rp = {}}
        for j = 1, #systemMessages[i].before do
            endingBuffers[i].system.before[j] = {car = {}, gan = {}}
            for k, ending in ipairs(endings[i].system.before[j].car) do
                endingBuffers[i].system.before[j].car[k] = imgui.ImBuffer(ending, 256)
            end
            for id, ending in pairs(endings[i].system.before[j].gan) do
                endingBuffers[i].system.before[j].gan[id] = imgui.ImBuffer(ending, 256)
            end
        end
        for j = 1, #systemMessages[i].after do
            endingBuffers[i].system.after[j] = {car = {}, gan = {}}
            for k, ending in ipairs(endings[i].system.after[j].car) do
                endingBuffers[i].system.after[j].car[k] = imgui.ImBuffer(ending, 256)
            end
            for id, ending in pairs(endings[i].system.after[j].gan) do
                endingBuffers[i].system.after[j].gan[id] = imgui.ImBuffer(ending, 256)
            end
        end
        for j = 1, #rpMessages[i] do
            endingBuffers[i].rp[j] = {car = {}, gan = {}}
            for k, ending in ipairs(endings[i].rp[j].car) do
                endingBuffers[i].rp[j].car[k] = imgui.ImBuffer(ending, 256)
            end
            for id, ending in pairs(endings[i].rp[j].gan) do
                endingBuffers[i].rp[j].gan[id] = imgui.ImBuffer(ending, 256)
            end
        end
    end

    -- Сообщения таймеров по умолчанию
    timerEventMessages = {}
    timerEventMessageBuffers = {}
    timerMessageEnabled = {}
    for i = 1, 6 do
        timerEventMessages[i] = {
            before = {u8"/me ввел пароль от бомбы и установил таймер на $time"},
            during = {u8"/do Таймер отсчитывает: $time"},
            after = {u8"/do Таймер завершился!"},
            interval = 120
        }
        timerEventMessageBuffers[i] = {
            before = {},
            during = {},
            after = {},
            intervalBuffer = imgui.ImInt(timerEventMessages[i].interval)
        }
        timerMessageEnabled[i] = {
            before = imgui.ImBool(true),
            during = imgui.ImBool(true),
            after = imgui.ImBool(true)
        }
        for j, msg in ipairs(timerEventMessages[i].before) do
            timerEventMessageBuffers[i].before[j] = imgui.ImBuffer(msg, 256)
        end
        for j, msg in ipairs(timerEventMessages[i].during) do
            timerEventMessageBuffers[i].during[j] = imgui.ImBuffer(msg, 256)
        end
        for j, msg in ipairs(timerEventMessages[i].after) do
            timerEventMessageBuffers[i].after[j] = imgui.ImBuffer(msg, 256)
        end
    end

    -- Инициализация таймеров (пустой список по умолчанию)
    timers = {}
    timerWindows = {}
end

-- Сравнение таблиц
function table.equals(t1, t2)
    if type(t1) ~= type(t2) then return false end
    if type(t1) ~= "table" then return t1 == t2 end
    for k, v in pairs(t1) do
        if not table.equals(v, t2[k]) then return false end
    end
    for k, v in pairs(t2) do
        if t1[k] == nil then return false end
    end
    return true
end

-- Глубокое копирование таблицы
function table.clone(t)
    local copy = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            copy[k] = table.clone(v)
        else
            copy[k] = v
        end
    end
    return copy
end

local function getWeaponDescription(commandIndex, messageIndex, isBefore)
    -- Получаем ID текущего оружия игрока
    local weaponId = getCurrentCharWeapon(PLAYER_PED)
    
    -- Выбираем таблицу окончаний в зависимости от режима и типа сообщения (до/после)
    if mode.v == 0 then -- Системный режим
        local endingsTable = isBefore and endings[commandIndex].system.before[messageIndex].gan or endings[commandIndex].system.after[messageIndex].gan
        return endingsTable[weaponId] or weaponMappings[weaponId] or u8"оружием" -- Если нет, используем запасное слово
    else -- РП-режим
        return endings[commandIndex].rp[messageIndex].gan[weaponId] or weaponMappings[weaponId] or u8"оружием"
    end
end

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then 
        log("Ошибка: SA-MP или SAMPFUNCS не загружены")
        return 
    end
    while not isSampAvailable() do wait(100) end
    
    -- Инициализируем MessageSender
    MessageSender:init()
    
    -- Список разрешённых IP-адресов серверов (без строгой проверки порта)
    local allowedIPs = {
        "5.252.33.202",
        "legacy.samp-rp.ru"
    }
    
    -- Список разрешённых никнеймов локальных игроков
    local allowedNicknames = {
        "Alexandr_Dunaevskiy",
        "Andrey_Dunaevskiy",
        "Oleg_Dunaevskiy",
		"nick"
    }
    
    -- Получаем IP сервера
    local serverIP = sampGetCurrentServerAddress()
    log("Текущий IP сервера: " .. serverIP)
    
    -- Проверяем, соответствует ли IP сервера разрешённому
    local ipAllowed = false
    for _, ip in ipairs(allowedIPs) do
        if serverIP == ip then
            ipAllowed = true
            break
        end
    end
    
    if not ipAllowed then
        log("Скрипт не запущен: IP сервера " .. serverIP .. " не входит в список разрешённых")
        sampAddChatMessage("{FF0000}[AlexKmenu] {FFFFFF}Скрипт не работает на этом сервере.", -1)
        return
    end
    
    -- Получаем никнейм локального игрока
    local _, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
    local myNickname = sampGetPlayerNickname(myId)
    log("Локальный ник: " .. myNickname)
    
    -- Проверяем, входит ли никнейм игрока в список разрешённых
    local nicknameAllowed = false
    for _, nick in ipairs(allowedNicknames) do
        if myNickname == nick then
            nicknameAllowed = true
            break
        end
    end
    
    if not nicknameAllowed then
        log("Скрипт не запущен: Никнейм " .. myNickname .. " не входит в список разрешённых")
        sampAddChatMessage("{FF0000}[AlexKmenu] {FFFFFF}У вас нет доступа к использованию этого скрипта.", -1)
        return
    end
    
    -- Если проверки пройдены, продолжаем выполнение скрипта
    loadSettings()
    loadPassportValues()
    sampRegisterChatCommand("km", function(arg)
        if arg and arg ~= "" then
            local id = tonumber(arg)
            if id and sampIsPlayerConnected(id) then
                lockedTargetId = id
                targetInputBuffer.v = tostring(id)
                kidnappingActive = true
                keyUpdated = true
                log("Цель запомнена через команду: " .. id)
            end
        else
            showWindow.v = not showWindow.v
        end
    end)
    
    local textVisible = true
    local beforeMessagesSent = {}
    for i = 1, 6 do
        beforeMessagesSent[i] = false
    end
    
    local activeText = nil
    local lastCommandIndex = nil
    local lastTargetIdForMessage = nil
    local commandConfirmed = false
    local kidnappingStarted = false -- Новый флаг для начала похищения
    
    while true do
        wait(0)
        imgui.Process = showWindow.v or #timers > 0 or kidnappingActive
        
        processMessageQueue()
        
		if kidnappingActive then
			local newMembers = processTeamTextDraw()
			
			-- Обновляем список игроков из текстдрава
			if #newMembers > 0 then
				local currentNames = {}
				for _, member in ipairs(teamMembers) do
					currentNames[member.name] = true
				end
				
				local newNames = {}
				for _, name in ipairs(newMembers) do
					newNames[name] = true
					if not currentNames[name] then
						table.insert(teamMembers, {name = name, hp = 100, armor = 0, color = 0xFFFFFFFF})
						log("Добавлен новый игрок: " .. name)
					end
				end
				
				for i = #teamMembers, 1, -1 do
					if not newNames[teamMembers[i].name] then
						log("Удалён игрок: " .. teamMembers[i].name)
						table.remove(teamMembers, i)
					end
				end
			end
			
			-- Обновляем данные (HP, броня, цвет), включая локального игрока
			updateTeamMemberData()
		end
		
        -- Обработка таймеров
        for i, timer in ipairs(timers) do
            if timer.enabled and timer.startTime and not timer.paused then
                local elapsed = (timer.elapsed or 0) + (os.clock() - timer.startTime)
                local remaining = parseTimeString(timer) - elapsed
                if remaining <= 0 then
                    if timerMessageEnabled[i].after.v then
                        for _, msg in ipairs(timerEventMessages[i].after) do
                            local message = msg:gsub("$time", timer.durationStr):gsub("$label", timer.label)
                            processMessageQueue(message)
                        end
                    end
                    timer.startTime = nil
                    timer.paused = false
                    timer.elapsed = 0
                    timer.lastDuringMessageTime = nil
                    log("Таймер '" .. timer.label .. "' завершился")
                else
                    local lastMessageTime = timer.lastDuringMessageTime or 0
                    if timerMessageEnabled[i].during.v and os.clock() - lastMessageTime >= timerEventMessages[i].interval then
                        for _, msg in ipairs(timerEventMessages[i].during) do
                            local message = msg:gsub("$time", formatTime(remaining)):gsub("$label", timer.label)
                            processMessageQueue(message)
                        end
                        timer.lastDuringMessageTime = os.clock()
                    end
                end
            end
        end
        
        -- Обработка клавиши показа/скрытия окна
        if showKeyEnabled.v and isKeyJustPressed(showKey.v) and not (sampIsChatInputActive() or sampIsDialogActive(-1)) then
            showWindow.v = not showWindow.v
        end
        
        -- Проверка активации похищения и отображение текста
        if kidnappingActive then
            local targetId = nil
            
            -- Выбор цели: запомненная или через ПКМ
            if lockedTargetId and sampIsPlayerConnected(lockedTargetId) then
                targetId = lockedTargetId
            elseif isKeyDown(0x02) then
                local result, target = getCharPlayerIsTargeting(PLAYER_HANDLE)
                if result then
                    local res, id = sampGetPlayerIdByCharHandle(target)
                    if res then 
                        targetId = id 
                        log("Выбрана цель через ПКМ: " .. id)
                    end
                end
            end

            -- Обработка клавиши запоминания цели (F4) с использованием lastTargetId
            if isKeyJustPressed(targetKey.v) and not (sampIsChatInputActive() or sampIsDialogActive(-1)) then
                log("Нажата клавиша F4, текущая цель: " .. tostring(targetId) .. ", lastTargetId: " .. tostring(lastTargetId) .. ", lockedTargetId: " .. tostring(lockedTargetId))
                if lastTargetId and sampIsPlayerConnected(lastTargetId) then
                    if lockedTargetId == lastTargetId then
                        lockedTargetId = nil
                        targetInputBuffer.v = ""
                        log("Цель забыта: " .. lastTargetId)
                    else
                        lockedTargetId = lastTargetId
                        targetInputBuffer.v = tostring(lastTargetId)
                        local targetName = sampGetPlayerNickname(lastTargetId)
                        log("Цель запомнена: " .. lastTargetId)
                    end
                    keyUpdated = true  -- Устанавливаем флаг для немедленного обновления текста
                else
                    log("Нет последней выбранной цели для запоминания")
                end
            end

            -- Отрисовка текста: для запомненной цели — всегда, для незапомненной — только при ПКМ
            if targetId and (lockedTargetId or isKeyDown(0x02)) then
                local result, target = sampGetCharHandleBySampPlayerId(targetId)
                if result then
                    local targetX, targetY, targetZ = getCharCoordinates(target)
                    local myX, myY, myZ = getCharCoordinates(PLAYER_PED)
                    local distance = getDistanceBetweenCoords3d(myX, myY, myZ, targetX, targetY, targetZ)
                    
                    local color = (distance > RADIUS) and "{FF0000}" or "{00FF00}"
                    local colorPohit = (distance > RADIUSPOHIT) and "{FF0000}" or "{00FF00}"
                    local targetName = sampGetPlayerNickname(targetId)
                    local orgData = passportData[targetName] or "Неизвестно"
                    local value = passportValues[orgData] or ""
                    local formattedValue = value ~= "" and "{FFA500}$" .. formatNumber(value:sub(2)) or ""
                    local hideKeyName = key.id_to_name(hideKey.v) or "?"
                    local targetKeyName = key.id_to_name(targetKey.v) or "?"

                    -- Добавляем строку с организацией и должностью, если данные есть
                    local passportInfo = ""
                    if passportData[targetName] and passportData[targetName] ~= "Неизвестно" then
                        passportInfo = "\n{FFFFFF}" .. passportData[targetName]
                    end

                    -- Обновляем текст при смене цели, цвета или состояния запоминания
                    if targetId ~= lastTargetId or (activeText ~= nil and (lastColor ~= color or lastColorPohit ~= colorPohit)) or keyUpdated then
                        if activeText ~= nil then
                            sampDestroy3dText(activeText)
                            activeText = nil
                        end
                        textVisible = true
                        local result, target = sampGetCharHandleBySampPlayerId(targetId)
                        if result then
                            local targetX, targetY, targetZ = getCharCoordinates(target)
                            local myX, myY, myZ = getCharCoordinates(PLAYER_PED)
                            distance = getDistanceBetweenCoords3d(myX, myY, myZ, targetX, targetY, targetZ)
                        end
                        local color = (distance > RADIUS) and "{FF0000}" or "{00FF00}"
                        local colorPohit = (distance > RADIUSPOHIT) and "{FF0000}" or "{00FF00}"
                        
                        local targetName = sampGetPlayerNickname(targetId)
                        local orgData = passportData[targetName] or "Неизвестно"
                        local value = passportValues[orgData] or ""
                        local formattedValue = value ~= "" and "{FFA500}$" .. formatNumber(value:sub(2)) or ""
                        local hideKeyName = key.id_to_name(hideKey.v) or "?"
                        local targetKeyName = key.id_to_name(targetKey.v) or "?"

                        local passportInfo = ""
                        if passportData[targetName] and passportData[targetName] ~= "Неизвестно" then
                            passportInfo = "\n{FFFFFF}" .. passportData[targetName]
                        end

                        local text = "Цель: " .. targetName .. " " .. formattedValue .. 
                                     passportInfo .. "\n" .. 
                                     color .. "1. Нокаут\n" .. 
                                     color .. "2. Связать\n" .. 
                                     color .. "3. Кляп\n" .. 
                                     color .. "4. В авто/из авто\n" .. 
                                     color .. "5. Вести цель за собой\n" .. 
                                     colorPohit .. "6. Начать похищение\n" .. 
                                     "{00FF00}" .. hideKeyName .. ". Скрыть | " .. targetKeyName .. ". " .. 
                                     (lockedTargetId and lockedTargetId == targetId and "Забыть" or "Запомнить") .. " цель"
                        activeText = sampCreate3dText(
                            text,
                            0xFFFFFFFF,
                            0, 1.4, -0.5,
                            9999.0,
                            false,
                            targetId,
                            -1
                        )
                        if lastTargetId ~= nil and targetId ~= lastTargetId and lastCommandIndex and not commandConfirmed then
                            beforeMessagesSent[lastCommandIndex] = false
                        end
                        lastTargetId = targetId
                        lastColor = color
                        lastColorPohit = colorPohit -- Сохраняем цвет кнопки 6
                        keyUpdated = false
                    end
                end
            end

            -- Обработка текста и действий после отпускания ПКМ
            if lastTargetId ~= nil then
                local result, target = sampGetCharHandleBySampPlayerId(lastTargetId)
                if result then
                    local targetX, targetY, targetZ = getCharCoordinates(target)
                    local myX, myY, myZ = getCharCoordinates(PLAYER_PED)
                    local distance = getDistanceBetweenCoords3d(myX, myY, myZ, targetX, targetY, targetZ)
                    
                    if distance > STREAM_DISTANCE or isCharDead(PLAYER_PED) or isCharDead(target) then
                        sampDestroy3dText(activeText)
                        activeText = nil
                        lastTargetId = nil
                        lastColor = nil
                        previousTargetId = nil
                        for i = 1, 6 do
                            beforeMessagesSent[i] = false
                        end
                        lastCommandIndex = nil
                        lastTargetIdForMessage = nil
                        commandConfirmed = false
                    else
                        local newColor = (distance > RADIUS) and "{FF0000}" or "{00FF00}"
                        local newColorPohit = (distance > RADIUSPOHIT) and "{FF0000}" or "{00FF00}"
                        
                        if not (sampIsChatInputActive() or sampIsDialogActive(-1)) then
                            if isKeyJustPressed(hideKey.v) and lastTargetId ~= nil then
                                if textVisible then
                                    sampDestroy3dText(activeText)
                                    activeText = nil
                                    textVisible = false
                                else
                                    local nickname = sampGetPlayerNickname(lastTargetId)
                                    local orgData = passportData[nickname] or "Неизвестно"
                                    local value = passportValues[orgData] or ""
                                    local formattedValue = value ~= "" and "{FFA500}$" .. formatNumber(value:sub(2)) or ""
                                    local hideKeyName = key.id_to_name(hideKey.v) or "?"
                                    local targetKeyName = key.id_to_name(targetKey.v) or "?"

                                    local passportInfo = ""
                                    if passportData[nickname] and passportData[nickname] ~= "Неизвестно" then
                                        passportInfo = "\n{FFFFFF}" .. passportData[nickname]
                                    end

                                    local text = "Цель: " .. nickname .. " " .. formattedValue .. 
                                                passportInfo .. "\n" .. 
                                                newColor .. "1. Нокаут\n" .. 
                                                newColor .. "2. Связать\n" .. 
                                                newColor .. "3. Кляп\n" .. 
                                                newColor .. "4. В авто/из авто\n" .. 
                                                newColor .. "5. Вести цель за собой\n" .. 
                                                newColorPohit .. "6. Начать похищение\n" .. 
                                                "{00FF00}" .. hideKeyName .. ". Скрыть | " .. targetKeyName .. ". " .. 
                                                (lockedTargetId and lockedTargetId == lastTargetId and "Забыть" or "Запомнить") .. " цель"
                                    activeText = sampCreate3dText(
                                        text,
                                        0xFFFFFFFF,
                                        0, 1.4, -0.5,
                                        9999.0,
                                        false,
                                        lastTargetId,
                                        -1
                                    )
                                    textVisible = true
                                    lastColor = newColor
                                    lastColorPohit = newColorPohit
                                end
                            end

                            if textVisible then
                                -- Обновление цвета текста или состояния запоминания
                                if lastColor ~= newColor or lastColorPohit ~= newColorPohit or passportUpdated or keyUpdated then
                                    if activeText ~= nil then
                                        sampDestroy3dText(activeText)
                                        activeText = nil
                                    end
                                    local result, target = sampGetCharHandleBySampPlayerId(lastTargetId)
                                    if result then
                                        local targetX, targetY, targetZ = getCharCoordinates(target)
                                        local myX, myY, myZ = getCharCoordinates(PLAYER_PED)
                                        distance = getDistanceBetweenCoords3d(myX, myY, myZ, targetX, targetY, targetZ)
                                    end
                                    local newColor = (distance > RADIUS) and "{FF0000}" or "{00FF00}"
                                    local newColorPohit = (distance > RADIUSPOHIT) and "{FF0000}" or "{00FF00}"
                                    
                                    local nickname = sampGetPlayerNickname(lastTargetId)
                                    local orgData = passportData[nickname] or "Неизвестно"
                                    local value = passportValues[orgData] or ""
                                    local formattedValue = value ~= "" and "{FFA500}$" .. formatNumber(value:sub(2)) or ""
                                    local hideKeyName = key.id_to_name(hideKey.v) or "?"
                                    local targetKeyName = key.id_to_name(targetKey.v) or "?"

                                    local passportInfo = ""
                                    if passportData[nickname] and passportData[nickname] ~= "Неизвестно" then
                                        passportInfo = "\n{FFFFFF}" .. passportData[nickname]
                                    end

                                    local text = "Цель: " .. nickname .. " " .. formattedValue .. 
                                                 passportInfo .. "\n" .. 
                                                 newColor .. "1. Нокаут\n" .. 
                                                 newColor .. "2. Связать\n" .. 
                                                 newColor .. "3. Кляп\n" .. 
                                                 newColor .. "4. В авто/из авто\n" .. 
                                                 newColor .. "5. Вести цель за собой\n" .. 
                                                 newColorPohit .. "6. Начать похищение\n" .. 
                                                 "{00FF00}" .. hideKeyName .. ". Скрыть | " .. targetKeyName .. ". " .. 
                                                 (lockedTargetId and lockedTargetId == lastTargetId and "Забыть" or "Запомнить") .. " цель"
                                    activeText = sampCreate3dText(
                                        text,
                                        0xFFFFFFFF,
                                        0, 1.4, -0.5,
                                        9999.0,
                                        false,
                                        lastTargetId,
                                        -1
                                    )
                                    lastColor = newColor
                                    lastColorPohit = newColorPohit -- Сохраняем цвет кнопки 6
                                    passportUpdated = false
                                    keyUpdated = false
                                end

                                -- Обработка клавиш действий
                                if isKeyJustPressed(0x31) and distance <= RADIUS then -- Нокаут
                                    if lastCommandIndex ~= 2 or lastTargetIdForMessage ~= lastTargetId or not commandConfirmed then
                                        lastCommandIndex = 2
                                        lastTargetIdForMessage = lastTargetId
                                        commandConfirmed = false
                                        if mode.v == 0 then
                                            if messageEnabled[2].v and not beforeMessagesSent[2] then
                                                for j, msg in ipairs(systemMessages[2].before) do
                                                    if msg ~= "" then
                                                        local targetName = sampGetPlayerNickname(lastTargetId)
                                                        local weaponDesc = getWeaponDescription(2, j, true)
                                                        local message = msg:gsub("$name", targetName):gsub("$gan", weaponDesc)
                                                        processMessageQueue(message)
                                                    end
                                                end
                                                beforeMessagesSent[2] = true
                                            end
                                            processMessageQueue("/knockout " .. lastTargetId)
                                        else
                                            if messageEnabled[2].v then
                                                for j, msg in ipairs(rpMessages[2]) do
                                                    if msg ~= "" then
                                                        local targetName = sampGetPlayerNickname(lastTargetId)
                                                        local weaponDesc = getWeaponDescription(2, j, true)
                                                        local message = msg:gsub("$name", targetName):gsub("$gan", weaponDesc)
                                                        processMessageQueue(message)
                                                    end
                                                end
                                            end
                                        end
                                    end
                                elseif isKeyJustPressed(0x32) and distance <= RADIUS then -- Связать
                                    if lastCommandIndex ~= 1 or lastTargetIdForMessage ~= lastTargetId or not commandConfirmed then
                                        lastCommandIndex = 1
                                        lastTargetIdForMessage = lastTargetId
                                        commandConfirmed = false
                                        if mode.v == 0 then
                                            if messageEnabled[1].v and not beforeMessagesSent[1] then
                                                for j, msg in ipairs(systemMessages[1].before) do
                                                    if msg ~= "" then
                                                        local targetName = sampGetPlayerNickname(lastTargetId)
                                                        local message = msg:gsub("$name", targetName)
                                                        processMessageQueue(message)
                                                    end
                                                end
                                                beforeMessagesSent[1] = true
                                            end
                                            processMessageQueue("/tie " .. lastTargetId)
                                        else
                                            if messageEnabled[1].v then
                                                for j, msg in ipairs(rpMessages[1]) do
                                                    if msg ~= "" then
                                                        local targetName = sampGetPlayerNickname(lastTargetId)
                                                        local weaponDesc = getWeaponDescription(1, j, true)
                                                        local message = msg:gsub("$name", targetName):gsub("$gan", weaponDesc)
                                                        processMessageQueue(message)
                                                    end
                                                end
                                            end
                                        end
                                    end
                                elseif isKeyJustPressed(0x33) and distance <= RADIUS then -- Кляп
                                    if lastCommandIndex ~= 3 or lastTargetIdForMessage ~= lastTargetId or not commandConfirmed then
                                        lastCommandIndex = 3
                                        lastTargetIdForMessage = lastTargetId
                                        commandConfirmed = false
                                        if mode.v == 0 then
                                            if messageEnabled[3].v and not beforeMessagesSent[3] then
                                                for j, msg in ipairs(systemMessages[3].before) do
                                                    if msg ~= "" then
                                                        local targetName = sampGetPlayerNickname(lastTargetId)
                                                        local message = msg:gsub("$name", targetName)
                                                        processMessageQueue(message)
                                                    end
                                                end
                                                beforeMessagesSent[3] = true
                                            end
                                            processMessageQueue("/gag " .. lastTargetId)
                                        else
                                            if messageEnabled[3].v then
                                                for j, msg in ipairs(rpMessages[3]) do
                                                    if msg ~= "" then
                                                        local targetName = sampGetPlayerNickname(lastTargetId)
                                                        local weaponDesc = getWeaponDescription(3, j, true)
                                                        local message = msg:gsub("$name", targetName):gsub("$gan", weaponDesc)
                                                        processMessageQueue(message)
                                                    end
                                                end
                                            end
                                        end
                                    end
                                elseif isKeyJustPressed(0x34) and distance <= RADIUS then -- В авто/из авто
                                    if lastCommandIndex ~= 4 and lastCommandIndex ~= 5 or lastTargetIdForMessage ~= lastTargetId or not commandConfirmed then
                                        local result, targetHandle = sampGetCharHandleBySampPlayerId(lastTargetId)
                                        if result then
                                            if isCharInAnyCar(targetHandle) then
                                                lastCommandIndex = 5
                                                lastTargetIdForMessage = lastTargetId
                                                commandConfirmed = false
                                                if mode.v == 0 then
                                                    if messageEnabled[5].v and not beforeMessagesSent[5] then
                                                        for j, msg in ipairs(systemMessages[5].before) do
                                                            if msg ~= "" then
                                                                local targetName = sampGetPlayerNickname(lastTargetId)
                                                                local carDesc = getCarDescription(5, j, targetHandle, true)
                                                                local message = msg:gsub("$name", targetName):gsub("$car", carDesc)
                                                                processMessageQueue(message)
                                                            end
                                                        end
                                                        beforeMessagesSent[5] = true
                                                    end
                                                    processMessageQueue("/keject " .. lastTargetId)
                                                else
                                                    if messageEnabled[5].v then
                                                        for j, msg in ipairs(rpMessages[5]) do
                                                            if msg ~= "" then
                                                                local targetName = sampGetPlayerNickname(lastTargetId)
                                                                local carDesc = getCarDescription(5, j, targetHandle, true)
                                                                local message = msg:gsub("$name", targetName):gsub("$car", carDesc)
                                                                processMessageQueue(message)
                                                            end
                                                        end
                                                    end
                                                end
                                            else
                                                lastCommandIndex = 4
                                                lastTargetIdForMessage = lastTargetId
                                                commandConfirmed = false
                                                if mode.v == 0 then
                                                    if messageEnabled[4].v and not beforeMessagesSent[4] then
                                                        for j, msg in ipairs(systemMessages[4].before) do
                                                            if msg ~= "" then
                                                                local targetName = sampGetPlayerNickname(lastTargetId)
                                                                local carDesc = getCarDescription(4, j, targetHandle, true)
                                                                local message = msg:gsub("$name", targetName):gsub("$car", carDesc)
                                                                processMessageQueue(message)
                                                            end
                                                        end
                                                        beforeMessagesSent[4] = true
                                                    end
                                                    processMessageQueue("/kput " .. lastTargetId)
                                                else
                                                    if messageEnabled[4].v then
                                                        for j, msg in ipairs(rpMessages[4]) do
                                                            if msg ~= "" then
                                                                local targetName = sampGetPlayerNickname(lastTargetId)
                                                                local carDesc = getCarDescription(4, j, targetHandle, true)
                                                                local message = msg:gsub("$name", targetName):gsub("$car", carDesc)
                                                                processMessageQueue(message)
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                elseif isKeyJustPressed(0x35) and distance <= RADIUS then -- Вести за собой
                                    if lastCommandIndex ~= 6 or lastTargetIdForMessage ~= lastTargetId or not commandConfirmed then
                                        lastCommandIndex = 6
                                        lastTargetIdForMessage = lastTargetId
                                        commandConfirmed = false
                                        if mode.v == 0 then
                                            if messageEnabled[6].v and not beforeMessagesSent[6] then
                                                for j, msg in ipairs(systemMessages[6].before) do
                                                    if msg ~= "" then
                                                        local targetName = sampGetPlayerNickname(lastTargetId)
                                                        local message = msg:gsub("$name", targetName)
                                                        processMessageQueue(message)
                                                    end
                                                end
                                                beforeMessagesSent[6] = true
                                            end
                                            processMessageQueue("/kfollow " .. lastTargetId)
                                        else
                                            if messageEnabled[6].v then
                                                for j, msg in ipairs(rpMessages[6]) do
                                                    if msg ~= "" then
                                                        local targetName = sampGetPlayerNickname(lastTargetId)
                                                        local weaponDesc = getWeaponDescription(6, j, true)
                                                        local message = msg:gsub("$name", targetName):gsub("$gan", weaponDesc)
                                                        processMessageQueue(message)
                                                    end
                                                end
                                            end
                                        end
                                    end
                                elseif isKeyJustPressed(0x36) and distance <= RADIUSPOHIT then -- Начать похищение (клавиша 6)
                                    log("[Kidnapping] Нажата клавиша 6 для начала похищения, текущий флаг kidnappingStarted: " .. tostring(kidnappingStarted))
                                    kidnappingStarted = true
                                    kidnappingDialogInitiated = true -- Устанавливаем флаг для обработки диалога похищения
                                    processMessageQueue("/kmenu")
                                    log("[Kidnapping] Флаг kidnappingStarted установлен в true для цели ID: " .. lastTargetId)
                                    log("[Kidnapping] Отправлена команда /kmenu в чат после начала похищения, kidnappingDialogInitiated установлен в true")
                                end
                            end

                            -- Подтверждение команд в системном режиме
                            if mode.v == 0 and lastTargetIdForMessage and lastCommandIndex and commandConfirmed then
                                local result, targetHandle = sampGetCharHandleBySampPlayerId(lastTargetIdForMessage)
                                if result and distance <= RADIUS then
                                    if messageEnabled[lastCommandIndex].v then
                                        for j, msg in ipairs(systemMessages[lastCommandIndex].after) do
                                            if msg ~= "" then
                                                local targetName = sampGetPlayerNickname(lastTargetIdForMessage)
                                                local message = msg:gsub("$name", targetName)
                                                if lastCommandIndex == 2 then
                                                    message = message:gsub("$gan", getWeaponDescription(lastCommandIndex, j, false))
                                                elseif lastCommandIndex == 4 or lastCommandIndex == 5 then
                                                    local carDesc = getCarDescription(lastCommandIndex, j, targetHandle, false)
                                                    message = message:gsub("$car", carDesc)
                                                end
                                                processMessageQueue(message)
                                            end
                                        end
                                    end
                                    commandConfirmed = false
                                end
                            end
                        end
                    end
                else
                    sampDestroy3dText(activeText)
                    activeText = nil
                    lastTargetId = nil
                    lastColor = nil
                    previousTargetId = nil
                    for i = 1, 6 do
                        beforeMessagesSent[i] = false
                    end
                    lastCommandIndex = nil
                    lastTargetIdForMessage = nil
                    commandConfirmed = false
                    log("Цель " .. tostring(lastTargetId) .. " недоступна, текст удален")
                end
            end
        end
        
        -- Обработка паспортных данных
        if awaitingPassport then
            local result, dialogId = sampGetCurrentDialogId()
            if result and dialogId == 0 then
                local text = sampGetDialogText()
                if text then
                    local org = text:match("Организация: ([^\n]+)")
                    local money = text:match("Деньги: (%d+)")
                    if org and money then
                        passportData[currentPassportName] = {org = org, money = money}
                        local file = io.open(passport_file, "a")
                        if file then
                            file:write(org .. "=" .. money .. "\n")
                            file:close()
                            log("Паспорт сохранён: " .. org .. " = " .. money)
                        end
                        passportValues[org] = "$" .. formatNumber(tonumber(money))
                        awaitingPassport = false
                        currentPassportName = nil
                        passportUpdated = true
                    end
                end
            end
        end
    end
end

function processTeamTextDraw()
    if not isSampfuncsLoaded() then
        log("SAMPFUNCS не загружен, обработка текстдравов невозможна")
        return {}
    end
    
    local teamTextDrawId = nil
    for id = 0, 4095 do
        if sampTextdrawIsExists(id) then
            local text = sampTextdrawGetString(id)
            if text and text:match("~b~~h~TEAM:~w~~n~") then
                teamTextDrawId = id
                break
            end
        end
    end
    
    local newMembers = {}
    
    if teamTextDrawId then
        local textDrawText = sampTextdrawGetString(teamTextDrawId)
        log("Полный текст текстдрава (ID " .. teamTextDrawId .. "): " .. textDrawText)
        
        local teamSection = textDrawText:match("~b~~h~TEAM:~w~~n~(.+)")
        if teamSection then
            log("Секция с никами: " .. teamSection)
            local names = {}
            local startPos = 1
            while true do
                local nextPos = teamSection:find("~n~", startPos)
                if nextPos then
                    local name = teamSection:sub(startPos, nextPos - 1)
                    local cleanName = name:gsub("~[wbgrh]~", ""):gsub("^%s+", ""):gsub("%s+$", "")
                    if cleanName ~= "" then
                        table.insert(names, cleanName)
                    end
                    startPos = nextPos + 3
                else
                    local name = teamSection:sub(startPos)
                    local cleanName = name:gsub("~[wbgrh]~", ""):gsub("^%s+", ""):gsub("%s+$", "")
                    if cleanName ~= "" then
                        table.insert(names, cleanName)
                    end
                    break
                end
            end
            
            for i, name in ipairs(names) do
                log("Извлеченный ник " .. i .. ": " .. name)
                table.insert(newMembers, name)
            end
        else
            log("Не удалось извлечь секцию с никами из: " .. textDrawText)
        end
        
        sampTextdrawSetString(teamTextDrawId, "")
    else
    end
    
    return newMembers
end

function updateTeamMemberData()
    local _, localPlayerId = sampGetPlayerIdByCharHandle(PLAYER_PED)
    local localPlayerName = sampGetPlayerNickname(localPlayerId)
	
    -- Получаем цвет локального игрока
    local rawColor = sampGetPlayerColor(localPlayerId) or 0xFFFFFFFF
    -- Проверяем, есть ли локальный игрок в teamMembers
    local localPlayerFound = false
    for i, member in ipairs(teamMembers) do
        if member.name == localPlayerName then
            localPlayerFound = true
            -- Обновляем данные локального игрока
            teamMembers[i].hp = math.floor(getCharHealth(PLAYER_PED))
            teamMembers[i].armor = math.floor(getCharArmour(PLAYER_PED))
            teamMembers[i].color = rawColor
            break
        end
    end

    -- Если локальный игрок не найден, добавляем его
    if not localPlayerFound then
        local hp = math.floor(getCharHealth(PLAYER_PED))
        local armor = math.floor(getCharArmour(PLAYER_PED))
        local color = rawColor
        table.insert(teamMembers, {
            name = localPlayerName,
            hp = hp,
            armor = armor,
            color = color
        })
        log("Локальный игрок " .. localPlayerName .. " добавлен в teamMembers: HP=" .. hp .. ", Armor=" .. armor .. ", Color=" .. string.format("0x%08X", color))
    end

    -- Обновляем данные для других игроков
    for i, member in ipairs(teamMembers) do
        if member.name ~= localPlayerName then
            local playerId = nil
            for id = 0, 1000 do
                if sampIsPlayerConnected(id) and sampGetPlayerNickname(id) == member.name then
                    playerId = id
                    break
                end
            end
            if playerId then
                local hp = sampGetPlayerHealth(playerId)
                local armor = sampGetPlayerArmor(playerId)
                local color = sampGetPlayerColor(playerId) or 0xFFFFFFFF
                teamMembers[i].hp = hp and math.floor(hp) or 100
                teamMembers[i].armor = armor and math.floor(armor) or 0
                teamMembers[i].color = color
                log("Данные SA-MP для " .. member.name .. " (ID " .. playerId .. "): HP=" .. teamMembers[i].hp .. ", Armor=" .. teamMembers[i].armor .. ", Color=" .. string.format("0x%08X", teamMembers[i].color))
            else
                teamMembers[i].hp = 100
                teamMembers[i].armor = 0
                teamMembers[i].color = 0xFFFFFFFF
                log("Игрок " .. member.name .. " не найден среди подключённых, установлены значения по умолчанию")
            end
        end
    end
end

function imgui.BeforeDrawFrame()
    if fa_font == nil then
        local font_config = imgui.ImFontConfig()
        font_config.MergeMode = true
        fa_font = imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader/resource/fonts/fa-solid-900.ttf', 13.0, font_config, fa_glyph_ranges)
    end
end

function imgui.OnDrawFrame()
    local screenX, screenY = getScreenResolution()
    
    if showWindow.v then
        -- Включаем курсор при открытии основного окна
        imgui.ShowCursor = true
        imgui.SetNextWindowSize(imgui.ImVec2(400, 500), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowPos(imgui.ImVec2(screenX / 2, screenY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.Begin(fa.ICON_FA_COG .. " " .. u8"Меню похищений", showWindow)
        
        -- Кнопка "Начать похищение"
        if imgui.Button(fa.ICON_FA_PLAY .. " " .. u8"Начать похищение") then
            kidnappingActive = not kidnappingActive
            log("Похищение " .. (kidnappingActive and "активировано" or "деактивировано"))
            if kidnappingActive then
                InvertoryDialog = true
                processMessageQueue("/inventory")
                log("Отправлен запрос /inventory для проверки предметов при активации похищения")
                -- Инициализируем teamMembers и скрываем текстдрав
                local newMembers = processTeamTextDraw()
                teamMembers = {}
                for _, name in ipairs(newMembers) do
                    table.insert(teamMembers, {name = name, hp = 100, armor = 0, color = 0xFFFFFFFF})
                end
                updateTeamMemberData() -- Первоначальное обновление данных
            else
                teamMembers = {} -- Очищаем список при деактивации
            end
        end
        
        -- Кнопка "Пригласить в команду"
        if imgui.Button(fa.ICON_FA_USERS .. " " .. u8"Пригласить в команду") then
            inviteNearbyPlayers() -- Вызываем функцию напрямую
        end
        
        imgui.Separator()
        
        imgui.Text(fa.ICON_FA_COGS .. " " .. u8"Режим работы:")
        imgui.Combo(u8"##Mode", mode, modeNames, 2)
        imgui.Separator()
        
        if mode.v == 0 then
            imgui.Text(fa.ICON_FA_COMMENT .. " " .. u8"Настройка сообщений (с командами):")
            imgui.Text(u8"Поддерживается $name - ник цели, $car - транспорт, $gan - оружие")
            local commandNames = {
                u8"/tie - Связать",
                u8"/knockout - Оглушить",
                u8"/gag - Кляп",
                u8"/kput - В авто",
                u8"/keject - Из авто",
                u8"/kfollow - Следовать"
            }
            
            if imgui.CollapsingHeader(fa.ICON_FA_COG .. " " .. u8"Настройки команд") then
                local toRemoveBefore, toRemoveAfter = {}, {}
                for i = 1, 6 do
                    local headerOpen = imgui.CollapsingHeader(fa.ICON_FA_COG .. " " .. commandNames[i])
                    imgui.SameLine()
                    
                    imgui.Checkbox(u8"Включить##EnableMsg" .. i, messageEnabled[i])
                    local checkboxPos = imgui.GetItemRectMin()
                    local checkboxSize = imgui.GetItemRectSize()
                    imgui.SetCursorScreenPos(checkboxPos)
                    if imgui.InvisibleButton("##CheckboxButton" .. i, checkboxSize) then
                        -- ЛКМ ничего не делает, так как CollapsingHeader уже обрабатывает открытие/закрытие
                    end
                    if imgui.IsItemClicked(1) then -- ПКМ
                        messageEnabled[i].v = not messageEnabled[i].v
                        log("Состояние сообщений для " .. commandNames[i] .. " изменено на: " .. tostring(messageEnabled[i].v))
                    end
                    
                    if headerOpen then
                        imgui.BeginGroup()
                        
                        -- Сообщения "До команды"
                        imgui.Text(fa.ICON_FA_ARROW_RIGHT .. " " .. u8"До команды:")
                        if #systemMessages[i].before > 0 then
                            for j, buffer in ipairs(systemMessageBuffers[i].before) do
                                imgui.BeginGroup()
                                if imgui.InputText(u8"##Before" .. i .. j, buffer, imgui.InputTextFlags.None, nil, nil, 300) then
                                    systemMessages[i].before[j] = buffer.v
                                end
                                imgui.SameLine()
                                if imgui.Button(fa.ICON_FA_TRASH .. u8"##BeforeDel" .. i .. j) then
                                    toRemoveBefore[#toRemoveBefore + 1] = {i = i, j = j}
                                end
                                imgui.SameLine()
                                if imgui.Button(fa.ICON_FA_PLUS .. u8"##BeforeAddInline" .. i .. j) then
                                    table.insert(systemMessages[i].before, j + 1, u8"")
                                    table.insert(systemMessageBuffers[i].before, j + 1, imgui.ImBuffer(u8"", 256))
                                    table.insert(endings[i].system.before, j + 1, {car = {u8"машину", u8"вертолёт", u8"лодку", u8"самолёт"}, gan = weaponMappings})
                                    table.insert(endingBuffers[i].system.before, j + 1, {car = {}, gan = {}})
                                    for k, ending in ipairs(endings[i].system.before[j + 1].car) do
                                        endingBuffers[i].system.before[j + 1].car[k] = imgui.ImBuffer(ending, 256)
                                    end
                                    for id, ending in pairs(endings[i].system.before[j + 1].gan) do
                                        endingBuffers[i].system.before[j + 1].gan[id] = imgui.ImBuffer(ending, 256)
                                    end
                                end
                                imgui.SameLine()
                                if imgui.Button(fa.ICON_FA_COG .. u8"##BeforeSettings" .. i .. j) then
                                    imgui.OpenPopup(u8"BeforeSettings" .. i .. j)
                                end
                                if imgui.BeginPopup(u8"BeforeSettings" .. i .. j) then
                                    if systemMessages[i].before[j]:find("$car") then
                                        imgui.Text(fa.ICON_FA_CAR .. " " .. u8"Окончания для $car:")
                                        for k, ending in ipairs(endings[i].system.before[j].car) do
                                            if imgui.InputText(u8"##CarBefore" .. i .. j .. k, endingBuffers[i].system.before[j].car[k]) then
                                                endings[i].system.before[j].car[k] = endingBuffers[i].system.before[j].car[k].v
                                            end
                                            imgui.SameLine()
                                            imgui.Text(carTypeNames[k])
                                        end
                                    end
                                    if systemMessages[i].before[j]:find("$gan") then
                                        imgui.Text(fa.ICON_FA_SKULL .. " " .. u8"Окончания для $gan:")
                                        for id, ending in pairs(endings[i].system.before[j].gan) do
                                            if imgui.InputText(u8"##GanBefore" .. i .. j .. id, endingBuffers[i].system.before[j].gan[id]) then
                                                endings[i].system.before[j].gan[id] = endingBuffers[i].system.before[j].gan[id].v
                                            end
                                            imgui.SameLine()
                                            imgui.Text(ganTypeNames[id] or u8"Неизвестно")
                                        end
                                    end
                                    imgui.EndPopup()
                                end
                                imgui.EndGroup()
                            end
                        else
                            if imgui.Button(fa.ICON_FA_PLUS .. u8" Добавить строку##BeforeAdd" .. i) then
                                table.insert(systemMessages[i].before, u8"")
                                table.insert(systemMessageBuffers[i].before, imgui.ImBuffer(u8"", 256))
                                table.insert(endings[i].system.before, {car = {u8"машину", u8"вертолёт", u8"лодку", u8"самолёт"}, gan = weaponMappings})
                                table.insert(endingBuffers[i].system.before, {car = {}, gan = {}})
                                local newIndex = #systemMessages[i].before
                                for k, ending in ipairs(endings[i].system.before[newIndex].car) do
                                    endingBuffers[i].system.before[newIndex].car[k] = imgui.ImBuffer(ending, 256)
                                end
                                for id, ending in pairs(endings[i].system.before[newIndex].gan) do
                                    endingBuffers[i].system.before[newIndex].gan[id] = imgui.ImBuffer(ending, 256)
                                end
                            end
                        end
                        
                        imgui.Separator()
                        
                        -- Сообщения "После команды"
                        imgui.Text(fa.ICON_FA_ARROW_LEFT .. " " .. u8"После команды:")
                        if #systemMessages[i].after > 0 then
                            for j, buffer in ipairs(systemMessageBuffers[i].after) do
                                imgui.BeginGroup()
                                if imgui.InputText(u8"##After" .. i .. j, buffer, imgui.InputTextFlags.None, nil, nil, 300) then
                                    systemMessages[i].after[j] = buffer.v
                                end
                                imgui.SameLine()
                                if imgui.Button(fa.ICON_FA_TRASH .. u8"##AfterDel" .. i .. j) then
                                    toRemoveAfter[#toRemoveAfter + 1] = {i = i, j = j}
                                end
                                imgui.SameLine()
                                if imgui.Button(fa.ICON_FA_PLUS .. u8"##AfterAddInline" .. i .. j) then
                                    table.insert(systemMessages[i].after, j + 1, u8"")
                                    table.insert(systemMessageBuffers[i].after, j + 1, imgui.ImBuffer(u8"", 256))
                                    table.insert(endings[i].system.after, j + 1, {car = {u8"машину", u8"вертолёт", u8"лодку", u8"самолёт"}, gan = weaponMappings})
                                    table.insert(endingBuffers[i].system.after, j + 1, {car = {}, gan = {}})
                                    for k, ending in ipairs(endings[i].system.after[j + 1].car) do
                                        endingBuffers[i].system.after[j + 1].car[k] = imgui.ImBuffer(ending, 256)
                                    end
                                    for id, ending in pairs(endings[i].system.after[j + 1].gan) do
                                        endingBuffers[i].system.after[j + 1].gan[id] = imgui.ImBuffer(ending, 256)
                                    end
                                end
                                imgui.SameLine()
                                if imgui.Button(fa.ICON_FA_COG .. u8"##AfterSettings" .. i .. j) then
                                    imgui.OpenPopup(u8"AfterSettings" .. i .. j)
                                end
                                if imgui.BeginPopup(u8"AfterSettings" .. i .. j) then
                                    if systemMessages[i].after[j]:find("$car") then
                                        imgui.Text(fa.ICON_FA_CAR .. " " .. u8"Окончания для $car:")
                                        for k, ending in ipairs(endings[i].system.after[j].car) do
                                            if imgui.InputText(u8"##CarAfter" .. i .. j .. k, endingBuffers[i].system.after[j].car[k]) then
                                                endings[i].system.after[j].car[k] = endingBuffers[i].system.after[j].car[k].v
                                            end
                                            imgui.SameLine()
                                            imgui.Text(carTypeNames[k])
                                        end
                                    end
                                    if systemMessages[i].after[j]:find("$gan") then
                                        imgui.Text(fa.ICON_FA_SKULL .. " " .. u8"Окончания для $gan:")
                                        for id, ending in pairs(endings[i].system.after[j].gan) do
                                            if imgui.InputText(u8"##GanAfter" .. i .. j .. id, endingBuffers[i].system.after[j].gan[id]) then
                                                endings[i].system.after[j].gan[id] = endingBuffers[i].system.after[j].gan[id].v
                                            end
                                            imgui.SameLine()
                                            imgui.Text(ganTypeNames[id] or u8"Неизвестно")
                                        end
                                    end
                                    imgui.EndPopup()
                                end
                                imgui.EndGroup()
                            end
                        else
                            if imgui.Button(fa.ICON_FA_PLUS .. u8" Добавить строку##AfterAdd" .. i) then
                                table.insert(systemMessages[i].after, u8"")
                                table.insert(systemMessageBuffers[i].after, imgui.ImBuffer(u8"", 256))
                                table.insert(endings[i].system.after, {car = {u8"машину", u8"вертолёт", u8"лодку", u8"самолёт"}, gan = weaponMappings})
                                table.insert(endingBuffers[i].system.after, {car = {}, gan = {}})
                                local newIndex = #systemMessages[i].after
                                for k, ending in ipairs(endings[i].system.after[newIndex].car) do
                                    endingBuffers[i].system.after[newIndex].car[k] = imgui.ImBuffer(ending, 256)
                                end
                                for id, ending in pairs(endings[i].system.after[newIndex].gan) do
                                    endingBuffers[i].system.after[newIndex].gan[id] = imgui.ImBuffer(ending, 256)
                                end
                            end
                        end
                        
                        imgui.Separator()
                        imgui.EndGroup()
                    end
                end
                for _, remove in ipairs(toRemoveBefore) do
                    table.remove(systemMessages[remove.i].before, remove.j)
                    table.remove(systemMessageBuffers[remove.i].before, remove.j)
                    table.remove(endings[remove.i].system.before, remove.j)
                    table.remove(endingBuffers[remove.i].system.before, remove.j)
                end
                for _, remove in ipairs(toRemoveAfter) do
                    table.remove(systemMessages[remove.i].after, remove.j)
                    table.remove(systemMessageBuffers[remove.i].after, remove.j)
                    table.remove(endings[remove.i].system.after, remove.j)
                    table.remove(endingBuffers[remove.i].system.after, remove.j)
                end
            end
        else
            imgui.Text(fa.ICON_FA_COMMENT .. " " .. u8"Настройка сообщений (без команд):")
            imgui.Text(u8"Поддерживается $name - ник цели, $car - транспорт, $gan - оружие")
            local commandNames = {u8"Связать", u8"Нокаут", u8"Кляп", u8"В авто", u8"Из авто", u8"Вести за собой"}
            if imgui.CollapsingHeader(fa.ICON_FA_COG .. " " .. u8"Настройки сообщений") then
                local toRemoveRP = {}
                for i = 1, 6 do
                    imgui.BeginGroup()
                    imgui.Checkbox(u8"##EnableMsgRP" .. i, messageEnabled[i])
                    imgui.SameLine()
                    imgui.Text(commandNames[i])
                    
                    for j, buffer in ipairs(rpMessageBuffers[i]) do
                        imgui.BeginGroup()
                        if imgui.InputText(u8"##MsgRP" .. i .. j, buffer, imgui.InputTextFlags.None, nil, nil, 300) then
                            rpMessages[i][j] = buffer.v
                        end
                        imgui.SameLine()
                        if imgui.Button(fa.ICON_FA_MINUS .. u8"##RPDel" .. i .. j) and #rpMessages[i] > 1 then
                            toRemoveRP[#toRemoveRP + 1] = {i = i, j = j}
                        end
                        imgui.SameLine()
                        if imgui.Button(fa.ICON_FA_PLUS .. u8"##RPAddInline" .. i .. j) then
                            table.insert(rpMessages[i], j + 1, u8"")
                            table.insert(rpMessageBuffers[i], j + 1, imgui.ImBuffer(u8"", 256))
                            table.insert(endings[i].rp, j + 1, {car = {u8"машину", u8"вертолёт", u8"лодку", u8"самолёт"}, gan = weaponMappings})
                            table.insert(endingBuffers[i].rp, j + 1, {car = {}, gan = {}})
                            for k, ending in ipairs(endings[i].rp[j + 1].car) do
                                endingBuffers[i].rp[j + 1].car[k] = imgui.ImBuffer(ending, 256)
                            end
                            for id, ending in pairs(endings[i].rp[j + 1].gan) do
                                endingBuffers[i].rp[j + 1].gan[id] = imgui.ImBuffer(ending, 256)
                            end
                        end
                        imgui.SameLine()
                        if imgui.Button(fa.ICON_FA_COG .. u8"##RPSettings" .. i .. j) then
                            imgui.OpenPopup(u8"RPSettings" .. i .. j)
                        end
                        if imgui.BeginPopup(u8"RPSettings" .. i .. j) then
                            if rpMessages[i][j]:find("$car") then
                                imgui.Text(fa.ICON_FA_CAR .. " " .. u8"Окончания для $car:")
                                for k, ending in ipairs(endings[i].rp[j].car) do
                                    if imgui.InputText(u8"##CarRP" .. i .. j .. k, endingBuffers[i].rp[j].car[k]) then
                                        endings[i].rp[j].car[k] = endingBuffers[i].rp[j].car[k].v
                                    end
                                    imgui.SameLine()
                                    imgui.Text(carTypeNames[k])
                                end
                            end
                            if rpMessages[i][j]:find("$gan") then
                                imgui.Text(fa.ICON_FA_SKULL .. " " .. u8"Окончания для $gan:")
                                for id, ending in pairs(endings[i].rp[j].gan) do
                                    if imgui.InputText(u8"##GanRP" .. i .. j .. id, endingBuffers[i].rp[j].gan[id]) then
                                        endings[i].rp[j].gan[id] = endingBuffers[i].rp[j].gan[id].v
                                    end
                                    imgui.SameLine()
                                    imgui.Text(ganTypeNames[id] or u8"Неизвестно")
                                end
                            end
                            imgui.EndPopup()
                        end
                        imgui.EndGroup()
                    end
                    
                    imgui.Separator()
                    imgui.EndGroup()
                end
                for _, remove in ipairs(toRemoveRP) do
                    table.remove(rpMessages[remove.i], remove.j)
                    table.remove(rpMessageBuffers[remove.i], remove.j)
                    table.remove(endings[remove.i].rp, remove.j)
                    table.remove(endingBuffers[remove.i].rp, remove.j)
                end
            end
        end
        
        imgui.Separator()
        imgui.Text(fa.ICON_FA_KEYBOARD .. " " .. u8"Клавиши управления:")
        
        -- Клавиша скрытия текста
        local hideKeyName = key.id_to_name(hideKey.v) or "Неизвестно"
        if imgui.Button(fa.ICON_FA_EDIT .. " " .. u8"Скрыть текст: " .. hideKeyName) then
            keySelecting.v = true
        end

        -- Клавиша показа окна
        local showKeyName = key.id_to_name(showKey.v) or "Неизвестно"
        imgui.Checkbox(u8"Включить клавишу показа##ShowKeyEnable", showKeyEnabled)
        imgui.SameLine()
        if imgui.Button(fa.ICON_FA_EDIT .. " " .. u8"Показать меню: " .. showKeyName) then
            showKeySelecting.v = true
        end

        -- Клавиша запоминания цели
        local targetKeyName = key.id_to_name(targetKey.v) or "Неизвестно"
        if imgui.Button(fa.ICON_FA_EDIT .. " " .. u8"Запомнить цель: " .. targetKeyName) then
            targetKeySelecting.v = true
        end

        -- Обработка выбора клавиш
        if keySelecting.v then
            imgui.Text(fa.ICON_FA_KEY .. " " .. u8"Нажмите клавишу для скрытия текста...")
            for i = 0, 255 do
                if isKeyJustPressed(i) then
                    hideKey.v = i
                    keySelecting.v = false
                    keyUpdated = true
                    log("Выбрана новая клавиша скрытия текста: " .. key.id_to_name(hideKey.v))
                    break
                end
            end
        elseif showKeySelecting.v then
            imgui.Text(fa.ICON_FA_KEY .. " " .. u8"Нажмите клавишу для показа меню...")
            for i = 0, 255 do
                if isKeyJustPressed(i) then
                    showKey.v = i
                    showKeySelecting.v = false
                    keyUpdated = true
                    log("Выбрана новая клавиша показа меню: " .. key.id_to_name(showKey.v))
                    break
                end
            end
        elseif targetKeySelecting.v then
            imgui.Text(fa.ICON_FA_KEY .. " " .. u8"Нажмите клавишу для запоминания цели...")
            for i = 0, 255 do
                if isKeyJustPressed(i) then
                    targetKey.v = i
                    targetKeySelecting.v = false
                    keyUpdated = true
                    log("Выбрана новая клавиша запоминания цели: " .. key.id_to_name(targetKey.v))
                    break
                end
            end
        end

        -- Поле ввода ID цели
        imgui.Separator()
        imgui.Text(fa.ICON_FA_USER .. " " .. u8"ID похищаемой цели:")
        imgui.InputText(u8"##TargetID", targetInputBuffer, imgui.InputTextFlags.CharsDecimal)
        imgui.SameLine()
        if imgui.Button(fa.ICON_FA_CHECK .. " " .. u8"OK") then
            local id = tonumber(targetInputBuffer.v)
            if id and sampIsPlayerConnected(id) then
                lockedTargetId = id
                kidnappingActive = true
            else
                lockedTargetId = nil
                targetInputBuffer.v = ""
            end
        end
        
        imgui.Separator()
        imgui.Text(fa.ICON_FA_CLOCK .. " " .. u8"Настройка таймеров:")
        if imgui.CollapsingHeader(fa.ICON_FA_COG .. " " .. u8"Таймеры") then
            local toRemoveTimer = nil
            if not timerWindows then
                timerWindows = {}
                for i = 1, #timers do
                    timerWindows[i] = imgui.ImBool(timers[i].enabledBuffer.v)
                end
            end
            for i, timer in ipairs(timers) do
                imgui.BeginGroup()
                imgui.Text(fa.ICON_FA_CLOCK .. " " .. u8"Таймер " .. i)
                
                if imgui.InputText(u8"Подпись##TimerLabel" .. i, timer.labelBuffer) then
                    timer.label = u8:decode(timer.labelBuffer.v)
                end
                
                imgui.Text(fa.ICON_FA_HOURGLASS .. " " .. u8"Длительность (ЧЧ:ММ:СС):")
                imgui.PushItemWidth(40)
                
                if imgui.InputText(u8"##Hours" .. i, timer.hoursBuffer, imgui.InputTextFlags.CharsDecimal) then
                    timer.hours = formatTimeComponent(timer.hoursBuffer.v, 99)
                    timer.hoursBuffer.v = u8(timer.hours)
                    timer.durationStr = timer.hours .. ":" .. timer.minutes .. ":" .. timer.seconds
                end
                imgui.SameLine()
                imgui.Text(u8":")
                imgui.SameLine()
                
                if imgui.InputText(u8"##Minutes" .. i, timer.minutesBuffer, imgui.InputTextFlags.CharsDecimal) then
                    timer.minutes = formatTimeComponent(timer.minutesBuffer.v, 59)
                    timer.minutesBuffer.v = u8(timer.minutes)
                    timer.durationStr = timer.hours .. ":" .. timer.minutes .. ":" .. timer.seconds
                end
                imgui.SameLine()
                imgui.Text(u8":")
                imgui.SameLine()
                
                if imgui.InputText(u8"##Seconds" .. i, timer.secondsBuffer, imgui.InputTextFlags.CharsDecimal) then
                    timer.seconds = formatTimeComponent(timer.secondsBuffer.v, 59)
                    timer.secondsBuffer.v = u8(timer.seconds)
                    timer.durationStr = timer.hours .. ":" .. timer.minutes .. ":" .. timer.seconds
                end
                
                imgui.PopItemWidth()
                
                local wasEnabled = timer.enabledBuffer.v
                if imgui.Checkbox(u8"Вкл##TimerEnabled" .. i, timer.enabledBuffer) then
                    timer.enabled = timer.enabledBuffer.v
                    if timer.enabledBuffer.v and not wasEnabled then
                        timerWindows[i].v = true
                    end
                end
                
                imgui.SameLine()
                if imgui.Button((timer.paused and fa.ICON_FA_PLAY or fa.ICON_FA_PLAY) .. u8"##TimerStart" .. i) then
                    if timer.enabled then
                        if timer.paused then
                            timer.startTime = os.clock()
                            timer.paused = false
                            log("Таймер '" .. timer.label .. "' возобновлен")
                        elseif not timer.startTime then
                            if timerMessageEnabled[i].before.v then
                                for _, msg in ipairs(timerEventMessages[i].before) do
                                    local labelInCP1251 = u8:decode(timer.label)
                                    local message = msg:gsub("$time", timer.durationStr):gsub("$label", labelInCP1251)
                                    processMessageQueue(message)
                                end
                            end
                            timer.startTime = os.clock()
                            timer.elapsed = 0
                            timer.paused = false
                            timer.lastDuringMessageTime = nil
                            log("Таймер '" .. timer.label .. "' запущен")
                        end
                    end
                end
                
                imgui.SameLine()
                if imgui.Button(fa.ICON_FA_PAUSE .. u8"##TimerPause" .. i) and timer.enabled and timer.startTime and not timer.paused then
                    timer.elapsed = (timer.elapsed or 0) + (os.clock() - timer.startTime)
                    timer.startTime = nil
                    timer.paused = true
                    log("Таймер '" .. timer.label .. "' на паузе")
                end
                
                imgui.SameLine()
                if imgui.Button(fa.ICON_FA_STOP .. u8"##TimerReset" .. i) then
                    timer.startTime = nil
                    timer.paused = false
                    timer.elapsed = 0
                    timer.lastDuringMessageTime = nil
                    log("Таймер '" .. timer.label .. "' сброшен")
                end
                
                imgui.SameLine()
                if imgui.Button(fa.ICON_FA_TRASH .. u8"##TimerDelete" .. i) then
                    toRemoveTimer = i
                end
                
                local timeText = timer.hours .. ":" .. timer.minutes .. ":" .. timer.seconds
                if timer.enabled then
                    if timer.startTime and not timer.paused then
                        local elapsed = (timer.elapsed or 0) + (os.clock() - timer.startTime)
                        local remaining = parseTimeString(timer) - elapsed
                        timeText = formatTime(math.max(0, remaining))
                    elseif timer.paused then
                        local remaining = parseTimeString(timer) - (timer.elapsed or 0)
                        timeText = formatTime(math.max(0, remaining)) .. " " .. u8"(пауза)"
                    end
                end
                imgui.Text(fa.ICON_FA_HOURGLASS .. " " .. u8"Осталось: " .. timeText)
                
                imgui.Separator()
                imgui.Text(fa.ICON_FA_BELL .. " " .. u8"События таймера " .. i .. ":")
                imgui.Text(u8"Поддерживает $time (время)")
                
                imgui.Checkbox(u8"До##TimerBeforeEnable" .. i, timerMessageEnabled[i].before)
                imgui.SameLine()
                imgui.Text(fa.ICON_FA_ARROW_RIGHT .. " " .. u8"Сообщения до запуска:")
                local toRemoveBefore = {}
                for j, buffer in ipairs(timerEventMessageBuffers[i].before) do
                    imgui.BeginGroup()
                    if imgui.InputText(u8"##TimerBefore" .. i .. j, buffer, imgui.InputTextFlags.None, nil, nil, 300) then
                        timerEventMessages[i].before[j] = buffer.v
                    end
                    imgui.SameLine()
                    if imgui.Button(fa.ICON_FA_MINUS .. u8"##TimerBeforeDel" .. i .. j) and #timerEventMessages[i].before > 1 then
                        toRemoveBefore[#toRemoveBefore + 1] = j
                    end
                    imgui.SameLine()
                    if imgui.Button(fa.ICON_FA_PLUS .. u8"##TimerBeforeAddInline" .. i .. j) then
                        table.insert(timerEventMessages[i].before, j + 1, u8"")
                        table.insert(timerEventMessageBuffers[i].before, j + 1, imgui.ImBuffer(u8"", 256))
                    end
                    imgui.EndGroup()
                end
                for _, j in ipairs(toRemoveBefore) do
                    table.remove(timerEventMessages[i].before, j)
                    table.remove(timerEventMessageBuffers[i].before, j)
                end
                
                imgui.Separator()
                
                imgui.Checkbox(u8"Во время##TimerDuringEnable" .. i, timerMessageEnabled[i].during)
                imgui.SameLine()
                imgui.Text(fa.ICON_FA_HOURGLASS_HALF .. " " .. u8"Сообщения во время отсчёта:")
                local toRemoveDuring = {}
                for j, buffer in ipairs(timerEventMessageBuffers[i].during) do
                    imgui.BeginGroup()
                    if imgui.InputText(u8"##TimerDuring" .. i .. j, buffer, imgui.InputTextFlags.None, nil, nil, 300) then
                        timerEventMessages[i].during[j] = buffer.v
                    end
                    imgui.SameLine()
                    if imgui.Button(fa.ICON_FA_MINUS .. u8"##TimerDuringDel" .. i .. j) and #timerEventMessages[i].during > 1 then
                        toRemoveDuring[#toRemoveDuring + 1] = j
                    end
                    imgui.SameLine()
                    if imgui.Button(fa.ICON_FA_PLUS .. u8"##TimerDuringAddInline" .. i .. j) then
                        table.insert(timerEventMessages[i].during, j + 1, u8"")
                        table.insert(timerEventMessageBuffers[i].during, j + 1, imgui.ImBuffer(u8"", 256))
                    end
                    imgui.EndGroup()
                end
                for _, j in ipairs(toRemoveDuring) do
                    table.remove(timerEventMessages[i].during, j)
                    table.remove(timerEventMessageBuffers[i].during, j)
                end
                
                imgui.Text(fa.ICON_FA_STOPWATCH .. " " .. u8"Интервал сообщений (сек):")
                if imgui.InputInt(u8"##TimerInterval" .. i, timerEventMessageBuffers[i].intervalBuffer) then
                    timerEventMessages[i].interval = math.max(1, timerEventMessageBuffers[i].intervalBuffer.v)
                    timerEventMessageBuffers[i].intervalBuffer.v = timerEventMessages[i].interval
                end
                
                imgui.Separator()
                
                imgui.Checkbox(u8"После##TimerAfterEnable" .. i, timerMessageEnabled[i].after)
                imgui.SameLine()
                imgui.Text(fa.ICON_FA_ARROW_LEFT .. " " .. u8"Сообщения после завершения:")
                local toRemoveAfter = {}
                for j, buffer in ipairs(timerEventMessageBuffers[i].after) do
                    imgui.BeginGroup()
                    if imgui.InputText(u8"##TimerAfter" .. i .. j, buffer, imgui.InputTextFlags.None, nil, nil, 300) then
                        timerEventMessages[i].after[j] = buffer.v
                    end
                    imgui.SameLine()
                    if imgui.Button(fa.ICON_FA_MINUS .. u8"##TimerAfterDel" .. i .. j) and #timerEventMessages[i].after > 1 then
                        toRemoveAfter[#toRemoveAfter + 1] = j
                    end
                    imgui.SameLine()
                    if imgui.Button(fa.ICON_FA_PLUS .. u8"##TimerAfterAddInline" .. i .. j) then
                        table.insert(timerEventMessages[i].after, j + 1, u8"")
                        table.insert(timerEventMessageBuffers[i].after, j + 1, imgui.ImBuffer(u8"", 256))
                    end
                    imgui.EndGroup()
                end
                for _, j in ipairs(toRemoveAfter) do
                    table.remove(timerEventMessages[i].after, j)
                    table.remove(timerEventMessageBuffers[i].after, j)
                end
                
                imgui.Separator()
                imgui.EndGroup()
            end
            if toRemoveTimer then
                table.remove(timers, toRemoveTimer)
                table.remove(timerWindows, toRemoveTimer)
                local newTimers = {}
                for i, timer in ipairs(timers) do
                    newTimers[i] = timer
                end
                timers = newTimers
                local newWindows = {}
                for i, window in ipairs(timerWindows) do
                    newWindows[i] = window
                end
                timerWindows = newWindows
            end
            
            if imgui.Button(fa.ICON_FA_PLUS .. " " .. u8"Добавить таймер") then
                table.insert(timers, {
                    label = "Таймер " .. (#timers + 1),
                    hours = "00",
                    minutes = "01",
                    seconds = "00",
                    durationStr = "00:01:00",
                    enabled = false,
                    paused = false,
                    elapsed = 0,
                    labelBuffer = imgui.ImBuffer(u8"Таймер " .. (#timers + 1), 256),
                    hoursBuffer = imgui.ImBuffer(u8"00", 3),
                    minutesBuffer = imgui.ImBuffer(u8"01", 3),
                    secondsBuffer = imgui.ImBuffer(u8"00", 3),
                    enabledBuffer = imgui.ImBool(false),
                    position = {x = screenX * 0.1, y = screenY * 0.1 + (#timers * 50)},
                    lastDuringMessageTime = nil
                })
                table.insert(timerWindows, imgui.ImBool(false))
            end
        end
        
        imgui.Separator()
        if not showWindow.v then
            saveSettings()
        end
        
        imgui.End()
    end

    if not timerWindows then
        timerWindows = {}
        for i = 1, #timers do
            timerWindows[i] = imgui.ImBool(timers[i].enabledBuffer.v)
        end
    end
    for i, timer in ipairs(timers) do
        if timer.enabledBuffer.v then
            local windowFlags = imgui.WindowFlags.NoTitleBar + 
                               imgui.WindowFlags.NoCollapse + 
                               imgui.WindowFlags.NoScrollbar + 
                               imgui.WindowFlags.NoResize + 
                               imgui.WindowFlags.AlwaysAutoResize
            if not showWindow.v then
                windowFlags = windowFlags + imgui.WindowFlags.NoMove
                imgui.ShowCursor = false
            else
                imgui.ShowCursor = true
            end
            
            if not timer.position then
                timer.position = {x = screenX * 0.1, y = screenY * 0.1 + (i - 1) * 50}
            end
            imgui.SetNextWindowPos(imgui.ImVec2(timer.position.x, timer.position.y), imgui.Cond.Once)
            
            imgui.Begin("TimerWindow" .. i, timerWindows[i], windowFlags)
            local timerText = timer.hours .. ":" .. timer.minutes .. ":" .. timer.seconds
            local remainingSeconds = 0
            if timer.enabled then
                if timer.startTime and not timer.paused then
                    local elapsed = (timer.elapsed or 0) + (os.clock() - timer.startTime)
                    local remaining = parseTimeString(timer) - elapsed
                    remainingSeconds = math.max(0, remaining)
                    timerText = formatTime(remainingSeconds)
                elseif timer.paused then
                    local remaining = parseTimeString(timer) - (timer.elapsed or 0)
                    remainingSeconds = math.max(0, remaining)
                    timerText = formatTime(remainingSeconds) .. " " .. u8"(пауза)"
                end
            end
            imgui.Text(fa.ICON_FA_CLOCK .. " " .. u8(timer.label))
            if remainingSeconds < 60 and timer.enabled and (timer.startTime or timer.paused) then
                imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1.0, 0.0, 0.0, 1.0))
                imgui.Text(fa.ICON_FA_HOURGLASS .. " " .. u8"Осталось: " .. timerText)
                imgui.PopStyleColor()
            else
                imgui.Text(fa.ICON_FA_HOURGLASS .. " " .. u8"Осталось: " .. timerText)
            end
            
            if showWindow.v then
                local pos = imgui.GetWindowPos()
                local size = imgui.GetWindowSize()
                timer.position.x = math.max(0, math.min(screenX - size.x, pos.x))
                timer.position.y = math.max(0, math.min(screenY - size.y, pos.y))
            end
            
            imgui.End()
        end
    end
	
	-- Окно инвентаря/клисты
	if kidnappingActive then
		local windowFlags = imgui.WindowFlags.NoTitleBar +
							imgui.WindowFlags.NoCollapse +
							imgui.WindowFlags.NoScrollbar +
							imgui.WindowFlags.NoResize +
							imgui.WindowFlags.AlwaysAutoResize

		-- Разрешаем перемещение только если основное окно открыто
		if not showWindow.v then
			windowFlags = windowFlags + imgui.WindowFlags.NoMove
		end

		imgui.SetNextWindowPos(imgui.ImVec2(inventoryPosition.x, inventoryPosition.y), imgui.Cond.Once)

		imgui.Begin("InventoryWindow", inventoryWindowVisible, windowFlags)
		imgui.Text(fa.ICON_FA_BOX .. " " .. u8"Инвентарь:")

		-- Объединяем тряпку и верёвку в одну строку
		local trapkaText = InvertoryTrapka == true and fa.ICON_FA_CHECK .. u8" Тряпка" or
						   (InvertoryTrapka == false and fa.ICON_FA_TIMES .. u8" Тряпка" or fa.ICON_FA_QUESTION .. u8" Тряпка")
		local verevkaText = InvertoryVerevka == true and fa.ICON_FA_CHECK .. u8" Веревка" or
							(InvertoryVerevka == false and fa.ICON_FA_TIMES .. u8" Веревка" or fa.ICON_FA_QUESTION .. u8" Веревка")
		local inventoryText = trapkaText .. u8" | " .. verevkaText
		imgui.Text(inventoryText)

		imgui.Separator()
		imgui.Text(fa.ICON_FA_USERS .. " " .. u8"Команда:")

		if #teamMembers > 0 then
			local _, localPlayerId = sampGetPlayerIdByCharHandle(PLAYER_PED)
			local localPlayerName = sampGetPlayerNickname(localPlayerId)
			local localPlayerColor = sampGetPlayerColor(localPlayerId) or 0xFFFFFFFF
			for _, member in ipairs(teamMembers) do
				local color = (member.name == localPlayerName) and localPlayerColor or member.color
				local r = bit.band(bit.rshift(color, 16), 0xFF) / 255.0
				local g = bit.band(bit.rshift(color, 8), 0xFF) / 255.0
				local b = bit.band(color, 0xFF) / 255.0
				-- Принудительно устанавливаем альфа-канал в 1.0 (полная непрозрачность)
				local a = 1.0

				-- Отладка: выводим значения цвета для каждого игрока
				log(string.format("Игрок: %s, Цвет: 0x%08X, R=%.2f, G=%.2f, B=%.2f, A=%.2f (исправлено на 1.0)", 
					member.name, color, r, g, b, a))

				local nameText = u8(member.name)

				-- Условие для отображения маски и корректировки цвета ника
				if r < 0.25 and g < 0.25 and b < 0.25 then
					-- Для тёмных цветов показываем маску и делаем ник светлым
					imgui.Text(fa.ICON_FA_MASK)
					imgui.SameLine()
					imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.8, 0.8, 0.8, 1)) -- Светлый цвет для читаемости
					imgui.Text(nameText)
					imgui.PopStyleColor()
					log("Применён светлый цвет (0.8, 0.8, 0.8, 1) для тёмного ника: " .. member.name)
				else
					-- Для всех остальных цветов маска не отображается, ник в оригинальном цвете с A=1.0
					local appliedColor = imgui.ImVec4(r, g, b, a)
					imgui.PushStyleColor(imgui.Col.Text, appliedColor)
					imgui.Text(nameText)
					imgui.PopStyleColor()
					log(string.format("Применён оригинальный цвет для %s: R=%.2f, G=%.2f, B=%.2f, A=%.2f", 
						member.name, r, g, b, a))
				end

				imgui.SameLine()
				imgui.Text(u8" | " .. fa.ICON_FA_HEART .. u8": " .. member.hp .. u8" | " .. fa.ICON_FA_SHIELD_ALT .. u8": " .. member.armor)
			end
		else
			imgui.Text(u8"Информация о команде недоступна")
		end

		-- Обновляем позицию окна, если оно перемещается (доступно только при открытом основном окне)
		if showWindow.v then
			local pos = imgui.GetWindowPos()
			local size = imgui.GetWindowSize()
			inventoryPosition.x = math.max(0, math.min(screenX - size.x, pos.x))
			inventoryPosition.y = math.max(0, math.min(screenY - size.y, pos.y))
		end

		imgui.End()
	end
    
    if not showWindow.v then
        imgui.ShowCursor = false
    end
end

function sampev.onServerMessage(color, text)
    log("Получено сообщение чата: " .. text)
    
    if text == "Не флуди!" then
        floodDetected = true
        log("Обнаружен флуд, будет выполнена переотправка")
        return
    end
    
    local rawText = text
    local decodedText = u8:decode(text)
    log("Сырой текст: '" .. rawText .. "', Декодированный текст: '" .. decodedText .. "'")
	
	-- Убираем ведущие и конечные пробелы для проверки
    local trimmedText = rawText:match("^%s*(.-)%s*$")
    
    -- Проверка на приобретение верёвки
    if trimmedText == "Веревка приобретена. Осталось: 1/1" then
        InvertoryVerevka = true
        log("Верёвка приобретена, флаг InvertoryVerevka установлен в true")
    else
        log("Сообщение '" .. rawText .. "' не соответствует 'Веревка приобретена. Осталось: 1/1'")
    end
    
    -- Проверка на приобретение тряпки
    if trimmedText == "Тряпка приобретена. Осталось: 1/1" then
        InvertoryTrapka = true
        log("Тряпка приобретена, флаг InvertoryTrapka установлен в true")
    else
        log("Сообщение '" .. rawText .. "' не соответствует 'Тряпка приобретена. Осталось: 1/1'")
    end

	-- Проверка сообщения о начале похищения с учётом цветового кода
    local targetName, initiatorName = rawText:match("%[Похищение%].-%{FFFFFF}.-цели ([%w_]+)%. Инициатор: ([%w_]+)")
    if targetName and initiatorName then
        log("Обнаружено сообщение о начале похищения. Цель: " .. targetName .. ", Инициатор: " .. initiatorName)
        
        -- Поиск ID цели по нику
        local targetId = nil
        for i = 0, 1000 do
            if sampIsPlayerConnected(i) then
                local nickname = sampGetPlayerNickname(i)
                if nickname == targetName then
                    targetId = i
                    break
                end
            end
        end
        
        if targetId then
            lockedTargetId = targetId
            targetInputBuffer.v = tostring(targetId)
            kidnappingActive = true
            sampAddChatMessage("{00FF00}[AlexKmenu] {FFFFFF}Цель " .. targetName .. " (ID: " .. targetId .. ") автоматически запомнена из сообщения о похищении", -1)
            log("Цель " .. targetName .. " (ID: " .. targetId .. ") установлена как запомненная")
        else
            log("Не удалось найти ID для цели " .. targetName)
        end
    else
        log("Сообщение '" .. rawText .. "' не соответствует шаблону начала похищения")
    end
    
    -- Проверка на отсутствие в команде похитителей
    if rawText == " Вы не состоите в команде похитителей" or decodedText:find("Вы не состоите в команде похитителей") then
        log("Обнаружено сообщение о том, что игрок не в команде")
        scriptInitiatedDialog = true -- Устанавливаем флаг перед вызовом команды
        processMessageQueue("/kmenu")
        log("Команда /kmenu добавлена в очередь")
    else
        log("Сообщение не соответствует ожидаемому: 'Вы не состоите в команде похитителей'")
    end
    
    -- Подтверждение команд в системном режиме
    if mode.v == 0 and lastTargetIdForMessage and lastCommandIndex and not commandConfirmed then
        local myNickname = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))
        local targetName = sampGetPlayerNickname(lastTargetIdForMessage)
        local expectedMessage = nil
        
        if lastCommandIndex == 2 then
            expectedMessage = myNickname .. " нокаутировал " .. targetName
        elseif lastCommandIndex == 1 then
            expectedMessage = myNickname .. " связал " .. targetName .. " веревкой"
        elseif lastCommandIndex == 3 then
            expectedMessage = myNickname .. " вставил кляп " .. targetName .. " в рот"
        elseif lastCommandIndex == 4 then
            expectedMessage = myNickname .. " открыл двери транспорта и посадил в него " .. targetName
        elseif lastCommandIndex == 5 then
            expectedMessage = myNickname .. " вытащил " .. targetName .. " из транспорта"
        elseif lastCommandIndex == 6 then
            expectedMessage = myNickname .. " повёл " .. targetName .. " за собой"
            local altExpectedMessage = myNickname .. " отпустил " .. targetName
            if text:find(expectedMessage) or text:find(altExpectedMessage) then
                commandConfirmed = true
            end
        end
        
        if expectedMessage and text:find(expectedMessage) then
            commandConfirmed = true
        end
    end
    
    -- Парсинг сообщения о показе паспорта (учитываем полное имя с подчёркиванием)
    local victimName = rawText:match("%s*([%w_]+)%s+показал%(а%) свой паспорт$")
    if victimName then
        currentPassportName = victimName
        log("Установлено имя жертвы: " .. victimName)
    end
    
    -- Парсинг сообщения /do от другого игрока как триггера (работаем с сырым текстом)
    local senderName, senderId, org, pos = rawText:match("^{FFFFFF}%s*%(%(%s*([%w_]+)%[(%d+)%]%s*%)%)%s*{FF8000}%s*С документах: Организация:%s*(.-)%s+Должность:%s*(.*)")
    if senderName and senderId and org and pos then
        if currentPassportName then
            local fullPassportData = "Организация: " .. org .. "   Должность: " .. pos
            passportData[currentPassportName] = fullPassportData
            log("Получены данные паспорта от " .. senderName .. "[" .. senderId .. "] для " .. currentPassportName .. ": " .. passportData[currentPassportName])
            passportUpdated = true
            
            -- Проверяем полную строку в passport_values.txt
            if passportValues[fullPassportData] then
                log("Найдено значение в passport_values.txt для '" .. fullPassportData .. "': " .. passportValues[fullPassportData])
            else
                log("'" .. fullPassportData .. "' не найдено в passport_values.txt")
            end
        else
            log("Не удалось определить имя жертвы для паспортных данных от " .. senderName .. "[" .. senderId .. "]")
        end
        return
    else
        if rawText:find("С документах: Организация:") then
            log("Паттерн для /do не сработал для текста: " .. rawText)
        end
    end
    
    -- Обработка паспорта (если вы сами получили паспорт)
    if rawText:match("-----------===%[ PASSPORT %]===----------") then
        awaitingPassport = true
        currentPassportName = nil
    elseif awaitingPassport then
        local name = rawText:match("Имя: ([%w_]+)")
        if name then currentPassportName = name end
        
        local org, pos = rawText:match("Организация: (.-)%s+Должность: (.-)$")
        if org and pos and currentPassportName then
            local fullPassportData = "Организация: " .. org .. "   Должность: " .. pos
            passportData[currentPassportName] = fullPassportData
            awaitingPassport = false
            passportUpdated = true
            log("Паспорт обновлён для " .. currentPassportName .. ": " .. passportData[currentPassportName])
            
            -- Проверяем условия для отправки сообщения
            local shouldSendMessage = false
            if kidnappingActive then
                local targetId = nil
                -- Проверяем текущую цель через ПКМ
                if isKeyDown(0x02) then
                    local result, target = getCharPlayerIsTargeting(PLAYER_HANDLE)
                    if result then
                        local res, id = sampGetPlayerIdByCharHandle(target)
                        if res then targetId = id end
                    end
                end
                -- Сравниваем имя из паспорта с текущей целью, последней целью или запомненной целью
                local targetName = targetId and sampGetPlayerNickname(targetId) or nil
                if (targetName and targetName == currentPassportName) or 
                   (lastTargetId and sampGetPlayerNickname(lastTargetId) == currentPassportName) or 
                   (lockedTargetId and sampGetPlayerNickname(lockedTargetId) == currentPassportName) then
                    shouldSendMessage = true
                end
            end
            
            if shouldSendMessage then
                -- Формируем сообщение в CP1251, затем преобразуем в UTF-8
                local rawPassportMessage = "/do С документах: Организация: " .. org .. "   Должность: " .. pos
                local passportMessage = u8(rawPassportMessage) -- Преобразуем в UTF-8 для совместимости с processMessageQueue
                log("Сырые данные: org='" .. org .. "', pos='" .. pos .. "'")
                log("Отправлено в чат: " .. passportMessage)
                processMessageQueue(passportMessage)
            else
                log("Сообщение не отправлено: похищение не активно или цель не соответствует")
            end
            
            -- Проверяем полную строку в passport_values.txt
            if passportValues[fullPassportData] then
                log("Найдено значение в passport_values.txt для '" .. fullPassportData .. "': " .. passportValues[fullPassportData])
            else
                log("'" .. fullPassportData .. "' не найдено в passport_values.txt")
            end
        end
        
        if rawText:match("=============================") then
            awaitingPassport = false
            currentPassportName = nil
        end
    end
end

function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
    log("Диалог открыт: ID=" .. dialogId .. ", Заголовок='" .. title .. "', Текст='" .. text .. "'")
    log("Текущие флаги: scriptInitiatedDialog=" .. tostring(scriptInitiatedDialog) .. ", kidnappingStarted=" .. tostring(kidnappingStarted) .. ", kidnappingDialogInitiated=" .. tostring(kidnappingDialogInitiated) .. ", lastTargetId=" .. tostring(lastTargetId))
	-- Обработка диалога инвентаря
    if InvertoryDialog and dialogId == 22 and title == "Карманы" then
        log("Обнаружен диалог инвентаря (ID 22)")
        -- Проверяем наличие "Тряпка" и "Веревка" в тексте диалога
        InvertoryTrapka = text:find("Тряпка") and true or false
        InvertoryVerevka = text:find("Веревка") and true or false
        
        log("Состояние инвентаря: Тряпка=" .. tostring(InvertoryTrapka) .. ", Веревка=" .. tostring(InvertoryVerevka))
        InvertoryDialog = false -- Сбрасываем флаг после обработки
        sampCloseCurrentDialogWithButton(1) -- Закрываем диалог
        return false -- Блокируем отображение диалога
    end    
    -- Обрабатываем диалоги, инициированные скриптом (например, для приглашений или других автоматических вызовов)
    if scriptInitiatedDialog then
        if dialogId == 1367 and title == "Меню похищений" then
            sampSendDialogResponse(dialogId, 1, 0, nil)
            log("Выбрана первая опция в диалоге 1367 (Меню похищений)")
            return false -- Блокируем отображение диалога в игре
        end
        
        if dialogId == 1368 and title == "Меню похищений" then
            if kidnappingStarted then
                log("[Kidnapping] Диалог 1368 открыт, kidnappingStarted=true, отправляем ответ для начала похищения")
                sampSendDialogResponse(dialogId, 1, 1, nil) -- Выбираем "Начать похищение" (вторая строка)
                log("[Kidnapping] Отправлен ответ в диалоге 1368: button=1, item=1")
            else
                sampCloseCurrentDialogWithButton(0)
                log("Диалог 1368 закрыт локально, kidnappingStarted=false")
                lua_thread.create(function()
                    wait(100)
                    inviteNearbyPlayers()
                    scriptInitiatedDialog = false
                    log("Повторное приглашение игроков вызвано после закрытия диалога 1368")
                end)
            end
            return false -- Блокируем отображение диалога в игре
        end
    end
    
    -- Обрабатываем диалог для начала похищения через клавишу 6
    if kidnappingDialogInitiated then
        if dialogId == 1368 and title == "Меню похищений" then
            log("[Kidnapping] Диалог 1368 открыт через клавишу 6, kidnappingStarted=true, отправляем ответ для начала похищения")
            sampSendDialogResponse(dialogId, 1, 1, nil) -- Выбираем "Начать похищение" (вторая строка)
            log("[Kidnapping] Отправлен ответ в диалоге 1368: button=1, item=1")
            kidnappingStarted = true -- Убеждаемся, что флаг установлен для следующего шага
            return false -- Блокируем отображение диалога в игре
        end
        
        if dialogId == 1373 and title == "Начало похищения" and lastTargetId then
            log("[Kidnapping] Диалог 1373 открыт, kidnappingDialogInitiated=true, последняя цель ID: " .. tostring(lastTargetId))
            local targetIdStr = tostring(lastTargetId)
            sampSendDialogResponse(dialogId, 1, -1, targetIdStr)
            log("[Kidnapping] Отправлен ответ в диалоге 1373 с ID цели: " .. targetIdStr)
            kidnappingStarted = false -- Сбрасываем флаг после успешной отправки
            kidnappingDialogInitiated = false -- Сбрасываем флаг после завершения процесса
            log("[Kidnapping] Флаги kidnappingStarted и kidnappingDialogInitiated сброшены после отправки ID в диалоге 1373")
            return false -- Блокируем отображение диалога в игре
        end
    end
    
    -- Для всех остальных случаев показываем диалог (например, при ручном вызове /kmenu)
    log("Диалог передан игре без изменений: ID=" .. dialogId)
    return true
end

function inviteNearbyPlayers()
    if inviteInProgress then return end
    inviteInProgress = true
    
    local myX, myY, myZ = getCharCoordinates(PLAYER_PED)
    local _, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
    for i = 0, 1000 do
        if i ~= myId and sampIsPlayerConnected(i) then
            local result, ped = sampGetCharHandleBySampPlayerId(i)
            if result then
                local px, py, pz = getCharCoordinates(ped)
                local distance = getDistanceBetweenCoords3d(myX, myY, myZ, px, py, pz)
                if distance <= 5.0 then
                    scriptInitiatedDialog = true -- Устанавливаем флаг перед вызовом команды
                    processMessageQueue("/kinvite " .. i)
                    log("Приглашение отправлено игроку с ID " .. i)
                end
            end
        end
    end
    sampAddChatMessage("{00FF00}[AlexKmenu] {FFFFFF}Приглашения отправлены игрокам в радиусе 5 метров", -1)
    
    inviteInProgress = false
end

function sampev.onPlayerDisconnect(id)
    if activeText ~= nil and lastTargetId == id then
        sampDestroy3dText(activeText)
        activeText = nil
        lastTargetId = nil
        lastColor = nil
    end
    local nickname = sampGetPlayerNickname(id)
    if nickname then passportData[nickname] = nil end
end