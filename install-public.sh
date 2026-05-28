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


ensure_binaries_clean() {
    mkdir -p /opt/UDPMOD /etc/udpmod /etc/zivpn /opt/darkzsaid/files/bin

    # Binario Hysteria v1 para UDPMod, pero SIN activar servicio por defecto
    if [ ! -x /opt/UDPMOD/hysteria-linux-amd64 ]; then
        wget -q -O /opt/UDPMOD/hysteria-linux-amd64 "https://github.com/apernet/hysteria/releases/download/v1.3.5/hysteria-linux-amd64"
        chmod +x /opt/UDPMOD/hysteria-linux-amd64
    fi

    # ZiVPN: copiar si viene guardado en el repo. No activar por defecto.
    if [ -f /opt/darkzsaid/files/bin/zivpn ]; then
        cp -f /opt/darkzsaid/files/bin/zivpn /usr/local/bin/zivpn
        chmod +x /usr/local/bin/zivpn
    fi

    # Certificados base si algún protocolo se activa después desde el menú
    if [ ! -f /opt/UDPMOD/udpmod.server.crt ] || [ ! -f /opt/UDPMOD/udpmod.server.key ]; then
        openssl req -x509 -newkey rsa:2048 -nodes \
          -keyout /opt/UDPMOD/udpmod.server.key \
          -out /opt/UDPMOD/udpmod.server.crt \
          -days 3650 \
          -subj "/CN=DarkZsaid" >/dev/null 2>&1
    fi

    if [ ! -f /etc/zivpn/zivpn.crt ] || [ ! -f /etc/zivpn/zivpn.key ]; then
        openssl req -x509 -newkey rsa:2048 -nodes \
          -keyout /etc/zivpn/zivpn.key \
          -out /etc/zivpn/zivpn.crt \
          -days 3650 \
          -subj "/CN=zivpn" >/dev/null 2>&1
    fi

    # Reconfirmar permisos del panel
    chmod +x /opt/darkzsaid/panel.sh 2>/dev/null || true
    chmod +x /opt/darkzsaid/menus/*.sh 2>/dev/null || true
    ln -sf /opt/darkzsaid/panel.sh /usr/local/bin/menu
    ln -sf /opt/darkzsaid/panel.sh /usr/local/bin/darkzsaid
    chmod +x /usr/local/bin/menu /usr/local/bin/darkzsaid

    # Verificación de binarios obligatorios
    for bin in bash curl wget git python3 iptables ss systemctl openssl toilet figlet; do
        command -v "$bin" >/dev/null 2>&1 || return 1
    done

    # Hysteria sí debe quedar listo, pero apagado
    [ -x /opt/UDPMOD/hysteria-linux-amd64 ] || return 1

    return 0
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
run_step "Verificando y reparando binarios" ensure_binaries_clean
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

# ===== DARKZSAID RUNTIME SERVICES AUTO-RESTORE =====
echo
echo "===== RESTAURANDO SERVICIOS RUNTIME DARKZSAID ====="

APP_DIR="${APP_DIR:-/opt/darkzsaid}"

# UDPMod motor/config
if [ -f "$APP_DIR/backup_runtime/udpmod/config.json" ]; then
  mkdir -p /etc/udpmod
  cp -f "$APP_DIR/backup_runtime/udpmod/config.json" /etc/udpmod/config.json
  chmod 644 /etc/udpmod/config.json
fi

if [ -f "$APP_DIR/backup_runtime/udpmod/udpmod.service" ]; then
  cp -f "$APP_DIR/backup_runtime/udpmod/udpmod.service" /etc/systemd/system/udpmod.service
  chmod 644 /etc/systemd/system/udpmod.service
fi

if [ -f "$APP_DIR/backup_runtime/udpmod/darkzsaid-udpmod-redirect.service" ]; then
  cp -f "$APP_DIR/backup_runtime/udpmod/darkzsaid-udpmod-redirect.service" /etc/systemd/system/darkzsaid-udpmod-redirect.service
  chmod 644 /etc/systemd/system/darkzsaid-udpmod-redirect.service
fi

# ZiVPN
# Copiar binario ZiVPN a las 2 rutas posibles:
# 1) /usr/local/bin/zivpn
# 2) /opt/darkzsaid/sipvpn-activex/ZiVPN
if [ -f "$APP_DIR/files/bin/zivpn" ]; then
  mkdir -p /usr/local/bin
  mkdir -p "$APP_DIR/sipvpn-activex"

  cp -f "$APP_DIR/files/bin/zivpn" /usr/local/bin/zivpn
  chmod +x /usr/local/bin/zivpn

  cp -f "$APP_DIR/files/bin/zivpn" "$APP_DIR/sipvpn-activex/ZiVPN"
  chmod +x "$APP_DIR/sipvpn-activex/ZiVPN"
fi

if [ -f "$APP_DIR/backup_runtime/zivpn/zivpn.service" ]; then
  cp -f "$APP_DIR/backup_runtime/zivpn/zivpn.service" /etc/systemd/system/zivpn.service
  chmod 644 /etc/systemd/system/zivpn.service
fi

systemctl daemon-reload

# Encender UDPMod si existe
if [ -f /etc/systemd/system/udpmod.service ]; then
  systemctl enable udpmod.service >/dev/null 2>&1 || true
  systemctl restart udpmod.service >/dev/null 2>&1 || true
fi

# Encender redirect UDPMod si existe
if [ -f /etc/systemd/system/darkzsaid-udpmod-redirect.service ]; then
  systemctl enable darkzsaid-udpmod-redirect.service >/dev/null 2>&1 || true
  systemctl restart darkzsaid-udpmod-redirect.service >/dev/null 2>&1 || true
fi

# Encender ZiVPN si existe
if [ -f /etc/systemd/system/zivpn.service ]; then
  systemctl enable zivpn.service >/dev/null 2>&1 || true
  systemctl restart zivpn.service >/dev/null 2>&1 || true
fi

echo "===== VERIFICANDO SERVICIOS ====="
systemctl is-active udpmod.service >/dev/null 2>&1 && echo "✅ UDPMod activo" || echo "⚠️ UDPMod no activo"
systemctl is-active zivpn.service >/dev/null 2>&1 && echo "✅ ZiVPN activo" || echo "⚠️ ZiVPN no activo"
systemctl is-active darkzsaid-udpmod-redirect.service >/dev/null 2>&1 && echo "✅ Redirect UDPMod activo" || echo "⚠️ Redirect UDPMod no activo"

echo "===== PUERTOS UDP ====="
ss -lunpt | grep -E "36712|5667|6000|19999|zivpn|hysteria" || true
# ===== END DARKZSAID RUNTIME SERVICES AUTO-RESTORE =====
