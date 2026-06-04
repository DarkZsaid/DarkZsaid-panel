#!/bin/bash

pantalla_limpia() {
    printf '\033c'
}


limpiar_pantalla() {
    printf '\033[H\033[2J\033[3J'
}


source /opt/darkzsaid/lib/estilo_original.sh

REGISTER_LOG="/etc/adm-lite/registerBOT.log"
USERDIR="/etc/adm-lite/userDIR"

mkdir -p /etc/adm-lite "$USERDIR"
touch "$REGISTER_LOG"

dias_restantes_user() {
    local user="$1"
    local data_user data_user_sec data_sec variavel_soma dias_use

    data_sec=$(date +%s)
    data_user=$(chage -l "$user" 2>/dev/null | grep -i "Account expires" | awk -F ":" '{print $2}' | xargs)

    if [[ -z "$data_user" || "$data_user" = "never" ]]; then
        echo "Null"
        return
    fi

    data_user_sec=$(date +%s --date="$data_user" 2>/dev/null)

    if [[ -z "$data_user_sec" ]]; then
        echo "Null"
        return
    fi

    variavel_soma=$((data_user_sec - data_sec))
    dias_use=$((variavel_soma / 86400))

    if [[ "$dias_use" -le 0 ]]; then
        echo "CADUCADO"
    else
        echo "$dias_use"
    fi
}

datos_cliente() {
    local nombre_usuario_ssh="$1"
    local _sen _limit dias_user nombre_mostrar

    dias_user="$(dias_restantes_user "$nombre_usuario_ssh")"

    if [[ -e "$USERDIR/$nombre_usuario_ssh" ]]; then
        _sen=$(grep -i "senha" "$USERDIR/$nombre_usuario_ssh" | awk '{print $2}')
        _limit=$(grep -i "limite" "$USERDIR/$nombre_usuario_ssh" | awk '{print $2}')

        if [[ "$_limit" = "HWID" || "$_limit" = "TOKEN" ]]; then
            _sen="$nombre_usuario_ssh"
            nombre_mostrar=$(grep -i "senha" "$USERDIR/$nombre_usuario_ssh" | awk '{print $2}')
        else
            nombre_mostrar="$nombre_usuario_ssh"
        fi
    else
        _limit=$(grep -w "$nombre_usuario_ssh" /etc/passwd 2>/dev/null | awk -F ':' '{split($5, a, ","); print a[1]}')
        _sen="$nombre_usuario_ssh"
        nombre_mostrar="$nombre_usuario_ssh"

        if [[ "$_limit" = "HWID" || "$_limit" = "TOKEN" ]]; then
            nombre_mostrar="TK"
        fi
    fi

    [[ -z "$_sen" ]] && _sen="$nombre_usuario_ssh"
    [[ -z "$_limit" ]] && _limit="null"

    echo "$nombre_mostrar|$_sen|$_limit|$dias_user"
}

ver_por_id_reseller() {
    header
    msg -bar3
    print_center -azu "VERIFICADOR CLIENTES"
    print_center -ama "CLIENTES POR ID RESELLER"
    msg -bar3

    read -rp "Ingrese ID reseller/admin: " id_buscar

    [[ -z "$id_buscar" ]] && {
        msg -verm "No ingresaste ID."
        sleep 2
        return
    }

    if ! grep -q "^${id_buscar}|" "$REGISTER_LOG" 2>/dev/null; then
        msg -verm "No hay clientes registrados para ese ID."
        msg -bar3
        read -rp "Presiona ENTER para volver..."
        return
    fi

    echo -e "${cor[1]}  ▸ ${cor[3]}USUARIO        ${cor[1]}CONTRASEÑA       ${cor[1]}LIMITE   ${cor[4]}DIAS${cor[0]}"
    msg -bar3

    i=1
    grep "^${id_buscar}|" "$REGISTER_LOG" | while IFS="|" read -r id_admin nombre_usuario_ssh; do
        [[ -z "$nombre_usuario_ssh" ]] && continue

        if grep -q "^${nombre_usuario_ssh}:" /etc/passwd; then
            info="$(datos_cliente "$nombre_usuario_ssh")"
            user_show="$(echo "$info" | cut -d'|' -f1)"
            pass_show="$(echo "$info" | cut -d'|' -f2)"
            limit_show="$(echo "$info" | cut -d'|' -f3)"
            dias_show="$(echo "$info" | cut -d'|' -f4)"

            num=$(printf "%02d" "$i")

            printf " \033[0;35m[%s]\033[0;33m ➮ \033[1;37m%-12s \033[1;31m%-14s \033[1;35m%-7s \033[1;32m%s\033[0m\n" \
                "$num" "$user_show" "$pass_show" "$limit_show" "$dias_show"
            i=$((i + 1))
        else
            num=$(printf "%02d" "$i")
            echo -e "\033[0;35m [${cor[2]}${num}\033[0;35m]\033[0;33m ${flech}${cor[3]} $nombre_usuario_ssh ${cor[1]}NO EXISTE EN LINUX"
            i=$((i + 1))
        fi
    done

    msg -bar3
    read -rp "Presiona ENTER para volver..."
}

ver_todos_registerbot() {
    header
    msg -bar3
    print_center -azu "VERIFICADOR CLIENTES"
    print_center -ama "REGISTROS BOT / RESELLER"
    msg -bar3

    if [[ ! -s "$REGISTER_LOG" ]]; then
        msg -verm "No hay registros en /etc/adm-lite/registerBOT.log"
        msg -bar3
        read -rp "Presiona ENTER para volver..."
        return
    fi

    echo -e "${cor[1]}  ▸ ${cor[3]}ID ADMIN / RESELLER       ${cor[1]}USUARIO SSH       ESTADO${cor[0]}"
    msg -bar3

    i=1
    while IFS="|" read -r id_admin nombre_usuario_ssh; do
        [[ -z "$id_admin" || -z "$nombre_usuario_ssh" ]] && continue

        num=$(printf "%02d" "$i")

        if id "$nombre_usuario_ssh" >/dev/null 2>&1; then
            estado="\033[1;32mOK"
        else
            estado="\033[1;31mNO EXISTE"
        fi

        echo -e "\033[0;35m [${cor[2]}${num}\033[0;35m]\033[0;33m ${flech}${cor[3]} ID:${cor[2]} $id_admin ${cor[5]}USER:${cor[3]} $nombre_usuario_ssh $estado${cor[0]}"
        i=$((i + 1))
    done < "$REGISTER_LOG"

    msg -bar3
    echo -e "${cor[4]} ▼ # REGISTROS ${cor[5]}[ ${cor[3]}$((i-1)) ${cor[5]}] ${cor[4]} | CLIENTES BOT ${cor[2]}▾${cor[0]}"
    msg -bar3
    read -rp "Presiona ENTER para volver..."
}

verificar_registros_rotos() {
    header
    msg -bar3
    print_center -azu "VERIFICADOR CLIENTES"
    print_center -ama "REGISTROS ROTOS"
    msg -bar3

    if [[ ! -s "$REGISTER_LOG" ]]; then
        msg -verm "No hay registros en registerBOT.log"
        msg -bar3
        read -rp "Presiona ENTER para volver..."
        return
    fi

    rotos=0

    while IFS="|" read -r id_admin nombre_usuario_ssh; do
        [[ -z "$id_admin" || -z "$nombre_usuario_ssh" ]] && continue

        if ! id "$nombre_usuario_ssh" >/dev/null 2>&1; then
            rotos=$((rotos + 1))
            num=$(printf "%02d" "$rotos")
            echo -e "\033[0;35m [${cor[2]}${num}\033[0;35m]\033[0;33m ${flech}${cor[3]} ID:${cor[2]} $id_admin ${cor[5]}USER:${cor[1]} $nombre_usuario_ssh NO EXISTE"
        fi
    done < "$REGISTER_LOG"

    [[ "$rotos" -eq 0 ]] && echo -e "${cor[2]} No hay registros rotos.${cor[0]}"

    msg -bar3
    echo -e "${cor[4]} ▼ # ROTOS ${cor[5]}[ ${cor[3]}$rotos ${cor[5]}] ${cor[4]} | REGISTERBOT ${cor[2]}▾${cor[0]}"
    msg -bar3
    read -rp "Presiona ENTER para volver..."
}

limpiar_registros_rotos() {
    header
    msg -bar3
    print_center -verm2 "LIMPIAR REGISTROS ROTOS"
    msg -bar3

    echo -e "${cor[1]}Esto eliminará líneas de registerBOT.log cuyo usuario ya no existe.${cor[0]}"
    read -rp "Escribe SI para continuar: " conf

    [[ "$conf" != "SI" ]] && {
        msg -ama "Cancelado."
        sleep 2
        return
    }

    tmp="/tmp/registerBOT.clean"
    : > "$tmp"

    eliminados=0

    while IFS="|" read -r id_admin nombre_usuario_ssh; do
        [[ -z "$id_admin" || -z "$nombre_usuario_ssh" ]] && continue

        if id "$nombre_usuario_ssh" >/dev/null 2>&1; then
            echo "$id_admin|$nombre_usuario_ssh" >> "$tmp"
        else
            eliminados=$((eliminados + 1))
        fi
    done < "$REGISTER_LOG"

    cp -a "$REGISTER_LOG" "$REGISTER_LOG.bak_$(date +%F_%H%M%S)"
    mv "$tmp" "$REGISTER_LOG"

    msg -verd "Registros rotos eliminados: $eliminados"
    msg -bar3
    read -rp "Presiona ENTER para volver..."
}

while true; do
    header
    msg -bar3
    echo -e "${cor[2]}VERIFICADOR CLIENTES"
    msg -bar3

    echo -e "\033[0;35m [${cor[2]}01\033[0;35m]\033[0;33m ${flech}${cor[3]} VER CLIENTES POR ID RESELLER"
    echo -e "\033[0;35m [${cor[2]}02\033[0;35m]\033[0;33m ${flech}${cor[3]} VER TODOS LOS CLIENTES BOT"
    echo -e "\033[0;35m [${cor[2]}03\033[0;35m]\033[0;33m ${flech}${cor[3]} VERIFICAR REGISTROS ROTOS"
    echo -e "\033[0;35m [${cor[2]}04\033[0;35m]\033[0;33m ${flech}\033[1;31m LIMPIAR REGISTROS ROTOS"
    msg -bar3
    echo -e " \033[0;35m [${cor[2]}0\033[0;35m]\033[0;33m ${flech} \033[1;37m\e[3;33m[ REGRESAR ]\e[0m"
    msg -bar3

    selection=$(selection_fun 4)

    case "$selection" in
        0) break ;;
        1) ver_por_id_reseller ;;
        2) ver_todos_registerbot ;;
        3) verificar_registros_rotos ;;
        4) limpiar_registros_rotos ;;
    esac
done
