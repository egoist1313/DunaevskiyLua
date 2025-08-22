local script_name = 'PacketAnalyzer'
local script_author = 'Alex_Swift'
local script_version = '2.0.0'
require 'samp.events'
local imgui = require 'mimgui'
local encoding = require 'encoding'
local ffi = require 'ffi'
encoding.default = 'CP1251'
local u8 = encoding.UTF8
local cp1251 = encoding.CP1251

local inMode = imgui.new.int(0) -- 0: ��������, 1: ��� ID, 2: ID � ������ ���������� ������, 3: ID � ���������� ���� �������
local outMode = imgui.new.int(0) -- ���������� ��� ���������
local inTargetPacketId = imgui.new.int(0) -- ID ������ ��� ������ 2 (��������)
local outTargetPacketId = imgui.new.int(0) -- ID ������ ��� ������ 2 (���������)
local excludedPacketIds = {61, 93} -- ������, ����������� �� �����
local logFileName = 'PacketAnalyzer.log' -- ��� ����� ����
local showMenu = imgui.new.bool(false) -- ��������� ���� ImGui
local packets = {} -- ������ ������� ��� �����������
local filterPacketId = imgui.new.int(-1) -- ������ �� ID ������ (-1: ��� �������)
local excludeInput = imgui.new.char[10]() -- ���� ��� ���������� ID � ����������

-- ������ ����� ��� ���������� �������
local modeLabelsRaw = {u8('��������'), u8('��� ID'), u8('��������� ID'), u8('��� ������')}
local modeLabels = {}
for _, label in ipairs(modeLabelsRaw) do
    table.insert(modeLabels, label)
end

-- ������� ��� �������������� ������ � �������� ����� (CP1251 -> UTF-8)
function bytesToText(bytes)
    local text = {}
    for _, byte in ipairs(bytes) do
        -- ���������, �������� �� ���� ���������� �������� (ASCII 32�126 ��� CP1251 128�255 ��� ���������)
        if (byte >= 32 and byte <= 126) or (byte >= 128 and byte <= 255) then
            table.insert(text, string.char(byte))
        else
            table.insert(text, '.') -- �������� ������������ ������� �� �����
        end
    end
    local rawStr = table.concat(text)
    -- ���������� �� CP1251 � UTF-8
    local success, decodedStr = pcall(cp1251.decode, rawStr)
    if success then
        return decodedStr
    else
        return rawStr -- ���������� �������� ������, ���� ������������� �� �������
    end
end

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then
        print('[PacketAnalyzer] ������: SA:MP ��� sampfuncs �� ���������')
        return
    end
    sampRegisterChatCommand('packet', function() showMenu[0] = not showMenu[0] end)
    writeToLog('Packet Analyzer started! Use /packet to open the menu.')
    
    -- �������: ������� ���������� modeLabels ��� ��������
    for i, label in ipairs(modeLabels) do
        print(string.format('[Debug] modeLabels[%d] = %s', i - 1, label))
    end
    
    while true do
        wait(0)
        imgui.Process = showMenu[0]
    end
end

function writeToLog(message)
    local file = io.open(getWorkingDirectory() .. '/' .. logFileName, 'a')
    if file then
        file:write(os.date('[%Y-%m-%d %H:%M:%S] ') .. message .. '\n')
        file:close()
    end
end

function isPacketExcluded(id)
    for _, excludedId in ipairs(excludedPacketIds) do
        if id == excludedId then return true end
    end
    return false
end

function to_utf8(str)
    if type(str) ~= 'string' then return str end
    return u8:decode(str)
end

imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    style.WindowRounding = 15.0
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.FrameRounding = 10.0
    style.ScrollbarRounding = 10.0
    style.GrabRounding = 10.0
    style.ItemSpacing = imgui.ImVec2(8.0, 6.0)
    style.ScrollbarSize = 12.0
    style.GrabMinSize = 10.0
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
    style.AntiAliasedLines = true
    style.AntiAliasedFill = true
    style.WindowBorderSize = 0.0
    style.FrameBorderSize = 0.5
    colors[clr.Text] = ImVec4(0.95, 0.95, 0.95, 1.00)
    colors[clr.WindowBg] = ImVec4(0.10, 0.10, 0.12, 0.85)
    colors[clr.FrameBg] = ImVec4(0.15, 0.15, 0.20, 0.70)
    colors[clr.FrameBgHovered] = ImVec4(0.25, 0.50, 0.75, 0.80)
    colors[clr.FrameBgActive] = ImVec4(0.30, 0.60, 0.85, 0.90)
    colors[clr.Button] = ImVec4(0.20, 0.40, 0.70, 0.70)
    colors[clr.ButtonHovered] = ImVec4(0.25, 0.50, 0.80, 0.90)
    colors[clr.ButtonActive] = ImVec4(0.30, 0.60, 0.90, 1.00)
    colors[clr.CheckMark] = ImVec4(0.30, 0.60, 0.90, 1.00)
    colors[clr.SliderGrab] = ImVec4(0.25, 0.50, 0.80, 1.00)
    colors[clr.SliderGrabActive] = ImVec4(0.30, 0.60, 0.90, 1.00)
    colors[clr.TitleBg] = ImVec4(0.10, 0.10, 0.12, 0.85)
    colors[clr.TitleBgActive] = ImVec4(0.10, 0.10, 0.12, 0.85)
    colors[clr.TitleBgCollapsed] = ImVec4(0.10, 0.10, 0.12, 0.85)
    imgui.ShowCursor = true
end)

imgui.OnFrame(
    function() return showMenu[0] end,
    function()
        local success, err = pcall(function()
            imgui.SetNextWindowSize(imgui.ImVec2(1000, 600), imgui.Cond.FirstUseEver)
            local screen_x, screen_y = getScreenResolution()
            imgui.SetNextWindowPos(imgui.ImVec2(screen_x / 2, screen_y / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
            imgui.Begin(u8('Packet Analyzer'), showMenu, imgui.WindowFlags.NoResize)
            
            imgui.Columns(2, 'mainSplit', true) -- ����� ���������� (����� ������� - ����������, ������ - �������)
            imgui.SetColumnWidth(0, 300) -- ������ ����� �������
            
            -- ������ ���������� (����� �������)
            imgui.Text(u8('�������� ������'))
            if imgui.BeginCombo(u8('�����##inMode'), modeLabels[inMode[0] + 1]) then
                for i, label in ipairs(modeLabels) do
                    if imgui.Selectable(label, inMode[0] == i - 1) then
                        inMode[0] = i - 1
                    end
                end
                imgui.EndCombo()
            end
            if inMode[0] == 2 then
                imgui.SetNextItemWidth(100)
                imgui.InputInt(u8('ID ������##inTarget'), inTargetPacketId)
            end
            if inMode[0] == 0 then
                if imgui.Button(u8('�����##inStart'), imgui.ImVec2(100, 30)) then
                    inMode[0] = 1
                    writeToLog('��������: ����� 1 - ��� ID')
                    print('[PacketAnalyzer] ��������: ����� 1 - ��� ID')
                end
            else
                if imgui.Button(u8('����##inStop'), imgui.ImVec2(100, 30)) then
                    inMode[0] = 0
                    writeToLog('��������: ������ ��������')
                    print('[PacketAnalyzer] ��������: ������ ��������')
                end
            end
            
            imgui.Text(u8('��������� ������'))
            if imgui.BeginCombo(u8('�����##outMode'), modeLabels[outMode[0] + 1]) then
                for i, label in ipairs(modeLabels) do
                    if imgui.Selectable(label, outMode[0] == i - 1) then
                        outMode[0] = i - 1
                    end
                end
                imgui.EndCombo()
            end
            if outMode[0] == 2 then
                imgui.SetNextItemWidth(100)
                imgui.InputInt(u8('ID ������##outTarget'), outTargetPacketId)
            end
            if outMode[0] == 0 then
                if imgui.Button(u8('�����##outStart'), imgui.ImVec2(100, 30)) then
                    outMode[0] = 1
                    writeToLog('���������: ����� 1 - ��� ID')
                    print('[PacketAnalyzer] ���������: ����� 1 - ��� ID')
                end
            else
                if imgui.Button(u8('����##outStop'), imgui.ImVec2(100, 30)) then
                    outMode[0] = 0
                    writeToLog('���������: ������ ��������')
                    print('[PacketAnalyzer] ���������: ������ ��������')
                end
            end
            
            imgui.Text(u8('������������ ID:'))
            imgui.SetNextItemWidth(100)
            imgui.InputText(u8('##excludeId'), excludeInput, 10)
            if imgui.Button(u8('��������##excludeAdd'), imgui.ImVec2(100, 30)) then
                local id = tonumber(ffi.string(excludeInput))
                if id and not isPacketExcluded(id) then
                    table.insert(excludedPacketIds, id)
                    writeToLog('�������� ID � ����������: ' .. id)
                    print('[PacketAnalyzer] �������� ID � ����������: ' .. id)
                    excludeInput = imgui.new.char[10]()
                end
            end
            
            imgui.Text(u8('������ ����������� ID:'))
            imgui.BeginChild('ExcludedIDs', imgui.ImVec2(0, 100), true)
            imgui.Columns(2, 'excludedTable', true)
            imgui.SetColumnWidth(0, 100)
            imgui.SetColumnWidth(1, 150)
            imgui.Text(u8('ID')) imgui.NextColumn()
            imgui.Text(u8('��������')) imgui.NextColumn()
            imgui.Separator()
            
            for i = #excludedPacketIds, 1, -1 do -- ���������� � �������� �������
                imgui.Text(tostring(excludedPacketIds[i])) imgui.NextColumn()
                if imgui.Button(u8('�������##remove' .. i), imgui.ImVec2(80, 20)) then
                    local removedId = table.remove(excludedPacketIds, i)
                    writeToLog('������ ID �� ����������: ' .. removedId)
                    print('[PacketAnalyzer] ������ ID �� ����������: ' .. removedId)
                end
                imgui.NextColumn()
            end
            imgui.Columns(1)
            imgui.EndChild()
            
            imgui.NextColumn() -- ������� � ������ �������
            
            -- ������ � ������ ������� (��� �������� �������)
            imgui.Text(u8('������ �� ID (-1 ��� ����������):'))
            imgui.SetNextItemWidth(100)
            imgui.InputInt(u8('##filterId'), filterPacketId)
            if imgui.Button(u8('��������##clearTable'), imgui.ImVec2(100, 30)) then
                packets = {}
                writeToLog('������� ������� �������')
                print('[PacketAnalyzer] ������� ������� �������')
            end
            imgui.Separator() -- ���������� ���������
            
            -- ������� ������� (������ �������)
            imgui.BeginChild('Packets', imgui.ImVec2(0, 0), true)
            imgui.Columns(4, 'packetTable', true) -- ����������� �� 4 �������
            imgui.SetColumnWidth(0, 150) -- ��� ������
            imgui.SetColumnWidth(1, 80)  -- ID
            imgui.SetColumnWidth(2, 300) -- ������ (�����)
            imgui.SetColumnWidth(3, 300) -- �����
            imgui.Text(u8('��� ������')) imgui.NextColumn()
            imgui.Text(u8('ID')) imgui.NextColumn()
            imgui.Text(u8('������ (�����)')) imgui.NextColumn()
            imgui.Text(u8('�����')) imgui.NextColumn()
            imgui.Separator()
            
            for i, packet in ipairs(packets) do
                if filterPacketId[0] == -1 or packet.id == filterPacketId[0] then
                    local label = u8(packet.type) .. '##' .. i
                    if imgui.Selectable(label, false) and (packet.type == 'Sent Packet' or packet.type == 'Sent RPC') then
                        local bs = raknetNewBitStream()
                        for _, byte in ipairs(packet.data) do
                            raknetBitStreamWriteInt8(bs, byte)
                        end
                        if packet.type == 'Sent Packet' then
                            raknetSendPacket(packet.id, bs)
                            writeToLog('�������� ��������� Packet ID: ' .. packet.id .. ' Data: ' .. table.concat(packet.data, ', ') .. ' Text: ' .. bytesToText(packet.data))
                            print('[PacketAnalyzer] �������� ��������� Packet ID: ' .. packet.id)
                        else
                            raknetSendRpc(packet.id, bs)
                            writeToLog('�������� ��������� RPC ID: ' .. packet.id .. ' Data: ' .. table.concat(packet.data, ', ') .. ' Text: ' .. bytesToText(packet.data))
                            print('[PacketAnalyzer] �������� ��������� RPC ID: ' .. packet.id)
                        end
                        raknetDeleteBitStream(bs)
                    end
                    imgui.NextColumn()
                    imgui.Text(tostring(packet.id)) imgui.NextColumn()
                    imgui.TextWrapped(table.concat(packet.data, ', ')) imgui.NextColumn()
                    imgui.TextWrapped(u8(bytesToText(packet.data))) imgui.NextColumn()
                    imgui.Separator()
                end
            end
            imgui.Columns(1)
            imgui.EndChild()
            
            imgui.Columns(1)
            imgui.End()
        end)
        if not success then
            print('[PacketAnalyzer] ������ ���������� ImGui: ' .. tostring(err))
        end
    end
)

function onReceivePacket(id, bs)
    if inMode[0] == 0 or isPacketExcluded(id) then return true end
    local v = {}
    local byteCount = raknetBitStreamGetNumberOfBytesUsed(bs)
    for i = 1, byteCount do
        v[i] = raknetBitStreamReadInt8(bs)
    end
    local packet = {type = 'Received Packet', id = id, data = v}
    table.insert(packets, packet)
    if inMode[0] == 1 then
        writeToLog('Received Packet ID: ' .. id)
    elseif inMode[0] == 2 and id == inTargetPacketId[0] then
        writeToLog('Received Packet ID: ' .. id .. ' Data (bytes): ' .. table.concat(v, ', ') .. ' Text: ' .. bytesToText(v))
        if id == 223 and v[2] == 2 and v[3] == 3 then
            local fuel = v[4]
            writeToLog('Fuel Value: ' .. fuel)
            print('[PacketAnalyzer] Fuel Value: ' .. fuel)
        elseif id == 223 and v[2] == 5 then
            local satiety = v[3]
            writeToLog('Satiety Value: ' .. satiety)
            print('[PacketAnalyzer] Satiety Value: ' .. satiety)
        end
    elseif inMode[0] == 3 then
        writeToLog('Received Packet ID: ' .. id .. ' Data (bytes): ' .. table.concat(v, ', ') .. ' Text: ' .. bytesToText(v))
        if id == 223 and v[2] == 2 and v[3] == 3 then
            local fuel = v[4]
            writeToLog('Fuel Value: ' .. fuel)
            print('[PacketAnalyzer] Fuel Value: ' .. fuel)
        elseif id == 223 and v[2] == 5 then
            local satiety = v[3]
            writeToLog('Satiety Value: ' .. satiety)
            print('[PacketAnalyzer] Satiety Value: ' .. satiety)
        end
    end
    writeToLog('----------------------------------------------------')
    return true
end

function onReceiveRpc(id, bs)
    if inMode[0] == 0 or isPacketExcluded(id) then return true end
    local v = {}
    local byteCount = raknetBitStreamGetNumberOfBytesUsed(bs)
    for i = 1, byteCount do
        v[i] = raknetBitStreamReadInt8(bs)
    end
    local packet = {type = 'Received RPC', id = id, data = v}
    table.insert(packets, packet)
    if inMode[0] == 1 then
        writeToLog('Received RPC ID: ' .. id)
    elseif inMode[0] == 2 and id == inTargetPacketId[0] then
        writeToLog('Received RPC ID: ' .. id .. ' Data (bytes): ' .. table.concat(v, ', ') .. ' Text: ' .. bytesToText(v))
    elseif inMode[0] == 3 then
        writeToLog('Received RPC ID: ' .. id .. ' Data (bytes): ' .. table.concat(v, ', ') .. ' Text: ' .. bytesToText(v))
    end
    writeToLog('----------------------------------------------------')
    return true
end

function onSendPacket(id, bs)
    if outMode[0] == 0 or isPacketExcluded(id) then return true end
    local v = {}
    local byteCount = raknetBitStreamGetNumberOfBytesUsed(bs)
    for i = 1, byteCount do
        v[i] = raknetBitStreamReadInt8(bs)
    end
    local packet = {type = 'Sent Packet', id = id, data = v}
    table.insert(packets, packet)
    if outMode[0] == 1 then
        writeToLog('Sent Packet ID: ' .. id)
    elseif outMode[0] == 2 and id == outTargetPacketId[0] then
        writeToLog('Sent Packet ID: ' .. id .. ' Data (bytes): ' .. table.concat(v, ', ') .. ' Text: ' .. bytesToText(v))
    elseif outMode[0] == 3 then
        writeToLog('Sent Packet ID: ' .. id .. ' Data (bytes): ' .. table.concat(v, ', ') .. ' Text: ' .. bytesToText(v))
    end
    writeToLog('----------------------------------------------------')
    return true
end

function onSendRpc(id, bs)
    if outMode[0] == 0 or isPacketExcluded(id) then return true end
    local v = {}
    local byteCount = raknetBitStreamGetNumberOfBytesUsed(bs)
    for i = 1, byteCount do
        v[i] = raknetBitStreamReadInt8(bs)
    end
    local packet = {type = 'Sent RPC', id = id, data = v}
    table.insert(packets, packet)
    if outMode[0] == 1 then
        writeToLog('Sent RPC ID: ' .. id)
    elseif outMode[0] == 2 and id == outTargetPacketId[0] then
        writeToLog('Sent RPC ID: ' .. id .. ' Data (bytes): ' .. table.concat(v, ', ') .. ' Text: ' .. bytesToText(v))
    elseif outMode[0] == 3 then
        writeToLog('Sent RPC ID: ' .. id .. ' Data (bytes): ' .. table.concat(v, ', ') .. ' Text: ' .. bytesToText(v))
    end
    writeToLog('----------------------------------------------------')
    return true
end