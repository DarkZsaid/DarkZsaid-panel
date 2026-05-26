#!/bin/bash

source /opt/darkzsaid/lib/estilo_original.sh

contar_sshd() {
    ps -ef | grep -i "sshd:" | grep -v grep | grep -v root | awk '{print $1}' | sort | uniq -c
}

contar_dropbear() {
    if command -v dropbear_pids >/dev/null 2>&1; then
        dropbear_pids 2>/dev/null | while read -r pid; do
            ps -p "$pid" -o user= 2>/dev/null
        done | grep -v '^$' | sort | uniq -c
    else
        ps -ef | grep -i dropbear | grep -v grep | awk '{print $1}' | sort | uniq -c
    fi
}

contar_openvpn() {
    if [[ -f /etc/openvpn/openvpn-status.log ]]; then
        grep -E ",[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:" /etc/openvpn/openvpn-status.log 2>/dev/null | cut -d',' -f1 | sort | uniq -c
    elif [[ -f /etc/openvpn/server/openvpn-status.log ]]; then
        grep -E ",[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:" /etc/openvpn/server/openvpn-status.log 2>/dev/null | cut -d',' -f1 | sort | uniq -c
    fi
}

while true; do
    header

    msg -bar3
    print_center -azu "CONTADOR ONLINE USERS"
    print_center -ama "SSH / DROPBEAR / OPENVPN"
    msg -bar3

    echo -e "\033[1;33m OpenSSH conectados:\033[0m"
    ssh_data="$(contar_sshd)"
    if [[ -n "$ssh_data" ]]; then
        echo "$ssh_data"
    else
        echo -e "\033[1;31m Ningún usuario SSH detectado.\033[0m"
    fi

    msg -bar3
    echo -e "\033[1;33m Dropbear conectados:\033[0m"
    db_data="$(contar_dropbear)"
    if [[ -n "$db_data" ]]; then
        echo "$db_data"
    else
        echo -e "\033[1;31m Ningún usuario Dropbear detectado.\033[0m"
    fi

    msg -bar3
    echo -e "\033[1;33m OpenVPN conectados:\033[0m"
    ovpn_data="$(contar_openvpn)"
    if [[ -n "$ovpn_data" ]]; then
        echo "$ovpn_data"
    else
        echo -e "\033[1;31m Ningún usuario OpenVPN detectado.\033[0m"
    fi

    msg -bar3
    echo -e "\033[0;35m [${cor[2]}1\033[0;35m]\033[0;33m ${flech}${cor[3]} Actualizar contador"
    echo -e "\033[0;35m [${cor[2]}0\033[0;35m]\033[0;33m ⇦ \033[1;37m\e[3;33m[ VOLVER ]\e[0m"
    msg -bar3

    selection=$(selection_fun 1)

    case "$selection" in
        0) break ;;
        1) continue ;;
    esac
done
