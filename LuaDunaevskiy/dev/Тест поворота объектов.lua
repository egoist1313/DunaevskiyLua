script_name('AttachObjectToLocalPlayer')
script_author('YourName')
script_version('1.0')

local vkeys = require 'vkeys' -- Для обработки клавиш
local samp = require 'samp.events' -- Для работы с командами
local memory = require 'memory' -- Для работы с буфером обмена

-- Переменные для хранения состояния
local attachedObject = nil
local dragging = false
local offsetX, offsetY, offsetZ = 0, 0, 0.3 -- Начальное смещение относительно кости
local rotX, rotY, rotZ = 0, 0, 0 -- Углы поворота объекта
local scaleX, scaleY, scaleZ = 1.0, 1.0, 1.0 -- Масштаб объекта
local lastCommandTime = 0
local lastCursorX, lastCursorY = nil, nil -- Для отслеживания предыдущей позиции курсора
local objectId = nil -- Для хранения ID объекта
local boneOffsetZ = 0.7 -- Смещение кости 1 (позвоночник) относительно центра игрока

function main()
    while not isSampAvailable() do wait(100) end
    sampAddChatMessage("{FFFFFF}Скрипт AttachObjectToLocalPlayer загружен. Используйте /test <object_id>.", -1)
    sampRegisterChatCommand("test", onTestCommand)

    while true do
        wait(0)
        if attachedObject then
            updateObjectPosition()
            handleDragging()
        end
    end
end

-- Обработка команды /test
function onTestCommand(arg)
    local currentTime = os.clock()
    if currentTime - lastCommandTime < 1 then return end -- Задержка 1 сек
    lastCommandTime = currentTime

    if attachedObject then
        -- Повторный ввод: вывод команды в буфер
        copyCommandToClipboard()
        if doesObjectExist(attachedObject) then
            deleteObject(attachedObject)
        end
        attachedObject = nil
        dragging = false
        lastCursorX, lastCursorY = nil, nil -- Сброс позиции курсора
        objectId = nil
        sampAddChatMessage("{00FF00}Объект откреплён. Команда /hbject скопирована в буфер обмена.", -1)
    else
        -- Первый ввод: создание и прикрепление объекта
        local id = arg:match("^(%d+)$")
        if not id then
            sampAddChatMessage("{FF0000}Использование: /test <object_id>", -1)
            return
        end

        objectId = tonumber(id)
        if not sampIsLocalPlayerSpawned() then
            sampAddChatMessage("{FF0000}Вы должны быть заспавнены.", -1)
            return
        end

        -- Загружаем модель и проверяем её доступность
        requestModel(objectId)
        if not isModelAvailable(objectId) then
            sampAddChatMessage("{FF0000}Модель " .. objectId .. " недоступна.", -1)
            return
        end

        local px, py, pz = getCharCoordinates(PLAYER_PED)
        attachedObject = createObjectNoOffset(objectId, px, py, pz + boneOffsetZ + offsetZ) -- Создаём над костью
        if not doesObjectExist(attachedObject) then
            sampAddChatMessage("{FF0000}Не удалось создать объект с ID " .. objectId .. ".", -1)
            return
        end

        offsetX, offsetY, offsetZ = 0, 0, 0.3 -- Начальное смещение относительно кости
        rotX, rotY, rotZ = 0, 0, 0 -- Начальные углы
        scaleX, scaleY, scaleZ = 1.0, 1.0, 1.0 -- Начальный масштаб
        sampAddChatMessage("{00FF00}Объект " .. objectId .. " прикреплён к кости 1. F5+ЛКМ: перетаскивание/масштаб, F4+ЛКМ: высота, F3+ЛКМ: вращение.", -1)
    end
end

-- Обновление позиции объекта
function updateObjectPosition()
    if not doesObjectExist(attachedObject) then
        attachedObject = nil
        sampAddChatMessage("{FF0000}Объект был уничтожен.", -1)
        return
    end

    local playerX, playerY, playerZ = getCharCoordinates(PLAYER_PED)
    local playerAngle = getCharHeading(PLAYER_PED)
    local rad = math.rad(playerAngle)

    -- Рассчитываем мировые координаты с учётом смещения кости
    local newX = playerX + offsetX * math.cos(rad) + offsetY * math.sin(rad)
    local newY = playerY - offsetX * math.sin(rad) + offsetY * math.cos(rad)
    local newZ = playerZ + boneOffsetZ + offsetZ

    setObjectCoordinates(attachedObject, newX, newY, newZ)
    setObjectRotation(attachedObject, rotX, rotY, rotZ)
end

-- Перетаскивание, изменение высоты, вращение и масштаб
function handleDragging()
    local cursorX, cursorY = getCursorPos()
    local isLButtonDown = isKeyDown(vkeys.VK_LBUTTON) -- Проверка удержания ЛКМ
    local isF5Down = isKeyDown(vkeys.VK_F5) -- Проверка удержания F5
    local isF4Down = isKeyDown(vkeys.VK_F4) -- Проверка удержания F4
    local isF3Down = isKeyDown(vkeys.VK_F3) -- Проверка удержания F3

    -- Перетаскивание и масштаб (F5 + ЛКМ)
    if isF5Down and isLButtonDown then
        if not dragging then
            dragging = true
            lastCursorX, lastCursorY = cursorX, cursorY -- Запоминаем начальную позицию курсора
            sampAddChatMessage("{FFFF00}Перетаскивание начато. Двигайте мышкой или используйте колёсико для масштаба с зажатой ЛКМ.", -1)
        end

        -- Перемещение по X и Y (ускорено в 4 раза)
        if lastCursorX and lastCursorY then
            local dx = (cursorX - lastCursorX) / 100
            local dy = (cursorY - lastCursorY) / 100
            offsetX = offsetX + dx * 0.2 -- Ускорено до 0.2
            offsetY = offsetY - dy * 0.2 -- Ускорено до 0.2
            lastCursorX, lastCursorY = cursorX, cursorY -- Обновляем последнюю позицию
        end

        -- Регулировка масштаба на колёсико мыши
        if isKeyJustPressed(vkeys.VK_MWHEELUP) then
            scaleX = scaleX + 0.1
            scaleY = scaleY + 0.1
            scaleZ = scaleZ + 0.1
        elseif isKeyJustPressed(vkeys.VK_MWHEELDOWN) then
            scaleX = math.max(0.1, scaleX - 0.1) -- Минимальный масштаб 0.1
            scaleY = math.max(0.1, scaleY - 0.1)
            scaleZ = math.max(0.1, scaleZ - 0.1)
        end
    elseif dragging and not isLButtonDown then
        dragging = false
        sampAddChatMessage("{FFFF00}Перетаскивание завершено.", -1)
    end

    -- Изменение высоты (F4 + ЛКМ)
    if isF4Down and isLButtonDown and attachedObject then
        if lastCursorY then
            local dy = (cursorY - lastCursorY) / 100
            offsetZ = offsetZ - dy * 0.2 -- Ускорено до 0.2, инверсия для естественного движения
            lastCursorY = cursorY -- Обновляем позицию Y для высоты
        else
            lastCursorY = cursorY -- Инициализируем начальную позицию Y
        end
    end

    -- Вращение (F3 + ЛКМ, ускорено в 4 раза)
    if isF3Down and isLButtonDown and attachedObject then
        if lastCursorX and lastCursorY then
            local dx = (cursorX - lastCursorX) / 10
            local dy = (cursorY - lastCursorY) / 10
            rotZ = rotZ + dx * 2.0 -- Ускорено до 2.0 (ось Z)
            rotX = rotX - dy * 2.0 -- Ускорено до 2.0 (ось X, инверсия для соответствия /hbject)
            rotX = math.max(-180, math.min(180, rotX))
            rotZ = rotZ % 360
            lastCursorX, lastCursorY = cursorX, cursorY -- Обновляем позицию для вращения
        else
            lastCursorX, lastCursorY = cursorX, cursorY -- Инициализируем начальную позицию для вращения
        end
    end
end

-- Копирование команды в буфер обмена
function copyCommandToClipboard()
    if not attachedObject or not objectId then return end

    local playerId = select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))
    local playerX, playerY, playerZ = getCharCoordinates(PLAYER_PED)
    local result, objectX, objectY, objectZ = getObjectCoordinates(attachedObject)
    
    if not result then
        sampAddChatMessage("{FF0000}Не удалось получить координаты объекта.", -1)
        return
    end

    -- Формируем команду /hbject с использованием локальных координат относительно кости
    local command = string.format(
        "/hbject %d 0 %d 1 %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f 0x0 0x0",
        playerId, objectId, offsetX, offsetY, offsetZ, rotX, rotY, rotZ, scaleX, scaleY, scaleZ
    )

    -- Копируем в буфер обмена
    setClipboardText(command)
    print("Скопирована команда: " .. command)

    -- Вывод мировых координат для отладки
    local worldMsg = string.format(
        "{FFFFFF}Мировые координаты объекта:\nX: %.2f, Y: %.2f, Z: %.2f\nУгол игрока: %.2f",
        objectX, objectY, objectZ, getCharHeading(PLAYER_PED)
    )
    sampAddChatMessage(worldMsg, -1)
end

-- Очистка при выходе
function onScriptTerminate(script, quitGame)
    if script == thisScript() and attachedObject and doesObjectExist(attachedObject) then
        deleteObject(attachedObject)
    end
end