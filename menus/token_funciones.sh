#!/bin/bash

limpiar_pantalla() {
    printf '\033[H\033[2J\033[3J'
}


ROJO="\e[31m"
VERDE="\e[32m"
AMARILLO="\e[33m"
CYAN="\e[36m"
BLANCO="\e[97m"
RESET="\e[0m"
BOLD="\e[1m"

TOKEN_FILE="/bin/ejecutar/token"
TOKEN_FILE2="/opt/darkzsaid/users/token_password.conf"
TOKEN_FILE3="/opt/darkzsaid/data/token_password.conf"
USERDIR="/etc/adm-lite/userDIR"

pausa() {
    echo ""
    read -p "Presiona ENTER para continuar..."
}

titulo() {
    limpiar_pantalla
    echo -e "${CYAN}════════════════════════════════════════════${RESET}"
    echo -e "${BLANCO}${BOLD}        $1${RESET}"
    echo -e "${CYAN}════════════════════════════════════════════${RESET}"
    echo ""
}

leer_token_actual() {
    if [ -f "$TOKEN_FILE" ]; then
        cat "$TOKEN_FILE" | tr -d '\r\n'
    elif [ -f "$TOKEN_FILE2" ]; then
        cat "$TOKEN_FILE2" | tr -d '\r\n'
    else
        echo "No configurada"
    fi
}

guardar_token_global() {
    local pass="$1"

    mkdir -p /bin/ejecutar /opt/darkzsaid/users /opt/darkzsaid/data

    echo "$pass" > "$TOKEN_FILE"
    echo "$pass" > "$TOKEN_FILE2"
    echo "TOKEN_PASSWORD=\"$pass\"" > "$TOKEN_FILE3"

    chmod 600 "$TOKEN_FILE" "$TOKEN_FILE2" "$TOKEN_FILE3"
}

modificar_contrasena_token() {
    titulo "MODIFICAR CONTRASEÑA TOKEN"

    ACTUAL="$(leer_token_actual)"

    echo -e "${AMARILLO}CLAVE TOKEN ACTUAL:${RESET} $ACTUAL"
    echo ""
    echo -e "${AMARILLO}Esta clave es la que la app usa después de los dos puntos.${RESET}"
    echo "Ejemplo:"
    echo "HWID:$ACTUAL"
    echo ""
    read -p "Nueva contraseña token: " nueva

    if [ -z "$nueva" ]; then
        echo "Contraseña vacía. Cancelado."
        pausa
        return
    fi

    guardar_token_global "$nueva"

    echo ""
    echo -e "${VERDE}Contraseña token actualizada correctamente.${RESET}"
    echo "Nueva contraseña token: $nueva"
    pausa
}

crear_usuario_token() {
    titulo "CREAR TOKEN"

    TOKEN_PASS="$(leer_token_actual)"

    if [ "$TOKEN_PASS" = "No configurada" ]; then
        echo -e "${ROJO}Primero configura la contraseña token.${RESET}"
        echo "Usa la opción: MODIFICAR CONTRASEÑA TOKEN"
        pausa
        return
    fi

    echo -e "${AMARILLO}Contraseña token actual:${RESET} $TOKEN_PASS"
    echo ""
    echo "Pega aquí el HWID que manda la aplicación."
    echo "Ejemplo: 7862b1a3d31422c9"
    echo ""
    read -p "HWID / TOKEN: " hwid

    if [ -z "$hwid" ]; then
        echo "HWID vacío. Cancelado."
        pausa
        return
    fi

    mkdir -p "$USERDIR"

    cat > "$USERDIR/$hwid" <<EOF2
senha: $TOKEN_PASS
limite: TOKEN
EOF2

    chmod 644 "$USERDIR/$hwid"

    echo ""
    echo -e "${VERDE}TOKEN creado correctamente.${RESET}"
    echo ""
    echo "HWID: $hwid"
    echo "Contraseña TOKEN: $TOKEN_PASS"
    echo ""
    echo "La app debe mandar:"
    echo "$hwid:$TOKEN_PASS"
    echo ""
    cat "$USERDIR/$hwid"
    pausa
}

listar_usuarios_token() {
    titulo "USUARIOS TOKEN"

    if [ ! -d "$USERDIR" ]; then
        echo "No existe $USERDIR"
        pausa
        return
    fi

    for f in "$USERDIR"/*; do
        [ -f "$f" ] || continue

        LIMITE="$(grep -i '^limite:' "$f" | awk '{print $2}')"

        if [ "$LIMITE" = "TOKEN" ]; then
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
            echo "HWID: $(basename "$f")"
            cat "$f"
        fi
    done

    pausa
}

eliminar_usuario_token() {
    titulo "ELIMINAR TOKEN"

    read -p "HWID a eliminar: " hwid

    if [ -z "$hwid" ]; then
        echo "HWID vacío."
        pausa
        return
    fi

    rm -f "$USERDIR/$hwid"

    echo "TOKEN eliminado si existía: $hwid"
    pausa
}

menu_token() {
    while true; do
        titulo "CREADOR DE CUENTAS TOKEN"

        echo -e "${ROJO}[01]${RESET} > CREAR TOKEN"
        echo -e "${ROJO}[02]${RESET} > LISTAR USUARIOS TOKEN"
        echo -e "${ROJO}[03]${RESET} > ELIMINAR TOKEN"
        echo -e "${ROJO}[05]${RESET} > MODIFICAR CONTRASEÑA TOKEN"
        echo ""
        echo -e "${ROJO}[00]${RESET} > VOLVER"
        echo ""
        echo -e "${AMARILLO}CLAVE ACTUAL:${RESET} $(leer_token_actual)"
        echo ""
        read -p "Opción: " op

        case "$op" in
            1|01) crear_usuario_token ;;
            2|02) listar_usuarios_token ;;
            3|03) eliminar_usuario_token ;;
            5|05) modificar_contrasena_token ;;
            0|00) return ;;
            *) echo "Opción inválida"; sleep 1 ;;
        esac
    done
}
