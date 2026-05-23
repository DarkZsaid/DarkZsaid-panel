#!/bin/bash

clear

LOG="/root/darkzsaid-install.log"
: > "$LOG"

BLUE="\e[94m"
CYAN="\e[96m"
GREEN="\e[92m"
YELLOW="\e[93m"
RED="\e[91m"
WHITE="\e[97m"
BOLD="\e[1m"
RESET="\e[0m"

banner() {
clear
echo -e "${CYAN}${BOLD}"
echo "██████╗  █████╗ ██████╗ ██╗  ██╗███████╗███████╗ █████╗ ██╗██████╗ "
echo "██╔══██╗██╔══██╗██╔══██╗██║ ██╔╝╚══███╔╝██╔════╝██╔══██╗██║██╔══██╗"
echo "██║  ██║███████║██████╔╝█████╔╝   ███╔╝ ███████╗███████║██║██║  ██║"
echo "██║  ██║██╔══██║██╔══██╗██╔═██╗  ███╔╝  ╚════██║██╔══██║██║██║  ██║"
echo "██████╔╝██║  ██║██║  ██║██║  ██╗███████╗███████║██║  ██║██║██████╔╝"
echo "╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝╚═════╝ "
echo -e "${RESET}"
echo -e "${WHITE}${BOLD}          DARKZSAID VPS MANAGER / PANEL SSH${RESET}"
echo -e "${CYAN}────────────────────────────────────────────────────────────${RESET}"
echo ""
}

run_step() {
    local msg="$1"
    shift

    echo -ne "${CYAN}➜${RESET} ${WHITE}${BOLD}${msg}${RESET} "

    "$@" >> "$LOG" 2>&1 &
    local pid=$!

    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0

    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i+1) % 10 ))
        echo -ne "\r${CYAN}➜${RESET} ${WHITE}${BOLD}${msg}${RESET} ${YELLOW}${spin:$i:1}${RESET}"
        sleep 0.1
    done

    wait "$pid"
    local status=$?

    if [ "$status" -eq 0 ]; then
        echo -e "\r${GREEN}✅${RESET} ${WHITE}${BOLD}${msg}${RESET}"
    else
        echo -e "\r${RED}❌${RESET} ${WHITE}${BOLD}${msg}${RESET}"
        echo ""
        echo -e "${RED}Error. Revisa el log:${RESET} $LOG"
        exit 1
    fi
}

install_base() {
    apt update -y
    apt install -y git curl wget sudo dos2unix toilet figlet openssl iptables ufw
}

clone_panel() {
    rm -rf /opt/darkzsaid
    git clone https://github.com/stevenjosecarcamo-star/DarkZsaid--panel.git /opt/darkzsaid
}

fix_permissions() {
    cd /opt/darkzsaid || exit 1
    find /opt/darkzsaid -type f -name "*.sh" -exec dos2unix {} \;
    chmod +x /opt/darkzsaid/*.sh 2>/dev/null || true
    chmod +x /opt/darkzsaid/menus/*.sh 2>/dev/null || true
    bash -n /opt/darkzsaid/panel.sh
    ln -sf /opt/darkzsaid/panel.sh /usr/local/bin/menu
    ln -sf /opt/darkzsaid/panel.sh /usr/local/bin/darkzsaid
    chmod +x /usr/local/bin/menu /usr/local/bin/darkzsaid
}

setup_logo() {
    mkdir -p /etc/darkzsaid
    cat > /etc/darkzsaid/panel_logo.conf <<'CONF'
PANEL_LOGO_TEXT="DarkZsaid"
CONF
}

setup_udpmod() {
    mkdir -p /opt/UDPMOD /etc/udpmod

    wget -q -O /opt/UDPMOD/hysteria-linux-amd64 \
    https://github.com/apernet/hysteria/releases/download/v1.3.5/hysteria-linux-amd64

    chmod +x /opt/UDPMOD/hysteria-linux-amd64

    openssl req -x509 -newkey rsa:2048 -nodes \
    -keyout /opt/UDPMOD/udpmod.server.key \
    -out /opt/UDPMOD/udpmod.server.crt \
    -days 3650 \
    -subj "/CN=DarkZsaid"

    chmod 600 /opt/UDPMOD/udpmod.server.key
    chmod 644 /opt/UDPMOD/udpmod.server.crt

    cat > /etc/udpmod/config.json <<'CONF'
{
  "listen": ":36712",
  "cert": "/opt/UDPMOD/udpmod.server.crt",
  "key": "/opt/UDPMOD/udpmod.server.key",
  "obfs": "DarkZsaid",
  "auth": {
    "mode": "passwords",
    "config": ["DarkZsaid"]
  },
  "disable_udp": false,
  "alpn": "",
  "up_mbps": 17,
  "down_mbps": 15
}
CONF

    cat > /etc/systemd/system/udpmod.service <<'SERVICE'
[Unit]
Description=DarkZsaid UDPMod Hysteria v1 36712
After=network.target

[Service]
Type=simple
ExecStart=/opt/UDPMOD/hysteria-linux-amd64 server -c /etc/udpmod/config.json
Restart=always
RestartSec=3
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
SERVICE
}

setup_redirect() {
    cat > /etc/systemd/system/darkzsaid-udpmod-redirect.service <<'SERVICE'
[Unit]
Description=DarkZsaid UDPMod Redirect 10000-65000 to 36712
After=network.target udpmod.service
Wants=udpmod.service

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'iptables -t nat -D PREROUTING -p udp --dport 10000:65000 -j REDIRECT --to-ports 36712 2>/dev/null || true; iptables -t nat -A PREROUTING -p udp --dport 10000:65000 -j REDIRECT --to-ports 36712; iptables -D INPUT -p udp --dport 36712 -j ACCEPT 2>/dev/null || true; iptables -I INPUT -p udp --dport 36712 -j ACCEPT; ufw allow 36712/udp >/dev/null 2>&1 || true'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SERVICE
}

start_services() {
    systemctl daemon-reload
    systemctl enable udpmod darkzsaid-udpmod-redirect
    systemctl restart udpmod
    systemctl restart darkzsaid-udpmod-redirect
}

final_check() {
    bash -n /opt/darkzsaid/panel.sh
    systemctl is-active --quiet udpmod
    ss -lunp | grep -q 36712
}

banner
run_step "Instalando dependencias base" install_base
run_step "Descargando panel DarkZsaid" clone_panel
run_step "Preparando permisos y comandos" fix_permissions
run_step "Configurando logo superior" setup_logo
run_step "Descargando binarios UDPMod Hysteria" setup_udpmod
run_step "Configurando redirección UDP 10000:65000 → 36712" setup_redirect
run_step "Activando servicios DarkZsaid" start_services
run_step "Verificando instalación final" final_check

echo ""
echo -e "${GREEN}${BOLD}✅ DARKZSAID INSTALADO CORRECTAMENTE${RESET}"
echo ""
echo -e "${WHITE}${BOLD}Comandos disponibles:${RESET}"
echo -e "${CYAN}menu${RESET}"
echo -e "${CYAN}darkzsaid${RESET}"
echo ""
echo -e "${WHITE}${BOLD}UDPMod / Hysteria:${RESET}"
echo -e "Puerto: ${GREEN}36712${RESET}"
echo -e "OBFS: ${GREEN}DarkZsaid${RESET}"
echo -e "Password: ${GREEN}DarkZsaid${RESET}"
echo -e "Rango UDP: ${GREEN}10000:65000 → 36712${RESET}"
echo ""
echo -e "${YELLOW}Log de instalación:${RESET} $LOG"
echo ""

# ===== DARKZSAID WELCOME SSH =====
if [ -f /opt/darkzsaid/files/profile.d/darkzsaid-welcome.sh ]; then
    cp -f /opt/darkzsaid/files/profile.d/darkzsaid-welcome.sh /etc/profile.d/darkzsaid-welcome.sh
    chmod +x /etc/profile.d/darkzsaid-welcome.sh
    echo "" > /etc/motd
fi
