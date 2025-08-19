script_name('ProveObjectPosition')
script_author('YourName')
script_version('1.0')

local samp = require 'samp.events' -- Для работы с командами
local memory = require 'memory' -- Для работы с буфером обмена

function main()
    while not isSampAvailable() do wait(100) end
    sampAddChatMessage("{FFFFFF}Скрипт ProveObjectPosition загружен. Используйте /prov <object_id>.", -1)
    sampRegisterChatCommand("prov", onProveCommand)
    wait(-1) -- Бесконечный цикл не нужен, только обработка команд
end

-- Обработка команды /prov
function onProveCommand(arg)
    local objectId = arg:match("^(%d+)$")
    if not objectId then
        sampAddChatMessage("{FF0000}Использование: /prov <object_id>", -1)
        return
    end

    objectId = tonumber(objectId)
    if not sampIsLocalPlayerSpawned() then
        sampAddChatMessage("{FF0000}Вы должны быть заспавнены.", -1)
        return
    end

    -- Ищем ближайший объект с указанным ID
    local playerX, playerY, playerZ = getCharCoordinates(PLAYER_PED)
    local nearestObject = nil
    local minDistance = math.huge

    for _, obj in pairs(getAllObjects()) do
        if getObjectModel(obj) == objectId then
            local _, objX, objY, objZ = getObjectCoordinates(obj)
            local distance = getDistanceBetweenCoords3d(playerX, playerY, playerZ, objX, objY, objZ)
            if distance < minDistance then
                minDistance = distance
                nearestObject = obj
            end
        end
    end

    if not nearestObject then
        sampAddChatMessage("{FF0000}Объект с ID " .. objectId .. " не найден в зоне стрима.", -1)
        return
    end

    -- Получаем данные объекта
    local playerId = select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))
    local playerAngle = getCharHeading(PLAYER_PED)
    local result, objectX, objectY, objectZ = getObjectCoordinates(nearestObject)
    
    if not result then
        sampAddChatMessage("{FF0000}Не удалось получить координаты объекта.", -1)
        return
    end

    -- Вычисляем локальные координаты относительно игрока
    local rad = math.rad(playerAngle)
    local dx = objectX - playerX
    local dy = objectY - playerY
    local dz = objectZ - playerZ
    local localX = dx * math.cos(-rad) + dy * math.sin(-rad)
    local localY = -dx * math.sin(-rad) + dy * math.cos(-rad)
    local localZ = dz

    -- Углы поворота недоступны, ставим 0.0
    local rx, ry, rz = 0.0, 0.0, 0.0

    -- Формируем команду /hbject
    local command = string.format(
        "/hbject %d 0 %d 1 %.3f %.3f %.3f %.3f %.3f %.3f 1.000 1.000 1.000 0x0 0x0",
        playerId, objectId, localX, localY, localZ, rx, ry, rz
    )

    -- Копируем в буфер обмена
    setClipboardText(command)
    sampAddChatMessage("{00FF00}Данные объекта " .. objectId .. " скопированы в буфер обмена (углы недоступны, установлены как 0).", -1)
    print("Скопирована команда: " .. command)
end