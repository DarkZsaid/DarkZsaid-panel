#!/bin/bash

BASE_DIR="/opt/darkzsaid"

ROJO="\e[31m"
VERDE="\e[32m"
AMARILLO="\e[33m"
AZUL="\e[34m"
CYAN="\e[36m"
BLANCO="\e[97m"
RESET="\e[0m"

limpiar() {
    clear 2>/dev/null || true
}

pausa() {
    echo
    read -rp "Presiona ENTER para continuar..."
}

titulo() {
    limpiar
    echo -e "${CYAN}╔════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET}        ⚡ ${BLANCO}DARKZSAID PROTOCOLOS MODULAR${RESET} ⚡        ${CYAN}║${RESET}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════╝${RESET}"
    echo
}

onoff() {
    if [[ "$1" == "1" ]]; then
        echo -e "${VERDE}[ON]${RESET}"
    else
        echo -e "${ROJO}[OFF]${RESET}"
    fi
}

svc_on() {
    systemctl is-active --quiet "$1" 2>/dev/null
}

port_on_tcp() {
    ss -tulnp 2>/dev/null | grep -qE "[:.]$1[[:space:]]"
}

port_on_udp() {
    ss -tulnp 2>/dev/null | grep -qE "[:.]$1[[:space:]]"
}

proc_on() {
    pgrep -af "$1" >/dev/null 2>&1
}

estado_udpmod() {
    # UDP-Hysteria solo debe depender del servicio udpmod o proceso hysteria,
    # no del puerto 36712, porque otro UDP podría confundir el estado.
    if svc_on udpmod.service || proc_on "hysteria-linux-amd64"; then
        onoff 1
    else
        onoff 0
    fi
}

estado_udpcustom() {
    # UDP-Custom queda separado en puerto 8081.
    if svc_on udp-custom.service || port_on_udp 8081 || proc_on "/usr/bin/udp|udp server"; then
        onoff 1
    else
        onoff 0
    fi
}

estado_zivpn() {
    if svc_on sipvpn-activex.service || svc_on zivpn.service || port_on_udp 5667 || proc_on "ZiVPN|zivpn"; then
        onoff 1
    else
        onoff 0
    fi
}

estado_dropbear() {
    if svc_on dropbear.service || port_on_tcp 109 || port_on_tcp 143 || proc_on "dropbear"; then
        onoff 1
    else
        onoff 0
    fi
}

estado_stunnel() {
    if svc_on stunnel4.service || svc_on stunnel.service || port_on_tcp 443 || proc_on "stunnel"; then
        onoff 1
    else
        onoff 0
    fi
}

estado_badvpn() {
    if svc_on badvpn.service || port_on_udp 7300 || port_on_udp 7200 || proc_on "badvpn|udpgw"; then
        onoff 1
    else
        onoff 0
    fi
}

ejecutar_local() {
    local archivo="$1"

    if [[ -f "$BASE_DIR/$archivo" ]]; then
        chmod +x "$BASE_DIR/$archivo" 2>/dev/null || true
        bash "$BASE_DIR/$archivo"
    else
        echo -e "${ROJO}No existe:${RESET} $BASE_DIR/$archivo"
        pausa
    fi
}

abrir_puertos_recomendados() {
    titulo
    echo -e "${AMARILLO}Abriendo puertos recomendados DarkZsaid...${RESET}"
    echo

    iptables -I INPUT -p tcp --dport 22 -j ACCEPT 2>/dev/null || true
    iptables -I INPUT -p tcp --dport 53 -j ACCEPT 2>/dev/null || true
    iptables -I INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null || true
    iptables -I INPUT -p tcp --dport 90 -j ACCEPT 2>/dev/null || true
    iptables -I INPUT -p tcp --dport 109 -j ACCEPT 2>/dev/null || true
    iptables -I INPUT -p tcp --dport 143 -j ACCEPT 2>/dev/null || true
    iptables -I INPUT -p tcp --dport 443 -j ACCEPT 2>/dev/null || true
    iptables -I INPUT -p tcp --dport 8080 -j ACCEPT 2>/dev/null || true
    iptables -I INPUT -p tcp --dport 8082 -j ACCEPT 2>/dev/null || true
    iptables -I INPUT -p tcp --dport 8084 -j ACCEPT 2>/dev/null || true
    iptables -I INPUT -p tcp --dport 8086 -j ACCEPT 2>/dev/null || true

    iptables -I INPUT -p udp --dport 5667 -j ACCEPT 2>/dev/null || true
    iptables -I INPUT -p udp --dport 36712 -j ACCEPT 2>/dev/null || true
    iptables -I INPUT -p udp --dport 7200 -j ACCEPT 2>/dev/null || true
    iptables -I INPUT -p udp --dport 7300 -j ACCEPT 2>/dev/null || true
    iptables -I INPUT -p udp --dport 10000:65000 -j ACCEPT 2>/dev/null || true

    if command -v netfilter-persistent >/dev/null 2>&1; then
        netfilter-persistent save >/dev/null 2>&1 || true
    elif command -v iptables-save >/dev/null 2>&1; then
        mkdir -p /etc/iptables
        iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
    fi

    echo -e "${VERDE}✓ Puertos recomendados aplicados.${RESET}"
    echo
    echo -e "${CYAN}TCP:${RESET} 22,53,80,90,109,143,443,8080,8082,8084,8086"
    echo -e "${CYAN}UDP:${RESET} 5667,36712,7200,7300,10000:65000"
    pausa
}

while true; do
    titulo

    echo -e "${ROJO}[01]${RESET} ${BLANCO}ABRIR PUERTOS RECOMENDADOS${RESET}"
    echo -e "${ROJO}[02]${RESET} ${BLANCO}UDP-HYSTERIA APPMOD'S / UDPMOD${RESET}        $(estado_udpmod)"
    echo -e "${ROJO}[03]${RESET} ${BLANCO}UDP-CUSTOM${RESET}                             $(estado_udpcustom)"
    echo -e "${ROJO}[04]${RESET} ${BLANCO}ZIVPN${RESET}                                  $(estado_zivpn)"
    echo -e "${ROJO}[05]${RESET} ${BLANCO}SOCKS PYTHON DIRECTO WS${RESET}"
    echo -e "${ROJO}[06]${RESET} ${BLANCO}DROPBEAR${RESET}                               $(estado_dropbear)"
    echo -e "${ROJO}[07]${RESET} ${BLANCO}STUNNEL SSL${RESET}                            $(estado_stunnel)"
    echo -e "${ROJO}[08]${RESET} ${BLANCO}BADVPN UDPGW${RESET}                           $(estado_badvpn)"
    echo -e "${ROJO}[09]${RESET} ${BLANCO}PANEL WEB 3X-UI${RESET}"
    echo
    echo -e "${ROJO}[00]${RESET} ${BLANCO}VOLVER${RESET}"
    echo
    read -rp "Opción: " op

    case "$op" in
        1|01)
            abrir_puertos_recomendados
            ;;
        2|02)
            ejecutar_local "menus/udp_hysteria_menu.sh"
            ;;
        3|03)
            ejecutar_local "menus/udp_custom_menu.sh"
            ;;
        4|04)
            ejecutar_local "menus/zivpn_menu.sh"
            ;;
        5|05)
            ejecutar_local "menus/socks_ws_menu.sh"
            ;;
        6|06)
            ejecutar_local "menus/dropbear_menu.sh"
            ;;
        7|07)
            ejecutar_local "menus/stunnel_menu.sh"
            ;;
        8|08)
            ejecutar_local "menus/badvpn_menu.sh"
            ;;
        9|09)
            ejecutar_local "menus/protocolos_menu_completo.sh"
            ;;
        0|00)
            exit 0
            ;;
        *)
            echo -e "${ROJO}Opción inválida.${RESET}"
            sleep 1
            ;;
    esac
done
