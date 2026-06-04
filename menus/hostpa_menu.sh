#!/bin/bash

# HOST-PA DarkZsaid
BASE="/opt/darkzsaid/protocolos_hostpa"
PIDFILE="/var/run/darkzsaid_hostpa.pid"
LOGFILE="/var/log/darkzsaid_hostpa.log"
PORT_DEFAULT="8080"

clear_screen() {
  clear
}

stop_hostpa() {
  if [ -f "$PIDFILE" ]; then
    PID="$(cat "$PIDFILE" 2>/dev/null)"
    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
      kill "$PID" 2>/dev/null
      sleep 1
      kill -9 "$PID" 2>/dev/null || true
    fi
    rm -f "$PIDFILE"
  fi

  pkill -f "/opt/darkzsaid/protocolos_hostpa/proxy_" 2>/dev/null || true
}

status_hostpa() {
  if [ -f "$PIDFILE" ]; then
    PID="$(cat "$PIDFILE" 2>/dev/null)"
    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
      echo "ACTIVO PID: $PID"
      return
    fi
  fi
  echo "DETENIDO"
}

start_hostpa() {
  SCRIPT="$1"
  PORT="$2"

  stop_hostpa

  nohup python3 "$SCRIPT" "$PORT" > "$LOGFILE" 2>&1 &
  echo $! > "$PIDFILE"
  sleep 1

  PID="$(cat "$PIDFILE" 2>/dev/null)"
  if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
    echo
    echo "✅ HOST-PA iniciado correctamente"
    echo " Puerto: $PORT"
    echo "� Log: $LOGFILE"
  else
    echo
    echo "� No se pudo iniciar HOST-PA"
    echo "Revisa el log:"
    echo "$LOGFILE"
  fi
}

menu_hostpa() {
  while true; do
    clear_screen
    echo "============================================"
    echo "        SELECCI❌ÓN DE PROTOCOLO HOST-PA       "
    echo "============================================"
    echo
    echo "Estado actual: $(status_hostpa)"
    echo
    echo "[1] Status 200 (Clásico Host-Pa)"
    echo "[2] Status 302 (Google Redirect)"
    echo "[3] Status 400 (Bad Request)"
    echo "[4] Status 101 (WebSocket)"
    echo "[5] Combo 101 + 200 (WebSocket) - EL MEJOR"
    echo "[6] Combo 302 + 200 (Redirect)"
    echo
    echo "[7] Detener HOST-PA"
    echo "[8] Ver log"
    echo "[0] Volver"
    echo
    read -rp "Elija una opción [0-8]: " op

    case "$op" in
      1)
        read -rp "Puerto para escuchar [8080]: " PORT
        PORT="${PORT:-$PORT_DEFAULT}"
        start_hostpa "$BASE/proxy_status_200.py" "$PORT"
        read -rp "ENTER para continuar..."
        ;;
      2)
        read -rp "Puerto para escuchar [8080]: " PORT
        PORT="${PORT:-$PORT_DEFAULT}"
        start_hostpa "$BASE/proxy_status_302.py" "$PORT"
        read -rp "ENTER para continuar..."
        ;;
      3)
        read -rp "Puerto para escuchar [8080]: " PORT
        PORT="${PORT:-$PORT_DEFAULT}"
        start_hostpa "$BASE/proxy_status_400.py" "$PORT"
        read -rp "ENTER para continuar..."
        ;;
      4)
        read -rp "Puerto para escuchar [8080]: " PORT
        PORT="${PORT:-$PORT_DEFAULT}"
        start_hostpa "$BASE/proxy_status_101.py" "$PORT"
        read -rp "ENTER para continuar..."
        ;;
      5)
        read -rp "Puerto para escuchar [8080]: " PORT
        PORT="${PORT:-$PORT_DEFAULT}"
        start_hostpa "$BASE/proxy_combo_101_200.py" "$PORT"
        read -rp "ENTER para continuar..."
        ;;
      6)
        read -rp "Puerto para escuchar [8080]: " PORT
        PORT="${PORT:-$PORT_DEFAULT}"
        start_hostpa "$BASE/proxy_combo_302_200.py" "$PORT"
        read -rp "ENTER para continuar..."
        ;;
      7)
        stop_hostpa
        echo "HOST-PA detenido."
        read -rp "ENTER para continuar..."
        ;;
      8)
        clear_screen
        echo "===== LOG HOST-PA ====="
        tail -80 "$LOGFILE" 2>/dev/null || echo "Sin log todavía."
        echo
        read -rp "ENTER para continuar..."
        ;;
      0)
        clear_screen
        exit 0
        ;;
      *)
        echo "Opción inválida."
        sleep 1
        ;;
    esac
  done
}

menu_hostpa
