#!/bin/bash

limpiar_pantalla() {
    printf '\033[H\033[2J\033[3J'
}


source /opt/darkzsaid/lib/estilo_original.sh

CONF="/etc/darkzsaid/checkuser/checkuser.conf"
SERVICE="/etc/systemd/system/chekuser.service"
ACTIVE_FLAG="/etc/darkzsaid/checkuser/show_active_users.on"

mkdir -p /etc/darkzsaid/checkuser /bin/ejecutar

get_ip() {
    if [[ -f /bin/ejecutar/IPcgh ]]; then
        cat /bin/ejecutar/IPcgh
    else
        hostname -I 2>/dev/null | awk '{print $1}'
    fi
}

load_conf() {
    [[ -f "$CONF" ]] && source "$CONF"
    [[ -z "$CHECKUSER_PORT" ]] && CHECKUSER_PORT=""
    [[ -z "$CHECKUSER_FORMAT" ]] && CHECKUSER_FORMAT="1"
}

save_conf() {
    cat > "$CONF" <<EOC
CHECKUSER_PORT="$CHECKUSER_PORT"
CHECKUSER_FORMAT="$CHECKUSER_FORMAT"
EOC
}

checkuser_on() {
    if ps x | grep "CheckUser" | grep -v grep >/dev/null 2>&1 || systemctl is-active --quiet chekuser 2>/dev/null; then
        return 0
    fi
    return 1
}

status_txt() {
    if checkuser_on; then
        echo -e "${cor[2]}ON\033[0m"
    else
        echo -e "\033[1;31mOFF\033[0m"
    fi
}

crear_servicio() {
    load_conf

    cat > "$SERVICE" <<EOC
[Unit]
Description=DarkZsaid CheckUser API
After=network.target

[Service]
Type=simple
ExecStart=/bin/ejecutar/CheckUser ${CHECKUSER_PORT} ${CHECKUSER_FORMAT}
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOC

    systemctl daemon-reload >/dev/null 2>&1
}

puerto_libre_checkuser() {
    local p

    for p in $(shuf -i 82-150); do
        if ! ss -ltn 2>/dev/null | awk '{print $4}' | grep -q ":${p}$"; then
            echo "$p"
            return
        fi
    done

    echo "90"
}

start_checkUser() {
    limpiar_pantalla
    header
    msg -bar3
    print_center -azu "VERIFICACION DE USUARIOS ONLINE"
    msg -bar3

    if [[ ! -x /bin/ejecutar/CheckUser ]]; then
        msg -verm "No existe /bin/ejecutar/CheckUser"
        msg -bar3
        read -rp "Presiona ENTER para volver..."
        return
    fi

    random_port=$(puerto_libre_checkuser)
    [[ -z "$random_port" ]] && random_port="90"

    read -p " PUERTO CheckUser [$random_port]: " CHECKUSER_PORT
    [[ -z "$CHECKUSER_PORT" ]] && CHECKUSER_PORT="$random_port"

    if ! [[ "$CHECKUSER_PORT" =~ ^[0-9]+$ ]] || [[ "$CHECKUSER_PORT" -lt 1 || "$CHECKUSER_PORT" -gt 65535 ]]; then
        msg -verm "Puerto inválido."
        sleep 2
        return
    fi

    msg -bar3
    echo -e "${cor[5]}Seleccione formato de fecha:${cor[0]}"
    echo -e "\033[0;35m [${cor[2]}01\033[0;35m]\033[0;33m ${flech}${cor[3]} YYYY/MM/DD"
    echo -e "\033[0;35m [${cor[2]}02\033[0;35m]\033[0;33m ${flech}${cor[3]} DD/MM/YYYY"
    msg -bar3
    read -p " FORMATO [1]: " CHECKUSER_FORMAT
    [[ -z "$CHECKUSER_FORMAT" ]] && CHECKUSER_FORMAT="1"
    [[ "$CHECKUSER_FORMAT" != "2" ]] && CHECKUSER_FORMAT="1"

    save_conf
    crear_servicio

    systemctl enable chekuser >/dev/null 2>&1
    systemctl restart chekuser >/dev/null 2>&1

    sleep 2

    limpiar_pantalla
    header
    msg -bar3
    print_center -azu "VERIFICACION DE USUARIOS ONLINE"
    msg -bar3

    if checkuser_on; then
        msg -verd "CheckUser ACTIVADO correctamente."
        msg -bar3
        echo -e "${cor[5]}URL:${cor[2]} http://$(get_ip):${CHECKUSER_PORT}/checkUser${cor[0]}"
        echo -e "${cor[5]}JSON:${cor[2]} http://$(get_ip):${CHECKUSER_PORT}/json${cor[0]}"
    else
        msg -verm "No se pudo activar CheckUser."
        systemctl status chekuser --no-pager 2>/dev/null | head -20
    fi

    msg -bar3
    read -rp "Presiona ENTER para volver..."
}

stop_checkUser() {
    systemctl stop chekuser >/dev/null 2>&1
    systemctl disable chekuser >/dev/null 2>&1
    rm -f "$SERVICE"
    systemctl daemon-reload >/dev/null 2>&1
    pkill -f "/bin/ejecutar/CheckUser" 2>/dev/null
    pkill -f "checkuser_server.py" 2>/dev/null

    limpiar_pantalla
    header
    msg -bar3
    print_center -azu "VERIFICACION DE USUARIOS ONLINE"
    msg -bar3
    msg -verd "CheckUser DESACTIVADO."
    msg -bar3
    read -rp "Presiona ENTER para volver..."
}

modificar_puerto() {
    load_conf

    limpiar_pantalla
    header
    msg -bar3
    print_center -azu "MODIFICAR PUERTO CheckUser"
    msg -bar3

    echo -e "${cor[5]}Puerto actual:${cor[2]} $CHECKUSER_PORT"
    msg -bar3
    read -p " Nuevo puerto: " nuevo

    if ! [[ "$nuevo" =~ ^[0-9]+$ ]] || [[ "$nuevo" -lt 1 || "$nuevo" -gt 65535 ]]; then
        msg -verm "Puerto inválido."
        sleep 2
        return
    fi

    CHECKUSER_PORT="$nuevo"
    save_conf
    crear_servicio
    systemctl restart chekuser >/dev/null 2>&1

    msg -verd "Puerto modificado."
    echo -e "${cor[5]}URL:${cor[2]} http://$(get_ip):${CHECKUSER_PORT}/checkUser${cor[0]}"
    msg -bar3
    read -rp "Presiona ENTER para volver..."
}

modificar_formato() {
    load_conf

    limpiar_pantalla
    header
    msg -bar3
    print_center -azu "MODIFICAR FORMATO CheckUser"
    msg -bar3

    echo -e "${cor[5]}Formato actual:${cor[2]} $CHECKUSER_FORMAT"
    msg -bar3
    echo -e "\033[0;35m [${cor[2]}01\033[0;35m]\033[0;33m ${flech}${cor[3]} YYYY/MM/DD"
    echo -e "\033[0;35m [${cor[2]}02\033[0;35m]\033[0;33m ${flech}${cor[3]} DD/MM/YYYY"
    msg -bar3
    read -p " Nuevo formato: " fmt

    [[ "$fmt" != "2" ]] && fmt="1"

    CHECKUSER_FORMAT="$fmt"
    save_conf
    crear_servicio
    systemctl restart chekuser >/dev/null 2>&1

    msg -verd "Formato modificado."
    msg -bar3
    read -rp "Presiona ENTER para volver..."
}

toggle_user_activos_app() {
    limpiar_pantalla
    header
    msg -bar3
    print_center -azu "USER ACTIVOS EN APP"
    msg -bar3

    if [[ -e "$ACTIVE_FLAG" ]]; then
        rm -f "$ACTIVE_FLAG"
        msg -ama "Usuarios activos en app: OFF"
    else
        touch "$ACTIVE_FLAG"
        msg -verd "Usuarios activos en app: ON"
    fi

    systemctl restart chekuser >/dev/null 2>&1
    msg -bar3
    read -rp "Presiona ENTER para volver..."
}

menu_chekuser() {
    while true; do
        load_conf
        STATUS="$(status_txt)"

        limpiar_pantalla
        header
        msg -bar3
        print_center -azu "VERIFICACION DE USUARIOS ONLINE"
        msg -bar3

        if checkuser_on; then
            echo -e "${cor[5]}URL:${cor[2]} http://$(get_ip):${CHECKUSER_PORT}/checkUser${cor[0]}"
            msg -bar3
            echo -e "\033[0;35m [${cor[2]}1\033[0;35m]\033[0;33m >${cor[3]} DESACTIVAR CHEKUSER"
            echo -e "\033[0;35m [${cor[2]}2\033[0;35m]\033[0;33m >${cor[3]} MODIFICAR PUERTO"
            echo -e "\033[0;35m [${cor[2]}3\033[0;35m]\033[0;33m >${cor[3]} MODIFICAR FORMATO"
            echo -e "\033[0;35m [${cor[2]}4\033[0;35m]\033[0;33m >${cor[3]} ACTIVAR/DESACTIVAR USER ACTIVOS EN APP"
            echo -e "\033[0;35m [${cor[2]}0\033[0;35m]\033[0;33m > \033[1;37m\e[3;33m[ VOLVER ]\e[0m"
            msg -bar3
            read -rp " ► Opcion : " op

            case "$op" in
                0) break ;;
                1) stop_checkUser ;;
                2) modificar_puerto ;;
                3) modificar_formato ;;
                4) toggle_user_activos_app ;;
            esac
        else
            print_center -verm2 "ADVERTENCIA!!!\n CheckUser PODRIA CONSUMIR RECURSOS \n EN CONEXIONES O METODOS INESTABLES \n RECOMENDABLE ANALIZAR TU METODO PRIMERO"
            msg -bar3
            echo -e "\033[0;35m [${cor[2]}1\033[0;35m]\033[0;33m >${cor[3]} ACTIVAR CHEKUSER"
            echo -e "\033[0;35m [${cor[2]}0\033[0;35m]\033[0;33m > \033[1;37m\e[3;33m[ VOLVER ]\e[0m"
            msg -bar3
            read -rp " ► Opcion : " op

            case "$op" in
                0) break ;;
                1) start_checkUser ;;
            esac
        fi
    done
}

menu_chekuser
