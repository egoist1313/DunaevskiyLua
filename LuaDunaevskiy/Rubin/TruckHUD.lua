local script_name = 'TruckHUD'
local script_author = 'Serhiy_Rubin'
local script_version = '14.06.2023'
local inicfg = require "inicfg"
local dlstatus = require("moonloader").download_status
local vkeys = require "lib.vkeys"
local ffi = require("ffi")
ffi.cdef [[ bool SetCursorPos(int X, int Y); ]]

local encoding = require "encoding"
encoding.default = "CP1251"
local u8 = encoding.UTF8

function try(f, catch_f)
  local status, exception = pcall(f)
  if not status then
    catch_f(exception)
  end
end

------- 3d text
local id_3D_text = os.time()
local what_is_uploaded = {[0] = "Нет", [1] = "Нефть", [2] = "Уголь", [3] = "Дерево"}
local texts_of_reports = {
    ["n1"] = "Нефтезаводе №1",
    ["n2"] = "Нефтезаводе №2",
    ["y1"] = "Складе Угля №1",
    ["y2"] = "Складе Угля №2",
    ["l1"] = "Лесопилке №1",
    ["l2"] = "Лесопилке №2",
    ["lsn"] = "Нефть в ЛС",
    ["lsy"] = "Уголь в ЛС",
    ["lsl"] = "Дерево в ЛС",
    ["sfn"] = "Нефть в СФ",
    ["sfy"] = "Уголь в СФ",
    ["sfl"] = "Дерево в СФ"
}
local dop_chat_light = {
    "Нефтезавод №1", "Нефтезавод №2", "Склад Угля №1", "Склад Угля №2", "Лесопилку №1", "Лесопилку №2", "Нефть в Порт ЛС", "Нефть в Порт СФ", "Уголь в Порт ЛС", "Уголь в Порт СФ", "Дерево в Порт ЛС", "Дерево в Порт СФ", " в Порт ЛС", " в Порт СФ"
}
for k,v in pairs(texts_of_reports) do
    dop_chat_light[#dop_chat_light+1] = v
end

local find_3dText = {
    ["n1"] = "Нефтезавод №1.*Цена груза: 0.(%d+)",
    ["n2"] = "Нефтезавод №2.*Цена груза: 0.(%d+)",
    ["y1"] = "Склад угля №1.*Цена груза: 0.(%d+)",
    ["y2"] = "Склад угля №2.*Цена груза: 0.(%d+)",
    ["l1"] = "Лесопилка №1.*Цена груза: 0.(%d+)",
    ["l2"] = "Лесопилка №2.*Цена груза: 0.(%d+)",
    ["ls"] = "Порт ЛС.*Нефть: 0.(%d+).*Уголь: 0.(%d+).*Дерево: 0.(%d+)",
    ["sf"] = "Порт СФ.*Нефть: 0.(%d+).*Уголь: 0.(%d+).*Дерево: 0.(%d+)"
}

local menu = {
    [1] = {[1] = "TruckHUD: {06940f}ON", [2] = "TruckHUD: {d10000}OFF", run = false},
    [2] = {[1] = "Load/Unload: {06940f}ON", [2] = "Load/Unload: {d10000}OFF", run = false},
    [3] = {[1] = "Авто-Доклад: {06940f}ON", [2] = "Авто-Доклад: {d10000}OFF", run = false},
    [4] = {[1] = "SMS » Serhiy_Rubin[777]", [2] = "Режим пары: {d10000}OFF", run = false},
    [5] = {[1] = "Соло-Чекер: ", [2] = "Соло-Чекер: ", run = false},
    [6] = {[1] = "Дальнобойщики онлайн", [2] = "Дальнобойщики онлайн", run = false},
    [7] = {[1] = "Дальнобойщики со скриптом", [2] = "Дальнобойщики со скриптом", run = false},
    [8] = {[1] = "Настройки", [2] = "Настройки", run = false},
    [9] = {[1] = "Мониторинг цен", [2] = "Мониторинг цен", run = false},
    [10] = {[1] = "Купить груз", [2] = "Купить груз", run = false},
    [11] = {[1] = "Продать груз", [2] = "Продать груз", run = false},
    [12] = {[1] = "Восстановить груз", [2] = "Восстановить груз", run = false}
}


local pair_afk_stop = {
    player_live = 0,
    pair_live = 0,
    auto_stop = 0
}


local pair_mode, sms_pair_mode, report_text, pair_mode_id, pair_mode_name, BinderMode = false, "", "", -1, "Нет", true

local script_run, control, auto, autoh, wait_auto, pos = false, false, false, true, 0, {[1] = false, [2] = false, [3] = false}

local price_frozen, timer, antiflood, current_load, load_location, unload_location = false, 0, 0, 0, false, false

local my_nick, server, timer_min, timer_sec, workload = "", "", 0, 0, 0

local mon_life, mon_time, mon_ctime = 0, 0, 0

local prices_3dtext_pos = {}
local prices_3dtext_id = {}
local prices_3dtext = { n1 = 0, n2 = 0, y1 = 0, y2 = 0, l1 = 0, l2 = 0, lsn = 0, lsy = 0, lsl = 0, sfn = 0, sfy = 0, sfl = 0 }
local prices_mon = { n1 = 0, n2 = 0, y1 = 0, y2 = 0, l1 = 0, l2 = 0, lsn = 0, lsy = 0, lsl = 0, sfn = 0, sfy = 0, sfl = 0 }
local prices_smon = { n1 = 0, n2 = 0, y1 = 0, y2 = 0, l1 = 0, l2 = 0, lsn = 0, lsy = 0, lsl = 0, sfn = 0, sfy = 0, sfl = 0 }

local delay, d = {chatMon = 0, chat = 0, skill = -1, mon = 0, load = 0, unload = 0, sms = 0, dir = 0, paycheck = 0}, {[3] = ""}
local pickupLoad = {
    [1] = {251.32167053223, 1420.3039550781, 11.5}, -- N1
    [2] = {839.09020996094, 880.17510986328, 14.3515625}, -- Y1
    [3] = {-1048.6430664063, -660.54699707031, 33.012603759766}, -- N2
    [4] = {-2913.8544921875, -1377.0952148438, 12.762256622314}, -- y2
    [5] = {-1963.6184082031, -2438.9055175781, 31.625}, -- l2
    [6] = {-457.45620727539, -53.193939208984, 60.938865661621} -- l1
}
local newMarkers = {}
local pair_table = {}
local pair_timestamp = 0
local pair_status = 0
local response_timestamp = 0
local transponder_delay = 500
local ScriptTerminate = false
local msk_timestamp = 0
local responce_delay = 0
local timer_secc = 0
local base = {}
local payday = 0
local chat_mon = {}
local _3dTextplayers = {}
local live = os.time()

--- pair mode new
parking_pair = {
    {
        [1] = { 251.32167053223, 1420.3039550781, 11.5, 15.0 }, -- N1
        [2] = { -1048.6430664063, -660.54699707031, 33.012603759766, 10.0 } -- N2
    },
    {
        [1] = { 839.09020996094, 880.17510986328, 14.3515625, 15.0 }, -- У1
        [2] = { -2913.8544921875, -1377.0952148438, 12.762256622314, 25.0 } -- У2
    },
    {
        [1] = { -457.45620727539, -53.193939208984, 60.938865661621, 15.0 }, -- Л1
        [2] = { -1963.6184082031, -2438.9055175781, 31.625, 25.0 } -- Л2
    },
    {
        [1] = { 2507.0256, -2234.2151, 13.5469, 30.0 }, -- ЛС
        [2] = { -1731.5022, 118.8936, 3.5547, 30.0 } -- СФ
    }
}
pair_ready = false
player_ready = false

location_pos = {
    ["Нефть 1"] = {x = 256.02127075195, y = 1414.8492431641, z = 10.232398033142},
    ["Уголь 1"] = {x = 832.10766601563, y = 864.03668212891, z = 11.643839836121},
    ["Лес 1"] = {x = -448.91455078125, y = -65.951385498047, z = 58.959014892578},
    ["Нефть 2"] = {x = -1046.7521972656, y = -670.66937255859, z = 31.885597229004},
    ["Уголь 2"] = {x = -2913.8544921875, y = -1377.0952148438, z = 10.762256622314},
    ["Лес 2"] = {x = -1978.8649902344, y = -2434.9421386719, z = 30.192840576172},
    ["Порт ЛС"] = {x = 2507.02, y = -2234.05, z = 13.55},
    ["Порт СФ"] = {x = -1731.5022, y = 118.8936, z = 3.5547},
    ["Аренда"] = {x = 2239.8333, y = 2779.6016, z = 10.8203}
}
location_keys = {
    ["n1"] = {x = 256.02127075195, y = 1414.8492431641, z = 10.232398033142, },
    ["y1"] = {x = 832.10766601563, y = 864.03668212891, z = 11.643839836121},
    ["l1"] = {x = -448.91455078125, y = -65.951385498047, z = 58.959014892578},
    ["n2"] = {x = -1046.7521972656, y = -670.66937255859, z = 31.885597229004},
    ["y2"] = {x = -2913.8544921875, y = -1377.0952148438, z = 10.762256622314},
    ["l2"] = {x = -1978.8649902344, y = -2434.9421386719, z = 30.192840576172},
    ["ls"] = {x = 2507.02, y = -2234.05, z = 13.55},
    ["sf"] = {x = -1731.5022, y = 118.8936, z = 3.5547}
}
cargo_replace = { "n", "y", "l" }

binder_mode_sms = false

stop_downloading_1, stop_downloading_2, stop_downloading_3, stop_downloading_4, stop_downloading_5 = false, false, false, false, false

threads = {}
threads_save = {}
afk_solo_message_false = 0

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(0) end
    --lua_thread.create(script_update.main)

    try(function()
        sampev = require "lib.samp.events"
    end, function(e)
        sampAddChatMessage(">> TruckHUD: Отсутствует модуль 'samp.events'  (SAMP.lua)", 0xff0000)
        sampAddChatMessage(">> Официальная страница TruckHUD: https://vk.com/rubin.mods",0xff0000)
        thisScript():unload()
    end)
    loadEvents()
    loadPtt()

    repeat wait(0) until sampGetCurrentServerName() ~= "SA-MP"
    repeat wait(0) until sampGetCurrentServerName():find("Samp%-Rp.Ru") or sampGetCurrentServerName():find("SRP")

    local _, my_id = sampGetPlayerIdByCharHandle(PLAYER_PED)
    my_nick = sampGetPlayerNickname(my_id)
    server = sampGetCurrentServerName():gsub("|", "")
    server =
        (server:find("02") and "Two" or
        (server:find("Revo") and "Revolution" or
            (server:find("Legacy") and "Legacy" or (server:find("Classic") and "Classic" or
        (server:find("Zero Two") and "Two" or
        (server:find("TEST") and "TEST" or
        (server:find("Renaissance") and "Renaissance" or "" )))))))
    if server == "" then
        thisScript():unload()
    end
    AdressConfig = string.format("%s\\moonloader\\config ", getGameDirectory())
    AdressFolder = string.format("%s\\moonloader\\config\\TruckHUD", getGameDirectory())
    AdressJson = string.format("%s\\moonloader\\config\\TruckHUD\\%s-%s.json", getGameDirectory(), server, my_nick)

    if not doesDirectoryExist(AdressConfig) then
        createDirectory(AdressConfig)
    end
    if not doesDirectoryExist(AdressFolder) then
        createDirectory(AdressFolder)
    end
    settings_load()
    lua_thread.create(get_time)
    logAvailable()
    for k,v in pairs(prices_mon) do
        prices_mon[k] = inifiles.tmonitor[k]
    end
    mon_time = inifiles.tmonitor.time

    menu[3].run = inifiles.Settings.Report
    font = renderCreateFont(inifiles.Render.FontName, inifiles.Render.FontSize, inifiles.Render.FontFlag)

    --gmap area
    lua_thread.create(transponder)
    lua_thread.create(fastmap)
    lua_thread.create(renderTruckers)
    lua_thread.create(luChecker.checker)
    lua_thread.create(doCruise)

    platinum_check()

    repeat
        wait(0)
    until msk_timestamp ~= 0
    while true do
        wait(0)
        if os.time() - live > 3 then
            afk_solo_message_false = os.time()
        end
        live = os.time()
        logAvailable()
        doControl()
        doSendCMD()
        doDialog()
        doPair()
        doPickup()
        doPtt()
        if script_run then
            if not sampIsScoreboardOpen() and sampIsChatVisible() and not isKeyDown(116) and not isKeyDown(121) and fastmapshow == nil then
                doPair_G()
                doRenderStats()
                doRenderMon()
                doRenderBind()
            end
        end
    end
end

maxload_int = 0
function maxload()
    if maxload_int == 0 then
        addChatMessage("Пересядь в фуру чтобы понять сколько груза брать!")
    else
        sampSendChat("/truck load "..maxload_int)
    end
end

function settings_load()
    wait(0)
    local x1, y1 = convertGameScreenCoordsToWindowScreenCoords(14.992679595947, 274.75)
    local x2, y2 = convertGameScreenCoordsToWindowScreenCoords(146.17861938477, 345.91665649414)
    local x3, y3 = convertGameScreenCoordsToWindowScreenCoords(529.42901611328, 158.08332824707)
    defaultMon =
[[!mn!Скилл: {FFFFFF}!skill! [!skill_poc!%] [!skill_reys!]!n!Ранг: {FFFFFF}!rang! [!rang_poc!%] [!rang_reys!]!n!!mn!Зарплата:{FFFFFF} !zp_hour!/!max_zp!!n!Прибыль: {FFFFFF}!profit!!n!Рейсы: {FFFFFF}!reys_hour!/!reys_day! [!left_reys!] ]]
        local table_std = {
            Settings = {
                binder_sms_mode = false,
                auto_load_unload_kd_pair_use = true,
                TruckRender = true,
                Cruise = false,
                chat_in_truck = false,
                blacklist_inversion = false,
                pairinfo = true,
                transponder = true,
                fastmap = true,
                ad = true,
                AutoWait = true,
                highlight_jf = true,
                Stop = false,
                ChatOFF = false,
                ChatDoklad = false,
                X1 = x1,
                Y1 = y1,
                X2 = x2,
                Y2 = y2,
                X3 = x3,
                Y3 = y3,
                AutoOFF = false,
                Tuning = true,
                Report = true,
                Key = 90,
                Key1 = "VK_RBUTTON",
                Key2 = "VK_Z",
                Key3 = "VK_LBUTTON",
                Key4 = 'VK_LSHIFT',
                Binder = true,
                SMSpara = false,
                ColorPara = "ff9900",
                LightingPara = true,
                LightingPrice = true,
                girl = false,
                pickup = true,
                markers = false,
                stats_text = defaultMon,
                renderTruck = true,
                AutoClear = true,
                NewPairMSG = true,
                luCheckerCargo = 0
            },
            Render = {
                FontName = "Segoe UI",
                FontSize = 10,
                FontFlag = 15,
                Color1 = "2f72f7",
                Color2 = "FFFFFF"
            },
            Trucker = {
                Skill = 1,
                ReysSkill = 0,
                Rank = 1,
                ReysRank = 0,
                ProcSkill = 100.0,
                ProcRank = 100.0,
                MaxZP = 197000
            },
            Price = {
                Load = 500,
                UnLoad = 800
            },
            tmonitor = {
                time = 0,
                n1 = 0, n2 = 0, y1 = 0, y2 = 0, l1 = 0, l2 = 0, lsn = 0, lsy = 0, lsl = 0, sfn = 0, sfy = 0, sfl = 0
            },
            binder = { '/r На месте', '/r Загружаюсь', '/r Задержусь', '/r Разгружаюсь' },
            binder_sms = { '/sms !ИдПары На месте', '/sms !ИдПары Загружаюсь', '/sms !ИдПары Задержусь', '/sms !ИдПары Разгружаюсь' },
            blacklist = {},
            version = thisScript().version,
            platinum = {
                status = false,
                time = 0
            }
        }
    if not doesFileExist(AdressJson) then
        local file, error = io.open(AdressJson, "w")
        if file ~= nil then
            file:write(encodeJson(table_std))
            file:flush()
            io.close(file)
        else
            sampAddChatMessage(error, -1)
        end
    end

    local readJson = function()
        local file, error = io.open(AdressJson, "r")
        if file then
            local fileText = file:read("*a")
            inifiles = decodeJson(fileText)
            if inifiles["version"] == nil then
                inifiles = decodeJson(u8(fileText))
                inifiles["version"] = thisScript().version
                os.remove(AdressJson)
                addChatMessage("Конфиг был перезаписан в UTF-8!")
                local file, error = io.open(AdressJson, "w")
                if file ~= nil then
                    file:write(encodeJson(inifiles))
                    file:flush()
                    io.close(file)
                end
            else
                inifiles["version"] = thisScript().version
            end
            if inifiles == nil then
                sampAddChatMessage("[TruckHUD] Ошибка чтения конфига! Сбрасываю конфиг!", 0xff0000)
                local file, error = io.open(AdressJson, "w")
                if file ~= nil then
                    file:write(encodeJson(table_std))
                    file:flush()
                    io.close(file)
                end
            end
            io.close(file)
        end
    end
    local result = pcall(readJson)
    if not result then
        sampAddChatMessage("[TruckHUD] Ошибка чтения конфига! Сбрасываю конфиг!", 0xff0000)
        local file, error = io.open(AdressJson, "w")
        if file ~= nil then
            file:write(encodeJson(table_std))
            file:flush()
            io.close(file)
        end
    end


    if inifiles ~= nil then
        if error_ini ~= nil then
            sampAddChatMessage("[TruckHUD] Конфиг был успешно загружен!", 0xff0000)
            error_ini = nil
        end
        for k,v in pairs(table_std) do
            if inifiles[k] == nil then
                inifiles[k] = v
            end
            if k ~= "binder" and k ~= "binder_sms" and type(v) == "table" then
                for i, s in pairs(v) do
                    if inifiles[k][i] == nil then
                        inifiles[k][i] = s
                    end
                end
            end
        end
        settings_save()
    else
        error_ini = true
        sampAddChatMessage("[TruckHUD] Ошибка чтения конфига! Пробую ещё раз прочесть", 0xff0000)
        settings_load()
    end
end

function settings_save()
    local file, error = io.open(AdressJson, "w")
    if file ~= nil then
        file:write(encodeJson(inifiles))
        file:flush()
        io.close(file)
    else
        sampAddChatMessage(error, -1)
    end
end

function doControl()
    if
        isKeyDown(vkeys[inifiles.Settings.Key1]) and
            (isTruckCar() or (isKeyDown(vkeys[inifiles.Settings.Key2] or pos[1] or pos[2] or pos[3]))) and
            not sampIsDialogActive() and
            not sampIsScoreboardOpen()
    then
        dialogActiveClock = os.time()
        sampSetCursorMode(3)
        local X, Y = getScreenResolution()
        if not control then
            ffi.C.SetCursorPos((X / 2), (Y / 2))
        end
        control = true
        local plus = (renderGetFontDrawHeight(font) + (renderGetFontDrawHeight(font) / 10))
        Y = ((Y / 2.2) - (renderGetFontDrawHeight(font) * 3))
        for i = 1, 12 do
            local string_render = menu[i].run and menu[i][1] or menu[i][2]
            if i == 5 then
                local text = { "{d10000}OFF", "{06940f}Нефть", "{06940f}Уголь", "{06940f}Дерево", "{06940f}Все" }
                if text[inifiles.Settings.luCheckerCargo+1] ~= nil then
                    string_render = string.format("%s%s", string_render, text[inifiles.Settings.luCheckerCargo+1])
                end
            end
            if drawClickableText(string_render, ((X / 2) - (renderGetFontDrawTextLength(font, string_render) / 2)), Y) then
                if i == 1 then
                    script_run = not script_run
                    if script_run then
                        delay.paycheck = 1
                    end
                    menu[i].run = script_run
                end
                if i == 2 then
                    auto = not auto
                    menu[i].run = auto
                end
                if i == 3 then
                    inifiles.Settings.Report = not inifiles.Settings.Report
                    settings_save()
                    menu[i].run = inifiles.Settings.Report
                end
                if i == 4 then
                    if pair_mode then
                        sampSetChatInputText("/sms " .. pair_mode_id .. " ")
                        sampSetChatInputEnabled(true)
                    else
                        ShowDialog1(8)
                    end
                end
                if i == 5 then
                    inifiles.Settings.luCheckerCargo = inifiles.Settings.luCheckerCargo + 1
                    if inifiles.Settings.luCheckerCargo >= 5 then
                        inifiles.Settings.luCheckerCargo = 0
                    end
                    luChecker.load_position.x, luChecker.load_position.y, luChecker.load_position.z = 7777.0, 7777.0, 7777.0
                    settings_save()
                end
                if i == 6 then
                    delay.dir = 1
                end
                if i == 7 and script_run then
                    lua_thread.create(showTruckers)
                end
                if i == 8 then
                    ShowDialog1(1)
                end
                if i == 9 then
                    sampSendChat("/truck mon")
                end
                if i == 10 then
                    maxload()
                end
                if i == 11 then
                    sampSendChat("/truck unload")
                end
                if i == 12 then
                    sampSendChat("/truck trailer")
                end
            end
            if
                i == 4 and pair_mode and
                    drawClickableText(
                        "{e30202}х",
                        ((X / 2) + (renderGetFontDrawTextLength(font, menu[4][1] .. "   ") / 2)),
                        Y
                    )
             then
                pair_mode = false
                menu[4].run = false
            end
            Y = Y + plus
            if i == 7 then
                Y = Y + plus
            end
        end
    else
        if control and not isKeyDown(vkeys[inifiles.Settings.Key1]) and not pos[1] and not pos[2] and not pos[3] then
            control = false
            sampSetCursorMode(0)
        end
    end
end

function doSendCMD()
    local ms = math.ceil(os.clock() * 1000 - antiflood)
    if ms >= 1150 then
        if delay.mon == 1 then
            sampSendChat("/truck mon")
            delay.mon = 2
        end
        if delay.mon == 0 then
            if delay.chat == 1 then
                sampSendChat("/jf chat " .. report_text)
                delay.chat = 2
            end
            if delay.chat == 0 then
                if delay.chatMon == 1 then
                    sampSendChat("/jf chat " .. SendMonText)
                    delay.chatMon = 2
                end
                if delay.chatMon == 0 then
                    if delay.sms == 1 then
                        sampSendChat("/sms " .. pair_mode_id .. " " .. sms_pair_mode)
                        delay.sms = 2
                    end
                    if delay.sms == 0 then
                        if delay.load == 1 then
                            maxload()
                            delay.load = 2
                        end
                        if delay.load == 0 then
                            if delay.unload == 1 then
                                sampSendChat("/truck unload")
                                delay.unload = 2
                            end
                            if delay.unload == 0 then
                                if delay.dir == 1 then
                                    sampSendChat("/dir")
                                    delay.dir = 2
                                end
                                if delay.dir == 0 then
                                    if delay.skill == 1 then
                                        sampSendChat("/jskill")
                                        delay.skill = 2
                                    end
                                    if delay.skill == 0 then
                                        if delay.paycheck == 1 then
                                            sampSendChat("/paycheck")
                                            delay.paycheck = 2
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function doDialog()
    local result, button, list, input = sampHasDialogRespond(222)
    local caption = sampGetDialogCaption()
    if caption:find('Truck%-HUD: Блокировка') then
        if result then
            doLocalBlock(button, list, input, caption)
        end
    end
    if string.find(caption, 'Truck%-HUD: Настройки') then
        if result and button == 1 then
            if dialogLine ~= nil and dialogLine[list + 1] ~= nil then
                local str = dialogLine[list + 1]
                if str:find("TruckHUD") then
                    script_run = not script_run
                    if script_run then
                        delay.paycheck = 1
                    end
                    menu[1].run = script_run
                    ShowDialog1(1)
                end
                if str:find("Сменить позицию статистики с таймером") then
                    wait(100)
                    pos[1] = true
                end
                if str:find("Сменить позицию мониторинга цен") then
                    wait(100)
                    pos[2] = true
                end
                if str:find("Сменить позицию биндера") then
                    wait(100)
                    pos[3] = true
                end
                if str:find("Доклады по клику на цены") then
                    inifiles.Settings.binder_sms_mode = not inifiles.Settings.binder_sms_mode
                    settings_save()
                    ShowDialog1(1)
                end
                if str:find("Редактировать формат статистики") then
                    editbox_stats = true
                    ShowDialog1(9)
                end
                if str:find("Cruise Control") then
                    if str:find("Кнопка") then
                        ShowDialog1(4, 4)
                    else
                        inifiles.Settings.Cruise = not inifiles.Settings.Cruise
                        if inifiles.Settings.Cruise then
                            sampAddChatMessage('Для активации когда едете нажмите '..inifiles.Settings.Key4:gsub('VK_', '')..'. Чтобы отключить нажмите W.', -1)
                        end
                        settings_save()
                        ShowDialog1(1)
                    end
                 end
                if str:find("Информация о напарнике на HUD") then
                    inifiles.Settings.pairinfo = not inifiles.Settings.pairinfo
                    settings_save()
                    ShowDialog1(9)
                end
                if str:find("Доклады в рацию") then
                    inifiles.Settings.Report = not inifiles.Settings.Report
                    menu[3].run = inifiles.Settings.Report
                    settings_save()
                    ShowDialog1(1)
                end
                if str:find("Доклады от") then
                    inifiles.Settings.girl = not inifiles.Settings.girl
                    settings_save()
                    ShowDialog1(1)
                end
                if str:find("Авто загрузка/разгрузка") then
                    auto = not auto
                    menu[2].run = auto
                    ShowDialog1(1)
                end
                if str:find("Учитывать КД напарника") then
                    inifiles.Settings.auto_load_unload_kd_pair_use = not inifiles.Settings.auto_load_unload_kd_pair_use
                    settings_save()
                    ShowDialog1(1)
                end
                if str:find("Режим авто загрузки/разгрузки") then
                    inifiles.Settings.AutoOFF = not inifiles.Settings.AutoOFF
                    settings_save()
                    ShowDialog1(1)
                end
                if str:find("Информация на фурах дальнобойщиков") then
                    inifiles.Settings.TruckRender = not inifiles.Settings.TruckRender
                    settings_save()
                    ShowDialog1(1)
                end
                if str:find("Убрать тюнинг колес с фур") then
                    inifiles.Settings.Tuning = not inifiles.Settings.Tuning
                    settings_save()
                    ShowDialog1(1)
                end
                if str:find("Биндер") then
                    inifiles.Settings.Binder = not inifiles.Settings.Binder
                    settings_save()
                    ShowDialog1(1)
                end
                if str:find("Режим пары ") then
                    if pair_mode then
                        pair_mode = false
                        menu[4].run = false
                        ShowDialog1(9)
                    else
                        ShowDialog1(8)
                    end
                end
                if str:find("Соло") then
                    inifiles.Settings.luCheckerCargo = inifiles.Settings.luCheckerCargo + 1
                    if inifiles.Settings.luCheckerCargo >= 5 then
                        inifiles.Settings.luCheckerCargo = 0
                    end
                    luChecker.load_position.x, luChecker.load_position.y, luChecker.load_position.z = 7777.0, 7777.0, 7777.0
                    settings_save()
                    ShowDialog1(1)
                end
                if str:find("Доклады в SMS") then
                    inifiles.Settings.SMSpara = not inifiles.Settings.SMSpara
                    settings_save()
                    ShowDialog1(1)
                end
                if str:find("Подсветка напарника в чате") then
                    inifiles.Settings.LightingPara = not inifiles.Settings.LightingPara
                    settings_save()
                    ShowDialog1(1)
                end
                if str:find("Остановка фуры после разгрузки") then
                    inifiles.Settings.Stop = not inifiles.Settings.Stop
                    settings_save()
                    ShowDialog1(1)
                end
                if str:find("Синхронизация") then
                    inifiles.Settings.transponder = not inifiles.Settings.transponder
                    settings_save()
                    ShowDialog1(1)
                end
                if str:find("Карта с позицией") then
                    inifiles.Settings.fastmap = not inifiles.Settings.fastmap
                    settings_save()
                    ShowDialog1(1)
                end
                if str:find("Скрывать чат профсоюза") then
                    inifiles.Settings.ChatOFF = not inifiles.Settings.ChatOFF
                    settings_save()
                    ShowDialog1(1)
                end
                if str:find("только в фуре") then
                    inifiles.Settings.chat_in_truck = not inifiles.Settings.chat_in_truck
                    settings_save()
                    ShowDialog1(1)
                end
                if str:find("Отправка мониторинга в чат") then
                    inifiles.Settings.ChatDoklad = not inifiles.Settings.ChatDoklad
                    settings_save()
                    ShowDialog1(1)
                end
                if str:find("Выделение Портов") then
                    inifiles.Settings.highlight_jf = not inifiles.Settings.highlight_jf
                    settings_save()
                    ShowDialog1(1)
                end
                if str:find("Выделение цены") then
                    inifiles.Settings.LightingPrice = not inifiles.Settings.LightingPrice
                    settings_save()
                    ShowDialog1(1)
                end
                if str:find("Цвет подсветки напарника") then
                    if dialogTextToList[list + 1] ~= nil then
                        ShowDialog1(
                            2,
                            dialogTextToList[list + 1],
                            inifiles.Settings.ColorPara,
                            true,
                            "Settings",
                            "ColorPara"
                        )
                    end
                end
                if str:find("Platinum VIP") then
                    inifiles.platinum.status = not inifiles.platinum.status
                    settings_save()
                    ShowDialog1(1)
                end
                if str:find("Шрифт") then
                    if dialogTextToList[list + 1] ~= nil then
                        ShowDialog1(2, dialogTextToList[list + 1], inifiles.Render.FontName, true, "Render", "FontName")
                    end
                end
                if str:find("Размер") then
                    if dialogTextToList[list + 1] ~= nil then
                        ShowDialog1(
                            2,
                            dialogTextToList[list + 1],
                            inifiles.Render.FontSize,
                            false,
                            "Render",
                            "FontSize"
                        )
                    end
                end
                if str:find("Стиль") then
                    if dialogTextToList[list + 1] ~= nil then
                        ShowDialog1(
                            2,
                            dialogTextToList[list + 1],
                            inifiles.Render.FontFlag,
                            false,
                            "Render",
                            "FontFlag"
                        )
                    end
                end
                if str:find("Цвет первый") then
                    if dialogTextToList[list + 1] ~= nil then
                        ShowDialog1(2, dialogTextToList[list + 1], inifiles.Render.Color1, true, "Render", "Color1")
                    end
                end
                if str:find("Цвет второй") then
                    if dialogTextToList[list + 1] ~= nil then
                        ShowDialog1(2, dialogTextToList[list + 1], inifiles.Render.Color2, true, "Render", "Color2")
                    end
                end
                if str:find("Цена авто%-загрузки") then
                    if dialogTextToList[list + 1] ~= nil then
                        ShowDialog1(2, dialogTextToList[list + 1], inifiles.Price.Load, false, "Price", "Load")
                    end
                end
                if str:find("Цена авто%-разгрузки") then
                    if dialogTextToList[list + 1] ~= nil then
                        ShowDialog1(2, dialogTextToList[list + 1], inifiles.Price.UnLoad, false, "Price", "UnLoad")
                    end
                end
                if str:find("Кнопка отображения меню") then
                    ShowDialog1(4, 1)
                end
                if str:find("Задержка") then
                    inifiles.Settings.AutoWait = not inifiles.Settings.AutoWait
                    settings_save()
                    ShowDialog1(1)
                end
                if str:find("Кнопка для работы без фуры") then
                    ShowDialog1(4, 2)
                end
                if str:find("Кнопка для отображения карты") then
                    ShowDialog1(4, 3)
                end
                if str:find("Локальная блокировка участников") then
                    LocalBlock(1)
                end
                if str:find("Уведомления когда Вас установили напарником") then
                    inifiles.Settings.NewPairMSG = not inifiles.Settings.NewPairMSG
                    settings_save()
                    ShowDialog1(1)
                end
                if str:find("Авто%-Очистка неиспользуемой памяти скрипта") then
                    inifiles.Settings.AutoClear = not inifiles.Settings.AutoClear
                    settings_save()
                    ShowDialog1(1)
                end
                if str:find("Очистить неиспользуемую память скрипта") then
                    local mem_do = string.format('%0.2f MB', (tonumber(gcinfo()) / 1000))
                    collectgarbage("step")
                    sampAddChatMessage('Памяти очищена. Было: '..mem_do..'. Стало: '..string.format('%0.2f MB', (tonumber(gcinfo()) / 1000)), -1)
                    ShowDialog1(1)
                end
                if str:find("Подробная статистика") then
                    ShowStats(1)
                end
                if str:find("Контакты автора") then
                    ShowDialog1(3)
                end
                if str:find("Перезагрузка скрипта") then
                    thisScript():reload()
                end
            end
        end
    end
    if caption == "Truck-HUD: Изменение настроек" then
        if d[7] then
            d[7] = false
            sampSetCurrentDialogEditboxText(inifiles[d[5]][d[6]])
        end
        if result then
            if button == 1 then
                local gou = (d[4] and (#input > 0 and true or false) or (input:find("%d+") and true or false))
                if gou then
                    d[3] = (d[4] and tostring(input) or tonumber(input))
                    inifiles[d[5]][d[6]] = d[3]
                    settings_save()
                    if d[5]:find("Render") then
                        renderReleaseFont(font)
                        font =
                            renderCreateFont(
                            inifiles.Render.FontName,
                            inifiles.Render.FontSize,
                            inifiles.Render.FontFlag
                        )
                    end
                    ShowDialog1(1)
                else
                    ShowDialog1(d[1], d[2], d[3], d[4], d[5], d[6])
                end
            else
                ShowDialog1(1)
            end
        end
    end
    if caption == "Truck-HUD: Редактор HUD" then
        if result then
            if button == 1 then
                local text = getClipboardText()
                if #text > 1 then
                    inifiles.Settings.stats_text = text
                    settings_save()
                else
                    inifiles.Settings.stats_text = defaultMon
                    settings_save()
                end
            end
            ShowDialog1(1)
        end
    end
    if caption == "Truck-HUD: Контакты автора" then
        if result then
            if button == 1 then
                if list == 0 then
                    setClipboardText("Serhiy_Rubin")
                end
                if list == 1 then
                    setClipboardText("https://vk.com/id353828351")
                end
                if list == 2 then
                    setClipboardText("https://vk.com/club161589495")
                end
                if list == 3 then
                    setClipboardText("serhiyrubin")
                end
                if list == 4 then
                    setClipboardText("Serhiy_Rubin#3391")
                end
                ShowDialog1(3)
            else
                ShowDialog1(1)
            end
        end
    end
    if caption == 'Truck-HUD: Биндер' then
        if result then
            if button == 1 and #input > 0 then
                if d[2] == 1 then
                    if not binder_mode_sms then
                        inifiles.binder[#inifiles.binder + 1] = input
                    else
                        inifiles.binder_sms[#inifiles.binder_sms + 1] = input
                    end
                    settings_save()
                elseif d[2] == 2 then
                    if not binder_mode_sms then
                        inifiles.binder[d[3]] = input
                    else
                        inifiles.binder_sms[d[3]] = input
                    end
                    settings_save()
                end
            end
        end
    end
    if caption == "Truck-HUD: Статистика" then
        if result then
           WhileShowStats(button, list)
        end
    end
    if caption == "Truck-HUD: Режим пары" then
        if result then
            if button == 1 then
                if string.find(input, "(%d+)") then
                    pair_mode_id = tonumber(string.match(input, "(%d+)"))
                    if sampIsPlayerConnected(pair_mode_id) then
                        error_message(1, '')
                        para_message_send = nil
                        pair_mode_name = sampGetPlayerNickname(pair_mode_id)
                        menu[4][1] = "SMS » " .. pair_mode_name .. "[" .. pair_mode_id .. "]"
                        pair_mode = true
                        menu[4].run = true
                        transponder_delay = 100
                    else
                        pair_mode_id = -1
                        pair_mode = false
                        menu[4].run = false
                        sampAddChatMessage("Ошибка! Игрок под этим ID не в сети.", -1)
                    end
                end
            else
                pair_mode = false
                menu[4].run = false
            end
        end
    end
end

function doPair()
    if pair_mode then
        if not sampIsPlayerConnected(pair_mode_id) or sampGetPlayerNickname(pair_mode_id) ~= pair_mode_name then
            pair_mode = false
            menu[4].run = false
            sampAddChatMessage(
                "Напарник " .. pair_mode_name .. "[" .. pair_mode_id .. "]" .. " вышел из игры. Режим пары выключен.",
                -1
            )
            if auto then
                auto = false
                menu[2].run = false
                sampAddChatMessage("Режим АВТО TruckHUD выключен!", -1)
            end
        end

        if pair_table["pos"] ~= nil then
            local x, y, z = getCharCoordinates(playerPed)
            local result_find = false
            for i = 1, #parking_pair do
                for k,v in pairs(parking_pair[i]) do
                    local not_i = (k == 1 and 2 or 1)
                    local pair_dist = getDistanceBetweenCoords3d(pair_table["pos"]["x"], pair_table["pos"]["y"], pair_table["pos"]["z"], parking_pair[i][not_i][1], parking_pair[i][not_i][2], parking_pair[i][not_i][3])
                    local player_dist = getDistanceBetweenCoords3d(x, y, z, v[1], v[2], v[3])

                    if player_dist <= v[4] then
                        pair_ready = (pair_dist <= parking_pair[i][not_i][4] and true or false)
                        player_ready = (player_dist <= v[4] and true or false)
                        result_find = true
                        break
                    end
                end
            end
            if not result_find then
                pair_ready = false
                player_ready = false
            end
        else
            pair_ready = false
            player_ready = false
        end
    end
end

function doPickup()
    if script_run then
        for k, v in pairs(pickupLoad) do
            local X, Y, Z = getDeadCharCoordinates(PLAYER_PED)
            local distance = getDistanceBetweenCoords3d(X, Y, Z, v[1], v[2], v[3])
            if inifiles.Settings.pickup and distance <= 15.0 and isTruckCar() then
                if v.pickup == nil then
                    result, v.pickup = createPickup(19135, 1, v[1], v[2], v[3])
                end
            else
                if v.pickup ~= nil then
                    if doesPickupExist(v.pickup) then
                        removePickup(v.pickup)
                        v.pickup = nil
                    end
                end
            end
        end
    else
        for k, v in pairs(pickupLoad) do
            if v.pickup ~= nil then
                if doesPickupExist(v.pickup) then
                    removePickup(v.pickup)
                    v.pickup = nil
                end
            end
        end
    end
end

function check_press_key(table)
    local result = false
    local result_key_text = ""
    for i = 1, #table do
        if isKeyDown(vkeys[table[i]]) then
            result = true
            result_key_text = table[i]:gsub("VK_", "")
            break
        end
    end
    return result, result_key_text
end

cruise = false
function doCruise()
    while true do
        wait(0)
        if inifiles.Settings.Cruise and script_run then
            additional_key_stop =  { "VK_W", "VK_S" }
            if not isCharInAnyCar(playerPed) or not isCarEngineOn(storeCarCharIsInNoSave(playerPed)) then
                if cruise then
                    cruise = false
                    printStringNow('~R~cruise control - OFF', 1500)
                end
            end
            if isCharInAnyCar(playerPed) and not sampIsChatInputActive() and not sampIsDialogActive() and not sampIsCursorActive() then
                if not cruise and isKeyDown(vkeys["VK_W"]) and isKeyDown(vkeys[inifiles.Settings.Key4]) then
                    cruise = true
                    printStringNow('~G~cruise control - ON', 1500)
                    repeat
                        wait(100)
                    until not isKeyDown(vkeys["VK_W"])
                elseif cruise and (isKeyDown(vkeys[inifiles.Settings.Key4]) or select(1, check_press_key(additional_key_stop))) then
                    cruise = false
                    printStringNow('~R~cruise control - OFF', 1500)
                end
            end
            if cruise then
                setGameKeyState(16, 255)
            end
        end
    end
end

function doRenderStats()
    if pos[1] then
        sampSetCursorMode(3)
        local X, Y = getCursorPos()
        inifiles.Settings.X1, inifiles.Settings.Y1 = X, Y + 15
        if isKeyJustPressed(1) then
            settings_save()
            pos[1] = false
            sampSetCursorMode(0)
        end
    end

    if pair_timestamp ~= nil then
        local afk_wait = (live-pair_afk_stop.player_live > 3 and live-pair_afk_stop.player_live or
        (pair_timestamp-pair_afk_stop.pair_live > 3 and pair_timestamp-pair_afk_stop.pair_live or 0))
        if afk_wait > 0 then
            pair_afk_stop.auto_stop = os.time()
        end
        pair_afk_stop.player_live = live
        pair_afk_stop.pair_live = pair_timestamp
    end

    local X, Y, c1, c2 = inifiles.Settings.X1, inifiles.Settings.Y1, inifiles.Render.Color1, inifiles.Render.Color2
    local down = (renderGetFontDrawHeight(font) / 6)
    local height = (renderGetFontDrawHeight(font) - (renderGetFontDrawHeight(font) / 20))
    if control then
        if drawClickableText("{" .. c2 .. "}[Смена позиции]", X, Y) then
            pos[1] = true
        end
    end
    Y = Y + height
    sec_timer = (inifiles.platinum.status and 120 or 180)
    timer_secc = sec_timer - os.difftime(msk_timestamp, timer)
    local ost_time = 3600 - (os.date("%M", msk_timestamp) * 60) + (os.date("%S", msk_timestamp))
    local greys = 0
    if workload == 1 then
        if timer_secc > 0 then
            if ost_time > timer_secc then
                ost_time = ost_time - timer_secc
                greys = 1
            else
                greys = 0
            end
        end
    end
    greys = greys + math.floor(ost_time / 360)
    if timer_secc >= (sec_timer - 3) and workload == 0 and isTruckCar() and inifiles.Settings.Stop then
        setGameKeyState(6, 255)
    end
    timer_min, timer_sec = math.floor(timer_secc / 60), timer_secc % 60
    strok =
        (timer_secc >= 0 and
        (workload == 1 and
            string.format(
                "{%s}До разгрузки {%s}%d:%02d",
                inifiles.Render.Color1,
                (timer_secc <= 10 and "b50000" or inifiles.Render.Color2),
                timer_min,
                timer_sec
            ) or
            string.format(
                "{%s}До загрузки {%s}%d:%02d",
                inifiles.Render.Color1,
                (timer_secc <= 10 and "b50000" or inifiles.Render.Color2),
                timer_min,
                timer_sec
            )) or
        (workload == 1 and string.format("{%s}Можно разгружать", inifiles.Render.Color1) or
            string.format("{%s}Можно загружать", inifiles.Render.Color1)))
    if auto then
        if control then
            local delta = getMousewheelDelta()
            if delta ~= 0 then
                ChangeCena(delta)
            end
        end
        local autoColor = (autoh and inifiles.Render.Color2 or "d90b0b")
        str =
            (inifiles.Price[(workload == 1 and "UnLoad" or "Load")] ~= 0 and
            " {" ..
                autoColor ..
                    "}[" ..
                        (workload == 1 and "Un" or "") ..
                            "Load: " .. inifiles.Price[(workload == 1 and "UnLoad" or "Load")] .. "] " or
            " {" .. autoColor .. "}[" .. (workload == 1 and "Un" or "") .. "Load] ")


        if os.difftime(msk_timestamp, timer) > 178 and isPairModeActive() and os.time() - pair_afk_stop.auto_stop <= 3 and (unload_location or load_location) then
            printStyledString("Wait afk " .. (3 - (os.time() - pair_afk_stop.auto_stop)), 1111, 5)
        end

        if
         os.difftime(msk_timestamp, timer) > sec_timer and
         autoh and
         (not isPairModeActive() or (isPairModeActive() and os.time() - pair_afk_stop.auto_stop >= 3)) and
         (not isPairModeActive() or (isPairModeActive() and (msk_timestamp - pair_timestamp) < 5)) and
         (not isPairModeActive() or (isPairModeActive() and (pair_ready and player_ready))) and
         not (isPairModeActive() and inifiles.Settings.auto_load_unload_kd_pair_use and base[pair_mode_name].gruz == current_load and os.difftime(msk_timestamp, base[pair_mode_name].timer) <= sec_timer)
        then
            if workload == 1 then
                if unload_location then
                    local dp = {ls = "sf", sf = "ls"} -- определить порт
                    local dport, ds = string.match(current_warehouse, "(..)(.)") -- место загрузки
                    local dcena =
                        (inifiles.tmonitor[dp[dport] .. ds] + inifiles.tmonitor[current_warehouse]) - prices_3dtext[current_warehouse]
                        -- цена в другом порту f= цена груза в другом порту + цена в этом порту - цена на 3D тексте этом порту
                    if inifiles.Price.UnLoad ~= 0 then
                        if price_frozen then
                            if tonumber(prices_3dtext[current_warehouse]) == tonumber(inifiles.Price.UnLoad) then
                                autoh, delay.unload = (dcena ~= 900 and true or false), (dcena ~= 900 and 1 or delay.unload)
                            end
                        else
                            if tonumber(prices_3dtext[current_warehouse]) >= tonumber(inifiles.Price.UnLoad) then
                                autoh, delay.unload = (dcena ~= 900 and true or false), (dcena ~= 900 and 1 or delay.unload)
                            end
                        end
                    else
                        autoh, delay.unload = (dcena ~= 900 and true or false), (dcena ~= 900 and 1 or delay.unload)
                    end
                end
            else
                if load_location then
                    if inifiles.Price.Load ~= 0 then
                        if
                            (price_frozen and
                                tonumber(prices_3dtext[current_warehouse]) == tonumber(inifiles.Price.Load)) or
                                (not price_frozen and
                                    tonumber(prices_3dtext[current_warehouse]) <= tonumber(inifiles.Price.Load))
                         then
                            if inifiles.Settings.AutoWait then
                                if (msk_timestamp - wait_auto) <= 3 then
                                    printStyledString("Wait load " .. (3 - (msk_timestamp - wait_auto)), 1111, 5)
                                end
                                if (msk_timestamp - wait_auto) > 3 then
                                    delay.load, autoh = 1, false
                                end
                            else
                                delay.load, autoh = 1, false
                            end
                        end
                    else
                        delay.load, autoh = 1, false
                    end
                end
            end
        end
        if drawClickableText(str, (X + renderGetFontDrawTextLength(font, strok)), Y) then
            if autoh then
                if workload == 1 then
                    inifiles.Price.UnLoad = 0
                else
                    inifiles.Price.Load = 0
                end
                settings_save()
            else
                delay.load = 0
                delay.unload = 0
                autoh = true
            end
        end
        if price_frozen or control then
            if drawClickableText("=", (X + renderGetFontDrawTextLength(font, strok .. str)), Y) then
                price_frozen = not price_frozen
            end
        end
        if isKeyDown(vkeys[inifiles.Settings.Key1]) and (isTruckCar() or isKeyDown(90)) then
            if
                drawClickableText(
                    "+",
                    (X + renderGetFontDrawTextLength(font, strok) + (renderGetFontDrawTextLength(font, str) / 3)),
                    (Y - height)
                )
             then
                ChangeCena(1)
            end
            if
                drawClickableText(
                    "-",
                    (X + renderGetFontDrawTextLength(font, "+" .. strok) + (renderGetFontDrawTextLength(font, str) / 2)),
                    (Y - height)
                )
             then
                ChangeCena(0)
            end
        end
    end
    drawClickableText(strok, X, Y)
    local stats_array = split(inifiles.Settings.stats_text,'!n!')
    local stats_info = {
        ['!m!'] = string.format('%0.2f mb', (tonumber(gcinfo()) / 1000)),
        ['!skill!'] = inifiles.Trucker.Skill,
        ['!skill_poc!'] = inifiles.Trucker.ProcSkill,
        ['!skill_reys!'] = inifiles.Trucker.ReysSkill,
        ['!rang!'] = inifiles.Trucker.Rank,
        ['!rang_poc!'] = inifiles.Trucker.ProcRank,
        ['!rang_reys!'] = inifiles.Trucker.ReysRank,
        ['!zp_hour!'] = inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].hour[os.date("%H", msk_timestamp)].zp,
        ['!max_zp!'] = inifiles.Trucker.MaxZP,
        ['!profit!'] = inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].day.pribil,
        ['!reys_hour!'] = inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].hour[os.date("%H", msk_timestamp)].razgruzkacount,
        ['!reys_day!'] = inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].day.razgruzkacount,
        ['!left_reys!'] = greys,
        ['!profit_hour!'] = inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].hour[os.date("%H", msk_timestamp)].pribil,
        ['!all_zp!'] = inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].day.zp
    }

    for k, v in pairs(stats_array) do
        for i, s in pairs(stats_info) do
            if v:find(i) then
                v = v:gsub(i, s)
            end
        end
        if v:find('!mn!') then
            v = v:gsub('!mn!', '')
            Y = Y + down + height
        else
            Y = Y + height
        end
        drawClickableText(v, X, Y)
    end
    if inifiles.Settings.pairinfo and pair_mode and pair_status == 200 and pair_table ~= nil and pair_table["pos"] ~= nil and base[pair_mode_name] ~= nil then
        local afk = msk_timestamp - pair_timestamp
        local timer_d = sec_timer - (base[pair_mode_name].timer > 1000 and os.difftime(msk_timestamp, base[pair_mode_name].timer) or (sec_timer+1))
        local color = ( not player_ready and "" or (
            pair_ready and "{07a817}" or "{d90b0b}"
        ))
        string_render, Y = string.format(" {%s}%s%s[%s]%s", c2, color, pair_mode_name, pair_mode_id, (afk > 5 and ' [AFK: '..math.ceil(afk)..']' or '')), Y + height + down
        drawClickableText(string_render, X, Y)
        local para_pos = FindSklad(pair_table["pos"]["x"], pair_table["pos"]["y"], pair_table["pos"]["z"])
        string_render, Y = string.format("{%s} [{%s}%s{%s}] %s (%s m)", c2, (timer_d < 11 and (timer_d > 0 and 'b50000' or c2) or c2), (timer_d > 0 and string.format('%d:%02d', math.floor(timer_d / 60), timer_d % 60) or '0:00'), c2, para_pos.text, math.ceil(para_pos.dist)), Y + height
        drawClickableText(string_render, X, Y)
    end

    if delay.skill == -1 then
        delay.skill = 1
    end
end

function isPairModeActive()
    if pair_mode and pair_status == 200 and pair_table ~= nil and pair_table["pos"] ~= nil and base[pair_mode_name] ~= nil then
        return true
    end
end

function renderStringMON(X, Y, dist, text1, text2, sendtext1, sendtext2, dist2, text3, text4, sendtext3, sendtext4)
    if drawClickableText(text1, X, Y) then
        sampSendChat( string.format("%s %s м.", sendtext1, dist) )
    end
    local x = (X + renderGetFontDrawTextLength(font, text1))
    if drawClickableText(text2, x, Y) then
        sampSendChat( string.format("%s", sendtext2) )
    end

    local x = x + renderGetFontDrawTextLength(font, text2)
    if drawClickableText(text3, x, Y) then
        sampSendChat( string.format("%s %s м.", sendtext3, dist2) )
    end
    if drawClickableText(text4, x + renderGetFontDrawTextLength(font, text3), Y) then
        sampSendChat( string.format("%s", sendtext4) )
    end
end

function doRenderMon()
    if pos[2] then
        sampSetCursorMode(3)
        local X, Y = getCursorPos()
        inifiles.Settings.X2, inifiles.Settings.Y2 = X, Y
        if isKeyJustPressed(1) then
            settings_save()
            pos[2] = false
            sampSetCursorMode(0)
        end
    end

    local X, Y, c1, c2 = inifiles.Settings.X2, inifiles.Settings.Y2, inifiles.Render.Color1, inifiles.Render.Color2
    local height = renderGetFontDrawHeight(font)

    local A1 = os.difftime(msk_timestamp, mon_time)
    local A2 = os.difftime(msk_timestamp, mon_ctime)
    stimer = (A2 >= A1 and A1 or A2)
    local hour, minute, second = stimer / 3600, math.floor(stimer / 60), stimer % 60
    send_time_mon = (hour >= 1 and string.format("%02d:%02d:%02d", math.floor(hour), minute - (math.floor(hour) * 60), second) or string.format("%02d:%02d", minute, second))
    rdtext = string.format("Склады. %s", send_time_mon)
    if drawClickableText(rdtext, X, Y) then
        transponder_delay = 100
    end

    local secund = os.difftime(msk_timestamp, mon_life)
    if secund == 3 or secund == 1 then c2 = "ff0000" end
    local pX, pY, pZ = getDeadCharCoordinates(PLAYER_PED)

    local replace_location = {
        ["Н1"] = { "Нефтезавод №1", "n1", "Нефть 1" },
        ["Н2"] = { "Нефтезавод №2", "n2", "Нефть 2" },
        ["У1"] = { "Склад Угля №1", "y1", "Уголь 1" },
        ["У2"] = { "Склад Угля №2", "y2", "Уголь 2" },
        ["Л1"] = { "Лесопилку №1", "l1", "Лес 1" },
        ["Л2"] = { "Лесопилку №2", "l2", "Лес 2" }
    }

    local text_chat = "/jf chat "
    if inifiles.Settings.binder_sms_mode and binder_mode_sms then
        text_chat = "/sms "..pair_mode_id.." "
    end

    local text_render_mon = { "Н1", "Н2", "У1", "У2", "Л1", "Л2" }
    local newX = X
    Y = Y + height
    for i = 1, #text_render_mon do
        local pos = location_pos[replace_location[text_render_mon[i]][3]]
        local text_render_1 = string.format("  {%s}%s: ", c1, text_render_mon[i])
        local text_render_2 = string.format("{%s}%03d", c2, prices_mon[replace_location[text_render_mon[i]][2]])
        local text_send_1 = string.format("%sЕду на %s. До цели: %d м.", text_chat, replace_location[text_render_mon[i]][1], math.ceil(getDistanceBetweenCoords3d(pX, pY, pZ, pos.x, pos.y, pos.z)) )
        local text_send_2 = string.format("%sКто едет на %s?", text_chat, replace_location[text_render_mon[i]][1])

        if drawClickableText(text_render_1, newX, Y) then
            sampSendChat(text_send_1)
        end
        newX = newX + renderGetFontDrawTextLength(font, text_render_1)
        if drawClickableText(text_render_2, newX, Y) then
            sampSendChat(text_send_2)
        end
        newX = newX + renderGetFontDrawTextLength(font, text_render_2)

        if math.fmod(i, 2) == 0 then
            Y = Y + height
            newX = X
        end
    end

    if control and workload == 1 then
        if drawClickableText("?", X - renderGetFontDrawTextLength(font, "  "), Y) then
            sampSendChat(text_chat .. what_is_uploaded[current_load] .. " в ЛС едет?")
        end
    end
    local string = string.format("{%s}Порт ЛС.\n  Н: {%s}%03d {%s}У: {%s}%03d {%s}Л: {%s}%03d", c1, c2, prices_mon.lsn, c1, c2, prices_mon.lsy, c1, c2, prices_mon.lsl)
    if drawClickableText(string, X, Y) then
        local dist = getDistanceBetweenCoords3d(pX, pY, pZ, location_pos["Порт ЛС"].x, location_pos["Порт ЛС"].y, location_pos["Порт ЛС"].z)
        if workload ~= 0 then
            local text = string.format("%sВезу %s в Порт ЛС. До цели: %0.2d м.", text_chat, what_is_uploaded[current_load], dist)
            sampSendChat(text)
        else
            local text = string.format("%sЕду в Порт ЛС. До цели: %0.2d м.", text_chat, dist)
            sampSendChat(text)
        end
    end
    Y = Y + (height * 2)
    if control and workload == 1 then
        if drawClickableText("?", X - renderGetFontDrawTextLength(font, "  "), Y) then
            sampSendChat("/jf chat " .. what_is_uploaded[current_load] .. " в СФ едет?")
        end
    end
    local string = string.format("{%s}Порт СФ.\n  Н: {%s}%03d {%s}У: {%s}%03d {%s}Л: {%s}%03d", c1, c2, prices_mon.sfn, c1, c2, prices_mon.sfy, c1, c2, prices_mon.sfl)
    if drawClickableText(string, X, Y) then
        local dist = getDistanceBetweenCoords3d(pX, pY, pZ, location_pos["Порт СФ"].x, location_pos["Порт СФ"].y, location_pos["Порт СФ"].z)
        if workload ~= 0 then
            local text = string.format("%sВезу %s в Порт СФ. До цели: %0.2d м.", text_chat, what_is_uploaded[current_load], dist)
            sampSendChat(text)
        else
            local text = string.format("%sЕду в Порт СФ. До цели: %0.2d м.", text_chat, dist)
            sampSendChat(text)
        end
    end
    if control then
        Y = Y + (height * 2)
        if drawClickableText("{" .. inifiles.Render.Color2 .. "}[Смена позиции]", X, Y) then
            pos[2] = true
        end
        Y = Y + height
        if drawClickableText("{" .. inifiles.Render.Color2 .. "}[Отправить в чат]", X, Y) then
            if (unload_location or load_location) then
                delay.mon = 1
                delay.chatMon = -1
            else
                SendMonText = string.format("/jf chat [ЛС H:%d У:%d Л:%d] [1 H:%d У:%d Л:%d] [2 H:%d У:%d Л:%d] [CФ H:%d У:%d Л:%d] [%s]", (prices_mon.lsn / 100), (prices_mon.lsy / 100), (prices_mon.lsl / 100), (prices_mon.n1 / 100), (prices_mon.y1 / 100), (prices_mon.l1 / 100), (prices_mon.n2 / 100), (prices_mon.y2 / 100), (prices_mon.l2 / 100), (prices_mon.sfn / 100), (prices_mon.sfy / 100), (prices_mon.sfl / 100), send_time_mon)
                sampSendChat(SendMonText)
            end
        end
    end
end

function doRenderBind()
    if pos[3] then
        sampSetCursorMode(3)
        local X, Y = getCursorPos()
        inifiles.Settings.X3, inifiles.Settings.Y3 = X, Y + 15
        if isKeyJustPressed(1) then
            settings_save()
            pos[3] = false
            sampSetCursorMode(0)
        end
    end
    if script_run and inifiles.Settings.Binder and control or pos[3] then
        local X, Y = inifiles.Settings.X3, inifiles.Settings.Y3
        local plus = (renderGetFontDrawHeight(font) + (renderGetFontDrawHeight(font) / 10))
        if drawClickableText("{" .. inifiles.Render.Color2 .. "}[Смена позиции]", X, Y) then
            pos[3] = true
        end
        if pair_mode then
            local color = (binder_mode_sms and "{06940f}" or "{d10000}")
            if drawClickableText(color.."[SMS]", X + renderGetFontDrawTextLength(font,"[Смена позиции] "), Y) then
                binder_mode_sms = not binder_mode_sms
            end
        end
        local array = (binder_mode_sms and inifiles.binder_sms or inifiles.binder)
        for k, string in pairs(array) do
            old_string = string
            if string.find(string, "!НикПары") then
                local nick = " "
                if sampIsPlayerConnected(pair_mode_id) then
                    nick = sampGetPlayerNickname(pair_mode_id):gsub("_", " ")
                end
                string = string:gsub("!НикПары", nick)
            end
            if string.find(string, "!ИдПары") then
                string = string:gsub("!ИдПары", pair_mode_id)
            end
            if string.find(string, "!КД") then
                local min, sec = timer_min, timer_sec
                if min < 0 then min, sec = 0, 0 end
                string = string:gsub("!КД", string.format("%d:%02d", min, sec))
            end
            if string.find(string, "!Груз") then
                string = string:gsub("!Груз", what_is_uploaded[current_load])
            end
            if string.find(string, "!Место") then
                local x, y, z = getCharCoordinates(playerPed)
                local pos = FindSklad(x, y, z)
                string = string:gsub("!Место", string.format("%s (%s m)", pos.text, math.ceil(pos.dist)))
            end
            Y = Y + plus
            if drawClickableText(string, X, Y) then
                sampSendChat(string)
            end
            if drawClickableText("{ff0000}х", (X + renderGetFontDrawTextLength(font, string .. "  ")), Y) then
                if not binder_mode_sms then
                    table.remove(inifiles.binder, k)
                else
                    table.remove(inifiles.binder_sms, k)
                end
                settings_save()
            end
            if drawClickableText("{12a61a}/", (X + renderGetFontDrawTextLength(font, string .. "     ")), Y) then
                binder_read = old_string
                ShowDialog1(7, 2, k)
            end
        end
        Y = Y + plus
        if drawClickableText("{12a61a}Добавить строку", X, Y) then
            ShowDialog1(7, 1)
        end
    end
end

function doLocalBlock(button, list, input, caption)
    if caption:find('1') then
        if button == 1 then
            if list == 0 then
                LocalBlock(2)
            elseif list == 1 then
                LocalBlock(3)
            elseif list == 2 then
                inifiles.Settings.blacklist_inversion = not inifiles.Settings.blacklist_inversion
                settings_save()
                LocalBlock(1)
            end
        else
            ShowDialog1(1)
        end
    end
    if caption:find('2') then
        if button == 1 then
            if dialogFunc[list + 1] ~= nil then
                dialogFunc[list + 1]()
            end
            LocalBlock(2)
        else
            LocalBlock(1)
        end
    end
    if caption:find('3') then
        if button == 1 then
            if dialogFunc[list + 1] ~= nil then
                dialogFunc[list + 1]()
            end
            LocalBlock(3)
        else
            LocalBlock(1)
        end
    end
end

function LocalBlock(int, param)
    if int == 1 then
        dialogText = 'Блокировка мониторинга от пользователей\nБлокировка мониторинга с хостинга\nБлокировка мониторинга из чата\nРежим: '..(inifiles.Settings.blacklist_inversion and 'Как белый список' or 'Как черный список')
        sampShowDialog(222, 'Truck-HUD: Блокировка [1]', dialogText, 'Выбрать', 'Закрыть', 5)
    end
    if int == 2 then
        dialogFunc = {}
        dialogText = '' -- fa3620
        for k, v in pairs(base) do
            if v.tmonitor ~= nil and v.tmonitor.lsn ~= nil then
                local color = ( inifiles.blacklist[k] == nil and 'FFFFFF' or ( inifiles.blacklist[k] == true and 'fa3620' or 'FFFFFF'))
                dialogText = string.format('%s{%s}Игрок: %s\tВремя мониторинга: %s\n', dialogText, color, k, (msk_timestamp - v.tmonitor.time))
                dialogFunc[#dialogFunc + 1] = function()
                    if inifiles.blacklist[k] == nil then
                        inifiles.blacklist[k] = false
                    end
                    inifiles.blacklist[k] = not inifiles.blacklist[k]
                end
                dialogText = string.format('%s{%s}[ЛС Н:%s У:%s Л:%s] [1 Н:%s У:%s Л:%s] [2 Н:%s У:%s Л:%s] [CФ Н:%s У:%s Л:%s\n', dialogText, color, v.tmonitor.lsn, v.tmonitor.lsy,v.tmonitor.lsl,v.tmonitor.n1,v.tmonitor.y1,v.tmonitor.l1,v.tmonitor.n2,v.tmonitor.y2, v.tmonitor.l2, v.tmonitor.sfn,v.tmonitor.sfy,v.tmonitor.sfl)
                dialogFunc[#dialogFunc + 1] = dialogFunc[#dialogFunc]
                dialogText = string.format('%s \n', dialogText)
                dialogFunc[#dialogFunc + 1] = dialogFunc[#dialogFunc]
            end
        end
        settings_save()
        sampShowDialog(222, 'Truck-HUD: Блокировка [2]', dialogText, 'Выбрать', 'Назад', 2)
    end
    if int == 3 then
        dialogFunc = {}
        dialogText = '' -- fa3620
        for k, v in pairs(chat_mon) do
            if v ~= nil and v.lsn ~= nil then
                local color = ( inifiles.blacklist[k] == nil and 'FFFFFF' or ( inifiles.blacklist[k] == true and 'fa3620' or 'FFFFFF'))
                dialogText = string.format('%s{%s}Игрок: %s\tВремя мониторинга: %s\n', dialogText, color, k, (msk_timestamp - v.time))
                dialogFunc[#dialogFunc + 1] = function()
                    if inifiles.blacklist[k] == nil then
                        inifiles.blacklist[k] = false
                    end
                    inifiles.blacklist[k] = not inifiles.blacklist[k]
                end
                dialogText = string.format('%s{%s}[ЛС Н:%s У:%s Л:%s] [1 Н:%s У:%s Л:%s] [2 Н:%s У:%s Л:%s] [CФ Н:%s У:%s Л:%s\n', dialogText, color, v.lsn, v.lsy,v.lsl,v.n1,v.y1,v.l1,v.n2,v.y2, v.l2, v.sfn,v.sfy,v.sfl)
                dialogFunc[#dialogFunc + 1] = dialogFunc[#dialogFunc]
                dialogText = string.format('%s \n', dialogText)
                dialogFunc[#dialogFunc + 1] = dialogFunc[#dialogFunc]
            end
        end
        settings_save()
        sampShowDialog(222, 'Truck-HUD: Блокировка [3]', dialogText, 'Выбрать', 'Назад', 2)
    end
end

function ShowStats(int, param)
    dialogINT = int
    if int == 1 then
        dialogKeytoList = { '1' }
        dialogText = 'Статистика за всё время\n'
        local array = {}
        for k,v in pairs(inifiles.log) do
            local day, month, year = string.match(k, '(%d+)%.(%d+)%.%d%d(%d+)')
            local keydate = tonumber( string.format('%02d%02d%02d', year, month, day) )
            array[keydate] = k
        end
        for i = tonumber(os.date('%y%m%d', msk_timestamp)), 1, -1 do
            if array[i] ~= nil then
                dialogText = string.format('%s%s\n', dialogText, array[i])
                dialogKeytoList[#dialogKeytoList + 1] = array[i]
            end
        end
        dialogKeytoList[#dialogKeytoList + 1] = 'nil'
        dialogKeytoList[#dialogKeytoList + 1] = 'del'
        dialogText = string.format('%s\n \nУдалить всю статистику', dialogText)
        sampShowDialog(222, 'Truck-HUD: Статистика', dialogText, 'Выбрать', 'Назад', 2)
    end
    if int == 2 then
        dialogKeytoList = { param[1], param[1], param[1] }
        dialogText = 'Дата: '..param[1]..'\nСтатистика\nУдалить статистику'
        sampShowDialog(222, 'Truck-HUD: Статистика', dialogText, 'Выбрать', 'Назад', 5)
    end
    if int == 3 then
        dialogKeytoList = {}
        dialogText = ''
        local v = inifiles.log[param[1]][param[2]]
            if param[2] == 'day' then
                dialogKeytoList[1] = param[1]
                dialogText = string.format('Дата: %s{FFFFFF}\nПодсчет:\n %d фур на сумму %d вирт\n %d загрузок на сумму %d вирт\n %d разгрузок на сумму %d вирт\n %d заправок на сумму %d вирт\n %d починок на сумму %d вирт\n %d канистр на сумму %d вирт\n %d штрафов на сумму %d вирт\nИтоги:\n Зарплата: %d вирт\n Затраты: %d вирт\n Прибыль: %d вирт', param[1],
                    v.arendacount, v.arenda,
                    v.zagruzkacount, v.zagruzka,
                    v.razgruzkacount, v.razgruzka,
                    v.refillcount, v.refill,
                    v.repaircount, v.repair,
                    v.kanistrcount, v.kanistr,
                    v.shtrafcount, v.shtraf,
                    v.zp, (v.arenda + v.refill + v.repair + v.kanistr + v.shtraf), v.pribil)
                    dialogText = string.format('%s\n  \n Лог действий:\n', dialogText, v)
                    for k, v in pairs(inifiles.log[param[1]].event) do
                        dialogText = string.format('%s%s\n', dialogText, v)
                    end
                    sampShowDialog(222, 'Truck-HUD: Статистика', dialogText, 'Выбрать', 'Назад', 5)
            else
                local dd = {}
                local list = 0
                for k,v in pairs(v) do
                    dd[tonumber(k) + 1] = string.format('%s%02d:00\n', dialogText, tonumber(k) )
                    list = list + 1
                end
                for i = 1, 25 do
                    if dd[i] ~= nil then
                        dialogText = dd[i]..dialogText
                        dialogKeytoList[list] = { param[1], param[2],  string.format('%02d', i - 1) }
                        list = list -1
                    end
                end
                sampShowDialog(222, 'Truck-HUD: Статистика', dialogText, 'Выбрать', 'Назад', 2)
            end
    end
    if int == 4 then
        dialogKeytoList = {}
        dialogText = ''
        local v = inifiles.log[param[1]][param[2]][param[3]]
        dialogKeytoList[1] = { param[1], param[2] }
        dialogText = string.format('{FFFFFF}%02d:00 | %s\n\nПодсчет:\n %d фур на сумму %d вирт\n %d загрузок на сумму %d вирт\n %d разгрузок на сумму %d вирт\n %d заправок на сумму %d вирт\n %d починок на сумму %d вирт\n %d канистр на сумму %d вирт\n %d штрафов на сумму %d вирт\nИтоги:\n Зарплата: %d вирт\n Затраты: %d вирт\n Прибыль: %d вирт',
            tonumber(param[3]), param[1],
            v.arendacount, v.arenda,
            v.zagruzkacount, v.zagruzka,
            v.razgruzkacount, v.razgruzka,
            v.refillcount, v.refill,
            v.repaircount, v.repair,
            v.kanistrcount, v.kanistr,
            v.shtrafcount, v.shtraf,
            v.zp, (v.arenda + v.refill + v.repair + v.kanistr + v.shtraf), v.pribil)
        sampShowDialog(222, 'Truck-HUD: Статистика', dialogText, 'Выбрать', 'Назад', 5)
    end
    if int == 5 then
        local all = {
            arenda = 0,
            arendacount = 0,
            zagruzka = 0,
            zagruzkacount = 0,
            razgruzka = 0,
            razgruzkacount = 0,
            pribil = 0,
            shtraf = 0,
            shtrafcount = 0,
            repair = 0,
            repaircount = 0,
            refill = 0,
            refillcount = 0,
            reys = 0,
            kanistr = 0,
            kanistrcount = 0,
            zp = 0
        }
        local day = 0
        for k,v in pairs(inifiles.log) do
            day = day + 1
            for i,s in pairs(v.day) do
                all[i] = all[i] + s
            end
        end
        dialogText = string.format('Статистика за %d суток{FFFFFF}\nПодсчет:\n %d фур на сумму %d вирт\n %d загрузок на сумму %d вирт\n %d разгрузок на сумму %d вирт\n %d заправок на сумму %d вирт\n %d починок на сумму %d вирт\n %d канистр на сумму %d вирт\n %d штрафов на сумму %d вирт\nИтоги:\n Зарплата: %d вирт\n Затраты: %d вирт\n Прибыль: %d вирт', day,
                    all.arendacount, all.arenda,
                    all.zagruzkacount, all.zagruzka,
                    all.razgruzkacount, all.razgruzka,
                    all.refillcount, all.refill,
                    all.repaircount, all.repair,
                    all.kanistrcount, all.kanistr,
                    all.shtrafcount, all.shtraf,
                    all.zp, (all.arenda + all.refill + all.repair + all.kanistr + all.shtraf), all.pribil)
        sampShowDialog(222, 'Truck-HUD: Статистика', dialogText, 'Выбрать', 'Назад', 5)
    end
end

function WhileShowStats(button, list)
    if dialogINT == 1 then
        if button == 1 and dialogKeytoList[list + 1] ~= nil then
            if list == 0 then
                ShowStats(5)
            else
                if dialogKeytoList[list + 1] == 'nil' then
                    ShowStats(1)
                elseif  dialogKeytoList[list + 1] == 'del' then
                    inifiles.log = {}
                    logAvailable()
                    settings_save()
                    ShowStats(1)
                else
                    ShowStats(2, { dialogKeytoList[list + 1] })
                end
            end
        else
            ShowDialog1(1)
        end
        return
    end
    if dialogINT == 2 then
        if button == 1 and dialogKeytoList[list + 1] ~= nil then
            if list == 1 then
                inifiles.log[dialogKeytoList[list + 1]] = nil
                logAvailable()
                settings_save()
                ShowStats(1)
            else
                ShowStats(3, { dialogKeytoList[list + 1], 'day'})
            end
        else
            ShowStats(1)
        end
        return
    end
    if dialogINT == 3 then
        if type(dialogKeytoList[1]) == 'table' then
            if button == 1 then
                ShowStats(4, { dialogKeytoList[list + 1][1], dialogKeytoList[list + 1][2], dialogKeytoList[list + 1][3] })
            else
                ShowStats(2, { dialogKeytoList[list + 1][1] })
            end
        else
            if button == 1 then
                ShowStats(2, { dialogKeytoList[1] })
            else
                ShowStats(2, { dialogKeytoList[1] })
            end
        end
        return
    end
    if dialogINT == 4 then
        if button == 1 then
            ShowStats(3, dialogKeytoList[1])
        else
            ShowStats(3, dialogKeytoList[1])
        end
        return
    end
    if dialogINT == 5 then
        ShowStats(1)
    end
end

function ShowDialog1(int, dtext, dinput, string_or_number, ini1, ini2)
    d[1], d[2], d[3], d[4], d[5], d[6] = int, dtext, dinput, string_or_number, ini1, ini2
    if int == 1 then
        local new = "{59fc30}[NEW]{ffffff} "
        dialogLine, dialogTextToList, iniName = {}, {}, {}
        dialogLine[#dialogLine + 1] = (script_run and "TruckHUD\t{59fc30}ON" or "TruckHUD\t{ff0000}OFF")

        if script_run then
            dialogLine[#dialogLine + 1] = "Сменить позицию статистики с таймером\t"
            dialogLine[#dialogLine + 1] = "Сменить позицию мониторинга цен\t"
            if inifiles.Settings.Binder then
                dialogLine[#dialogLine + 1] = "Сменить позицию биндера\t"
            end
        end

        dialogLine[#dialogLine + 1] =
            "Редактировать формат статистики\t"

        dialogLine[#dialogLine + 1] =
            "Cruise Control\t" .. (inifiles.Settings.Cruise == true and "{59fc30}ON" or "{ff0000}OFF")

        dialogLine[#dialogLine + 1] = "Информация о напарнике на HUD\t" .. (inifiles.Settings.pairinfo == true and "{59fc30}ON" or "{ff0000}OFF")

        dialogLine[#dialogLine + 1] = "Биндер\t" .. (inifiles.Settings.Binder == true and "{59fc30}ON" or "{ff0000}OFF")

        dialogLine[#dialogLine + 1] = "Доклады по клику на цены > в СМС напарнику\t" .. (inifiles.Settings.binder_sms_mode == true and "{59fc30}ON" or "{ff0000}OFF")

        dialogLine[#dialogLine + 1] = "Авто загрузка/разгрузка\t" .. (auto and "{59fc30}ON" or "{ff0000}OFF")

        dialogLine[#dialogLine + 1] =
            "Режим авто загрузки/разгрузки\t" ..
            (inifiles.Settings.AutoOFF == true and "{59fc30}Разовая" or "{59fc30}Постоянная")

        dialogLine[#dialogLine + 1] =
            "Учитывать КД напарника в режиме авто загрузка/разгрузка\t" ..
            (inifiles.Settings.auto_load_unload_kd_pair_use == true and "{59fc30}ON" or "{ff0000}OFF")

        dialogLine[#dialogLine + 1] =
            "Задержка перед авто-загрузкой\t" .. (inifiles.Settings.AutoWait == true and "{59fc30}ON" or "{ff0000}OFF")

        dialogLine[#dialogLine + 1] =
            "Остановка фуры после разгрузки\t" .. (inifiles.Settings.Stop == true and "{59fc30}ON" or "{ff0000}OFF")

        dialogLine[#dialogLine + 1] =
            "Авто Доклады в рацию\t" .. (inifiles.Settings.Report == true and "{59fc30}ON" or "{ff0000}OFF")

        dialogLine[#dialogLine + 1] =
            "Доклады от?\t" .. (inifiles.Settings.girl == true and "{59fc30}Женщины" or "{59fc30}Мужчины")

        dialogLine[#dialogLine + 1] =
            "Авто Отправка мониторинга в чат\t" .. (inifiles.Settings.ChatDoklad and "{59fc30}ON" or "{ff0000}OFF")

        dialogLine[#dialogLine + 1] =
            (pair_mode and "Режим пары\t{59fc30}" .. pair_mode_name .. "[" .. pair_mode_id .. "]" or
            "Режим пары\t{ff0000}OFF")

        local text = { "{ff0000}OFF", "{59fc30}Нефть", "{59fc30}Уголь", "{59fc30}Дерево", "{59fc30}Все" }
        if text[inifiles.Settings.luCheckerCargo+1] ~= nil then
            dialogLine[#dialogLine + 1] =
                "Соло-чекер\t" .. (text[inifiles.Settings.luCheckerCargo+1])
        end

        dialogLine[#dialogLine + 1] =
            "Авто Доклады в SMS (режим пары)\t" .. (inifiles.Settings.SMSpara == true and "{59fc30}ON" or "{ff0000}OFF")

        dialogLine[#dialogLine + 1] =
            "Подсветка напарника в чате (режим пары)\t" ..
            (inifiles.Settings.LightingPara == true and "{59fc30}ON" or "{ff0000}OFF")

        dialogLine[#dialogLine + 1] =
            "Выделение Портов/Складов/Цен в докладах\t" ..
            (inifiles.Settings.highlight_jf == true and "{59fc30}ON" or "{ff0000}OFF")

        dialogLine[#dialogLine + 1] =
            "Выделение цены текущего груза в порту\t" ..
            (inifiles.Settings.LightingPrice == true and "{59fc30}ON" or "{ff0000}OFF")

        dialogLine[#dialogLine + 1] =
            "Скрывать чат профсоюза\t" .. (inifiles.Settings.ChatOFF == true and "{59fc30}ON" or "{ff0000}OFF")

        if inifiles.Settings.ChatOFF == false then
            dialogLine[#dialogLine + 1] =
                "Чат профсоюза только в фуре\t" .. (inifiles.Settings.chat_in_truck == true and "{59fc30}ON" or "{ff0000}OFF")
        end

        dialogLine[#dialogLine + 1] =
            "Информация на фурах дальнобойщиков\t" .. (inifiles.Settings.TruckRender == true and "{59fc30}ON" or "{ff0000}OFF")

        dialogLine[#dialogLine + 1] =
            "Убрать тюнинг колес с фур\t" .. (inifiles.Settings.Tuning == false and "{59fc30}ON" or "{ff0000}OFF")

        dialogLine[#dialogLine + 1] =
            "Синхронизация с другими пользователями\t" ..
            (inifiles.Settings.transponder == true and "{59fc30}ON" or "{ff0000}OFF")

        if inifiles.Settings.transponder then
            dialogLine[#dialogLine + 1] =
            "Карта с позицией напарника\t"..
            (inifiles.Settings.fastmap == true and "{59fc30}ON" or "{ff0000}OFF")
        end

        dialogLine[#dialogLine + 1] =
            "Цвет подсветки напарника\t{" .. inifiles.Settings.ColorPara .. "}" .. inifiles.Settings.ColorPara -- 6
        dialogTextToList[#dialogLine] =
            "{FFFFFF}Введите новый цвет в HEX\nПодобрать цвет можно через браузер\nЧтобы скопировать ссылку введите /truck url"

        dialogLine[#dialogLine + 1] = new.."Platinum VIP (2 мин кд)\t" .. (inifiles.platinum.status == true and "{59fc30}ON" or "{ff0000}OFF")

        dialogLine[#dialogLine + 1] = "Шрифт\t" .. inifiles.Render.FontName -- 7
        dialogTextToList[#dialogLine] = "{FFFFFF}Введите название шрифта"

        dialogLine[#dialogLine + 1] = "Размер\t" .. inifiles.Render.FontSize -- 8
        dialogTextToList[#dialogLine] = "{FFFFFF}Введите размер шрифта"

        dialogLine[#dialogLine + 1] = "Стиль\t" .. inifiles.Render.FontFlag -- 9
        dialogTextToList[#dialogLine] =
            "{FFFFFF}Устанавливайте стиль путем сложения.\n\nТекст без особенностей = 0\nЖирный текст = 1\nНаклонность(Курсив) = 2\nОбводка текста = 4\nТень текста = 8\nПодчеркнутый текст = 16\nЗачеркнутый текст = 32\n\nСтандарт: 13"

        dialogLine[#dialogLine + 1] = "Цвет первый\t{" .. inifiles.Render.Color1 .. "}" .. inifiles.Render.Color1 -- 10
        dialogTextToList[#dialogLine] =
            "{FFFFFF}Введите новый цвет в HEX\nПодобрать цвет можно через браузер\nЧтобы скопировать ссылку введите /truck url"

        dialogLine[#dialogLine + 1] = "Цвет второй\t{" .. inifiles.Render.Color2 .. "}" .. inifiles.Render.Color2 -- 11
        dialogTextToList[#dialogLine] =
            "{FFFFFF}Введите новый цвет в HEX\nПодобрать цвет можно через браузер\nЧтобы скопировать ссылку введите /truck url"

        dialogLine[#dialogLine + 1] = "Цена авто-загрузки\t" .. inifiles.Price.Load -- 12
        dialogTextToList[#dialogLine] = "{FFFFFF}Введите цену Авто-Загрузки"

        dialogLine[#dialogLine + 1] = "Цена авто-разгрузки\t" .. inifiles.Price.UnLoad -- 13
        dialogTextToList[#dialogLine] = "{FFFFFF}Введите цену Авто-Разгрузки"

        dialogLine[#dialogLine + 1] = "Кнопка отображения меню\t" .. inifiles.Settings.Key1:gsub("VK_", "") -- 14

        dialogLine[#dialogLine + 1] = "Кнопка для работы без фуры\t" .. inifiles.Settings.Key2:gsub("VK_", "") -- 15

        dialogLine[#dialogLine + 1] = "Кнопка для отображения карты\t" .. inifiles.Settings.Key3:gsub("VK_", "") -- 16

        dialogLine[#dialogLine + 1] = "Кнопка для Cruise Control\t" .. inifiles.Settings.Key4:gsub("VK_", "") -- 16

        dialogLine[#dialogLine + 1] = "Локальная блокировка участников"

        dialogLine[#dialogLine + 1] = "Уведомления когда Вас установили напарником\t" .. (inifiles.Settings.NewPairMSG == true and "{59fc30}ON" or "{ff0000}OFF")

        dialogLine[#dialogLine + 1] = "Авто-Очистка неиспользуемой памяти скрипта\t" .. (inifiles.Settings.AutoClear == true and "{59fc30}ON" or "{ff0000}OFF")

        dialogLine[#dialogLine + 1] = "Очистить неиспользуемую память скрипта\t" .. string.format('%0.2f MB', (tonumber(gcinfo()) / 1000))

        dialogLine[#dialogLine + 1] = "Подробная статистика"

        dialogLine[#dialogLine + 1] = "Контакты автора"

        dialogLine[#dialogLine + 1] = "Перезагрузка скрипта"
        local text, list = "", 0
        for k, v in pairs(dialogLine) do
            text = text .. "[" .. list .. "] " .. v .. "\n"
            list = list + 1
        end
        sampShowDialog(222, "Truck-HUD: Настройки", text, "Выбрать", "Закрыть", 4)
    end
    if int == 2 then
        d[7] = true
        sampShowDialog(222, "Truck-HUD: Изменение настроек", dtext, "Выбрать", "Назад", 1)
    end
    if int == 3 then
        sampShowDialog(
            222,
            "Truck-HUD: Контакты автора",
            "{FFFFFF}Выбери что скопировать\t\nНик на Samp-Rp\tSerhiy_Rubin\nСтраничка {4c75a3}VK{FFFFFF}\tvk.com/id353828351\nГруппа {4c75a3}VK{FFFFFF} с модами\tvk.com/club161589495\n{10bef2}Skype{FFFFFF}\tserhiyrubin\n{7289da}Discord{FFFFFF}\tSerhiy_Rubin#3391\nПромокод\t#rubin",
            "Копировать",
            "Назад",
            5
        )
    end
    if int == 4 then
        lua_thread.create(
            function()
                wait(100)
                local key = ""
                repeat
                    wait(0)
                    if not sampIsDialogActive() then
                        sampShowDialog(
                            222,
                            "LUA Truck-HUD: Смена активации",
                            "Нажмите на любую клавишу",
                            "Выбрать",
                            "Закрыть",
                            0
                        )
                    end
                    for k, v in pairs(vkeys) do
                        if wasKeyPressed(v) and k ~= "VK_ESCAPE" and k ~= "VK_RETURN" then
                            key = k
                        end
                    end
                until key ~= ""
                local ini__name = string.format("Key%d", dtext)
                inifiles.Settings[ini__name] = key
                settings_save()
                ShowDialog1(1)
            end
        )
    end
    if int == 7 then
        sampShowDialog(
            222,
            "Truck-HUD: Биндер",
            "{FFFFFF}Поддерживает замены\n!НикПары - Заменится ником напарника\n!ИдПары - Заменится на ID напарника\n!КД - Заменится на время до загрузки/разгрузки\n!Груз - Заменится на [Без груза/Нефть/Уголь/Дерево]\n!Место - Заменится на склад/порт который ближе",
            "Сохранить",
            "Закрыть",
            1
        )

        if binder_read ~= nil then
            repeat wait(0) until sampIsDialogActive()
            sampSetCurrentDialogEditboxText(binder_read)
            binder_read = nil
        end

        if dtext == 2 then
            d[7] = true
        end
    end
    if int == 8 then
        sampShowDialog(
            222,
            "Truck-HUD: Режим пары",
            "\t{FFFFFF}Введите ID напарника\nЕму будут отсылаться SMS сообщения о ваших загрузках/разгрузках",
            "Выбрать",
            "Закрыть",
            1
        )
    end
    if int == 9 then
        setClipboardText(inifiles.Settings.stats_text..'\n\n!n! - Для новой строки\n!mn! - Используется для двойного отступа, после !n!\n!skill! - Скилл\n!skill_poc! - Проценты скилла\n!skill_reys! - Остаток рейсов до нового скилла\n!rang! - Ранг\n!rang_poc! - Проценты ранга\n!rang_reys! - Остаток рейсов для нового ранга\n!reys_hour! - Рейсов в этом часу\n!reys_day! - Рейсов за сутки\n!zp_hour! - Зарплата в этом часу\n!all_zp! - Зарплата за сутки\n!profit_hour! - Прибыль в этом часу\n!profit! - Прибыль за сутки')
        sampShowDialog(
            222,
            "Truck-HUD: Редактор HUD",
            [[{ffffff}Замены для составления HUD статистики

{ff0000}ТЕКУЩИЙ ТЕКСТ HUD ПОМЕЩЕН В ВАШ БУФЕР ОБМЕНА
СВЕРНИТЕ ИГРУ
{ff0000}ОТКРОЙТЕ БЛОКНОТ В WINDOWS И ВСТАВЬТЕ ТУДА ТЕКСТ CTRL + V
{ff0000}ПОСЛЕ ВНЕСЕНИЯ ИЗМЕНЕНИЙ СКОПИРУЙТЕ КОД СТАТИСТИКИ
РАЗВЕРНИТЕ ИГРУ И НАЖМИТЕ CОХРАНИТЬ В ДИАЛОГЕ
{FFFFFF}

ЧТОБЫ ВЕРНУТЬ ВСЕ ПО УМОЛЧАНИЮ СКОПИРУЙТЕ ЦИФРУ 0 И НАЖМИТЕ CОХРАНИТЬ
ЕСЛИ КОПИРУЮТСЯ ИЕРОГЛИФЫ ВМЕСТО РУССКИХ БУКВ - ПОВТОРИТЕ ВСЕ ТОЖЕ САМОЕ С РУССКОЙ РАКЛАДКОЙ

!n! - Для новой строки
!mn! - Используется для двойного отступа, после !n!

!skill! - Скилл
!skill_poc! - Проценты скилла
!skill_reys! - Остаток рейсов до нового скилла

!rang! - Ранг
!rang_poc! - Проценты ранга
!rang_reys! - Остаток рейсов для нового ранга

!reys_hour! - Рейсов в этом часу
!reys_day! - Рейсов за сутки

!zp_hour! - Зарплата в этом часу
!all_zp! - Зарплата за сутки

!zatrat_hour! - Затраты в этом часу
!zatrat_day! - Затраты за сутки

!profit_hour! - Прибыль в этом часу
!profit! - Прибыль за сутки]],
            "Сохранить",
            "Назад",
            0
        )
    end
end

function FindSklad(x, y, z)
    local minDist, minResult = 1000000, ""
    for name, cord in pairs(location_pos) do
        local distance = getDistanceBetweenCoords3d(x, y, z, cord.x, cord.y, cord.z)
        if distance < minDist then
            minDist = distance
            minResult = name
        end
    end
    return { text = minResult, dist = minDist }
end

function loadEvents()

    time_send_trailer_sync = 0
    function sampev.onSendVehicleSync()
        time_send_trailer_sync = os.time()
    end
    function sampev.onSendTrailerSync()
        if os.time() - time_send_trailer_sync >= 2 then
            local data = samp_create_sync_data("vehicle")
            data.send()
        end
    end
    function sampev.onVehicleSync(playerId, vehicleId, data)
       luChecker.vehicleSync(playerId, vehicleId, data)
    end
    function sampev.onTrailerSync(playerId, data)
        luChecker.trailerSync(playerId, data)
    end
    function sampev.onVehicleStreamOut(vehicleId)
        luChecker.vehicleStream(false, vehicleId)
    end
    function sampev.onSendChat(message)
        antiflood = os.clock() * 1000
    end
    function sampev.onSendCommand(cmd)
        local command, params = string.match(cmd, "^%/([^ ]*)(.*)")
        if command ~= nil and params ~= nil and command:lower() == "truck" then
            if params:lower() == " menu" then
                ShowDialog1(1)
                return false
            end
            if params:lower() == " cmd" then
                local text =
                    " /truck hud\tВкл/Выкл скрипт\n /truck auto\tВкл/Выкл Auto-Load/Unload\n /truck chat\tВкл/Выкл доклады в рацию\n /truck para\tВкл/Выкл режим пары\n /truck menu\tМеню настроек скрипта\n /truck play\tДополнительное меню управления скриптом\n /truck mon [ID]\tОтправить мониторинг другому игроку в СМС"
                sampShowDialog(222, "Команды скрипта TruckHUD", text, "Закрыть", "", 4)
                return false
            end
            if params:lower() == " hud" then
                script_run = not script_run
                if script_run then
                    delay.paycheck = 1
                end
                menu[1].run = script_run
                return false
            end
            if params:lower() == " auto" then
                auto = not auto
                menu[2].run = auto
                return false
            end
            if params:lower() == " chat" then
                inifiles.Settings.Report = not inifiles.Settings.Report
                menu[3].run = inifiles.Settings.Report
                sampAddChatMessage(
                    string.format("Авто Доклад в рацию %s", (inifiles.Settings.Report and "активирован" or "деактивирован")),
                    0xFF2f72f7
                )
                settings_save()
                return false
            end
            if params:lower() == " para" then
                if pair_mode then
                    pair_mode = false
                else
                    ShowDialog1(8)
                end
                return false
            end
            if params:lower() == " url" then
                setClipboardText("https://colorscheme.ru/color-converter.html")
                return false
            end
            if params:lower() == " users" then
                showUsers()
                return false
            end
            if params:lower():find(" mon (%d+)") then
                local id = params:lower():match(" mon (%d+)")
                return {
                    string.format(
                        "/sms %s [ЛС H:%d У:%d Л:%d][1 H:%d У:%d Л:%d][2 H:%d У:%d Л:%d][CФ H:%d У:%d Л:%d]",
                        id,
                        (prices_mon.lsn / 100),
                        (prices_mon.lsy / 100),
                        (prices_mon.lsl / 100),
                        (prices_mon.n1 / 100),
                        (prices_mon.y1 / 100),
                        (prices_mon.l1 / 100),
                        (prices_mon.n2 / 100),
                        (prices_mon.y2 / 100),
                        (prices_mon.l2 / 100),
                        (prices_mon.sfn / 100),
                        (prices_mon.sfy / 100),
                        (prices_mon.sfl / 100)
                    )
                }
            end
        end
        if params:lower():find(" server_help") then
            sampShowDialog(0, 'TruckHUD: Server Help', [[{FFFFFF}   << Основные причины проблем соединения с сервером >>

    1. Сервер отключился. Поспрашивайте других дальнобойщиков нет ли у них такой проблемы
    Если у всех такая проблема - значит сервер упал. Сообщите в группу разработчику.

    2. У скрипта нет доступа в интернет. Установлен антистиллер.]], 'Закрыть', '', 0)
            return false
        end
        antiflood = os.clock() * 1000
    end
    function sampev.onVehicleStreamIn(vehicleId, data)
        luChecker.vehicleStream(true, vehicleId, data)
        if inifiles ~= nil and not inifiles.Settings.Tuning and (data.type == 403 or data.type == 515) then
            data.modSlots[8] = 0
            return {vehicleId, data}
        end
    end

    function sampev.onServerMessage(color, message)
        if message:find("У вас .E5E4E2.PLATINUM VIP.EAC700. до %d+/%d+/%d+ %d+:%d+") then
            local year, mounth, day, hour, min = message:match("У вас .E5E4E2.PLATINUM VIP.EAC700. до (%d+)/(%d+)/(%d+) (%d+):(%d+)")
            datetime = {
                year = tonumber(year),
                month = tonumber(mounth),
                day = tonumber(day),
                hour = tonumber(hour),
                min = tonumber(min),
                sec = 5
            }
            if os.time(datetime) ~= inifiles.platinum.time then
                inifiles.platinum.time = os.time(datetime)
                settings_save()
            end
            if not inifiles.platinum.status then
                inifiles.platinum.status = true
                settings_save()
            end
        end
        if string.find(message, " Нефть: %d+ / (%d+)$") then
            maxload_int = tonumber(string.match(message, " Нефть: %d+ / (%d+)$"))
        end
        if message == " У вас бан чата!" then
            delay.chatMon = 0
            delay.chat = 0
        end
        if script_run and string.find(message, " Вы заработали (.+) вирт%. Деньги будут зачислены на ваш банковский счет в .+") then
            local string = string.match(message, " Вы заработали (.+) вирт%. Деньги будут зачислены на ваш банковский счет в .+")
            inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].hour[os.date("%H", msk_timestamp)].zp = string:find('/') and string:match('(%d+) /') or string
            if delay.paycheck == 2 then
                delay.paycheck = 0
                return false
            end
        end
        if string.find(message, " .+<.+>: .+") and not string.find(message, "%->Вопрос") and inifiles ~= nil then
            if string.find(message, my_nick) then
                if string.find(message, "ЛС Н") then
                    delay.chatMon = 0
                else
                    delay.chat = 0
                end
            end
            if inifiles.Settings.ChatOFF then
                return false
            else
                if inifiles.Settings.chat_in_truck and not isTruckCar() then
                    return false
                end
            end

            if pair_mode and inifiles.Settings.LightingPara and string.find(message, pair_mode_name) then
                paraColor = "{"..inifiles.Settings.ColorPara.."}"
                color = "0xFF" .. inifiles.Settings.ColorPara
            else
                paraColor = "{30A0A7}"
                color = "0xFF30A0A7"
            end

            local result = false
            if string.find(message, " Serhiy_Rubin%[%d+%]<.+>: .+") or string.find(message, " Rafael_Moreno%[%d+%]<.+>: .+") or string.find(message, " Warren_Ix%[%d+%]<.+>: .+") then
                result = true
                local text = message:match(" (.+)%[%d+%]<")
                message = message:gsub(" "..text.."%[", " {FFFFFF}[DEV]"..paraColor.." "..text.."[")
            end


            if script_run then
                if inifiles.Settings.highlight_jf then
                    local result = ""
                    for i = 1, #dop_chat_light do
                        if message:find(dop_chat_light[i]) then
                            result = dop_chat_light[i]
                            break
                        end
                    end
                    if result ~= "" then
                        message = message:gsub(result, "{ffffff}"..result..paraColor)
                        if message:find("(по %d+)") then
                            local text = message:match("по (%d+)")
                            message = message:gsub(" по "..text, " по {ffffff}"..text..paraColor)
                        end
                        if message:find(" в ") then
                            local text = message:match(" в (.+)")
                            if text:find(paraColor) then
                                message = message:gsub(" в ", paraColor.." в {ffffff}")
                            end
                        end
                        sampAddChatMessage(message, color)
                        return false
                    end
                end
                if pair_mode and inifiles.Settings.LightingPara and string.find(message, pair_mode_name) then
                    sampAddChatMessage(message, color)
                    return false
                end
            end
            if result then
                sampAddChatMessage(message, 0xFF30A0A7)
                return false
            end
        end
        if
            string.find(
                message,
                " (.*)<(.*)>: %[ЛС Н:(%d+) У:(%d+) Л:(%d+)%] %[1 Н:(%d+) У:(%d+) Л:(%d+)%] %[2 Н:(%d+) У:(%d+) Л:(%d+)%] %[CФ Н:(%d+) У:(%d+) Л:(%d+)%]"
            )
        then
            if (string.find(message, "Купил") or string.find(message, "Продал")) then
                nick,
                    rank,
                    prices_smon.lsn,
                    prices_smon.lsy,
                    prices_smon.lsl,
                    prices_smon.n1,
                    prices_smon.y1,
                    prices_smon.l1,
                    prices_smon.n2,
                    prices_smon.y2,
                    prices_smon.l2,
                    prices_smon.sfn,
                    prices_smon.sfy,
                    prices_smon.sfl,
                    _ =
                    string.match(
                    message,
                    " (.*)%[.+%]<(.*)>: %[ЛС Н:(%d+) У:(%d+) Л:(%d+)%] %[1 Н:(%d+) У:(%d+) Л:(%d+)%] %[2 Н:(%d+) У:(%d+) Л:(%d+)%] %[CФ Н:(%d+) У:(%d+) Л:(%d+)%] %[(.*)%]"
                )
            else
                nick,
                    rank,
                    prices_smon.lsn,
                    prices_smon.lsy,
                    prices_smon.lsl,
                    prices_smon.n1,
                    prices_smon.y1,
                    prices_smon.l1,
                    prices_smon.n2,
                    prices_smon.y2,
                    prices_smon.l2,
                    prices_smon.sfn,
                    prices_smon.sfy,
                    prices_smon.sfl =
                    string.match(
                    message,
                    " (.*)%[.+%]<(.*)>: %[ЛС Н:(%d+) У:(%d+) Л:(%d+)%] %[1 Н:(%d+) У:(%d+) Л:(%d+)%] %[2 Н:(%d+) У:(%d+) Л:(%d+)%] %[CФ Н:(%d+) У:(%d+) Л:(%d+)%]"
                )
            end
            chat_mon[nick] = prices_smon
            chat_mon[nick].time = msk_timestamp
            if inifiles.blacklist[nick] == nil then
                inifiles.blacklist[nick] = false
            end
            if (not inifiles.Settings.blacklist_inversion and inifiles.blacklist[nick] == false) or (inifiles.Settings.blacklist_inversion and inifiles.blacklist[nick] == true) then
                mon_life = msk_timestamp
                mon_ctime = msk_timestamp
                prices_mon.lsn = prices_smon.lsn * 100
                prices_mon.lsy = prices_smon.lsy * 100
                prices_mon.lsl = prices_smon.lsl * 100
                prices_mon.sfn = prices_smon.sfn * 100
                prices_mon.sfy = prices_smon.sfy * 100
                prices_mon.sfl = prices_smon.sfl * 100
                prices_mon.n1 = prices_smon.n1 * 100
                prices_mon.n2 = prices_smon.n2 * 100
                prices_mon.y1 = prices_smon.y1 * 100
                prices_mon.y2 = prices_smon.y2 * 100
                prices_mon.l1 = prices_smon.l1 * 100
                prices_mon.l2 = prices_smon.l2 * 100
            end
        end

        if string.find(message, " Нефть: (%d+) / (%d+)") then
            if current_load ~= 0 then
                check_noLoad = true
            end
            local S1, S2 = string.match(message, " Нефть: (%d+) / (%d+)")
            if tonumber(S1) ~= 0 then
                current_load = 1
                check_noLoad = false
            end
        end
        if string.find(message, " Уголь: (%d+) / (%d+)") then
            local S1, S2 = string.match(message, " Уголь: (%d+) / (%d+)")
            if tonumber(S1) ~= 0 then
                current_load = 2
                check_noLoad = false
            end
        end
        if string.find(message, " Дерево: (%d+) / (%d+)") then
            local S1, S2 = string.match(message, " Дерево: (%d+) / (%d+)")
            if tonumber(S1) ~= 0 then
                current_load = 3
                check_noLoad = false
            end
            if check_noLoad and current_load ~= 0 then
                current_load = 0
            end
        end
        if string.find(message, " Извините, мы вас немного задержим, нужно подготовить груз. Осталось (%d+) секунд") then
            local S1 =
                string.match(message, " Извините, мы вас немного задержим, нужно подготовить груз. Осталось (%d+) секунд")
            if tonumber(S1) > 3 then
                delay.load = 0
                delay.unload = 0
            end
        end

        if
            message == " У вас недостаточно денег" or message == " Нужно находиться у склада" or
                message == " Нужно находиться в порту" or
                message == " У вас нет продуктов" or
                message == " Вы прибыли без прицепа" or
                message == " Вы не в служебной машине. Нужно быть водителем" or
                message == " Вы должны находиться в порту, или на складе" or
                message == " Вы должны устроиться на работу дальнобойщика"
        then
            delay.mon, delay.chatMon = 0, 0
            delay.load = 0
            delay.unload = 0
            if auto then
                auto = false
                autoh = true
                menu[2].run = false
                message = message..". Режим АВТО TruckHUD выключен!"
                return { color, message }
            end
        end -- /truck load unload error


        if message == " Вам не доступен этот чат!" or message == " Введите: /r или /f [text]" then
            delay.chat = 0
            delay.chatMon = 0
        end -- /jf chat error

        if string.find(message, "===============%[(%d+):(%d+)%]===============") then
            payday = msk_timestamp
            write_table_log('payday', {0}, 9)
            settings_save()
        end -- Log update

        if
            message == " Сообщение доставлено" or message == " Игрок оффлайн" or
                message == " Введите: /sms [playerid / phonenumber] [текст]" or
                message == " Телефон вне зоны доступа сети"
        then
            delay.sms = 0
        end

        if string.find(message, "Загружено %d+ груза, на сумму (%d+) вирт. Скидка: %d+ вирт") and isTruckCar() then
            timer = msk_timestamp
            local Z1, Z2, Z3 = string.match(message, " Загружено (%d+) груза, на сумму (%d+) вирт. Скидка: (%d+) вирт")
            gruzLOAD = Z1
            if texts_of_reports[current_warehouse] ~= nil then
                local cena = (Z2 + Z3) / (Z1 / 1000)
                local sklad = texts_of_reports[current_warehouse]
                local modelId = getCharModel(PLAYER_PED)
                report_text =
                    (not inifiles.Settings.girl and "Загрузился" or "Загрузилась") .. " на " .. sklad .. " по " .. cena
                sms_pair_mode = report_text
                if inifiles.Settings.Report then
                    delay.chat = 1
                end
                if pair_mode and inifiles.Settings.SMSpara then
                    delay.sms = 1
                end
            end
            write_table_log('zagruzka', {Z2}, 1)
            delay.load = 0
            if script_run then
                if inifiles.Settings.ChatDoklad then
                    delay.chatMon = -1
                end
                delay.mon = 1
            end
            workload = 1
            autoh = true
            if inifiles.Settings.AutoOFF then
                auto = false
            end
        end

        if string.find(message, "Вы заработали (%d+) вирт, из которых (%d+) вирт будет добавлено к вашей зарплате") and isTruckCar() then
            pttModule()
            timer = msk_timestamp
            local Z1, Z2 =
                string.match(message, " Вы заработали (%d+) вирт, из которых (%d+) вирт будет добавлено к вашей зарплате")
            if texts_of_reports[current_warehouse] ~= nil and gruzLOAD ~= nil then
                local cena = Z1 / (gruzLOAD / 1000)
                local sklad = texts_of_reports[current_warehouse]
                local modelId = getCharModel(PLAYER_PED)
                report_text = "Разгрузил" .. (not inifiles.Settings.girl and " " or "а ") .. sklad .. " по " .. cena
                sms_pair_mode = report_text
                if inifiles.Settings.Report then
                    delay.chat = 1
                end
                if pair_mode and inifiles.Settings.SMSpara then
                    delay.sms = 1
                end
            end
            if inifiles.Trucker.MaxZP > tonumber(inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].hour[os.date("%H", msk_timestamp)].zp + Z2) then
                write_table_log('razgruzka', {Z1, Z2, (Z1 - Z2)}, 2)
            else
                if tonumber(inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].hour[os.date("%H", msk_timestamp)].zp) ~= inifiles.Trucker.MaxZP then
                    local param4 = ((tonumber(inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].hour[os.date("%H", msk_timestamp)].zp) + Z2) -
                        inifiles.Trucker.MaxZP - Z2)
                    local param5 = string.match(param4, "-(.*)")
                    write_table_log('razgruzka', {param5, param5, 0}, 2)
                end
            end
            delay.unload = 0
            if script_run then
                if inifiles.Settings.ChatDoklad then
                    delay.chatMon = -1
                end
                delay.mon = 1
                delay.skill = 1
            end
            workload = 0
            current_load = 0
            autoh = true
            if inifiles.Settings.AutoOFF then
                auto = false
            end
            delay.paycheck = 1
        end
        if message == " Не флуди!" then
            if delay.skill == 2 then
                delay.skill = 1
            end
            if delay.load == 2 then
                delay.load = 1
            end
            if delay.unload == 2 then
                delay.unload = 1
            end
            if delay.sms == 2 then
                delay.sms = 1
            end
            if delay.chat == 2 then
                delay.chat = 1
            end
            if delay.chatMon == 2 then
                delay.chatMon = 1
            end
            if delay.dir == 2 then
                delay.dir = 1
            end
        end
        if message == " У вас нет телефонного справочника!" then
            delay.dir = 0
        end
        if string.find(message, " Вы арендовали транспортное средство") and isTruckCar() then
            local message = sampGetDialogText()
            if string.find(message, "Стоимость") then
                local Z1 = string.match(message, "Стоимость аренды: {FFFF00}(%d+) вирт")
                write_table_log('arenda', {Z1}, 3)
            end
        end
        if string.find(message, " Вы заплатили штраф (%d+) вирт, Офицеру (%g+)") then
            local Z1, Z2 = string.match(message, " Вы заплатили штраф (%d+) вирт, Офицеру (%g+)")
            write_table_log('shtraf', {Z1, message}, 4)
        end
        if string.find(message, " Вашу машину отремонтировал%(а%) за (%d+) вирт, Механик (%g+)") and isTruckCar() then
            local Z1, Z2 = string.match(message, " Вашу машину отремонтировал%(а%) за (%d+) вирт, Механик (%g+)")
            write_table_log('repair', {Z1}, 5)
        end
        if string.find(message, " Автомеханик (%g+) заправил ваш автомобиль на 300 за (%d+) вирт") and isTruckCar() then
            local Z1, Z2 = string.match(message, " Автомеханик (%g+) заправил ваш автомобиль на 300 за (%d+) вирт")
            write_table_log('refill', {Z2}, 6)
        end
        if string.find(message, " Машина заправлена, за: (%d+) вирт") and isTruckCar() then
            local Z1 = string.match(message, " Машина заправлена, за: (%d+) вирт")
            write_table_log('refill', {Z1}, 7)
        end
        if string.find(message, " Вы купили канистру с 50 литрами бензина за (%d+) вирт") and isTruckCar() then
            local Z1 = string.match(message, " Вы купили канистру с 50 литрами бензина за (%d+) вирт")
            write_table_log('kanistr', {Z1}, 8)
        end
    end

    function sampev.onShowDialog(DdialogId, Dstyle, Dtitle, Dbutton1, Dbutton2, Dtext)
        if Dstyle == 0 and string.find(Dtext, "{00AB06}Дальнобойщик{CECECE}") and string.find(Dtext, "{00AB06}Механик{CECECE}") then
            local Skill, SkillP, Rank, RankP = string.match( Dtext, ".+{00AB06}Дальнобойщик{CECECE}.*Скилл: (%d+)\tОпыт: .+ (%d+%.%d+)%%.*{CECECE}Ранг: (%d+)  \tОпыт: .+ (%d+%.%d+)%%")
            if Skill ~= nil then
                SkillP = tonumber(SkillP)
                RankP = tonumber(RankP)
                Skill = tonumber(Skill)
                Rank = tonumber(Rank)
                local gruzs =
                    (Skill < 10 and 10000 or
                    (Skill < 20 and 20000 or (Skill < 30 and 30000 or (Skill < 40 and 40000 or (Skill >= 40 and 50000)))))
                local S1 = gruzs / 100 * (1.1 ^ (50 - inifiles.Trucker.Skill))
                local S2 = 10000 * (1.1 ^ inifiles.Trucker.Skill)
                local S3 = (S1 * 100) / S2
                inifiles.Trucker.ReysSkill = math.ceil((100.0 - SkillP) / S3)
                inifiles.Trucker.ProcSkill = SkillP
                if inifiles.Trucker.ProcRank ~= RankP then
                    inifiles.Trucker.ReysRank = math.ceil((100.0 - RankP) / (RankP - inifiles.Trucker.ProcRank))
                    inifiles.Trucker.ProcRank = RankP
                end
                inifiles.Trucker.Skill = Skill
                inifiles.Trucker.Rank = Rank
                inifiles.Trucker.MaxZP = math.ceil( 50000 + (2500 * (1.1 ^ Skill)) + (2500 * (1.1 ^ Rank)) )
                settings_save()
            end
            if delay.skill ~= 0 then
                delay.skill = 0
                return false
            end
        end

        if DdialogId == 22 and Dstyle == 0 and string.find(Dtext, "Заводы") then
            delay.mon = 0
            mon_life = msk_timestamp
            mon_time = msk_timestamp
            prices_mon.n1, prices_mon.n2, prices_mon.y1, prices_mon.y2, prices_mon.l1, prices_mon.l2, prices_mon.lsn, prices_mon.lsy, prices_mon.lsl, prices_mon.sfn, prices_mon.sfy, prices_mon.sfl = string.match( Dtext, "[Заводы].*Нефтезавод №1.*.*Нефть: 0.(%d+) вирт.*Нефтезавод №2.*.*Нефть: 0.(%d+) вирт.*Склад угля №1.*.*Уголь: 0.(%d+) вирт.*Склад угля №2.*.*Уголь: 0.(%d+) вирт.*Лесопилка №1.*.*Дерево: 0.(%d+) вирт.*Лесопилка №2.*.*Дерево: 0.(%d+) вирт.*[Порты].*Порт ЛС.*.*Нефть: 0.(%d+) вирт.*.*Уголь: 0.(%d+) вирт.*.*Дерево: 0.(%d+) вирт.*Порт СФ.*.*Нефть: 0.(%d+) вирт.*.*Уголь: 0.(%d+) вирт.*.*Дерево: 0.(%d+) вирт" )

            for k, v in pairs(prices_mon) do
                if string.find(tostring(prices_mon[k]), "99") then
                    prices_mon[k] = tonumber(prices_mon[k]) + 1
                end
            end

            inifiles.tmonitor = {
                n1 = prices_mon.n1,
                n2 = prices_mon.n2,
                y1 = prices_mon.y1,
                y2 = prices_mon.y2,
                l1 = prices_mon.l1,
                l2 = prices_mon.l2,
                lsn = prices_mon.lsn,
                lsy = prices_mon.lsy,
                lsl = prices_mon.lsl,
                sfn = prices_mon.sfn,
                sfy = prices_mon.sfy,
                sfl = prices_mon.sfl,
                time = msk_timestamp
            }
            settings_save()

            if delay.chatMon == -1 then
                SendMonText =
                    string.format(
                    "[ЛС Н:%d У:%d Л:%d] [1 Н:%d У:%d Л:%d] [2 Н:%d У:%d Л:%d] [CФ Н:%d У:%d Л:%d]",
                    (prices_mon.lsn / 100),
                    (prices_mon.lsy / 100),
                    (prices_mon.lsl / 100),
                    (prices_mon.n1 / 100),
                    (prices_mon.y1 / 100),
                    (prices_mon.l1 / 100),
                    (prices_mon.n2 / 100),
                    (prices_mon.y2 / 100),
                    (prices_mon.l2 / 100),
                    (prices_mon.sfn / 100),
                    (prices_mon.sfy / 100),
                    (prices_mon.sfl / 100)
                )
                delay.chatMon = 1
            end
            if script_run then
                transponder_delay = 100
                return false
            end
        end

        if delay.dir ~= 0 then
            if string.find(Dtitle, "Тел.справочник") and delay.dir == 2 then
                sampSendDialogResponse(DdialogId, 1, 1, "")
                delay.dir = 3
                return false
            end

            if string.find(Dtitle, "Работы") and delay.dir == 3 then
                lua_thread.create(
                    function()
                        repeat
                            wait(0)
                        until delay.dir == 4
                        wait(150)
                        sampSendDialogResponse(DdialogId, 1, 8, "[8] Дальнобойщик")
                    end
                )
                delay.dir = 4
                return false
            end

            if string.find(Dtitle, "Меню") and string.find(Dtext, "AFK секунд") and delay.dir == 4 then
                delay.dir = 0
                sampShowDialog(222, Dtitle, Dtext, Dbutton1, Dbutton2, Dstyle)
                return false
            end
        end
    end

    function sampev.onCreate3DText(id, color, position, distance, testLOS, attachedPlayerId, attachedVehicleId, text)
        lua_thread.create(
            function(id, color, position, distance, testLOS, attachedPlayerId, attachedVehicleId, textt)
                for k, v in pairs(find_3dText) do

                    if string.find(text, v) then
                        if (msk_timestamp - id_3D_text) > 1 then
                            wait_auto = msk_timestamp
                        end
                        id_3D_text = id
                        if text:find("Порт") then
                            unload_location = true
                            local one_plus = function(price)
                                for i = 1, #price do
                                    if string.find(tostring(price[i]), "99") then
                                        price[i] = tonumber(price[i]) + 1
                                    end
                                end
                                return price[1], price[2], price[3]
                            end
                            local cargoN, cargoY, cargoL = string.match(text, v)
                            cargoN, cargoY, cargoL = one_plus({cargoN, cargoY, cargoL})
                            luChecker.set3Dtext("Порт", {prices_3dtext[k .. "n"], prices_3dtext[k .. "y"], prices_3dtext[k .. "l"]}, {cargoN, cargoY, cargoL}, position)
                            prices_3dtext[k .. "n"], prices_3dtext[k .. "y"], prices_3dtext[k .. "l"] = cargoN, cargoY, cargoL
                            prices_3dtext_id[k .. "n"], prices_3dtext_id[k .. "y"], prices_3dtext_id[k .. "l"] = id, id, id
                            prices_3dtext_pos[k .. "n"], prices_3dtext_pos[k .. "y"], prices_3dtext_pos[k .. "l"] = position, position, position
                            local port = (text:find("ЛС") and "ЛС" or "СФ")
                            local ctext =
                                string.format(
                                "Порт %s\nНефть: 0.%s\nУголь: 0.%s\nДерево: 0.%s ",
                                port,
                                prices_3dtext[k .. "n"],
                                prices_3dtext[k .. "y"],
                                prices_3dtext[k .. "l"]
                            )
                            current_warehouse =
                                (current_load == 1 and k .. "n" or
                                (current_load == 2 and k .. "y" or (current_load == 3 and k .. "l" or "")))
                            repeat
                                wait(0)
                            until sampIs3dTextDefined(id)
                            if inifiles.Settings.LightingPrice then
                                if current_load == 1 then
                                    ctext = ctext:gsub("Нефть:", "{FFFFFF}Нефть:")
                                    ctext = ctext:gsub("Уголь:", "{FFFF00}Уголь:")
                                elseif current_load == 2 then
                                    ctext = ctext:gsub("Уголь:", "{FFFFFF}Уголь:")
                                    ctext = ctext:gsub("Дерево:", "{FFFF00}Дерево:")
                                elseif current_load == 3 then
                                    ctext = ctext:gsub("Дерево:", "{FFFFFF}Дерево:")
                                end
                            end
                            sampCreate3dTextEx(
                                id,
                                ctext,
                                0xFFFFFF00,
                                position.x,
                                position.y,
                                position.z,
                                distance,
                                testLOS,
                                attachedPlayerId,
                                attachedVehicleId
                            )
                        else
                            local cargo_save = string.match(text, v)
                            luChecker.set3Dtext("Склад", {prices_3dtext[k], k}, {cargo_save, k}, position)
                            prices_3dtext[k] = cargo_save
                            prices_3dtext_id[k] = id
                            prices_3dtext_pos[k] = position
                            load_location = true
                            current_warehouse = k
                        end
                    end
                end
            end,
            id,
            color,
            position,
            distance,
            testLOS,
            attachedPlayerId,
            attachedVehicleId,
            text
        )
    end

    function sampev.onRemove3DTextLabel(Cid) -- f3d2
        lua_thread.create(function(Cid)
            if id_3D_text == Cid then
                id_3D_text = msk_timestamp
                load_location = false
                unload_location = false
                current_warehouse = "none"
            end
            local result, key = isTruck3dTextDefined(Cid)
            if result then
                for i = 1, #key do
                    prices_3dtext_id[key[i]] = nil
                    prices_3dtext[key[i]] = 0
                end
            end
        end, Cid)
    end
    utf8({ "sampev", "onShowDialog" }, "AnsiToUtf8", "Utf8ToAnsi")
    utf8({ "sampev", "onServerMessage" }, "AnsiToUtf8", "Utf8ToAnsi")
    utf8({ "sampev", "onCreate3DText" }, "AnsiToUtf8", "Utf8ToAnsi")
end

function isTruck3dTextDefined(id)
    local result = false
    local delete = {}
    local x, y, z = getCharCoordinates(PLAYER_PED)
    for k,v in pairs(prices_3dtext_id) do
        local dist = getDistanceBetweenCoords3d(x, y, z, prices_3dtext_pos[k].x, prices_3dtext_pos[k].y, prices_3dtext_pos[k].z)
        if id == v and v ~= -1 and dist > 20 then
            result = true
            delete[#delete+1] = k
        end
    end
    return result, delete
end

function say(text)
    sampAddChatMessage(tostring(text),-1)
end

function write_table_log(key, param, Log)
    if Log >= 3 and Log ~= 9 then
        inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].hour[os.date("%H", msk_timestamp)]['pribil'] = inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].hour[os.date("%H", msk_timestamp)]['pribil'] - tonumber(param[1])
        inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].day['pribil'] = inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].day['pribil'] - tonumber(param[1])

        inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].hour[os.date("%H", msk_timestamp)][key] = inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].hour[os.date("%H", msk_timestamp)][key] + tonumber(param[1])
        inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].day[key] = inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].day[key] + tonumber(param[1])
    end
    if inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].hour[os.date("%H", msk_timestamp)][key..'count'] ~= nil then
        inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].hour[os.date("%H", msk_timestamp)][key..'count'] = inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].hour[os.date("%H", msk_timestamp)][key..'count'] + 1
        inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].day[key..'count'] = inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].day[key..'count'] + 1
    end

    if key == 'zagruzka' then
        inifiles.Settings.DataLoad = os.date("%d.%m.%Y", msk_timestamp)
        inifiles.Settings.HourLoad = os.date("%H", msk_timestamp)
        if inifiles.Trucker.MaxZP > tonumber(inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].hour[os.date("%H", msk_timestamp)].zp) then
            inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].hour[os.date("%H", msk_timestamp)]['pribil'] = inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].hour[os.date("%H", msk_timestamp)]['pribil'] - tonumber(param[1])
            inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].day['pribil'] = inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].day['pribil'] - tonumber(param[1])

            inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].hour[os.date("%H", msk_timestamp)][key] = inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].hour[os.date("%H", msk_timestamp)][key] + tonumber(param[1])
            inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].day[key] = inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].day[key] + tonumber(param[1])
        end
    end

    if key == 'razgruzka' then
        if inifiles.Trucker.MaxZP > tonumber(inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].hour[os.date("%H", msk_timestamp)].zp)then
            if inifiles.Settings.HourLoad ~= os.date("%H", msk_timestamp) or inifiles.Settings.DataLoad ~= os.date("%d.%m.%Y", msk_timestamp)  then
                inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].hour[os.date("%H", msk_timestamp)]['zp'] = inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].hour[os.date("%H", msk_timestamp)]['zp'] + tonumber(param[2])
                inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].day['zp'] = inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].day['zp'] + tonumber(param[2])
                inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].hour[os.date("%H", msk_timestamp)]['pribil'] = inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].hour[os.date("%H", msk_timestamp)]['pribil'] + tonumber(param[2])
                inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].day['pribil'] = inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].day['pribil'] + tonumber(param[2])
                inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].hour[os.date("%H", msk_timestamp)][key] = inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].hour[os.date("%H", msk_timestamp)][key] + tonumber(param[1])
                inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].day[key] = inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].day[key] + tonumber(param[1])
            else
                inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].hour[os.date("%H", msk_timestamp)]['zp'] = inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].hour[os.date("%H", msk_timestamp)]['zp'] + tonumber(param[2])
                inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].day['zp'] = inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].day['zp'] + tonumber(param[2])
                inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].hour[os.date("%H", msk_timestamp)]['pribil'] = inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].hour[os.date("%H", msk_timestamp)]['pribil'] + tonumber(param[1])
                inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].day['pribil'] = inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].day['pribil'] + tonumber(param[1])
                inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].hour[os.date("%H", msk_timestamp)][key] = inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].hour[os.date("%H", msk_timestamp)][key] + tonumber(param[1])
                inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].day[key] = inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].day[key] + tonumber(param[1])
            end
            inifiles.Settings.HourLoad = os.date("%H", msk_timestamp)
            inifiles.Settings.DataLoad = os.date("%d.%m.%Y", msk_timestamp)
        end
    end

    local text_to_log = {
        [1] = { string.format('Загрузка за %s$ %s', param[1], (inifiles.Trucker.MaxZP < tonumber(inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].hour[os.date("%H", msk_timestamp)].zp) and ' [Достигнут лимит зарплаты]' or '') )},
        [2] = { string.format('Разгрузка за %s$ | Заработано %s$ %s', param[1], param[2], (inifiles.Trucker.MaxZP < tonumber(inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].hour[os.date("%H", msk_timestamp)].zp) and ' [Достигнут лимит зарплаты]' or '')) },
        [3] = { string.format('Аренда фуры за %s$', param[1]) },
        [4] = { string.format('Штраф %s$ офицеру %s', param[1], param[2]) },
        [5] = { string.format('Починка фуры за %s$', param[1]) },
        [6] = { string.format('Заправка фуры за %s$', param[1]) },
        [7] = { string.format('Заправка фуры за %s$', param[1]) },
        [8] = { string.format('Покупка канистры за %s$', param[1]) },
        [9] = { string.format('PayDay') }
    }
    for k, v in pairs(text_to_log[Log]) do
        inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].event[#inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].event + 1] = os.date("%X", msk_timestamp).." | "..v
    end
    settings_save()
end

function logAvailable()
    if msk_timestamp == 0 then return end
    if inifiles.log == nil then
        inifiles.log = {}
        settings_save()
    end
    if inifiles.log[os.date("%d.%m.%Y", msk_timestamp)] == nil then
        inifiles.log[os.date("%d.%m.%Y", msk_timestamp)] = {
            event = {},
            hour = {},
            day = {
                arenda = 0,
                arendacount = 0,
                zagruzka = 0,
                zagruzkacount = 0,
                razgruzka = 0,
                razgruzkacount = 0,
                pribil = 0,
                shtraf = 0,
                shtrafcount = 0,
                repair = 0,
                repaircount = 0,
                refill = 0,
                refillcount = 0,
                kanistr = 0,
                kanistrcount = 0,
                zp = 0
            }
        }
        settings_save()
    end
    if inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].hour[os.date("%H", msk_timestamp)] == nil then
        inifiles.log[os.date("%d.%m.%Y", msk_timestamp)].hour[os.date("%H", msk_timestamp)] = {
            arenda = 0,
            arendacount = 0,
            zagruzka = 0,
            zagruzkacount = 0,
            razgruzka = 0,
            razgruzkacount = 0,
            pribil = 0,
            shtraf = 0,
            shtrafcount = 0,
            repair = 0,
            repaircount = 0,
            refill = 0,
            refillcount = 0,
            kanistr = 0,
            kanistrcount = 0,
            zp = 0
        }
        settings_save()
    end
end

function isTruckCar()
    if isCharInModel(PLAYER_PED, 403) or isCharInModel(PLAYER_PED, 514) or isCharInModel(PLAYER_PED, 515) then --463 ubrat or isCharInModel(PLAYER_PED, 463)
        if getDriverOfCar(getCarCharIsUsing(playerPed)) == playerPed then
            return true
        else
            return false
        end
    else
        return false
    end
end

function ChangeCena(st)
    if st > 0 then
        if workload == 1 then
            if inifiles.Price.UnLoad >= 0 and inifiles.Price.UnLoad < 900 then
                inifiles.Price.UnLoad = inifiles.Price.UnLoad + 100
                settings_save()
            end
        else
            if inifiles.Price.Load >= 0 and inifiles.Price.Load < 900 then
                inifiles.Price.Load = inifiles.Price.Load + 100
                settings_save()
            end
        end
    else
        if workload == 1 then
            if inifiles.Price.UnLoad > 0 and inifiles.Price.UnLoad <= 900 then
                inifiles.Price.UnLoad = inifiles.Price.UnLoad - 100
                settings_save()
            end
        else
            if inifiles.Price.Load > 0 and inifiles.Price.Load <= 900 then
                inifiles.Price.Load = inifiles.Price.Load - 100
                settings_save()
            end
        end
    end
end

function drawClickableText(text, posX, posY)
    if text ~= nil and posX ~= nil and posY ~= nil then
        renderFontDrawText(font, text, posX, posY, "0xFF" .. inifiles.Render.Color1)
        local textLenght = renderGetFontDrawTextLength(font, text)
        local textHeight = renderGetFontDrawHeight(font)
        local curX, curY = getCursorPos()
        if curX >= posX and curX <= posX + textLenght and curY >= posY and curY <= posY + textHeight then
            if control or sampIsChatInputActive() then
                renderFontDrawText(font, text, posX, posY, "0x70" .. inifiles.Render.Color2)
                if isKeyJustPressed(1) then
                    return true
                else
                    return false
                end
            end
        end
    else
        return false
    end
end

--------------------------------------------------------------------------------
--------------------------------------GMAP--------------------------------------
--------------------------------------------------------------------------------
delay_start = 0

function clearSoloMessage()
    solo_message_send = {
        name = "",
        id = -1,
        action = "",
        cargo = "",
        time = 0
    }
end

function doPair_G()
    if pair_yes ~= nil then
        if os.time() - pair_yes.time < 60 then
            if wasKeyPressed(vkeys["VK_G"]) then
                pair_mode_id = tonumber(pair_yes.id)
                if sampIsPlayerConnected(pair_mode_id) then
                    error_message(1, '')
                    para_message_send = nil
                    pair_mode_name = sampGetPlayerNickname(pair_mode_id)
                    menu[4][1] = "SMS » " .. pair_mode_name .. "[" .. pair_mode_id .. "]"
                    pair_mode = true
                    menu[4].run = true
                    transponder_delay = 100
                else
                    pair_mode_id = -1
                    pair_mode = false
                    menu[4].run = false
                    sampAddChatMessage("Ошибка! Игрок под этим ID не в сети.", -1)
                end
                pair_yes = nil
            end
        else
            pair_yes = nil
        end
    end
end

function transponder()
    new_pair = {}
    error_array = {}
    solo_data_antiflood = {}
    clearSoloMessage()
    while true do
        wait(0)
        if script_run and inifiles.Settings.transponder then
            delay_start = os.clock()
            repeat
                wait(0)
            until os.clock() * 1000 - (delay_start * 1000) > transponder_delay
            if inifiles.Settings.transponder then
                local request_table = {}
                request_table["request"] = 1
                local ip, port = sampGetCurrentServerAddress()
                local _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
                local x, y, z = getCharCoordinates(playerPed)
                local result, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
                local myname = sampGetPlayerNickname(myid)

                if (os.time() - afk_solo_message_false < 7 or os.time() - live > 7) or (solo_message_send.time ~= 0 and os.time() - solo_message_send.time > 5) then -- Очистить если данные устарели
                    clearSoloMessage()
                end

                request_table["info"] = {
                    server = ip .. ":" .. tostring(port),
                    sender = myname,
                    pos = {x = x, y = y, z = z, heading = getCharHeading(playerPed)},
                    data = {
                        pair_mode_name = pair_mode_name,
                        is_truck = isTruckCar(),
                        gruz = current_load,
                        skill = inifiles.Trucker.Skill,
                        rank = inifiles.Trucker.Rank,
                        id = myid,
                        paraid = pair_mode_id,
                        timer = timer,
                        tmonitor = inifiles.tmonitor,
                        version = inifiles.version,
                        platinum = inifiles.platinum.status
                    },
                    solo_message = solo_message_send
                }
                request_table['random'] = tostring(os.clock()):gsub('%.', '')

                if pair_mode and pair_mode_name ~= nil then
                    request_table["info"]['data']["pair_mode_name"] = pair_mode_name
                else
                    request_table["info"]['data']["pair_mode_name"] = "____"
                end

                download_call = 0
                collecting_data = false
                wait_for_response = true
                local response_path = os.tmpname()
                down = false
                download_id_4 = downloadUrlToFile(
                    "http://th.deadpoo.net/" .. encodeJson(request_table),
                    response_path,
                    function(id, status, p1, p2)
                        if stop_downloading_4 then
                            stop_downloading_4 = false
                            download_id_4 = nil
                            return false
                        end
                        if status == dlstatus.STATUS_ENDDOWNLOADDATA then
                            down = true
                            download_id_4 = nil
                        end
                        if status == dlstatus.STATUSEX_ENDDOWNLOAD then
                            wait_for_response = false
                            download_id_4 = nil
                        end
                    end
                )
                while wait_for_response do
                    wait(10)
                end
                processing_response = true

                if down and doesFileExist(response_path) then
                    local f = io.open(response_path, "r")
                    if f then
                        local fileText = f:read("*a")
                        if fileText ~= nil and #fileText > 0 then
                            try(function()
                                info = decodeJson(fileText)
                            end, function(e)
                                sampfuncsLog(fileText)
                                sampAddChatMessage("[TruckHUD]: Ошибочный ответ сервера!",-1)
                                info = nil
                            end)
                            if info == nil then
                                print("{ff0000}[" .. string.upper(thisScript().name) .. "]: Был получен некорректный ответ от сервера.")
                            else
                                if download_call == 0 then
                                    if request_table["info"]["solo_message"]["name"] == solo_message_send.name then
                                        clearSoloMessage()
                                    end
                                    transponder_delay = info.delay
                                    response_timestamp = info.timestamp
                                    if info.base ~= nil then
                                        transponder_solo_message(info)
                                        base = info.base
                                        error_message('2', '')
                                        local minKD = 1000000
                                        local dialogText = 'Имя[ID]\tСкилл\tФура/Груз\tНапарник\n'
                                        local tmonitor = {}
                                        for k,v in pairs(base) do
                                            if v.pair_mode_name == myname then
                                                if new_pair[k] == nil then
                                                    if sampIsPlayerConnected(v.id) and sampGetPlayerNickname(v.id) == k then
                                                        new_pair[k] = true
                                                        sampAddChatMessage('TruckHUD: Игрок '..k..'['..v.id..'] добавил Вас в режим пары.', -1)
                                                        if pair_mode_id ~= v.id then
                                                            sampAddChatMessage('TruckHUD: Нажмите {e63939}"G"{FFFFFF} чтобы принять его в напарники.', -1)
                                                            pair_yes = {
                                                                time = os.time(),
                                                                id = v.id
                                                            }
                                                        end
                                                    end
                                                end
                                            end
                                            if new_pair[k] ~= nil and v.pair_mode_name ~= myname then
                                                sampAddChatMessage('TruckHUD: Игрок '..k..'['..v.id..'] убрал Вас из режима пары.', -1)
                                                new_pair[k] = nil
                                            end
                                            if inifiles.blacklist[k] == nil then
                                                inifiles.blacklist[k] = false
                                            end
                                            if (not inifiles.Settings.blacklist_inversion and inifiles.blacklist[k] == false) or (inifiles.Settings.blacklist_inversion and inifiles.blacklist[k] == true) then
                                                if v.tmonitor ~= nil and v.tmonitor.lsn ~= nil and tonumber(v.tmonitor.lsn) ~= 0 then
                                                    local monKD = msk_timestamp - v.tmonitor.time
                                                    if monKD > 0 then
                                                        if monKD < minKD then
                                                            minKD = monKD
                                                            tmonitor = v.tmonitor
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                        if minKD ~= 1000000 then
                                            if mon_ctime < tmonitor.time then
                                                mon_time = tmonitor.time
                                                for k, v in pairs(prices_mon) do
                                                    if tmonitor[k] ~= nil then
                                                        prices_mon[k] = tmonitor[k]
                                                    end
                                                end
                                            end
                                        end
                                    end

                                    if info.result == "para" then
                                        error_message('2', '')
                                        pair_timestamp = info.data.timestamp
                                        base[pair_mode_name].pos = { x = info.data.x, y = info.data.y, z = info.data.z }
                                        base[pair_mode_name].heading = info.data.heading
                                        pair_table = base[pair_mode_name]
                                        pair_status = 200
                                        if para_message_send == nil then
                                            para_message_send = 1
                                            sampAddChatMessage("Установлен напарник "..pair_mode_name.."["..pair_mode_id.."]"..". Теперь вы можете пользоваться картой.", -1)
                                            sampAddChatMessage(string.format("Активация в фуре: %s. Без фуры: %s + %s.", inifiles.Settings.Key3:gsub("VK_", ""), inifiles.Settings.Key3:gsub("VK_", ""), inifiles.Settings.Key2:gsub("VK_", "")), -1)
                                        end
                                    elseif info.result == "error" then
                                        if info.reason ~= nil then
                                            if info.reason == 403 then
                                                error_message('2', '')
                                                pair_status = info.reason
                                                error_message('1', pair_mode_name.."["..pair_mode_id.."] пока не установил Вас напарником в своем TruckHUD.")
                                            elseif info.reason == 404 then
                                                error_message('2', '')
                                                pair_status = info.reason
                                                error_message('1', pair_mode_name.."["..pair_mode_id.."] не найден в базе игроков TruckHUD")
                                            elseif info.reason == 425 then
                                                error_message('2', 'Слишком частые запросы на хостинг. Разберитесь с этим или обратитесь за помощью в группу vk.com/rubin.mods')
                                            end
                                        end
                                    end
                                end
                                wait_for_response = false
                                info = nil
                            end
                        end
                        fileText = nil
                        f:close()
                        f = nil
                    end
                else
                    error_message('2', 'Не получил ответа от хостинга. Найдите причину с помощью /truck server_help или напишите о проблеме в группу vk.com/rubin.mods.')
                end
                if doesFileExist(response_path) then
                    os.remove(response_path)
                end
                request_table = nil
                processing_response = false
            end
        end
    end
end

function fix_l(symbol, cargo_msg)
    if symbol == "l" then
        if cargo_msg == "lsn" or cargo_msg == "lsy" then
            return false
        end
    end
    return true
end

solo_antiflood_message = {}
function transponder_solo_message(info)
    if info.solo_data ~= nil then
        for sender, solo_data in pairs(info.solo_data) do
            if (inifiles.blacklist[sender] ~= nil and not inifiles.blacklist[sender]) and info.timestamp - solo_data.time < 5 and getNameById(tonumber(solo_data.id)) == solo_data.name then
                if solo_data_antiflood[sender] == nil then
                    solo_data_antiflood[sender] = {}
                end
                local result_find = false -- Отклонить показ сообщения
                local check_label = { "id", "name", "action", "cargo" }

                local cargo_symbol = (inifiles.Settings.luCheckerCargo == 1 and "n" or (inifiles.Settings.luCheckerCargo == 2 and "y" or (inifiles.Settings.luCheckerCargo == 3 and "l" or "")))

                if cargo_symbol ~= "" or inifiles.Settings.luCheckerCargo == 4 then
                    if (solo_data["cargo"]:find(cargo_symbol) and fix_l(cargo_symbol, solo_data["cargo"])) or inifiles.Settings.luCheckerCargo == 4 then
                        for i = 1, #solo_data_antiflood[sender] do -- Поиск дубликата
                            local counter = 0
                            for s = 1, #check_label do
                                if solo_data[s] == solo_data_antiflood[sender][i][s] then
                                    counter = counter + 1
                                end
                            end
                            if counter == 4 and os.time() - solo_data_antiflood[sender][i]["antiflood"] < 10 then
                                result_find = true
                                break
                            else
                                if af_say == nil then
                                    af_say = {}
                                end
                                local key = string.format("%s%s", solo_data_antiflood[sender][i]["name"], solo_data_antiflood[sender][i]["time"])

                                if af_say[key] == nil then
                                    af_say[key] = true
                                end
                            end
                        end
                        if not result_find then
                            if texts_of_reports[solo_data["cargo"]] ~= nil then
                                local text1 = string.format("%s[%s] %s %s.", solo_data.name, solo_data.id, (solo_data.action == "load" and "загрузился на" or "разгрузил"), texts_of_reports[solo_data["cargo"]])
                                local text = string.format("%s Отправил: %s", text1, sender)
                                if solo_antiflood_message[text1] == nil or (os.time() - solo_antiflood_message[text1] > 3) then
                                    solo_antiflood_message[text1] = os.time()
                                    addChatMessage(text)
                                end
                            end
                        end
                        solo_data_antiflood[sender][#solo_data_antiflood[sender]+1] = solo_data
                        solo_data_antiflood[sender][#solo_data_antiflood[sender]]["antiflood"] = os.time()
                    end
                end
            end
        end
    end
end


function error_message(key, text)
    if text ~= '' then
        if error_array[key] == nil then
            error_array[key] = true
            sampAddChatMessage(text, -1)
        end
    else
        if error_array[key] ~= nil then
            if key == '2' or key == '3' then
                sampAddChatMessage('Связь с сервером TruckHUD возобновлена.', -1)
            end
            error_array[key] = nil
        end
    end
end

function count_next()
        local count = (transponder_delay - (os.clock() * 1000 - delay_start * 1000)) / 1000
        if count >= 0 then
            return string.format("%0.3fс", count)
        elseif wait_for_response then
            return "Ожидание ответа" -- WAITING FOR RESPONSE
        elseif processing_response then
            return "Обработка ответа" -- PROCESSING RESPONSE
        else
            return "Выполнение запроса" -- PERFOMING REQUEST
        end
end

function dn(nam)
    file = getGameDirectory() .. "\\moonloader\\resource\\TruckHUD\\" .. nam
    if not doesFileExist(file) then
        downloadUrlToFile(
            "http://th.deadpoo.net/download/" .. nam,
            file
        )
    end
end

function init()
    if not doesDirectoryExist(getGameDirectory() .. "\\moonloader\\resource") then
        createDirectory(getGameDirectory() .. "\\moonloader\\resource")
    end
    if not doesDirectoryExist(getGameDirectory() .. "\\moonloader\\resource\\TruckHUD") then
        createDirectory(getGameDirectory() .. "\\moonloader\\resource\\TruckHUD")
    end
    dn("truck.png")
    dn("pla.png")
    dn("map.png")

    player = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/TruckHUD/pla.png")
    truck = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/TruckHUD/truck.png")
    map = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/TruckHUD/map.png")

    font10 = renderCreateFont("Segoe UI", 10, 13)
    resX, resY = getScreenResolution()

    if resX > 1024 and resY >= 1024 then
        bX = (resX - 1024) / 2
        bY = (resY - 1024) / 2
        size = 1024
        iconsize = 32
    elseif resX > 720 and resY >= 720 then
        bX = (resX - 720) / 2
        bY = (resY - 720) / 2
        size = 720
        iconsize = 24
    else
        bX = (resX - 512) / 2
        bY = (resY - 512) / 2
        size = 512
        iconsize = 16
    end
end

function fastmap()
    init()
    dialogActiveClock = os.time()
    while true do
        wait(0)
        if inifiles.Settings.transponder and inifiles.Settings.fastmap then
            if sampIsDialogActive() then
                dialogActiveClock = os.time()
            end

            if pair_mode and
                pair_status == 200 and
                not sampIsDialogActive() and
                (os.time() - dialogActiveClock) > 1 and
                not sampIsScoreboardOpen() and
                not isSampfuncsConsoleActive() and
               ( (isKeyDown(vkeys[inifiles.Settings.Key3]) and isKeyDown(vkeys[inifiles.Settings.Key2]) or (isTruckCar() and isKeyDown(vkeys[inifiles.Settings.Key3]))))
            then
                fastmapshow = true
                local x, y = getCharCoordinates(playerPed)
                renderDrawTexture(map, bX, bY, size, size, 0, 0xFFFFFFFF)

                if isTruckCar() then
                    renderDrawTexture( truck, getX(x), getY(y), iconsize, iconsize, -getCharHeading(playerPed) + 90, -1 )
                else
                    renderDrawTexture( player, getX(x), getY(y), iconsize, iconsize, -getCharHeading(playerPed), -1 )
                end

                if pair_table ~= nil and pair_table["pos"] ~= nil and pair_table["pos"]["x"] ~= nil then
                    color = 0xFFdedbd2
                    if pair_table["is_truck"] then
                        renderDrawTexture(truck, getX(pair_table["pos"]["x"]), getY(pair_table["pos"]["y"]), iconsize, iconsize, -pair_table["heading"] + 90, -1 )
                    else
                        renderDrawTexture(player, getX(pair_table["pos"]["x"]), getY(pair_table["pos"]["y"]), iconsize, iconsize, -pair_table["heading"], -1 )
                    end
                end
            else
                fastmapshow = nil
            end
        end
    end
end

function getX(x)
    x = math.floor(x + 3000)
    return bX + x * (size / 6000) - iconsize / 2
end

function getY(y)
    y = math.floor(y * -1 + 3000)
    return bY + y * (size / 6000) - iconsize / 2
end

function onScriptTerminate(LuaScript, quitGame)
    if LuaScript == thisScript() then
        stop_downloading_1 = true
        stop_downloading_2 = true
        stop_downloading_3 = true
        stop_downloading_4 = true
        stop_downloading_5 = true
        for k, v in pairs(pickupLoad) do
            if v.pickup ~= nil then
                if doesPickupExist(v.pickup) then
                    removePickup(v.pickup)
                    v.pickup = nil
                end
            end
        end
        delete_all__3dTextplayers()
        removeBlip(pttBlip)
        if sampIs3dTextDefined(ptt3dText) then
            sampDestroy3dText(ptt3dText)
        end
        deleteActor(999)
    end
end

function get_time()
    _time = os.time()
    if inifiles.Settings.transponder then
        local adress = os.getenv('TEMP')..'\\truck-timestamp'
        local url = 'http://th.deadpoo.net/timestamp'
        downloadUrlToFile(url, adress, function(id, status, p1, p2)
            if status == dlstatus.STATUSEX_ENDDOWNLOAD then
                if doesFileExist(adress) then
                local f = io.open(adress, 'r')
                    if f then
                      local time = f:read('*a')
                      msk_timestamp = tonumber(time)
                      f:close()
                      os.remove(adress)
                    else
                        msk_timestamp = os.time()
                        sampAddChatMessage('TruckHUD: Ошибка получения точного времени. Используется локальное.', -1)
                    end
                end
            end
            if status == 58 then
                if msk_timestamp == 0 then
                    msk_timestamp = os.time()
                    sampAddChatMessage('TruckHUD: Ошибка получения точного времени. Используется локальное.', -1)
                end
            end
        end)
    else
        msk_timestamp = os.time()
        sampAddChatMessage('TruckHUD: Ошибка получения точного времени. Используется локальное.', -1)
    end

    repeat wait(0) until msk_timestamp > 0

    while true do
        wait(500)
        msk_timestamp = msk_timestamp + (os.time() - _time)
        _time = os.time()
        if inifiles.Settings.AutoClear then
            collectgarbage("step")
        end
    end
end

function split(str, delim, plain)
    local tokens, pos, plain = {}, 1, not (plain == false) --[[ delimiter is plain text by default ]]
    repeat
        local npos, epos = string.find(str, delim, pos, plain)
        table.insert(tokens, string.sub(str, pos, npos and npos - 1))
        pos = epos and epos + 1
    until not pos
    return tokens
end

function showUsers()
    local dialogText = 'Имя[ID] AFK\tВерсия скрипта\n'
    local trucker_count = 0
    local _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
    for k,v in pairs(base) do
        if v.pair_mode_name ~= nil and v.is_truck ~= nil and v.gruz ~= nil and v.skill ~= nil and v.id ~= nil and v.paraid ~= nil and v.timer ~= nil and v.tmonitor ~= nil then
            if (sampIsPlayerConnected(v.id) or myid == v.id) and sampGetPlayerNickname(v.id) == k then
                trucker_count = trucker_count + 1
                local afk = math.ceil(msk_timestamp - v.timestamp)
                dialogText = string.format('%s%s[%s] %s\t%s\n', dialogText, k, v.id, (afk > 10 and '[AFK: '..afk..']' or ''), (v.version ~= nil and v.version or "Неизвестно"))
            end
        end
    end
    sampShowDialog(0, 'Дальнобойщики со скриптом в сети: '..trucker_count, (#dialogText == 0 and 'Список пуст' or dialogText), 'Выбрать', 'Закрыть', 5)
end

function showTruckers()
    local dialogText = 'Имя[ID] AFK\tСкилл / Ранг\tФура / Груз\tНапарник\n'
    local trucker_count = 0

    local _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
    for k,v in pairs(base) do
        if v.pair_mode_name ~= nil and v.is_truck ~= nil and v.gruz ~= nil and v.skill ~= nil and v.id ~= nil and v.paraid ~= nil and v.timer ~= nil and v.tmonitor ~= nil then
            if (sampIsPlayerConnected(v.id) or myid == v.id) and sampGetPlayerNickname(v.id) == k then
                trucker_count = trucker_count + 1
                local afk = math.ceil(msk_timestamp - v.timestamp)
                local platinum = ""
                if v.platinum then
                    platinum = "[VIP] "
                end
                dialogText = string.format('%s%s%s[%s] %s\t%s / %s\t%s\t%s\n', dialogText, platinum, k, v.id, (afk > 10 and '[AFK: '..afk..']' or ''), v.skill, v.rank, ( (v.is_truck and 'Да ' or 'Нет ')..(v.gruz == 0 and '/ Нет' or (v.gruz == 1 and '/ Нефть' or (v.gruz == 2 and '/ Уголь' or (v.gruz == 3 and '/ Дерево' or '/ Нет')))) ), ( v.pair_mode_name == '____' and 'Нет' or v.pair_mode_name..'['..v.paraid..']'))
            end
        end
    end
    sampShowDialog(0, 'Дальнобойщики со скриптом в сети: '..trucker_count, (#dialogText == 0 and 'Список пуст' or dialogText), 'Выбрать', 'Закрыть', 5)
end

function renderTruckers()
    font_t = renderCreateFont(inifiles.Render.FontName, inifiles.Render.FontSize, inifiles.Render.FontFlag)
    _3dTextplayers = {}
    while true do
        wait(0)
        if script_run and inifiles.Settings.TruckRender then
            for id = 0, 999 do
                if sampIsPlayerConnected(id) then
                    local nickname = sampGetPlayerNickname(id)
                    if base[nickname] ~= nil then
                        local stream, ped = sampGetCharHandleBySampPlayerId(id)
                        if stream then
                            if (isCharInModel(ped, 403) or isCharInModel(ped, 514) or isCharInModel(ped, 515)) then
                                sec_timer = (base[nickname].platinum and 120 or 180)
                                local car = storeCarCharIsInNoSave(ped)
                                local result, idcar = sampGetVehicleIdByCarHandle(car)
                                if _3dTextplayers[id] == nil and result then
                                    _3dTextplayers[id] = sampCreate3dText(' ', -1, 0.0, 0.0, 0.0, 30.0, false, -1, idcar)
                                end
                                if _3dTextplayers[id] ~= nil and result then
                                    local timer_player = sec_timer - (base[nickname].timer > 1000 and os.difftime(msk_timestamp, base[nickname].timer) or (sec_timer+1))
                                    local color = (timer_player <= 0 and inifiles.Render.Color2 or (timer_player <= 10 and 'b50000' or inifiles.Render.Color2))
                                    local kd_player = (timer_player > 0
                                        and
                                        string.format('{%s}<< {%s}%d:%02d {%s}>>', inifiles.Render.Color1, color, math.floor(timer_player / 60), timer_player % 60, inifiles.Render.Color1)
                                        or
                                        string.format('{%s}<< {%s}0:00 {%s}>>', inifiles.Render.Color1, inifiles.Render.Color2, inifiles.Render.Color1)
                                    )
                                    local gruz_player = string.format('{%s}%s', inifiles.Render.Color2,
                                    (base[nickname].gruz == 0 and 'Нет груза' or (base[nickname].gruz == 1 and 'Нефть' or (base[nickname].gruz == 2 and 'Уголь' or (base[nickname].gruz == 3 and 'Дерево' or 'Нет'))))
                                    )
                                    local para_player = string.format('{%s}%s', inifiles.Render.Color2,
                                    (base[nickname].pair_mode_name ~= '____' and base[nickname].pair_mode_name..'['..base[nickname].paraid..']' or 'Нет напарника')
                                    )
                                    local pair_kd = ''
                                    if base[nickname].pair_mode_name ~= '____' and base[base[nickname].pair_mode_name] ~= nil then
                                    local timer_d = sec_timer - (base[base[nickname].pair_mode_name].timer > 1000 and os.difftime(msk_timestamp, base[base[nickname].pair_mode_name].timer) or (sec_timer+1))
                                    local color = (timer_d <= 0 and inifiles.Render.Color2 or (timer_d <= 10 and 'b50000' or inifiles.Render.Color2))
                                    pair_kd = string.format('(%s{%s})', (timer_d > 0 and string.format('{%s}%d:%02d', color, math.floor(timer_d / 60), timer_d % 60) or string.format('{%s}0:00', inifiles.Render.Color2)), inifiles.Render.Color2)
                                    end

                                    sampSet3dTextString(_3dTextplayers[id], string.format('%s\n%s\n%s %s', kd_player, gruz_player, para_player, pair_kd))
                                end
                                if not result and _3dTextplayers[id] ~= nil then
                                    sampDestroy3dText(_3dTextplayers[id])
                                    _3dTextplayers[id] = nil
                                end
                            else
                                if _3dTextplayers[id] ~= nil then
                                    sampDestroy3dText(_3dTextplayers[id])
                                    _3dTextplayers[id] = nil
                                end
                            end
                        else
                            if _3dTextplayers[id] ~= nil then
                                sampDestroy3dText(_3dTextplayers[id])
                                _3dTextplayers[id] = nil
                            end
                        end
                    end
                else
                    if _3dTextplayers[id] ~= nil then
                        sampDestroy3dText(_3dTextplayers[id])
                        _3dTextplayers[id] = nil
                    end
                end
            end
        else
            delete_all__3dTextplayers()
        end
    end
end

function delete_all__3dTextplayers()
    for k, v in pairs(_3dTextplayers) do
        sampDestroy3dText(_3dTextplayers[k])
        _3dTextplayers[k] = nil
    end
end




--->>>

function loadPtt()
    pttCreate = false
    pttManStatus = false
    pttTime = 0
    ptt3dText = 0
    pttBlip = 0

    pttStatus = 1
    pttArr = {
        [1] = {
            skins = { 63, 64, 85, 87, 152, 178, 207, 237, 238, 243, 244, 245, 246, 256, 257 },
            names = { "Rachel", "Sara", "Cindy", "Clover", "Cleo", "Lisa", "Melissa", "Jessica", "Samantha", "Susan", "Rose", "April", "Ashley", "Amelia", "Emily", "Angela", "Annabel", "Abby", "Abigail", "Elise", "Milly", "Stacey", "Gloria", "Courtney", "Patricia", "Penelope" },
            message = {
                "А вот и король дорог приехал",
                "Разгрузил тележку? Потанцуй со мной",
                "От тебя воняет бензином, фии",
                "Руками не трогать",
                "Отойди на 3 метра, противный",
                "Иди ко мне, мой тигр!",
                "Я сейчас тебе покажу такое, чего ты никогда не видел в жизни",
                "Ну иди сюда, ты заслужил",
                "Хочешь поразвлекаться?",
                "Я могу поднять твое настроение, если ты понимаешь о чем я",
                "Первый час бесплатно, за второй ты еще не отработал",
                "Хочеть выпить кофе со мной?",
                "К тебе или ко мне?"
            }
        }, -- shluxi
        [2] = {
            skins = { 10, 39, 53, 54, 75, 77, 88, 89, 129, 130, 196, 197, 199, 218, 231, 232 },
            names = { "Rachel", "Sara", "Cindy", "Clover", "Cleo", "Lisa", "Melissa", "Jessica", "Samantha", "Susan", "Rose", "April", "Ashley", "Amelia", "Emily", "Angela", "Annabel", "Abby", "Abigail", "Elise", "Milly", "Stacey", "Gloria", "Courtney", "Patricia", "Penelope" },
            message = {
                "Ээх, встряхнем стариной",
                "Давай танцуй внучок",
                "Деньги только крупными купюрами, все таки пенсия понимаешь",
                "Бутылочку от пива не выбрасывай",
                "И что как работа, внучок? Платят хоть?",
                "Иди ко мне, мой тигр!",
                "Иди сюда, мой милый, не бойся",
                "До тебя пол страны обслужила, а все такая же красивая",
                "Как говорится \"В 45 - баба ягодка опять\"",
                "Можешь оплатить пустыми банками",
                "Ты прям как мой внучек, такой же стеснительный",
                "Трахни меня, я тебе заплачу",
                "Да ты не пугайся, я просто не накрашена"
            }
        }, -- bomjixi
        [3] = {
            skins = { 78, 79, 134, 135, 136, 137, 160, 162, 200, 212, 213, 230, 239 },
            names = { "Ivan", "Vanya", "Dmitry", "Dima", "Mikhail", "Vladimir", "Vova", "Evgeny", "Zhenya", "Alexei", "Lyosha", "Slava" },
            anim = {
                { "VENDING", "VEND_EAT1_P" },
                { "ATTRACTORS", "STEPSIT_LOOP" },
                { "BAR", "DNK_STNDF_LOOP" },
                { "BASEBALL", "BAT_BLOCK" },
                { "BD_FIRE", "BD_PANIC_01" },
                { "BENCHPRESS", "GYM_BP_CELEBRATE" },
                { "FREEWEIGHTS", "GYM_FREE_CELEBRATE" }
            },
            message = {
                "Ну ты и долгий, я ее уже во все щели отымел пока ты полз на своем корыте",
                "У твоей бабочки отвалились крылышки",
                "Садись в свое корыто и вали отсюда",
                "Свободен!",
                "Шо, и тебе колено прострелить?",
                "Если ты ищешь даму своего сердца, то ты опоздал",
                "Ищешь кого-то? Тут ты никого не найдешь",
                "А ты что тут забыл?",
                "Ты потерялся? Показать дорогу нахуй?",
                "Я конечно не баба, но можно попробовать"
            }
        } -- bomji


    }
    pttAnim = { "PLY_CASH", "PUN_CASH", "PUN_HOLLER", "PUN_LOOP", "strip_A", "strip_B", "strip_C", "strip_D", "strip_E", "strip_F", "strip_G", "STR_A2B", "STR_B2C", "STR_C1", "STR_C2", "STR_Loop_A", "STR_Loop_B", "STR_Loop_C"}
    pttCoord = {
        {
            { 2329.87, -2315.49, 13.55, 129.32 },
            { 2281.67, -2364.62, 13.55, 316.15 },
            { 2506.76, -2205.70, 13.55, 94.71 },
            { 2380.22, -2265.17, 13.55, 312.31 },
            { 2364.69, -2285.37, 14.31, 295.64 }
        },
        {
            { -1742.690918, 36.748432, 3.554688, 90.169365 },
            { -1811.328369, -135.691116, 6.141476, 271.798401 },
            { -1722.343262, -117.837288, 3.548919, 119.073662 },
            { -1862.199219, -144.499191, 11.898438, 12.920449 },
            { -1712.599976, -65.256927, 3.554688, 95.030235 }

        }
    }
end

function pttStart()
    if not pttCreate then
        pttCreate = true
        pttMessage = false
        math.randomseed(os.time())
        pttStatus = (math.random(1, 5) == 3 and 2 or 1)
        local x, y, z = getCharCoordinates(PLAYER_PED)

        local dist_portLS = getDistanceBetweenCoords3d(x, y, z, 2507.02, -2234.05, 13.55)
        local dist_portSF = getDistanceBetweenCoords3d(x, y, z, -1733.18, 120.08, 3.11)
        local pttPos = (dist_portLS < dist_portSF and 1 or 2)
        local randPos = math.random(1, #pttCoord[pttPos])
        pttX, pttY, pttZ, pttHeading = pttCoord[pttPos][randPos][1], pttCoord[pttPos][randPos][2], pttCoord[pttPos][randPos][3], pttCoord[pttPos][randPos][4]

        createActor(999, pttArr[pttStatus].skins[math.random(1, #pttArr[pttStatus].skins)], pttX, pttY, pttZ + 0.5, pttHeading, 100.0)
        animActor(999, "STRIP", pttAnim[math.random(1, #pttAnim)], 4.1, 0, 0, 0, 0, 0)
        pttName = pttArr[pttStatus].names[math.random(1, #pttArr[pttStatus].names)]
        create3DtextPtt(pttName, pttX, pttY, pttZ)
        pttTime = os.time()
        local text = string.format(" SMS: %s ждёт Вас! Дистанция: %0.2d м. Отправитель: Prostitute_Radar", pttName, getDistanceBetweenCoords3d(x, y, z, pttX, pttY, pttZ))
        sampAddChatMessage(text, 0xFFFFFF00)
        removeBlip(pttBlip)
        pttBlip = addBlipForCoord(pttX, pttY, pttZ)
        changeBlipScale(pttBlip, 1)
        changeBlipColour(pttBlip, 0xFFFFFFFF)
    end
end

function pttCMD(param)
    pttStart()
end

function doPtt()
    if pttCreate and pttX ~= nil then
        local x, y, z = getCharCoordinates(PLAYER_PED)
        local dist = getDistanceBetweenCoords3d(x, y, z, pttX, pttY, pttZ)
        if dist < 10.0 then
            pttTime = 0
            if pttBlip ~= 0 then
                removeBlip(pttBlip)
                pttBlip = 0
            end
            if wasKeyPressed(vkeys["VK_H"]) then
                if pttStatus ~= 3 then
                    anim = pttAnim[math.random(1, #pttAnim)]
                    animActor(999, "STRIP", anim, 4.1, 0, 0, 0, 0, 0)
                else
                    local rands = math.random(1, #pttArr[pttStatus].anim)
                    animActor(999, pttArr[pttStatus].anim[rands][1], pttArr[pttStatus].anim[rands][2], 4.1, 0, 0, 0, 0, 0)
                end
                local rands = math.random(1, #pttArr[pttStatus].message)
                local text = pttArr[pttStatus].message[rands]
                if not pttMessage then
                    pttMessage = true
                    sampAddChatMessage(string.format("- %s: %s", pttName, text), 0xFFC8C8C8)
                end
            end
        elseif dist > 1000 and os.time() - pttTime > 180 then
            if pttBlip ~= 0 then
                removeBlip(pttBlip)
                pttBlip = 0
            end
        end

        if pttTime ~= 0 and os.time() - pttTime > 60 and pttStatus ~= 3 then
            pttStatus = 3
            createActor(999, pttArr[pttStatus].skins[math.random(1, #pttArr[pttStatus].skins)], pttX, pttY, pttZ, pttHeading, 100.0)
            pttName = pttArr[pttStatus].names[math.random(1, #pttArr[pttStatus].names)]
            create3DtextPtt(pttName, pttX, pttY, pttZ)
            local text = string.format(" SMS: Слишком долго. Отправитель: Prostitute_Radar")
            sampAddChatMessage(text, 0xFFFFFF00)
        end

        if dist < 100 then
            if afptt == nil or os.time() - afptt > 3 then
                afptt = os.time()
                setActorPos(999, pttX, pttY, pttZ)
            end
        end
    end
end


function createActor(actorId, skinId, x, y, z, rotation, health)
    deleteActor(actorId)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt16(bs,actorId) -- actorId
    raknetBitStreamWriteInt32(bs,skinId) -- skinId
    raknetBitStreamWriteFloat(bs,x) -- PosX
    raknetBitStreamWriteFloat(bs,y) -- PosY
    raknetBitStreamWriteFloat(bs,z) -- PosZ
    raknetBitStreamWriteFloat(bs,rotation) -- rotation
    raknetBitStreamWriteFloat(bs,health) -- health
    raknetEmulRpcReceiveBitStream(171,bs)
    raknetDeleteBitStream(bs)
end

function clearAnimActor(actorId)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt16(bs,actorId)
    raknetEmulRpcReceiveBitStream(174,bs)
    raknetDeleteBitStream(bs)
end

function animActor(actorId, animLib, animName, frameDelta, loop, lockX, lockY, freeze, time)
    clearAnimActor(actorId)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt16(bs,actorId)
    raknetBitStreamWriteInt8(bs, #animLib)
    raknetBitStreamWriteString(bs, animLib)
    raknetBitStreamWriteInt8(bs, #animName)
    raknetBitStreamWriteString(bs, animName)
    raknetBitStreamWriteFloat(bs,frameDelta)
    raknetBitStreamWriteBool(bs,loop)
    raknetBitStreamWriteBool(bs,lockX)
    raknetBitStreamWriteBool(bs,lockY)
    raknetBitStreamWriteBool(bs,freeze)
    raknetBitStreamWriteInt32(bs,time)
    raknetEmulRpcReceiveBitStream(173,bs)
    raknetDeleteBitStream(bs)
end

function deleteActor(actorId)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt16(bs,actorId)
    raknetEmulRpcReceiveBitStream(172,bs)
    raknetDeleteBitStream(bs)
end

function setActorPos(actorId, x, y, z)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt16(bs,actorId)
    raknetBitStreamWriteFloat(bs,x)
    raknetBitStreamWriteFloat(bs,y)
    raknetBitStreamWriteFloat(bs,z)
    raknetEmulRpcReceiveBitStream(176,bs)
    raknetDeleteBitStream(bs)
end

function create3DtextPtt(text, x, y, z)
    sampDestroy3dText(ptt3dText)
    text = text.."\n\n\n\n\n\n\n\n\n\n\n\n{028c00}PRESS 'H'"
    ptt3dText = sampCreate3dText(text, 0xFFFFFFFF, x, y, z + 1.0, 8.0, true, -1, -1)
end

function pttModule()
    if pttMax == nil then
        math.randomseed(os.time())
        pttMax = math.random(11, 20)
        pttCount = 0
    end
    pttCount = pttCount + 1
    if pttCount ~= -1 and pttCount >= pttMax then
        pttCount = -1
        pttStart()
    end
end

--> LOAD & UNLOAD CHECKER

luChecker = {
    vehicles = {},
    truckers = {}, -- Игроки не в скрипте
    price_set = {},
    trailer_delete = {},
    load_position = { x = 0.0, y = 0.0, z = 0.0 }
}

--[[

 разгрузил эвент
 сменился 3д текст эвент
 разгрузил эвент
 сменился 3д текст эвент

]]

function isPlayerHaveTruckHUD(playerId)
    local result = false
    for k,v in pairs(base) do
        if v.id == playerId then
            result = true
            break
        end
    end
    return result
end

function isVehicleTruckersDelete(table, vehicleId)
    local result = false
    local playerId = -1
    local isTrailer = false
    for k,v in pairs(table) do
        if v["trailerData"] ~= nil and v["trailerData"].trailerId == vehicleId then
            result = true
            playerId = k
            isTrailer = true
            break
        end
        if v.vehicleId == vehicleId then
            result = true
            playerId = k
            break
        end
    end
    return result, playerId, isTrailer
end

function luChecker.vehicleStream(stream, vehicleId, data)
    if stream then
        luChecker.vehicles[vehicleId] = {}
        luChecker.vehicles[vehicleId]["type"] = data["type"]
    else
        local result, playerId, isTrailer = isVehicleTruckersDelete(luChecker.truckers, vehicleId)
        if result then
            if isTrailer then
                luChecker.trailer_delete[#luChecker.trailer_delete + 1] = { time = os.clock() * 1000, playerId = playerId, position = luChecker.truckers[playerId]["data"]["position"] }
                luChecker.truckers[playerId]["trailerData"] = {
                    trailerId = -1
                }
            else
                luChecker.truckers[playerId] = nil
            end
        end
        luChecker.vehicles[vehicleId] = nil
    end
end

function luChecker.vehicleSync(playerId, vehicleId, data)
    if luChecker.vehicles[vehicleId] ~= nil and not isPlayerHaveTruckHUD(playerId) then
        if luChecker.vehicles[vehicleId] ~= nil and (luChecker.vehicles[vehicleId].type == 403 or luChecker.vehicles[vehicleId].type == 514 or luChecker.vehicles[vehicleId].type == 515) then
            if luChecker.truckers[playerId] == nil then
                luChecker.truckers[playerId] = {}
                luChecker.truckers[playerId]["data"] = {}
                luChecker.truckers[playerId]["data"]["position"] = data["position"]
                luChecker.truckers[playerId]["vehicleId"] = vehicleId
                luChecker.truckers[playerId]["vehicleDataTime"] = os.time()
                luChecker.truckers[playerId]["trailerDataTime"] = 0
                luChecker.truckers[playerId]["trailerData"] = {
                    trailerId = -1
                }
            else
                luChecker.truckers[playerId]["data"] = {}
                luChecker.truckers[playerId]["data"]["position"] = data["position"]
                luChecker.truckers[playerId]["vehicleId"] = vehicleId
                if os.time() - luChecker.truckers[playerId]["trailerDataTime"] > 5 and os.time() - luChecker.truckers[playerId]["vehicleDataTime"] < 5 and os.time() - live == 0 then
                    luChecker.truckers[playerId]["trailerData"]["trailerId"] = -1
                end
                luChecker.truckers[playerId]["vehicleDataTime"] = os.time()
            end
        end
    end
end

function luChecker.trailerSync(playerId, data)
    if not isPlayerHaveTruckHUD(playerId) and luChecker.truckers[playerId] ~= nil then
        if luChecker.vehicles[data["trailerId"]] ~= nil then
            luChecker.truckers[playerId]["trailerDataTime"] = os.time()
            luChecker.checkerLoad(playerId, data, luChecker.truckers[playerId]["data"]["position"])
            luChecker.truckers[playerId]["trailerData"]["trailerId"] = data["trailerId"]
        end
    end
end

function luChecker.checkerLoad(playerId, data, position) -- Проверка когда игрок получил груз
    if luChecker.truckers[playerId]["trailerData"]["trailerId"] ~= data["trailerId"] then
        if getLocalPlayerId() ~= playerId then
            local trucker_x, trucker_y, trucker_z = position.x, position.y, position.z
            local key, x, y, z = getKeysPoint(trucker_x, trucker_y, trucker_z)
            local cargoNow = (key:find("n") and 1 or (key:find("y") and 2 or (key:find("l") and 3 or 0)))
            local local_x, local_y, local_z = getCharCoordinates(PLAYER_PED)
            local dist_localPlayer_storage = getDistanceBetweenCoords3d(local_x, local_y, local_z, x, y, z)
            local dist_trucker_storage = getDistanceBetweenCoords3d(trucker_x, trucker_y, trucker_z, x, y, z)

            if dist_localPlayer_storage <= 120.0 and dist_trucker_storage <= 50.0 then
                solo_message_send = {
                    name = getNameById(playerId),
                    id = playerId,
                    action = "load",
                    cargo = key,
                    time = os.time()
                }
            end
        end
    end
end

function luChecker.set3Dtext(type, data_old, data, position)
    if type == "Порт" then
        for key = 1, 3 do
            if tonumber(data_old[key]) ~= 0 and not (tonumber(data_old[key]) == tonumber(data[1])) then
                if tonumber(data_old[key]) > tonumber(data[key]) then
                    luChecker.price_set[#luChecker.price_set + 1] = { type = "unload", old_price = tonumber(data_old[key]), new_price = tonumber(data[key]), time = os.clock() * 1000, position = position, key = key }
                end
            end
        end
    elseif type == "Склад" then
        local cargoName = data[2]
        local cargoId = (cargoName:find("n") and 1 or (cargoName:find("y") and 2 or (cargoName:find("l") and 3 or 0)))
        if cargoId ~= 0 then
            luChecker.load_position = { x = position.x, y = position.y, z = position.z }
        end
    end
end

function luChecker.checker()
    while true do
        wait(0)
        clear_old_value("price_set")
        clear_old_value("trailer_delete")

        if luChecker.price_set[1] ~= nil and luChecker.trailer_delete[1] ~= nil then
            playerId = luChecker.trailer_delete[1].playerId
            old_price = luChecker.price_set[1].old_price
            new_price = luChecker.price_set[1].new_price
            position_3dtext = luChecker.price_set[1].position
            position_trailer = luChecker.trailer_delete[1].position

            if getLocalPlayerId() ~= playerId then
                local dist = getDistanceBetweenCoords3d(position_3dtext.x,position_3dtext.y,position_3dtext.z,position_trailer.x,position_trailer.y,position_trailer.z)
                if dist < 50 then
                    local key = getPort(position_trailer.x,position_trailer.y,position_trailer.z)
                    key = key..cargo_replace[luChecker.price_set[1].key]
                    solo_message_send = {
                        name = getNameById(playerId),
                        id = playerId,
                        action = "unload",
                        cargo = key,
                        time = os.time()
                    }
                end
            end

            table.remove(luChecker.trailer_delete, 1)
            table.remove(luChecker.price_set, 1)
        end
    end
end

-- platinum
function platinum_check()
    if inifiles.platinum.status and inifiles.platinum.time < os.time() then
        addChatMessage("'Platinum VIP' закончился. Теперь у Вас кд сново 3 минуты")
        inifiles.platinum.status = false
        settings_save()
    end
end

function getLocalPlayerId()
    return select(2,sampGetPlayerIdByCharHandle(PLAYER_PED))
end

function getNameById(i)
    local name = ""
    if sampIsPlayerConnected(i) or i == select(2,sampGetPlayerIdByCharHandle(PLAYER_PED)) then
        name = sampGetPlayerNickname(i)
    end
    return name
end

function clear_old_value(key)
    local delete = {}
    for i = 1, #luChecker[key] do
        if os.clock() * 1000 - luChecker[key][i].time > 500 then
            delete[#delete+1] = i
        end
    end
    for i = 1, #delete do
        table.remove(luChecker[key], delete[i])
    end
end

function getKeysPoint(x, y, z)
    local minDist, minResult = 1000000, ""
    local resX, resY, resZ = 0.0, 0.0, 0.0
    for name, cord in pairs(location_keys) do
        if not name:find("ls") and not name:find("sf") then
            local distance = getDistanceBetweenCoords3d(x, y, z, cord.x, cord.y, cord.z)
            if distance < minDist then
                minDist = distance
                minResult = name
                resX, resY, resZ = cord.x, cord.y, cord.z
            end
        end
    end
    return minResult, resX, resY, resZ
end

function getPort(x, y, z)
    local coords = {
        ["ls"] = {x = 2507.02, y = -2234.05, z = 13.55},
        ["sf"] = {x = -1731.5022, y = 118.8936, z = 3.5547}
    }
    local minDist, minResult = 1000000, ""
    local resX, resY, resZ = 0.0, 0.0, 0.0
    for name, cord in pairs(coords) do
        local distance = getDistanceBetweenCoords3d(x, y, z, cord.x, cord.y, cord.z)
        if distance < minDist then
            minDist = distance
            minResult = name
            resX, resY, resZ = cord.x, cord.y, cord.z
        end
    end
    return minResult, resX, resY, resZ
end

function samp_create_sync_data(sync_type, copy_from_player)
    local ffi = require "ffi"
    local sampfuncs = require "sampfuncs"
    local raknet = require "samp.raknet"

    copy_from_player = copy_from_player or true
    local sync_traits = {
        player = {"PlayerSyncData", raknet.PACKET.PLAYER_SYNC, sampStorePlayerOnfootData},
        vehicle = {"VehicleSyncData", raknet.PACKET.VEHICLE_SYNC, sampStorePlayerIncarData},
        passenger = {"PassengerSyncData", raknet.PACKET.PASSENGER_SYNC, sampStorePlayerPassengerData},
        aim = {"AimSyncData", raknet.PACKET.AIM_SYNC, sampStorePlayerAimData},
        trailer = {"TrailerSyncData", raknet.PACKET.TRAILER_SYNC, sampStorePlayerTrailerData},
        unoccupied = {"UnoccupiedSyncData", raknet.PACKET.UNOCCUPIED_SYNC, nil},
        bullet = {"BulletSyncData", raknet.PACKET.BULLET_SYNC, nil},
        spectator = {"SpectatorSyncData", raknet.PACKET.SPECTATOR_SYNC, nil}
    }
    local sync_info = sync_traits[sync_type]
    local data_type = "struct " .. sync_info[1]
    local data = ffi.new(data_type, {})
    local raw_data_ptr = tonumber(ffi.cast("uintptr_t", ffi.new(data_type .. "*", data)))
    if copy_from_player then
        local copy_func = sync_info[3]
        if copy_func then
            local _, player_id
            if copy_from_player == true then
                _, player_id = sampGetPlayerIdByCharHandle(playerPed)
            else
                player_id = tonumber(copy_from_player)
            end
            copy_func(player_id, raw_data_ptr)
        end
    end
    local func_send = function()
        local bs = raknetNewBitStream()
        raknetBitStreamWriteInt8(bs, sync_info[2])
        raknetBitStreamWriteBuffer(bs, raw_data_ptr, ffi.sizeof(data))
        raknetSendBitStreamEx(bs, sampfuncs.HIGH_PRIORITY, sampfuncs.UNRELIABLE_SEQUENCED, 1)
        raknetDeleteBitStream(bs)
    end
    local mt = {
        __index = function(t, index)
            return data[index]
        end,
        __newindex = function(t, index, value)
            data[index] = value
        end
    }
    return setmetatable({send = func_send}, mt)
end

-->> UPDATE MODULE

function openURL(url, fpath)
    local text = ""
    local file_download = false
    local download_final = false


    if doesFileExist(fpath) then
        os.remove(fpath)
    end

    downloadUrlToFile(url, fpath, function(id, status, p1, p2)
        if status == dlstatus.STATUS_ENDDOWNLOADDATA then
            file_download = true
        end
        if status == dlstatus.STATUSEX_ENDDOWNLOAD then
            download_final = true
        end
    end
    )

    repeat
        wait(1000)
    until download_final or file_download

    if file_download then
        local f = io.open(fpath, "r")
        if f then
            text = f:read("*a")
            io.close(f)
        end
        os.remove(fpath)
    end

    if (text:find("Not found") and not text:find('"Not found"')) or text == "" then
        text = ""
        addChatMessage("Не удалось скачать обновление по ссылке:")
        addChatMessage(url)
    end

    return text
end


function addChatMessage(text)
    local tag = string.format("{667dff}[%s]{FFFFFF} ", thisScript().name)
    sampAddChatMessage(tag..text, 0xFFFFFFFF)
end

script_update = {
    version_url = "http://git.deadpoo.net/rubin/TruckHUD/raw/branch/master/version",
    script_url = "http://git.deadpoo.net/rubin/TruckHUD/raw/branch/master/TruckHUD.lua",
    changelog_url = "http://git.deadpoo.net/rubin/TruckHUD/raw/branch/master/changelog",
    address_ini = string.format("rubin-mods-updates\\%s.ini", thisScript().name),
    main = function()
        if not doesDirectoryExist("moonloader\\config\\rubin-mods-updates") then
            createDirectory("moonloader\\config\\rubin-mods-updates")
        end
        local ini = inicfg.load({
            settings = {
                check_update = true,
                auto_update = true,
                server_version = ""
            }
        }, script_update.address_ini)
        ini.settings.version_url = script_update.version_url
        ini.settings.script_url = script_update.script_url
        ini.settings.changelog_url = script_update.changelog_url
        ini.settings.version = thisScript().version
        ini.settings.script_name = thisScript().name
        local command = (thisScript().name:gsub(" ", "").."-update"):lower()
        sampRegisterChatCommand(command, script_update.command)
        if ini.settings.check_update or ini.settings.auto_update then
            local fpath = os.tmpname()
            local result, text = pcall(openURL, script_update.version_url, fpath)
            if result then
                ini.settings.server_version = text
                if text ~= "" and text ~= thisScript().version then
                    addChatMessage( string.format("Вышла новая версия '%s'. Текущая: '%s'", text, thisScript().version) )
                    if ini.settings.auto_update then
                        addChatMessage( string.format("Автообновление скрипта включено. Процесс запущен!") )
                        script_update.command()
                    else
                        addChatMessage( string.format("Автообновление скрипта выключено. Обновить самому: /%s", command) )
                    end
                end
            end
        end
        inicfg.save(ini, script_update.address_ini)
        script_update.menu.init()
    end,
    command = function()
        lua_thread.create(function()
            local fpath = os.tmpname()
            local result, text = pcall(openURL, script_update.version_url, fpath)
            if result then
                if text ~= "" and text ~= thisScript().version then
                    addChatMessage( string.format("Вышла новая версия '%s'. Текущая: '%s'", text, thisScript().version) )
                    local fpath = os.tmpname()
                    local result, text = pcall(openURL, script_update.script_url, fpath)
                    if result and text ~= "" and text:find(thisScript().name:gsub("%-", "%%-")) then
                        local file, error = io.open(thisScript().path, "w")
                        if file ~= nil then
                            file:write(text)
                            file:flush()
                            io.close(file)
                            addChatMessage("Обновление завершено, скрипт перезагружен!")
                            wait(500)
                            thisScript():reload()
                        end
                    end
                else
                    addChatMessage("У Вас установлена последняя версия!")
                end
            end
        end)
    end,
    menu = {
        dialog = {},
        ini = {},
        init = function()
            if not sampIsChatCommandDefined("rubin-mods") then
                sampAddChatMessage("{667dff}[RUBIN MODS]{FFFFFF} Управление обновлениями скриптов: /rubin-mods", 0xFFFFFFFF)
                sampRegisterChatCommand("rubin-mods",script_update.menu.show)
                while true do
                    wait(0)
                    local result, button, list, input = sampHasDialogRespond(2160)
                    if result and button == 1 then
                        if script_update.menu.ini[list+1] ~= nil and script_update.menu.dialog[list+1] ~= nil then
                            script_update.menu.dialog[list+1](script_update.menu.ini[list+1])
                        end
                    end
                    local result, button, list, input = sampHasDialogRespond(2162)
                    if result then
                        if button == 1 then
                            if script_update.menu2.text[list+1] ~= nil and script_update.menu2.dialog[list+1] ~= nil then
                                script_update.menu2.dialog[list+1]()
                            end
                        else
                            script_update.menu.show()
                        end
                    end
                    local result, button, list, input = sampHasDialogRespond(2161)
                    if result then
                        script_update.menu2.show(script_update.menu2.data)
                    end
                end
            end
        end,
        show = function()
            script_update.menu.dialog = {}
            script_update.menu.ini = {}
            local text = ""
            if doesDirectoryExist("moonloader\\config\\rubin-mods-updates") then
                local FileHandle, FileName = findFirstFile("moonloader\\config\\rubin-mods-updates\\*")
                while FileName ~= nil do
                    if FileName ~= nil and FileName ~= ".." and FileName ~= "." and FileName:find("%.ini") then
                        local address = string.format("moonloader\\config\\rubin-mods-updates\\%s", FileName)
                        if doesFileExist(address) then
                            local ini = inicfg.load({}, address)
                            script_update.menu.ini[#script_update.menu.ini+1] = address
                            text = string.format("%s%s\n", text, string.format("%s\t%s%s", ini.settings.script_name, (ini.settings.version == ini.settings.server_version and "{59fc30}" or "{ff0000}"),ini.settings.version))
                            script_update.menu.dialog[#script_update.menu.dialog+1] = function(data)
                               script_update.menu2.show(data)
                            end
                        end
                    end
                    FileName = findNextFile(FileHandle)
                end
                findClose(FileHandle)
            else
                text = "Не найдена директория:\t\n    moonloader\\config\\rubin-mods-updates\t"
            end
            sampShowDialog(2160,"Обновление скриптов: Rubin Mods","Скрипт\tВерсия\n"..text,"Выбрать","Закрыть",5)
        end
    },
    menu2 = {
        data = {},
        text = {},
        dialog = {},
        show = function(data)
            script_update.menu2.data = data
            script_update.menu2.text = {}
            script_update.menu2.dialog = {}
            if doesFileExist(data) then
                local ini = inicfg.load({}, data)
                script_update.menu2.text[#script_update.menu2.text+1] = string.format("Автообновление %s", (ini.settings.auto_update and "{59fc30}ON" or "{ff0000}OFF"))
                script_update.menu2.dialog[#script_update.menu2.dialog+1] = function()
                    ini.settings.auto_update = not ini.settings.auto_update
                    inicfg.save(ini, data)
                    script_update.menu2.show(data)
                end
                if not ini.settings.auto_update then
                    script_update.menu2.text[#script_update.menu2.text+1] = string.format("Проверять обновления %s", (ini.settings.check_update and "{59fc30}ON" or "{ff0000}OFF"))
                    script_update.menu2.dialog[#script_update.menu2.dialog+1] = function()
                        ini.settings.check_update = not ini.settings.check_update
                        inicfg.save(ini, data)
                        script_update.menu2.show(data)
                    end
                end
                script_update.menu2.text[#script_update.menu2.text+1] = string.format("Последние изменения")
                script_update.menu2.dialog[#script_update.menu2.dialog+1] = function()
                    script_update.changelog(ini.settings.changelog_url, ini.settings.script_name)
                end
                script_update.menu2.text[#script_update.menu2.text+1] = string.format("Удалить из списка")
                script_update.menu2.dialog[#script_update.menu2.dialog+1] = function()
                    os.remove(data)
                    script_update.menu.show()
                end
                local text = ""
                for i = 1, #script_update.menu2.text do
                    text = text..script_update.menu2.text[i].."\n"
                end
                sampShowDialog(2162,"Настройки обновления для "..ini.settings.script_name,text,"Выбрать","Назад",2)
            end
        end
    },
    changelog = function(url, name)
        local fpath = os.tmpname()
        local result, text = pcall(openURL, url, fpath)
        if result then
            sampShowDialog(2161,"Changelog - "..name,text,"Выбрать","Назад",4)
        end
    end
}

-->> SCRIPT UTF-8
-->> utf8(table path, incoming variables encoding, outcoming variables encoding)
-->> table path example { "sampev", "onShowDialog" }
-->> encoding options nil | AnsiToUtf8 | Utf8ToAnsi
_utf8 = load([=[return function(utf8_func, in_encoding, out_encoding); if encoding == nil then; encoding = require("encoding"); encoding.default = "CP1251"; u8 = encoding.UTF8; end; if type(utf8_func) ~= "table" then; return false; end; if AnsiToUtf8 == nil or Utf8ToAnsi == nil then; AnsiToUtf8 = function(text); return u8(text); end; Utf8ToAnsi = function(text); return u8:decode(text); end; end; if _UTF8_FUNCTION_SAVE == nil then; _UTF8_FUNCTION_SAVE = {}; end; local change_var = "_G"; for s = 1, #utf8_func do; change_var = string.format('%s["%s"]', change_var, utf8_func[s]); end; if _UTF8_FUNCTION_SAVE[change_var] == nil then; _UTF8_FUNCTION = function(...); local pack = table.pack(...); readTable = function(t, enc); for k, v in next, t do; if type(v) == 'table' then; readTable(v, enc); else; if enc ~= nil and (enc == "AnsiToUtf8" or enc == "Utf8ToAnsi") then; if type(k) == "string" then; k = _G[enc](k); end; if type(v) == "string" then; t[k] = _G[enc](v); end; end; end; end; return t; end; return table.unpack(readTable({_UTF8_FUNCTION_SAVE[change_var](table.unpack(readTable(pack, in_encoding)))}, out_encoding)); end; local text = string.format("_UTF8_FUNCTION_SAVE['%s'] = %s; %s = _UTF8_FUNCTION;", change_var, change_var, change_var); load(text)(); _UTF8_FUNCTION = nil; end; return true; end]=])

function utf8(...)
    pcall(_utf8(), ...)
end

utf8({ "sampShowDialog" }, "Utf8ToAnsi")
utf8({ "sampSendChat" }, "Utf8ToAnsi")
utf8({ "sampAddChatMessage" }, "Utf8ToAnsi")
utf8({ "print" }, "Utf8ToAnsi")
utf8({ "renderGetFontDrawTextLength" }, "Utf8ToAnsi")
utf8({ "renderFontDrawText" }, "Utf8ToAnsi")
utf8({ "sampSetCurrentDialogEditboxText" }, "Utf8ToAnsi")
utf8({ "sampCreate3dTextEx" }, "Utf8ToAnsi")
utf8({ "sampCreate3dText" }, "Utf8ToAnsi")
utf8({ "sampSet3dTextString" }, "Utf8ToAnsi")
utf8({ "sampGetDialogText" }, nil, "AnsiToUtf8")
utf8({ "sampGetDialogCaption" }, nil, "AnsiToUtf8")
utf8({ "sampHasDialogRespond" }, nil, "AnsiToUtf8")