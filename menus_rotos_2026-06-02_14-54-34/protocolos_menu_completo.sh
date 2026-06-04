#!/bin/bash

pantalla_limpia() {
    printf '\033c'
}


limpiar_pantalla() {
    printf '\033[H\033[2J\033[3J'
}


ROJO="\e[31m"
VERDE="\e[32m"
AMARILLO="\e[33m"
AZUL="\e[34m"
CYAN="\e[36m"
BLANCO="\e[97m"
RESET="\e[0m"

estado_servicio() {
    local svc="$1"
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
        echo -e "${VERDE}[ON]${RESET}"
    else
        echo -e "${ROJO}[OFF]${RESET}"
    fi
}

estado_puerto() {
    local port="$1"
    if ss -tulnp 2>/dev/null | grep -qE "(:${port}[[:space:]]|:${port}$)"; then
        echo -e "${VERDE}[ON]${RESET}"
    else
        echo -e "${ROJO}[OFF]${RESET}"
    fi
}

titulo_protocolos() {
    limpiar_pantalla
    echo -e "${CYAN}◆══════════════════════════════════════════════◆${RESET}"
    echo -e "${BLANCO}        ⚡ INSTALADORES & PROTOCOLOS ⚡${RESET}"
    echo -e "${CYAN}◆══════════════════════════════════════════════◆${RESET}"
    echo ""
}

while true; do
    titulo_protocolos

    echo -e "${ROJO}[01]${RESET} ${AZUL}ABRIR PUERTOS RECOMENDADOS${RESET}"
    echo -e "${ROJO}[02]${RESET} ${AZUL}UDP-HYSTERIA APPMOD'S / UDPMOD${RESET}   $(estado_servicio udpmod)"
    echo -e "${ROJO}[03]${RESET} ${AZUL}UDP-CUSTOM${RESET}                       $(estado_servicio udp-custom)"
    echo -e "${ROJO}[04]${RESET} ${AZUL}ZIVPN${RESET}                            $(estado_servicio zivpn)"
    echo -e "${ROJO}[05]${RESET} ${AZUL}SOCKS PYTHON DIRECTO WS${RESET}"
    echo -e "${ROJO}[06]${RESET} ${AZUL}DROPBEAR${RESET}                         $(estado_servicio dropbear)"
    echo -e "${ROJO}[07]${RESET} ${AZUL}STUNNEL SSL${RESET}                      $(estado_puerto 443)"
    echo -e "${ROJO}[08]${RESET} ${AZUL}BADVPN UDPGW${RESET}                     $(estado_puerto 7300)"
    echo -e "${ROJO}[09]${RESET} ${AZUL}PANEL WEB 3X-UI${RESET}                  $(estado_servicio x-ui)"
    echo -e "${ROJO}[00]${RESET} ${BLANCO}VOLVER${RESET}"
    echo ""
    read -p "Opción: " op; printf '\033c'

    case "$op" in
        1|01)
            ufw allow 22/tcp 2>/dev/null || true
            ufw allow 53/tcp 2>/dev/null || true
            ufw allow 53/udp 2>/dev/null || true
            ufw allow 80/tcp 2>/dev/null || true
            ufw allow 443/tcp 2>/dev/null || true
            ufw allow 36712/udp 2>/dev/null || true
            ufw allow 5667/udp 2>/dev/null || true
            ufw allow 7200/udp 2>/dev/null || true
            ufw allow 7300/udp 2>/dev/null || true
            echo -e "${VERDE}Puertos recomendados abiertos.${RESET}"
            read -p "ENTER..."
        ;;

        2|02)
            bash /opt/darkzsaid/menus/udp_hysteria_menu.sh
        ;;

        3|03)
            bash /opt/darkzsaid/menus/udp_custom_menu.sh
        ;;

        4|04)
            bash /opt/darkzsaid/menus/zivpn_menu.sh
        ;;

        5|05)
            bash /opt/darkzsaid/menus/socks_ws_menu.sh
        ;;

        6|06)
            bash /opt/darkzsaid/menus/dropbear_menu.sh
        ;;

        7|07)
            bash /opt/darkzsaid/menus/stunnel_menu.sh
        ;;

        8|08)
            bash /opt/darkzsaid/menus/badvpn_menu.sh
        ;;

        9|09)
            bash /opt/darkzsaid/menus/xui_menu.sh
        ;;

        0|00)
            exit 0
        ;;

        *)
            echo "Opción inválida."
            sleep 1
        ;;
    esac
done
