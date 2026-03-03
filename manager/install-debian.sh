#!/data/data/com.termux/files/usr/bin/bash
# Variáveis de configuração
config_file="$1"
andistro_files="$2"
distro_name="$3"
bin="$4"
folder="$5"
binds="$6"
archurl="$7"
config_environment="$8"
distro_theme="$9"
distro_version="${10}"

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
	{
		for i in {1..50}; do
			sleep 0.1
			echo $((i * 2))
		done
	} | dialog --no-shadow --gauge "$label_distro_download_start" $dialog_height $dialog_width
	debootstrap --arch=$archurl --variant=minbase --include=dialog,sudo,wget,nano,locales,gpg,curl,ca-certificates $distro_version $folder http://deb.${distro_name}.org/${distro_name}/  2>&1 | dialog --no-shadow --title "${label_distro_download}" --progressbox $dialog_height $dialog_width
	{
		for i in {1..50}; do
			sleep 0.1
			echo $((i * 2))
		done
	} | dialog --no-shadow --gauge "$label_distro_download_finish" $dialog_height $dialog_width
fi

echo 'VARIANT="AnDistro"
VARIANT_ID="andistro"' >> $folder/etc/os-release

rm -rf $folder/etc/apt/sources.list

echo "deb http://deb.debian.org/debian $distro_version main contrib non-free non-free-firmware
deb http://deb.debian.org/debian $distro_version-updates main contrib non-free
deb http://security.debian.org/debian-security $distro_version-security main contrib non-free" >> $folder/etc/apt/sources.list

chmod 644 $folder/etc/apt/sources.list
chown root:root $folder/etc/apt/sources.list

# Configurações pós-instalação
cp "$config_file/start-distro" $bin

sed -i "s|command+=\" LANG=\$system_icu_lang_code_env.UTF-8\"|command+=\" LANG=$system_icu_lang_code_env.UTF-8\"|g" $bin

chmod +x $bin

rm -rf $folder/root/.bash_profile
cp "$config_file/.bash_profile" $folder/root/.bash_profile

sed -i "s|distro_name=\"\"|distro_name=\"$distro_name\"|g" $folder/root/.bash_profile
sed -i "s|distro_theme=\"\"|distro_theme=\"$distro_theme\"|g" $folder/root/.bash_profile
sed -i "s|LANG=\"\"|LANG=\"$system_icu_lang_code_env.UTF-8\"|g" $folder/root/.bash_profile
	
cp $config_file/system-config.sh $folder/root/system-config.sh

if [ "$config_environment" = "null" ]; then
	echo " "
elif [ "$config_environment" = "xfce4" ]; then
	cp "$config_file/environment/$config_environment/config-environment.sh" "$folder/root/config-environment.sh"
	cp "$config_file/environment/$config_environment/xfce4-panel.tar.bz2" "$folder/root/xfce4-panel.tar.bz2"
else
	cp "$config_file/environment/$config_environment/config-environment.sh" "$folder/root/config-environment.sh"
fi

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

echo "nameserver 8.8.8.8
nameserver 8.8.4.4" | tee $folder/etc/resolv.conf > /dev/null 2>&1
echo "$system_timezone" | tee $folder/etc/timezone > /dev/null 2>&1

if grep -q "^LANG=" $folder/etc/environment 2>/dev/null; then
    sed -i "s/^LANG=.*$/LANG=$system_icu_lang_code_env.UTF-8/" $folder/etc/environment
else
    echo "LANG=$system_icu_lang_code_env.UTF-8" | tee -a $folder/etc/environment > /dev/null 2>&1
fi

# KERNEL_VERSON=$(uname -r)

# if [ ! -f "${folder}/proc/fakethings/version" ]; then
# 	cat <<- EOF > "${folder}/proc/fakethings/version"
# 	$KERNEL_VERSION (FakeAndroid)
# 	EOF
# fi

echo "APT::Acquire::Retries \"3\";" > $folder/etc/apt/apt.conf.d/80-retries #Setting APT retry count
touch $folder/root/.hushlogin

# Cria o arquivo bash_profile para as configurações serem iniciadas junto com o sistema

# Inicia o sistema

sed -i "s/^# *\($system_icu_lang_code_env.UTF-8\)/\1/" $folder/etc/locale.gen

echo -e "LANG=$system_icu_lang_code_env.UTF-8" > $folder/etc/locale.conf

echo "export LANG=$system_icu_lang_code_env.UTF-8" >> $folder/root/.bashrc 

echo "export LANGUAGE=$system_icu_lang_code_env.UTF-8" >> $folder/root/.bashrc

echo "export LANGUAGE=$system_icu_lang_code_env.UTF-8" >> $folder/root/.bashrc

bash $bin "locale-gen $system_icu_lang_code_env.UTF-8"


bash $bin