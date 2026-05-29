#!/bin/bash

ROJO="\e[31m"
VERDE="\e[32m"
AMARILLO="\e[33m"
CYAN="\e[36m"
BLANCO="\e[97m"
RESET="\e[0m"
BOLD="\e[1m"

TOKEN_PASS="steven2002"
DATA_DIR="/opt/darkzsaid/data"
SSH_DB="$DATA_DIR/usuarios_ssh.db"
TOKEN_DB="$DATA_DIR/tokens_zivpn.db"
USERDIR="/etc/adm-lite/userDIR"

mkdir -p "$DATA_DIR" "$USERDIR" /opt/darkzsaid/users
touch "$SSH_DB" "$TOKEN_DB"

echo 'TOKEN_PASSWORD="steven2002"' > "$DATA_DIR/token_password.conf"
echo 'steven2002' > /opt/darkzsaid/users/token_password.conf
chmod 600 "$DATA_DIR/token_password.conf" /opt/darkzsaid/users/token_password.conf 2>/dev/null || true

clear
echo -e "${CYAN}╔════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║${RESET} ${BLANCO}${BOLD}        CREAR CUENTA TOKEN${RESET}"
echo -e "${CYAN}╚════════════════════════════════════════════════════╝${RESET}"
echo ""

read -p "Nombre: " nombre
read -p "Token: " token
read -p "Días: " dias

if [[ -z "$nombre" || -z "$token" || ! "$dias" =~ ^[0-9]+$ ]]; then
    echo -e "${ROJO}Datos inválidos. Los días deben ser números.${RESET}"
    read -p "Presiona ENTER para continuar..."
    exit 1
fi

if [[ "$token" =~ [[:space:]/] ]]; then
    echo -e "${ROJO}Token inválido. No uses espacios ni /.${RESET}"
    read -p "Presiona ENTER para continuar..."
    exit 1
fi

fecha=$(date -d "+$dias days" +%Y-%m-%d 2>/dev/null)

cat > "$USERDIR/$token" <<EOF2
tipo: TOKEN
nombre: $nombre
token: $token
usuario: $token
senha: $TOKEN_PASS
limite: TOKEN
data: $fecha
EOF2

chmod 644 "$USERDIR/$token"

if ! id "$token" >/dev/null 2>&1; then
    useradd -M -s /bin/bash "$token" >/dev/null 2>&1 || true
fi

HASH=$(openssl passwd -6 "$TOKEN_PASS")
    usermod -p "$HASH" "$token" >/dev/null 2>&1
chage -E "$fecha" "$token" >/dev/null 2>&1 || true

grep -v "^$token|" "$SSH_DB" > "$SSH_DB.tmp" 2>/dev/null || true
mv "$SSH_DB.tmp" "$SSH_DB"

grep -v "^$token|" "$TOKEN_DB" > "$TOKEN_DB.tmp" 2>/dev/null || true
mv "$TOKEN_DB.tmp" "$TOKEN_DB"

echo "$token|$TOKEN_PASS|TOKEN|1|$dias|$fecha|$nombre" >> "$SSH_DB"
echo "$token|$TOKEN_PASS|TOKEN|1|$dias|$fecha|$nombre" >> "$TOKEN_DB"

bash /opt/darkzsaid/menus/sync_udpmod_users.sh 2>/dev/null || true

echo ""
echo -e "${VERDE}✓ TOKEN creado correctamente.${RESET}"
echo ""
echo "Nombre     : $nombre"
echo "Token/HWID : $token"
echo "Contraseña : ********"
echo "Expira     : $fecha"
echo ""
echo "La app manda:"
echo "$token:********"
echo ""

read -p "Presiona ENTER para continuar..."
