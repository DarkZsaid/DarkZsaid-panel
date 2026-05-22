#!/bin/bash

# DarkZsaid UDPMod / Hysteria redirect permanente
# Rango externo: UDP 10000:65000
# Puerto interno UDPMod: 36712

iptables -t nat -D PREROUTING -p udp --dport 10000:65000 -j REDIRECT --to-ports 36712 2>/dev/null || true
iptables -t nat -A PREROUTING -p udp --dport 10000:65000 -j REDIRECT --to-ports 36712

iptables -D INPUT -p udp --dport 36712 -j ACCEPT 2>/dev/null || true
iptables -I INPUT -p udp --dport 36712 -j ACCEPT

ufw allow 36712/udp >/dev/null 2>&1 || true

exit 0
