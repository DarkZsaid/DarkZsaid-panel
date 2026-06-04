#!/bin/bash

limpiar_pantalla() {
    printf '\033[H\033[2J\033[3J'
}

source /opt/darkzsaid/menus/ui_instalacion.sh 2>/dev/null || true
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
instalar(){ titulo "ACTIVAR BADVPN UDPGW"; apt install -y cmake gcc make git; cd /opt || return; rm -rf badvpn; git clone https://github.com/ambrop72/badvpn.git; cd /opt/badvpn || return; mkdir -p build; cd build || return; cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1; make install; cat > /etc/systemd/system/badvpn-udpgw.service <<EOC
[Unit]
Description=BadVPN UDPGW
After=network.target

[Service]
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOC
systemctl daemon-reload; systemctl enable badvpn-udpgw; systemctl restart badvpn-udpgw; ufw allow 7300/tcp 2>/dev/null || true; ufw allow 7300/udp 2>/dev/null || true; echo "BadVPN activado en 127.0.0.1:7300"; pausa; }
detener(){ titulo "DETENER BADVPN"; systemctl stop badvpn-udpgw 2>/dev/null; echo "BadVPN detenido."; pausa; }
reiniciar(){ titulo "REINICIAR BADVPN"; systemctl restart badvpn-udpgw 2>/dev/null; echo "BadVPN reiniciado."; pausa; }
remover(){ titulo "REMOVER BADVPN"; read -p "¿Seguro? [s/n]: " r; [[ "$r" != "s" && "$r" != "S" ]] && echo "Cancelado." && pausa && return; systemctl stop badvpn-udpgw 2>/dev/null; systemctl disable badvpn-udpgw 2>/dev/null; rm -f /etc/systemd/system/badvpn-udpgw.service; rm -rf /opt/badvpn; rm -f /usr/local/bin/badvpn-udpgw; systemctl daemon-reload; echo "BadVPN removido."; pausa; }
estado(){ titulo "ESTADO BADVPN"; systemctl status badvpn-udpgw --no-pager -l; echo ""; ss -tulnp | grep ':7300' || echo "Puerto 7300 no está escuchando."; pausa; }
while true; do titulo "BADVPN UDPGW"; echo -e "${ROJO}[1]${RESET} ${AZUL}ACTIVAR / INSTALAR${RESET}"; echo -e "${ROJO}[2]${RESET} ${AZUL}DETENER${RESET}"; echo -e "${ROJO}[3]${RESET} ${AZUL}REINICIAR${RESET}"; echo -e "${ROJO}[4]${RESET} ${AZUL}REMOVER${RESET}"; echo -e "${ROJO}[5]${RESET} ${AZUL}VER ESTADO${RESET}"; echo -e "${ROJO}[6]${RESET} ${AZUL}VER LOGS${RESET}"; echo -e "${ROJO}[0]${RESET} ${BLANCO}VOLVER${RESET}"; echo ""; read -p "⚡ Opción: " op; case "$op" in 1) instalar ;; 2) detener ;; 3) reiniciar ;; 4) remover ;; 5) estado ;; 6) journalctl -u badvpn-udpgw -n 80 --no-pager -l; pausa ;; 0) exit 0 ;; *) echo "Opción inválida"; sleep 1 ;; esac; done
