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
BIN_REPO="$BASE_DIR/files/bin/zivpn"
BIN_SYS="/usr/local/bin/zivpn"
CONF_DIR="/etc/zivpn"
SERVICE="/etc/systemd/system/sipvpn-activex.service"

info "Preparando ZiVPN independiente..."

mkdir -p "$CONF_DIR" "$BASE_DIR/sipvpn-activex"

if [ ! -f "$BIN_REPO" ]; then
    fail "No existe motor ZiVPN en $BIN_REPO"
    exit 1
fi

cp -f "$BIN_REPO" "$BIN_SYS"
cp -f "$BIN_REPO" "$BASE_DIR/sipvpn-activex/ZiVPN" 2>/dev/null || true
chmod +x "$BIN_SYS" "$BASE_DIR/sipvpn-activex/ZiVPN" 2>/dev/null || true
ok "Motor ZiVPN instalado"

if [ ! -f "$CONF_DIR/zivpn.crt" ] || [ ! -f "$CONF_DIR/zivpn.key" ]; then
    info "Creando certificados ZiVPN..."
    openssl req -x509 -newkey rsa:2048 \
      -keyout "$CONF_DIR/zivpn.key" \
      -out "$CONF_DIR/zivpn.crt" \
      -days 3650 -nodes -subj "/CN=DarkZsaid" >/dev/null 2>&1
fi

if [ ! -f "$CONF_DIR/config.json" ]; then
cat > "$CONF_DIR/config.json" <<JSON
{
  "listen": ":5667",
  "cert": "/etc/zivpn/zivpn.crt",
  "key": "/etc/zivpn/zivpn.key"
}
JSON
fi

chmod 600 "$CONF_DIR/zivpn.key" 2>/dev/null || true
chmod 644 "$CONF_DIR/zivpn.crt" "$CONF_DIR/config.json" 2>/dev/null || true
ok "Config ZiVPN lista"

cat > "$SERVICE" <<SERVICEEOF
[Unit]
Description=SIPVPN ActiveX - DarkZsaid
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/zivpn
ExecStart=/usr/local/bin/zivpn server -c /etc/zivpn/config.json
Restart=always
RestartSec=3
Environment=ZIVPN_LOG_LEVEL=info
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
SERVICEEOF

ok "Servicio ZiVPN creado"

iptables -I INPUT -p udp --dport 5667 -j ACCEPT 2>/dev/null || true
iptables -t nat -C PREROUTING -p udp --dport 6000:19999 -j REDIRECT --to-ports 5667 2>/dev/null || \
iptables -t nat -A PREROUTING -p udp --dport 6000:19999 -j REDIRECT --to-ports 5667 2>/dev/null || true

systemctl daemon-reload
systemctl enable sipvpn-activex.service >/dev/null 2>&1 || true
systemctl restart sipvpn-activex.service
sleep 2

if systemctl is-active --quiet sipvpn-activex.service || ss -H -ulnp 2>/dev/null | grep -q ':5667'; then
    ok "ZIVPN activo en puerto 5667"
    exit 0
else
    fail "ZIVPN no levantó"
    journalctl -u sipvpn-activex.service --no-pager -n 25
    exit 1
fi
