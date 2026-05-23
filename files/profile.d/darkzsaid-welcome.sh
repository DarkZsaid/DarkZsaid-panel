#!/bin/bash

clear

BLANCO="\e[97m"
AZUL="\e[94m"
VERDE="\e[92m"
AMARILLO="\e[93m"
ROJO="\e[91m"
BOLD="\e[1m"
RESET="\e[0m"

echo -e "${AZUL}${BOLD}"
toilet -f big "DarkZsaid" 2>/dev/null || figlet "DarkZsaid" 2>/dev/null || echo "DarkZsaid"
echo -e "${RESET}"
echo -e "${AMARILLO}${BOLD}────────────────────────────────────────────${RESET}"
echo -e "${BLANCO}${BOLD}      DARKZSAID VPS MANAGER / PANEL SSH${RESET}"
echo -e "${AMARILLO}${BOLD}────────────────────────────────────────────${RESET}"
echo ""

FECHA_ACTUAL=$(date '+%d-%m-%Y - %H:%M:%S')
HOST_ACTUAL=$(hostname 2>/dev/null)
IP_ACTUAL=$(curl -s --max-time 3 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
UP_ACTUAL=$(uptime -p 2>/dev/null | sed 's/up //')
RAM_LIBRE=$(free -m | awk '/Mem:/ {print $7"Mi"}')
DISCO_LIBRE=$(df -h / | awk 'NR==2 {print $4}')

echo -e "${BLANCO}${BOLD}FECHA/HORA ACTUAL     : $FECHA_ACTUAL${RESET}"
echo -e "${BLANCO}${BOLD}NOMBRE DEL SERVIDOR   : $HOST_ACTUAL${RESET}"
echo -e "${BLANCO}${BOLD}IP PUBLICA            : $IP_ACTUAL${RESET}"
echo -e "${BLANCO}${BOLD}TIEMPO EN LINEA       : $UP_ACTUAL${RESET}"
echo -e "${BLANCO}${BOLD}VERSION INSTALADA     : V1.0 ESTABLE${RESET}"
echo -e "${BLANCO}${BOLD}MEMORIA RAM LIBRE     : $RAM_LIBRE${RESET}"
echo -e "${BLANCO}${BOLD}DISCO LIBRE           : $DISCO_LIBRE${RESET}"
echo ""

echo -e "${AMARILLO}${BOLD}        RESELLER:${RESET} ${ROJO}${BOLD}DarkZsaid${RESET}"
echo ""
echo -e "${VERDE}${BOLD}BIENVENIDO DE NUEVO!${RESET}"
echo -e "${BLANCO}${BOLD}Teclee menu o darkzsaid para ver el MENU.${RESET}"
echo ""
