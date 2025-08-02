-- Автор: AlexDunaevskiy, 2025  https://t.me/+VxorOlng8OcwMjUy
-- Скрипт "cook" для готовки в SA-MP 
local script_name = 'cook'
local script_version = '17/03/2025'

local sampfuncs = require 'sampfuncs'
local sampevents = require 'samp.events'

-- Глобальные переменные
local altKey = 21   
local scriptActive = false
local selectedDish = 0 -- Номер выбранной строчки 
local waitAfterCooking = false
local waitStartTime = 0
local isSpecialMode = false -- Флаг для специального режима (/cook 0)
local specialModeStep = 0 -- Шаг выполнения в специальном режиме
local lastDialogId = -1 -- Для предотвращения повторной обработки диалога

local function setKeyState(key, isEnabled)
    local state = isEnabled and 255 or 0
    setGameKeyState(key, state)
end

local function pressAlt()
    setKeyState(altKey, true)
    wait(10)
    setKeyState(altKey, false)
end

function main()
    if not isSampfuncsLoaded() then return end
    if not isSampLoaded() then return end

    while not isSampAvailable() do
        wait(100)
    end

    sampRegisterChatCommand("cook", function(arg)
        if not arg or arg == "" then
            if scriptActive then
                scriptActive = false
                setKeyState(altKey, false)
                waitAfterCooking = false
                postDialogDelay = false
                dialogProcessing = false
                lastDialogId = -1
                sampAddChatMessage("[Cook] Остановлен", 0xFF0000)
            else
                sampAddChatMessage("[Cook] Введите /cook 0-19 для выбора блюда", 0xFFFF00)
            end
            return
        end

        local dishNumber = tonumber(arg)
        if not dishNumber or dishNumber < 0 or dishNumber > 19 then
            sampAddChatMessage("[Cook] Неверный номер блюда. Используйте /cook 0-19", 0xFF0000)
            return
        end

        scriptActive = not scriptActive
        if scriptActive then
            isSpecialMode = (dishNumber == 0)
            selectedDish = isSpecialMode and 0 or (dishNumber - 1)
            sampAddChatMessage("[Cook] Активирован для блюда #" .. dishNumber .. (isSpecialMode and " (спец. режим)" or ""), 0x00FF00)
        else
            setKeyState(altKey, false)
            waitAfterCooking = false
            postDialogDelay = false
            dialogProcessing = false
            lastDialogId = -1
            sampAddChatMessage("[Cook] Остановлен", 0xFF0000)
        end
    end)

    while true do
        wait(0)

        if scriptActive then
            local timestamp = os.date("%H:%M:%S")
            if waitAfterCooking then
                if os.clock() - waitStartTime >= 6.5 then
                    if isSpecialMode then
                        sampSendChat("/accept grib")
                        wait(1000)
                    end
                    waitAfterCooking = false
                end
            elseif postDialogDelay then
                if os.clock() - delayStartTime >= 1 then
                    postDialogDelay = false
                    dialogProcessing = false
                end
            elseif not dialogProcessing then
                if not sampIsDialogActive() then
                    pressAlt()
                    wait(500)
                end

                local dialogProcessed = false
                for i = 1, 50 do
                    if sampIsDialogActive() then
                        dialogProcessed = true
                        dialogProcessing = true
                        break
                    end
                    wait(100)
                end
            end
        else
            wait(100)
        end
    end
end

-- Обработка диалогов
function sampevents.onShowDialog(id, style, title, button1, button2, text)
    if not scriptActive then return true end

    local timestamp = os.date("%H:%M:%S")

    if id == lastDialogId then
        return true
    end

    if style == 0 and title == "Кухня" and button1 == "Заплатить" and button2 == "Отмена" and text:find("Аренда кухни на 600 секунд") then
        sampSendDialogResponse(id, 1, -1, "")
        lastDialogId = id
        return false
    end

    if style == 5 and title == "Кухня" and button1 == "Ок" and button2 == "Отмена" and text:find("Блюдо") then
        sampSendDialogResponse(id, 1, selectedDish, "")
        lastDialogId = id
        return false
    end

    if style == 0 and title == "Кухня" and button1 == "Начать" and button2 == "Назад" and text:find("Блюдо:") then
        sampSendDialogResponse(id, 1, -1, "")
        waitAfterCooking = true
        waitStartTime = os.clock()
        postDialogDelay = true
        delayStartTime = os.clock()
        lastDialogId = id
        return false
    end

    return true
end

-- Обработка сообщений сервера
function sampevents.onServerMessage(color, text)
    if scriptActive then
        if not isSpecialMode and (text:find("Нет места") or text:find("У вас нет нужных ингредиентов")) then
            scriptActive = false
            waitAfterCooking = false
            setKeyState(altKey, false)
            sampAddChatMessage("[Cook] Остановлен", 0xFF0000)
        end
    end
end