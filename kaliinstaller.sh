#!/usr/bin/env bash

# Colors
CRE=$(tput setaf 1)    # Red
CYE=$(tput setaf 3)    # Yellow
CGR=$(tput setaf 2)    # Green
CBL=$(tput setaf 4)    # Blue
BLD=$(tput bold)       # Bold
CNC=$(tput sgr0)       # Reset colors

# Global vars
backup_folder=~/.RiceBackup
ERROR_LOG="$HOME/RiceError.log"

# Logo function (unchanged)
logo() {
    local text="${1:?}"
    echo -en "
                %%%
         %%%%%//%%%%%
       %%************%%%
   (%%//############*****%%
  %%%%**###&&&&&&&&&###**//
  %%(**##&&&#########&&&##**
  %%(**##*****#####*****##**%%%
  %%(**##     *****     ##**
    //##   @@**   @@   ##//
      ##     **###     ##
      #######     #####//
        ###**&&&&&**###
        &&&         &&&
        &&&////   &&
           &&//@@@**
             ..***

    ${BLD}${CRE}[ ${CYE}${text} ${CRE}]${CNC}\n\n"
}

# Handle errors
log_error() {
    local error_msg="$1"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[${timestamp}] ERROR: ${error_msg}" >> "$ERROR_LOG"
    printf "%s%sERROR:%s %s\n" "${CRE}" "${BLD}" "${CNC}" "${error_msg}" >&2
}

# Initial checks
initial_checks() {
    if [ "$(id -u)" = 0 ]; then
        log_error "This script MUST NOT be run as root user."
        exit 1
    fi

    if [ "$PWD" != "$HOME" ]; then
        log_error "The script must be executed from HOME directory."
        exit 1
    fi

    if ! ping -q -c 1 -W 1 8.8.8.8 &>/dev/null; then
        log_error "No internet connection detected."
        exit 1
    fi
}

# Check if a package is installed
is_installed() {
    dpkg -l "$1" &> /dev/null
}

# Welcome message
welcome() {
    clear
    logo "Welcome $USER"
    echo -en "${BLD}${CGR}This script will install my dotfiles and this is what it will do:${CNC}

    ${BLD}${CGR}[${CYE}i${CGR}]${CNC} Install necessary dependencies
    ${BLD}${CGR}[${CYE}i${CGR}]${CNC} Download my dotfiles in ${HOME}/dotfiles
    ${BLD}${CGR}[${CYE}i${CGR}]${CNC} Backup of possible existing configurations (bspwm, polybar, etc...)
    ${BLD}${CGR}[${CYE}i${CGR}]${CNC} Install my configuration
    ${BLD}${CGR}[${CYE}i${CGR}]${CNC} Enabling MPD service (Music player daemon)
    ${BLD}${CGR}[${CYE}i${CGR}]${CNC} Change your shell to zsh shell

    ${BLD}${CGR}[${CRE}!${CGR}]${CNC} ${BLD}${CRE}My dotfiles DO NOT modify any of your system configurations${CNC}
    ${BLD}${CGR}[${CRE}!${CGR}]${CNC} ${BLD}${CRE}This script does NOT have the potential power to break your system${CNC}
    "
    local yn
    while true; do
        read -rp " ${BLD}${CGR}Do you wish to continue?${CNC} [y/N]: " yn
        case "${yn,,}" in
            y|yes) return 0 ;;
            n|no|"") echo -e "\n${BLD}${CYE}Operation cancelled${CNC}"; exit 0 ;;
            *) echo -e "\n${BLD}${CRE}Error:${CNC} Just write '${BLD}${CYE}y${CNC}' or '${BLD}${CYE}n${CNC}'\n" ;;
        esac
    done
}

# Install dependencies
install_dependencies() {
    clear
    logo "Installing needed packages from official repositories..."
    sleep 2

    local dependencies=(
        alacritty build-essential bat brightnessctl bspwm clipcat dunst eza feh fzf thunar
        tumbler gvfs-mtp firefox geany git imagemagick jq jgmenu kitty libwebp maim
        mpc mpd mpv neovim ncmpcpp npm pamixer papirus-icon-theme
        picom playerctl polybar policykit-1-gnome python3-gi redshift rofi rustup
        sxhkd tmux xclip xdg-user-dirs xdo xdotool xsettingsd xorg-xdpyinfo
        xorg-xkill xorg-xprop xorg-xrandr xorg-xsetroot xorg-xwininfo
        ttf-inconsolata fonts-jetbrains-mono fonts-jetbrains-mono-nerd fonts-terminus-nerd
        fonts-ubuntu fonts-webp-pixbuf-loader
    )

    echo -e "\n${BLD}${CBL}Checking for required packages...${CNC}\n"
    sleep 2

    local missing_pkgs=()
    for pkg in "${dependencies[@]}"; do
        if ! is_installed "$pkg"; then
            missing_pkgs+=("$pkg")
            echo -e " ${BLD}${CYE}${pkg} ${CRE}not installed${CNC}"
        else
            echo -e "${BLD}${CGR}${pkg} ${CBL}already installed${CNC}"
        fi
    done

    if ((${#missing_pkgs[@]} > 0)); then
        echo -e "\n${BLD}${CYE}Installing ${#missing_pkgs[@]} packages...${CNC}\n"
        if sudo apt-get install -y "${missing_pkgs[@]}" >> "$ERROR_LOG" 2>&1; then
            local failed_pkgs=()
            for pkg in "${missing_pkgs[@]}"; do
                if ! is_installed "$pkg"; then
                    failed_pkgs+=("$pkg")
                    log_error "Failed to install: $pkg"
                fi
            done

            if ((${#failed_pkgs[@]} == 0)); then
                echo -e "${BLD}${CGR}All packages installed successfully!${CNC}\n\n"
            else
                echo -e "${BLD}${CRE}Failed to install ${#failed_pkgs[@]} packages:${CNC}\n"
                echo -e "  ${BLD}${CYE}${failed_pkgs[*]}${CNC}\n\n"
            fi
        else
            log_error "Critical error during batch installation"
            echo -e "${BLD}${CRE}Installation failed! Check log for details${CNC}\n"
            return 1
        fi
    else
        echo -e "\n${BLD}${CGR}All dependencies are already installed!${CNC}"
    fi

    sleep 3
}

# Clone dotfiles repository
clone_dotfiles() {
    clear
    logo "Downloading dotfiles"
    local repo_url="https://github.com/gh0stzk/dotfiles"
    local repo_dir="$HOME/dotfiles"
    local timestamp=$(date +%Y%m%d-%H%M%S)
    sleep 3

    if [[ -d "$repo_dir" ]]; then
        local backup_dir="${repo_dir}_${timestamp}"
        echo -en "${BLD}${CYE}Existing repository found - renaming to: ${CBL}${backup_dir}${CNC}\n"
        if ! mv -v "$repo_dir" "$backup_dir" >> "$ERROR_LOG" 2>&1; then
            log_error "Failed to rename existing repository"
            echo -en "${BLD}${CRE}Renaming failed! Check${CYE}RiceError.log${CNC}\n"
            return 1
        fi
        echo -en "${BLD}${CGR}Repository successfully renamed for backup${CNC}\n\n"
    fi

    echo -en "${BLD}${CYE}Cloning dotfiles from: ${CBL}${repo_url}${CNC}\n"
    if git clone --depth=1 "$repo_url" "$repo_dir" >> "$ERROR_LOG" 2>&1; then
        echo -en "${BLD}${CGR}Dotfiles cloned successfully!${CNC}\n\n"
    else
        log_error "Repository clone failed"
        echo -en "${BLD}${CRE}Clone failed! Check ${CYE}RiceError.log${CNC}\n"
        return 1
    fi

    sleep 3
}

# Backup existing configuration
backup_existing_config() {
    clear
    logo "Backup files"
    local date=$(date +%Y%m%d-%H%M%S)
    sleep 2

    declare -g try_nvim try_firefox
    while true; do
        read -rp "${BLD}${CYE}Do you want to use my Neovim setup?${CNC} [y/N]: " try_nvim
        case "${try_nvim,,}" in
            y|n) break ;;
            *) echo " ${BLD}${CRE}Error:${CNC} write 'y' or 'n'" ;;
        esac
    done

    while true; do
        read -rp "${BLD}${CYE}Do you want to use my Firefox theme?${CNC} [y/N]: " try_firefox
        case "${try_firefox,,}" in
            y|n) break ;;
            *) echo " ${BLD}${CRE}Error:${CNC} write 'y' or 'n'" ;;
        esac
    done

    mkdir -p "$backup_folder" 2>> "$ERROR_LOG"
    echo -en "\n${BLD}${CYE}Backup directory: ${CBL}${backup_folder}${CNC}\n\n"
    sleep 2

    backup_item() {
        local type=$1 path=$2 target=$3
        local base_name=$(basename "$path")

        if [ -$type "$path" ]; then
            if mv "$path" "$backup_folder/${target}_${date}" 2>> "$ERROR_LOG"; then
                echo -en "${BLD}${CGR}${base_name} ${CBL}backup successful${CNC}\n"
            else
                log_error "Error backup: $base_name"
                echo -en "${BLD}${CRE}${base_name} ${CYE}backup failed${CNC}\n"
            fi
            sleep 0.5
        else
            echo -en "${BLD}${CYE}${base_name} ${CBL}not found${CNC}\n"
            sleep 0.3
        fi
    }

    local config_folders=(bspwm alacritty clipcat picom rofi eww sxhkd dunst kitty polybar geany gtk-3.0 ncmpcpp yazi tmux zsh mpd)
    for folder in "${config_folders[@]}"; do
        backup_item d "$HOME/.config/$folder" "$folder"
    done

    if [[ "${try_nvim,,}" == "y" ]]; then
        backup_item d "$HOME/.config/nvim" "nvim"
    fi

    if [[ "${try_firefox,,}" == "y" ]]; then
        if [ ! -d "$HOME/.mozilla" ]; then
            echo -en "${BLD}${CYE}Creating Firefox profile...${CNC}\n"
            timeout 1s firefox --headless --display=0 >/dev/null 2>&1
            sleep 1
        fi

        local firefox_profile=$(find "$HOME/.mozilla/firefox" -maxdepth 1 -type d -name '*.default-release' 2>/dev/null | head -1)
        if [ -n "$firefox_profile" ]; then
            backup_item d "${firefox_profile}/chrome" "chrome"
            backup_item f "${firefox_profile}/user.js" "user.js"
        fi
    fi

    local single_files=("$HOME/.zshrc" "$HOME/.gtkrc-2.0" "$HOME/.icons")
    for item in "${single_files[@]}"; do
        if [[ "$item" == *".icons" ]]; then
            backup_item d "$item" ".icons"
        else
            backup_item f "$item" "$(basename "$item")"
        fi
    done

    echo -en "\n${BLD}${CGR}Backup completed!${CNC}\n\n"
    sleep 3
}

# Install dotfiles
install_dotfiles() {
    clear
    logo "Installing dotfiles.."
    echo -en "${BLD}${CBL} Copying files to respective directories...${CNC}\n\n"
    sleep 2

    local required_dirs=("$HOME/.config" "$HOME/.local/bin" "$HOME/.local/share")
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir" 2>> "$ERROR_LOG" && \
            echo -en "${BLD}${CGR}Created directory: ${CBL}${dir}${CNC}\n"
        fi
    done

    copy_files() {
        local source="$1"
        local target="$2"
        local item_name=$(basename "$source")

        if cp -R "$source" "$target" 2>> "$ERROR_LOG"; then
            echo -en "${BLD}${CYE}${item_name} ${CGR}copied successfully!${CNC}\n"
            return 0
        else
            log_error "Failed to copy: $item_name"
            echo -en "${BLD}${CYE}${item_name} ${CRE}copy failed!${CNC}\n"
            return 1
        fi
    }

    local config_source="$HOME/dotfiles/config"
    for config_dir in "$config_source"/*; do
        local dir_name=$(basename "$config_dir")
        [[ "$dir_name" == "nvim" && "$try_nvim" != "y" ]] && continue
        copy_files "$config_dir" "$HOME/.config/"
        sleep 0.3
    done

    local misc_items=("applications" "asciiart" "fonts" "startup-page" "bin")
    for item in "${misc_items[@]}"; do
        local source_path="$HOME/dotfiles/misc/$item"
        local target_path="$HOME/.local/share/"
        [[ "$item" == "bin" ]] && target_path="$HOME/.local/"
        copy_files "$source_path" "$target_path"
        sleep 0.3
    done

    if [[ "$try_firefox" == "y" ]]; then
        local firefox_profile=$(find "$HOME/.mozilla/firefox" -maxdepth 1 -type d -name '*.default-release' 2>/dev/null | head -n1)
        if [ -n "$firefox_profile" ]; then
            mkdir -p "$firefox_profile/chrome" 2>> "$ERROR_LOG"
            for item in "$HOME/dotfiles/misc/firefox/"*; do
                if [ -e "$item" ]; then
                    local item_name=$(basename "$item")
                    local target="$firefox_profile"
                    if [[ "$item_name" == "chrome" ]]; then
                        for chrome_item in "$item"/*; do
                            copy_files "$chrome_item" "$firefox_profile/chrome/"
                        done
                    else
                        copy_files "$item" "$target/"
                    fi
                fi
            done

            local user_js="$firefox_profile/user.js"
            local startup_cfg="$HOME/.local/share/startup-page/config.js"
            if [ -f "$user_js" ]; then
                sed -i "s|/home/z0mbi3|/home/$USER|g" "$user_js" 2>> "$ERROR_LOG" && \
                echo -en "${BLD}${CGR}Firefox config updated!${CNC}\n"
            fi
            if [ -f "$startup_cfg" ]; then
                sed -i "s/name: 'gh0stzk'/name: '$USER'/" "$startup_cfg" 2>> "$ERROR_LOG" && \
                echo -en "${BLD}${CGR}Startup page updated!${CNC}\n"
            fi
        else
            log_error "Firefox profile not found"
            echo -en "${BLD}${CRE}Firefox profile not found!${CNC}\n"
        fi
    fi

    local home_files=("$HOME/dotfiles/home/.zshrc" "$HOME/dotfiles/home/.gtkrc-2.0" "$HOME/dotfiles/home/.icons")
    for file in "${home_files[@]}"; do
        copy_files "$file" "$HOME/"
    done

    if fc-cache -rv >/dev/null 2>&1; then
        echo -en "\n${BLD}${CGR}Font cache updated successfully!${CNC}\n"
    else
        log_error "Failed to update font cache"
    fi

    if [[ ! -e "$HOME/.config/user-dirs.dirs" ]]; then
        if xdg-user-dirs-update >/dev/null 2>&1; then
            echo -en "${BLD}${CGR}Xdg dirs generated successfully!${CNC}\n"
        else
            log_error "Failed to generate xdg dirs"
        fi
    fi

    echo -en "\n${BLD}${CGR}Dotfiles installed successfully!${CNC}\n"
    sleep 3
}

# Configure Services
configure_services() {
    clear
    logo "Configuring Services"
    local picom_config="$HOME/.config/bspwm/src/config/picom.conf"
    sleep 2

    if systemctl is-enabled --quiet mpd.service; then
        printf "%s%sDisabling global MPD service...%s\n" "${BLD}" "${CYE}" "${CNC}"
        if sudo systemctl disable --now mpd.service >> "$ERROR_LOG" 2>&1; then
            echo -en "${BLD}${CGR}Global MPD service disabled successfully${CNC}"
        else
            log_error "Failed to disable global MPD service"
            echo -en "${BLD}${CRE}
