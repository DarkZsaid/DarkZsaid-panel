#!/bin/bash

limpiar_pantalla() {
    printf '\033[H\033[2J\033[3J'
}


source /opt/darkzsaid/menus/ui_instalacion.sh 2>/dev/null || true

VERDE="\e[32m"
ROJO="\e[31m"
AMARILLO="\e[33m"
CYAN="\e[36m"
BLANCO="\e[97m"
RESET="\e[0m"

pausa_udp_custom() {
    echo ""
    read -p "Presiona ENTER para continuar..."
}

estado_udp_custom() {
    titulo_instalacion "UDP CUSTOM HTTP"

    if systemctl is-active --quiet udp-custom 2>/dev/null; then
        ok "Servicio udp-custom activo"
    else
        fail "Servicio udp-custom apagado"
    fi

    if ss -ulnp 2>/dev/null | grep -q ":36712"; then
        ok "Puerto 36712 escuchando"
    else
        fail "Puerto 36712 no escucha"
    fi

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BLANCO}Servidor/IP:${RESET} $(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')"
    echo -e "${BLANCO}Puerto UDP:${RESET} 36712"
    echo -e "${BLANCO}Modo:${RESET} UDP Custom / HTTP Custom"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

    pausa_udp_custom
}

activar_udp_custom() {
    if [[ -f /opt/darkzsaid/menus/install_udp_custom_http.sh ]]; then
        bash /opt/darkzsaid/menus/install_udp_custom_http.sh
    else
        titulo_instalacion "UDP CUSTOM HTTP"
        fail "No se encontró install_udp_custom_http.sh"
        pausa_udp_custom
    fi
}

detener_udp_custom() {
    titulo_instalacion "DETENER UDP CUSTOM"

    paso "Deteniendo servicio udp-custom..."
    systemctl stop udp-custom >/dev/null 2>&1 || true

    if systemctl is-active --quiet udp-custom 2>/dev/null; then
        fail "No se pudo detener udp-custom"
    else
        ok "UDP Custom detenido"
    fi

    pausa_udp_custom
}

while true; do
    limpiar_pantalla
    echo -e "${CYAN}╔══════════════════════════════════════════════╗${RESET}"
    echo -e "${BLANCO}║          ⚡ UDP CUSTOM HTTP CUSTOM ⚡        ║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${BLANCO}[01]${RESET} Activar / instalar UDP Custom"
    echo -e "${BLANCO}[02]${RESET} Ver estado y datos de conexión"
    echo -e "${BLANCO}[03]${RESET} Detener UDP Custom"
    echo ""
    echo -e "${BLANCO}[00]${RESET} Volver"
    echo ""
    read -p "Opción: " op

    case "$op" in
        1|01) activar_udp_custom ;;
        2|02) estado_udp_custom ;;
        3|03) detener_udp_custom ;;
        0|00) exit 0 ;;
        *) echo "Opción inválida"; sleep 1 ;;
    esac
done
