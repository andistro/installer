#!/data/data/com.termux/files/usr/bin/bash
# Variáveis de configuração
config_file="$1"
andistro_files="$2"
distro_name="$3"
bin="$4"
folder="$5"
config_environment="$6"
distro_version="$7"

source "$PREFIX/var/lib/andistro/lib/share/global" # Fonte modular configuração global

#=============================================================================================
# Caso a versão já tenha sido baixada, não baixar novamente
if [ -d "$folder" ]; then
	first=1
	echo "${label_skip_download}"
fi

sleep 2
# Baixar
label_distro_download=$(printf "$label_distro_download" "Debian")
label_distro_download_start=$(printf "$label_distro_download_start" "Debian")
label_distro_download_finish=$(printf "$label_distro_download_finish" "Debian")

if [ "$first" != 1 ];then

show_progress_dialog steps-one-label "Copiando o Debian do Proot-Distro e baixando pacotes necessários para o Andistro" 12 \
    'sleep 1' \
    'sleep 1' \
    "mkdir -p \"$folder\"" \
    'cp -a "/data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/debian"/* "/data/data/com.termux/files/usr/var/lib/andistro/manager/debian/stable/"' \
    'sleep 5' \
    "cp \"$config_file/start-distro\" $bin" \
    "chmod +x $bin" \
    "bash $bin apt update" \
    "bash $bin apt install dialog sudo wget nano locales gpg curl ca-certificates -y" \
    "sed -i \"s|command+=\" LANG=\$system_icu_lang_code_env.UTF-8\"|command+=\" LANG=$system_icu_lang_code_env.UTF-8\"|g\" $bin" \
    "rm -rf $folder/root/.bash_profile" \
    "cp \"$config_file/.bash_profile\" $folder/root/.bash_profile"
    
fi

rm -rf $folder/etc/apt/sources.list

echo "deb http://deb.debian.org/debian $distro_version main contrib non-free non-free-firmware
deb http://deb.debian.org/debian $distro_version-updates main contrib non-free
deb http://security.debian.org/debian-security $distro_version-security main contrib non-free" >> $folder/etc/apt/sources.list

chmod 644 $folder/etc/apt/sources.list
chown root:root $folder/etc/apt/sources.list

echo "nameserver 8.8.8.8
nameserver 8.8.4.4" | tee $folder/etc/resolv.conf > /dev/null 2>&1
echo "$system_timezone" | tee $folder/etc/timezone > /dev/null 2>&1

cat << 'EOF' >> $folder/etc/hosts
# IPv4.
127.0.0.1   localhost.localdomain localhost
# IPv6.
::1         localhost.localdomain localhost ip6-localhost ip6-loopback
fe00::0     ip6-localnet
ff00::0     ip6-mcastprefix
ff02::1     ip6-allnodes
ff02::2     ip6-allrouters
ff02::3     ip6-allhosts
EOF

# Verifica se existe LANG em /etc/environment e substitui por pt_BR.UTF-8
if grep -q "^LANG=" $folder/etc/environment 2>/dev/null; then
    sed -i "s/^LANG=.*$/LANG=$system_icu_lang_code_env.UTF-8/" $folder/etc/environment
else
    echo "LANG=$system_icu_lang_code_env.UTF-8" | tee -a $folder/etc/environment > /dev/null 2>&1 
fi


rm -rf $folder/etc/profile
cat << 'EOF' >> $folder/etc/profile
# /etc/profile: system-wide .profile file for the Bourne shell (sh(1))
# and Bourne compatible shells (bash(1), ksh(1), ash(1), ...).

if [ "$(id -u)" -eq 0 ]; then
  PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
else
  PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games"
fi
export PATH

if [ "${PS1-}" ]; then
  if [ "${BASH-}" ] && [ "$BASH" != "/bin/sh" ]; then
    # The file bash.bashrc already sets the default PS1.
    # PS1='\h:\w\$ '
    if [ -f /etc/bash.bashrc ]; then
      . /etc/bash.bashrc
    fi
  else
    if [ "$(id -u)" -eq 0 ]; then
      PS1='# '
    else
      PS1='$ '
    fi
  fi
fi

if [ -d /etc/profile.d ]; then
  for i in $(run-parts --list --regex '^[a-zA-Z0-9_][a-zA-Z0-9._-]*\.sh$' /etc/profile.d); do
    if [ -r $i ]; then
      . $i
    fi
  done
  unset i
fi
EOF

if [ "$config_environment" = "null" ]; then
	echo " "
elif [ "$config_environment" = "xfce4" ]; then
    # Coloque aqui o comando que você quer executar quando for XFCE4
	cp "$config_file/environment/$config_environment/config-environment.sh" "$folder/root/config-environment.sh"
	cp "$config_file/environment/$config_environment/xfce4-panel.tar.bz2" "$folder/root/xfce4-panel.tar.bz2"
elif [ "$config_environment" = "lxde" ]; then
    # Coloque aqui o comando que você quer executar quando for LXDE
	cp "$config_file/environment/$config_environment/config-environment.sh" "$folder/root/config-environment.sh"
fi

echo "APT::Acquire::Retries \"3\";" > $folder/etc/apt/apt.conf.d/80-retries #Setting APT retry count

touch $folder/root/.hushlogin

# Inicia o sistema
bash $bin