-- DialogLogger.lua
local sampev = require 'lib.samp.events' -- Подключаем библиотеку для работы с событиями SA-MP

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then
        return -- Ждём загрузки SA-MP и SAMPFUNCS
    end
    
    while not isSampAvailable() do
        wait(0) -- Ждём полной доступности SA-MP
    end
    
    print("DialogLogger: Скрипт загружен. Логирование диалогов начато.")
    sampAddChatMessage("[DialogLogger] Скрипт запущен. Смотрите консоль MoonLoader для логов.", 0x00FF00)
end

-- Обработка события показа диалога
function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
    -- Выводим информацию о диалоге в консоль
    print("=== Новый диалог найден ===")
    print("ID диалога: " .. dialogId)
    print("Стиль диалога: " .. style)
    print("Заголовок: " .. title)
    print("Кнопка 1: " .. button1)
    print("Кнопка 2: " .. button2)
    print("Текст диалога: " .. text)
    print("========================")
    
    -- Возвращаем true, чтобы не блокировать дальнейшую обработку диалога
    return true
end

-- Обработка ответа на диалог (опционально)
function sampev.onDialogResponse(dialogId, button, listItem, inputText)
    print("=== Ответ на диалог ===")
    print("ID диалога: " .. dialogId)
    print("Нажатая кнопка: " .. button .. " (0 - кнопка 2, 1 - кнопка 1)")
    print("Выбранный пункт: " .. listItem)
    print("Введённый текст: " .. inputText)
    print("======================")
end