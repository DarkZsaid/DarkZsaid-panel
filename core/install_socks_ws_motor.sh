#!/bin/bash

BASE_DIR="/opt/darkzsaid"
SERVICE="ssh-ws"
PORT="80"
PY_FILE="$BASE_DIR/socks-python-ws.py"

VERDE="\033[1;32m"
CYAN="\033[1;36m"
ROJO="\033[1;31m"
RESET="\033[0m"

ok(){ echo -e "${VERDE}✓ $1${RESET}"; }
info(){ echo -e "${CYAN}➜ $1${RESET}"; }
fail(){ echo -e "${ROJO}✗ $1${RESET}"; exit 1; }

clear 2>/dev/null || true
echo -e "${CYAN}╔════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║${RESET}        ⚡ SOCKS PYTHON DIRECTO WS ⚡        ${CYAN}║${RESET}"
echo -e "${CYAN}╚════════════════════════════════════════════╝${RESET}"
echo

info "Preparando dependencias..."
apt-get update -y >/dev/null 2>&1 || true
apt-get install -y python3 >/dev/null 2>&1 || true
ok "Dependencias listas"

info "Verificando archivo Python..."
[ -f "$PY_FILE" ] || fail "No existe $PY_FILE"
chmod +x "$PY_FILE" 2>/dev/null || true
ok "Archivo Python listo"

info "Creando servicio systemd puerto 80..."
cat > /etc/systemd/system/${SERVICE}.service <<SERVICEEOF
[Unit]
Description=SOCKS Python Directo WS Puerto 80 - DarkZsaid
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 $PY_FILE --listen-port 80 --local-port 22 --response 200 --banner "ADM SJCC"
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
SERVICEEOF

systemctl daemon-reload
systemctl enable ${SERVICE}.service >/dev/null 2>&1 || true

info "Abriendo puerto 80..."
ufw allow 80/tcp >/dev/null 2>&1 || true
iptables -C INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null || iptables -I INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null || true
ok "Puerto 80 permitido"

info "Iniciando SOCKS Python Directo WS..."
systemctl restart ${SERVICE}.service
sleep 2

if systemctl is-active --quiet ${SERVICE}.service && ss -tlnp 2>/dev/null | grep -q ':80'; then
    ok "SOCKS Python Directo WS activo en puerto 80"
else
    fail "SOCKS Python Directo WS no arrancó"
fi

echo
echo -e "${CYAN}Servidor/IP:${RESET} $(curl -4 -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')"
echo -e "${CYAN}Puerto WS:${RESET} 80"
echo -e "${CYAN}Modo:${RESET} SOCKS Python Directo WS"
echo
