#!/bin/bash

limpiar_pantalla() {
    printf '\033[H\033[2J\033[3J'
}

source /opt/darkzsaid/menus/ui_instalacion.sh 2>/dev/null || true
[[ -f /opt/darkzsaid/lib/ui.sh ]] && source /opt/darkzsaid/lib/ui.sh

ZIVPN_SERVICE="zivpn"
ZIVPN_CONFIG="/etc/zivpn/config.json"
ZIVPN_BIN="/usr/local/bin/zivpn"
ZIVPN_PORT="5667"

titulo_zivpn() {
    limpiar_pantalla
    echo -e "${CYAN}╔════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET}              ${BLANCO}⚡ ZIVPN ⚡${RESET}                 ${CYAN}║${RESET}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${AMARILLO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "              ${VERDE}$1${RESET}"
    echo -e "${AMARILLO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
}

estado_zivpn() {
    if systemctl is-active --quiet zivpn 2>/dev/null; then
        echo -e "${VERDE}[ON]${RESET}"
    else
        echo -e "${ROJO}[OFF]${RESET}"
    fi
}

asegurar_motor_zivpn() {
    mkdir -p /etc/zivpn

    if [[ -x "/usr/local/bin/zivpn" ]]; then
        return 0
    fi

    titulo_zivpn "INSTALANDO MOTOR ZIVPN"
    echo -e "${CYAN}➜ Descargando motor ZiVPN independiente...${RESET}"

    apt-get update -y >/dev/null 2>&1
    apt-get install -y curl openssl iptables libc6-i386 >/dev/null 2>&1

    ARCH="$(uname -m)"

    if [[ "$ARCH" == "x86_64" ]]; then
        BIN_URL="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64"
    elif [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
        BIN_URL="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-arm64"
    else
        error_msg "Arquitectura no soportada: $ARCH"
        pausa_bonita
        return 1
    fi

    if curl -L --fail --retry 3 -o /usr/local/bin/zivpn "$BIN_URL"; then
        chmod +x /usr/local/bin/zivpn
        ok_msg "Motor ZiVPN instalado correctamente."
        return 0
    else
        error_msg "No se pudo descargar el motor ZiVPN."
        pausa_bonita
        return 1
    fi
}

normalizar_config_zivpn() {
    mkdir -p /etc/zivpn

    python3 <<'PY'
import json
from pathlib import Path

p = Path("/etc/zivpn/config.json")

try:
    data = json.loads(p.read_text())
except Exception:
    data = {}

claves = []

for campo in [
    data.get("auth", {}).get("config", []),
    data.get("auth", {}).get("Config", []),
    data.get("config", []),
    data.get("users", [])
]:
    if isinstance(campo, list):
        for c in campo:
            c = str(c).strip()
            if c and c not in claves:
                claves.append(c)

nuevo = {
    "listen": ":5667",
    "cert": "/etc/zivpn/zivpn.crt",
    "key": "/etc/zivpn/zivpn.key",
    "max_conn": 0,
    "obfs": "zivpn",
    "auth": {
        "mode": "passwords",
        "config": claves
    }
}

p.write_text(json.dumps(nuevo, indent=2))
PY
}

red_zivpn() {
    ufw allow 5667/udp >/dev/null 2>&1 || true

    sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1
    grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf || echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

    IFACE=$(ip -4 route | awk '/default/ {print $5; exit}')

    iptables -C INPUT -p udp --dport 5667 -j ACCEPT 2>/dev/null || iptables -I INPUT -p udp --dport 5667 -j ACCEPT
    iptables -C FORWARD -j ACCEPT 2>/dev/null || iptables -I FORWARD -j ACCEPT
    iptables -t nat -C POSTROUTING -o "$IFACE" -j MASQUERADE 2>/dev/null || iptables -t nat -A POSTROUTING -o "$IFACE" -j MASQUERADE

    netfilter-persistent save >/dev/null 2>&1 || true
}

liberar_puerto_zivpn() {
    systemctl stop zvpn 2>/dev/null || true
    systemctl stop sipvpn-activex 2>/dev/null || true

    pkill -f "zivpn server" 2>/dev/null || true
    pkill -f "/usr/local/bin/zivpn" 2>/dev/null || true

    sleep 1
}

reiniciar_zivpn_limpio() {
    systemctl daemon-reload >/dev/null 2>&1 >/dev/null 2>&1
    systemctl enable zivpn >/dev/null 2>&1 >/dev/null 2>&1

    systemctl stop zivpn >/dev/null 2>&1 || true
    liberar_puerto_zivpn
    redireccion_udp_zivpn
    systemctl start zivpn >/dev/null 2>&1

    sleep 1
}

activar_zivpn() {
    titulo_zivpn "ACTIVAR / INSTALAR ZIVPN"

    cargando "Cargando binarios ZIVPN"
    asegurar_motor_zivpn || return

    cargando "Aplicando configuración"
    normalizar_config_zivpn

    cargando "Preparando puerto UDP"
    red_zivpn

    cargando "Iniciando servicio"
    reiniciar_zivpn_limpio

    ok_msg "ZIVPN activado correctamente."
    echo -e "${AMARILLO}Estado:${RESET} $(estado_zivpn)"

    pausa_bonita
}


ZIVPN_KEYS_DB="/etc/zivpn/keys_expire.db"

sincronizar_claves_zivpn() {
    mkdir -p /etc/zivpn
    touch "$ZIVPN_KEYS_DB"

    python3 <<'PY2'
import json, os
from datetime import date

config_path = "/etc/zivpn/config.json"
db_path = "/etc/zivpn/keys_expire.db"

today = date.today().isoformat()

if not os.path.exists(config_path):
    raise SystemExit(0)

try:
    data = json.load(open(config_path))
except Exception:
    raise SystemExit(0)

validas = []
nuevas_lineas = []

if os.path.exists(db_path):
    for line in open(db_path, errors="ignore"):
        line = line.strip()
        if not line or "|" not in line:
            continue
        clave, vence = line.split("|", 1)
        clave = clave.strip()
        vence = vence.strip()
        if not clave:
            continue
        if vence >= today:
            validas.append(clave)
            nuevas_lineas.append(f"{clave}|{vence}")

data.setdefault("auth", {})
data["auth"]["mode"] = "passwords"
data["auth"]["config"] = validas

json.dump(data, open(config_path, "w"), indent=2)

with open(db_path, "w") as f:
    if nuevas_lineas:
        f.write("\n".join(nuevas_lineas) + "\n")
PY2
}

reiniciar_zivpn_con_red() {
    sincronizar_claves_zivpn
    if declare -F redireccion_udp_zivpn >/dev/null; then
        redireccion_udp_zivpn
    fi
    systemctl restart zivpn >/dev/null 2>&1 || true
}

crear_clave_zivpn() {
    titulo_zivpn "CREAR CLAVE ZIVPN"

    asegurar_motor_zivpn || return
    normalizar_config_zivpn

    echo ""
    read -r -p "Clave nueva: " CLAVE
    CLAVE="$(echo "$CLAVE" | xargs)"

    if [[ -z "$CLAVE" ]]; then
        error_msg "No escribiste ninguna clave."
        pausa_bonita
        return
    fi

    echo ""
    read -r -p "Días de validez: " DIAS
    DIAS="$(echo "$DIAS" | xargs)"

    if ! [[ "$DIAS" =~ ^[0-9]+$ ]]; then
        error_msg "Los días deben ser un número."
        pausa_bonita
        return
    fi

    if [[ "$DIAS" -le 0 ]]; then
        error_msg "Los días deben ser mayor que 0."
        pausa_bonita
        return
    fi

    VENCE="$(date -d "+$DIAS days" +%F)"

    mkdir -p /etc/zivpn
    touch "$ZIVPN_KEYS_DB"

    grep -v "^${CLAVE}|" "$ZIVPN_KEYS_DB" > "${ZIVPN_KEYS_DB}.tmp" 2>/dev/null || true
    mv "${ZIVPN_KEYS_DB}.tmp" "$ZIVPN_KEYS_DB"

    echo "${CLAVE}|${VENCE}" >> "$ZIVPN_KEYS_DB"

    sincronizar_claves_zivpn
    reiniciar_zivpn_con_red

    ok_msg "Clave creada correctamente."
    echo -e "${AMARILLO}Clave:${RESET} $CLAVE"
    echo -e "${AMARILLO}Vence:${RESET} $VENCE"
    echo -e "${AMARILLO}Estado:${RESET} $(estado_zivpn)"
    pausa_bonita
}

listar_claves_zivpn() {
    titulo_zivpn "LISTAR CLAVES ZIVPN"

    sincronizar_claves_zivpn

    if [[ ! -s "$ZIVPN_KEYS_DB" ]]; then
        echo -e "${ROJO}No hay claves registradas.${RESET}"
        pausa_bonita
        return
    fi

    HOY="$(date +%F)"

    echo -e "${CYAN}CLAVES ACTIVAS:${RESET}"
    echo ""

    while IFS="|" read -r CLAVE VENCE; do
        [[ -z "$CLAVE" ]] && continue

        if [[ "$VENCE" < "$HOY" ]]; then
            ESTADO="${ROJO}VENCIDA${RESET}"
        else
            ESTADO="${VERDE}ACTIVA${RESET}"
        fi

        echo -e "${BLANCO}Clave:${RESET} ${CLAVE}  ${AMARILLO}Vence:${RESET} ${VENCE}  ${ESTADO}"
    done < "$ZIVPN_KEYS_DB"

    echo ""
    pausa_bonita
}

eliminar_clave_zivpn() {
    titulo_zivpn "ELIMINAR CLAVE ZIVPN"

    sincronizar_claves_zivpn

    if [[ ! -s "$ZIVPN_KEYS_DB" ]]; then
        echo -e "${ROJO}No hay claves registradas.${RESET}"
        pausa_bonita
        return
    fi

    echo -e "${CYAN}Claves actuales:${RESET}"
    cat "$ZIVPN_KEYS_DB" | cut -d'|' -f1
    echo ""

    read -r -p "Clave a eliminar: " CLAVE
    CLAVE="$(echo "$CLAVE" | xargs)"

    if [[ -z "$CLAVE" ]]; then
        error_msg "No escribiste ninguna clave."
        pausa_bonita
        return
    fi

    grep -v "^${CLAVE}|" "$ZIVPN_KEYS_DB" > "${ZIVPN_KEYS_DB}.tmp" 2>/dev/null || true
    mv "${ZIVPN_KEYS_DB}.tmp" "$ZIVPN_KEYS_DB"

    sincronizar_claves_zivpn
    reiniciar_zivpn_con_red

    ok_msg "Clave eliminada si existía."
    pausa_bonita
}


redireccion_udp_zivpn() {
    local PORT="5667"

    sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1
    grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf 2>/dev/null || echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

    local DEV
    DEV=$(ip -4 route show default | awk '{print $5}' | head -1)

    if [[ -z "$DEV" ]]; then
        DEV=$(ip link show up | grep -v loopback | grep -v 'lo:' | head -1 | awk '{print $2}' | cut -d':' -f1)
    fi

    if [[ -z "$DEV" ]]; then
        error_msg "No se pudo detectar la interfaz de red."
        return 1
    fi

    # Limpiar reglas viejas del rango UDP
    iptables -t nat -S PREROUTING | grep '6000:19999' | sed 's/-A/-D/' | while read -r line; do iptables -t nat $line 2>/dev/null || true; done
    iptables -S INPUT | grep '6000:19999' | sed 's/-A/-D/' | while read -r line; do iptables $line 2>/dev/null || true; done
    iptables -S INPUT | grep -w "$PORT" | sed 's/-A/-D/' | while read -r line; do iptables $line 2>/dev/null || true; done

    # Aplicar reglas necesarias
    iptables -t nat -I PREROUTING 1 -i "$DEV" -p udp --dport 6000:19999 -j REDIRECT --to-port "$PORT"
    iptables -I INPUT 1 -p udp --dport "$PORT" -j ACCEPT
    iptables -I INPUT 1 -p udp --dport 6000:19999 -j ACCEPT

    iptables -t nat -D POSTROUTING -o "$DEV" -j MASQUERADE 2>/dev/null || true
    iptables -t nat -A POSTROUTING -o "$DEV" -j MASQUERADE

    return 0
}

encender_zivpn() {
    titulo_zivpn "ENCENDER ZIVPN"

    asegurar_motor_zivpn || return
    normalizar_config_zivpn
    red_zivpn

    systemctl enable zivpn >/dev/null 2>&1 >/dev/null 2>&1
    redireccion_udp_zivpn
    systemctl start zivpn >/dev/null 2>&1

    ok_msg "ZIVPN encendido."
    echo -e "${AMARILLO}Estado:${RESET} $(estado_zivpn)"

    pausa_bonita
}

detener_zivpn() {
    titulo_zivpn "DETENER ZIVPN"

    systemctl stop zivpn >/dev/null 2>&1
    pkill -f "zivpn server" 2>/dev/null || true

    warn_msg "ZIVPN detenido."
    echo -e "${AMARILLO}Estado:${RESET} $(estado_zivpn)"

    pausa_bonita
}

reiniciar_zivpn() {
    titulo_zivpn "REINICIAR ZIVPN"

    asegurar_motor_zivpn || return
    normalizar_config_zivpn
    red_zivpn

    cargando "Reiniciando ZIVPN"
    reiniciar_zivpn_limpio

    ok_msg "ZIVPN reiniciado."
    echo -e "${AMARILLO}Estado:${RESET} $(estado_zivpn)"

    pausa_bonita
}

remover_zivpn() {
    titulo_zivpn "REMOVER ZIVPN"

    read -r -p "¿Seguro que quieres remover ZIVPN? [s/n]: " r

    if [[ "$r" == "s" || "$r" == "S" ]]; then
        systemctl stop zivpn >/dev/null 2>&1 || true
        systemctl disable zivpn >/dev/null 2>&1 || true
        pkill -f "zivpn server" 2>/dev/null || true
        rm -f /etc/systemd/system/zivpn.service
        systemctl daemon-reload >/dev/null 2>&1 >/dev/null 2>&1
        ok_msg "ZIVPN removido del servicio."
        echo "Las claves quedan guardadas en /etc/zivpn/config.json"
    else
        echo "Cancelado."
    fi

    pausa_bonita
}

menu_zivpn() {
    while true; do
        titulo_zivpn "MENÚ ZIVPN"

        echo -e "${ROJO}[01]${RESET} ${CYAN}➜${RESET} ${BLANCO}ACTIVAR / INSTALAR${RESET}      $(estado_zivpn)"
        echo -e "${ROJO}[02]${RESET} ${CYAN}➜${RESET} ${BLANCO}CREAR CLAVE${RESET}"
        echo -e "${ROJO}[03]${RESET} ${CYAN}➜${RESET} ${BLANCO}LISTAR CLAVES${RESET}"
        echo -e "${ROJO}[04]${RESET} ${CYAN}➜${RESET} ${BLANCO}ELIMINAR CLAVE${RESET}"
        echo -e "${ROJO}[05]${RESET} ${CYAN}➜${RESET} ${BLANCO}ENCENDER${RESET}"
        echo -e "${ROJO}[06]${RESET} ${CYAN}➜${RESET} ${BLANCO}DETENER${RESET}"
        echo -e "${ROJO}[07]${RESET} ${CYAN}➜${RESET} ${BLANCO}REINICIAR${RESET}"
        echo -e "${ROJO}[08]${RESET} ${CYAN}➜${RESET} ${ROJO}REMOVER${RESET}"
        echo ""
        echo -e "${ROJO}[00]${RESET} ${CYAN}➜${RESET} ${ROJO}[ VOLVER ]${RESET}"

        leer_opcion op "⚡ Opción: "

        case "$op" in
            1|01) activar_zivpn ;;
            2|02) crear_clave_zivpn ;;
            3|03) listar_claves_zivpn ;;
            4|04) eliminar_clave_zivpn ;;
            5|05) encender_zivpn ;;
            6|06) detener_zivpn ;;
            7|07) reiniciar_zivpn ;;
            8|08) remover_zivpn ;;
            0|00) return ;;
            *) opcion_invalida ;;
        esac
    done
}

menu_zivpn
