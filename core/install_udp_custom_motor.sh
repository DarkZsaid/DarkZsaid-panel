#!/bin/bash

ROJO="\033[1;31m"
VERDE="\033[1;32m"
AMARILLO="\033[1;33m"
AZUL="\033[1;34m"
CYAN="\033[1;36m"
BLANCO="\033[1;37m"
RESET="\033[0m"

ok(){ echo -e "${VERDE}✓ $1${RESET}"; }
fail(){ echo -e "${ROJO}✗ $1${RESET}"; }
paso(){ echo -e "${AZUL}➜ $1${RESET}"; }
warn(){ echo -e "${AMARILLO}➜ $1${RESET}"; }

UDP_PORT="36712"
BIN_URL="https://raw.github.com/http-custom/udp-custom/main/bin/udp-custom-linux-amd64"

clear
echo -e "${CYAN}╔════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║${RESET}        ${BLANCO}⚡ UDP CUSTOM HTTP ⚡${RESET}          ${CYAN}║${RESET}"
echo -e "${CYAN}╚════════════════════════════════════════════╝${RESET}"
echo

paso "Preparando dependencias..."
apt-get update -y >/dev/null 2>&1 || true
apt-get install -y curl iptables >/dev/null 2>&1 || true
ok "Dependencias listas"

paso "Detectando arquitectura..."
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64|amd64)
    ok "Arquitectura detectada: x86_64"
    ;;
  *)
    fail "Arquitectura no soportada: $ARCH"
    exit 1
    ;;
esac

paso "Descargando motor UDP Custom..."
curl -L --fail --retry 3 -o /usr/bin/udp "$BIN_URL" >/dev/null 2>&1 || {
  fail "No se pudo descargar el motor UDP Custom"
  exit 1
}
chmod +x /usr/bin/udp
ok "Motor UDP Custom instalado"

paso "Creando configuración..."
cat > /usr/bin/config.json <<JSON
{
  "listen": ":${UDP_PORT}",
  "stream_buffer": 8388608,
  "receive_buffer": 8388608,
  "auth": {
    "mode": "passwords"
  }
}
JSON
ok "Configuración creada"

paso "Creando servicio systemd..."
cat > /etc/systemd/system/udp-custom.service <<EOF2
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

paso "Abriendo puerto UDP ${UDP_PORT}..."
ufw allow ${UDP_PORT}/udp >/dev/null 2>&1 || true
iptables -I INPUT -p udp --dport ${UDP_PORT} -j ACCEPT 2>/dev/null || true
ok "Puerto ${UDP_PORT} permitido"

paso "Aplicando redirección UDP Custom hacia ${UDP_PORT}..."
iptables -t nat -D PREROUTING -p udp --dport 20000:39999 -j REDIRECT --to-ports ${UDP_PORT} 2>/dev/null || true
iptables -t nat -A PREROUTING -p udp --dport 20000:39999 -j REDIRECT --to-ports ${UDP_PORT} 2>/dev/null || true

iptables -t nat -D PREROUTING -p udp --dport 36700:36800 -j REDIRECT --to-ports ${UDP_PORT} 2>/dev/null || true
iptables -t nat -A PREROUTING -p udp --dport 36700:36800 -j REDIRECT --to-ports ${UDP_PORT} 2>/dev/null || true
ok "Redirección UDP Custom aplicada hacia ${UDP_PORT}"

paso "Apagando UDPMod/Hysteria para liberar puerto ${UDP_PORT}..."
systemctl stop udpmod.service 2>/dev/null || true
systemctl disable udpmod.service 2>/dev/null || true
pkill -f 'hysteria-linux' 2>/dev/null || true
ok "UDPMod/Hysteria apagado si estaba activo"

paso "Iniciando UDP Custom..."
systemctl daemon-reload
systemctl enable udp-custom.service >/dev/null 2>&1 || true
systemctl restart udp-custom.service
sleep 3

if systemctl is-active --quiet udp-custom.service && ss -H -ulnp 2>/dev/null | grep -q ":${UDP_PORT}"; then
  ok "UDP Custom activo en puerto ${UDP_PORT}"
else
  fail "UDP Custom no levantó"
  echo
  journalctl -u udp-custom.service --no-pager -n 30
  exit 1
fi

echo
echo -e "${AZUL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BLANCO}Servidor/IP:${RESET} $(curl -4 -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')"
echo -e "${BLANCO}Puerto UDP:${RESET} ${UDP_PORT}"
echo -e "${BLANCO}Modo:${RESET} UDP Custom / HTTP Custom"
echo -e "${AZUL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
