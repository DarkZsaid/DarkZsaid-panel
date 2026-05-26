#!/bin/bash

# Colores DarkZsaid
export NC='\033[0m'
export RED='\033[1;31m'
export GREEN='\033[1;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[1;34m'
export MAGENTA='\033[1;35m'
export CYAN='\033[1;36m'
export WHITE='\033[1;37m'

dz_line() {
    echo -e "${CYAN}════════════════════════════════════════════${NC}"
}

dz_header() {
    clear
    dz_line
    echo -e "${WHITE}        ⚡ DARKZSAID PANEL ⚡${NC}"
    echo -e "${YELLOW}        SSH / SSL / VMESS / UDP${NC}"
    dz_line
    echo
}

dz_pause() {
    echo
    read -rp "Presiona ENTER para continuar..."
}
