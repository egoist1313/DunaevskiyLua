local script_name = 'mafia-tools'
local script_author = 'Serhiy_Rubin'
local script_version = '05.07.2025'
sampev = require 'samp.events'
inicfg = require "inicfg"
dlstatus = require("moonloader").download_status
vkeys = require "vkeys"
live = 0

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	while not isSampAvailable() do wait(0) end
    --lua_thread.create(script_update.main)
    repeat wait(0) until sampGetCurrentServerName() ~= "SA-MP"
    repeat wait(0) until sampGetCurrentServerName():find("Samp%-Rp.Ru") or sampGetCurrentServerName():find("SRP")
    local server = getSampRpServerName()
    if server == "" then
        thisScript():unload()
    end
    config.init()
    lua_thread.create(timer_2min.loop)
    lua_thread.create(ammo_timer.loop)
    lua_thread.create(request.loop)
    lua_thread.create(menu.loop)
    lua_thread.create(mafia_checker.loop)
    lua_thread.create(antiflood.loop)
    lua_thread.create(invite_helper.loop)
    lua_thread.create(get_guns.loop)
    lua_thread.create(updateScoresAndPing)
    lua_thread.create(mafiawar.loop)
    lua_thread.create(mhcars.loop)
    lua_thread.create(healme.loop)
    lua_thread.create(armoff.loop)
    lua_thread.create(clistoff.loop)
    lua_thread.create(stream_checker.loop)

    while true do
        wait(0)
        live = os.time()
        msg.loop()
    end
end

-->> MENU DIALOG
menu = {}
menu.dialog = {}
menu.data = {}
menu.ffixcar_log = {}
menu.update = function()

    -->> Список блокировщика
    local blacklist = {}
    for k,v in pairs(config.data.list) do
        blacklist[#blacklist+1] = {
            title = k,
            click = function(button, list, input , outs)
                if button == 1 then
                    config.data.list[k] = nil
                    config.save(config.data)
                    addChatMessage(string.format("Вы удалили %s из списка!", k))
                end
                menu.show = { true, "main" }
            end
        }
    end

    -->> Обновление инфы от сервера
    local players = getNicknamesOnline()
    local count = 0
    local members = {}
    for sender, sender_data in pairs(menu.data) do
        count = count + 1
        members[#members+1] = {
            title = string.format("%s\t", (players[sender] ~= nil and sender.."["..players[sender].."]" or sender)),
            click = function(button, list, input, outs)
                if button == 1 then
                    menu.show = {
                        true,
                        "members_user",
                        {
                            {
                                title = (config.data.list[sender] ~= nil and "Убрать из списка" or "Добавить в список"),
                                click = function(button, list, input , outs)
                                    if button == 1 then
                                        if config.data.list[sender] == nil then
                                            config.data.list[sender] = true
                                            addChatMessage(string.format("Вы добавли %s в список!", sender))
                                        else
                                            config.data.list[sender] = nil
                                            addChatMessage(string.format("Вы удалили %s из списка!", sender))
                                        end
                                        config.save(config.data)
                                    end
                                    menu.show = { true, "members" }
                                end
                            },
                            {
                                title = "{"..config.data.font.color1.."}".."Тайминги от пользователя:",
                                click = function(button, list, input , outs)
                                    menu.show = { true, "members" }
                                end
                            },
                            {
                                title = "{"..config.data.font.color1.."}"..">{FFFFFF} LS: "..sender_data["ls"]["text"].." "..(sender_data["mhcars"]["time"] > 0 and math.floor(msk_time.get() - sender_data["mhcars"]["time"]).." sec" or ""),
                                click = function(button, list, input , outs)
                                    menu.show = { true, "members" }
                                end
                            },
                            {
                                title = "{"..config.data.font.color1.."}"..">{FFFFFF} SF: "..sender_data["sf"]["text"].." "..(sender_data["mhcars"]["time"] > 0 and math.floor(msk_time.get() - sender_data["mhcars"]["time"]).." sec" or ""),
                                click = function(button, list, input , outs)
                                    menu.show = { true, "members" }
                                end
                            },
                            {
                                title = "{"..config.data.font.color1.."}"..">{FFFFFF} LV: "..sender_data["lv"]["text"].." "..(sender_data["mhcars"]["time"] > 0 and math.floor(msk_time.get() - sender_data["mhcars"]["time"]).." sec" or ""),
                                click = function(button, list, input , outs)
                                    menu.show = { true, "members" }
                                end
                            },
                            {
                                title = "{"..config.data.font.color1.."}"..">{FFFFFF} MHCARS: "..sender_data["mhcars"]["text"].." "..(sender_data["mhcars"]["time"] > 0 and math.floor(msk_time.get() - sender_data["mhcars"]["time"]).." sec" or ""),
                                click = function(button, list, input , outs)
                                    menu.show = { true, "members" }
                                end
                            },
                        }
                    }
                else
                    menu.show = { true, "main" }
                end
            end
        }
    end

    -- Список армофф айди
    local armoff_list = ""
    for i = 1, #config.data.armoff do
        armoff_list = string.format("%s%s%s", armoff_list, (i == 1 and "" or " "), config.data.armoff[i])
    end
    if armoff_list == "" then
        armoff_list = "нет"
    end

    menu.dialog = {
		["main"] = {
			settings = {title = "mafia-tools" ,style = 4 ,btn1 = "Выбрать" ,btn2 = "Закрыть" ,forward =  "{ffffff}" ,backwards = "\n" ,score = false},
			{
                { -->> Синхронизация таймингов
                    title = "{"..config.data.font.color1.."}".."Синхронизация таймингов\t",
					click = function(button, list, input , outs)
						if button ~= 1 then return end
						menu.show = { true, "main" }
					end
                },
				{ -->> Комната
					title = "{"..config.data.font.color1.."}"..">{ffffff} Комната\t"..config.data.room,
					click = function(button, list, input , outs)
						if button ~= 1 then return end
                        menu.show = { true, "edit", function(button, list, input, outs)
                            if button == 1 then
                                if #input > 0 then
                                    config.data.room = input
                                    config.save(config.data)
                                end
                            end
                            menu.show = { true, "main" }
                        end, config.data.room, "Введите название комнаты!"}
					end
				},
				{ -->> Участники
					title = "{"..config.data.font.color1.."}"..">{ffffff} Участники комнаты\t"..count,
					click = function(button, list, input , outs)
						if button ~= 1 then return end
						menu.show = { true, "members" }
					end
				},
				{ -->> Список блокировщика
					title = "{"..config.data.font.color1.."}"..">{ffffff} Список блокировщика\t",
					click = function(button, list, input , outs)
						if button ~= 1 then return end
                        if #blacklist > 0 then
                            menu.show = { true, "members_user", blacklist }
                        else
                            menu.show = { true, "main" }
                        end
					end
				},
				{ -->> Использовать список как
					title = "{"..config.data.font.color1.."}"..">{ffffff} Использовать список как:\t"..(config.data.list_block and "Черный список" or "Белый список"),
					click = function(button, list, input , outs)
						if button ~= 1 then return end
                        config.data.list_block = not config.data.list_block
                        config.save(config.data)
                        menu.show = { true, "main" }
					end
				},
                { -->> Клавиша отправки таймингов
                    title = "{"..config.data.font.color1.."}"..">{ffffff} Отправить тайминги в рацию\t"..convertKeysToText(config.data.chat_timing.key),
                    click = function(button, list, input , outs)
                        if button ~= 1 then return end
                        config.data.chat_timing.key = setKeys()
                        config.save(config.data)
						menu.show = { true, "main" }
                    end
                },
				{ -->> Отправлять тайминги при получении
					title = "{"..config.data.font.color1.."}"..">{ffffff} Отправлять тайминги в рацию при проверке\t"..(config.data.chat_timing.auto and "вкл" or "выкл"),
					click = function(button, list, input , outs)
						if button ~= 1 then return end
                        config.data.chat_timing.auto = not config.data.chat_timing.auto
                        config.save(config.data)
						menu.show = { true, "main" }
					end
				},
                { -->> Разделитель
                    title = " \t ",
                    click = function(button, list, input , outs)
                        if button ~= 1 then return end
                        menu.show = { true, "main" }
                    end
                },
                { -->> Настройки отображения
                    title = "{"..config.data.font.color1.."}".."Настройки отображения\t",
					click = function(button, list, input , outs)
						if button ~= 1 then return end
						menu.show = { true, "main" }
					end
                },
				{ -->> Рендер
					title = "{"..config.data.font.color1.."}"..">{ffffff} Показать на экране\t"..(config.data.timer_hud.main and "вкл" or "выкл"),
					click = function(button, list, input , outs)
						if button ~= 1 then return end
                        config.data.timer_hud.main = not config.data.timer_hud.main
                        config.save(config.data)
						menu.show = { true, "main" }
					end
				},
				{ -->> Показывать таймер mhcars
                    title = "{"..config.data.font.color1.."}"..">{ffffff} Показывать таймер mhcars\t"..(config.data.timer_hud.mhcars and "вкл" or "выкл"),
					click = function(button, list, input , outs)
						if button ~= 1 then return end
                        config.data.timer_hud.mhcars = not config.data.timer_hud.mhcars
                        config.save(config.data)
						menu.show = { true, "main" }
					end
				},
				{ -->> Показывать таймер ffixcar
                    title = "{"..config.data.font.color1.."}"..">{ffffff} Показывать таймер ffixcar\t"..(config.data.timer_hud.ffixcar and "вкл" or "выкл"),
					click = function(button, list, input , outs)
						if button ~= 1 then return end
                        config.data.timer_hud.ffixcar = not config.data.timer_hud.ffixcar
                        config.save(config.data)
						menu.show = { true, "main" }
					end
				},
				{ -->> Логи ffixcar
					title = "{"..config.data.font.color1.."}"..">{ffffff} Логи /ffixcar\t",
					click = function(button, list, input , outs)
						if button ~= 1 then return end
                        wait(100)
						menu.show = { true, "ffixcar_log" }
					end
				},
				{ -->> Смена позиции
					title = "{"..config.data.font.color1.."}"..">{ffffff} Сменить позицию\t",
					click = function(button, list, input , outs)
						if button ~= 1 then return end
                        config.data.timer_hud.main = true
                        wait(100)
                        ammo_timer.setpos = true
						menu.show = { true, "main" }
					end
				},
                { -->> Разделитель
                    title = " \t ",
                    click = function(button, list, input , outs)
                        if button ~= 1 then return end
                        menu.show = { true, "main" }
                    end
                },
                { -->> Mafia Checker
                    title = "{"..config.data.font.color1.."}".."Счетчик мафий на сервере и в стриме\t",
                    click = function(button, list, input , outs)
                        if button ~= 1 then return end
                        menu.show = { true, "main" }
                    end
                },
				{ -->> Рендер Mafia Checker
					title = "{"..config.data.font.color1.."}"..">{ffffff} Показать на экране\t"..(config.data.mafia_checker.main and "вкл" or "выкл"),
					click = function(button, list, input , outs)
						if button ~= 1 then return end
                        config.data.mafia_checker.main = not config.data.mafia_checker.main
                        config.save(config.data)
						menu.show = { true, "main" }
					end
				},
				{ -->> Позиция Mafia Checker
					title = "{"..config.data.font.color1.."}"..">{ffffff} Сменить позицию\t",
					click = function(button, list, input , outs)
						if button ~= 1 then return end
                        wait(100)
                        config.data.mafia_checker.main = true
                        mafia_checker.setpos = true
						menu.show = { true, "main" }
					end
				},
                { -->> Разделитель
                    title = " \t ",
                    click = function(button, list, input , outs)
                        if button ~= 1 then return end
                        menu.show = { true, "main" }
                    end
                },
                { -->> Invite Helper
                    title = "{"..config.data.font.color1.."}".."Инвайт хелпер\t",
                    click = function(button, list, input , outs)
                        if button ~= 1 then return end
                        menu.show = { true, "main" }
                    end
                },
                { -->> Минимальный лвл
                    title = "{"..config.data.font.color1.."}"..">{ffffff} Минимальный уровень\t"..config.data.invite_helper.lvl,
                    click = function(button, list, input , outs)
                        if button ~= 1 then return end
                        menu.show = { true, "edit", function(button, list, input, outs)
                            if button == 1 then
                                if #input > 0 and input:find("(%d+)") then
                                    config.data.invite_helper.lvl = tonumber(input:match("(%d+)"))
                                    config.save(config.data)
                                end
                            end
                            menu.show = { true, "main" }
                        end, config.data.invite_helper.lvl, "Введите минимальный уровень для инвайта!"}
                    end
                },
				{ -->> Авто ранг вкл выкл
					title = "{"..config.data.font.color1.."}"..">{ffffff} Устанавливать ранг автоматически\t"..(config.data.invite_helper.auto_rank and "вкл" or "выкл"),
					click = function(button, list, input , outs)
						if button ~= 1 then return end
                        config.data.invite_helper.auto_rank = not config.data.invite_helper.auto_rank
                        config.save(config.data)
						menu.show = { true, "main" }
					end
				},
                { -->> Ранг по умолчанию
                    title = "{"..config.data.font.color1.."}"..">{ffffff} Установить ранг\t"..config.data.invite_helper.rank,
                    click = function(button, list, input , outs)
                        if button ~= 1 then return end
                        menu.show = { true, "edit", function(button, list, input, outs)
                            if button == 1 then
                                if #input > 0 and input:find("(%d+)") then
                                    config.data.invite_helper.rank = tonumber(input:match("(%d+)"))
                                    config.save(config.data)
                                end
                            end
                            menu.show = { true, "main" }
                        end, config.data.invite_helper.rank, "Введите какой ранг давать после инвайта!"}
                    end
                },
                { -->> Сообщение в чат после инвайта
                    title = "{"..config.data.font.color1.."}"..">{ffffff} Сообщение в рацию\t"..config.data.invite_helper.message,
                    click = function(button, list, input , outs)
                        if button ~= 1 then return end
                        menu.show = { true, "edit", function(button, list, input, outs)
                            if button == 1 then
                                config.data.invite_helper.message = input
                                config.save(config.data)
                            end
                            menu.show = { true, "main" }
                        end, config.data.invite_helper.message, "{name} - Заменится на никнейм игрока которого приняли\nЧтобы не отправлять сообщение оставьте поле пустым!"}
                    end
                },
                { -->> Клавиша инвайта
                    title = "{"..config.data.font.color1.."}"..">{ffffff} Инвайт по кнопке\tПрицел + "..convertKeysToText(config.data.invite_helper.key),
                    click = function(button, list, input , outs)
                        if button ~= 1 then return end
                        config.data.invite_helper.key = setKeys()
                        config.save(config.data)
						menu.show = { true, "main" }
                    end
                },
                { -->> Разделитель
                    title = " \t ",
                    click = function(button, list, input , outs)
                        if button ~= 1 then return end
                        menu.show = { true, "main" }
                    end
                },
                { -->> Склад
                    title = "{"..config.data.font.color1.."}".."Склад\t",
                    click = function(button, list, input , outs)
                        if button ~= 1 then return end
                        menu.show = { true, "main" }
                    end
                },
				{ -->> Открывать склад по запросу в рацию
					title = "{"..config.data.font.color1.."}"..">{ffffff} Открывать склад по запросу\t"..(config.data.get_guns.warelock_auto and "вкл" or "выкл"),
					click = function(button, list, input , outs)
						if button ~= 1 then return end
                        config.data.get_guns.warelock_auto = not config.data.get_guns.warelock_auto
                        config.save(config.data)
						menu.show = { true, "main" }
					end
				},
                { -->> Открывать склад на
                    title = "{"..config.data.font.color1.."}"..">{ffffff} Держать склад открытым\t"..config.data.get_guns.warelock_time.." сек",
                    click = function(button, list, input , outs)
                        if button ~= 1 then return end
                        menu.show = { true, "edit", function(button, list, input, outs)
                            if button == 1 then
                                if #input > 0 and input:find("(%d+)") then
                                    if tonumber(input:match("(%d+)")) > 0 then
                                        config.data.get_guns.warelock_time = tonumber(input:match("(%d+)"))
                                        config.save(config.data)
                                    end
                                end
                            end
                            menu.show = { true, "main" }
                        end, config.data.get_guns.warelock_time, "Введите сколько секунд склад держать открытым"}
                    end
                },
				{ -->> Брать оружие сразу как откроют склад
					title = "{"..config.data.font.color1.."}"..">{ffffff} Брать оружие сразу как откроют склад\t"..(config.data.get_guns.auto_get_guns and "вкл" or "выкл"),
					click = function(button, list, input , outs)
						if button ~= 1 then return end
                        config.data.get_guns.auto_get_guns = not config.data.get_guns.auto_get_guns
                        config.save(config.data)
						menu.show = { true, "main" }
					end
				},
                { -->> Клавиша взятия ганов
                    title = "{"..config.data.font.color1.."}"..">{ffffff} Брать оружие по кнопке\t"..convertKeysToText(config.data.get_guns.key),
                    click = function(button, list, input , outs)
                        if button ~= 1 then return end
                        config.data.get_guns.key = setKeys()
                        config.save(config.data)
						menu.show = { true, "main" }
                    end
                },
                { -->> Список оружия
                    title = "{"..config.data.font.color1.."}"..">{ffffff} Список оружия\t",
                    click = function(button, list, input , outs)
                        if button ~= 1 then return end
                        menu.show = { true, "get_guns" }
                    end
                },
                { -->> Разделитель
                    title = " \t ",
                    click = function(button, list, input , outs)
                        if button ~= 1 then return end
                        menu.show = { true, "main" }
                    end
                },
                { -->> Mafiawar
                    title = "{"..config.data.font.color1.."}".."Забив\t",
                    click = function(button, list, input , outs)
                        if button ~= 1 then return end
                        menu.show = { true, "main" }
                    end
                },
                { -->> Mafiawar auto
                    title = "{"..config.data.font.color1.."}"..">{ffffff} Флудер\t"..(config.data.mafiawar.auto and "вкл" or "выкл"),
					click = function(button, list, input , outs)
						if button ~= 1 then return end
                        config.data.mafiawar.auto = not config.data.mafiawar.auto
                        config.save(config.data)
						menu.show = { true, "main" }
					end
                },
				{ -->> Mafiawar id
					title = "{"..config.data.font.color1.."}"..">{ffffff} ID\t"..config.data.mafiawar.id,
					click = function(button, list, input , outs)
						if button ~= 1 then return end
                        menu.show = { true, "edit", function(button, list, input, outs)
                            if button == 1 then
                                if input:find("(%d+)") then
                                    local id = tonumber(input:match("(%d+)"))
                                    if id >= 0 and id <= 4 then
                                        config.data.mafiawar.id = id
                                        config.save(config.data)
                                    end
                                end
                            end
                            menu.show = { true, "main" }
                        end, config.data.mafiawar.id, "Введите ID для стрелы [0-4]"}
					end
				},
				{ -->> Mafiawar wait
					title = "{"..config.data.font.color1.."}"..">{ffffff} Задержка флудера\t"..config.data.mafiawar.wait.." ms",
					click = function(button, list, input , outs)
						if button ~= 1 then return end
                        menu.show = { true, "edit", function(button, list, input, outs)
                            if button == 1 then
                                if input:find("(%d+)") then
                                    local wait = tonumber(input:match("(%d+)"))
                                    config.data.mafiawar.wait = wait
                                    config.save(config.data)
                                end
                            end
                            menu.show = { true, "main" }
                        end, config.data.mafiawar.wait, "Введите задержку для флудера mafiawar в ms"}
					end
				},
                { -->> Разделитель
                    title = " \t ",
                    click = function(button, list, input , outs)
                        if button ~= 1 then return end
                        menu.show = { true, "main" }
                    end
                },
                { -->> Mhcars
                    title = "{"..config.data.font.color1.."}".."Перегон\t",
                    click = function(button, list, input , outs)
                        if button ~= 1 then return end
                        menu.show = { true, "main" }
                    end
                },
                { -->> Mhcars auto
                    title = "{"..config.data.font.color1.."}"..">{ffffff} Флудер перегона\t"..(config.data.mhcars.auto and "вкл" or "выкл"),
					click = function(button, list, input , outs)
						if button ~= 1 then return end
                        config.data.mhcars.auto = not config.data.mhcars.auto
                        config.save(config.data)
						menu.show = { true, "main" }
					end
                },
				{ -->> Кому перегон
					title = "{"..config.data.font.color1.."}"..">{ffffff} Кому\t"..config.data.mhcars.gang,
					click = function(button, list, input , outs)
						if button ~= 1 then return end
                        menu.show = { true, "edit", function(button, list, input, outs)
                            if button == 1 then
                                if #input > 0 then
                                    config.data.mhcars.gang = input
                                    config.save(config.data)
                                end
                            end
                            menu.show = { true, "main" }
                        end, config.data.mhcars.gang, "Введите название банды\n\tgrove\n\tballas\n\tvagos\n\trifa\n\taztec"}
					end
				},
				{ -->> Таймер перегон
					title = "{"..config.data.font.color1.."}"..">{ffffff} Задержка флуда\t"..config.data.mhcars.wait.." ms",
					click = function(button, list, input , outs)
						if button ~= 1 then return end
                        menu.show = { true, "edit", function(button, list, input, outs)
                            if button == 1 then
                                if input:find("(%d+)") then
                                    config.data.mhcars.wait = tonumber(input:match("(%d+)"))
                                    config.save(config.data)
                                end
                            end
                            menu.show = { true, "main" }
                        end, config.data.mhcars.wait, "Введите задержку для флудера mhcars в ms"}
					end
				},
				{ -->> Начать флудить раньше на сек
					title = "{"..config.data.font.color1.."}"..">{ffffff} Флудить раньше на\t"..config.data.mhcars.offset_wait.." sec",
					click = function(button, list, input , outs)
						if button ~= 1 then return end
                        menu.show = { true, "edit", function(button, list, input, outs)
                            if button == 1 then
                                if input:find("(%d+)") then
                                    config.data.mhcars.offset_wait = tonumber(input:match("(%d+)"))
                                    config.save(config.data)
                                end
                            end
                            menu.show = { true, "main" }
                        end, config.data.mhcars.offset_wait, "Введите на сколько секунд раньше нужно начать флудить"}
					end
				},
                { -->> Разделитель
                    title = " \t ",
                    click = function(button, list, input , outs)
                        if button ~= 1 then return end
                        menu.show = { true, "main" }
                    end
                },
                { -->> Список отсутствующих
                    title = "{"..config.data.font.color1.."}".."Список отсутствующих\t",
                    click = function(button, list, input , outs)
                        if button ~= 1 then return end
                        menu.show = { true, "main" }
                    end
                },
				{ -->> Отправить по команде
					title = "{"..config.data.font.color1.."}"..">{ffffff} Отправить по команде\t/"..config.data.stream_checker,
					click = function(button, list, input , outs)
						if button ~= 1 then return end
                        menu.show = { true, "edit", function(button, list, input, outs)
                            if button == 1 then
                                if #input > 0 then
                                    config.data.stream_checker = input
                                    config.save(config.data)
                                end
                            end
                            menu.show = { true, "main" }
                        end, config.data.stream_checker, "Введите название команды\nПо умолчанию: progul"}
					end
				},
                { -->> Отправлять ID или Ники
                    title = "{"..config.data.font.color1.."}"..">{ffffff} Режим\t"..(config.data.stream_checker_name and "Ник[ID] - Ранг" or "Только ID"),
					click = function(button, list, input , outs)
						if button ~= 1 then return end
                        config.data.stream_checker_name = not config.data.stream_checker_name
                        config.save(config.data)
						menu.show = { true, "main" }
					end
                },
                { -->> Разделитель
                    title = " \t ",
                    click = function(button, list, input , outs)
                        if button ~= 1 then return end
                        menu.show = { true, "main" }
                    end
                },
                { -->> ПРочее
                    title = "{"..config.data.font.color1.."}".."Прочее\t",
                    click = function(button, list, input , outs)
                        if button ~= 1 then return end
                        menu.show = { true, "main" }
                    end
                },
				{ -->> Авто healme
					title = "{"..config.data.font.color1.."}"..">{ffffff} Использовать аптечку\t"..(config.data.healme and "вкл" or "выкл"),
					click = function(button, list, input , outs)
						if button ~= 1 then return end
                        config.data.healme = not config.data.healme
                        config.save(config.data)
					end
				},
				{ -->> armoff
					title = "{"..config.data.font.color1.."}"..">{ffffff} armoff на ID стрел\t"..armoff_list,
					click = function(button, list, input , outs)
						if button ~= 1 then return end
                        menu.show = { true, "edit", function(button, list, input, outs)
                            if button == 1 then
                                local arr = split(input, " ")
                                local new = {}
                                for i = 1, #arr do
                                    if arr[i]:find("(%d+)") then
                                        new[#new+1] = tonumber(arr[i]:match("(%d+)"))
                                    end
                                end
                                config.data.armoff = new
                                config.save(config.data)
                            end
                            menu.show = { true, "main" }
                        end, armoff_list, "Введите ID стрел на которых нужно оффать броню\nВведите ID через пробел\nПример: 0 1 3"}
					end
				},
				{ -->> clistoff
					title = "{"..config.data.font.color1.."}"..">{ffffff} clist off при спавне/после стрелы\t"..(config.data.clistoff and "вкл" or "выкл"),
					click = function(button, list, input , outs)
						if button ~= 1 then return end
                        config.data.clistoff = not config.data.clistoff
                        config.save(config.data)
                        menu.show = { true, "main" }
					end
				},
			}
		},
        ["edit"] = {
			settings = {title = "mafia-tools" ,style = 1 ,btn1 = "Выбрать" ,btn2 = "Назад" ,forward =  "{ffffff}" ,backwards = "\n" ,score = true},
			{
                text = menu.show[5],
				{
					click = function(button, list, input, outs)
						menu.show[3](button, list, input, outs)
					end
				}
			}
        },
        ["members"] = {
            settings = {title = "mafia-tools" ,style = 4 ,btn1 = "Выбрать" ,btn2 = "Назад" ,forward =  "{ffffff}" ,backwards = "\n" ,score = true},
            members
        },
        ["members_user"] = {
            settings = {title = "mafia-tools" ,style = 2 ,btn1 = "Выбрать" ,btn2 = "Назад" ,forward =  "{ffffff}" ,backwards = "\n" ,score = true},
            menu.show[3]
        },
        ["ffixcar_log"] = {
            settings = {title = "mafia-tools" ,style = 0 ,btn1 = "Выбрать" ,btn2 = "Назад" ,forward =  "{ffffff}" ,backwards = "\n" ,score = false},
            {
                text = menu.ffixcar_log,
                {
					click = function(button, list, input, outs)
						menu.show = { true, "main" }
					end
                }
            }
        },
        ["get_guns"] = {
            settings = {title = "mafia-tools" ,style = 4 ,btn1 = "Выбрать" ,btn2 = "Назад" ,forward =  "{ffffff}" ,backwards = "\n" ,score = true},
            {
                { -->> Desert Eagle
                    title = "Desert Eagle\t"..config.data.get_guns.list[1][2],
                    click = function(button, list, input, outs)
                        if button ~= 1 then
                            menu.show = { true, "main" }
                            return
                        end
                        config.data.get_guns.list[1][2] = config.data.get_guns.list[1][2] + 1
                        config.save(config.data)
                        menu.show[1] = true
                    end
                },
                { -->> Shotgun
                    title = "Shotgun\t"..config.data.get_guns.list[2][2],
                    click = function(button, list, input, outs)
                        if button ~= 1 then
                            menu.show = { true, "main" }
                            return
                        end
                        config.data.get_guns.list[2][2] = config.data.get_guns.list[2][2] + 1
                        config.save(config.data)
                        menu.show[1] = true
                    end
                },
                { -->> SMG
                    title = "SMG\t"..config.data.get_guns.list[3][2],
                    click = function(button, list, input, outs)
                        if button ~= 1 then
                            menu.show = { true, "main" }
                            return
                        end
                        config.data.get_guns.list[3][2] = config.data.get_guns.list[3][2] + 1
                        config.save(config.data)
                        menu.show[1] = true
                    end
                },
                { -->> AK47
                    title = "AK47\t"..config.data.get_guns.list[4][2],
                    click = function(button, list, input, outs)
                        if button ~= 1 then
                            menu.show = { true, "main" }
                            return
                        end
                        config.data.get_guns.list[4][2] = config.data.get_guns.list[4][2] + 1
                        config.save(config.data)
                        menu.show[1] = true
                    end
                },
                { -->> M4A1
                    title = "M4A1\t"..config.data.get_guns.list[5][2],
                    click = function(button, list, input, outs)
                        if button ~= 1 then
                            menu.show = { true, "main" }
                            return
                        end
                        config.data.get_guns.list[5][2] = config.data.get_guns.list[5][2] + 1
                        config.save(config.data)
                        menu.show[1] = true
                    end
                },
                { -->> Rifle
                    title = "Rifle\t"..config.data.get_guns.list[6][2],
                    click = function(button, list, input, outs)
                        if button ~= 1 then
                            menu.show = { true, "main" }
                            return
                        end
                        config.data.get_guns.list[6][2] = config.data.get_guns.list[6][2] + 1
                        config.save(config.data)
                        menu.show[1] = true
                    end
                },
                { -->> Броня
                    title = "Броня\t"..config.data.get_guns.list[7][2],
                    click = function(button, list, input, outs)
                        if button ~= 1 then
                            menu.show = { true, "main" }
                            return
                        end
                        config.data.get_guns.list[7][2] = config.data.get_guns.list[7][2] + 1
                        config.save(config.data)
                        menu.show[1] = true
                    end
                },
                { -->> Сброс
                    title = "Сброс\t",
                    click = function(button, list, input, outs)
                        if button ~= 1 then
                            menu.show = { true, "main" }
                            return
                        end
                        for i = 1, #config.data.get_guns.list do
                            config.data.get_guns.list[i][2] = 0
                        end
                        config.save(config.data)
                        menu.show[1] = true
                    end
                },
            }
        },
	}
end
menu.show = { false, "main" }
menu.put = ""
af_chat = 0
menu.loop = function()
	sampRegisterChatCommand('maf', function(param)
        if #param > 0 then
            if os.time() - af_chat < 60 then
                addChatMessage("Не чаще чем раз в минуту!")
            else
                request.send[#request.send + 1] = {
                    key = "messages",
                    text = AnsiToUtf8(param)
                }
                request.wait = 0
                af_chat = os.time()
            end
        else
		    menu.show = { true, "main" }
        end
	end)
	while true do
		wait(0)
		if menu.show[1] then
			menu.show[1] = false
            menu.update()
            if menu.dialog[menu.show[2]] ~= nil then
                wait(100)
			    start_dialog(menu.dialog[menu.show[2]], menu.show[4])
            end
		end
	end
end

-->> STREAM CHECKER
stream_checker = {}
stream_checker.hide = 0
stream_checker.members = {}
stream_checker.sender = {}
stream_checker.textfuncs = {
	['%[ID%]Имя  {C0C0C0}Ранг%[Номер%]  {6495ED}%[AFK секунд%]  {C0C0C0}Бан чата'] = function(message)
		stream_checker.members = {}
		return true
	end,
	['%[(%d+)%] (.+)  {C0C0C0}.+ %[.+%](.+)'] = function(message)
		local id, name, rank, afk = string.match(message, '%[(%d+)%] (.+) {C0C0C0}(.+ %[.+%])(.+)')
        local result, ped = sampGetCharHandleBySampPlayerId(id)
        if not result and tonumber(id) ~= getLocalPlayerId() then
            name = name:gsub("{......}", "")
            stream_checker.members[name] = { id = id, rank = rank }
        end
		return true
	end,
	['Всего онлайн: %d+'] = function(message)
        local sender = {}
        if config.data.stream_checker_name then
            for name, data in pairs(stream_checker.members) do
                name = name:gsub(" ", "")
                sender[#sender+1] = string.format("/rb %s[%s] - %s", name, data.id, data.rank:gsub(" %[", "["))
            end
        else
            local ids = ""
            for name, data in pairs(stream_checker.members) do
                ids = ids..data.id.." "
                if #ids > 40 then
                    sender[#sender+1] = string.format("/rb %s", ids)
                    ids = ""
                end
            end
            if #ids > 0 then
                sender[#sender+1] = string.format("/rb %s", ids)
            end
        end
        if #sender > 0 then
            sender[#sender+1] = string.format("/rb Список отсутствующих")
        end
        stream_checker.sender = sender
		return true
	end,
}
stream_checker.onServerMessage = function(color, message)
    if os.time() - stream_checker.hide < 3 then
        message = remove_ms(message)
        if message == " " or message == "===========================================" then
            return false
        end
        for k,v in pairs(stream_checker.textfuncs) do
            if message:find(k) then
                if v(message) then
                    return false
                end
            end
        end
    end
end
stream_checker.onSendCommand = function(cmd)
    if cmd == string.format("/%s", config.data.stream_checker) then
        stream_checker.hide = os.time()
        sampSendChat("/members")
        return false
    end
end
stream_checker.loop = function()
    while true do
        wait(0)
        if #stream_checker.sender > 0 then
            printStringNow("~Y~PRESS 'L' STOP~N~"..#stream_checker.sender, 1)
            if isKeyCanBePressed() and wasKeyPressed(76) then -->> 76 VK_L
                stream_checker.sender = {}
                msg.add("Отправка остановлена.")
            end
            if antiflood.get() > 700 then
                sampSendChat(stream_checker.sender[1])
                table.remove(stream_checker.sender, 1)
            end
        end
    end
end

-->> CLISTOFF
clistoff = {}
clistoff.onServerMessage = function(color, message)
    if message == " (( Чтобы посмотреть правила проведения войны за бизнес введите /mrules ))" then
        clistoff.war = true
    end
    if message == " (( /captstats - подробная статистика ))" then
        clistoff.wait = os.time()
        clistoff.war = false
        clistoff.start = true
    end
    if message == " Нельзя использовать во время войны" then
        clistoff.war = true
    end
end
clistoff.loop = function()
    clistoff.war = false
    clistoff.start = true
    clistoff.wait = 0
    while true do
        wait(0)
        if not clistoff.war and clistoff.start and os.time() - clistoff.wait > 3 then
            local id = getLocalPlayerId()
            local color = sampGetPlayerColor(id)
            if color ~= 16777215 and config.data.clistoff then
                antiflood.add("/clist 0")
            end
            clistoff.start = false
            clistoff.wait = os.time()
        end
    end
end
clistoff.spawn = function()
    clistoff.wait = os.time()
    clistoff.war = false
    clistoff.start = true
end

-->> ARMOFF
armoff = {}
armoff.onServerMessage = function(color, message)
    if message:find("Война за бизнес %{6AB1FF%}.+ %{FFFFFF%}пройдет в %{6AB1FF%}.+ %{FFFFFF%}| ID: %{6AB1FF%}(%d+)") then
        armoff.id = tonumber(message:match("Война за бизнес %{6AB1FF%}.+ %{FFFFFF%}пройдет в %{6AB1FF%}.+ %{FFFFFF%}| ID: %{6AB1FF%}(%d+)"))
        armoff.time = os.time()
    end
end
armoff.loop = function()
    armoff.id = -1
    armoff.time = 0
    while true do
        wait(0)
        for a = 0, 2304 do
            if sampTextdrawIsExists(a) then
                local x, y = sampTextdrawGetPos(a)
                if math.ceil(x) == 87 and math.ceil(y) == 244 then
                    sampTextdrawGetString()
                    local text = sampTextdrawGetString(a)
                    if text:find("ID:_(%d+)") then
                        armoff.id = tonumber(text:match("ID:_(%d+)"))
                        armoff.time = os.time()
                    end
                end
            end
        end
        if os.time() - armoff.time < 3 and #config.data.armoff > 0 then
            if armoff.check() then
                local arm = getCharArmour(PLAYER_PED)
                if arm > 0 and (armoff.antiflood == nil or os.time() - armoff.antiflood > 3) then
                    armoff.antiflood = os.time()
                    antiflood.add("/armoff")
                end
            end
        end
    end
end
armoff.check = function()
    local result = false
    if os.time() - armoff.time < 3 then
        for i = 1, #config.data.armoff do
            if config.data.armoff[i] == armoff.id then
                result = true
            end
        end
    end
    return result
end

-->> HEALME
healme = {}
healme.old_interior = -1
healme.sended = 0
healme.onServerMessage = function(color, message)
    if message == " Вы должны быть на своей базе или дома" or message == " В этом месте нет аптечки" then
        if os.time() - healme.sended < 5 then
            return false
        end
    end
end

healme.onSetPlayerPos = function(position)
    local coords = {
        { 246.2885, -0.1631, 1501.0837 },
        { -189.5952, -69.3178, 1497.3289 },
        { 1389.1643, -22.6256, 1000.9240 }
    }
    local result = false
    for k, v in pairs(coords) do
        local distance = getDistanceBetweenCoords3d(position.x, position.y, position.z, v[1], v[2], v[3])
        if distance <= 5 then
            result = true
        end
    end
    if result and config.data.healme then
        healme.start = true
    end
end
healme.onSendPickedUpPickup = function(id)
    local X, Y, Z = getCharCoordinates(PLAYER_PED)
    local coords = {
        { 1396.63, -17.18, 1000.92 }, -- LCN
        { 1371.64, -30.00, 1004.59 }, -- LCN
        { 1455.21, 749.96, 11.02 }, -- LCN
        { 938.19, 1732.91, 8.85 }, -- RM
        { 1457.42, 2773.18, 10.82 }, -- Yaki
        { 251.82, -12.46, 1501.00 }, -- Yaki
    }
    local result = false
    for k, v in pairs(coords) do
        local distance = getDistanceBetweenCoords3d(X, Y, Z, v[1], v[2], v[3])
        if distance <= 5 then
            result = true
        end
    end
    if result and config.data.healme then
        healme.start = true
    end
end
healme.start = false
healme.loop = function()
    while true do
        wait(0)
        if config.data.healme and healme.start then
            local health = getCharHealth(PLAYER_PED)
            local hp = math.ceil((100 - health) / 25)
            if hp > 0 then
                for i = 1, hp do
                    repeat
                        wait(0)
                    until antiflood.get() > 250
                    sampSendChat("/healme")
                    healme.sended = os.time()
                end
            end
            healme.start = false
        end
    end
end


-->> MHCARS
mhcars = {}
mhcars.time = 0
mhcars.onServerMessage = function(color, message)
    if message == " Вы не являетесь лидером/замом мафии" or
       message == " Ожидайте принятия задания" or
       message == " Задание уже начато" or 
       message:find("Перегон был инициирован мафией ") then
        mhcars.time = os.time() + 1800
    end
    if message == " Задание по перегону машин завершено" then
        mhcars.time = 0
    end
    if message:find("^ Задание будет доступно через: ") then
        local p1, p2, p3 = string.match(message, "Задание будет доступно через: (%d+):(%d+):(%d+)")
        if(p3 == nil)then
            p1, p2 = string.match(message, "Задание будет доступно через: (%d+):(%d+)")
        end
        if(p1 ~= nil and p2 ~= nil)then
            local mhTimer = 0
            if(p3 ~= nil)then
                mhTimer = tonumber(p1) * 3600
                mhTimer = mhTimer + (tonumber(p2) * 60)
                mhTimer = mhTimer + tonumber(p3)
            else
                mhTimer = mhTimer + (tonumber(p1) * 60)
                mhTimer = mhTimer + tonumber(p2)
            end
            mhcars.time = os.time() + mhTimer - config.data.mhcars.offset_wait
            request.send[#request.send + 1] = {
                key = "mhcars",
                second = mhTimer
            }
            request.wait = 0
        end
    end --> by Richard_Holmes
end
mhcars.loop = function()
    while true do
        wait(0)
        if sampIsLocalPlayerSpawned() and isPlayerInMafia() and config.data.stats.rank >= 9 then
            if mhcars.time == 0 then
                if mhcars.antiflood == nil or os.time() - mhcars.antiflood > 1 then
                    mhcars.antiflood = os.time()
                    antiflood.add("/mhcars "..config.data.mhcars.gang)
                end
            end
            if mhcars.time ~= 0 and os.time() > mhcars.time then
                if antiflood.get() > config.data.mhcars.wait then
                    sampSendChat("/mhcars "..config.data.mhcars.gang)
                end
            end
        end
    end
end

-->> MAFIAWAR
mafiawar = {}
mafiawar.id = -1
mafiawar.biz = false
mafiawar.time = 0
mafiawar.onServerMessage = function(color, message)
    if message:find("^ Начать войну можно не раньше (%d+):00$") then
        local hour = message:match("^ Начать войну можно не раньше (%d+):00$")
        mafiawar.set_time(hour)
    end
    if message:find("^ Начать войну с этой мафией можно не раньше (%d+):00$") then
        local hour = message:match("^ Начать войну с этой мафией можно не раньше (%d+):00$")
        mafiawar.set_time(hour)
    end
    if message == " Вы далеко от бизнеса" then
        if mafiawar.biz then
            mafiawar.biz = false
            mafiawar.time = 0
            msg.add("Если не каптит - нужно отойти от 3D текста бизнеса и подойти снова")
        end
    end
    if message:find("^ Война за бизнес %{6AB1FF%}.+ %{FFFFFF%}пройдет в %{6AB1FF%}.+ %{FFFFFF%}| ID: {6AB1FF}%d+$") or
       message == " Ваша мафия уже участвует в войне" or
       message == " Эта мафия уже начала войну за бизнес" or
       message == " Этот бизнес под контролем вашей мафии" or
       message:find("^ Начать войну за этот бизнес можно не раньше %d+:%d+$") or
       message == " Ваша мафия временно не может участвовать в войне" then
        if mafiawar.biz then
            mafiawar.biz = false
            mafiawar.time = 0
        end
    end
end
mafiawar.set_time = function(hour)
    local time = os.time()
    if tonumber(hour) < tonumber(os.date("%H")) then
        time = time + 10000
    end
    datetime = {
        year = tonumber(os.date("%Y", time)),
        month = tonumber(os.date("%m", time)),
        day = tonumber(os.date("%d", time)),
        hour = tonumber(hour),
        min = 0,
        sec = 0
    }
    mafiawar.time = os.time(datetime)
end
mafiawar.onCreate3DText = function(id, color, position, distance, testLOS, attachedPlayerId, attachedVehicleId, text)

    -- msg.add(string.format("%d", color))
    -- msg.add(string.format("%s", text))
    if color == 10289407 and text:find("Владелец") then
        mafiawar.id = id
        mafiawar.biz = true
    end
    if color == -356056833 and text:find("Продается") then
        mafiawar.id = id
        mafiawar.biz = true
    end
end
mafiawar.onRemove3DTextLabel = function(id)
    if mafiawar.id == id then
        mafiawar.id = -1
        mafiawar.biz = false
    end
end
mafiawar.loop = function()
    while true do
        wait(0)
        if sampIsLocalPlayerSpawned() and isPlayerInMafia() and config.data.stats.rank >= 6 then
            if config.data.mafiawar.auto and mafiawar.biz then
                if mafiawar.time == 0 then
                    if mafiawar.antiflood == nil or os.time() - mafiawar.antiflood > 1 then
                        mafiawar.antiflood = os.time()
                        antiflood.send[#antiflood.send+1] = "/mafiawar "..config.data.mafiawar.id
                    end
                end
                if mafiawar.time ~= 0 and os.time() >= mafiawar.time then
                    if antiflood.get() > config.data.mafiawar.wait then
                        sampSendChat("/mafiawar "..config.data.mafiawar.id)
                    end
                end
            end
        end
    end
end

-->> CHECK STATS
function isPlayerInMafia()
    if config.data.stats.frac == "LCN" or config.data.stats.frac == "Yakuza" or config.data.stats.frac == "Russian Mafia" then
        return true
    end
end

-->> GET GUNS
get_guns = {}
get_guns.warehouse = false
get_guns.isCanOpen = false
get_guns.onServerMessage = function(color, message)
    if message == "{FFFFFF} Вы можете использовать {00AB06}/getgun [ID игрока]{FFFFFF}, чтобы выдать оружие другим членам организации" then
        if get_guns.getgun then
            return false
        end
    end
    if message == " Вы не на складе оружия своей организации / у вас нет доступа!" or message == " Склад закрыт" then
        if get_guns.getgun then
            get_guns.getgun = false
        end
    end
    if message:find("^ Склад .+ %{C42100%}закрыт") or message == " Склад закрыт" then
        get_guns.warehouse = false
        if not get_guns.check_warehouse then
            get_guns.check_warehouse = true
            get_guns.check_warehouse_time = os.time()
            return false
        end
    end
    if message:find("^ Склад .+ %{00AB06%}открыт") or message == " Склад открыт" then
        get_guns.warehouse = true
        if not get_guns.check_warehouse then
            get_guns.check_warehouse = true
            get_guns.check_warehouse_time = os.time()
            return false
        end
    end
    if message == " Вам недоступна эта функция" then
        if not get_guns.check_warehouse then
            get_guns.check_warehouse = true
            get_guns.check_warehouse_time = os.time()
            return false
        end
    end
    if message:find("^ %d+/%d+ Матов | %d+/%d+ Аптечек") and os.time() - get_guns.check_warehouse_time < 2 then
        return false
    end
    if message:find("^ .+ открыл%(а%) склад с оружием$") then
        get_guns.warehouse = true
        if not message:find(getLocalPlayerNickname()) then
            get_guns.warelock_send = {}
            if config.data.get_guns.auto_get_guns and get_guns.enter_textdraw and isPlayerInWarehouse() then
                get_guns.start_get()
            end
        end
    end
    if message:find("^ .+ закрыл%(а%) склад с оружием$") then
        get_guns.warehouse = false
        if not message:find(getLocalPlayerNickname()) then
            get_guns.warelock_send = {}
        end
    end
    if message == " Броня уже 100%" and get_guns.getgun then
        antiflood.send[#antiflood.send+1] = "/getgun"
    end
end
get_guns.enter_textdrawId = -1
get_guns.enter_textdraw = false
get_guns.onShowTextDraw = function(id, textdraw)
    if textdraw.text:find("VEHICLE_ENTER_EXIT") then
        get_guns.enter_textdrawId = id
        get_guns.enter_textdraw = true
    end
end
get_guns.onTextDrawHide = function(id)
    if id == get_guns.enter_textdrawId then
        get_guns.enter_textdrawId = -1
        get_guns.enter_textdraw = false
    end
end
get_guns.onShowDialog = function(id, style, title, button1, button2, text)
    if title == "Статистика персонажа" then
        local frac, rank = text:match("Организация\t(.+).Ранг\t.+%[(.+)%]")
        if frac == nil then
            frac, rank = text:match("Организация\t(.+).Ранг\t(.+).Работа")
        end
        if rank ~= nil then
            rank = rank:gsub("Нет", 0)
            rank = rank:gsub("лидер", 10)
            rank = tonumber(rank)
            config.data.stats.rank = rank
            config.data.stats.frac = frac
            config.save(config.data)
            if not isPlayerInMafia() then
                lua_thread.create(function()
                    wait(3000)
                    thisScript():unload()
                end)
            end
        end
        if not get_guns.check_stats then
            get_guns.check_stats = true
            get_guns.antiflood = os.time() - 28
            return false
        end
    end
    if title == "Склад оружия" then
        if get_guns.getgun then
            if #get_guns.list > 0 then
                sampSendDialogResponse(id,1,get_guns.list[1],"")
                table.remove(get_guns.list, 1)
            else
                get_guns.getgun = false
                if get_guns.closed and config.data.stats.rank >= 8 and get_guns.warehouse then
                    antiflood.send[#antiflood.send+1] = "/warelock"
                end
            end
            return false
        end
    end
end
get_guns.weapon = {} -- >> onSendPacket
get_guns.onResetPlayerWeapons = function()
    get_guns.weapon = {}
end
get_guns.loop = function()
    get_guns.antiflood = 0
    get_guns.check_stats = false
    get_guns.check_warehouse = false
    get_guns.check_warehouse_time = 0
    get_guns.warehouse = false
    get_guns.getgun = false
    get_guns.closed = false
    get_guns.list = {}
    get_guns.messages = {}
    get_guns.warelock_send = {}
    while true do
        wait(0)
        if not get_guns.check_stats then
            if sampIsLocalPlayerSpawned() and os.time() - get_guns.antiflood > 30 then
                get_guns.antiflood = os.time()
                antiflood.send[#antiflood.send+1] = "/stats"
            end
        elseif not get_guns.check_warehouse then
            if sampIsLocalPlayerSpawned() and isPlayerInMafia() and os.time() - get_guns.antiflood > 30 then
                get_guns.antiflood = os.time()
                antiflood.send[#antiflood.send+1] = "/warehouse"
            end
        end
        if isPlayerInMafia() then
            if get_guns.enter_textdraw and isPlayerInWarehouse() and isKeyCanBePressed() and isKeysPressed(config.data.get_guns.key) and not get_guns.getgun then
                if not get_guns.warehouse and config.data.stats.rank < 8 then
                    request.warelock = true
                    request.wait = 0
                    msg.add("Отправлен запрос")
                else
                    get_guns.start_get()
                end
            else
                if isKeysPressed(config.data.get_guns.key) and get_guns.getgun then
                    msg.add("Выполняется взятие ганов")
                end
            end
            if #get_guns.warelock_send > 0 and antiflood.get() > 700 then
                if get_guns.warelock_send[1][1] < os.time() then
                    if get_guns.warelock_send[1][2] == get_guns.warehouse then
                        antiflood.send[#antiflood.send+1] = "/warelock"
                    end
                    table.remove(get_guns.warelock_send, 1)
                end
            end
        end
    end
end
get_guns.start_get = function()
    get_guns.list = {}
    for i = 1, #config.data.get_guns.list do
        if config.data.get_guns.list[i][2] > 0 then
            if get_guns.weapon[config.data.get_guns.list[i][3]] == nil or get_guns.weapon[config.data.get_guns.list[i][3]] < (config.data.get_guns.list[i][4] * config.data.get_guns.list[i][2]) then
                for n = 1, config.data.get_guns.list[i][2] do
                    if i ~= 7 or (i == 7 and not armoff.check()) then
                        get_guns.list[#get_guns.list+1] = i - 1
                    end
                end
            end
        end
    end
    if #get_guns.list > 0 then
        get_guns.getgun = true
        get_guns.closed = false
        if not get_guns.warehouse and config.data.stats.rank >= 8 then
            antiflood.send[#antiflood.send+1] = "/warelock"
            get_guns.closed = true
        end
        antiflood.send[#antiflood.send+1] = "/getgun"
    else
        msg.add("У Вас достаточно оружия!")
    end
end

-->> Обновление листа таба
function updateScoresAndPing()
    while true do
        wait(1000)
        local bs = raknetNewBitStream()
        raknetSendRpc(155,bs)
        raknetDeleteBitStream(bs)
    end
end

-->> INVITE HELPER
invite_helper = {}
invite_helper.data = {}
invite_helper.onServerMessage = function(color, message)
    if message:find("^ Вы приняли .+ в ") then
        local name = message:match("^ Вы приняли (.+) в ")
        if invite_helper.data[name] ~= nil then
            antiflood.send[#antiflood.send+1] = invite_helper.data[name]
            invite_helper.data[name] = nil
        else
            if config.data.invite_helper.auto_rank then
                local result, id = getPlayerIdByPlayerName(name)
                if result then
                    antiflood.send[#antiflood.send+1] = "/giverank "..id.." "..config.data.invite_helper.rank
                end
            end
        end
        if #config.data.invite_helper.message > 0 then
            name = name:gsub("_", " ")
            antiflood.send[#antiflood.send+1] = string.format("/r %s", config.data.invite_helper.message:gsub("{name}", name))
        end
    end
end
invite_helper.onSendCommand = function(cmd)
    if cmd:find("%/invite %d+") then
        local id, rank = cmd:match("%/invite (%d+)"), config.data.invite_helper.rank
        if cmd:find("%/invite (%d+) (%d+)") then
            id, rank = cmd:match("%/invite (%d+) (%d+)")
        end
        id = tonumber(id)
        local result, name = getNickNameByPlayerId(id)
        if result then
            if ScoresAndPings[id] ~= nil then
                local score = ScoresAndPings[id].score
                if score >= config.data.invite_helper.lvl then
                    invite_helper.data[name] = "/giverank "..id.." "..rank
                else
                    msg.add(string.format("У игрока %s[%d] всего %d уровень. Нужен %d уровень!", name, id, score, config.data.invite_helper.lvl))
                    return false
                end
            end
        end
    end
end
invite_helper.loop = function()
    while true do
        wait(0)
        local result, ped = getCharPlayerIsTargeting(PLAYER_HANDLE)
        if result then
            local result, id = sampGetPlayerIdByCharHandle(ped)
            if result and isKeysPressed(config.data.invite_helper.key) then
                antiflood.send[#antiflood.send+1] = "/invite "..id
            end
        end
    end
end

-->> ANTIFLOOD
antiflood = {}
antiflood.clock = 0
antiflood.set = function()
    antiflood.clock = os.clock() * 1000
end
antiflood.get = function()
    return (os.clock() * 1000 - antiflood.clock)
end
antiflood.send = {}
antiflood.loop = function()
    while true do
        wait(0)
        if antiflood.get() > 1300 then
            if #antiflood.send > 0 then
                sampSendChat(antiflood.send[1])
                table.remove(antiflood.send, 1)
                antiflood.set()
            end
        end
    end
end
antiflood.add = function(text)
    local result = true
    for i = 1, #antiflood.send do
        if antiflood.send[i] == text then
            result = false
        end
    end
    if result then
        antiflood.send[#antiflood.send+1] = text
    end
end

-->> MAFIA CHECKER
mafia_checker = {}
mafia_checker.loop = function()
    mafia_checker.skin = {
        [118] = 2868839942,
        [117] = 2868839942,
        [169] = 2868839942,
        [120] = 2868839942,
        [186] = 2868839942,
        [123] = 2868839942,
        [272] = 2864232118,
        [112] = 2864232118,
        [125] = 2864232118,
        [214] = 2864232118,
        [111] = 2864232118,
        [126] = 2864232118,
        [124] = 2868164608,
        [223] = 2868164608,
        [113] = 2868164608,
        [91] = 2868164608,
        [127] = 2868164608
    }
    while true do
        wait(0)
        if config.data.mafia_checker.main then
            if mafia_checker.setpos then
                sampSetCursorMode(3)
                local x, y = getCursorPos()
                config.data.mafia_checker.x = x
                config.data.mafia_checker.y = y
                if isKeyJustPressed(1) then
                    sampSetCursorMode(0)
                    config.save(config.data)
                    mafia_checker.setpos = false
                end
            end
            local players = {
                [2868164608] = { "lcn", 0, 0 },
                [2868839942] = { "yakuza", 0, 0 },
                [2864232118] = { "rm", 0, 0 },
            }
            for i = 0, sampGetMaxPlayerId(false) do
                if sampIsPlayerConnected(i) then
                    local color = sampGetPlayerColor(i)
                    if players[color] ~= nil then
                        players[color][2] = players[color][2] + 1
                    end
                    local result, handle = sampGetCharHandleBySampPlayerId(i)
                    if result then
                        local model = getCharModel(handle)
                        if mafia_checker.skin[model] ~= nil then
                            players[mafia_checker.skin[model]][3] = players[mafia_checker.skin[model]][3] + 1
                        end
                    end
                end
            end
            local text = string.format("{ba9307}LCN:{ffffff} %d (%d)\n{b81a24}Yakuza:{ffffff} %d (%d)\n{999696}RM:{ffffff} %d (%d)\n", players[2868164608][2], players[2868164608][3], players[2868839942][2], players[2868839942][3], players[2864232118][2], players[2864232118][3])
            renderFontDrawText(font,text,config.data.mafia_checker.x,config.data.mafia_checker.y,-1)
        end
    end
end

-->> MSK TIME
msk_time = {}
msk_time.update = 0
msk_time.time = 0
msk_time.get = function()
    if msk_time.update == 0 then
        return os.time()
    end
    return msk_time.time + (os.time() - msk_time.update)
end

-->> REQUEST
request = {}
request.chat = {}
request.send = {}
request.base = {}
request.warelock = false
request.loop = function()
    request.wait = 0
    while true do
        wait(0)
        if isPlayerInMafia() and os.time() - request.wait >= 5 then
            --> Может ли игрок открыть склад?
            local can_warelock = false
            if config.data.stats.rank >= 8 and config.data.get_guns.warelock_auto then
                can_warelock = true
            end
            request.wait = os.time()
            local request_table = {
                sender = getLocalPlayerNickname(),
                server = getServerAddress(),
                room = config.data.room,
                send = request.send,
                can_warelock = can_warelock,
                request_warelock = request.warelock,
                rand = os.clock(),
                frac = config.data.stats.frac
            }
            request.send = {}
            request.warelock = false
            local url = string.format("http://mafia.deadpoo.net/%s", urlencode(encodeJson(request_table)))
            local result, text = pcall(openURL, url, os.tmpname(), true)
            if result then
                local result = pcall(request.handler, text)
                if not result then
                    addChatMessage(text)
                    addChatMessage("Сервер 'mafia-tools' не отвечает!")
                    break
                end
            end
        end
    end
end
request.handler = function(text)
    local info = decodeJson(text)
    if info["time"] ~= nil then
        msk_time.update = os.time()
        msk_time.time = info["time"]
    end
    if info["result"] == "ok" then
        menu.data = info["data"]
        local new_data = {
            ls = { time = 0, text = "00:00:00" },
            sf = { time = 0, text = "00:00:00" },
            lv = { time = 0, text = "00:00:00" },
            mhcars = { time = 0, text = "00:00:00" },
            ffixcar = { time = 0, text = "00:00:00" },
        }
        for sender, sender_data in pairs(info["data"]) do
            if isPlayerInList(sender) then
                for key, v in pairs(sender_data) do
                    if new_data[key] ~= nil then
                        if new_data[key]["time"] < v["time"] then
                            new_data[key]["time"] = v["time"]
                            new_data[key]["text"] = v["text"]
                        end
                    end
                end
            end
        end
        ammo_timer.data = new_data
        local text = ""
        for i = 1, #info["ffixcar_log"] do
            local data = info["ffixcar_log"][i]
            if isPlayerInList(data["sender"]) then
                text = string.format("%s[%s] %s\n", text, os.date("%X", data["time"]), data["text"])
            end
        end
        menu.ffixcar_log = text
        for sender, sender_data in pairs(info["chat"]) do
            if isPlayerInList(sender) then
                local key = string.format("%d%s", sender_data.time, sender_data.text)
                if request.chat[key] == nil then
                    request.chat[key] = true
                    local dev = ""
                    if sender == "Serhiy_Rubin" or sender == "Rafael_Moreno" then
                        dev = "[Разработчик] "
                    end
                    if msk_time.get() - sender_data.time < 15 then
                        local text = string.format("%s%s: %s", dev, sender, sender_data.text)
                        addChatMessage(text)
                    end
                end
            end
        end

        --> warelock
        if info["response_warelock"] ~= nil and info["response_warelock"] ~= "" then
            addChatMessage(info["response_warelock"])
        end
        --> can_warelock
        if info["can_warelock"] ~= nil and info["can_warelock"] then
            get_guns.warelock_send = {
                { os.time(), false },
                { os.time() + config.data.get_guns.warelock_time, true }
            }
        end

    end
    return true
end
-->> AMMO TIMER
ammo_timer = {}
ammo_timer.last_ammo = ""
ammo_timer.onServerMessage = function(color, message)
    if message:find("^ .+ ограбил магазин оружия. На склад добавлено %d+ материалов$") then
        if ammo_timer.last_ammo ~= "" then
            request.send[#request.send + 1] = {
                key = ammo_timer.last_ammo,
                text = "last"
            }
            request.wait = 0
        end
    end
    if message:find("^ Следующее ограбление будет доступно в (%d+:%d+:%d+)") then
        if ammo_timer.last_ammo ~= "" then
            local text = message:match("^ Следующее ограбление будет доступно в (%d+:%d+:%d+)")
            request.send[#request.send + 1] = {
                key = ammo_timer.last_ammo,
                text = text
            }
            request.wait = 0
            if config.data.chat_timing.auto then
                antiflood.send[#antiflood.send + 1] = "/r "..ammo_timer.last_ammo:upper()..": "..text
            end
        end
    end
    if message:find(".+ заказал спавн транспорта через %d+ секунд%. С банка фракции снято %d+ вирт$") then
        request.send[#request.send + 1] = {
            key = "ffixcar",
            text = message:match(" (%g+_%g+ заказал спавн транспорта через %d+ секунд%. С банка фракции снято %d+ вирт)$")
        }
        request.wait = 0
    end
end
ammo_timer.onSendPickedUpPickup = function(id)
    local X, Y, Z = getCharCoordinates(PLAYER_PED)
    local ammo = {
        ["ls"] = {x = 1366.6401367188, y = -1279.4899902344, z = 13.546875},
        ["sf"] = {x = -2626.4050292969, y = 210.6088104248, z = 4.6033186912537},
        ["lv"] = {x = 2158.3286132813, y = 943.17541503906, z = 10.371940612793}
    }
    local ignore_coord = {
        { 300.95, -74.43, 1001.52 },
        { 301.60, -77.81, 1001.52 }
    }
    local ignore = false
    for k,v in pairs(ignore_coord) do
        local distance = getDistanceBetweenCoords3d(X, Y, Z, v[1], v[2], v[3])
        if distance <= 5 then
            ignore = true
        end
    end
    if not ignore then
        ammo_timer.last_ammo = ""
        for k, v in pairs(ammo) do
            local distance = getDistanceBetweenCoords3d(X, Y, Z, v.x, v.y, v.z)
            if distance <= 5 then
                ammo_timer.last_ammo = k
            end
        end --> by Benya
    end
end
ammo_timer.data = {
    ls = { time = 0, text = "00:00:00" },
    sf = { time = 0, text = "00:00:00" },
    lv = { time = 0, text = "00:00:00" },
    mhcars = { time = 0, text = "00:00:00" },
    ffixcar = { time = 0, text = "00:00:00" },
}
ammo_timer.loop = function()
    font = renderCreateFont(config.data.font.name,config.data.font.size,config.data.font.flag)
    local getText = function(key, oneline)
        if config.data.timer_hud[key] ~= nil and not config.data.timer_hud[key] then
            return ""
        end
        if ammo_timer.data[key]["time"] == 0 then
            if oneline == nil then
                return string.format("{%s}%s:{%s} %s\n", config.data.font.color1, key:upper(), config.data.font.color2, ammo_timer.data[key]["text"])
            else
                return string.format("%s: %s", key:upper(), ammo_timer.data[key]["text"])
            end
        else
            local min = math.floor((msk_time.get() - ammo_timer.data[key]["time"]) / 60)
            if oneline == nil then
                return string.format("{%s}%s:{%s} %s (%d min)\n", config.data.font.color1, key:upper(), config.data.font.color2, ammo_timer.data[key]["text"], min)
            else
                return string.format("%s: %s (%d min)", key:upper(), ammo_timer.data[key]["text"], min)
            end
        end
    end
    while true do
        wait(0)
        if isKeyCanBePressed() and isKeysPressed(config.data.chat_timing.key) then
            local text = string.format("/r %s  %s  %s", getText("ls", 1), getText("sf", 1), getText("lv", 1))
            antiflood.send[#antiflood.send+1] = text
        end
        if config.data.timer_hud.main then
            if ammo_timer.setpos then
                sampSetCursorMode(3)
                local x, y = getCursorPos()
                config.data.timer_hud.x = x
                config.data.timer_hud.y = y
                if isKeyJustPressed(1) then
                    sampSetCursorMode(0)
                    config.save(config.data)
                    ammo_timer.setpos = false
                end
            end
            local text = string.format("%s%s%s%s%s", getText("ls"), getText("sf"), getText("lv"), getText("mhcars"), getText("ffixcar"))
            renderFontDrawText(font,text,config.data.timer_hud.x,config.data.timer_hud.y,-1)
        end
    end
end

-->> 2 MIN TIMER
timer_2min = {}
timer_2min.onServerMessage = function(color, message)
    if message:find("Война за бизнес .+ продлена на 2 минуты") then
        local now = os.time() - config.data.time_2min
        if now < 300 and (os.time() - config.data.time_2min) > 120 then
            addChatMessage("2 мин длилось на "..((os.time() - config.data.time_2min) - 120).." секунд больше")
        end
        config.data.time_2min = os.time()
        config.save(config.data)
    end
end
timer_2min.loop = function()
    while true do
        wait(0)
        for a = 0, 2304 do
            if sampTextdrawIsExists(a) then
                local x, y = sampTextdrawGetPos(a)
                if math.ceil(x) == 87 and math.ceil(y) == 256 then
                    local time = 120 - (os.time() - config.data.time_2min)
                    local text = string.format("%02d:%02d", math.floor(time / 60), time % 60)
                    if time < 120 and time >= 0 and sampTextdrawGetString(a) ~= text then
                        sampTextdrawSetString(a,text)
                    end
                end
            end
        end
    end
end

-->> CONFIG
config = {}
config.data = {}
local x1, y1 = convertGameScreenCoordsToWindowScreenCoords(146.66, 352.17)
local x2, y2 = convertGameScreenCoordsToWindowScreenCoords(146.66, 394.48)
config.default = {
    font = {
        name = "Segoe UI",
        size = 10,
        flag = 13,
        color1 = "fffd8f",
        color2 = "ffffff"
    },
    time_2min = 0,
    room = "all",
    list = {}, -->> Список
    list_block = true, -->> Использовать как Черный или Белый список
    timer_hud = {
        main = true,
        mhcars = false,
        ffixcar = false,
        x = x1,
        y = y1
    },
    mafia_checker = {
        main = true,
        x = x2,
        y = y2
    },
    invite_helper = {
        lvl = 5,
        auto_rank = true,
        rank = 7,
        key = { "VK_I" },
        message = "Добро пожаловать, {name}!"
    },
    get_guns = {
        list = {
            { "Desert Eagle", 2, 2, 14 },
            { "Shotgun", 0, 3, 10 },
            { "SMG", 0, 4, 60 },
            { "AK47", 0, 5, 60 },
            { "M4A1", 1, 5, 100 },
            { "Rifle", 0, 6, 10 },
            { "Броня", 1, 777, 10 }
        },
        key = { "VK_G" },
        auto_get_guns = true,
        warelock_auto = true,
        warelock_time = 5
    },
    stats = {
        frac = "",
        rank = 0
    },
    armoff = { 0, 1, 4 },
    mafiawar = {
        auto = true,
        id = 0,
        wait = 600
    },
    chat_timing = {
        key = { "VK_MENU", "VK_H" },
        auto = true
    },
    mhcars = {
        auto = true,
        gang = "grove",
        wait = 200,
        offset_wait = 1
    },
    healme = true,
    clistoff = true,
    stream_checker = "progul",
    stream_checker_name = false,
}
config.directory = string.format("%s\\moonloader\\config\\%s\\", getGameDirectory(), thisScript().name)
config.init = function()
    if not doesDirectoryExist("moonloader\\config") then
        createDirectory("moonloader\\config")
    end
    if not doesDirectoryExist(config.directory) then
        createDirectory(config.directory)
    end
    config.address = string.format("%s\\%s-%s.json", config.directory, getSampRpServerName(), getLocalPlayerNickname())
    if not doesFileExist(config.address) then
        config.save(config.default)
    end
    config.read()
    for k,v in pairs(config.default) do
        if config.data[k] == nil then
            config.data[k] = v
        end
        if type(v) == "table" then
            for kk,vv in pairs(v) do
                if config.data[k][kk] == nil then
                    config.data[k][kk] = vv
                end
                if type(vv) ~= type(config.data[k][kk]) then
                    config.data[k][kk] = vv
                end
            end
        end
    end
    config.save(config.data)
end
config.save = function(data)
    local file, error = io.open(config.address, "w")
    if file == nil then
        addChatMessage(error)
    end
    file:write(encodeJson(data))
    file:flush()
    io.close(file)
end
config.read = function()
    local readJson = function()
        local file, error = io.open(config.address, "r")
        if file then
            config.data = decodeJson(file:read("*a"))
            io.close(file)
            if config.data == nil then
                addChatMessage("Ошибка чтения конфига! Сбрасываю конфиг!")
                config.save(config.default)
            end
        end
    end
    local result = pcall(readJson)
    if not result then
        addChatMessage("Ошибка чтения конфига! Сбрасываю конфиг!")
        config.save(config.default)
    end
    if config.data == nil then
        config.error = true
        addChatMessage("Ошибка чтения конфига! Пробую ещё раз прочесть")
        config.read()
    else
        if config.error then
            addChatMessage("Конфиг был успешно загружен!")
            config.error = false
        end
    end
end

-->> EVENTS
function processEvent(func, args)
    if args == nil then
      args = {}
    end
    local kk = table.pack(func(table.unpack(args)))
    if kk.n > 0 then
      return kk
    end
end -- by QRLK (edith.lua)
function sampev.onServerMessage(color, message)
    message = remove_ms(message)
    local res = processEvent(get_guns.onServerMessage, table.pack(color, message))
    if res then
        return table.unpack(res)
    end
    if os.time() - live < 3 then
        timer_2min.onServerMessage(color, message)
        ammo_timer.onServerMessage(color, message)
        invite_helper.onServerMessage(color, message)
        mafiawar.onServerMessage(color, message)
        mhcars.onServerMessage(color, message)
        armoff.onServerMessage(color, message)
        local res = processEvent(healme.onServerMessage, table.pack(color, message))
        if res then
            return table.unpack(res)
        end
    end
end
function sampev.onSendPickedUpPickup(id)
    ammo_timer.onSendPickedUpPickup(id)
    healme.onSendPickedUpPickup(id)
end
ScoresAndPings = {}
function sampev.onUpdateScoresAndPings(data)
    ScoresAndPings = data
end
function sampev.onSendCommand(cmd)
    antiflood.set()
    local res = processEvent(invite_helper.onSendCommand, table.pack(cmd))
    if res then
        return table.unpack(res)
    end
    local res = processEvent(stream_checker.onSendCommand, table.pack(cmd))
    if res then
        return table.unpack(res)
    end
end
function sampev.onSendChat(message)
    antiflood.set()
end
function sampev.onShowDialog(id, style, title, button1, button2, text)
    local res = processEvent(get_guns.onShowDialog, table.pack(id, style, title, button1, button2, text))
    if res then
        return table.unpack(res)
    end
end
function sampev.onShowTextDraw(id, data)
    get_guns.onShowTextDraw(id, data)
end
function sampev.onTextDrawHide(id)
    get_guns.onTextDrawHide(id)
end
function sampev.onCreate3DText(id, color, position, distance, testLOS, attachedPlayerId, attachedVehicleId, text)
    mafiawar.onCreate3DText(id, color, position, distance, testLOS, attachedPlayerId, attachedVehicleId, text)
end
function sampev.onRemove3DTextLabel(id)
    mafiawar.onRemove3DTextLabel(id)
end
function onSendPacket(id, bs)
    if id == 204 then
        raknetBitStreamIgnoreBits(bs,40)
        local count = raknetBitStreamGetNumberOfUnreadBits(bs) / 32
        for i = 1, count do
            local slot = raknetBitStreamReadInt8(bs)
            local weapon = raknetBitStreamReadInt8(bs)
            local ammo = raknetBitStreamReadInt16(bs)
            if get_guns.weapon ~= nil then
                get_guns.weapon[slot] = ammo
                --msg.add(string.format("slot %d = %d ammo", slot, ammo))
                if ammo == 0 then
                    table.remove(get_guns.weapon, slot)
                end
            end
        end
    end
end
function onReceiveRpc(id,bs)
    if id == 93 then
        local color = raknetBitStreamReadInt32(bs)
        local len = raknetBitStreamReadInt32(bs)
        local message = raknetBitStreamReadString(bs,len)
        local res = processEvent(stream_checker.onServerMessage, table.pack(color, AnsiToUtf8(message)))
        if res then
            return table.unpack(res)
        end
    end
end
function sampev.onSendSpawn()
    clistoff.spawn()
end
function sampev.onResetPlayerWeapons()
    get_guns.onResetPlayerWeapons()
end
function sampev.onSetPlayerPos(position)
    healme.onSetPlayerPos(position)
end
-->> NEW FUNCTION
function getLocalPlayerNickname()
    return sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))
end
function getLocalPlayerId()
    return select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))
end
function getServerAddress()
    local ip, port = sampGetCurrentServerAddress()
    return string.format("%s:%s", ip, port)
end
function getSampRpServerName()
    local result = ""
    local server = sampGetCurrentServerName():gsub("|", "")
    local server_find = { "02", "Two", "Revo", "Legacy", "Classic", "Renaissance" }
    for i = 1, #server_find do
        if server:find(server_find[i]) then
            result = server_find[i]
        end
    end
    return result
end
function convertTableToString(table)
    local result = ""
    for i = 1, #table do
        result = string.format("%s%s\n", result, table[i])
    end
    return result
end
function start_dialog(_menu, put) -- module by trefa & modify (put & list in [])
    function _dialog(_menu, id, outs, put)
        sampShowDialog(id, _menu.settings.title, tbl_split(_menu.settings.style, _menu, _menu.settings.forward ,_menu.settings.backwards ,_menu.settings.score), _menu.settings.btn1, (_menu.settings.btn2 ~= nil and _menu.settings.btn2 or _), _menu.settings.style)
        repeat
            wait(0)
            if put ~= nil and sampIsDialogActive() then
                sampSetCurrentDialogEditboxText(put)
                put = nil
            end
            local result, button, list, input = sampHasDialogRespond(id)
            if result then
                local out, outs = _menu[((_menu.settings.style == 0 or _menu.settings.style == 1 or _menu.settings.style == 3) and 1 or ((list + 1) > #_menu[1] and 2 or 1))][((_menu.settings.style == 0 or _menu.settings.style == 1 or _menu.settings.style == 3) and 1 or ((list + 1) > #_menu[1] and (list - #_menu[1]) + 1  or list + 1))].click(button, list, input, outs)
                if type(out) == "table" then
                    return _dialog(out, id - 1, outs, put)
                elseif type(out) == "boolean" then
                    if not out then
                        return out
                    end
                        return _dialog(_menu, id, outs, put)
                end
            end
        until result or menu.show[1]
    end

    function tbl_split(style, tbl, forward ,backwards ,score)
        if style == 2 or style == 4 or style == 5 then
            text = (style == 5 and tbl[1].text.."\n" or "")
            for i, val in ipairs(tbl[1]) do
                text = text..""..forward..""..(score and "["..(i-1).."] " or "")..""..val.title..""..backwards
            end
            if tbl[2] ~= nil then
                for _, val in ipairs(tbl[2]) do
                    text = text..""..forward..""..val.title..""..backwards
                end
            end
            return text
        end
        return tbl[1].text
    end

    return _dialog(_menu, 1337, outs, put)
end
function getNicknamesOnline()
    local result = {}
    for i = 0, sampGetMaxPlayerId(false) do
        if sampIsPlayerConnected(i) or select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)) == i then
            result[sampGetPlayerNickname(i)] = i
        end
    end
    return result
end
function urlencode(str)
    str = string.gsub (str, "([^0-9a-zA-Z !'()*._~-])", -- locale independent
    function (c) return string.format ("%%%02X", string.byte(c)) end)
    return str
end
function getNickNameByPlayerId(id)
    local result = false
    local nick = ""
    if sampIsPlayerConnected(id) then
        nick = sampGetPlayerNickname(id)
        result = true
    end
    return result, nick
end
function getPlayerIdByPlayerName(name)
    local result = false
    local id = -1
    for i = 0, sampGetMaxPlayerId(false) do
        if sampIsPlayerConnected(i) then
            if sampGetPlayerNickname(i) == name then
                result = true
                id = i
                break
            end
        end
    end
    return result, id
end
function isPlayerInList(sender)
    local result = false
    if config.data.list_block then
        if config.data.list[sender] == nil then
            result = true
        end
    else
        if config.data.list[sender] ~= nil then
            result = true
        end
    end
    return result
end
function isKeyCanBePressed()
    if sampIsDialogActive() or sampIsChatInputActive() or sampIsCursorActive() or isSampfuncsConsoleActive() then
        return false
    end
    return true
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
function sendRpcCommand(text)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt32(bs, #text)
    raknetBitStreamWriteString(bs,text)
    raknetSendRpc(50,bs)
    raknetDeleteBitStream(bs)
end
function convertKeysToText(arr)
    local text = ""
    for i = 1, #arr do
        text = string.format("%s%s%s", text, arr[i]:gsub("VK_", ""), (i == #arr and "" or " + "))
    end
    return text
end
function isKeysPressed(arr)
    local result = 0
    for i = 1, #arr do
        if i == #arr then
            if wasKeyPressed(vkeys[arr[i]]) then
                result = result + 1
            end
        else
            if isKeyDown(vkeys[arr[i]]) then
                result = result + 1
            end
        end
    end
    if result == #arr then
        return true
    end
end
function setKeys()
    wait(100)
    local key_combo = {}
    repeat
        wait(0)
        if not sampIsDialogActive() then
            sampShowDialog(222, "Смена активации", "Зажмите нужное сочетание клавиш и отпустите для сохранения!", "Выбрать", "Закрыть", 0)
        end
        local isPress = false
        for k, v in pairs(vkeys) do
            if isKeyDown(v) and k ~= "VK_ESCAPE" and k ~= "VK_RETURN" then
                local isKeyFind = false
                for i = 1, #key_combo do
                    if key_combo[i] == k then
                        isKeyFind = true
                    end
                end
                if not isKeyFind then
                    key_combo[#key_combo+1] = k
                end
                isPress = true
            end
        end
        printStringNow(convertKeysToText(key_combo), 1)
    until #key_combo > 0 and not isPress
    return key_combo
end
function isPlayerInWarehouse()
    local position = {
        { 1379.8171, -20.1072, 1000.9240 },
        { 254.3029, 10.9711, 1504.5144 },
        { -225.0700, -74.8219, 1497.3340 }
    }
    local result = false
    for i = 1, #position do
        local x, y, z = getCharCoordinates(PLAYER_PED)
        local dist = getDistanceBetweenCoords3d(x, y, z, position[i][1], position[i][2], position[i][3])
        if dist < 20.0 then
            result = true
        end
    end
    return result
end
function remove_ms(text)
    text = text:gsub("%[%d+ms%] ", "")
    text = text:gsub("%[%d+:%d+:%d+:%d+%] ", "")
    return text
end

-->> UPDATE MODULE
function openURL(url, fpath, message_off)
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
        if not message_off then
            addChatMessage("Не удалось скачать обновление по ссылке:")
            addChatMessage(url)
        end
    end

    return text
end

function addChatMessage(text)
    local tag = string.format("{667dff}[%s]{FFFFFF} ", thisScript().name)
    sampAddChatMessage(tag..text, 0xFFFFFFFF)
end

-->> Chat Message HOOK (Для addChatMessage вне хука samp events)
msg = {}
msg.list = {}
msg.add = function(arg)
    msg.list[#msg.list+1] = arg
end
msg.loop = function()
    if #msg.list > 0 then
        addChatMessage(msg.list[1])
        table.remove(msg.list, 1)
    end
end

script_update = {
    version_url = "http://git.deadpoo.net/rubin/mafia-tools/raw/branch/master/version",
    script_url = "http://git.deadpoo.net/rubin/mafia-tools/raw/branch/master/mafia-tools.lua",
    changelog_url = "http://git.deadpoo.net/rubin/mafia-tools/raw/branch/master/changelog",
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
utf8({ "sampHasDialogRespond" }, nil, "AnsiToUtf8")
utf8({ "sampev", "onServerMessage" }, "AnsiToUtf8", "Utf8ToAnsi")
utf8({ "sampev", "onShowDialog" }, "AnsiToUtf8", "Utf8ToAnsi")
utf8({ "sampev", "onSendCommand" }, "AnsiToUtf8", "Utf8ToAnsi")
utf8({ "sampev", "onCreate3DText" }, "AnsiToUtf8", "Utf8ToAnsi")