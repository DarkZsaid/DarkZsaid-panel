#!/bin/bash

pantalla_limpia() {
    printf '\033c'
}


limpiar_pantalla() {
    printf '\033[H\033[2J\033[3J'
}

[[ -f /opt/darkzsaid/lib/puertas_reales.sh ]] && source /opt/darkzsaid/lib/puertas_reales.sh

ROJO="\e[31m"; VERDE="\e[32m"; AMARILLO="\e[33m"; AZUL="\e[34m"
CYAN="\e[36m"; BLANCO="\e[97m"; RESET="\e[0m"; BOLD="\e[1m"
IP="216.238.113.15"

titulo() {
    limpiar_pantalla
    echo -e "${CYAN}╔════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET}        ${BLANCO}${BOLD}⚡ DARKZSAID CONTROL ⚡${RESET}             ${CYAN}║${RESET}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${AMARILLO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${VERDE}        $1${RESET}"
    echo -e "${AMARILLO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
}


pausa(){ echo ""; read -p "Presiona ENTER para continuar..."; }
titulo(){ clear; echo -e "${ROJO}══════════════════════════ / / / ══════════════════════════${RESET}"; echo -e "${BLANCO}${BOLD}          $1${RESET}"; echo -e "${ROJO}══════════════════════════ / / / ══════════════════════════${RESET}"; echo ""; }

instalar_udpmod(){
    titulo "ACTIVAR / INSTALAR UDPMOD"

    apt update
    apt install -y git curl wget ufw iptables-persistent netfilter-persistent openssl

    systemctl stop udp-hysteria-appmods 2>/dev/null
    systemctl disable udp-hysteria-appmods 2>/dev/null
    systemctl stop udpmod 2>/dev/null

    rm -f /etc/systemd/system/udp-hysteria-appmods.service
    rm -f /usr/local/bin/udp-hysteria-appmods
    systemctl daemon-reload

    cd /opt || return
    rm -rf /opt/UDPMOD
    git clone https://github.com/rudi9999/UDPMOD.git /opt/UDPMOD

    chmod +x /opt/UDPMOD/* 2>/dev/null

    OBFS_CUSTOM="DarkZsaid"
    OBFS_CUSTOM="DarkZsaid"

    if [[ ! -f /opt/UDPMOD/udpmod.server.crt ]] || [[ ! -f /opt/UDPMOD/udpmod.server.key ]]; then
        openssl req -x509 -nodes -newkey rsa:2048 \
            -keyout /opt/UDPMOD/udpmod.server.key \
            -out /opt/UDPMOD/udpmod.server.crt \
            -subj "/CN=$IP" \
            -days 3650 >/dev/null 2>&1
    fi

    cat > /etc/udpmod/config.json <<JSON
{
  "listen": ":36712",
  "cert": "/opt/UDPMOD/udpmod.server.crt",
  "key": "/opt/UDPMOD/udpmod.server.key",
  "protocol": "udp",
  "up": "100 Mbps",
  "up_mbps": 100,
  "down": "100 Mbps",
  "down_mbps": 100,
  "disable_udp": false,
  "obfs": "$OBFS_CUSTOM",
  "auth": {
    "mode": "external",
    "config": {
      "cmd": "/opt/UDPMOD/autSSH"
    }
  }
}
JSON

    if [[ -f /opt/UDPMOD/hysteria-v1-linux-amd64 ]]; then
        BIN="/opt/UDPMOD/hysteria-v1-linux-amd64"
    elif [[ -f /opt/UDPMOD/hysteria-linux-amd64 ]]; then
        BIN="/opt/UDPMOD/hysteria-linux-amd64"
    elif [[ -f /opt/UDPMOD/hysteria-v2-linux-amd64 ]]; then
        BIN="/opt/UDPMOD/hysteria-v2-linux-amd64"
    else
        echo "No encontré binario Hysteria en /opt/UDPMOD."
        pausa
        return
    fi

    chmod +x "$BIN"
    chmod +x /opt/UDPMOD/autSSH 2>/dev/null

    cat > /etc/systemd/system/udpmod.service <<SERVICE
[Unit]
Description=UDPMOD Service BY DarkZsaid
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/UDPMOD
ExecStart=$BIN server -c /etc/udpmod/config.json
Restart=always
RestartSec=3
User=root
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
SERVICE

    ufw allow 22/tcp 2>/dev/null || true
    ufw allow 36712/udp 2>/dev/null || true
    ufw allow 20000:39999/udp 2>/dev/null || true
    ufw --force enable 2>/dev/null || true

    iptables -t nat -D PREROUTING -p udp --dport 20000:39999 -j REDIRECT --to-ports 36712 2>/dev/null
    iptables -t nat -A PREROUTING -p udp --dport 20000:39999 -j REDIRECT --to-ports 36712
    netfilter-persistent save 2>/dev/null || true

    systemctl daemon-reload
    systemctl enable udpmod
    bash /opt/darkzsaid/menus/fix_udpmod_permanente.sh 2>/dev/null || true
    systemctl restart udpmod
    bash /opt/darkzsaid/menus/sync_udpmod_users.sh 2>/dev/null || true

    bash /opt/darkzsaid/menus/sync_udpmod_users.sh 2>/dev/null || true
    echo -e "${VERDE}UDPMOD activado correctamente.${RESET}"
    pausa
}

detener_udpmod(){ titulo "DETENER UDPMOD"; systemctl stop udpmod 2>/dev/null; echo "UDPMOD detenido."; pausa; }
reiniciar_udpmod(){ titulo "REINICIAR UDPMOD"; bash /opt/darkzsaid/menus/fix_udpmod_permanente.sh 2>/dev/null || true
    systemctl restart udpmod 2>/dev/null; echo "UDPMOD reiniciado."; pausa; }
remover_udpmod(){
    titulo "REMOVER UDPMOD"
    read -p "¿Seguro que quieres remover UDPMOD? [s/n]: " r
    [[ "$r" != "s" && "$r" != "S" ]] && echo "Cancelado." && pausa && return
    systemctl stop udpmod 2>/dev/null
    systemctl disable udpmod 2>/dev/null
    rm -f /etc/systemd/system/udpmod.service
    rm -rf /opt/UDPMOD
    systemctl daemon-reload
    echo "UDPMOD removido."
    pausa
}
estado_udpmod(){
    titulo "ESTADO UDPMOD"
    echo "Servicio:"; systemctl is-active udpmod 2>/dev/null || echo "inactive"
    echo ""; echo "Puerto:"; ss -ulnp | grep 36712 || echo "36712 UDP no está escuchando."
    echo ""; echo "Redirección:"; iptables -t nat -S PREROUTING | grep 36712 || echo "Sin redirección."
    echo ""; echo "Config:"; cat /etc/udpmod/config.json 2>/dev/null || echo "No instalado."
    pausa
}

while true; do
    titulo "UDP-HYSTERIA APPMOD'S / UDPMOD"
    echo -e "${ROJO}[1]${RESET} ${AZUL}ACTIVAR / INSTALAR${RESET}"
    echo -e "${ROJO}[2]${RESET} ${AZUL}DETENER${RESET}"
    echo -e "${ROJO}[3]${RESET} ${AZUL}REINICIAR${RESET}"
    echo -e "${ROJO}[4]${RESET} ${AZUL}REMOVER${RESET}"
    echo -e "${ROJO}[5]${RESET} ${AZUL}VER ESTADO${RESET}"
    echo -e "${ROJO}[6]${RESET} ${AZUL}VER LOGS${RESET}"
    echo -e "${ROJO}[0]${RESET} ${BLANCO}VOLVER${RESET}"
    echo ""
    read -p "⚡ Opción: " op; printf '\033c'
    case "$op" in
        1) instalar_udpmod ;;
        2) detener_udpmod ;;
        3) reiniciar_udpmod ;;
        4) remover_udpmod ;;
        5) estado_udpmod ;;
        6) journalctl -u udpmod -n 80 --no-pager -l; pausa ;;
        0) exit 0 ;;
        *) echo "Opción inválida"; sleep 1 ;;
    esac
done
