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
    dialog --no-shadow --msgbox "❌ Erro: $DEBIAN_DIR não encontrado!" $dialog_height $dialog_width
    return 1
fi

OS_RELEASE="$DEBIAN_DIR/etc/os-release"
VERSION_CODENAME=$(grep '^VERSION_CODENAME=' "$OS_RELEASE" 2>/dev/null | cut -d= -f2 | tr -d '"')
[ -z "$VERSION_CODENAME" ] && VERSION_CODENAME="unknown"

TIMESTAMP=$(date +'%d%m%Y-%H%M%S')
BACKUP_NAME="andistro_debian-${VERSION_CODENAME}-${TIMESTAMP}.tar.gz.gpg"
ARQ="$BACKUP_DIR/$BACKUP_NAME"

SCRIPT_NAME=$(basename "$0"); SCRIPT_NAME="${SCRIPT_NAME%%.*}"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_${TIMESTAMP}.txt"

# Pede senha com opção de exibir/ocultar
SENHA=$(dialog --no-shadow --insecure --cancel-label "Exibir" \
    --passwordbox "Senha forte para criptografar o backup:\n\n(20+ chars, números/símbolos)" \
    $dialog_height $dialog_width 3>&1 1>&2 2>&3)
dialog_retorno=$?

if [ $dialog_retorno -eq 1 ]; then
    # Usuário clicou "Exibir": mostra inputbox visível
    SENHA=$(dialog --no-shadow --cancel-label "Ocultar" \
        --inputbox "Senha forte para criptografar o backup (VISÍVEL):\n\n(20+ chars, números/símbolos)" \
        $dialog_height $dialog_width 3>&1 1>&2 2>&3)
    dialog_retorno=$?
    if [ $dialog_retorno -eq 1 ]; then
        # Usuário clicou "Ocultar": volta para passwordbox
        SENHA=$(dialog --no-shadow --insecure --cancel-label "Exibir" \
            --passwordbox "Senha forte para criptografar o backup:\n\n(20+ chars, números/símbolos)" \
            $dialog_height $dialog_width 3>&1 1>&2 2>&3)
    fi
fi

if [ -z "$SENHA" ]; then
    dialog --no-shadow --msgbox "❌ Senha vazia! Backup cancelado." $dialog_height $dialog_width
    return 1
fi

TAR_TEMP=$(mktemp "$TMPDIR_DEFAULT/andistro-tar-XXXXXX.tar.gz")
SENHA_FILE=$(mktemp "$TMPDIR_DEFAULT/andistro-pass-XXXXXX")

echo "$SENHA" > "$SENHA_FILE"
chmod 600 "$SENHA_FILE"

label_step1="Compactando sistema Debian (stable)..."

# Etapa 1: compactação com barra de progresso real via pv + dialog --gauge
TAMANHO_BYTES=$(du -sb "$DEBIAN_DIR" 2>/dev/null | awk '{print $1}')
[ -z "$TAMANHO_BYTES" ] && TAMANHO_BYTES=0

{
    echo "[1/3] $label_step1" >> "$LOG_FILE"
    (
        cd "$DEBIAN_DIR" || exit 1
        # tar -> pv -n (percent) -> gzip -> TAR_TEMP; pv escreve percentuais para stderr
        tar -cf - . 2>>"$LOG_FILE" \
            | pv -n -s "$TAMANHO_BYTES" 2>>"$LOG_FILE" \
            | gzip -c > "$TAR_TEMP"
    ) | dialog --no-shadow --gauge "$label_step1" $dialog_height $dialog_width
}

# Etapas seguintes com steps-multi-label (sempre pares "label" "comando")
show_progress_dialog steps-multi-label 8 \
    "Iniciando backup do Debian (AnDistro)..." "echo \"[2/8] Iniciando backup\" >> \"$LOG_FILE\"; sleep 1" \
    "Preparando para criptografar backup..." "echo \"[3/8] Preparando GPG\" >> \"$LOG_FILE\"; sleep 1" \
    "Compactação concluída, iniciando criptografia..." "echo \"[4/8] Compactação concluída, iniciando GPG\" >> \"$LOG_FILE\"; sleep 1" \
    "Criptografando backup com GPG (AES256)..." "echo \"[5/8] Criptografando com GPG\" >> \"$LOG_FILE\"; gpg --batch --yes --passphrase-file \"$SENHA_FILE\" --symmetric --cipher-algo AES256 --output \"$ARQ\" \"$TAR_TEMP\" 2>>\"$LOG_FILE\"" \
    "Verificando arquivo gerado..." "echo \"[6/8] Verificando arquivo $ARQ\" >> \"$LOG_FILE\"; if [ -f \"$ARQ\" ]; then echo \"OK: $ARQ\" >> \"$LOG_FILE\"; else echo \"ERRO: arquivo não encontrado\" >> \"$LOG_FILE\"; fi" \
    "Limpando temporários..." "echo \"[7/8] Limpando temporários\" >> \"$LOG_FILE\"; rm -f \"$TAR_TEMP\" \"$SENHA_FILE\"" \
    "Registrando localização do backup..." "echo \"[8/8] Backup gerado em: $ARQ\" >> \"$LOG_FILE\"; sleep 1"

# Resultado final
if [ -f "$ARQ" ]; then
    dialog --no-shadow --msgbox "✅ Backup concluído!\n\nArquivo: $ARQ\nTamanho: $(du -sh "$ARQ" | cut -f1)\n\nLog: $LOG_FILE" $dialog_height $dialog_width
    return 0
else
    dialog --no-shadow --msgbox "❌ Erro ao criar backup.\nVeja o log:\n$LOG_FILE" $dialog_height $dialog_width
    return 1
fi
