#!/usr/bin/env bash

clear

CYAN="\033[1;36m"
VERDE="\033[1;32m"
AMARILLO="\033[1;33m"
BLANCO="\033[1;37m"
ROJO="\033[1;31m"
RESET="\033[0m"

echo -e "${CYAN}=====>>> 🐲 DarkZsaid 💥 Plus 🐲 <<<=====${RESET}"
echo
echo -e "🔐 ${BLANCO}USUARIOS CONECTADOS SSH | DROPBEAR | WS${RESET} 🔐"
echo -e "${AMARILLO}--------------------------------------------------${RESET}"

echo -ne "${CYAN}PROTOCOLOS ACTIVOS:${RESET} "
ss -ltnp 2>/dev/null | grep -q ':22' && echo -ne "${VERDE}SSH:22 ${RESET}"
ss -ltnp 2>/dev/null | grep -q ':80' && echo -ne "${VERDE}WS:80 ${RESET}"
ss -ltnp 2>/dev/null | grep -q ':443' && echo -ne "${VERDE}SSL:443 ${RESET}"
ss -ltnp 2>/dev/null | grep -qi 'dropbear' && echo -ne "${VERDE}DROPBEAR ${RESET}"
echo

echo -e "${AMARILLO}--------------------------------------------------${RESET}"
printf "${ROJO}%-16s %-14s %-12s${RESET}\n" "USUARIO" "CONEXIONES" "TIEMPO"
echo -e "${AMARILLO}--------------------------------------------------${RESET}"

total=0

# SSHD reales por usuario
while read -r pid etimes args; do
    echo "$args" | grep -q "sshd:" || continue
    echo "$args" | grep -qi "listener" && continue
    echo "$args" | grep -qi "\[priv\]" && continue
    echo "$args" | grep -qi "\[preauth\]" && continue

    user="$(echo "$args" | sed -n 's/.*sshd: \([A-Za-z0-9_.-]*\).*/\1/p')"
    [ -z "$user" ] && continue
    [ "$user" = "root" ] && continue

    h=$((etimes/3600))
    m=$(((etimes%3600)/60))
    s=$((etimes%60))
    tiempo="$(printf "%02d:%02d:%02d" "$h" "$m" "$s")"

    printf "${VERDE}%-16s${RESET} %-14s %-12s\n" "$user" "SSH:1" "$tiempo"
    total=$((total + 1))
done < <(ps -eo pid=,etimes=,args= 2>/dev/null)

# Dropbear sesiones reales
# Detecta sesiones Dropbear con "-2" o procesos hijos reales con PPID distinto de 1.
dropbear_info="$(ps -eo pid=,ppid=,etime=,args= 2>/dev/null | awk '
/\/usr\/sbin\/dropbear/ {
    ppid=$2
    etime=$3
    args=$0

    if (args ~ / -2 / || ppid != 1) {
        count++
        if (first_time == "") first_time=etime
    }
}
END {
    if (count == "") count=0
    print count "|" first_time
}')"

dropbear_total="${dropbear_info%%|*}"
dropbear_time="${dropbear_info#*|}"

if [ "$dropbear_total" -gt 0 ] 2>/dev/null; then
    [ -z "$dropbear_time" ] && dropbear_time="ACTIVO"
    printf "${VERDE}%-16s${RESET} %-14s %-12s\n" "DROPBEAR" "$dropbear_total" "$dropbear_time"
    total=$((total + dropbear_total))
fi

echo -e "${AMARILLO}--------------------------------------------------${RESET}"
echo -e "🛡 # TIENES [ ${VERDE}$total${RESET} ] USUARIOS CONECTADOS 🛡 #"
echo -e "${AMARILLO}--------------------------------------------------${RESET}"
echo
read -rp "Presiona ENTER para continuar..."
