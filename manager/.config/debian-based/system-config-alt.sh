#!/usr/bin/env bash
# Configuração pós-bootstrap otimizada para Debian em Termux/PRoot.
# Execute como root dentro da distribuição.

set -u
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

distro_theme="${1:-Blue}"
distro_name="${2:-debian}"

# O valor 0 instala só o necessário para o desktop funcionar.
# Use ANDISTRO_FULL_INSTALL=1 para instalar navegador e ferramentas multimídia.
: "${ANDISTRO_FULL_INSTALL:=0}"
: "${ANDISTRO_MIN_FREE_MB:=1800}"

if [ -r /usr/local/lib/andistro/global ]; then
    # shellcheck disable=SC1091
    . /usr/local/lib/andistro/global
fi

LOG_DIR="${ANDISTRO_LOG_DIR:-/sdcard/termux/andistro/logs}"
mkdir -p "$LOG_DIR" 2>/dev/null || LOG_DIR="${TMPDIR:-/tmp}/andistro-logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/system-config-$(date +%Y%m%d-%H%M%S).log"

say() {
    local message="$1"
    printf '%s\n' "$message"
    if command -v dialog >/dev/null 2>&1 && [ -t 1 ]; then
        dialog --no-shadow --infobox "$message" 8 70 || true
    fi
}

run() {
    local description="$1"
    shift
    say "$description"
    printf '\n== %s ==\n$ ' "$description" >> "$LOG_FILE"
    printf '%q ' "$@" >> "$LOG_FILE"
    printf '\n' >> "$LOG_FILE"
    if "$@" >> "$LOG_FILE" 2>&1; then
        return 0
    fi
    printf 'FALHOU (%s): %s\n' "$?" "$description" >> "$LOG_FILE"
    say "Falhou: $description\nConsulte: $LOG_FILE"
    return 1
}

# Executa uma única transação APT, mas conserva o feedback visual por pacote.
# O APT escreve o pacote corrente ("Unpacking" / "Setting up") no log; a
# barra lê esse estado sem iniciar um novo apt-get a cada item.
apt_install_with_progress() {
    local description="$1"
    shift
    local total="$#"
    local progress_log="$LOG_FILE.apt-progress"
    local status_file="$LOG_FILE.apt-status"
    local current=""
    local completed=0
    local percent=0
    local rc=1

    : > "$progress_log"
    rm -f "$status_file"
    say "$description"

    {
        printf '\n== %s ==\n' "$description" >> "$LOG_FILE"
        "${APT[@]}" install "$@" > "$progress_log" 2>&1 &
        local apt_pid=$!

        while kill -0 "$apt_pid" 2>/dev/null; do
            # Conta só a primeira ocorrência de cada pacote e exibe o último
            # pacote que o dpkg está desempacotando/configurando.
            IFS='|' read -r completed current < <(
                awk '
                    /^(Preparing to unpack|Unpacking|Setting up) / {
                        pkg=$3; gsub(/[():]/, "", pkg)
                        if (!seen[pkg]++) count++
                        last=pkg
                    }
                    END { printf "%d|%s\\n", count+0, last }
                ' "$progress_log"
            )
            [ "$completed" -gt "$total" ] && completed="$total"
            percent=$(( completed * 100 / total ))
            printf 'XXX\n%s\n%s%s\nXXX\n' "$percent" "$description" "${current:+\n → $current}"
            sleep 0.35
        done

        wait "$apt_pid"; rc=$?
        cat "$progress_log" >> "$LOG_FILE"
        printf '%s\n' "$rc" > "$status_file"
        if [ "$rc" -eq 0 ]; then
            printf 'XXX\n100\n%s\nXXX\n' "$description"
        else
            printf 'XXX\n100\nFalhou: %s\nXXX\n' "$description"
        fi
    } | if command -v dialog >/dev/null 2>&1 && [ -t 1 ]; then
            dialog --no-shadow --gauge "$description" 10 70
        else
            cat >/dev/null
        fi

    [ -r "$status_file" ] && rc="$(cat "$status_file")"
    if [ "$rc" -ne 0 ]; then
        say "Falhou: $description\nConsulte: $LOG_FILE"
        return "$rc"
    fi
}

free_mb() {
    df -Pk / 2>/dev/null | awk 'NR==2 { print int($4 / 1024) }'
}

available_mb="$(free_mb)"
case "$available_mb" in
    ''|*[!0-9]*) ;;
    *)
        if [ "$available_mb" -lt "$ANDISTRO_MIN_FREE_MB" ]; then
            say "Espaço insuficiente: ${available_mb} MB livres; mínimo: ${ANDISTRO_MIN_FREE_MB} MB."
            exit 1
        fi
        ;;
esac

# Uma transação APT por grupo reduz drasticamente forks, parsing do cache e I/O.
APT=(apt-get -y --no-install-recommends
     -o Acquire::Retries=3
     -o Dpkg::Use-Pty=0
     -o Dpkg::Options::=--force-confdef
     -o Dpkg::Options::=--force-confold)

core_packages=(
    apt-utils apt-transport-https ca-certificates debconf-utils dbus-x11
    tzdata python3 python3-psutil python3-pip python3-venv
    at-spi2-core exo-utils git inetutils-tools lsb-release make net-tools
    tigervnc-common tigervnc-standalone-server tigervnc-tools
    gvfs-backends tumbler xdg-user-dirs xz-utils unzip zip
    mesa-utils mesa-utils-extra mesa-vulkan-drivers libgl1-mesa-dri libglx-mesa0
)

# Estes pacotes são grandes e não são necessários para concluir o primeiro boot.
extra_packages=(
    firefox "firefox-l10n-${system_lang_code_env_lower:-en-us}"
    bleachbit font-manager pavucontrol pulseaudio-utils alsa-utils
    ffmpeg ffmpegthumbnailer mpv
)

run "Limpando cache APT" apt-get clean || true
run "Atualizando índices de pacotes" "${APT[@]}" update || exit 1
# Evite full-upgrade no bootstrap: ele aumenta o pico de RAM/dados e pode trocar
# pacotes críticos. A atualização completa pode ser oferecida depois, sob demanda.
apt_install_with_progress "Instalando componentes essenciais" "${core_packages[@]}" || exit 1

if [ "$ANDISTRO_FULL_INSTALL" = 1 ]; then
    apt_install_with_progress "Instalando componentes opcionais" "${extra_packages[@]}" || true
else
    say "Essenciais concluídos. Extras foram adiados (defina ANDISTRO_FULL_INSTALL=1 para instalá-los)."
fi

run "Finalizando configuração de pacotes" dpkg --configure -a || exit 1
run "Reparando dependências pendentes" "${APT[@]}" -f install || exit 1

install -d -m 0755 /usr/share/backgrounds /usr/share/icons "$HOME/.config/gtk-3.0" "$HOME/.vnc"
printf 'file:///sdcard sdcard\n' > "$HOME/.config/gtk-3.0/bookmarks"
grep -qxF "alias ls='ls --color=auto'" "$HOME/.bashrc" 2>/dev/null || printf "alias ls='ls --color=auto'\n" >> "$HOME/.bashrc"
grep -qxF 'source "/usr/local/lib/andistro/global"' "$HOME/.bashrc" 2>/dev/null || printf 'source "/usr/local/lib/andistro/global"\n' >> "$HOME/.bashrc"

# Clone apenas quando os temas forem realmente necessários; use diretórios
# temporários para não deixar repositórios grandes dentro de /root.
if [ "${ANDISTRO_INSTALL_THEMES:-1}" = 1 ]; then
    workdir="$(mktemp -d)"
    trap 'rm -rf "$workdir"' EXIT
    if run "Baixando tema AnDistro" git clone --depth=1 https://github.com/andistro/themes.git "$workdir/themes"; then
        find "$workdir/themes" -mindepth 1 -maxdepth 1 -type d -name 'AnDistro*' -exec mv -t /usr/share/themes {} + 2>>"$LOG_FILE" || true
    fi
    if run "Baixando ícones Zorin" git clone --depth=1 https://github.com/ZorinOS/zorin-icon-themes.git "$workdir/icons"; then
        find "$workdir/icons" -mindepth 1 -maxdepth 1 -type d -name 'Zorin*' -exec mv -t /usr/share/icons {} + 2>>"$LOG_FILE" || true
    fi
fi

xdg-user-dirs-update || true
printf '[Settings]\ngtk-theme-name=AnDistro-Majorelle-Blue-%s\n' "$distro_theme" > "$HOME/.config/gtk-3.0/settings.ini"
printf 'gtk-theme-name="AnDistro-Majorelle-Blue-%s"\n' "$distro_theme" > "$HOME/.gtkrc-2.0"

run "Limpando arquivos temporários" apt-get clean || true
say "Configuração concluída. Log: $LOG_FILE"
