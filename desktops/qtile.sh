#!/usr/bin/env bash

SCRIPTNAME="${0##*/}"
SCRIPTDIR="$(dirname "${BASH_SOURCE[0]}")"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# @Author      : Jason
# @Contact     : casjaysdev@casjay.pro
# @File        : qtile.sh
# @Created     : Mon, Dec 31, 2019, 00:00 EST
# @License     : WTFPL
# @Copyright   : Copyright (c) CasjaysDev
# @Description : xfce4 installer for arcolinux
# @Resource    : https://github.com/arcolinuxd/arco-qtile
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Set functions

# Vendored from casjay-dotfiles/scripts system-installer.bash (self-contained,
# no network fetch) - only the functions this script actually calls.
__printf_color() { printf "%b" "$(tput setaf "$2" 2>/dev/null)" "$1" "$(tput sgr0 2>/dev/null)"; }
__printf_green() { __printf_color "$1
" 2; }
__printf_red() { __printf_color "$1
" 208; }
__printf_yellow() { __printf_color "$1
" 3; }
__printf_blue() { __printf_color "$1
" 33; }
__printf_info() { __printf_color "[ ℹ️ ] $1
" 3; }
__printf_exit() {
  __printf_color "$1
" 208 1>&2
  exit 1
}
__printf_head() {
  [[ $1 == ?(-)+([0-9]) ]] && local color="$1" && shift 1 || local color="6"
  local msg="$*"
  shift
  __printf_color "
##################################################
$msg
##################################################
" "$color"
}
__printf_custom() {
  [[ $1 == ?(-)+([0-9]) ]] && local color="$1" && shift 1 || local color="208"
  local msg="$*"
  shift
  __printf_color "$msg" "$color"
  printf '
'
}
__printf_execute_success() { __printf_color "[ ✔ ] $1 
" 2; }
__printf_execute_error() { __printf_color "[ ✖ ] $1 $2 
" 1; }
__printf_execute_error_stream() { while read -r line; do __printf_execute_error "↳ ERROR: $line"; done; }
__printf_execute_result() {
  if [ "$1" -eq 0 ]; then __printf_execute_success "$2"; else __printf_execute_error "$2"; fi
  return "$1"
}
__devnull() { "$@" >/dev/null 2>&1; }
__set_trap() { trap -p "$1" | grep -- "$2" &>/dev/null || trap "$2" "$1"; }
__setexitstatus() {
  EXIT="${EXIT:-$?}"
  local EXITSTATUS+="$EXIT"
  if [ -z "$EXITSTATUS" ] || [ "$EXITSTATUS" -ne 0 ]; then
    BG_EXIT="${BG_RED}"
    return 1
  else
    BG_EXIT="${BG_GREEN}"
    return 0
  fi
}
__execute() {
  __kill_all_subprocesses() {
    local i=""
    for i in $(jobs -p); do
      kill "$i"
      wait "$i" &>/dev/null
    done
  }
  __show_spinner() {
    local -r FRAMES='/-\|'
    local -r NUMBER_OR_FRAMES=${#FRAMES}
    local -r CMDS="$2"
    local -r MSG="$3"
    local -r PID="$1"
    local i=0
    local frameText=""
    if [ "$TRAVIS" != "true" ]; then
      printf "


"
      tput cuu 3
      tput sc
    fi
    while kill -0 "$PID" &>/dev/null; do
      frameText="[ ${FRAMES:i++%NUMBER_OR_FRAMES:1} ] $MSG"
      if [ "$TRAVIS" != "true" ]; then
        printf "%s
" "$frameText"
      else
        printf "%s" "$frameText"
      fi
      sleep 0.2
      if [ "$TRAVIS" != "true" ]; then
        tput rc
      else
        printf ""
      fi
    done
  }
  local -r CMDS="$1"
  local -r MSG="${2:-$1}"
  local -r TMP_FILE="$(mktemp /tmp/XXXXX)"
  local exitCode=0
  local cmdsPID=""
  __set_trap "EXIT" "__kill_all_subprocesses"
  eval "$CMDS" >/dev/null 2>"$TMP_FILE" &
  cmdsPID=$!
  __show_spinner "$cmdsPID" "$CMDS" "$MSG"
  wait "$cmdsPID" &>/dev/null
  exitCode=$?
  __printf_execute_result $exitCode "$MSG"
  if [ $exitCode -ne 0 ]; then
    __printf_execute_error_stream <"$TMP_FILE"
  fi
  rm -rf "$TMP_FILE"
  return $exitCode
}
__sudoask() {
  if [ ! -f "$HOME/.sudo" ]; then
    sudo true &>/dev/null
    while true; do
      echo -e "$!" >"$HOME/.sudo"
      sudo -n true && echo -e "$$" >>"$HOME/.sudo"
      sleep 10
      rm -Rf "$HOME/.sudo"
      kill -0 "$$" || return
    done &>/dev/null &
  fi
}
__sudoexit() {
  if [ $? -eq 0 ]; then
    __sudoask || __printf_green "Getting privileges successful continuing" &&
      sudo -n true
  else
    __printf_red "Failed to get privileges"
  fi
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

__run_post() {
  local e="$1"
  local m="${1//__devnull /}"
  __execute "$e" "executing: $m"
  __setexitstatus
  set --
}
__system_service_exists() {
  if sudo systemctl list-units --full -all | grep -F -- "$1"; then return 0; else return 1; fi
  __setexitstatus
  set --
}
__system_service_enable() {
  if __system_service_exists; then __execute "sudo systemctl enable -f $1" "Enabling service: $1"; fi
  __setexitstatus
  set --
}
__system_service_disable() {
  if __system_service_exists; then __execute "sudo systemctl disable --now $@" "Disabling service: $@"; fi
  __setexitstatus
  set --
}

__test_pkg() {
  __devnull sudo pacman -Qi "$1" && __printf_custom "6" "[ ✔ ] Installed: $1" && return 1 || return 0
  __setexitstatus
  set --
}
__remove_pkg() {
  if ! __test_pkg "$1"; then __execute "sudo pacman -R  --noconfirm $1" "Removing: $1"; fi
  __setexitstatus
  set --
}
__install_pkg() {
  if __test_pkg "$1"; then __execute "sudo pacman -S --noconfirm --needed $1" "Installing: $1"; fi
  __setexitstatus
  set --
}
__install_aur() {
  if __test_pkg "$1"; then __execute "sudo --user=$(whoami) yay -S --noconfirm $1" "Installing: $1"; fi
  __setexitstatus
  set --
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

[ ! -z "$1" ] && __printf_exit 'To many options provided'

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

##################################################################################################################
__printf_head "Initializing the setup script"
##################################################################################################################

__sudoask && __sudoexit
__execute "sudo pacman -Syyu --noconfirm" "Updating System"

##################################################################################################################
__printf_head "Configuring cores for compiling"
##################################################################################################################

numberofcores=$(grep -c ^processor /proc/cpuinfo)
__printf_info "Total cores avaliable: $numberofcores"

if [ $numberofcores -gt 1 ]; then
  sudo sed -i 's/#MAKEFLAGS="-j2"/MAKEFLAGS="-j'$(($numberofcores + 1))'"/g' /etc/makepkg.conf
  sudo sed -i 's/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -T '"$numberofcores"' -z -)/g' /etc/makepkg.conf
fi

##################################################################################################################
__printf_head "Installing the qtile desktop"
##################################################################################################################

__install_pkg qtile

__install_pkg arcolinux-xfce-git
__install_pkg arcolinux-qtile-git
__install_pkg arcolinux-config-qtile-git
__install_pkg arcolinux-qtile-dconf-git

##################################################################################################################
__printf_head "Installing desktop packages"
##################################################################################################################

__install_pkg lightdm
__install_pkg arcolinux-lightdm-gtk-greeter
__install_pkg arcolinux-lightdm-gtk-greeter-settings
__install_pkg arcolinux-wallpapers-git
__install_pkg pulseaudio
__install_pkg pulseaudio-alsa
__install_pkg pavucontrol
__install_pkg alsa-utils
__install_pkg alsa-plugins
__install_pkg alsa-lib
__install_pkg alsa-firmware
__install_pkg gstreamer
__install_pkg gst-plugins-good
__install_pkg gst-plugins-bad
__install_pkg gst-plugins-base
__install_pkg gst-plugins-ugly
__install_pkg volumeicon
__install_pkg playerctl
__install_pkg pulseaudio-bluetooth
__install_pkg bluez
__install_pkg bluez-libs
__install_pkg bluez-utils
__install_pkg blueberry
__install_pkg cups
__install_pkg cups-pdf
__install_pkg ghostscript
__install_pkg gsfonts
__install_pkg gutenprint
__install_pkg gtk3-print-backends
__install_pkg libcups
__install_pkg hplip
__install_pkg system-config-printer
__install_pkg samba
__install_pkg gvfs-smb
__install_pkg avahi
__install_pkg nss-mdns
__install_pkg gvfs-smb
__install_pkg tlp

__install_pkg catfish
__install_pkg cronie
__install_pkg galculator
__install_pkg gnome-screenshot
__install_pkg plank
__install_pkg xfburn
__install_pkg variety
__install_pkg geany
__install_pkg vim
__install_pkg nano

__install_pkg gimp
__install_pkg gnome-font-viewer
__install_pkg gpick
__install_pkg inkscape

__install_pkg chromium
__install_pkg firefox
__install_pkg thunderbird
__install_pkg hexchat
__install_pkg pidgin

__install_pkg deadbeef
__install_pkg mpv
__install_pkg pragha
__install_pkg simplescreenrecorder
__install_pkg smplayer
__install_pkg vlc
__install_pkg rhythmbox

__install_pkg libreoffice-fresh

__install_pkg arc-gtk-theme
__install_pkg accountsservice
__install_pkg baobab
__install_pkg curl
__install_pkg dconf-editor
__install_pkg dmidecode
__install_pkg ffmpegthumbnailer
__install_pkg git
__install_pkg glances
__install_pkg gnome-disk-utility
__install_pkg gnome-keyring
__install_pkg gparted
__install_pkg grsync
__install_pkg gtk-engines
__install_pkg gtk-engine-murrine
__install_pkg gvfs
__install_pkg gvfs-mtp
__install_pkg hardinfo
__install_pkg hddtemp
__install_pkg htop
__install_pkg kvantum-qt5
__install_pkg kvantum-theme-arc
__install_pkg lm_sensors
__install_pkg lsb-release
__install_pkg mlocate
__install_pkg net-tools
__install_pkg notify-osd
__install_pkg noto-fonts
__install_pkg numlockx
__install_pkg polkit-gnome
__install_pkg qt5ct
__install_pkg sane
__install_pkg screenfetch
__install_pkg scrot
__install_pkg simple-scan
__install_pkg sysstat
__install_pkg termite
__install_pkg thunar
__install_pkg thunar-archive-plugin
__install_pkg thunar-volman
__install_pkg ttf-ubuntu-font-family
__install_pkg ttf-droid
__install_pkg tumbler
__install_pkg vnstat
__install_pkg wget
__install_pkg wmctrl
__install_pkg unclutter
__install_pkg rxvt-unicode
__install_pkg urxvt-perls
__install_pkg xdg-user-dirs
__install_pkg xdo
__install_pkg xdotool
__install_pkg zenity
__install_pkg unace
__install_pkg unrar
__install_pkg zip
__install_pkg unzip
__install_pkg sharutils
__install_pkg uudeview
__install_pkg arj
__install_pkg cabextract
__install_pkg file-roller

__install_pkg arcolinux-arc-themes-nico-git
__install_pkg arcolinux-bin-git
__install_pkg arcolinux-conky-collection-git
__install_pkg arcolinux-cron-git
__install_pkg arcolinux-faces-git
__install_pkg arcolinux-fonts-git
__install_pkg arcolinux-geany-git
__install_pkg arcolinux-hblock-git
__install_pkg arcolinux-kvantum-git
__install_pkg arcolinux-lightdm-gtk-greeter
__install_pkg arcolinux-lightdm-gtk-greeter-settings
__install_pkg arcolinux-local-applications-git
__install_pkg arcolinux-local-xfce4-git
__install_pkg arcolinux-mirrorlist-git
__install_pkg arcolinux-neofetch-git
__install_pkg arcolinux-nitrogen-git
__install_pkg arcolinux-pipemenus-git
__install_pkg arcolinux-plank-git
__install_pkg arcolinux-plank-themes-git
__install_pkg arcolinux-qt5-git
__install_pkg arcolinux-rofi-git
__install_pkg arcolinux-rofi-themes-git
__install_pkg arcolinux-root-git
__install_pkg arcolinux-slim
__install_pkg arcolinux-slimlock-themes-git
__install_pkg arcolinux-system-config-git
__install_pkg arcolinux-termite-themes-git
__install_pkg arcolinux-variety-git
__install_pkg arcolinux-wallpapers-git

__install_pkg adobe-source-sans-pro-fonts
__install_pkg cantarell-fonts
__install_pkg noto-fonts
__install_pkg ttf-bitstream-vera
__install_pkg ttf-dejavu
__install_pkg ttf-droid
__install_pkg ttf-hack
__install_pkg ttf-inconsolata
__install_pkg ttf-liberation
__install_pkg ttf-roboto
__install_pkg ttf-ubuntu-font-family
__install_pkg tamsyn-font
__install_pkg intel-ucode

##################################################################################################################
__printf_head "installing aur packages"
##################################################################################################################

__install_aur ttf-font-awesome
__install_aur brackets-bin
__install_aur cmatrix-git
__install_aur font-manager-git
__install_aur hardcode-fixer-git
__install_aur pamac-aur
__install_aur menulibre
__install_aur mugshot
__install_aur xfce4-panel-profiles

##################################################################################################################
__printf_head "Fixing packages"
##################################################################################################################

__run_post "sudo sed -i 's/'#AutoEnable=false'/'AutoEnable=true'/g' /etc/bluetooth/main.conf"
__run_post "sudo sed -i 's/files mymachines myhostname/files mymachines/g' /etc/nsswitch.conf"
__run_post "sudo sed -i 's/\[\!UNAVAIL=return\] dns/\[\!UNAVAIL=return\] mdns dns wins myhostname/g' /etc/nsswitch.conf"
__run_post "sudo usermod  -a -G rfkill $USER"

##################################################################################################################
__printf_head "setting up config files"
##################################################################################################################

[ ! -d "$HOME/.config/qtile" ] && [ -d "/etc/skel/.config/qtile" ] &&
  __run_post "cp -rT /etc/skel/.config/qtile $HOME/.config/qtile"

__run_post "dotfiles install qtile"
__run_post "dotfiles install bash"
__run_post "dotfiles install geany"
__run_post "dotfiles install misc"
__run_post "dotfiles install mpd"
__run_post "dotfiles install youtube-dl"
__run_post "dotfiles install xfce4"

__run_post "dotfiles admin scripts"
__run_post "dotfiles admin cron"
__run_post "dotfiles admin ssl"
__run_post "dotfiles admin ssh"
__run_post "dotfiles admin samba"

##################################################################################################################
__printf_head "Enabling services"
##################################################################################################################

__system_service_enable lightdm.service
__system_service_enable bluetooth.service
__system_service_enable smb.service
__system_service_enable nmb.service
__system_service_enable avahi-daemon.service
__system_service_enable tlp.service
__system_service_enable org.cups.cupsd.service
__system_service_disable mpd

__run_post "__devnull sudo systemctl set-default graphical.target"

__run_post "__devnull sudo grub-mkconfig -o /boot/grub/grub.cfg"

##################################################################################################################
__printf_head "Cleaning up"
##################################################################################################################

__remove_pkg xfce4-artwork

##################################################################################################################
__printf_head "Finished "
echo ""
##################################################################################################################

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
set --

# end
