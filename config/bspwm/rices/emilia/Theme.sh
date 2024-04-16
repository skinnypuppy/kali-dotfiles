#!/usr/bin/env bash
#  ███████╗███╗   ███╗██╗██╗     ██╗ █████╗     ██████╗ ██╗ ██████╗███████╗
#  ██╔════╝████╗ ████║██║██║     ██║██╔══██╗    ██╔══██╗██║██╔════╝██╔════╝
#  █████╗  ██╔████╔██║██║██║     ██║███████║    ██████╔╝██║██║     █████╗
#  ██╔══╝  ██║╚██╔╝██║██║██║     ██║██╔══██║    ██╔══██╗██║██║     ██╔══╝
#  ███████╗██║ ╚═╝ ██║██║███████╗██║██║  ██║    ██║  ██║██║╚██████╗███████╗
#  ╚══════╝╚═╝     ╚═╝╚═╝╚══════╝╚═╝╚═╝  ╚═╝    ╚═╝  ╚═╝╚═╝ ╚═════╝╚══════╝
#  Author  :  z0mbi3
#  Url     :  https://github.com/gh0stzk/dotfiles
#  About   :  This file will configure and launch the rice.
#

# Set bspwm configuration for Emilia
set_bspwm_config() {
	bspc config border_width 0
	bspc config top_padding 56
	bspc config bottom_padding 2
	bspc config left_padding 2
	bspc config right_padding 2
	bspc config normal_border_color "#414868"
	bspc config active_border_color "#c0caf5"
	bspc config focused_border_color "#bb9af7"
	bspc config presel_feedback_color "#7aa2f7"
}

# Reload terminal colors
set_term_config() {
	cat >"$HOME"/.config/alacritty/rice-colors.toml <<EOF
# (Tokyo Night) color scheme for Emilia Rice

# Default colors
[colors.primary]
background = "#1a1b26"
foreground = "#c0caf5"

# Cursor colors
[colors.cursor]
cursor = "#c0caf5"
text = "#1a1b26"

# Normal colors
[colors.normal]
black = "#15161e"
blue = "#7aa2f7"
cyan = "#7dcfff"
green = "#9ece6a"
magenta = "#bb9af7"
red = "#f7768e"
white = "#a9b1d6"
yellow = "#e0af68"

# Bright colors
[colors.bright]
black = "#414868"
blue = "#7aa2f7"
cyan = "#7dcfff"
green = "#9ece6a"
magenta = "#bb9af7"
red = "#f7768e"
white = "#c0caf5"
yellow = "#e0af68"
EOF
}

# Set kitty colorscheme
set_kitty_config() {
  cat >"$HOME"/.config/kitty/current-theme.conf <<EOF
## This file is autogenerated, do not edit it, instead edit the Theme.sh file inside the rice directory.
## (Tokyo Night) color scheme for Emilia Rice


# The basic colors
foreground              #c0caf5
background              #1a1b26
selection_foreground    #24273A
selection_background    #F4DBD6

# Cursor colors
cursor                  #c0caf5
cursor_text_color       #1a1b26

# URL underline color when hovering with mouse
url_color               #7aa2f7

# Kitty window border colors
active_border_color     #bb9af7
inactive_border_color   #414868
bell_border_color       #e0af68

# Tab bar colors
active_tab_foreground   #1a1b26
active_tab_background   #bb9af7
inactive_tab_foreground #a9b1d6
inactive_tab_background #15161e
tab_bar_background      #1a1b26

# The 16 terminal colors

# black
color0 #15161e
color8 #414868

# red
color1 #f7768e
color9 #f7768e

# green
color2  #9ece6a
color10 #9ece6a

# yellow
color3  #e0af68
color11 #e0af68

# blue
color4  #7aa2f7
color12 #7aa2f7

# magenta
color5  #bb9af7
color13 #bb9af7

# cyan
color6  #7dcfff
color14 #7dcfff

# white
color7  #a9b1d6
color15 #c0caf5
EOF

killall -USR1 kitty
}

# Set compositor configuration
set_picom_config() {
	sed -i "$HOME"/.config/bspwm/picom.conf \
		-e "s/normal = .*/normal =  { fade = true; shadow = true; }/g" \
		-e "s/shadow-color = .*/shadow-color = \"#000000\"/g" \
		-e "s/corner-radius = .*/corner-radius = 6/g" \
		-e "s/\".*:class_g = 'Alacritty'\"/\"100:class_g = 'Alacritty'\"/g" \
		-e "s/\".*:class_g = 'kitty'\"/\"100:class_g = 'kitty'\"/g" \
		-e "s/\".*:class_g = 'FloaTerm'\"/\"100:class_g = 'FloaTerm'\"/g"
}

# Set dunst notification daemon config
set_dunst_config() {
	sed -i "$HOME"/.config/bspwm/dunstrc \
		-e "s/transparency = .*/transparency = 0/g" \
		-e "s/frame_color = .*/frame_color = \"#1a1b26\"/g" \
		-e "s/separator_color = .*/separator_color = \"#c0caf5\"/g" \
		-e "s/font = .*/font = JetBrainsMono NF Medium 9/g" \
		-e "s/foreground='.*'/foreground='#f9f9f9'/g"

	sed -i '/urgency_low/Q' "$HOME"/.config/bspwm/dunstrc
	cat >>"$HOME"/.config/bspwm/dunstrc <<-_EOF_
		[urgency_low]
		timeout = 3
		background = "#1a1b26"
		foreground = "#c0caf5"

		[urgency_normal]
		timeout = 6
		background = "#1a1b26"
		foreground = "#c0caf5"

		[urgency_critical]
		timeout = 0
		background = "#1a1b26"
		foreground = "#c0caf5"
	_EOF_
}

# Set eww colors
set_eww_colors() {
	cat >"$HOME"/.config/bspwm/eww/colors.scss <<EOF
// Eww colors for Emilia rice
\$bg: #1a1b26;
\$bg-alt: #222330;
\$fg: #c0caf5;
\$black: #414868;
\$lightblack: #262831;
\$red: #f7768e;
\$blue: #7aa2f7;
\$cyan: #7dcfff;
\$magenta: #bb9af7;
\$green: #9ece6a;
\$yellow: #e0af68;
\$archicon: #0f94d2;
EOF
}

# Set jgmenu colors for Emilia
set_jgmenu_colors() {
	sed -i "$HOME"/.config/bspwm/jgmenurc \
		-e 's/color_menu_bg = .*/color_menu_bg = #1a1b26/' \
		-e 's/color_norm_fg = .*/color_norm_fg = #c0caf5/' \
		-e 's/color_sel_bg = .*/color_sel_bg = #222330/' \
		-e 's/color_sel_fg = .*/color_sel_fg = #c0caf5/' \
		-e 's/color_sep_fg = .*/color_sep_fg = #414868/'
}

# Set Rofi launcher config
set_launcher_config() {
	sed -i "$HOME/.config/bspwm/scripts/Launcher.rasi" \
		-e '22s/\(font: \).*/\1"JetBrainsMono NF Bold 9";/' \
		-e 's/\(background: \).*/\1#1A1B26;/' \
		-e 's/\(background-alt: \).*/\1#1A1B26E0;/' \
		-e 's/\(foreground: \).*/\1#c0caf5;/' \
		-e 's/\(selected: \).*/\1#7aa2f7;/' \
		-e "s/rices\/[[:alnum:]\-]*/rices\/${RICETHEME}/g"

	# NetworkManager launcher
	sed -i "$HOME/.config/bspwm/scripts/NetManagerDM.rasi" \
		-e '12s/\(background: \).*/\1#1A1B26;/' \
		-e '13s/\(background-alt: \).*/\1#222330;/' \
		-e '14s/\(foreground: \).*/\1#c0caf5;/' \
		-e '15s/\(selected: \).*/\1#7aa2f7;/' \
		-e '16s/\(active: \).*/\1#9ece6a;/' \
		-e '17s/\(urgent: \).*/\1#f7768e;/'

	# WallSelect menu colors
	sed -i "$HOME/.config/bspwm/scripts/WallSelect.rasi" \
		-e 's/\(main-bg: \).*/\1#1A1B26E6;/' \
		-e 's/\(main-fg: \).*/\1#C0CAF5;/' \
		-e 's/\(select-bg: \).*/\1#7aa2f7;/' \
		-e 's/\(select-fg: \).*/\1#1A1B26;/'
}

# Launch the bar
launch_bars() {

	for mon in $(polybar --list-monitors | cut -d":" -f1); do
		MONITOR=$mon polybar -q emi-bar -c "${rice_dir}"/config.ini &
	done

}

### ---------- Apply Configurations ---------- ###

set_bspwm_config
set_term_config
set_kitty_config
set_picom_config
launch_bars
set_eww_colors
set_jgmenu_colors
set_dunst_config
set_launcher_config
