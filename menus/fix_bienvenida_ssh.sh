#!/bin/bash

limpiar_pantalla() {
    printf '\033[H\033[2J\033[3J'
}


# ELIMINADO AUTOINICIADOR: rm -f /opt/darkzsaid/data/autoiniciador.conf 2>/dev/null || true
# ELIMINADO AUTOINICIADOR: rm -f /usr/local/bin/autoiniciador-on 2>/dev/null || true
# ELIMINADO AUTOINICIADOR: rm -f /usr/local/bin/autoiniciador-off 2>/dev/null || true

chmod -x /etc/update-motd.d/* 2>/dev/null || true
rm -f /etc/motd 2>/dev/null || true
touch /etc/motd

cat > /root/.darkzsaid_welcome.sh <<'EOF2'
#!/bin/bash

VERDE="\e[32m"
CYAN="\e[36m"
ROJO="\e[31m"
AMARILLO="\e[33m"
BLANCO="\e[97m"
RESET="\e[0m"
BOLD="\e[1m"

limpiar_pantalla

IP_PUBLICA=$(curl -4 -s https://api.ipify.org 2>/dev/null)
IP_LOCAL=$(hostname -I 2>/dev/null | awk '{print $1}')
HOSTNAME_SERVER=$(hostname)
FECHA_ACTUAL=$(date '+%d-%m-%Y - %H:%M:%S')
UPTIME_TXT=$(uptime -p 2>/dev/null | sed 's/up //')
RAM_LIBRE=$(free -h | awk '/Mem:/ {print $7}')
DISCO_LIBRE=$(df -h / | awk 'NR==2 {print $4}')
VERSION_DARK="V1.0 ESTABLE"

if [[ -z "$IP_PUBLICA" ]]; then
    IP_PUBLICA="$IP_LOCAL"
fi

echo -e "${CYAN}"
echo "██████╗  █████╗ ██████╗ ██╗  ██╗███████╗ █████╗ ██╗██████╗ "
echo "██╔══██╗██╔══██╗██╔══██╗██║ ██╔╝╚══███╔╝██╔══██╗██║██╔══██╗"
echo "██║  ██║███████║██████╔╝█████╔╝   ███╔╝ ███████║██║██║  ██║"
echo "██║  ██║██╔══██║██╔══██╗██╔═██╗  ███╔╝  ██╔══██║██║██║  ██║"
echo "██████╔╝██║  ██║██║  ██║██║  ██╗███████╗██║  ██║██║██████╔╝"
echo "╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝╚═════╝ "
echo -e "${RESET}"

echo -e "${VERDE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BLANCO}${BOLD}        DARKZSAID VPS MANAGER / PANEL SSH${RESET}"
echo -e "${VERDE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo
echo -e "${CYAN}FECHA/HORA ACTUAL    :${RESET} ${VERDE}$FECHA_ACTUAL${RESET}"
echo -e "${CYAN}NOMBRE DEL SERVIDOR  :${RESET} ${VERDE}$HOSTNAME_SERVER${RESET}"
echo -e "${CYAN}IP PUBLICA           :${RESET} ${VERDE}$IP_PUBLICA${RESET}"
echo -e "${CYAN}TIEMPO EN LINEA      :${RESET} ${VERDE}$UPTIME_TXT${RESET}"
echo -e "${CYAN}VERSION INSTALADA    :${RESET} ${VERDE}$VERSION_DARK${RESET}"
echo -e "${CYAN}MEMORIA RAM LIBRE    :${RESET} ${VERDE}$RAM_LIBRE${RESET}"
echo -e "${CYAN}DISCO LIBRE          :${RESET} ${VERDE}$DISCO_LIBRE${RESET}"
echo
echo -e "${AMARILLO}      RESELLER:${RESET} ${ROJO}${BOLD}DarkZsaid${RESET}"
echo
echo -e "${VERDE}${BOLD}BIENVENIDO DE NUEVO!${RESET}"
echo -e "${AMARILLO}${BOLD}Teclee menu o darkzsaid para ver el MENU.${RESET}"
echo
EOF2

chmod +x /root/.darkzsaid_welcome.sh

cat > /root/.bashrc <<'EOF2'
# ~/.bashrc limpio para root

case $- in
    *i*) ;;
      *) return;;
esac

HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s checkwinsize

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w# '

# Bienvenida permanente DarkZsaid
if [[ -t 1 && -z "$DARKZSAID_WELCOME_SHOWN" ]]; then
    export DARKZSAID_WELCOME_SHOWN=1
    bash /root/.darkzsaid_welcome.sh
fi
EOF2

cat > /root/.profile <<'EOF2'
# ~/.profile limpio para root

if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi
EOF2

ln -sf /opt/darkzsaid/panel.sh /usr/local/bin/menu
ln -sf /opt/darkzsaid/panel.sh /usr/local/bin/darkzsaid
chmod +x /opt/darkzsaid/panel.sh /usr/local/bin/menu /usr/local/bin/darkzsaid 2>/dev/null || true

echo "Bienvenida permanente DarkZsaid instalada."
