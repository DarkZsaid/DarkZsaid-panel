#!/bin/bash

pantalla_limpia() {
    printf '\033c'
}


limpiar_pantalla() {
    printf '\033[H\033[2J\033[3J'
}

source /opt/darkzsaid/menus/ui_instalacion.sh 2>/dev/null || true

source /opt/darkzsaid/lib/install_clean.sh 2>/dev/null || true

ROJO="\e[31m"
VERDE="\e[32m"
AMARILLO="\e[33m"
CYAN="\e[36m"
BLANCO="\e[97m"
RESET="\e[0m"
BOLD="\e[1m"

pausa() {
    echo ""
    read -p "Presiona ENTER para continuar..."
}

titulo_dropbear() {
    limpiar_pantalla
    echo -e "${CYAN}╔════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET} ${BLANCO}${BOLD}        DROPBEAR SSH${RESET}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════╝${RESET}"
    echo ""
}

estado_dropbear() {
    if systemctl is-active --quiet dropbear 2>/dev/null; then
        echo -e "${VERDE}[ON]${RESET}"
    else
        echo -e "${ROJO}[OFF]${RESET}"
    fi
}

instalar_dropbear_full() {
    source /opt/darkzsaid/lib/install_clean.sh 2>/dev/null || true

    clean_title "INSTALANDO DROPBEAR SSH"

    clean_task "Instalando paquete Dropbear" "apt-get update -y >/dev/null 2>&1 >/dev/null 2>&1 && apt-get install -y >/dev/null 2>&1 dropbear >/dev/null 2>&1"

    clean_task "Creando configuración" "cat > /etc/default/dropbear <<'EOD'
NO_START=0
DROPBEAR_PORT=109
DROPBEAR_EXTRA_ARGS='-p 109 -p 143'
DROPBEAR_BANNER='/etc/issue.net'
DROPBEAR_RECEIVE_WINDOW=65536
EOD"

    clean_task "Abriendo puertos" "ufw allow 109/tcp >/dev/null 2>&1 || true; ufw allow 143/tcp >/dev/null 2>&1 || true; ufw reload >/dev/null 2>&1 || true"

    clean_task "Activando servicio" "systemctl enable dropbear >/dev/null 2>&1 >/dev/null 2>&1; systemctl restart dropbear >/dev/null 2>&1"

    clean_task "Verificando Dropbear" "systemctl is-active --quiet dropbear"

    clean_done
    pausa
}

detener_dropbear() {
    source /opt/darkzsaid/lib/install_clean.sh 2>/dev/null || true

    clean_title "DETENIENDO DROPBEAR SSH"

    clean_task_soft "Deteniendo servicio Dropbear" "systemctl stop dropbear 2>/dev/null || true"
    clean_task_soft "Verificando apagado" "! systemctl is-active --quiet dropbear"

    clean_done
    pausa
}

reiniciar_dropbear() {
    source /opt/darkzsaid/lib/install_clean.sh 2>/dev/null || true

    clean_title "REINICIANDO DROPBEAR SSH"

    clean_task "Reiniciando servicio" "systemctl restart dropbear >/dev/null 2>&1"
    clean_task "Verificando Dropbear" "systemctl is-active --quiet dropbear"

    clean_done
    pausa
}

estado_dropbear_full() {
    titulo_dropbear

    echo -e "${AMARILLO}Estado:${RESET} $(estado_dropbear)"
    echo ""
    echo -e "${AMARILLO}Puertos activos:${RESET}"
    ss -tulnp | grep -E ':(109|143) ' || echo "No se detectan puertos Dropbear activos."
    echo ""
    echo -e "${AMARILLO}Servicio:${RESET}"
    systemctl status dropbear --no-pager -l 2>/dev/null | head -25 || echo "Dropbear no está instalado."

    pausa
}

remover_dropbear() {
    source /opt/darkzsaid/lib/install_clean.sh 2>/dev/null || true

    clean_title "REMOVIENDO DROPBEAR SSH"

    clean_task_soft "Deteniendo servicio" "systemctl stop dropbear 2>/dev/null || true"
    clean_task_soft "Desactivando servicio" "systemctl disable dropbear 2>/dev/null || true"
    clean_task_soft "Cerrando puertos UFW" "ufw delete allow 109/tcp >/dev/null 2>&1 || true; ufw delete allow 143/tcp >/dev/null 2>&1 || true; ufw reload >/dev/null 2>&1 || true"

    clean_done
    pausa
}

while true; do
    titulo_dropbear
    echo -e "${ROJO}[01]${RESET} ${CYAN}➜${RESET} ${BLANCO}ACTIVAR / INSTALAR DROPBEAR${RESET} $(estado_dropbear)"
    echo -e "${ROJO}[02]${RESET} ${CYAN}➜${RESET} ${BLANCO}DETENER DROPBEAR${RESET}"
    echo -e "${ROJO}[03]${RESET} ${CYAN}➜${RESET} ${BLANCO}REINICIAR DROPBEAR${RESET}"
    echo -e "${ROJO}[04]${RESET} ${CYAN}➜${RESET} ${BLANCO}VER ESTADO DROPBEAR${RESET}"
    echo -e "${ROJO}[05]${RESET} ${CYAN}➜${RESET} ${BLANCO}REMOVER DROPBEAR${RESET}"
    echo ""
    echo -e "${ROJO}[00]${RESET} ${CYAN}➜${RESET} ${BLANCO}VOLVER${RESET}"
    echo ""
    read -p "Seleccione una opción: " opc; printf '\033c'

    case "$opc" in
        1|01) instalar_dropbear_full ;;
        2|02) detener_dropbear ;;
        3|03) reiniciar_dropbear ;;
        4|04) estado_dropbear_full ;;
        5|05) remover_dropbear ;;
        0|00) exit 0 ;;
        *) echo -e "${ROJO}Opción inválida.${RESET}"; sleep 1 ;;
    esac
done
