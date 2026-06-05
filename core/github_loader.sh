#!/bin/bash

# DarkZsaid GitHub Loader
# Descarga subpaneles desde GitHub y usa copia local si GitHub falla.

CONFIG="/opt/darkzsaid/core/config_github.conf"

if [[ -f "$CONFIG" ]]; then
  source "$CONFIG"
else
  GITHUB_USER="DarkZsaid"
  GITHUB_REPO="DarkZsaid-panel"
  GITHUB_BRANCH="main"
  RAW_BASE="https://raw.githubusercontent.com/DarkZsaid/DarkZsaid-panel/main"
  CACHE_DIR="/opt/darkzsaid/cache_github"
  LOCAL_BASE="/opt/darkzsaid"
fi

mkdir -p "$CACHE_DIR"

run_github_panel() {
  local rel="$1"
  local local_file="$LOCAL_BASE/$rel"
  local cache_file="$CACHE_DIR/${rel//\//_}"
  local url="$RAW_BASE/$rel"

  echo
  echo "=============================================="
  echo " DarkZsaid cargando módulo:"
  echo " $rel"
  echo "=============================================="
  echo

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL --connect-timeout 8 --max-time 20 "$url" -o "$cache_file.tmp" 2>/dev/null
  elif command -v wget >/dev/null 2>&1; then
    wget -q --timeout=20 -O "$cache_file.tmp" "$url" 2>/dev/null
  else
    echo "curl/wget no disponible. Usando archivo local..."
  fi

  if [[ -s "$cache_file.tmp" ]]; then
    mv -f "$cache_file.tmp" "$cache_file"
    chmod +x "$cache_file"
    if bash -n "$cache_file" 2>/dev/null; then
      bash "$cache_file"
      return $?
    else
      echo "Módulo descargado tiene error de sintaxis. Usando local..."
      rm -f "$cache_file"
    fi
  fi

  rm -f "$cache_file.tmp" 2>/dev/null

  if [[ -f "$local_file" ]]; then
    chmod +x "$local_file"
    if bash -n "$local_file" 2>/dev/null; then
      bash "$local_file"
      return $?
    else
      echo "ERROR: archivo local tiene error de sintaxis:"
      echo "$local_file"
      return 1
    fi
  fi

  echo "ERROR: no existe módulo local ni remoto:"
  echo "$rel"
  echo
  read -rp "Presione ENTER para continuar..."
  return 1
}

run_local_panel() {
  local rel="$1"
  local local_file="$LOCAL_BASE/$rel"

  if [[ -f "$local_file" ]]; then
    chmod +x "$local_file"
    bash "$local_file"
  else
    echo "No existe: $local_file"
    read -rp "Presione ENTER para continuar..."
  fi
}
