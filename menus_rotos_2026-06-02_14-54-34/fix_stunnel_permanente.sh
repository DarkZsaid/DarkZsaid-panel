#!/bin/bash

pantalla_limpia() {
    printf '\033c'
}


limpiar_pantalla() {
    printf '\033[H\033[2J\033[3J'
}


set +e

STUNNEL_DIR="/etc/darkzsaid/stunnel"
STUNNEL_CONF="$STUNNEL_DIR/stunnel.conf"
STUNNEL_CERT="$STUNNEL_DIR/stunnel.pem"
SERVICE_FILE="/etc/systemd/system/darkzsaid-stunnel.service"

ROJO="\e[31m"
VERDE="\e[32m"
AMARILLO="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"
BOLD="\e[1m"

echo -e "${CYAN}Reparando Stunnel SSL DarkZsaid...${RESET}"

if [[ "$(id -u)" -ne 0 ]]; then
  echo -e "${ROJO}Ejecuta como root.${RESET}"
  exit 1
fi

apt update -y >/dev/null 2>&1
apt install -y stunnel4 openssl >/dev/null 2>&1

if [[ ! -x /usr/bin/stunnel4 ]]; then
  echo -e "${ROJO}Error: stunnel4 no quedó instalado.${RESET}"
  exit 1
fi

mkdir -p "$STUNNEL_DIR"
mkdir -p /run

if [[ ! -f "$STUNNEL_CERT" ]]; then
  openssl req -new -x509 -days 3650 -nodes \
    -out "$STUNNEL_CERT" \
    -keyout "$STUNNEL_CERT" \
    -subj "/CN=DarkZsaid" >/dev/null 2>&1
fi

chmod 600 "$STUNNEL_CERT"

cat > "$STUNNEL_CONF" <<EOF2
pid = /run/darkzsaid-stunnel.pid
foreground = yes
client = no

[ssh-ssl]
accept = 443
connect = 127.0.0.1:22
cert = $STUNNEL_CERT
EOF2

cat > "$SERVICE_FILE" <<EOF2
[Unit]
Description=DarkZsaid Stunnel SSL
After=network.target ssh.service

[Service]
Type=simple
ExecStart=/usr/bin/stunnel4 $STUNNEL_CONF
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF2

systemctl daemon-reload
systemctl enable darkzsaid-stunnel >/dev/null 2>&1
systemctl restart darkzsaid-stunnel >/dev/null 2>&1

sleep 1

if systemctl is-active --quiet darkzsaid-stunnel; then
  echo -e "${VERDE}${BOLD}Stunnel SSL activo correctamente.${RESET}"
else
  echo -e "${ROJO}Stunnel no pudo iniciar. Revisa:${RESET}"
  echo "journalctl -u darkzsaid-stunnel -n 80 --no-pager"
  exit 1
fi

if ss -tulnp | grep -q ':443'; then
  echo -e "${VERDE}Puerto 443 escuchando correctamente.${RESET}"
else
  echo -e "${AMARILLO}Aviso: el servicio está activo, pero no se detectó el puerto 443 con ss.${RESET}"
fi
