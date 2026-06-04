#!/bin/bash

pantalla_limpia() {
    printf '\033c'
}


limpiar_pantalla() {
    printf '\033[H\033[2J\033[3J'
}

[[ -f /opt/darkzsaid/lib/ui.sh ]] && source /opt/darkzsaid/lib/ui.sh

titulo_udp() {
    limpiar_pantalla
    echo -e "${CYAN}╔════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET}        ${BLANCO}⚡ DARKZSAID CONTROL PANEL ⚡${RESET}     ${CYAN}║${RESET}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${AMARILLO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "           ${VERDE}PROTOCOLO UDP${RESET}"
    echo -e "${AMARILLO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
}

estado_service() {
    if systemctl is-active --quiet "$1" 2>/dev/null; then
        echo -e "${VERDE}[ON]${RESET}"
    else
        echo -e "${ROJO}[OFF]${RESET}"
    fi
}

abrir_udp_hysteria() {
    if [[ -f /opt/darkzsaid/menus/udp_hysteria_menu.sh ]]; then
        bash /opt/darkzsaid/menus/udp_hysteria_menu.sh
    elif declare -f menu_udp_hysteria >/dev/null 2>&1; then
        menu_udp_hysteria
    else
        limpiar_pantalla
        echo -e "${AMARILLO}UDP HYSTERIA todavía usa la opción antigua del panel.${RESET}"
        echo "No se encontró /opt/darkzsaid/menus/udp_hysteria_menu.sh"
        echo ""
        echo "Servicio: udpmod"
        echo "Estado: $(estado_service udpmod)"
        pausa_bonita
    fi
}

abrir_udp_custom() {
    if [[ -f /opt/darkzsaid/menus/udp_custom_menu.sh ]]; then
        bash /opt/darkzsaid/menus/udp_custom_menu.sh
    elif declare -f menu_udp_custom >/dev/null 2>&1; then
        menu_udp_custom
    else
        limpiar_pantalla
        echo -e "${AMARILLO}UDP CUSTOM todavía usa la opción antigua del panel.${RESET}"
        echo "No se encontró /opt/darkzsaid/menus/udp_custom_menu.sh"
        echo ""
        echo "Servicio: udp-custom"
        echo "Estado: $(estado_service udp-custom)"
        pausa_bonita
    fi
}

abrir_zivpn() {
    if [[ -f /opt/darkzsaid/menus/zivpn_menu.sh ]]; then
        bash /opt/darkzsaid/menus/zivpn_menu.sh
    else
        error_msg "No existe el menú ZIVPN."
        pausa_bonita
    fi
}

menu_metodos_udp() {
    while true; do
        titulo_udp

        echo -e "${ROJO}[01]${RESET} ${CYAN}➜${RESET} ${BLANCO}UDP HYSTERIA${RESET}                 $(estado_service udpmod)"
        echo -e "${ROJO}[02]${RESET} ${CYAN}➜${RESET} ${BLANCO}UDP CUSTOM${RESET}                   $(estado_service udp-custom)"
        echo -e "${ROJO}[03]${RESET} ${CYAN}➜${RESET} ${BLANCO}ZIVPN${RESET}                        $(estado_service zivpn)"
        echo ""
        echo -e "${ROJO}[00]${RESET} ${CYAN}➜${RESET} ${ROJO}[ VOLVER ]${RESET}"

        leer_opcion op "⚡ Opción: "

        case "$op" in
            1|01) abrir_udp_hysteria ;;
            2|02) abrir_udp_custom ;;
            3|03) abrir_zivpn ;;
            6|06)
                bash /opt/darkzsaid/menus/udpmod_users_menu.sh
            ;;

            0|00) return ;;
            *) opcion_invalida ;;
        esac
    done
}

menu_metodos_udp
