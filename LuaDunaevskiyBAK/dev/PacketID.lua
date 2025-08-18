local script_name = 'PacketAnalyzer'
local script_author = 'Grok'
local script_version  = '1.0'

require 'samp.events'

local mode = 0 -- 0: выключен, 1: все ID, 2: ID и данные указанного пакета, 3: ID и содержимое всех пакетов
local targetPacketId = nil -- ID пакета для режима 2, задаётся через команду

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then
        return
    end
    sampRegisterChatCommand("packet", toggleMode)
    print("Packet Analyzer started! Use /packet [0-3] [id] to toggle modes.")
    wait(0)
end

function toggleMode(cmd)
    local args = {}
    for arg in cmd:gmatch("%S+") do table.insert(args, arg) end
    
    local newMode = tonumber(args[1]) or 0
    if newMode >= 0 and newMode <= 3 then
        mode = newMode
        if mode == 0 then
            sampAddChatMessage("Packet Analyzer: Disabled", 0xFFFFFF)
            targetPacketId = nil
        elseif mode == 1 then
            sampAddChatMessage("Packet Analyzer: Mode 1 - All Packet IDs", 0xFFFFFF)
            targetPacketId = nil
        elseif mode == 2 then
            targetPacketId = tonumber(args[2])
            if targetPacketId then
                sampAddChatMessage("Packet Analyzer: Mode 2 - Packet ID " .. targetPacketId .. " with Data", 0xFFFFFF)
            else
                sampAddChatMessage("Usage for Mode 2: /packet 2 [id]", 0xFFFFFF)
                mode = 0
            end
        elseif mode == 3 then
            sampAddChatMessage("Packet Analyzer: Mode 3 - All Packets with Data", 0xFFFFFF)
            targetPacketId = nil
        end
    else
        sampAddChatMessage("Usage: /packet [0-3] [id for mode 2] (0: off, 1: all IDs, 2: specific ID with data, 3: all data)", 0xFFFFFF)
    end
end

function onReceivePacket(id, bs)
    if mode == 0 then return true end -- Выключен
    
    -- Режим 1: Только ID всех пакетов
    if mode == 1 then
        print("Received Packet ID: " .. id)
        print("----------------------------------------------------")
    end
    
    -- Режим 2: ID и содержимое указанного пакета
    if mode == 2 and id == targetPacketId then
        local v = {}
        local byteCount = raknetBitStreamGetNumberOfBytesUsed(bs)
        for i = 1, byteCount do
            v[i] = raknetBitStreamReadInt8(bs)
        end
        print("Packet ID: " .. id .. " Data (bytes): " .. table.concat(v, ", "))
        
        -- Опционально: проверка топлива для ID 223
        if id == 223 and v[2] == 2 and v[3] == 3 then
            local fuel = v[4]
            print("Fuel Value: " .. fuel)
            sampAddChatMessage("Fuel: " .. fuel, 0xFFFFFF)
        end
        -- Опционально: проверка сытости для ID 223
        if id == 223 and v[2] == 5 then
            local satiety = v[3]
            print("Satiety Value: " .. satiety)
            sampAddChatMessage("Satiety: " .. satiety, 0xFFFF00)
        end
        print("----------------------------------------------------")
    end
    
    -- Режим 3: ID и содержимое всех пакетов
    if mode == 3 then
        local v = {}
        local byteCount = raknetBitStreamGetNumberOfBytesUsed(bs)
        for i = 1, byteCount do
            v[i] = raknetBitStreamReadInt8(bs)
        end
        print("Packet ID: " .. id .. " Data (bytes): " .. table.concat(v, ", "))
        
        -- Опционально: проверка топлива для ID 223
        if id == 223 and v[2] == 2 and v[3] == 3 then
            local fuel = v[4]
            print("Fuel Value: " .. fuel)
            sampAddChatMessage("Fuel: " .. fuel, 0xFFFFFF)
        end
        -- Опционально: проверка сытости для ID 223
        if id == 223 and v[2] == 5 then
            local satiety = v[3]
            print("Satiety Value: " .. satiety)
            sampAddChatMessage("Satiety: " .. satiety, 0xFFFF00)
        end
        print("----------------------------------------------------")
    end
    
    return true
end

function onReceiveRpc(id, bs)
    if mode == 0 then return true end -- Выключен
    
    if mode == 1 then
        print("Received RPC ID: " .. id)
        print("----------------------------------------------------")
    elseif mode == 2 and id == targetPacketId then
        local v = {}
        local byteCount = raknetBitStreamGetNumberOfBytesUsed(bs)
        for i = 1, byteCount do
            v[i] = raknetBitStreamReadInt8(bs)
        end
        print("RPC ID: " .. id .. " Data (bytes): " .. table.concat(v, ", "))
        print("----------------------------------------------------")
    elseif mode == 3 then
        local v = {}
        local byteCount = raknetBitStreamGetNumberOfBytesUsed(bs)
        for i = 1, byteCount do
            v[i] = raknetBitStreamReadInt8(bs)
        end
        print("RPC ID: " .. id .. " Data (bytes): " .. table.concat(v, ", "))
        print("----------------------------------------------------")
    end
    
    return true
end