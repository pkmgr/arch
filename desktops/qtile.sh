#!/usr/bin/env bash

SCRIPTNAME="$(basename $0)"
SCRIPTDIR="$(dirname "${BASH_SOURCE[0]}")"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# @Author      : Jason
# @Contact     : casjaysdev@casjay.net
# @File        : qtile.sh
# @Created     : Mon, Dec 31, 2019, 00:00 EST
# @License     : WTFPL
# @Copyright   : Copyright (c) CasjaysDev
# @Description : xfce4 installer for arcolinux
# @Resource    : https://github.com/arcolinuxd/arco-qtile
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Set functions

SCRIPTSFUNCTURL="${SCRIPTSFUNCTURL:-https://github.com/casjay-dotfiles/scripts/raw/main/functions}"
SCRIPTSFUNCTDIR="${SCRIPTSFUNCTDIR:-/usr/local/share/CasjaysDev/scripts}"
SCRIPTSFUNCTFILE="${SCRIPTSFUNCTFILE:-system-installer.bash}"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

if [ -f "../functions/$SCRIPTSFUNCTFILE" ]; then
  . "../functions/$SCRIPTSFUNCTFILE"
elif [ -f "$SCRIPTSFUNCTDIR/functions/$SCRIPTSFUNCTFILE" ]; then
  . "$SCRIPTSFUNCTDIR/functions/$SCRIPTSFUNCTFILE"
else
  curl -LSs "$SCRIPTSFUNCTURL/$SCRIPTSFUNCTFILE" -o "/tmp/$SCRIPTSFUNCTFILE" || exit 1
  . "/tmp/$SCRIPTSFUNCTFILE"
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

run_post() {
  local e="$1"
  local m="$(echo $1 | sed 's#devnull ##g')"
  execute "$e" "executing: $m"
  setexitstatus
  set --
}
system_service_exists() {
  if sudo systemctl list-units --full -all | grep -Fq "$1"; then return 0; else return 1; fi
  setexitstatus
  set --
}
system_service_enable() {
  if system_service_exists; then execute "sudo systemctl enable -f $1" "Enabling service: $1"; fi
  setexitstatus
  set --
}
system_service_disable() {
  if system_service_exists; then execute "sudo systemctl disable --now $@" "Disabling service: $@"; fi
  setexitstatus
  set --
}

test_pkg() {
  devnull sudo pacman -Qi "$1" && printf_custom "6" "[ ✔ ] Installed: $1" && return 1 || return 0
  setexitstatus
  set --
}
remove_pkg() {
  if ! test_pkg "$1"; then execute "sudo pacman -R  --noconfirm $1" "Removing: $1"; fi
  setexitstatus
  set --
}
install_pkg() {
  if test_pkg "$1"; then execute "sudo pacman -S --noconfirm --needed $1" "Installing: $1"; fi
  setexitstatus
  set --
}
install_aur() {
  if test_pkg "$1"; then execute "sudo --user=$(whoami) yay -S --noconfirm $1" "Installing: $1"; fi
  setexitstatus
  set --
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

[ ! -z "$1" ] && printf_exit 'To many options provided'

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

##################################################################################################################
printf_head "Initializing the setup script"
##################################################################################################################

sudoask && sudoexit
execute "sudo pacman -Syyu --noconfirm" "Updating System"

##################################################################################################################
printf_head "Configuring cores for compiling"
##################################################################################################################

numberofcores=$(grep -c ^processor /proc/cpuinfo)
printf_info "Total cores avaliable: $numberofcores"

if [ $numberofcores -gt 1 ]; then
  sudo sed -i 's/#MAKEFLAGS="-j2"/MAKEFLAGS="-j'$(($numberofcores + 1))'"/g' /etc/makepkg.conf
  sudo sed -i 's/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -T '"$numberofcores"' -z -)/g' /etc/makepkg.conf
fi

##################################################################################################################
printf_head "Installing the qtile desktop"
##################################################################################################################

install_pkg qtile

install_pkg arcolinux-xfce-git
install_pkg arcolinux-qtile-git
install_pkg arcolinux-config-qtile-git
install_pkg arcolinux-qtile-dconf-git

##################################################################################################################
printf_head "Installing desktop packages"
##################################################################################################################

install_pkg lightdm
install_pkg arcolinux-lightdm-gtk-greeter
install_pkg arcolinux-lightdm-gtk-greeter-settings
install_pkg arcolinux-wallpapers-git
install_pkg pulseaudio
install_pkg pulseaudio-alsa
install_pkg pavucontrol
install_pkg alsa-utils
install_pkg alsa-plugins
install_pkg alsa-lib
install_pkg alsa-firmware
install_pkg gstreamer
install_pkg gst-plugins-good
install_pkg gst-plugins-bad
install_pkg gst-plugins-base
install_pkg gst-plugins-ugly
install_pkg volumeicon
install_pkg playerctl
install_pkg pulseaudio-bluetooth
install_pkg bluez
install_pkg bluez-libs
install_pkg bluez-utils
install_pkg blueberry
install_pkg cups
install_pkg cups-pdf
install_pkg ghostscript
install_pkg gsfonts
install_pkg gutenprint
install_pkg gtk3-print-backends
install_pkg libcups
install_pkg hplip
install_pkg system-config-printer
install_pkg samba
install_pkg gvfs-smb
install_pkg avahi
install_pkg nss-mdns
install_pkg gvfs-smb
install_pkg tlp

install_pkg catfish
install_pkg cronie
install_pkg galculator
install_pkg gnome-screenshot
install_pkg plank
install_pkg xfburn
install_pkg variety
install_pkg geany
install_pkg vim
install_pkg nano

install_pkg gimp
install_pkg gnome-font-viewer
install_pkg gpick
install_pkg inkscape

install_pkg chromium
install_pkg firefox
install_pkg thunderbird
install_pkg hexchat
install_pkg pidgin

install_pkg deadbeef
install_pkg mpv
install_pkg pragha
install_pkg simplescreenrecorder
install_pkg smplayer
install_pkg vlc
install_pkg rhythmbox

install_pkg libreoffice-fresh

install_pkg arc-gtk-theme
install_pkg accountsservice
install_pkg baobab
install_pkg curl
install_pkg dconf-editor
install_pkg dmidecode
install_pkg ffmpegthumbnailer
install_pkg git
install_pkg glances
install_pkg gnome-disk-utility
install_pkg gnome-keyring
install_pkg gparted
install_pkg grsync
install_pkg gtk-engines
install_pkg gtk-engine-murrine
install_pkg gvfs
install_pkg gvfs-mtp
install_pkg hardinfo
install_pkg hddtemp
install_pkg htop
install_pkg kvantum-qt5
install_pkg kvantum-theme-arc
install_pkg lm_sensors
install_pkg lsb-release
install_pkg mlocate
install_pkg net-tools
install_pkg notify-osd
install_pkg noto-fonts
install_pkg numlockx
install_pkg polkit-gnome
install_pkg qt5ct
install_pkg sane
install_pkg screenfetch
install_pkg scrot
install_pkg simple-scan
install_pkg sysstat
install_pkg termite
install_pkg thunar
install_pkg thunar-archive-plugin
install_pkg thunar-volman
install_pkg ttf-ubuntu-font-family
install_pkg ttf-droid
install_pkg tumbler
install_pkg vnstat
install_pkg wget
install_pkg wmctrl
install_pkg unclutter
install_pkg rxvt-unicode
install_pkg urxvt-perls
install_pkg xdg-user-dirs
install_pkg xdo
install_pkg xdotool
install_pkg zenity
install_pkg unace
install_pkg unrar
install_pkg zip
install_pkg unzip
install_pkg sharutils
install_pkg uudeview
install_pkg arj
install_pkg cabextract
install_pkg file-roller

install_pkg arcolinux-arc-themes-nico-git
install_pkg arcolinux-bin-git
install_pkg arcolinux-conky-collection-git
install_pkg arcolinux-cron-git
install_pkg arcolinux-faces-git
install_pkg arcolinux-fonts-git
install_pkg arcolinux-geany-git
install_pkg arcolinux-hblock-git
install_pkg arcolinux-kvantum-git
install_pkg arcolinux-lightdm-gtk-greeter
install_pkg arcolinux-lightdm-gtk-greeter-settings
install_pkg arcolinux-local-applications-git
install_pkg arcolinux-local-xfce4-git
install_pkg arcolinux-mirrorlist-git
install_pkg arcolinux-neofetch-git
install_pkg arcolinux-nitrogen-git
install_pkg arcolinux-pipemenus-git
install_pkg arcolinux-plank-git
install_pkg arcolinux-plank-themes-git
install_pkg arcolinux-qt5-git
install_pkg arcolinux-rofi-git
install_pkg arcolinux-rofi-themes-git
install_pkg arcolinux-root-git
install_pkg arcolinux-slim
install_pkg arcolinux-slimlock-themes-git
install_pkg arcolinux-system-config-git
install_pkg arcolinux-termite-themes-git
install_pkg arcolinux-variety-git
install_pkg arcolinux-wallpapers-git

install_pkg adobe-source-sans-pro-fonts
install_pkg cantarell-fonts
install_pkg noto-fonts
install_pkg ttf-bitstream-vera
install_pkg ttf-dejavu
install_pkg ttf-droid
install_pkg ttf-hack
install_pkg ttf-inconsolata
install_pkg ttf-liberation
install_pkg ttf-roboto
install_pkg ttf-ubuntu-font-family
install_pkg tamsyn-font
install_pkg intel-ucode

##################################################################################################################
printf_head "installing aur packages"
##################################################################################################################

install_aur ttf-font-awesome
install_aur brackets-bin
install_aur cmatrix-git
install_aur font-manager-git
install_aur hardcode-fixer-git
install_aur pamac-aur
install_aur menulibre
install_aur mugshot
install_aur xfce4-panel-profiles

##################################################################################################################
printf_head "Fixing packages"
##################################################################################################################

run_post "sudo sed -i 's/'#AutoEnable=false'/'AutoEnable=true'/g' /etc/bluetooth/main.conf"
run_post "sudo sed -i 's/files mymachines myhostname/files mymachines/g' /etc/nsswitch.conf"
run_post "sudo sed -i 's/\[\!UNAVAIL=return\] dns/\[\!UNAVAIL=return\] mdns dns wins myhostname/g' /etc/nsswitch.conf"
run_post "sudo usermod  -a -G rfkill $USER"

##################################################################################################################
printf_head "setting up config files"
##################################################################################################################

[ ! -d "$HOME/.config/qtile" ] && [ -d "/etc/skel/.config/qtile" ] &&
  run_post "cp -rT /etc/skel/.config/qtile $HOME/.config/qtile"

run_post "dotfiles install qtile"
run_post "dotfiles install bash"
run_post "dotfiles install geany"
run_post "dotfiles install misc"
run_post "dotfiles install mpd"
run_post "dotfiles install youtube-dl"
run_post "dotfiles install xfce4"

run_post "dotfiles admin scripts"
run_post "dotfiles admin cron"
run_post "dotfiles admin ssl"
run_post "dotfiles admin ssh"
run_post "dotfiles admin samba"

##################################################################################################################
printf_head "Enabling services"
##################################################################################################################

system_service_enable lightdm.service
system_service_enable bluetooth.service
system_service_enable smb.service
system_service_enable nmb.service
system_service_enable avahi-daemon.service
system_service_enable tlp.service
system_service_enable org.cups.cupsd.service
system_service_disable mpd

run_post "devnull sudo systemctl set-default graphical.target"

run_post "devnull sudo grub-mkconfig -o /boot/grub/grub.cfg"

##################################################################################################################
printf_head "Cleaning up"
##################################################################################################################

remove_pkg xfce4-artwork

##################################################################################################################
printf_head "Finished "
echo ""
##################################################################################################################

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
set --

# end
