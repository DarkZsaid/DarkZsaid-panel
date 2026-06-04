#!/bin/bash

limpiar_pantalla() {
    printf '\033[H\033[2J\033[3J'
}


# DarkZsaid UDPMod Redirect
# Redirige UDP 10000-65000 hacia el puerto real UDPMod 36712

TARGET_PORT="36712"
RANGE_PORTS="10000:65000"

# Asegurar iptables
command -v iptables >/dev/null 2>&1 || exit 0

# Evitar duplicados: borrar reglas iguales si ya existen
while iptables -t nat -C PREROUTING -p udp --dport "$RANGE_PORTS" -j REDIRECT --to-ports "$TARGET_PORT" 2>/dev/null; do
  iptables -t nat -D PREROUTING -p udp --dport "$RANGE_PORTS" -j REDIRECT --to-ports "$TARGET_PORT" 2>/dev/null || break
done

# Crear regla limpia
iptables -t nat -A PREROUTING -p udp --dport "$RANGE_PORTS" -j REDIRECT --to-ports "$TARGET_PORT"

# Abrir puerto real UDPMod
iptables -D INPUT -p udp --dport "$TARGET_PORT" -j ACCEPT 2>/dev/null || true
iptables -I INPUT -p udp --dport "$TARGET_PORT" -j ACCEPT

# Abrir rango UDP de entrada
iptables -D INPUT -p udp --dport "$RANGE_PORTS" -j ACCEPT 2>/dev/null || true
iptables -I INPUT -p udp --dport "$RANGE_PORTS" -j ACCEPT

# Intentar guardar reglas si existe herramienta disponible
if command -v netfilter-persistent >/dev/null 2>&1; then
  netfilter-persistent save >/dev/null 2>&1 || true
elif command -v iptables-save >/dev/null 2>&1 && [ -d /etc/iptables ]; then
  iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
fi

exit 0
