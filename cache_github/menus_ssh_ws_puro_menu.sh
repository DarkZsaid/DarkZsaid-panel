#!/bin/bash

MARINO="\033[38;5;33m"
RESET="\033[0m"

start_ws="/opt/darkzsaid/bin/ssh_ws_puro_start.sh"
stop_ws="/opt/darkzsaid/bin/ssh_ws_puro_stop.sh"
status_ws="/opt/darkzsaid/bin/ssh_ws_puro_status.sh"

while true; do
  clear
  echo -e "${MARINO}==============================================${RESET}"
  echo -e "${MARINO}          DarkZsaid - PROTOCOLOS SSH WS        ${RESET}"
  echo -e "${MARINO}==============================================${RESET}"
  echo
  echo -e "${MARINO}Puerto Activos: 80, 90, 8080, 8082, 8084, 8086${RESET}"
  echo -e "${MARINO}Destino: 80/8084/8086 -> Dropbear 109${RESET}"
  echo -e "${MARINO}Destino: 90/8080/8082 -> OpenSSH 22${RESET}"
  echo -e "${MARINO}----------------------------------------------${RESET}"
  echo
  echo -e "${MARINO} 1) ENCENDER PROTOCOLOS SSH WS${RESET}"
  echo -e "${MARINO} 2) APAGAR PROTOCOLOS SSH WS${RESET}"
  echo -e "${MARINO} 3) REINICIAR PROTOCOLOS SSH WS${RESET}"
  echo -e "${MARINO} 4) VER ESTADO DE LOS PUERTOS${RESET}"
  echo -e "${MARINO} 5) VOLVER AL MENU PRINCIPAL${RESET}"
  echo
  echo -e "${MARINO}==============================================${RESET}"
  echo -ne "${MARINO}Seleccione opción: ${RESET}"
  read -r op

  case "$op" in
    1)
      bash "$start_ws"
      echo
      read -rp "Presione Enter para continuar..."
      ;;
    2)
      bash "$stop_ws"
      echo
      read -rp "Presione Enter para continuar..."
      ;;
    3)
      bash "$stop_ws"
      sleep 1
      bash "$start_ws"
      echo
      read -rp "Presione Enter para continuar..."
      ;;
    4)
      bash "$status_ws"
      echo
      read -rp "Presione Enter para continuar..."
      ;;
    5|0)
      clear
      exit 0
      ;;
    *)
      echo "Opción inválida."
      sleep 1
      ;;
  esac
done
