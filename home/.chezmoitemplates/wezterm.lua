local wezterm = require 'wezterm'

local scheme_light = {{ (index .themes .theme).ghostty_light | default (index .themes .theme).ghostty | quote }}
local scheme_dark = {{ (index .themes .theme).ghostty_dark | default (index .themes .theme).ghostty | quote }}

local appearance = wezterm.gui and wezterm.gui.get_appearance() or 'Dark'

-- Open the WSL distro that chezmoi was applied from.
local wsl_distro = {{ env "WSL_DISTRO_NAME" | default "Ubuntu" | quote }}

return {
	-- Remote hosts lack wezterm terminfo; xterm-256color is the portable fallback
	term = 'xterm-256color',
	color_scheme = appearance:find 'Dark' and scheme_dark or scheme_light,
	font_size = 12,
	default_domain = 'WSL:' .. wsl_distro,
}
