#!/bin/bash

pantalla_limpia() {
    printf '\033c'
}


limpiar_pantalla() {
    printf '\033[H\033[2J\033[3J'
}


limpiar_pantalla
echo "======================================"
echo "        DESINSTALAR DARKZSAID"
echo "======================================"
echo
echo "Esto eliminará servicios, comandos y carpeta del panel."
echo
echo "Para borrar TODO, escribe exactamente: SI"
read -rp "Confirmar desinstalación: " CONFIRMAR

if [[ "$CONFIRMAR" != "SI" ]]; then
    echo
    echo "Cancelado."
    read -rp "Presiona ENTER para volver..."
    exit 0
fi

echo
echo "Deteniendo servicios..."

systemctl stop darkzsaid-bot 2>/dev/null || true
systemctl disable darkzsaid-bot 2>/dev/null || true
rm -f /etc/systemd/system/darkzsaid-bot.service

systemctl stop udpmod 2>/dev/null || true
systemctl disable udpmod 2>/dev/null || true
rm -f /etc/systemd/system/udpmod.service

systemctl stop hysteria-server 2>/dev/null || true
systemctl disable hysteria-server 2>/dev/null || true
rm -f /etc/systemd/system/hysteria-server.service

systemctl daemon-reload

echo "Eliminando comandos..."
rm -f /usr/local/bin/menu
rm -f /usr/local/bin/darkzsaid

echo "Eliminando carpeta principal..."
rm -rf /opt/darkzsaid

echo
echo "======================================"
echo " DARKZSAID DESINSTALADO CORRECTAMENTE"
echo "======================================"
echo
