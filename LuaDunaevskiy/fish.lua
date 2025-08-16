
script_author('AlexDunaevskiy')
local script_name = 'Fish'
local script_version = '2.0.0'

local samp = require 'samp.events'
local json = require 'json'
local MessageSender = require 'lib.messagesender'
require "lib.sampfuncs"

-- Глобальные переменные для fish
local shiftKey = 16
local altKey = 21
local scriptActive = false
local dialogQueue = {}
local fishStartTextdraw = nil
local fishLineTextdraw = nil
local fishTargetTextdraw = nil
local netData = {}
local configPath = getWorkingDirectory() .. "\\config\\Alexfish.json"

-- Глобальные переменные для автокликера
local targetModelIds = {1604, 1600, 19630, 1599} -- Рыба
local textdrawModels = {} -- для ID модели

-- Функция для удаления цветовых кодов из текста
local function removeColorCodes(text)
    return text:gsub("{[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]}", "")
end

-- Функция для загрузки данных из JSON
local function loadNetData()
    if doesFileExist(configPath) then
        local file = io.open(configPath, "r")
        if file then
            local content = file:read("*all")
            file:close()
            if content and content ~= "" then
                local success, result = pcall(json.decode, content)
                if success and type(result) == "table" then
                    netData = result
                else
                    netData = {}
                end
            else
                netData = {}
            end
        else
            netData = {}
        end
    else
        netData = {}
    end
end

-- Функция для сохранения данных в JSON
local function saveNetData()
    local dir = getWorkingDirectory() .. "\\config"
    if not doesDirectoryExist(dir) then
        createDirectory(dir)
    end
    local file = io.open(configPath, "w")
    if file then
        file:write(json.encode(netData))
        file:close()
    else
    end
end

-- Функция для установки состояния клавиши
local function setKeyState(key, isEnabled)
    local state = isEnabled and 255 or 0
    setGameKeyState(key, state)
end

-- Функция для нажатия и отпускания клавиши Alt
local function pressAlt()
    setKeyState(altKey, true)
    wait(10)
    setKeyState(altKey, false)
end

-- Функция для отображения главного меню
local function showFishMenu()
    local menuItems = {
        "Экипировка (/fish equip)",
        "Журнал (/fish journal)",
        "Сети (/fish net)",
        "Инвентарь (/fish inv)",
        "Скилл (/fish skill)",
        "Информация (/fish info)",
        "Автоловля (активировать/деактивировать)"
    }
    sampShowDialog(6000, "Рыболовное меню", table.concat(menuItems, "\n"), "Выбрать", "Закрыть", 4)

    table.insert(dialogQueue, function()
        while sampIsDialogActive(6000) do
            wait(0)
        end
        local result, button, listItem = sampHasDialogRespond(6000)
        if result then
            if button == 1 then
                if listItem == 0 then MessageSender:sendChatMessage("/fish equip")
                elseif listItem == 1 then MessageSender:sendChatMessage("/fish journal")
                elseif listItem == 2 then MessageSender:sendChatMessage("/fish net")
                elseif listItem == 3 then MessageSender:sendChatMessage("/fish inv")
                elseif listItem == 4 then MessageSender:sendChatMessage("/fish skill")
                elseif listItem == 5 then MessageSender:sendChatMessage("/fish info")
                elseif listItem == 6 then
                    scriptActive = not scriptActive
                    if scriptActive then
                        sampAddChatMessage("[Fish] Активирован", -1)
                    else
                        setKeyState(shiftKey, false)
                        setKeyState(altKey, false)
                        sampAddChatMessage("[Fish] Деактивирован", -1)
                    end
                    showFishMenu()
                end
            end
        end
    end)
end

-- Регистрация команды /fish
sampRegisterChatCommand("fish", function(arg)
    local inputText = sampGetChatInputText()
    if inputText == "/fish" or inputText == "/fish " then
        showFishMenu()
    else
        MessageSender:sendChatMessage(inputText)
    end
end)

-- Обработка очереди диалогов
local function processDialogQueue()
    if #dialogQueue > 0 and not sampIsDialogActive() then
        local dialogFunc = table.remove(dialogQueue, 1)
        dialogFunc()
    end
end

-- Поиск текстдравов по содержимому и цвету (для fish)
local function findFishTextdraws()
    fishStartTextdraw = nil
    fishLineTextdraw = nil
    fishTargetTextdraw = nil
    for id = 0, 2304 do
        if sampTextdrawIsExists(id) then
            local text = sampTextdrawGetString(id)
            local _, _, color = sampTextdrawGetLetterSizeAndColor(id)
            local x, y = sampTextdrawGetPos(id)
            if text:find("CATCHING") and color == 0xFFFFFFFF then
                fishStartTextdraw = {id = id, x = x, y = y}
            elseif text == "LD_BEAT:chit" and color == 0xFF000000 and x >= 418 and x <= 422 then
                fishLineTextdraw = {id = id, x = x, y = y}
            elseif text == "LD_SPAC:white" and color == 0xA01472FF then
                fishTargetTextdraw = {id = id, x = x, y = y}
            end
        end
    end
end

-- Функция поиска TextDraw (для автокликера)
local function findTextdraw(text, style, modelIds)
    for id = 0, 3047 do
        if sampTextdrawIsExists(id) then
            local tdText = sampTextdrawGetString(id) or ""
            local tdStyle = sampTextdrawGetStyle(id)
            local tdModelId = textdrawModels[id] or 0
            if tdText == text and tdStyle == style and table.contains(modelIds, tdModelId) then
                return id
            end
        end
    end
    return nil
end

-- Функция проверки наличия объектов (для автокликера)
local function isObjectNearby(targetModels, radius)
    local playerX, playerY, playerZ = getCharCoordinates(PLAYER_PED)
    
    for _, obj in pairs(getAllObjects()) do
        local model = getObjectModel(obj)
        if table.contains(targetModels, model) then
            local _, objX, objY, objZ = getObjectCoordinates(obj)
            local distance = getDistanceBetweenCoords3d(playerX, playerY, playerZ, objX, objY, objZ)
            if distance <= radius then
                return true
            end
        end
    end
    return false
end

-- Вспомогательная функция (для автокликера)
function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

-- Обработка входящих сообщений чата
function samp.onServerMessage(color, text)
    local cleanText = removeColorCodes(text)
    if cleanText:find("Вы успешно установили рыболовную сеть") then
        local playerId = select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))
        local nickname = sampGetPlayerNickname(playerId)
        local timestamp = math.floor(os.time() / 60) -- Время в минутах с 1970 года
        
        netData[nickname] = netData[nickname] or {}
        netData[nickname].time = timestamp
        saveNetData()
    elseif cleanText:find("Вы должны находиться на воде для установки сети") then
        local playerId = select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))
        local nickname = sampGetPlayerNickname(playerId)
        if netData[nickname] and netData[nickname].duration and not netData[nickname].time then
            netData[nickname].duration = nil
            saveNetData()
        end
    end
end

-- Глобальная переменная для хранения ID диалога установки сети
local netDialogId = nil

-- Обработка показа диалога
function samp.onShowDialog(dialogId, style, title, button1, button2, text)
    local cleanTitle = removeColorCodes(title)
    if cleanTitle:find("Установка сети") then
        netDialogId = dialogId
    end
end

-- Обработка отправки ответа на диалог
function samp.onSendDialogResponse(dialogId, button, listItem, inputText)
    if dialogId == netDialogId then
        if button == 1 then -- Кнопка "Выбрать"
            local playerId = select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))
            local nickname = sampGetPlayerNickname(playerId)
            local duration

            if listItem == 0 then duration = 6
            elseif listItem == 1 then duration = 12
            elseif listItem == 2 then duration = 18
            elseif listItem == 3 then duration = 24 end

            if duration then
                netData[nickname] = netData[nickname] or {}
                netData[nickname].duration = duration
                saveNetData()
            else
            end
        elseif button == 0 then
        end
        netDialogId = nil -- Сбрасываем ID после обработки
    end
end

-- Перехват события создания TextDraw (для автокликера)
function samp.onShowTextDraw(id, data)
    if data.text == "model" and data.style == 5 then
        textdrawModels[id] = data.modelId or 0
    end
end

local shiftReleasedInCar = false

-- Основной цикл
function main()
    if not isSampfuncsLoaded() or not isSampLoaded() then
        return
    end

    while not isSampAvailable() do
        wait(100)
    end

    -- Инициализируем MessageSender
    MessageSender:init()
    loadNetData()
    sampAddChatMessage("[Fish] Скрипт загружен", -1)

    while true do
        wait(0)
        processDialogQueue()

        -- Логика автокликера
        local targetTextdraw = findTextdraw("model", 5, targetModelIds)
        if targetTextdraw and sampTextdrawIsExists(targetTextdraw) and isObjectNearby({2076}, 2) then
            sampSendClickTextdraw(targetTextdraw)
            wait(100)
        end

        -- Логика fish
        if not scriptActive then
            wait(100)
            goto continue
        end

        local playerHandle = PLAYER_PED
        if not isCharInAnyCar(playerHandle) then
            shiftReleasedInCar = false
            findFishTextdraws()

            if fishStartTextdraw and not fishLineTextdraw then
                pressAlt()
                wait(300)
            end

            if fishLineTextdraw and fishTargetTextdraw then
                if fishTargetTextdraw.y > fishLineTextdraw.y then
                    setKeyState(shiftKey, true)
                else
                    setKeyState(shiftKey, false)
                end
            elseif fishLineTextdraw then
                setKeyState(shiftKey, false)
            else
                setKeyState(shiftKey, false)
            end
        else
            if not shiftReleasedInCar then
                setKeyState(shiftKey, false)
                shiftReleasedInCar = true
            end
        end

        ::continue::
    end
end