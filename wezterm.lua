local wezterm = require('wezterm')

-- Leader Active
wezterm.on("update-right-status", function(window)
  local leader = ""
  if window:leader_is_active() then
    leader = "LEADER"
  end
  window:set_right_status(leader)
end);

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


local function font_fb(font, params)
	local names = {font, "Noto Color Emoji", "JetBrains Mono"}
	return wezterm.font_with_fallback(names, params)
end

return {
	animation_fps = 144,
  check_for_updates = true,

	-- Aesthetics
	front_end = "OpenGL",
	font=font_fb('Hurmit Nerd Font'),
	font_size = 10,
	line_height = 0.9,
	color_scheme = "Wryan",

	-- Exit behavior
	window_close_confirmation = "NeverPrompt",
	exit_behavior = "Close",

	-- Tab Bar below and usually hidden
	use_fancy_tab_bar = true,
	window_frame = {
		font = font_fb('scientifica'),
		font_size = 13.0,
	},

	hide_tab_bar_if_only_one_tab = false,
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
	window_background_opacity = 0.95,
	window_background_image_hsb = {
    brightness = 0.025,
    hue = 1.0,
    saturation = 0.35,
  },

	-- Disable default keybindings
	disable_default_key_bindings = true,
	canonicalize_pasted_newlines = false,

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
		{ key = '=', mods = "CTRL", action = "IncreaseFontSize"},
		{ key = '-', mods = "CTRL", action = "DecreaseFontSize"},
		{ key = '`', mods = "CTRL", action = "ResetFontSize" },

		--- Extra
		-- Toggle Opacity
		{key = "t", mods = "LEADER", action = wezterm.action {EmitEvent = "toggle-opacity"}},

		-- Copy paste
		{key = "c", mods = "CTRL|SHIFT", action = wezterm.action { CopyTo="Clipboard"}},
		{key = "v", mods = "CTRL|SHIFT", action = wezterm.action { PasteFrom="Clipboard" }},

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

