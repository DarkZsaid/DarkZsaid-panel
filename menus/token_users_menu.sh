#!/bin/bash

TOKEN_DIR="/etc/darkzsaid"
TOKEN_DB="$TOKEN_DIR/token_users.db"
TOKEN_PASS_FILE="$TOKEN_DIR/token_global.pass"
SSH_DB="/opt/darkzsaid/data/usuarios_ssh.db"
TOKENS_SSH_DB="/opt/darkzsaid/data/tokens_ssh.db"

ROJO="\033[1;31m"
VERDE="\033[1;32m"
AZUL="\033[1;34m"
CYAN="\033[1;36m"
BLANCO="\033[1;37m"
RESET="\033[0m"

ok(){ echo -e "${VERDE}✓ $1${RESET}"; }
fail(){ echo -e "${ROJO}✗ $1${RESET}"; }
pausa(){ echo; read -rp "Presiona ENTER para continuar..."; }

preparar_base(){
    mkdir -p "$TOKEN_DIR"
    [ -f "$TOKEN_PASS_FILE" ] || echo "steven2002" > "$TOKEN_PASS_FILE"
    touch "$TOKEN_DB"
    chmod 600 "$TOKEN_PASS_FILE" "$TOKEN_DB" 2>/dev/null || true
}

crear_cuenta_token(){
    preparar_base
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET}        ${BLANCO}⚡ CREAR CUENTA TOKEN ⚡${RESET}       ${CYAN}║${RESET}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${RESET}"
    echo

    read -rp "Nombre: " nombre
    read -rp "Token: " token
    read -rp "Días: " dias

    nombre="$(echo "$nombre" | tr -d '|')"
    token="$(echo "$token" | tr -d '| ' | tr -cd 'a-zA-Z0-9_.-')"
    dias="$(echo "$dias" | tr -dc '0-9')"

    if [ -z "$nombre" ] || [ -z "$token" ] || [ -z "$dias" ]; then
        fail "Datos incompletos"
        pausa
        exit 1
    fi

    pass="$(cat "$TOKEN_PASS_FILE" 2>/dev/null)"
    creado="$(date '+%Y-%m-%d %H:%M:%S')"
    expira="$(date -d "+$dias days" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "N/A")"
    expira_linux="$(date -d "+$dias days" '+%Y-%m-%d' 2>/dev/null || echo "")"

    # El TOKEN es el usuario real de conexión para la app.
    if ! id "$token" >/dev/null 2>&1; then
        useradd -M -s /bin/bash "$token" 2>/dev/null || true
    fi

    echo "${token}:${pass}" | chpasswd 2>/dev/null || true
    usermod -s /bin/bash "$token" 2>/dev/null || true

    if [ -n "$expira_linux" ]; then
        chage -E "$expira_linux" "$token" 2>/dev/null || true
    fi

    grep -v "^${token}|" "$TOKEN_DB" > "$TOKEN_DB.tmp" 2>/dev/null || true
    mv "$TOKEN_DB.tmp" "$TOKEN_DB" 2>/dev/null || true
    echo "${token}|${nombre}|${pass}|${dias}|${creado}|${expira}|ACTIVO" >> "$TOKEN_DB"
    chmod 600 "$TOKEN_DB" 2>/dev/null || true


    # Registrar también en la base principal SSH para que salga en CLIENTES DARKZSAID SSH
    mkdir -p /opt/darkzsaid/data
    touch "$SSH_DB" "$TOKENS_SSH_DB"
    chmod 600 "$SSH_DB" "$TOKENS_SSH_DB" 2>/dev/null || true

    # Limpiar registro anterior del mismo token si existe
    grep -v "^${token}|" "$SSH_DB" > "$SSH_DB.tmp" 2>/dev/null || true
    mv "$SSH_DB.tmp" "$SSH_DB" 2>/dev/null || true

    # Formato compatible con la lista actual:
    # usuario|clave|NORMAL|dias|fecha_expira
    echo "${token}|${pass}|NORMAL|${dias}|$(date -d "+$dias days" '+%Y-%m-%d' 2>/dev/null || echo "$expira")" >> "$SSH_DB"

    # Base secundaria de tokens SSH, por si el panel la usa después
    grep -v "^${token}|" "$TOKENS_SSH_DB" > "$TOKENS_SSH_DB.tmp" 2>/dev/null || true
    mv "$TOKENS_SSH_DB.tmp" "$TOKENS_SSH_DB" 2>/dev/null || true
    echo "${token}|${pass}|NORMAL|${dias}|$(date -d "+$dias days" '+%Y-%m-%d' 2>/dev/null || echo "$expira")" >> "$TOKENS_SSH_DB"

    echo
    ok "Cuenta token creada"
    echo
    echo -e "${AZUL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BLANCO}Nombre:${RESET} $nombre"
    echo -e "${BLANCO}Token / usuario app:${RESET} $token"
    echo -e "${BLANCO}Contraseña token:${RESET} $pass"
    echo -e "${BLANCO}Días:${RESET} $dias"
    echo -e "${BLANCO}Expira:${RESET} $expira"
    echo -e "${BLANCO}Formato app:${RESET} ${token}:${pass}"
    echo -e "${AZUL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    pausa
}

cambiar_password_token(){
    preparar_base
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET}       ${BLANCO}⚡ CONTRASEÑA TOKEN ⚡${RESET}          ${CYAN}║${RESET}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${RESET}"
    echo

    echo -e "${BLANCO}Actual:${RESET} $(cat "$TOKEN_PASS_FILE" 2>/dev/null)"
    echo
    read -rp "Nueva contraseña token global: " nueva

    if [ -z "$nueva" ]; then
        fail "Contraseña vacía"
        pausa
        exit 1
    fi

    echo "$nueva" > "$TOKEN_PASS_FILE"
    chmod 600 "$TOKEN_PASS_FILE" 2>/dev/null || true

    if [ -s "$TOKEN_DB" ]; then
        cut -d'|' -f1 "$TOKEN_DB" | while read -r token; do
            if [ -n "$token" ] && id "$token" >/dev/null 2>&1; then
                echo "${token}:${nueva}" | chpasswd 2>/dev/null || true
            fi
        done
    fi


    # Actualizar contraseña global también en bases visibles SSH
    for DBSYNC in "$SSH_DB" "$TOKENS_SSH_DB"; do
        [ -f "$DBSYNC" ] || continue
        TMP="${DBSYNC}.tmp"
        : > "$TMP"
        while IFS='|' read -r u oldpass tipo dias fecha resto; do
            [ -z "$u" ] && continue
            if grep -q "^${u}|" "$TOKEN_DB" 2>/dev/null; then
                echo "${u}|${nueva}|${tipo:-NORMAL}|${dias:-1}|${fecha}" >> "$TMP"
            else
                echo "${u}|${oldpass}|${tipo}|${dias}|${fecha}${resto:+|$resto}" >> "$TMP"
            fi
        done < "$DBSYNC"
        mv "$TMP" "$DBSYNC"
    done

    ok "Contraseña token global guardada"
    echo
    echo -e "${BLANCO}Nueva contraseña:${RESET} $nueva"
    pausa
}

case "$1" in
    crear) crear_cuenta_token ;;
    pass) cambiar_password_token ;;
    *) echo "Uso: $0 crear | pass" ;;
esac
