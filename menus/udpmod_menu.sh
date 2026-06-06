#!/bin/bash

BASE_DIR="/opt/darkzsaid"

ROJO="\033[1;31m"
VERDE="\033[1;32m"
AMARILLO="\033[1;33m"
AZUL="\033[1;34m"
CYAN="\033[1;36m"
BLANCO="\033[1;37m"
RESET="\033[0m"

limpiar(){
    printf '\033[H\033[2J\033[3J'
    clear 2>/dev/null || true
}

pausa(){
    echo
    read -rp "Presiona ENTER para continuar..."
}

titulo(){
    limpiar
    echo -e "${ROJO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "             ${BLANCO}UDP-HYSTERIA APPMOD'S / UDPMOD${RESET}"
    echo -e "${ROJO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo
}

estado_udpmod(){
    if systemctl is-active --quiet udpmod.service 2>/dev/null || \
       ss -H -ulnp 2>/dev/null | grep -q ':36712'; then
        echo -e "${VERDE}[ON]${RESET}"
    else
        echo -e "${ROJO}[OFF]${RESET}"
    fi
}

activar_udpmod(){
    titulo
    echo -e "${CYAN}➜ Activando / instalando UDP-Hysteria...${RESET}"

    if [ -x "$BASE_DIR/core/install_udpmod_motor.sh" ]; then
        bash "$BASE_DIR/core/install_udpmod_motor.sh"
    else
        echo -e "${AMARILLO}No existe instalador independiente. Usando instalación básica...${RESET}"

        mkdir -p /opt/UDPMOD /etc/udpmod

        if [ -f "$BASE_DIR/files/udpmod/hysteria-linux-amd64" ]; then
            cp -f "$BASE_DIR/files/udpmod/hysteria-linux-amd64" /opt/UDPMOD/hysteria-linux-amd64
            chmod +x /opt/UDPMOD/hysteria-linux-amd64
        fi

        if [ ! -f /etc/udpmod/config.json ]; then
cat > /etc/udpmod/config.json <<JSON
{
  "listen": ":36712",
  "protocol": "udp",
  "obfs": "DarkZsaid",
  "auth": {
    "type": "password",
    "password": "DarkZsaid"
  }
}
JSON
        fi

cat > /etc/systemd/system/udpmod.service <<SERVICE
[Unit]
Description=DarkZsaid UDPMod Hysteria v1 36712
After=network.target

[Service]
Type=simple
ExecStart=/opt/UDPMOD/hysteria-linux-amd64 server -c /etc/udpmod/config.json
Restart=always
RestartSec=3
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
SERVICE

        ufw allow 36712/udp 2>/dev/null || true
        iptables -I INPUT -p udp --dport 36712 -j ACCEPT 2>/dev/null || true
        iptables -t nat -C PREROUTING -p udp --dport 20000:39999 -j REDIRECT --to-ports 36712 2>/dev/null || \
        iptables -t nat -A PREROUTING -p udp --dport 20000:39999 -j REDIRECT --to-ports 36712 2>/dev/null || true

        systemctl daemon-reload
        systemctl enable udpmod.service >/dev/null 2>&1 || true
        systemctl restart udpmod.service
    fi

    echo
    echo -e "Estado: $(estado_udpmod)"
    pausa
}

detener_udpmod(){
    titulo
    systemctl stop udpmod.service 2>/dev/null || true
    pkill -f "hysteria-linux-amd64" 2>/dev/null || true
    echo -e "${AMARILLO}UDPMOD detenido.${RESET}"
    echo -e "Estado: $(estado_udpmod)"
    pausa
}

reiniciar_udpmod(){
    titulo
    systemctl restart udpmod.service 2>/dev/null || true
    sleep 2
    echo -e "${VERDE}UDPMOD reiniciado.${RESET}"
    echo -e "Estado: $(estado_udpmod)"
    pausa
}

remover_udpmod(){
    titulo
    read -rp "¿Seguro que quieres remover UDPMOD? [s/n]: " r
    [[ "$r" != "s" && "$r" != "S" ]] && return

    systemctl stop udpmod.service 2>/dev/null || true
    systemctl disable udpmod.service 2>/dev/null || true
    rm -f /etc/systemd/system/udpmod.service
    systemctl daemon-reload
    echo -e "${ROJO}UDPMOD removido.${RESET}"
    pausa
}

ver_estado_udpmod(){
    titulo
    echo -e "${CYAN}Servicio:${RESET}"
    systemctl is-active udpmod.service 2>/dev/null || echo "inactive"

    echo
    echo -e "${CYAN}Puerto 36712:${RESET}"
    ss -ulnp | grep ':36712' || echo "36712 no escucha"

    echo
    echo -e "${CYAN}Redirección:${RESET}"
    iptables -t nat -S PREROUTING 2>/dev/null | grep 36712 || echo "Sin redirección"

    echo
    echo -e "${CYAN}Config:${RESET}"
    cat /etc/udpmod/config.json 2>/dev/null || echo "No existe config.json"

    pausa
}

usuarios_udpmod(){
    if [ -f "$BASE_DIR/menus/udpmod_users_menu.sh" ]; then
        bash "$BASE_DIR/menus/udpmod_users_menu.sh"
    else
        titulo
        echo -e "${ROJO}No existe el centro de usuarios:${RESET}"
        echo "$BASE_DIR/menus/udpmod_users_menu.sh"
        echo
        echo "Buscando archivos parecidos..."
        find "$BASE_DIR/menus" -maxdepth 1 -type f | grep -Ei 'udpmod.*user|users.*udp|usuarios.*udp|sync_udpmod' || true
        pausa
    fi
}

ver_logs_udpmod(){
    titulo
    journalctl -u udpmod.service --no-pager -n 60
    pausa
}

while true; do
    titulo
    echo -e "${ROJO}[1]${RESET} ${BLANCO}ACTIVAR / INSTALAR${RESET}     $(estado_udpmod)"
    echo -e "${ROJO}[2]${RESET} ${BLANCO}DETENER${RESET}"
    echo -e "${ROJO}[3]${RESET} ${BLANCO}REINICIAR${RESET}"
    echo -e "${ROJO}[4]${RESET} ${BLANCO}REMOVER${RESET}"
    echo -e "${ROJO}[5]${RESET} ${BLANCO}VER ESTADO${RESET}"
    echo -e "${ROJO}[6]${RESET} ${BLANCO}USUARIOS UDP-HYSTERIA${RESET}"
    echo -e "${ROJO}[7]${RESET} ${BLANCO}VER LOGS${RESET}"
    echo
    echo -e "${ROJO}[0]${RESET} ${BLANCO}VOLVER${RESET}"
    echo
    read -rp "⚡ Opción: " op

    case "$op" in
        1|01) activar_udpmod ;;
        2|02) detener_udpmod ;;
        3|03) reiniciar_udpmod ;;
        4|04) remover_udpmod ;;
        5|05) ver_estado_udpmod ;;
        6|06) usuarios_udpmod ;;
        7|07) ver_logs_udpmod ;;
        0|00) break ;;
        *) echo "Opción inválida"; sleep 1 ;;
    esac
done
