local script_name = 'xmas-clicker'
local script_author = 'Serhiy_Rubin'
local script_version = '1.00'
clicker = false
wait_point = 0
wait_clicker = 100
plus_rand = 0
model_xmas = { 19059, 19060, 19061, 19062, 19063 }

function main()
    while not isSampfuncsLoaded() do wait(100) end
    repeat wait(0) until isSampAvailable()

    sampRegisterChatCommand("xmas", function(arg)
        if arg:find("%d+") then
            wait_clicker = tonumber(arg:match("(%d+)"))    
        end

        clicker = not clicker
        local text = string.format("~Y~XMAS-CLICKER~n~%s", (clicker and "~G~ON~N~~Y~WAIT: "..wait_clicker or "~R~OFF"))
        printStringNow(text, 1500)
    end)

    while true do wait(0)
        if clicker then
            for a = 0, 2304 do
                if sampTextdrawIsExists(a) then
                    local model = sampTextdrawGetModelRotationZoomVehColor(a)
                    if isVarInArr(model, model_xmas) then
                        if os.clock() * 1000 - wait_point > (wait_clicker + plus_rand) then
                            sampSendClickTextdraw(a)
                            plus_rand = math.random(50, 300)
                            wait_point = os.clock() * 1000
                        end
                    end
                end
            end
        end
    end
end

function isVarInArr(var, array)
    local result = false
    for i = 1, #array do
        if array[i] == var then
            result = true
            break
        end
    end
    return result
end