local script_name = 'CEF'
local script_version = '14/08/2025'
script_version_number = 1
script_dependencies = {'sampfuncs'}

local sampfuncs = require 'sampfuncs'

local is_cursor_visible = false -- ���������� ��� ������������ ��������� �������

function main()
    if not isSampfuncsLoaded() or not isSampLoaded() then return end
    while true do
        wait(0)
    end
end

sampRegisterChatCommand('cef', function()
    is_cursor_visible = not is_cursor_visible -- ����������� ���������
    showCursor(is_cursor_visible) -- ���������� ��� �������� ������
end)