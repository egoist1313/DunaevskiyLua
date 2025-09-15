script_name('drugs-mats')
script_author("Serhiy_Rubin")
script_version("20.02.2023")
sampev, vkeys, inicfg = require 'lib.samp.events', require 'lib.vkeys', require 'inicfg'
local check_inventory, drugs_timer, not_drugs_timer, renderText, d = 1, 0, false, {}, {}
dlstatus = require("moonloader").download_status
local sleep = 0
local check_get_mats = true
local check_boostinfo = 0
local bonus_drugs = 1

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	while not isSampAvailable() do wait(100) end
    lua_thread.create(script_update.main)
	local result, PlayerId = sampGetPlayerIdByCharHandle(PLAYER_PED)
	my_name = sampGetPlayerNickname(PlayerId)
	local ip, port = sampGetCurrentServerAddress(  )
	inikeys = string.format('%s %s-%s', my_name, ip:gsub('%.', '-'), port)
	posX, posY = convertGameScreenCoordsToWindowScreenCoords(88.081993103027, 322.58331298828)
	ini = inicfg.load({
		render = {
			font = 'Segoe UI',
			size = 10,
			flag = 13,
			align = 2,
			x = posX,
			y = posY,
			height = 4
		},
		global = {
			cmd = 'us',
			key = 'VK_U'
		},
		[inikeys] = {
			hp = 160,
			hp_one_gram = 10,
			max_use_gram = 15,
			seconds = 60,
			run = true,
			drugs = 0,
			mats = 0,
			server_cmd = 'usedrugs',
			inventory = true,
			boostinfo = true
		},
		lines = {
			one = '{1a9614}drugs !a!n{dedede}mats !m',
			two = '{e81526}cooldown !s!n{dedede}mats !m'
		}
	})
	inicfg.save(ini)
	font = renderCreateFont(ini.render.font, ini.render.size, ini.render.flag)
	text_to_table()
	while true do
	wait(0)
		GetMats()
		doDialog()
		if ini[inikeys].run and not sampIsScoreboardOpen() and sampIsChatVisible() and not isKeyDown(116) and not isKeyDown(121) then
			second_timer = os.difftime(os.time(), drugs_timer)
			render_table = ( (second_timer <= ini[inikeys].seconds * bonus_drugs and second_timer > 0) and renderText[4] or renderText[3] )
			local Y, Height = ini.render.y, (renderGetFontDrawHeight(font) - (renderGetFontDrawHeight(font) / ini.render.height)  )
			for i = 1, #render_table do
				if render_table[i] ~= nil then
					string_gsub = render_table[i]:gsub("!a", ini[inikeys].drugs)
					string_gsub = string_gsub:gsub("!s", tostring(math.ceil(ini[inikeys].seconds * bonus_drugs - second_timer)))
					string_gsub = string_gsub:gsub("!m", tostring(ini[inikeys].mats))
					if ini.render.align == 1 then X = ini.render.x end
					if ini.render.align == 2 then X = ini.render.x - (renderGetFontDrawTextLength(font, string_gsub) / 2) end
					if ini.render.align == 3 then X = ini.render.x - renderGetFontDrawTextLength(font, string_gsub) end
					renderFontDrawText(font, string_gsub, X, Y, 0xFFFFFFFF)
					Y = Y + Height
				end
			end

			if isKeyJustPressed(vkeys[ini.global.key]) and not sampIsDialogActive() and not sampIsChatInputActive() and not sampIsCursorActive() then
				local gramm = math.ceil(((ini[inikeys].hp + 1) - getCharHealth(playerPed)) / ini[inikeys].hp_one_gram)
				if gramm > ini[inikeys].max_use_gram then gramm = ini[inikeys].max_use_gram end
				if second_timer <= math.floor(ini[inikeys].seconds * bonus_drugs) and second_timer > 0 then gramm = 1 end
				sampSendChat(string.format('/%s %d', ini[inikeys].server_cmd, gramm))
			end

			if pos then
				sampSetCursorMode(3)
				curX, curY = getCursorPos()
				ini.render.x = curX
				ini.render.y = curY
				if isKeyJustPressed(1) then
					sampSetCursorMode(0)
					pos = false
					inicfg.save(ini)
				end
			end
		end
	end
end

function text_to_table()
	renderText[3] = {}
	renderText[4] = {}
	for str in string.gmatch(ini.lines.one:gsub("!n", "\n"), '[^\n]+') do
		renderText[3][#renderText[3] + 1] = str
	end
	for str in string.gmatch(ini.lines.two:gsub("!n", "\n"), '[^\n]+') do
		renderText[4][#renderText[4] + 1] = str
	end
end

function ShowDialog(int, dtext, dinput, string_or_number, ini1, ini2)
	d[1], d[2], d[3], d[4], d[5], d[6] = int, dtext, dinput, string_or_number, ini1, ini2
	if int == 1 then
		dialogLine, dialogTextToList = {}, {}
		dialogLine[#dialogLine + 1] = '{59fc30} > Настройки для аккаунта\t{FFFFFF}'..my_name
			dialogLine[#dialogLine + 1] = ' Скрипт\t'..(ini[inikeys].run and "{59fc30}ON" or "{ff0000}OFF")
			dialogLine[#dialogLine + 1] = ' Проверка инвентаря [SRP/ERP]\t'..(ini[inikeys].inventory and "{59fc30}ON" or "{ff0000}OFF")
			dialogLine[#dialogLine + 1] = ' Проверка /boostinfo [SRP]\t'..(ini[inikeys].boostinfo and "{59fc30}ON" or "{ff0000}OFF")
			if ini[inikeys].run then
				dialogLine[#dialogLine + 1] = ' Сменить позицию\t'
			end
			dialogLine[#dialogLine + 1] = ' Серверная команда принять нарко\t'..ini[inikeys].server_cmd
				dialogTextToList[#dialogLine] = "{FFFFFF}Введите команду которая используется для принятия наркотиков на вашем сервере!"
			dialogLine[#dialogLine + 1] = ' Секунд до следующего принятия нарко\t'..ini[inikeys].seconds
				dialogTextToList[#dialogLine] = "{FFFFFF}Введите через сколько можно принять наркотик на вашем сервере!"
			dialogLine[#dialogLine + 1] = ' Максимальное HP\t'..ini[inikeys].hp
				dialogTextToList[#dialogLine] = "{FFFFFF}Введите ваше максимальное HP!"
			dialogLine[#dialogLine + 1] = ' Максимум грамм можно использовать\t'..ini[inikeys].max_use_gram
				dialogTextToList[#dialogLine] = "{FFFFFF}Введите сколько максимум грамм наркотиков можно использовать за раз!"
			dialogLine[#dialogLine + 1] = ' HP дает 1 грамм наркотиков\t'..ini[inikeys].hp_one_gram
				dialogTextToList[#dialogLine] = "{FFFFFF}Введите сколько HP дает 1 грамм наркотиков!"
		dialogLine[#dialogLine + 1] = '{59fc30} > Общие настройки\t'
			dialogLine[#dialogLine + 1] = ' Кнопка для использвания нарко\t'..ini.global.key:gsub("VK_", '')
			dialogLine[#dialogLine + 1] = ' Сокращенная команда\t'..ini.global.cmd
				dialogTextToList[#dialogLine] = "{FFFFFF}Введите сокращенную команду для принятия наркотиков!"
			dialogLine[#dialogLine + 1] = ' Текст когда таймер стоит\t'..ini.lines.one
				dialogTextToList[#dialogLine] = "{FFFFFF}Введите текст таймера когда он отключен.\n\tМожно использовать замены и цвета HEX\n\t  {036d80}!n{FFFFFF} - переход на новую строку\n\t  {036d80}!a{FFFFFF} - заменится на остаток наркотиков\n\t  {036d80}!m{FFFFFF} - заменится на остаток материалов"
			dialogLine[#dialogLine + 1] = ' Текст когда идёт таймер\t'..ini.lines.two
				dialogTextToList[#dialogLine] = "{FFFFFF}Введите текст таймера когда он работает.\n\tМожно использовать замены и цвета HEX\n\t  {036d80}!n{FFFFFF} - переход на новую строку\n\t  {036d80}!a{FFFFFF} - заменится на остаток наркотиков\n\t  {036d80}!s{FFFFFF} - заменится на остаток секунд\n\t  {036d80}!m{FFFFFF} - заменится на остаток материалов"
			dialogLine[#dialogLine + 1] = ' Шрифт\t'..ini.render.font
				dialogTextToList[#dialogLine] = "{FFFFFF}Введите название шрифта"
			dialogLine[#dialogLine + 1] = ' Размер\t'..ini.render.size
				dialogTextToList[#dialogLine] = "{FFFFFF}Введите размер шрифта"
			dialogLine[#dialogLine + 1] = ' Стиль\t'..ini.render.flag
				dialogTextToList[#dialogLine] = "{FFFFFF}Устанавливайте стиль путем сложения.\n\nТекст без особенностей = 0\nЖирный текст = 1\nНаклонность(Курсив) = 2\nОбводка текста = 4\nТень текста = 8\nПодчеркнутый текст = 16\nЗачеркнутый текст = 32\n\nСтандарт: 13"
			dialogLine[#dialogLine + 1] = ' Выравнивание\t'..( ini.render.align == 1 and "От левого края" or ( ini.render.align == 2 and "По середине" or ( ini.render.align == 3 and " От правого края" or '' ) ) )
			dialogLine[#dialogLine + 1] = ' Отступ новой строки\t'..ini.render.height
				dialogTextToList[#dialogLine] = "{FFFFFF}Введите число от 2 до 10."
			dialogLine[#dialogLine + 1] = '{59fc30}Контакты автора\t'
		local text = ""
		for k,v in pairs(dialogLine) do
			text = text..v.."\n"
		end
		sampShowDialog(0, 'Drugs-Mats: Настройки', text, "Выбрать", "Закрыть", 4)
	end
	if int == 2 then
		d[7] = true
		sampShowDialog(0, "Drugs-Mats: Изменение настроек", dtext, "Выбрать", "Назад", 1)
	end
	if int == 3 then
		sampShowDialog(0, "Drugs-Mats: Контакты автора", "{FFFFFF}Выбери что скопировать\t\nНик на Samp-Rp\tSerhiy_Rubin\nСтраничка {4c75a3}VK{FFFFFF}\tvk.com/id353828351\nГруппа {4c75a3}VK{FFFFFF} с модами\tvk.com/club161589495\n{10bef2}Skype{FFFFFF}\tserhiyrubin\n{7289da}Discord{FFFFFF}\tSerhiy_Rubin#3391", "Копировать", "Назад", 5)
	end
end

function doDialog()
	local caption = sampGetDialogCaption()
	if caption == 'Drugs-Mats: Настройки' then
		local result, button, list, input = sampHasDialogRespond(0)
		if result and button == 1 then
			if dialogLine ~= nil and dialogLine[list + 1] ~= nil then
				local str = dialogLine[list + 1]
				if str:find('Скрипт') then
					ini[inikeys].run = not ini[inikeys].run
					inicfg.save(ini)
					ShowDialog(1)
				end
				if str:find('Сменить позицию') then
					lua_thread.create(function()
						wait(200)
						pos = true
					end)
				end
				if str:find('Проверка инвентаря') then
					ini[inikeys].inventory = not ini[inikeys].inventory
					inicfg.save(ini)
					ShowDialog(1)
				end
				if str:find('Серверная команда принять нарко') then
					ShowDialog(2, dialogTextToList[list + 1], ini[inikeys].server_cmd, true, inikeys, 'server_cmd')
				end
				if str:find('boostinfo') then
					ini[inikeys].boostinfo = not ini[inikeys].boostinfo
					inicfg.save(ini)
					ShowDialog(1)
				end
				if str:find('Секунд до следующего принятия нарко') then
					ShowDialog(2, dialogTextToList[list + 1], ini[inikeys].seconds, false, inikeys, 'seconds')
				end
				if str:find('Максимальное HP') then
					ShowDialog(2, dialogTextToList[list + 1], ini[inikeys].hp, false, inikeys, 'hp')
				end
				if str:find('Максимум грамм можно использовать') then
					ShowDialog(2, dialogTextToList[list + 1], ini[inikeys].max_use_gram, false, inikeys, 'max_use_gram')
				end
				if str:find('HP дает 1 грамм наркотиков') then
					ShowDialog(2, dialogTextToList[list + 1], ini[inikeys].hp_one_gram, false, inikeys, 'hp_one_gram')
				end
				if str:find('Сокращенная команда') then
					ShowDialog(2, dialogTextToList[list + 1], ini.global.cmd, true, 'global', 'cmd')
				end
				if str:find('Текст когда таймер стоит') then
					ShowDialog(2, dialogTextToList[list + 1], ini.lines.one, true, 'lines', 'one')
				end
				if str:find('Текст когда идёт таймер') then
					ShowDialog(2, dialogTextToList[list + 1], ini.lines.two, true, 'lines', 'two')
				end
				if str:find('Шрифт') then
					ShowDialog(2, dialogTextToList[list + 1], ini.render.font, true, 'render', 'font')
				end
				if str:find('Размер') then
					ShowDialog(2, dialogTextToList[list + 1], ini.render.size, true, 'render', 'size')
				end
				if str:find('Стиль') then
					ShowDialog(2, dialogTextToList[list + 1], ini.render.flag, true, 'render', 'flag')
				end
				if str:find('Выравнивание') then
					ini.render.align = ( ini.render.align == 1 and 2 or ( ini.render.align == 2 and 3 or ( ini.render.align == 3 and 1 or 2 ) ) )
					inicfg.save(ini)
					ShowDialog(1)
				end
				if str:find('Отступ новой строки') then
					ShowDialog(2, dialogTextToList[list + 1], ini.render.height, false, 'render', 'height')
				end
				if str:find('Контакты автора') then
					ShowDialog(3)
				end
				if str:find('Кнопка для использвания нарко') then
					lua_thread.create(function()
						wait(150)
						local keys = ""
						repeat
							wait(0)
							for k, v in pairs(vkeys) do
								if not sampIsDialogActive() then
									sampShowDialog(0, "Смена клавиши", "{FFFFFF}Нажмите на любую клавишу\nОна будет использоваться для использования наркотика", "Выбрать", "Закрыть", 0)
								end
								if wasKeyPressed(v) and k ~= "VK_ESCAPE" and k ~= "VK_RETURN" and k ~= "VK_SPACE" then
									keys = k
								end
							end
						until keys ~= ""
						ini.global.key = keys
						inicfg.save(ini)
						ShowDialog(1)
					end)
				end
			end
		end
	end
	if caption == "Drugs-Mats: Изменение настроек" then
		if d[7] then
			d[7] = false
			sampSetCurrentDialogEditboxText(ini[d[5]][d[6]])
		end
		local result, button, list, input = sampHasDialogRespond(0)
		if result then
			if button == 1 then
				local gou = ( d[4] and (#input > 0 and true or false) or (input:find("^%d+$") and true or false))
				if gou then
					d[3] = (d[4] and tostring(input) or tonumber(input))
					ini[d[5]][d[6]] = d[3]
					inicfg.save(ini)
					if d[5]:find('render') then
						renderReleaseFont(font)
						font = renderCreateFont(ini.render.font, ini.render.size, ini.render.flag)
					end
					if d[5]:find('lines') then
						text_to_table()
					end
					ShowDialog(1)
				else
					ShowDialog(d[1], d[2], d[3], d[4], d[5], d[6])
				end
			else
				ShowDialog(1)
			end
		end
	end
	if caption == "Drugs-Mats: Контакты автора" then
		local result, button, list, input = sampHasDialogRespond(0)
		if result then
			if button == 1 then
				if list == 0 then setClipboardText("Serhiy_Rubin") end
				if list == 1 then setClipboardText("https://vk.com/id353828351") end
				if list == 2 then setClipboardText("https://vk.com/club161589495") end
				if list == 3 then setClipboardText("serhiyrubin") end
				if list == 4 then setClipboardText("Serhiy_Rubin#3391") end
				ShowDialog(3)
			else
				ShowDialog(1)
			end
		end
	end
end

function sampev.onServerMessage(color, message)
    if check_boostinfo == 2 and color == -1 and message:find("Действует до") then
		return false
	end
    if check_boostinfo == 2 and color == -1 and message:find("Бонусы отключены") then
		check_boostinfo = 0
		return false
	end
	if (message == " (( Здоровье не пополняется чаще, чем раз в минуту ))" or message == ' (( Здоровье можно пополнить не чаще, чем раз в минуту ))') then not_drugs_timer = true end
	if string.find(message, my_name) then
		if string.find(message, "употребил%(а%) наркотик") then
			if not not_drugs_timer then drugs_timer = os.time() else not_drugs_timer = false end
		end
		if string.find(message, "оружие из материалов") then
			check_get_mats = true
		end
	end
	if message:find('выбросил') and (message:find('аркотики') or message:find('атериалы')) and string.find(message, my_name) then
		check_get_mats = true
	end
	if message:find('Вы взяли несколько комплектов') then
		check_get_mats = true
	end
	if message:find('Вы ограбили дом! Наворованный металл можно сдать около порта.') then
		check_get_mats = true
	end
	if message:find('У вас (%d+)/500 материалов с собой') then
		ini[inikeys].mats = message:match('У вас (%d+)/500 материалов с собой')
		inicfg.save(ini)
	end
	if string.find(message, " %(%( Остаток: (%d+) грамм %)%)") then
		if not not_drugs_timer then drugs_timer = os.time() else not_drugs_timer = false end
		ini[inikeys].drugs = string.match(message, " %(%( Остаток: (%d+) грамм %)%)")
		inicfg.save(ini)
	end
	if string.find(message, '%(%( Остаток: (%d+) материалов %)%)') then
		ini[inikeys].mats = message:match('%(%( Остаток: (%d+) материалов %)%)')
		inicfg.save(ini)
	end
	if message:find('Вы купили %d+ грамм наркотиков за %d+ вирт %(У вас есть (%d+) грамм%)') then
		ini[inikeys].drugs = message:match('Вы купили %d+ грамм наркотиков за %d+ вирт %(У вас есть (%d+) грамм%)')
		inicfg.save(ini)
	end
	if message:find('Вы купили (%d+) грамм наркотиков за %d+ вирт у .+') then
		local s1 = message:match('Вы купили (%d+) грамм наркотиков за %d+ вирт у .+')
		ini[inikeys].drugs = tonumber(s1) + ini[inikeys].drugs
		inicfg.save(ini)
	end
end

function sampev.onSendChat(message) sleep = os.clock() * 1000 end
function sampev.onSendCommand(cmd)
	local command, params = string.match(cmd:lower(), "^%/([^ ]*)(.*)")
	if command == ini.global.cmd:lower() or string.find(command, ini[inikeys].server_cmd) then
		if string.find(params, "menu") then
			ShowDialog(1)
			return false
		end
		if #params == 0 then
			local gramm = math.ceil(((ini[inikeys].hp + 1) - getCharHealth(playerPed)) / ini[inikeys].hp_one_gram)
			if gramm > ini[inikeys].max_use_gram then gramm = ini[inikeys].max_use_gram end
			second_timer = os.difftime(os.time(), drugs_timer)
			if second_timer <= ini[inikeys].seconds and second_timer > 0 then gramm = 1 end
			return {string.format('/%s %d', ini[inikeys].server_cmd, gramm)}
		end
		if command == ini.global.cmd:lower() then
			cmd = cmd:lower():gsub(ini.global.cmd:lower(), ini[inikeys].server_cmd)
			return { cmd }
		end
	end
	sleep = os.clock() * 1000
end

function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
	if title:find('Информация') or title:find('Карманы') then
		local nark, mats = false, false
		local arr = split(text, "\n")
		for i = 1, #arr do
			if arr[i]:find('Наркотики\t(%d+)') then
				ini[inikeys].drugs = arr[i]:match('Наркотики\t(%d+)')
				nark = true
			end
			if arr[i]:find('Материалы\t(%d+)') then
				ini[inikeys].mats = arr[i]:match('Материалы\t(%d+)')
				mats = true
			end
		end
		if not nark then ini[inikeys].drugs = 0 end
		if not mats then ini[inikeys].mats = 0 end
		inicfg.save(ini)

		if check_inventory == 2 or (check_inventory_time ~= nil and os.time() - check_inventory_time < 5) then
			check_inventory = 0
			check_inventory_time = os.time()
			sampSendDialogResponse(dialogId, 0, 0, "")
			return false
		end
	end
    if dialogId == 22 and title == "Бонусы" then
		local arr = split(text, "\n")
		for i = 1, #arr do
			if arr[i]:find('Таймер на Нарко	(.+)') then
				bonus_drugs = tonumber(arr[i]:match('Таймер на Нарко	(.+)'))
				break
			end
		end
		if check_boostinfo == 2 then
			check_boostinfo = 0
		  	return false
		end
	end
end

function GetMats()
	if not check_get_mats then return end
	check_get_mats = false
	repeat
		wait(0)
	until os.clock() * 1000 - sleep > 1200 and sampGetPlayerScore(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))) >= 1 and not sampIsDialogActive() and not sampIsChatInputActive()

	local _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
	if ini[inikeys].inventory then
		check_inventory = 2
		repeat
			wait(0)
			if os.clock() * 1000 - sleep > 1200 and sampGetPlayerScore(id) >= 1 and not sampIsDialogActive() and not sampIsChatInputActive() then
				sampSendChat('/inventory')
				sleep = os.clock() * 1000
			end
		until check_inventory ~= 2
	end

	if ini[inikeys].boostinfo and check_boostinfo_status == nil then
		check_boostinfo_status = os.time()
		check_boostinfo = 2
		repeat
			wait(0)
			if os.clock() * 1000 - sleep > 1200 and sampGetPlayerScore(id) >= 1 and not sampIsDialogActive() and not sampIsChatInputActive() then
				sampSendChat('/boostinfo')
				sleep = os.clock() * 1000
			end
		until check_boostinfo ~= 2
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

function addChatMessage(text)
    local tag = string.format("{667dff}[%s]{FFFFFF} ", thisScript().name)
    sampAddChatMessage(tag..text, 0xFFFFFFFF)
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

script_update = {
    version_url = "http://git.deadpoo.net/rubin/drugs-mats/raw/branch/master/version",
    script_url = "http://git.deadpoo.net/rubin/drugs-mats/raw/branch/master/drugs-mats.lua",
    changelog_url = "http://git.deadpoo.net/rubin/drugs-mats/raw/branch/master/changelog",
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
utf8({ "sampAddChatMessage" }, "Utf8ToAnsi")
utf8({ "print" }, "Utf8ToAnsi")
utf8({ "renderGetFontDrawTextLength" }, "Utf8ToAnsi")
utf8({ "renderFontDrawText" }, "Utf8ToAnsi")
utf8({ "sampSetCurrentDialogEditboxText" }, "Utf8ToAnsi")
utf8({ "sampHasDialogRespond" }, nil, "AnsiToUtf8")
utf8({ "sampGetDialogCaption" }, nil, "AnsiToUtf8")
utf8({ "sampev", "onServerMessage" }, "AnsiToUtf8", "Utf8ToAnsi")
utf8({ "sampev", "onShowDialog" }, "AnsiToUtf8", "Utf8ToAnsi")
utf8({ "sampev", "onSendCommand" }, "AnsiToUtf8", "Utf8ToAnsi")