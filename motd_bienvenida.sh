# DARKZSAID WELCOME

clear

BLANCO="\e[1;97m"
CYAN="\e[1;36m"
VERDE="\e[1;32m"
AMARILLO="\e[1;33m"
ROJO="\e[1;31m"
RESET="\e[0m"

IP_PUBLICA=$(curl -s --max-time 3 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
FECHA=$(date '+%d-%m-%Y - %H:%M:%S')
HOSTNAME=$(hostname)
UPTIME=$(uptime -p | sed 's/up //')
RAM_LIBRE=$(free -m | awk '/Mem:/ {print $7"Mi"}')
DISCO_LIBRE=$(df -h / | awk 'NR==2 {print $4}')

echo -e "${CYAN}"
toilet -f big "DarkZsaid" 2>/dev/null | sed '/^[[:space:]]*$/d'
echo -e "${RESET}"

echo -e "${VERDE}────────────────────────────────────────────${RESET}"
echo -e "${BLANCO}        DARKZSAID VPS MANAGER / PANEL SSH${RESET}"
echo -e "${VERDE}────────────────────────────────────────────${RESET}"
echo ""

echo -e "${CYAN}FECHA/HORA ACTUAL    :${RESET} ${BLANCO}${FECHA}${RESET}"
echo -e "${CYAN}NOMBRE DEL SERVIDOR  :${RESET} ${BLANCO}${HOSTNAME}${RESET}"
echo -e "${CYAN}IP PUBLICA           :${RESET} ${BLANCO}${IP_PUBLICA}${RESET}"
echo -e "${CYAN}TIEMPO EN LINEA      :${RESET} ${BLANCO}${UPTIME}${RESET}"
echo -e "${CYAN}VERSION INSTALADA    :${RESET} ${BLANCO}v1.0 ESTABLE${RESET}"
echo -e "${CYAN}MEMORIA RAM LIBRE    :${RESET} ${BLANCO}${RAM_LIBRE}${RESET}"
echo -e "${CYAN}DISCO LIBRE          :${RESET} ${BLANCO}${DISCO_LIBRE}${RESET}"

echo ""
echo -e "${BLANCO}        RESELLER:${RESET} ${ROJO}DarkZsaid${RESET}"
echo ""
echo -e "${BLANCO}BIENVENIDO DE NUEVO!${RESET}"
echo -e "${BLANCO}Teclee ${AMARILLO}menu${BLANCO} o ${AMARILLO}darkzsaid${BLANCO} para ver el MENU.${RESET}"
echo ""

