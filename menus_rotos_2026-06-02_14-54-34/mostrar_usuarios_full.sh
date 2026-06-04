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

USERDIR="/etc/adm-lite/userDIR"
DB="/opt/darkzsaid/data/usuarios_ssh.db"

limpiar_pantalla
echo -e "======>>> 🐉 ${CYAN}DarkZsaid${RESET} 💥 ${ROJO}Plus${RESET} 🐉 <<<======"
echo ""
echo -e "${AMARILLO}🔐 ADMINISTRADOR DE USUARIOS SSH|SSL|DROPBEAR 🔐${RESET}"
echo -e "${AZUL}  ▸ M LIBRE:${RESET} $(free -m | awk '/Mem:/ {print $7"M"}') ${AZUL}  ▸ USO DE CPU:${RESET} $(top -bn1 | awk -F'id,' '/Cpu/ {split($1,a,","); print 100-a[length(a)]"%"}' 2>/dev/null)"
echo ""
echo -e "${AMARILLO}────────────────────────────────────────────${RESET}"
echo ""
echo -e "${AZUL}➜   USUARIO        CONTRASEÑA        LIMITE        CADUCA${RESET}"
echo -e "${AMARILLO}────────────────────────────────────────────${RESET}"

python3 <<'PY'
import os
import re
import subprocess
from datetime import datetime, date

DB = "/opt/darkzsaid/data/usuarios_ssh.db"
USERDIR = "/etc/adm-lite/userDIR"

ROJO = "\033[31m"
VERDE = "\033[32m"
AMARILLO = "\033[33m"
AZUL = "\033[34m"
CYAN = "\033[36m"
BLANCO = "\033[97m"
RESET = "\033[0m"

usuarios = {}

def dias_restantes(fecha):
    if not fecha or fecha in ["-", "0", "null", "None"]:
        return "-"
    fecha = fecha.strip()
    for fmt in ("%Y-%m-%d", "%d-%m-%Y", "%d/%m/%Y"):
        try:
            f = datetime.strptime(fecha, fmt).date()
            return str((f - date.today()).days)
        except:
            pass
    return fecha

def chage_expire(user):
    try:
        out = subprocess.check_output(["chage", "-l", user], text=True, stderr=subprocess.DEVNULL)
        for line in out.splitlines():
            if "Account expires" in line or "La cuenta caduca" in line:
                val = line.split(":", 1)[1].strip()
                if val.lower() in ["never", "nunca"]:
                    return "-"
                # Intentar convertir fecha estilo May 25, 2026
                try:
                    f = datetime.strptime(val, "%b %d, %Y").date()
                    return f.isoformat()
                except:
                    return val
    except:
        pass
    return "-"

def add_user(usuario, clave="-", limite="1", expira="-", tipo="NORMAL"):
    usuario = (usuario or "").strip()
    if not usuario:
        return
    if usuario.startswith("#") or usuario.lower() in ["usuario", "user", "readme"]:
        return

    # Evitar basura
    if "/" in usuario or usuario.startswith(".git"):
        return

    if expira in ["", "-", "0", "null", "None"]:
        expira = chage_expire(usuario)

    usuarios[usuario] = {
        "clave": clave.strip() if clave else "-",
        "limite": limite.strip() if limite else "1",
        "expira": expira.strip() if expira else "-",
        "tipo": tipo.strip() if tipo else "NORMAL",
    }

# 1) Leer base nueva usuarios_ssh.db
if os.path.exists(DB):
    with open(DB, "r", errors="ignore") as f:
        for raw in f:
            line = raw.strip()
            if not line or line.startswith("#"):
                continue

            # Soporta formatos:
            # usuario|clave|limite|expira
            # usuario:clave:limite:expira
            # usuario clave limite expira
            if "|" in line:
                p = line.split("|")
            elif ":" in line:
                p = line.split(":")
            else:
                p = re.split(r"\s+", line)

            p = [x.strip() for x in p if x.strip()]
            if len(p) >= 4:
                add_user(p[0], p[1], p[2], p[3], p[4] if len(p) > 4 else "NORMAL")
            elif len(p) == 3:
                add_user(p[0], p[1], "1", p[2], "NORMAL")
            elif len(p) == 2:
                add_user(p[0], p[1], "1", "-", "NORMAL")

# 2) Leer userDIR viejo si existe
if os.path.isdir(USERDIR):
    for name in os.listdir(USERDIR):
        path = os.path.join(USERDIR, name)
        if not os.path.isfile(path):
            continue

        clave = "-"
        limite = "1"
        expira = "-"
        tipo = "NORMAL"

        try:
            content = open(path, "r", errors="ignore").read().strip()
        except:
            content = ""

        # key=value
        for line in content.splitlines():
            if "=" in line:
                k, v = line.split("=", 1)
                k = k.strip().lower()
                v = v.strip().strip('"')
                if k in ["pass", "password", "senha", "clave", "contraseña"]:
                    clave = v
                elif k in ["limit", "limite", "conexiones"]:
                    limite = v
                elif k in ["expire", "expira", "caduca", "fecha"]:
                    expira = v
                elif k in ["tipo", "type"]:
                    tipo = v

        # formato plano
        if content and clave == "-":
            if "|" in content:
                p = content.replace("\n", "|").split("|")
            else:
                p = re.split(r"\s+", content.replace("\n", " "))
            p = [x.strip() for x in p if x.strip()]
            if len(p) >= 3:
                clave = p[0]
                limite = p[1]
                expira = p[2]

        add_user(name, clave, limite, expira, tipo)

# 3) Si no hay registros, revisar usuarios Linux creados
# Solo como respaldo: usuarios con UID >= 1000 y shell válido
if not usuarios:
    try:
        with open("/etc/passwd", "r", errors="ignore") as f:
            for line in f:
                parts = line.strip().split(":")
                if len(parts) < 7:
                    continue
                user, uid, shell = parts[0], parts[2], parts[6]
                try:
                    uid = int(uid)
                except:
                    continue
                if uid >= 1000 and ("bash" in shell or "sh" in shell):
                    add_user(user, "-", "1", chage_expire(user), "LINUX")
    except:
        pass

total = 0
for i, usuario in enumerate(sorted(usuarios.keys()), start=1):
    info = usuarios[usuario]
    clave = info["clave"]
    limite = info["limite"]
    expira = info["expira"]
    dias = dias_restantes(expira)

    if dias != "-":
        try:
            d = int(dias)
            caduca = f"{ROJO}EXP{RESET}" if d < 0 else f"{VERDE}{d}{RESET}"
        except:
            caduca = dias
    else:
        caduca = "-"

    print(f"{ROJO}[{i}]{RESET}> {BLANCO}{usuario:<14}{RESET} {AMARILLO}{clave:<16}{RESET} {CYAN}{limite:<8}{RESET} {caduca}")
    total += 1

print(f"\n🛡️ # TIENES  [ {VERDE}{total}{RESET} ] CLIENTES EN TU SERVIDOR 🛡️ #")
PY

echo -e "${AMARILLO}────────────────────────────────────────────${RESET}"
echo ""
read -p "Presiona ENTER para continuar..."
