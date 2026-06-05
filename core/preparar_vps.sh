#!/bin/bash

set +e

echo "=============================================="
echo "        PREPARADOR VPS DARKZSAID"
echo "=============================================="
echo

if [[ "$(id -u)" != "0" ]]; then
  echo "Ejecute como root."
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo "[1/5] Actualizando repositorios..."
apt update -y

echo "[2/5] Instalando paquetes base..."
apt install -y \
  curl wget git sudo bash nano \
  python3 python3-pip python3-venv \
  unzip zip tar gzip \
  net-tools iproute2 iptables iptables-persistent \
  lsof cron procps psmisc \
  openssl ca-certificates dos2unix screen tmux \
  jq bc socat

echo "[3/5] Creando carpetas base..."
mkdir -p /opt/darkzsaid
mkdir -p /opt/darkzsaid/menus
mkdir -p /opt/darkzsaid/core
mkdir -p /opt/darkzsaid/data
mkdir -p /opt/darkzsaid/logs
mkdir -p /opt/darkzsaid/cache_github

echo "[4/5] Corrigiendo permisos básicos..."
chmod -R +x /opt/darkzsaid 2>/dev/null || true

echo "[5/5] Verificación rápida..."
command -v curl >/dev/null && echo "OK curl"
command -v wget >/dev/null && echo "OK wget"
command -v git >/dev/null && echo "OK git"
command -v python3 >/dev/null && echo "OK python3"
command -v ss >/dev/null && echo "OK ss/iproute2"
command -v iptables >/dev/null && echo "OK iptables"

echo
echo "Preparador VPS terminado."
