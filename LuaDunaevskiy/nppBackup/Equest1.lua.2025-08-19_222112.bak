-- Автор: AlexDunaevskiy, 2025 https://t.me/AlexDunaevskiy
local script_name = 'QuestChecker'
local script_version = '14/08/2025'
local enableLogging = false -- true - логи включены, false - логи отключены
local imgui = require 'imgui'
local encoding = require 'encoding'
local json = require 'dkjson'
local vkeys = require 'vkeys'
local ffi = require 'ffi'
local fa = require 'fAwesome5'
local sampev
local success, result = pcall(function() return require 'lib.samp.events' end)
if success then
    sampev = result
else
    if enableLogging then
        print("[QuestChecker] Error: Failed to load lib.samp.events")
    end
    return
end
local MessageSender = require 'lib.messagesender'
encoding.default = 'CP1251'
local u8 = encoding.UTF8
local windowTitle = fa.ICON_FA_CHECK_SQUARE .. " QuestChecker"
local questTitle = fa.ICON_FA_LIST .. " " .. u8'Не выполненные задания:'
local showQuests = imgui.ImBool(true)
local showNets = imgui.ImBool(true)
local showSatiety = imgui.ImBool(true)
local eatKey = imgui.ImInt(vkeys.VK_F3)
local eatKeySelecting = imgui.ImBool(false)
local isScriptActive = true
local playerNickname = nil
local state = {
    isFullyConnected = false,
    isWindowVisible = false,
    customFont = nil,
    faFont = nil,
    showWindow = imgui.ImBool(true),
    showSettings = imgui.ImBool(false),
    showFoodSettings = imgui.ImBool(false),
    config = {
        position = { x = 0.02, y = 0.90 },
        bgColor = { 0.0, 1.0, 1.0, 0.2 },
        textColor = { 0.0, 0.0, 0.0, 1.0 },
        questFontSize = 18.0,
        netsFontSize = 18.0,
        satietyFontSize = 18.0,
        foodSettings = {},
        eatNowSettings = {},
        eatKey = vkeys.VK_F3,
        showQuests = true,
        showNets = true,
        showSatiety = true
    },
    configFile = "moonloader\\LuaDunaevskiy\\config\\Equest\\QuestChecker.json",
    questReplacements = {},
    shouldRedraw = false,
    questData = {},
    previousQuestData = {},
    questCount = 0,
    waitingForDialog1013 = false,
    lastEquestSendTime = 0,
    timerExpired = false,
    lastQuestCompletionTime = nil,
    dailyStreak = 0,
    previousDailyStreak = 0,
    waitingForDailyResponse = false,
    dailyMessagesProcessed = 0,
    netData = {},
    fishScriptLoaded = false,
    satietyValue = 0,
    autoEatEnabled = false,
    foodStock = {},
    eatenFood = {},
    foodList = {
        {command = "grib", name = "{FFFFFF}Готовые грибы", satietyAdd = 10, maxSatiety = 50, dialogBased = false},
        {command = "fish", name = "{FFFFFF}Жареная рыба", satietyAdd = 35, maxSatiety = 75, dialogBased = false},
        {command = "beef", name = "{FFFFFF}Жареная говядина", satietyAdd = 35, maxSatiety = 75, dialogBased = true},
        {command = "deer", name = "{FFFFFF}Жареное мясо оленя", satietyAdd = 35, maxSatiety = 75, dialogBased = true},
        {command = "turtle", name = "{FFFFFF}Тушеное черепашье мясо", satietyAdd = 35, maxSatiety = 75, dialogBased = true},
        {command = "shark", name = "{FFFFFF}Жареное акулье мясо", satietyAdd = 35, maxSatiety = 75, dialogBased = true},
        {command = "turtle_ragu", name = "{FFFFFF}Рагу из черепашьего мяса", satietyAdd = 65, maxSatiety = 150, dialogBased = true},
        {command = "beef_mushroom", name = "{FFFFFF}Говядина с грибами", satietyAdd = 75, maxSatiety = 150, dialogBased = true},
        {command = "deer_mushroom", name = "{FFFFFF}Оленина с грибами", satietyAdd = 75, maxSatiety = 150, dialogBased = true},
        {command = "shark_soup", name = "{FFFFFF}Уха с мясом акулы", satietyAdd = 85, maxSatiety = 150, dialogBased = true},
        {command = "sea_dish", name = "{FFFFFF}Морское блюдо", satietyAdd = 25, maxSatiety = 150, dialogBased = true},
        {command = "trout_soup", name = "{FFFFFF}Уха из форели", satietyAdd = 30, maxSatiety = 150, dialogBased = true},
        {command = "pike_soup", name = "{FFFFFF}Уха из щуки", satietyAdd = 35, maxSatiety = 150, dialogBased = true},
        {command = "fish_soup", name = "{FFFFFF}Рыбная похлебка", satietyAdd = 40, maxSatiety = 150, dialogBased = true},
        {command = "carp", name = "{FFFFFF}Запечённый карп", satietyAdd = 50, maxSatiety = 150, dialogBased = true},
        {command = "squid", name = "{FFFFFF}Жареный кальмар", satietyAdd = 65, maxSatiety = 150, dialogBased = true},
        {command = "taco", name = "{FFFFFF}Рыбные тако", satietyAdd = 65, maxSatiety = 150, dialogBased = true},
        {command = "pudding", name = "{FFFFFF}Морской пенный пудинг", satietyAdd = 80, maxSatiety = 150, dialogBased = true},
        {command = "pufferfish", name = "{FFFFFF}Жареная рыба-еж", satietyAdd = 150, maxSatiety = 150, dialogBased = true}
    },
    hasInitializedFoodStock = false,
    lastCommandTime = 0,
    lastEatUpdateTime = 0,
    EAT_UPDATE_INTERVAL = 1800000,
    expectingEatDialog = false,
    selectedFoodCommand = nil,
    waitingForConfirmationDialog = false,
    messageSenderInitialized = false,
    isChatOpen = false,
    chatCloseTime = nil,
    isDraggingEnabled = false,
    waitingForDialog1018 = false,
    waitingForDialog1014 = false,
    currentQuestIndex = 0,
    unknownQuests = {},
    questUpdateTime = nil,
    timezoneOffset = nil,
    canAutoEat = true,
    satietyPacketReceived = false,
    satietyPacketWaitStart = nil,
    SATIETY_PACKET_TIMEOUT = 5000,
    lastNetDataStatus = nil,
    netTimeLeft = nil,
    lastNetTimeUpdate = 0,
    NET_TIME_UPDATE_INTERVAL = 1000
}
for _, food in ipairs(state.foodList) do
    state.foodStock[food.command] = 0
    state.eatenFood[food.command] = 0
    state.config.foodSettings[food.command] = imgui.ImBool(false)
    state.config.eatNowSettings[food.command] = imgui.ImBool(false)
end

local function handleJsonFile(filePath, data)
    local success, result = pcall(function()
        if data then
            local dir = filePath:match("^(.*[\\/])")
            if dir and not doesDirectoryExist(dir) then
                createDirectory(dir)
            end
            local tempFile = filePath .. ".tmp"
            local file = io.open(tempFile, "w")
            if file then
                local encoded = json.encode(data, { indent = true })
                file:write(encoded)
                file:close()
                local renameSuccess = os.rename(tempFile, filePath)
                if not renameSuccess then
                    local mainFile = io.open(filePath, "w")
                    if mainFile then
                        mainFile:write(encoded)
                        mainFile:close()
                    else
                        if enableLogging then
                            print("[QuestChecker] Error: Unable to write to " .. filePath)
                        end
                    end
                    os.remove(tempFile)
                end
                return true
            else
                if enableLogging then
                    print("[QuestChecker] Error: Unable to open " .. tempFile .. " for writing")
                end
                return false
            end
        else
            if doesFileExist(filePath) then
                local file = io.open(filePath, "r")
                if file then
                    local content = file:read("*all")
                    file:close()
                    if content and content ~= "" then
                        local decoded = json.decode(content)
                        if type(decoded) == "table" then
                            return decoded
                        else
                            if enableLogging then
                                print("[QuestChecker] Error: Invalid JSON content in " .. filePath)
                            end
                        end
                    else
                        if enableLogging then
                            print("[QuestChecker] Error: Empty or invalid file content in " .. filePath)
                        end
                    end
                else
                    if enableLogging then
                        print("[QuestChecker] Error: Unable to open " .. filePath .. " for reading")
                    end
                end
            end
            return nil
        end
    end)
    if not success and enableLogging then
        print("[QuestChecker] Error in handleJsonFile: " .. tostring(result))
    end
    return success and result or (data and false or nil)
end

function table.copy(t)
    local u = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            u[k] = table.copy(v)
        else
            u[k] = v
        end
    end
    return u
end

local function updateLastCommandTime()
    state.lastCommandTime = os.time() * 1000
end

local function getKeyName(vkCode)
    local success, name = pcall(function()
        return vkeys.id_to_name(vkCode)
    end)
    return success and name or u8"Неизвестно"
end

local function updatePlayerNickname()
    local success, nickname = pcall(function()
        return sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))
    end)
    if success then
        playerNickname = nickname
    else
        playerNickname = nil
        if enableLogging then
            print("[QuestChecker] Error getting player nickname: " .. tostring(nickname))
        end
    end
end

local function selectBestFood()
    local bestFood = nil
    local maxStock = 0
    for _, food in ipairs(state.foodList) do
        local isEnabled = state.config.foodSettings[food.command].v
        local stock = state.foodStock[food.command] or 0
        local threshold = food.maxSatiety - food.satietyAdd
        local canEat = state.satietyValue <= threshold and (state.satietyValue + food.satietyAdd) <= food.maxSatiety
        if isEnabled and stock > 10 and canEat and stock > maxStock then
            maxStock = stock
            bestFood = food
        end
    end
    return bestFood
end

local function selectBestFoodForEatNow()
    local bestFood = nil
    local maxStock = 0
    for _, food in ipairs(state.foodList) do
        local isEnabled = state.config.eatNowSettings[food.command].v
        local stock = state.foodStock[food.command] or 0
        if isEnabled and stock > 0 and stock > maxStock then
            maxStock = stock
            bestFood = food
        end
    end
    return bestFood
end

local function sendEatCommandNow(food)
    if not state.messageSenderInitialized or not isScriptActive then return end
    if state.isChatOpen then
        local timeout = os.time() + 5
        while state.isChatOpen and os.time() < timeout and isScriptActive do
            wait(100)
        end
        if state.isChatOpen then return end
    end
    if food.dialogBased then
        state.expectingEatDialog = true
        state.selectedFoodCommand = food.command
        MessageSender:sendChatMessage("/eat")
    else
        MessageSender:sendChatMessage("/eat " .. food.command)
        state.eatenFood[food.command] = state.eatenFood[food.command] + 1
        state.foodStock[food.command] = state.foodStock[food.command] - 1
    end
    updateLastCommandTime()
end

local function eatBestFoodNow()
    local bestFood = selectBestFoodForEatNow()
    if bestFood then
        sendEatCommandNow(bestFood)
    end
end

local function sendEatCommand()
    if not state.messageSenderInitialized or not isScriptActive then return end
    if state.isChatOpen then
        local timeout = os.time() + 5
        while state.isChatOpen and os.time() < timeout and isScriptActive do
            wait(100)
        end
        if state.isChatOpen then return end
    end
    state.expectingEatDialog = true
    state.waitingForConfirmationDialog = false
    MessageSender:sendChatMessage("/eat")
    wait(2500)
    updateLastCommandTime()
    state.lastEatUpdateTime = os.time() * 1000
end

local function sendEquestCommand()
    if not state.messageSenderInitialized or not isScriptActive then return end
    if state.isChatOpen then
        local timeout = os.time() + 5
        while state.isChatOpen and os.time() < timeout and isScriptActive do
            wait(100)
        end
        if state.isChatOpen then return end
    end
    MessageSender:sendChatMessage("/equest")
    state.waitingForDialog1013 = true
    state.lastEquestSendTime = os.time() * 1000
    updateLastCommandTime()
end

local function saveConfig()
    state.config.showQuests = showQuests.v
    state.config.showNets = showNets.v
    state.config.showSatiety = showSatiety.v
    state.config.eatKey = eatKey.v
    local configToSave = {
        position = state.config.position,
        bgColor = state.config.bgColor,
        textColor = state.config.textColor,
        questFontSize = state.config.questFontSize,
        netsFontSize = state.config.netsFontSize,
        satietyFontSize = state.config.satietyFontSize,
        showQuests = state.config.showQuests,
        showNets = state.config.showNets,
        showSatiety = state.config.showSatiety,
        eatKey = state.config.eatKey,
        foodSettings = {},
        eatNowSettings = {}
    }
    for _, food in ipairs(state.foodList) do
        configToSave.foodSettings[food.command] = state.config.foodSettings[food.command].v
        configToSave.eatNowSettings[food.command] = state.config.eatNowSettings[food.command].v
    end
    handleJsonFile(state.configFile, configToSave)
end

local function loadConfig()
    local defaultConfig = {
        bgColor = { 0.0, 1.0, 1.0, 0.2 },
        textColor = { 0.0, 0.0, 0.0, 1.0 },
        questFontSize = 18.0,
        netsFontSize = 18.0,
        satietyFontSize = 18.0,
        position = { x = 0.02, y = 0.90 },
        foodSettings = {},
        eatNowSettings = {},
        eatKey = vkeys.VK_F3,
        showQuests = true,
        showNets = true,
        showSatiety = true
    }
    for _, food in ipairs(state.foodList) do
        defaultConfig.foodSettings[food.command] = false
        defaultConfig.eatNowSettings[food.command] = false
    end
    local result = handleJsonFile(state.configFile)
    if result and type(result) == "table" then
        for k, v in pairs(defaultConfig) do
            if result[k] == nil or type(result[k]) ~= type(v) then
                result[k] = v
            elseif type(v) == "table" and type(result[k]) == "table" then
                for sk, sv in pairs(v) do
                    if result[k][sk] == nil or type(result[k][sk]) ~= type(sv) then
                        result[k][sk] = sv
                    end
                end
            end
        end
        state.config = result
    else
        state.config = defaultConfig
    end
    eatKey.v = state.config.eatKey
    for _, food in ipairs(state.foodList) do
        local foodSetting = state.config.foodSettings[food.command]
        local eatNowSetting = state.config.eatNowSettings[food.command]
        state.config.foodSettings[food.command] = imgui.ImBool(type(foodSetting) == "boolean" and foodSetting or false)
        state.config.eatNowSettings[food.command] = imgui.ImBool(type(eatNowSetting) == "boolean" and eatNowSetting or false)
    end
    showQuests.v = type(state.config.showQuests) == "boolean" and state.config.showQuests or true
    showNets.v = type(state.config.showNets) == "boolean" and state.config.showNets or true
    showSatiety.v = type(state.config.showSatiety) == "boolean" and state.config.showSatiety or true
    state.autoEatEnabled = false
    for _, food in ipairs(state.foodList) do
        if state.config.foodSettings[food.command].v then
            state.autoEatEnabled = true
            break
        end
    end
end

local function applySettings()
    if not state.isFullyConnected then return end
    state.autoEatEnabled = false
    for _, food in ipairs(state.foodList) do
        if state.config.foodSettings[food.command].v then
            state.autoEatEnabled = true
            break
        end
    end
    state.config.showQuests = showQuests.v
    state.config.showNets = showNets.v
    state.config.showSatiety = showSatiety.v
    state.config.eatKey = eatKey.v
    saveConfig()
    state.showSettings.v = false
    state.showFoodSettings.v = false
    state.isDraggingEnabled = false
    state.shouldRedraw = true
end

local function areTablesEqual(t1, t2)
    if #t1 ~= #t2 then return false end
    for i, v in ipairs(t1) do
        if v ~= t2[i] then return false end
    end
    return true
end

local function startTimer()
    state.timerExpired = false
    lua_thread.create(function()
        if not isScriptActive then return end
        wait(90000)
        if isScriptActive then
            state.timerExpired = true
        end
    end)
end

local function getTimezoneOffset()
    if state.timezoneOffset then return state.timezoneOffset end
    local success, result = pcall(function()
        ffi.cdef[[
            typedef struct {
                int32_t Bias;
                wchar_t StandardName[32];
                char padding[128];
            } TIME_ZONE_INFORMATION;
            uint32_t GetTimeZoneInformation(TIME_ZONE_INFORMATION *lpTimeZoneInformation);
        ]]
        local tzInfo = ffi.new("TIME_ZONE_INFORMATION")
        local result = ffi.C.GetTimeZoneInformation(tzInfo)
        if result ~= 0xFFFFFFFF then
            return tonumber(tzInfo.Bias) or 0
        end
        return 0
    end)
    state.timezoneOffset = success and result or 0
    if enableLogging and not success then
        print("[QuestChecker] Error getting timezone offset: " .. tostring(result))
    end
    return state.timezoneOffset
end

local function dateToMinutes(dateStr)
    if not dateStr then return nil end
    local success, result = pcall(function()
        local year, month, day, hour, min = dateStr:match("(%d+)/(%d+)/(%d+)%s+(%d+):(%d+)")
        if not year then return nil end
        local timeTable = {
            year = tonumber(year),
            month = tonumber(month),
            day = tonumber(day),
            hour = tonumber(hour),
            min = tonumber(min),
            sec = 0
        }
        local seconds = os.time(timeTable)
        return math.floor(seconds / 60)
    end)
    if enableLogging and not success then
        print("[QuestChecker] Error parsing date: " .. tostring(result))
    end
    return success and result or nil
end

local function formatTime(minutes)
    local hours = math.floor(minutes / 60)
    local mins = minutes % 60
    return string.format("%02d:%02d", hours, mins)
end

local function getNetTimeLeft()
    if not playerNickname or not state.netData[playerNickname] then
        local currentStatus = "invalid"
        if state.lastNetDataStatus ~= currentStatus and enableLogging then
            print("[QuestChecker] No net data for nickname: " .. (playerNickname or "nil"))
            state.lastNetDataStatus = currentStatus
        end
        return nil
    end
    local netInfo = state.netData[playerNickname]
    if not netInfo or not netInfo.time or not netInfo.duration then
        local currentStatus = "invalid"
        if state.lastNetDataStatus ~= currentStatus and enableLogging then
            print("[QuestChecker] Invalid netInfo for " .. playerNickname)
            state.lastNetDataStatus = currentStatus
        end
        return nil
    end
    local currentTime = math.floor(os.time() / 60)
    if currentTime - netInfo.time > 4320 then
        local currentStatus = "outdated"
        if state.lastNetDataStatus ~= currentStatus and enableLogging then
            print("[QuestChecker] Net data for " .. playerNickname .. " is outdated (age: " .. (currentTime - netInfo.time) .. " minutes)")
            state.lastNetDataStatus = currentStatus
        end
        return nil
    end
    local currentStatus = "valid"
    if state.lastNetDataStatus ~= currentStatus then
        state.lastNetDataStatus = currentStatus
    end
    local endTime = netInfo.time + netInfo.duration * 60
    local timeLeft = endTime - currentTime
    if timeLeft < 0 then
        return "Сбор сети!"
    else
        local hours = math.floor(timeLeft / 60)
        local mins = timeLeft % 60
        return string.format("Сети: %02d:%02d", hours, mins)
    end
end

local function safeU8(str)
    if type(str) ~= "string" or str == "" then
        return str or ""
    end
    local success, result = pcall(u8, str)
    if enableLogging and not success then
        print("[QuestChecker] Error in safeU8: " .. tostring(result))
    end
    return success and result or str
end

function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
    if not isScriptActive then return true end
    if enableLogging then
        print("[QuestChecker] Dialog ID: " .. dialogId .. ", Title: " .. (title or "nil") .. ", Style: " .. style)
        if text and text ~= "" then
            print("[QuestChecker] Dialog text: " .. text)
        end
    end
    if title == "{FFFFFF}Еда" and style == 5 then
        local success = pcall(function()
            for _, food in ipairs(state.foodList) do
                local cleanName = food.name:gsub("{.-}", "")
                local escapedName = cleanName:gsub("[-]", "[-–—]")
                local pattern = escapedName .. "%s*{.-}(%d+)"
                local count = text and text:match(pattern) or nil
                if count then
                    state.foodStock[food.command] = tonumber(count) or 0
                    state.eatenFood[food.command] = 0
                elseif enableLogging then
                    print("[QuestChecker] Warning: No match for food " .. cleanName .. " in dialog")
                end
            end
            state.hasInitializedFoodStock = true
        end)
        if not success and enableLogging then
            print("[QuestChecker] Error parsing food dialog: " .. tostring(success))
        end
        if state.expectingEatDialog and state.selectedFoodCommand then
            local selectedIndex = -1
            local dialogIndex = 0
            for line in (text or ""):gmatch("[^\r\n]+") do
                if dialogIndex > 0 then
                    for _, food in ipairs(state.foodList) do
                        local cleanName = food.name:gsub("{.-}", "")
                        local escapedName = cleanName:gsub("[-]", "[-–—]")
                        if food.command == state.selectedFoodCommand and line:match(escapedName) then
                            selectedIndex = dialogIndex - 1
                            break
                        end
                    end
                end
                if selectedIndex >= 0 then break end
                dialogIndex = dialogIndex + 1
            end
            if selectedIndex >= 0 then
                if enableLogging then
                    print("[QuestChecker] Sending response for food selection: Dialog ID " .. dialogId .. ", Index " .. selectedIndex)
                end
                sampSendDialogResponse(dialogId, 1, selectedIndex, -1)
                state.waitingForConfirmationDialog = true
            else
                if enableLogging then
                    print("[QuestChecker] Failed to find food index for " .. state.selectedFoodCommand)
                end
                state.selectedFoodCommand = nil
            end
            state.expectingEatDialog = false
            return false
        elseif state.expectingEatDialog then
            state.expectingEatDialog = false
            return false
        else
            return true
        end
    end
    if state.waitingForConfirmationDialog and state.selectedFoodCommand then
        local selectedFood = nil
        for _, food in ipairs(state.foodList) do
            if food.command == state.selectedFoodCommand then
                selectedFood = food
                break
            end
        end
        if selectedFood then
            local cleanTitle = title and title:gsub("{.-}", "") or ""
            local cleanFoodName = selectedFood.name:gsub("{.-}", "")
            if cleanTitle == cleanFoodName then
                if enableLogging then
                    print("[QuestChecker] Sending confirmation for " .. cleanFoodName .. ", Dialog ID " .. dialogId)
                end
                sampSendDialogResponse(dialogId, 1, -1, -1)
                state.eatenFood[selectedFood.command] = state.eatenFood[selectedFood.command] + 1
                state.foodStock[selectedFood.command] = state.foodStock[selectedFood.command] - 1
                state.selectedFoodCommand = nil
                state.waitingForConfirmationDialog = false
                return false
            end
        else
            if enableLogging then
                print("[QuestChecker] No matching food for command " .. (state.selectedFoodCommand or "nil"))
            end
            state.waitingForConfirmationDialog = false
            state.selectedFoodCommand = nil
            return true
        end
    end
    if dialogId == 1013 and state.waitingForDialog1013 then
        local newQuestData = {}
        local newQuestCount = 0
        state.unknownQuests = {}
        local updateTimeStr = title and title:match("Обновление заданий: {6AB1FF}(%d+/%d+/%d+%s+%d+:%d+)")
        if updateTimeStr then
            local updateMinutes = dateToMinutes(updateTimeStr)
            if updateMinutes then
                state.questUpdateTime = updateMinutes - 180
            end
        end
        local dialogIndex = 0
        local questIndex = -1
        for line in (text or ""):gmatch("[^\r\n]+") do
            if dialogIndex > 0 then
                questIndex = questIndex + 1
                if line:find("%[Не выполнено%]") then
                    local success, taskName = pcall(function()
                        return line:gsub("{.-}", ""):match("^(.+)%s+%d+ из %d+") or line:gsub("{.-}", "")
                    end)
                    if success and taskName then
                        local replacement = state.questReplacements[taskName]
                        if replacement then
                            table.insert(newQuestData, replacement)
                        else
                            table.insert(newQuestData, taskName)
                            table.insert(state.unknownQuests, {index = questIndex, name = taskName})
                        end
                        newQuestCount = newQuestCount + 1
                    elseif enableLogging then
                        print("[QuestChecker] Error parsing quest line: " .. tostring(taskName))
                    end
                end
            end
            dialogIndex = dialogIndex + 1
        end
        if newQuestCount ~= state.questCount or not areTablesEqual(newQuestData, state.questData) then
            state.previousQuestData = state.questData
            state.questData = newQuestData
            state.questCount = newQuestCount
            state.shouldRedraw = true
        end
        state.waitingForDialog1013 = false
        if #state.unknownQuests > 0 then
            state.currentQuestIndex = 1
            local selectedIndex = state.unknownQuests[state.currentQuestIndex].index
            sampSendDialogResponse(1013, 1, selectedIndex, -1)
            state.waitingForDialog1018 = true
            lua_thread.create(function()
                if not isScriptActive then return end
                wait(5000)
                if isScriptActive and state.waitingForDialog1018 then
                    state.waitingForDialog1018 = false
                    state.unknownQuests = {}
                    state.currentQuestIndex = 0
                end
            end)
        else
            if isScriptActive and not isPauseMenuActive() and not state.isChatOpen then
                MessageSender:sendChatMessage("/dailyaward")
                state.waitingForDailyResponse = true
                lua_thread.create(function()
                    if not isScriptActive then return end
                    local timeout = os.time() + 10
                    while state.waitingForDailyResponse and isScriptActive and os.time() < timeout do
                        wait(100)
                    end
                    if isScriptActive then
                        state.waitingForDailyResponse = false
                        sendEatCommand()
                    end
                end)
            end
        end
        return false
    end
    if dialogId == 1018 and state.waitingForDialog1018 then
        sampSendDialogResponse(dialogId, 1, 0, -1)
        state.waitingForDialog1018 = false
        state.waitingForDialog1014 = true
        return false
    end
    if dialogId == 1014 and state.waitingForDialog1014 then
        local description = ""
        if text and text ~= "" then
            local success, result = pcall(function()
                return text:match("Описание:%s*(.-)%s*\nПрогресс:") or ""
            end)
            if success then
                description = result
            elseif enableLogging then
                print("[QuestChecker] Error parsing dialog 1014 description: " .. tostring(result))
            end
        else
            if enableLogging then
                print("[QuestChecker] Warning: Dialog 1014 text is nil or empty")
            end
        end
        if description ~= "" and state.unknownQuests[state.currentQuestIndex] then
            local cleanName = description:gsub("{.-}", "")
            local questName = state.unknownQuests[state.currentQuestIndex].name
            state.questReplacements[questName] = cleanName
            for i, v in ipairs(state.questData) do
                if v == questName then
                    state.questData[i] = cleanName
                    break
                end
            end
            state.shouldRedraw = true
        elseif enableLogging then
            print("[QuestChecker] Warning: No description or invalid quest index for dialog 1014")
        end
        state.waitingForDialog1014 = false
        if state.currentQuestIndex < #state.unknownQuests then
            state.currentQuestIndex = state.currentQuestIndex + 1
            local nextIndex = state.unknownQuests[state.currentQuestIndex].index
            sampSendDialogResponse(dialogId, 1, -1, -1)
            state.waitingForDialog1013 = true
            lua_thread.create(function()
                if isScriptActive then
                    sampSendDialogResponse(1013, 1, nextIndex, -1)
                    state.waitingForDialog1018 = true
                end
            end)
        else
            sampSendDialogResponse(dialogId, 0, -1, -1)
            state.unknownQuests = {}
            state.currentQuestIndex = 0
            if isScriptActive and not isPauseMenuActive() and not state.isChatOpen then
                MessageSender:sendChatMessage("/dailyaward")
                state.waitingForDailyResponse = true
                lua_thread.create(function()
                    if not isScriptActive then return end
                    local timeout = os.time() + 10
                    while state.waitingForDailyResponse and isScriptActive and os.time() < timeout do
                        wait(100)
                    end
                    if isScriptActive then
                        state.waitingForDailyResponse = false
                        sendEatCommand()
                    end
                end)
            end
        end
        return false
    end
    return true
end

function sampev.onServerMessage(color, text)
    if not isScriptActive then return true end
    local cleanText = text and text:gsub("{[0-9A-Fa-f]+}", "") or ""
    if text and text:find("%[Quest%]") then
        if text:find("Выполнено задание") or
           text:find("Вы заменили задание") or
           text:find("У вас появились новые ежедневные квесты!") then
            local currentTime = os.time()
            if state.lastQuestCompletionTime ~= currentTime then
                state.lastQuestCompletionTime = currentTime
                if state.isChatOpen then
                    lua_thread.create(function()
                        if not isScriptActive then return end
                        while state.isChatOpen and isScriptActive do
                            wait(100)
                        end
                        if isScriptActive and not isPauseMenuActive() then
                            sendEquestCommand()
                            startTimer()
                        end
                    end)
                else
                    sendEquestCommand()
                    startTimer()
                end
                state.shouldRedraw = true
            end
        end
    end
    if cleanText:find("%[Рыбалка%] Вы успешно установили рыболовную сеть") then
        lua_thread.create(function()
            if not isScriptActive then return end
            wait(2000)
            local configPath = "moonloader\\LuaDunaevskiy\\config\\Alexfish.json"
            local netData = handleJsonFile(configPath)
            if netData and type(netData) == "table" then
                local currentTime = math.floor(os.time() / 60)
                for nickname, netInfo in pairs(netData) do
                    if netInfo and netInfo.time and (currentTime - netInfo.time) > 4320 then
                        if enableLogging then
                            print("[QuestChecker] Clearing outdated net data for " .. nickname .. " (age: " .. (currentTime - netInfo.time) .. " minutes)")
                        end
                        netData[nickname] = nil
                    end
                end
                state.netData = netData
                state.netTimeLeft = nil
                state.lastNetDataStatus = nil
            else
                state.netData = {}
                state.netTimeLeft = nil
                state.lastNetDataStatus = nil
            end
            state.shouldRedraw = true
        end)
    end
    if cleanText:find("Не флуди!") and (state.waitingForDialog1013 or state.expectingEatDialog or state.waitingForConfirmationDialog) then
        lua_thread.create(function()
            if not isScriptActive then return end
            wait(2000)
            if isScriptActive then
                if state.waitingForDialog1013 then
                    sendEquestCommand()
                    startTimer()
                elseif state.expectingEatDialog or state.waitingForConfirmationDialog then
                    if state.selectedFoodCommand then
                        state.expectingEatDialog = true
                        MessageSender:sendChatMessage("/eat")
                    else
                        sendEatCommand()
                    end
                end
            end
        end)
    end
    if cleanText:find("Вы не голодны") or cleanText:find("Превышен лимит допустимой сытости") then
        state.canAutoEat = false
    end
    if state.waitingForDailyResponse then
        local cleanTextDaily = text and text:gsub("{[0-9A-Fa-f]+}", "") or ""
        if cleanTextDaily:match("%[Quest%] Серия квестов ещё не была выполнена!") then
            state.dailyMessagesProcessed = state.dailyMessagesProcessed + 1
            state.waitingForDailyResponse = false
            state.dailyMessagesProcessed = 0
            state.shouldRedraw = true
            return false
        end
        local streak = cleanTextDaily:match("%[Quest%] Ваша серия успешно выполненных заданий: (%d+)")
        if streak then
            local newStreak = tonumber(streak)
            if newStreak ~= state.previousDailyStreak then
                state.dailyStreak = newStreak
                state.previousDailyStreak = newStreak
                state.shouldRedraw = true
            end
            state.dailyMessagesProcessed = state.dailyMessagesProcessed + 1
            if state.dailyMessagesProcessed >= 2 then
                state.waitingForDailyResponse = false
                state.dailyMessagesProcessed = 0
            end
            return false
        end
    end
    return true
end

function sampev.onToggleChat(opened)
    state.isChatOpen = opened
    if not opened then
        state.chatCloseTime = os.time()
    end
end

function imgui.BeforeDrawFrame()
    if not state.customFont then
        local success, result = pcall(function()
            local fontPath = getFolderPath(0x14) .. '\\trebucbd.ttf'
            if not doesFileExist(fontPath) then
                if enableLogging then
                    print("[QuestChecker] Error: Font file not found at " .. fontPath)
                end
                windowTitle = "QuestChecker"
                questTitle = u8'Не выполненные задания:'
                return nil
            end
            imgui.GetIO().Fonts:Clear()
            local font = imgui.GetIO().Fonts:AddFontFromFileTTF(fontPath, 18.0, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
            if doesFileExist('moonloader/resource/fonts/fa-solid-900.ttf') then
                local font_config = imgui.ImFontConfig()
                font_config.MergeMode = true
                state.faFont = imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader/resource/fonts/fa-solid-900.ttf', 18.0, font_config, imgui.ImGlyphRanges({ fa.min_range, fa.max_range }))
            else
                if enableLogging then
                    print("[QuestChecker] Warning: Font Awesome file not found")
                end
            end
            imgui.GetIO().Fonts:Build()
            return font
        end)
        if success and result then
            state.customFont = result
        else
            if enableLogging then
                print("[QuestChecker] Error loading font: " .. tostring(result))
            end
            windowTitle = "QuestChecker"
            questTitle = u8'Не выполненные задания:'
        end
    end
end

function imgui.OnDrawFrame()
    if not state.isWindowVisible then return end
    local screenX, screenY = getScreenResolution()
    local wasSettingsOpen = state.showSettings.v
    if state.showWindow.v then
        local windowFlags = imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.AlwaysAutoResize
        if not state.isDraggingEnabled then
            windowFlags = windowFlags + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoMove
            imgui.ShowCursor = false
        else
            imgui.ShowCursor = true
        end
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(unpack(state.config.bgColor)))
        if imgui.Begin(windowTitle, nil, windowFlags) then
            local windowWidth = imgui.GetWindowWidth()
            local windowHeight = imgui.GetWindowHeight()
            local posX = screenX * state.config.position.x
            local posY = screenY * state.config.position.y
            posX = math.max(0, math.min(screenX - windowWidth, posX))
            posY = math.max(0, math.min(screenY - windowHeight, posY))
            imgui.SetWindowPos(imgui.ImVec2(posX, posY), not state.isDraggingEnabled and imgui.Cond.Always or imgui.Cond.FirstUseEver)
            if state.customFont then
                imgui.PushFont(state.customFont)
            end
            imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(unpack(state.config.textColor)))
            if showQuests.v then
                imgui.SetWindowFontScale(math.max(0.1, state.config.questFontSize / 18.0))
                imgui.Text(questTitle)
                if state.questData and (#state.questData > 0 or state.waitingForDialog1013) then
                    if #state.questData == 0 then
                        imgui.TextColored(imgui.ImVec4(unpack(state.config.textColor)), fa.ICON_FA_SPINNER .. " " .. safeU8'Загрузка...')
                    else
                        for i, task in ipairs(state.questData) do
                            if task then
                                imgui.Text(safeU8(task))
                            end
                        end
                    end
                else
                    if state.questUpdateTime then
                        local currentTime = math.floor(os.time() / 60)
                        local timezoneOffset = getTimezoneOffset() or 0
                        local currentUTCMinutes = currentTime + timezoneOffset
                        local minutesLeft = state.questUpdateTime - currentUTCMinutes
                        if minutesLeft > 0 then
                            local timeStr = formatTime(minutesLeft)
                            imgui.Text(fa.ICON_FA_CLOCK .. " " .. safeU8('Обновление через ' .. timeStr))
                        else
                            imgui.Text(fa.ICON_FA_HOURGLASS .. " " .. safeU8'Ожидание обновления...')
                        end
                    else
                        imgui.Text(fa.ICON_FA_HOURGLASS_START .. " " .. safeU8'Ожидание данных...')
                    end
                end
                imgui.Separator()
                imgui.Text(fa.ICON_FA_TROPHY .. " " .. safeU8(string.format("Серия квестов: %d", state.dailyStreak or 0)))
                imgui.SetWindowFontScale(1.0)
            else
                if showNets.v or showSatiety.v then
                    imgui.Separator()
                end
            end
            if state.fishScriptLoaded and showNets.v then
                imgui.SetWindowFontScale(math.max(0.1, state.config.netsFontSize / 18.0))
                local currentTime = os.time() * 1000
                if currentTime - state.lastNetTimeUpdate >= state.NET_TIME_UPDATE_INTERVAL then
                    state.netTimeLeft = getNetTimeLeft()
                    state.lastNetTimeUpdate = currentTime
                end
                if state.netTimeLeft then
                    imgui.Text(fa.ICON_FA_FISH .. " " .. safeU8(state.netTimeLeft))
                else
                    imgui.Text(fa.ICON_FA_FISH .. " " .. safeU8"Сети: нет данных")
                end
                imgui.SetWindowFontScale(1.0)
                if showSatiety.v then
                    imgui.Separator()
                end
            end
            if showSatiety.v then
                imgui.SetWindowFontScale(math.max(0.1, state.config.satietyFontSize / 18.0))
                local autoEatStatus = state.autoEatEnabled and "вкл." or "выкл."
                imgui.Text(fa.ICON_FA_UTENSILS .. " " .. safeU8(string.format("Сытость: %d | %s", state.satietyValue or 0, autoEatStatus)))
                imgui.SetWindowFontScale(1.0)
            end
            if state.isDraggingEnabled then
                if imgui.IsWindowHovered() and imgui.IsMouseDragging(0) then
                    local newPos = imgui.GetWindowPos()
                    state.config.position.x = math.max(0, math.min(1 - windowWidth / screenX, newPos.x / screenX))
                    state.config.position.y = math.max(0, math.min(1 - windowHeight / screenY, newPos.y / screenY))
                    state.shouldRedraw = true
                end
            end
            imgui.PopStyleColor()
            if state.customFont then
                imgui.PopFont()
            end
        end
        imgui.End()
        imgui.PopStyleColor()
    end
    if state.showSettings.v then
        imgui.SetNextWindowPos(imgui.ImVec2(screenX/2, screenY/2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(300, 500), imgui.Cond.FirstUseEver)
        if imgui.Begin(fa.ICON_FA_COG .. " " .. safeU8"Настройки QuestChecker", state.showSettings) then
            imgui.Text(fa.ICON_FA_SLIDERS_H .. " " .. safeU8"Настройки:")
            if imgui.Checkbox(fa.ICON_FA_LIST_ALT .. " " .. safeU8"Показывать квесты", showQuests) then
                state.shouldRedraw = true
                state.config.showQuests = showQuests.v
            end
            if state.fishScriptLoaded then
                if imgui.Checkbox(fa.ICON_FA_FISH .. " " .. safeU8"Показывать сети", showNets) then
                    state.shouldRedraw = true
                    state.config.showNets = showNets.v
                end
            end
            if imgui.Checkbox(fa.ICON_FA_UTENSIL_SPOON .. " " .. safeU8"Показывать сытость", showSatiety) then
                state.shouldRedraw = true
                state.config.showSatiety = showSatiety.v
            end
            if imgui.Button(fa.ICON_FA_COOKIE_BITE .. " " .. safeU8"Настроить автопоедание") then
                state.showFoodSettings.v = not state.showFoodSettings.v
            end
            local eatKeyName = getKeyName(eatKey.v)
            if imgui.Button(fa.ICON_FA_UTENSILS .. " " .. safeU8"Съесть лучшее: " .. eatKeyName) then
                eatKeySelecting.v = true
            end
            if eatKeySelecting.v then
                imgui.Text(fa.ICON_FA_KEY .. " " .. safeU8"Нажмите клавишу для поедания...")
                for i = 0, 255 do
                    if isKeyJustPressed(i) and i > 0 then
                        eatKey.v = i
                        eatKeySelecting.v = false
                        state.config.eatKey = eatKey.v
                        break
                    end
                end
            end
            imgui.BeginGroup()
            local bgColor = imgui.ImFloat4(unpack(state.config.bgColor))
            if imgui.ColorEdit4("##bgColor", bgColor, imgui.ColorEditFlags.AlphaBar + imgui.ColorEditFlags.NoInputs + imgui.ColorEditFlags.NoLabel) then
                state.config.bgColor = { bgColor.v[1], bgColor.v[2], bgColor.v[3], bgColor.v[4] }
                state.shouldRedraw = true
            end
            imgui.SameLine()
            imgui.Text(fa.ICON_FA_PAINT_ROLLER .. " " .. safeU8"Цвет фона")
            imgui.EndGroup()
            imgui.BeginGroup()
            local textColor = imgui.ImFloat4(unpack(state.config.textColor))
            if imgui.ColorEdit4("##textColor", textColor, imgui.ColorEditFlags.AlphaBar + imgui.ColorEditFlags.NoInputs + imgui.ColorEditFlags.NoLabel) then
                state.config.textColor = { textColor.v[1], textColor.v[2], textColor.v[3], textColor.v[4] }
                state.shouldRedraw = true
            end
            imgui.SameLine()
            imgui.Text(fa.ICON_FA_FONT .. " " .. safeU8"Цвет текста")
            imgui.EndGroup()
            local questFontSize = imgui.ImFloat(state.config.questFontSize)
            if imgui.SliderFloat(fa.ICON_FA_ARROWS_ALT_V .. " " .. safeU8"Квесты", questFontSize, 10.0, 30.0, "%.1f") then
                state.config.questFontSize = questFontSize.v
                state.shouldRedraw = true
            end
            if state.fishScriptLoaded then
                local netsFontSize = imgui.ImFloat(state.config.netsFontSize)
                if imgui.SliderFloat(fa.ICON_FA_ARROWS_ALT_V .. " " .. safeU8"Сети", netsFontSize, 10.0, 30.0, "%.1f") then
                    state.config.netsFontSize = netsFontSize.v
                    state.shouldRedraw = true
                end
            end
            local satietyFontSize = imgui.ImFloat(state.config.satietyFontSize)
            if imgui.SliderFloat(fa.ICON_FA_ARROWS_ALT_V .. " " .. safeU8"Сытость", satietyFontSize, 10.0, 30.0, "%.1f") then
                state.config.satietyFontSize = satietyFontSize.v
                state.shouldRedraw = true
            end
            if imgui.Button(fa.ICON_FA_TIMES_CIRCLE .. " " .. safeU8"Закрыть") then
                applySettings()
            end
        end
        imgui.End()
        if state.showFoodSettings.v then
            imgui.SetNextWindowPos(imgui.ImVec2(screenX/2 + 310, screenY/2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
            imgui.SetNextWindowSize(imgui.ImVec2(350, 400), imgui.Cond.FirstUseEver)
            if imgui.Begin(fa.ICON_FA_UTENSILS .. " " .. safeU8"Настройки автопоедания", state.showFoodSettings) then
                imgui.Text(fa.ICON_FA_HAMBURGER .. " " .. safeU8"Выбор еды (А - авто, K - съесть):")
                imgui.BeginChild("FoodList", imgui.ImVec2(0, 300), true)
                for _, food in ipairs(state.foodList) do
                    local foodName = food.name:gsub("{.-}", "")
                    imgui.PushID(food.command)
                    if imgui.Checkbox("A##" .. food.command, state.config.foodSettings[food.command]) then
                        state.shouldRedraw = true
                    end
                    imgui.SameLine()
                    if imgui.Checkbox("K##" .. food.command, state.config.eatNowSettings[food.command]) then
                        state.shouldRedraw = true
                    end
                    imgui.SameLine()
                    if food.command == "fish" then
                        imgui.Text(fa.ICON_FA_FISH .. " " .. safeU8(foodName))
                    elseif food.command == "beef" then
                        imgui.Text(fa.ICON_FA_DRUMSTICK_BITE .. " " .. safeU8(foodName))
                    elseif food.command == "grib" then
                        imgui.Text(fa.ICON_FA_COOKIE .. " " .. safeU8(foodName))
                    elseif food.command == "deer" then
                        imgui.Text(fa.ICON_FA_DRUMSTICK_BITE .. " " .. safeU8(foodName))
                    elseif food.command == "turtle" then
                        imgui.Text(fa.ICON_FA_DRUMSTICK_BITE .. " " .. safeU8(foodName))
                    elseif food.command == "shark" then
                        imgui.Text(fa.ICON_FA_DRUMSTICK_BITE .. " " .. safeU8(foodName))
                    elseif food.command == "turtle_ragu" then
                        imgui.Text(fa.ICON_FA_DRUMSTICK_BITE .. " " .. safeU8(foodName))
                    elseif food.command == "beef_mushroom" then
                        imgui.Text(fa.ICON_FA_DRUMSTICK_BITE .. " " .. safeU8(foodName))
                    elseif food.command == "deer_mushroom" then
                        imgui.Text(fa.ICON_FA_DRUMSTICK_BITE .. " " .. safeU8(foodName))
                    elseif food.command == "shark_soup" then
                        imgui.Text(fa.ICON_FA_DRUMSTICK_BITE .. " " .. safeU8(foodName))
                    elseif food.command == "sea_dish" then
                        imgui.Text(fa.ICON_FA_FISH .. " " .. safeU8(foodName))
                    elseif food.command == "trout_soup" then
                        imgui.Text(fa.ICON_FA_FISH .. " " .. safeU8(foodName))
                    elseif food.command == "pike_soup" then
                        imgui.Text(fa.ICON_FA_FISH .. " " .. safeU8(foodName))
                    elseif food.command == "fish_soup" then
                        imgui.Text(fa.ICON_FA_FISH .. " " .. safeU8(foodName))
                    elseif food.command == "carp" then
                        imgui.Text(fa.ICON_FA_FISH .. " " .. safeU8(foodName))
                    elseif food.command == "squid" then
                        imgui.Text(fa.ICON_FA_FISH .. " " .. safeU8(foodName))
                    elseif food.command == "taco" then
                        imgui.Text(fa.ICON_FA_FISH .. " " .. safeU8(foodName))
                    elseif food.command == "pudding" then
                        imgui.Text(fa.ICON_FA_FISH .. " " .. safeU8(foodName))
                    elseif food.command == "pufferfish" then
                        imgui.Text(fa.ICON_FA_FISH .. " " .. safeU8(foodName))
                    end
                    imgui.PopID()
                end
                imgui.EndChild()
                if imgui.Button(fa.ICON_FA_TIMES_CIRCLE .. " " .. safeU8"Закрыть") then
                    state.showFoodSettings.v = false
                end
            end
            imgui.End()
        end
    end
    if wasSettingsOpen and not state.showSettings.v then
        applySettings()
    end
end

function onReceivePacket(id, bs)
    if not isScriptActive then return true end
    if id == 223 then
        local success, result = pcall(function()
            local byteCount = raknetBitStreamGetNumberOfBytesUsed(bs)
            if byteCount < 3 or byteCount > 100 then return nil end
            local v = {}
            for i = 1, byteCount do
                v[i] = raknetBitStreamReadInt8(bs)
            end
            if v[2] == 5 and v[3] ~= nil then
                return v[3]
            end
            return nil
        end)
        if success and result then
            if state.satietyValue ~= result then
                state.satietyValue = result
                state.canAutoEat = true
                state.shouldRedraw = true
                state.satietyPacketReceived = true
            end
        elseif enableLogging then
            print("[QuestChecker] Error in onReceivePacket: " .. tostring(result))
        end
        if not state.isFullyConnected then
            state.isFullyConnected = true
        end
    end
    return true
end

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then
        if enableLogging then
            print("[QuestChecker] Error: SAMP or SAMPFUNCS not loaded")
        end
        return
    end
    while not isSampAvailable() do wait(100) end
    isScriptActive = true
    MessageSender:init()
    state.messageSenderInitialized = true
    loadConfig()
    updatePlayerNickname()
    state.fishScriptLoaded = doesFileExist("moonloader\\LuaDunaevskiy\\fish.lua")
    if state.fishScriptLoaded then
        local configPath = "moonloader\\LuaDunaevskiy\\config\\Alexfish.json"
        local netData = handleJsonFile(configPath)
        if netData and type(netData) == "table" then
            local currentTime = math.floor(os.time() / 60)
            for nickname, netInfo in pairs(netData) do
                if netInfo and netInfo.time and (currentTime - netInfo.time) > 4320 then
                    if enableLogging then
                        print("[QuestChecker] Clearing outdated net data for " .. nickname .. " (age: " .. (currentTime - netInfo.time) .. " minutes)")
                    end
                    netData[nickname] = nil
                end
            end
            state.netData = netData
            state.netTimeLeft = nil
            state.lastNetDataStatus = nil
        else
            state.netData = {}
            state.netTimeLeft = nil
            state.lastNetDataStatus = nil
        end
    end
    sampRegisterChatCommand("eq", function()
        if isScriptActive then
            state.showSettings.v = not state.showSettings.v
            state.isDraggingEnabled = state.showSettings.v
            state.shouldRedraw = true
        end
    end)
    wait(15000)
    if not isScriptActive then return end
    state.isWindowVisible = true
    state.satietyPacketWaitStart = os.time() * 1000
    state.satietyPacketReceived = false
    sendEquestCommand()
    local questUpdateSent = false
    local questUpdateDelayStart = nil
    while isScriptActive do
        wait(0)
        imgui.Process = state.isWindowVisible
        if state.isWindowVisible and isKeyJustPressed(vkeys.VK_HOME) then
            state.showWindow.v = not state.showWindow.v
            state.shouldRedraw = true
        end
        if isKeyJustPressed(eatKey.v) and not (sampIsChatInputActive() or sampIsDialogActive(-1)) then
            eatBestFoodNow()
        end
        imgui.Process = state.isWindowVisible and (state.showWindow.v or state.showSettings.v or state.showFoodSettings.v)
        if state.satietyPacketWaitStart and not state.satietyPacketReceived then
            local currentTime = os.time() * 1000
            if (currentTime - state.satietyPacketWaitStart) >= state.SATIETY_PACKET_TIMEOUT then
                state.autoEatEnabled = true
                state.satietyPacketWaitStart = nil
                state.satietyPacketReceived = false
            end
        end
        if not state.waitingForDailyResponse and state.autoEatEnabled and state.canAutoEat and not state.expectingEatDialog and not state.waitingForConfirmationDialog then
            local currentTime = os.time() * 1000
            if (currentTime - state.lastCommandTime) >= 3000 then
                if not state.hasInitializedFoodStock then
                    sendEatCommand()
                else
                    local timeNow = os.time() * 1000
                    local bestFood = selectBestFood()
                    if bestFood then
                        local remaining = state.foodStock[bestFood.command] - state.eatenFood[bestFood.command]
                        local threshold = bestFood.maxSatiety - bestFood.satietyAdd
                        if remaining > 10 then
                            if bestFood.dialogBased then
                                state.expectingEatDialog = true
                                state.selectedFoodCommand = bestFood.command
                                MessageSender:sendChatMessage("/eat")
                            else
                                MessageSender:sendChatMessage("/eat " .. bestFood.command)
                                state.eatenFood[bestFood.command] = state.eatenFood[bestFood.command] + 1
                                state.foodStock[bestFood.command] = state.foodStock[bestFood.command] - 1
                            end
                            updateLastCommandTime()
                        elseif remaining <= 10 and remaining > 0 then
                            state.eatenFood[bestFood.command] = 0
                            sendEatCommand()
                        end
                    end
                    if (timeNow - state.lastEatUpdateTime) >= state.EAT_UPDATE_INTERVAL then
                        sendEatCommand()
                    end
                end
            end
        end
        local currentTime = os.time() * 1000
        if state.waitingForDialog1013 and (currentTime - state.lastEquestSendTime) > 60000 and (currentTime - state.lastCommandTime) >= 3000 then
            sendEquestCommand()
        end
        if state.questUpdateTime and not state.waitingForDialog1013 then
            local currentTime = math.floor(os.time() / 60)
            local timezoneOffset = getTimezoneOffset() or 0
            local currentUTCMinutes = currentTime + timezoneOffset
            local minutesLeft = state.questUpdateTime - currentUTCMinutes
            if minutesLeft <= 0 and not questUpdateSent then
                if not questUpdateDelayStart then
                    questUpdateDelayStart = os.time()
                elseif os.time() - questUpdateDelayStart >= 60 then
                    sendEquestCommand()
                    questUpdateSent = true
                    questUpdateDelayStart = nil
                end
            elseif minutesLeft > 0 then
                questUpdateSent = false
                questUpdateDelayStart = nil
            end
        end
    end
end

function onScriptTerminate(script)
    if script == thisScript() then
        isScriptActive = false
        saveConfig()
    end
end