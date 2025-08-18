	-- �����: AlexDunaevskiy, 2025  https://t.me/+VxorOlng8OcwMjUy
	-- ������ "LogChat" ��� ����������� ���� � SA-MP
	local script_name = 'LogChat'
	local script_version = '25/03/2025'
	require "lib.sampfuncs"
	local sampev = require "lib.samp.events"
	local imgui = require 'imgui'
	local encoding = require 'encoding'
	local bit = require 'bit'
	local json = require 'json'

	encoding.default = 'CP1251'
	local u8 = encoding.UTF8

	-- ���� � ������ � ������
	local log_folder = getWorkingDirectory() .. "\\LuaDunaevskiy\\logChat"
	local sms_log_file = log_folder .. "\\sms.txt"
	local announcement_log_file = log_folder .. "\\announcement.txt"
	local admin_log_file = log_folder .. "\\admin.txt"
	local all_chat_log_file = log_folder .. "\\all_chat.txt"
	local faction_log_file = log_folder .. "\\faction.txt"
	local archive_folder = log_folder .. "\\archives"
	local settings_file = log_folder .. "\\logChat_settings.json"
	local kills_log_file = log_folder .. "\\kills.txt"
	-- ���������� ���������
	local main_window_state = imgui.ImBool(false)
	local blacklist_window_state = imgui.ImBool(false)
	local active_tab = 1 -- 1 = SMS, 2 = ����������, 3 = �������������, 4 = ��� �������, 5 = �������, 6 = ������, 7 = ���������
	local search_text = imgui.ImBuffer(256)
	local block_announcements = imgui.ImBool(false)
	local block_admin_messages = imgui.ImBool(false)
	local block_faction_messages = imgui.ImBool(false)
	local block_news = imgui.ImBool(false)
	local block_all_factions = imgui.ImBool(false)
	local archive_by_lines = imgui.ImBool(true)
	local max_lines = imgui.ImInt(5000)
	local selected_archive = imgui.ImInt(0)
	local window_pos = imgui.ImVec2(100, 100)
	local window_size = imgui.ImVec2(400, 300)
	local font_size = imgui.ImFloat(14.0)
	local prev_font_size = font_size.v
	local log_font = nil
	local font_needs_update = false
	local is_first_run = true
	local just_opened = false
	local max_kills = {} -- ��������� ������������� ����� ��� ������� ������
	-- ���������������� ���������
	local line_counts = {}
	local log_contents = {}
	local color_cache = {}
	local cached_filtered_content = {}
	local last_search_text = ""
	local current_archive_content = nil
	local current_selected_file = nil
	local prevTextDrawState = nil

	-- ������ ������ ��� ���������
	local blacklist = {}
	local blacklist_enabled = imgui.ImBool(false)
	local blacklist_log_enabled = imgui.ImBool(true)
	local blacklist_input_nick = imgui.ImBuffer(32)

	-- ���������
	local ads = {'����������:', '�������� News'}
	local admin_phrases = {'�������������:', '�� ��������������'}

	-- ������� ������������ ������ ��� ����� ���������
	local color_mappings = {
		sms = {"{FFFFFFFFFFFF00FF}", "{FFFF00FF}"}, -- SMS-���������
		announcements = {"{FF8C37FF}", "{00D900FF}", "{FFFFFFFFFF8C37FF}", "{FFFFFFFF00D900FF}"}, -- ����������
		news = {"{2641FEFF}", "{FFFFFFFF2641FEFF}"}, -- �������
		admin = {"{FF6347FF}", "{FFFFFFFFFF6347FF}"}, -- �����-���������
		faction = {"{01FCFFFF}", "{FFFFFFFF01FCFFFF}"}, -- ����������� ���
		state_news = {"{FFFFFFFFFFFFFFFF}", "{FFFFFFFF}"}, -- ��������������� �������
		kills = {"{FFFFFFFF}", "{FF0000FF}"} -- ����� ��� ������� �������
	}

	-- ��������� ������� � �������������� ����������������� ���������
	local faction_settings = {
		yakudza = {color = "{01FCFFFF}", phrases = {'������', '�����', 'ʸ���', '����-�������', '����������', '��-�������', '�����', '�����-�����', '�����', '������'}, block = imgui.ImBool(false)},
		ballas = {color = "{01FCFFFF}", phrases = {'�����', '������', '������', '��� ���', '�� ���', '��������', '������� ����', '�����', '���� ����', '��� �����'}, block = imgui.ImBool(false)},
		grove = {color = "{01FCFFFF}", phrases = {'�����', '������', '�����', '���� �', '�������', '�. �.', '������', '�� ����', '������', '��� ���'}, block = imgui.ImBool(false)},
		aztec = {color = "{01FCFFFF}", phrases = {'�����', '�������', '������', '��� ������', '�������', '�����', '�������', '��������', '������', '�����'}, block = imgui.ImBool(false)},
		vagos = {color = "{01FCFFFF}", phrases = {'������', '���������', '�����', '����������', '�������', 'V. E. G.', '��������', '����� V. E. G.', '�������', '�����'}, block = imgui.ImBool(false)},
		rifa = {color = "{01FCFFFF}", phrases = {'������', '������', '�����', '����', '�������', '������', '�������', '���������', '�������', '�����'}, block = imgui.ImBool(false)},
		lcn = {color = "{01FCFFFF}", phrases = {'�������', '���������', '�����������', '�������', '����', '����� ����', '����', '������� ����', '����������', '���'}, block = imgui.ImBool(false)},
		russian_mafia = {color = "{01FCFFFF}", phrases = {'�����', '�����', '���', '������', '�������', '�����', '������', '���', '��� � ������', '���������'}, block = imgui.ImBool(false)},
		reporters = {color = "{01FCFFFF}", phrases = {'������', '�������������', '�������������', '��������', '�������', '��������', '��. ��������', '���. ��������', '����������� ��������', '��������'}, block = imgui.ImBool(false)},
		instructors = {color = "{01FCFFFF}", phrases = {'������', '�����������', '�����������', '��. ����������', '����������', '�����������', '��. ��������', '��. ��������', '��������', '�����������'}, block = imgui.ImBool(false)},
		medics = {color = "{01FCFFFF}", phrases = {'������', '�������', '���. ����', '���������', '��������', '������', '��������', '������', '���. ����. �����', '����. ����'}, block = imgui.ImBool(false)},
		army = {color = "{01FCFFFF}", phrases = {'�������', '��������', '��. �������', '�������', '��. �������', '��������', '���������', '��. ���������', '���������', '��. ���������', '�������', '�����', '������������', '���������', '�������'}, block = imgui.ImBool(false)},
		police = {color = "{01FCFFFF}", phrases = {'�����', '������', '��. �������', '�������', '���������', '��. ���������', '��. ���������', '���������', '��. ���������', '�������', '�����', '������������', '���������', '�����'}, block = imgui.ImBool(false)},
		bikers = {color = "{01FCFFFF}", phrases = {'Support', 'Hang around', 'Prospect', 'Member', 'Road captain', 'Sergeant-at-arms', 'Treasurer', 'Vice president', 'President'}, block = imgui.ImBool(false)},
		fbi = {color = "{01FCFFFF}", phrases = {'������', '��������', '������� �����', '����� GNK', '����� CID', '����� GNK', '����� CID', '���������', '����������� ���������', '��������'}, block = imgui.ImBool(false)},
		city_hall = {color = "{01FCFFFF}", phrases = {'���������', '�������', '��������', '��������� ������', '���. ����', '���'}, block = imgui.ImBool(false)}
	}

	-- ��������������� ���������� �������� ��� �������
	for faction, settings in pairs(faction_settings) do
		settings.pattern = "^(" .. table.concat(settings.phrases, "|") .. ")"
	end

	-- �������� ����������
	if not doesDirectoryExist(log_folder) then createDirectory(log_folder) end
	if not doesDirectoryExist(archive_folder) then createDirectory(archive_folder) end

	-- ������������� ����� � ������
	local function initialize_log_contents()
		for _, file in ipairs({sms_log_file, announcement_log_file, admin_log_file, all_chat_log_file, faction_log_file}) do
			line_counts[file] = 0
			log_contents[file] = {}
			local file_obj = io.open(file, "rb")
			if file_obj then
				for line in file_obj:lines() do
					table.insert(log_contents[file], line)
					line_counts[file] = line_counts[file] + 1
				end
				file_obj:close()
			end
		end
		
		-- ����������� ��� ��� kills_log_file
		line_counts[kills_log_file] = 0
		log_contents[kills_log_file] = {}
		local file_obj = io.open(kills_log_file, "rb")
		if file_obj then
			for line in file_obj:lines() do
				table.insert(log_contents[kills_log_file], line)
				line_counts[kills_log_file] = line_counts[kills_log_file] + 1
			end
			file_obj:close()
		end
	end
	initialize_log_contents()

	-- ��������� ������
function imgui.BeforeDrawFrame()
    if log_font == nil or font_needs_update then
        imgui.GetIO().Fonts:Clear()
        log_font = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\calibri.ttf', font_size.v, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
        if not log_font then
            sampAddChatMessage("[LogChat] ������ �������� ������ Calibri. ������������ ����� �� ���������.", 0xFF0000)
            log_font = imgui.GetIO().Fonts:AddFontDefault()
        end
        imgui.GetIO().Fonts:Build()
        font_needs_update = false
    end
end

	-- ���������� ��������
	local function save_settings()
		local data = {
			block_announcements = block_announcements.v,
			block_admin_messages = block_admin_messages.v,
			block_faction_messages = block_faction_messages.v,
			block_news = block_news.v,
			block_all_factions = block_all_factions.v,
			archive_by_lines = archive_by_lines.v,
			max_lines = max_lines.v,
			font_size = font_size.v,
			window_pos_x = window_pos.x,
			window_pos_y = window_pos.y,
			window_size_x = window_size.x,
			window_size_y = window_size.y,
			faction_blocks = {},
			blacklist = {},
			blacklist_enabled = blacklist_enabled.v,
			blacklist_log_enabled = blacklist_log_enabled.v
		}
		for faction, settings in pairs(faction_settings) do
			data.faction_blocks[faction] = settings.block.v
		end
		for nick in pairs(blacklist) do table.insert(data.blacklist, nick) end
		local file = io.open(settings_file, "w")
		if file then
			file:write(json.encode(data))
			file:close()
			if font_size.v ~= prev_font_size then
				font_needs_update = true
				prev_font_size = font_size.v
				thisScript():reload()
			end
		else
			sampAddChatMessage("[LogChat] �� ������� ��������� ��������� � " .. settings_file, 0xFF0000)
		end
	end

	-- �������� ��������
	local function load_settings()
		if doesFileExist(settings_file) then
			local file = io.open(settings_file, "r")
			if file then
				local content = file:read("*a")
				file:close()
				if content and content:match("%S") then
					local success, data = pcall(json.decode, content)
					if success and data then
						block_announcements.v = data.block_announcements or false
						block_admin_messages.v = data.block_admin_messages or false
						block_faction_messages.v = data.block_faction_messages or false
						block_news.v = data.block_news or false
						block_all_factions.v = data.block_all_factions or false
						archive_by_lines.v = data.archive_by_lines or true
						max_lines.v = data.max_lines or 5000
						font_size.v = data.font_size or 14.0
						prev_font_size = font_size.v
						window_pos.x = data.window_pos_x or 100
						window_pos.y = data.window_pos_y or 100
						window_size.x = data.window_size_x or 400
						window_size.y = data.window_size_y or 300
						blacklist = {}
						for _, nick in ipairs(data.blacklist or {}) do blacklist[nick] = true end
						blacklist_enabled.v = data.blacklist_enabled or false
						blacklist_log_enabled.v = data.blacklist_log_enabled ~= nil and data.blacklist_log_enabled or true
						for faction, settings in pairs(faction_settings) do
							settings.block.v = data.faction_blocks and data.faction_blocks[faction] or false
						end
					else
						sampAddChatMessage("[LogChat] ������������ JSON � " .. settings_file, 0xFF0000)
						save_settings()
					end
				else
					save_settings()
				end
			else
				save_settings()
			end
		else
			save_settings()
		end
	end

	-- ������������� �����
	local function archive_file(filename)
		local timestamp = os.date("%Y-%m-%d_%H-%M-%S")
		local archive_name = archive_folder .. "\\" .. filename:match("([^\\]+)$"):gsub("%.txt", "") .. "_" .. timestamp .. ".txt"
		local file = io.open(filename, "r")
		if file then
			local content = file:read("*a")
			file:close()
			local archive_file = io.open(archive_name, "w")
			if archive_file then
				archive_file:write(content)
				archive_file:close()
				local new_file = io.open(filename, "w")
				if new_file then new_file:close() end
			end
		end
	end

	-- ���������� ������ � ���� � ������
	local function append_to_file(filename, text)
		local timestamp = os.date("%Y-%m-%d %H:%M:%S")
		local utf8_text = u8:encode(text, 'CP1251')
		local formatted_text = string.format("[%s] %s", timestamp, utf8_text)
		local file = io.open(filename, "a+b")
		if file then
			file:write(formatted_text .. "\n")
			file:close()
			table.insert(log_contents[filename], formatted_text)
			line_counts[filename] = line_counts[filename] + 1
			if line_counts[filename] > max_lines.v then
				archive_file(filename)
				log_contents[filename] = {}
				line_counts[filename] = 0
				cached_filtered_content[filename] = nil
			end
		else
			sampAddChatMessage("[LogChat] ������ ������ � " .. filename, 0xFF0000)
		end
	end

	-- ���������� ����������� �����
	local function filter_content(content, search)
		if search == "" then return content end
		local filtered = {}
		local escaped_search = search:lower():gsub("[%%%(%)%.%+%-%*%?%[%]%^%$]", "%%%0")
		for _, line in ipairs(content) do
			if line:lower():find(escaped_search) then
				table.insert(filtered, line)
			end
		end
		return filtered
	end

	-- �������������� ARGB � HEX
	local function argb_to_hex(argb_color)
		return string.format("{%08X}", argb_color)
	end

	-- ��������, ������ �� ���� � ������ ��� ������ ���������
	local function matches_color(raw_text, category)
		for _, color in ipairs(color_mappings[category]) do
			if raw_text:match("^" .. color:gsub("[{}]", "%%%1")) then
				return true
			end
		end
		return false
	end

local function processKillsTextDraw()
    local weapons = {
        "Fist", "Brass Knuckles", "Golf Club", "Nite Stick", "Knife", 
        "Baseball Bat", "Shovel", "Pool Cue", "Chainsaw", "Dildo", 
        "Dildo", "Vibrator", "Flowers", "Cane", "Grenade", 
        "Teargas", "Molotov Cocktail", "Colt 45", "Silenced Pistol", "Desert Eagle", 
        "Shotgun", "Sawn-off Shotgun", "Combat Shotgun", "UZI", "MP5", 
        "AK47", "M4", "TEC9", "Rifle", "Sniper Rifle", 
        "Rocket Launcher", "Heat Seeker", "Flamethrower", "Minigun", "Satchel Explosives", 
        "Bomb", "Fire Extinguisher", "Vehicle", "Helicopter Blades", "Explosion"
    }
    local killsTextDrawId = nil
    
    -- ������� ��� ������� ��������
    local function trim(s)
        return s:match("^%s*(.-)%s*$")
    end
    
    for id = 0, 4095 do
        if sampTextdrawIsExists(id) then
            local text = sampTextdrawGetString(id)
            if text and text ~= "" then
                -- ���������� ���������� ��������� ��� ��������� ������� � �������� ������
                local nick, weapon, number = text:match("^([%w_]+)%s*-%s*([%w%-]+%s*[%w%-]*)%s*-([%d%.%-]+)")
                if nick and weapon and number then
                    weapon = trim(weapon)
                    for _, w in ipairs(weapons) do
                        if string.lower(weapon) == string.lower(w) then
                            killsTextDrawId = id
                            break
                        end
                    end
                end
            end
            if killsTextDrawId then break end
        end
    end
    
    if killsTextDrawId then
        local text = sampTextdrawGetString(killsTextDrawId)
        local nick, weapon, number = text:match("^([%w_]+)%s*-%s*([%w%-]+%s*[%w%-]*)%s*-([%d%.%-]+)")
        
        if nick and weapon and number then
            local num = tonumber(number)
            if not num then
                return
            end
            
            weapon = trim(weapon)
            local killFlag = text:find("%s*-%s*KILL$") ~= nil
            local currentTime = os.clock()
            
            -- ��������� ������ ������ ���� ��������� ����� ��� ���������
            if not max_kills[nick] or max_kills[nick].weapon ~= weapon or max_kills[nick].number ~= num or max_kills[nick].id ~= killsTextDrawId then
                max_kills[nick] = {
                    weapon = weapon,
                    number = num,
                    id = killsTextDrawId,
                    logged = false,
                    lastUpdate = currentTime
                }
            end
            
            -- ��������� ������ �� ������� ��� � "KILL"
            if killFlag and not max_kills[nick].logged then
                local entry = string.format("%s - %s - %.1f - KILL", nick, max_kills[nick].weapon, max_kills[nick].number)
                append_to_file(kills_log_file, "{FF0000FF}" .. entry .. "{FF0000FF}")
                max_kills[nick].logged = true
                prevTextDrawState = text
            elseif not killFlag and max_kills[nick] and not max_kills[nick].logged then
                if (currentTime - max_kills[nick].lastUpdate) >= 3 then
                    local entry = string.format("%s - %s - %.1f", nick, max_kills[nick].weapon, max_kills[nick].number)
                    append_to_file(kills_log_file, "{FFFFFFFF}" .. entry .. "{FFFFFFFF}")
                    max_kills[nick].logged = true
                end
                prevTextDrawState = text
            else
                prevTextDrawState = text
            end
        else
        end
    elseif prevTextDrawState and next(max_kills) then
        local currentTime = os.clock()
        for nick, data in pairs(max_kills) do
            if not sampTextdrawIsExists(data.id) then
                if not data.logged and (currentTime - data.lastUpdate) >= 3 then
                    local entry = string.format("%s - %s - %.1f", nick, data.weapon, data.number)
                    append_to_file(kills_log_file, "{FFFFFFFF}" .. entry .. "{FFFFFFFF}")
                end
                max_kills[nick] = nil
            elseif not data.logged and (currentTime - data.lastUpdate) >= 3 then
                local entry = string.format("%s - %s - %.1f", nick, data.weapon, data.number)
                append_to_file(kills_log_file, "{FFFFFFFF}" .. entry .. "{FFFFFFFF}")
                max_kills[nick].logged = true
            end
        end
        if not next(max_kills) then
            prevTextDrawState = nil
        end
    end
end

-- ��������� ���� �� ID
local function getNickFromId(id)
    local playerId = tonumber(id)
    if not playerId or playerId < 0 or playerId > 999 then
        return nil
    end

    -- ���������, ��������� �� ����� � ������ ID
    if sampIsPlayerConnected(playerId) then
        if not sampGetPlayerNickname then
            return nil
        end

        local success, result = pcall(function()
            local nick = sampGetPlayerNickname(playerId)
            if nick then
                return nick
            else
                return nil
            end
        end)
        if success and result then
            return result
        elseif not success then
            return nil
        else
            return nil
        end
    else
        sampAddChatMessage("[LogChat] ����� � ID " .. playerId .. " �� ���������", 0xFF0000)
        return nil
    end
end
	-- ���������� � ������ ������
-- ���������� � ������ ������
local function addToBlacklist(nick)
    if nick == "" then
        sampAddChatMessage("[LogChat] ������� ��� ������ ��� ID", 0xFF0000)
        return
    end
    
    -- ���������, �������� �� ��������� �������� ������ �� 0 �� 999
    local num = tonumber(nick)
    if num and num >= 0 and num <= 999 then
        local playerNick = getNickFromId(num)
        if playerNick then
            if blacklist[playerNick] then
                sampAddChatMessage("[LogChat] ����� " .. playerNick .. " ��� � ������ ������", 0xFF0000)
                return
            end
            blacklist[playerNick] = true
            sampAddChatMessage("[LogChat] ����� " .. playerNick .. " (ID: " .. nick .. ") �������� � ������ ������", 0x00FF00)
            save_settings()
        end
    else
        -- ������� ��������� ����
        if blacklist[nick] then
            sampAddChatMessage("[LogChat] ����� " .. nick .. " ��� � ������ ������", 0xFF0000)
            return
        end
        blacklist[nick] = true
        sampAddChatMessage("[LogChat] ����� " .. nick .. " �������� � ������ ������", 0x00FF00)
        save_settings()
    end
end

	-- ������� �������
	function main()
		if not isSampLoaded() or not isSampfuncsLoaded() then return end
		while not isSampAvailable() do wait(100) end

		load_settings()
		sampAddChatMessage("[LogChat] ������� ��������", 0x00FF00)

		local function ensure_file_exists(file, initial_text)
			if not doesFileExist(file) then append_to_file(file, initial_text) end
		end

		ensure_file_exists(sms_log_file, "��� SMS �����")
		ensure_file_exists(announcement_log_file, "��� ���������� �����")
		ensure_file_exists(admin_log_file, "��� ������������� �����")
		ensure_file_exists(all_chat_log_file, "��� ���� ������� ���� �����")
		ensure_file_exists(faction_log_file, "��� ������������ ���� �����")
		ensure_file_exists(kills_log_file, "��� ������� �����")

		cached_filtered_content = {}
		last_search_text = ""

		sampRegisterChatCommand("log", function() main_window_state.v = not main_window_state.v end)
		sampRegisterChatCommand("chs", function(arg)
			if not arg or arg == "" then
				sampAddChatMessage("[LogChat] �������������: /chs [��� ��� ID]", 0xFF0000)
				blacklist_window_state.v = true
				return
			end
			addToBlacklist(arg)
		end)

		while true do
			wait(0)
			imgui.Process = main_window_state.v or blacklist_window_state.v
			processKillsTextDraw()
		end
	end


	-- ��������� ��������� ���������
function sampev.onServerMessage(color, text)
    local color_hex = argb_to_hex(color)
    local raw_text = text:gsub("%s*$", "")
    if not raw_text:match("^{%x%x%x%x%x%x%x%x}") then
        raw_text = color_hex .. raw_text .. color_hex
    end

    -- ���������� ��� ������������ ������� ������
    local is_blacklisted = false
    if blacklist_enabled.v and matches_color(raw_text, "sms") and raw_text:find("SMS:") then
        local sender
        local success, result = pcall(function()
            return raw_text:match("�����������:%s*([%w_]+)%[%d+]")
        end)
        if success then
            sender = result
        else
            sampAddChatMessage("[LogChat] ������ �������� SMS: " .. raw_text, 0xFF0000)
        end
        if sender and blacklist[sender] then
            is_blacklisted = true
            if not blacklist_log_enabled.v then return false end
        end
    end

    -- ���� ��� ���������� ����������� � ����
    local should_block = false
    local is_faction_message = raw_text:find("{01FCFFFF}")

    -- �������� ���������� �������
    if block_faction_messages.v and is_faction_message then
        local text_after_color = raw_text:sub(raw_text:find("{01FCFFFF}", 1, true) + 10)
        if block_all_factions.v then
            should_block = true
        else
            for faction, settings in pairs(faction_settings) do
                for _, phrase in ipairs(settings.phrases) do
                    if text_after_color:find(phrase, 1, true) and settings.block.v then
                        should_block = true
                        break
                    end
                end
                if should_block then break end
            end
        end
    end

    -- ������ ����������� ���� ���������
    if not is_blacklisted or blacklist_log_enabled.v then
        append_to_file(all_chat_log_file, raw_text) -- ������ ���������� � ����� ���
        if matches_color(raw_text, "sms") and raw_text:find("SMS:") then
            append_to_file(sms_log_file, raw_text)
        elseif matches_color(raw_text, "announcements") and raw_text:find("����������:") then
            append_to_file(announcement_log_file, raw_text)
        elseif matches_color(raw_text, "admin") then
            for _, phrase in pairs(admin_phrases) do
                if raw_text:find(phrase) or raw_text:find("�������%(%a?%) ��� ���� �� ��������������") then
                    append_to_file(admin_log_file, raw_text)
                    break
                end
            end
        elseif is_faction_message then
            append_to_file(faction_log_file, raw_text) -- ���������� ����������� ��������� ������ �����
        elseif (matches_color(raw_text, "news") and raw_text:find("�������:")) or
               (matches_color(raw_text, "state_news") and raw_text:find("��������������� �������")) then
            append_to_file(announcement_log_file, raw_text)
        end
    end

    -- ���������� ����������� � ����
    if is_blacklisted then return false end
    if should_block then return false end
    if block_announcements.v then
        for _, v in pairs(ads) do
            if raw_text:find(v) and matches_color(raw_text, "announcements") then
                return false
            end
        end
    end
    if block_news.v then
        if (matches_color(raw_text, "news") and raw_text:find("�������:")) or
           (matches_color(raw_text, "state_news") and raw_text:find("��������������� �������")) then
            return false
        end
    end
    if block_admin_messages.v then
        for _, v in pairs(admin_phrases) do
            if raw_text:find(v) and matches_color(raw_text, "admin") then
                return false
            end
        end
        if raw_text:find("�������%([�%]%) ��� ���� �� ��������������") and matches_color(raw_text, "admin") then
            return false
        end
    end
end
	
	-- ��������� �������� ������
	local timestamp_menus = {}
	function draw_colored_text(text)
		local default_color = imgui.ImVec4(1.0, 1.0, 1.0, 1.0)
		local current_color = default_color
		local line_width = 0
		local max_width = imgui.GetContentRegionAvail().x - 10

		imgui.PushFont(log_font)
		local timestamp_start, timestamp_end = text:find("^%[%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d%]")
		local content_without_timestamp = text
		local unique_id = "##ts_" .. tostring(string.hash(text))

		if timestamp_start then
			local timestamp = text:sub(timestamp_start, timestamp_end)
			local timestamp_width = imgui.CalcTextSize(timestamp).x
			imgui.BeginGroup()
			imgui.PushStyleColor(imgui.Col.Text, current_color)
			local is_active = timestamp_menus[unique_id] == true
			if imgui.Selectable(timestamp .. unique_id, is_active, 0, imgui.ImVec2(timestamp_width, 20)) then
				if timestamp_menus[unique_id] then timestamp_menus[unique_id] = false end
			end
			if imgui.IsItemHovered() and imgui.IsMouseReleased(0) then
				local clean_text = content_without_timestamp:gsub("{%x+}", "")
				imgui.SetClipboardText(clean_text)
			end
			if imgui.IsItemHovered() and imgui.IsMouseReleased(1) then
				timestamp_menus[unique_id] = true
				for key in pairs(timestamp_menus) do if key ~= unique_id then timestamp_menus[key] = false end end
				imgui.OpenPopup(unique_id .. "_Menu")
			end
			if imgui.IsMouseClicked(0) and not imgui.IsItemHovered() and timestamp_menus[unique_id] then
				timestamp_menus[unique_id] = false
			end
			imgui.PopStyleColor()
			imgui.EndGroup()
			imgui.SameLine(0, 0)
			line_width = line_width + timestamp_width
			content_without_timestamp = text:sub(timestamp_end + 2)
		end

		if unique_id and imgui.BeginPopup(unique_id .. "_Menu") then
			if imgui.MenuItem(u8"���������� (��� �������)") then
				local clean_text = content_without_timestamp:gsub("{%x+}", "")
				imgui.SetClipboardText(clean_text)
				timestamp_menus[unique_id] = false
			end
			local nicks = {}
			local nick_pattern = "%w+_%w+"
			local last_pos = 1
			while true do
				local nick_start, nick_end = content_without_timestamp:find(nick_pattern, last_pos)
				if not nick_start then break end
				local nick = content_without_timestamp:sub(nick_start, nick_end):gsub("{%x+}", "")
				if nick ~= "" then nicks[nick] = true end
				last_pos = nick_end + 1
			end
			if next(nicks) then
				for nick in pairs(nicks) do
					if imgui.MenuItem(u8"����� �� ����: " .. nick) then
						search_text.v = nick
						timestamp_menus[unique_id] = false
					end
				end
			else
				imgui.Text(u8"�� ������ ���� �� �������")
			end
			if imgui.MenuItem(u8"�������") then timestamp_menus[unique_id] = false end
			imgui.EndPopup()
		end

		local parts = {}
		local last_pos = timestamp_end and (timestamp_end + 2) or 1
		while true do
			local color_start, color_end = text:find("{%x+}", last_pos)
			if not color_start then
				table.insert(parts, {type = "text", content = text:sub(last_pos), color = current_color})
				break
			end
			if last_pos < color_start then
				table.insert(parts, {type = "text", content = text:sub(last_pos, color_start - 1), color = current_color})
			end
			local color_tag = text:sub(color_start + 1, color_end - 1)
			if #color_tag >= 6 then
				local rgb_or_rgba_tag = #color_tag >= 8 and color_tag:sub(-8) or color_tag
				if not color_cache[rgb_or_rgba_tag] then
					local r = tonumber(rgb_or_rgba_tag:sub(1, 2), 16) or 255
					local g = tonumber(rgb_or_rgba_tag:sub(3, 4), 16) or 255
					local b = tonumber(rgb_or_rgba_tag:sub(5, 6), 16) or 255
					color_cache[rgb_or_rgba_tag] = imgui.ImVec4(r / 255, g / 255, b / 255, 1.0)
				end
				current_color = color_cache[rgb_or_rgba_tag]
			else
				table.insert(parts, {type = "text", content = "{" .. color_tag .. "}", color = current_color})
			end
			last_pos = color_end + 1
		end

		for _, part in ipairs(parts) do
			if part.content ~= "" then
				for word in part.content:gmatch("%S+%s*") do
					local word_width = imgui.CalcTextSize(word).x
					if line_width + word_width > max_width then
						imgui.NewLine()
						line_width = 0
					end
					imgui.TextColored(part.color, word)
					imgui.SameLine(0, 0)
					line_width = line_width + word_width
				end
			end
		end
		imgui.NewLine()
		imgui.PopFont()
	end

	-- ����������� �����
	if not string.hash then
		function string.hash(s)
			local hash = 0
			for i = 1, #s do
				hash = bit.bxor(hash, bit.lshift(hash, 5))
				hash = bit.bxor(hash, string.byte(s, i))
			end
			return math.abs(hash)
		end
	end

	-- �������� ������� �� ����������
	local faction_names = {
		["������"] = "yakudza", ["������"] = "ballas", ["�����"] = "grove", ["������"] = "aztec",
		["�����"] = "vagos", ["����"] = "rifa", ["LCN"] = "lcn", ["������� �����"] = "russian_mafia",
		["��������"] = "reporters", ["�����������"] = "instructors", ["������"] = "medics",
		["�����"] = "army", ["�������"] = "police", ["�������"] = "bikers", ["���"] = "fbi",
		["�����"] = "city_hall"
	}

	-- ��������� ����������
function imgui.OnDrawFrame()
    if main_window_state.v then
        if is_first_run then
            imgui.SetNextWindowPos(window_pos, imgui.Cond.FirstUseEver)
            imgui.SetNextWindowSize(window_size, imgui.Cond.FirstUseEver)
            is_first_run = false
            just_opened = true
        elseif just_opened then
            just_opened = false
        end

        imgui.Begin(u8'������� ����', main_window_state)
        local prev_tab = active_tab
        if imgui.RadioButton(u8'SMS', active_tab == 1) then active_tab = 1 end imgui.SameLine()
        if imgui.RadioButton(u8'����������', active_tab == 2) then active_tab = 2 end imgui.SameLine()
        if imgui.RadioButton(u8'�������������', active_tab == 3) then active_tab = 3 end imgui.SameLine()
        if imgui.RadioButton(u8'��� �������', active_tab == 4) then active_tab = 4 end imgui.SameLine()
        if imgui.RadioButton(u8'�������', active_tab == 5) then active_tab = 5 end imgui.SameLine()
        if imgui.RadioButton(u8'������', active_tab == 6) then active_tab = 6 end imgui.SameLine()
        if imgui.RadioButton(u8'���������', active_tab == 7) then active_tab = 7 end imgui.SameLine()
        if imgui.RadioButton(u8'��������', active_tab == 8) then active_tab = 8 end -- ��������� ������� "��������" � ��� �� ������

        local should_scroll_to_bottom = just_opened or prev_tab ~= active_tab
        imgui.BeginChild("ScrollRegion", imgui.ImVec2(0, -30), true)

        if not cached_filtered_content or prev_tab ~= active_tab or last_search_text ~= search_text.v then
            cached_filtered_content = {}
            last_search_text = search_text.v
        end

        if active_tab <= 5 then
            local files = {sms_log_file, announcement_log_file, admin_log_file, all_chat_log_file, faction_log_file}
            local titles = {u8'��������� SMS:', u8'����������:', u8'��������� �������������:', u8'��� ������� ����:', u8'����������� ���:'}
            imgui.Text(titles[active_tab])
            imgui.Separator()

            if not cached_filtered_content[files[active_tab]] or last_search_text ~= search_text.v then
                cached_filtered_content[files[active_tab]] = filter_content(log_contents[files[active_tab]], search_text.v)
            end
            local content = cached_filtered_content[files[active_tab]]

            if not cached_filtered_content.prev_count then
                cached_filtered_content.prev_count = {}
            end
            local prev_count = cached_filtered_content.prev_count[files[active_tab]] or 0
            local current_count = #content
            cached_filtered_content.prev_count[files[active_tab]] = current_count

            if #content == 0 then
                imgui.Text(u8"��� ��������� ��� ������ �� �������")
            else
                imgui.PushFont(log_font)
                local item_height = imgui.CalcTextSize("A").y + 6
                imgui.PopFont()

                local clipper = imgui.ImGuiListClipper(#content, item_height)
                local scroll_to_bottom = should_scroll_to_bottom
                local scroll_y = imgui.GetScrollY()
                local max_scroll_y = imgui.GetScrollMaxY()
                local was_at_bottom = scroll_y >= max_scroll_y - item_height

                while clipper:Step() do
                    for i = clipper.DisplayStart + 1, clipper.DisplayEnd do
                        draw_colored_text(content[i])
                    end
                end

                if scroll_to_bottom then
                    imgui.SetScrollHere(1.0)
                elseif was_at_bottom and current_count > prev_count then
                    imgui.SetScrollY(imgui.GetScrollMaxY())
                end
            end
        elseif active_tab == 8 then
            imgui.Text(u8'��������:')
            imgui.Separator()

            if not cached_filtered_content[kills_log_file] or last_search_text ~= search_text.v then
                cached_filtered_content[kills_log_file] = filter_content(log_contents[kills_log_file], search_text.v)
            end
            local content = cached_filtered_content[kills_log_file]

            if not cached_filtered_content.prev_count then
                cached_filtered_content.prev_count = {}
            end
            local prev_count = cached_filtered_content.prev_count[kills_log_file] or 0
            local current_count = #content
            cached_filtered_content.prev_count[kills_log_file] = current_count

            if #content == 0 then
                imgui.Text(u8"��� ������� �� ��������� ��� ������ �� �������")
            else
                imgui.PushFont(log_font)
                local item_height = imgui.CalcTextSize("A").y + 6
                imgui.PopFont()

                local clipper = imgui.ImGuiListClipper(#content, item_height)
                local scroll_to_bottom = should_scroll_to_bottom
                local scroll_y = imgui.GetScrollY()
                local max_scroll_y = imgui.GetScrollMaxY()
                local was_at_bottom = scroll_y >= max_scroll_y - item_height

                while clipper:Step() do
                    for i = clipper.DisplayStart + 1, clipper.DisplayEnd do
                        draw_colored_text(content[i])
                    end
                end

                if scroll_to_bottom then
                    imgui.SetScrollHere(1.0)
                elseif was_at_bottom and current_count > prev_count then
                    imgui.SetScrollY(imgui.GetScrollMaxY())
                end
            end
        elseif active_tab == 6 then
            imgui.Text(u8'������:')
            imgui.Separator()

            if not cached_filtered_content.archive_files then
                cached_filtered_content.archive_files = {}
                for file in io.popen('dir "' .. archive_folder .. '\\*.txt" /b'):lines() do
                    table.insert(cached_filtered_content.archive_files, file)
                end
            end
            local files = cached_filtered_content.archive_files

            if #files > 0 then
                imgui.Text(u8'�������� �����:')
                local changed = imgui.Combo("##ArchiveSelector", selected_archive, files, #files)
                imgui.BeginChild("ArchiveContent", imgui.ImVec2(0, -imgui.GetStyle().ItemSpacing.y), true)
                if selected_archive.v >= 0 and selected_archive.v < #files then
                    local selected_file = files[selected_archive.v + 1]
                    if selected_file ~= current_selected_file then
                        current_selected_file = selected_file
                        local file_path = archive_folder .. "\\" .. selected_file
                        current_archive_content = {}
                        local file = io.open(file_path, "rb")
                        if file then
                            for line in file:lines() do
                                table.insert(current_archive_content, line)
                            end
                            file:close()
                        end
                        cached_filtered_content["archive"] = nil
                    end

                    if not cached_filtered_content["archive"] or last_search_text ~= search_text.v then
                        cached_filtered_content["archive"] = filter_content(current_archive_content or {}, search_text.v)
                        last_search_text = search_text.v
                    end
                    local filtered_content = cached_filtered_content["archive"]

                    if not cached_filtered_content.prev_count then
                        cached_filtered_content.prev_count = {}
                    end
                    local prev_count = cached_filtered_content.prev_count["archive"] or 0
                    local current_count = #filtered_content
                    cached_filtered_content.prev_count["archive"] = current_count

                    if #filtered_content == 0 then
                        imgui.Text(u8"��� ��������� � ������ ��� ������ �� �������")
                    else
                        imgui.PushFont(log_font)
                        local item_height = imgui.CalcTextSize("A").y + 6
                        imgui.PopFont()

                        local clipper = imgui.ImGuiListClipper(#filtered_content, item_height)
                        local scroll_to_bottom = should_scroll_to_bottom or changed
                        local scroll_y = imgui.GetScrollY()
                        local max_scroll_y = imgui.GetScrollMaxY()
                        local was_at_bottom = scroll_y >= max_scroll_y - item_height

                        while clipper:Step() do
                            for i = clipper.DisplayStart + 1, clipper.DisplayEnd do
                                draw_colored_text(filtered_content[i])
                            end
                        end
                        if scroll_to_bottom then
                            imgui.SetScrollHere(1.0)
                        elseif was_at_bottom and current_count > prev_count then
                            imgui.SetScrollY(imgui.GetScrollMaxY())
                        end
                    end
                end
                imgui.EndChild()
            else
                imgui.Text(u8'������ �����������.')
            end
        elseif active_tab == 7 then
            imgui.Text(u8'���������:', imgui.ImVec4(0.0, 0.5, 1.0, 1.0))
            imgui.Separator()

            imgui.Text(u8'���������� � �������', imgui.ImVec4(0.0, 0.5, 1.0, 1.0))
            imgui.Checkbox(u8'����������� ����������', block_announcements)
            imgui.SameLine()
            imgui.Checkbox(u8'����������� �������', block_news)
            imgui.TextColored(block_announcements.v and imgui.ImVec4(0.65, 1.0, 0.0, 1.0) or imgui.ImVec4(1.0, 0.15, 0.0, 1.0),
                block_announcements.v and u8'���������� ������' or u8'���������� ������������')
            imgui.SameLine()
            imgui.TextColored(block_news.v and imgui.ImVec4(0.65, 1.0, 0.0, 1.0) or imgui.ImVec4(1.0, 0.15, 0.0, 1.0),
                block_news.v and u8'������� ������' or u8'������� ������������')

            imgui.Text(u8'�������������', imgui.ImVec4(0.0, 0.5, 1.0, 1.0))
            imgui.Checkbox(u8'����������� �����-���������', block_admin_messages)
            imgui.TextColored(block_admin_messages.v and imgui.ImVec4(0.65, 1.0, 0.0, 1.0) or imgui.ImVec4(1.0, 0.15, 0.0, 1.0),
                block_admin_messages.v and u8'�����-��������� ������' or u8'�����-��������� ������������')

            imgui.Text(u8'�������', imgui.ImVec4(0.0, 0.5, 1.0, 1.0))
            imgui.Checkbox(u8'����������� ����������� ���', block_faction_messages)
            if block_faction_messages.v then
                imgui.TextColored(imgui.ImVec4(0.65, 1.0, 0.0, 1.0), u8'����������� ��� �����')
                imgui.Text(u8'�������� ������� ��� ����������:')
                imgui.BeginGroup()
                imgui.Columns(3, "FactionColumns", false)
                local factions = {"������", "������", "�����", "������", "�����", "����", "LCN", "������� �����",
                                  "��������", "�����������", "������", "�����", "�������", "�������", "���", "�����"}
                for i, faction in ipairs(factions) do
                    local key = faction_names[faction]
                    imgui.Checkbox(u8(faction), faction_settings[key].block)
                    if i % 6 == 0 then imgui.NextColumn() end
                end
                imgui.Columns(1)
                imgui.EndGroup()
                if imgui.Button(u8'����������� ���') then
                    block_all_factions.v = true
                    for _, settings in pairs(faction_settings) do settings.block.v = true end
                end
                imgui.SameLine()
                if imgui.Button(u8'����� ����������') then
                    block_all_factions.v = false
                    for _, settings in pairs(faction_settings) do settings.block.v = false end
                end
            end

            imgui.Text(u8'�������������', imgui.ImVec4(0.0, 0.5, 1.0, 1.0))
            if imgui.Button(u8'������� ������ ������') then blacklist_window_state.v = true end

            imgui.Text(u8'���������', imgui.ImVec4(0.0, 0.5, 1.0, 1.0))
            imgui.Text(u8'�������� �����:')
            imgui.InputInt("##MaxLines", max_lines)

            imgui.Text(u8'�����', imgui.ImVec4(0.0, 0.5, 1.0, 1.0))
            imgui.Text(u8'������ ������ �����:')
            imgui.SliderFloat("##FontSize", font_size, 10.0, 30.0, "%.0f")

            if imgui.Button(u8'��������� ���������') then
                window_pos = imgui.GetWindowPos()
                window_size = imgui.GetWindowSize()
                save_settings()
            end
        end

        if not is_first_run then
            window_pos = imgui.GetWindowPos()
            window_size = imgui.GetWindowSize()
        end
        imgui.EndChild()

        if active_tab ~= 7 then
            imgui.Text(u8"�����:")
            imgui.SameLine()
            imgui.InputText("##Search", search_text, imgui.InputTextFlags.AutoSelectAll)
        end
        imgui.End()
    end

    if blacklist_window_state.v then
        imgui.SetNextWindowSize(imgui.ImVec2(300, 400), imgui.Cond.FirstUseEver)
        imgui.Begin(u8'������ ������ (������ SMS)', blacklist_window_state)

        imgui.Checkbox(u8'�������� ������ ������', blacklist_enabled)
        imgui.TextColored(blacklist_enabled.v and imgui.ImVec4(0.65, 1.0, 0.0, 1.0) or imgui.ImVec4(1.0, 0.15, 0.0, 1.0),
            blacklist_enabled.v and u8'������ ������ ������� (SMS ������)' or u8'������ ������ �������� (SMS ������������)')
        imgui.Checkbox(u8'���������� SMS �� ������� ������ � ���', blacklist_log_enabled)
        imgui.TextColored(blacklist_log_enabled.v and imgui.ImVec4(0.65, 1.0, 0.0, 1.0) or imgui.ImVec4(1.0, 0.15, 0.0, 1.0),
            blacklist_log_enabled.v and u8'SMS �� �� ������������ � ���' or u8'SMS �� �� �� ������������ � ���')

        imgui.Separator()
        imgui.Text(u8'�������� ������ �� ���� ��� ID (0-999):')
        imgui.InputText("##BlacklistNick", blacklist_input_nick)
        imgui.SameLine()
        if imgui.Button(u8'��������') then
            addToBlacklist(blacklist_input_nick.v)
            blacklist_input_nick.v = ""
        end

        if next(blacklist) then
            imgui.Text(u8'������ ���������������:')
            imgui.BeginChild("BlacklistScroll", imgui.ImVec2(0, -30), true)
            for nick in pairs(blacklist) do
                imgui.Text(nick)
                imgui.SameLine()
                if imgui.Button(u8'�������##'..nick) then
                    blacklist[nick] = nil
                    sampAddChatMessage("[LogChat] ����� " .. nick .. " ������ �� ������� ������", 0x00FF00)
                    save_settings()
                end
            end
            imgui.EndChild()
        end
        imgui.End()
    end
end