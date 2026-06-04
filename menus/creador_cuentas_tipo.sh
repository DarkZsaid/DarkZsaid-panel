#!/bin/bash

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
DATA_DIR="/opt/darkzsaid/data"
TOKEN_PASS_FILE="/bin/ejecutar/token"

mkdir -p "$USERDIR" "$DATA_DIR" /bin/ejecutar /opt/darkzsaid/users

pausa() {
    echo ""
    read -p "¡Enter, para volver! "
}

titulo() {
    limpiar_pantalla
    echo -e "${AZUL}=====>>> 🐉 DarkZsaid 💥 Plus 🐉 <<<=====${RESET}"
    echo -e "${AMARILLO}────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "${AMARILLO}        ⚜  CREADOR DE CUENTAS TIPO  ⚜${RESET}"
    echo -e "${AMARILLO}────────────────────────────────────────────${RESET}"
    echo ""
}

ip_vps() {
    curl -s --max-time 3 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}'
}

fecha_iso() {
    local dias="$1"
    date -d "+$dias days" +%Y-%m-%d 2>/dev/null
}

dias_restantes() {
    local fecha="$1"
    local hoy_sec
    local fecha_sec
    local diff

    hoy_sec=$(date +%s)
    fecha_sec=$(date -d "$fecha" +%s 2>/dev/null || echo 0)

    if [ "$fecha_sec" -eq 0 ]; then
        echo "-"
        return
    fi

    diff=$(( (fecha_sec - hoy_sec) / 86400 ))

    if [ "$diff" -lt 0 ]; then
        echo "EXP"
    else
        echo "$diff"
    fi
}

leer_token_global() {
    if [ -f "$TOKEN_PASS_FILE" ]; then
        cat "$TOKEN_PASS_FILE" | tr -d '\r\n'
    else
        echo "No configurada"
    fi
}

guardar_token_global() {
    local clave="$1"

    echo "$clave" > /bin/ejecutar/token
    echo "$clave" > /opt/darkzsaid/users/token_password.conf
    echo "TOKEN_PASSWORD=\"$clave\"" > /opt/darkzsaid/data/token_password.conf

    chmod 600 /bin/ejecutar/token
    chmod 600 /opt/darkzsaid/users/token_password.conf
    chmod 600 /opt/darkzsaid/data/token_password.conf
}

crear_linux_user() {
    local usuario="$1"
    local clave="$2"
    local fecha="$3"

    if id "$usuario" >/dev/null 2>&1; then
        HASH=$(openssl passwd -6 "$clave")
    usermod -p "$HASH" "$usuario"
        usermod -e "$fecha" "$usuario"
    else
        useradd -M "$usuario" -s /bin/bash -e "$fecha"
        mkdir -p "/home/$usuario"
        chown "$usuario:$usuario" "/home/$usuario"
        usermod -d "/home/$usuario" -s /bin/bash "$usuario"
        HASH=$(openssl passwd -6 "$clave")
    usermod -p "$HASH" "$usuario"
    fi
}

crear_demo() {
    titulo

    usuario="demo$(tr -dc 'a-z0-9' </dev/urandom | head -c 4)"
    clave="$(tr -dc 'a-z0-9' </dev/urandom | head -c 6)"

    echo -e "${AMARILLO}TIEMPO DE DURACION DEMO${RESET}"
    echo ""
    echo -e "${ROJO}[1]${RESET} 4 HORAS"
    echo -e "${ROJO}[2]${RESET} 8 HORAS"
    echo -e "${ROJO}[3]${RESET} 1 DIA"
    echo ""
    read -p "OPCION: " op

    case "$op" in
        1) horas=4 ;;
        2) horas=8 ;;
        3) horas=24 ;;
        *) horas=4 ;;
    esac

    fecha="$(fecha_iso 1)"
    crear_linux_user "$usuario" "$clave" "$fecha"

    cat > "$USERDIR/$usuario" <<EOF2
tipo: SSH
usuario: $usuario
senha: $clave
limite: 1
data: $fecha
EOF2

    chmod 644 "$USERDIR/$usuario"

    echo "userdel -r '$usuario' 2>/dev/null; rm -f '$USERDIR/$usuario'" | at now + "$horas" hours 2>/dev/null || true

    echo ""
    echo -e "${VERDE}CUENTA DEMO CREADA${RESET}"
    echo ""
    echo "USUARIO  : $usuario"
    echo "CLAVE    : $clave"
    echo "LIMITE   : 1"
    echo "DURACION : $horas horas"
    pausa
}

crear_ssh() {
    titulo

    read -p "USUARIO: " usuario
    read -p "CONTRASEÑA: " clave
    read -p "VALIDEZ EN DIAS: " dias
    read -p "LIMITE DE CONEXIONES: " limite

    if [ -z "$usuario" ] || [ -z "$clave" ] || ! [[ "$dias" =~ ^[0-9]+$ ]] || ! [[ "$limite" =~ ^[0-9]+$ ]]; then
        echo -e "${ROJO}Datos inválidos.${RESET}"
        pausa
        return
    fi

    fecha="$(fecha_iso "$dias")"

    crear_linux_user "$usuario" "$clave" "$fecha"

    cat > "$USERDIR/$usuario" <<EOF2
tipo: SSH
usuario: $usuario
senha: $clave
limite: $limite
data: $fecha
EOF2

    chmod 644 "$USERDIR/$usuario"

    echo ""
    echo -e "${VERDE}CUENTA SSH/DROPBEAR CREADA${RESET}"
    echo ""
    echo "USUARIO     : $usuario"
    echo "CONTRASEÑA  : $clave"
    echo "LIMITE      : $limite"
    echo "CADUCA      : $(dias_restantes "$fecha")"
    pausa
}

crear_hwid() {
    titulo

    read -p "USUARIO/HWID: " usuario
    read -p "CLAVE/HWID: " clave
    read -p "VALIDEZ EN DIAS: " dias

    if [ -z "$usuario" ] || [ -z "$clave" ] || ! [[ "$dias" =~ ^[0-9]+$ ]]; then
        echo -e "${ROJO}Datos inválidos.${RESET}"
        pausa
        return
    fi

    fecha="$(fecha_iso "$dias")"

    cat > "$USERDIR/$usuario" <<EOF2
tipo: HWID
usuario: $usuario
senha: $clave
limite: HWID
data: $fecha
EOF2

    chmod 644 "$USERDIR/$usuario"

    echo ""
    echo -e "${VERDE}CUENTA HWID CREADA${RESET}"
    echo ""
    echo "USUARIO/HWID : $usuario"
    echo "CLAVE        : $clave"
    echo "CADUCA       : $(dias_restantes "$fecha")"
    pausa
}

crear_token() {
    titulo

    TOKEN_PASS="$(leer_token_global)"

    if [ "$TOKEN_PASS" = "No configurada" ]; then
        echo -e "${ROJO}Primero configura la contraseña token en la opción [05].${RESET}"
        pausa
        return
    fi

    read -p "USUARIO: " usuario
    echo ""
    echo -e "${AMARILLO}INGRESA TOKEN PARA $usuario${RESET}"
    read -p "TOKEN/HWID: " token
    echo ""
    echo -e "${AMARILLO}TIEMPO DE DURACION EN DIAS PARA $usuario${RESET}"
    read -p "VALIDEZ: " dias

    if [ -z "$usuario" ] || [ -z "$token" ] || ! [[ "$dias" =~ ^[0-9]+$ ]]; then
        echo -e "${ROJO}Datos inválidos.${RESET}"
        pausa
        return
    fi

    fecha="$(fecha_iso "$dias")"

    # El archivo debe llamarse igual que el token/HWID porque la app autentica HWID:clave
    cat > "$USERDIR/$token" <<EOF2
tipo: TOKEN
usuario: $TOKEN: $token
senha: $TOKEN_PASS
limite: TOKEN
data: $fecha
EOF2

    chmod 644 "$USERDIR/$token"

    echo ""
    echo -e "${AMARILLO}* Puertas Activas en su Servidor *${RESET}"
    echo -e "${AMARILLO}────────────────────────────────────────────${RESET}"
    echo "° SSH: 22              ° System-DNS: 53"
    echo "° SOCKS/PYTHON: 80     ° WEB-Nginx: 81"
    echo "° SSL: 443             ° BadVPN: 7200"
    echo "° BadVPN: 7300"
    echo "° UDP-Custom: 36712"
    echo -e "${AMARILLO}────────────────────────────────────────────${RESET}"
    echo ""
    echo "Host/IP-Address : $(ip_vps)"
    echo "USUARIO         : $usuario"
    echo "TOKEN/HWID      : $token"
    echo "CONTRASEÑA      : $TOKEN_PASS"
    echo "CADUCA          : $(dias_restantes "$fecha")"
    echo ""
    echo "La app manda:"
    echo "$token:$TOKEN_PASS"
    echo ""
    echo -e "${ROJO} En APPS como HTTP Injector, CUSTOM, etc${RESET}"
    echo -e "${ROJO} No existe Dropbear${RESET}"
    echo ""
    echo "👨‍💻 SSL/TLS(SNI) : $(ip_vps):443"
    echo "👨‍💻 Proxy(WS)    : 80"
    echo "👨‍💻 SSH UDP      : $(ip_vps):1-65535"
    echo -e "${AMARILLO}────────────────────────────────────────────${RESET}"
    pausa
}

modificar_token_pass() {
    titulo

    actual="$(leer_token_global)"

    echo -e "${AMARILLO}CLAVE ACTUAL : $actual${RESET}"
    echo ""
    echo -e "${AMARILLO}ATENCION ANTES DE CONTINUAR${RESET}"
    echo ""
    echo "SE DEFINIRA SU CONTRASEÑA TOKEN UNICA"
    echo "UNA VEZ COLOCADA SE RECOMIENDA NO CAMBIARLA"
    echo ""
    read -p "CONTRASEÑA TOKEN: " nueva

    if [ -z "$nueva" ]; then
        echo -e "${ROJO}Contraseña vacía.${RESET}"
        pausa
        return
    fi

    guardar_token_global "$nueva"

    echo ""
    echo -e "${VERDE}CONTRASEÑA TOKEN ACTUALIZADA${RESET}"
    echo "Nueva contraseña token: $nueva"
    pausa
}

listar_usuarios() {
    limpiar_pantalla

    HOY_SEC=$(date +%s)

    echo -e "${CYAN}   ____"
    echo -e "  / __/ /___ ___  ___ ___"
    echo -e " _\\ \\  / -_) _ \\/ -_) _ \\"
    echo -e "/___/_/\\__/_//_/\\__/_//_/${RESET}"
    echo ""
    echo -e "${AMARILLO}────────────────────────────────────────────${RESET}"
    echo -e "${AMARILLO}🔐 ADMINISTRADOR DE USUARIOS SSH|SSL|DROPBEAR 🔐${RESET}"
    echo -e "   ${AZUL}▸ M LIBRE:${RESET} ${VERDE}$(free -h | awk '/Mem:/ {print $7}')${RESET}   ${AZUL}▸ USO DE CPU:${RESET} ${VERDE}$(top -bn1 | awk -F',' '/Cpu/ {print 100-$4 "%"}' | awk '{print $1}')${RESET}"
    echo -e "${AMARILLO}────────────────────────────────────────────${RESET}"
    echo ""

    echo -e "${AMARILLO}────────────────────────────────────────────${RESET}"
    printf "${AZUL}%-5s %-13s %-14s %-10s %-8s${RESET}\n" ">" "USUARIO" "CONTRASEÑA" "LIMITE" "CADUCA"
    echo -e "${AMARILLO}────────────────────────────────────────────${RESET}"

    total=0
    tk_contador=0

    for archivo in $(ls -1tr "$USERDIR" 2>/dev/null); do
        f="$USERDIR/$archivo"
        [ -f "$f" ] || continue

        tipo="$(grep -m1 '^tipo:' "$f" 2>/dev/null | cut -d':' -f2- | xargs)"
        usuario="$(grep -m1 '^usuario:' "$f" 2>/dev/null | cut -d':' -f2- | xargs)"
        senha="$(grep -m1 '^senha:' "$f" 2>/dev/null | cut -d':' -f2- | xargs)"
        token="$(grep -m1 '^token:' "$f" 2>/dev/null | cut -d':' -f2- | xargs)"
        limite="$(grep -m1 '^limite:' "$f" 2>/dev/null | cut -d':' -f2- | xargs)"
        data="$(grep -m1 '^data:' "$f" 2>/dev/null | cut -d':' -f2- | xargs)"

        [ -z "$usuario" ] && usuario="$archivo"
        [ -z "$senha" ] && senha="-"
        [ -z "$limite" ] && limite="-"
        [ -z "$data" ] && data="-"

        data_sec=$(date -d "$data" +%s 2>/dev/null || echo 0)

        if [ "$data_sec" -gt 0 ]; then
            diff=$(( (data_sec - HOY_SEC) / 86400 ))
            if [ "$diff" -lt 0 ]; then
                caduca="EXP"
            else
                caduca="$diff"
            fi
        else
            caduca="-"
        fi

        total=$((total+1))

        if [ "$limite" = "TOKEN" ] || [ "$tipo" = "TOKEN" ]; then
            tk_contador=$((tk_contador+1))
            tk="TK$tk_contador"

            [ -z "$token" ] && token="$archivo"

            printf "${ROJO}[%s]>${RESET} %-13s %-14s ${ROJO}%-10s${RESET} ${VERDE}%-8s${RESET}\n" "$total" "$usuario" "" "$tk" "$caduca"
            echo -e "     ${CYAN}↪ TOKEN -${RESET} ${ROJO}$token${RESET}"

        elif [ "$limite" = "HWID" ] || [ "$tipo" = "HWID" ]; then
            printf "${ROJO}[%s]>${RESET} %-13s %-14s ${ROJO}%-10s${RESET} ${VERDE}%-8s${RESET}\n" "$total" "$usuario" "" "HWID" "$caduca"
            echo -e "     ${CYAN}↪ HWID -${RESET} ${ROJO}$senha${RESET}"

        else
            printf "${ROJO}[%s]>${RESET} %-13s ${ROJO}%-14s${RESET} ${VERDE}%-10s${RESET} ${VERDE}%-8s${RESET}\n" "$total" "$usuario" "$senha" "$limite" "$caduca"
        fi
    done

    echo -e "${AMARILLO}────────────────────────────────────────────${RESET}"
    echo -e "${VERDE}🛡 # TIENES [ $total ] CLIENTES EN TU SERVIDOR 🛡 #${RESET}"
    echo -e "${AMARILLO}────────────────────────────────────────────${RESET}"
    pausa
}

eliminar_usuario() {
    titulo

    read -p "USUARIO o TOKEN/HWID a eliminar: " user

    if [ -z "$user" ]; then
        echo "Vacío."
        pausa
        return
    fi

    if id "$user" >/dev/null 2>&1; then
        userdel -r "$user" 2>/dev/null || true
    fi

    rm -f "$USERDIR/$user"

    # Si buscaron por nombre visible, intenta eliminar por usuario interno
    for f in "$USERDIR"/*; do
        [ -f "$f" ] || continue
        u="$(grep -m1 '^usuario:' "$f" 2>/dev/null | cut -d':' -f2- | xargs)"
        if [ "$u" = "$user" ]; then
            rm -f "$f"
        fi
    done

    echo ""
    echo -e "${VERDE}Usuario eliminado si existía:${RESET} $user"
    pausa
}

menu() {
    while true; do
        titulo

        echo -e "${ROJO}[01]${RESET}  > SSH DROPBEAR (DEMO)"
        echo -e "${ROJO}[02]${RESET}  > SSH DROPBEAR"
        echo -e "${ROJO}[03]${RESET}  > HWID"
        echo -e "${ROJO}[04]${RESET}  > TOKEN"
        echo ""
        echo -e "${ROJO}[05]${RESET}  > MODIFICAR CONTRASEÑA TOKEN"
        echo ""
        echo -e "${ROJO}[00]${RESET}  ⇦ [ VOLVER ]"
        echo ""
        read -p "► Opcion : " op

        case "$op" in
            1|01) crear_demo ;;
            2|02) crear_ssh ;;
            3|03) crear_hwid ;;
            4|04) crear_token ;;
            5|05) modificar_token_pass ;;
            0|00) exit ;;
            *) echo "Opción inválida"; sleep 1 ;;
        esac
    done
}

menu
