#!/bin/bash
set +e

INSTALL_DIR="${INSTALL_DIR:-/opt/darkzsaid}"
LOGFILE="${LOGFILE:-/tmp/darkzsaid-install.log}"

mkdir -p /opt/UDPMOD /etc/udpmod >> "$LOGFILE" 2>&1

if [[ -f "$INSTALL_DIR/files/udpmod/hysteria-linux-amd64" ]]; then
  cp -f "$INSTALL_DIR/files/udpmod/hysteria-linux-amd64" /opt/UDPMOD/hysteria-linux-amd64 >> "$LOGFILE" 2>&1
  chmod +x /opt/UDPMOD/hysteria-linux-amd64
fi

if [[ ! -f /opt/UDPMOD/udpmod.server.key || ! -f /opt/UDPMOD/udpmod.server.crt ]]; then
  openssl req -x509 -newkey rsa:2048 -nodes \
    -keyout /opt/UDPMOD/udpmod.server.key \
    -out /opt/UDPMOD/udpmod.server.crt \
    -subj "/CN=DarkZsaid-UDPMod" \
    -days 3650 >> "$LOGFILE" 2>&1
fi

chmod 600 /opt/UDPMOD/udpmod.server.key 2>/dev/null || true
chmod 644 /opt/UDPMOD/udpmod.server.crt 2>/dev/null || true

cat > /etc/udpmod/config.json <<'JSON'
{
  "listen": ":36712",
  "protocol": "udp",
  "cert": "/opt/UDPMOD/udpmod.server.crt",
  "key": "/opt/UDPMOD/udpmod.server.key",
  "obfs": {
    "type": "salamander",
    "salamander": {
      "password": "DarkZsaid"
    }
  },
  "auth": {
    "type": "password",
    "password": "DarkZsaid"
  },
  "bandwidth": {
    "up": "17 mbps",
    "down": "15 mbps"
  },
  "disable_udp": false
}
JSON

chmod 644 /etc/udpmod/config.json

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

systemctl daemon-reload >> "$LOGFILE" 2>&1
systemctl enable udpmod.service >> "$LOGFILE" 2>&1

exit 0
