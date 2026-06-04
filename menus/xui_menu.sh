#!/bin/bash

limpiar_pantalla() {
    printf '\033[H\033[2J\033[3J'
}

[[ -f /opt/darkzsaid/lib/puertas_reales.sh ]] && source /opt/darkzsaid/lib/puertas_reales.sh
ROJO="\e[31m"; VERDE="\e[32m"; AMARILLO="\e[33m"; AZUL="\e[34m"
CYAN="\e[36m"; BLANCO="\e[97m"; RESET="\e[0m"; BOLD="\e[1m"
titulo() {
    limpiar_pantalla
    echo -e "${CYAN}╔════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET}        ${BLANCO}${BOLD}⚡ DARKZSAID CONTROL ⚡${RESET}             ${CYAN}║${RESET}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${AMARILLO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${VERDE}        $1${RESET}"
    echo -e "${AMARILLO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
}


pausa(){ echo ""; read -p "Presiona ENTER para continuar..."; }
titulo(){ clear; echo -e "${ROJO}══════════════════════════ / / / ══════════════════════════${RESET}"; echo -e "${BLANCO}${BOLD}          $1${RESET}"; echo -e "${ROJO}══════════════════════════ / / / ══════════════════════════${RESET}"; echo ""; }
instalar(){ titulo "ACTIVAR / INSTALAR 3X-UI"; bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh); pausa; }
detener(){ titulo "DETENER 3X-UI"; systemctl stop x-ui 2>/dev/null; echo "3X-UI detenido."; pausa; }
reiniciar(){ titulo "REINICIAR 3X-UI"; systemctl restart x-ui 2>/dev/null; echo "3X-UI reiniciado."; pausa; }
remover(){ titulo "REMOVER 3X-UI"; read -p "¿Seguro? [s/n]: " r; [[ "$r" != "s" && "$r" != "S" ]] && echo "Cancelado." && pausa && return; x-ui uninstall 2>/dev/null || bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh) uninstall; pausa; }
estado(){ titulo "ESTADO 3X-UI"; systemctl status x-ui --no-pager -l; pausa; }
while true; do titulo "PANEL WEB 3X-UI"; echo -e "${ROJO}[1]${RESET} ${AZUL}ACTIVAR / INSTALAR${RESET}"; echo -e "${ROJO}[2]${RESET} ${AZUL}DETENER${RESET}"; echo -e "${ROJO}[3]${RESET} ${AZUL}REINICIAR${RESET}"; echo -e "${ROJO}[4]${RESET} ${AZUL}REMOVER${RESET}"; echo -e "${ROJO}[5]${RESET} ${AZUL}VER ESTADO${RESET}"; echo -e "${ROJO}[6]${RESET} ${AZUL}VER LOGS${RESET}"; echo -e "${ROJO}[0]${RESET} ${BLANCO}VOLVER${RESET}"; echo ""; read -p "⚡ Opción: " op; case "$op" in 1) instalar ;; 2) detener ;; 3) reiniciar ;; 4) remover ;; 5) estado ;; 6) journalctl -u x-ui -n 80 --no-pager -l; pausa ;; 0) exit 0 ;; *) echo "Opción inválida"; sleep 1 ;; esac; done
