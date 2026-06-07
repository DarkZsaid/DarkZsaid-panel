#!/bin/bash

BASE_DIR="/opt/darkzsaid"

ROJO="\033[1;31m"
VERDE="\033[1;32m"
AMARILLO="\033[1;33m"
AZUL="\033[1;34m"
CYAN="\033[1;36m"
BLANCO="\033[1;37m"
RESET="\033[0m"

limpiar_pantalla(){
    printf '\033[H\033[2J\033[3J'
    clear 2>/dev/null || true
}

pausa(){
    echo
    read -rp "Presiona ENTER para continuar..."
}

ok(){ echo -e "${VERDE}✓${RESET} $1"; }
fail(){ echo -e "${ROJO}✗${RESET} $1"; }
info(){ echo -e "${CYAN}➜${RESET} $1"; }

titulo(){
    limpiar_pantalla
    echo -e "${CYAN}╔════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET}        ${BLANCO}⚡ UDP CUSTOM HTTP ⚡${RESET}         ${CYAN}║${RESET}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${RESET}"
    echo
}

estado_on(){ echo -e "${VERDE}[ON]${RESET}"; }
estado_off(){ echo -e "${ROJO}[OFF]${RESET}"; }

estado_udp_custom(){
    if systemctl is-active --quiet udp-custom.service 2>/dev/null || \
       ss -ulnp 2>/dev/null | grep -q ':36712'; then
        estado_on
    else
        estado_off
    fi
}

activar_udp_custom(){
    titulo
    info "Activando / instalando UDP Custom desde instalador oficial..."

    if [ -x "$BASE_DIR/core/install_udp_custom_motor.sh" ]; then
        bash "$BASE_DIR/core/install_udp_custom_motor.sh"
    else
        fail "No existe instalador oficial UDP Custom."
        echo "$BASE_DIR/core/install_udp_custom_motor.sh"
        pausa
        return
    fi

    echo
    echo -e "${BLANCO}Estado:${RESET} $(estado_udp_custom)"
    pausa
}

estado_detallado_udp_custom(){
    titulo
    echo -e "${BLANCO}Servicio udp-custom:${RESET}"
    systemctl is-active udp-custom.service 2>/dev/null || echo "inactive"

    echo
    echo -e "${BLANCO}Puerto UDP Custom:${RESET}"
    ss -ulnp 2>/dev/null | grep ':36712' || echo "Puerto 36712 no escucha"

    echo
    echo -e "${BLANCO}Config:${RESET}"
    cat /usr/bin/config.json 2>/dev/null || echo "No existe /usr/bin/config.json"

    echo
    echo -e "${BLANCO}Logs:${RESET}"
    journalctl -u udp-custom.service --no-pager -n 20 2>/dev/null || true

    pausa
}

detener_udp_custom(){
    titulo
    info "Deteniendo servicio udp-custom..."
    systemctl stop udp-custom.service >/dev/null 2>&1 || true

    if systemctl is-active --quiet udp-custom.service 2>/dev/null; then
        fail "No se pudo detener udp-custom"
    else
        ok "UDP Custom detenido"
    fi

    pausa
}

reiniciar_udp_custom(){
    titulo
    info "Reiniciando UDP Custom..."
    systemctl restart udp-custom.service >/dev/null 2>&1 || bash "$BASE_DIR/core/install_udp_custom_motor.sh"

    if systemctl is-active --quiet udp-custom.service 2>/dev/null || ss -ulnp 2>/dev/null | grep -q ':36712'; then
        ok "UDP Custom activo en puerto 36712"
    else
        fail "UDP Custom no levantó"
    fi

    pausa
}

remover_udp_custom(){
    titulo
    read -rp "¿Seguro que quieres remover UDP Custom? [s/n]: " r
    [[ "$r" != "s" && "$r" != "S" ]] && return

    systemctl stop udp-custom.service >/dev/null 2>&1 || true
    systemctl disable udp-custom.service >/dev/null 2>&1 || true
    rm -f /etc/systemd/system/udp-custom.service
    systemctl daemon-reload >/dev/null 2>&1 || true

    ok "UDP Custom removido"
    pausa
}

menu_udp_custom(){
    while true; do
        titulo
        echo -e "${ROJO}[01]${RESET} ${BLANCO}ACTIVAR / INSTALAR${RESET}       $(estado_udp_custom)"
        echo -e "${ROJO}[02]${RESET} ${BLANCO}VER ESTADO / DATOS${RESET}"
        echo -e "${ROJO}[03]${RESET} ${BLANCO}DETENER${RESET}"
        echo -e "${ROJO}[04]${RESET} ${BLANCO}REINICIAR${RESET}"
        echo -e "${ROJO}[05]${RESET} ${BLANCO}REMOVER${RESET}"
        echo
        echo -e "${ROJO}[00]${RESET} ${BLANCO}VOLVER${RESET}"
        echo
        read -rp "Opción: " op

        case "$op" in
            1|01) activar_udp_custom ;;
            2|02) estado_detallado_udp_custom ;;
            3|03) detener_udp_custom ;;
            4|04) reiniciar_udp_custom ;;
            5|05) remover_udp_custom ;;
            0|00) break ;;
            *) pausa ;;
        esac
    done
}

menu_udp_custom
