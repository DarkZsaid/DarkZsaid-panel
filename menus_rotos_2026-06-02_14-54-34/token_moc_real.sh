pantalla_limpia() {
    printf '\033c'
}


limpiar_pantalla() {
    printf '\033[H\033[2J\033[3J'
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


#!/bin/bash

ROJO="\e[31m"
VERDE="\e[32m"
AMARILLO="\e[33m"
CYAN="\e[36m"
BLANCO="\e[97m"
RESET="\e[0m"
BOLD="\e[1m"

TOKEN_FILE="/bin/ejecutar/token"
USERDIR="/etc/adm-lite/userDIR"

mkdir -p /bin/ejecutar
mkdir -p "$USERDIR"

pausa() {
    echo ""
    read -p "Presiona ENTER para continuar..."
}

titulo() {
    limpiar_pantalla
    echo -e "${CYAN}═════>>> 🐉 DarkZsaid ✸ Plus 🐉 <<<═════${RESET}"
    echo -e "${AMARILLO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BLANCO}${BOLD}          $1${RESET}"
    echo -e "${AMARILLO}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
}

modificar_token_moc() {
    titulo "MODIFICAR CONTRASEÑA TOKEN MOC"

    if [[ -f "$TOKEN_FILE" ]]; then
        echo -e "${AMARILLO}CLAVE ACTUAL:${RESET} $(cat "$TOKEN_FILE")"
    else
        echo -e "${AMARILLO}CLAVE ACTUAL:${RESET} No configurada"
    fi

    echo ""
    echo "Esta clave es la contraseña TOKEN MOC real."
    echo "Debe ser la misma que usa tu app privada/eClick."
    echo ""
    read -p "Nueva contraseña TOKEN MOC: " clave

    if [[ -z "$clave" ]]; then
        echo "Clave vacía. Cancelado."
        pausa
        return
    fi

    echo "$clave" > "$TOKEN_FILE"
    chmod 600 "$TOKEN_FILE"

    mkdir -p /opt/darkzsaid/users /opt/darkzsaid/data
    echo "$clave" > /opt/darkzsaid/users/token_password.conf
    echo "$clave" > /opt/darkzsaid/data/token.key
    cat > /opt/darkzsaid/data/token_password.conf <<EOF2
TOKEN_PASSWORD="$clave"
EOF2

    chmod 600 /opt/darkzsaid/users/token_password.conf
    chmod 600 /opt/darkzsaid/data/token.key
    chmod 600 /opt/darkzsaid/data/token_password.conf

    echo ""
    echo -e "${VERDE}Contraseña TOKEN MOC actualizada correctamente.${RESET}"
    echo ""
    echo "Archivo principal:"
    echo "$TOKEN_FILE"
    echo ""
    echo "Clave:"
    echo "$clave"
    pausa
}

crear_usuario_token() {
    titulo "CREAR TOKEN"

    read -p "Nombre TOKEN / usuario: " user
    read -p "Contraseña o identificador TOKEN: " pass

    if [[ -z "$user" || -z "$pass" ]]; then
        echo "Usuario o contraseña vacíos."
        pausa
        return
    fi

    if [[ "$user" =~ [[:space:]/] ]]; then
        echo "El usuario no debe llevar espacios ni /"
        pausa
        return
    fi

    cat > "$USERDIR/$user" <<EOF2
senha: $pass
limite: TOKEN
EOF2

    chmod 644 "$USERDIR/$user"

    echo ""
    echo -e "${VERDE}TOKEN creado correctamente.${RESET}"
    echo ""
    echo "Archivo:"
    echo "$USERDIR/$user"
    echo ""
    cat "$USERDIR/$user"
    echo ""
    echo "Clave TOKEN MOC global actual:"
    [[ -f "$TOKEN_FILE" ]] && cat "$TOKEN_FILE" || echo "No configurada"
    pausa
}

listar_tokens() {
    titulo "TOKENS / USUARIOS ADM-LITE"

    for f in "$USERDIR"/*; do
        [ -f "$f" ] || continue
        user=$(basename "$f")
        senha=$(grep '^senha:' "$f" | cut -d':' -f2- | xargs)
        limite=$(grep '^limite:' "$f" | cut -d':' -f2- | xargs)

        echo "Usuario: $user | Senha: $senha | Limite: $limite"
    done

    pausa
}

eliminar_token() {
    titulo "ELIMINAR TOKEN"

    mapfile -t files < <(ls "$USERDIR" 2>/dev/null)

    if [[ ${#files[@]} -eq 0 ]]; then
        echo "No hay usuarios en userDIR."
        pausa
        return
    fi

    for i in "${!files[@]}"; do
        echo "[$((i+1))] ${files[$i]}"
    done

    echo ""
    read -p "Número a eliminar: " num

    if ! [[ "$num" =~ ^[0-9]+$ ]]; then
        echo "Número inválido."
        pausa
        return
    fi

    idx=$((num-1))

    if [[ -z "${files[$idx]}" ]]; then
        echo "No existe ese número."
        pausa
        return
    fi

    rm -f "$USERDIR/${files[$idx]}"
    echo "Eliminado: ${files[$idx]}"
    pausa
}

ver_estado_token() {
    titulo "ESTADO TOKEN MOC"

    echo "Archivo clave TOKEN MOC:"
    echo "$TOKEN_FILE"
    echo ""

    if [[ -f "$TOKEN_FILE" ]]; then
        echo "Clave actual:"
        cat "$TOKEN_FILE"
    else
        echo "No configurada."
    fi

    echo ""
    echo "UserDIR:"
    echo "$USERDIR"
    echo ""
    ls -lah "$USERDIR"

    echo ""
    echo "Contenido:"
    for f in "$USERDIR"/*; do
        [ -f "$f" ] || continue
        echo ""
        echo "━━━━ $f ━━━━"
        cat "$f"
    done

    pausa
}

while true; do
    titulo "TOKEN MOC / ADM-LITE"

    echo -e "${ROJO}[1]${RESET} Modificar contraseña TOKEN MOC"
    echo -e "${ROJO}[2]${RESET} Crear TOKEN"
    echo -e "${ROJO}[3]${RESET} Ver tokens / usuarios"
    echo -e "${ROJO}[4]${RESET} Eliminar TOKEN"
    echo -e "${ROJO}[5]${RESET} Ver estado completo"
    echo -e "${ROJO}[0]${RESET} Volver"
    echo ""
    read -p "Opción: " op; printf '\033c'

    case "$op" in
        1) modificar_token_moc ;;
        2) crear_usuario_token ;;
        3) listar_tokens ;;
        4) eliminar_token ;;
        5) ver_estado_token ;;
        0) exit 0 ;;
        *) echo "Opción inválida"; sleep 1 ;;
    esac
done
