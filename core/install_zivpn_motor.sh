#!/bin/bash
set +e

INSTALL_DIR="${INSTALL_DIR:-/opt/darkzsaid}"
LOGFILE="${LOGFILE:-/tmp/darkzsaid-install.log}"

mkdir -p /etc/zivpn "$INSTALL_DIR/sipvpn-activex" >> "$LOGFILE" 2>&1

if [[ -f "$INSTALL_DIR/files/bin/zivpn" ]]; then
  cp -f "$INSTALL_DIR/files/bin/zivpn" /usr/local/bin/zivpn >> "$LOGFILE" 2>&1
  cp -f "$INSTALL_DIR/files/bin/zivpn" "$INSTALL_DIR/sipvpn-activex/ZiVPN" >> "$LOGFILE" 2>&1
  chmod +x /usr/local/bin/zivpn "$INSTALL_DIR/sipvpn-activex/ZiVPN"
fi

if [[ ! -f /etc/zivpn/zivpn.key || ! -f /etc/zivpn/zivpn.crt ]]; then
  openssl req -x509 -newkey rsa:2048 -nodes \
    -keyout /etc/zivpn/zivpn.key \
    -out /etc/zivpn/zivpn.crt \
    -subj "/CN=DarkZsaid-ZiVPN" \
    -days 3650 >> "$LOGFILE" 2>&1
fi

chmod 600 /etc/zivpn/zivpn.key 2>/dev/null || true
chmod 644 /etc/zivpn/zivpn.crt 2>/dev/null || true

cat > /etc/zivpn/config.json <<'JSON'
{
  "listen": ":5667",
  "cert": "/etc/zivpn/zivpn.crt",
  "key": "/etc/zivpn/zivpn.key",
  "obfs": "DarkZsaid"
}
JSON

chmod 644 /etc/zivpn/config.json

cat > /etc/systemd/system/sipvpn-activex.service <<SERVICE
[Unit]
Description=SIPVPN ActiveX - DarkZsaid
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/zivpn
ExecStart=$INSTALL_DIR/sipvpn-activex/ZiVPN server -c /etc/zivpn/config.json
Restart=always
RestartSec=3
Environment=ZIVPN_LOG_LEVEL=info
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
SERVICE

systemctl stop zivpn.service >> "$LOGFILE" 2>&1 || true
systemctl disable zivpn.service >> "$LOGFILE" 2>&1 || true
systemctl daemon-reload >> "$LOGFILE" 2>&1
systemctl enable sipvpn-activex.service >> "$LOGFILE" 2>&1

exit 0
