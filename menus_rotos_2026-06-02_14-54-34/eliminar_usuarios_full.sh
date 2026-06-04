#!/bin/bash

pantalla_limpia() {
    printf '\033c'
}


limpiar_pantalla() {
    printf '\033[H\033[2J\033[3J'
}


ROJO="\e[31m"
VERDE="\e[32m"
AMARILLO="\e[33m"
AZUL="\e[34m"
CYAN="\e[36m"
BLANCO="\e[97m"
RESET="\e[0m"
BOLD="\e[1m"

DB="/opt/darkzsaid/data/usuarios_ssh.db"
TOKENDB="/opt/darkzsaid/data/tokens_zivpn.db"
USERDIR="/etc/adm-lite/userDIR"

mkdir -p /opt/darkzsaid/data
mkdir -p "$USERDIR"
touch "$DB"
touch "$TOKENDB"

listar_usuarios() {
python3 <<'PY'
import os
import re
import subprocess

DB="/opt/darkzsaid/data/usuarios_ssh.db"
USERDIR="/etc/adm-lite/userDIR"

usuarios=[]

def add(u):
    u=(u or "").strip()
    if not u:
        return
    if u.startswith("#") or u.lower() in ["usuario","user","readme"]:
        return
    if "/" in u or u.startswith(".git"):
        return
    if u not in usuarios:
        usuarios.append(u)

# Leer DB principal
if os.path.exists(DB):
    with open(DB, "r", errors="ignore") as f:
        for raw in f:
            line=raw.strip()
            if not line or line.startswith("#"):
                continue
            if "|" in line:
                p=line.split("|")
            elif ":" in line:
                p=line.split(":")
            else:
                p=re.split(r"\s+", line)
            if p:
                add(p[0])

# Leer userDIR viejo
if os.path.isdir(USERDIR):
    for name in os.listdir(USERDIR):
        path=os.path.join(USERDIR,name)
        if os.path.isfile(path):
            add(name)

# Verificar usuarios Linux si aparecen en DB
# No listamos todo Linux para no mostrar root/system.
for i,u in enumerate(sorted(usuarios), start=1):
    print(f"{i}|{u}")
PY
}

borrar_usuario() {
    local usuario="$1"

    if [[ -z "$usuario" ]]; then
        echo -e "${ROJO}Usuario vacío. Cancelado.${RESET}"
        return
    fi

    echo -e "${AMARILLO}Eliminando usuario:${RESET} ${BLANCO}$usuario${RESET}"

    # Borrar usuario Linux si existe
    if id "$usuario" >/dev/null 2>&1; then
        pkill -u "$usuario" 2>/dev/null || true
        userdel -r "$usuario" >/dev/null 2>&1 || userdel "$usuario" >/dev/null 2>&1 || true
    fi

    # Borrar archivo userDIR
    rm -f "$USERDIR/$usuario" 2>/dev/null || true

    # Borrar de DB principal, tomando primer campo por | : o espacio
    python3 <<PY
from pathlib import Path
import re

usuario = "$usuario"

for file in ["/opt/darkzsaid/data/usuarios_ssh.db", "/opt/darkzsaid/data/tokens_zivpn.db"]:
    p = Path(file)
    if not p.exists():
        continue
    out = []
    for raw in p.read_text(errors="ignore").splitlines():
        line = raw.strip()
        if not line:
            continue

        if "|" in line:
            first = line.split("|",1)[0].strip()
        elif ":" in line:
            first = line.split(":",1)[0].strip()
        else:
            first = re.split(r"\s+", line)[0].strip()

        # También borrar si aparece como usuario exacto al inicio.
        if first == usuario:
            continue

        out.append(raw)

    p.write_text("\n".join(out) + ("\n" if out else ""))
PY

    bash /opt/darkzsaid/menus/sync_udpmod_users.sh 2>/dev/null || true

    echo -e "${VERDE}Usuario eliminado:${RESET} $usuario"
}

opcion_1_user() {
    limpiar_pantalla
    echo -e "${AMARILLO}USUARIOS REGISTRADOS${RESET}"
    echo -e "${AMARILLO}────────────────────────────────────────────${RESET}"

    mapfile -t LISTA < <(listar_usuarios)

    if [[ "${#LISTA[@]}" -eq 0 ]]; then
        echo -e "${ROJO}No hay usuarios registrados para eliminar.${RESET}"
        echo ""
        read -p "Presiona ENTER para continuar..."
        exit 0
    fi

    for item in "${LISTA[@]}"; do
        num="${item%%|*}"
        user="${item#*|}"
        echo -e "${ROJO}[$num]${RESET} ➜ ${BLANCO}$user${RESET}"
    done

    echo ""
    read -p "Escribe número o nombre del usuario: " eleccion

    if [[ -z "$eleccion" ]]; then
        echo -e "${ROJO}Cancelado.${RESET}"
        sleep 1
        exit 0
    fi

    usuario=""

    if [[ "$eleccion" =~ ^[0-9]+$ ]]; then
        for item in "${LISTA[@]}"; do
            num="${item%%|*}"
            user="${item#*|}"
            if [[ "$num" == "$eleccion" ]]; then
                usuario="$user"
                break
            fi
        done
    else
        usuario="$eleccion"
    fi

    if [[ -z "$usuario" ]]; then
        echo -e "${ROJO}No encontré ese usuario.${RESET}"
        read -p "Presiona ENTER para continuar..."
        exit 0
    fi

    borrar_usuario "$usuario"
    echo ""
    read -p "Presiona ENTER para continuar..."
}

opcion_borrar_todo() {
    limpiar_pantalla
    echo -e "${ROJO}${BOLD}BORRAR TODOS LOS USUARIOS REGISTRADOS${RESET}"
    echo -e "${AMARILLO}────────────────────────────────────────────${RESET}"
    echo ""

    mapfile -t LISTA < <(listar_usuarios)

    if [[ "${#LISTA[@]}" -eq 0 ]]; then
        echo -e "${AMARILLO}No hay usuarios registrados para borrar.${RESET}"
        echo ""
        read -p "Presiona ENTER para continuar..."
        exit 0
    fi

    echo -e "${AMARILLO}Se eliminarán estos usuarios:${RESET}"
    echo ""

    for item in "${LISTA[@]}"; do
        num="${item%%|*}"
        user="${item#*|}"
        echo -e "${ROJO}[$num]${RESET} $user"
    done

    echo ""
    echo -e "${ROJO}Borrando todo sin pedir confirmación...${RESET}"
    sleep 1

    for item in "${LISTA[@]}"; do
        user="${item#*|}"
        borrar_usuario "$user"
    done

    # Limpiar bases por seguridad
    : > "$DB"
    : > "$TOKENDB"
    rm -f "$USERDIR"/* 2>/dev/null || true

    echo ""
    bash /opt/darkzsaid/menus/sync_udpmod_users.sh 2>/dev/null || true

    echo -e "${VERDE}Todos los usuarios registrados fueron eliminados.${RESET}"
    echo ""
    read -p "Presiona ENTER para continuar..."
}

case "$1" in
    one)
        opcion_1_user
        ;;
    all)
        opcion_borrar_todo
        ;;
    *)
        echo "Uso: $0 one | all"
        ;;
esac
