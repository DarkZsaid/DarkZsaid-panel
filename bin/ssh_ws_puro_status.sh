#!/bin/bash

PORTS="80 90 8080 8082 8084 8086"

echo "=============================================="
echo "             ESTADO DE PUERTOS SSH WS          "
echo "=============================================="
echo

for p in $PORTS; do
  if ss -tulnp 2>/dev/null | grep -q ":$p "; then
    PID="$(ss -tulnp 2>/dev/null | grep ":$p " | head -1 | grep -o 'pid=[0-9]*' | head -1 | cut -d= -f2)"
    [ -z "$PID" ] && PID="?"
    echo "Puerto $p: ✔ ACTIVO - Proceso: ${PID}/python3"
  else
    echo "Puerto $p: ✘ INACTIVO"
  fi
done

echo
echo "Destino interno:"
echo "80, 8084, 8086  -> Dropbear 109"
echo "90, 8080, 8082  -> OpenSSH 22"
