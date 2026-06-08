#!/bin/bash

BASE_DIR="/opt/darkzsaid"
SERVICE="darkzsaid-checkuser"
PORT_DEFAULT="2095"

ROJO="\033[1;31m"
VERDE="\033[1;32m"
AMARILLO="\033[1;33m"
AZUL="\033[1;34m"
CYAN="\033[1;36m"
BLANCO="\033[1;37m"
RESET="\033[0m"

get_ip(){
    curl -4 -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}'
}

pausa(){
    echo
    read -rp "Presiona ENTER para continuar..."
}

crear_servicio_checkuser(){
    local puerto="$1"
    [ -z "$puerto" ] && puerto="$PORT_DEFAULT"

    mkdir -p "$BASE_DIR/checkuser"

    if [ ! -f "$BASE_DIR/checkuser/checkuser_server.py" ]; then
        echo -e "${ROJO}✗ No existe $BASE_DIR/checkuser/checkuser_server.py${RESET}"
        pausa
        return 1
    fi

    chmod +x "$BASE_DIR/checkuser/checkuser_server.py" 2>/dev/null || true

    cat > "/etc/systemd/system/${SERVICE}.service" <<EOF2
[Unit]
Description=DarkZsaid CheckUser API
After=network.target

[Service]
Type=simple
WorkingDirectory=${BASE_DIR}
Environment=CHECKUSER_PORT=${puerto}
ExecStart=/usr/bin/python3 ${BASE_DIR}/checkuser/checkuser_server.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF2

    systemctl daemon-reload
    systemctl enable "$SERVICE" >/dev/null 2>&1 || true

    ufw allow "${puerto}/tcp" >/dev/null 2>&1 || true
    iptables -I INPUT -p tcp --dport "$puerto" -j ACCEPT 2>/dev/null || true

    systemctl restart "$SERVICE"
    sleep 1
}

estado_checkuser(){
    clear
    echo -e "${CYAN}════════════════════════════════════════${RESET}"
    echo -e "          ${BLANCO}ACTIVADOR CHECKUSER${RESET}"
    echo -e "${CYAN}════════════════════════════════════════${RESET}"
    echo

    local puerto
    puerto=$(grep -m1 '^Environment=CHECKUSER_PORT=' "/etc/systemd/system/${SERVICE}.service" 2>/dev/null | cut -d= -f3)
    [ -z "$puerto" ] && puerto="$PORT_DEFAULT"

    if systemctl is-active --quiet "$SERVICE"; then
        echo -e "${BLANCO}Estado:${RESET} ${VERDE}ON${RESET}"
    else
        echo -e "${BLANCO}Estado:${RESET} ${ROJO}OFF${RESET}"
    fi

    echo -e "${BLANCO}Puerto:${RESET} $puerto"
    echo -e "${BLANCO}URL:${RESET} http://$(get_ip):${puerto}/"
    echo

    echo -e "${AMARILLO}Respuesta local:${RESET}"
    curl -s "http://127.0.0.1:${puerto}/" 2>/dev/null | head -15 || echo "No responde local"
    echo
    pausa
}

while true; do
    clear
    echo -e "${CYAN}════════════════════════════════════════${RESET}"
    echo -e "          ${BLANCO}ACTIVADOR CHECKUSER${RESET}"
    echo -e "${CYAN}════════════════════════════════════════${RESET}"
    echo
    echo -e "${ROJO}[01]${RESET} ➜ ${BLANCO}ACTIVAR / INSTALAR CHECKUSER${RESET}"
    echo -e "${ROJO}[02]${RESET} ➜ ${BLANCO}DETENER CHECKUSER${RESET}"
    echo -e "${ROJO}[03]${RESET} ➜ ${BLANCO}REINICIAR CHECKUSER${RESET}"
    echo -e "${ROJO}[04]${RESET} ➜ ${BLANCO}VER ESTADO / URL${RESET}"
    echo -e "${ROJO}[00]${RESET} ➜ ${ROJO}VOLVER${RESET}"
    echo
    read -rp "Opción: " op

    case "$op" in
        1|01)
            read -rp "Puerto CheckUser [2095]: " puerto
            [ -z "$puerto" ] && puerto="$PORT_DEFAULT"

            if ! [[ "$puerto" =~ ^[0-9]+$ ]]; then
                echo -e "${ROJO}Puerto inválido${RESET}"
                sleep 1
                continue
            fi

            crear_servicio_checkuser "$puerto"

            if systemctl is-active --quiet "$SERVICE"; then
                echo -e "${VERDE}✓ CheckUser activo${RESET}"
                echo -e "${BLANCO}URL:${RESET} http://$(get_ip):${puerto}/"
            else
                echo -e "${ROJO}✗ CheckUser no levantó${RESET}"
                journalctl -u "$SERVICE" --no-pager -n 20
            fi
            pausa
            ;;
        2|02)
            systemctl stop "$SERVICE" 2>/dev/null || true
            echo -e "${AMARILLO}CheckUser detenido${RESET}"
            pausa
            ;;
        3|03)
            systemctl restart "$SERVICE" 2>/dev/null || true
            echo -e "${VERDE}CheckUser reiniciado${RESET}"
            pausa
            ;;
        4|04)
            estado_checkuser
            ;;
        0|00)
            exit 0
            ;;
        *)
            echo "Opción inválida"
            sleep 1
            ;;
    esac
done
