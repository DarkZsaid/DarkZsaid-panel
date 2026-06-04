#!/bin/bash

pantalla_limpia() {
    printf '\033c'
}


limpiar_pantalla() {
    printf '\033[H\033[2J\033[3J'
}


source /opt/darkzsaid/lib/estilo_original.sh

USERDIR="/etc/adm-lite/userDIR"
mkdir -p "$USERDIR"

listar_ssh() {
    ps -eo user,args 2>/dev/null | grep -E "sshd: .*@|sshd: .*notty|sshd: .*pts" | grep -v grep | awk '{print $1}' | grep -v '^root$' | sort
}

listar_dropbear() {
    if command -v dropbear_pids >/dev/null 2>&1; then
        dropbear_pids 2>/dev/null | while read -r pid; do
            ps -p "$pid" -o user= 2>/dev/null
        done | grep -v '^$' | grep -v '^root$' | sort
    else
        ps -eo user,args 2>/dev/null | grep -i dropbear | grep -v grep | awk '{print $1}' | grep -v '^root$' | sort
    fi
}

listar_openvpn() {
    if [[ -f /etc/openvpn/openvpn-status.log ]]; then
        grep -E ",[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:" /etc/openvpn/openvpn-status.log 2>/dev/null | cut -d',' -f1 | sort
    elif [[ -f /etc/openvpn/server/openvpn-status.log ]]; then
        grep -E ",[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:" /etc/openvpn/server/openvpn-status.log 2>/dev/null | cut -d',' -f1 | sort
    fi
}

contar_usuario() {
    local usuario="$1"
    local fuente="$2"

    case "$fuente" in
        ssh) listar_ssh | grep -Fx "$usuario" | wc -l ;;
        dropbear) listar_dropbear | grep -Fx "$usuario" | wc -l ;;
        openvpn) listar_openvpn | grep -Fx "$usuario" | wc -l ;;
    esac
}

mostrar_conectados() {
    header
    msg -bar3
    print_center -azu "USUARIOS CONECTADOS"
    print_center -ama "SSH / DROPBEAR / OPENVPN"
    msg -bar3

    usuarios_panel=()
    while IFS= read -r u; do
        [[ -z "$u" ]] && continue
        usuarios_panel+=("$u")
    done < <(find "$USERDIR" -maxdepth 1 -type f -printf "%f\n" 2>/dev/null | sort)

    if [[ "${#usuarios_panel[@]}" -eq 0 ]]; then
        echo -e "${cor[5]} NO HAY USUARIOS REGISTRADOS EN EL PANEL${cor[0]}"
        msg -bar3
        read -rp "Enter para volver..."
        return
    fi

    total_conectados=0

    echo -e "${cor[1]}  ▸ ${cor[3]}USUARIO        ${cor[1]}SSH   DROPBEAR   OPENVPN   TOTAL${cor[0]}"
    msg -bar3

    i=1
    for u in "${usuarios_panel[@]}"; do
        ssh_c=$(contar_usuario "$u" ssh)
        db_c=$(contar_usuario "$u" dropbear)
        ovpn_c=$(contar_usuario "$u" openvpn)
        total=$((ssh_c + db_c + ovpn_c))

        if [[ "$total" -gt 0 ]]; then
            num=$(printf "%02d" "$i")
            printf " \033[0;35m[%s]\033[0;33m ➮ \033[1;37m%-13s \033[1;32m%-5s \033[1;32m%-10s \033[1;32m%-8s \033[1;33m%s\033[0m\n" \
                "$num" "$u" "$ssh_c" "$db_c" "$ovpn_c" "$total"
            total_conectados=$((total_conectados + total))
            ((i++))
        fi
    done

    if [[ "$total_conectados" -eq 0 ]]; then
        echo -e "${cor[5]}  NO HAY CLIENTES CONECTADOS EN ESTE MOMENTO${cor[0]}"
    fi

    msg -bar3
    echo -e "${cor[4]} ▼ # ONLINE ${cor[5]}[ ${cor[3]}${total_conectados} ${cor[5]}] ${cor[4]} | CLIENTES CONECTADOS ${cor[2]}▾${cor[0]}"
    msg -bar3

    echo -e " \033[0;35m[\033[0;32m01\033[0;35m]\033[0;33m ➮ \033[1;37mACTUALIZAR"
    echo -e " \033[0;35m[\033[0;32m00\033[0;35m]\033[0;33m ⇦ \033[1;37m\e[3;33m[ VOLVER ]\e[0m"
    msg -bar3

    read -rp " ► Opcion : " op
    [[ "$op" = "1" || "$op" = "01" ]] && mostrar_conectados
}

mostrar_conectados
