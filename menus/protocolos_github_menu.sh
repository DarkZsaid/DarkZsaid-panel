#!/bin/bash

BASE_DIR="/opt/darkzsaid"

ROJO="\033[1;31m"
VERDE="\033[1;32m"
CYAN="\033[1;36m"
BLANCO="\033[1;37m"
RESET="\033[0m"

limpiar(){
    printf '\033[H\033[2J\033[3J'
    clear 2>/dev/null || true
}

on(){ echo -e "${VERDE}[ON]${RESET}"; }
off(){ echo -e "${ROJO}[OFF]${RESET}"; }

estado_udp_hyst(){
    if systemctl is-active --quiet udpmod.service 2>/dev/null; then
        on
    else
        off
    fi
}

estado_udp_custom(){
    if systemctl is-active --quiet udp-custom.service 2>/dev/null; then
        on
    else
        off
    fi
}

estado_zivpn(){
    if systemctl is-active --quiet sipvpn-activex.service 2>/dev/null || \
       systemctl is-active --quiet zivpn.service 2>/dev/null || \
       ss -H -ulnp 2>/dev/null | grep -q ':5667'; then
        on
    else
        off
    fi
}

estado_dropbear(){
    if systemctl is-active --quiet dropbear.service 2>/dev/null || ss -H -tlnp 2>/dev/null | grep -Eq ':109|:143'; then
        on
    else
        off
    fi
}

estado_stunnel(){
    if systemctl is-active --quiet stunnel4.service 2>/dev/null || ss -H -tlnp 2>/dev/null | grep -q ':443'; then
        on
    else
        off
    fi
}

estado_badvpn(){
    if systemctl is-active --quiet badvpn-udpgw.service 2>/dev/null || ss -H -ulnp 2>/dev/null | grep -Eq ':7200|:7300'; then
        on
    else
        off
    fi
}

estado_xui(){
    if systemctl is-active --quiet x-ui.service 2>/dev/null || systemctl is-active --quiet xui.service 2>/dev/null; then
        on
    else
        off
    fi
}

abrir(){
    local archivo="$1"
    if [ -f "$BASE_DIR/$archivo" ]; then
        bash "$BASE_DIR/$archivo"
    else
        echo "No existe $BASE_DIR/$archivo"
        read -rp "Presiona ENTER para volver..."
    fi
}

while true; do
    limpiar
    echo -e "${CYAN}╔══════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET}     ⚡ ${BLANCO}INSTALADORES & PROTOCOLOS OFICIAL${RESET} ⚡     ${CYAN}║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════╝${RESET}"
    echo

    printf "${ROJO}[01]${RESET} ${BLANCO}ABRIR PUERTOS RECOMENDADOS${RESET}\n"
    printf "${ROJO}[02]${RESET} ${BLANCO}UDP-HYSTERIA APPMOD'S / UDPMOD${RESET}        %b\n" "$(estado_udp_hyst)"
    printf "${ROJO}[03]${RESET} ${BLANCO}UDP-CUSTOM${RESET}                              %b\n" "$(estado_udp_custom)"
    printf "${ROJO}[04]${RESET} ${BLANCO}ZIVPN${RESET}                                   %b\n" "$(estado_zivpn)"
    printf "${ROJO}[05]${RESET} ${BLANCO}SOCKS PYTHON DIRECTO WS${RESET}\n"
    printf "${ROJO}[06]${RESET} ${BLANCO}DROPBEAR${RESET}                                %b\n" "$(estado_dropbear)"
    printf "${ROJO}[07]${RESET} ${BLANCO}STUNNEL SSL${RESET}                             %b\n" "$(estado_stunnel)"
    printf "${ROJO}[08]${RESET} ${BLANCO}BADVPN UDPGW${RESET}                            %b\n" "$(estado_badvpn)"
    printf "${ROJO}[09]${RESET} ${BLANCO}PANEL WEB 3X-UI${RESET}                         %b\n" "$(estado_xui)"
    echo
    printf "${ROJO}[00]${RESET} ${BLANCO}VOLVER${RESET}\n"
    echo
    read -rp "Opción: " op

    case "$op" in
        1|01)
            for p in 22 53 80 90 109 143 443 8080 8082 8084 8086; do
                ufw allow "$p" 2>/dev/null || true
            done
            echo "Puertos recomendados aplicados."
            read -rp "Presiona ENTER para continuar..."
        ;;
        2|02) abrir "menus/udpmod_menu.sh" ;;
        3|03) abrir "menus/udp_custom_menu.sh" ;;
        4|04) abrir "menus/zivpn_menu.sh" ;;
        5|05) abrir "menus/socks_ws_menu.sh" ;;
        6|06) abrir "menus/dropbear_menu.sh" ;;
        7|07) abrir "menus/stunnel_menu.sh" ;;
        8|08) abrir "menus/badvpn_menu.sh" ;;
        9|09) abrir "menus/xui_menu.sh" ;;
        0|00) exit 0 ;;
        *) echo "Opción inválida"; sleep 1 ;;
    esac
done
