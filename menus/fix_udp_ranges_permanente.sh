#!/bin/bash

limpiar_pantalla() {
    printf '\033[H\033[2J\033[3J'
}


set +e

PUERTO_UDP="36712"
RANGO_APP="20000:39999"
RANGO_EXTRA="36700:36800"

echo "Reparando redirección permanente de rangos UDP DarkZsaid..."

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Ejecuta como root."
  exit 1
fi

apt update -y >/dev/null 2>&1
apt install -y iptables-persistent netfilter-persistent >/dev/null 2>&1

# Evitar reglas duplicadas
iptables -t nat -D PREROUTING -p udp --dport "$RANGO_APP" -j REDIRECT --to-ports "$PUERTO_UDP" 2>/dev/null || true
iptables -t nat -D PREROUTING -p udp --dport "$RANGO_EXTRA" -j REDIRECT --to-ports "$PUERTO_UDP" 2>/dev/null || true

# Crear reglas correctas
iptables -t nat -A PREROUTING -p udp --dport "$RANGO_APP" -j REDIRECT --to-ports "$PUERTO_UDP"
iptables -t nat -A PREROUTING -p udp --dport "$RANGO_EXTRA" -j REDIRECT --to-ports "$PUERTO_UDP"

# Abrir firewall local
ufw allow 36712/udp >/dev/null 2>&1 || true
ufw allow 20000:39999/udp >/dev/null 2>&1 || true
ufw allow 36700:36800/udp >/dev/null 2>&1 || true
ufw reload >/dev/null 2>&1 || true

# Guardar reglas para reinicio
netfilter-persistent save >/dev/null 2>&1 || true
systemctl enable netfilter-persistent >/dev/null 2>&1 || true

echo "Rangos UDP aplicados:"
echo " - 20000:39999 -> 36712"
echo " - 36700:36800 -> 36712"
echo
iptables -t nat -L PREROUTING -n -v | grep -E "36712|20000|39999|36700|36800" || true
