script_name("hallowen-door-cracker")
script_author("Serhiy_Rubin")
script_version("31.10.2023")

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(0) end
    bot = false
    sampRegisterChatCommand("hdoor", function() 
        bot = not bot
        printStringNow("~Y~Hallowen Door Cracker~N~"..(bot and "~G~ON" or "~R~OFF"), 1000)
    end)
    while true do
        wait(0)
        if bot then
            for a = 0, 2304 do
                if sampTextdrawIsExists(a) then
                    local x, y = sampTextdrawGetPos(a)
                    local text = sampTextdrawGetString(a)
                    if getDistanceBetweenCoords2d(399.0, 270.0, x, y) < 0.3 then
                        if text:find("PRESS %~r%~%~k%~%~(.+)%~ %~w%~TO HACK THE DOOR") then
                            local key = text:match("PRESS %~r%~%~k%~%~(.+)%~ %~w%~TO HACK THE DOOR")
                            local keys = {
                                ["CONVERSATION_YES"] = 64,
                                ["CONVERSATION_NO"] = 128,
                                ["GROUP_CONTROL_BWD"] = 192,
                            }
                            if keys[key] ~= nil then 
                                if af_send == nil or ((os.clock() * 1000 - af_send > 100) or old_key ~= keys[key]) then
                                    af_send = os.clock() * 1000
                                    old_key = keys[key]
                                    local data = allocateMemory(68)
                                    sampStorePlayerOnfootData(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)), data)
                                    setStructElement(data, 36, 1, keys[key], false)
                                    sampSendOnfootData(data)
                                    freeMemory(data)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end