#!/bin/bash

pantalla_limpia() {
    printf '\033c'
}


limpiar_pantalla() {
    printf '\033[H\033[2J\033[3J'
}


CONFIG="/etc/udpmod/config.json"
DB="/opt/darkzsaid/data/usuarios_udpmod.db"

mkdir -p /opt/darkzsaid/data
touch "$DB"

ROJO="\e[31m"
VERDE="\e[32m"
AMARILLO="\e[33m"
AZUL="\e[34m"
CYAN="\e[36m"
BLANCO="\e[97m"
RESET="\e[0m"
BOLD="\e[1m"

pausa() {
    echo ""
    read -r -p "Presiona ENTER para continuar..."
}

linea() {
    echo -e "${CYAN}════════════════════════════════════════════${RESET}"
}

titulo() {
    limpiar_pantalla
    echo -e "${CYAN}╔════════════════════════════════════════════╗${RESET}"
    printf "${CYAN}║${RESET} ${BLANCO}${BOLD}%-42s${RESET} ${CYAN}║${RESET}\n" "$1"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${RESET}"
    echo ""
}

get_ip() {
    curl -4 -s https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}'
}

get_json_value() {
    local key="$1"
    python3 <<PY 2>/dev/null
import json
path="$CONFIG"
key="$key"
try:
    with open(path) as f:
        cfg=json.load(f)
    print(cfg.get(key,""))
except Exception:
    print("")
PY
}

sync_udp_config() {
python3 <<PY
import json, os

config = "$CONFIG"
db = "$DB"

if not os.path.exists(config):
    print("No existe", config)
    raise SystemExit(1)

usuarios = []

if os.path.exists(db):
    with open(db, "r", errors="ignore") as f:
        for line in f:
            line = line.strip()
            if not line or "|" not in line:
                continue
            partes = line.split("|")
            if len(partes) >= 2:
                user = partes[0].strip()
                passwd = partes[1].strip()
                if user and passwd:
                    usuarios.append(f"{user}:{passwd}")

with open(config, "r") as f:
    cfg = json.load(f)

cfg.setdefault("auth", {})
cfg["auth"]["mode"] = "passwords"
cfg["auth"]["config"] = usuarios
cfg["obfs"] = cfg.get("obfs") or "DarkZsaid"

with open(config, "w") as f:
    json.dump(cfg, f, indent=2)

print("UDPMod sincronizado con", len(usuarios), "usuario(s).")
PY

systemctl restart udpmod 2>/dev/null || true
}

mostrar_tarjeta_usuario() {
    local usuario="$1"
    local clave="$2"
    local expira="$3"

    IP_PUBLICA=$(get_ip)
    OBFS=$(get_json_value "obfs")
    UP=$(get_json_value "up_mbps")
    DOWN=$(get_json_value "down_mbps")

    [[ -z "$OBFS" ]] && OBFS="DarkZsaid"
    [[ -z "$UP" ]] && UP="17"
    [[ -z "$DOWN" ]] && DOWN="15"

    limpiar_pantalla
    echo -e "${VERDE}╔════════════════════════════════════════════╗${RESET}"
    echo -e "${VERDE}║${RESET} ${BLANCO}${BOLD}      USUARIO UDP-HYSTERIA CREADO       ${RESET}${VERDE}║${RESET}"
    echo -e "${VERDE}╚════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${CYAN}┌────────────────────────────────────────────┐${RESET}"
    echo -e "${CYAN}│${RESET} ${AMARILLO}👤 Usuario      :${RESET} ${BLANCO}$usuario${RESET}"
    echo -e "${CYAN}│${RESET} ${AMARILLO}🔑 Contraseña  :${RESET} ${BLANCO}$clave${RESET}"
    echo -e "${CYAN}│${RESET} ${AMARILLO}📅 Expira      :${RESET} ${BLANCO}$expira${RESET}"
    echo -e "${CYAN}│${RESET} ${AMARILLO}🌐 IP VPS      :${RESET} ${BLANCO}$IP_PUBLICA${RESET}"
    echo -e "${CYAN}│${RESET} ${AMARILLO}📡 Puerto      :${RESET} ${BLANCO}36712${RESET}"
    echo -e "${CYAN}│${RESET} ${AMARILLO}🛡️ OBFS        :${RESET} ${BLANCO}$OBFS${RESET}"
    echo -e "${CYAN}│${RESET} ${AMARILLO}⬆️ UP Mbps     :${RESET} ${BLANCO}$UP${RESET}"
    echo -e "${CYAN}│${RESET} ${AMARILLO}⬇️ DOWN Mbps   :${RESET} ${BLANCO}$DOWN${RESET}"
    echo -e "${CYAN}└────────────────────────────────────────────┘${RESET}"
    echo ""
    echo -e "${VERDE}✅ Usuario guardado en base UDPMod.${RESET}"
    echo -e "${VERDE}✅ Configuración sincronizada.${RESET}"
    echo -e "${VERDE}✅ Servicio UDPMod reiniciado.${RESET}"
    echo ""
    echo -e "${AMARILLO}Datos para la app:${RESET}"
    echo ""
    echo -e "${BLANCO}IP: $IP_PUBLICA${RESET}"
    echo -e "${BLANCO}Puerto: 36712${RESET}"
    echo -e "${BLANCO}Usuario: $usuario${RESET}"
    echo -e "${BLANCO}Contraseña: $clave${RESET}"
    echo -e "${BLANCO}OBFS: $OBFS${RESET}"
    echo ""
    pausa
}

crear_usuario_udp() {
    titulo "CREAR USUARIO UDPMod / HYSTERIA"

    echo -e "${AMARILLO}Complete los datos del usuario UDP:${RESET}"
    echo ""
    read -r -p "Usuario UDP: " usuario
    read -r -p "Contraseña UDP: " clave
    read -r -p "Días de duración: " dias

    if [[ -z "$usuario" || -z "$clave" || -z "$dias" ]]; then
        echo ""
        echo -e "${ROJO}Datos incompletos.${RESET}"
        pausa
        return
    fi

    if ! [[ "$dias" =~ ^[0-9]+$ ]]; then
        echo ""
        echo -e "${ROJO}Los días deben ser número.${RESET}"
        pausa
        return
    fi

    expira=$(date -d "+$dias days" +%Y-%m-%d 2>/dev/null)

    if [[ -z "$expira" ]]; then
        echo ""
        echo -e "${ROJO}No se pudo calcular fecha de expiración.${RESET}"
        pausa
        return
    fi

    grep -v "^${usuario}|" "$DB" > "$DB.tmp" 2>/dev/null || true
    mv "$DB.tmp" "$DB"

    echo "${usuario}|${clave}|${expira}" >> "$DB"

    echo ""
    echo -e "${CYAN}Sincronizando usuario con UDPMod...${RESET}"
    sleep 1
    sync_udp_config

    mostrar_tarjeta_usuario "$usuario" "$clave" "$expira"
}

listar_usuarios_udp() {
    titulo "USUARIOS UDPMod / HYSTERIA"

    TOKEN_DB="/opt/darkzsaid/data/tokens_zivpn.db"
    TOKEN_PASS_FILE="/opt/darkzsaid/data/token_global.pass"
    TOKEN_PASS=$(cat "$TOKEN_PASS_FILE" 2>/dev/null)

    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET}        ${BLANCO}${BOLD}LISTA PREMIUM DE USUARIOS UDP / TOKEN${RESET}        ${CYAN}║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    if [[ ! -s "$DB" ]]; then
        echo -e "${AMARILLO}No hay usuarios UDPMod guardados.${RESET}"
        echo ""
        pausa
        return
    fi

    echo -e "${CYAN}┌─────┬────────────────────┬────────────────────────┬───────────────┐${RESET}"
    printf "${CYAN}│${RESET} %-3s ${CYAN}│${RESET} %-18s ${CYAN}│${RESET} %-22s ${CYAN}│${RESET} %-13s ${CYAN}│${RESET}\n" "N°" "USUARIO" "TOKEN / CLAVE" "EXPIRA"
    echo -e "${CYAN}├─────┼────────────────────┼────────────────────────┼───────────────┤${RESET}"

    n=1

    while IFS='|' read -r user pass exp extra; do
        [[ -z "$user" ]] && continue

        mostrar_user="$user"
        mostrar_token="$pass"

        # Si este registro es TOKEN, buscar el nombre real del cliente en tokens_zivpn.db
        if [[ -s "$TOKEN_DB" ]]; then
            linea_token=$(grep -m1 "^${user}|" "$TOKEN_DB" 2>/dev/null || true)
            if [[ -n "$linea_token" ]]; then
                IFS='|' read -r token_db nombre_db exp_db tipo_db <<< "$linea_token"
                if [[ -n "$nombre_db" ]]; then
                    mostrar_user="$nombre_db"
                    mostrar_token="$token_db"
                    [[ -n "$exp_db" ]] && exp="$exp_db"
                fi
            fi
        fi

        # Si por alguna razón queda la contraseña global, no mostrarla
        if [[ -n "$TOKEN_PASS" && "$mostrar_token" == "$TOKEN_PASS" ]]; then
            mostrar_token="TOKEN PRIVADO"
        fi

        printf "${CYAN}│${RESET} %-3s ${CYAN}│${RESET} %-18s ${CYAN}│${RESET} %-22s ${CYAN}│${RESET} %-13s ${CYAN}│${RESET}\n" "$n" "$mostrar_user" "$mostrar_token" "$exp"
        n=$((n+1))

    done < "$DB"

    echo -e "${CYAN}└─────┴────────────────────┴────────────────────────┴───────────────┘${RESET}"
    echo ""
    echo -e "${VERDE}${BOLD}✔ Lista cargada correctamente.${RESET}"
    echo -e "${BLANCO}${BOLD}✔ Contraseña global TOKEN oculta por seguridad.${RESET}"
    echo ""
    pausa
}

eliminar_usuario_udp() {
    titulo "ELIMINAR USUARIO UDPMod"

    TOKEN_DB="/opt/darkzsaid/data/tokens_zivpn.db"
    SSH_DB="/opt/darkzsaid/data/usuarios_ssh.db"
    USERDIR="/etc/adm-lite/userDIR"

    if [[ ! -s "$DB" ]]; then
        echo -e "${AMARILLO}No hay usuarios UDPMod para eliminar.${RESET}"
        pausa
        return
    fi

    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET}        ${BLANCO}${BOLD}SELECCIONE USUARIO / TOKEN A ELIMINAR${RESET}       ${CYAN}║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    echo -e "${CYAN}┌─────┬────────────────────┬────────────────────────┬───────────────┐${RESET}"
    printf "${CYAN}│${RESET} %-3s ${CYAN}│${RESET} %-18s ${CYAN}│${RESET} %-22s ${CYAN}│${RESET} %-13s ${CYAN}│${RESET}\n" "N°" "USUARIO" "TOKEN / CLAVE" "EXPIRA"
    echo -e "${CYAN}├─────┼────────────────────┼────────────────────────┼───────────────┤${RESET}"

    TMP_LIST="/tmp/darkzsaid_udp_delete_list.txt"
    : > "$TMP_LIST"

    n=1
    while IFS='|' read -r user pass exp extra; do
        [[ -z "$user" ]] && continue

        mostrar_user="$user"
        mostrar_token="$pass"

        if [[ -s "$TOKEN_DB" ]]; then
            linea_token=$(grep -m1 "^${user}|" "$TOKEN_DB" 2>/dev/null || true)
            if [[ -n "$linea_token" ]]; then
                IFS='|' read -r token_db nombre_db exp_db tipo_db <<< "$linea_token"
                [[ -n "$nombre_db" ]] && mostrar_user="$nombre_db"
                [[ -n "$token_db" ]] && mostrar_token="$token_db"
                [[ -n "$exp_db" ]] && exp="$exp_db"
            fi
        fi

        printf "${CYAN}│${RESET} %-3s ${CYAN}│${RESET} %-18s ${CYAN}│${RESET} %-22s ${CYAN}│${RESET} %-13s ${CYAN}│${RESET}\n" "$n" "$mostrar_user" "$mostrar_token" "$exp"
        echo "${n}|${user}|${mostrar_user}|${mostrar_token}|${exp}" >> "$TMP_LIST"

        n=$((n+1))
    done < "$DB"

    echo -e "${CYAN}└─────┴────────────────────┴────────────────────────┴───────────────┘${RESET}"
    echo ""

    read -r -p "Número, usuario o TOKEN a eliminar: " entrada

    if [[ -z "$entrada" ]]; then
        echo -e "${ROJO}Entrada vacía.${RESET}"
        pausa
        return
    fi

    eliminar=""

    if [[ "$entrada" =~ ^[0-9]+$ ]]; then
        eliminar=$(awk -F'|' -v n="$entrada" '$1==n {print $2; exit}' "$TMP_LIST")
    else
        eliminar=$(awk -F'|' -v e="$entrada" '$2==e || $3==e || $4==e {print $2; exit}' "$TMP_LIST")
    fi

    if [[ -z "$eliminar" ]]; then
        echo ""
        echo -e "${ROJO}No encontré ese usuario/token.${RESET}"
        pausa
        return
    fi

    echo ""
    echo -e "${AMARILLO}Eliminando:${RESET} ${BLANCO}$eliminar${RESET}"

    # Quitar de base UDPMod
    grep -v "^${eliminar}|" "$DB" > "$DB.tmp" 2>/dev/null || true
    mv "$DB.tmp" "$DB" 2>/dev/null || true

    # Quitar de base tokens
    grep -v "^${eliminar}|" "$TOKEN_DB" > "$TOKEN_DB.tmp" 2>/dev/null || true
    mv "$TOKEN_DB.tmp" "$TOKEN_DB" 2>/dev/null || true

    # Quitar de base principal
    grep -v "^${eliminar}|" "$SSH_DB" > "$SSH_DB.tmp" 2>/dev/null || true
    mv "$SSH_DB.tmp" "$SSH_DB" 2>/dev/null || true

    # Quitar userDIR
    rm -f "$USERDIR/$eliminar" 2>/dev/null || true

    # Eliminar usuario Linux si existe
    if id "$eliminar" >/dev/null 2>&1; then
        userdel "$eliminar" 2>/dev/null || true
    fi

    echo ""
    echo -e "${CYAN}Sincronizando cambios con UDPMod...${RESET}"
    sync_udp_config
    systemctl restart udpmod 2>/dev/null || true

    echo ""
    echo -e "${VERDE}${BOLD}✔ Usuario/TOKEN eliminado correctamente.${RESET}"
    echo -e "${BLANCO}Eliminado:${RESET} ${AMARILLO}$eliminar${RESET}"
    echo ""
    pausa
}

estado_udpmod_premium() {
    titulo "ESTADO UDPMod / HYSTERIA"

    if systemctl is-active --quiet udpmod 2>/dev/null; then
        echo -e "${VERDE}✅ Servicio UDPMod: ACTIVO${RESET}"
    else
        echo -e "${ROJO}❌ Servicio UDPMod: APAGADO${RESET}"
    fi

    if ss -ulnp | grep -q ':36712'; then
        echo -e "${VERDE}✅ Puerto 36712: ESCUCHANDO${RESET}"
    else
        echo -e "${ROJO}❌ Puerto 36712: NO ESCUCHA${RESET}"
    fi

    echo ""
    echo -e "${AMARILLO}Configuración:${RESET}"
    echo -e "OBFS      : $(get_json_value obfs)"
    echo -e "UP Mbps   : $(get_json_value up_mbps)"
    echo -e "DOWN Mbps : $(get_json_value down_mbps)"
    echo ""

    echo -e "${AMARILLO}Usuarios cargados en UDPMod:${RESET}"
    grep -A20 '"auth"' "$CONFIG" 2>/dev/null || echo "No se pudo leer config.json"
    pausa
}


crear_token_app() {
    titulo "CREAR TOKEN"

    mkdir -p /opt/darkzsaid/data /etc/adm-lite/userDIR

    TOKEN_PASS_FILE="/opt/darkzsaid/data/token_global.pass"
    TOKEN_DB="/opt/darkzsaid/data/tokens_zivpn.db"
    SSH_DB="/opt/darkzsaid/data/usuarios_ssh.db"
    USERDIR="/etc/adm-lite/userDIR"

    if [[ ! -f "$TOKEN_PASS_FILE" ]]; then
        echo "Steve2012" > "$TOKEN_PASS_FILE"
        chmod 600 "$TOKEN_PASS_FILE" 2>/dev/null || true
    fi

    TOKEN_PASS=$(cat "$TOKEN_PASS_FILE" 2>/dev/null)
    [[ -z "$TOKEN_PASS" ]] && TOKEN_PASS="Steve2012"

    echo -e "${AMARILLO}Crear TOKEN para la app:${RESET}"
    echo ""
    echo -e "${BLANCO}${BOLD}La contraseña global TOKEN queda interna y no se mostrará.${RESET}"
    echo ""

    read -r -p "Nombre de usuario: " nombre_usuario
    read -r -p "TOKEN/HWID: " token
    read -r -p "Días de duración: " dias

    if [[ -z "$nombre_usuario" || -z "$token" || -z "$dias" ]]; then
        echo ""
        echo -e "${ROJO}Datos incompletos.${RESET}"
        pausa
        return
    fi

    if ! [[ "$dias" =~ ^[0-9]+$ ]]; then
        echo ""
        echo -e "${ROJO}Los días deben ser número.${RESET}"
        pausa
        return
    fi

    if ! [[ "$token" =~ ^[A-Za-z0-9._-]+$ ]]; then
        echo ""
        echo -e "${ROJO}Token inválido. Usa letras, números, punto, guion o guion bajo.${RESET}"
        pausa
        return
    fi

    if ! [[ "$nombre_usuario" =~ ^[A-Za-z0-9._-]+$ ]]; then
        echo ""
        echo -e "${ROJO}Nombre inválido. Usa letras, números, punto, guion o guion bajo.${RESET}"
        pausa
        return
    fi

    expira=$(date -d "+$dias days" +%Y-%m-%d 2>/dev/null)

    if [[ -z "$expira" ]]; then
        echo ""
        echo -e "${ROJO}No se pudo calcular fecha de expiración.${RESET}"
        pausa
        return
    fi

    # Usuario Linux interno con el TOKEN/HWID
    if ! id "$token" >/dev/null 2>&1; then
        useradd -M -s /bin/false -e "$expira" "$token" 2>/dev/null || true
    fi

    # Contraseña global interna
    HASH=$(openssl passwd -6 "$TOKEN_PASS")
  usermod -p "$HASH" "$token" 2>/dev/null || true
    chage -E "$expira" "$token" 2>/dev/null || true

    # Archivo interno para la app: TOKEN/HWID:contraseña_global
    echo "${token}:${TOKEN_PASS}" > "$USERDIR/$token"
    chmod 600 "$USERDIR/$token" 2>/dev/null || true

    # Base tokens_zivpn.db sin mostrar contraseña como dato principal
    grep -v "^${token}|" "$TOKEN_DB" > "$TOKEN_DB.tmp" 2>/dev/null || true
    mv "$TOKEN_DB.tmp" "$TOKEN_DB" 2>/dev/null || true
    echo "${token}|${nombre_usuario}|${expira}|TOKEN" >> "$TOKEN_DB"

    # Base principal usuarios_ssh.db sin exponer contraseña global
    grep -v "^${token}|" "$SSH_DB" > "$SSH_DB.tmp" 2>/dev/null || true
    mv "$SSH_DB.tmp" "$SSH_DB" 2>/dev/null || true
    echo "${token}|${nombre_usuario}|${expira}|TOKEN" >> "$SSH_DB"

    # Base UDPMod/Hysteria interna para que conecte
    grep -v "^${token}|" "$DB" > "$DB.tmp" 2>/dev/null || true
    mv "$DB.tmp" "$DB" 2>/dev/null || true
    echo "${token}|${TOKEN_PASS}|${expira}" >> "$DB"

    echo ""
    echo -e "${CYAN}Sincronizando TOKEN con UDPMod/Hysteria...${RESET}"
    sync_udp_config
    systemctl restart udpmod 2>/dev/null || true
    sleep 1

    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET}        ${BLANCO}${BOLD}TOKEN CREADO CORRECTAMENTE${RESET}       ${CYAN}║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${AMARILLO}Usuario   :${RESET} ${BLANCO}$nombre_usuario${RESET}"
    echo -e "${AMARILLO}TOKEN/HWID:${RESET} ${BLANCO}$token${RESET}"
    echo -e "${AMARILLO}Caduca    :${RESET} ${BLANCO}$expira${RESET}"
    echo -e "${AMARILLO}Días      :${RESET} ${BLANCO}$dias${RESET}"
    echo ""
    echo -e "${VERDE}${BOLD}✔ TOKEN registrado para la app.${RESET}"
    echo -e "${BLANCO}${BOLD}✔ Contraseña global guardada internamente.${RESET}"
    echo ""
    pausa
}

cambiar_password_token_global() {
    titulo "CAMBIAR CONTRASEÑA GLOBAL TOKEN"

    mkdir -p /opt/darkzsaid/data
    TOKEN_PASS_FILE="/opt/darkzsaid/data/token_global.pass"

    if [[ ! -f "$TOKEN_PASS_FILE" ]]; then
        echo "Steven2022" > "$TOKEN_PASS_FILE"
        chmod 600 "$TOKEN_PASS_FILE" 2>/dev/null || true
    fi

    ACTUAL=$(cat "$TOKEN_PASS_FILE" 2>/dev/null)
    echo -e "${AMARILLO}Contraseña global actual:${RESET} ${VERDE}$ACTUAL${RESET}"
    echo ""

    read -r -p "Nueva contraseña global TOKEN: " nueva

    if [[ -z "$nueva" ]]; then
        echo ""
        echo -e "${ROJO}Contraseña vacía.${RESET}"
        pausa
        return
    fi

    echo "$nueva" > "$TOKEN_PASS_FILE"
    chmod 600 "$TOKEN_PASS_FILE" 2>/dev/null || true

    echo ""
    echo -e "${VERDE}Contraseña global TOKEN actualizada correctamente.${RESET}"
    echo -e "${AMARILLO}Nueva contraseña:${RESET} ${BLANCO}$nueva${RESET}"
    echo ""
    pausa
}

while true; do
    limpiar_pantalla

    TOTAL_UDP=$(grep -c "|" "$DB" 2>/dev/null || echo 0)

    if systemctl is-active --quiet udpmod 2>/dev/null; then
        ESTADO_UDP="${VERDE}ACTIVO${RESET}"
    else
        ESTADO_UDP="${ROJO}APAGADO${RESET}"
    fi

    if ss -ulnp 2>/dev/null | grep -q ":36712"; then
        PUERTO_UDP="${VERDE}36712 ABIERTO${RESET}"
    else
        PUERTO_UDP="${ROJO}36712 CERRADO${RESET}"
    fi

    OBFS_ACTUAL=$(python3 - <<PY2 2>/dev/null
import json
try:
    with open("/etc/udpmod/config.json") as f:
        cfg=json.load(f)
    print(cfg.get("obfs","DarkZsaid"))
except Exception:
    print("DarkZsaid")
PY2
)

    echo -e "${CYAN}╔════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET} ${BLANCO}${BOLD}        UDPMod / HYSTERIA USER CENTER       ${RESET}${CYAN}║${RESET}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${AMARILLO} Servicio UDPMod :${RESET} $ESTADO_UDP"
    echo -e "${AMARILLO} Puerto UDP      :${RESET} $PUERTO_UDP"
    echo -e "${AMARILLO} OBFS actual     :${RESET} ${VERDE}$OBFS_ACTUAL${RESET}"
    echo -e "${AMARILLO} Usuarios UDP    :${RESET} ${BLANCO}$TOTAL_UDP${RESET}"
    echo ""
    echo -e "${CYAN}┌──────────────────────────────────────────────────┐${RESET}"
    echo -e "${CYAN}│${RESET} ${ROJO}[1]${RESET} ${BLANCO}Crear usuario UDP-Hysteria${RESET}"
    echo -e "${CYAN}│${RESET} ${ROJO}[2]${RESET} ${BLANCO}Ver usuarios UDP guardados${RESET}"
    echo -e "${CYAN}│${RESET} ${ROJO}[3]${RESET} ${BLANCO}Eliminar usuario UDP${RESET}"
    echo -e "${CYAN}│${RESET} ${ROJO}[4]${RESET} ${BLANCO}Sincronizar base con UDPMod${RESET}"
    echo -e "${CYAN}│${RESET} ${ROJO}[5]${RESET} ${BLANCO}Estado premium del servicio${RESET}"
    echo -e "${CYAN}│${RESET} ${ROJO}[6]${RESET} ${BLANCO}Crear usuario UDP-Hysteria${RESET}"
    echo -e "${CYAN}│${RESET} ${ROJO}[7]${RESET} ${BLANCO}Cambiar contraseña global TOKEN${RESET}"
    echo -e "${CYAN}│${RESET} ${ROJO}[6]${RESET} ${BLANCO}Crear TOKEN${RESET}"
    echo -e "${CYAN}│${RESET} ${ROJO}[7]${RESET} ${BLANCO}Cambiar contraseña global TOKEN${RESET}"
    echo -e "${CYAN}│${RESET} ${ROJO}[0]${RESET} ${AMARILLO}Volver al menú anterior${RESET}"
    echo -e "${CYAN}└──────────────────────────────────────────────────┘${RESET}"
    echo ""
    read -r -p "⚡ Seleccione una opción: " op

    case "$op" in
        1|01) crear_usuario_udp ;;
        2|02) listar_usuarios_udp ;;
        3|03) eliminar_usuario_udp ;;
        4|04) titulo "SINCRONIZAR UDPMod"; sync_udp_config; pausa ;;
        5|05) estado_udpmod_premium ;;
        6|06) crear_token_app ;;
        7|07) cambiar_password_token_global ;;
        0|00) exit 0 ;;
        *) echo "Opción inválida."; sleep 1 ;;
    esac
done
