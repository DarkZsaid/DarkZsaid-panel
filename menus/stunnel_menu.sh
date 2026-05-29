#!/bin/bash

open_ssl_443_firewall() {
  echo -e "${CYAN:-}Abriendo puerto SSL/TLS 443...${RESET:-}"

  # UFW si existe
  if command -v ufw >/dev/null 2>&1; then
    ufw allow 443/tcp >/dev/null 2>&1 || true
  fi

  # iptables directo
  if command -v iptables >/dev/null 2>&1; then
    iptables -D INPUT -p tcp --dport 443 -j ACCEPT 2>/dev/null || true
    iptables -I INPUT -p tcp --dport 443 -j ACCEPT 2>/dev/null || true
  fi

  # Guardar reglas si existe soporte
  if command -v netfilter-persistent >/dev/null 2>&1; then
    netfilter-persistent save >/dev/null 2>&1 || true
  elif command -v iptables-save >/dev/null 2>&1 && [ -d /etc/iptables ]; then
    iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
  fi
}

source /opt/darkzsaid/menus/ui_instalacion.sh 2>/dev/null || true

ROJO="\e[31m"
VERDE="\e[32m"
AMARILLO="\e[33m"
CYAN="\e[36m"
AZUL="\e[34m"
BLANCO="\e[97m"
RESET="\e[0m"
BOLD="\e[1m"

FIX="/opt/darkzsaid/menus/fix_stunnel_permanente.sh"

pausa() {
  echo
  read -r -p "Presiona ENTER para continuar..."
}

titulo_stunnel() {
  clear
  echo -e "${CYAN}╔════════════════════════════════════════════════════╗${RESET}"
  echo -e "${CYAN}║${RESET} ${BLANCO}${BOLD}          DARKZSAID STUNNEL SSL 443          ${RESET}${CYAN}║${RESET}"
  echo -e "${CYAN}╚════════════════════════════════════════════════════╝${RESET}"
  echo
}

instalar_stunnel() {
  titulo_stunnel
  echo -e "${AMARILLO}Instalando/Reparando Stunnel SSL...${RESET}"
  echo
  bash "$FIX"
  pausa
}

estado_stunnel() {
  titulo_stunnel
  echo -e "${AMARILLO}Estado del servicio darkzsaid-stunnel:${RESET}"
  echo
  systemctl status darkzsaid-stunnel --no-pager 2>/dev/null || echo -e "${ROJO}Servicio no encontrado.${RESET}"
  echo
  echo -e "${AMARILLO}Puerto 443:${RESET}"
  ss -tulnp | grep ':443' || echo -e "${ROJO}443 no está escuchando.${RESET}"
  pausa
}

reiniciar_stunnel() {
  titulo_stunnel
  echo -e "${AMARILLO}Reiniciando Stunnel SSL...${RESET}"
  open_ssl_443_firewall
  systemctl restart darkzsaid-stunnel 2>/dev/null || bash "$FIX"
  sleep 1
  systemctl status darkzsaid-stunnel --no-pager 2>/dev/null || true
  ss -tulnp | grep ':443' || echo -e "${ROJO}443 no está escuchando.${RESET}"
  pausa
}

detener_stunnel() {
  titulo_stunnel
  echo -e "${AMARILLO}Deteniendo Stunnel SSL...${RESET}"
  systemctl stop darkzsaid-stunnel 2>/dev/null || true
  echo -e "${VERDE}Stunnel detenido.${RESET}"
  pausa
}

remover_stunnel() {
  titulo_stunnel
  echo -e "${ROJO}Removiendo servicio Stunnel DarkZsaid...${RESET}"
  systemctl stop darkzsaid-stunnel 2>/dev/null || true
  systemctl disable darkzsaid-stunnel 2>/dev/null || true
  rm -f /etc/systemd/system/darkzsaid-stunnel.service
  rm -rf /etc/darkzsaid/stunnel
  systemctl daemon-reload
  echo -e "${VERDE}Stunnel removido.${RESET}"
  pausa
}

while true; do
  titulo_stunnel

  if systemctl is-active --quiet darkzsaid-stunnel; then
    ESTADO="${VERDE}ACTIVO${RESET}"
  else
    ESTADO="${ROJO}INACTIVO${RESET}"
  fi

  if ss -tulnp | grep -q ':443'; then
    PUERTO="${VERDE}443 escuchando${RESET}"
  else
    PUERTO="${ROJO}443 no escuchando${RESET}"
  fi

  echo -e "${AMARILLO}Estado:${RESET} $ESTADO"
  echo -e "${AMARILLO}Puerto:${RESET} $PUERTO"
  echo
  echo -e "${CYAN}[1]${RESET} Instalar / Reparar Stunnel SSL"
  echo -e "${CYAN}[2]${RESET} Estado"
  echo -e "${CYAN}[3]${RESET} Reiniciar"
  echo -e "${CYAN}[4]${RESET} Detener"
  echo -e "${CYAN}[5]${RESET} Remover"
  echo -e "${CYAN}[0]${RESET} Volver"
  echo
  read -r -p "Opción: " op

  case "$op" in
    1) instalar_stunnel ;;
    2) estado_stunnel ;;
    3) reiniciar_stunnel ;;
    4) detener_stunnel ;;
    5) remover_stunnel ;;
    0) exit 0 ;;
    *) echo -e "${ROJO}Opción inválida.${RESET}"; sleep 1 ;;
  esac
done
