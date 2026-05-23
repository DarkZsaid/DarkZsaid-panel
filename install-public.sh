#!/bin/bash

clear

LOG="/root/darkzsaid-install.log"
: > "$LOG"

CYAN="\e[96m"
VERDE="\e[92m"
AMARILLO="\e[93m"
ROJO="\e[91m"
BLANCO="\e[97m"
AZUL="\e[94m"
BOLD="\e[1m"
RESET="\e[0m"

banner() {
clear
echo -e "${AZUL}${BOLD}"
toilet -f big "DarkZsaid" 2>/dev/null || figlet "DarkZsaid" 2>/dev/null || echo "DarkZsaid"
echo -e "${RESET}"
echo -e "${AMARILLO}${BOLD}────────────────────────────────────────────${RESET}"
echo -e "${BLANCO}${BOLD}      INSTALADOR LIMPIO DARKZSAID${RESET}"
echo -e "${AMARILLO}${BOLD}────────────────────────────────────────────${RESET}"
echo ""
}

run_step() {
    local msg="$1"
    shift

    echo -ne "${CYAN}➜${RESET} ${BLANCO}${BOLD}${msg}${RESET} "

    "$@" >> "$LOG" 2>&1 &
    local pid=$!

    local spin='|/-\'
    local i=0

    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i+1) % 4 ))
        echo -ne "\r${CYAN}➜${RESET} ${BLANCO}${BOLD}${msg}${RESET} ${AMARILLO}${spin:$i:1}${RESET}"
        sleep 0.15
    done

    wait "$pid"
    local status=$?

    if [ "$status" -eq 0 ]; then
        echo -e "\r${VERDE}✅${RESET} ${BLANCO}${BOLD}${msg}${RESET}"
    else
        echo -e "\r${ROJO}❌${RESET} ${BLANCO}${BOLD}${msg}${RESET}"
        echo ""
        echo -e "${ROJO}${BOLD}Error durante la instalación.${RESET}"
        echo -e "${AMARILLO}Revisa el log:${RESET} $LOG"
        exit 1
    fi
}

install_base() {
    export DEBIAN_FRONTEND=noninteractive
    apt update -y
    apt install -y wget curl git sudo nano unzip zip dos2unix toilet figlet openssl iptables ufw net-tools
}

clone_panel() {
    rm -rf /opt/darkzsaid
    git clone https://github.com/DarkZsaid/DarkZsaid-panel.git /opt/darkzsaid || \
    git clone https://github.com/stevenjosecarcamo-star/DarkZsaid--panel.git /opt/darkzsaid
}

fix_permissions() {
    cd /opt/darkzsaid || exit 1

    find /opt/darkzsaid -type f -name "*.sh" -exec dos2unix {} \; 2>/dev/null || true

    chmod +x /opt/darkzsaid/*.sh 2>/dev/null || true
    chmod +x /opt/darkzsaid/menus/*.sh 2>/dev/null || true

    bash -n /opt/darkzsaid/panel.sh
    bash -n /opt/darkzsaid/menus/users_menu.sh 2>/dev/null || true
    bash -n /opt/darkzsaid/menus/udpmod_users_menu.sh 2>/dev/null || true

    ln -sf /opt/darkzsaid/panel.sh /usr/local/bin/menu
    ln -sf /opt/darkzsaid/panel.sh /usr/local/bin/darkzsaid
    chmod +x /usr/local/bin/menu /usr/local/bin/darkzsaid
}

setup_welcome() {
    mkdir -p /etc/profile.d

    if [ -f /opt/darkzsaid/files/profile.d/darkzsaid-welcome.sh ]; then
        cp -f /opt/darkzsaid/files/profile.d/darkzsaid-welcome.sh /etc/profile.d/darkzsaid-welcome.sh
        chmod +x /etc/profile.d/darkzsaid-welcome.sh
        echo "" > /etc/motd
    fi

    if ! grep -q "darkzsaid-welcome.sh" /root/.bashrc 2>/dev/null; then
cat >> /root/.bashrc <<'BASHRC'

# DarkZsaid welcome
if [ -f /etc/profile.d/darkzsaid-welcome.sh ]; then
    source /etc/profile.d/darkzsaid-welcome.sh
fi
BASHRC
    fi
}

clean_runtime_data() {
    mkdir -p /opt/darkzsaid/data
    mkdir -p /etc/adm-lite/userDIR

    # VPS nueva = sin clientes copiados
    : > /opt/darkzsaid/data/usuarios_ssh.db
    : > /opt/darkzsaid/data/tokens_zivpn.db
    : > /opt/darkzsaid/data/udpmod_users.db

    # contraseña global token default, interna
    echo "Steve2012" > /opt/darkzsaid/data/token_global.pass
    chmod 600 /opt/darkzsaid/data/token_global.pass

    # limpiar userDIR runtime
    find /etc/adm-lite/userDIR -type f -delete 2>/dev/null || true
}

default_ports_only() {
    # Default limpio: SSH 22 y DNS 53.
    iptables -D INPUT -p tcp --dport 22 -j ACCEPT 2>/dev/null || true
    iptables -I INPUT -p tcp --dport 22 -j ACCEPT

    iptables -D INPUT -p tcp --dport 53 -j ACCEPT 2>/dev/null || true
    iptables -I INPUT -p tcp --dport 53 -j ACCEPT

    iptables -D INPUT -p udp --dport 53 -j ACCEPT 2>/dev/null || true
    iptables -I INPUT -p udp --dport 53 -j ACCEPT

    ufw allow 22/tcp >/dev/null 2>&1 || true
    ufw allow 53/tcp >/dev/null 2>&1 || true
    ufw allow 53/udp >/dev/null 2>&1 || true
}

disable_extra_protocols() {
    # No arrancar protocolos premium automáticamente en VPS nueva.
    systemctl disable --now udpmod 2>/dev/null || true
    systemctl disable --now darkzsaid-udpmod-redirect 2>/dev/null || true
    systemctl disable --now zivpn 2>/dev/null || true
    systemctl disable --now stunnel4 2>/dev/null || true
    systemctl disable --now stunnel 2>/dev/null || true

    # Quitar redirecciones runtime heredadas si existieran.
    iptables -t nat -D PREROUTING -p udp --dport 10000:65000 -j REDIRECT --to-ports 36712 2>/dev/null || true
}

final_check() {
    bash -n /opt/darkzsaid/panel.sh
    bash -n /opt/darkzsaid/menus/users_menu.sh 2>/dev/null || true
    bash -n /opt/darkzsaid/menus/udpmod_users_menu.sh 2>/dev/null || true

    systemctl restart ssh 2>/dev/null || true

    ss -lntup | grep -q ':22'
}

banner
run_step "Instalando dependencias base" install_base
run_step "Descargando panel DarkZsaid" clone_panel
run_step "Preparando permisos y comandos" fix_permissions
run_step "Instalando bienvenida SSH premium" setup_welcome
run_step "Limpiando clientes y tokens de plantilla" clean_runtime_data
run_step "Aplicando puertos default 22 y DNS 53" default_ports_only
run_step "Dejando protocolos extra apagados" disable_extra_protocols
run_step "Verificando instalación limpia" final_check

echo ""
echo -e "${VERDE}${BOLD}✅ DARKZSAID INSTALADO LIMPIO CORRECTAMENTE${RESET}"
echo ""
echo -e "${BLANCO}${BOLD}Comandos:${RESET} ${CYAN}menu${RESET} / ${CYAN}darkzsaid${RESET}"
echo -e "${BLANCO}${BOLD}Default:${RESET} ${VERDE}SSH 22 + DNS 53${RESET}"
echo -e "${BLANCO}${BOLD}Clientes:${RESET} ${VERDE}0${RESET}"
echo -e "${BLANCO}${BOLD}Protocolos extra:${RESET} ${AMARILLO}apagados hasta activarlos desde el menú${RESET}"
echo ""
echo -e "${AMARILLO}Log completo:${RESET} $LOG"
echo ""
