#!/bin/bash

pantalla_limpia() {
    printf '\033c'
}


limpiar_pantalla() {
    printf '\033[H\033[2J\033[3J'
}


# Sincroniza usuarios SSH/TOKEN con UDP-Hysteria
# y mantiene OBFS permanente en DarkZsaid.

bash /opt/darkzsaid/menus/fix_udpmod_permanente.sh 2>/dev/null || true
