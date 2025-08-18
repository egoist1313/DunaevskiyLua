script_name("MouseChecker")
script_author("YourName")
script_version("1.0")

require "lib.moonloader"
require "sampfuncs"
local imgui = require "imgui"

local lastState = nil -- Для отслеживания изменения состояния

function main()
    -- Проверяем, загружен ли SAMP
    while not isSampAvailable() do
        print("Ожидание загрузки SA-MP...")
        wait(100)
    end
    
    print("MouseChecker запущен!")
    
    -- Основной цикл
    while true do
        local currentState = isMouseActive()
        -- Выводим сообщение только при изменении состояния
        if currentState ~= lastState then
            if currentState then
                sampAddChatMessage("{00FF00}[MouseChecker]: {FFFFFF}Курсор мыши активен!", -1)
            else
                sampAddChatMessage("{FF0000}[MouseChecker]: {FFFFFF}Курсор мыши неактивен!", -1)
            end
            lastState = currentState
        end
        wait(500) -- Проверка каждые 500 мс
    end
end

-- Функция для проверки активности курсора
function isMouseActive()
    return imgui.GetIO().WantCaptureMouse -- ImGui захватывает мышь
        or sampIsChatInputActive()        -- Чат активен
        or sampIsDialogActive()           -- Диалог активен
        or isPauseMenuActive()            -- Меню паузы активно
end