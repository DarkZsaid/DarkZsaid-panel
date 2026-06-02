#!/bin/bash
CONF="/etc/darkzsaid/domain.conf"
touch "$CONF"

while true; do
clear
DOMINIO_ACTUAL=$(cat "$CONF" 2>/dev/null)

echo -e "\033[1;36m════════════════════════════════════\033[0m"
echo -e "\033[1;35m        🌐 DOMINIO DARKZSAID 🌐\033[0m"
echo -e "\033[1;36m════════════════════════════════════\033[0m"
echo
echo -e "\033[1;37mDominio actual:\033[0m \033[1;36m${DOMINIO_ACTUAL:-NO CONFIGURADO}\033[0m"
echo
echo -e "\033[1;36m[1]\033[0m Configurar / cambiar dominio"
echo -e "\033[1;36m[2]\033[0m Probar DNS"
echo -e "\033[1;36m[3]\033[0m Probar HTTP 80"
echo -e "\033[1;36m[4]\033[0m Probar HTTPS 443"
echo -e "\033[1;36m[5]\033[0m Ver puertos activos"
echo -e "\033[1;31m[0]\033[0m Volver"
echo
read -rp "Opción: " op

case "$op" in
  1)
    read -rp "Escribe tu dominio: " NUEVO_DOM
    [[ -n "$NUEVO_DOM" ]] && echo "$NUEVO_DOM" > "$CONF" && echo "Dominio guardado: $NUEVO_DOM"
    read -rp "ENTER para volver..."
    ;;
  2)
    DOM=$(cat "$CONF" 2>/dev/null)
    [[ -z "$DOM" ]] && read -rp "Dominio a probar: " DOM
    nslookup "$DOM" 2>/dev/null || true
    read -rp "ENTER para volver..."
    ;;
  3)
    DOM=$(cat "$CONF" 2>/dev/null)
    [[ -z "$DOM" ]] && read -rp "Dominio a probar: " DOM
    curl -I -m 10 "http://$DOM" 2>/dev/null || true
    read -rp "ENTER para volver..."
    ;;
  4)
    DOM=$(cat "$CONF" 2>/dev/null)
    [[ -z "$DOM" ]] && read -rp "Dominio a probar: " DOM
    curl -I -m 10 "https://$DOM" 2>/dev/null || true
    read -rp "ENTER para volver..."
    ;;
  5)
    ss -lntup 2>/dev/null | grep -E ':(22|53|80|443|36712|5667|6000|7300|7200)' || ss -lntup
    read -rp "ENTER para volver..."
    ;;
  0)
    exit 0
    ;;
  *)
    echo "Opción inválida."
    sleep 1
    ;;
esac
done
