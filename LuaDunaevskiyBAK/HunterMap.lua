-- Автор: AlexDunaevskiy, 2025 https://t.me/AlexDunaevskiy
local script_name = 'HunterMap'
local script_version = '2.0.0'
script_properties("work-in-pause")

require "lib.moonloader"
require "lib.sampfuncs"
local samp = require "samp.events"
local MessageSender = require "lib.messagesender" 
local imgui = require "mimgui"

-- Путь к файлу для сохранения данных
local SAVE_FILE = "moonloader/LuaDunaevskiy/object_markers.txt"

-- Список целевых моделей объектов для ObjectMarker
local targetModels = {1608, 1609, 19315, 19833}

-- Список моделей для автокликера
local clickerTargetModels = {19315, 19833}

-- Таблица для хранения найденных объектов
local foundObjects = {}

-- Флаг для включения/отключения меток
local markersEnabled = false

-- Список созданных меток (blips)
local blips = {}

-- Таблица для временного хранения объектов и их координат для проверки движения
local tempObjects = {}

-- Переменные для управления командой /hunting spear и атакой
local lastSpearCommand = 0 -- Время последней отправки команды
local floodWait = false -- Флаг ожидания после "Не флуди"
local spearSent = false -- Флаг отправки команды в текущей сессии в воде
local lastAttackTime = 0 -- Время последней эмуляции Ctrl
local hasSpear = true -- Флаг наличия копья
local wasInWater = false -- Флаг для отслеживания предыдущего состояния в воде

-- Переменная для хранения следующего номера объекта
local nextObjectNumber = 1

function main()
    while not isSampAvailable() do
        wait(100)
    end

    -- Инициализируем MessageSender
    MessageSender:init()

    loadObjectsFromFile()
    sampAddChatMessage("{FFFFFF} /hmap для управления метками. Все метки видны на паузе (Esc).", -1)
    sampRegisterChatCommand("hmap", toggleMarkers)

    -- Запускаем автокликер как отдельную корутину
    lua_thread.create(textDrawClickerCoroutine)

    -- Основной цикл для ObjectMarker
    while true do
        wait(0)
        if not isPauseMenuActive() then
            updateObjectList()
            checkWaterSpearAndAttack()
        end
        if markersEnabled then
            if isPauseMenuActive() then
                updateMarkers(true)
                drawObjectNumbersOnMap()
            else
                updateMarkers(false)
            end
        end
        wait(50)
    end
end

-- Функция для отрисовки номеров объектов на большой карте
function drawObjectNumbersOnMap()
    local DL = imgui.GetBackgroundDrawList()
    if not DL then
        print("[ObjectMarker] Ошибка: imgui.GetBackgroundDrawList() вернул nil")
        return
    end
    print("[ObjectMarker] Вызов drawObjectNumbersOnMap, объектов: " .. #foundObjects)

    -- Параметры карты (пример для разрешения 1920x1080)
    local mapLeft = 600 -- Левый край карты на экране
    local mapTop = 200 -- Верхний край карты на экране
    local mapWidth = 600 -- Ширина карты на экране
    local mapHeight = 600 -- Высота карты на экране
    local worldSize = 6000 -- Размер игрового мира (-3000 до 3000)

    for _, obj in ipairs(foundObjects) do
        print("[ObjectMarker] Обработка объекта #" .. obj.number .. " на координатах x=" .. obj.x .. ", y=" .. obj.y .. ", z=" .. obj.z)
        -- Преобразуем игровые координаты в экранные координаты на большой карте
        local mapX = mapLeft + (obj.x - (-3000)) * (mapWidth / worldSize)
        local mapY = mapTop + (3000 - obj.y) * (mapHeight / worldSize) -- Инвертируем Y, так как карта отображается сверху вниз
        print("[ObjectMarker] Объект #" .. obj.number .. " mapSpace: x=" .. mapX .. ", y=" .. mapY)
        local number = tostring(obj.number)
        local textSize = imgui.CalcTextSize(number)
        local pos = imgui.ImVec2(mapX - textSize.x / 2, mapY - textSize.y / 2)
        -- Отрисовка текста с тенью
        DL:AddText(imgui.ImVec2(pos.x - 1, pos.y - 1), 0xCC000000, number)
        DL:AddText(imgui.ImVec2(pos.x + 1, pos.y + 1), 0xCC000000, number)
        DL:AddText(imgui.ImVec2(pos.x - 1, pos.y + 1), 0xCC000000, number)
        DL:AddText(imgui.ImVec2(pos.x + 1, pos.y - 1), 0xCC000000, number)
        -- Основной цвет текста (белый)
        DL:AddText(pos, 0xFFFFFFFF, number)
        print("[ObjectMarker] Отрисован номер " .. number .. " на позиции x=" .. pos.x .. ", y=" .. pos.y)
    end
end

-- Функция автокликера, работающая как корутина
function textDrawClickerCoroutine()
    while true do
        wait(0) -- Основной цикл автокликера
        local targetTextdraw = findTextdrawByContent("ld_beat:chit")
        if targetTextdraw and isObjectNearby(clickerTargetModels, 2) then
            sampSendClickTextdraw(targetTextdraw) -- Клик по найденному TextDraw
            wait(100) -- Задержка 100 мс
        end
    end
end

-- Функция для поиска TextDraw по содержимому
function findTextdrawByContent(content)
    for id = 0, 2047 do
        if sampTextdrawIsExists(id) then
            local text = sampTextdrawGetString(id) or ""
            if text == content then
                return id
            end
        end
    end
    return nil
end

-- Функция проверки наличия объектов в заданном радиусе (для автокликера)
function isObjectNearby(targetModels, radius)
    local playerX, playerY, playerZ = getCharCoordinates(PLAYER_PED)

    -- Перебираем все объекты в зоне стрима
    for _, obj in pairs(getAllObjects()) do
        local model = getObjectModel(obj)
        if table.contains(targetModels, model) then
            local _, objX, objY, objZ = getObjectCoordinates(obj)
            local distance = getDistanceBetweenCoords3d(playerX, playerY, playerZ, objX, objY, objZ)
            if distance <= radius then
                return true -- Объект найден в радиусе
            end
        end
    end
    return false -- Объекты не найдены в радиусе
end

function updateObjectList()
    local playerX, playerY, playerZ = getCharCoordinates(PLAYER_PED)
    local _, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)

    local newTempObjects = {}
    for _, obj in pairs(getAllObjects()) do
        local model = getObjectModel(obj)
        if table.contains(targetModels, model) then
            local _, objX, objY, objZ = getObjectCoordinates(obj)
            local distance = getDistanceBetweenCoords3d(playerX, playerY, playerZ, objX, objY, objZ)

            if distance <= 250 then
                local playerNear, _ = isPlayerNearObject(objX, objY, objZ, myId)
                if not playerNear then
                    local objKey = tostring(obj)
                    if not tempObjects[objKey] then
                        newTempObjects[objKey] = {x = objX, y = objY, z = objZ, timer = os.clock()}
                    else
                        local oldData = tempObjects[objKey]
                        local timeElapsed = os.clock() - oldData.timer
                        if timeElapsed >= 2.0 then
                            local distMoved = getDistanceBetweenCoords3d(oldData.x, oldData.y, oldData.z, objX, objY, objZ)
                            if distMoved < 0.5 then
                                if not isObjectInList(objX, objY, objZ) then
                                    local newObj = {
                                        model = model,
                                        x = objX,
                                        y = objY,
                                        z = objZ,
                                        number = nextObjectNumber -- Присваиваем следующий номер
                                    }
                                    nextObjectNumber = nextObjectNumber + 1 -- Увеличиваем номер для следующего объекта
                                    table.insert(foundObjects, newObj)
                                    saveNewObjectToFile(newObj)
                                end
                            end
                        else
                            newTempObjects[objKey] = {x = oldData.x, y = oldData.y, z = oldData.z, timer = oldData.timer}
                        end
                    end
                end
            end
        end
    end

    tempObjects = newTempObjects
end

function checkWaterSpearAndAttack()
    local playerX, playerY, playerZ = getCharCoordinates(PLAYER_PED)
    local isInWater = isCharInWater(PLAYER_PED)

    -- Проверяем переход из состояния "не в воде" в "в воде"
    if isInWater and not wasInWater then
        hasSpear = true -- Сбрасываем флаг при новом погружении
    end

    if isInWater and hasSpear then
        for _, obj in pairs(getAllObjects()) do
            local model = getObjectModel(obj)
            if model == 1608 or model == 1609 then
                local _, objX, objY, objZ = getObjectCoordinates(obj)
                local distance = getDistanceBetweenCoords3d(playerX, playerY, playerZ, objX, objY, objZ)
                local currentTime = os.clock()

                -- Проверка на радиус 5 метров для команды
                if distance <= 5.0 then
                    if not spearSent and not floodWait and (currentTime - lastSpearCommand >= 2.0) then
                        MessageSender:sendChatMessage("/hunting spear") -- Заменяем sampSendChat
                        lastSpearCommand = currentTime
                        spearSent = true
                    end

                    -- Проверка на радиус 3 метра для эмуляции Ctrl
                    if distance <= 3.0 and spearSent then
                        if currentTime - lastAttackTime >= 0.05 then -- Частота 20 раз в секунду (50мс)
                            setGameKeyState(17, 255) -- Нажатие Ctrl
                            lua_thread.create(function()
                                wait(25) -- Держим 25мс (половина цикла)
                                setGameKeyState(17, 0) -- Отпускаем Ctrl
                            end)
                            lastAttackTime = currentTime
                        end
                    end
                    return
                end
            end
        end
    else
        spearSent = false
        setGameKeyState(17, 0) -- Отпускаем Ctrl при выходе из воды или отсутствии копья
    end

    wasInWater = isInWater -- Обновляем состояние для следующей итерации
end

function isObjectInList(x, y, z)
    for _, obj in ipairs(foundObjects) do
        local dist = getDistanceBetweenCoords3d(x, y, z, obj.x, obj.y, obj.z)
        if dist < 5.0 then
            return true
        end
    end
    return false
end

function isPlayerNearObject(objX, objY, objZ, myId)
    for i = 0, 1003 do
        if sampIsPlayerConnected(i) and i ~= myId then
            local result, ped = sampGetCharHandleBySampPlayerId(i)
            if result and ped then
                local charX, charY, charZ = getCharCoordinates(ped)
                if charX and charY and charZ then
                    local distance = getDistanceBetweenCoords3d(objX, objY, objZ, charX, charY, charZ)
                    if distance <= 20 then
                        return true, i
                    end
                end
            end
        end
    end
    return false, nil
end

function isObjectVisibleInStream(x, y, z)
    for _, obj in pairs(getAllObjects()) do
        local _, objX, objY, objZ = getObjectCoordinates(obj)
        local dist = getDistanceBetweenCoords3d(x, y, z, objX, objY, objZ)
        if dist < 5.0 then
            return true
        end
    end
    return false
end

function toggleMarkers()
    markersEnabled = not markersEnabled
    if markersEnabled then
        updateMarkers(false)
        sampAddChatMessage("{FFFFFF}Метки включены. Все метки видны на паузе (Esc).", -1)
    else
        removeMarkers()
        sampAddChatMessage("{FFFFFF}Метки отключены.", -1)
    end
end

function updateMarkers(showAll)
    removeMarkers()
    local playerX, playerY, playerZ = getCharCoordinates(PLAYER_PED)

    for _, obj in ipairs(foundObjects) do
        local distance = getDistanceBetweenCoords3d(playerX, playerY, playerZ, obj.x, obj.y, obj.z)
        local isNotVisible = distance <= 299 and not isObjectVisibleInStream(obj.x, obj.y, obj.z)
        local icon = 0

        if distance <= 250 or showAll then
            local blip = addSpriteBlipForCoord(obj.x, obj.y, obj.z, icon)
            if blip then
                if isNotVisible then
                    changeBlipColour(blip, 0xFF0000FF) -- Красный
                else
                    changeBlipColour(blip, 0x00FF00FF) -- Зелёный
                end
                table.insert(blips, blip)
            end
        end
    end
end

function removeMarkers()
    for _, blip in ipairs(blips) do
        removeBlip(blip)
    end
    blips = {}
end

function saveNewObjectToFile(obj)
    local file = io.open(SAVE_FILE, "a")
    if file then
        local line = string.format("%d %.6f %.6f %.6f %d\n", obj.model, obj.x, obj.y, obj.z, obj.number)
        file:write(line)
        file:close()
    end
end

function loadObjectsFromFile()
    foundObjects = {}
    local file = io.open(SAVE_FILE, "r")
    if file then
        for line in file:lines() do
            local model, x, y, z, number = line:match("(%d+)%s+([%d%.%-]+)%s+([%d%.%-]+)%s+([%d%.%-]+)%s+(%d+)")
            if model and x and y and z and number then
                table.insert(foundObjects, {
                    model = tonumber(model),
                    x = tonumber(x),
                    y = tonumber(y),
                    z = tonumber(z),
                    number = tonumber(number)
                })
                -- Обновляем следующий номер, чтобы не пересекаться с уже загруженными
                if tonumber(number) >= nextObjectNumber then
                    nextObjectNumber = tonumber(number) + 1
                end
            else
                -- Поддержка старого формата файла (без номера)
                local model, x, y, z = line:match("(%d+)%s+([%d%.%-]+)%s+([%d%.%-]+)%s+([%d%.%-]+)")
                if model and x and y and z then
                    table.insert(foundObjects, {
                        model = tonumber(model),
                        x = tonumber(x),
                        y = tonumber(y),
                        z = tonumber(z),
                        number = nextObjectNumber
                    })
                    nextObjectNumber = nextObjectNumber + 1
                end
            end
        end
        file:close()
    end
end

function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

function samp.onServerMessage(color, text)
    if text:find("Не флуди") then
        floodWait = true
        lua_thread.create(function()
            wait(2000)
            floodWait = false
            if isCharInWater(PLAYER_PED) and hasSpear then
                checkWaterSpearAndAttack()
            end
        end)
    elseif text:find("У вас нет копья") then
        hasSpear = false -- Устанавливаем флаг, что копья нет
        spearSent = false -- Сбрасываем флаг команды
        setGameKeyState(17, 0) -- Отпускаем Ctrl
    end
end

function onScriptTerminate(scr, quitGame)
    if scr == thisScript() then
        removeMarkers()
        setGameKeyState(17, 0) -- Отпускаем Ctrl при выгрузке скрипта
    end
end