#!/bin/bash

pantalla_limpia() {
    printf '\033c'
}


limpiar_pantalla() {
    printf '\033[H\033[2J\033[3J'
}


source /opt/darkzsaid/lib/estilo_original.sh
shopt -s extglob

BANNER="/etc/bannerssh"
TMP_BANNER="/bin/ejecutar/bannerssh"
SSHD_CONFIG="/etc/ssh/sshd_config"

mkdir -p /bin/ejecutar

restart_ssh_dropbear() {
    msg -bar3

    echo -ne " \033[1;31m[ ! ] VERIFICANDO DROPBEAR "
    if [[ -d /etc/dropbear ]]; then
        [[ -e "$BANNER" ]] && cat "$BANNER" > /etc/dropbear/banner
        service dropbear restart >/dev/null 2>&1 || systemctl restart dropbear >/dev/null 2>&1
        if [[ "$?" = "0" ]]; then
            echo -e "\033[1;32m [OK]"
        else
            echo -e "\033[1;31m - BANNER INCOMPATIBLE CON DROPBEAR -"
            echo "" > /etc/dropbear/banner
            service dropbear restart >/dev/null 2>&1 || systemctl restart dropbear >/dev/null 2>&1
        fi
    else
        echo -e "\033[0;35m [ NO EXISTE DROPBEAR ]"
    fi

    echo -ne " \033[1;31m[ ! ] VERIFICANDO SSH "
    service ssh restart >/dev/null 2>&1 || service sshd restart >/dev/null 2>&1 || systemctl restart ssh >/dev/null 2>&1 || systemctl restart sshd >/dev/null 2>&1
    if [[ "$?" = "0" ]]; then
        echo -e "\033[1;32m [OK]"
    else
        echo -e "\033[1;31m [FAIL]"
    fi

    sleep 1
}

asegurar_banner_ssh() {
    if [[ -f "$SSHD_CONFIG" ]]; then
        chk=$(grep "^Banner " "$SSHD_CONFIG" 2>/dev/null | grep -v "#Banner")
        if [[ -z "$chk" ]]; then
            echo "Banner $BANNER" >> "$SSHD_CONFIG"
        else
            sed -i "s|^Banner .*|Banner $BANNER|" "$SSHD_CONFIG"
        fi
    fi
}

banner_personalizado() {
    limpiar_pantalla
    local="/etc/bannerssh"

    msg -bar3
    echo -e "\033[1;37m - BANNER CUSTOM EDITABLE -  \033[0m"
    msg -bar3
    echo -e "\033[1;37mSeleccione su Sistema:    Para Salir Ctrl + C o 0 Para Regresar\033[1;33m"
    echo -e " \033[1;31m[ !!! ]\033[1;33m PEGA AQUI TU BANNER"
    msg -bar3
    echo -e " \033[1;31mLuego de Pegar tu banner Presiona Ctrl + O y Enter"
    echo -e " \033[1;31m          Por Ultimo Ctrl + X"
    echo -ne "\033[1;37m"
    read -rp " Presiona Enter para Continuar "

    killall apt-get apt >/dev/null 2>&1
    if ! command -v nano >/dev/null 2>&1; then
        apt-get update -y >/dev/null 2>&1
        apt-get install nano -y >/dev/null 2>&1
    fi

    touch "$TMP_BANNER"
    nano "$TMP_BANNER"

    if [[ -z "$(cat "$TMP_BANNER" 2>/dev/null)" ]]; then
        echo -e " INFORMACION TEXTUAL INVALIDA "
    else
        cat "$TMP_BANNER" > "$BANNER"
        asegurar_banner_ssh
    fi

    rm -f "$TMP_BANNER"
    restart_ssh_dropbear
}

agregar_mensaje_banner() {
    unset x
    unset ban_ner2
    unset ban_ner2_cor

    msg -bar3
    echo -e "\n\033[1;31m[\033[1;36m01\033[1;31m]\033[1;33m Letra Pequeña"
    echo -e "\033[1;31m[\033[1;36m02\033[1;31m]\033[1;33m Letra Media"
    echo -e "\033[1;31m[\033[1;36m03\033[1;31m]\033[1;33m Letra Grande"
    echo -e "\033[1;31m[\033[1;36m04\033[1;31m]\033[1;33m Letra ExtraGrande"
    echo ""
    echo -ne "\033[1;32mEscoje el Tamaño de Letra\033[1;31m ?\033[1;37m : "
    read -r opc

    if [[ "$opc" = "1" || "$opc" = "01" ]]; then
        _size='6'
    elif [[ "$opc" = "2" || "$opc" = "02" ]]; then
        _size='4'
    elif [[ "$opc" = "3" || "$opc" = "03" ]]; then
        _size='3'
    elif [[ "$opc" = "4" || "$opc" = "04" ]]; then
        _size='1'
    else
        _size='6'
    fi

    msg -bar3
    echo -ne "\033[1;37m"
    read -rp " INGRESA TU MENSAJE : " ban_ner2
    msg -bar3

    echo -e "\033[1;42m Deseas centrar el contenido del banner\033[0;33m  :v"
    echo ""
    echo -ne "\033[0;32m Responde [ s | n ] : "
    read -e -i "s" x

    msg -bar3

    [[ "$x" = @(s|S|y|Y) ]] && echo -e '<p style="text-align: center;">' >> "$BANNER"

    echo -e " \033[1;31m[ 1 ]\033[1;33m > VERDE         \033[1;31m[ 9  ]\033[1;33m > AZUL PIZARRA OSCURO"
    echo -e " \033[1;31m[ 2 ]\033[1;33m > ROJO          \033[1;31m[ 10 ]\033[1;33m > MAGENTA"
    echo -e " \033[1;31m[ 3 ]\033[1;33m > AZUL          \033[1;31m[ 11 ]\033[1;33m > CHOCOLATE"
    echo -e " \033[1;31m[ 4 ]\033[1;33m > AMARILLO      \033[1;31m[ 12 ]\033[1;33m > VERDE CLARO"
    echo -e " \033[1;31m[ 5 ]\033[1;33m > PURPURA       \033[1;31m[ 13 ]\033[1;33m > GRIS"
    echo -e " \033[1;31m[ 6 ]\033[1;33m > Naranja       \033[1;31m[ 14 ]\033[1;33m > VERDE MAR"
    echo -e " \033[1;31m[ 7 ]\033[1;33m > Crema         \033[1;31m[ 15 ]\033[1;33m > CIAN OSCURO"
    echo -e " \033[1;31m[ 8 ]\033[1;33m > Cyano         \033[1;31m[ *  ]\033[1;33m > Negro"
    read -rp " Digite A Cor [ 1 ⇿ 15 ]: " ban_ner2_cor

    case "$ban_ner2_cor" in
        1)  color="green" ;;
        2)  color="red" ;;
        3)  color="blue" ;;
        4)  color="yellow" ;;
        5)  color="purple" ;;
        6)  color="#FF7F00" ;;
        7)  color="#AEB404" ;;
        8)  color="cyan" ;;
        9)  color="#483D8B" ;;
        10) color="#FF00FF" ;;
        11) color="#D2691E" ;;
        12) color="#90EE90" ;;
        13) color="#BEBEBE" ;;
        14) color="#2E8B57" ;;
        15) color="#008B8B" ;;
        *)  color="black" ;;
    esac

    echo "<h${_size}><font color=\"$color\">" >> "$BANNER"
    echo "$ban_ner2" >> "$BANNER"
    echo "</h${_size}></font>" >> "$BANNER"
    [[ "$x" = @(s|S|y|Y) ]] && echo "</p>" >> "$BANNER"

    asegurar_banner_ssh
    restart_ssh_dropbear
}

eliminar_banner() {
    limpiar_pantalla
    msg -bar3
    echo -e "\033[1;37m Verificando existencia de BANNER\033[0m"
    msg -bar3

    if [[ -f "$SSHD_CONFIG" ]]; then
        if grep -q "^Banner" "$SSHD_CONFIG"; then
            sed -i 's/^Banner/#Banner/' "$SSHD_CONFIG"
            echo -e "\033[1;31m DESTRUYENDO BANNER SSH"
        else
            echo -e "\033[1;33m NO EXISTE BANNER SSH ESTRUCTURADO"
        fi
    fi

    if [[ -f /etc/dropbear/banner ]]; then
        echo "" > /etc/dropbear/banner
        echo -e "\033[1;31m DESTRUYENDO BANNER DROPBEAR"
    else
        echo -e "\033[1;33m NO EXISTE BANNER DROPBEAR ESTRUCTURADO"
    fi

    restart_ssh_dropbear
}

checkuser_banner() {
    limpiar_pantalla
    msg -bar3
    print_center -verm2 " BANNER + CHECKUSER CUSTOM"
    msg -bar3
    echo -e "${cor[5]} Esta opción en el original reconstruye SSH/Dropbear"
    echo -e "${cor[5]} y descarga binarios CheckBanner externos."
    echo
    echo -e "${cor[3]} Por seguridad en DarkZsaid la dejaremos como módulo"
    echo -e "${cor[3]} pendiente para hacerlo propio, sin binarios ocultos."
    msg -bar3
    read -rp "Presiona ENTER para volver..."
}

while true; do
    header
    msg -bar3
    echo -e "${cor[2]}MENU BANNER  (RECOMENDADO 2):"
    msg -bar3
    echo -e "\033[0;35m [\033[0;36m01\033[0;35m]\033[0;31m >${cor[3]} Pegar BANNER Personalizado ( html , etc )"
    echo -e "\033[0;35m [\033[0;36m02\033[0;35m]\033[0;31m >${cor[3]} AGREGAR MENSAJES BANNER SSH"
    echo -e "\033[0;35m [\033[0;36m03\033[0;35m]\033[0;31m >${cor[3]} ELIMINAR BANNER ( SSH ⇿ DROPBEAR )"
    echo -e "\033[0;35m [\033[0;36m04\033[0;35m]\033[0;31m >${cor[3]} CheckUser + BANNER \033[0;31m[ $(msg -verm2 'NUEVO') \033[0;31m]"
    msg -bar3
    echo -e " \033[0;35m [\033[0;36m0\033[0;35m]\033[0;31m > $(msg -bra "\033[1;41m[ REGRESAR ]\e[0m")"
    msg -bar3

    selection=$(selection_fun 4)

    case "$selection" in
        0) break ;;
        1)
            limpiar_pantalla
            echo -e " Al escojer que coloques tu Banner creado fuera del Script, ADM no se "
            echo -e "    Responsabiliza por el Fallo de ciertos recursos del SISTEMA"
            echo -e "RECUERDA QUE EL SCRIPT ESTA REALIZADO PARA FUNCIONAR CON SUS FUNCIONES"
            echo -e "                          Y esta es EXPERIMENTAL"
            echo -e "Esta SEGURO QUE DESEAS CONTINUAR ?:"
            read -p " [S/N]: " -e -i n sshsn
            [[ "$sshsn" = @(s|S|y|Y) ]] && banner_personalizado
            ;;
        2)
            limpiar_pantalla
            echo -e "${cor[3]} Buena ELECCION, Tienes un 99% mas Garantia"
            echo -e "${cor[3]} Esta SEGURO:"
            read -p " [S/N]: " -e -i s sshsn
            [[ "$sshsn" = @(s|S|y|Y) ]] && agregar_mensaje_banner
            ;;
        3)
            eliminar_banner
            ;;
        4)
            checkuser_banner
            ;;
    esac
done
