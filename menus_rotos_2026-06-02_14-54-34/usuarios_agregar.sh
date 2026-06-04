#!/bin/bash

pantalla_limpia() {
    printf '\033c'
}


limpiar_pantalla() {
    printf '\033[H\033[2J\033[3J'
}


source /opt/darkzsaid/lib/estilo_original.sh
source /opt/darkzsaid/lib/usuarios_core.sh

mkdir -p /bin/ejecutar
mkdir -p /etc/adm-lite/userDIR
mkdir -p /etc/darkzsaid/usuarios

IP="$(hostname -I 2>/dev/null | awk '{print $1}')"

fecha_linux() {
    local dias="$1"
    date '+%Y-%m-%d' -d " +$dias days"
}

fecha_mostrar() {
    local dias="$1"
    date '+%d/%m/%Y' -d " +$dias days"
}

crear_usuario_base() {
    local login="$1"
    local pass="$2"
    local dias="$3"
    local limite="$4"
    local nombre_visible="$5"

    local valid
    valid="$(fecha_linux "$dias")"

    if id "$login" >/dev/null 2>&1; then
        echo -e "${cor[5]} ⚠️ USUARIO/TOKEN YA EXISTE, REGISTRE OTRO ⚠️${cor[0]}"
        return 1
    fi

    useradd -M -s /bin/false -e "$valid" "$login" 2>/dev/null || return 1
    HASH=$(openssl passwd -6 "$pass")
    usermod -p "$HASH" "$login" 2>/dev/null || {
        userdel "$login" 2>/dev/null
        return 1
    }

    echo "senha: $nombre_visible" > "/etc/adm-lite/userDIR/$login"
    echo "limite: $limite" >> "/etc/adm-lite/userDIR/$login"
    echo "data: $valid" >> "/etc/adm-lite/userDIR/$login"
    echo "pass: $pass" >> "/etc/adm-lite/userDIR/$login"

    cp -a "/etc/adm-lite/userDIR/$login" "/etc/darkzsaid/usuarios/$login" 2>/dev/null

    echo "$login|$pass|$dias|$limite|$valid|$nombre_visible|$(date '+%Y-%m-%d %H:%M:%S')" >> /opt/darkzsaid/data/usuarios.db

    return 0
}

mostrar_cuenta_normal() {
    local login="$1"
    local pass="$2"
    local dias="$3"
    local limite="$4"
    local datexp
    datexp="$(fecha_mostrar "$dias")"

    msg -bar3
    echo -e "${cor[5]} * Puertas Activas en su Servidor *"
    msg -bar3
    ports_
    msg -bar3
    echo -e "${cor[5]} Host/IP-Address : ${cor[4]}$IP"
    echo -e "${cor[5]} USUARIO : ${cor[4]}$login"
    echo -e "${cor[5]} SENHA   : ${cor[4]}$pass"
    echo -e "${cor[5]} LIMITE  : ${cor[4]}$limite"
    echo -e "${cor[5]} VALIDEZ : ${cor[4]}$datexp"
    msg -bar3
}

mostrar_cuenta_hwid() {
    local nombre="$1"
    local hwid="$2"
    local dias="$3"
    local datexp
    datexp="$(fecha_mostrar "$dias")"

    msg -bar3
    echo -e "${cor[5]} * Puertas Activas en su Servidor *"
    msg -bar3
    ports_
    msg -bar3
    echo -e "${cor[5]} Host/IP-Address : ${cor[4]}$IP"
    echo -e "${cor[5]} USUARIO : ${cor[4]}$nombre"
    echo -e "${cor[5]} HWID    : ${cor[4]}$hwid"
    echo -e "${cor[5]} VALIDEZ : ${cor[4]}$datexp"
    msg -bar3
}

mostrar_cuenta_token() {
    local nombre="$1"
    local token="$2"
    local dias="$3"
    local pass_token="$4"
    local datexp
    datexp="$(fecha_mostrar "$dias")"

    msg -bar3
    echo -e "${cor[5]} * Puertas Activas en su Servidor *"
    msg -bar3
    ports_
    msg -bar3
    echo -e "${cor[5]} Host/IP-Address : ${cor[4]}$IP"
    echo -e "${cor[5]} USUARIO : ${cor[4]}$nombre"
    echo -e "${cor[5]} TOKEN   : ${cor[4]}$token"
    echo -e "${cor[5]} PASS TK : ${cor[4]}$pass_token"
    echo -e "${cor[5]} VALIDEZ : ${cor[4]}$datexp"
    msg -bar3
}

crear_demo_original() {
    header
    msg -bar3
    print_center -azu "SSH|DROPBEAR (DEMO)"
    msg -bar3

    local login pass dias limite
    login="demo$(tr -dc '0-9' </dev/urandom | head -c 3)"
    pass="1234"
    dias="1"
    limite="1"

    if crear_usuario_base "$login" "$pass" "$dias" "$limite" "$login"; then
        mostrar_cuenta_normal "$login" "$pass" "$dias" "$limite"
    else
        print_center -verm2 "Error, Usuario no creado"
        msg -bar3
    fi

    read -rp "Presiona ENTER para volver..."
}

crear_normal_original() {
    header
    echo -e "${cor[4]} ❑ MENU DE CREACION DE USUARIOS ❒ "
    msg -bar3

    echo -ne "${cor[5]} > NOMBRE DE"
    read -rp " USUARIO : " name
    [[ -z "$name" ]] && echo -e "${cor[5]} ⚠️ NO REGISTRO NOMBRE, RETORNANDO ⚠️${cor[0]}" && sleep 2 && return

    echo -ne "${cor[5]} > CONTRASEÑA"
    read -rp " : " pass
    [[ -z "$pass" ]] && echo -e "${cor[5]} ⚠️ NO REGISTRO CONTRASEÑA, RETORNANDO ⚠️${cor[0]}" && sleep 2 && return

    echo -ne "${cor[5]} > LIMITE"
    read -rp " : " limit
    [[ -z "$limit" ]] && limit="1"

    echo -ne "${cor[5]} > VALIDEZ"
    read -rp " : " daysrnf
    [[ -z "$daysrnf" ]] && daysrnf="2"

    local d_reg=$((daysrnf + 1))

    if crear_usuario_base "$name" "$pass" "$d_reg" "$limit" "$name"; then
        mostrar_cuenta_normal "$name" "$pass" "$daysrnf" "$limit"
    else
        print_center -verm2 "Error, Usuario no creado"
        msg -bar3
    fi

    read -rp "Presiona ENTER para volver..."
}

crear_hwid_original() {
    [[ ! -e /bin/ejecutar/limFIX ]] && {
        header
        echo -e "${cor[5]} ⚠️ ATENCION ANTES DE CONTINUAR ⚠️${cor[0]}"
        echo
        echo -e "  OPCIONAL DEFINE UN LIMITE DE RECONEXIONES"
        echo -e " ESPECIALES PARA APPS O METODOS INESTABLES!!"
        echo -e " SINO ENTIENDES LA FUNCION, PRESIONA ENTER!!"
        echo
        msg -bar3
        echo -ne "${cor[5]} ⎚ DEFINE TU "
        read -rp " LIMITE : " _limTP
        [[ -z "$_limTP" ]] && _limTP="2"
        echo "$_limTP" > /bin/ejecutar/limFIX
    }

    header
    echo -ne "${cor[5]} ⎚ NOMBRE DE"
    read -rp " USUARIO : " name
    [[ -z "$name" ]] && echo -e "${cor[5]} ⚠️ NO REGISTRO NOMBRE, RETORNANDO ⚠️${cor[0]}" && sleep 2 && return

    msg -bar3
    echo -e "${cor[5]} INGRESA HWID PARA $name"
    read -rp " HWID: " hwid

    [[ -z "$hwid" ]] && echo " ⚠️ No se Ingreso HWID , RETORNANDO! ⚠️" && sleep 2 && return

    if id "$hwid" >/dev/null 2>&1; then
        echo -e "${cor[5]} ⚠️ HWID YA EXISTE, REGISTRE OTRO ⚠️${cor[0]}"
        sleep 2
        return
    fi

    msg -bar3
    echo -e "${cor[5]} TIEMPO DE DURACION EN DIAS PARA $name"
    read -rp " VALIDEZ : " daysrnf
    [[ -z "$daysrnf" ]] && daysrnf="2"

    local d_reg=$((daysrnf + 1))

    if crear_usuario_base "$hwid" "$hwid" "$d_reg" "HWID" "$name"; then
        mostrar_cuenta_hwid "$name" "$hwid" "$daysrnf"
    else
        print_center -verm2 "Error, Usuario no creado"
        msg -bar3
    fi

    read -rp "Presiona ENTER para volver..."
}

crear_token_original() {
    [[ ! -e /bin/ejecutar/token ]] && {
        header
        echo -e "${cor[5]} ⚠️ ATENCION ANTES DE CONTINUAR ⚠️${cor[0]}"
        echo
        echo -e "  SE DEFINIRA SU CONTRASEÑA TOKEN UNICA"
        echo -e " UNA VEZ COLOCADA NO PODRA SER MANIPULADA"
        echo
        msg -bar3
        echo -ne "${cor[5]} ⎚ CONTRASEÑA "
        read -rp "TOKEN : " passtok
        [[ -z "$passtok" ]] && passtok="DarkZsaidPlus"
        echo "$passtok" > /bin/ejecutar/token
    }

    [[ ! -e /bin/ejecutar/limFIX ]] && {
        header
        echo -e "${cor[5]} ⚠️ ATENCION ANTES DE CONTINUAR ⚠️${cor[0]}"
        echo
        echo -e "  OPCIONAL DEFINE UN LIMITE DE RECONEXIONES"
        echo -e " ESPECIALES PARA APPS O METODOS INESTABLES!!"
        echo -e " SINO ENTIENDES LA FUNCION, PRESIONA ENTER!!"
        echo
        msg -bar3
        echo -ne "${cor[5]} ⎚ DEFINE TU "
        read -rp " LIMITE : " _limTP
        [[ -z "$_limTP" ]] && _limTP="1"
        echo "$_limTP" > /bin/ejecutar/limFIX
    }

    header
    echo -ne "${cor[5]} ⎚ NOMBRE DE"
    read -rp " USUARIO : " name
    [[ -z "$name" ]] && echo -e "${cor[5]} ⚠️ NO REGISTRO NOMBRE, RETORNANDO ⚠️${cor[0]}" && sleep 2 && return

    msg -bar3
    echo -e "${cor[5]} INGRESA TOKEN PARA $name"
    read -rp " TOKEN: " token

    [[ -z "$token" ]] && echo " ⚠️ No se Ingreso TOKEN , RETORNANDO! ⚠️" && sleep 2 && return

    if id "$token" >/dev/null 2>&1; then
        echo -e "${cor[5]} ⚠️ TOKEN YA EXISTE, REGISTRE OTRO ⚠️${cor[0]}"
        sleep 2
        return
    fi

    msg -bar3
    echo -e "${cor[5]} TIEMPO DE DURACION EN DIAS PARA $name"
    read -rp " VALIDEZ : " daysrnf
    [[ -z "$daysrnf" ]] && daysrnf="2"

    passTOKEN="$(cat /bin/ejecutar/token 2>/dev/null)"
    [[ -z "$passTOKEN" ]] && passTOKEN="DarkZsaidPlus"

    local d_reg=$((daysrnf + 1))

    if crear_usuario_base "$token" "$passTOKEN" "$d_reg" "TOKEN" "$name"; then
        mostrar_cuenta_token "$name" "$token" "$daysrnf" "$passTOKEN"
    else
        echo -e "${cor[5]} ⚠️ ERROR AL REGISTRAR SU TOKEN | REINTENTE ⚠️${cor[0]}"
        msg -bar3
    fi

    read -rp "Presiona ENTER para volver..."
}

modificar_pass_token_original() {
    mkdir -p /bin/ejecutar
    [[ ! -e /bin/ejecutar/token ]] && touch /bin/ejecutar/token

    header
    echo -e "${cor[5]} ⚠️ CLAVE ACTUAL : $(cat /bin/ejecutar/token) ⚠️${cor[0]}"
    msg -bar3
    echo -e "${cor[5]} ⚠️ ATENCION ANTES DE CONTINUAR ⚠️${cor[0]}"
    echo
    echo -e "   SE DEFINIRA SU CONTRASEÑA TOKEN UNICA"
    echo -e " UNA VEZ COLOCADA SE RECOMIENDA NO CAMBIARLA"
    echo
    msg -bar3
    echo -ne "${cor[5]} ⎚ CONTRASEÑA "
    read -rp "TOKEN : " passtok

    [[ -z "$passtok" ]] && echo -e "${cor[5]} ⚠️ NO INGRESO CONTRASEÑA ⚠️${cor[0]}" && sleep 2 && return

    echo "$passtok" > /bin/ejecutar/token
    echo -e "${cor[5]} ⚠️ CLAVE TOKEN ACTUALIZADA ⚠️${cor[0]}"
    msg -bar3
    sleep 2
}

while true; do
    header
    msg -bar3
    echo -e " \033[0;50m       ⚜️   CREADOR DE CUENTAS TIPO  ⚜️ "
    msg -bar3
    echo -e " \033[0;35m[\033[0;32m01\033[0;35m] \033[0;33m >\033[0;33m SSH|DROPBEAR (DEMO) "
    echo -e " \033[0;35m[\033[0;32m02\033[0;35m] \033[0;33m >\033[0;33m SSH|DROPBEAR "
    echo -e " \033[0;35m[\033[0;32m03\033[0;35m] \033[0;33m >\033[0;33m HWID         "
    echo -e " \033[0;35m[\033[0;32m04\033[0;35m] \033[0;33m >\033[0;31m TOKEN "
    msg -bar3
    echo -e " \033[0;35m[\033[0;32m05\033[0;35m] \033[0;33m >\033[0;31m MODIFICAR CONTRASEÑA TOKEN "
    msg -bar3
    echo -e " \033[0;35m[\033[1;32m00\033[0;35m] \033[0;33m ⇦ \033[1;37m\e[3;33m[ VOLVER ]\e[0m"
    msg -bar3

    selection=$(selection_fun 5)

    case "$selection" in
        0) break ;;
        1) crear_demo_original ;;
        2) crear_normal_original ;;
        3) crear_hwid_original ;;
        4) crear_token_original ;;
        5) modificar_pass_token_original ;;
    esac
done
