script_name('ObjectMarker with TextDraw Clicker')
script_author('AlexSwift, Clicker by YourName')
script_version('1.0')
script_properties("work-in-pause") -- Ïîçâîëÿåò ñêðèïòó ðàáîòàòü â ïàóçå

require "lib.moonloader"
require "lib.sampfuncs"
local samp = require "samp.events"
local MessageSender = require "lib.messagesender" -- Ïîäêëþ÷àåì áèáëèîòåêó
local imgui = require "mimgui"

-- Ïóòü ê ôàéëó äëÿ ñîõðàíåíèÿ äàííûõ
local SAVE_FILE = "moonloader/object_markers.txt"

-- Ñïèñîê öåëåâûõ ìîäåëåé îáúåêòîâ äëÿ ObjectMarker
local targetModels = {1608, 1609, 19315, 19833}
-- Ñïèñîê ìîäåëåé äëÿ àâòîêëèêåðà
local clickerTargetModels = {19315, 19833}
-- Òàáëèöà äëÿ õðàíåíèÿ íàéäåííûõ îáúåêòîâ
local foundObjects = {}
-- Ôëàã äëÿ âêëþ÷åíèÿ/îòêëþ÷åíèÿ ìåòîê
local markersEnabled = false
-- Ñïèñîê ñîçäàííûõ ìåòîê (blips)
local blips = {}
-- Òàáëèöà äëÿ âðåìåííîãî õðàíåíèÿ îáúåêòîâ è èõ êîîðäèíàò äëÿ ïðîâåðêè äâèæåíèÿ
local tempObjects = {}
-- Ïåðåìåííûå äëÿ óïðàâëåíèÿ êîìàíäîé /hunting spear è àòàêîé
local lastSpearCommand = 0 -- Âðåìÿ ïîñëåäíåé îòïðàâêè êîìàíäû
local floodWait = false -- Ôëàã îæèäàíèÿ ïîñëå "Íå ôëóäè"
local spearSent = false -- Ôëàã îòïðàâêè êîìàíäû â òåêóùåé ñåññèè â âîäå
local lastAttackTime = 0 -- Âðåìÿ ïîñëåäíåé ýìóëÿöèè Ctrl
local hasSpear = true -- Ôëàã íàëè÷èÿ êîïüÿ
local wasInWater = false -- Ôëàã äëÿ îòñëåæèâàíèÿ ïðåäûäóùåãî ñîñòîÿíèÿ â âîäå
-- Ïåðåìåííàÿ äëÿ õðàíåíèÿ ñëåäóþùåãî íîìåðà îáúåêòà
local nextObjectNumber = 1

function main()
    while not isSampAvailable() do 
        wait(100) 
    end
    
    -- Èíèöèàëèçèðóåì MessageSender
    MessageSender:init()
    
    loadObjectsFromFile()
    sampAddChatMessage("{FFFFFF} /hmap äëÿ óïðàâëåíèÿ ìåòêàìè. Âñå ìåòêè âèäíû íà ïàóçå (Esc).", -1)
    sampAddChatMessage("{FFFFFF} Àâòîêëèêåð ïî TextDraw (ld_beat:chit) çàïóùåí.", -1)
    sampRegisterChatCommand("hmap", toggleMarkers)
    
    -- Çàïóñêàåì àâòîêëèêåð êàê îòäåëüíóþ êîðóòèíó
    lua_thread.create(textDrawClickerCoroutine)
    
    -- Îñíîâíîé öèêë äëÿ ObjectMarker
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

-- Ôóíêöèÿ äëÿ îòðèñîâêè íîìåðîâ îáúåêòîâ íà áîëüøîé êàðòå
function drawObjectNumbersOnMap()
    local DL = imgui.GetBackgroundDrawList()
    if not DL then
        print("[ObjectMarker] Îøèáêà: imgui.GetBackgroundDrawList() âåðíóë nil")
        return
    end
    print("[ObjectMarker] Âûçîâ drawObjectNumbersOnMap, îáúåêòîâ: " .. #foundObjects)
    
    -- Ïàðàìåòðû êàðòû (ïðèìåð äëÿ ðàçðåøåíèÿ 1920x1080)
    local mapLeft = 600   -- Ëåâûé êðàé êàðòû íà ýêðàíå
    local mapTop = 200    -- Âåðõíèé êðàé êàðòû íà ýêðàíå
    local mapWidth = 600  -- Øèðèíà êàðòû íà ýêðàíå
    local mapHeight = 600 -- Âûñîòà êàðòû íà ýêðàíå
    local worldSize = 6000 -- Ðàçìåð èãðîâîãî ìèðà (-3000 äî 3000)

    for _, obj in ipairs(foundObjects) do
        print("[ObjectMarker] Îáðàáîòêà îáúåêòà #" .. obj.number .. " íà êîîðäèíàòàõ x=" .. obj.x .. ", y=" .. obj.y .. ", z=" .. obj.z)
        -- Ïðåîáðàçóåì èãðîâûå êîîðäèíàòû â ýêðàííûå êîîðäèíàòû íà áîëüøîé êàðòå
        local mapX = mapLeft + (obj.x - (-3000)) * (mapWidth / worldSize)
        local mapY = mapTop + (3000 - obj.y) * (mapHeight / worldSize) -- Èíâåðòèðóåì Y, òàê êàê êàðòà îòîáðàæàåòñÿ ñâåðõó âíèç

        print("[ObjectMarker] Îáúåêò #" .. obj.number .. " mapSpace: x=" .. mapX .. ", y=" .. mapY)
        local number = tostring(obj.number)
        local textSize = imgui.CalcTextSize(number)
        local pos = imgui.ImVec2(mapX - textSize.x / 2, mapY - textSize.y / 2)
        -- Îòðèñîâêà òåêñòà ñ òåíüþ
        DL:AddText(imgui.ImVec2(pos.x - 1, pos.y - 1), 0xCC000000, number)
        DL:AddText(imgui.ImVec2(pos.x + 1, pos.y + 1), 0xCC000000, number)
        DL:AddText(imgui.ImVec2(pos.x - 1, pos.y + 1), 0xCC000000, number)
        DL:AddText(imgui.ImVec2(pos.x + 1, pos.y - 1), 0xCC000000, number)
        -- Îñíîâíîé öâåò òåêñòà (áåëûé)
        DL:AddText(pos, 0xFFFFFFFF, number)
        print("[ObjectMarker] Îòðèñîâàí íîìåð " .. number .. " íà ïîçèöèè x=" .. pos.x .. ", y=" .. pos.y)
    end
end

-- Ôóíêöèÿ àâòîêëèêåðà, ðàáîòàþùàÿ êàê êîðóòèíà
function textDrawClickerCoroutine()
    while true do
        wait(0) -- Îñíîâíîé öèêë àâòîêëèêåðà
        local targetTextdraw = findTextdrawByContent("ld_beat:chit")
        if targetTextdraw and isObjectNearby(clickerTargetModels, 2) then
            sampSendClickTextdraw(targetTextdraw) -- Êëèê ïî íàéäåííîìó TextDraw
            wait(100)                            -- Çàäåðæêà 100 ìñ
        end
    end
end

-- Ôóíêöèÿ äëÿ ïîèñêà TextDraw ïî ñîäåðæèìîìó
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

-- Ôóíêöèÿ ïðîâåðêè íàëè÷èÿ îáúåêòîâ â çàäàííîì ðàäèóñå (äëÿ àâòîêëèêåðà)
function isObjectNearby(targetModels, radius)
    local playerX, playerY, playerZ = getCharCoordinates(PLAYER_PED)
    
    -- Ïåðåáèðàåì âñå îáúåêòû â çîíå ñòðèìà
    for _, obj in pairs(getAllObjects()) do
        local model = getObjectModel(obj)
        if table.contains(targetModels, model) then
            local _, objX, objY, objZ = getObjectCoordinates(obj)
            local distance = getDistanceBetweenCoords3d(playerX, playerY, playerZ, objX, objY, objZ)
            if distance <= radius then
                return true -- Îáúåêò íàéäåí â ðàäèóñå
            end
        end
    end
    return false -- Îáúåêòû íå íàéäåíû â ðàäèóñå
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
                                        number = nextObjectNumber -- Ïðèñâàèâàåì ñëåäóþùèé íîìåð
                                    }
                                    nextObjectNumber = nextObjectNumber + 1 -- Óâåëè÷èâàåì íîìåð äëÿ ñëåäóþùåãî îáúåêòà
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
    
    -- Ïðîâåðÿåì ïåðåõîä èç ñîñòîÿíèÿ "íå â âîäå" â "â âîäå"
    if isInWater and not wasInWater then
        hasSpear = true -- Ñáðàñûâàåì ôëàã ïðè íîâîì ïîãðóæåíèè
    end
    
    if isInWater and hasSpear then
        for _, obj in pairs(getAllObjects()) do
            local model = getObjectModel(obj)
            if model == 1608 or model == 1609 then
                local _, objX, objY, objZ = getObjectCoordinates(obj)
                local distance = getDistanceBetweenCoords3d(playerX, playerY, playerZ, objX, objY, objZ)
                local currentTime = os.clock()
                
                -- Ïðîâåðêà íà ðàäèóñ 5 ìåòðîâ äëÿ êîìàíäû
                if distance <= 5.0 then
                    if not spearSent and not floodWait and (currentTime - lastSpearCommand >= 2.0) then
                        MessageSender:sendChatMessage("/hunting spear") -- Çàìåíÿåì sampSendChat
                        lastSpearCommand = currentTime
                        spearSent = true
                    end
                    
                    -- Ïðîâåðêà íà ðàäèóñ 3 ìåòðà äëÿ ýìóëÿöèè Ctrl
                    if distance <= 3.0 and spearSent then
                        if currentTime - lastAttackTime >= 0.05 then -- ×àñòîòà 20 ðàç â ñåêóíäó (50ìñ)
                            setGameKeyState(17, 255) -- Íàæàòèå Ctrl
                            lua_thread.create(function()
                                wait(25) -- Äåðæèì 25ìñ (ïîëîâèíà öèêëà)
                                setGameKeyState(17, 0) -- Îòïóñêàåì Ctrl
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
        setGameKeyState(17, 0) -- Îòïóñêàåì Ctrl ïðè âûõîäå èç âîäû èëè îòñóòñòâèè êîïüÿ
    end
    
    wasInWater = isInWater -- Îáíîâëÿåì ñîñòîÿíèå äëÿ ñëåäóþùåé èòåðàöèè
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
        sampAddChatMessage("{FFFFFF}Ìåòêè âêëþ÷åíû. Âñå ìåòêè âèäíû íà ïàóçå (Esc).", -1)
    else
        removeMarkers()
        sampAddChatMessage("{FFFFFF}Ìåòêè îòêëþ÷åíû.", -1)
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
                    changeBlipColour(blip, 0xFF0000FF) -- Êðàñíûé
                else
                    changeBlipColour(blip, 0x00FF00FF) -- Çåë¸íûé
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
                -- Îáíîâëÿåì ñëåäóþùèé íîìåð, ÷òîáû íå ïåðåñå÷üñÿ ñ óæå çàãðóæåííûìè
                if tonumber(number) >= nextObjectNumber then
                    nextObjectNumber = tonumber(number) + 1
                end
            else
                -- Ïîääåðæêà ñòàðîãî ôîðìàòà ôàéëà (áåç íîìåðà)
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
    if text:find("Íå ôëóäè") then
        floodWait = true
        lua_thread.create(function()
            wait(2000)
            floodWait = false
            if isCharInWater(PLAYER_PED) and hasSpear then
                checkWaterSpearAndAttack()
            end
        end)
    elseif text:find("Ó âàñ íåò êîïüÿ") then
        hasSpear = false -- Óñòàíàâëèâàåì ôëàã, ÷òî êîïüÿ íåò
        spearSent = false -- Ñáðàñûâàåì ôëàã êîìàíäû
        setGameKeyState(17, 0) -- Îòïóñêàåì Ctrl
    end
end

function onScriptTerminate(scr, quitGame)
    if scr == thisScript() then
        removeMarkers()
        setGameKeyState(17, 0) -- Îòïóñêàåì Ctrl ïðè âûãðóçêå ñêðèïòà
    end
end
