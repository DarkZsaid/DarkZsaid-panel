#!/bin/bash

set +e

REPO_URL="https://github.com/DarkZsaid/DarkZsaid-panel.git"
INSTALL_DIR="/opt/darkzsaid"
LOGFILE="/tmp/darkzsaid_install.log"

ROJO="\033[1;31m"
VERDE="\033[1;32m"
AMARILLO="\033[1;33m"
AZUL="\033[1;34m"
MORADO="\033[1;35m"
CYAN="\033[1;36m"
BLANCO="\033[1;97m"
RESET="\033[0m"

clear

rm -f "$LOGFILE"
touch "$LOGFILE"

banner() {
  clear
  echo -e "${CYAN}╔══════════════════════════════════════════════╗${RESET}"
  echo -e "${CYAN}║${RESET}      ${BLANCO}⚡ DARKZSAID PREMIUM INSTALLER ⚡${RESET}     ${CYAN}║${RESET}"
  echo -e "${CYAN}╚══════════════════════════════════════════════╝${RESET}"
  echo
  echo -e "${MORADO}        VPN / SSH / WS / UDP PANEL${RESET}"
  echo -e "${AZUL}        Instalación limpia y estable${RESET}"
  echo
}

barra() {
  local pct="$1"
  local msg="$2"
  local total=20
  local filled=$((pct * total / 100))
  local empty=$((total - filled))
  local bar=""

  for ((i=0; i<filled; i++)); do bar="${bar}█"; done
  for ((i=0; i<empty; i++)); do bar="${bar}░"; done

  echo -ne "${CYAN}[${bar}]${RESET} ${VERDE}${pct}%${RESET} ${BLANCO}${msg}${RESET}\r"
  sleep 1
  echo
}

paso() {
  echo
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${BLANCO}$1${RESET}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  sleep 1
}

ok() {
  echo -e "${VERDE}✔ $1${RESET}"
  sleep 0.5
}

warn() {
  echo -e "${AMARILLO}⚠ $1${RESET}"
  sleep 0.5
}

fail() {
  echo
  echo -e "${ROJO}✘ Error:${RESET} $1"
  echo -e "${AMARILLO}Revisa el log:${RESET} $LOGFILE"
  echo
  exit 1
}


barra_premium(){
    local texto="${1:-Preparando instalación premium}"
    local total="${2:-34}"
    local delay="${3:-0.035}"
    local i percent filled empty

    if [[ -z "${DZ_BARRA_TITULO_MOSTRADO:-}" ]]; then
        export DZ_BARRA_TITULO_MOSTRADO=1
        echo
        echo -e "${CYAN}╔════════════════════════════════════════════╗${RESET}"
        echo -e "${CYAN}║${RESET}      ${BLANCO}⚡ DARKZSAID INSTALLER ⚡${RESET}       ${CYAN}║${RESET}"
        echo -e "${CYAN}╚════════════════════════════════════════════╝${RESET}"
        echo
    fi

    echo -e "${AZUL}➜ ${BLANCO}${texto}${RESET}"
    echo

    for i in $(seq 1 "$total"); do
        percent=$(( i * 100 / total ))
        filled=$(printf "%0.s█" $(seq 1 "$i"))
        empty=$(printf "%0.s░" $(seq 1 $((total-i))))
        printf "
${CYAN}[${VERDE}%s${AMARILLO}%s${CYAN}] ${BLANCO}%3d%%${RESET}" "$filled" "$empty" "$percent"
        sleep "$delay"
    done

    echo
    echo -e "${VERDE}✓ ${BLANCO}${texto} completado${RESET}"
    echo
}


run_silent() {
  local desc="$1"
  shift

  echo -e "${AZUL}• ${desc}...${RESET}"
  "$@" >> "$LOGFILE" 2>&1
  local code=$?

  if [[ "$code" -eq 0 ]]; then
    ok "$desc"
  else
    fail "$desc"
  fi
}

run_warn() {
  local desc="$1"
  shift

  echo -e "${AZUL}• ${desc}...${RESET}"
  "$@" >> "$LOGFILE" 2>&1
  local code=$?

  if [[ "$code" -eq 0 ]]; then
    ok "$desc"
  else
    warn "$desc tuvo avisos, continuando"
  fi
}

if [[ "$(id -u)" != "0" ]]; then
  echo "Ejecute como root."
  exit 1
fi

banner

echo -e "${BLANCO}Este instalador preparará tu VPS para DarkZsaid.${RESET}"
echo -e "${AMARILLO}La instalación será más pausada para evitar errores en VPS nuevas.${RESET}"
echo
sleep 2

barra_premium "Preparando VPS DarkZsaid Premium" 34 0.035

paso "[01/10] Dominio opcional"

echo -e "${BLANCO}Puedes enlazar un dominio ahora.${RESET}"
echo -e "${AMARILLO}Si no tienes dominio, presiona ENTER y seguirá normal.${RESET}"
echo
read -rp "Dominio para esta VPS [opcional]: " DOMINIO_INPUT

DOMINIO_INPUT="$(echo "$DOMINIO_INPUT" | tr -d ' ' | tr -d '\r')"

if [[ -n "$DOMINIO_INPUT" ]]; then
  echo "$DOMINIO_INPUT" > /tmp/darkzsaid_dominio_instalacion.txt
  ok "Dominio recibido: $DOMINIO_INPUT"
else
  rm -f /tmp/darkzsaid_dominio_instalacion.txt 2>/dev/null
  warn "Instalación sin dominio inicial"
fi

barra 10 "Dominio procesado"

export DEBIAN_FRONTEND=noninteractive

paso "[02/10] Preparando repositorios Ubuntu"
run_warn "Actualizando lista de paquetes" apt update -y

barra 20 "Sistema preparado"

paso "[03/10] Instalando dependencias principales"
run_silent "Instalando paquetes base" apt install -y \
  git curl wget bash sudo python3 python3-pip python3-venv \
  tar gzip unzip zip ca-certificates dos2unix rsync \
  net-tools iproute2 iptables lsof cron procps psmisc \
  openssl screen tmux jq bc socat figlet toilet figlet toilet figlet toilet

barra 35 "Dependencias instaladas"

paso "[04/10] Preparando carpeta DarkZsaid"
barra_premium "Preparando carpeta DarkZsaid" 26 0.025
mkdir -p "$INSTALL_DIR" >> "$LOGFILE" 2>&1 || fail "No se pudo crear $INSTALL_DIR"
ok "Carpeta lista: $INSTALL_DIR"

barra 45 "Carpeta preparada"

if [[ -d "$INSTALL_DIR/.git" ]]; then
  paso "[05/10] Actualizando repositorio existente"
  cd "$INSTALL_DIR" || fail "No se pudo entrar a $INSTALL_DIR"
  run_warn "Actualizando DarkZsaid desde GitHub" git pull
else
  paso "[05/10] Descargando panel desde GitHub"
  rm -rf "$INSTALL_DIR.tmp" >> "$LOGFILE" 2>&1
  run_silent "Clonando repositorio DarkZsaid" git clone "$REPO_URL" "$INSTALL_DIR.tmp"

  echo -e "${AZUL}• Copiando archivos del panel...${RESET}"
  rsync -a "$INSTALL_DIR.tmp/" "$INSTALL_DIR/" >> "$LOGFILE" 2>&1 || cp -a "$INSTALL_DIR.tmp/." "$INSTALL_DIR/" >> "$LOGFILE" 2>&1
  rm -rf "$INSTALL_DIR.tmp" >> "$LOGFILE" 2>&1
  ok "Archivos copiados"
fi

cd "$INSTALL_DIR" || fail "No se pudo entrar a $INSTALL_DIR"

barra 55 "Panel descargado"

paso "[06/10] Guardando configuración inicial"

mkdir -p "$INSTALL_DIR/data" "$INSTALL_DIR/logs" "$INSTALL_DIR/cache_github"

# DARKZSAID_CLEAN_NEW_VPS_START
# En VPS nueva el panel debe iniciar sin clientes viejos del repositorio
mkdir -p "$INSTALL_DIR/data" "$INSTALL_DIR/logs" "$INSTALL_DIR/cache_github" >> "$LOGFILE" 2>&1

if [[ ! -f "$INSTALL_DIR/.darkzsaid_installed" ]]; then
  rm -f "$INSTALL_DIR/data/usuarios_ssh.db" \
        "$INSTALL_DIR/data/tokens_ssh.db" \
        "$INSTALL_DIR/data/usuarios_udp.db" \
        "$INSTALL_DIR/usuarios_ssh.db" \
        "$INSTALL_DIR/tokens_ssh.db" \
        "$INSTALL_DIR/usuarios_udp.db" >> "$LOGFILE" 2>&1

  touch "$INSTALL_DIR/data/usuarios_ssh.db" >> "$LOGFILE" 2>&1
  touch "$INSTALL_DIR/data/tokens_ssh.db" >> "$LOGFILE" 2>&1
  touch "$INSTALL_DIR/data/usuarios_udp.db" >> "$LOGFILE" 2>&1
fi

touch "$INSTALL_DIR/.darkzsaid_installed" >> "$LOGFILE" 2>&1
# DARKZSAID_CLEAN_NEW_VPS_END


# DARKZSAID_CLEAN_RUNTIME_START
mkdir -p "$INSTALL_DIR/data" "$INSTALL_DIR/logs" "$INSTALL_DIR/cache_github"

# DARKZSAID_CLEAN_NEW_VPS_START
# En VPS nueva el panel debe iniciar sin clientes viejos del repositorio
mkdir -p "$INSTALL_DIR/data" "$INSTALL_DIR/logs" "$INSTALL_DIR/cache_github" >> "$LOGFILE" 2>&1

if [[ ! -f "$INSTALL_DIR/.darkzsaid_installed" ]]; then
  rm -f "$INSTALL_DIR/data/usuarios_ssh.db" \
        "$INSTALL_DIR/data/tokens_ssh.db" \
        "$INSTALL_DIR/data/usuarios_udp.db" \
        "$INSTALL_DIR/usuarios_ssh.db" \
        "$INSTALL_DIR/tokens_ssh.db" \
        "$INSTALL_DIR/usuarios_udp.db" >> "$LOGFILE" 2>&1

  touch "$INSTALL_DIR/data/usuarios_ssh.db" >> "$LOGFILE" 2>&1
  touch "$INSTALL_DIR/data/tokens_ssh.db" >> "$LOGFILE" 2>&1
  touch "$INSTALL_DIR/data/usuarios_udp.db" >> "$LOGFILE" 2>&1
fi

touch "$INSTALL_DIR/.darkzsaid_installed" >> "$LOGFILE" 2>&1
# DARKZSAID_CLEAN_NEW_VPS_END
 >> "$LOGFILE" 2>&1

# Bases limpias: NO traer usuarios desde GitHub
touch "$INSTALL_DIR/data/usuarios_ssh.db" >> "$LOGFILE" 2>&1
touch "$INSTALL_DIR/data/tokens_ssh.db" >> "$LOGFILE" 2>&1
touch "$INSTALL_DIR/data/usuarios_udp.db" >> "$LOGFILE" 2>&1

# Archivos runtime locales vacíos si no existen
[ -f /etc/adm-lite/userDIR ] || {
  mkdir -p /etc/adm-lite >> "$LOGFILE" 2>&1
  touch /etc/adm-lite/userDIR >> "$LOGFILE" 2>&1
}

# El repo instala el panel limpio; los clientes se crean después desde el menú/bot
# DARKZSAID_CLEAN_RUNTIME_END


# DARKZSAID_REAL_LOGO_CONFIG_START
mkdir -p /etc/darkzsaid >> "$LOGFILE" 2>&1
cat > /etc/darkzsaid/panel_logo.conf <<'LOGOCONF'
PANEL_LOGO_TEXT="DarkZsaid"
LOGOCONF
chmod 644 /etc/darkzsaid/panel_logo.conf >> "$LOGFILE" 2>&1
# DARKZSAID_REAL_LOGO_CONFIG_END


# DARKZSAID_DEFAULT_LOGO_START
mkdir -p "$INSTALL_DIR/backup_runtime/logo" "$INSTALL_DIR/data" >> "$LOGFILE" 2>&1
cat > "$INSTALL_DIR/backup_runtime/logo/panel_logo.conf" <<'LOGOEOF'
██████╗  █████╗ ██████╗ ██╗  ██╗███████╗███████╗ █████╗ ██╗██████╗
██╔══██╗██╔══██╗██╔══██╗██║ ██╔╝╚══███╔╝██╔════╝██╔══██╗██║██╔══██╗
██║  ██║███████║██████╔╝█████╔╝   ███╔╝ ███████╗███████║██║██║  ██║
██║  ██║██╔══██║██╔══██╗██╔═██╗  ███╔╝  ╚════██║██╔══██║██║██║  ██║
██████╔╝██║  ██║██║  ██║██║  ██╗███████╗███████║██║  ██║██║██████╔╝
╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝╚═════╝
LOGOEOF
cp -f "$INSTALL_DIR/backup_runtime/logo/panel_logo.conf" "$INSTALL_DIR/panel_logo.conf" >> "$LOGFILE" 2>&1
cp -f "$INSTALL_DIR/backup_runtime/logo/panel_logo.conf" "$INSTALL_DIR/data/panel_logo.conf" >> "$LOGFILE" 2>&1
# DARKZSAID_DEFAULT_LOGO_END
 >> "$LOGFILE" 2>&1

if [[ -s /tmp/darkzsaid_dominio_instalacion.txt ]]; then
  DOMINIO_FINAL="$(cat /tmp/darkzsaid_dominio_instalacion.txt | head -1 | tr -d ' ' | tr -d '\r')"

  if [[ -n "$DOMINIO_FINAL" ]]; then
    echo "$DOMINIO_FINAL" > "$INSTALL_DIR/dominio.txt"
    echo "$DOMINIO_FINAL" > "$INSTALL_DIR/domain.txt"
    echo "$DOMINIO_FINAL" > "$INSTALL_DIR/domain.conf"
    echo "$DOMINIO_FINAL" > "$INSTALL_DIR/data/dominio.txt"
    ok "Dominio guardado: $DOMINIO_FINAL"
  fi
else
  warn "Dominio no configurado"
fi

barra 65 "Configuración guardada"

paso "[07/10] Preparador interno de VPS"

if [[ -x "$INSTALL_DIR/core/preparar_vps.sh" ]]; then
  echo -e "${AZUL}• Ejecutando preparador DarkZsaid...${RESET}"
  bash "$INSTALL_DIR/core/preparar_vps.sh" >> "$LOGFILE" 2>&1
  if [[ "$?" -eq 0 ]]; then
    ok "Preparador ejecutado"
  else
    warn "Preparador terminó con avisos, continuando"
  fi
else
  warn "No se encontró core/preparar_vps.sh"
fi

barra 75 "VPS preparada"

paso "[08/10] Permisos y comandos"

echo -e "${AZUL}• Aplicando permisos...${RESET}"
find "$INSTALL_DIR" -type f -name "*.sh" -exec chmod +x {} \; >> "$LOGFILE" 2>&1
chmod +x "$INSTALL_DIR/panel.sh" >> "$LOGFILE" 2>&1 || true
chmod +x "$INSTALL_DIR/core/"*.sh >> "$LOGFILE" 2>&1 || true
chmod +x "$INSTALL_DIR/menus/"*.sh >> "$LOGFILE" 2>&1 || true
ok "Permisos aplicados"

echo -e "${AZUL}• Creando comandos globales...${RESET}"
ln -sf "$INSTALL_DIR/panel.sh" /usr/local/bin/menu >> "$LOGFILE" 2>&1
ln -sf "$INSTALL_DIR/panel.sh" /usr/local/bin/darkzsaid >> "$LOGFILE" 2>&1
chmod +x /usr/local/bin/menu /usr/local/bin/darkzsaid >> "$LOGFILE" 2>&1 || true

# DARKZSAID_INSTALL_MOTORES_START
# Motores independientes disponibles.
# No se ejecutan aquí para mantener instalación limpia.
# Cada protocolo se instala desde su opción del menú.
for motor in "$INSTALL_DIR"/core/install_*_motor.sh; do
    [ -f "$motor" ] && chmod +x "$motor" >> "$LOGFILE" 2>&1 || true
done
# DARKZSAID_INSTALL_MOTORES_END

ok "Comandos creados: menu / darkzsaid"

# DARKZSAID_AUTO_MENU_INSTALL_START
# Autoabrir DarkZsaid al entrar por SSH como root
if ! grep -q "DARKZSAID_AUTO_MENU_START" /root/.bashrc 2>/dev/null; then
cat >> /root/.bashrc <<'BASHRCEOF'

# DARKZSAID_AUTO_MENU_START
# Abrir DarkZsaid automáticamente al entrar por SSH como root
if [[ $- == *i* ]] && [[ -t 0 ]] && [[ -z "$DARKZSAID_AUTO_MENU_SHOWN" ]]; then
  export DARKZSAID_AUTO_MENU_SHOWN=1
  if [[ -x /usr/local/bin/menu ]]; then
    /usr/local/bin/menu
  elif [[ -x /opt/darkzsaid/panel.sh ]]; then
    bash /opt/darkzsaid/panel.sh
  fi
fi
# DARKZSAID_AUTO_MENU_END
BASHRCEOF
fi
# DARKZSAID_AUTO_MENU_INSTALL_END


barra 85 "Comandos listos"

paso "[09/10] Verificación final"

bash -n "$INSTALL_DIR/panel.sh" >> "$LOGFILE" 2>&1 || fail "panel.sh tiene error de sintaxis"

if [[ -f "$INSTALL_DIR/core/github_loader.sh" ]]; then
  bash -n "$INSTALL_DIR/core/github_loader.sh" >> "$LOGFILE" 2>&1 || fail "github_loader.sh tiene error de sintaxis"
fi

if [[ -f "$INSTALL_DIR/core/preparar_vps.sh" ]]; then
  bash -n "$INSTALL_DIR/core/preparar_vps.sh" >> "$LOGFILE" 2>&1 || fail "preparar_vps.sh tiene error de sintaxis"
fi

if [[ -f "$INSTALL_DIR/install-public.sh" ]]; then
  bash -n "$INSTALL_DIR/install-public.sh" >> "$LOGFILE" 2>&1 || fail "install-public.sh tiene error de sintaxis"
fi

ok "Sintaxis correcta"

barra 95 "Verificación completada"

paso "[10/10] Finalizando instalación"

rm -f /tmp/darkzsaid_dominio_instalacion.txt >> "$LOGFILE" 2>&1
hash -r 2>/dev/null || true

barra 100 "Instalación completada"

echo
echo -e "${CYAN}╔══════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║${RESET}        ${VERDE}DARKZSAID INSTALADO CORRECTAMENTE${RESET}       ${CYAN}║${RESET}"
echo -e "${CYAN}╚══════════════════════════════════════════════╝${RESET}"
echo

if [[ -s "$INSTALL_DIR/dominio.txt" ]]; then
  echo -e "${BLANCO}Dominio:${RESET} ${VERDE}$(cat "$INSTALL_DIR/dominio.txt")${RESET}"
else
  echo -e "${BLANCO}Dominio:${RESET} ${AMARILLO}No configurado${RESET}"
fi

echo -e "${BLANCO}Panel:${RESET} ${VERDE}$INSTALL_DIR${RESET}"
echo -e "${BLANCO}Log instalación:${RESET} ${AMARILLO}$LOGFILE${RESET}"
echo
echo -e "${BLANCO}Para abrir el panel escribe:${RESET}"
echo -e "${VERDE}menu${RESET}"
echo -e "${VERDE}darkzsaid${RESET}"
echo
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo
