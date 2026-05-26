#!/bin/bash

# Estilo visual tipo original, adaptado para DarkZsaid

flech='➮'
pPIniT='∘'
_on='ON'
_off='OFF'

cor[0]="\033[0m"
cor[1]="\033[1;34m"
cor[2]="\033[1;32m"
cor[3]="\033[1;37m"
cor[4]="\033[1;36m"
cor[5]="\033[1;33m"
cor[6]="\033[1;35m"

msg() {
    local SEMCOR='\033[0m'
    case "$1" in
        -ne)    echo -ne "\033[1;31m${2}${SEMCOR}" ;;
        -ama)   echo -e  "\033[1;33m${2}${SEMCOR}" ;;
        -verm)  echo -e  "\033[1;33m[!] \033[1;31m${2}${SEMCOR}" ;;
        -verm2) echo -e  "\033[1;31m${2}${SEMCOR}" ;;
        -azu)   echo -e  "\033[1;36m${2}${SEMCOR}" ;;
        -verd)  echo -e  "\033[1;32m${2}${SEMCOR}" ;;
        -bra)   echo -e  "\033[1;37m${2}${SEMCOR}" ;;
        -nazu)  echo -ne "\033[1;36m${2}${SEMCOR}" ;;
        -nverd) echo -ne "\033[1;32m${2}${SEMCOR}" ;;
        -nama)  echo -ne "\033[1;33m${2}${SEMCOR}" ;;
        -bar)   echo -e  "\033[1;31m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${SEMCOR}" ;;
        -bar2)  echo -e  "\033[1;31m=====================================================${SEMCOR}" ;;
        -bar3)  echo -e  "\033[1;33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${SEMCOR}" ;;
        -blue)  echo -e  "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${SEMCOR}" ;;
        *)      echo -e "$2" ;;
    esac
}

print_center() {
    local col=""
    local text=""

    if [[ -z "$2" ]]; then
        text="$1"
        col="-azu"
    else
        col="$1"
        text="$2"
    fi

    while read -r line; do
        local space=""
        local x=$(( (54 - ${#line}) / 2 ))
        [[ "$x" -lt 0 ]] && x=0
        for ((i=0; i<x; i++)); do
            space+=" "
        done
        msg "$col" "$space$line"
    done <<< "$(echo -e "$text")"
}

selection_fun() {
    local max="$1"
    local selection="null"
    local range=""

    for ((i=0; i<=max; i++)); do
        range="$range $i"
    done

    while [[ ! " $range " =~ " $selection " ]]; do
        echo -ne "\033[1;37m ► Opcion : " >&2
        read -r selection
        tput cuu1 >&2
        tput dl1 >&2
    done

    echo "$selection"
}

header() {
    clear
    msg -bar3
    print_center -azu "⚡ DARKZSAID PANEL ⚡"
    print_center -ama "SSH / SSL / VMESS / UDP"
    msg -bar3
}

ports_() {
    local ssh_port dropbear_port squid_port ssl_port
    ssh_port=$(grep -i "^Port " /etc/ssh/sshd_config 2>/dev/null | head -1 | awk '{print $2}')
    dropbear_port=$(grep -oE 'DROPBEAR_PORT=[0-9]+' /etc/default/dropbear 2>/dev/null | head -1 | cut -d= -f2)
    squid_port=$(grep -E "^[[:space:]]*http_port" /etc/squid/squid.conf /etc/squid3/squid.conf 2>/dev/null | head -1 | awk '{print $2}')
    ssl_port=$(ss -ltnp 2>/dev/null | grep -i stunnel | awk '{print $4}' | awk -F: '{print $NF}' | head -1)

    [[ -n "$ssh_port" ]] && echo -e "${cor[1]} ${pPIniT} ${cor[5]}OpenSSH:${cor[2]} $ssh_port"
    [[ -n "$dropbear_port" ]] && echo -e "${cor[1]} ${pPIniT} ${cor[5]}Dropbear:${cor[2]} $dropbear_port"
    [[ -n "$squid_port" ]] && echo -e "${cor[1]} ${pPIniT} ${cor[5]}Squid:${cor[2]} $squid_port"
    [[ -n "$ssl_port" ]] && echo -e "${cor[1]} ${pPIniT} ${cor[5]}SSL:${cor[2]} $ssl_port"
}
