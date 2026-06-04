#!/bin/bash

limpiar_pantalla() {
    printf '\033[H\033[2J\033[3J'
}


source /opt/darkzsaid/lib/estilo_original.sh

USERDIR="/etc/adm-lite/userDIR"
DZ_USERDIR="/etc/darkzsaid/usuarios"

mkdir -p "$USERDIR" "$DZ_USERDIR"

listar_usuarios_panel() {
    find "$USERDIR" -maxdepth 1 -type f -printf "%f\n" 2>/dev/null | sort
}

fecha_linux() {
    local dias="$1"
    date '+%Y-%m-%d' -d " +$dias days"
}

fecha_mostrar() {
    local fecha="$1"
    date -d "$fecha" '+%d/%m/%Y' 2>/dev/null || echo "$fecha"
}

seleccionar_usuario() {
    usuarios=()
    while IFS= read -r u; do
        [[ -z "$u" ]] && continue
        usuarios+=("$u")
    done < <(listar_usuarios_panel)

    if [[ "${#usuarios[@]}" -eq 0 ]]; then
        msg -verm "No hay usuarios registrados."
        read -rp "Presiona ENTER para volver..."
        return 1
    fi

    local i=1
    for u in "${usuarios[@]}"; do
        local nombre limite data
        nombre=$(grep -i "^senha:" "$USERDIR/$u" 2>/dev/null | cut -d: -f2- | xargs)
        limite=$(grep -i "^limite:" "$USERDIR/$u" 2>/dev/null | cut -d: -f2- | xargs)
        data=$(grep -i "^data:" "$USERDIR/$u" 2>/dev/null | cut -d: -f2- | xargs)
        [[ -z "$nombre" ]] && nombre="$u"
        [[ -z "$limite" ]] && limite="?"
        [[ -z "$data" ]] && data="?"

        num=$(printf "%02d" "$i")
        echo -e "\033[0;35m [${cor[2]}${num}\033[0;35m]\033[0;33m ${flech}\033[1;37m ${u}  \033[1;33mNombre:\033[1;32m ${nombre}  \033[1;33mLim:\033[1;32m ${limite}  \033[1;33mExp:\033[1;32m ${data}\033[0m"
        ((i++))
    done

    msg -bar3
    echo -e "\033[0;35m [${cor[2]}0\033[0;35m]\033[0;33m ⇦ \033[1;37m\e[3;33m[ VOLVER ]\e[0m"
    msg -bar3
    read -rp "Seleccione usuario: " op

    [[ "$op" = "0" ]] && return 1

    if ! [[ "$op" =~ ^[0-9]+$ ]] || [[ "$op" -lt 1 ]] || [[ "$op" -gt "${#usuarios[@]}" ]]; then
        msg -verm "Opción inválida."
        sleep 2
        return 1
    fi

    USUARIO_SEL="${usuarios[$((op-1))]}"
    return 0
}

actualizar_archivo_campo() {
    local archivo="$1"
    local campo="$2"
    local valor="$3"

    [[ ! -f "$archivo" ]] && return

    if grep -qi "^$campo:" "$archivo"; then
        sed -i "s|^$campo:.*|$campo: $valor|I" "$archivo"
    else
        echo "$campo: $valor" >> "$archivo"
    fi
}

renovar_usuario() {
    header
    msg -bar3
    print_center -azu "RENOVAR USUARIO"
    msg -bar3

    seleccionar_usuario || return

    msg -bar3
    echo -e "${cor[5]}Usuario seleccionado:${cor[3]} $USUARIO_SEL"
    read -rp "Nuevos días de validez: " dias

    if ! [[ "$dias" =~ ^[0-9]+$ ]]; then
        msg -verm "Los días deben ser numéricos."
        sleep 2
        return
    fi

    nueva_fecha="$(fecha_linux "$dias")"

    chage -E "$nueva_fecha" "$USUARIO_SEL" 2>/dev/null
    usermod -e "$nueva_fecha" "$USUARIO_SEL" 2>/dev/null

    actualizar_archivo_campo "$USERDIR/$USUARIO_SEL" "data" "$nueva_fecha"
    actualizar_archivo_campo "$DZ_USERDIR/$USUARIO_SEL" "data" "$nueva_fecha"

    msg -verd "Usuario renovado correctamente."
    echo -e "${cor[5]}Nueva expiración:${cor[2]} $(fecha_mostrar "$nueva_fecha")"
    msg -bar3
    read -rp "Presiona ENTER para volver..."
}

cambiar_password() {
    header
    msg -bar3
    print_center -azu "CAMBIAR CONTRASEÑA"
    msg -bar3

    seleccionar_usuario || return

    msg -bar3
    echo -e "${cor[5]}Usuario seleccionado:${cor[3]} $USUARIO_SEL"
    read -rp "Nueva contraseña: " nueva_pass

    [[ -z "$nueva_pass" ]] && msg -verm "Contraseña vacía." && sleep 2 && return

    HASH=$(openssl passwd -6 "$nueva_pass")
    usermod -p "$HASH" "$USUARIO_SEL" 2>/dev/null || {
        msg -verm "No se pudo cambiar la contraseña."
        sleep 2
        return
    }

    actualizar_archivo_campo "$USERDIR/$USUARIO_SEL" "pass" "$nueva_pass"
    actualizar_archivo_campo "$DZ_USERDIR/$USUARIO_SEL" "pass" "$nueva_pass"

    msg -verd "Contraseña actualizada correctamente."
    msg -bar3
    read -rp "Presiona ENTER para volver..."
}

cambiar_limite() {
    header
    msg -bar3
    print_center -azu "CAMBIAR LIMITE"
    msg -bar3

    seleccionar_usuario || return

    msg -bar3
    echo -e "${cor[5]}Usuario seleccionado:${cor[3]} $USUARIO_SEL"
    read -rp "Nuevo límite de conexiones: " nuevo_limite

    [[ -z "$nuevo_limite" ]] && nuevo_limite="1"

    actualizar_archivo_campo "$USERDIR/$USUARIO_SEL" "limite" "$nuevo_limite"
    actualizar_archivo_campo "$DZ_USERDIR/$USUARIO_SEL" "limite" "$nuevo_limite"

    msg -verd "Límite actualizado correctamente."
    msg -bar3
    read -rp "Presiona ENTER para volver..."
}

ver_datos_usuario() {
    header
    msg -bar3
    print_center -azu "DATOS DEL USUARIO"
    msg -bar3

    seleccionar_usuario || return

    header
    msg -bar3
    print_center -azu "DATOS DEL USUARIO"
    msg -bar3

    echo -e "${cor[5]}Usuario Linux:${cor[2]} $USUARIO_SEL"
    msg -bar3

    if [[ -f "$USERDIR/$USUARIO_SEL" ]]; then
        cat "$USERDIR/$USUARIO_SEL"
    else
        msg -verm "No existe archivo de datos."
    fi

    msg -bar3
    chage -l "$USUARIO_SEL" 2>/dev/null
    msg -bar3
    read -rp "Presiona ENTER para volver..."
}

while true; do
    header
    msg -bar3
    print_center -azu "EDITAR/RENOVAR USUARIOS"
    print_center -ama "SSH / SSL / VMESS"
    msg -bar3

    echo -e "\033[0;35m [${cor[2]}01\033[0;35m]\033[0;33m ${flech}${cor[3]} RENOVAR DIAS DE USUARIO"
    echo -e "\033[0;35m [${cor[2]}02\033[0;35m]\033[0;33m ${flech}${cor[3]} CAMBIAR CONTRASEÑA"
    echo -e "\033[0;35m [${cor[2]}03\033[0;35m]\033[0;33m ${flech}${cor[3]} CAMBIAR LIMITE DE CONEXIONES"
    echo -e "\033[0;35m [${cor[2]}04\033[0;35m]\033[0;33m ${flech}${cor[3]} VER DATOS DEL USUARIO"
    msg -bar3
    echo -e "\033[0;35m [${cor[2]}0\033[0;35m]\033[0;33m ⇦ \033[1;37m\e[3;33m[ VOLVER ]\e[0m"
    msg -bar3

    selection=$(selection_fun 4)

    case "$selection" in
        0) break ;;
        1) renovar_usuario ;;
        2) cambiar_password ;;
        3) cambiar_limite ;;
        4) ver_datos_usuario ;;
    esac
done
