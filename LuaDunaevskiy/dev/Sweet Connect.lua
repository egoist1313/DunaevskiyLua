__name__	= "Sweet Connect"
__version__ = "2.3.8"
__author__	= "Double Tap Inside"
__email__	= "double.tap.inside@gmail.com"


MAIN_TITLE	= "Sweet Connect"
MAIN_CMD	= "scm"

-- ! Добавь шифрование, а то рано или поздно спиздят нахуй у всех акки.
-- ! Сделай блокировку смены никнейма галочкой, возможно.
-- ! Сделай фикс курсора вкл/выкл, возможно.
-- ! У меня вопрос, а нахуя ты делал заточение курсора вместо просто отцентровать его? Наверное были на то причины?

---- Modules -----
require 'lib.moonloader'
require "sampfuncs" -- Constants: RPC, PACKET, GAMESTATE
RPC_CONNECTIONREJECTED = require("lib.samp.raknet").RPC.CONNECTIONREJECTED

sampev				= require "lib.samp.events"
socket				= require "socket"
bit					= require "bit"

sha1 				= require "sha1"
basexx 				= require "basexx"
wm					= require "lib.windows.message"
memory 				= require 'memory'

dlstatus			= require('moonloader').download_status

encoding			= require "encoding"
encoding.default	= "CP1251"
u8					= encoding.UTF8

ffi 				= require 'ffi'

ffi.cdef [[
	typedef unsigned long HANDLE;
    typedef HANDLE HWND;
	typedef unsigned long DWORD;
    typedef int HCURSOR;
    typedef int BOOL;
	
	typedef struct _POINT {
		int x, y;
	} POINT, *PPOINT;
	
	typedef struct _RECT {
        long left;
        long top;
        long right;
        long bottom;
    } RECT, *LPRECT;
	
		
	typedef struct _CURSORINFO {
        DWORD   cbSize, flags;
        HCURSOR hCursor;
        POINT   ptScreenPos;
    } CURSORINFO, *LPCURSORINFO;
	
	
	BOOL SetRect(
	  LPRECT lprc,
	  int    xLeft,
	  int    yTop,
	  int    xRight,
	  int    yBottom
	);
	
	BOOL ClientToScreen(
		HWND    hWnd,
		PPOINT lpPoint
	);

    BOOL GetCursorInfo(LPCURSORINFO);
	
	HWND GetForegroundWindow(void);
    HWND GetActiveWindow(void);

	BOOL GetClientRect(
		HWND   hWnd,
		LPRECT lpRect
	);
	
	BOOL ClipCursor(const RECT *lpRect);
	
	bool SetCursorPos(int X, int Y);
]]


ci = ffi.new('CURSORINFO[1]')
ci[0].cbSize = ffi.sizeof('CURSORINFO')



imgui				= require "imgui"
imgui.EditedItem 	= {}
local function my_unpack(tbl)
    if type(tbl) ~= "table" then return nil end
    local result = {}
    for i = 1, #tbl do
        result[i] = tbl[i]
    end
    return table.concat(result, ",") -- Или другой способ обработки
end

function imgui.ButtonActivated(activated, ...)
	if activated then
		imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.TextSelectedBg])
		imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.GetStyle().Colors[imgui.Col.TextSelectedBg])
		imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.GetStyle().Colors[imgui.Col.TextSelectedBg])
		
			imgui.Button(...)
			
		imgui.PopStyleColor()
		imgui.PopStyleColor()
		imgui.PopStyleColor()
		
	else
		return imgui.Button(...)			
	end
end

function imgui.TextColoredRGB(text)
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end

    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImColor(r, g, b, a):GetVec4()
    end

    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], text[i])
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else imgui.Text(w) end
        end
    end

    render_text(text)
end




function imgui.TextQuestion(label, description)
    imgui.TextDisabled(label)
	
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
			imgui.PushTextWrapPos(600)
				imgui.TextUnformatted(description)
			imgui.PopTextWrapPos()
        imgui.EndTooltip()
    end
end

--[[
function imgui.Link(label, text)
	
	local size = imgui.CalcTextSize(label)
	
	local pos = imgui.GetCursorPos()
	
	imgui.InvisibleButton(label, imgui.ImVec2(size.x, size.y) )
	
	imgui.SameLine()
	
	imgui.SetCursorPos(pos)
	
	if imgui.IsItemHovered() then
	
		if text then
			imgui.BeginTooltip()
			imgui.PushTextWrapPos(600)
			imgui.TextUnformatted(text)
			imgui.PopTextWrapPos()
			imgui.EndTooltip()
		
		end
		
		imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.00, 0.60, 1.00, 1.00))
			imgui.Text(label)
		imgui.PopStyleColor()
		
		if imgui.IsMouseClicked(0) then
			return true
			
		end
		
	else
		imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.00, 0.45, 1.00, 1.00))
			imgui.Text(label)
		imgui.PopStyleColor()
		
	end
	
end
--]]

function imgui.Link(label, description)

    local size = imgui.CalcTextSize(label)
    local p = imgui.GetCursorScreenPos()
    local p2 = imgui.GetCursorPos()
    local result = imgui.InvisibleButton(label, size)
    
    imgui.SetCursorPos(p2)
	
    if imgui.IsItemHovered() then
		if description then
			imgui.BeginTooltip()
			imgui.PushTextWrapPos(600)
			imgui.TextUnformatted(description)
			imgui.PopTextWrapPos()
			imgui.EndTooltip()
		
		end
	
        imgui.TextColored(imgui.GetStyle().Colors[imgui.Col.CheckMark], label)
        imgui.GetWindowDrawList():AddLine(imgui.ImVec2(p.x, p.y + size.y), imgui.ImVec2(p.x + size.x, p.y + size.y), imgui.GetColorU32(imgui.GetStyle().Colors[imgui.Col.CheckMark]))
		
    else
        imgui.TextColored(imgui.GetStyle().Colors[imgui.Col.CheckMark], label)
    end
	
    return result
end

-- Целое число
imgui.InputIntEx = {
	_edited_item = {}
}
setmetatable(imgui.InputIntEx, {__call = function(self, str_id, ...)
	local result = imgui.InputInt(str_id, ...)
	
	
	if result then
		imgui.InputIntEx._edited_item[str_id] = true
	end
	
	if not imgui.IsItemActive() and imgui.InputIntEx._edited_item[str_id] then
		imgui.InputIntEx._edited_item[str_id] = nil
		
		return true
		
	end
end})



-- Имгуи холдер
im = {}
setmetatable(im, {__call = function(self, str_id, func, ...)
	if im[str_id] then
		return im[str_id]
		
	else
		im[str_id] = func(...)
		return im[str_id]
	end
end})


function imgui.ButtonActive(...)
	imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.CloseButtonActive])
	imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.GetStyle().Colors[imgui.Col.CloseButtonActive])
	imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.GetStyle().Colors[imgui.Col.CloseButtonActive])
		local result = imgui.Button(...)
	
	imgui.PopStyleColor()
	imgui.PopStyleColor()
	imgui.PopStyleColor()
		
	return result
	
end


function imgui.ButtonDisabled(...)
	local r, g, b, a = imgui.ImColor(imgui.GetStyle().Colors[imgui.Col.Button]):GetFloat4() 
	
	imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(r, g, b, a/2) )
	imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(r, g, b, a/2))
	imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(r, g, b, a/2))
	imgui.PushStyleColor(imgui.Col.Text, imgui.GetStyle().Colors[imgui.Col.TextDisabled])

		local result = imgui.Button(...)
	
	imgui.PopStyleColor()
	imgui.PopStyleColor()
	imgui.PopStyleColor()
	imgui.PopStyleColor()
		
	return result
end

function imgui.ButtonGreen(...)
	imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0, .4, 0, 1))
	imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0, .50, 0, 1))
	imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0, .50, 0, 1))
	
		local result = imgui.Button(...)
	
	imgui.PopStyleColor()
	imgui.PopStyleColor()
	imgui.PopStyleColor()
		
	return result
end


-- Стиль
function apply_custom_style()
	-- v6
 
	imgui.SwitchContext()
	local style = imgui.GetStyle()
	local colors = style.Colors
	local clr = imgui.Col
	local ImVec4 = imgui.ImVec4
	local ImVec2 = imgui.ImVec2

   
	--style.WindowPadding = ImVec2(5, 5) -- это
	--style.FramePadding = ImVec2(5, 5)
	style.WindowRounding = 4.0
	style.WindowTitleAlign = imgui.ImVec2(0.5, 0.84)
	style.ChildWindowRounding = 2.0
	style.FrameRounding = 4.0
	style.ItemSpacing = imgui.ImVec2(10.0, 10.0)
	--style.ItemInnerSpacing = ImVec2(8, 6)
	--style.IndentSpacing = 25.0
	style.ScrollbarSize = 18.0
	style.ScrollbarRounding = 0
	style.GrabMinSize = 8.0
	style.GrabRounding = 1.0

	colors[clr.Text] = ImVec4(0.95, 0.96, 0.98, 1.00)
	colors[clr.TextDisabled] = ImVec4(0.50, 0.50, 0.50, 1.00)

	colors[clr.TitleBgActive] = ImVec4(0.07, 0.11, 0.13, 1.00) --ImVec4(0.08, 0.10, 0.12, 0.90)
	colors[clr.TitleBg] = colors[clr.TitleBgActive]
	colors[clr.TitleBgCollapsed] = ImVec4(0.00, 0.00, 0.00, 0.51)

	colors[clr.WindowBg]		= colors[clr.TitleBgActive]
	colors[clr.ChildWindowBg] = ImVec4(0.07, 0.11, 0.13, 1.00)

	colors[clr.PopupBg] = ImVec4(0.08, 0.08, 0.08, 1.00)
	colors[clr.Border] = ImVec4(0.43, 0.43, 0.50, 0.50)
	colors[clr.BorderShadow] = ImVec4(0.00, 0.00, 0.00, 0.00)
	
	 
	colors[clr.Separator] = colors[clr.Border]
	colors[clr.SeparatorHovered] = colors[clr.Border]
	colors[clr.SeparatorActive] = colors[clr.Border]

	colors[clr.MenuBarBg] = ImVec4(0.15, 0.18, 0.22, 1.00)

	colors[clr.CheckMark] = ImVec4(0.00, 0.50, 0.50, 1.00)

	colors[clr.SliderGrab] = ImVec4(0.28, 0.56, 1.00, 1.00)
	colors[clr.SliderGrabActive] = ImVec4(0.37, 0.61, 1.00, 1.00)

	colors[clr.Button] = ImVec4(0.15, 0.20, 0.24, 1.00)
	colors[clr.ButtonHovered] = ImVec4(0.20, 0.25, 0.29, 1.00)
	colors[clr.ButtonActive] = colors[clr.ButtonHovered]

	colors[clr.ScrollbarBg] = ImVec4(0.02, 0.02, 0.02, 0.39)
	colors[clr.ScrollbarGrab] = colors[clr.Button]
	colors[clr.ScrollbarGrabHovered] = colors[clr.ButtonHovered]
	colors[clr.ScrollbarGrabActive] = colors[clr.ButtonHovered]

	colors[clr.FrameBg] = colors[clr.Button]
	colors[clr.FrameBgHovered] = colors[clr.ButtonHovered]
	colors[clr.FrameBgActive] = colors[clr.ButtonHovered]

	colors[clr.ComboBg] = ImVec4(0.35, 0.35, 0.35, 1.00)

	colors[clr.Header] = colors[clr.Button]
	colors[clr.HeaderHovered] = colors[clr.ButtonHovered]
	colors[clr.HeaderActive] = colors[clr.HeaderHovered]

	colors[clr.ResizeGrip] = ImVec4(0.26, 0.59, 0.98, 0.25)
	colors[clr.ResizeGripHovered] = ImVec4(0.26, 0.59, 0.98, 0.67)
	colors[clr.ResizeGripActive] = ImVec4(0.06, 0.05, 0.07, 1.00)

	colors[clr.CloseButton] = ImVec4(0.40, 0.39, 0.38, 0.16)
	colors[clr.CloseButtonHovered] = imgui.ImVec4(0.50, 0.25, 0.00, 1.00)
	colors[clr.CloseButtonActive] = colors[clr.CloseButtonHovered]

	colors[clr.PlotLines] = ImVec4(0.61, 0.61, 0.61, 1.00)
	colors[clr.PlotLinesHovered] = ImVec4(1.00, 0.43, 0.35, 1.00)

	colors[clr.PlotHistogram] = ImVec4(0.90, 0.70, 0.00, 1.00)
	colors[clr.PlotHistogramHovered] = ImVec4(1.00, 0.60, 0.00, 1.00)

	colors[clr.TextSelectedBg] = colors[clr.CloseButtonHovered]

	colors[clr.ModalWindowDarkening] = ImVec4(1.00, 0.98, 0.95, 0.73)
end


apply_custom_style()




---------------------------------------------------------

-- fix shift bug
memory.fill(0x00531155, 0x90, 5, true)

----------------------------------------------------




Luacfg = {
	--[[
		Version:	2.0.1
		Author:		Double Tap Inside",
		Email:		double.tap.inside@gmail.com
		
		
		Table luacfg			= Luacfg()
		
		Bool result				= luacfg.update(Table original, Table update or Str update_filename,  [Bool rewrite=true])
		Bool result				= luacfg.save(Table updated, Str filename)
				
		nil						= luacfg.mkpath(Str filename)
		Table loaded / nil		= luacfg.load(Str filename)
	--]]
}
setmetatable(Luacfg, {
	__call = function(self)
		return self.__init()
	end
})
function Luacfg.__init()
	local self = {}
	
	local lfs = require "lfs"
	local inspect = require "inspect"
	
	function self.mkpath(filename)
	
		assert(type(filename)=="string", ("bad argument #1 to 'mkpath' (string expected, got %s)"):format(type(filename)))
	
		local sep, pStr = package.config:sub(1, 1), ""
		local path = filename:match("(.+"..sep..").+$") or filename
		
		for dir in path:gmatch("[^" .. sep .. "]+") do
			pStr = pStr .. dir .. sep
			lfs.mkdir(pStr)
		end
	end
	
	
	function self.load(filename)
		
		assert(type(filename)=="string", ("bad argument #1 to 'load' (string expected, got %s)"):format(type(filename)))
	
		local file = io.open(filename, "r")
		
		if file then 	
			local text = file:read("*all")
			file:close()
			local lua_code = loadstring("return "..text)
			
			if lua_code then
				local result = lua_code()
				
				if type(result) == "table" then
					return result
				end
			end
		end
	end
	
	
	function self.save(updated, filename)
		
		assert(type(updated)=="table", ("bad argument #1 to 'save' (table expected, got %s)"):format(type(updated)))
		assert(type(filename)=="string", ("bad argument #2 to 'save' (string expected, got %s)"):format(type(filename)))
	
		self.mkpath(filename)
		local file = io.open(filename, "w+")
		
		if file then
			file:write(inspect(updated))
			file:close()
			
			return true
			
		else
			return false
		end
	end
	
	
	function self.update(original, update, rewrite)
			
		assert(type(original)=="table", ("bad argument #1 to 'update' (table expected, got %s)"):format(type(original)))
		assert(type(update)=="string" or type(update)=="table", ("bad argument #2 to 'update' (string or table expected, got %s)"):format(type(update)))
		assert(type(rewrite)=="boolean" or type(rewrite)=="nil", ("bad argument #1 to 'update' (boolean or nil expected, got %s)"):format(type(rewrite)))
		
		if rewrite == nil then
			rewrite = true
		end
	
		if type(update) == "table" then
			if rewrite then
				for key, value in pairs(update) do
					original[key] = value
				end
				
			else
				for key, value in pairs(update) do
					if not original[key] then
						original[key] = value
					end
				end
			end
			
			return true
			
		elseif type(update) == "string" then
			local loaded = self.load(update)
			
			if loaded then
				if rewrite then
					for key, value in pairs(loaded) do
						original[key] = value
					end
					
				else
					for key, value in pairs(loaded) do
						if not original[key] then
							original[key] = value
						end
					end
				end
				
				return true
			end
		end
		
		return false
	end
	
	return self
end

luacfg = Luacfg()

local HKeys = {
	_version	= "1.0.4",
	_author		= "Double Tap Inside", -- Mod of rkeys and imgui_addons.Hotkey() by DonHomka
	_email		= "double.tap.inside@gmail.com",
	
	--[[
	
	Table hkeys								= HKeys()
	
	Table hotkey_data						= hkeys.register(IntList keycombo, Int press_type, Bool blocked, Func callback, [Args ...])
	Bool result								= hkeys.unregister(Table hotkey_data)
	Bool result								= hkeys.is_registered(Table hotkey_data)
	
	List old_keycombo / nil					= hkeys.ImguiKeyComboEditor(Str str_id, Str str_id2, Table hotkey_data, [Int width=200])
	Str hkeys.ImguiKeyComboEditor_Promt		= "..."
	
	IntList keycombo						= hkeys.get_keycombo(Table hotkey_data)
	StrList keynames 						= hkeys.get_keynames(Table hotkey_data)
		
	Int press_type							= hkeys.get_press_type(Table hotkey_data)
	Bool blocked							= hkeys.get_blocked(Table hotkey_data)
	Func callback, List args				= hkeys.get_callback(Table hotkey_data)
	
	IntList down_keycombo					= hkeys.get_down_keycombo()
	StrList down_keynames				 	= hkeys.get_down_keynames()
	Bool result								= hkeys.is_keycombo_down(IntList keycombo)
	Bool result								= hkeys.is_key_down(Int vkey)

	IntList old_keycombo / nil				= hkeys.set_keycombo(Table hotkey_data, IntList keycombo)
	Int old_press_type / nil				= hkeys.set_press_type(Table hotkey_data, Int press_type)
	Bool old_blocked / nil					= hkeys.set_blocked(Table hotkey_data, Bool blocked)
	Func old_callback, List old_args / nil	= hkeys.set_callback(Table hotkey_data, Func callback, [Args ...])
	
	Str keyname								= hkeys.id_to_name(Int vkey)
	Int vkey								= hkeys.name_to_id(Str keyname, [Bool case_sensitive = false])
	StrList keynames						= hkeys.keycombo_to_keynames(IntList keycombo)
	IntList keycombo						= hkeys.keynames_to_keycombo(StrList keynames)
	
	hkeys.register(...) args:
		
		1. IntList keycombo:
			ID list of virtual keys
		
		2. Int press_type:
			hkeys.DOWN
			hkeys.HOLD (No mouse button support)
			hkeys.UP
			
		3. Bool blocked:
			true - Block a hotkey press from the game or Lua scripts. As well as it possible.
		
		4.Func callback:
			It calls on hotkey press
		
		5. Args:
			Arguments for Func callback
	
	---
	
		Table hotkey_data = {
			keycombo	= IntList keycombo,
			press_type	= Int press_type,	
			blocked		= Bool blocked,		
			callback	= Func callback,	
			args		= List args			
		}
		
	---
	
		Dict hkeys.KEYS = {
			VK_WHEELDOWN = 0x100,
			VK_WHEELUP = 0x101,
			VK_OEM_PERIOD = 0xBE,
			Etc.
		}
		
		Ussage:
			hkeys.VK_WHEELDOWN
			hkeys.KEYS.VK_WHEELDOWN
			
	---
	
		Table hkeys.NAMES = {
			[hkeys.KEYS.VK_WHEELDOWN] = "Wheel Down",
			[hkeys.KEYS.VK_WHEELUP] = "Wheel Up",
			[hkeys.KEYS.VK_OEM_PERIOD] = {'.', '>'},
			Etc.
		}
		
	--]]	
	
	-- ѕри блокеровке DOWN надо ли блокировать с ним и HOLD ?
}
setmetatable(HKeys, {
	__call = function(self)
		return self.__init()
	end
})
function HKeys.__init()
	local self = {}
	
	local vkeys = require 'vkeys'
	local wm = require 'lib.windows.message'
	local bitex = require "bitex"
	
	
	self.VK_WHEELDOWN = 0x100
	self.VK_WHEELUP = 0x101
	
	self.KEYS = {
		VK_WHEELDOWN = self.VK_WHEELDOWN,
		VK_WHEELUP = self.VK_WHEELUP
	}
	
	self.NAMES = {
		[self.KEYS.VK_WHEELDOWN] = "Wheel Down",
		[self.KEYS.VK_WHEELUP] = "Wheel Up",
	}
	
	for key, value in pairs(vkeys) do	
		if key:sub(1, 3) == 'VK_' then
			self.KEYS[key] = value
			self[key] = value
		end
	end
	
	for key, value in pairs(vkeys.key_names) do
		self.NAMES[key] = value
	end
	
	function self.id_to_name(vkey)
		local name = self.NAMES[vkey]
		if type(name) == 'table' then
			return name[1]
		end
		return name
	end
	
	function self.name_to_id(keyname, case_sensitive)
		if not case_sensitive then
			keyname = string.upper(keyname)
		end
		for id, v in pairs(self.NAMES) do
			if type(v) == 'table' then
				for _, v2 in pairs(v) do
					v2 = (case_sensitive) and v2 or string.upper(v2)
					if v2 == keyname then
						return id
					end
				end
			else
				local name = (case_sensitive) and v or string.upper(v)
				if name == keyname then
					return id
				end
			end
		end
	end
	
	
	
	local HK_hotkeys = {}
	local HK_down_keycombo = {}
	local HK_last_down_combokey = nil
	local HK_key_counter = 0
	
	local KE_current_name = nil
	local KE_new_keycombo = nil
	local KE_tick_clock = os.clock()
	local KE_tick_state = true
	local KE_hovered = false
		
	local DOWN_MESSAGES = {
		[wm.WM_KEYDOWN] = true,
		[wm.WM_SYSKEYDOWN] = true,
		[wm.WM_LBUTTONDBLCLK] = true,
		[wm.WM_LBUTTONDOWN] = true,
		[wm.WM_RBUTTONDOWN] = true,
		[wm.WM_MBUTTONDOWN] = true,
		[wm.WM_XBUTTONDOWN] = true,
		[wm.WM_MOUSEWHEEL] = true

	}
	
	local UP_MESSAGES = {
		[wm.WM_KEYUP] = true,
		[wm.WM_SYSKEYUP] = true,
		[wm.WM_LBUTTONDBLCLK] = true,
		[wm.WM_LBUTTONUP] = true,
		[wm.WM_RBUTTONUP] = true,
		[wm.WM_MBUTTONUP] = true,
		[wm.WM_XBUTTONUP] = true,
		[wm.WM_MOUSEWHEEL] = true
	}
	
	local MBUTTON = {
		[wm.WM_LBUTTONDOWN] = self.VK_LBUTTON,
		[wm.WM_LBUTTONUP] = self.VK_LBUTTON,
		[wm.WM_RBUTTONDOWN] = self.VK_RBUTTON,
		[wm.WM_RBUTTONUP] = self.VK_RBUTTON,
		[wm.WM_MBUTTONDOWN] = self.VK_MBUTTON,
		[wm.WM_MBUTTONUP] = self.VK_MBUTTON,
    }
	
	local XBUTTON = {
		self.VK_XBUTTON1,
		self.VK_XBUTTON2
	}
	
	
	local function HIWORD(param)
		return bit.rshift(bit.band(param, 0xffff0000), 16);
	end
	
	
	
	
	
	local function compareKeyCombos(keycombo1, keycombo2)
	
		if #keycombo1 == 0 or keycombo2 == 0 then
			return false
		end
	
        local keycombo1 = {my_unpack(keycombo1)}
        local keycombo2 = {my_unpack(keycombo2)}
    
        local last_key1 = table.remove(keycombo1, #keycombo1)
        local last_key2 = table.remove(keycombo2, #keycombo2)
        
        table.sort(keycombo1)
        table.sort(keycombo2)
    
        table.insert(keycombo1, last_key1)
        table.insert(keycombo2, last_key2)
    
        for index = 1, #keycombo1 do
		
            if keycombo1[index] ~= keycombo2[index] then
                return false
            end
        end
        
        return true
	end
	
	
	local function isDublicateExist(keycombo, press_type)
		
		for index = 1, #HK_hotkeys do
		
			if compareKeyCombos(HK_hotkeys[index].keycombo, keycombo) and HK_hotkeys[index].press_type == press_type then
				return index
			end
		end
	
		return false
	end
	
	
	local function getKeyID(message, wparam, lparam)
		
		if message == wm.WM_XBUTTONDOWN
		or message == wm.WM_XBUTTONUP then
			local btn = HIWORD(wparam)
			
			return XBUTTON[btn]
			
		elseif MBUTTON[message] then
			return MBUTTON[message]
		
		elseif message == wm.WM_MOUSEWHEEL then
			local keystate = bitex.bextract(wparam, 30, 1)
			
			if keystate == 1 then
				return self.VK_WHEELDOWN
			elseif keystate == 0 then
				return self.VK_WHEELUP
			end
		end
		
		local newKeyId = wparam
		local scancode = bitex.bextract(lparam, 16, 8)
		local extend = bitex.bextract(lparam, 24, 1)
	
		if wparam == self.VK_MENU then
		
			if extend == 1 then
				newKeyId = self.VK_RMENU
				
			else
				newKeyId = self.VK_LMENU
			end
			
		elseif wparam == self.VK_SHIFT then
		
			if scancode == 42 then
				newKeyId = self.VK_LSHIFT
				
			elseif scancode == 54 then
				newKeyId = self.VK_RSHIFT
			end
			
		elseif wparam == self.VK_CONTROL then
		
			if extend == 1 then
				newKeyId = self.VK_RCONTROL
				
			else
				newKeyId = self.VK_LCONTROL
			end
		
		end
	   
		return newKeyId
	end
		
		
		
	addEventHandler("onWindowMessage",
		function (message, wparam, lparam)		
	
			if DOWN_MESSAGES[message] then
				local key_id = getKeyID(message, wparam, lparam)
				
				if not HK_down_keycombo[key_id] then
					HK_last_down_combokey = key_id
					HK_key_counter = HK_key_counter + 1
					HK_down_keycombo[key_id] = HK_key_counter
					
					if KE_current_name then
					
						if key_id == self.VK_ESCAPE then
							KE_current_name = nil
						end
						
						consumeWindowMessage(true, true)
						
					else
					
						for index = 1, #HK_hotkeys do
						
							if self.is_keycombo_down(HK_hotkeys[index].keycombo) and HK_hotkeys[index].press_type == self.DOWN then
							
								if HK_hotkeys[index].callback and not (KE_hovered and compareKeyCombos({self.VK_LBUTTON}, HK_down_keycombo)) then
									HK_hotkeys[index].callback(my_unpack(HK_hotkeys[index].args))
								end
								
								if HK_hotkeys[index].blocked then
									consumeWindowMessage(true, true)
								end
							end
						end
					end
					
						
				else
				
					if KE_current_name then
						consumeWindowMessage(true, true)
						
					else
					
						for index = 1, #HK_hotkeys do
						
							if self.is_keycombo_down(HK_hotkeys[index].keycombo) and HK_hotkeys[index].press_type == self.HOLD then
							
								if HK_hotkeys[index].callback and not (KE_hovered and compareKeyCombos({self.VK_LBUTTON}, HK_down_keycombo)) then
									HK_hotkeys[index].callback(my_unpack(HK_hotkeys[index].args))
								end
								
								if HK_hotkeys[index].blocked then
									consumeWindowMessage()
								end
							end
						end
					end
				end
			end
			
			if UP_MESSAGES[message] then
				local key_id = getKeyID(message, wparam, lparam)
				
				HK_last_down_combokey = key_id
				HK_key_counter = HK_key_counter + 1
				HK_down_keycombo[key_id] = HK_key_counter
				
				if HK_down_keycombo[key_id] then
					
					if KE_current_name then
						KE_new_keycombo = self.get_down_keycombo()
						consumeWindowMessage(true, true)
						
					else
					
						for index = 1, #HK_hotkeys do
						
							if self.is_keycombo_down(HK_hotkeys[index].keycombo) and HK_hotkeys[index].press_type == self.UP then
							
								if HK_hotkeys[index].callback and not (KE_hovered and compareKeyCombos({self.VK_LBUTTON}, HK_down_keycombo)) then
									HK_hotkeys[index].callback(my_unpack(HK_hotkeys[index].args))
								end
								
								if HK_hotkeys[index].blocked then
									consumeWindowMessage()
								end
							end
						end
					end
				end
				
				HK_last_down_combokey = nil
				HK_down_keycombo[key_id] = nil
				
				if not next(HK_down_keycombo) then
					HK_key_counter = 0
				end
			end
			
			if message == wm.WM_CHAR then
				
				if KE_current_name then
					consumeWindowMessage(true, true)
					
				else
				
					for index = 1, #HK_hotkeys do
					
						if self.is_keycombo_down(HK_hotkeys[index].keycombo) and (HK_hotkeys[index].press_type == self.DOWN or HK_hotkeys[index].press_type == self.UP or HK_hotkeys[index].press_type == self.HOLD) then
						
							if HK_hotkeys[index].blocked then
								consumeWindowMessage()
							end
						end
					end
				end
			end 
			
			if message == wm.WM_KILLFOCUS then
				HK_last_down_combokey = nil
				HK_down_keycombo = {}
				HK_key_counter = 0
				KE_new_keycombo = nil
				KE_current_name = nil
				KE_tick_clock = os.clock()
				KE_tick_state = true
			end
		end
	)
	
	--------------------------------------
	
	self.DOWN = 1
	self.HOLD = 2
	self.UP = 3
	self.ImguiKeyComboEditor_Promt = "..."
		
		
	function self.register(keycombo, press_type, blocked, callback, ...)
	
		assert(type(keycombo)=="table", ("bad argument #1 to 'register' (table expected, got %s)"):format(type(keycombo)))
		assert(type(press_type)=="number", ("bad argument #2 to 'register' (number expected, got %s)"):format(type(press_type)))
		assert(type(blocked)=="boolean" or not blocked, ("bad argument #3 to 'register' (bool expected, got %s)"):format(type(blocked)))
		assert(type(callback)=="function", ("bad argument #4 to 'register' (function expected, got %s)"):format(type(callback)))
				
		local hotkey_data = {
			keycombo = {my_unpack(keycombo)},
			press_type = press_type,
			blocked = blocked,
			callback = callback,
			args = {...}
		}
		
		-- clear a duplicate
		local index = isDublicateExist(keycombo, hotkey_data.press_type)
		if index then
			HK_hotkeys[index].keycombo = {}
		end
		
		table.insert(HK_hotkeys, hotkey_data)
		
		return hotkey_data
	end
	
	
	function self.is_registered(hotkey_data)
	
		assert(type(hotkey_data)=="table", ("bad argument #1 to 'set_keycombo' (table expected, got %s)"):format(type(hotkey_data)))
	
		for index = 1, #HK_hotkeys do
		
			if HK_hotkeys[index] == hotkey_data then
				return true
			end
		end
		
		return false
	end
	
	
	function self.is_keycombo_down(keycombo)
		assert(type(keycombo)=="table", ("bad argument #1 to 'is_keycombo_down' (table expected, got %s)"):format(type(keycombo)))
		
		if HK_last_down_combokey ~= keycombo[#keycombo] then
			return false
		end
		
		for index = 1, #keycombo do
			local l_key
			local r_key
			
			if keycombo[index] == self.VK_MENU then
				l_key = self.VK_LMENU
				r_key = self.VK_RMENU
				
			elseif keycombo[index] == self.VK_SHIFT then
				l_key = self.VK_LSHIFT
				r_key = self.VK_RSHIFT
				
			elseif keycombo[index] == self.VK_CONTROL then
				l_key = self.VK_LCONTROL
				r_key = self.VK_RCONTROL
			end
			
			if l_key and r_key then
			
				if not HK_down_keycombo[l_key] and not HK_down_keycombo[r_key] then
					return false
				end
				
			else
			
				if not HK_down_keycombo[keycombo[index]] then
					return false
				end
			end
		end

		return true
	end
	
	function self.is_key_down(vkey)
		assert(type(vkey)=="number", ("bad argument #1 to 'is_key_down' (table expected, got %s)"):format(type(vkey)))
		
		local l_key
		local r_key
		
		if vkey == self.VK_MENU then
			l_key = self.VK_LMENU
			r_key = self.VK_RMENU
			
		elseif vkey == self.VK_SHIFT then
			l_key = self.VK_LSHIFT
			r_key = self.VK_RSHIFT
			
		elseif vkey == self.VK_CONTROL then
			l_key = self.VK_LCONTROL
			r_key = self.VK_RCONTROL
		end
		
		if l_key and r_key then
		
			if not HK_down_keycombo[l_key] and not HK_down_keycombo[r_key] then
				return false
			end
			
		else
		
			if not HK_down_keycombo[vkey] then
				return false
			end
		end


		return true
	end
	
	
	function self.set_keycombo(hotkey_data, keycombo)
	
		assert(type(hotkey_data)=="table", ("bad argument #1 to 'set_keycombo' (table expected, got %s)"):format(type(hotkey_data)))
		assert(type(keycombo)=="table", ("bad argument #2 to 'set_keycombo' (table expected, got %s)"):format(type(keycombo)))
		
		-- clear a duplicate
		local index = isDublicateExist(keycombo, hotkey_data.press_type)
		if index then
			HK_hotkeys[index].keycombo = {}
		end
		
		if self.is_registered(hotkey_data) then
			local old_keycombo = {my_unpack(hotkey_data.keycombo)}
			hotkey_data.keycombo = {my_unpack(keycombo)}
			return old_keycombo
		end
	end
	
	
	
	function self.set_press_type(hotkey_data, press_type)
	
		assert(type(hotkey_data)=="table", ("bad argument #1 to 'set_press_type' (table expected, got %s)"):format(type(hotkey_data)))
		assert(type(press_type)=="number", ("bad argument #2 to 'set_press_type' (table expected, got %s)"):format(type(press_type)))
		
		-- clear a duplicate
		local index = isDublicateExist(hotkey_data.keycombo, press_type)
		
		if index then
			HK_hotkeys[index].keycombo = {}
		end
		
		if self.is_registered(hotkey_data) then
			local old_press_type = hotkey_data.press_type
			hotkey_data.press_type = press_type
			
			return old_press_type
		end		
	end
	
	
	function self.set_blocked(hotkey_data, blocked)
	
		assert(type(hotkey_data)=="table", ("bad argument #1 to 'set_blocked' (table expected, got %s)"):format(type(hotkey_data)))
		assert(type(blocked)=="boolean", ("bad argument #2 to 'set_blocked' (boolean expected, got %s)"):format(type(blocked)))
		
		if self.is_registered(hotkey_data) then
			local old_blocked = hotkey_data.blocked
			hotkey_data.blocked = blocked
			
			return old_blocked
		end	
	end
	
	
	function self.set_callback(hotkey_data, callback, ...)
	
		assert(type(hotkey_data)=="table", ("bad argument #1 to 'set_callback' (table expected, got %s)"):format(type(hotkey_data)))
		assert(type(callback)=="function" or not callback, ("bad argument #2 to 'set_callback' (function expected, got %s)"):format(type(callback)))
		
		if self.is_registered(hotkey_data) then
			local old_callback = hotkey_data.callback
			local old_args = {my_unpack(hotkey_data.args)}
			hotkey_data.callback = callback
			hotkey_data.args = {...}
			
			return old_callback, old_args
		end
	end
	
	
	function self.get_keycombo(hotkey_data)
	
		assert(type(hotkey_data)=="table", ("bad argument #1 to 'set_callback' (table expected, got %s)"):format(type(hotkey_data)))
	
		return {my_unpack(hotkey_data.keycombo)}
	end
	
	
	function self.get_keynames(hotkey_data)
	
		assert(type(hotkey_data)=="table", ("bad argument #1 to 'get_keynames' (table expected, got %s)"):format(type(hotkey_data)))
		
		return self.keycombo_to_keynames({my_unpack(hotkey_data.keycombo)})
	end
	
	
	
	function self.get_press_type(hotkey_data)
	
		assert(type(hotkey_data)=="table", ("bad argument #1 to 'get_press_type' (table expected, got %s)"):format(type(hotkey_data)))
		
		return hotkey_data.press_type
	end
	
	
	
	function self.get_blocked(hotkey_data)
	
		assert(type(hotkey_data)=="table", ("bad argument #1 to 'get_blocked' (table expected, got %s)"):format(type(hotkey_data)))
		
		return hotkey_data.blocked
	end
	
	
	
	function self.get_callback(hotkey_data)
	
		assert(type(hotkey_data)=="table", ("bad argument #1 to 'get_callback' (table expected, got %s)"):format(type(hotkey_data)))
				
		return hotkey_data.get_callback, {my_unpack(hotkey_data.args)}
	end
	
	
	
	function self.unregister(hotkey_data)
	
		assert(type(hotkey_data)=="table", ("bad argument #1 to 'unregister' (table expected, got %s)"):format(type(hotkey_data)))
		
		if self.is_registered(hotkey_data) then
			table.remove(HK_hotkeys, index)
			
			return true
			
		else
			return false
		end
	end
	
	
	function self.get_down_keycombo()
		local keys = {}
		
		for key, value in pairs(HK_down_keycombo) do
			table.insert(keys, key)
		end

		table.sort(keys,
			function(a, b)
			
				if HK_down_keycombo[a] < HK_down_keycombo[b] then
					return true
				end
			end
		)
		
		return keys
	end
	
	
	function self.get_down_keynames()
		local keys = self.get_down_keycombo()
		local names = self.keycombo_to_keynames(keys)
		
		return names
	end
	
	
	function self.keycombo_to_keynames(keys)
		local names = {}
		
		for index = 1, #keys do
			table.insert(names, self.id_to_name(keys[index]))
		end
		
		return names
	end
	
	
	function self.keynames_to_keycombo(names)
		local keys = {}
		
		for index = 1, #names do
			table.insert(keys, self.name_to_id(names[index]))
		end
		
		return keys
	end
	
	
	
	--------------- ImguiKeyComboEditor -----------------
	
	function self.ImguiKeyComboEditor(str_id, str_id2, hotkey_data, width)
	
		assert(type(str_id)=="string" or not str_id, ("bad argument #1 to 'ImguiKeyComboEditor' (string expected, got %s)"):format(type(str_id)))
		assert(type(str_id2)=="string" or not str_id2, ("bad argument #2 to 'ImguiKeyComboEditor' (string expected, got %s)"):format(type(str_id2)))
		assert(type(hotkey_data)=="table", ("bad argument #3 to 'ImguiKeyComboEditor' (table expected, got %s)"):format(type(hotkey_data)))
		assert(type(width)=="number" or not width, ("bad argument #4 to 'ImguiKeyComboEditor' (number expected, got %s)"):format(type(width)))
	
		local imgui = require "imgui"
		local width = width or 200
		local width2 = 22
		
		if width == 0 then
			width2 = 0
		end
		
		local sKeys
			
		if (KE_current_name == str_id) and not KE_new_keycombo then
			local current_names = self.get_down_keynames()
			
			if #current_names ~= 0 then
				sKeys = table.concat(self.get_down_keynames(), " + ")
				
			else
			
				if (os.clock()-KE_tick_clock) > 0.4 then
					KE_tick_clock = os.clock()
					KE_tick_state = not KE_tick_state
				end
				
				sKeys =  (KE_tick_state and self.ImguiKeyComboEditor_Promt) or " "
			end
		
		elseif (KE_current_name == str_id) and KE_new_keycombo then
			sKeys = table.concat(self.keycombo_to_keynames(KE_new_keycombo), " + ")
			
		else
			sKeys = table.concat(self.keycombo_to_keynames(hotkey_data.keycombo), " + ")
		end
		
		imgui.PushStyleVar(imgui.StyleVar.ItemSpacing, imgui.ImVec2(2, 0))
		
			imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
			imgui.PushStyleVar(imgui.StyleVar.ButtonTextAlign, imgui.ImVec2(0, 0))
			
				if imgui.Button(sKeys..str_id, imgui.ImVec2(width- width2, 0)) then
					if not KE_current_name then
						KE_new_keycombo = nil
						KE_tick_clock = os.clock()
						KE_tick_state = true
						KE_current_name = str_id
					end
				end
				
				if imgui.IsItemHovered() then
				
					if KE_hovered ~= str_id then
						KE_hovered = str_id
					end
					
				elseif KE_hovered == str_id then
					KE_hovered = nil
				end
				
	
			
			imgui.PopStyleColor()
			imgui.PopStyleVar()
		
			imgui.SameLine()
		
		imgui.PopStyleVar()
		
		local clear = imgui.Button("X"..str_id2, imgui.ImVec2(20, 20))
		
		if imgui.IsItemHovered() then
				
			if KE_hovered ~= "X"..str_id2 then
				KE_hovered = "X"..str_id2
			end
			
		elseif KE_hovered == "X"..str_id2 then
			KE_hovered = nil
		end
		
		--[[
		if str_id then
			imgui.SameLine()
			imgui.Text(str_id)
		end
		--]]
		
		if clear then
			KE_current_name = nil
			return self.set_keycombo(hotkey_data, {})
		end
		
		if (KE_current_name == str_id) and KE_new_keycombo then
			KE_current_name = nil

			return self.set_keycombo(hotkey_data, KE_new_keycombo)	
		end
	end
		
	
	return self
end



hkeys = HKeys()


----- Paths and filenames -----

path_resources		= getWorkingDirectory().."\\config\\"..__name__
filename_update		= path_resources.."\\update.txt"
filename_cfg		= path_resources.."\\cfg.txt"
filename_servers	= path_resources.."\\servers.txt"


----- Globals -----

-- Update checker
upd_version = nil
upd_url = nil
upd_description = nil

current_moving_server = nil
current_moving_login = nil
user_title = nil
gauth_key = nil
use_gauth = nil

reconnecting_text = nil
sc_thread = nil
start_connecting = nil

-- imgui window
imw_menu = imgui.ImBool(false)
pos_menu = nil

imw_saving = imgui.ImBool(false)
pos_saving = nil

imw_save_button = imgui.ImBool(false)
imw_reconnecting = imgui.ImBool(false)
imw_notif = imgui.ImBool(false)
notif_clock = nil


IS_WINDOW_ACTIVE = true
IS_CURSOR_BLOCKED = true

-- settings

LANG_ENG = {
	LABEL								= u8"English",
	
	-- Hello
	HELLO_MENU							= "Menu",
	HELLO_NEW_VERSION					= "New version",
	HELLO_SAVED							= "The dialog response was saved",
	HELLO_DISCONNECTED					= "You closed connection",
	
	-- Top
	TAB_SETTINGS						= u8"Settings",
	TAB_SETTINGS_RECONNECT				= u8"Reconnect",
	TAB_ACCOUNTS						= u8"Accounts",
	ADD_CURRENT_DIALOG					= u8"Save the dialog response",
	TAB_SETTINGS_AUTORESPONSE			= u8"Dialog response",
	TAB_SETTINGS_OTHER					= u8"Other",
	TAB_SETTINGS_INFO					= u8"About",
	
	
	-- Settings
	SETTINGS_RESTART_REQUIRED			= u8"Game restart required",
	SETTINGS_FIX_INTERIOR_BUG			= u8"Fix mirror interior bug with anti-AFK",
	SETTINGS_HELLO						= u8"Show notifications in chat",
	SETTINGS_NOTIF						= u8"Show pop-up notifications",
	SETTINGS_SAVE_BUTTON				= u8"Show green button to save dialog response",
	SETTINGS_AUTORECONNECT				= u8"Auto reconnect",
	SETTINGS_SC_TIMEOUT					= u8"Reconnect timeout (sec)",
	SETTINGS_DISCONNECT_TIMEOUT			= u8"Disconnect timeout (sec)",
	SETTINGS_BANNED_IP_TIMEOUT			= u8"Banned IP timeot (sec)",
	SETTINGS_LOST_CONNECTION_TIMEOUT	= u8"Lost connection timeout (sec)",
	
	SETTINGS_AUTORESPONSE				= u8"Auto dialog response",
	SETTINGS_AUTORESPONSE_DELAY			= u8"Delay of auto dialog response (ms)",
	SETTINGS_FASTCONNECT				= u8"Fast connect",
	SETTINGS_WIB						= u8"Anti-AFK",
	SETTINGS_PAUSE						= u8"No auto reconnect",
	SETTINGS_PAUSE_TIME					= u8"Time range",
	SETTINGS_RECONNECT					= u8"-    Reconnect",
	SETTINGS_DISCONNECT					= u8"-    Disconnect",
	SETTINGS_MENU						= u8"-    Menu",
	SETTINGS_COMMANDS					= u8"Commands",
	SETTINGS_CONNECTING_TIMEOUT			= u8"Connecting timeout (ms)",
	SETTINGS_RECONNECTING_WINDOW		= u8"Show reconnecting window",
	SETTINGS_MENU_CHEAT					= u8"-    Use like a cheat code",
	
	NOTIF_WIB_OFF						= u8"Anti-AFK: Disabled",
	NOTIF_WIB_ON						= u8"Anti-AFK: Enabled",
	NOTIF_AUTO_RESPONSE					= u8"Auto-response",
	
	
	HOTKEY_AND_CMD						= u8"Hotkeys",
	HOTKEY_RECONNECT					= u8"Reconnect in %s sec",
	HOTKEY_DISCONNECT_NOW				= u8"Disconnect",
	HOTKEY_MENU							= u8"Open the menu",
	HOTKEY_WIB							= u8"Anti-AFK",
	HOTKEY_CMDS							= u8"Script commands",
	
	NEW_NICKNAME						= u8"Nickname",
	NEW_IP								= u8"IP:PORT",
	NEW_PORT							= u8"Port",
	NEW_PASTE_CURRENT_NICKNAME			= u8"Current",
	NEW_PASTE_CURRENT_IP_PORT			= u8"Current",
	NEW_CONNECT							= u8"Connect",
	NEW_ACCOUNT							= u8"Connect as...",
	AUTHOR								= u8"Author: ",
	VERSION								= u8"Version: ",
	DOWNLOAD_NEW_VERSION				= u8"Download the new version ",
	EMAIL								= u8"Email: ",
	
	
	-- Dialog list
	CHECK_DIALOG_TITLE					= u8"Define the dialog by its title",
	CHECK_DIALOG_ID						= u8"Define the dialog by its ID",
	CHECK_DIALOG_CONTENT				= u8"Define the dialog by its content",
	DETAILS 							= u8"Details",
	DELETE_DIALOG						= u8" X ",
	CONNECT								= u8"Connect",
	
	-- Dialog details
	RESPONSE_TEXT						= u8"Send a text: ",
	RESPONSE_INDEX						= u8"Send an item index: ",
	RESPONSE_BUTTON						= u8"Send a button: ",
		
	DIALOG_TITLE						= u8"The dialog title: ",
	DIALOG_ID							= u8"The dialog ID: ",
	DIALOG_STYLE						= u8"The dialog style: ",
	DIALOG_TEXT							= u8"The dialog text:",
	GAUTH_KEY							= u8"Google Authenticator key",
		
	-- Server info
	SERVER_NAME							= u8"Server name",
	SERVER_IP							= u8"IP:PORT",
	SERVER_PORT							= u8"Port",
	SERVER_USE_TIMEOUTS					= u8"Use the server timeouts",
	SERVER_SC_TIMEOUT					= u8"Reconnect timeout (sec): /sc",
	SERVER_DISCONNECT_TIMEOUT			= u8"Disconnect timeout (sec)",
	SERVER_BANNED_IP_TIMEOUT			= u8"Banned IP timeot (sec)",
	SERVER_LOST_CONNECTION_TIMEOUT		= u8"Lost connection timeout (sec)",
	
	SERVER_CHANGE_NICKNAME				= u8"Connect with another nickname",
	
	-- Saving window
	SAVING_TITLE						= u8"Saving",
	SAVING_CHECK_DIALOG_CONTENT			= u8"Define the dialog by its content",
	SAVING_CHECK_DIALOG_TITLE			= u8"Define the dialog by its title",
	SAVING_CHECK_DIALOG_ID				= u8"Define the dialog by its ID",
	SAVING_USER_TITLE					= u8"Label",
	SAVING_GAUTH						= u8"Google Authenticator Key",
	SAVING_SPAWN_PLAYER					= u8"Spawn player (ms)",
	
	-- Reconnecting Window
	RECONNECT_IN						= u8"Reconnect in ",
	CONNECT								= u8"Connect",
	CANCEL								= u8"Cancel",
	
	

}

LANG_RUS = {
	LABEL								= u8"Русский",
	
	-- Hello
	HELLO_MENU							= "Меню",
	HELLO_NEW_VERSION					= "Новая версия",
	HELLO_SAVED							= "Ответ на диалог сохранен",
	HELLO_DISCONNECTED					= "Вы закрыли соединение",
	
	-- Top
	TAB_SETTINGS						= u8"Настройки",
	TAB_ACCOUNTS						= u8"Аккаунты",
	TAB_SETTINGS_RECONNECT				= u8"Переподключение",
	TAB_SETTINGS_AUTORESPONSE			= u8"Ответ на диалоги",
	TAB_SETTINGS_OTHER					= u8"Прочее",
	TAB_SETTINGS_INFO					= u8"О скрипте",
	ADD_CURRENT_DIALOG					= u8"Сохранить ответ на диалог",
	
	
	-- Settings
	SETTINGS_RESTART_REQUIRED			= u8"Требуется перезагрузка игры",
	SETTINGS_FIX_INTERIOR_BUG			= u8"Исправлять баг в зеркальных интерьерах с анти-AFK",
	SETTINGS_HELLO						= u8"Отображать подсказки в чате",
	SETTINGS_SAVE_BUTTON				= u8"Отображать зелёную кнопку добавления диалога",
	SETTINGS_NOTIF						= u8"Отображать всплывающие подсказки",
	SETTINGS_AUTORECONNECT				= u8"Автоматическое переподключение",
	
	SETTINGS_SC_TIMEOUT					= u8"Тайм-аут переподключения командой /sc или горячей клавишей (сек)", --==1
	SETTINGS_DISCONNECT_TIMEOUT			= u8"Тайм-аут при разъединении (сек)",
	SETTINGS_BANNED_IP_TIMEOUT			= u8"Тайм-аут при бане IP (сек)",
	SETTINGS_LOST_CONNECTION_TIMEOUT	= u8"Тайм-аут при потере соединения (сек)",
	
	SETTINGS_AUTORESPONSE				= u8"Автоматический ответ на диалоги",
	SETTINGS_AUTORESPONSE_DELAY			= u8"Задержка перед ответом (мс)",
	SETTINGS_FASTCONNECT				= u8"Фаст коннект",
	SETTINGS_WIB						= u8"Анти-AFK",
	SETTINGS_PAUSE						= u8"Не переподключаться автоматически",
	SETTINGS_PAUSE_TIME					= u8"Время",
	
	SETTINGS_RECONNECT					= u8"-    Переподключиться",
	SETTINGS_DISCONNECT					= u8"-    Отключиться",
	SETTINGS_MENU						= u8"-    Открыть меню",
	SETTINGS_COMMANDS					= u8"Команды",
	SETTINGS_CONNECTING_TIMEOUT			= u8"Тайм-аут на подключение (мс)",
	SETTINGS_RECONNECTING_WINDOW		= u8"Отображать окно переподключения",
	SETTINGS_MENU_CHEAT					= u8"-    Открыть меню (Использовать как чит-код)",
	
	NOTIF_WIB_OFF						= u8"Анти-AFK: Отключен",
	NOTIF_WIB_ON						= u8"Анти-AFK: Включен",
	NOTIF_AUTO_RESPONSE					= u8"Авто-ответ",
	
	HOTKEY_AND_CMD						= u8"Горячие клавиши",
	HOTKEY_RECONNECT					= u8"Переподключиться через %s сек",
	HOTKEY_DISCONNECT_NOW				= u8"Отключиться",
	HOTKEY_MENU							= u8"Открыть меню",
	HOTKEY_WIB							= u8"Анти-AFK",
	HOTKEY_CMDS							= u8"Команды скрипта",
	
	NEW_NICKNAME						= u8"Никнейм",
	NEW_IP								= u8"IP:PORT",
	NEW_PORT							= u8"Порт",
	NEW_PASTE_CURRENT_NICKNAME			= u8"Текущий",
	NEW_PASTE_CURRENT_IP_PORT			= u8"Текущий",
	NEW_CONNECT							= u8"Подключиться",
	NEW_ACCOUNT							= u8"Подключиться как...",
	AUTHOR								= u8"Автор: ",
	VERSION								= u8"Версия: ",
	DOWNLOAD_NEW_VERSION				= u8"Скачать новую версию ",
	EMAIL								= u8"Email: ",
	
	
	-- Dialog list
	CHECK_DIALOG_TITLE					= u8"Определять диалог по заголовку",
	CHECK_DIALOG_ID						= u8"Определять диалог по ID",
	CHECK_DIALOG_CONTENT				= u8"Определять диалог по содержимому",
	DETAILS 							= u8"Подробнее",
	DELETE_DIALOG						= u8" X ",
	CONNECT								= u8"Подключиться",
	
	-- Dialog details
	RESPONSE_TEXT						= u8"Отправить текст",
	RESPONSE_INDEX						= u8"Отправить пункт: ",
	RESPONSE_BUTTON						= u8"Отправить кнопку: ",
	GAUTH_KEY							= u8"Ключ Google Authenticator",
		
	DIALOG_TITLE						= u8"Заголовок диалога: ",
	DIALOG_ID							= u8"ID диалога: ",
	DIALOG_STYLE						= u8"Стиль диалога: ",
	DIALOG_TEXT							= u8"Текст диалога:",
		
	-- Server info
	SERVER_NAME							= u8"Имя сервера",
	SERVER_IP							= u8"IP:PORT",
	SERVER_PORT							= u8"Порт",
	SERVER_USE_TIMEOUTS					= u8"Использовать тайм-ауты сервера",
	SERVER_SC_TIMEOUT					= u8"Тайм-аут переподключения командой /sc или горячей клавишей (сек)", --==2
	SERVER_DISCONNECT_TIMEOUT			= u8"Тайм-аут при разъединении (сек)",
	SERVER_BANNED_IP_TIMEOUT			= u8"Тайм-аут при бане IP (сек)",
	SERVER_LOST_CONNECTION_TIMEOUT		= u8"Тайм-аут при потере соединения (сек)",
	
	SERVER_CHANGE_NICKNAME				= u8"Подключиться под другим никнеймом",
	
	-- Saving window
	SAVING_TITLE						= u8"Сохранение",
	SAVING_CHECK_DIALOG_CONTENT			= u8"Определять диалог по содержимому",
	SAVING_CHECK_DIALOG_TITLE			= u8"Определять диалог по заголовку",
	SAVING_CHECK_DIALOG_ID				= u8"Определять диалог по ID",
	SAVING_USER_TITLE					= u8"Название",
	SAVING_GAUTH						= u8"Ключ Google Authenticator",
	SAVING_SPAWN_PLAYER					= u8"Заспавнить персонажа (ms)",
	
	-- Reconnecting Window
	RECONNECT_IN						= u8"Переподключение через ",
	CONNECT								= u8"Подключиться",
	CANCEL								= u8"Отмена",
	
	

}

LANG_BGR = {
	LABEL								= u8"Български",
	
	-- Hello
	HELLO_MENU							= "Меню",
	HELLO_NEW_VERSION					= "Нова Версия",
	HELLO_SAVED							= "Диалогът беше запазен",
	HELLO_DISCONNECTED					= "Затворихте връзката",
	
	-- Top
	TAB_SETTINGS						= u8"Настройки",
	TAB_ACCOUNTS						= u8"Aкаунти",
	ADD_CURRENT_DIALOG					= u8"Запазете диалоговия отговор",
	
	
	-- Settings
	SETTINGS_HELLO						= u8"Показване на известия в чата",
	--SETTINGS_NOTIF						= u8"Показване на известия на диалога",
	SETTINGS_SAVE_BUTTON				= u8"Покажи зелен бутон за да се запамети диалога",
	SETTINGS_AUTORECONNECT				= u8"Автоматично влизане",
	SETTINGS_SC_TIMEOUT					= u8"Времето за повторно свързване (sec)",
	SETTINGS_DISCONNECT_TIMEOUT			= u8"Оставащо време до прекъсване (sec)",
	SETTINGS_BANNED_IP_TIMEOUT			= u8"Баннато IP (sec)",
	SETTINGS_LOST_CONNECTION_TIMEOUT	= u8"Изгубена връзка (sec)",
	
	SETTINGS_AUTORESPONSE				= u8"Автоматичен отговор на диалога",
	SETTINGS_AUTORESPONSE_DELAY			= u8"Забавяне на автоматическия диалог (ms)",
	SETTINGS_FASTCONNECT				= u8"Бързо свързане",
	SETTINGS_WIB						= u8"Anti-AFK",
	SETTINGS_PAUSE						= u8"Няма повторно влизане",
	SETTINGS_PAUSE_TIME					= u8"Времеви Интервал",
	SETTINGS_RECONNECT					= u8"-    Повторно влизане",
	SETTINGS_DISCONNECT					= u8"-    Излизане",
	SETTINGS_MENU						= u8"-    Меню",
	SETTINGS_COMMANDS					= u8"Команди",

	
	
	HOTKEY_AND_CMD						= u8"Бутони",
	HOTKEY_RECONNECT					= u8"Повторно свързване след %s sec",
	HOTKEY_DISCONNECT_NOW				= u8"Излизане",
	HOTKEY_MENU							= u8"Отворете менюто",
	HOTKEY_WIB							= u8"Anti-AFK",
	
	NEW_NICKNAME						= u8"Име",
	NEW_IP								= u8"IP:PORT",
	NEW_PORT							= u8"Port",
	NEW_PASTE_CURRENT_NICKNAME			= u8"Текущ",
	NEW_PASTE_CURRENT_IP_PORT			= u8"Текущ",
	NEW_CONNECT							= u8"Свързване",
	--NEW_ACCOUNT							= u8"Смени акаунт",
	AUTHOR								= u8"Автор: ",
	VERSION								= u8"Версия: ",
	DOWNLOAD_NEW_VERSION				= u8"Изтегли новата версия ",
	EMAIL								= u8"Email: ",
	
	
	-- Dialog list
	CHECK_DIALOG_TITLE					= u8"Дефинирайте диалоговия прозорец от заглавието му",
	CHECK_DIALOG_ID						= u8"Дефинирайте диалоговия прозорец от ID-то",
	CHECK_DIALOG_CONTENT				= u8"Дефинирайте диалога по неговото съдържание",
	DETAILS 							= u8"Детайли",
	DELETE_DIALOG						= u8" X ",
	CONNECT								= u8"Свързване",
	
	-- Dialog details
	RESPONSE_TEXT						= u8"Изпратете текст: ",
	RESPONSE_INDEX						= u8"Изпратете индекс на артикул: ",
	RESPONSE_BUTTON						= u8"Изпратете бутон: ",
		
	DIALOG_TITLE						= u8"Заглавието на диалога: ",
	DIALOG_ID							= u8"Диалоговият прозорец ID: ",
	DIALOG_STYLE						= u8"Стил на диалога: ",
	DIALOG_TEXT							= u8"Текстът на диалога:",
	GAUTH_KEY							= u8"Google Authenticator ключ",
		
	-- Server info
	SERVER_NAME							= u8"Име на сървър",
	SERVER_IP							= u8"IP:PORT",
	SERVER_PORT							= u8"Port",
	SERVER_USE_TIMEOUTS					= u8"Използвайте таймаутите на сървъра",
	SERVER_SC_TIMEOUT					= u8"Времето за изчакване за повторно свързване (sec): /sc",
	SERVER_DISCONNECT_TIMEOUT			= u8"Оставащо време до прекъсване (sec)",
	SERVER_BANNED_IP_TIMEOUT			= u8"Баннато IP таймер (sec)",
	SERVER_LOST_CONNECTION_TIMEOUT		= u8"Изгубена връзка таймер (sec)",
	
	-- Saving window
	SAVING_TITLE						= u8"Запаметяване",
	SAVING_CHECK_DIALOG_CONTENT			= u8"Дефинирайте диалога по неговото съдържание",
	SAVING_CHECK_DIALOG_TITLE			= u8"Дефинирайте диалоговия прозорец от заглавието му",
	SAVING_CHECK_DIALOG_ID				= u8"Дефинирайте диалоговия прозорец от ID-то",
	SAVING_USER_TITLE					= u8"Етикет",
	SAVING_GAUTH						= u8"Google Authenticator ключ",
	
	-- Reconnecting Window
	RECONNECT_IN						= u8"Свързване след ",
	CONNECT								= u8"Свързване",
	CANCEL								= u8"Отмяна",
}

LANG_UKR = {
	LABEL								= u8"Українська",
	
	-- Hello
	HELLO_MENU							= "Меню",
	HELLO_NEW_VERSION					= "Нова версія",
	HELLO_SAVED							= "Відповідь на діалог збережена",
	HELLO_DISCONNECTED					= "Ви закрили з'єднання",
	
	-- Top
	TAB_SETTINGS						= u8"Налаштування",
	TAB_ACCOUNTS						= u8"Акаунти",
	ADD_CURRENT_DIALOG					= u8"Зберегти відповідь на діалог",
	
	
	-- Settings
	SETTINGS_RESTART_REQUIRED			= u8"Потрібно перезавантаження гри",
	SETTINGS_FIX_INTERIOR_BUG			= u8"Виправляти баг в дзеркальных інтер'єрах з анти-AFK",
	SETTINGS_HELLO						= u8"Відображати підказки в чаті",
	SETTINGS_SAVE_BUTTON				= u8"Відображати зелену кнопку додання діалога",
	SETTINGS_NOTIF						= u8"Відображати вспливаючі підказки",
	SETTINGS_RECONNECTING_WINDOW		= u8"Відображати вікно перепідключення",
	
	SETTINGS_AUTORECONNECT				= u8"Автоматичне перепідключення",
	
	SETTINGS_SC_TIMEOUT					= u8"Тайм-аут перепідключення (сек)",
	SETTINGS_DISCONNECT_TIMEOUT			= u8"Тайм-аут при роз'єднанні (сек)",
	SETTINGS_BANNED_IP_TIMEOUT			= u8"Тайм-аут при бані IP (сек)",
	SETTINGS_LOST_CONNECTION_TIMEOUT	= u8"Тайм-аут при втраті з'єднання (сек)",
	
	SETTINGS_AUTORESPONSE				= u8"Автоматична відповідь на діалоги",
	SETTINGS_AUTORESPONSE_DELAY			= u8"Затримка перед відповіддю (мс)",
	SETTINGS_FASTCONNECT				= u8"Фаст коннект",
	SETTINGS_WIB						= u8"Анти-AFK",
	SETTINGS_PAUSE						= u8"Не перепідключатись автоматично",
	SETTINGS_PAUSE_TIME					= u8"Час",
	
	SETTINGS_RECONNECT					= u8"-    Перепідключитись",
	SETTINGS_DISCONNECT					= u8"-    Відключитись",
	SETTINGS_MENU						= u8"-    Меню",
	SETTINGS_COMMANDS					= u8"Команди",
	SETTINGS_CONNECTING_TIMEOUT			= u8"Тайм-аут на підключення (мс)",
	SETTINGS_MENU_CHEAT					= u8"Використовувати як чіт-код",
	
	NOTIF_WIB_OFF						= u8"Анти-AFK: Увімкнено",
	NOTIF_WIB_ON						= u8"Анти-AFK: Вимкнено",
	NOTIF_AUTO_RESPONSE					= u8"Авто-відповідь",
	
	HOTKEY_AND_CMD						= u8"Гарячі клавіші",
	HOTKEY_RECONNECT					= u8"Перепідключитись через %s сек",
	HOTKEY_DISCONNECT_NOW				= u8"Відключитись",
	HOTKEY_MENU							= u8"Відкрити меню",
	HOTKEY_WIB							= u8"Анти-AFK",
	HOTKEY_CMDS							= u8"Команди скрипта",
	
	NEW_NICKNAME						= u8"Нікнейм",
	NEW_IP								= u8"IP:PORT",
	NEW_PORT							= u8"Порт",
	NEW_PASTE_CURRENT_NICKNAME			= u8"Поточний",
	NEW_PASTE_CURRENT_IP_PORT			= u8"Поточний",
	NEW_CONNECT							= u8"Підключитись",
	NEW_ACCOUNT							= u8"Підключитись як...",
	AUTHOR								= u8"Автор: ",
	VERSION								= u8"Версія: ",
	DOWNLOAD_NEW_VERSION				= u8"Скачати нову версію ",
	EMAIL								= u8"Email: ",
	
	
	-- Dialog list
	CHECK_DIALOG_TITLE					= u8"Розпізнавати діалог по заголовку",
	CHECK_DIALOG_ID						= u8"Розпізнавати діалог по ID",
	CHECK_DIALOG_CONTENT				= u8"Розпізнавати діалог по вмісту",
	DETAILS 							= u8"Детальніше",
	DELETE_DIALOG						= u8" X ",
	CONNECT								= u8"Підключитися",
	
	-- Dialog details
	RESPONSE_TEXT						= u8"Відправити текст",
	RESPONSE_INDEX						= u8"Відправити пункт: ",
	RESPONSE_BUTTON						= u8"Відправити кнопку: ",
	GAUTH_KEY							= u8"Ключ Google Authenticator",
		
	DIALOG_TITLE						= u8"Заголовок діалога: ",
	DIALOG_ID							= u8"ID діалога: ",
	DIALOG_STYLE						= u8"Стиль діалога: ",
	DIALOG_TEXT							= u8"Текст діалога:",
		
	-- Server info
	SERVER_NAME							= u8"Ім'я сервера",
	SERVER_IP							= u8"IP:PORT",
	SERVER_PORT							= u8"Порт",
	SERVER_USE_TIMEOUTS					= u8"Використовувати тайм-аути сервера",
	SERVER_SC_TIMEOUT					= u8"Тайм-аут перепідключення (сек): /sc",
	SERVER_DISCONNECT_TIMEOUT			= u8"Тайм-аут при роз'єднанні (сек)",
	SERVER_BANNED_IP_TIMEOUT			= u8"Тайм-аут при бані IP (сек)",
	SERVER_LOST_CONNECTION_TIMEOUT		= u8"Тайм-аут при втраті з'єднання (сек)",
	
	SERVER_CHANGE_NICKNAME				= u8"Підключитись з іншим нікнеймом",
	
	-- Saving window
	SAVING_TITLE						= u8"Збереження",
	SAVING_CHECK_DIALOG_CONTENT			= u8"Розпізнавати діалог по вмісту",
	SAVING_CHECK_DIALOG_TITLE			= u8"Розпізнавати діалог по заголовку",
	SAVING_CHECK_DIALOG_ID				= u8"Розпізнавати діалог по ID",
	SAVING_USER_TITLE					= u8"Назва",
	SAVING_GAUTH						= u8"Ключ Google Authenticator",
	SAVING_SPAWN_PLAYER					= u8"Заспавнити персонажа (ms)",
	
	-- Reconnecting Window
	RECONNECT_IN						= u8"Перепідключення через ",
	CONNECT								= u8"Підключитись",
	CANCEL								= u8"Скасувати",
}


LANG_TITLE = u8"Language | Язык | Език | Мова"
LANGS = {LANG_ENG, LANG_RUS, LANG_BGR, LANG_UKR}

for index, lang in ipairs(LANGS) do
	luacfg.update(lang, LANG_ENG, false)
end


cfg = {
	spawn_delay = 1500,
	reconnecting_window = true,
	cmds = true,
	hello = true,
	notif = true,
	save_button = true,
	use_connecting_timeout = false,
	connecting_timeout = 1000,
	
	current_tab = "settings" or "accounts",
	current_settings_tab = "reconnect",
	current_server_index = 0,
	
	sc_timeout = 16,
	disconnect_timeout = 16,
	lost_connection_timeout = 36,
	banned_ip_timeout = 320,
	
	
	check_id = false,
	check_content = true,
	check_title = false,
	
	fix_interior_bug = true,

	autoreconnect = true,
	
	autoresponse = true,
	autoresponse_delay = 0,
	
	
	pause = false,
	pause_from_hour = 4,
	pause_from_min = 55,
	pause_to_hour = 5,
	pause_to_min = 25,
	
	fastconnect = false,
	wib = false,
	lang_index = 1,
	
	
	combo_reconnect = {},
	combo_disconnect_now = {},
	combo_menu = {},
	combo_wib = {},
	combo_cmds = {},
	
}

luacfg.update(cfg, filename_cfg)

if cfg.fix_interior_bug then
	-- fix interior bug
	writeMemory(0x555854, 4, -1869574000, true)
	writeMemory(0x555858, 1, 144, true)
end

LANG = LANGS[cfg.lang_index]

servers = {
--[[
	{ip = "192.168.0.1", port = 7777, name = "Diamond Role Play | Amber", disconnect_timeout = 0, lost_connection_timeout, banned_ip_timeout = 120, use_timeouts = true,
		logins = {
			{nickname = "Jane_Christie",
				dialogs = {
					{nickname = "Jane_Christie", response_button = 1, response_text = "1234", response_index = 1, text = "( ? )", title = "Введите пароль", user_title = "Один", id = 26, check_content = true, check_title = false, check_id = false},
					{nickname = "Jane_Christie", response_button = 1, response_text = "1234", response_index = 1, text = "( ? )", title = "Введите пароль", user_title = "Два", id = 26, check_content = true, check_title = false, check_id = false},
					{nickname = "Jane_Christie", response_button = 1, response_text = "1234", response_index = 1, text = "( ? )", title = "Введите пароль", user_title = "Три", id = 26, check_content = true, check_title = false, check_id = false},
				}	
			}
		}
		
		
	},
--]]
}

luacfg.update(servers, filename_servers)

-- Совместимость < 2.1.4
for server_index, server in ipairs(servers) do
	luacfg.update(server, {["sc_timeout"] = cfg.sc_timeout}, false)
end
--

----- Functions -----

function setCenterCursor()
	local cRECT = ffi.new('RECT')
		
	ffi.C.GetClientRect(ffi.C.GetActiveWindow(), cRECT)
	
	local point = ffi.new('POINT')
	point.x = cRECT.left
	point.y = cRECT.top
	
	local point2 = ffi.new('POINT')
	point2.x = cRECT.right
	point2.y = cRECT.bottom
	
	ffi.C.ClientToScreen(ffi.C.GetActiveWindow(), point)
	ffi.C.ClientToScreen(ffi.C.GetActiveWindow(), point2)
	
	ffi.C.SetCursorPos(point.x+cRECT.right/2, point.y+cRECT.bottom/2)
	--sampAddChatMessage("курсор в центр, надеюсь...", -1)
end

function ClipCursor(state)

	if state then
	
		local cRECT = ffi.new('RECT')
		
		ffi.C.GetClientRect(ffi.C.GetActiveWindow(), cRECT)
		
		--[[
		local wRECT = ffi.new('RECT')
		
		ffi.C.GetWindowRect(ffi.C.GetActiveWindow(), wRECT)
		
		local window_w = wRECT.right - wRECT.left
		local window_h = wRECT.bottom - wRECT.top
		
		local window_side_border = (window_w - cRECT.right) / 2
		local window_top_border = window_h - cRECT.bottom - window_side_border
		
		local left = wRECT.left + window_side_border
		local top = wRECT.top + window_top_border
		local right = left + cRECT.right
		local bottom = top + cRECT.bottom
		--]]
		
		
		local point = ffi.new('POINT')
		point.x = cRECT.left
		point.y = cRECT.top
		
		local point2 = ffi.new('POINT')
		point2.x = cRECT.right
		point2.y = cRECT.bottom
		
		ffi.C.ClientToScreen(ffi.C.GetActiveWindow(), point)
		ffi.C.ClientToScreen(ffi.C.GetActiveWindow(), point2)
		
		ffi.C.SetRect(cRECT, point.x, point.y, point2.x, point2.y)
		ffi.C.ClipCursor(cRECT)
		
	else
		ffi.C.ClipCursor(nil)
	end

end

-- Ping
function ping(ip, port)
    local data
    local commonPattern = generateCommonPattern(ip, port)

    local udp = socket.udp()
    udp:settimeout(3)
    udp:setsockname("*", 0)
    --
    udp:sendto(commonPattern .. "i", ip, port)
    --data = udp:receive() -- optional

    --
    udp:sendto(commonPattern .. "p" .. "aaaa", ip, port)
    --data = udp:receive() -- optional
    --
    udp:sendto(commonPattern .. "c", ip, port)
    --data = udp:receive() -- optional

    --
    udp:sendto(commonPattern .. "r", ip, port)
    --data = udp:receive() -- optional
    udp:close()
end

function generateCommonPattern(ip, port)
    local separatedIp = explode(".", ip)
    local firstPortByte = bit.band(port, 0xFF)
    local secondPortByte = bit.band(bit.rshift(port, 8), 0xFF)
    return "SAMP" ..
        string.char(separatedIp[1]) ..
            string.char(separatedIp[2]) ..
                string.char(separatedIp[3]) ..
                    string.char(separatedIp[4]) ..
                        string.char(firstPortByte) .. string.char(secondPortByte)
end

function explode(div, str)
    if (div == "") then
        return false
    end
    local pos, arr = 0, {}
    for st, sp in function()
        return string.find(str, div, pos, true)
    end do
        table.insert(arr, string.sub(str, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(str, pos))
    return arr
end
--

function secondsToClock(seconds) 
   local seconds = tonumber(seconds)  
   if seconds <= 0 then 
		return "00:00:00"; 
   else 
		hours = string.format("%02.f", math.floor(seconds/3600)); 
		mins = string.format("%02.f", math.floor(seconds/60 - (hours*60))); 
		secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60)); 
		return hours..":"..mins..":"..secs 
	end 
end

function sampGetNickname()
	local result, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
	if result then
		return sampGetPlayerNickname(id)
	else
		return ""
	end
end

function add_dialog(args)
	
	-- ip, port, name,
	-- nickname,
	-- id, title, user_title, text,
	-- check_id, check_title, check_content
	-- response_button, response_text, response_index
	-- disconnect_timeout, banned_ip_timeout, use_timeouts, lost_connection_timeout
	
	local dialog = {
		--nickname = args.nickname,
		id = args.id,
		title = args.title,
		user_title = args.user_title,
		text = args.text,
		style = args.style,
		
		check_id = args.check_id,
		check_content = args.check_content,
		check_title = args.check_title,
		
		response_button = args.response_button,
		response_text = args.response_text,
		response_index = args.response_index,
		use_gauth = args.use_gauth,
		spawn_player = args.spawn_player,
		spawn_delay = args.spawn_delay,
		gauth_key = args.gauth_key
	}

	for server_index, server in ipairs(servers) do
	
		if	server.ip == args.ip and server.port == args.port then
		
			for login_index, login in ipairs(server.logins) do
				if login.nickname == args.nickname then
					table.insert(login.dialogs, dialog)
					return
				end
			end
			
			table.insert(server.logins, {nickname = args.nickname, dialogs = {dialog}})
			return

		end
	end
	
	table.insert(servers,
		{
			ip = args.ip,
			port = args.port,
			name = args.name,
			sc_timeout = args.sc_timeout,
			disconnect_timeout = args.disconnect_timeout,
			banned_ip_timeout = args.banned_ip_timeout, 
			lost_connection_timeout = args.lost_connection_timeout,
			use_timeouts = args.use_timeouts,
			logins = {
				{nickname = args.nickname, dialogs = {dialog}}
			}	
		}
	)

end

function get_dialog(args)
	-- ip, port,
	-- nickname,
	-- id, title, text, style

	for server_index, server in ipairs(servers) do
		
		if server.ip == args.ip and server.port == args.port then
			for login_index, login in ipairs(server.logins) do
				
				if login.nickname == args.nickname then
					for dialog_index, dialog in ipairs(login.dialogs) do
						
						if	(not dialog.check_id or dialog.id == args.id)
						and	(not dialog.check_title or dialog.title == args.title)
						and	(not dialog.check_content or dialog.text == args.text)
						and (not dialog.check_content or dialog.style == args.style) then
						
							if dialog.check_id or dialog.check_title or dialog.check_content then
								return dialog
							end
						end
					end
				end
			end
		end
	end
end

function get_server(args)
	-- ip, port
	
	for server_index, server in ipairs(servers) do
	
		if server.ip == args.ip and server.port == args.port then
			return server
		end
	end
end


function get_sc_timeout()
	local ip, port = sampGetCurrentServerAddress()
	local server = get_server{ip = ip, port = port}
	
	if server and server.use_timeouts then
		return server.sc_timeout
	else
		return cfg.sc_timeout
	end
end

function get_disconnect_timeout()
	local ip, port = sampGetCurrentServerAddress()
	local server = get_server{ip = ip, port = port}
	
	if server and server.use_timeouts then
		return server.disconnect_timeout
	else
		return cfg.disconnect_timeout
	end
end

function get_banned_ip_timeout()
	local ip, port = sampGetCurrentServerAddress()
	local server = get_server{ip = ip, port = port}
	
	if server and server.use_timeouts then
		return server.banned_ip_timeout
	else
		return cfg.banned_ip_timeout
	end
end

function get_lost_connection_timeout()
	local ip, port = sampGetCurrentServerAddress()
	local server = get_server{ip = ip, port = port}
	
	if server and server.use_timeouts then
		return server.lost_connection_timeout
	else
		return cfg.lost_connection_timeout
	end
end


function gen_gauth_code(skey)
	skey = basexx.from_base32(skey)
	value = math.floor(os.time() / 30)
	value = string.char(
	0, 0, 0, 0,
	bit.band(value, 0xFF000000) / 0x1000000,
	bit.band(value, 0xFF0000) / 0x10000,
	bit.band(value, 0xFF00) / 0x100,
	bit.band(value, 0xFF))
	local hash = sha1.hmac_binary(skey, value)
	local offset = bit.band(hash:sub(-1):byte(1, 1), 0xF)
	local function bytesToInt(a,b,c,d)
		return a*0x1000000 + b*0x10000 + c*0x100 + d
	end
	hash = bytesToInt(hash:byte(offset + 1, offset + 4))
	hash = bit.band(hash, 0x7FFFFFFF) % 1000000
	return ('%06d'):format(hash)
end


function delete_dialog(server_index, login_index, dialog_index)
	table.remove(servers[server_index].logins[login_index].dialogs, dialog_index)
	
	if #servers[server_index].logins[login_index].dialogs == 0 then
		table.remove(servers[server_index].logins, login_index)
	end
	
	if #servers[server_index].logins == 0 then
		table.remove(servers, server_index)
	end
end

function move_login(server_index, from, to)
	table.insert(servers[server_index].logins, to, table.remove(servers[server_index].logins, from))
end

function move_server(from, to)
	table.insert(servers, to, table.remove(servers, from))
end

--
function cmd_sc(timeout_sec, disconnect_now, ping)
	if disconnect_now == nil then
		disconnect_now = true
	end
	
	
		
	timeout_sec = tonumber(timeout_sec) or get_sc_timeout()
	
	

	if sc_thread then
		sc_thread:terminate()
	end
	
	if ping then
		local ip, port = sampGetCurrentServerAddress()
		pcall(ping, ip, port)
	end
	
	sc_thread = lua_thread.create_suspended(function()
		wait(0)
		
		if disconnect_now and sampGetGamestate() ~= GAMESTATE_RESTARTING then
			sampSetGamestate(GAMESTATE_DISCONNECTED)
			sampDisconnectWithReason(0)
		end

		local timeout_clock = os.clock()
		local clock_counter
		
		while true do
			wait(0)
			
			clock_counter = os.clock()-timeout_clock
			if clock_counter < timeout_sec then
				
				reconnecting_text = u8(secondsToClock(timeout_sec-clock_counter))
				imw_reconnecting.v = true
			else
				break
			end
		end
		
		imw_reconnecting.v = false
		
		
		if not disconnect_now and sampGetGamestate() ~= GAMESTATE_RESTARTING then
			sampSetGamestate(GAMESTATE_DISCONNECTED)
			sampDisconnectWithReason(0)
			
		end
		
		if sampIsDialogActive() then
			sampCloseCurrentDialogWithButton(0)
		end
		
		
		sampSetGamestate(GAMESTATE_WAIT_CONNECT)
		start_connecting = os.clock()
		--sampAddChatMessage("Подключение через /sc...", 0xff8800)
	end)
		
	sc_thread:run()
end

function cmd_scd()
	if sc_thread then
		sc_thread:terminate()
	end

	--if sampGetGamestate() == GAMESTATE_CONNECTED then
		start_connecting = nil
		sampSetGamestate(GAMESTATE_DISCONNECTED)
		sampAddChatMessage(LANG.HELLO_DISCONNECTED, 0xABCDEF)
		--sampDisconnectWithReason(0)
	--end
end

function connect(ip, port, nickname)
	if sc_thread then
		sc_thread:terminate()
	end
	imw_reconnecting.v = false
	imw_menu.v = false
	
	local current_ip, current_port = sampGetCurrentServerAddress()
	
	sampSetLocalPlayerName(nickname)
	sampConnectToServer(ip, port)
	sampDisconnectWithReason(0)
	
	
	if current_ip == ip and current_port == port then
		cmd_sc(get_sc_timeout(), true)
		
	else
		cmd_sc(0, true)
	end
end

function get_pause_sec(phour1, pmin1, phour2, pmin2)
	local epoch_time = os.time(os.date("*t"))
	local datetime = os.date("*t", epoch_time)
	

	datetime.hour = phour1
	datetime.min = pmin1
	datetime.sec = 0

	local start = os.time(datetime)


	datetime.hour = phour2
	datetime.min = pmin2
	datetime.sec = 0

	local finish = os.time(datetime)

	if finish <= start then
		datetime.hour = phour2
		datetime.min = pmin2
		datetime.day = datetime.day+1
		finish = os.time(datetime)

		if (epoch_time < start and epoch_time < finish) then
			epoch_time = epoch_time + 86400
		end
	end

	if	(epoch_time > start and epoch_time < finish) then
    	return finish - epoch_time
	else
		return false
	end
  
end

function set_fastconnect(work)
	if work then
		writeMemory(sampGetBase() + 0x2D3C45, 2, 0, true)
	else
		writeMemory(sampGetBase() + 0x2D3C45, 2, 8228, true)
	end
end

function set_wib(work)
    local memory = require 'memory'
    if work then
		memory.setuint8(7634870, 1, false)
		memory.setuint8(7635034, 1, false)
		memory.fill(7623723, 144, 8, false)
		memory.fill(5499528, 144, 6, false)
    else
        memory.setuint8(7634870, 0, false)
		memory.setuint8(7635034, 0, false)
		memory.hex2bin('0F 84 7B 01 00 00', 7623723, 8)
		memory.hex2bin('50 51 FF 15 00 83 85 00', 5499528, 6)
    end
end

function set_cmds(work)
	if work then
		-- Сommands
		sampRegisterChatCommand(MAIN_CMD,
			function()
				imw_menu.v = not imw_menu.v
			end
		)
		
		sampRegisterChatCommand("sc", cmd_sc)
		sampRegisterChatCommand("scd", cmd_scd)
	else
		sampUnregisterChatCommand(MAIN_CMD)
		sampUnregisterChatCommand("sc")
		sampUnregisterChatCommand("scd")
	end
end


----- Events -----
function onReceivePacket(id, bitStream)
	--sampAddChatMessage("packet "..id, -1)
	
	if (id == PACKET_RECEIVED_STATIC_DATA) then
		--start_connecting = nil
		--sampAddChatMessage("Контакт с сервером установлен", 0xff8800)
	
	elseif (id == PACKET_INVALID_PASSWORD) then
		start_connecting = nil
	
		if cfg.autoreconnect then
			if cfg.pause then
				local psec = get_pause_sec(cfg.pause_from_hour, cfg.pause_from_min, cfg.pause_to_hour, cfg.pause_to_min)
				if psec then
					cmd_sc(psec)
				else
					cmd_sc(get_disconnect_timeout())
				end
			else
				cmd_sc(get_disconnect_timeout())
			end			
		end
	
	elseif (id == PACKET_DISCONNECTION_NOTIFICATION) then
		start_connecting = nil
	
		if cfg.autoreconnect then
			if cfg.pause then
				local psec = get_pause_sec(cfg.pause_from_hour, cfg.pause_from_min, cfg.pause_to_hour, cfg.pause_to_min)
				if psec then
					cmd_sc(psec, false)
				else
					cmd_sc(get_disconnect_timeout(), false)
				end
			else
				cmd_sc(get_disconnect_timeout(), false)
			end			
		end
		
		local ip, port = sampGetCurrentServerAddress()
		--pcall(ping, ip, port)
	
	elseif (id == PACKET_CONNECTION_LOST) then
		start_connecting = nil
	
		if cfg.autoreconnect then
			
			if cfg.pause then
				local psec = get_pause_sec(cfg.pause_from_hour, cfg.pause_from_min, cfg.pause_to_hour, cfg.pause_to_min)
				if psec then
					cmd_sc(psec)
				else
					cmd_sc(get_lost_connection_timeout())
				end
			else
				cmd_sc(get_lost_connection_timeout())
			end			
		end
		
		local ip, port = sampGetCurrentServerAddress()
		--pcall(ping, ip, port)
		
	elseif (id == PACKET_CONNECTION_BANNED) then
		start_connecting = nil
		
		if cfg.autoreconnect then
			if cfg.pause then
				local psec = get_pause_sec(cfg.pause_from_hour, cfg.pause_from_min, cfg.pause_to_hour, cfg.pause_to_min)
				if psec then
					cmd_sc(psec)
				else
					cmd_sc(cfg.timeout_sec_banned)
				end
			else
				cmd_sc(get_banned_ip_timeout())
			end			
		end
		
		local ip, port = sampGetCurrentServerAddress()
		--pcall(ping, ip, port)
	
	elseif (id == PACKET_CONNECTION_ATTEMPT_FAILED) then
		if not start_connecting then
			start_connecting = os.clock()
			--sampAddChatMessage("Подключение через didn't respond...", 0xff8800)
		end
		
	
		local ip, port = sampGetCurrentServerAddress()
		pcall(ping, ip, port)
	end
end


function onReceiveRpc(id, bitStream)
	--sampAddChatMessage("rpc "..id, -1)
	if (id == RPC_SCRINITGAME) then
		start_connecting = nil
		--sampAddChatMessage("Подключено", 0xff8800)
	end
	
	
	if (id == RPC_CONNECTIONREJECTED) then
		start_connecting = nil
		
		if cfg.autoreconnect then
			if cfg.pause then
				local psec = get_pause_sec(cfg.pause_from_hour, cfg.pause_from_min, cfg.pause_to_hour, cfg.pause_to_min)
				if psec then
					cmd_sc(psec)
				else
					cmd_sc(get_lost_connection_timeout())
				end
			else
				cmd_sc(get_lost_connection_timeout())
			end			
		end
	end
end


function sampev.onSetPlayerName(playerId, name, success)
	local result, myId = sampGetPlayerIdByCharHandle(PLAYER_PED)
	
	if result and myId == playerId then
		return false
	end
end


addEventHandler("onWindowMessage",
	function (msg, wparam, lparam)
		if msg == wm.WM_ACTIVATE then
		
			if wparam == 1 or wparam == 2 then
				IS_WINDOW_ACTIVE = true
				
				
				if wparam == 1 then
					setCenterCursor()		
				end		
				
				if sampIsDialogActive() and last_dialog and not sampIsDialogClientside() then
					local editbox_text = sampGetCurrentDialogEditboxText()
					last_dialog[3] = sampGetDialogText()	
					sampShowDialog(unpack(last_dialog))
					sampSetCurrentDialogEditboxText(editbox_text)
					sampSetDialogClientside(false)
					last_dialog = nil
				end
				
			elseif wparam == 0 then
				IS_WINDOW_ACTIVE = false
			end
		end
	end
)


			 

function onScriptTerminate(LuaScript, quitGame)

	if LuaScript == thisScript() and not quitGame then
		showCursor(false, false)
	end
end

function sampev.onSendDialogResponse(id, button, index, text)
		
	if imw_saving.v then
	
		local ip, port = sampGetCurrentServerAddress()
		
		add_dialog{
			ip = ip,
			port = port,
			name = sampGetCurrentServerName(),
			
			nickname = sampGetNickname(),
			
			id = id,
			title = sampGetDialogCaption(),
			user_title = user_title,
			text = sampGetDialogText(),
			style = sampGetCurrentDialogType(),
			
			check_content = cfg.check_content,
			check_title = cfg.check_title,
			check_id = cfg.check_id,
			
			response_button = button,
			response_index = index,
			response_text = text,
			
			sc_timeout = cfg.sc_timeout,
			disconnect_timeout = cfg.disconnect_timeout,
			banned_ip_timeout = cfg.banned_ip_timeout,
			lost_connection_timeout = cfg.lost_connection_timeout,
			use_timeouts = false,
			use_gauth = use_gauth,
			gauth_key = gauth_key,
			spawn_player = spawn_player,
			spawn_delay = cfg.spawn_delay
		}
		
		luacfg.save(servers, filename_servers)
		
		
		imw_saving.v = false
		user_title = nil
		gauth_key = nil
		use_gauth = nil
		
		sampAddChatMessage("• {88FF88}["..MAIN_TITLE.."] {FFFFFF}"..LANG.HELLO_SAVED, 0xFFFFFF)
	end
end

function sampev.onShowDialog(id, style, title, label_button1, label_button0, text)
	last_dialog = {id, title, text, label_button1, label_button0, style}
	
	if cfg.autoresponse then
		
		local ip, port = sampGetCurrentServerAddress()
		local nickname = sampGetNickname()
		
		local dialog = get_dialog{
			ip = ip,
			port = port,
			nickname = nickname,
			id = id,
			title = title,
			text = text,
			style = style,
		}
		
		if dialog then
			lua_thread.create(
				function()
					wait(cfg.autoresponse_delay)
					if dialog.use_gauth then
					
						local sec = os.date("*t").sec
						local offset = 5
						local mode = sec % 30

						if mode < offset then
							wait( (offset - mode) * 1000 )
							
						elseif mode > (30 - offset) then
							wait( (30 - mode + offset) * 1000 )
						end
										
						sampSendDialogResponse(id, dialog.response_button, dialog.response_index, gen_gauth_code(dialog.gauth_key))
					
					else
						sampSendDialogResponse(id, dialog.response_button, dialog.response_index, dialog.response_text)
					end
					
					if dialog.spawn_player then
						wait(dialog.spawn_delay)
						sampSpawnPlayer()
					end
				end
			)
			
			if cfg.notif then
				notif_text = LANG.NOTIF_AUTO_RESPONSE
				notif_clock = os.clock()
				imw_notif.v = true
			end
				
			return false
		end
		
	end
end

local button_w1 = 188
local button_h1 = 28

local button_w2 = 160
local button_h2 = 28

function imgui.OnDrawFrame()
	local w, h = getScreenResolution()
	
	
	if imw_notif.v then
	
		if (os.clock() - notif_clock) < 1.5 then
			imgui.SetNextWindowSize(imgui.ImVec2(150, 32), imgui.Cond.Always)
			imgui.SetNextWindowPos(imgui.ImVec2(w/2, h-32-10), imgui.Cond.Always, imgui.ImVec2(0.5, 0))
			imgui.Begin(u8(MAIN_TITLE).." ##imw_notif", imw_notif, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoTitleBar)
				
				imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(notif_text).x)/2)
				imgui.Text(notif_text)
			imgui.End()
		else
			imw_notif.v = false
		end
	end
	
	if imw_reconnecting.v and not sc_thread.dead and cfg.reconnecting_window then
		
		
		imgui.SetNextWindowSize(imgui.ImVec2(190, 142), imgui.Cond.Always)  
		imgui.SetNextWindowPos(imgui.ImVec2(w-190-10, h-142-10))
		imgui.Begin(u8(__name__.."## reconnect window"), imw_reconnecting, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar) 
		
			imgui.BeginChild("##reconnect window", imgui.ImVec2(0, 0), true)
				imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(LANG.RECONNECT_IN).x)/2)
				imgui.Text(LANG.RECONNECT_IN)
				
				imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(reconnecting_text).x)/2)
				imgui.Text(reconnecting_text)
				
				
				if imgui.Button(LANG.CONNECT.."## connect now", imgui.ImVec2(160, 25)) then
					imw_reconnecting.v = false
					cmd_sc(0)
				end
				
				if imgui.Button(LANG.CANCEL.."## cancel reconnecting", imgui.ImVec2(160, 25)) then
					imw_reconnecting.v = false
					sc_thread:terminate()
				end
			imgui.EndChild()
		imgui.End()
	end
	
	
	if imw_saving.v then
		imgui.SetNextWindowSize(imgui.ImVec2(380, 300), imgui.Cond.Always)
		
		
		if pos_saving then
			if imgui.IsMouseDown(0) then
				imgui.SetNextWindowPos(imgui.ImVec2(pos_saving.x, pos_saving.y), imgui.Cond.FirstUseEver)
			else
				imgui.SetNextWindowPos(imgui.ImVec2(pos_saving.x, pos_saving.y), imgui.Cond.Always)
			end
		else
			imgui.SetNextWindowPos(imgui.ImVec2(10, h-300-10), imgui.Cond.Always)
		end
		
		
		imgui.Begin(LANG.SAVING_TITLE.."## imw_saving", imw_saving, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
			
			
			imgui.BeginChild("imw_saving", imgui.ImVec2(0, 135), true)
			
				if not user_title then
					user_title = sampGetDialogCaption():gsub("{%x%x%x%x%x%x}", "")
				end
				
				local im_buffer = imgui.ImBuffer(u8(user_title), 1024)
				local str_id = "## user_title"
				
				imgui.PushItemWidth(225)
					local result = imgui.InputText(LANG.SAVING_USER_TITLE..str_id, im_buffer)
				imgui.PopItemWidth()
				
				if result then
					imgui.EditedItem[str_id] = true
					user_title = u8:decode(im_buffer.v)
				end
				
				if not imgui.IsItemActive() and imgui.EditedItem[str_id] then	
					imgui.EditedItem[str_id] = nil
				end
		
				
				local im_bool = imgui.ImBool(cfg.check_content)
				local str_id = "## cfg.check_content"
				
				if imgui.Checkbox(LANG.SAVING_CHECK_DIALOG_CONTENT..str_id, im_bool) then
					cfg.check_content = im_bool.v
					luacfg.save(cfg, filename_cfg)
				end
				
				
				-- ##
				local im_bool = imgui.ImBool(cfg.check_title)
				local str_id = "## cfg.check_title"
				
				if imgui.Checkbox(LANG.SAVING_CHECK_DIALOG_TITLE..str_id, im_bool) then
					cfg.check_title = im_bool.v
					luacfg.save(cfg, filename_cfg)
				end
				
				
				-- ##
				local im_bool = imgui.ImBool(cfg.check_id)
				local str_id = "## cfg.check_id"
											
				if imgui.Checkbox(LANG.SAVING_CHECK_DIALOG_ID..str_id, im_bool) then
					cfg.check_id = im_bool.v
					luacfg.save(cfg, filename_cfg)
				end
				
				
				
				
			imgui.EndChild()
			
			
			imgui.BeginChild("gauth", imgui.ImVec2(0, 70), true)
				
				-- ##
				if use_gauth == nil then
					use_gauth = false
				end
				
				local im_bool = imgui.ImBool(use_gauth)
				local str_id = "## use_gauth"
											
				if imgui.Checkbox(LANG.SAVING_GAUTH..str_id, im_bool) then
					use_gauth = im_bool.v
				end
				
				-- ##
				if not gauth_key then
					gauth_key = ""
				end
				
				local im_buffer = imgui.ImBuffer(u8(gauth_key), 1024)
				local str_id = "## gauth_key"
				
				imgui.PushItemWidth(-.4)
					local result = imgui.InputText(str_id, im_buffer)
				imgui.PopItemWidth()
				
				if result then
					imgui.EditedItem[str_id] = true
					gauth_key = u8:decode(im_buffer.v)
				end
				
				if not imgui.IsItemActive() and imgui.EditedItem[str_id] then	
					imgui.EditedItem[str_id] = nil
				end
				
			imgui.EndChild()
			
			imgui.BeginChild("spawn_player", imgui.ImVec2(0, 0), true)
				-- ##
				if spawn_player == nil then
					spawn_player = false
				end
				
				local im_bool = imgui.ImBool(spawn_player)
				local str_id = "## spawn_player"
											
				if imgui.Checkbox(str_id, im_bool) then
					spawn_player = im_bool.v
				end
				
				imgui.SameLine()
				
				
				imgui.PushItemWidth(50)
				
				-- #
				local str_id = "## cfg.spawn_delay"
				local im_int = im(str_id, imgui.ImInt, cfg.spawn_delay)
	
				
				if imgui.InputIntEx(LANG.SAVING_SPAWN_PLAYER..str_id, im_int, 0, 0) then
					cfg.spawn_delay = im_int.v
					luacfg.save(cfg, filename_cfg)
				end
				
				imgui.PopItemWidth()
				
			imgui.EndChild()
			
			
			if imgui.IsRootWindowOrAnyChildHovered() then
					
				if imgui.IsMouseDown(0) then		
					local window_pos = imgui.GetWindowPos()
					
					if (not pos_saving) or (pos_saving.x ~= window_pos.x) or (pos_saving.y ~= window_pos.y)  then
						pos_saving = {x = window_pos.x, y = window_pos.y}
					end	
				end
			end
			
			
			if not imw_saving.v then
				user_title = nil
				gauth_key = nil
				use_gauth = nil
				spawn_player = nil
			end
		imgui.End()
	end
	

	if imw_save_button.v and not imw_saving.v then
		imgui.SetNextWindowSize(imgui.ImVec2(32, 32), imgui.Cond.Always)
		imgui.SetNextWindowPos(imgui.ImVec2(2, h-32-2), imgui.Cond.Always)
		
		imgui.PushStyleVar(imgui.StyleVar.WindowPadding, imgui.ImVec2(1, 1))
		
			imgui.Begin(u8(MAIN_TITLE).." ##imw_save_button", imw_save_button, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoTitleBar)
				if imgui.ButtonGreen("+## imw_save_button", imgui.ImVec2(-0.1, -0.1)) then
					imw_saving.v = true
				end
			imgui.End()
		imgui.PopStyleVar()
	end

	
	if imw_menu.v then
		imgui.SetNextWindowSize(imgui.ImVec2(800, 600), imgui.Cond.Always)
		
		
		if pos_menu then
			if imgui.IsMouseDown(0) then
				imgui.SetNextWindowPos(imgui.ImVec2(pos_menu.x, pos_menu.y), imgui.Cond.FirstUseEver)
			else
				imgui.SetNextWindowPos(imgui.ImVec2(pos_menu.x, pos_menu.y), imgui.Cond.Always)
			end
		else
			imgui.SetNextWindowPos(imgui.ImVec2(w/2, h/2), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
		end

		
		
		
		imgui.Begin(u8(MAIN_TITLE).." ##imw_menu", imw_menu, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoScrollWithMouse)
			
			----- TABS -----
			local str_id = "## tab: settings"
			
			if imgui.ButtonActivated(cfg.current_tab == "settings", LANG.TAB_SETTINGS..str_id, imgui.ImVec2(button_w1, button_h1)) then
				cfg.current_tab = "settings"
				luacfg.save(cfg, filename_cfg)
			end
				
			imgui.SameLine()
			
			local str_id = "## tab: accounts"
			if cfg.current_tab == "accounts" then
				imgui.ButtonActive(LANG.TAB_ACCOUNTS..str_id, imgui.ImVec2(button_w1, button_h1))

			elseif imgui.Button(LANG.TAB_ACCOUNTS..str_id, imgui.ImVec2(button_w1, button_h1)) then
				cfg.current_tab = "accounts"
				luacfg.save(cfg, filename_cfg)
			end
			
			imgui.SameLine() --imgui.SameLine(440)
			
			if imgui.BeginPopup("change popup") then
								
							
							
				imgui.PushItemWidth(168)
					local str_id = "## im_new_address"
					imgui.InputText(LANG.NEW_IP..str_id, im_new_address, imgui.InputTextFlags.AutoSelectAll)
				imgui.PopItemWidth()
				
				local ip, port = sampGetCurrentServerAddress()
				
				imgui.SameLine(335)
				local str_id = "## past current address"
				
				if u8:decode(im_new_address.v) ~= ip..":"..port then
					if imgui.Button(LANG.NEW_PASTE_CURRENT_IP_PORT..str_id, imgui.ImVec2(130, 0)) then
						im_new_address.v = u8(ip..":"..port)
					end
					
				else
					imgui.ButtonDisabled(LANG.NEW_PASTE_CURRENT_IP_PORT..str_id, imgui.ImVec2(130, 0))
				end
				
				
				imgui.PushItemWidth(168)
					local str_id = "## im_new_nickname"
					imgui.InputText(LANG.NEW_NICKNAME..str_id, im_new_nickname) -- imgui.InputTextFlags.AutoSelectAll
				imgui.PopItemWidth()
				
				imgui.SameLine(335)
				
				-- ##
				local str_id = "## paste current nickname"
				local nickname = sampGetNickname()
				
				if u8:decode(im_new_nickname.v) ~= nickname then
					if imgui.Button(LANG.NEW_PASTE_CURRENT_NICKNAME..str_id, imgui.ImVec2(130, 0)) then
						im_new_nickname.v = nickname
					end
					
				else
					imgui.ButtonDisabled(LANG.NEW_PASTE_CURRENT_NICKNAME..str_id, imgui.ImVec2(130, 0))
				end
				
				
				local new_ip, new_port = u8:decode(im_new_address.v):match("^(.+):(.+)$")
				-- ##
				local str_id = "## connet with new"
				if new_ip and tonumber(new_port) and (#im_new_nickname.v ~= 0) then
					if imgui.Button(LANG.NEW_CONNECT..str_id, imgui.ImVec2(168, 0)) then
						connect(new_ip, tonumber(new_port), u8:decode(im_new_nickname.v))
						imw_menu.v = false
					end
					
				else
					imgui.ButtonDisabled(LANG.NEW_CONNECT..str_id, imgui.ImVec2(168, 0))
				end


				imgui.EndPopup()
			end
			
			if imgui.Button(LANG.NEW_ACCOUNT.."##change popup", imgui.ImVec2(button_w1, button_h1)) then
				imgui.OpenPopup("change popup")
			end
			
			imgui.SameLine()
			
			if sampIsDialogActive() then
				if imgui.ButtonGreen(LANG.ADD_CURRENT_DIALOG.."## add_current_dialog", imgui.ImVec2(button_w1, button_h1)) then
					imw_menu.v = false
					imw_saving.v = true
				end
				
			else
				imgui.ButtonDisabled(LANG.ADD_CURRENT_DIALOG.."## add_current_dialog", imgui.ImVec2(button_w1, button_h1))
			end
			
			
			
			
			--------------- нижние вкладки ----------------
			
			local str_id = "## tab: settings: tabs"
			
			if cfg.current_tab == "settings" then
				
				imgui.NewLine()
			
				if imgui.ButtonActivated(cfg.current_settings_tab == "reconnect", LANG.TAB_SETTINGS_RECONNECT..str_id, imgui.ImVec2(button_w2, button_h2)) then
					cfg.current_settings_tab = "reconnect"
					luacfg.save(cfg, filename_cfg)
				end
				
				imgui.SameLine()
				
				if imgui.ButtonActivated(cfg.current_settings_tab == "autoresponse", LANG.TAB_SETTINGS_AUTORESPONSE..str_id, imgui.ImVec2(button_w2, button_h2)) then
					cfg.current_settings_tab = "autoresponse"
					luacfg.save(cfg, filename_cfg)
				end
				
				imgui.SameLine()
				
				if imgui.ButtonActivated(cfg.current_settings_tab == "other", LANG.TAB_SETTINGS_OTHER..str_id, imgui.ImVec2(button_w2, button_h2)) then
					cfg.current_settings_tab = "other"
					luacfg.save(cfg, filename_cfg)
				end
				
				imgui.SameLine()
				
				if imgui.ButtonActivated(cfg.current_settings_tab == "info", LANG.TAB_SETTINGS_INFO..str_id, imgui.ImVec2(button_w2, button_h2)) then
					cfg.current_settings_tab = "info"
					luacfg.save(cfg, filename_cfg)
				end
			end
			
			
			
			
			
			
			----- TAB: SETTINGS -----
			
			if cfg.current_tab == "settings" then
				imgui.BeginChild("sc_timeout", imgui.ImVec2(0, -50), true)
				
					----------- Реконект ------------------
					if cfg.current_settings_tab == "reconnect" then
						
						--------------- Команды для реконекта ----------------
						imgui.TextColoredRGB(u8"{008800}/sc {0077FF}[sec]", 3)
						imgui.SameLine()
						imgui.SetCursorPosX(65)
						imgui.Text(LANG.SETTINGS_RECONNECT)
						
						
						imgui.TextColoredRGB(u8"{008800}/scd")
						imgui.SameLine()
						imgui.SetCursorPosX(65)
						imgui.Text(LANG.SETTINGS_DISCONNECT)
					
					
						imgui.Separator()
						
						--------------- ручной реконнект ----------------
						imgui.PushItemWidth(45)
						
						-- ##
						local im_int = imgui.ImInt(cfg.sc_timeout)
						local str_id = "## cfg.sc_timeout"
						local result = imgui.InputInt(LANG.SETTINGS_SC_TIMEOUT..str_id, im_int, 0, 0)
						
						if result then
							imgui.EditedItem[str_id] = true
							cfg.sc_timeout = im_int.v
						end
						
						if not imgui.IsItemActive() and imgui.EditedItem[str_id] then	
							imgui.EditedItem[str_id] = nil
							luacfg.save(cfg, filename_cfg)
						end
						imgui.PopItemWidth()
						
						-- ##
						if hkeys.ImguiKeyComboEditor("## hotkeys.reconnect## 1", "## hotkeys.reconnect## 2", hotkeys.reconnect) then
							cfg.combo_reconnect = hkeys.get_keycombo(hotkeys.reconnect)
							luacfg.save(cfg, filename_cfg)
						end
						
						imgui.SameLine()
						
						imgui.Text(LANG.HOTKEY_RECONNECT:format(get_sc_timeout()))
							
						-- ##
						if hkeys.ImguiKeyComboEditor("## hotkeys.disconnect_now## 1", "## hotkeys.disconnect_now## 2", hotkeys.disconnect_now) then
							cfg.combo_disconnect_now = hkeys.get_keycombo(hotkeys.disconnect_now)
							luacfg.save(cfg, filename_cfg)
						end
						
						imgui.SameLine()
						imgui.Text(LANG.HOTKEY_DISCONNECT_NOW)
						
						
						---------------- Авто реконнект ----------------------------
					
						imgui.Separator()
						
						-- ##
						local im_bool = imgui.ImBool(cfg.autoreconnect)
						local str_id = "## cfg.autoreconnect"
						
						if imgui.Checkbox(LANG.SETTINGS_AUTORECONNECT..str_id, im_bool) then
							cfg.autoreconnect = im_bool.v
							luacfg.save(cfg, filename_cfg)
						end
					
					
						imgui.PushItemWidth(45)
						
						-- ##
						local im_int = imgui.ImInt(cfg.disconnect_timeout)
						local str_id = "## cfg.disconnect_timeout"
						local result = imgui.InputInt(LANG.SETTINGS_DISCONNECT_TIMEOUT..str_id, im_int, 0, 0)
						
						if result then
							imgui.EditedItem[str_id] = true
							cfg.disconnect_timeout = im_int.v
						end
						
						if not imgui.IsItemActive() and imgui.EditedItem[str_id] then	
							imgui.EditedItem[str_id] = nil
							luacfg.save(cfg, filename_cfg)
						end
						
						-- ##
						local im_int = imgui.ImInt(cfg.lost_connection_timeout)
						local str_id = "## cfg.lost_connection_timeout"
						local result = imgui.InputInt(LANG.SETTINGS_LOST_CONNECTION_TIMEOUT..str_id, im_int, 0, 0)
						
						if result then
							imgui.EditedItem[str_id] = true
							cfg.lost_connection_timeout = im_int.v
						end
						
						if not imgui.IsItemActive() and imgui.EditedItem[str_id] then	
							imgui.EditedItem[str_id] = nil
							luacfg.save(cfg, filename_cfg)
						end
						
						
						-- ##
						local im_int = imgui.ImInt(cfg.banned_ip_timeout)
						local str_id = "## cfg.banned_ip_timeout"
						local result = imgui.InputInt(LANG.SETTINGS_BANNED_IP_TIMEOUT..str_id, im_int, 0, 0)
						
						if result then
							imgui.EditedItem[str_id] = true
							cfg.banned_ip_timeout = im_int.v
						end
						
						if not imgui.IsItemActive() and imgui.EditedItem[str_id] then	
							imgui.EditedItem[str_id] = nil
							luacfg.save(cfg, filename_cfg)
						end
							
						imgui.PopItemWidth()
						
						
						-------------- Пауза ------------------------
						
						imgui.Separator()
						
						local im_bool = imgui.ImBool(cfg.pause)
						local str_id = "## cfg.pause"
						
						if imgui.Checkbox(LANG.SETTINGS_PAUSE..str_id, im_bool) then
							cfg.pause = im_bool.v
							luacfg.save(cfg, filename_cfg)
						end
						
					
						imgui.PushItemWidth(23)
						imgui.PushStyleVar(imgui.StyleVar.ItemSpacing, imgui.ImVec2(0, 0))
							local im_int = imgui.ImInt(cfg.pause_from_hour)
							local str_id = "## cfg.pause_from_hour"
							local result = imgui.InputInt(str_id, im_int, 0, 0)
							
							if result then
								imgui.EditedItem[str_id] = true
								cfg.pause_from_hour = im_int.v
							end
							
							if not imgui.IsItemActive() and imgui.EditedItem[str_id] then	
								imgui.EditedItem[str_id] = nil
								luacfg.save(cfg, filename_cfg)
							end
							
							imgui.SameLine()
							imgui.Text(u8" : ")
							
							imgui.SameLine()
							local im_int = imgui.ImInt(cfg.pause_from_min)
							local str_id = "## cfg.pause_from_min"
							local result = imgui.InputInt(str_id, im_int, 0, 0)
							
							if result then
								imgui.EditedItem[str_id] = true
								cfg.pause_from_min = im_int.v
							end
							
							if not imgui.IsItemActive() and imgui.EditedItem[str_id] then	
								imgui.EditedItem[str_id] = nil
								luacfg.save(cfg, filename_cfg)
							end
							
							imgui.SameLine()
							imgui.Text(u8"  -  ")
							
							imgui.SameLine()
							local im_int = imgui.ImInt(cfg.pause_to_hour)
							local str_id = "## cfg.pause_to_hour"
							local result = imgui.InputInt(str_id, im_int, 0, 0)
							
							if result then
								imgui.EditedItem[str_id] = true
								cfg.pause_to_hour = im_int.v
							end
							
							if not imgui.IsItemActive() and imgui.EditedItem[str_id] then	
								imgui.EditedItem[str_id] = nil
								luacfg.save(cfg, filename_cfg)
							end
							
							imgui.SameLine()
							imgui.Text(u8" : ")
							
							
							imgui.SameLine()
							imgui.PopStyleVar()
							
							local im_int = imgui.ImInt(cfg.pause_to_min)
							local str_id = "## cfg.pause_to_min"
							local result = imgui.InputInt(LANG.SETTINGS_PAUSE_TIME..str_id, im_int, 0, 0)
							
							if result then
								imgui.EditedItem[str_id] = true
								cfg.pause_to_min = im_int.v
							end
							
							if not imgui.IsItemActive() and imgui.EditedItem[str_id] then	
								imgui.EditedItem[str_id] = nil
								luacfg.save(cfg, filename_cfg)
							end
							
							
						imgui.PopItemWidth()
						
						imgui.Separator()
						
						-------------- Таймаут на подключение -----
						-- ##
						local im_bool = imgui.ImBool(cfg.use_connecting_timeout)
						local str_id = "## cfg.use_connecting_timeout"
						
						if imgui.Checkbox(str_id, im_bool) then
							cfg.use_connecting_timeout = im_bool.v
							
							set_wib(cfg.wib)
							luacfg.save(cfg, filename_cfg)
						end
						
						imgui.SameLine()
						
						imgui.PushItemWidth(45)
							
						local str_id = "## cfg.connecting_timeout"
						local im_int = im(str_id, imgui.ImInt, cfg.connecting_timeout)
						
						if imgui.InputIntEx(LANG.SETTINGS_CONNECTING_TIMEOUT..str_id, im_int, 0, 0) then
							cfg.connecting_timeout = im_int.v
							luacfg.save(cfg, filename_cfg)
						end
							
						imgui.PopItemWidth()
						
					end
					
					
					
					--------------------- Авто ответ ----------------
					if cfg.current_settings_tab == "autoresponse" then
						local im_bool = imgui.ImBool(cfg.autoresponse)
						local str_id = "## cfg.autoresponse"
						
						if imgui.Checkbox(LANG.SETTINGS_AUTORESPONSE..str_id, im_bool) then
							cfg.autoresponse = im_bool.v
							luacfg.save(cfg, filename_cfg)
						end
						
						imgui.PushItemWidth(45)
							local im_int = imgui.ImInt(cfg.autoresponse_delay)
							local str_id = "## cfg.autoresponse_delay"
							local result = imgui.InputInt(LANG.SETTINGS_AUTORESPONSE_DELAY..str_id, im_int, 0, 0)
							
							if result then
								imgui.EditedItem[str_id] = true
								cfg.autoresponse_delay = im_int.v
							end
							
							if not imgui.IsItemActive() and imgui.EditedItem[str_id] then	
								imgui.EditedItem[str_id] = nil
								luacfg.save(cfg, filename_cfg)
							end
						imgui.PopItemWidth()
					end
					
					--------------------- Прочее --------------
					if cfg.current_settings_tab == "other" then
						imgui.TextColoredRGB(u8"{008800}/scm")
						imgui.SameLine(65)
						imgui.Text(LANG.SETTINGS_MENU)
						
						imgui.TextColoredRGB("{008800}SCMENU")
						imgui.SameLine(65)
						imgui.Text(LANG.SETTINGS_MENU_CHEAT)
						
						
						
						
						
						-- ##
						if hkeys.ImguiKeyComboEditor("## hotkeys.menu## 1", "## hotkeys.menu## 2", hotkeys.menu) then
							cfg.combo_menu = hkeys.get_keycombo(hotkeys.menu)
							luacfg.save(cfg, filename_cfg)
						end
						
						imgui.SameLine()
						
						imgui.Text(LANG.HOTKEY_MENU)
						
						imgui.Separator()
					
						--##
						local im_bool = imgui.ImBool(cfg.fastconnect)
						local str_id = "## cfg.fastconnect"
						
						if imgui.Checkbox(LANG.SETTINGS_FASTCONNECT..str_id, im_bool) then
							cfg.fastconnect = im_bool.v
							set_fastconnect(cfg.fastconnect)
							
							luacfg.save(cfg, filename_cfg)
						end
						
						-- ##
						local im_bool = imgui.ImBool(cfg.wib)
						local str_id = "## cfg.wib"
						
						if imgui.Checkbox(LANG.HOTKEY_WIB..str_id, im_bool) then
							cfg.wib = im_bool.v
							
							set_wib(cfg.wib)
							luacfg.save(cfg, filename_cfg)
						end
						
						local tab = 170
						
						imgui.SameLine(tab)
						
						-- ####
						if hkeys.ImguiKeyComboEditor("## hotkeys.wib## 1", "## hotkeys.wib## 2", hotkeys.wib) then
							cfg.combo_wib = hkeys.get_keycombo(hotkeys.wib)
							luacfg.save(cfg, filename_cfg)
						end	
						
						
						-- ##
						local im_bool = imgui.ImBool(cfg.fix_interior_bug)
						local str_id = "## cfg.fix_interior_bug"
						
						if imgui.Checkbox(LANG.SETTINGS_FIX_INTERIOR_BUG..str_id, im_bool) then
							cfg.fix_interior_bug = im_bool.v
							luacfg.save(cfg, filename_cfg)
						end
						
						imgui.SameLine()
						
						imgui.TextQuestion("( ! )", LANG.SETTINGS_RESTART_REQUIRED)
						
						imgui.Separator()
						
						-- ##
						local im_bool = imgui.ImBool(cfg.hello)
						local str_id = "## cfg.hello"
						
						if imgui.Checkbox(LANG.SETTINGS_HELLO..str_id, im_bool) then
							cfg.hello = im_bool.v
							luacfg.save(cfg, filename_cfg)
						end
						
						-- ##
						local im_bool = imgui.ImBool(cfg.reconnecting_window)
						local str_id = "## cfg.reconnecting_window"
						
						if imgui.Checkbox(LANG.SETTINGS_RECONNECTING_WINDOW..str_id, im_bool) then
							cfg.reconnecting_window = im_bool.v
							luacfg.save(cfg, filename_cfg)
						end
						
						-- ##
						local im_bool = imgui.ImBool(cfg.notif)
						local str_id = "## cfg.notif"
						
						if imgui.Checkbox(LANG.SETTINGS_NOTIF..str_id, im_bool) then
							cfg.notif = im_bool.v
							luacfg.save(cfg, filename_cfg)
						end
						
						-- ##
						local im_bool = imgui.ImBool(cfg.save_button)
						local str_id = "## cfg.save_button"
						
						if imgui.Checkbox(LANG.SETTINGS_SAVE_BUTTON..str_id, im_bool) then
							cfg.save_button = im_bool.v
							luacfg.save(cfg, filename_cfg)
						end
						
						
						-- ##
						local im_bool = imgui.ImBool(cfg.cmds)
						local str_id = "## cfg.cmds"
						
						if imgui.Checkbox(LANG.HOTKEY_CMDS..str_id, im_bool) then
							cfg.cmds = im_bool.v
							set_cmds(cfg.cmds)
							
							luacfg.save(cfg, filename_cfg)
						end
						
						imgui.SameLine(tab)
						
						-- ####
						if hkeys.ImguiKeyComboEditor("## hotkeys.cmds## 1", "## hotkeys.cmds## 2", hotkeys.cmds) then
							cfg.combo_cmds = hkeys.get_keycombo(hotkeys.cmds)
							luacfg.save(cfg, filename_cfg)
						end
					end
					
					--------------------- Инфо ---------------------
					if cfg.current_settings_tab == "info" then
						
						imgui.TextDisabled(LANG.VERSION..__version__)
							
						if upd_url and upd_version then
							imgui.SameLine()
							if imgui.Link(LANG.DOWNLOAD_NEW_VERSION..upd_version, upd_description) then
								os.execute( ('explorer.exe "%s"'):format(upd_url) )
							end
							
						end		
				
						imgui.TextQuestion(LANG.AUTHOR..__author__, u8[[
	И вот теперь в краю мечты волне навстречу слеза бежит.
	И вздрогнул я, и понял всё: что я искал… и что нашёл.

	Это всё наваждение, это песни сирен.
	Этим ласковым тварям не взять меня в плен!

	Золотые долины, хрустальные небеса…
	Я хочу их увидеть в огне! Прости меня.

	© Argument 5.45]]
						)

						imgui.TextDisabled(LANG.EMAIL..__email__)
						
					end
				
				imgui.EndChild()
				
				--imgui.TextDisabled(LANG_TITL)
				
			
				for index, value in ipairs(LANGS) do
					if imgui.RadioButton(value.LABEL.."## LANG##"..index, cfg.lang_index == index) then
						cfg.lang_index = index
						LANG = value
						luacfg.save(cfg, filename_cfg)
					end	
					imgui.SameLine()
				end
			end
			
			
			----- TAB: ACCOUNTS -----
			
			if cfg.current_tab == "accounts" then
				
				
				imgui.BeginGroup("Left")
					
					----- SERVER LIST -----
					
					imgui.BeginChild("servers", imgui.ImVec2(270, 0), true)
						if cfg.current_server_index > #servers then
							cfg.current_server_index = #servers
						end
						
						if cfg.current_server_index < 1 and #servers > 0 then
							cfg.current_server_index = 1
						end
						
						for server_index, server in ipairs(servers) do
							
							local str_id = "## move_server() ## "..server_index
							if current_moving_server then
								if imgui.RadioButton(str_id, current_moving_server == server_index) then
									move_server(current_moving_server, server_index)
									cfg.current_server_index = server_index
									current_moving_server = nil
									luacfg.save(servers, filename_servers)
								end
								
							else
								if imgui.RadioButton(str_id, current_moving_server == server_index) then
									current_moving_server = server_index
								end
							end
							
							
							imgui.SameLine()
		
							
							if imgui.BeginPopup("server settings "..server_index) then
							
								---------------------------------------------
								--
								---------------------------------------------
							
								imgui.PushItemWidth(180)
									--imgui.SameLine()
									local im_buffer = imgui.ImBuffer(u8(servers[server_index].name), 1024)
									local str_id = "## server.name"
									local result = imgui.InputText(LANG.SERVER_NAME..str_id, im_buffer)
									
									if result then
										imgui.EditedItem[str_id] = true
										servers[server_index].name = u8:decode(im_buffer.v)
									end
									
									if not imgui.IsItemActive() and imgui.EditedItem[str_id] then	
										imgui.EditedItem[str_id] = nil
										luacfg.save(servers, filename_servers)
									end		
								imgui.PopItemWidth()
								
							
								imgui.PushItemWidth(180)
									local im_buffer = imgui.ImBuffer(u8(servers[server_index].ip..":"..servers[server_index].port), 1024)
									local str_id = "## server.ip:server.port"
									local result = imgui.InputText(LANG.SERVER_IP..str_id, im_buffer, imgui.InputTextFlags.AutoSelectAll)
									
									if result then	
										imgui.EditedItem[str_id] = true
										local ip, port = im_buffer.v:match("^(.+):(.+)$")
										
										if ip and tonumber(port) then
											servers[server_index].ip = u8:decode(ip)
											servers[server_index].port = tonumber(port)
										end
									end
									
									if not imgui.IsItemActive() and imgui.EditedItem[str_id] then
										imgui.EditedItem[str_id] = nil
										luacfg.save(servers, filename_servers)
									end
									
									
								imgui.PopItemWidth()

								local ip, port = sampGetCurrentServerAddress()
				
								imgui.SameLine(335)
								local str_id = "## past current address"
								
								
								if u8:decode(im_buffer.v) ~= ip..":"..port then
									if imgui.Button(LANG.NEW_PASTE_CURRENT_IP_PORT..str_id, imgui.ImVec2(130, 0)) then
										--im_buffer.v = u8(ip..":"..port)
										servers[server_index].ip = u8:decode(ip)
										servers[server_index].port = tonumber(port)
										luacfg.save(servers, filename_servers)
									end
									
								else
									imgui.ButtonDisabled(LANG.NEW_PASTE_CURRENT_IP_PORT..str_id, imgui.ImVec2(130, 0))
								end
								
								
								--------------------------------------------------
								--imgui.NewLine()
								imgui.Separator()
								---------------------------------------------------
								
								
								-- ##
								local im_bool = imgui.ImBool(servers[server_index].use_timeouts)
								local str_id = "## server.use_timeouts"
								
								if imgui.Checkbox(LANG.SERVER_USE_TIMEOUTS..str_id, im_bool) then
									servers[server_index].use_timeouts = im_bool.v
									luacfg.save(servers, filename_servers)
								end
								
								
								imgui.PushItemWidth(64)
									
									
									-- ##
									local im_int = imgui.ImInt(servers[server_index].sc_timeout)
									local str_id = "## server.sc_timeout"
									local result = imgui.InputInt(LANG.SERVER_SC_TIMEOUT..str_id, im_int, 0, 0)
									
									if result then
										imgui.EditedItem[str_id] = true
										servers[server_index].sc_timeout = im_int.v
									end
									
									if not imgui.IsItemActive() and imgui.EditedItem[str_id] then	
										imgui.EditedItem[str_id] = nil
										luacfg.save(servers, filename_servers)
									end
									
									-- ##
									local im_int = imgui.ImInt(servers[server_index].disconnect_timeout)
									local str_id = "## server.disconnect_timeout"
									local result = imgui.InputInt(LANG.SERVER_DISCONNECT_TIMEOUT..str_id, im_int, 0, 0)
									
									if result then
										imgui.EditedItem[str_id] = true
										servers[server_index].disconnect_timeout = im_int.v
									end
									
									if not imgui.IsItemActive() and imgui.EditedItem[str_id] then	
										imgui.EditedItem[str_id] = nil
										luacfg.save(servers, filename_servers)
									end
									
									-- ##
									local im_int = imgui.ImInt(servers[server_index].lost_connection_timeout)
									local str_id = "## server.lost_connection_timeout"
									local result = imgui.InputInt(LANG.SERVER_LOST_CONNECTION_TIMEOUT..str_id, im_int, 0, 0)
									
									if result then
										imgui.EditedItem[str_id] = true
										servers[cfg.current_server_index].lost_connection_timeout = im_int.v
									end
									
									if not imgui.IsItemActive() and imgui.EditedItem[str_id] then	
										imgui.EditedItem[str_id] = nil
										luacfg.save(servers, filename_servers)
									end
									
									-- ##
									local im_int = imgui.ImInt(servers[server_index].banned_ip_timeout)
									local str_id = "## server.banned_ip_timeout"
									local result = imgui.InputInt(LANG.SERVER_BANNED_IP_TIMEOUT..str_id, im_int, 0, 0)
									
									if result then
										imgui.EditedItem[str_id] = true
										servers[server_index].banned_ip_timeout = im_int.v
									end
									
									if not imgui.IsItemActive() and imgui.EditedItem[str_id] then	
										imgui.EditedItem[str_id] = nil
										luacfg.save(servers, filename_servers)
									end
									
									
									
								imgui.PopItemWidth()
								
								---------------------------------------------------
								
								
								imgui.NewLine()
								imgui.TextDisabled(LANG.SERVER_CHANGE_NICKNAME)
								imgui.Separator()
								
								
								----------------------------------------------------
								
																
								imgui.PushItemWidth(168)
									local str_id = "## im_new_nickname"
									imgui.InputText(LANG.NEW_NICKNAME..str_id, im_new_nickname) -- imgui.InputTextFlags.AutoSelectAll
								imgui.PopItemWidth()
								
								imgui.SameLine(335)
								
								local current_nickname = sampGetNickname() 
								
								if u8:decode(im_new_nickname.v) ~= current_nickname then
									local str_id = "## paste current nickname"
									if imgui.Button(LANG.NEW_PASTE_CURRENT_NICKNAME..str_id, imgui.ImVec2(130, 0)) then
										im_new_nickname.v = u8(current_nickname)
									end
								
								else
									imgui.ButtonDisabled(LANG.NEW_PASTE_CURRENT_NICKNAME..str_id, imgui.ImVec2(130, 0))
								end
								
								
								local str_id = "## connet with new"
								
								if #im_new_nickname.v ~= 0 then
								
									if imgui.Button(LANG.NEW_CONNECT..str_id, imgui.ImVec2(168, 0)) then
									
										connect(servers[server_index].ip, servers[server_index].port, u8:decode(im_new_nickname.v))
										imw_menu.v = false
									end
									
								else
									imgui.ButtonDisabled(LANG.NEW_CONNECT..str_id, imgui.ImVec2(168, 0))
								end
								
								
								imgui.EndPopup()
							end
							
							if imgui.Button(" ... ##server settings popup "..server_index) then
								imgui.OpenPopup("server settings "..server_index)
							end
							
							
							imgui.SameLine()
							
							if imgui.Selectable(u8(server.name).."## server.name ## "..server_index, server_index == cfg.current_server_index) then
								cfg.current_server_index = server_index
								luacfg.save(cfg, filename_cfg)
							end
							
							
							
			
						end
					imgui.EndChild()
					
					
				imgui.EndGroup()
					
					
					
				imgui.SameLine()
				
				imgui.BeginGroup("Правая часть")
					
					----- SERVER INFO -----
					
					
					
					----- DIALOG LIST ----- 
					
					imgui.BeginChild("dialogs", imgui.ImVec2(0, 0), true)
					
						if servers[cfg.current_server_index] then
							for login_index, login in ipairs(servers[cfg.current_server_index].logins) do
							
								-- ##
								local str_id = "## move_login() ##"..login_index
								if current_moving_login then
									if imgui.RadioButton(str_id, current_moving_login == login_index) then
										move_login(cfg.current_server_index, current_moving_login, login_index)
										current_moving_login = nil
										luacfg.save(servers, filename_servers)
									end
									
								else
									if imgui.RadioButton(str_id, current_moving_login == login_index) then
										current_moving_login = login_index
									end
								end
								
								imgui.SameLine()
								
								if imgui.BeginPopup("login settings## "..login_index) then
										
									-- ##
									local im_buffer = imgui.ImBuffer(u8(login.nickname), 1024)
									local str_id = "## login.nickname ## "..login_index
									local result = imgui.InputText(LANG.NEW_NICKNAME..str_id, im_buffer, imgui.InputTextFlags.AutoSelectAll)
									
									if result then
										imgui.EditedItem[str_id] = true
										login.nickname = u8:decode(im_buffer.v)
									end
									
									if not imgui.IsItemActive() and imgui.EditedItem[str_id] then	
										imgui.EditedItem[str_id] = nil
										luacfg.save(servers, filename_servers)
									end
									
									imgui.EndPopup()
								end
								
								if imgui.Button(" ... ##login settings popup ##"..login_index) then
									imgui.OpenPopup("login settings## "..login_index)
								end
								
								
								
								
								imgui.SameLine()
								local str_id = "## connect to login.nickname ## "..login_index
										
								if imgui.Button(LANG.CONNECT..str_id, imgui.ImVec2(100, 0)) then
									connect(servers[cfg.current_server_index].ip, servers[cfg.current_server_index].port, login.nickname)
								end
								
								
								
								

								
								imgui.SameLine()
								if imgui.CollapsingHeader(u8(login.nickname)) then
									
									
									for dialog_index, dialog in ipairs(login.dialogs) do
										imgui.SetCursorPosX(182)
										

										--##
										if imgui.BeginPopup("dialog settings## "..login_index.." ## "..dialog_index) then
										
											local im_bool = imgui.ImBool(dialog.check_content)
											local str_id = "## dialog.check_content ## "..login_index.." ## "..dialog_index
											
											if imgui.Checkbox(LANG.CHECK_DIALOG_CONTENT..str_id, im_bool) then
												dialog.check_content = im_bool.v
												luacfg.save(servers, filename_servers)
											end
											
											
											-- ##
											local im_bool = imgui.ImBool(dialog.check_title)
											local str_id = "## dialog.check_title ## "..login_index.." ## "..dialog_index
											
											if imgui.Checkbox(LANG.CHECK_DIALOG_TITLE..str_id, im_bool) then
												dialog.check_title = im_bool.v
												luacfg.save(servers, filename_servers)
											end
											
											
											-- ##
											local im_bool = imgui.ImBool(dialog.check_id)
											local str_id = "## dialog.check_id ## "..login_index.." ## "..dialog_index
																		
											if imgui.Checkbox(LANG.CHECK_DIALOG_ID..str_id, im_bool) then
												dialog.check_id = im_bool.v
												luacfg.save(servers, filename_servers)
											end
											
											imgui.Separator()
											
											if dialog.use_gauth then
												local im_buffer = imgui.ImBuffer(u8(dialog.gauth_key), 1024)
												local str_id = "## dialog.gauth_key ## "..login_index.." ## "..dialog_index
												local result = imgui.InputText(LANG.GAUTH_KEY..str_id, im_buffer, imgui.InputTextFlags.AutoSelectAll)
												
												if result then
													imgui.EditedItem[str_id] = true
													dialog.gauth_key = u8:decode(im_buffer.v)
												end
												
												if not imgui.IsItemActive() and imgui.EditedItem[str_id] then	
													imgui.EditedItem[str_id] = nil
													luacfg.save(servers, filename_servers)
												end
												
												
											else
												-- ##
												local im_buffer = imgui.ImBuffer(u8(dialog.response_text), 1024)
												local str_id = "## dialog.response_text ## "..login_index.." ## "..dialog_index
												local result = imgui.InputText(LANG.RESPONSE_TEXT..str_id, im_buffer, imgui.InputTextFlags.AutoSelectAll)
												
												if result then
													imgui.EditedItem[str_id] = true
													dialog.response_text = u8:decode(im_buffer.v)
												end
												
												if not imgui.IsItemActive() and imgui.EditedItem[str_id] then	
													imgui.EditedItem[str_id] = nil
													luacfg.save(servers, filename_servers)
												end
											end
											
											imgui.Text(LANG.RESPONSE_INDEX..dialog.response_index)
											imgui.Text(LANG.RESPONSE_BUTTON..dialog.response_button)
											
											
											imgui.Separator()
											
											-- ##
											local im_bool = imgui.ImBool(dialog.spawn_player or false)
											local str_id = "## dialog.spawn_player ## "..login_index.." ## "..dialog_index
																		
											if imgui.Checkbox(str_id, im_bool) then
												dialog.spawn_player = im_bool.v
												luacfg.save(servers, filename_servers)
											end
											
											imgui.SameLine()
											
											imgui.PushItemWidth(50)
											
											-- #
											local str_id = "## dialog.spawn_delay ## "..login_index.." ## "..dialog_index
											local im_int = im(str_id, imgui.ImInt, dialog.spawn_delay or cfg.spawn_delay)
								
											
											if imgui.InputIntEx(LANG.SAVING_SPAWN_PLAYER..str_id, im_int, 0, 0) then
												dialog.spawn_delay = im_int.v
												luacfg.save(servers, filename_servers)
											end
											
											imgui.PopItemWidth()
											
											imgui.Separator()
											
											imgui.Text(LANG.DIALOG_TITLE..u8(dialog.title))
											imgui.Text(LANG.DIALOG_ID..u8(dialog.id))
											imgui.Text(LANG.DIALOG_STYLE..u8(dialog.style))
											imgui.Text(LANG.DIALOG_TEXT)
											
											imgui.SameLine()
											imgui.TextQuestion("( ? )", u8(dialog.text))
											

											imgui.EndPopup()
										end
										
										if imgui.Button(" ... ##dialog settings popup ##"..login_index.." ## "..dialog_index) then
											imgui.OpenPopup("dialog settings## "..login_index.." ## "..dialog_index)
										end
										
											
										imgui.PushItemWidth(229)	
										
											imgui.SameLine()
											
											-- ##
											local im_buffer = imgui.ImBuffer(u8(dialog.user_title), 1024)
											local str_id = "## dialog.user_title ## "..login_index.." ## "..dialog_index
											local result = imgui.InputText(str_id, im_buffer)
											
											if result then
												imgui.EditedItem[str_id] = true
												dialog.user_title = u8:decode(im_buffer.v)
											end
											
											if not imgui.IsItemActive() and imgui.EditedItem[str_id] then	
												imgui.EditedItem[str_id] = nil
												luacfg.save(servers, filename_servers)
											end
											

										imgui.PopItemWidth()
								
										
										
										
										imgui.SameLine()
										local str_id = "## delete_dialog() ## "..dialog_index
										if imgui.Button(LANG.DELETE_DIALOG..str_id, imgui.ImVec2(0, 0)) then
											delete_dialog(cfg.current_server_index, login_index, dialog_index)
											luacfg.save(servers, filename_servers)
										end
									end
									
									imgui.NewLine()
								end
						
							end
						end
					imgui.EndChild()
				imgui.EndGroup()
			end
			
	
			
			if imgui.IsRootWindowOrAnyChildHovered() then
					
				if imgui.IsMouseDown(0) then		
					local window_pos = imgui.GetWindowPos()
					
					if (not pos_menu) or (pos_menu.x ~= window_pos.x) or (pos_menu.y ~= window_pos.y)  then
						pos_menu = {x = window_pos.x, y = window_pos.y}
					end	
				end
			end
			
		
		imgui.End()
	end
	
end

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then
		return
	end
	
	while not isSampAvailable() do
		wait(0)
	end	

	
	imgui.Process = true
	
	if cfg.fastconnect then
		set_fastconnect(cfg.fastconnect)
	end

	-- AntiAFK 
	local wib_thread = lua_thread.create(
		function()
			while true do
				if cfg.wib then
					set_wib(true)
				end
				wait(1000)
			end
		end
	)
	wib_thread.work_in_pause = true
	wib_thread:run()
	
	local cursor_thread = lua_thread.create_suspended(
		function()
			while true do
				wait(100)
				
				
				ci[0].cbSize = ffi.sizeof('CURSORINFO')
				if IS_WINDOW_ACTIVE and (ffi.C.GetCursorInfo(ci)) then
					--sampAddChatMessage("1", -1)
					if isPauseMenuActive() or ffi.C.GetForegroundWindow() ~= ffi.C.GetActiveWindow() then
						if IS_CURSOR_BLOCKED then
							ClipCursor(false)
							IS_CURSOR_BLOCKED = false
						end
					
					elseif (ci[0].flags == 0) then
						--sampAddChatMessage("2", -1)
						ClipCursor(true)
						--setCenterCursor()
						IS_CURSOR_BLOCKED = true
						
					else
						--sampAddChatMessage("4", -1)
						if IS_CURSOR_BLOCKED then
							ClipCursor(false)
							IS_CURSOR_BLOCKED = false
						end
					end
					
				else
					--sampAddChatMessage("3", -1)
					if IS_CURSOR_BLOCKED then
						ClipCursor(false)
						IS_CURSOR_BLOCKED = false
					end
				end
			end
		end  
	)
	cursor_thread.work_in_pause = true
	cursor_thread:run()
	
	-- Проверяем обновение
	downloadUrlToFile("https://pastebin.com/raw/WaLz0LzP", filename_update,
		function(id, status, p1, p2) 
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
			
				local file = io.open(filename_update, "r")
				if file then
					local filetext_update = file:read("*all")
					file:close()
					os.remove(filename_update)
					
					local update_version, update_url, update_description = filetext_update:match('Sweet Connect\n"(.-)"\n"(.-)"\n"""\n?(.-)"""')
															
					if update_version and (update_version ~= __version__) then
						upd_version = update_version
						upd_url = update_url
						if update_description ~= "" then
							upd_description = update_description
						end
						
						if cfg.hello then
							sampAddChatMessage("• {FF8888}["..MAIN_TITLE.."] {FFFFFF}/"..MAIN_CMD.." | "..LANG.HELLO_NEW_VERSION.." "..upd_version, 0xFFFFFF)
						end
						
					end
				else
					os.remove(filename_update)
				end
			end
		end
	)
	
	im_new_nickname = imgui.ImBuffer(u8(sampGetNickname()), 1024)
	local ip, port = sampGetCurrentServerAddress()
	
	im_new_address = imgui.ImBuffer(u8(ip..":"..port), 1024)
	
	
	hotkeys = {
		reconnect = hkeys.register(cfg.combo_reconnect, hkeys.DOWN, false, cmd_sc),
		disconnect_now = hkeys.register(cfg.combo_disconnect_now, hkeys.DOWN, false, cmd_scd),
		menu = hkeys.register(cfg.combo_menu, hkeys.DOWN, false, function() imw_menu.v = not imw_menu.v end),
		cmds = hkeys.register(cfg.combo_cmds, hkeys.DOWN, false,
			function()
				cfg.cmds = not cfg.cmds
				set_cmds(cfg.cmds)
			end
		),
		
		wib = hkeys.register(cfg.combo_wib, hkeys.DOWN, false,
			function()
				cfg.wib = not cfg.wib
				if cfg.notif then
					if cfg.wib then
						notif_text = LANG.NOTIF_WIB_ON
					else
						notif_text = LANG.NOTIF_WIB_OFF
					end
					
					notif_clock = os.clock()
					imw_notif.v = true
				end
				
				luacfg.save(cfg, filename_cfg)
				
			end
		),
	}
	
	if cfg.cmds then
		set_cmds(true)
	end
	
	
	if cfg.hello then
		sampAddChatMessage("• {FFC800}["..MAIN_TITLE.."] {FFFFFF}/"..MAIN_CMD.." | "..LANG.HELLO_MENU, 0xFFFFFF)
	end
	
	
	while true do
		wait(0)
		
		if testCheat("SCMENU") then
			imw_menu.v = not imw_menu.v
		end
		
		if cfg.use_connecting_timeout and not imw_reconnecting.v then
			if start_connecting and (os.clock()-start_connecting) > (cfg.connecting_timeout / 1000) then
				start_connecting = nil
				cmd_sc(0, true, true)
				--sampAddChatMessage("Время вышло", 0xFF8800)
			end
		end


		if sampIsDialogActive() then
			imw_save_button.v = cfg.save_button
			
		else
			imw_save_button.v = false
			imw_saving.v = false
			user_title = nil
			gauth_key = nil
			use_gauth = nil
		end	
		
		
		imgui.ShowCursor = imw_menu.v or imw_saving.v or imw_save_button.v or imw_reconnecting.v

	end
end
