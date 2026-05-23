#!/bin/bash

clear

LOG="/root/darkzsaid-install.log"
: > "$LOG"

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

    local spin='|/-\'
    local i=0

    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i+1) % 4 ))
        echo -ne "\r${CYAN}➜${RESET} ${WHITE}${BOLD}${msg}${RESET} ${YELLOW}${spin:$i:1}${RESET}"
        sleep 0.15
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
    apt install -y git curl wget sudo dos2unix toilet figlet openssl iptables ufw net-tools
}

clone_panel() {
    rm -rf /opt/darkzsaid
    git clone https://github.com/DarkZsaid/DarkZsaid-panel.git /opt/darkzsaid || \
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

setup_welcome() {
    if [ -f /opt/darkzsaid/files/profile.d/darkzsaid-welcome.sh ]; then
        cp -f /opt/darkzsaid/files/profile.d/darkzsaid-welcome.sh /etc/profile.d/darkzsaid-welcome.sh
        chmod +x /etc/profile.d/darkzsaid-welcome.sh
        echo "" > /etc/motd
    fi
}

setup_udpmod() {
    mkdir -p /opt/UDPMOD /etc/udpmod

    wget -q -O /opt/UDPMOD/hysteria-linux-amd64 \
    https://github.com/apernet/hysteria/releases/download/v1.3.5/hysteria-linux-amd64

    chmod +x /opt/UDPMOD/hysteria-linux-amd64

    if [ -f /opt/darkzsaid/files/udpmod/udpmod.server.crt ]; then
        cp -f /opt/darkzsaid/files/udpmod/udpmod.server.crt /opt/UDPMOD/udpmod.server.crt
        cp -f /opt/darkzsaid/files/udpmod/udpmod.server.key /opt/UDPMOD/udpmod.server.key
    else
        openssl req -x509 -newkey rsa:2048 -nodes \
        -keyout /opt/UDPMOD/udpmod.server.key \
        -out /opt/UDPMOD/udpmod.server.crt \
        -days 3650 \
        -subj "/CN=DarkZsaid"
    fi

    chmod 600 /opt/UDPMOD/udpmod.server.key
    chmod 644 /opt/UDPMOD/udpmod.server.crt

    if [ -f /opt/darkzsaid/files/udpmod/config.json ]; then
        cp -f /opt/darkzsaid/files/udpmod/config.json /etc/udpmod/config.json
    else
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
    fi

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

setup_udp_redirect() {
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

setup_zivpn() {
    mkdir -p /etc/zivpn

    if [ -f /opt/darkzsaid/files/bin/zivpn ]; then
        cp -f /opt/darkzsaid/files/bin/zivpn /usr/local/bin/zivpn
        chmod +x /usr/local/bin/zivpn
    fi

    if [ ! -x /usr/local/bin/zivpn ]; then
        echo "No existe binario ZiVPN en /usr/local/bin/zivpn"
        exit 1
    fi

    if [ -f /opt/darkzsaid/files/zivpn/zivpn.crt ]; then
        cp -f /opt/darkzsaid/files/zivpn/zivpn.crt /etc/zivpn/zivpn.crt
        cp -f /opt/darkzsaid/files/zivpn/zivpn.key /etc/zivpn/zivpn.key
    else
        openssl req -x509 -newkey rsa:2048 -nodes \
        -keyout /etc/zivpn/zivpn.key \
        -out /etc/zivpn/zivpn.crt \
        -days 3650 \
        -subj "/CN=zivpn"
    fi

    if [ -f /opt/darkzsaid/files/zivpn/config.json ]; then
        cp -f /opt/darkzsaid/files/zivpn/config.json /etc/zivpn/config.json
    else
        cat > /etc/zivpn/config.json <<'CONF'
{
  "listen": ":5667",
  "cert": "/etc/zivpn/zivpn.crt",
  "key": "/etc/zivpn/zivpn.key",
  "max_conn": 0,
  "obfs": "zivpn",
  "auth": {
    "mode": "passwords",
    "config": ["DarkZsaid"]
  }
}
CONF
    fi

    cat > /etc/systemd/system/zivpn.service <<'SERVICE'
[Unit]
Description=DarkZsaid ZiVPN Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/zivpn server -c /etc/zivpn/config.json
Restart=always
RestartSec=3
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
SERVICE

    iptables -D INPUT -p udp --dport 5667 -j ACCEPT 2>/dev/null || true
    iptables -I INPUT -p udp --dport 5667 -j ACCEPT
    ufw allow 5667/udp >/dev/null 2>&1 || true
}

start_services() {
    systemctl daemon-reload
    systemctl enable udpmod darkzsaid-udpmod-redirect zivpn
    systemctl restart udpmod
    systemctl restart darkzsaid-udpmod-redirect
    systemctl restart zivpn
}

final_check() {
    bash -n /opt/darkzsaid/panel.sh
    systemctl is-active --quiet udpmod
    ss -lunp | grep -q 36712
    systemctl is-active --quiet zivpn
    ss -lunp | grep -q 5667
}

banner
run_step "Instalando dependencias base" install_base
run_step "Descargando panel DarkZsaid" clone_panel
run_step "Preparando permisos y comandos" fix_permissions
run_step "Instalando bienvenida SSH premium" setup_welcome
run_step "Configurando UDPMod Hysteria 36712" setup_udpmod
run_step "Aplicando redirección UDP 10000:65000 → 36712" setup_udp_redirect
run_step "Configurando ZiVPN 5667" setup_zivpn
run_step "Activando servicios" start_services
run_step "Verificando instalación final" final_check

echo ""
echo -e "${GREEN}${BOLD}✅ DARKZSAID INSTALADO CORRECTAMENTE${RESET}"
echo ""
echo -e "${WHITE}${BOLD}Comandos:${RESET} ${CYAN}menu${RESET} / ${CYAN}darkzsaid${RESET}"
echo -e "${WHITE}${BOLD}UDPMod:${RESET} puerto ${GREEN}36712${RESET} | OBFS ${GREEN}DarkZsaid${RESET} | PASS ${GREEN}DarkZsaid${RESET}"
echo -e "${WHITE}${BOLD}ZiVPN:${RESET} puerto ${GREEN}5667${RESET} | OBFS ${GREEN}zivpn${RESET} | PASS ${GREEN}DarkZsaid${RESET}"
echo -e "${WHITE}${BOLD}Rango UDP:${RESET} ${GREEN}10000:65000 → 36712${RESET}"
echo ""
echo -e "${YELLOW}Log:${RESET} $LOG"
echo ""

# ===== DARKZSAID RUNTIME FINAL: TOKEN / UDPMOD / ZIVPN / WELCOME =====
mkdir -p /opt/darkzsaid/data /etc/adm-lite/userDIR /etc/udpmod /opt/UDPMOD /etc/zivpn /etc/profile.d

if [ -f /opt/darkzsaid/files/profile.d/darkzsaid-welcome.sh ]; then
  cp -f /opt/darkzsaid/files/profile.d/darkzsaid-welcome.sh /etc/profile.d/darkzsaid-welcome.sh
  chmod +x /etc/profile.d/darkzsaid-welcome.sh
  echo "" > /etc/motd
fi

if [ -f /opt/darkzsaid/files/data/token_global.pass ]; then
  cp -f /opt/darkzsaid/files/data/token_global.pass /opt/darkzsaid/data/token_global.pass
else
  echo "Steve2012" > /opt/darkzsaid/data/token_global.pass
fi
chmod 600 /opt/darkzsaid/data/token_global.pass 2>/dev/null || true

[ -f /opt/darkzsaid/files/data/tokens_zivpn.db ] && cp -f /opt/darkzsaid/files/data/tokens_zivpn.db /opt/darkzsaid/data/tokens_zivpn.db
[ -f /opt/darkzsaid/files/data/usuarios_ssh.db ] && cp -f /opt/darkzsaid/files/data/usuarios_ssh.db /opt/darkzsaid/data/usuarios_ssh.db
[ -f /opt/darkzsaid/files/data/udpmod_users.db ] && cp -f /opt/darkzsaid/files/data/udpmod_users.db /opt/darkzsaid/data/udpmod_users.db

[ -f /opt/darkzsaid/files/udpmod/config.json ] && cp -f /opt/darkzsaid/files/udpmod/config.json /etc/udpmod/config.json
[ -f /opt/darkzsaid/files/udpmod/udpmod.server.crt ] && cp -f /opt/darkzsaid/files/udpmod/udpmod.server.crt /opt/UDPMOD/udpmod.server.crt
[ -f /opt/darkzsaid/files/udpmod/udpmod.server.key ] && cp -f /opt/darkzsaid/files/udpmod/udpmod.server.key /opt/UDPMOD/udpmod.server.key

[ -f /opt/darkzsaid/files/zivpn/config.json ] && cp -f /opt/darkzsaid/files/zivpn/config.json /etc/zivpn/config.json
[ -f /opt/darkzsaid/files/zivpn/zivpn.crt ] && cp -f /opt/darkzsaid/files/zivpn/zivpn.crt /etc/zivpn/zivpn.crt
[ -f /opt/darkzsaid/files/zivpn/zivpn.key ] && cp -f /opt/darkzsaid/files/zivpn/zivpn.key /etc/zivpn/zivpn.key
[ -f /opt/darkzsaid/files/bin/zivpn ] && cp -f /opt/darkzsaid/files/bin/zivpn /usr/local/bin/zivpn && chmod +x /usr/local/bin/zivpn

[ -f /opt/darkzsaid/files/systemd/udpmod.service ] && cp -f /opt/darkzsaid/files/systemd/udpmod.service /etc/systemd/system/udpmod.service
[ -f /opt/darkzsaid/files/systemd/darkzsaid-udpmod-redirect.service ] && cp -f /opt/darkzsaid/files/systemd/darkzsaid-udpmod-redirect.service /etc/systemd/system/darkzsaid-udpmod-redirect.service
[ -f /opt/darkzsaid/files/systemd/zivpn.service ] && cp -f /opt/darkzsaid/files/systemd/zivpn.service /etc/systemd/system/zivpn.service

systemctl daemon-reload
systemctl enable udpmod darkzsaid-udpmod-redirect zivpn 2>/dev/null || true
systemctl restart udpmod 2>/dev/null || true
systemctl restart darkzsaid-udpmod-redirect 2>/dev/null || true
systemctl restart zivpn 2>/dev/null || true
