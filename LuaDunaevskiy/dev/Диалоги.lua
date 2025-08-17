-- DialogLogger.lua
local sampev = require 'lib.samp.events' -- ���������� ���������� ��� ������ � ��������� SA-MP

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then
        return -- ��� �������� SA-MP � SAMPFUNCS
    end
    
    while not isSampAvailable() do
        wait(0) -- ��� ������ ����������� SA-MP
    end
    
    print("DialogLogger: ������ ��������. ����������� �������� ������.")
    sampAddChatMessage("[DialogLogger] ������ �������. �������� ������� MoonLoader ��� �����.", 0x00FF00)
end

-- ��������� ������� ������ �������
function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
    -- ������� ���������� � ������� � �������
    print("=== ����� ������ ������ ===")
    print("ID �������: " .. dialogId)
    print("����� �������: " .. style)
    print("���������: " .. title)
    print("������ 1: " .. button1)
    print("������ 2: " .. button2)
    print("����� �������: " .. text)
    print("========================")
    
    -- ���������� true, ����� �� ����������� ���������� ��������� �������
    return true
end

-- ��������� ������ �� ������ (�����������)
function sampev.onDialogResponse(dialogId, button, listItem, inputText)
    print("=== ����� �� ������ ===")
    print("ID �������: " .. dialogId)
    print("������� ������: " .. button .. " (0 - ������ 2, 1 - ������ 1)")
    print("��������� �����: " .. listItem)
    print("�������� �����: " .. inputText)
    print("======================")
end