script_name("MouseChecker")
script_author("YourName")
script_version("1.0")

require "lib.moonloader"
require "sampfuncs"
local imgui = require "imgui"

local lastState = nil -- ��� ������������ ��������� ���������

function main()
    -- ���������, �������� �� SAMP
    while not isSampAvailable() do
        print("�������� �������� SA-MP...")
        wait(100)
    end
    
    print("MouseChecker �������!")
    
    -- �������� ����
    while true do
        local currentState = isMouseActive()
        -- ������� ��������� ������ ��� ��������� ���������
        if currentState ~= lastState then
            if currentState then
                sampAddChatMessage("{00FF00}[MouseChecker]: {FFFFFF}������ ���� �������!", -1)
            else
                sampAddChatMessage("{FF0000}[MouseChecker]: {FFFFFF}������ ���� ���������!", -1)
            end
            lastState = currentState
        end
        wait(500) -- �������� ������ 500 ��
    end
end

-- ������� ��� �������� ���������� �������
function isMouseActive()
    return imgui.GetIO().WantCaptureMouse -- ImGui ����������� ����
        or sampIsChatInputActive()        -- ��� �������
        or sampIsDialogActive()           -- ������ �������
        or isPauseMenuActive()            -- ���� ����� �������
end