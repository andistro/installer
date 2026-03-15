#!/bin/bash
export distro_theme="$1"
export distro_name="$2"


# Fonte modular configuração global
source "/usr/local/lib/andistro/global"

# Baixa os pacotes base, um por um
show_progress_dialog steps-multi-label 65 \
    "${label_progress}" 'sudo apt clean' \
    "${label_find_update}" 'sudo apt update' \
    "${label_upgrade}" 'sudo apt full-upgrade -y' \
    "${label_install_script_download}\n\n → apt-utils" 'sudo apt install apt-utils --no-install-recommends -y' \
    "${label_install_script_download}\n\n → apt-transport-https" 'sudo apt install apt-transport-https --no-install-recommends -y' \
    "${label_install_script_download}\n\n → debconf-utils" 'sudo apt install debconf-utils --no-install-recommends -y' \
    "${label_install_script_download}\n\n → dbus-x11" 'sudo apt install dbus-x11 --no-install-recommends -y' \
    "${label_install_script_download}\n\n → tzdata" "sudo DEBIAN_FRONTEND=noninteractive apt install tzdata --no-install-recommends -y" \
    "${label_install_script_download}\n\n → keyboard-configuration" "sudo DEBIAN_FRONTEND=noninteractive apt install keyboard-configuration --no-install-recommends -y" \
    "${label_install_script_download}\n\n → python3" 'sudo apt install python3 --no-install-recommends -y' \
    "${label_install_script_download}\n\n → python3-psutil" 'sudo apt install python3-psutil --no-install-recommends -y' \
    "${label_install_script_download}\n\n → python3-pip" 'sudo apt install python3-pip --no-install-recommends -y' \
    "${label_install_script_download}\n\n → python3-venv" 'sudo apt install python3-venv --no-install-recommends -y' \
    "${label_install_script_download}\n\n → at-spi2-core" 'sudo apt install at-spi2-core --no-install-recommends -y' \
    "${label_install_script_download}\n\n → bleachbit" 'sudo apt install bleachbit --no-install-recommends -y' \
    "${label_install_script_download}\n\n → exo-utils" 'sudo apt install exo-utils --no-install-recommends -y' \
    "${label_install_script_download}\n\n → firefox" 'sudo apt install firefox --no-install-recommends -y' \
    "${label_install_script_download}\n\n → firefox ${system_lang_code_env_lower}" "sudo apt install firefox-l10n-${system_lang_code_env_lower} --no-install-recommends -y" \
    "${label_install_script_download}\n\n → font-manager" 'sudo apt install font-manager --no-install-recommends -y' \
    "${label_install_script_download}\n\n → git" 'sudo apt install git --no-install-recommends -y' \
    "${label_install_script_download}\n\n → inetutils-tools" 'sudo apt install inetutils-tools --no-install-recommends -y' \
    "${label_install_script_download}\n\n → lsb-release" 'sudo apt install lsb-release --no-install-recommends -y' \
    "${label_install_script_download}\n\n → make" 'sudo apt install make --no-install-recommends -y' \
    "${label_install_script_download}\n\n → net-tools" 'sudo apt install net-tools --no-install-recommends -y' \
    "${label_install_script_download}\n\n → pavucontrol" 'sudo apt install pavucontrol --no-install-recommends -y' \
    "${label_install_script_download}\n\n → pulseaudio-utils" 'sudo apt install pulseaudio-utils --no-install-recommends -y' \
    "${label_install_script_download}\n\n → alsa-utils" 'sudo apt install alsa-utils --no-install-recommends -y' \
    "${label_install_script_download}\n\n → tigervnc-common" 'sudo apt install tigervnc-common --no-install-recommends -y' \
    "${label_install_script_download}\n\n → tigervnc-standalone-server" 'sudo apt install tigervnc-standalone-server --no-install-recommends -y' \
    "${label_install_script_download}\n\n → tigervnc-tools" 'sudo apt install tigervnc-tools --no-install-recommends -y' \
    "${label_install_script_download}\n\n → gvfs-backends" 'sudo apt install gvfs-backends --no-install-recommends -y' \
    "${label_install_script_download}\n\n → tumbler" 'sudo apt install tumbler --no-install-recommends -y' \
    "${label_install_script_download}\n\n → ffmpeg" 'sudo apt install ffmpeg --no-install-recommends -y' \
    "${label_install_script_download}\n\n → ffmpegthumbnailer" 'sudo apt install ffmpegthumbnailer --no-install-recommends -y' \
    "${label_install_script_download}\n\n → mpv" 'sudo apt install mpv --no-install-recommends -y' \
    "${label_install_script_download}\n\n → unzip" 'sudo apt install unzip --no-install-recommends -y' \
    "${label_install_script_download}\n\n → xdg-user-dirs" 'sudo apt install xdg-user-dirs --no-install-recommends -y' \
    "${label_install_script_download}\n\n → xz-utils" 'sudo apt install xz-utils --no-install-recommends -y' \
    "${label_install_script_download}\n\n → zip" 'sudo apt install zip --no-install-recommends -y' \
    "${label_install_script_download}\n\n → mesa-utils" 'sudo apt install mesa-utils --no-install-recommends -y' \
    "${label_install_script_download}\n\n → mesa-utils-extra" 'sudo apt install mesa-utils-extra --no-install-recommends -y' \
    "${label_install_script_download}\n\n → mesa-vulkan-drivers" 'sudo apt install mesa-vulkan-drivers --no-install-recommends -y' \
    "${label_install_script_download}\n\n → libgl1-mesa-dri" 'sudo apt install libgl1-mesa-dri --no-install-recommends -y' \
    "${label_install_script_download}\n\n → libglx-mesa0" 'sudo apt install libglx-mesa0 --no-install-recommends -y' \
    "${label_install_script_download}" 'sleep 5' \
    "${label_system_setup}" 'mkdir -p "/usr/share/backgrounds"' \
    "${label_system_setup}" 'mkdir -p "/usr/share/icons"' \
    "${label_system_setup}" "mkdir -p $HOME/.config/gtk-3.0" \
    "${label_system_setup}" "mkdir -p $HOME/.vnc" \
    "${label_system_setup}" "echo -e \"file:///sdcard sdcard\" | tee $HOME/.config/gtk-3.0/bookmarks" \
    "${label_system_setup}" "echo \"alias ls='ls --color=auto'\" >> $HOME/.bashrc" \
    "${label_system_setup}" 'echo "source \"/usr/local/lib/andistro/global\"" >> $HOME/.bashrc' \
    "${label_system_setup}\n\n → ${label_themes}: andistro-themes" 'git clone --depth 1 https://github.com/andistro/themes.git' \
    "${label_system_setup}\n\n → ${label_themes}: andistro-themes" 'mv themes/AnDistro*/ /usr/share/themes/' \
    "${label_system_setup}\n\n → ${label_icons}: zorin-icon-themes" 'git clone --depth 1 https://github.com/ZorinOS/zorin-icon-themes.git' \
    "${label_system_setup}\n\n → ${label_icons}: zorin-icon-themes" 'mv zorin-icon-themes/Zorin*/ /usr/share/icons/' \
    "${label_system_setup}\n\n → ${label_xdg_user_dirs_setup}" "xdg-user-dirs-update" \
    "${label_system_setup}" 'rm -rf zorin-*-themes/' \
    "${label_system_setup}" 'rm -rf themes/' \
    "${label_system_setup}" "echo -e '[Settings]\ngtk-theme-name=AnDistro-Majorelle-Blue-${distro_theme}' | sudo tee $HOME/.config/gtk-3.0/settings.ini" \
    "${label_system_setup}" "echo 'gtk-theme-name=\"AnDistro-Majorelle-Blue-${distro_theme}\"' | sudo tee $HOME/.gtkrc-2.0" \
    "${label_system_setup}" 'sudo dpkg --configure -a' \
    "${label_system_setup}" 'sudo apt --fix-broken install -y' \
    "${label_system_setup}" 'sudo apt-get clean' \
    "${label_system_setup}" 'sudo apt remove keyboard-configuration -y'

sleep 2

#Tempo de 10s antes de inicializar as configurações do teclado
{
 for i in {1..50}; do
   sleep 0.1
   echo $((i * 2))
 done
} | dialog --no-shadow --gauge "$label_keyboard_setup" 10 60
sudo apt install keyboard-configuration -y

# Remove o arquivo do sistema
rm -rf system-config.sh
