#!/bin/bash
# Variáveis de configuração
distro_name=""
distro_theme=""
LANG=""
etc_timezone=$(cat /etc/timezone)

# Fonte modular configuração global
source "/usr/local/lib/andistro/global"

# Mensagem de inicialização
echo -e "\n ${distro_wait}\n"

show_progress_dialog steps-one-label "${label_progress}" 34 \
    "sed -i \"s/^# *\(${system_icu_lang_code_env}.UTF-8\)/\1/\" /etc/locale.gen" \
    "sudo locale-gen ${system_icu_lang_code_env}.UTF-8" \
    "echo \"LANG=${system_icu_lang_code_env}.UTF-8\" > /etc/locale.conf" \
    "echo \"export LANG=${system_icu_lang_code_env}.UTF-8\" >> $HOME/.bashrc" \
    "echo \"export LANGUAGE=${system_icu_lang_code_env}.UTF-8\" >> $HOME/.bashrc" \
    "sudo mv /var/lib/dpkg/info /var/lib/dpkg/info_old" \
    "sudo mkdir /var/lib/dpkg/info" \
    "apt update" \
    "sudo install -d -m 0755 /etc/apt/keyrings" \
    "[ ! -f /etc/apt/sources.list.d/mozilla.sources ] && wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc" \
    "if [ ! -f /etc/apt/sources.list.d/mozilla.sources ]; then
cat <<EOF | sudo tee /etc/apt/sources.list.d/mozilla.sources
Types: deb
URIs: https://packages.mozilla.org/apt
Suites: mozilla
Components: main
Signed-By: /etc/apt/keyrings/packages.mozilla.org.asc
EOF
fi" \
    "if [ ! -f /etc/apt/preferences.d/mozilla ]; then
echo -e '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' | sudo tee /etc/apt/preferences.d/mozilla
fi" \
    "[ ! -f /etc/apt/sources.list.d/vscode.sources ] && wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg" \
    "[ ! -f /etc/apt/sources.list.d/vscode.sources ] && sudo install -D -o root -g root -m 644 microsoft.gpg /usr/share/keyrings/microsoft.gpg" \
    "rm -f microsoft.gpg" \
    "if [ ! -f /etc/apt/sources.list.d/vscode.sources ]; then
cat <<EOF | sudo tee /etc/apt/sources.list.d/vscode.sources
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Signed-By: /usr/share/keyrings/microsoft.gpg
EOF
fi" \
    "[ ! -f /etc/apt/sources.list.d/brave-browser-release.sources ] && sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg" \
    "[ ! -f /etc/apt/sources.list.d/brave-browser-release.sources ] && sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources https://brave-browser-apt-release.s3.brave.com/brave-browser.sources" \
    "[ ! -f /etc/apt/sources.list.d/brave-browser-beta.sources ] && sudo curl -fsSLo /usr/share/keyrings/brave-browser-beta-archive-keyring.gpg https://brave-browser-apt-beta.s3.brave.com/brave-browser-beta-archive-keyring.gpg" \
    "[ ! -f /etc/apt/sources.list.d/brave-browser-beta.sources ] && sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-beta.sources https://brave-browser-apt-beta.s3.brave.com/brave-browser.sources" \
    "[ ! -f /etc/apt/sources.list.d/brave-browser-nightly.sources ] && sudo curl -fsSLo /usr/share/keyrings/brave-browser-nightly-archive-keyring.gpg https://brave-browser-apt-nightly.s3.brave.com/brave-browser-nightly-archive-keyring.gpg" \
    "[ ! -f /etc/apt/sources.list.d/brave-browser-nightly.sources ] && sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-nightly.sources https://brave-browser-apt-nightly.s3.brave.com/brave-browser.sources" \
    "[ ! -f /etc/apt/sources.list.d/vivaldi.sources ] && wget -O /usr/share/keyrings/vivaldi-archive-keyring.gpg https://repo.vivaldi.com/archive/linux_signing_key.pub" \
    "if [ ! -f /etc/apt/sources.list.d/vivaldi.sources ]; then
cat <<EOF | sudo tee /etc/apt/sources.list.d/vivaldi.sources
Types: deb
URIs: https://repo.vivaldi.com/archive/deb/
Suites: stable
Components: main
Signed-By: /usr/share/keyrings/vivaldi-archive-keyring.gpg
EOF
fi" \
    "apt update" \
    "sudo dpkg --configure -a" \
    "sudo apt --fix-broken install -y" \
    "sudo mv /var/lib/dpkg/info/* /var/lib/dpkg/info_old/." \
    "sudo rm -rf /var/lib/dpkg/info" \
    "sudo mv /var/lib/dpkg/info_old /var/lib/dpkg/info" \
    "sudo apt update" \
    "sudo ln -sf \"/usr/share/zoneinfo/${etc_timezone}\" /etc/localtime" \
    "dialog --create-rc $HOME/.dialogrc" \
    "sed -i \"s|use_shadow = ON|use_shadow = OFF|g\" $HOME/.dialogrc"

# Executa as configurações base do sistema
bash $HOME/system-config.sh "${distro_theme}" "${distro_name}"


show_progress_dialog steps-multi-label 4 \
    "${label_wallpaper_download}\n\n → AnDistro: " 'mkdir -p /usr/share/backgrounds/andistro'\
    "${label_wallpaper_download}\n\n → AnDistro: Light" 'wget -O "/usr/share/backgrounds/andistro/andistro-light.jpg" "https://gitlab.com/andistro/wallpapers/-/raw/main/light.jpg"' \
    "${label_wallpaper_download}\n\n → AnDistro: Medium" 'wget -O "/usr/share/backgrounds/andistro/andistro-medium.jpg" "https://gitlab.com/andistro/wallpapers/-/raw/main/medium.jpg"' \
    "${label_wallpaper_download}\n\n → AnDistro: Dark" 'wget -O "/usr/share/backgrounds/andistro/andistro-dark.jpg" "https://gitlab.com/andistro/wallpapers/-/raw/main/dark.jpg"'


# Configurações da inteface escolhida
if [ -f "$HOME/config-environment.sh" ]; then
    bash "$HOME/config-environment.sh" "${distro_theme}"
fi

distro_name="$(tr '[:lower:]' '[:upper:]' <<< "${distro_name:0:1}")${distro_name:1}"
label_distro_boot=$(printf "$label_distro_boot" "$distro_name")

echo "echo -e \"\033[1;96m${label_distro_boot}\033[0m\"" >> $HOME/.bashrc

rm -rf $HOME/.hushlogin
rm -rf $HOME/system-config.sh
rm -rf $HOME/config-environment.sh
rm -rf $HOME/.bash_profile
rm -rf $HOME/.dialogrc
sudo apt clean

sudo apt autoclean

andistro alerta install-success

exit