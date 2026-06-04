#!/bin/bash

pantalla_limpia() {
    printf '\033c'
}


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

estado_user() {
    local u="$1"

    if ! id "$u" >/dev/null 2>&1; then
        echo -e "\033[1;31mNO EXISTE\033[0m"
        return
    fi

    if passwd -S "$u" 2>/dev/null | grep -q " L "; then
        echo -e "\033[1;31mBLOQUEADO\033[0m"
    else
        echo -e "\033[1;32mACTIVO\033[0m"
    fi
}

matar_sesiones_usuario() {
    local usuario="$1"

    pkill -u "$usuario" 2>/dev/null
    pkill -f "sshd: $usuario" 2>/dev/null
    pkill -f "dropbear.*$usuario" 2>/dev/null
}

seleccionar_usuario() {
    usuarios=()
    while IFS= read -r u; do
        [[ -z "$u" ]] && continue
        usuarios+=("$u")
    done < <(listar_usuarios_panel)

    if [[ "${#usuarios[@]}" -eq 0 ]]; then
        msg -verm "No hay usuarios registrados."
        msg -bar3
        read -rp "Presiona ENTER para volver..."
        return 1
    fi

    local i=1
    for u in "${usuarios[@]}"; do
        nombre=$(grep -i "^senha:" "$USERDIR/$u" 2>/dev/null | cut -d: -f2- | xargs)
        limite=$(grep -i "^limite:" "$USERDIR/$u" 2>/dev/null | cut -d: -f2- | xargs)
        data=$(grep -i "^data:" "$USERDIR/$u" 2>/dev/null | cut -d: -f2- | xargs)
        [[ -z "$nombre" ]] && nombre="$u"
        [[ -z "$limite" ]] && limite="?"
        [[ -z "$data" ]] && data="?"

        num=$(printf "%02d" "$i")
        status=$(estado_user "$u")

        echo -e "\033[0;35m [${cor[2]}${num}\033[0;35m]\033[0;33m ${flech}\033[1;37m ${u}  \033[1;33mNombre:\033[1;32m ${nombre}  \033[1;33mLim:\033[1;32m ${limite}  \033[1;33mEstado:\033[0m ${status}"
        ((i++))
    done

    msg -bar3
    echo -e "\033[0;35m [${cor[2]}00\033[0;35m]\033[0;33m ⇦ \033[1;37m\e[3;33m[ VOLVER ]\e[0m"
    msg -bar3

    read -rp "Seleccione usuario: " op

    [[ "$op" = "0" || "$op" = "00" ]] && return 1

    if ! [[ "$op" =~ ^[0-9]+$ ]] || [[ "$op" -lt 1 ]] || [[ "$op" -gt "${#usuarios[@]}" ]]; then
        msg -verm "Opción inválida."
        sleep 2
        return 1
    fi

    USUARIO_SEL="${usuarios[$((op-1))]}"
    return 0
}

bloquear_usuario() {
    header
    msg -bar3
    print_center -azu "BLOQUEAR USUARIO"
    msg -bar3

    seleccionar_usuario || return

    msg -bar3
    echo -e "${cor[5]}Usuario seleccionado:${cor[3]} $USUARIO_SEL"
    read -rp "Escribe SI para bloquear: " conf

    if [[ "$conf" != "SI" ]]; then
        msg -ama "Cancelado."
        sleep 2
        return
    fi

    passwd -l "$USUARIO_SEL" >/dev/null 2>&1 || usermod -L "$USUARIO_SEL" >/dev/null 2>&1
    matar_sesiones_usuario "$USUARIO_SEL"

    echo "bloqueado: SI" >> "$USERDIR/$USUARIO_SEL" 2>/dev/null
    echo "bloqueado: SI" >> "$DZ_USERDIR/$USUARIO_SEL" 2>/dev/null

    msg -verd "Usuario bloqueado correctamente: $USUARIO_SEL"
    msg -bar3
    read -rp "Presiona ENTER para volver..."
}

desbloquear_usuario() {
    header
    msg -bar3
    print_center -azu "DESBLOQUEAR USUARIO"
    msg -bar3

    seleccionar_usuario || return

    msg -bar3
    echo -e "${cor[5]}Usuario seleccionado:${cor[3]} $USUARIO_SEL"
    read -rp "Escribe SI para desbloquear: " conf

    if [[ "$conf" != "SI" ]]; then
        msg -ama "Cancelado."
        sleep 2
        return
    fi

    passwd -u "$USUARIO_SEL" >/dev/null 2>&1 || usermod -U "$USUARIO_SEL" >/dev/null 2>&1

    sed -i '/^bloqueado:/d' "$USERDIR/$USUARIO_SEL" 2>/dev/null
    sed -i '/^bloqueado:/d' "$DZ_USERDIR/$USUARIO_SEL" 2>/dev/null

    msg -verd "Usuario desbloqueado correctamente: $USUARIO_SEL"
    msg -bar3
    read -rp "Presiona ENTER para volver..."
}

ver_bloqueados() {
    header
    msg -bar3
    print_center -azu "USUARIOS BLOQUEADOS"
    msg -bar3

    total=0

    while IFS= read -r u; do
        [[ -z "$u" ]] && continue

        if id "$u" >/dev/null 2>&1 && passwd -S "$u" 2>/dev/null | grep -q " L "; then
            total=$((total + 1))
            num=$(printf "%02d" "$total")
            nombre=$(grep -i "^senha:" "$USERDIR/$u" 2>/dev/null | cut -d: -f2- | xargs)
            [[ -z "$nombre" ]] && nombre="$u"

            echo -e "\033[0;35m [${cor[2]}${num}\033[0;35m]\033[0;33m ${flech}\033[1;37m $u  \033[1;33mNombre:\033[1;32m $nombre  \033[1;31mBLOQUEADO\033[0m"
        fi
    done < <(listar_usuarios_panel)

    if [[ "$total" -eq 0 ]]; then
        echo -e "${cor[5]} NO HAY USUARIOS BLOQUEADOS${cor[0]}"
    fi

    msg -bar3
    echo -e "${cor[4]} ▼ # BLOQUEADOS ${cor[5]}[ ${cor[3]}$total ${cor[5]}] ${cor[4]} | CLIENTES EN TU SERVIDOR ${cor[2]}▾${cor[0]}"
    msg -bar3
    read -rp "Presiona ENTER para volver..."
}

while true; do
    header
    msg -bar3
    echo -e "${cor[2]}BLOQUEAR USUARIOS"
    msg -bar3

    echo -e "\033[0;35m [\033[0;36m01\033[0;35m]\033[0;31m >${cor[3]} BLOQUEAR USUARIO"
    echo -e "\033[0;35m [\033[0;36m02\033[0;35m]\033[0;31m >${cor[3]} DESBLOQUEAR USUARIO"
    echo -e "\033[0;35m [\033[0;36m03\033[0;35m]\033[0;31m >${cor[3]} VER USUARIOS BLOQUEADOS"
    msg -bar3
    echo -e " \033[0;35m [\033[0;36m0\033[0;35m]\033[0;31m > \033[1;37m\e[3;33m[ REGRESAR ]\e[0m"
    msg -bar3

    selection=$(selection_fun 3)

    case "$selection" in
        0) break ;;
        1) bloquear_usuario ;;
        2) desbloquear_usuario ;;
        3) ver_bloqueados ;;
    esac
done
