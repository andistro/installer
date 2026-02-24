#!/bin/bash
# Variáveis de configuração
distro_name="$1"
distro_theme="$2"
system_lang_code="$3"
system_lang_code_env="${system_lang_code//-/_}"
LANG=""
system_lang_code_env_lower=$(echo "$LANG" | sed 's/\..*//' | sed 's/_/-/' | tr '[:upper:]' '[:lower:]')
# Fonte modular configuração global
source "/usr/local/lib/andistro/global"

# Mensagem de inicialização
echo -e "\n${distro_wait}\n"

#======================================================================================================
# global == update_progress() {}

sed -i "s/^# *\($system_icu_lang_code_env.UTF-8\)/\1/" /etc/locale.gen

sudo locale-gen $system_icu_lang_code_env.UTF-8

echo -e "LANG=$system_icu_lang_code_env.UTF-8" > /etc/locale.conf

echo "export LANG=$system_icu_lang_code_env.UTF-8" >> $HOME/.bashrc 

echo "export LANGUAGE=$system_icu_lang_code_env.UTF-8" >> $HOME/.bashrc

echo "export LANGUAGE=$system_icu_lang_code_env.UTF-8" >> $HOME/.bashrc

sudo apt install language-pack-gnome-$default_locale_lang_global -y

sudo apt install language-pack-$default_locale_lang_global -y

sudo mv /var/lib/dpkg/info /var/lib/dpkg/info_old

sudo mkdir /var/lib/dpkg/info

apt update

cat <<EOF | sudo tee /etc/apt/sources.list.d/mozilla.sources
Types: deb
URIs: https://packages.mozilla.org/apt
Suites: mozilla
Components: main
Signed-By: /etc/apt/keyrings/packages.mozilla.org.asc
EOF

echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' | sudo tee /etc/apt/preferences.d/mozilla

wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg

sudo install -D -o root -g root -m 644 microsoft.gpg /usr/share/keyrings/microsoft.gpg &&

rm -f microsoft.gpg

cat <<EOF | sudo tee /etc/apt/sources.list.d/vscode.sources
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Signed-By: /usr/share/keyrings/microsoft.gpg
EOF

sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg

sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources https://brave-browser-apt-release.s3.brave.com/brave-browser.sources

sudo curl -fsSLo /usr/share/keyrings/brave-browser-beta-archive-keyring.gpg https://brave-browser-apt-beta.s3.brave.com/brave-browser-beta-archive-keyring.gpg

sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-beta.sources https://brave-browser-apt-beta.s3.brave.com/brave-browser.sources

sudo curl -fsSLo /usr/share/keyrings/brave-browser-nightly-archive-keyring.gpg https://brave-browser-apt-nightly.s3.brave.com/brave-browser-nightly-archive-keyring.gpg

sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-nightly.sources https://brave-browser-apt-nightly.s3.brave.com/brave-browser.sources

wget -O /usr/share/keyrings/vivaldi-archive-keyring.gpg https://repo.vivaldi.com/archive/linux_signing_key.pub

cat <<EOF | sudo tee /etc/apt/sources.list.d/vivaldi.sources
Types: deb
URIs: https://repo.vivaldi.com/archive/deb/
Suites: stable
Components: main
Signed-By: /usr/share/keyrings/vivaldi-archive-keyring.gpg
EOF

apt update 

#echo 'export VISUAL=nano' >> $HOME/.bashrc
#echo 'export EDITOR=nano' >> $HOME/.bashrc
#======================================================================================================
sudo dpkg --configure -a 
sudo apt --fix-broken install -y 

sudo mv /var/lib/dpkg/info/* /var/lib/dpkg/info_old/

sudo rm -rf /var/lib/dpkg/info

sudo mv /var/lib/dpkg/info_old /var/lib/dpkg/info

sudo apt update

sudo apt clean

sudo apt autoclean

etc_timezone=$(cat /etc/timezone)

sudo ln -sf "/usr/share/zoneinfo/$etc_timezone" /etc/localtime


dialog --create-rc $HOME/.dialogrc
sed -i "s|use_shadow = ON|use_shadow = OFF|g" $HOME/.dialogrc

sudo apt update

sudo apt upgrade

echo -e "\033[1;96m$label_install_script_download\033[0m"
echo " "
sleep 2

sudo DEBIAN_FRONTEND=noninteractive apt install tzdata --no-install-recommends -y

sudo apt install --no-install-recommends -y \
    apt-utils \
    apt-transport-https \
    debconf-utils \
    dbus-x11 \
    keyboard-configuration \
    python3 \
    python3-psutil \
    python3-pip \
    python3-venv \
    at-spi2-core \
    bleachbit \
    exo-utils \
    firefox \
    firefox-l10n-${system_lang_code_env_lower} \
    font-manager \
    git \
    inetutils-tools \
    lsb-release \
    make \
    net-tools \
    pavucontrol \
    pulseaudio-utils \
    alsa-utils \
    tigervnc-common \
    tigervnc-standalone-server \
    tigervnc-tools \
    gvfs-backends \
    tumbler \
    ffmpegthumbnailer \
    ffmpeg \
    mpv \
    unzip \
    xdg-user-dirs \
    xz-utils \
    zip \
    mesa-utils \
    mesa-utils-extra \
    mesa-vulkan-drivers \
    libgl1-mesa-dri \
    libglx-mesa0


echo -e "\033[1;96m$label_system_setup\033[0m"
echo " "
sleep 2

mkdir -p "/usr/share/backgrounds"
mkdir -p "/usr/share/icons"
mkdir -p "/root/.config/gtk-3.0"
mkdir -p "/root/.vnc"
echo -e "file:///sdcard sdcard" | tee /root/.config/gtk-3.0/bookmarks
echo "alias ls='ls --color=auto'" >> $HOME/.bashrc
echo "source \"/usr/local/lib/andistro/global\"" >> $HOME/.bashrc

echo -e "\033[1;96m$label_themes\033[0m"
echo " "
sleep 2
git clone https://github.com/andistro/themes.git
mv themes/AnDistro*/ /usr/share/themes/
rm -rf themes/

echo -e "\033[1;96m$label_icons\033[0m"
echo " "
sleep 2
git clone https://github.com/ZorinOS/zorin-icon-themes.git
mv zorin-icon-themes/Zorin*/ /usr/share/icons/
rm -rf zorin-*-themes/

echo -e "\033[1;96m$label_xdg_user_dirs_setup\033[0m"
echo " "
sleep 2
xdg-user-dirs-update

echo -e "[Settings]\ngtk-theme-name=AnDistro-Majorelle-Blue-${distro_theme}" | sudo tee $HOME/.config/gtk-3.0/settings.ini
echo "gtk-theme-name=\"AnDistro-Majorelle-Blue-${distro_theme}\"" | sudo tee $HOME/.gtkrc-2.0

udo apt --fix-broken install -y
sudo dpkg --configure -a
udo apt --fix-broken install -y

sudo apt-get clean

echo -e "\033[1;96m$label_wallpaper_download\033[0m"
echo " "
sleep 2

mkdir -p /usr/share/backgrounds/andistro

wget -O "/usr/share/backgrounds/andistro/andistro-light.jpg" "https://gitlab.com/andistro/wallpapers/-/raw/main/light.jpg"
wget -O "/usr/share/backgrounds/andistro/andistro-medium.jpg" "https://gitlab.com/andistro/wallpapers/-/raw/main/medium.jpg"
wget -O "/usr/share/backgrounds/andistro/andistro-dark.jpg" "https://gitlab.com/andistro/wallpapers/-/raw/main/dark.jpg"

bash $HOME/config-environment.sh "$distro_theme"

distro_name="$(tr '[:lower:]' '[:upper:]' <<< "${distro_name:0:1}")${distro_name:1}"
label_distro_boot=$(printf "$label_distro_boot" "$distro_name")
echo "\033[1;96m$label_distro_boot\033[0m" >> $HOME/.bashrc > /dev/null 2>&1

echo -e "\033[1;96m$label_distro_boot\033[0m"

rm -rf $HOME/locale*.sh
rm -rf $HOME/.hushlogin
rm -rf $HOME/system-config.sh
rm -rf $HOME/config-environment.sh
rm -rf $HOME/start-environment.sh
rm -rf $HOME/wallpapers.sh
rm -rf $HOME/.bash_profile
rm -rf $HOME/.dialogrc

sudo apt clean > /dev/null 2>&1

sudo apt autoclean > /dev/null 2>&1

exit