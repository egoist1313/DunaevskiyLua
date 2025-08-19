script_name('TeleportToObject')
script_author('YourName')
script_version('1.0')

require "lib.moonloader"
require "lib.sampfuncs"
local vkeys = require 'vkeys'

function main()
    while not isSampAvailable() do 
        wait(100) 
    end
    sampAddChatMessage("{FFFFFF}Скрипт телепортации загружен. Нажмите F5 для телепорта к ближайшему зелёному объекту.", -1)
    
    while true do
        wait(0)
        if isKeyJustPressed(vkeys.VK_F5) then
            teleportToNearestGreenObject({1608, 1609, 19315, 19833})
            wait(200) -- Задержка для предотвращения спама
        end
    end
end

-- Функция телепортации к ближайшему зелёному объекту
function teleportToNearestGreenObject(targetModels)
    local playerX, playerY, playerZ = getCharCoordinates(PLAYER_PED)
    local _, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
    local nearestObject = nil
    local minDistance = math.huge

    for _, obj in pairs(getAllObjects()) do
        local model = getObjectModel(obj)
        if table.contains(targetModels, model) then
            local _, objX, objY, objZ = getObjectCoordinates(obj)
            local distance = getDistanceBetweenCoords3d(playerX, playerY, playerZ, objX, objY, objZ)
            local playerNear, _ = isPlayerNearObject(objX, objY, objZ, myId)
            local isNotVisible = distance <= 299 and not isObjectVisibleInStream(objX, objY, objZ)
            
            -- Условие для зелёных меток: объект виден и нет игроков рядом
            if not isNotVisible and not playerNear then
                if distance < minDistance then
                    minDistance = distance
                    nearestObject = obj
                end
            end
        end
    end

    if nearestObject then
        local _, targetX, targetY, targetZ = getObjectCoordinates(nearestObject)
        local newZ = targetZ - 1.0
        setCharCoordinates(PLAYER_PED, targetX, targetY, newZ)
        sampAddChatMessage("{FFFFFF}Телепортировался к объекту с моделью " .. getObjectModel(nearestObject) .. " (расстояние: " .. string.format("%.2f", minDistance) .. " м)", -1)
    else
        sampAddChatMessage("{FF0000}Нет доступных зелёных объектов для телепортации в зоне стрима.", -1)
    end
end

-- Проверка, есть ли другие игроки в радиусе 20 метров от объекта
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

-- Проверка, виден ли объект в зоне стрима
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

-- Вспомогательная функция для проверки наличия значения в таблице
function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end