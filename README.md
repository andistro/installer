<!--
📄 Documentação
<div align="center">
<a href="#"><img src=""></a>
</div>
-->

<div align="center">
  <img src="https://raw.githubusercontent.com/andistro/.github/refs/heads/main/profile/assets/images/logo.png">
</div>

<br>
<div align="center">
  
  |<img height="24" src="https://raw.githubusercontent.com/andistro/.github/main/profile/assets/flags/brasil.svg" />|[Guia de instalação e resolução de problemas](https://github.com/andistro/wiki/tree/main/pt-BR#readme)|
  |-|-|
  <!-- |<img height="24" src="https://raw.githubusercontent.com/andistro/.github/main/profile/assets/flags/united_states.svg" />|[**Installation and troubleshooting guide**](https://github.com/andistro/wiki/tree/main/en-US#readme)| -->
  
</div>

<br>
# 📥
```bash
curl -L "https://raw.githubusercontent.com/andistro/installer/refs/heads/alpha/andistro_setup" | bash
```
<br><br>



```bash 
andistro/app (branch: alpha)
│
├── manager/
│   ├── .config/
│   │   ├── debian-based/
│   │   │   ├── environment/
│   │   │   │   ├── lxde/
│   │   │   │   │   └── config-environment.sh
│   │   │   │   └── xfce4/
│   │   │   │       ├── config-environment.sh
│   │   │   │       └── xfce4-panel.tar.bz2
│   │   │   ├── proc/
│   │   │   │   └── fakethings/
│   │   │   │       ├── stat
│   │   │   │       └── vmstat
│   │   │   ├── .bash_profile
│   │   │   ├── start-distro
│   │   │   └── system-config.sh
│   │   └── autoboot
│   ├── .terminal_mode/
│   │   ├── .config/
│   │   │   └── debian-based/
│   │   │       └── environment/
│   │   │           ├─── lxde/
│   │   │           │    └── config-environment.sh
│   │   │           └── xfce4/
│   │   │               ├── config-environment.sh
│   │   │               └── xfce4-panel.tar.bz2
│   │   ├── .bash_profile
│   │   └── install-debian.sh
│   └── install-debian.sh
├── lib/
│   └── share/
│       ├── locales/
│       │   ├── l10n_en-US.sh
│       │   └── l10n_pt-BR.sh
│       ├── global
│       └── listener
├── .editorconfig
├── .gitattributes
├── README.md
├── andistro
├── andistro_setup
└── termos.sh
```



#### Comando experimental para testes

Este é um comando do desenvolvedor para instalar o debian puro para fazer testes de instalação.

```bash
source "$PREFIX/var/lib/andistro/lib/share/global"
cleanup_old_logs
andistro_files="$PREFIX/var/lib/andistro"
distro_name="debian"
distro_version="stable"
distro_based="debian"
distro_file="install-$distro_name.sh"
config_file="$andistro_files/manager/.config/$distro_based-based"
bin="$andistro_files/manager/start-$distro_name"
folder="$andistro_files/manager/$distro_name/$distro_version"
mkdir -p "$PREFIX/var/lib/andistro/manager/$distro_name"
mkdir -p "/sdcard/termux/andistro/manager/$distro_name/$distro_version"
archurl="arm64"
config_environment="xfce4"
distro_theme="Dark"
debootstrap --arch=$archurl --variant=minbase --include=dialog,sudo,wget,nano,locales,gpg,curl,ca-certificates $distro_version $folder http://deb.${distro_name}.org/${distro_name}/
cp "$config_file/start-distro" $bin
sed -i "s|command+=\" LANG=\$system_icu_lang_code_env.UTF-8\"|command+=\" LANG=$system_icu_lang_code_env.UTF-8\"|g" $bin
chmod +x $bin
rm -rf $folder/root/.bash_profile
cp "$config_file/.bash_profile" $folder/root/.bash_profile
sed -i "s|distro_name=\"\$1\"|distro_name=\"$distro_name\"|g" $folder/root/.bash_profile
sed -i "s|distro_theme=\"\$2\"|distro_theme=\"$distro_theme\"|g" $folder/root/.bash_profile
sed -i "s|LANG=\"\$3\"|LANG=\"$system_icu_lang_code_env.UTF-8\"|g" $folder/root/.bash_profile
cp $config_file/system-config.sh $folder/root/system-config.sh
echo "127.0.0.1 localhost localhost" | tee $folder/etc/hosts
echo "nameserver 8.8.8.8" | tee $folder/etc/resolv.conf
echo "$system_timezone" | tee $folder/etc/timezone
echo "APT::Acquire::Retries \"3\";" > $folder/etc/apt/apt.conf.d/80-retries
touch $folder/root/.hushlogin
```