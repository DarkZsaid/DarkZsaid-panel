#!/bin/bash

source /opt/darkzsaid/lib/estilo_original.sh

estado_bot() {
    if pgrep -f "darkzsaid_bot" >/dev/null 2>&1; then
        echo -e "\033[0;31m[\033[0;32mON\033[0;31m]"
    else
        echo -e "\033[0;31m[OFF]"
    fi
}

estado_checkuser() {
    if systemctl is-active --quiet chekuser 2>/dev/null || ps x | grep "CheckUser" | grep -v grep >/dev/null 2>&1; then
        echo -e "\033[0;31m[\033[0;32mON\033[0;31m]"
    else
        echo -e "\033[0;31m[OFF]"
    fi
}

estado_multilogin() {
    if [[ -e /etc/darkzsaid/multilogin.on ]]; then
        echo -e "\033[0;31m[\033[0;32mON\033[0;31m]"
    else
        echo -e "\033[0;31m[OFF]"
    fi
}

while true; do
    header

    msg -bar3
    print_center -azu "CONTROL USUARIOS"
    print_center -ama "SSH / SSL / VMESS"
    msg -bar3

    BOT_STATUS=$(estado_bot)
    CHECK_STATUS=$(estado_checkuser)
    MULTI_STATUS=$(estado_multilogin)

    echo -e "\033[0;35m [${cor[2]}01\033[0;35m]\033[0;33m ${flech}${cor[3]} AGREGAR USUARIO \033[0;33m(HWID/NORMAL/TOKEN) \033[1;32m[ADD]"
    echo -e "\033[0;35m [${cor[2]}02\033[0;35m]\033[0;33m ${flech}${cor[3]} BORRAR 1/TODOS LOS USUARIO/s \033[1;32m[DEL]"
    echo -e "\033[0;35m [${cor[2]}03\033[0;35m]\033[0;33m ${flech}${cor[3]} EDITAR/RENOVAR USUARIOS \033[1;32m[EDIT]"
    echo -e "\033[0;35m [${cor[2]}04\033[0;35m]\033[0;33m ${flech}${cor[3]} MOSTRAR USUARIOS REGISTRADOS \033[1;32m[LIST]"
    echo -e "\033[0;35m [${cor[2]}05\033[0;35m]\033[0;33m ${flech}${cor[3]} MOSTRAR USUARIOS CONECTADOS \033[1;32m[ONL]"
    echo -e "\033[0;35m [${cor[2]}06\033[0;35m]\033[0;33m ${flech}${cor[3]} ADD/REMOVE BANNER \033[0;33m(SSH/DROPBEAR) \033[1;32m[MSG]"
    echo -e "\033[0;35m [${cor[2]}07\033[0;35m]\033[0;33m ${flech}${cor[3]} LOG DE CONSUMO \033[0;33m(Artificial) \033[1;32m[LOG]"
    echo -e "\033[0;35m [${cor[2]}08\033[0;35m]\033[0;33m ${flech}${cor[3]} BLOQUEAR USUARIOS \033[1;32m[LOCK]"
    echo -e "\033[0;35m [${cor[2]}09\033[0;35m]\033[0;33m ${flech}${cor[3]} BACKUP USUARIOS \033[0;33m(#OFFICIAL) \033[1;32m[BKP]"
    echo -e "\033[0;35m [${cor[2]}10\033[0;35m]\033[0;33m ${flech}${cor[3]} MENU CUENTAS SSR/SS \033[1;32m[SSR]"
    echo -e "\033[0;35m [${cor[2]}11\033[0;35m]\033[0;33m ${flech}${cor[3]} BOT CLIENTES TELEGRAM ${BOT_STATUS} \033[0;33m(#BETA) \033[1;32m[BOT]"
    echo -e "\033[0;35m [${cor[2]}12\033[0;35m]\033[0;33m ${flech}${cor[3]} VERIFICADOR CLIENTES \033[1;32m[CHK]"
    echo -e "\033[0;35m [${cor[2]}13\033[0;35m]\033[0;33m ${flech}${cor[3]} ACTIVADOR CheckUser ${CHECK_STATUS} \033[1;32m[ACT]"
    echo -e "\033[0;35m [${cor[2]}14\033[0;35m]\033[0;33m ${flech}${cor[3]} CONTROL ADMINISTRACION MULTILOGINS ${MULTI_STATUS} \033[1;32m[MULTI]"

    msg -bar3
    echo -e "\033[0;35m [${cor[2]}0\033[0;35m]\033[0;33m ⇦ \033[1;37m\e[3;33m[ VOLVER ]\e[0m"
    msg -bar3

    selection=$(selection_fun 14)

    case "$selection" in
        0) break ;;
        1) bash /opt/darkzsaid/menus/usuarios_agregar.sh ;;
        2) bash /opt/darkzsaid/menus/usuarios_borrar.sh ;;
        3) bash /opt/darkzsaid/menus/usuarios_renovar.sh ;;
        4) bash /opt/darkzsaid/menus/usuarios_mostrar.sh ;;
        5) bash /opt/darkzsaid/menus/usuarios_conectados.sh ;;
        6) bash /opt/darkzsaid/menus/banner_ssh.sh ;;
        7) bash /opt/darkzsaid/menus/log_consumo.sh ;;
        8) bash /opt/darkzsaid/menus/usuarios_bloquear.sh ;;
        9) bash /opt/darkzsaid/menus/usuarios_backup.sh ;;
        10) bash /opt/darkzsaid/menus/menu_ssr_ss.sh ;;
        11) bash /opt/darkzsaid/menus/bot_clientes_telegram.sh ;;
        12) bash /opt/darkzsaid/menus/verificador_clientes.sh ;;
        13) bash /opt/darkzsaid/menus/checkuser.sh ;;
        14) bash /opt/darkzsaid/menus/multilogin.sh ;;
    esac
done
