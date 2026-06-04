#!/bin/bash

limpiar_pantalla() {
    printf '\033[H\033[2J\033[3J'
}


source /opt/darkzsaid/menus/ui_instalacion.sh 2>/dev/null || true

titulo_instalacion "UDP CUSTOM HTTP"

paso "Preparando dependencias..."
apt-get update -y >/dev/null 2>&1
apt-get install -y curl iptables libpam0g >/dev/null 2>&1
ok "Dependencias listas"

paso "Detectando arquitectura..."
ARCH=$(uname -m)

if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
    BIN_URL="https://github.com/firewallfalcons/FirewallFalcon-Manager/raw/main/udp/udp-custom-linux-arm"
else
    BIN_URL="https://github.com/firewallfalcons/FirewallFalcon-Manager/raw/main/udp/udp-custom-linux-amd64"
fi

ok "Arquitectura detectada: $ARCH"

paso "Descargando motor UDP Custom..."
curl -L -s -f -o /usr/bin/udp "$BIN_URL" >/dev/null 2>&1

if [[ ! -s /usr/bin/udp ]]; then
    fail "No se pudo descargar el motor UDP Custom"
    pausa_bonita
    exit 1
fi

chmod +x /usr/bin/udp
ok "Motor UDP Custom instalado"

paso "Creando configuración..."
cat > /usr/bin/config.json <<'JSON'
{
  "listen": ":36712",
  "stream_buffer": 8388608,
  "receive_buffer": 8388608,
  "auth": {
    "mode": "passwords"
  }
}
JSON
ok "Configuración creada"

paso "Creando servicio systemd..."
cat > /etc/systemd/system/udp-custom.service <<'EOF2'
[Unit]
Description=UDP Custom HTTP Custom
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/udp server --config /usr/bin/config.json --exclude 22,80,443,7300,7100,7200
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF2
ok "Servicio creado"

paso "Abriendo puerto UDP 36712..."
ufw allow 36712/udp >/dev/null 2>&1 || true
iptables -I INPUT -p udp --dport 36712 -j ACCEPT >/dev/null 2>&1 || true
ok "Puerto 36712 permitido"

paso "Iniciando UDP Custom..."
systemctl daemon-reload >/dev/null 2>&1
systemctl enable udp-custom >/dev/null 2>&1
systemctl restart udp-custom >/dev/null 2>&1

sleep 2

if systemctl is-active --quiet udp-custom && ss -ulnp 2>/dev/null | grep -q ":36712"; then
    ok "UDP Custom activo en puerto 36712"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BLANCO}Servidor/IP:${RESET} $(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')"
    echo -e "${BLANCO}Puerto UDP:${RESET} 36712"
    echo -e "${BLANCO}Modo:${RESET} UDP Custom / HTTP Custom"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
else
    fail "UDP Custom no levantó correctamente"
    echo ""
    echo -e "${AMARILLO}Revisa con:${RESET} journalctl -u udp-custom.service --no-pager -n 30"
fi

pausa_bonita
