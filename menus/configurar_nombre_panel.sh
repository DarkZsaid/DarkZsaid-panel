#!/bin/bash

limpiar_pantalla() {
    printf '\033[H\033[2J\033[3J'
}


CYAN="\e[36m"
VERDE="\e[32m"
ROJO="\e[31m"
AMARILLO="\e[33m"
BLANCO="\e[97m"
RESET="\e[0m"

CONFIG="/etc/darkzsaid/panel_logo.conf"
mkdir -p /etc/darkzsaid

limpiar_pantalla
echo -e "${CYAN}◆══════════════════════════════════════════════◆${RESET}"
echo -e "${BLANCO}        ⚡ CAMBIAR LOGO SUPERIOR ⚡${RESET}"
echo -e "${CYAN}◆══════════════════════════════════════════════◆${RESET}"
echo ""

if [[ -f "$CONFIG" ]]; then
    source "$CONFIG" 2>/dev/null || true
fi

echo -e "${AMARILLO}Logo actual:${RESET} ${VERDE}${PANEL_LOGO_TEXT:-DarkZsaid}${RESET}"
echo ""
echo -e "${BLANCO}Escribí el nuevo nombre que querés ver arriba.${RESET}"
echo -e "${BLANCO}Ejemplo: Steven${RESET}"
echo ""

read -r -p "Nuevo logo: " NUEVO_LOGO

NUEVO_LOGO="$(echo "$NUEVO_LOGO" | xargs)"

if [[ -z "$NUEVO_LOGO" ]]; then
    echo -e "${ROJO}No escribiste nada. No se cambió el logo.${RESET}"
    read -p "ENTER..."
    exit 0
fi

cat > "$CONFIG" <<CFG
PANEL_LOGO_TEXT="$NUEVO_LOGO"
CFG

echo ""
echo -e "${VERDE}✓ Logo guardado como: $NUEVO_LOGO${RESET}"
echo ""
cat "$CONFIG"
echo ""
read -p "ENTER para volver..."
