#!/data/data/com.termux/files/usr/bin/bash
# Variáveis de configuração
config_file="$1"
andistro_files="$2"
distro_name="$3"
bin="$4"
folder="$5"
binds="$6"
system_lang_code="$7"
system_lang_code_env="$8"
archurl="$9"
config_environment="${10}"
distro_theme="${11}"
distro_version="${12}"

source "$PREFIX/var/lib/andistro/lib/share/global"
# Fonte modular configuração global

#=============================================================================================
# Caso a versão já tenha sido baixada, não baixar novamente
if [ -d "$folder" ]; then
	first=1
	echo "${label_skip_download}"
fi

sleep 2
# Baixar
label_distro_download=$(printf "$label_distro_download" "$distro_name")
label_distro_download_start=$(printf "$label_distro_download_start" "$distro_name")
label_distro_download_finish=$(printf "$label_distro_download_finish" "$distro_name")

if [ "$first" != 1 ];then

echo -e "\033[1;96m$label_distro_download_start\033[0m"
echo -e"\033[1;96m$label_distro_download\033[0m"
echo " "
debootstrap --arch=$archurl --variant=minbase --include=dialog,sudo,wget,nano,locales,gpg,curl,ca-certificates $distro_version $folder http://deb.${distro_name}.org/${distro_name}/ 
echo " "
echo  -e "\033[1;32m$label_distro_download_finish\033[0m"

fi

# Configurações pós-instalação
# copia o arquivo de configuração de idioma da pasta $PREFIX/var/lib/andistro/manager/.configs/debian-based/locale_setup/ ppara o root
cp "$config_file/start-distro" $bin
sed -i "s|command+=\" -r \$folder\"|command+=\" -r $folder\"|g" $bin
sed -i "s|command+=\" -b \$folder/root:/dev/shm\"|command+=\" -b $folder/root:/dev/shm\"|g" $bin
sed -i "s|command+=\" -b \$config_file/proc/fakethings/stat:/proc/stat\"|command+=\" -b $config_file/proc/fakethings/stat:/proc/stat\"|g" $bin
sed -i "s|command+=\" -b \$config_file/proc/fakethings/vmstat:/proc/vmstat\"|command+=\" -b $config_file/proc/fakethings/vmstat:/proc/vmstat\"|g" $bin
sed -i "s|command+=\" -b \$andistro_files/lib/share:/usr/local/lib/andistro\"|command+=\" -b $andistro_files/lib/share:/usr/local/lib/andistro\"|g" $bin
sed -i "s|command+=\" -b \$andistro_files/manager:/usr/local/lib/andistro/manager\"|command+=\" -b $andistro_files/manager:/usr/local/lib/andistro/manager\"|g" $bin
sed -i "s|command+=\" -b \$andistro_files/manager/.config/debian-based/bin:/usr/local/bin/\"|command+=\" -b $andistro_files/manager/.config/debian-based/bin:/usr/local/bin/\"|g" $bin
sed -i "s|command+=\" -b \$PREFIX/bin/andistro:/usr/local/lib/andistro/bin/andistro\"|command+=\" -b $PREFIX/bin/andistro:/usr/local/lib/andistro/bin/andistro\"|g" $bin
sed -i "s|command+=\" LANG=\$system_icu_lang_code_env.UTF-8\"|command+=\" LANG=$system_icu_lang_code_env.UTF-8\"|g" $bin

chmod +x $bin

rm -rf $folder/root/.bash_profile
cp "$PREFIX/var/lib/andistro/manager/.terminal_mode/.bash_profile" $folder/root/.bash_profile

sed -i "s|distro_name=\"\$1\"|distro_name=\"$distro_name\"|g" $folder/root/.bash_profile
sed -i "s|distro_theme=\"\$2\"|distro_theme=\"$distro_theme\"|g" $folder/root/.bash_profile
sed -i "s|system_lang_code=\"\$3\"|system_lang_code=\"$system_lang_code\"|g" $folder/root/.bash_profile

cp "$PREFIX/var/lib/andistro/manager/.terminal_mode/.config/debian-based/environment/$config_environment/config-environment.sh" "$folder/root/config-environment.sh"
if [ "$config_environment" = "xfce4" ]; then
    # Coloque aqui o comando que você quer executar quando for XFCE4
	cp "$config_file/environment/$config_environment/xfce4-panel.tar.bz2" "$folder/root/xfce4-panel.tar.bz2"
fi

# Adicionar entradas em hosts, resolv.conf e timezone
echo "127.0.0.1 localhost localhost" | tee $folder/etc/hosts
echo "nameserver 8.8.8.8" | tee $folder/etc/resolv.conf 
echo "$system_timezone" | tee $folder/etc/timezone


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
bash $bin