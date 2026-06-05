#!/bin/bash

set +e

REPO_URL="https://github.com/DarkZsaid/DarkZsaid-panel.git"
INSTALL_DIR="/opt/darkzsaid"

echo "=============================================="
echo "        INSTALADOR PUBLICO DARKZSAID"
echo "=============================================="
echo

if [[ "$(id -u)" != "0" ]]; then
  echo "Ejecute como root."
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo "[1/6] Instalando dependencias mínimas..."
apt update -y
apt install -y git curl wget bash python3 sudo tar gzip ca-certificates dos2unix

echo "[2/6] Preparando carpeta..."
mkdir -p "$INSTALL_DIR"

if [[ -d "$INSTALL_DIR/.git" ]]; then
  echo "[3/6] Actualizando repo existente..."
  cd "$INSTALL_DIR" || exit 1
  git pull || true
else
  echo "[3/6] Clonando repo..."
  rm -rf "$INSTALL_DIR.tmp"
  git clone "$REPO_URL" "$INSTALL_DIR.tmp" || exit 1
  rsync -a "$INSTALL_DIR.tmp/" "$INSTALL_DIR/" 2>/dev/null || cp -a "$INSTALL_DIR.tmp/." "$INSTALL_DIR/"
  rm -rf "$INSTALL_DIR.tmp"
fi

cd "$INSTALL_DIR" || exit 1

echo "[4/6] Ejecutando preparador VPS..."
if [[ -x "$INSTALL_DIR/core/preparar_vps.sh" ]]; then
  bash "$INSTALL_DIR/core/preparar_vps.sh"
fi

echo "[5/6] Permisos..."
find "$INSTALL_DIR" -type f -name "*.sh" -exec chmod +x {} \;
chmod +x "$INSTALL_DIR/panel.sh" 2>/dev/null || true

echo "[6/6] Creando comandos menu/darkzsaid..."
cp -f "$INSTALL_DIR/panel.sh" /usr/local/bin/menu 2>/dev/null || true
cp -f "$INSTALL_DIR/panel.sh" /usr/local/bin/darkzsaid 2>/dev/null || true
chmod +x /usr/local/bin/menu /usr/local/bin/darkzsaid 2>/dev/null || true

echo
echo "Instalación terminada."
echo "Use: menu"
