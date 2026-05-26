#!/bin/bash

[[ -f /opt/darkzsaid/lib/estilo_original.sh ]] && source /opt/darkzsaid/lib/estilo_original.sh

while true; do
    clear

    if declare -F header >/dev/null 2>&1; then
        header
    else
        echo "DarkZsaid"
    fi

    echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e "\033[1;33m        EXTRAS TELEGRAM / CHECKUSER\033[0m"
    echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo
    echo -e "\033[0;35m [01]\033[0m ➜ \033[1;37mBANNER SSH / DROPBEAR\033[0m"
    echo -e "\033[0;35m [02]\033[0m ➜ \033[1;37mBOT CLIENTES TELEGRAM\033[0m"
    echo -e "\033[0;35m [03]\033[0m ➜ \033[1;37mACTIVADOR CHECKUSER\033[0m"
    echo
    echo -e "\033[0;35m [00]\033[0m ➜ \033[1;33mVOLVER\033[0m"
    echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    read -rp "Opción: " op

    case "$op" in
        1|01) bash /opt/darkzsaid/menus/banner_ssh.sh ;;
        2|02) bash /opt/darkzsaid/menus/bot_clientes_telegram.sh ;;
        3|03) bash /opt/darkzsaid/menus/checkuser.sh ;;
        0|00) break ;;
        *) echo "Opción inválida"; sleep 1 ;;
    esac
done
