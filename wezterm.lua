local wezterm = require('wezterm')

-- Determine which computer
local PROFILE = (function()
	local lup = {
		['DESKTOP-DRKGD'] = 'DESKTOP',
		['LAPTOP-DRKGD'] = 'LAPTOP'
	}

	local handle = io.popen("cat /etc/hostname | tr -d '\n'")
	local result = handle:read("*a")
	handle:close()

	return lup[result] or nil
end)()

-- Font sizes
local MIN_FONT_SIZE = (function()
	local lup = {
		['DESKTOP'] = 8.0,
		['LAPTOP'] = 12.0,
	}

	return lup[PROFILE]
end)()

local USE_FONT_SIZE = (function()
	local lup = {
		['DESKTOP'] = 10.0,
		['LAPTOP'] = 14.0,
	}

	return lup[PROFILE]
end)()

local MAX_FONT_SIZE = (function()
	local lup = {
		['DESKTOP'] = 14.0,
		['LAPTOP'] = 16.0,
	}

	return lup[PROFILE]
end)()

local STEP = 1.0 

wezterm.on("update-right-status", function(window) local leader = ""
  if window:leader_is_active() then
    leader = "LEADER"
  end
  window:set_right_status(leader)
end);

-- Decrease font size 
wezterm.on("capped-decreasefontsize", function(window, _)
	local overrides = window:get_config_overrides() or {}
	if not overrides.font_size then
		overrides.font_size = USE_FONT_SIZE - STEP
	else
		overrides.font_size = overrides.font_size - STEP 
	end

	if overrides.font_size < MIN_FONT_SIZE then
		overrides.font_size = MIN_FONT_SIZE end
		
	window:set_config_overrides(overrides)	
end)

-- Increase font size 
wezterm.on("capped-increasefontsize", function(window, _)
	local overrides = window:get_config_overrides() or {}
	if not overrides.font_size then
		overrides.font_size = USE_FONT_SIZE + STEP 
	else
		overrides.font_size = overrides.font_size + STEP 
	end
		
	if overrides.font_size > MAX_FONT_SIZE then
		overrides.font_size = MAX_FONT_SIZE end

	window:set_config_overrides(overrides)	
end)

-- Reset all the current changes to fontsize
wezterm.on("reset-fontsize", function(window, _)
	local overrides = window:get_config_overrides() or {}
	overrides.font_size = nil 

	window:set_config_overrides(overrides)
end)

-- Opacity
wezterm.on("toggle-opacity", function(window, pane)
	local overrides = window:get_config_overrides() or {}
	if not overrides.window_background_opacity then
		-- No opaque-ness
		overrides.window_background_opacity = 1.0
	else
		-- Restore set value
		overrides.window_background_opacity = nil
	end
	window:set_config_overrides(overrides)
end)

-- Local
local ispath = function(p) return p:match"/" end
local tail = function(p) return p:match"[^\\/]*$" end
local basename = function(n) return string.gsub(n or '?', "(.*[/\\])(.*)", "%2") end

local shells = {}
shells["wslhost.exe"] = function(pane) 
	return string.format('WSL-%s', pane.user_vars.WSL_DISTRO_NAME or '?') end

shells["powershell.exe"] = function(pane) 
	return 'PS' end

shells["cmd.exe"] = function(pane)
	return 'CMD' end

-- Known processes (cmd, powershell)
local known_process = {}
known_process["cmd.exe"] = function() return ' 'end
known_process["powershell.exe"] = function() return ' 'end

-- Known commands (nvim, neovim)
local known_exe = {}
known_exe["nvim"] =  function() return '  ' end
known_exe["neovim"] = known_exe["nvim"] 

-- Darken active tab
wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	-- Darken color
	local color = "#323232"
  if tab.is_active then color = "#020202" end

	local p = tab.active_pane
	local title = p.user_vars.panetitle or (function() 
		-- If is known, return most appropriate value
		local eval = known_process[tail(p.foreground_process_name)]
		if eval then return eval(p.title) end

		-- If executable is known
		eval = known_exe[p.title]
		if eval then return eval(p.title) end

		-- If is path	
		if ispath(p.title) then return string.format('%s/  ', tail(p.title)) end

		return string.format('%s', p.title)
	end)()

	local process = (function() 
		if not p.foreground_process_name then return '?' end
	
		-- Not really sure about always being a dialog, but...
		if p.foreground_process_name == '' then return 'dialog' end

		return basename(p.foreground_process_name)
		-- local name = basename(p.foreground_process_name)
		-- return shells[name](p)
	end)()

	local id	= p.pane_id
	local title = string.format("%s %s", process, title or 'default')
	if tab.is_active then title = string.format("* %s", title)
	else title = string.format("%s", title) end

	return {
    {Background={Color=color}},
		{Text = title}
	}
end)

-- TRAP: Can't implement that yet
wezterm.on("send-through-nvim", function(window, pane)

end)

local function font_fb(font)
	-- Main font
	-- Symbols font
	-- Secondary Symbols font
	-- Emoji Font

	local selected_fonts = {
		font,
		-- Do not use Mono, they do not behave like you'd expect
		{ family = "Noto Color Emoji", weight="Regular", stretch="Normal", style="Normal"},
		{ family = "Symbols Nerd Font", weight="Regular", stretch="Normal", style="Normal"},
		-- { family = "Nerd Emoji", weight="Regular", stretch="Normal", style="Normal"}
	}

	return wezterm.font_with_fallback(selected_fonts)
end

return {
	animation_fps = 144,
  check_for_updates = true,
	warn_about_missing_glyphs = false,

	-- Aesthetics
	front_end = "OpenGL",
	-- TODO: Revert this after the presentation
	font = font_fb({family= 'scientifica', weight="Bold"}),						-- Favorite

	font_size = USE_FONT_SIZE,
	adjust_window_size_when_changing_font_size = false,
  freetype_load_flags = "NO_HINTING",
	freetype_load_target = "HorizontalLcd",
	line_height = 0.85,
	color_scheme = "Ollie",

	-- Exit behavior
	window_close_confirmation = "NeverPrompt",
	exit_behavior = "Close",

	-- Tab Bar below and usually hidden
	use_fancy_tab_bar = true,
	window_frame = {
		-- Gohu GohuFont is a bitmap font, no scale allowed
		font = font_fb('Gohu GohuFont'),
		font_size = 10.0,
	},

	hide_tab_bar_if_only_one_tab = true,
	tab_bar_at_bottom = true,
	tab_max_width = 50,

	-- Remove ligatures n' shit
	harfbuzz_features = {"calt=0", "clig=0", "liga=0"},

	-- No bell
	audible_bell = "Disabled"	,

	-- Scroll settings
	scroll_to_bottom_on_input = true,
	scrollback_lines = 10000,

	-- Background
	-- window_background_image = "D:\\hackers_2.jpg",
	text_background_opacity = 1.0,
	window_background_opacity = 0.7,
	window_background_image_hsb = {
    brightness = 0.025,
    hue = 1.0,
    saturation = 0.35,
  },

	inactive_pane_hsb = {
		saturation = 0.4,
		brightness = 0.4
	},

	-- Disable default keybindings
	disable_default_key_bindings = true,
	canonicalize_pasted_newlines = "None",

	-- No padding (distance from edges)
	enable_scroll_bar = false,
	window_padding = {
    left = 0,
    right =  0,
    top = 0,
    bottom = 0,
  },

	--- Keybindings
	-- Debug by running wizterm.exe inside of wizterm
	debug_key_events = false,
	use_dead_keys = false,

	-- Right Ctrl is mapped to Numpad0
	leader = { key = "Numpad0", timeout_milliseconds = 1000},


	keys = {
		--- Panes navigation
		-- Open panes and close pane
		{ key = 's', mods = "LEADER", action = wezterm.action { SplitVertical = { domain = "CurrentPaneDomain"}}},
		{ key = 'v', mods = "LEADER", action = wezterm.action { SplitHorizontal = { domain = "CurrentPaneDomain"}}},
		{ key = "q", mods = "LEADER|SHIFT", action = wezterm.action { CloseCurrentPane = { confirm = false }}},

		{ key = 'z', mods = "LEADER", action = "TogglePaneZoomState" },

		-- Move between panes with ease
		{key = "RightArrow", mods = "LEADER", action = wezterm.action {ActivatePaneDirection = "Right"}},
		{key = "LeftArrow", mods = "LEADER", action = wezterm.action {ActivatePaneDirection = "Left"}},
		{key = "UpArrow", mods = "LEADER", action = wezterm.action {ActivatePaneDirection = "Up"}},
		{key = "DownArrow", mods = "LEADER", action = wezterm.action {ActivatePaneDirection = "Down"}},

		{key = "l", mods = "ALT", action = wezterm.action {ActivatePaneDirection = "Right"}},
		{key = "h", mods = "ALT", action = wezterm.action {ActivatePaneDirection = "Left"}},
		{key = "k", mods = "ALT", action = wezterm.action {ActivatePaneDirection = "Up"}},
		{key = "j", mods = "ALT", action = wezterm.action {ActivatePaneDirection = "Down"}},

		-- Resize pane
		{key = "RightArrow", mods = "ALT|SHIFT", action = wezterm.action {AdjustPaneSize = {"Right", 5}}},
		{key = "LeftArrow", mods = "ALT|SHIFT", action = wezterm.action {AdjustPaneSize = {"Left", 5}}},
		{key = "UpArrow", mods = "ALT|SHIFT", action = wezterm.action {AdjustPaneSize = {"Up", 5}}},
		{key = "DownArrow", mods = "ALT|SHIFT", action = wezterm.action {AdjustPaneSize = {"Down", 5}}},

		--- Navigation between tabs
		-- Navigate or search for a specific tab
		{ key = '/', mods = "LEADER", action = "ShowTabNavigator"},

		-- Spawn tab
		{ key = 'n', mods = 'LEADER', action = wezterm.action { SpawnTab="CurrentPaneDomain"}},
		{ key = 'n', mods = 'CTRL|LEADER', action = wezterm.action { SpawnTab="DefaultDomain"}},

		-- Next or Previous tab
		{ key = 'a', mods = "LEADER", action = wezterm.action { ActivateTabRelative=-1 }},
		{ key = 'f', mods = "LEADER", action = wezterm.action { ActivateTabRelative=1 }},
		{ key = 'q', mods = "LEADER", action = wezterm.action { ActivateTabRelative=-1 }},
		{ key = 'e', mods = "LEADER", action = wezterm.action { ActivateTabRelative=1 }},

		-- Resize font size
		-- TODO: Handle window position before and after fullscreen
		-- FIX: Disabled, bitmap do not support these
		{ key = '=', mods = "CTRL", action = wezterm.action { EmitEvent = 'capped-increasefontsize'}},
		{ key = '-', mods = "CTRL", action = wezterm.action { EmitEvent = 'capped-decreasefontsize'}},
		{ key = '`', mods = "CTRL", action = wezterm.action { EmitEvent = 'reset-fontsize'}},
		{key="r", mods="LEADER", action="ReloadConfiguration"},

		--- Extra
		-- Toggle Opacity
		{key = "t", mods = "LEADER", action = wezterm.action {EmitEvent = "toggle-opacity"}},

		-- Copy paste
		{key = "c", mods = "CTRL|SHIFT", action = wezterm.action { CopyTo="Clipboard"}},
		{key = "v", mods = "CTRL|SHIFT", action = wezterm.action { PasteFrom="Clipboard" }},

		-- Page Up / Page down
		-- TRAP: Binding those will prevent application in-terminal from using them...
    -- {key="PageUp",  action=wezterm.action{ScrollByPage=-0.5}},
    -- {key="PageDown",  action=wezterm.action{ScrollByPage=0.5}},

		-- Debug
    {key="l", mods="CTRL|SHIFT", action="ShowDebugOverlay"},

		-- Toggle fullscreen
		-- TODO: Handle window position before and after fullscreen
    {key="F11", action = "ToggleFullScreen"},

		-- Show launcher with custom flags
		-- {key = 'Enter', mods="LEADER", action = "ShowLauncher"},
		{key = 'Enter', mods="LEADER", action = wezterm.action { ShowLauncherArgs={
				flags='FUZZY|DOMAINS|LAUNCH_MENU_ITEMS'
			}
		}},

		-- Fix Ctrl-Backspace and Ctrl-enter (F36)
		{key = 'Backspace', mods="CTRL", action = wezterm.action { SendString="\x08" } },
		{key = 'Enter', mods="CTRL", action = wezterm.action {SendKey={key="F12", mods="CTRL"}}},
	}
}

