local wezterm = require 'wezterm'
local act = wezterm.action

{{- $t := index .themes .theme }}
local scheme_light = {{ get $t "ghostty_light" | default $t.ghostty | quote }}
local scheme_dark = {{ get $t "ghostty_dark" | default $t.ghostty | quote }}

local appearance = wezterm.gui and wezterm.gui.get_appearance() or 'Dark'

-- Open the WSL distro that chezmoi was applied from. Native Windows chezmoi
-- has no WSL_DISTRO_NAME and uses Ubuntu.
local wsl_distro = {{ env "WSL_DISTRO_NAME" | default "Ubuntu" | quote }}

return {
	-- Remote hosts lack wezterm terminfo; xterm-256color is the portable fallback
	term = 'xterm-256color',
	color_scheme = appearance:find 'Dark' and scheme_dark or scheme_light,
	font_size = 12,
	default_domain = 'WSL:' .. wsl_distro,
	keys = {
		-- Ctrl+Shift+V also pastes. Ctrl+V matches other Windows apps.
		{ key = 'v', mods = 'CTRL', action = act.PasteFrom 'Clipboard' },
	},
}
