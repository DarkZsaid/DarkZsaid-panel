#!/bin/bash

ROJO="\e[1;31m"
VERDE="\e[1;97m"
AMARILLO="\e[1;33m"
AZUL="\e[1;97m"
CYAN="\e[1;33m"
BLANCO="\e[1;97m"
CELESTE="\e[1;36m"
RESET="\e[0m"
BOLD="\e[1m"

APP_DIR="/opt/darkzsaid"
CONFIG_FILE="$APP_DIR/config.env"

source "$CONFIG_FILE"

LINEA="${ROJO}══════════════════════════ / / / ══════════════════════════${RESET}"

pausa() {
    echo ""
    read -p "Presiona ENTER para continuar..."
}

titulo() {
    clear
    echo -e "$LINEA"
    echo -e "${BLANCO}${BOLD}                 $1${RESET}"
    echo -e "$LINEA"
    echo ""
}

get_ip() {
    echo "$APP_DOMAIN"
}

estado_servicio() {
    systemctl is-active --quiet "$1" 2>/dev/null && echo -e "${VERDE}[ON]${RESET}" || echo -e "${ROJO}[OFF]${RESET}"
}

info_vps() {
    OS=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')
    IP=$(get_ip)
    RAM=$(free -m | awk '/Mem:/ {print $3 "/" $2 " MB"}')
    SWAP=$(free -m | awk '/Swap:/ {print $3 "/" $2 " MB"}')
    DISCO=$(df -h / | awk 'NR==2 {print $4 " libre"}')

    echo -e "${ROJO}»${RESET} OS: ${VERDE}$OS${RESET} | IP: ${AMARILLO}$IP${RESET}"
    echo -e "${ROJO}⇒${RESET} RAM: ${AMARILLO}$RAM${RESET} | Swap: ${AMARILLO}$SWAP${RESET} | Disco: ${AMARILLO}$DISCO${RESET}"
    echo ""
}


mostrar_puertas_activas_panel() {
    echo -e "${AMARILLO}*     clear

    PANEL_NAME="DARKZSAID"
    PANEL_AUTHOR="@DarkZsaid"
    PANEL_VERSION="v1.0"

    [[ -f /etc/darkzsaid/panel_theme.conf ]] && source /etc/darkzsaid/panel_theme.conf 2>/dev/null || true

    echo -e "${CIAN}${BOLD}        DARKZSAID${RESET}"
    echo -e "${BLANCO}${BOLD}     SCRIPT PREMIUM${RESET}"


    SO_INFO="$(lsb_release -ds 2>/dev/null | tr -d '"' || echo Linux)"
    IP_INFO="$(curl -s --max-time 2 ifconfig.me 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}')"
    CPU_INFO="$(nproc 2>/dev/null || echo 1)"
    FECHA_INFO="$(date '+%d/%m/%Y-%H:%M')"
    RAM_INFO="$(free -m | awk '/Mem:/ {print $3"Mi"}')"
    UPTIME_INFO="$(uptime -p 2>/dev/null | sed 's/up //')"

    PUERTO_SSH=""
    PUERTO_DNS=""
    PUERTO_SOCKS=""
    PUERTO_SSL=""
    PUERTO_UDP_CUSTOM=""
    PUERTO_ZIVPN=""
    PUERTO_BADVPN1=""
    PUERTO_BADVPN2=""

    ss -tulnp 2>/dev/null | grep -qE '(:22[[:space:]]|:22$)' && PUERTO_SSH="${VERDE}ON${RESET}"
    ss -tulnp 2>/dev/null | grep -qE '(:53[[:space:]]|:53$)' && PUERTO_DNS="${VERDE}ON${RESET}"
    ss -tulnp 2>/dev/null | grep -qE '(:80[[:space:]]|:80$)' && PUERTO_SOCKS="${VERDE}ON${RESET}"
    ss -tulnp 2>/dev/null | grep -qE '(:443[[:space:]]|:443$)' && PUERTO_SSL="${VERDE}ON${RESET}"
    ss -tulnp 2>/dev/null | grep -qE '(:36712[[:space:]]|:36712$)' && PUERTO_UDP_CUSTOM="${VERDE}ON${RESET}"
    ss -tulnp 2>/dev/null | grep -qE '(:5667[[:space:]]|:5667$)' && PUERTO_ZIVPN="${VERDE}ON${RESET}"
    ss -tulnp 2>/dev/null | grep -qE '(:7200[[:space:]]|:7200$)' && PUERTO_BADVPN1="${VERDE}ON${RESET}"
    ss -tulnp 2>/dev/null | grep -qE '(:7300[[:space:]]|:7300$)' && PUERTO_BADVPN2="${VERDE}ON${RESET}"

RAYA="${CYAN}◆════════════════════════════════════════════════◆${RESET}"

    echo -e "${CYAN}"
cat <<'LOGO'
 ____             _    ______          _     _ 
|  _ \  __ _ _ __| | _|__  / ___  ___(_) __| |
| | | |/ _  | '__| |/ / / / / __|/ _ \ |/ _  |
| |_| | (_| | |  |   < / /_ \__ \  __/ | (_| |
|____/ \__,_|_|  |_|\_/____|___/\___|_|\__,_|
LOGO
echo -e "${RESET}"
        echo -e "$RAYA"
    echo -e "${BLANCO} ⚡ Gestor VPN/SSH by ${CYAN}${PANEL_AUTHOR:-@DarkZsaid}${RESET}  ${AMARILLO}◆ ${PANEL_VERSION:-v1.0}${RESET}"
    echo -e "$RAYA"
    echo ""

    echo -e "$RAYA"
        echo -e "${CYAN} ◈${RESET} ${CYAN}SO:${RESET} ${BLANCO}${SO_INFO}${RESET} ${CYAN}◈${RESET} ${CYAN}IP:${RESET} ${CELESTE}${IP_INFO}${RESET}"
        echo -e "${CYAN} ◈${RESET} ${CYAN}CPU:${RESET} ${BLANCO}${CPU_INFO} cores${RESET}      ${CYAN}◈${RESET} ${CYAN}Fecha:${RESET} ${CELESTE}${FECHA_INFO}${RESET}"
        echo -e "${CYAN} ◈${RESET} ${CYAN}RAM:${RESET} ${BLANCO}${RAM_INFO}${RESET}"
        echo -e "${CYAN} ◈${RESET} ${CYAN}Up:${RESET} ${BLANCO}${UPTIME_INFO}${RESET}"

    [[ -n "$PUERTO_SSH" ]] && echo -e "${CYAN} ◈${RESET} SSH:22 ${CYAN}◆${RESET} $PUERTO_SSH        ${CYAN}◈${RESET} DNS:53 ${CYAN}◆${RESET} ${PUERTO_DNS:-${ROJO}OFF${RESET}}"
    [[ -n "$PUERTO_SOCKS" ]] && echo -e "${CYAN} ◈${RESET} SOCKS:80 ${CYAN}◆${RESET} $PUERTO_SOCKS"
    [[ -n "$PUERTO_SSL" ]] && echo -e "${CYAN} ◈${RESET} SSL:443 ${CYAN}◆${RESET} $PUERTO_SSL"
    [[ -n "$PUERTO_UDP_CUSTOM" ]] && echo -e "${CYAN} ◈${RESET} UDP:36712 ${CYAN}◆${RESET} $PUERTO_UDP_CUSTOM"
    [[ -n "$PUERTO_ZIVPN" ]] && echo -e "${CYAN} ◈${RESET} ZIVPN:5667 ${CYAN}◆${RESET} $PUERTO_ZIVPN"
    [[ -n "$PUERTO_BADVPN1" || -n "$PUERTO_BADVPN2" ]] && echo -e "${CYAN} ◈${RESET} BadVPN:7200 ${CYAN}◆${RESET} ${PUERTO_BADVPN1:-${ROJO}OFF${RESET}}    ${CYAN}◈${RESET} BadVPN:7300 ${CYAN}◆${RESET} ${PUERTO_BADVPN2:-${ROJO}OFF${RESET}}"
    echo -e "$RAYA"

    printf "%b
" "${BLANCO}\<1\>${RESET} ⚡ ${BLANCO}USUARIOS${RESET}          ${BLANCO}\<2\>${RESET} 📡 ${BLANCO}PROTOCOLOS${RESET}"
    printf "%b
" "${BLANCO}\<3\>${RESET} 🛠  ${BLANCO}HERRAMIENTAS${RESET}    ${BLANCO}\<5\>${RESET} ✚ ${BLANCO}PUERTOS${RESET}"
    printf "%b
" "${BLANCO}\<6\>${RESET} ◆  ${BLANCO}BOT TELEGRAM${RESET}    ${BLANCO}\<7\>${RESET} ⚙ ${BLANCO}NOMBRE PANEL${RESET}"
    printf "%b
" "${CYAN} ◈ Version: ${VERDE}${PANEL_VERSION:-v1.0}${RESET} ${CYAN}◈${RESET}"
    echo -e "$RAYA"

    printf "%b
" "${BLANCO}\<08\>${RESET} 💻 ${AMARILLO}ACTUALIZAR${RESET}      ${BLANCO}\<9\>${RESET} 🗑 ${ROJO}DESINSTALAR${RESET}"
    printf "%b
" "${BLANCO}\<99\>${RESET} 🔄 ${AMARILLO}REBOOT${RESET}"
    echo -e "$RAYA"
    printf "%b
" "${BLANCO}\<0\>${RESET} ❌ ${ROJO}SALIR${RESET}"
    echo -e "$RAYA"
    echo ""
    read -p "Opción: " op

        
case "$op" in
            1) bash /opt/darkzsaid/menus/users_menu.sh ;;
            2) bash /opt/darkzsaid/menus/metodos_udp_menu.sh ;;
            3) menu_herramientas ;;
        4|04)
            echo "Opción eliminada."
            sleep 1
            ;;
        5|05)
            bash /opt/darkzsaid/socks_ws_menu.sh
            ;;
            6|06)
                if [[ -x /opt/darkzsaid/menus/extras_telegram_checkuser.sh ]]; then
                    bash /opt/darkzsaid/menus/extras_telegram_checkuser.sh
                else
                    echo "No se encontró /opt/darkzsaid/menus/extras_telegram_checkuser.sh"
                    read -rp "Presiona ENTER para volver..."
                fi
                ;;
        7|07) bash /opt/darkzsaid/menus/configurar_nombre_panel.sh ;;



            98)
                bash /opt/darkzsaid/menus/uninstall_darkzsaid.sh
                exit 0
                ;;
            99) reboot ;;
            0) clear; exit ;;
            *) echo "Opción inválida"; sleep 1 ;;
        esac
    done
}



crear_usuario_ssh() {
    titulo "CREAR USUARIO SSH / UDP"

    read -p "Usuario: " user

    if [[ -z "$user" ]]; then
        echo "Usuario vacío."
        pausa
        return
    fi

    if id "$user" &>/dev/null; then
        echo "Ese usuario ya existe."
        pausa
        return
    fi

    read -p "Contraseña: " pass

    if [[ -z "$pass" ]]; then
        echo "Contraseña vacía."
        pausa
        return
    fi

    read -p "Días de duración: " dias

    if ! [[ "$dias" =~ ^[0-9]+$ ]]; then
        echo "Días inválidos."
        pausa
        return
    fi

    fecha=$(date -d "+$dias days" +%Y-%m-%d 2>/dev/null)

    useradd -M "$user" -s /bin/false -e "$fecha"
    echo "$user:$pass" | chpasswd

    echo ""
    echo -e "${VERDE}Usuario creado correctamente.${RESET}"
    echo ""
    echo "Usuario: $user"
    echo "Contraseña: $pass"
    echo "Expira: $fecha"
    echo "IP VPS: $(get_ip)"
    echo ""
    echo "Este usuario sirve para SSH, Dropbear, Stunnel, Socks Python WS y UDP-Hysteria APPmod's."
    pausa
}

menu_usuarios() {
    while true; do
        titulo "ADMINISTRACION DE USUARIOS"

        echo -e "${ROJO}[1]${RESET} ${AZUL}CREAR USUARIO${RESET}"
        echo -e "${ROJO}[8]${RESET} ${AZUL}CREADOR DE CUENTAS TIPO${RESET}"
        echo -e "${ROJO}[2]${RESET} ${AZUL}ELIMINAR USUARIO${RESET}"
        echo -e "${ROJO}[3]${RESET} ${AZUL}CAMBIAR PASSWORD${RESET}"
        echo -e "${ROJO}[4]${RESET} ${AZUL}BLOQUEAR USUARIO${RESET}"
        echo -e "${ROJO}[5]${RESET} ${AZUL}DESBLOQUEAR USUARIO${RESET}"
        echo -e "${ROJO}[6]${RESET} ${AZUL}LISTAR USUARIOS${RESET}"
        echo -e "${ROJO}[0]${RESET} ${BLANCO}VOLVER${RESET}"
        echo ""
        read -p "Opción: " op

        case "$op" in
            1) crear_usuario_ssh ;;
            2)
                read -p "Usuario a eliminar: " user
                deluser --remove-home "$user" 2>/dev/null
                echo "Usuario eliminado si existía."
                pausa
                ;;
            3)
                read -p "Usuario: " user
                read -p "Nueva contraseña: " pass
                echo "$user:$pass" | chpasswd
                echo "Contraseña cambiada."
                pausa
                ;;
            4)
                read -p "Usuario a bloquear: " user
                usermod -L "$user"
                echo "Usuario bloqueado."
                pausa
                ;;
            5)
                read -p "Usuario a desbloquear: " user
                usermod -U "$user"
                echo "Usuario desbloqueado."
                pausa
                ;;
            6)
                awk -F: '$3 >= 1000 && $1 != "nobody" {print "Usuario:", $1, "| Expira:", $8}' /etc/passwd
                pausa
                ;;
            9|09)
                bash /opt/darkzsaid/menus/udpmod_users_menu.sh
                ;;
            0) return ;;
            *) echo "Opción inválida"; sleep 1 ;;
        esac
    done
}

menu_instaladores() {
    while true; do
        titulo "INSTALADORES & PROTOCOLOS"

        echo -e "${ROJO}[01]${RESET} ${AZUL}ABRIR PUERTOS RECOMENDADOS${RESET}"
        echo -e "${ROJO}[02]${RESET} ${AZUL}UDP-HYSTERIA APPMOD'S / UDPMOD${RESET}   $(estado_servicio udpmod)"
        echo -e "${ROJO}[03]${RESET} ${AZUL}UDP-CUSTOM${RESET}                       $(estado_servicio udp-custom)"
        echo -e "${ROJO}[04]${RESET} ${AZUL}ZIVPN${RESET}                            $(estado_servicio zivpn)"
        echo -e "${ROJO}[05]${RESET} ${AZUL}SOCKS PYTHON DIRECTO WS${RESET}"
        echo -e "${ROJO}[06]${RESET} ${AZUL}DROPBEAR${RESET}                         $(estado_servicio dropbear)"
        echo -e "${ROJO}[07]${RESET} ${AZUL}STUNNEL SSL${RESET}                       $(estado_servicio darkzsaid-stunnel)"
        echo -e "${ROJO}[08]${RESET} ${AZUL}BADVPN UDPGW${RESET}                      $(estado_servicio badvpn-udpgw)"
        echo -e "${ROJO}[09]${RESET} ${AZUL}PANEL WEB 3X-UI${RESET}                   $(estado_servicio x-ui)"
        echo -e "${ROJO}[00]${RESET} ${BLANCO}VOLVER${RESET}"
        echo ""
        read -p "Opción: " op

        case "$op" in
            1|01) abrir_puertos_recomendados ;;
            2|02) menu_appmods ;;
            3|03) menu_udp_custom_seguro ;;
            4|04)
                menu_zivpn_seguro
                sleep 1
                ;;
            5|05) menu_socks_python_ws ;;
            6|06) instalar_dropbear ;;
            7|07) instalar_stunnel ;;
            8|08) instalar_badvpn ;;
            9|09) instalar_3xui ;;
            9|09)
            bash /opt/darkzsaid/menus/udpmod_users_menu.sh
            ;;
        0|00) return ;;
            *) echo "Opción inválida"; sleep 1 ;;
        esac
    done
}

abrir_puertos_recomendados() {
    titulo "ABRIR PUERTOS RECOMENDADOS"

    ufw allow 22/tcp
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw allow 109/tcp
    ufw allow 143/tcp
    ufw allow 7300/tcp
    ufw allow 7300/udp
    ufw allow 36712/udp
    ufw allow 5667/udp
    ufw allow 20000:39999/udp
    ufw --force enable

    echo "Puertos abiertos:"
    echo "22/tcp SSH"
    echo "80/tcp HTTP / WS"
    echo "443/tcp SSL"
    echo "109/tcp Dropbear"
    echo "143/tcp Dropbear"
    echo "7300/tcp BadVPN"
    echo "7300/udp BadVPN"
    echo "36712/udp UDP-Hysteria APPmod's"
    echo "5667/udp ZiVPN"
    echo "20000:39999/udp rango UDP"
    echo ""
    ufw status numbered
    pausa
}


estado_limpio_udpm() {
    titulo "DARKZSAID UDP HYSTERIA"

    IP=$(get_ip)
    CONFIG="/etc/udpmod/config.json"

    if [[ -f "$CONFIG" ]]; then
        OBFS_ACTUAL=$(grep '"obfs"' "$CONFIG" | head -1 | cut -d'"' -f4)
        ALPN_ACTUAL=$(grep '"alpn"' "$CONFIG" | head -1 | cut -d'"' -f4)
    else
        OBFS_ACTUAL="DarkZsaid"
        ALPN_ACTUAL="h3"
    fi

    [[ -z "$ALPN_ACTUAL" ]] && ALPN_ACTUAL="h3"

    if systemctl is-active --quiet udpmod 2>/dev/null; then
        ESTADO="${VERDE}[ON]${RESET}"
    else
        ESTADO="${ROJO}[OFF]${RESET}"
    fi

    echo -e "${AMARILLO}        DATOS UDP-HYSTERIA${RESET}"
    echo -e "$LINEA"
    echo ""
    echo -e "${CYAN}Servicio:${RESET} Hysteria"
    echo -e "${CYAN}Estado:${RESET} $ESTADO"
    echo ""
    echo -e "${CYAN}Servidor UDP/IP:${RESET} $IP"
    echo -e "${CYAN}Puerto:${RESET} 36712 UDP"
    echo -e "${CYAN}UDP:${RESET} Original"
    echo -e "${CYAN}Hysteria Obfuscation:${RESET} $OBFS_ACTUAL"
    echo -e "${CYAN}Rango:${RESET} 20000-39999"
    echo -e "${CYAN}ALPN:${RESET} $ALPN_ACTUAL"
    echo ""
    echo -e "${AMARILLO}Datos para la app:${RESET}"
    echo "Servidor UDP/IP: $IP"
    echo "Puerto: 36712"
    echo "Hysteria Obfuscation: $OBFS_ACTUAL"
    echo "Rango: 20000-39999"
    echo ""
    pausa
}


menu_udp_custom_seguro() {
    titulo "UDP-CUSTOM"

    if [[ -f /opt/darkzsaid/menus/udp_custom_menu.sh ]]; then
        bash /opt/darkzsaid/menus/udp_custom_menu.sh
        return
    fi

    echo -e "${AMARILLO}UDP-CUSTOM no tiene menú nuevo conectado.${RESET}"
    echo "No se encontró: /opt/darkzsaid/menus/udp_custom_menu.sh"
    echo ""
    echo "Servicio: udp-custom"
    echo -n "Estado: "
    systemctl is-active udp-custom 2>/dev/null || echo "OFF"
    echo ""
    echo "Puerto UDP-CUSTOM:"
    ss -ulnp | grep -Ei 'udp-custom|36712|5667' || echo "No se detectó puerto UDP-CUSTOM."
    pausa
}


menu_zivpn_seguro() {
    if [[ -f /opt/darkzsaid/menus/zivpn_menu.sh ]]; then
        bash /opt/darkzsaid/menus/zivpn_menu.sh
    else
        echo "No se encontró /opt/darkzsaid/menus/zivpn_menu.sh"
        read -p "Presiona ENTER para volver..."
    fi
}

menu_appmods() {
    while true; do
        titulo "UDP-HYSTERIA APPMOD'S / UDPMOD"

        echo -e "${ROJO}[1]${RESET} ${AZUL}INSTALAR / REINSTALAR UDPMOD ORIGINAL${RESET}"
        echo -e "${ROJO}[2]${RESET} ${AZUL}VER DATOS DE CONEXION${RESET}"
        echo -e "${ROJO}[3]${RESET} ${AZUL}REINICIAR SERVICIO${RESET}"
        echo -e "${ROJO}[4]${RESET} ${AZUL}DETENER UDPMOD / CERRAR 36712${RESET}"
        echo -e "${ROJO}[5]${RESET} ${AZUL}CAMBIAR OBFS${RESET}"
        echo -e "${ROJO}[6]${RESET} ${AZUL}USUARIOS UDPMOD / HYSTERIA${RESET}"
        echo -e "${ROJO}[0]${RESET} ${BLANCO}VOLVER${RESET}"
        echo ""
        read -p "Opción: " op

        case "$op" in
            1) instalar_appmods ;;
            2) datos_appmods ;;
            3)
                systemctl restart udpmod
                echo "Servicio reiniciado."
                pausa
                ;;
            4|04)
                systemctl stop udpmod 2>/dev/null || true
                pkill -f udpmod 2>/dev/null || true
                echo "UDPMod detenido. Puerto 36712 cerrado si solo dependía de UDPMod."
                pausa
                ;;
            5|05) cambiar_obfs_appmods ;;
            6|06)
                bash /opt/darkzsaid/menus/udpmod_users_menu.sh
                ;;
            0) return ;;
            *) echo "Opción inválida"; sleep 1 ;;
        esac
    done
}

instalar_appmods() {
    titulo "INSTALAR PROTOCOLO UDP"

    source "$CONFIG_FILE"

    mkdir -p /etc/udpmod

    ARCH=$(uname -m)

    if [[ "$ARCH" == "x86_64" ]]; then
        BIN_URL="https://github.com/apernet/hysteria/releases/download/v1.3.5/hysteria-linux-amd64"
    elif [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
        BIN_URL="https://github.com/apernet/hysteria/releases/download/v1.3.5/hysteria-linux-arm64"
    else
        echo "Arquitectura no soportada: $ARCH"
        pausa
        return
    fi

    wget -O /usr/local/bin/udpmod "$BIN_URL"
    chmod +x /usr/local/bin/udpmod

    openssl req -x509 -nodes -newkey rsa:2048 \
        -keyout /etc/udpmod/server.key \
        -out /etc/udpmod/server.crt \
        -subj "/CN=$APP_DOMAIN" \
        -days 3650 >/dev/null 2>&1

    cat > /etc/udpmod/config.json << EOC
{
  "listen": ":$APP_PORT",
  "cert": "/etc/udpmod/server.crt",
  "key": "/etc/udpmod/server.key",
  "obfs": "DarkZsaid",
  "auth": {
    "mode": "passwords",
    "config": ["USUARIO:CLAVE"]
  },
  "alpn": "$APP_ALPN",
  "up_mbps": 17,
  "down_mbps": 15,
  "disable_udp": false
}
EOC

    cat > /etc/systemd/system/udpmod.service << EOC
[Unit]
Description=UDP-Hysteria APPmod's
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/udpmod server -c /etc/udpmod/config.json
Restart=always
RestartSec=3
User=root
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOC

    ufw allow "$APP_PORT"/udp
    ufw allow "$APP_RANGE"/udp

    systemctl daemon-reload
    systemctl enable udpmod
    systemctl restart udpmod

    echo ""
    echo "UDP-Hysteria APPmod's instalado."
    datos_appmods
}

datos_appmods() {
    titulo "DATOS UDP-HYSTERIA APPMOD'S / UDPMOD"

    IP=$(get_ip)

    if [[ -f /etc/udpmod/config.json ]]; then
        OBFS_ACTUAL=$(grep '"obfs"' /etc/udpmod/config.json | head -1 | cut -d'"' -f4)
    else
        OBFS_ACTUAL="DarkZsaid"
    fi

    echo -e "${VERDE}Servidor UDP/IP:${RESET} $IP"
    echo -e "${VERDE}Puerto:${RESET} 36712"
    echo -e "${VERDE}Hysteria Obfuscation:${RESET} $OBFS_ACTUAL"
    echo -e "${VERDE}Rango:${RESET} 20000-39999"
    echo ""
    echo -e "${AMARILLO}Autenticación:${RESET}"
    echo "Usa el usuario SSH creado en:"
    echo "[1] USUARIOS SSH / UDP-HYSTERIA"
    echo ""
    echo -e "${CYAN}Ejemplo:${RESET}"
    echo "Servidor UDP/IP: $IP"
    echo "Hysteria Autenticacion: usuario:contraseña"
    echo "Hysteria Obfuscation: $OBFS_ACTUAL"
    echo ""
    echo "Estado UDPMOD:"
    systemctl is-active udpmod 2>/dev/null || echo "no activo"
    echo ""
    echo "Puerto:"
    ss -ulnp | grep 36712 || echo "36712 no está escuchando"
    pausa
}

menu_socks_python_ws() {
    bash /opt/darkzsaid/socks_ws_menu.sh
}


instalar_base_socks_python_ws() {
    titulo "INSTALAR BASE SOCKS PYTHON WS"

    apt install -y python3 ufw lsof net-tools

    mkdir -p /opt/darkzsaid
    mkdir -p /etc/darkzsaid/ws

    crear_script_python_ws
    crear_servicio_template_ws

    systemctl daemon-reload

    echo -e "${VERDE}Base Python WS instalada correctamente.${RESET}"
    echo "Ahora puedes agregar puertos personalizados."
    pausa
}

crear_script_python_ws() {
    cat > /opt/darkzsaid/socks-python-ws.py <<'PYEOF'
#!/usr/bin/env python3

import argparse
import socket
import threading
import select

def build_response(code: str, header: str, banner: str) -> bytes:
    reasons = {
        "101": "Switching Protocols",
        "200": "Connection Established",
        "403": "Forbidden",
        "500": "Internal Server Error",
    }

    reason = reasons.get(code, "Connection Established")

    if header and header != "DEFAULT_HOST":
        return header.replace("\\r", "\r").replace("\
", "
").encode()

    if code == "101":
        return (
            "HTTP/1.1 101 Switching Protocols\r
"
            "Upgrade: websocket\r
"
            "Connection: Upgrade\r
"
            f"Server: {banner}\r
"
            "\r
"
        ).encode()

    return (
        f"HTTP/1.1 {code} {reason}\r
"
        f"Server: {banner}\r
"
        "Connection: established\r
"
        "Content-Length: 0\r
"
        "\r
"
    ).encode()

def pipe(client, remote):
    sockets = [client, remote]

    try:
        while True:
            readable, _, error = select.select(sockets, [], sockets, 90)

            if error:
                break

            if not readable:
                break

            for sock in readable:
                data = sock.recv(8192)

                if not data:
                    return

                if sock is client:
                    remote.sendall(data)
                else:
                    client.sendall(data)

    except Exception:
        pass

    finally:
        try:
            client.close()
        except Exception:
            pass

        try:
            remote.close()
        except Exception:
            pass

def handle_client(client, local_port, response_code, custom_header, banner):
    try:
        try:
            first = client.recv(8192)
        except Exception:
            first = b""

        client.sendall(build_response(response_code, custom_header, banner))

        remote = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        remote.connect(("127.0.0.1", local_port))

        if first:
            upper = first[:200].upper()

            if not (
                upper.startswith(b"GET ")
                or upper.startswith(b"POST ")
                or upper.startswith(b"CONNECT ")
                or upper.startswith(b"OPTIONS ")
                or b"HTTP/" in upper
            ):
                remote.sendall(first)

        pipe(client, remote)

    except Exception:
        try:
            client.close()
        except Exception:
            pass

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--listen-port", type=int, required=True)
    parser.add_argument("--local-port", type=int, required=True)
    parser.add_argument("--response", default="200")
    parser.add_argument("--header", default="DEFAULT_HOST")
    parser.add_argument("--banner", default="DarkZsaid WS")

    args = parser.parse_args()

    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(("0.0.0.0", args.listen_port))
    server.listen(300)

    print(f"[DarkZsaid WS] 0.0.0.0:{args.listen_port} -> 127.0.0.1:{args.local_port}")
    print(f"[DarkZsaid WS] RESPONSE={args.response} BANNER={args.banner}")

    while True:
        client, addr = server.accept()
        threading.Thread(
            target=handle_client,
            args=(client, args.local_port, args.response, args.header, args.banner),
            daemon=True
        ).start()

if __name__ == "__main__":
    main()
PYEOF

    chmod +x /opt/darkzsaid/socks-python-ws.py
}

crear_servicio_template_ws() {
    cat > /etc/systemd/system/socks-python-ws@.service <<'EOF'
[Unit]
Description=Socks Python Direct WS Port %i - DarkZsaid
After=network.target

[Service]
Type=simple
EnvironmentFile=/etc/darkzsaid/ws/%i.conf
ExecStart=/usr/bin/python3 /opt/darkzsaid/socks-python-ws.py --listen-port ${PY_PORT} --local-port ${LOCAL_PORT} --response ${RESPONSE_CODE} --header ${CUSTOM_HEADER} --banner ${MINI_BANNER}
Restart=always
RestartSec=3
User=root
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF
}

validar_puerto_libre_ws() {
    local port="$1"

    if ! [[ "$port" =~ ^[0-9]+$ ]]; then
        echo -e "${ROJO}Puerto inválido: $port${RESET}"
        return 1
    fi

    if ss -tulnp | grep -q ":$port "; then
        echo -e "${ROJO}Puerto $port ocupado.${RESET}"
        ss -tulnp | grep ":$port "
        return 1
    fi

    echo -e "${VERDE}Puerto python: $port VALIDO${RESET}"
    return 0
}

validar_puerto_local_ws() {
    local port="$1"

    if ! [[ "$port" =~ ^[0-9]+$ ]]; then
        echo -e "${ROJO}Puerto local inválido.${RESET}"
        return 1
    fi

    if ss -tulnp | grep -q ":$port "; then
        echo -e "${VERDE}Puerto local: $port VALIDO${RESET}"
        return 0
    fi

    echo -e "${AMARILLO}No veo servicio activo en puerto local $port.${RESET}"
    echo "Puedes continuar si SSH/Dropbear/OpenVPN se activará después."
    read -p "¿Continuar? [s/n]: " r

    [[ "$r" == "s" || "$r" == "S" ]]
}

crear_config_puerto_ws() {
    local py_port="$1"
    local local_port="$2"
    local response="$3"
    local header="$4"
    local banner="$5"

    mkdir -p /etc/darkzsaid/ws

    cat > "/etc/darkzsaid/ws/${py_port}.conf" <<EOF
PY_PORT="$py_port"
LOCAL_PORT="$local_port"
RESPONSE_CODE="$response"
CUSTOM_HEADER="$header"
MINI_BANNER="$banner"
EOF
}

agregar_puerto_ws() {
    titulo "AGREGAR PUERTO WS"

    instalar_base_socks_python_ws_silencioso

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BLANCO}Puerto python:${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    read -p "Puerto python [80]: " PY_PORT
    PY_PORT=${PY_PORT:-80}

    validar_puerto_libre_ws "$PY_PORT" || {
        pausa
        return
    }

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BLANCO}Puerto Local SSH/DROPBEAR/OPENVPN${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    read -p "Puerto local [22]: " LOCAL_PORT
    LOCAL_PORT=${LOCAL_PORT:-22}

    validar_puerto_local_ws "$LOCAL_PORT" || {
        pausa
        return
    }

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BLANCO}RESPONDE DE CABECERA 101, 200, 403, 500, etc.${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo "Response personalizado."
    echo "Enter por defecto: 200"
    echo "Para OVER WEBSOCKET escribe: 101"
    read -p "RESPONSE [200]: " RESPONSE_CODE
    RESPONSE_CODE=${RESPONSE_CODE:-200}

    if ! [[ "$RESPONSE_CODE" =~ ^[0-9]{3}$ ]]; then
        echo -e "${ROJO}Response inválida.${RESET}"
        pausa
        return
    fi

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BLANCO}ENCABEZADO PERSONALIZADO${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo "Ejemplo:"
    echo '\r
Content-length: 0\r
\r
HTTP/1.1 200 Connection Established\r
\r
'
    echo ""
    echo "Si desconoces esta opción, solo presiona ENTER."
    read -p "CABECERA [DEFAULT_HOST]: " CUSTOM_HEADER
    CUSTOM_HEADER=${CUSTOM_HEADER:-DEFAULT_HOST}

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BLANCO}Introduzca su Mini-Banner${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    read -p "Mini-Banner [DarkZsaid WS]: " MINI_BANNER
    MINI_BANNER=${MINI_BANNER:-DarkZsaid WS}

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BLANCO}TIPO DE PROXY WEBSOCKET${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${ROJO}[1]${RESET} > Proxy (WS/Direct) (SYSTEMD)"
    echo -e "${ROJO}[2]${RESET} > Proxy (WS/Direct) RESPONSE 101"
    echo -e "${ROJO}[3]${RESET} > Proxy (WS/Direct) RESPONSE 200"
    echo ""
    read -p "Seleccione tipo [1]: " TIPO
    TIPO=${TIPO:-1}

    case "$TIPO" in
        2) RESPONSE_CODE="101" ;;
        3) RESPONSE_CODE="200" ;;
    esac

    crear_config_puerto_ws "$PY_PORT" "$LOCAL_PORT" "$RESPONSE_CODE" "$CUSTOM_HEADER" "$MINI_BANNER"

    ufw allow "$PY_PORT"/tcp 2>/dev/null

    systemctl daemon-reload
    systemctl enable "socks-python-ws@$PY_PORT"
    systemctl restart "socks-python-ws@$PY_PORT"

    echo ""
    echo -e "${VERDE}SOCKS Python WS activado correctamente.${RESET}"
    echo ""
    echo "Puerto Python WS: $PY_PORT"
    echo "Puerto local destino: $LOCAL_PORT"
    echo "Response: $RESPONSE_CODE"
    echo "Cabecera: $CUSTOM_HEADER"
    echo "Mini-Banner: $MINI_BANNER"
    echo ""
    pausa
}

detener_puerto_ws() {
    titulo "DETENER PUERTO WS"

    read -p "Puerto WS a detener: " PORT

    systemctl stop "socks-python-ws@$PORT" 2>/dev/null
    systemctl disable "socks-python-ws@$PORT" 2>/dev/null

    echo "Puerto $PORT detenido."
    pausa
}

reiniciar_puerto_ws() {
    titulo "REINICIAR PUERTO WS"

    read -p "Puerto WS a reiniciar: " PORT

    systemctl restart "socks-python-ws@$PORT" 2>/dev/null

    echo "Puerto $PORT reiniciado."
    pausa
}

estado_puertos_ws() {
    titulo "ESTADO PUERTOS WS"

    echo "Servicios WS:"
    echo ""

    systemctl list-units --type=service --all | grep "socks-python-ws@" || echo "No hay servicios WS creados."

    echo ""
    echo "Puertos escuchando:"
    echo ""

    ss -tulnp | grep "python3" || echo "No hay puertos Python WS activos."

    pausa
}

ver_config_ws() {
    titulo "CONFIGURACIONES WS"

    ls -lh /etc/darkzsaid/ws 2>/dev/null || {
        echo "No hay configuraciones."
        pausa
        return
    }

    echo ""
    read -p "Ver configuración de qué puerto, ejemplo 80, o ENTER para volver: " PORT

    if [[ -n "$PORT" ]]; then
        cat "/etc/darkzsaid/ws/${PORT}.conf" 2>/dev/null || echo "No existe config para ese puerto."
    fi

    pausa
}

desinstalar_socks_python_ws() {
    titulo "DESINSTALAR SOCKS PYTHON WS"

    for conf in /etc/darkzsaid/ws/*.conf; do
        [[ -f "$conf" ]] || continue

        port=$(basename "$conf" .conf)

        systemctl stop "socks-python-ws@$port" 2>/dev/null
        systemctl disable "socks-python-ws@$port" 2>/dev/null
    done

    rm -f /etc/systemd/system/socks-python-ws@.service
    rm -f /opt/darkzsaid/socks-python-ws.py
    rm -rf /etc/darkzsaid/ws

    systemctl daemon-reload

    echo "SOCKS Python WS desinstalado."
    pausa
}

instalar_base_socks_python_ws_silencioso() {
    apt install -y python3 ufw lsof net-tools >/dev/null 2>&1
    mkdir -p /opt/darkzsaid
    mkdir -p /etc/darkzsaid/ws
    crear_script_python_ws
    crear_servicio_template_ws
    systemctl daemon-reload
}

instalar_dropbear() {
    bash /opt/darkzsaid/menus/dropbear_menu.sh
}


instalar_stunnel() {
    bash /opt/darkzsaid/menus/stunnel_menu.sh
}


instalar_badvpn() {
    titulo "INSTALAR BADVPN UDPGW"

    apt install -y cmake gcc make git

    cd /opt || return
    rm -rf badvpn
    git clone https://github.com/ambrop72/badvpn.git

    cd /opt/badvpn || return
    mkdir -p build
    cd build || return

    cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1
    make install

    cat > /etc/systemd/system/badvpn-udpgw.service <<EOC
[Unit]
Description=BadVPN UDPGW
After=network.target

[Service]
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOC

    systemctl daemon-reload
    systemctl enable badvpn-udpgw
    systemctl restart badvpn-udpgw

    ufw allow 7300/tcp
    ufw allow 7300/udp

    echo "BADVPN UDPGW instalado en 127.0.0.1:7300"
    pausa
}

instalar_3xui() {
    titulo "PANEL WEB 3X-UI"

    bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
    pausa
}

menu_puertos() {
    while true; do
        titulo "ADMINISTRADOR DE PUERTOS"

        echo -e "${ROJO}[1]${RESET} ${AZUL}VER PUERTOS ACTIVOS${RESET}"
        echo -e "${ROJO}[2]${RESET} ${AZUL}BUSCAR PUERTO O SERVICIO${RESET}"
        echo -e "${ROJO}[3]${RESET} ${AZUL}ABRIR PUERTO TCP${RESET}"
        echo -e "${ROJO}[4]${RESET} ${AZUL}ABRIR PUERTO UDP${RESET}"
        echo -e "${ROJO}[5]${RESET} ${AZUL}ABRIR RANGO UDP${RESET}"
        echo -e "${ROJO}[6]${RESET} ${AZUL}VER REGLAS UFW${RESET}"
        echo -e "${ROJO}[7]${RESET} ${AZUL}ABRIR PUERTOS RECOMENDADOS${RESET}"
        echo -e "${ROJO}[0]${RESET} ${BLANCO}VOLVER${RESET}"
        echo ""
        read -p "Opción: " op

        case "$op" in
            1) ss -tulnp; pausa ;;
            2)
                read -p "Buscar: " term
                ss -tulnp | grep -i "$term"
                pausa
                ;;
            3)
                read -p "Puerto TCP: " port
                ufw allow "$port"/tcp
                pausa
                ;;
            4)
                read -p "Puerto UDP: " port
                ufw allow "$port"/udp
                pausa
                ;;
            5)
                read -p "Rango UDP, ejemplo 20000:39999: " rango
                ufw allow "$rango"/udp
                pausa
                ;;
            6) ufw status numbered; pausa ;;
            7) abrir_puertos_recomendados ;;
            0) return ;;
            *) echo "Opción inválida"; sleep 1 ;;
        esac
    done
}

menu_bot() {
    while true; do
        titulo "BOT TELEGRAM OPCIONAL"

        echo -e "${ROJO}[1]${RESET} ${AZUL}ACTIVAR / CONFIGURAR BOT TELEGRAM${RESET}"
        echo -e "${ROJO}[2]${RESET} ${AZUL}INICIAR BOT${RESET}              $(estado_servicio darkzsaid-bot)"
        echo -e "${ROJO}[3]${RESET} ${AZUL}DETENER BOT${RESET}"
        echo -e "${ROJO}[4]${RESET} ${AZUL}REINICIAR BOT${RESET}"
        echo -e "${ROJO}[5]${RESET} ${AZUL}ESTADO BOT${RESET}"
        echo -e "${ROJO}[6]${RESET} ${AZUL}VER LOGS BOT${RESET}"
        echo -e "${ROJO}[7]${RESET} ${AZUL}CAMBIAR TOKEN / ID ADMIN${RESET}"
        echo -e "${ROJO}[8]${RESET} ${AZUL}DESACTIVAR BOT${RESET}"
        echo -e "${ROJO}[0]${RESET} ${BLANCO}VOLVER${RESET}"
        echo ""
        read -p "Opción: " op

        case "$op" in
            1) activar_bot_telegram ;;
            2) systemctl start darkzsaid-bot 2>/dev/null; pausa ;;
            3) systemctl stop darkzsaid-bot 2>/dev/null; pausa ;;
            4) systemctl restart darkzsaid-bot 2>/dev/null; pausa ;;
            5) systemctl status darkzsaid-bot --no-pager 2>/dev/null; pausa ;;
            6) journalctl -u darkzsaid-bot -n 80 --no-pager 2>/dev/null; pausa ;;
            7) configurar_bot_telegram ;;
            8) desactivar_bot_telegram ;;
            0) return ;;
            *) echo "Opción inválida"; sleep 1 ;;
        esac
    done
}

activar_bot_telegram() {
    titulo "ACTIVAR BOT TELEGRAM"

    mkdir -p /opt/darkzsaid
    mkdir -p /opt/darkzsaid/logs

    crear_archivo_bot
    configurar_bot_telegram
    crear_servicio_bot_telegram

    echo "Instalando entorno Python del bot..."
    apt install -y python3 python3-venv python3-pip

    python3 -m venv /opt/darkzsaid/venv
    /opt/darkzsaid/venv/bin/pip install --upgrade pip
    /opt/darkzsaid/venv/bin/pip install python-telegram-bot

    systemctl daemon-reload
    systemctl enable darkzsaid-bot
    systemctl restart darkzsaid-bot

    echo ""
    echo -e "${VERDE}Bot Telegram activado correctamente.${RESET}"
    echo "Puedes probar en Telegram con /start"
    pausa
}

configurar_bot_telegram() {
    titulo "CONFIGURAR BOT TELEGRAM"

    read -p "Token del bot de Telegram: " BOT_TOKEN
    read -p "Tu ID de Telegram administrador: " ADMIN_ID

    if [[ -z "$BOT_TOKEN" || -z "$ADMIN_ID" ]]; then
        echo "Token o ID vacío. Cancelado."
        pausa
        return
    fi

    cat > /opt/darkzsaid/bot.env <<EOF
BOT_TOKEN="$BOT_TOKEN"
ADMIN_ID="$ADMIN_ID"
EOF

    chmod 600 /opt/darkzsaid/bot.env

    echo "Datos del bot guardados."
    pausa
}

crear_archivo_bot() {
    cat > /opt/darkzsaid/bot.py <<'PYBOT'
#!/usr/bin/env python3

import subprocess
from datetime import datetime, timedelta
from telegram import Update
from telegram.ext import ApplicationBuilder, CommandHandler, ContextTypes

BOT_ENV = "/opt/darkzsaid/bot.env"
CONFIG_FILE = "/opt/darkzsaid/config.env"

def load_env(path):
    data = {}
    with open(path, "r") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            data[k] = v.strip().strip('"')
    return data

BOTCFG = load_env(BOT_ENV)
CFG = load_env(CONFIG_FILE)

BOT_TOKEN = BOTCFG.get("BOT_TOKEN")
ADMIN_ID = int(BOTCFG.get("ADMIN_ID", "0"))

def run_cmd(cmd):
    try:
        result = subprocess.run(cmd, shell=True, text=True, capture_output=True, timeout=25)
        out = result.stdout.strip() or result.stderr.strip()
        return out[:3500] if out else "Sin salida."
    except Exception as e:
        return f"Error: {e}"

def is_admin(update: Update):
    return update.effective_user and update.effective_user.id == ADMIN_ID

async def deny(update: Update):
    await update.message.reply_text("Acceso denegado.")

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_admin(update):
        await deny(update)
        return

    msg = """
🤖 DARKZSAID BOT VPS

Comandos:

/status
/puertos
/ufw
/datos
/crear usuario password dias
/pass usuario password
/bloquear usuario
/desbloquear usuario
/eliminar usuario
/reiniciar_appmods
/reiniciar_bot
/logs_bot
"""
    await update.message.reply_text(msg)

async def status(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_admin(update):
        await deny(update)
        return
    out = run_cmd("systemctl is-active ssh; systemctl is-active ufw; systemctl is-active udpmod; systemctl is-active darkzsaid-bot")
    await update.message.reply_text(f"📡 Estado:
{out}")

async def puertos(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_admin(update):
        await deny(update)
        return
    out = run_cmd("ss -tulnp")
    await update.message.reply_text(f"📌 Puertos activos:
{out}")

async def ufw(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_admin(update):
        await deny(update)
        return
    out = run_cmd("ufw status numbered")
    await update.message.reply_text(f"🧱 UFW:
{out}")

async def datos(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_admin(update):
        await deny(update)
        return

    cfg = load_env(CONFIG_FILE)

    msg = f"""
📲 DATOS PROTOCOLO UDP

IP VPS: {cfg.get("APP_DOMAIN")}
DOMINIO/SNI: {cfg.get("APP_DOMAIN")}
PUERTO UDP: {cfg.get("APP_PORT")}
OBFS: {cfg.get("APP_OBFS")}
ALPN: {cfg.get("APP_ALPN")}
RANGO UDP: {cfg.get("APP_RANGE")}

Usuario y contraseña:
Usa el usuario SSH creado en la VPS.
"""
    await update.message.reply_text(msg)

async def crear(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_admin(update):
        await deny(update)
        return

    if len(context.args) != 3:
        await update.message.reply_text("Uso: /crear usuario password dias")
        return

    user, password, dias = context.args

    if not user.replace("_", "").replace("-", "").isalnum():
        await update.message.reply_text("Usuario inválido.")
        return

    try:
        dias_int = int(dias)
    except:
        await update.message.reply_text("Días inválidos.")
        return

    fecha = (datetime.now() + timedelta(days=dias_int)).strftime("%Y-%m-%d")

    run_cmd(f"useradd -M {user} -s /bin/false -e {fecha}")
    run_cmd(f"echo '{user}:{password}' | chpasswd")

    await update.message.reply_text(f"✅ Usuario creado
Usuario: {user}
Contraseña: {password}
Expira: {fecha}")

async def cambiar_pass(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_admin(update):
        await deny(update)
        return

    if len(context.args) != 2:
        await update.message.reply_text("Uso: /pass usuario password")
        return

    user, password = context.args
    run_cmd(f"echo '{user}:{password}' | chpasswd")
    await update.message.reply_text(f"✅ Password cambiada para {user}")

async def bloquear(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_admin(update):
        await deny(update)
        return
    if len(context.args) != 1:
        await update.message.reply_text("Uso: /bloquear usuario")
        return
    user = context.args[0]
    run_cmd(f"usermod -L {user}")
    await update.message.reply_text(f"🔒 Usuario bloqueado: {user}")

async def desbloquear(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_admin(update):
        await deny(update)
        return
    if len(context.args) != 1:
        await update.message.reply_text("Uso: /desbloquear usuario")
        return
    user = context.args[0]
    run_cmd(f"usermod -U {user}")
    await update.message.reply_text(f"🔓 Usuario desbloqueado: {user}")

async def eliminar(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_admin(update):
        await deny(update)
        return
    if len(context.args) != 1:
        await update.message.reply_text("Uso: /eliminar usuario")
        return
    user = context.args[0]
    run_cmd(f"deluser --remove-home {user}")
    await update.message.reply_text(f"🗑 Usuario eliminado: {user}")

async def reiniciar_appmods(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_admin(update):
        await deny(update)
        return
    out = run_cmd("systemctl restart udpmod")
    await update.message.reply_text(f"🔄 UDP-Hysteria reiniciado.
{out}")

async def reiniciar_bot(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_admin(update):
        await deny(update)
        return
    await update.message.reply_text("🔄 Reiniciando bot...")
    subprocess.Popen(["systemctl", "restart", "darkzsaid-bot"])

async def logs_bot(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_admin(update):
        await deny(update)
        return
    out = run_cmd("journalctl -u darkzsaid-bot -n 40 --no-pager")
    await update.message.reply_text(f"📜 Logs:
{out}")

def main():
    app = ApplicationBuilder().token(BOT_TOKEN).build()

    app.add_handler(CommandHandler("start", start))
    app.add_handler(CommandHandler("status", status))
    app.add_handler(CommandHandler("puertos", puertos))
    app.add_handler(CommandHandler("ufw", ufw))
    app.add_handler(CommandHandler("datos", datos))
    app.add_handler(CommandHandler("crear", crear))
    app.add_handler(CommandHandler("pass", cambiar_pass))
    app.add_handler(CommandHandler("bloquear", bloquear))
    app.add_handler(CommandHandler("desbloquear", desbloquear))
    app.add_handler(CommandHandler("eliminar", eliminar))
    app.add_handler(CommandHandler("reiniciar_appmods", reiniciar_appmods))
    app.add_handler(CommandHandler("reiniciar_bot", reiniciar_bot))
    app.add_handler(CommandHandler("logs_bot", logs_bot))

    app.run_polling()

if __name__ == "__main__":
    main()
PYBOT

    chmod +x /opt/darkzsaid/bot.py
}

crear_servicio_bot_telegram() {
    cat > /etc/systemd/system/darkzsaid-bot.service <<EOF
[Unit]
Description=DarkZsaid Telegram Bot
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/darkzsaid
ExecStart=/opt/darkzsaid/venv/bin/python /opt/darkzsaid/bot.py
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF
}

desactivar_bot_telegram() {
    titulo "DESACTIVAR BOT TELEGRAM"

    systemctl stop darkzsaid-bot 2>/dev/null
    systemctl disable darkzsaid-bot 2>/dev/null

    echo "Bot detenido y desactivado del arranque."
    pausa
}

menu_herramientas() {
    while true; do
        titulo "HERRAMIENTAS"

        echo -e "${ROJO}[1]${RESET} LIMPIAR CACHE"
        echo -e "${ROJO}[2]${RESET} ACTUALIZAR SISTEMA"
        echo -e "${ROJO}[3]${RESET} VER RAM"
        echo -e "${ROJO}[4]${RESET} CAMBIAR PASSWORD ROOT"
        echo -e "${ROJO}[5]${RESET} VER PROCESOS ACTIVOS"
        echo -e "${ROJO}[0]${RESET} VOLVER"
        echo ""
        read -p "Opción: " op

        case "$op" in
            1) apt clean; apt autoremove -y; pausa ;;
            2) apt update && apt upgrade -y; pausa ;;
            3) free -h; pausa ;;
            4) passwd root; pausa ;;
            5) ps aux --sort=-%mem | head -20; pausa ;;
            0) return ;;
            *) echo "Opción inválida"; sleep 1 ;;
        esac
    done
}

menu_banner() {

    cat > /etc/issue.net <<'EOC'
════════════════════════════════════════════════════
              DARKZSAID VPS
        Acceso autorizado solamente
════════════════════════════════════════════════════
EOC

    sed -i '/^Banner/d' /etc/ssh/sshd_config
    echo "Banner /etc/issue.net" >> /etc/ssh/sshd_config
    systemctl restart ssh || systemctl restart sshd

    echo "Banner creado."
    pausa
}



menu_ws_established() {
    while true; do
        titulo "SSH WEBSOCKET ESTABLISHED 200"

        echo -e "${ROJO}[1]${RESET} ${AZUL}INSTALAR / REINSTALAR SSH-WS ESTABLISHED${RESET}"
        echo -e "${ROJO}[2]${RESET} ${AZUL}VER ESTADO${RESET}"
        echo -e "${ROJO}[3]${RESET} ${AZUL}VER LOGS${RESET}"
        echo -e "${ROJO}[4]${RESET} ${AZUL}CAMBIAR MARCA FINAL${RESET}"
        echo -e "${ROJO}[5]${RESET} ${AZUL}REINICIAR SERVICIO${RESET}"
        echo -e "${ROJO}[0]${RESET} ${BLANCO}VOLVER${RESET}"
        echo ""
        read -p "Opción: " op

        case "$op" in
            1) instalar_ws_established ;;
            2) estado_ws_established ;;
            3) journalctl -u ssh-ws -n 80 --no-pager -l; pausa ;;
            4) cambiar_marca_ws_established ;;
            5) systemctl restart ssh-ws; pausa ;;
            0) return ;;
            *) echo "Opción inválida"; sleep 1 ;;
        esac
    done
}

instalar_python2_si_falta() {
    if command -v python2 >/dev/null 2>&1; then
        return
    fi

    echo "Python2 no encontrado. Instalando Python 2.7.18..."
    apt update
    apt install -y build-essential wget curl make gcc zlib1g-dev libffi-dev libbz2-dev libreadline-dev libsqlite3-dev

    cd /usr/src || return
    rm -rf Python-2.7.18 Python-2.7.18.tgz

    wget https://www.python.org/ftp/python/2.7.18/Python-2.7.18.tgz
    tar xzf Python-2.7.18.tgz
    cd Python-2.7.18 || return

    ./configure --prefix=/usr/local/python2.7
    make -j$(nproc)
    make install

    ln -sf /usr/local/python2.7/bin/python2.7 /usr/bin/python2
}

instalar_ws_established() {
    titulo "INSTALAR SSH-WS ESTABLISHED 200"

    instalar_python2_si_falta

    apt install -y ufw lsof net-tools openssl

    echo "Deteniendo servicios que pueden ocupar el puerto 80..."

    systemctl stop gost-http80 2>/dev/null
    systemctl disable gost-http80 2>/dev/null

    systemctl stop squid 2>/dev/null
    systemctl disable squid 2>/dev/null

    systemctl stop nginx 2>/dev/null
    systemctl disable nginx 2>/dev/null
    systemctl mask nginx 2>/dev/null

    systemctl stop socks-python-ws@80 2>/dev/null
    systemctl disable socks-python-ws@80 2>/dev/null
    systemctl mask socks-python-ws@80 2>/dev/null

    systemctl stop socks-python2-ws 2>/dev/null
    systemctl disable socks-python2-ws 2>/dev/null

    systemctl stop socks-python2-ws-nginx 2>/dev/null
    systemctl disable socks-python2-ws-nginx 2>/dev/null

    systemctl stop ssh-ws 2>/dev/null
    systemctl disable ssh-ws 2>/dev/null
    systemctl unmask ssh-ws 2>/dev/null

    fuser -k 80/tcp 2>/dev/null
    sleep 2

    mkdir -p /opt/darkzsaid

    read -p "Marca final del response [ADM SJCC]: " MARCA_WS
    MARCA_WS=${MARCA_WS:-ADM SJCC}

    cat > /opt/darkzsaid/ssh-ws-direct.py <<EOF
#!/usr/bin/env python2
# -*- coding: utf-8 -*-

import socket
import threading
import select

LISTEN_HOST = "0.0.0.0"
LISTEN_PORT = 80

SSH_HOST = "127.0.0.1"
SSH_PORT = 22

BRAND = "$MARCA_WS"

def response_200():
    return (
        "HTTP/1.1 200 Connection established " + BRAND + "\\r\
"
        "\\r\
"
    )

def is_http_payload(data):
    if not data:
        return False

    d = data[:500].upper()

    if d.startswith("GET "):
        return True
    if d.startswith("POST "):
        return True
    if d.startswith("CONNECT "):
        return True
    if d.startswith("OPTIONS "):
        return True
    if d.startswith("HTTP/"):
        return True
    if "HOST:" in d:
        return True
    if "UPGRADE:" in d:
        return True
    if "HTTP/" in d:
        return True

    return False

def tunnel(client, remote):
    sockets = [client, remote]

    try:
        while True:
            readable, _, errors = select.select(sockets, [], sockets, 180)

            if errors:
                break

            if not readable:
                break

            for s in readable:
                data = s.recv(8192)

                if not data:
                    return

                if s is client:
                    remote.sendall(data)
                else:
                    client.sendall(data)
    except:
        pass

    try:
        client.close()
    except:
        pass

    try:
        remote.close()
    except:
        pass

def handle_client(client, addr):
    try:
        client.settimeout(15)

        try:
            first = client.recv(8192)
        except:
            first = ""

        client.sendall(response_200())

        remote = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        remote.settimeout(15)
        remote.connect((SSH_HOST, SSH_PORT))

        client.settimeout(None)
        remote.settimeout(None)

        if first and not is_http_payload(first):
            remote.sendall(first)

        tunnel(client, remote)

    except:
        try:
            client.close()
        except:
            pass

def main():
    print("[DarkZsaid] SSH WebSocket Established")
    print("[DarkZsaid] 0.0.0.0:80 -> 127.0.0.1:22")
    print("[DarkZsaid] Response: HTTP/1.1 200 Connection established " + BRAND)

    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind((LISTEN_HOST, LISTEN_PORT))
    server.listen(500)

    while True:
        client, addr = server.accept()
        t = threading.Thread(target=handle_client, args=(client, addr))
        t.daemon = True
        t.start()

if __name__ == "__main__":
    main()
EOF

    chmod +x /opt/darkzsaid/ssh-ws-direct.py

    cat > /etc/systemd/system/ssh-ws.service <<'EOF'
[Unit]
Description=SSH WebSocket Python Direct Proxy Puerto 80 - DarkZsaid
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python2 /opt/darkzsaid/ssh-ws-direct.py
Restart=always
RestartSec=3
User=root
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

    ufw allow 80/tcp 2>/dev/null || true
    ufw allow 22/tcp 2>/dev/null || true

    systemctl daemon-reload
    systemctl enable ssh-ws
    systemctl restart ssh-ws

    echo ""
    echo -e "${VERDE}SSH WebSocket Established instalado correctamente.${RESET}"
    echo ""
    estado_ws_established
}

estado_ws_established() {
    titulo "ESTADO SSH-WS ESTABLISHED"

    echo "Servicio:"
    systemctl is-active ssh-ws 2>/dev/null || echo "inactive"

    echo ""
    echo "Puerto 80:"
    ss -tulnp | grep ':80' || echo "Puerto 80 no está escuchando"

    echo ""
    echo "Response configurado:"
    grep 'BRAND =' /opt/darkzsaid/ssh-ws-direct.py 2>/dev/null || echo "No instalado"

    echo ""
    echo "Datos para HTTP Custom:"
    echo "Host/IP: $(get_ip)"
    echo "Puerto: 80"
    echo "SSH Host: $(get_ip)"
    echo "SSH Puerto: 22"
    echo "Response: 200 Connection established"
    echo ""
    pausa
}

cambiar_marca_ws_established() {
    titulo "CAMBIAR MARCA SSH-WS"

    if [[ ! -f /opt/darkzsaid/ssh-ws-direct.py ]]; then
        echo "SSH-WS Established no está instalado."
        pausa
        return
    fi

    grep 'BRAND =' /opt/darkzsaid/ssh-ws-direct.py

    echo ""
    read -p "Nueva marca [ADM SJCC]: " NUEVA_MARCA
    NUEVA_MARCA=${NUEVA_MARCA:-ADM SJCC}

    sed -i 's/^BRAND = .*/BRAND = "'"$NUEVA_MARCA"'"/' /opt/darkzsaid/ssh-ws-direct.py

    systemctl restart ssh-ws

    echo ""
    echo "Marca actualizada:"
    grep 'BRAND =' /opt/darkzsaid/ssh-ws-direct.py
    pausa
}

menu_ws_established() {
    while true; do
        titulo "SSH WEBSOCKET ESTABLISHED 200"

        echo -e "${ROJO}[1]${RESET} ${AZUL}INSTALAR / REINSTALAR SSH-WS ESTABLISHED${RESET}"
        echo -e "${ROJO}[2]${RESET} ${AZUL}VER ESTADO${RESET}"
        echo -e "${ROJO}[3]${RESET} ${AZUL}VER LOGS${RESET}"
        echo -e "${ROJO}[4]${RESET} ${AZUL}CAMBIAR MARCA FINAL${RESET}"
        echo -e "${ROJO}[5]${RESET} ${AZUL}REINICIAR SERVICIO${RESET}"
        echo -e "${ROJO}[0]${RESET} ${BLANCO}VOLVER${RESET}"
        echo ""
        read -p "Opción: " op

        case "$op" in
            1) instalar_ws_established ;;
            2) estado_ws_established ;;
            3) journalctl -u ssh-ws -n 80 --no-pager -l; pausa ;;
            4) cambiar_marca_ws_established ;;
            5) systemctl restart ssh-ws; pausa ;;
            0) return ;;
            *) echo "Opción inválida"; sleep 1 ;;
        esac
    done
}

instalar_ws_established() {
    titulo "INSTALAR SSH-WS ESTABLISHED 200"

    systemctl stop gost-http80 2>/dev/null
    systemctl disable gost-http80 2>/dev/null

    systemctl stop squid 2>/dev/null
    systemctl disable squid 2>/dev/null

    systemctl stop nginx 2>/dev/null
    systemctl disable nginx 2>/dev/null
    systemctl mask nginx 2>/dev/null

    systemctl stop socks-python-ws@80 2>/dev/null
    systemctl disable socks-python-ws@80 2>/dev/null
    systemctl mask socks-python-ws@80 2>/dev/null

    systemctl stop socks-python2-ws 2>/dev/null
    systemctl disable socks-python2-ws 2>/dev/null

    systemctl stop ssh-ws 2>/dev/null
    systemctl disable ssh-ws 2>/dev/null
    systemctl unmask ssh-ws 2>/dev/null

    fuser -k 80/tcp 2>/dev/null
    sleep 2

    mkdir -p /opt/darkzsaid

    read -p "Marca final del response [ADM SJCC]: " MARCA_WS
    MARCA_WS=${MARCA_WS:-ADM SJCC}

    cat > /opt/darkzsaid/ssh-ws-direct.py <<PYEOF
#!/usr/bin/env python2
# -*- coding: utf-8 -*-

import socket
import threading
import select

LISTEN_HOST = "0.0.0.0"
LISTEN_PORT = 80

SSH_HOST = "127.0.0.1"
SSH_PORT = 22

BRAND = "$MARCA_WS"

def response_200():
    return (
        "HTTP/1.1 200 Connection established " + BRAND + "\\r\
"
        "\\r\
"
    )

def is_http_payload(data):
    if not data:
        return False

    d = data[:500].upper()

    if d.startswith("GET "):
        return True
    if d.startswith("POST "):
        return True
    if d.startswith("CONNECT "):
        return True
    if d.startswith("OPTIONS "):
        return True
    if d.startswith("HTTP/"):
        return True
    if "HOST:" in d:
        return True
    if "UPGRADE:" in d:
        return True
    if "HTTP/" in d:
        return True

    return False

def tunnel(client, remote):
    sockets = [client, remote]

    try:
        while True:
            readable, _, errors = select.select(sockets, [], sockets, 180)

            if errors:
                break

            if not readable:
                break

            for s in readable:
                data = s.recv(8192)

                if not data:
                    return

                if s is client:
                    remote.sendall(data)
                else:
                    client.sendall(data)
    except:
        pass

    try:
        client.close()
    except:
        pass

    try:
        remote.close()
    except:
        pass

def handle_client(client, addr):
    try:
        client.settimeout(15)

        try:
            first = client.recv(8192)
        except:
            first = ""

        client.sendall(response_200())

        remote = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        remote.settimeout(15)
        remote.connect((SSH_HOST, SSH_PORT))

        client.settimeout(None)
        remote.settimeout(None)

        if first and not is_http_payload(first):
            remote.sendall(first)

        tunnel(client, remote)

    except:
        try:
            client.close()
        except:
            pass

def main():
    print("[DarkZsaid] SSH WebSocket Established")
    print("[DarkZsaid] 0.0.0.0:80 -> 127.0.0.1:22")
    print("[DarkZsaid] Response: HTTP/1.1 200 Connection established " + BRAND)

    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind((LISTEN_HOST, LISTEN_PORT))
    server.listen(500)

    while True:
        client, addr = server.accept()
        t = threading.Thread(target=handle_client, args=(client, addr))
        t.daemon = True
        t.start()

if __name__ == "__main__":
    main()
PYEOF

    chmod +x /opt/darkzsaid/ssh-ws-direct.py

    cat > /etc/systemd/system/ssh-ws.service <<'EOFSERVICE'
[Unit]
Description=SSH WebSocket Python Direct Proxy Puerto 80 - DarkZsaid
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python2 /opt/darkzsaid/ssh-ws-direct.py
Restart=always
RestartSec=3
User=root
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOFSERVICE

    ufw allow 80/tcp 2>/dev/null || true
    ufw allow 22/tcp 2>/dev/null || true

    systemctl daemon-reload
    systemctl enable ssh-ws
    systemctl restart ssh-ws

    echo ""
    echo -e "${VERDE}SSH WebSocket Established instalado correctamente.${RESET}"
    echo ""
    estado_ws_established
}

estado_ws_established() {
    titulo "ESTADO SSH-WS ESTABLISHED"

    echo "Servicio:"
    systemctl is-active ssh-ws 2>/dev/null || echo "inactive"

    echo ""
    echo "Puerto 80:"
    ss -tulnp | grep ':80' || echo "Puerto 80 no está escuchando"

    echo ""
    echo "Response configurado:"
    grep 'BRAND =' /opt/darkzsaid/ssh-ws-direct.py 2>/dev/null || echo "No instalado"

    echo ""
    echo "Datos para HTTP Custom:"
    echo "Host/IP: $(get_ip)"
    echo "Puerto: 80"
    echo "SSH Host: $(get_ip)"
    echo "SSH Puerto: 22"
    echo "Response: HTTP/1.1 200 Connection established"
    echo ""
    pausa
}

cambiar_marca_ws_established() {
    titulo "CAMBIAR MARCA SSH-WS"

    if [[ ! -f /opt/darkzsaid/ssh-ws-direct.py ]]; then
        echo "SSH-WS Established no está instalado."
        pausa
        return
    fi

    grep 'BRAND =' /opt/darkzsaid/ssh-ws-direct.py

    echo ""
    read -p "Nueva marca [ADM SJCC]: " NUEVA_MARCA
    NUEVA_MARCA=${NUEVA_MARCA:-ADM SJCC}

    sed -i 's/^BRAND = .*/BRAND = "'"$NUEVA_MARCA"'"/' /opt/darkzsaid/ssh-ws-direct.py

    systemctl restart ssh-ws

    echo ""
    echo "Marca actualizada:"
    grep 'BRAND =' /opt/darkzsaid/ssh-ws-direct.py
    pausa
}



instalar_ssh_ws_permanente() {
    titulo "SOCKS PYTHON DIRECTO WS"

    echo "Este módulo usa el método permanente:"
    echo "SSH WebSocket Established 200 ADM SJCC"
    echo ""
    echo "Puerto público: 80"
    echo "Destino local: SSH 22"
    echo ""

    if systemctl is-active --quiet ssh-ws; then
        echo -e "${VERDE}Estado: ON${RESET}"
        echo ""
        ss -tulnp | grep ':80' || true
        pausa
        return
    fi

    echo "Estado: OFF"
    echo "Instalando / activando método permanente..."
    sleep 1

    if ! command -v python2 >/dev/null 2>&1; then
        echo "Python2 no está instalado. Instálalo antes de activar este módulo."
        echo "Comando recomendado:"
        echo "python2 --version"
        pausa
        return
    fi

    systemctl stop gost-http80 2>/dev/null
    systemctl disable gost-http80 2>/dev/null

    systemctl stop squid 2>/dev/null
    systemctl disable squid 2>/dev/null

    systemctl stop nginx 2>/dev/null
    systemctl disable nginx 2>/dev/null
    systemctl mask nginx 2>/dev/null

    systemctl stop socks-python-ws@80 2>/dev/null
    systemctl disable socks-python-ws@80 2>/dev/null
    systemctl mask socks-python-ws@80 2>/dev/null

    systemctl stop socks-python2-ws 2>/dev/null
    systemctl disable socks-python2-ws 2>/dev/null

    fuser -k 80/tcp 2>/dev/null
    sleep 2

    mkdir -p /opt/darkzsaid

    cat > /opt/darkzsaid/ssh-ws-direct.py <<'PYEOF'
#!/usr/bin/env python2
# -*- coding: utf-8 -*-

import socket
import threading
import select

LISTEN_HOST = "0.0.0.0"
LISTEN_PORT = 80

SSH_HOST = "127.0.0.1"
SSH_PORT = 22

BRAND = "ADM SJCC"

def response_200():
    return (
        "HTTP/1.1 200 Connection established " + BRAND + "\r
"
        "\r
"
    )

def is_http_payload(data):
    if not data:
        return False

    d = data[:500].upper()

    if d.startswith("GET "):
        return True
    if d.startswith("POST "):
        return True
    if d.startswith("CONNECT "):
        return True
    if d.startswith("OPTIONS "):
        return True
    if d.startswith("HTTP/"):
        return True
    if "HOST:" in d:
        return True
    if "UPGRADE:" in d:
        return True
    if "HTTP/" in d:
        return True

    return False

def tunnel(client, remote):
    sockets = [client, remote]

    try:
        while True:
            readable, _, errors = select.select(sockets, [], sockets, 180)

            if errors:
                break

            if not readable:
                break

            for s in readable:
                data = s.recv(8192)

                if not data:
                    return

                if s is client:
                    remote.sendall(data)
                else:
                    client.sendall(data)
    except:
        pass

    try:
        client.close()
    except:
        pass

    try:
        remote.close()
    except:
        pass

def handle_client(client, addr):
    try:
        client.settimeout(15)

        try:
            first = client.recv(8192)
        except:
            first = ""

        client.sendall(response_200())

        remote = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        remote.settimeout(15)
        remote.connect((SSH_HOST, SSH_PORT))

        client.settimeout(None)
        remote.settimeout(None)

        if first and not is_http_payload(first):
            remote.sendall(first)

        tunnel(client, remote)

    except:
        try:
            client.close()
        except:
            pass

def main():
    print("[DarkZsaid] Socks Python Directo WS")
    print("[DarkZsaid] 0.0.0.0:80 -> 127.0.0.1:22")
    print("[DarkZsaid] Response: HTTP/1.1 200 Connection established " + BRAND)

    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind((LISTEN_HOST, LISTEN_PORT))
    server.listen(500)

    while True:
        client, addr = server.accept()
        t = threading.Thread(target=handle_client, args=(client, addr))
        t.daemon = True
        t.start()

if __name__ == "__main__":
    main()
PYEOF

    chmod +x /opt/darkzsaid/ssh-ws-direct.py

    cat > /etc/systemd/system/ssh-ws.service <<'EOF'
[Unit]
Description=Socks Python Directo WS - Established 200 ADM SJCC
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python2 /opt/darkzsaid/ssh-ws-direct.py
Restart=always
RestartSec=3
User=root
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

    ufw allow 80/tcp 2>/dev/null || true
    ufw allow 22/tcp 2>/dev/null || true

    systemctl daemon-reload
    systemctl enable ssh-ws
    systemctl restart ssh-ws

    echo ""
    echo -e "${VERDE}SOCKS PYTHON DIRECTO WS activado correctamente.${RESET}"
    echo ""
    echo "Método: HTTP/1.1 200 Connection established ADM SJCC"
    echo "Puerto: 80"
    echo "Destino: SSH 22"
    echo ""
    ss -tulnp | grep ':80' || true
    pausa
}


menu_ssh_ws_permanente() {
    while true; do
        titulo "SOCKS PYTHON DIRECTO WS"

        echo -e "${ROJO}[1]${RESET} ${AZUL}ACTIVAR / INSTALAR PUERTO 80${RESET}"
        echo -e "${ROJO}[2]${RESET} ${AZUL}DETENER PUERTO 80${RESET}"
        echo -e "${ROJO}[3]${RESET} ${AZUL}REINICIAR PUERTO 80${RESET}"
        echo -e "${ROJO}[4]${RESET} ${AZUL}REMOVER PUERTO 80${RESET}"
        echo -e "${ROJO}[5]${RESET} ${AZUL}VER ESTADO${RESET}"
        echo -e "${ROJO}[6]${RESET} ${AZUL}VER LOGS${RESET}"
        echo -e "${ROJO}[0]${RESET} ${BLANCO}VOLVER${RESET}"
        echo ""
        read -p "Opción: " op

        case "$op" in
            1) instalar_ssh_ws_permanente ;;
            2) detener_ssh_ws_permanente ;;
            3) reiniciar_ssh_ws_permanente ;;
            4) remover_ssh_ws_permanente ;;
            5) estado_ssh_ws_permanente ;;
            6) journalctl -u ssh-ws -n 80 --no-pager -l; pausa ;;
            0) return ;;
            *) echo "Opción inválida"; sleep 1 ;;
        esac
    done
}

estado_ssh_ws_permanente() {
    titulo "ESTADO SOCKS PYTHON DIRECTO WS"

    echo "Servicio:"
    systemctl is-active ssh-ws 2>/dev/null || echo "inactive"

    echo ""
    echo "Puerto 80:"
    ss -tulnp | grep ':80' || echo "Puerto 80 no está escuchando"

    echo ""
    echo "Response:"
    grep 'Connection established' /opt/darkzsaid/ssh-ws-direct.py 2>/dev/null || echo "No instalado"

    echo ""
    echo "Datos:"
    echo "Host/IP: $(get_ip)"
    echo "Puerto: 80"
    echo "SSH Host: $(get_ip)"
    echo "SSH Puerto: 22"
    echo "Response: HTTP/1.1 200 Connection established ADM SJCC"
    pausa
}

detener_ssh_ws_permanente() {
    titulo "DETENER SOCKS PYTHON DIRECTO WS"

    systemctl stop ssh-ws 2>/dev/null

    echo "Servicio ssh-ws detenido."
    echo ""
    ss -tulnp | grep ':80' || echo "Puerto 80 libre."
    pausa
}

reiniciar_ssh_ws_permanente() {
    titulo "REINICIAR SOCKS PYTHON DIRECTO WS"

    systemctl restart ssh-ws 2>/dev/null

    echo "Servicio ssh-ws reiniciado."
    echo ""
    ss -tulnp | grep ':80' || echo "Puerto 80 no está escuchando."
    pausa
}

remover_ssh_ws_permanente() {
    titulo "REMOVER SOCKS PYTHON DIRECTO WS"

    read -p "¿Seguro que quieres remover el puerto 80 SSH-WS? [s/n]: " r

    if [[ "$r" != "s" && "$r" != "S" ]]; then
        echo "Cancelado."
        pausa
        return
    fi

    systemctl stop ssh-ws 2>/dev/null
    systemctl disable ssh-ws 2>/dev/null

    rm -f /etc/systemd/system/ssh-ws.service
    rm -f /opt/darkzsaid/ssh-ws-direct.py

    systemctl daemon-reload

    echo "SSH WebSocket removido."
    echo ""
    ss -tulnp | grep ':80' || echo "Puerto 80 libre."
    pausa
}

instalar_sockpython_200_establish() {
    clear
        echo -e "$RAYA"
    echo -e "${BLANCO}${BOLD}   SOCKS PYTHON DIRECTO OS / 200 ESTABLISH ADM SJCC - 200 ESTABLISH  ${RESET}"
        echo -e "$RAYA"
    echo ""

    echo -e "${CYAN}Configurando método WebSocket puerto 80...${RESET}"

    if [[ ! -f /opt/darkzsaid/ssh-ws-direct.py ]]; then
        echo -e "${ROJO}No existe /opt/darkzsaid/ssh-ws-direct.py${RESET}"
        echo ""
        read -p "Presiona ENTER para continuar..."
        return
    fi

    chmod +x /opt/darkzsaid/ssh-ws-direct.py

    cat > /etc/systemd/system/darkzsaid-ws80.service <<'EOSERVICE'
[Unit]
Description=DarkZsaid SSH WS Direct 200 Establish ADM SJCC
After=network.target ssh.service

[Service]
Type=simple
ExecStart=/usr/bin/python3 /opt/darkzsaid/ssh-ws-direct.py
Restart=always
RestartSec=3
User=root

[Install]
WantedBy=multi-user.target
EOSERVICE

    systemctl daemon-reload

    # Detener servicios que puedan usar puerto 80
    systemctl stop nginx 2>/dev/null || true
    systemctl disable nginx 2>/dev/null || true
    pkill -f "socks-python" 2>/dev/null || true
    pkill -f "ssh-ws-direct.py" 2>/dev/null || true

    ufw allow 80/tcp 2>/dev/null || true
    ufw reload 2>/dev/null || true

    systemctl enable darkzsaid-ws80 >/dev/null 2>&1
    systemctl restart darkzsaid-ws80

    sleep 2

    echo ""
    echo -e "${AMARILLO}Estado del servicio:${RESET}"
    systemctl is-active darkzsaid-ws80

    echo ""
    echo -e "${AMARILLO}Puerto 80:${RESET}"
    ss -tulnp | grep ':80' || echo "Puerto 80 no aparece activo."

    echo ""
    echo -e "${AMARILLO}Respuesta 200 Establish:${RESET}"
    echo -e "GET / HTTP/1.1\r
Host: test\r
\r
" | nc -w 2 127.0.0.1 80 2>/dev/null || true

    echo ""
    echo -e "${VERDE}Método activado correctamente.${RESET}"
    echo -e "${CYAN}Respuesta esperada:${RESET} HTTP/1.1 200 Connection established ADM SJCC"
    echo ""
    read -p "Presiona ENTER para continuar..."
}


# Ejecutar menú principal


# =========================================================
# 
estado_zivpn_panel() {
    if systemctl is-active --quiet zivpn 2>/dev/null || ss -H -ulnp 2>/dev/null | grep -q ":5667" || pgrep -af "zivpn" >/dev/null 2>&1; then
        echo -e "${CYAN}ON${RESET}"
    else
        echo -e "${ROJO}OFF${RESET}"
    fi
}

estado_udp_panel() {
    if ss -H -ulnp 2>/dev/null | grep -q ":36712" || pgrep -af "udp-custom|udpmod|udp-hysteria|hysteria" >/dev/null 2>&1; then
        echo -e "${CYAN}ON${RESET}"
    else
        echo -e "${ROJO}OFF${RESET}"
    fi
}

nombre_udp_panel() {
    local custom=0
    local hyst=0

    systemctl is-active --quiet udp-custom 2>/dev/null && custom=1
    systemctl is-active --quiet udpmod 2>/dev/null && hyst=1
    systemctl is-active --quiet udp-hysteria 2>/dev/null && hyst=1

    pgrep -af "udp-custom" >/dev/null 2>&1 && custom=1
    pgrep -af "udpmod|udp-hysteria|hysteria" >/dev/null 2>&1 && hyst=1

    if [[ "$custom" == "1" && "$hyst" == "1" ]]; then
        echo "UDP:CUST+HYST"
    elif [[ "$custom" == "1" ]]; then
        echo "UDP:CUSTOM"
    elif [[ "$hyst" == "1" ]]; then
        echo "UDP:HYST"
    else
        echo "UDP:36712"
    fi
}

MENU PRINCIPAL FINAL LIMPIO - DARKZSAID v1.0
# =========================================================

menu_principal() {
    while true; do
        clear

        # Logo superior
        if [[ -f /etc/darkzsaid/panel_logo.conf ]]; then
            source /etc/darkzsaid/panel_logo.conf
        fi

        PANEL_LOGO_TEXT="${PANEL_LOGO_TEXT:-DarkZsaid}"
        PANEL_VERSION="${PANEL_VERSION:-v1.0}"
        PANEL_AUTHOR="@DarkZsaid"

        echo -e "${CYAN}"
        toilet -f big "$PANEL_LOGO_TEXT" 2>/dev/null | sed '/^[[:space:]]*$/d' || figlet "$PANEL_LOGO_TEXT" 2>/dev/null | sed '/^[[:space:]]*$/d' || echo "$PANEL_LOGO_TEXT"
        echo -e "${RESET}"

RAYA="${CYAN}◆════════════════════════════════════════════════◆${RESET}"

        echo -e "$RAYA"
        printf "%b
" "${BLANCO}⚡ Gestor VPN/SSH by ${CYAN}${PANEL_AUTHOR}${RESET} ${AMARILLO}◆ ${PANEL_VERSION}${RESET}"
        echo -e "$RAYA"

        # Datos del sistema
        SO_INFO=$(lsb_release -ds 2>/dev/null | tr -d '"' || echo "Ubuntu")
        IP_INFO=$(curl -s --max-time 3 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
        CPU_INFO=$(nproc 2>/dev/null || echo "1")
        RAM_INFO=$(free -m | awk '/Mem:/ {print $7"Mi"}')
        FECHA_INFO=$(date '+%d/%m/%Y-%H:%M')
        UPTIME_INFO=$(uptime -p | sed 's/up //')

        echo -e "${CYAN} ◈${RESET} ${CYAN}SO:${RESET} ${BLANCO}${SO_INFO}${RESET} ${CYAN}◈${RESET} ${CYAN}IP:${RESET} ${CELESTE}${IP_INFO}${RESET}"
        echo -e "${CYAN} ◈${RESET} ${CYAN}CPU:${RESET} ${BLANCO}${CPU_INFO} cores${RESET}      ${CYAN}◈${RESET} ${CYAN}Fecha:${RESET} ${CELESTE}${FECHA_INFO}${RESET}"
        printf "%b
" "${CYAN} ◈ RAM:${RESET} ${BLANCO}${RAM_INFO}${RESET}"
        printf "%b
" "${CYAN} ◈ Up:${RESET} ${BLANCO}${UPTIME_INFO}${RESET}"
        echo -e "$RAYA"

        # Mostrar SOLO puertos activos
        PUERTOS_LINEAS=()

        puerto_activo() {
            local port="$1"
            ss -H -tulnp 2>/dev/null | grep -qE "[:.]${port}([[:space:]]|$)"
        }

        puerto_udp_activo() {
            local port="$1"
            ss -H -ulnp 2>/dev/null | grep -qE "[:.]${port}([[:space:]]|$)"
        }

        if puerto_activo 22; then
            PUERTOS_LINEAS+=("${CYAN} ◈${RESET} ${BLANCO}SSH:22${RESET} ${CYAN}◆ ON${RESET}")
        fi

        if puerto_activo 53; then
            PUERTOS_LINEAS+=("${CYAN} ◈${RESET} ${BLANCO}DNS:53${RESET} ${CYAN}◆ ON${RESET}")
        fi

        if puerto_activo 80; then
            PUERTOS_LINEAS+=("${CYAN} ◈${RESET} ${BLANCO}SOCKS:80${RESET} ${CYAN}◆ ON${RESET}")
        fi

        if puerto_activo 443; then
            PUERTOS_LINEAS+=("${CYAN} ◈${RESET} ${BLANCO}SSL:443${RESET} ${CYAN}◆ ON${RESET}")
        fi

        UDP_CUSTOM_ON=0
        UDP_HYST_ON=0

        systemctl is-active --quiet udp-custom 2>/dev/null && UDP_CUSTOM_ON=1
        systemctl is-active --quiet udpmod 2>/dev/null && UDP_HYST_ON=1
        systemctl is-active --quiet udp-hysteria 2>/dev/null && UDP_HYST_ON=1

        pgrep -af "udp-custom" >/dev/null 2>&1 && UDP_CUSTOM_ON=1
        pgrep -af "udpmod|udp-hysteria|hysteria" >/dev/null 2>&1 && UDP_HYST_ON=1

        if [[ "$UDP_CUSTOM_ON" == "1" ]]; then
            PUERTOS_LINEAS+=("${CYAN} ◈${RESET} ${BLANCO}UDP:CUSTOM${RESET} ${CYAN}◆ ON${RESET}")
        elif [[ "$UDP_HYST_ON" == "1" ]]; then
            PUERTOS_LINEAS+=("${CYAN} ◈${RESET} ${BLANCO}UDP:HYST${RESET} ${CYAN}◆ ON${RESET}")
        elif puerto_udp_activo 36712; then
            PUERTOS_LINEAS+=("${CYAN} ◈${RESET} ${BLANCO}UDP:36712${RESET} ${CYAN}◆ ON${RESET}")
        fi

        if systemctl is-active --quiet zivpn 2>/dev/null || puerto_udp_activo 5667 || pgrep -af "zivpn" >/dev/null 2>&1; then
            PUERTOS_LINEAS+=("${CYAN} ◈${RESET} ${BLANCO}ZIVPN:5667${RESET} ${CYAN}◆ ON${RESET}")
        fi

        if pgrep -af "badvpn|udpgw" >/dev/null 2>&1 || puerto_activo 7300 || puerto_activo 7200; then
            PUERTOS_LINEAS+=("${CYAN} ◈${RESET} ${BLANCO}BadVPN:7300${RESET} ${CYAN}◆ ON${RESET}")
        fi

        i=0
        total=${#PUERTOS_LINEAS[@]}
        while [[ $i -lt $total ]]; do
            left="${PUERTOS_LINEAS[$i]}"
            right=""

            if [[ $((i+1)) -lt $total ]]; then
                right="${PUERTOS_LINEAS[$((i+1))]}"
            fi

            if [[ -n "$right" ]]; then
                printf "%b
" "${left}        ${right}"
            else
                printf "%b
" "${left}"
            fi

            i=$((i+2))
        done

        echo -e "$RAYA"

        printf "%b
" "${BLANCO}<1>${RESET} ⚡ ${BLANCO}USUARIOS${RESET}          ${BLANCO}<2>${RESET} 📡 ${BLANCO}PROTOCOLOS${RESET}"
        printf "%b
" "${BLANCO}<3>${RESET} 🛠  ${BLANCO}HERRAMIENTAS${RESET}    ${BLANCO}<5>${RESET} ✚ ${BLANCO}PUERTOS${RESET}"
        printf "%b
" "${BLANCO}<6>${RESET} ◆  ${BLANCO}EXTRAS BOT${RESET}    ${BLANCO}<7>${RESET} ⚙ ${BLANCO}LOGO SUPERIOR${RESET}"
        printf "%b
" "${CYAN} ◈ Version: ${CYAN}${PANEL_VERSION}${RESET} ${CYAN}◈${RESET}"
        echo -e "$RAYA"

        printf "%b
" "${BLANCO}<08>${RESET} 💻 ${AMARILLO}ACTUALIZAR${RESET}      ${BLANCO}<9>${RESET} 🗑 ${ROJO}DESINSTALAR${RESET}"
        printf "%b
" "${BLANCO}<99>${RESET} 🔄 ${AMARILLO}REBOOT${RESET}"
        echo -e "$RAYA"

        printf "%b
" "${BLANCO}<0>${RESET} ❌ ${ROJO}SALIR${RESET}"
        echo -e "$RAYA"
        echo ""

        read -r -p "Opción: " op

        case "$op" in
            1|01)
                if [[ -f /opt/darkzsaid/menus/users_menu.sh ]]; then
                    bash /opt/darkzsaid/menus/users_menu.sh
                elif declare -F users_menu >/dev/null; then
                    users_menu
                elif declare -F menu_usuarios >/dev/null; then
                    menu_usuarios
                else
                    echo "No se encontró menú de usuarios."
                    read -p "ENTER..."
                fi
            ;;

            2|02)
                if declare -F menu_instaladores >/dev/null; then
                    menu_instaladores
                elif [[ -f /opt/darkzsaid/menus/protocolos_menu_completo.sh ]]; then
                    bash /opt/darkzsaid/menus/protocolos_menu_completo.sh
                elif [[ -f /opt/darkzsaid/menus/metodos_udp_menu.sh ]]; then
                    bash /opt/darkzsaid/menus/metodos_udp_menu.sh
                else
                    echo "No se encontró menú de protocolos."
                    read -p "ENTER..."
                fi
            ;;

            3|03)
                if declare -F menu_herramientas >/dev/null; then
                    menu_herramientas
                else
                    echo "No se encontró menú de herramientas."
                    read -p "ENTER..."
                fi
            ;;

            5|05)
                if declare -F menu_puertos >/dev/null; then
                    menu_puertos
                else
                    echo "No se encontró menú de puertos."
                    read -p "ENTER..."
                fi
            ;;

            6)
                bash /opt/darkzsaid/menus/extras_bot_banner_checkuser.sh
                ;;

            7|07)
                bash /opt/darkzsaid/menus/configurar_nombre_panel.sh 2>/dev/null || {
                    echo "No se encontró configurador de logo."
                    read -p "ENTER..."
                }
            ;;

            8|08)
                if [[ -f /opt/darkzsaid/darkzsaid-update.sh ]]; then
                    bash /opt/darkzsaid/darkzsaid-update.sh
                else
                    echo "Actualizador no encontrado."
                    read -p "ENTER..."
                fi
            ;;

            9|09)
                bash /opt/darkzsaid/menus/uninstall_darkzsaid.sh 2>/dev/null || {
                    echo "Desinstalador no encontrado."
                    read -p "ENTER..."
                }
            ;;

            99)
                reboot
            ;;

            0|00)
                clear
                exit 0
            ;;

            *)
                echo "Opción inválida."
                sleep 1
            ;;
        esac
    done
}
menu_principal

