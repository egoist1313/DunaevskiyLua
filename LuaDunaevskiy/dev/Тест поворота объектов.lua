script_name('AttachObjectToLocalPlayer')
script_author('YourName')
script_version('1.0')

local vkeys = require 'vkeys' -- ��� ��������� ������
local samp = require 'samp.events' -- ��� ������ � ���������
local memory = require 'memory' -- ��� ������ � ������� ������

-- ���������� ��� �������� ���������
local attachedObject = nil
local dragging = false
local offsetX, offsetY, offsetZ = 0, 0, 0.3 -- ��������� �������� ������������ �����
local rotX, rotY, rotZ = 0, 0, 0 -- ���� �������� �������
local scaleX, scaleY, scaleZ = 1.0, 1.0, 1.0 -- ������� �������
local lastCommandTime = 0
local lastCursorX, lastCursorY = nil, nil -- ��� ������������ ���������� ������� �������
local objectId = nil -- ��� �������� ID �������
local boneOffsetZ = 0.7 -- �������� ����� 1 (�����������) ������������ ������ ������

function main()
    while not isSampAvailable() do wait(100) end
    sampAddChatMessage("{FFFFFF}������ AttachObjectToLocalPlayer ��������. ����������� /test <object_id>.", -1)
    sampRegisterChatCommand("test", onTestCommand)

    while true do
        wait(0)
        if attachedObject then
            updateObjectPosition()
            handleDragging()
        end
    end
end

-- ��������� ������� /test
function onTestCommand(arg)
    local currentTime = os.clock()
    if currentTime - lastCommandTime < 1 then return end -- �������� 1 ���
    lastCommandTime = currentTime

    if attachedObject then
        -- ��������� ����: ����� ������� � �����
        copyCommandToClipboard()
        if doesObjectExist(attachedObject) then
            deleteObject(attachedObject)
        end
        attachedObject = nil
        dragging = false
        lastCursorX, lastCursorY = nil, nil -- ����� ������� �������
        objectId = nil
        sampAddChatMessage("{00FF00}������ ��������. ������� /hbject ����������� � ����� ������.", -1)
    else
        -- ������ ����: �������� � ������������ �������
        local id = arg:match("^(%d+)$")
        if not id then
            sampAddChatMessage("{FF0000}�������������: /test <object_id>", -1)
            return
        end

        objectId = tonumber(id)
        if not sampIsLocalPlayerSpawned() then
            sampAddChatMessage("{FF0000}�� ������ ���� ����������.", -1)
            return
        end

        -- ��������� ������ � ��������� � �����������
        requestModel(objectId)
        if not isModelAvailable(objectId) then
            sampAddChatMessage("{FF0000}������ " .. objectId .. " ����������.", -1)
            return
        end

        local px, py, pz = getCharCoordinates(PLAYER_PED)
        attachedObject = createObjectNoOffset(objectId, px, py, pz + boneOffsetZ + offsetZ) -- ������ ��� ������
        if not doesObjectExist(attachedObject) then
            sampAddChatMessage("{FF0000}�� ������� ������� ������ � ID " .. objectId .. ".", -1)
            return
        end

        offsetX, offsetY, offsetZ = 0, 0, 0.3 -- ��������� �������� ������������ �����
        rotX, rotY, rotZ = 0, 0, 0 -- ��������� ����
        scaleX, scaleY, scaleZ = 1.0, 1.0, 1.0 -- ��������� �������
        sampAddChatMessage("{00FF00}������ " .. objectId .. " ��������� � ����� 1. F5+���: ��������������/�������, F4+���: ������, F3+���: ��������.", -1)
    end
end

-- ���������� ������� �������
function updateObjectPosition()
    if not doesObjectExist(attachedObject) then
        attachedObject = nil
        sampAddChatMessage("{FF0000}������ ��� ���������.", -1)
        return
    end

    local playerX, playerY, playerZ = getCharCoordinates(PLAYER_PED)
    local playerAngle = getCharHeading(PLAYER_PED)
    local rad = math.rad(playerAngle)

    -- ������������ ������� ���������� � ������ �������� �����
    local newX = playerX + offsetX * math.cos(rad) + offsetY * math.sin(rad)
    local newY = playerY - offsetX * math.sin(rad) + offsetY * math.cos(rad)
    local newZ = playerZ + boneOffsetZ + offsetZ

    setObjectCoordinates(attachedObject, newX, newY, newZ)
    setObjectRotation(attachedObject, rotX, rotY, rotZ)
end

-- ��������������, ��������� ������, �������� � �������
function handleDragging()
    local cursorX, cursorY = getCursorPos()
    local isLButtonDown = isKeyDown(vkeys.VK_LBUTTON) -- �������� ��������� ���
    local isF5Down = isKeyDown(vkeys.VK_F5) -- �������� ��������� F5
    local isF4Down = isKeyDown(vkeys.VK_F4) -- �������� ��������� F4
    local isF3Down = isKeyDown(vkeys.VK_F3) -- �������� ��������� F3

    -- �������������� � ������� (F5 + ���)
    if isF5Down and isLButtonDown then
        if not dragging then
            dragging = true
            lastCursorX, lastCursorY = cursorX, cursorY -- ���������� ��������� ������� �������
            sampAddChatMessage("{FFFF00}�������������� ������. �������� ������ ��� ����������� ������� ��� �������� � ������� ���.", -1)
        end

        -- ����������� �� X � Y (�������� � 4 ����)
        if lastCursorX and lastCursorY then
            local dx = (cursorX - lastCursorX) / 100
            local dy = (cursorY - lastCursorY) / 100
            offsetX = offsetX + dx * 0.2 -- �������� �� 0.2
            offsetY = offsetY - dy * 0.2 -- �������� �� 0.2
            lastCursorX, lastCursorY = cursorX, cursorY -- ��������� ��������� �������
        end

        -- ����������� �������� �� ������� ����
        if isKeyJustPressed(vkeys.VK_MWHEELUP) then
            scaleX = scaleX + 0.1
            scaleY = scaleY + 0.1
            scaleZ = scaleZ + 0.1
        elseif isKeyJustPressed(vkeys.VK_MWHEELDOWN) then
            scaleX = math.max(0.1, scaleX - 0.1) -- ����������� ������� 0.1
            scaleY = math.max(0.1, scaleY - 0.1)
            scaleZ = math.max(0.1, scaleZ - 0.1)
        end
    elseif dragging and not isLButtonDown then
        dragging = false
        sampAddChatMessage("{FFFF00}�������������� ���������.", -1)
    end

    -- ��������� ������ (F4 + ���)
    if isF4Down and isLButtonDown and attachedObject then
        if lastCursorY then
            local dy = (cursorY - lastCursorY) / 100
            offsetZ = offsetZ - dy * 0.2 -- �������� �� 0.2, �������� ��� ������������� ��������
            lastCursorY = cursorY -- ��������� ������� Y ��� ������
        else
            lastCursorY = cursorY -- �������������� ��������� ������� Y
        end
    end

    -- �������� (F3 + ���, �������� � 4 ����)
    if isF3Down and isLButtonDown and attachedObject then
        if lastCursorX and lastCursorY then
            local dx = (cursorX - lastCursorX) / 10
            local dy = (cursorY - lastCursorY) / 10
            rotZ = rotZ + dx * 2.0 -- �������� �� 2.0 (��� Z)
            rotX = rotX - dy * 2.0 -- �������� �� 2.0 (��� X, �������� ��� ������������ /hbject)
            rotX = math.max(-180, math.min(180, rotX))
            rotZ = rotZ % 360
            lastCursorX, lastCursorY = cursorX, cursorY -- ��������� ������� ��� ��������
        else
            lastCursorX, lastCursorY = cursorX, cursorY -- �������������� ��������� ������� ��� ��������
        end
    end
end

-- ����������� ������� � ����� ������
function copyCommandToClipboard()
    if not attachedObject or not objectId then return end

    local playerId = select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))
    local playerX, playerY, playerZ = getCharCoordinates(PLAYER_PED)
    local result, objectX, objectY, objectZ = getObjectCoordinates(attachedObject)
    
    if not result then
        sampAddChatMessage("{FF0000}�� ������� �������� ���������� �������.", -1)
        return
    end

    -- ��������� ������� /hbject � �������������� ��������� ��������� ������������ �����
    local command = string.format(
        "/hbject %d 0 %d 1 %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f 0x0 0x0",
        playerId, objectId, offsetX, offsetY, offsetZ, rotX, rotY, rotZ, scaleX, scaleY, scaleZ
    )

    -- �������� � ����� ������
    setClipboardText(command)
    print("����������� �������: " .. command)

    -- ����� ������� ��������� ��� �������
    local worldMsg = string.format(
        "{FFFFFF}������� ���������� �������:\nX: %.2f, Y: %.2f, Z: %.2f\n���� ������: %.2f",
        objectX, objectY, objectZ, getCharHeading(PLAYER_PED)
    )
    sampAddChatMessage(worldMsg, -1)
end

-- ������� ��� ������
function onScriptTerminate(script, quitGame)
    if script == thisScript() and attachedObject and doesObjectExist(attachedObject) then
        deleteObject(attachedObject)
    end
end