#!/data/data/com.termux/files/usr/bin/bash
# chmod +x "$PREFIX/var/lib/andistro/manager/backup.sh" && bash "$PREFIX/var/lib/andistro/manager/backup.sh"
clear

source "$PREFIX/var/lib/andistro/lib/share/global"

title_progress="Progresso"

DEBIAN_DIR="$PREFIX/var/lib/andistro/manager/debian/stable"
BACKUP_BASE="/sdcard/termux/andistro"
BACKUP_DIR="$BACKUP_BASE/backups"
LOG_DIR="$BACKUP_BASE/logs"
TMPDIR_DEFAULT="$BACKUP_BASE/tmp"

mkdir -p "$BACKUP_DIR" "$LOG_DIR" "$TMPDIR_DEFAULT"

if [ ! -d "$DEBIAN_DIR" ]; then
    dialog --no-shadow --msgbox "Erro: $DEBIAN_DIR não encontrado." 8 60
    exit 1
fi

OS_RELEASE="$DEBIAN_DIR/etc/os-release"
VERSION_CODENAME=$(grep '^VERSION_CODENAME=' "$OS_RELEASE" 2>/dev/null | cut -d= -f2 | tr -d '"')
[ -z "$VERSION_CODENAME" ] && VERSION_CODENAME="unknown"

DEBIAN_LANG_FILE="$DEBIAN_DIR/etc/default/locale"
if [ -f "$DEBIAN_LANG_FILE" ]; then
    DEBIAN_LANG=$(grep '^LANG=' "$DEBIAN_LANG_FILE" 2>/dev/null | head -n1 | cut -d= -f2 | tr -d '"' | tr '_' '-')
else
    DEBIAN_LANG="unknown"
fi

TIMESTAMP=$(date +'%d%m%Y-%H%M%S')

SCRIPT_NAME=$(basename "$0"); SCRIPT_NAME="${SCRIPT_NAME%%.*}"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_${TIMESTAMP}.txt"

# Pede senha com opção de exibir/ocultar
SENHA=$(dialog --no-shadow --insecure --cancel-label "Exibir" \
    --passwordbox "Senha forte para criptografar o backup:\n\n(20+ chars, números/símbolos)" \
    $dialog_height $dialog_width 3>&1 1>&2 2>&3)
dialog_retorno=$?

if [ $dialog_retorno -eq 1 ]; then
    SENHA=$(dialog --no-shadow --cancel-label "Ocultar" \
        --inputbox "Senha forte para criptografar o backup (VISÍVEL):\n\n(20+ chars, números/símbolos)" \
        $dialog_height $dialog_width 3>&1 1>&2 2>&3)
    dialog_retorno=$?
    if [ $dialog_retorno -eq 1 ]; then
        SENHA=$(dialog --no-shadow --insecure --cancel-label "Exibir" \
            --passwordbox "Senha forte para criptografar o backup:\n\n(20+ chars, números/símbolos)" \
            $dialog_height $dialog_width 3>&1 1>&2 2>&3)
    fi
fi

if [ -z "$SENHA" ]; then
    dialog --no-shadow --msgbox "Senha vazia. Backup cancelado." $dialog_height $dialog_width
    exit 1
fi

TAR_TEMP=$(mktemp "$TMPDIR_DEFAULT/andistro-tar-XXXXXX.tar.gz")
SENHA_FILE=$(mktemp "$TMPDIR_DEFAULT/andistro-pass-XXXXXX")
GPG_TEMP="$BACKUP_DIR/andistro_debian-${VERSION_CODENAME}-${TIMESTAMP}.tar.gz.gpg"

echo "$SENHA" > "$SENHA_FILE"
chmod 600 "$SENHA_FILE"

show_progress_dialog steps-multi-label-alt 5 \
    "Iniciando backup do Debian..." "echo \"[1/5] Iniciando backup\" >> \"$LOG_FILE\"; sleep 2" \
    "Fazendo backup: compactando sistema Debian (stable)...\n\nEsta etapa pode ser demorada" "echo \"[2/5] Compactando sistema Debian (stable)\" >> \"$LOG_FILE\"; tar -czf \"$TAR_TEMP\" -C \"$DEBIAN_DIR\" . >> \"$LOG_FILE\" 2>&1" \
    "Criptografando backup com GPG (AES256)..." "echo \"[3/5] Criptografando com GPG\" >> \"$LOG_FILE\"; gpg --batch --yes --passphrase-file \"$SENHA_FILE\" --symmetric --cipher-algo AES256 --output \"$GPG_TEMP\" \"$TAR_TEMP\" >> \"$LOG_FILE\" 2>&1" \
    "Verificando arquivo gerado..." "echo \"[4/5] Verificando arquivo $GPG_TEMP\" >> \"$LOG_FILE\"; if [ -f \"$GPG_TEMP\" ]; then echo \"OK: $GPG_TEMP\" >> \"$LOG_FILE\"; else echo \"ERRO: arquivo não encontrado\" >> \"$LOG_FILE\"; fi; sleep 2" \
    "Finalizando o backup..." "echo \"[5/5] Limpando temporários\" >> \"$LOG_FILE\"; rm -f \"$TAR_TEMP\" \"$SENHA_FILE\"; sleep 2"

# Se o GPG gerou o arquivo temporário, calcula checksum e renomeia
if [ -f "$GPG_TEMP" ]; then
    # garante sha256sum disponível
    if ! command -v sha256sum >/dev/null 2>&1; then
        pkg install -y coreutils >/dev/null 2>&1
    fi

    FILE_CHECKSUM=$(sha256sum "$GPG_TEMP" | awk '{print $1}')

    LANG_CODE="$DEBIAN_LANG"
    [ -z "$LANG_CODE" ] && LANG_CODE="unknown"


    MANUF_CLEAN=$(echo "$device_manufacturer" | tr ' ' '_' | tr '/' '_')
    MODEL_CLEAN=$(echo "$device_model" | tr ' ' '_' | tr '/' '_')
    ARCH_CLEAN=$(echo "$android_architecture" | tr ' ' '_' | tr '/' '_')

    BACKUP_NAME="[ANDISTRO]__Debian_${VERSION_CODENAME}_${LANG_CODE}__-__${MANUF_CLEAN}_${MODEL_CLEAN}_${ARCH_CLEAN}__-__${FILE_CHECKSUM}__-__${TIMESTAMP}.tar.gz.gpg"
    ARQ="$BACKUP_DIR/$BACKUP_NAME"

    mv "$GPG_TEMP" "$ARQ"
    echo "Arquivo final: $ARQ" >> "$LOG_FILE"
fi

if [ -f "$ARQ" ]; then
    dialog --no-shadow --msgbox "Backup concluído com sucesso.\n\nArquivo: $ARQ\nTamanho: $(du -sh "$ARQ" | cut -f1)\n\nLog: $LOG_FILE" 11 70
    exit 0
else
    dialog --no-shadow --msgbox "Erro ao criar backup.\nVeja o log:\n$LOG_FILE" 10 70
    exit 1
fi
