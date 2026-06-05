
limpiar_pantalla() {
    printf '\033[H\033[2J\033[3J'
}


borrar_todos_usuarios_seguro() {
    limpiar_pantalla
    echo -e "${ROJO}${BOLD}BORRAR TODOS LOS USUARIOS REGISTRADOS${RESET}"
    echo -e "${AMARILLO}────────────────────────────────────────────${RESET}"
    echo ""

    DB="/opt/darkzsaid/data/usuarios_ssh.db"
    TMP="/tmp/darkzsaid_users_delete_$$.txt"

    if [[ ! -f "$DB" || ! -s "$DB" ]]; then
        echo -e "${AMARILLO}No hay usuarios registrados para borrar.${RESET}"
        read -r -p "Presiona ENTER para continuar..."
        return
    fi

    awk -F'|' '
    NF>=1 {
        u=$1
        if (u != "" && u != "0" && u != "root" && u != "ubuntu" && u != "admin" && u != "sshd" && u != "nobody") print u
    }' "$DB" | sort -u > "$TMP"

    if [[ ! -s "$TMP" ]]; then
        echo -e "${AMARILLO}No hay usuarios seguros para eliminar.${RESET}"
        rm -f "$TMP"
        read -r -p "Presiona ENTER para continuar..."
        return
    fi

    echo -e "${AMARILLO}Se eliminarán estos usuarios:${RESET}"
    echo ""
    n=1
    while read -r usuario; do
        echo -e "${ROJO}[$n]${RESET} ${BLANCO}$usuario${RESET}"
        n=$((n+1))
    done < "$TMP"

    echo ""
    echo -e "${ROJO}Esto NO borrará root, ubuntu, 0 ni usuarios del sistema.${RESET}"
    read -r -p "Escriba SI para confirmar: " confirma

    if [[ "$confirma" != "SI" ]]; then
        echo -e "${AMARILLO}Cancelado.${RESET}"
        rm -f "$TMP"
        read -r -p "Presiona ENTER para continuar..."
        return
    fi

    echo ""
    while read -r usuario; do
        [[ -z "$usuario" ]] && continue

        echo -e "${CYAN}➜ Eliminando usuario:${RESET} ${BLANCO}$usuario${RESET}"

        # matar solo procesos de ese usuario, nunca sshd global
        pkill -u "$usuario" 2>/dev/null || true

        # borrar usuario Linux si existe
        if id "$usuario" >/dev/null 2>&1; then
            userdel -f "$usuario" 2>/dev/null || deluser --remove-home "$usuario" 2>/dev/null || true
        fi

        # borrar carpeta adm-lite si existe
        rm -f "/etc/adm-lite/userDIR/$usuario" 2>/dev/null || true

    done < "$TMP"

    # limpiar bases sin tocar archivos del sistema
    cp -f "$DB" "$DB.bak_delete_all_$FECHA" 2>/dev/null || true
    : > "$DB"

    # limpiar bases extra solo de registros, no borrar servicios
    : > /opt/darkzsaid/data/tokens_zivpn.db 2>/dev/null || true
    : > /opt/darkzsaid/data/udpmod_users.db 2>/dev/null || true

    rm -f "$TMP"

    echo ""
    echo -e "${VERDE}${BOLD}✔ Usuarios eliminados sin cerrar SSH.${RESET}"
    echo ""
    read -r -p "Presiona ENTER para continuar..."
}


checkuser_protocolo_menu() {
    while true; do
        limpiar_pantalla
        echo -e "${CYAN}╔════════════════════════════════════════════════════╗${RESET}"
        echo -e "${CYAN}║${RESET} ${BLANCO}${BOLD}           CHECK USER API / PROTOCOLO          ${RESET}${CYAN}║${RESET}"
        echo -e "${CYAN}╚════════════════════════════════════════════════════╝${RESET}"
        echo ""

        if systemctl is-active --quiet darkzsaid-checkuser 2>/dev/null; then
            ESTADO_CHK="${VERDE}ACTIVO${RESET}"
        else
            ESTADO_CHK="${ROJO}APAGADO${RESET}"
        fi

        PUERTO_CHK=$(grep -m1 '^Environment=CHECKUSER_PORT=' /etc/systemd/system/darkzsaid-checkuser.service 2>/dev/null | cut -d= -f3)
        [[ -z "$PUERTO_CHK" ]] && PUERTO_CHK="2095"

        if ss -lntup 2>/dev/null | grep -q ":${PUERTO_CHK}"; then
            PUERTO_TXT="${VERDE}${PUERTO_CHK} ABIERTO${RESET}"
        else
            PUERTO_TXT="${ROJO}${PUERTO_CHK} CERRADO${RESET}"
        fi

        IP_PUBLICA=$(curl -s --max-time 3 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')

        echo -e "${AMARILLO} Servicio CheckUser :${RESET} $ESTADO_CHK"
        echo -e "${AMARILLO} Puerto API         :${RESET} $PUERTO_TXT"
        echo -e "${AMARILLO} URL App            :${RESET} ${BLANCO}http://${IP_PUBLICA}:${PUERTO_CHK}/checkUser${RESET}"
        echo ""
        echo -e "${CYAN}┌──────────────────────────────────────────────────┐${RESET}"
        echo -e "${CYAN}│${RESET} ${ROJO}[1]${RESET} ${BLANCO}Activar / instalar CheckUser API${RESET}"
        echo -e "${CYAN}│${RESET} ${ROJO}[2]${RESET} ${BLANCO}Detener CheckUser API${RESET}"
        echo -e "${CYAN}│${RESET} ${ROJO}[3]${RESET} ${BLANCO}Reiniciar CheckUser API${RESET}"
        echo -e "${CYAN}│${RESET} ${ROJO}[4]${RESET} ${BLANCO}Ver URL / probar usuario${RESET}"
        echo -e "${CYAN}│${RESET} ${ROJO}[5]${RESET} ${BLANCO}Remover CheckUser API${RESET}"
        echo -e "${CYAN}│${RESET} ${ROJO}[0]${RESET} ${AMARILLO}Volver${RESET}"
        echo -e "${CYAN}└──────────────────────────────────────────────────┘${RESET}"
        echo ""
        read -r -p "⚡ Opción: " op_chk

        case "$op_chk" in
            1|01)
                limpiar_pantalla
                echo -e "${CYAN}╔════════════════════════════════════════════════════╗${RESET}"
                echo -e "${CYAN}║${RESET} ${BLANCO}${BOLD}        ACTIVAR CHECK USER API DARKZSAID       ${RESET}${CYAN}║${RESET}"
                echo -e "${CYAN}╚════════════════════════════════════════════════════╝${RESET}"
                echo ""
                read -r -p "Puerto CheckUser [def: 2095]: " puerto
                [[ -z "$puerto" ]] && puerto="2095"

                if ! [[ "$puerto" =~ ^[0-9]+$ ]]; then
                    echo -e "${ROJO}Puerto inválido.${RESET}"
                    read -r -p "Presiona ENTER para continuar..."
                    continue
                fi

                mkdir -p /opt/darkzsaid/bin /opt/darkzsaid/data /etc/adm-lite/userDIR

                cat > /opt/darkzsaid/bin/checkuser_server.py <<'PYCHK'
#!/usr/bin/env python3
import json
import os
import urllib.parse
from datetime import datetime, date
from http.server import BaseHTTPRequestHandler, HTTPServer

PORT = int(os.environ.get("CHECKUSER_PORT", "2095"))

DBS = [
    "/opt/darkzsaid/data/usuarios_ssh.db",
    "/opt/darkzsaid/data/tokens_zivpn.db",
    "/opt/darkzsaid/data/udpmod_users.db",
]

def parse_date(value):
    value = (value or "").strip()
    for fmt in ("%Y-%m-%d", "%d/%m/%Y", "%Y/%m/%d"):
        try:
            return datetime.strptime(value, fmt).date()
        except Exception:
            pass
    return None

def find_user(username, password):
    username = (username or "").strip()
    password = (password or "").strip()

    if not username:
        return None

    for db in DBS:
        if not os.path.isfile(db):
            continue

        with open(db, "r", errors="ignore") as f:
            for line in f:
                line = line.strip()
                if not line or "|" not in line:
                    continue

                parts = line.split("|")

                user = parts[0].strip() if len(parts) > 0 else ""
                passwd = parts[1].strip() if len(parts) > 1 else ""
                expira = parts[2].strip() if len(parts) > 2 else ""
                tipo = parts[3].strip() if len(parts) > 3 else "NORMAL"

                if user != username:
                    continue

                if password and passwd != password:
                    continue

                exp_date = parse_date(expira)
                today = date.today()

                if exp_date:
                    dias = (exp_date - today).days
                    activo = dias >= 0
                else:
                    dias = 0
                    activo = True

                return {
                    "found": True,
                    "usuario": user,
                    "tipo": tipo,
                    "estado": "ACTIVO" if activo else "EXPIRADO",
                    "activo": activo,
                    "dias": dias,
                    "dias_restantes": dias,
                    "expira": expira,
                    "vencimiento": expira,
                    "db": os.path.basename(db),
                }

    return None

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        return

    def send_json(self, data, code=200):
        body = json.dumps(data, ensure_ascii=False, indent=2).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        query = urllib.parse.parse_qs(parsed.query)
        path_parts = [x for x in parsed.path.split("/") if x]

        user = (
            query.get("user", [""])[0]
            or query.get("usuario", [""])[0]
            or query.get("username", [""])[0]
        )

        passwd = (
            query.get("pass", [""])[0]
            or query.get("password", [""])[0]
            or query.get("clave", [""])[0]
            or query.get("senha", [""])[0]
        )

        if len(path_parts) >= 3 and path_parts[0].lower() == "checkuser":
            user = urllib.parse.unquote(path_parts[1])
            passwd = urllib.parse.unquote(path_parts[2])

        if parsed.path in ["/", "/checkUser", "/checkuser"] or parsed.path.lower().startswith("/checkuser"):
            result = find_user(user, passwd)

            if result:
                return self.send_json(result)

            return self.send_json({
                "found": False,
                "estado": "NO_EXISTE",
                "activo": False,
                "dias": 0,
                "dias_restantes": 0,
                "expira": "",
                "vencimiento": "",
                "mensaje": "Usuario no encontrado o contraseña incorrecta"
            }, 404)

        return self.send_json({
            "status": "ok",
            "service": "DarkZsaid CheckUser",
            "endpoint": "/checkUser?user=USUARIO&pass=CLAVE"
        })

if __name__ == "__main__":
    server = HTTPServer(("0.0.0.0", PORT), Handler)
    print(f"DarkZsaid CheckUser activo en puerto {PORT}")
    server.serve_forever()
PYCHK

                chmod +x /opt/darkzsaid/bin/checkuser_server.py

                cat > /etc/systemd/system/darkzsaid-checkuser.service <<SERVICE
[Unit]
Description=DarkZsaid CheckUser API
After=network.target

[Service]
Type=simple
Environment=CHECKUSER_PORT=${puerto}
ExecStart=/usr/bin/python3 /opt/darkzsaid/bin/checkuser_server.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
SERVICE

                iptables -D INPUT -p tcp --dport "$puerto" -j ACCEPT 2>/dev/null || true
                iptables -I INPUT -p tcp --dport "$puerto" -j ACCEPT
                ufw allow "$puerto"/tcp >/dev/null 2>&1 || true

                systemctl daemon-reload
                systemctl enable darkzsaid-checkuser >/dev/null 2>&1
                systemctl restart darkzsaid-checkuser

                sleep 1

                echo ""
                if systemctl is-active --quiet darkzsaid-checkuser 2>/dev/null; then
                    echo -e "${VERDE}${BOLD}✔ CheckUser API activado correctamente.${RESET}"
                    echo -e "${AMARILLO}URL:${RESET} ${BLANCO}http://${IP_PUBLICA}:${puerto}/checkUser?user=USUARIO&pass=CLAVE${RESET}"
                else
                    echo -e "${ROJO}No se pudo activar CheckUser API.${RESET}"
                    systemctl status darkzsaid-checkuser --no-pager -l | head -20
                fi

                echo ""
                read -r -p "Presiona ENTER para continuar..."
                ;;

            2|02)
                systemctl stop darkzsaid-checkuser 2>/dev/null || true
                echo -e "${AMARILLO}CheckUser detenido.${RESET}"
                read -r -p "Presiona ENTER para continuar..."
                ;;

            3|03)
                systemctl restart darkzsaid-checkuser 2>/dev/null || true
                echo -e "${VERDE}CheckUser reiniciado.${RESET}"
                read -r -p "Presiona ENTER para continuar..."
                ;;

            4|04)
                echo ""
                echo -e "${AMARILLO}URL base:${RESET} ${BLANCO}http://${IP_PUBLICA}:${PUERTO_CHK}/checkUser${RESET}"
                echo -e "${AMARILLO}Ejemplo:${RESET} ${BLANCO}http://${IP_PUBLICA}:${PUERTO_CHK}/checkUser?user=USUARIO&pass=CLAVE${RESET}"
                echo ""
                read -r -p "Usuario para probar: " utest
                read -r -p "Contraseña para probar: " ptest
                echo ""
                curl -s "http://127.0.0.1:${PUERTO_CHK}/checkUser?user=${utest}&pass=${ptest}" || true
                echo ""
                read -r -p "Presiona ENTER para continuar..."
                ;;

            5|05)
                systemctl disable --now darkzsaid-checkuser 2>/dev/null || true
                rm -f /etc/systemd/system/darkzsaid-checkuser.service
                systemctl daemon-reload
                echo -e "${ROJO}CheckUser removido.${RESET}"
                read -r -p "Presiona ENTER para continuar..."
                ;;

            0|00)
                
        printf "c"
        exit 0
        ;;

            *)
                echo "Opción inválida."
                sleep 1
                ;;
        esac
    done
}



dz_borrar_1_user_directo_final() {
    bash /opt/darkzsaid/menus/eliminar_usuarios_full.sh one
}


dz_borrar_todos_sin_preguntar_registrados_final() {
    bash /opt/darkzsaid/menus/eliminar_usuarios_full.sh all
}



modificar_contrasena_token() {
    limpiar_pantalla
    echo "════════════════════════════════════════"
    echo "      MODIFICAR CONTRASEÑA TOKEN"
    echo "════════════════════════════════════════"
    echo ""

    mkdir -p /opt/darkzsaid/data /opt/darkzsaid/users

    TOKEN_FILE1="/opt/darkzsaid/data/token_password.conf"
    TOKEN_FILE2="/opt/darkzsaid/users/token_password.conf"
    TOKEN_KEY="/opt/darkzsaid/data/token.key"

    ACTUAL="No configurada"

    if [ -f "" ]; then
        ACTUAL=""
    elif [ -f "" ]; then
        ACTUAL=""
    elif [ -f "" ]; then
        ACTUAL=""
    fi

    echo "Contraseña token actual: "
    echo ""
    read -p "Nueva contraseña token: " NUEVA_TOKEN

    if [ -z "" ]; then
        echo "Contraseña vacía. Cancelado."
        read -p "Presiona ENTER para continuar..."
        return
    fi

    echo "TOKEN_PASSWORD=\"\"" > ""
    echo "" > ""
    echo "" > ""

    chmod 600 "" "" "" 2>/dev/null

    echo ""
    echo "Contraseña token actualizada correctamente."
    echo "Nueva contraseña token: "
    echo ""
    echo "En la app debe quedar:"
    echo "TOKEN_GENERADO:"
    echo ""
    read -p "Presiona ENTER para continuar..."
}



modificar_password_token_moc() {
    titulo "MODIFICAR CONTRASEÑA TOKEN MOC"

    mkdir -p /opt/darkzsaid/users
    mkdir -p /opt/darkzsaid/data

    echo ""
    if [[ -f "$TOKEN_PASS_FILE" ]]; then
        echo "Contraseña Token actual:"
        echo -e "${VERDE}$(cat "$TOKEN_PASS_FILE")${RESET}"
    else
        echo -e "${AMARILLO}CONTRASEÑA TOKEN MOC:${RESET} No configurada"
    fi

    echo ""
    echo -e "${AMARILLO}ATENCION ANTES DE CONTINUAR${RESET}"
    echo ""
    echo "SE DEFINIRA SU CONTRASEÑA TOKEN UNICA"
    echo "UNA VEZ COLOCADA SE RECOMIENDA NO CAMBIARLA"
    echo ""
    read -p "NUEVA CONTRASEÑA TOKEN MOC: " nueva

    if [[ -z "$nueva" ]]; then
        echo "Contraseña token vacía."
        pausa
        return
    fi

    echo "$nueva" > "$TOKEN_PASS_FILE"
    chmod 600 "$TOKEN_PASS_FILE"

    # Copias espejo por compatibilidad con menú nuevo
    echo "$nueva" > /opt/darkzsaid/data/token.key
    cat > /opt/darkzsaid/data/token_password.conf <<EOF
TOKEN_PASSWORD="$nueva"
EOF

    chmod 600 /opt/darkzsaid/data/token.key
    chmod 600 /opt/darkzsaid/data/token_password.conf

    echo ""
    echo -e "${VERDE}Contraseña Token MOC actualizada correctamente.${RESET}"
    echo ""
    echo "Contraseña Token MOC: $nueva"
    echo ""
    echo "Guardado principal:"
    echo "$TOKEN_PASS_FILE"
    pausa
}


TOKEN_PASS_FILE="/opt/darkzsaid/users/token_password.conf"
#!/bin/bash

[[ -f /opt/darkzsaid/lib/ui.sh ]] && source /opt/darkzsaid/lib/ui.sh

ROJO="${ROJO:-\e[31m}"
VERDE="${VERDE:-\e[32m}"
AMARILLO="${AMARILLO:-\e[33m}"
AZUL="${AZUL:-\e[34m}"
CYAN="${CYAN:-\e[36m}"
BLANCO="${BLANCO:-\e[97m}"
RESET="${RESET:-\e[0m}"

DATA_DIR="/opt/darkzsaid/data"
USER_DB="$DATA_DIR/usuarios_ssh.db"
TOKEN_DB="$DATA_DIR/tokens_zivpn.db"
LIMIT_DB="$DATA_DIR/limites.db"

mkdir -p "$DATA_DIR" /opt/darkzsaid/backups

pausa_local() {
    echo ""
    read -r -p "Presiona ENTER para continuar..."
}

leer_local() {
    local var="$1"
    local prompt="$2"
    local val=""
    echo ""
    read -r -p "$prompt" val
    val="$(echo "$val" | xargs 2>/dev/null)"
    printf -v "$var" "%s" "$val"
}

opcion_mala() {
    echo ""
    echo -e "${ROJO}✖ Opción inválida.${RESET}"
    echo -e "${AMARILLO}Intenta nuevamente o presiona 0 para volver.${RESET}"
    sleep 1
}




titulo_users() {
    limpiar_pantalla
    echo -e "${CYAN}╔════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET}        ${BLANCO}⚡ DARKZSAID CONTROL PANEL ⚡${RESET}     ${CYAN}║${RESET}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${AMARILLO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "      ${VERDE}$1${RESET}"
    echo -e "${AMARILLO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
}

fecha_expira() {
    local dias="$1"
    date -d "+$dias days" +"%Y-%m-%d"
}

guardar_usuario_db() {
    local usuario="$1"
    local pass="$2"
    local tipo="$3"
    local limite="$4"
    local dias="$5"
    local expira="$6"

    grep -v "^$usuario|" "$USER_DB" 2>/dev/null > "$USER_DB.tmp" || true
    mv "$USER_DB.tmp" "$USER_DB" 2>/dev/null || true

    echo "$usuario|$pass|$tipo|$limite|$dias|$expira" >> "$USER_DB"
}



crear_normal() {
    titulo_users "CREAR SSH DROPBEAR"

    leer_local usuario "Usuario: "
    [[ -z "$usuario" ]] && echo "Usuario vacío." && pausa_local && return

    leer_local pass "Contraseña: "
    [[ -z "$pass" ]] && echo "Contraseña vacía." && pausa_local && return

    leer_local limite "Límite de conexiones: "
    [[ -z "$limite" ]] && limite="1"

    leer_local dias "Días de validez: "
    [[ -z "$dias" ]] && dias="1"

    expira="$(fecha_expira "$dias")"

    crear_usuario_linux "$usuario" "$pass" "$expira"
    guardar_usuario_db "$usuario" "$pass" "NORMAL" "$limite" "$dias" "$expira"

    echo ""
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET}        ${BLANCO}${BOLD}CUENTA SSH CREADA${RESET}              ${CYAN}║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${VERDE}${BOLD}✔ Usuario creado correctamente.${RESET}"
    echo ""
    echo ""
    echo -e "${AMARILLO}Usuario:${RESET} $usuario"
    echo -e "${AMARILLO}Contraseña:${RESET} $pass"
    echo -e "${AMARILLO}Límite:${RESET} $limite"
    echo -e "${AMARILLO}Caduca:${RESET} $expira"
    echo -e "${AMARILLO}Días:${RESET} $dias"

    pausa_local
}

crear_hwid() {
    titulo_users "CREAR HWID"

    leer_local usuario "Usuario: "
    [[ -z "$usuario" ]] && echo "Usuario vacío." && pausa_local && return

    leer_local pass "Contraseña: "
    [[ -z "$pass" ]] && echo "Contraseña vacía." && pausa_local && return

    leer_local hwid "HWID: "
    [[ -z "$hwid" ]] && hwid="SIN-HWID"

    leer_local limite "Límite de conexiones: "
    [[ -z "$limite" ]] && limite="1"

    leer_local dias "Días de validez: "
    [[ -z "$dias" ]] && dias="1"

    expira="$(fecha_expira "$dias")"

    crear_usuario_linux "$usuario" "$pass" "$expira"
    guardar_usuario_db "$usuario" "$pass" "HWID:$hwid" "$limite" "$dias" "$expira"

    echo ""
    echo -e "${VERDE}✔ HWID creado correctamente.${RESET}"
    echo ""
    echo -e "${AMARILLO}Usuario:${RESET} $usuario"
    echo -e "${AMARILLO}Contraseña:${RESET} $pass"
    echo -e "${AMARILLO}HWID:${RESET} $hwid"
    echo -e "${AMARILLO}Límite:${RESET} $limite"
    echo -e "${AMARILLO}Caduca:${RESET} $expira"
    echo -e "${AMARILLO}Días:${RESET} $dias"

    pausa_local
}

crear_token() {
    bash /opt/darkzsaid/menus/crear_token_oficial.sh
    bash /opt/darkzsaid/menus/fix_udpmod_permanente.sh >/dev/null 2>&1 || true
    echo
    read -r -p "Presiona ENTER para continuar..."
}

menu_agregar_usuario() {
    while true; do
        titulo_users "AGREGAR USUARIO"

        echo -e "${ROJO}[01]${RESET} ${CYAN}➜${RESET} ${BLANCO}SSH DROPBEAR${RESET}"
        echo ""
        echo -e "${ROJO}[00]${RESET} ${CYAN}➜${RESET} ${ROJO}[ VOLVER ]${RESET}"

        leer_local op "⚡ Opción: "

        case "$op" in
            4|04) modificar_contrasena_token ;;
        5|05) modificar_password_token_moc ;;
            1|01) crear_normal ;;
            2|02) crear_hwid ;;
            3|03) crear_token ;;
            4|04) modificar_password_token_moc ;;
            0|00) return ;;
            *) opcion_mala ;;
        esac
    done
}


listar_usuarios() {
    limpiar_pantalla

    echo -e "${CYAN}====================================================${RESET}"
    echo -e "${BLANCO}                 CLIENTES DARKZSAID                 ${RESET}"
    echo -e "${CYAN}====================================================${RESET}"
    echo
    echo -e "${CYAN}Memoria libre:${RESET} ${VERDE}$(free -m | awk '/Mem:/ {print $4"M"}')${RESET}   ${CYAN}CPU:${RESET} ${VERDE}$(top -bn1 | grep 'Cpu' | awk '{print int($2)}')%${RESET}"
    echo
    echo -e "${AMARILLO}----------------------------------------------------${RESET}"
    printf "${CYAN}%-5s %-14s %-14s %-10s %-8s${RESET}
" "N" "USUARIO" "CONTRASEÑA" "LIMITE" "CADUCA"
    echo -e "${AMARILLO}----------------------------------------------------${RESET}"

    total=0
    n=1

    if [[ -s "$USER_DB" ]]; then
        while IFS='|' read -r usuario clave fecha limite tipo nombre creado; do
            [[ -z "$usuario" ]] && continue

            total=$((total+1))

            [[ -z "$clave" ]] && clave="-"
            [[ -z "$limite" ]] && limite="NORMAL"

            dias="$(dias_restantes "$fecha" 2>/dev/null)"
            [[ -z "$dias" ]] && dias="$fecha"
            [[ -z "$dias" ]] && dias="-"

            printf "${ROJO}[%02d]${RESET} %-14s ${AMARILLO}%-14s${RESET} ${CYAN}%-10s${RESET} ${VERDE}%-8s${RESET}
" \
                "$n" "$usuario" "$clave" "$limite" "$dias"

            n=$((n+1))
        done < "$USER_DB"
    fi

    if [[ -s "$TOKEN_DB" ]]; then
        while IFS='|' read -r token dias expira extra; do
            [[ -z "$token" ]] && continue

            total=$((total+1))
            etiqueta="TOKEN$n"

            [[ -z "$dias" ]] && dias="-"
            [[ -z "$expira" ]] && expira="-"

            printf "${ROJO}[%02d]${RESET} %-14s ${AMARILLO}%-14s${RESET} ${CYAN}%-10s${RESET} ${VERDE}%-8s${RESET}
" \
                "$n" "$etiqueta" "$token" "TOKEN" "$expira"

            n=$((n+1))
        done < "$TOKEN_DB"
    fi

    echo -e "${AMARILLO}----------------------------------------------------${RESET}"
    echo
    if [[ "$total" -eq 0 ]]; then
        echo -e "${ROJO}TOTAL CLIENTES: 0${RESET}"
    else
        echo -e "${VERDE}TOTAL CLIENTES: $total${RESET}"
    fi
    echo
    echo -e "${CYAN}====================================================${RESET}"

    pausa_local
}

eliminar_un_usuario() {
    titulo_users "ELIMINAR 1 USUARIO"

    echo -e "${CYAN}- LISTA DE USUARIOS DISPONIBLES -${RESET}"
    echo -e "${AMARILLO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

    awk -F'|' '{print NR") "$1" ["$3"]"}' "$USER_DB" 2>/dev/null
    echo ""
    echo -e "${AMARILLO}Tokens:${RESET}"
    awk -F'|' '{print NR") "$1" [TOKEN]"}' "$TOKEN_DB" 2>/dev/null

    echo ""
    leer_local usuario "Escribe el usuario a eliminar: "

    [[ -z "$usuario" ]] && echo "Usuario vacío." && pausa_local && return

    if id "$usuario" >/dev/null 2>&1; then
        userdel -f "$usuario" >/dev/null 2>&1
    fi

    grep -v "^$usuario|" "$USER_DB" 2>/dev/null > "$USER_DB.tmp" || true
    mv "$USER_DB.tmp" "$USER_DB" 2>/dev/null || true

    grep -v "^$usuario|" "$TOKEN_DB" 2>/dev/null > "$TOKEN_DB.tmp" || true
    mv "$TOKEN_DB.tmp" "$TOKEN_DB" 2>/dev/null || true

    echo ""
    echo -e "${VERDE}✔ Usuario eliminado si existía:${RESET} $usuario"
    pausa_local
}
eliminar_caducados() {
    while true; do
        limpiar_pantalla
        titulo_users "ELIMINAR USUARIOS"
        echo -e "${ROJO}[01]${RESET} ${CYAN}➜${RESET} ${BLANCO}1 USER${RESET}"
        echo -e "${ROJO}[02]${RESET} ${CYAN}➜${RESET} ${BLANCO}TODOS ITERATIVO 1x1${RESET} ${VERDE}[RECOMENDADO]${RESET}"
        echo -e "${ROJO}[03]${RESET} ${CYAN}➜${RESET} ${BLANCO}SOLO CADUCADOS${RESET}"
        echo -e "${ROJO}[04]${RESET} ${CYAN}➜${RESET} ${ROJO}BORRAR TODO${RESET}"
        echo ""
        echo -e "${ROJO}[00]${RESET} ${CYAN}➜${RESET} ${BLANCO}[ VOLVER ]${RESET}"
        echo ""
        read -p "⚡ Opción: " opc

        case "$opc" in
            1|01)
                bash /opt/darkzsaid/menus/eliminar_usuarios_full.sh one
                ;;
            2|02)
                bash /opt/darkzsaid/menus/eliminar_usuarios_full.sh one
                ;;
            3|03)
                bash /opt/darkzsaid/menus/eliminar_usuarios_full.sh one
                ;;
            4|04)
                bash /opt/darkzsaid/menus/eliminar_usuarios_full.sh all
                ;;
            0|00)
                return
                ;;
            *)
                echo -e "${ROJO}Opción inválida.${RESET}"
                sleep 1
                ;;
        esac
    done
}


eliminar_todos() {
    titulo_users "ELIMINAR TODOS LOS USUARIOS"

    read -r -p "¿Seguro que quieres eliminar todos los usuarios del script? [s/n]: " r

    if [[ "$r" != "s" && "$r" != "S" ]]; then
        echo "Cancelado."
        pausa_local
        return
    fi

    if [[ -s "$USER_DB" ]]; then
        while IFS='|' read -r usuario pass tipo limite dias expira; do
            [[ -z "$usuario" ]] && continue
            userdel -f "$usuario" >/dev/null 2>&1 || true
        done < "$USER_DB"
    fi

    > "$USER_DB"
    > "$TOKEN_DB"

    echo ""
    echo -e "${VERDE}✔ Todos los usuarios del script fueron eliminados.${RESET}"
    pausa_local
}

menu_eliminar_usuarios() {
    while true; do
        titulo_users "ELIMINAR USUARIOS"

        echo -e "${ROJO}[01]${RESET} ${CYAN}➜${RESET} ${BLANCO}1 USER${RESET}"
        echo -e "${ROJO}[02]${RESET} ${CYAN}➜${RESET} ${BLANCO}TODOS ITERATIVO 1x1${RESET} ${VERDE}[RECOMENDADO]${RESET}"
        echo -e "${ROJO}[03]${RESET} ${CYAN}➜${RESET} ${BLANCO}SOLO CADUCADOS${RESET}"
        echo -e "${ROJO}[04]${RESET} ${CYAN}➜${RESET} ${ROJO}BORRAR TODO${RESET}"
        echo ""
        echo -e "${ROJO}[00]${RESET} ${CYAN}➜${RESET} ${ROJO}[ VOLVER ]${RESET}"

        leer_local op "⚡ Opción: "

        case "$op" in
            1|01) dz_borrar_1_user_directo_final ;;
            2|02) dz_borrar_todos_iterativo_full ;;
            3|03) dz_borrar_solo_caducados_full ;;
            4|04) dz_borrar_todos_sin_preguntar_registrados_final ;;
            0|00) return ;;
            *) opcion_mala ;;
        esac
    done
}

renovar_usuario() {
    titulo_users "EDITAR / RENOVAR USUARIO"

    leer_local usuario "Usuario a renovar: "
    [[ -z "$usuario" ]] && echo "Usuario vacío." && pausa_local && return

    leer_local dias "Nuevos días: "
    [[ -z "$dias" ]] && dias="1"

    expira="$(fecha_expira "$dias")"

    if id "$usuario" >/dev/null 2>&1; then
        chage -E "$expira" "$usuario" >/dev/null 2>&1
    fi

    if grep -q "^$usuario|" "$USER_DB" 2>/dev/null; then
        awk -F'|' -v u="$usuario" -v d="$dias" -v e="$expira" 'BEGIN{OFS="|"} {
            if ($1==u) {$5=d; $6=e}
            print
        }' "$USER_DB" > "$USER_DB.tmp"
        mv "$USER_DB.tmp" "$USER_DB"
    fi

    if grep -q "^$usuario|" "$TOKEN_DB" 2>/dev/null; then
        awk -F'|' -v u="$usuario" -v d="$dias" -v e="$expira" 'BEGIN{OFS="|"} {
            if ($1==u) {$3=d; $4=e}
            print
        }' "$TOKEN_DB" > "$TOKEN_DB.tmp"
        mv "$TOKEN_DB.tmp" "$TOKEN_DB"
    fi

    echo ""
    echo -e "${VERDE}✔ Usuario renovado:${RESET} $usuario"
    echo -e "${AMARILLO}Nueva caducidad:${RESET} $expira"
    pausa_local
}

backup_usuarios() {
    titulo_users "BACKUP USUARIOS"

    archivo="/opt/darkzsaid/backups/usuarios_backup_$(date +%s).tar.gz"

    tar -czf "$archivo" "$USER_DB" "$TOKEN_DB" /etc/passwd /etc/shadow /etc/group /etc/gshadow 2>/dev/null

    echo -e "${VERDE}✔ Backup creado:${RESET}"
    echo "$archivo"
    pausa_local
}

restaurar_backup_usuarios() {
    titulo_users "RESTAURAR BACKUP USUARIOS"

    echo "Backups disponibles:"
    echo ""
    ls -lh /opt/darkzsaid/backups/usuarios_backup_*.tar.gz 2>/dev/null || echo "No hay backups."
    echo ""

    leer_local archivo "Ruta del backup a restaurar: "

    if [[ ! -f "$archivo" ]]; then
        echo "Archivo no existe."
        pausa_local
        return
    fi

    tar -xzf "$archivo" -C / 2>/dev/null

    echo ""
    echo -e "${VERDE}✔ Backup restaurado.${RESET}"
    pausa_local
}





# ==========================================================
# RESTAURACIÓN FINAL: EDITAR POR NÚMERO/NOMBRE + CONECTADOS
# ==========================================================

listar_usuarios_para_elegir() {
    echo -e "${CYAN}- LISTA DE USUARIOS DISPONIBLES -${RESET}"
    echo -e "${AMARILLO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

    if [[ ! -s "$USER_DB" ]]; then
        echo "No hay usuarios registrados en la base del script."
        echo -e "${AMARILLO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        return 1
    fi

    local n=1

    while IFS='|' read -r usuario pass tipo limite dias expira; do
        [[ -z "$usuario" ]] && continue
        echo -e "${ROJO}[$n]${RESET} ${CYAN}➜${RESET} ${VERDE}$usuario${RESET}"
        n=$((n+1))
    done < "$USER_DB"

    echo -e "${AMARILLO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    return 0
}

obtener_usuario_por_numero_o_nombre_final() {
    local entrada="$1"
    local encontrado=""

    if [[ "$entrada" =~ ^[0-9]+$ ]]; then
        encontrado=$(awk -F'|' -v n="$entrada" 'NR==n {print $1; exit}' "$USER_DB" 2>/dev/null)
    else
        encontrado=$(awk -F'|' -v u="$entrada" '$1==u {print $1; exit}' "$USER_DB" 2>/dev/null)
    fi

    echo "$encontrado"
}

seleccionar_usuario_final() {
    listar_usuarios_para_elegir || return 1

    echo ""
    leer_local entrada_usuario "ESCRIBE (nombre o número) DEL USUARIO: "

    if [[ -z "$entrada_usuario" ]]; then
        echo -e "${ROJO}No escribiste ningún usuario.${RESET}"
        pausa_local
        return 1
    fi

    usuario=$(obtener_usuario_por_numero_o_nombre_final "$entrada_usuario")

    if [[ -z "$usuario" ]]; then
        echo -e "${ROJO}Usuario no encontrado.${RESET}"
        pausa_local
        return 1
    fi

    echo ""
    echo -e "${VERDE}Seleccionaste el usuario:${RESET} ${CYAN}$usuario${RESET}"
    sleep 1
    return 0
}

datos_usuario_final() {
    grep "^$usuario|" "$USER_DB" 2>/dev/null | head -1
}

guardar_usuario_final() {
    local nueva_linea="$1"

    grep -v "^$usuario|" "$USER_DB" 2>/dev/null > "$USER_DB.tmp" || true
    echo "$nueva_linea" >> "$USER_DB.tmp"
    mv "$USER_DB.tmp" "$USER_DB"
}

actualizar_linux_expira_final() {
    local user="$1"
    local fecha="$2"

    if id "$user" >/dev/null 2>&1; then
        chage -E "$fecha" "$user" >/dev/null 2>&1 || true
    fi
}



# ==========================================================
# BORRAR 1 USUARIO: TAMBIÉN POR NÚMERO O NOMBRE
# ==========================================================

eliminar_un_usuario() {
    titulo_users "ELIMINAR 1 USUARIO"

    seleccionar_usuario_final || return

    echo ""
    read -r -p "¿Eliminar usuario $usuario? [s/n]: " r

    if [[ "$r" != "s" && "$r" != "S" ]]; then
        echo "Cancelado."
        pausa_local
        return
    fi

    if id "$usuario" >/dev/null 2>&1; then
        userdel -f "$usuario" >/dev/null 2>&1 || true
    fi

    grep -v "^$usuario|" "$USER_DB" 2>/dev/null > "$USER_DB.tmp" || true
    mv "$USER_DB.tmp" "$USER_DB" 2>/dev/null || true

    grep -v "^$usuario|" "$TOKEN_DB" 2>/dev/null > "$TOKEN_DB.tmp" || true
    mv "$TOKEN_DB.tmp" "$TOKEN_DB" 2>/dev/null || true

    echo ""
    echo -e "${VERDE}✔ Usuario eliminado correctamente:${RESET} $usuario"
    pausa_local
}

# ==========================================================
# EDITAR / RENOVAR USUARIOS COMO EN LAS IMÁGENES
# ==========================================================

editar_limite_cliente_final() {
    titulo_users "LIMITADOR DEL CLIENTE"

    linea=$(datos_usuario_final)
    IFS='|' read -r u pass tipo limite dias expira <<< "$linea"

    echo -e "${AMARILLO}Cliente:${RESET} $usuario"
    echo -e "${AMARILLO}Límite actual:${RESET} $limite"
    echo ""
    leer_local nuevo_limite "NUEVO LÍMITE: "

    if ! [[ "$nuevo_limite" =~ ^[0-9]+$ ]]; then
        echo -e "${ROJO}Límite inválido.${RESET}"
        pausa_local
        return
    fi

    guardar_usuario_final "$u|$pass|$tipo|$nuevo_limite|$dias|$expira"

    echo ""
    echo -e "${VERDE}✔ Límite actualizado correctamente.${RESET}"
    echo -e "${AMARILLO}Cliente:${RESET} $usuario"
    echo -e "${AMARILLO}Nuevo límite:${RESET} $nuevo_limite"
    pausa_local
}

anadir_dias_cliente_final() {
    titulo_users "AÑADIR DÍAS"

    linea=$(datos_usuario_final)
    IFS='|' read -r u pass tipo limite dias expira <<< "$linea"

    echo -e "${AMARILLO}Cliente:${RESET} $usuario"
    echo -e "${AMARILLO}Válido hasta:${RESET} $expira"
    echo ""
    leer_local cantidad "DÍAS A AÑADIR: "

    if ! [[ "$cantidad" =~ ^[0-9]+$ ]]; then
        echo -e "${ROJO}Cantidad inválida.${RESET}"
        pausa_local
        return
    fi

    nueva_fecha=$(date -d "$expira +$cantidad days" +"%Y-%m-%d")
    nuevos_dias=$((dias + cantidad))

    guardar_usuario_final "$u|$pass|$tipo|$limite|$nuevos_dias|$nueva_fecha"
    actualizar_linux_expira_final "$usuario" "$nueva_fecha"

    limpiar_pantalla
    echo -e "${AMARILLO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "              ${VERDE}ACTUALIZACION EXITOSA !!!${RESET}"
    echo -e "${AMARILLO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${VERDE}★ PERFECTO, ACTUALIZAMOS TU MEMBRESIA!! ★${RESET}"
    echo -e "${AMARILLO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
    echo -e "${AMARILLO}RENOVADO EL  :${RESET} $(date +%d/%m/%Y)"
    echo -e "${AMARILLO}Host / IP    :${RESET} $(curl -s --max-time 2 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')"
    echo -e "${AMARILLO}ID/CLIENTE   :${RESET} $usuario"
    echo -e "${AMARILLO}PERMITIDOS   :${RESET} $limite"
    echo -e "${AMARILLO}VALIDO HASTA :${RESET} $(date -d "$nueva_fecha" +%d/%m/%Y)"
    echo -e "${CYAN}RENUEVA EN $nuevos_dias DÍAS, DISFRUTE SU ESTANCIA!${RESET}"
    echo -e "${AMARILLO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

    pausa_local
}

quitar_dias_cliente_final() {
    titulo_users "QUITAR DÍAS"

    linea=$(datos_usuario_final)
    IFS='|' read -r u pass tipo limite dias expira <<< "$linea"

    echo -e "${AMARILLO}Cliente:${RESET} $usuario"
    echo -e "${AMARILLO}Válido hasta:${RESET} $expira"
    echo ""
    leer_local cantidad "DÍAS A QUITAR: "

    if ! [[ "$cantidad" =~ ^[0-9]+$ ]]; then
        echo -e "${ROJO}Cantidad inválida.${RESET}"
        pausa_local
        return
    fi

    nueva_fecha=$(date -d "$expira -$cantidad days" +"%Y-%m-%d")
    nuevos_dias=$((dias - cantidad))
    [[ "$nuevos_dias" -lt 0 ]] && nuevos_dias=0

    guardar_usuario_final "$u|$pass|$tipo|$limite|$nuevos_dias|$nueva_fecha"
    actualizar_linux_expira_final "$usuario" "$nueva_fecha"

    echo ""
    echo -e "${VERDE}✔ Días quitados correctamente.${RESET}"
    echo -e "${AMARILLO}Cliente:${RESET} $usuario"
    echo -e "${AMARILLO}Válido hasta:${RESET} $(date -d "$nueva_fecha" +%d/%m/%Y)"
    echo -e "${AMARILLO}Días restantes:${RESET} $nuevos_dias"
    pausa_local
}

reiniciar_dias_cliente_final() {
    titulo_users "REINICIAR DÍAS"

    linea=$(datos_usuario_final)
    IFS='|' read -r u pass tipo limite dias expira <<< "$linea"

    echo -e "${AMARILLO}Cliente:${RESET} $usuario"
    echo ""
    leer_local cantidad "NUEVA CANTIDAD DE DÍAS: "

    if ! [[ "$cantidad" =~ ^[0-9]+$ ]]; then
        echo -e "${ROJO}Cantidad inválida.${RESET}"
        pausa_local
        return
    fi

    nueva_fecha=$(date -d "+$cantidad days" +"%Y-%m-%d")

    guardar_usuario_final "$u|$pass|$tipo|$limite|$cantidad|$nueva_fecha"
    actualizar_linux_expira_final "$usuario" "$nueva_fecha"

    echo ""
    echo -e "${VERDE}✔ Días reiniciados correctamente.${RESET}"
    echo -e "${AMARILLO}Cliente:${RESET} $usuario"
    echo -e "${AMARILLO}Válido hasta:${RESET} $(date -d "$nueva_fecha" +%d/%m/%Y)"
    echo -e "${AMARILLO}Días:${RESET} $cantidad"
    pausa_local
}

menu_renovar_cliente_final() {
    while true; do
        titulo_users "MODIFICAR DATOS DE USUARIOS"

        echo -e "${CYAN}- LISTA DE USUARIOS DISPONIBLES -${RESET}"
        echo -e "${AMARILLO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -e "${ROJO}[$usuario]${RESET} ${CYAN}➜${RESET} ${VERDE}$usuario${RESET}"
        echo -e "${AMARILLO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo ""
        echo -e "${VERDE}Seleccionaste el usuario:${RESET} ${CYAN}$usuario${RESET}"
        echo -e "${AMARILLO}ESCOJE LA OPCIÓN A CAMBIAR DE ${BLANCO}$usuario${RESET}"
        echo -e "${ROJO}────────────────────────────────────────────${RESET}"
        echo -e "${ROJO}[1]${RESET} ${CYAN}>${RESET} ${BLANCO}AÑADIR DÍAS A${RESET} ${CYAN}$usuario${RESET}"
        echo -e "${ROJO}[2]${RESET} ${CYAN}>${RESET} ${BLANCO}QUITAR DÍAS A${RESET} ${CYAN}$usuario${RESET}"
        echo -e "${ROJO}[3]${RESET} ${CYAN}>${RESET} ${BLANCO}REINICIAR DÍAS A${RESET} ${CYAN}$usuario${RESET}"
        echo -e "${ROJO}────────────────────────────────────────────${RESET}"
        echo ""
        echo -e "${ROJO}[0]${RESET} ${CYAN}>${RESET} ${ROJO}VOLVER${RESET}"

        leer_local op "OPCION: "

        case "$op" in
            1|01) anadir_dias_cliente_final ;;
            2|02) quitar_dias_cliente_final ;;
            3|03) reiniciar_dias_cliente_final ;;
            0|00) return ;;
            *) opcion_mala ;;
        esac
    done
}

cambiar_clave_cliente_final() {
    titulo_users "CLAVE DEL CLIENTE"

    linea=$(datos_usuario_final)
    IFS='|' read -r u pass tipo limite dias expira <<< "$linea"

    echo -e "${AMARILLO}Cliente:${RESET} $usuario"
    echo -e "${AMARILLO}Clave actual:${RESET} $pass"
    echo ""
    leer_local nueva_pass "NUEVA CLAVE: "

    if [[ -z "$nueva_pass" ]]; then
        echo -e "${ROJO}Clave vacía.${RESET}"
        pausa_local
        return
    fi

    actualizar_linux_clave_final "$usuario" "$nueva_pass"
    guardar_usuario_final "$u|$nueva_pass|$tipo|$limite|$dias|$expira"

    echo ""
    echo -e "${VERDE}✔ Clave actualizada correctamente.${RESET}"
    echo -e "${AMARILLO}Cliente:${RESET} $usuario"
    echo -e "${AMARILLO}Nueva clave:${RESET} $nueva_pass"
    pausa_local
}

renovar_usuario() {
    titulo_users "MODIFICAR DATOS DE USUARIOS"

    seleccionar_usuario_final || return

    while true; do
        titulo_users "MODIFICAR DATOS DE USUARIOS"

        linea=$(datos_usuario_final)
        IFS='|' read -r u pass tipo limite dias expira <<< "$linea"

        echo -e "${CYAN}- LISTA DE USUARIOS DISPONIBLES -${RESET}"
        echo -e "${AMARILLO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -e "${ROJO}[$usuario]${RESET} ${CYAN}➜${RESET} ${VERDE}$usuario${RESET}"
        echo -e "${AMARILLO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo ""
        echo -e "${VERDE}Seleccionaste el usuario:${RESET} ${CYAN}$usuario${RESET}"
        echo ""
        echo -e "${AMARILLO}$usuario - N° $dias${RESET}"
        echo -e "${AMARILLO}ESCOJE LA OPCIÓN A CAMBIAR DE ${BLANCO}$usuario${RESET}"
        echo -e "${AMARILLO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -e "${ROJO}[1]${RESET} ${CYAN}>${RESET} ${BLANCO}LIMITADOR DEL CLIENTE${RESET} ${CYAN}$usuario${RESET}"
        echo -e "${ROJO}[2]${RESET} ${CYAN}>${RESET} ${BLANCO}RENOVAR CLIENTE${RESET} ${CYAN}$usuario${RESET}"
        echo -e "${ROJO}[3]${RESET} ${CYAN}>${RESET} ${BLANCO}CLAVE DEL CLIENTE${RESET} ${CYAN}$usuario${RESET}"
        echo -e "${AMARILLO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo ""
        echo -e "${ROJO}[0]${RESET} ${CYAN}>${RESET} ${ROJO}VOLVER${RESET}"

        leer_local op "SELECCIONA UNA OPC : "

        case "$op" in
            1|01) editar_limite_cliente_final ;;
            2|02) menu_renovar_cliente_final ;;
            3|03) cambiar_clave_cliente_final ;;
            0|00) return ;;
            *) opcion_mala ;;
        esac
    done
}

# ==========================================================
# MOSTRAR USUARIOS CONECTADOS POR PUERTOS Y LÍMITES
# ==========================================================

limite_usuario_final() {
    local u="$1"
    awk -F'|' -v user="$u" '$1==user {print $4; exit}' "$USER_DB" 2>/dev/null
}

contar_conexiones_usuario_tcp() {
    local u="$1"
    pgrep -u "$u" 2>/dev/null | wc -l
}

mostrar_conexiones_puerto_final() {
    local puerto="$1"
    local nombre="$2"

    echo -e "${AMARILLO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${CYAN}$nombre / PUERTO $puerto${RESET}"
    echo -e "${AMARILLO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

    local hay=0

    ss -tnp 2>/dev/null | grep ":$puerto" | while read -r linea; do
        echo "$linea"
    done

    if ss -tnp 2>/dev/null | grep -q ":$puerto"; then
        hay=1
    fi

    if [[ "$hay" -eq 0 ]]; then
        echo "Sin conexiones visibles en este puerto."
    fi

    echo ""
}






# ==========================================================
# MOSTRAR USUARIOS CONECTADOS - ESTILO TABLA
# SSH / SSL / DROPBEAR / PUERTO 80 / 443
# ==========================================================

puerto_escuchando_tcp() {
    local puerto="$1"
    ss -ltnp 2>/dev/null | grep -qE "(:$puerto[[:space:]]|:$puerto$)"
}

puerto_escuchando_udp() {
    local puerto="$1"
    ss -ulnp 2>/dev/null | grep -qE "(:$puerto[[:space:]]|:$puerto$)"
}

formatear_tiempo_etime() {
    local et="$1"

    # Formatos posibles de ps etime:
    # 05
    # 01:22
    # 02:03:44
    # 1-02:03:44

    if [[ "$et" == *-* ]]; then
        dias="${et%%-*}"
        resto="${et#*-}"
        h="${resto%%:*}"
        resto2="${resto#*:}"
        m="${resto2%%:*}"
        s="${resto2##*:}"
        h=$((10#$h + dias * 24))
        printf "%02d:%02d:%02d" "$h" "$m" "$s"
    elif [[ "$et" =~ ^[0-9]+:[0-9]+:[0-9]+$ ]]; then
        echo "$et"
    elif [[ "$et" =~ ^[0-9]+:[0-9]+$ ]]; then
        m="${et%%:*}"
        s="${et##*:}"
        printf "00:%02d:%02d" "$m" "$s"
    else
        printf "00:00:%02d" "$et"
    fi
}

tiempo_usuario_conectado() {
    local user="$1"

    # Busca el proceso más viejo del usuario.
    local etime
    etime=$(ps -u "$user" -o etime= 2>/dev/null | awk 'NF {print $1; exit}')

    if [[ -z "$etime" ]]; then
        echo "00:00:00"
    else
        formatear_tiempo_etime "$etime"
    fi
}

contar_conexiones_usuario() {
    local user="$1"

    # Cuenta procesos reales del usuario.
    # En conexiones SSH/SSL/WS normalmente queda un proceso asociado al usuario.
    local total
    total=$(pgrep -u "$user" 2>/dev/null | wc -l)

    [[ -z "$total" ]] && total=0
    echo "$total"
}

limite_usuario_db() {
    local user="$1"
    local limite

    limite=$(awk -F'|' -v u="$user" '$1==u {print $4; exit}' "$USER_DB" 2>/dev/null)

    if [[ -z "$limite" ]]; then
        limite="1"
    fi

    echo "$limite"
}






# ==========================================================
# MOSTRAR USUARIOS CONECTADOS - ESTILO TABLA
# SSH / SSL / DROPBEAR / PUERTO 80 / 443
# ==========================================================

puerto_escuchando_tcp() {
    local puerto="$1"
    ss -ltnp 2>/dev/null | grep -qE "(:$puerto[[:space:]]|:$puerto$)"
}

puerto_escuchando_udp() {
    local puerto="$1"
    ss -ulnp 2>/dev/null | grep -qE "(:$puerto[[:space:]]|:$puerto$)"
}

formatear_tiempo_etime() {
    local et="$1"

    # Formatos posibles de ps etime:
    # 05
    # 01:22
    # 02:03:44
    # 1-02:03:44

    if [[ "$et" == *-* ]]; then
        dias="${et%%-*}"
        resto="${et#*-}"
        h="${resto%%:*}"
        resto2="${resto#*:}"
        m="${resto2%%:*}"
        s="${resto2##*:}"
        h=$((10#$h + dias * 24))
        printf "%02d:%02d:%02d" "$h" "$m" "$s"
    elif [[ "$et" =~ ^[0-9]+:[0-9]+:[0-9]+$ ]]; then
        echo "$et"
    elif [[ "$et" =~ ^[0-9]+:[0-9]+$ ]]; then
        m="${et%%:*}"
        s="${et##*:}"
        printf "00:%02d:%02d" "$m" "$s"
    else
        printf "00:00:%02d" "$et"
    fi
}

tiempo_usuario_conectado() {
    local user="$1"

    # Busca el proceso más viejo del usuario.
    local etime
    etime=$(ps -u "$user" -o etime= 2>/dev/null | awk 'NF {print $1; exit}')

    if [[ -z "$etime" ]]; then
        echo "00:00:00"
    else
        formatear_tiempo_etime "$etime"
    fi
}

contar_conexiones_usuario() {
    local user="$1"

    # Cuenta procesos reales del usuario.
    # En conexiones SSH/SSL/WS normalmente queda un proceso asociado al usuario.
    local total
    total=$(pgrep -u "$user" 2>/dev/null | wc -l)

    [[ -z "$total" ]] && total=0
    echo "$total"
}

limite_usuario_db() {
    local user="$1"
    local limite

    limite=$(awk -F'|' -v u="$user" '$1==u {print $4; exit}' "$USER_DB" 2>/dev/null)

    if [[ -z "$limite" ]]; then
        limite="1"
    fi

    echo "$limite"
}






# ==========================================================
# CLAVES DIRECTAS: PERMITE CONTRASEÑAS CORTAS SIN ERROR PAM
# ==========================================================

aplicar_clave_linux_directa() {
    local usuario="$1"
    local pass="$2"

    HASH=$(openssl passwd -6 "$pass")
    usermod -p "$HASH" "$usuario" >/dev/null 2>&1
    passwd -u "$usuario" >/dev/null 2>&1 || true
}

crear_usuario_linux() {
    local usuario="$1"
    local pass="$2"
    local expira="$3"

    if ! id "$usuario" >/dev/null 2>&1; then
        useradd -M -s /bin/bash "$usuario" >/dev/null 2>&1
    fi

    usermod -s /bin/bash "$usuario" >/dev/null 2>&1 || true
    mkdir -p "/home/$usuario" >/dev/null 2>&1 || true
    chown "$usuario:$usuario" "/home/$usuario" >/dev/null 2>&1 || true

    aplicar_clave_linux_directa "$usuario" "$pass"

    if [[ -n "$expira" ]]; then
        chage -E "$expira" "$usuario" >/dev/null 2>&1 || true
    bash /opt/darkzsaid/menus/sync_udpmod_users.sh 2>/dev/null || true
    fi

    return 0
}

actualizar_linux_clave_final() {
    local user="$1"
    local pass="$2"

    if id "$user" >/dev/null 2>&1; then
        aplicar_clave_linux_directa "$user" "$pass"
    fi
}

# ==========================================================
# USUARIOS CONECTADOS REAL: SSH / WS 80 / SSL 443
# ==========================================================

usuarios_conectados() {
    limpiar_pantalla

    echo -e "${CYAN}======>>> 🐲 DarkZsaid 💥 Plus 🐲 <<<======${RESET}"
    echo -e "${AMARILLO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "🔐 ${BLANCO}USUARIOS CONECTADOS SSH|SSL|WS${RESET} 🔐"
    echo -e "${AMARILLO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

    echo -ne "${CYAN}PROTOCOLOS ACTIVOS:${RESET} "

    ss -ltnp 2>/dev/null | grep -q ':22' && echo -ne "${VERDE}SSH:22 ${RESET}"
    ss -ltnp 2>/dev/null | grep -q ':80' && echo -ne "${VERDE}WS:80 ${RESET}"
    ss -ltnp 2>/dev/null | grep -q ':443' && echo -ne "${VERDE}SSL:443 ${RESET}"
    ss -ltnp 2>/dev/null | grep -q ':442' && echo -ne "${VERDE}DROPBEAR:442 ${RESET}"
    ss -ulnp 2>/dev/null | grep -q ':5667' && echo -ne "${VERDE}ZIVPN:5667 ${RESET}"

    echo ""
    echo -e "${AMARILLO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    printf "${ROJO}%-15s %-15s %-15s${RESET}\n" "USUARIO" "CONEXIONES" "TIEMPO"
    echo -e "${AMARILLO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

    python3 <<'PYCONN'
import os
import re
import subprocess
from pathlib import Path
from collections import defaultdict

DB = Path("/opt/darkzsaid/data/usuarios_ssh.db")

limites = {}
orden = []

if DB.exists():
    for line in DB.read_text(errors="ignore").splitlines():
        parts = line.split("|")
        if len(parts) >= 4 and parts[0].strip():
            user = parts[0].strip()
            limite = parts[3].strip() or "1"
            limites[user] = limite
            orden.append(user)

def fmt(seconds):
    try:
        seconds = int(seconds)
    except Exception:
        seconds = 0
    h = seconds // 3600
    m = (seconds % 3600) // 60
    s = seconds % 60
    return f"{h:02d}:{m:02d}:{s:02d}"

# Captura procesos sshd reales.
# Ejemplos:
# sshd: juan [priv]
# sshd: juan
# sshd: juan@pts/0
cmd = ["ps", "-eo", "pid=,etimes=,args="]
out = subprocess.check_output(cmd, text=True, errors="ignore")

conexiones = defaultdict(int)
tiempos = {}

for line in out.splitlines():
    if "sshd:" not in line:
        continue

    m = re.match(r"\s*(\d+)\s+(\d+)\s+(.*)$", line)
    if not m:
        continue

    pid, etimes, args = m.groups()

    muser = re.search(r"sshd:\s+([A-Za-z0-9._-]+)", args)
    if not muser:
        continue

    user = muser.group(1)

    # Ignorar root y listener
    if user in ("root", "/usr/sbin/sshd"):
        continue
    if "listener" in args:
        continue

    # Evitar contar doble la misma conexión SSH.
    # Linux crea un proceso interno tipo: sshd: usuario [priv]
    # Ese NO es otro dispositivo, solo es proceso de privilegios.
    if "[priv]" in args:
        continue

    # También ignoramos procesos previos a autenticación.
    if "[preauth]" in args:
        continue

    conexiones[user] += 1
    et = int(etimes)
    if user not in tiempos or et > tiempos[user]:
        tiempos[user] = et

total = 0
idx = 1

# Mostrar primero usuarios de la base
for user in orden:
    if user.lower() == "unknown":
        continue
    cant = conexiones.get(user, 0)
    if cant <= 0:
        continue
    limite = limites.get(user, "1")
    tiempo = fmt(tiempos.get(user, 0))
    print(f"\033[31m[{idx}]-{user:<11}\033[0m \033[36m[{cant}/{limite}]\033[0m          \033[32m{tiempo}\033[0m")
    total += 1
    idx += 1

# Mostrar conectados que no estén en la base
for user, cant in conexiones.items():
    if user.lower() == "unknown":
        continue
    if user in limites:
        continue
    if cant <= 0:
        continue
    tiempo = fmt(tiempos.get(user, 0))
    print(f"\033[31m[{idx}]-{user:<11}\033[0m \033[36m[{cant}/?]\033[0m          \033[32m{tiempo}\033[0m")
    total += 1
    idx += 1

print("\033[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m")
if total == 0:
    print("🛡️ # TIENES  [ \033[31m0\033[0m ] USUARIOS CONECTADOS 🛡️ #")
else:
    print(f"🛡️ # TIENES  [ \033[32m{total}\033[0m ] USUARIOS CONECTADOS 🛡️ #")
PYCONN

    echo -e "${AMARILLO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    pausa_local
}


menu_users() {
    while true; do
        titulo_users "CONTROL USUARIOS (SSH/SSL/UDP)"

        echo -e "${ROJO}[01]${RESET} ${CYAN}➜${RESET} ${BLANCO}AGREGAR USUARIO"
        echo -e "${ROJO}[02]${RESET} ${CYAN}➜${RESET} ${BLANCO}BORRAR 1/TODOS LOS USUARIO/S${RESET}"
        echo -e "${ROJO}[03]${RESET} ${CYAN}➜${RESET} ${BLANCO}EDITAR/RENOVAR USUARIOS${RESET}"
        echo -e "${ROJO}[04]${RESET} ${CYAN}➜${RESET} ${BLANCO}MOSTRAR USUARIOS REGISTRADOS${RESET}"
        echo -e "${ROJO}[05]${RESET} ${CYAN}➜${RESET} ${BLANCO}MOSTRAR USUARIOS CONECTADOS${RESET}"
        echo -e "${ROJO}[06]${RESET} ${CYAN}➜${RESET} ${BLANCO}BACKUP USUARIOS${RESET}"
        echo -e "${ROJO}[07]${RESET} ${CYAN}➜${RESET} ${BLANCO}RESTAURAR BACKUP USUARIOS${RESET}"
        echo -e "${ROJO}[08]${RESET} ${CYAN}➜${RESET} ${BLANCO}CHECK USER API${RESET}"
        echo ""
        echo -e "${ROJO}[00]${RESET} ${CYAN}➜${RESET} ${ROJO}[ VOLVER ]${RESET}"

        leer_local op "⚡ Opción: "

        case "$op" in
            1|01) menu_agregar_usuario ;;
            2|02) menu_eliminar_usuarios ;;
            3|03) renovar_usuario ;;
            4|04) bash /opt/darkzsaid/menus/mostrar_usuarios_full.sh ;;
            5|05) usuarios_conectados ;;
            6|06) backup_usuarios ;;
            7|07) restaurar_backup_usuarios ;;
                    8|08) checkuser_protocolo_menu ;;
0|00) return ;;
            *) opcion_mala ;;
        esac
    done
}

menu_users

