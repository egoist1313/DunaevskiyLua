local sampev = require 'lib.samp.events'

local MessageSender = {
    messageQueue = {},
    lastCommandTime = 0,
    messagesInBurst = 0,
    maxBurst = 3,
    burstInterval = 400,
    pauseInterval = 1000, -- ������� �����
    currentPauseMultiplier = 1, -- ���������������� �����
    messageInterval = 1000,
    isSending = false,
    isPaused = false,
    pauseEndTime = 0,
    lastSentCommand = nil,
    currentBurstCommands = {}, -- ������ ������� �������� burst
    initialized = false
}

function MessageSender:init()
    if not self.initialized then
        self:startSendingLoop()
        self.initialized = true
    end
end

function MessageSender:sendChatMessage(command)
    -- �������� ���������� � �������
    for _, queued in ipairs(self.messageQueue) do
        if queued == command then return end
    end
    table.insert(self.messageQueue, command)
end

function MessageSender:startSendingLoop()
    lua_thread.create(function()
        while true do
            local currentTime = os.clock() * 1000
            -- ���������, ����� �� ����������
            if #self.messageQueue > 0 and not self.isSending and not (self.isPaused and currentTime < self.pauseEndTime) then
                self.isSending = true
                local command = self.messageQueue[1]
                if command:find("^/") then
                    self:sendNextBurst()
                else
                    self:sendSingleMessage()
                end
            elseif self.isPaused and currentTime >= self.pauseEndTime then
                -- ���������� �����, ���� ����� �������
                self.isPaused = false
                self.isSending = false
                self.messagesInBurst = 0
                self.currentPauseMultiplier = 1 -- ����� ��������� ����� �����
            end
            wait(50) -- ��������� �������� ��� ����� ������� �������
        end
    end)
end

function MessageSender:sendNextBurst()
    local burstCount = math.min(self.maxBurst, #self.messageQueue)
    self.currentBurstCommands = {} -- �������
    for i = 1, burstCount do
        if self.isPaused then
            -- ���� �����, ���������� ���������� ������� � �������
            for j = i, burstCount do
                local cmd = table.remove(self.messageQueue, 1)
                table.insert(self.currentBurstCommands, cmd)
            end
            break
        end
        local command = table.remove(self.messageQueue, 1)
        table.insert(self.currentBurstCommands, command)
        self.lastSentCommand = command
        self:sendChatWithDelay(command, self.burstInterval)
        self.messagesInBurst = self.messagesInBurst + 1
        if self.messagesInBurst < self.maxBurst and i < burstCount then
            wait(self.burstInterval)
        end
    end
    if burstCount > 0 and not self.isPaused then
        wait(self.pauseInterval * self.currentPauseMultiplier)
        self.messagesInBurst = 0
        self.currentPauseMultiplier = 1 -- ����� ����� ������
    end
    self.isSending = false
end

function MessageSender:sendSingleMessage()
    local command = table.remove(self.messageQueue, 1)
    self.currentBurstCommands = {command}
    self.lastSentCommand = command
    self:sendChatWithDelay(command, self.messageInterval)
    wait(self.messageInterval)
    if not self.isPaused then
        self.currentPauseMultiplier = 1
    end
    self.isSending = false
end

function MessageSender:sendChatWithDelay(command, interval)
    local currentTime = os.clock() * 1000
    local timeSinceLast = currentTime - self.lastCommandTime
    if timeSinceLast < interval then
        wait(interval - timeSinceLast)
    end
    self.lastCommandTime = os.clock() * 1000
    sampSendChat(command)
    print("[MessageSender] Sent: " .. command)
end

function sampev.onServerMessage(color, text)
    local cleanText = text:gsub("{[0-9A-Fa-f]+}", "")
    if cleanText:find("�� �����~") then
        print("[MessageSender] Flood detected, pausing...")
        if #MessageSender.currentBurstCommands > 0 then
            -- ���������� ������� burst � ������ �������, ������� ����������
            for i = #MessageSender.currentBurstCommands, 1, -1 do
                local cmd = MessageSender.currentBurstCommands[i]
                local exists = false
                for _, q in ipairs(MessageSender.messageQueue) do
                    if q == cmd then exists = true break end
                end
                if not exists then
                    table.insert(MessageSender.messageQueue, 1, cmd)
                end
            end
            MessageSender.currentBurstCommands = {}
        end
        MessageSender.isPaused = true
        MessageSender.currentPauseMultiplier = math.min(MessageSender.currentPauseMultiplier * 2, 8) -- ������������ ���������
        MessageSender.pauseEndTime = os.clock() * 1000 + (MessageSender.pauseInterval * MessageSender.currentPauseMultiplier)
        MessageSender.isSending = false
    end
    return true
end

return MessageSender