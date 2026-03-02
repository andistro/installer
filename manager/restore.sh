#!/data/data/com.termux/files/usr/bin/bash
# chmod +x "$PREFIX/var/lib/andistro/manager/restore.sh" && bash "$PREFIX/var/lib/andistro/manager/restore.sh"
#rm -rf $PREFIX/var/lib/andistro/manager/debian/stable
#!/data/data/com.termux/files/usr/bin/bash
# chmod +x "$PREFIX/var/lib/andistro/manager/restore.sh" && bash "$PREFIX/var/lib/andistro/manager/restore.sh"
clear

source "$PREFIX/var/lib/andistro/lib/share/global"

title_progress="Progresso"

DEBIAN_DIR="$PREFIX/var/lib/andistro/manager/debian/stable"
BACKUP_BASE="/sdcard/termux/andistro"
BACKUP_DIR="$BACKUP_BASE/backups"
LOG_DIR="$BACKUP_BASE/logs"
TMPDIR_DEFAULT="$BACKUP_BASE/tmp"

mkdir -p "$BACKUP_DIR" "$LOG_DIR" "$TMPDIR_DEFAULT"

TIMESTAMP_RUN=$(date +'%d%m%Y-%H%M%S')
SCRIPT_NAME=$(basename "$0"); SCRIPT_NAME="${SCRIPT_NAME%%.*}"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_${TIMESTAMP_RUN}.txt"

ARCH_CURRENT="$android_architecture"
ARCH_CURRENT_CLEAN=$(echo "$ARCH_CURRENT" | tr ' ' '_' | tr '/' '_')

DATE_FMT=$(settings get system date_format 2>/dev/null)
if [ -z "$DATE_FMT" ] || [[ "$DATE_FMT" == *"Failure"* ]]; then
    case "$system_icu_locale_code" in
        en_US*) DATE_FMT="%m/%d/%Y %H:%M" ;;
        *)      DATE_FMT="%d/%m/%Y %H:%M" ;;
    esac
else
    case "$DATE_FMT" in
        dd/MM/yyyy) DATE_FMT="%d/%m/%Y %H:%M" ;;
        MM/dd/yyyy) DATE_FMT="%m/%d/%Y %H:%M" ;;
        yyyy-MM-dd) DATE_FMT="%Y-%m-%d %H:%M" ;;
        *)          DATE_FMT="%d/%m/%Y %H:%M" ;;
    esac
fi

if ! command -v sha256sum >/dev/null 2>&1; then
    pkg install -y coreutils >/dev/null 2>&1
fi

declare -a DIALOG_OPTS=()
idx=0

# Lista do mais recente para o mais antigo
for f in $(ls -t "$BACKUP_DIR"/"[ANDISTRO]__Debian_"*.tar.gz.gpg 2>/dev/null); do
    [ -e "$f" ] || continue

    base=$(basename "$f")
    echo "Analisando: $base" >> "$LOG_FILE"

    core="${base#\[ANDISTRO\]__Debian_}"
    core="${core%.tar.gz.gpg}"

    # core = CODENAME_LANG__-__MANUF_MODEL_ARCH__-__SHA__-__TS
    parts=$(printf '%s\n' "$core" | sed 's/__-__/|/g')

    CODENAME_LANG=$(printf '%s\n' "$parts" | cut -d'|' -f1)
    MANUF_MODEL_ARCH=$(printf '%s\n' "$parts" | cut -d'|' -f2)
    FILE_SHA_IN_NAME=$(printf '%s\n' "$parts" | cut -d'|' -f3)
    TS_RAW=$(printf '%s\n' "$parts" | cut -d'|' -f4)

    if [ -z "$CODENAME_LANG" ] || [ -z "$MANUF_MODEL_ARCH" ] || \
       [ -z "$FILE_SHA_IN_NAME" ] || [ -z "$TS_RAW" ]; then
        echo "Formato inválido: $base" >> "$LOG_FILE"
        continue
    fi

    CODENAME=$(printf '%s\n' "$CODENAME_LANG" | cut -d'_' -f1)
    LANG_CODE=$(printf '%s\n' "$CODENAME_LANG" | cut -d'_' -f2-)

    MANUF=$(printf '%s\n' "$MANUF_MODEL_ARCH" | cut -d'_' -f1)
    MODEL=$(printf '%s\n' "$MANUF_MODEL_ARCH" | cut -d'_' -f2)
    ARCH=$(printf '%s\n' "$MANUF_MODEL_ARCH" | cut -d'_' -f3-)

    echo "  CODENAME=$CODENAME LANG=$LANG_CODE MANUF=$MANUF MODEL=$MODEL ARCH=$ARCH" >> "$LOG_FILE"

    if [ "$ARCH" != "$ARCH_CURRENT_CLEAN" ]; then
        echo "Ignorando $base (arch $ARCH != $ARCH_CURRENT_CLEAN)" >> "$LOG_FILE"
        continue
    fi

    FILE_SHA_CALC=$(sha256sum "$f" | awk '{print $1}')
    if [ "$FILE_SHA_CALC" != "$FILE_SHA_IN_NAME" ]; then
        echo "Checksum inválido para $base (esperado $FILE_SHA_IN_NAME, calculado $FILE_SHA_CALC)" >> "$LOG_FILE"
        continue
    fi

    DAY=${TS_RAW:0:2}
    MON=${TS_RAW:2:2}
    YEA=${TS_RAW:4:4}
    HOU=${TS_RAW:9:2}
    MIN=${TS_RAW:11:2}
    SEC=${TS_RAW:13:2}

    TS_ISO="$YEA-$MON-$DAY $HOU:$MIN:$SEC"
    TS_FMT=$(date -d "$TS_ISO" +"$DATE_FMT" 2>/dev/null || echo "$TS_ISO")

    LABEL="Debian ${CODENAME} / Backup ${TS_FMT} / ${MANUF} ${MODEL}"

    DIALOG_OPTS+=("$idx" "$LABEL" "$f")
    idx=$((idx+1))
done

if [ ${#DIALOG_OPTS[@]} -eq 0 ]; then
    dialog --no-shadow --msgbox "Nenhum backup válido encontrado (checksum ou arquitetura não compatíveis)." $dialog_height $dialog_width
    exit 1
fi

MENU_OPTS=()
i=0
while [ $i -lt ${#DIALOG_OPTS[@]} ]; do
    MENU_OPTS+=("${DIALOG_OPTS[$i]}" "${DIALOG_OPTS[$((i+1))]}")
    i=$((i+3))
done

CHOICE=$(dialog --no-shadow --menu "Selecione o backup para restaurar:\n(Apenas arquivos com checksum válido e mesma arquitetura)" \
                $dialog_height $dialog_width $dialog_choice_height \
                "${MENU_OPTS[@]}" 3>&1 1>&2 2>&3)

[ $? -ne 0 ] && exit 1

SELECTED_FILE=""
i=0
while [ $i -lt ${#DIALOG_OPTS[@]} ]; do
    if [ "${DIALOG_OPTS[$i]}" = "$CHOICE" ]; then
        SELECTED_FILE="${DIALOG_OPTS[$((i+2))]}"
        break
    fi
    i=$((i+3))
done

if [ -z "$SELECTED_FILE" ]; then
    dialog --no-shadow --msgbox "Erro interno ao localizar o arquivo selecionado." $dialog_height $dialog_width
    exit 1
fi

SENHA=$(dialog --no-shadow --insecure --cancel-label "Exibir" \
               --passwordbox "Digite a senha para restaurar o backup selecionado:" \
               $dialog_height $dialog_width 3>&1 1>&2 2>&3)
ret=$?

if [ $ret -eq 1 ]; then
    SENHA=$(dialog --no-shadow --cancel-label "Ocultar" \
                   --inputbox "Senha (VISÍVEL) para restaurar o backup:" \
                   $dialog_height $dialog_width 3>&1 1>&2 2>&3)
fi

if [ -z "$SENHA" ]; then
    dialog --no-shadow --msgbox "Senha vazia. Restauração cancelada." $dialog_height $dialog_width
    exit 1
fi

# 1/2 – preparar
echo "[1/2] Preparando restauração" >> "$LOG_FILE"
show_progress_dialog steps-multi-label 1 "Preparando restauração..." "sleep 1"

# 2/2 – descriptografar e extrair em pipeline (igual ao teste manual)
echo "[2/2] Descriptografando e extraindo $SELECTED_FILE" >> "$LOG_FILE"

rm -rf "$DEBIAN_DIR"
mkdir -p "$DEBIAN_DIR"

GPG_TAR_ERROR=$(echo "$SENHA" | gpg --batch --yes --passphrase-fd 0 \
                                    --decrypt "$SELECTED_FILE" 2>>"$LOG_FILE" | \
                                    tar -xzf - -C "$DEBIAN_DIR" 2>&1)
status_pipeline=$?

echo "$GPG_TAR_ERROR" >> "$LOG_FILE"

if [ $status_pipeline -ne 0 ]; then
    if printf '%s\n' "$GPG_TAR_ERROR" | grep -qi "Bad session key"; then
        MSG="Falha na restauração.\n\nSenha incorreta para o backup selecionado."
    elif printf '%s\n' "$GPG_TAR_ERROR" | grep -qi "decryption failed"; then
        MSG="Falha na restauração.\n\nErro ao descriptografar o backup (senha incorreta ou arquivo corrompido)."
    elif printf '%s\n' "$GPG_TAR_ERROR" | grep -qi "not in gzip format"; then
        MSG="Falha na restauração.\n\nErro ao extrair o backup: conteúdo não está em formato .tar.gz.\n\nDetalhe:\n$GPG_TAR_ERROR"
    else
        MSG="Falha na restauração.\n\nErro ao restaurar o backup:\n$GPG_TAR_ERROR"
    fi
    rm -rf "$DEBIAN_DIR"
    dialog --no-shadow --msgbox "$MSG" $dialog_height $dialog_width
    exit 1
fi

# Sentinel / sucesso
if [ -d "$DEBIAN_DIR" ] && [ -f "$DEBIAN_DIR/etc/os-release" ]; then
    dialog --no-shadow --msgbox "Restauração concluída com sucesso." $dialog_height $dialog_width
    cp "$PREFIX/var/lib/andistro/manager/.config/debian-based/start-distro" $PREFIX/var/lib/andistro/manager/start-debian
    sed -i "s|command+=\" LANG=\$system_icu_lang_code_env.UTF-8\"|command+=\" LANG=$system_icu_lang_code_env.UTF-8\"|g" $PREFIX/var/lib/andistro/manager/start-debian
    chmod +x $PREFIX/var/lib/andistro/manager/start-debian
    exit 0
else
    dialog --no-shadow --msgbox "Erro ao restaurar o backup (conteúdo incompleto ou inválido)." $dialog_height $dialog_width
    exit 1
fi
