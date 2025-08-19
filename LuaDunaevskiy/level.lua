local script_name = 'Level'
local script_version = '07/03/2025'
local hook = require 'hooks'
local ffi = require('ffi')
local gameHandle = getModuleHandle('samp.dll')

function getSampVersion()
    if gameHandle == 0 then
        sampAddChatMessage('{FF0000}Не удалось определить версию SA:MP', -1)
        print('{FF0000}Не удалось определить версию SA:MP')
        thisScript():unload()
        return nil
    else
        local cast = ffi.cast('long*', gameHandle + 60)[0]
        local isR1 = ffi.cast('unsigned int*', gameHandle + cast + 40)[0] ~= 836816
        if isR1 then
            print("Detected SA:MP R1 (0.3.7)")
            return 'R1'
        else
            print("Detected SA:MP R3 (0.3.DL)")
            return 'R3'
        end
    end
end

function main()
    local base = gameHandle
    local offset
    local sampVersion = getSampVersion()

    -- Если версия не определена (например, из-за выгрузки), выходим
    if not sampVersion then return end

    -- Устанавливаем offset в зависимости от версии
    if sampVersion == "R1" then
        offset = 0x70F4E
        sampAddChatMessage("{FFFFFF}SAMP Version: {00FF00}R1 ", -1)
    elseif sampVersion == "R3" then
        offset = 0x74E3F
        sampAddChatMessage("{FFFFFF}SAMP Version: {00FF00}R3 ", -1)
    end

    -- Настраиваем хук для renderNick
    renderNick = hook.call.new(
        'int(__cdecl *)(char* buf, const char* fmt, const char* nick, int id, int score, int ping)',
        renderNick,
        base + offset
    )
    
    wait(-1)
end

function renderNick(buf, fmt, nick, id)
    local score = sampGetPlayerScore(id) or 0
    local ping = sampGetPlayerPing(id) or 0
    return renderNick(buf, '%s [%d] \n {00FF00} [lvl: %d] [ping: %d]', nick, id, score, ping)
end