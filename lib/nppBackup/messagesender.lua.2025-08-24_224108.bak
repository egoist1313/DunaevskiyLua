local samp = require 'lib.samp.events'

local MessageSender = {
    messageQueue = {},
    lastCommandTime = 0,
    messagesInBurst = 0,
    maxBurst = 3,
    burstInterval = 400,
    pauseInterval = 1000,  -- базова€, будет увеличиватьс€
    currentPauseMultiplier = 1,  -- дл€ экспоненциальной паузы
    messageInterval = 1000,
    isSending = false,
    isPaused = false,
    pauseEndTime = 0,
    lastSentCommand = nil,
    currentBurstCommands = {}  -- новый: храним команды текущего burst дл€ retry
}

function MessageSender:init()
    if not self.initialized then
        self:startSendingLoop()
        self.initialized = true
    end
end

function MessageSender:sendChatMessage(command)
    -- »збегать дубликатов в очереди
    for _, queued in ipairs(self.messageQueue) do
        if queued == command then return end
    end
    table.insert(self.messageQueue, command)
end

function MessageSender:startSendingLoop()
    lua_thread.create(function()
        while true do
            local currentTime = os.clock() * 1000
            if #self.messageQueue > 0 and not self.isSending and not (self.isPaused and currentTime < self.pauseEndTime) then
                self.isSending = true
                local command = self.messageQueue[1]
                if command:find("^/") then
                    self:sendNextBurst()
                else
                    self:sendSingleMessage()
                end
            end
            wait(100)
        end
    end)
end

function MessageSender:sendNextBurst()
    local burstCount = math.min(self.maxBurst, #self.messageQueue)
    self.currentBurstCommands = {}  -- очистка
    for i = 1, burstCount do
        if self.isPaused then break end  -- прерывание если пауза активирована
        local command = table.remove(self.messageQueue, 1)
        table.insert(self.currentBurstCommands, command)  -- сохран€ем дл€ retry
        self.lastSentCommand = command
        self:sendChatWithDelay(command, self.burstInterval)
        self.messagesInBurst = self.messagesInBurst + 1
        if self.messagesInBurst < self.maxBurst and i < burstCount then
            wait(self.burstInterval)
        end
    end
    if burstCount > 0 then
        wait(self.pauseInterval * self.currentPauseMultiplier)  -- синхронный wait дл€ паузы
        self.messagesInBurst = 0
        self.isSending = false
        self.currentPauseMultiplier = 1  -- сброс после успеха
    else
        self.isSending = false
    end
end

function MessageSender:sendSingleMessage()
    local command = table.remove(self.messageQueue, 1)
    self.currentBurstCommands = {command}  -- дл€ retry
    self.lastSentCommand = command
    self:sendChatWithDelay(command, self.messageInterval)
    wait(self.messageInterval)  -- синхронный
    self.isSending = false
    self.currentPauseMultiplier = 1
end

function MessageSender:sendChatWithDelay(command, interval)
    local currentTime = os.clock() * 1000
    local timeSinceLast = currentTime - self.lastCommandTime
    if timeSinceLast < interval then
        wait(interval - timeSinceLast)
    end
    self.lastCommandTime = os.clock() * 1000
    sampSendChat(command)
    print("[MessageSender] Sent: " .. command)  -- отладка
end

function samp.onServerMessage(color, text)
    local cleanText = text:gsub("{[0-9A-Fa-f]+}", "")
    if cleanText:find("Ќе флуди!") then
        print("[MessageSender] Flood detected, retrying burst...")
        if #MessageSender.currentBurstCommands > 0 then
            -- ¬ставл€ем все команды burst обратно в начало (в обратном пор€дке, чтобы сохранить последовательность)
            for i = #MessageSender.currentBurstCommands, 1, -1 do
                local cmd = MessageSender.currentBurstCommands[i]
                -- »збегать дубликатов
                local exists = false
                for _, q in ipairs(MessageSender.messageQueue) do
                    if q == cmd then exists = true; break end
                end
                if not exists then
                    table.insert(MessageSender.messageQueue, 1, cmd)
                end
            end
            MessageSender.currentBurstCommands = {}  -- очистка
        end
        MessageSender.isPaused = true
        MessageSender.currentPauseMultiplier = MessageSender.currentPauseMultiplier * 2  -- экспоненциально
        MessageSender.pauseEndTime = os.clock() * 1000 + (MessageSender.pauseInterval * MessageSender.currentPauseMultiplier)
    end
    return true
end

return MessageSender