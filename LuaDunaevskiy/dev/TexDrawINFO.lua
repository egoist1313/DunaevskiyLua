script_name('TextDraw Info')
script_author('YourName')
script_version('1.0')

require "lib.sampfuncs"
local sampevents = require 'samp.events' -- ���������� ��������� ����������, ��� � cook

-- ��������� ��� ������ TextDraw �� ������� onShowTextDraw
local textdrawData = {}

function main()
    while not isSampAvailable() do wait(100) end
    print('������ ��������. ����������� /tdinfo ��� ��������� ���������� � �������������')
    sampRegisterChatCommand('tdinfo', showTextDrawInfo)
    wait(-1)
end

-- �������� ������� �������� TextDraw
function sampevents.onShowTextDraw(id, data)
    -- ��������� ������ TextDraw
    textdrawData[id] = {
        modelId = data.modelId or 0,
        text = data.text or "N/A",
        positionX = data.position.x or 0,
        positionY = data.position.y or 0,
        style = data.style or 0,
        shadowColor = data.shadowColor or 0
    }
    -- �������� �������� TextDraw
    sampfuncsLog(('Textdraw create | ID: %d | ModelID: %d | Text: %s | X: %.2f | Y: %.2f | Style: %d | ShadowColor: %08X'):format(
        id, data.modelId or 0, data.text or "N/A", data.position.x or 0, data.position.y or 0, data.style or 0, data.shadowColor or 0))
end

function showTextDrawInfo()
    print('=== ���������� � ������������� ===')
    local found = false
    for id = 0, 3047 do
        if sampTextdrawIsExists(id) then
            found = true
            print(string.format('TextDraw ID: %d', id))
            
            -- �������� ��������� ����� sampfuncs
            local text = sampTextdrawGetString(id)
            if text and text ~= '' then
                print('�����: ' .. text)
            else
                print('�����: �� ������� �������� ��� ������')
            end
            
            local posX, posY = sampTextdrawGetPos(id)
            print(string.format('�������: X: %.2f, Y: %.2f', posX, posY))
            
            local isProportional = sampTextdrawGetProportional(id)
            print('������������������: ' .. (isProportional and '��' or '���'))
            
            local shadowColor = sampTextdrawGetShadowColor(id)
            print(string.format('���� ����: ARGB: %08X', shadowColor))
            
            local style = sampTextdrawGetStyle(id)
            print('�����: ' .. style)
            
            local alignment = sampTextdrawGetAlign(id)
            print('������������: ' .. alignment)
            
            -- ��������� ������ �� events.onShowTextDraw, ���� ��� ����
            if textdrawData[id] then
                print('ModelID: ' .. textdrawData[id].modelId)
                print('����� (�� �������): ' .. textdrawData[id].text)
                print(string.format('������� (�� �������): X: %.2f, Y: %.2f', textdrawData[id].positionX, textdrawData[id].positionY))
                print('����� (�� �������): ' .. textdrawData[id].style)
                print(string.format('���� ���� (�� �������): ARGB: %08X', textdrawData[id].shadowColor))
            else
                print('ModelID: ���������� (������ ������� �����������)')
            end
            
            print('------------------------')
        end
    end
    if not found then
        print('�������� ������������� �� �������')
    end
    print('=== ����� ���������� ===')
end