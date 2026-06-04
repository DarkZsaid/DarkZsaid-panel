#!/bin/bash

pantalla_limpia() {
    printf '\033c'
}


limpiar_pantalla() {
    printf '\033[H\033[2J\033[3J'
}

source /opt/darkzsaid/menus/ui_instalacion.sh 2>/dev/null || true

[[ -f /opt/darkzsaid/lib/ui.sh ]] && source /opt/darkzsaid/lib/ui.sh

ROJO="${ROJO:-\e[31m}"
VERDE="${VERDE:-\e[32m}"
AMARILLO="${AMARILLO:-\e[33m}"
CYAN="${CYAN:-\e[36m}"
BLANCO="${BLANCO:-\e[97m}"
RESET="${RESET:-\e[0m}"

UDP_SERVICE="udpmod"
UDP_PORT="36712"

pausa_udp() {
    echo ""
    read -r -p "Presiona ENTER para continuar..."
}

titulo_udp_hysteria() {
    limpiar_pantalla
    echo -e "${CYAN}╔════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET}       ${BLANCO}⚡ DARKZSAID UDP HYSTERIA ⚡${RESET}      ${CYAN}║${RESET}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${AMARILLO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "          ${VERDE}$1${RESET}"
    echo -e "${AMARILLO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
}

estado_udpmod() {
    if systemctl is-active --quiet "$UDP_SERVICE" 2>/dev/null; then
        echo -e "${VERDE}[ON]${RESET}"
    elif ss -ulnp 2>/dev/null | grep -qE "(:${UDP_PORT}[[:space:]]|:${UDP_PORT}$)"; then
        echo -e "${VERDE}[ON]${RESET}"
    else
        echo -e "${ROJO}[OFF]${RESET}"
    fi
}

puerto_udpmod() {
    ss -ulnp 2>/dev/null | grep -qE "(:${UDP_PORT}[[:space:]]|:${UDP_PORT}$)"
}

mostrar_datos_udpmod() {
    echo -e "${AMARILLO}Servicio:${RESET} $UDP_SERVICE"
    echo -e "${AMARILLO}Puerto:${RESET} $UDP_PORT UDP"
    echo -e "${AMARILLO}Estado:${RESET} $(estado_udpmod)"
    echo ""

    echo -e "${CYAN}Puerto escuchando:${RESET}"
    ss -ulnp 2>/dev/null | grep ":$UDP_PORT" || echo "Puerto $UDP_PORT no está escuchando."
    echo ""

    echo -e "${CYAN}Servicio systemd:${RESET}"
    systemctl is-active --quiet "$UDP_SERVICE" 2>/dev/null && echo -e "${VERDE}✓${RESET} Servicio activo" || echo -e "${ROJO}✘${RESET} Servicio apagado"
}

abrir_puerto_udpmod() {
    ufw allow ${UDP_PORT}/udp >/dev/null 2>&1 || true
    iptables -C INPUT -p udp --dport "$UDP_PORT" -j ACCEPT 2>/dev/null || iptables -I INPUT -p udp --dport "$UDP_PORT" -j ACCEPT
    netfilter-persistent save >/dev/null 2>&1 || true
}

buscar_motor_udpmod() {
    echo "Buscando motor UDP-Hysteria..."
    echo ""

    find / -type f \( \
        -iname "udp-hysteria*" -o \
        -iname "udpmod*" -o \
        -iname "*hysteria*" \
    \) 2>/dev/null | grep -v ".bak" | head -30
}

activar_instalar_udpmod() {
    titulo_udp_hysteria "ACTIVAR / INSTALAR UDP-HYSTERIA"

    abrir_puerto_udpmod

    if systemctl list-unit-files 2>/dev/null | grep -q "^${UDP_SERVICE}.service"; then
        echo -e "${VERDE}Servicio udpmod encontrado.${RESET}"
        echo "Iniciando UDP-Hysteria..."
        systemctl enable >/dev/null 2>&1 "$UDP_SERVICE" >/dev/null 2>&1
        systemctl restart >/dev/null 2>&1 "$UDP_SERVICE" >/dev/null 2>&1
        sleep 1

        mostrar_datos_udpmod
        pausa_udp
        return
    fi

    echo -e "${ROJO}No encontré udpmod.service instalado.${RESET}"
    echo ""
    echo "El último que funcionó era:"
    echo -e "${VERDE}UDP-HYSTERIA APPMOD'S / UDPMOD${RESET}"
    echo -e "${AMARILLO}Puerto:${RESET} 36712 UDP"
    echo ""
    echo "Voy a buscar si quedó el motor viejo en la VPS:"
    echo ""

    buscar_motor_udpmod

    echo ""
    echo -e "${AMARILLO}Si aparece un binario o archivo del motor, mándame esa salida y lo conectamos otra vez al servicio udpmod.${RESET}"
    pausa_udp
}

detener_udpmod() {
    titulo_udp_hysteria "DETENER UDP-HYSTERIA"

    systemctl stop "$UDP_SERVICE" >/dev/null 2>&1 || true

    pkill -f "udp-hysteria-ap" 2>/dev/null || true
    pkill -f "udp-hysteria" 2>/dev/null || true
    pkill -f "udpmod" 2>/dev/null || true

    echo -e "${AMARILLO}UDP-Hysteria detenido.${RESET}"
    echo ""
    ss -ulnp 2>/dev/null | grep ":$UDP_PORT" || echo "Puerto $UDP_PORT libre."

    pausa_udp
}

reiniciar_udpmod() {
    titulo_udp_hysteria "REINICIAR UDP-HYSTERIA"

    abrir_puerto_udpmod

    if systemctl list-unit-files 2>/dev/null | grep -q "^${UDP_SERVICE}.service"; then
        systemctl restart >/dev/null 2>&1 "$UDP_SERVICE" >/dev/null 2>&1
        sleep 1
        echo -e "${VERDE}UDP-Hysteria reiniciado.${RESET}"
    else
        echo -e "${ROJO}No existe udpmod.service.${RESET}"
    fi

    echo ""
    mostrar_datos_udpmod

    pausa_udp
}

remover_udpmod() {
    titulo_udp_hysteria "REMOVER UDP-HYSTERIA"

    read -r -p "¿Seguro que quieres remover UDP-Hysteria? [s/n]: " r

    if [[ "$r" != "s" && "$r" != "S" ]]; then
        echo "Cancelado."
        pausa_udp
        return
    fi

    systemctl stop "$UDP_SERVICE" >/dev/null 2>&1 || true
    systemctl disable "$UDP_SERVICE" >/dev/null 2>&1 || true

    pkill -f "udp-hysteria-ap" 2>/dev/null || true
    pkill -f "udp-hysteria" 2>/dev/null || true
    pkill -f "udpmod" 2>/dev/null || true

    rm -f /etc/systemd/system/udpmod.service
    systemctl daemon-reload >/dev/null 2>&1 >/dev/null 2>&1

    echo -e "${VERDE}UDP-Hysteria removido del servicio.${RESET}"
    echo ""
    ss -ulnp 2>/dev/null | grep ":$UDP_PORT" || echo "Puerto $UDP_PORT libre."

    pausa_udp
}

datos_udpmod() {
    titulo_udp_hysteria "DATOS UDP-HYSTERIA"
    mostrar_datos_udpmod
    pausa_udp
}

menu_udp_hysteria() {
    while true; do
        titulo_udp_hysteria "UDP-HYSTERIA APPMOD'S / UDPMOD"

        echo -e "${ROJO}[01]${RESET} ${CYAN}➜${RESET} ${BLANCO}ACTIVAR / INSTALAR${RESET}      $(estado_udpmod)"
        echo -e "${ROJO}[02]${RESET} ${CYAN}➜${RESET} ${BLANCO}DETENER${RESET}"
        echo -e "${ROJO}[03]${RESET} ${CYAN}➜${RESET} ${BLANCO}REINICIAR${RESET}"
        echo -e "${ROJO}[04]${RESET} ${CYAN}➜${RESET} ${BLANCO}DATOS / PUERTO${RESET}"
        echo -e "${ROJO}[05]${RESET} ${CYAN}➜${RESET} ${ROJO}REMOVER${RESET}"
        echo -e "${ROJO}[06]${RESET} ${AZUL}USUARIOS UDPMOD${RESET}"
        echo ""
        echo -e "${ROJO}[00]${RESET} ${CYAN}➜${RESET} ${ROJO}[ VOLVER ]${RESET}"
        echo ""

        read -r -p "⚡ Opción: " op

        case "$op" in
            1|01) activar_instalar_udpmod ;;
            2|02) detener_udpmod ;;
            3|03) reiniciar_udpmod ;;
            4|04) datos_udpmod ;;
            5|05) remover_udpmod ;;
            6|06)
                bash /opt/darkzsaid/menus/udpmod_users_menu.sh
            ;;

            0|00) return ;;
            *) echo -e "${ROJO}Opción inválida.${RESET}"; sleep 1 ;;
        esac
    done
}

menu_udp_hysteria
