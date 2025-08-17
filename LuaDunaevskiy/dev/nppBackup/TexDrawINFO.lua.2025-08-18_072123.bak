script_name('TextDraw Info')
script_author('YourName')
script_version('1.0')

require "lib.sampfuncs"
local sampevents = require 'samp.events' -- Используем локальную переменную, как в cook

-- Хранилище для данных TextDraw из события onShowTextDraw
local textdrawData = {}

function main()
    while not isSampAvailable() do wait(100) end
    print('Скрипт загружен. Используйте /tdinfo для просмотра информации о текстдраверах')
    sampRegisterChatCommand('tdinfo', showTextDrawInfo)
    wait(-1)
end

-- Перехват события создания TextDraw
function sampevents.onShowTextDraw(id, data)
    -- Сохраняем данные TextDraw
    textdrawData[id] = {
        modelId = data.modelId or 0,
        text = data.text or "N/A",
        positionX = data.position.x or 0,
        positionY = data.position.y or 0,
        style = data.style or 0,
        shadowColor = data.shadowColor or 0
    }
    -- Логируем создание TextDraw
    sampfuncsLog(('Textdraw create | ID: %d | ModelID: %d | Text: %s | X: %.2f | Y: %.2f | Style: %d | ShadowColor: %08X'):format(
        id, data.modelId or 0, data.text or "N/A", data.position.x or 0, data.position.y or 0, data.style or 0, data.shadowColor or 0))
end

function showTextDrawInfo()
    print('=== Информация о текстдраверах ===')
    local found = false
    for id = 0, 3047 do
        if sampTextdrawIsExists(id) then
            found = true
            print(string.format('TextDraw ID: %d', id))
            
            -- Получаем параметры через sampfuncs
            local text = sampTextdrawGetString(id)
            if text and text ~= '' then
                print('Текст: ' .. text)
            else
                print('Текст: Не удалось получить или пустой')
            end
            
            local posX, posY = sampTextdrawGetPos(id)
            print(string.format('Позиция: X: %.2f, Y: %.2f', posX, posY))
            
            local isProportional = sampTextdrawGetProportional(id)
            print('Пропорциональность: ' .. (isProportional and 'Да' or 'Нет'))
            
            local shadowColor = sampTextdrawGetShadowColor(id)
            print(string.format('Цвет тени: ARGB: %08X', shadowColor))
            
            local style = sampTextdrawGetStyle(id)
            print('Стиль: ' .. style)
            
            local alignment = sampTextdrawGetAlign(id)
            print('Выравнивание: ' .. alignment)
            
            -- Добавляем данные из events.onShowTextDraw, если они есть
            if textdrawData[id] then
                print('ModelID: ' .. textdrawData[id].modelId)
                print('Текст (из события): ' .. textdrawData[id].text)
                print(string.format('Позиция (из события): X: %.2f, Y: %.2f', textdrawData[id].positionX, textdrawData[id].positionY))
                print('Стиль (из события): ' .. textdrawData[id].style)
                print(string.format('Цвет тени (из события): ARGB: %08X', textdrawData[id].shadowColor))
            else
                print('ModelID: Неизвестно (данные события отсутствуют)')
            end
            
            print('------------------------')
        end
    end
    if not found then
        print('Активных текстдраверов не найдено')
    end
    print('=== Конец информации ===')
end