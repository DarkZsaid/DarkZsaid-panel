#!/bin/bash
set +e

VERDE="\033[1;32m"
ROJO="\033[1;31m"
AMARILLO="\033[1;33m"
RESET="\033[0m"

ok(){ echo -e "${VERDE}✓ $1${RESET}"; }
fail(){ echo -e "${ROJO}✗ $1${RESET}"; }
info(){ echo -e "${AMARILLO}➜ $1${RESET}"; }

BASE_DIR="/opt/darkzsaid"
BIN_REPO="$BASE_DIR/files/udpmod/hysteria-linux-amd64"
BIN_DIR="/opt/UDPMOD"
BIN="$BIN_DIR/hysteria-linux-amd64"
CONF_DIR="/etc/udpmod"
CONF="$CONF_DIR/config.json"
CRT="$CONF_DIR/udpmod.server.crt"
KEY="$CONF_DIR/udpmod.server.key"
SERVICE="/etc/systemd/system/udpmod.service"
PORT="36712"
OBFS="DarkZsaid"
PASS="DarkZsaid"

info "Preparando UDPMod / Hysteria independiente..."

systemctl stop udp-custom.service 2>/dev/null || true
pkill -f "/usr/bin/udp" 2>/dev/null || true

mkdir -p "$BIN_DIR" "$CONF_DIR"

if [ -f "$BIN_REPO" ]; then
    cp -f "$BIN_REPO" "$BIN"
    chmod +x "$BIN"
elif [ -f "$BIN" ]; then
    chmod +x "$BIN"
else
    fail "No existe motor UDPMOD en $BIN_REPO"
    exit 1
fi

ok "Motor UDPMOD listo"

if [ ! -f "$CRT" ] || [ ! -f "$KEY" ]; then
    info "Creando certificado UDPMOD..."
    openssl req -x509 -newkey rsa:2048 \
      -keyout "$KEY" \
      -out "$CRT" \
      -days 3650 -nodes -subj "/CN=DarkZsaid" >/dev/null 2>&1
fi

chmod 600 "$KEY" 2>/dev/null || true
chmod 644 "$CRT" 2>/dev/null || true

cat > "$CONF" <<JSON
{
  "listen": ":$PORT",
  "protocol": "udp",
  "obfs": "$OBFS",
  "auth": {
    "mode": "passwords",
    "config": [
      "$PASS"
    ]
  },
  "cert": "$CRT",
  "key": "$KEY"
}
JSON

chmod 644 "$CONF"
ok "Config UDPMOD lista"

cat > "$SERVICE" <<SERVICEEOF
[Unit]
Description=DarkZsaid UDPMod Hysteria v1 36712
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/UDPMOD
ExecStart=/opt/UDPMOD/hysteria-linux-amd64 server -c /etc/udpmod/config.json
Restart=always
RestartSec=3
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
SERVICEEOF

ok "Servicio UDPMOD creado"

ufw allow ${PORT}/udp 2>/dev/null || true
iptables -I INPUT -p udp --dport "$PORT" -j ACCEPT 2>/dev/null || true

iptables -t nat -C PREROUTING -p udp --dport 20000:39999 -j REDIRECT --to-ports "$PORT" 2>/dev/null || \
iptables -t nat -A PREROUTING -p udp --dport 20000:39999 -j REDIRECT --to-ports "$PORT" 2>/dev/null || true

systemctl daemon-reload
systemctl enable udpmod.service >/dev/null 2>&1 || true
systemctl restart udpmod.service
sleep 3

if systemctl is-active --quiet udpmod.service && ss -H -ulnp 2>/dev/null | grep -q ":$PORT"; then
    ok "UDPMOD activo en puerto $PORT"
    exit 0
else
    fail "UDPMOD no levantó"
    journalctl -u udpmod.service --no-pager -n 35
    exit 1
fi
