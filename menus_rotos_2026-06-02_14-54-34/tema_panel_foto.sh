#!/bin/bash

pantalla_limpia() {
    printf '\033c'
}


limpiar_pantalla() {
    printf '\033[H\033[2J\033[3J'
}


VERSION_SCRIPT="v1.0"

ROJO="\e[31m"
VERDE="\e[32m"
AMARILLO="\e[33m"
AZUL="\e[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"
BLANCO="\e[97m"
GRIS="\e[90m"
RESET="\e[0m"
BOLD="\e[1m"

LINEA="${CYAN}◆════════════════════════════════════════════════════◆${RESET}"

conf_panel="/etc/darkzsaid/panel_theme.conf"
mkdir -p /etc/darkzsaid

if [[ ! -f "$conf_panel" ]]; then
cat > "$conf_panel" <<CFG
PANEL_NAME="DARKZSAID"
PANEL_AUTHOR="@DarkZsaid"
PANEL_VERSION="v1.0"
CFG
fi

source "$conf_panel" 2>/dev/null || true

PANEL_NAME="${PANEL_NAME:-DARKZSAID}"
PANEL_AUTHOR="${PANEL_AUTHOR:-@DarkZsaid}"
PANEL_VERSION="v1.0"

linea_panel() {
    echo -e "$LINEA"
}

logo_panel() {
    echo -e "${CYAN}"
    echo " ____             _    ______          _     _ "
    echo "|  _ \  __ _ _ __| | _|__  / ___  ___(_) __| |"
    echo "| | | |/ _\` | '__| |/ / / / / __|/ _ \ |/ _\` |"
    echo "| |_| | (_| | |  |   < / /_ \__ \  __/ | (_| |"
    echo "|____/ \__,_|_|  |_|\_/____|___/\___|_|\__,_|"
    echo -e "${RESET}"
}

titulo_superior_panel() {
    HOST_VPS="$(hostname 2>/dev/null || echo VPS)"
    IP_VPS="$(curl -s --max-time 2 ifconfig.me 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}')"
    OS_VPS="$(lsb_release -ds 2>/dev/null | tr -d '"' || echo Linux)"
    RAM_VPS="$(free -m | awk '/Mem:/ {print $3"/"$2" MB"}')"
    SWAP_VPS="$(free -m | awk '/Swap:/ {print $3"/"$2" MB"}')"
    DISCO_VPS="$(df -h / | awk 'NR==2 {print $4" libre"}')"
    FECHA_VPS="$(date '+%d/%m/%Y-%H:%M')"
    UPTIME_VPS="$(uptime -p 2>/dev/null | sed 's/up //')"

    limpiar_pantalla
    logo_panel
    linea_panel
    echo -e "${BLANCO} ⚡ Gestor VPN/SSH by ${CYAN}${PANEL_AUTHOR}${BLANCO}  ◆  ${AMARILLO}${PANEL_VERSION}${RESET}"
    linea_panel
    echo ""
    linea_panel
    echo -e "${CYAN} ◈${RESET} SO:     ${BLANCO}${OS_VPS}${RESET}        ${CYAN}◈${RESET} IP:     ${BLANCO}${IP_VPS}${RESET}"
    echo -e "${CYAN} ◈${RESET} VPS:    ${BLANCO}${HOST_VPS}${RESET}      ${CYAN}◈${RESET} Fecha:  ${BLANCO}${FECHA_VPS}${RESET}"
    echo -e "${CYAN} ◈${RESET} RAM:    ${BLANCO}${RAM_VPS}${RESET}       ${CYAN}◈${RESET} Swap:   ${BLANCO}${SWAP_VPS}${RESET}"
    echo -e "${CYAN} ◈${RESET} Disco:  ${BLANCO}${DISCO_VPS}${RESET}    ${CYAN}◈${RESET} Uptime: ${BLANCO}${UPTIME_VPS}${RESET}"
    linea_panel
}

op_menu() {
    echo -e "${BLANCO}<${CYAN}$1${BLANCO}>${RESET} ${CYAN}$2${RESET} ${BLANCO}$3${RESET}"
}

op_menu_rojo() {
    echo -e "${BLANCO}<${ROJO}$1${BLANCO}>${RESET} ${ROJO}$2 ${3}${RESET}"
}

op_menu_amarillo() {
    echo -e "${BLANCO}<${AMARILLO}$1${BLANCO}>${RESET} ${AMARILLO}$2 ${3}${RESET}"
}

prompt_panel() {
    echo ""
    echo -ne "${CYAN}⚡${RESET} ${BLANCO}Opción:${RESET} "
}
