#!/bin/bash

source /opt/darkzsaid/lib/estilo_original.sh
source /opt/darkzsaid/lib/usuarios_core.sh 2>/dev/null

USERDIR="/etc/adm-lite/userDIR"
BACKUP_DIR="/root"
WEB_DIR1="/var/www"
WEB_DIR2="/var/www/html"

mkdir -p "$USERDIR"

get_ip_backup() {
    if [[ -f /bin/ejecutar/IPcgh ]]; then
        cat /bin/ejecutar/IPcgh
    else
        hostname -I 2>/dev/null | awk '{print $1}'
    fi
}

get_port_web() {
    local portFTP
    portFTP=$(lsof -V -i tcp -P -n 2>/dev/null | grep -v "ESTABLISHED" | grep -v "COMMAND" | grep "LISTEN" | grep -E "apache2|nginx" | cut -d: -f2 | cut -d' ' -f1 | uniq | head -1)
    [[ -z "$portFTP" ]] && portFTP="80"
    echo "$portFTP"
}

dias_restantes_user() {
    local user="$1"
    local data_user data_user_sec data_sec variavel_soma dias_use

    data_sec=$(date +%s)
    data_user=$(chage -l "$user" 2>/dev/null | grep -i "Account expires" | awk -F ":" '{print $2}' | xargs)

    if [[ -z "$data_user" || "$data_user" = "never" ]]; then
        echo "1"
        return
    fi

    data_user_sec=$(date +%s --date="$data_user" 2>/dev/null)

    if [[ -z "$data_user_sec" ]]; then
        echo "1"
        return
    fi

    variavel_soma=$((data_user_sec - data_sec))
    dias_use=$((variavel_soma / 86400))

    [[ "$dias_use" -le 0 ]] && dias_use=0

    echo $((dias_use + 1))
}

backup_de_usuarios() {
    local IP name bc arquivo_move passTK user pass limite NameTKID data sl

    IP="$(get_ip_backup)"

    clear
    msg -bar3
    print_center -verd '  \e[97m\033[1;41m NOMBRE DE FICHERO WEB FILE\033[0m'
    msg -bar3
    print_center -verm2 ' Este nombre sera el ARCHIVO FINAL \n PARA PODER SER RESTAURDO EN OTRO SERVIDOR \n Recuerda no colocar Espacios, ya que \n tambien sera el nombre del fichero WEB'
    msg -bar3
    print_center -verd ' NO SE RESPALDAN ** OPENVPN FILES **'
    msg -bar3

    echo -e "\033[1;33mINGRESA NOMBRE DEL FICHERO ( UsuarioXYZ ) "
    msg -bar3
    read -rp " Ejemplo: DarkZsaid : " name

    [[ -z "$name" ]] && name="UsuarioXYZ"

    name="$(echo "$name" | tr -cd '[:alnum:]_-')"
    [[ -z "$name" ]] && name="UsuarioXYZ"

    bc="$BACKUP_DIR/$name"
    arquivo_move="$name"

    [[ -e "$bc" ]] && rm -f "$bc"

    clear
    echo -e "\033[1;37mHaciendo Backup de Usuarios...\033[0m"
    msg -bar3

    [[ -e /bin/ejecutar/token ]] && passTK="$(cat /bin/ejecutar/token)" || passTK="DarkZsaidPlus"

    i=1

    for user in $(cat /etc/passwd | grep 'home' | grep 'false' | grep -v 'syslog' | cut -d: -f1 | sort); do
        if [[ -f "$USERDIR/$user" ]]; then
            pass="$(grep -i "^senha:" "$USERDIR/$user" | awk '{print $2}')"
            limite="$(grep -i "^limite:" "$USERDIR/$user" | awk '{print $2}')"
            data="$(grep -i "^data:" "$USERDIR/$user" | awk '{print $2}')"
            NameTKID="$pass"
            echo -e "\033[1;31m [ SCRIPT ] \033[1;37m"
        else
            linea="$(grep -w "$user" /etc/passwd)"
            limite="$(grep -w "$user" /etc/passwd | awk -F ':' '{split($5, a, ","); print a[1]}')"
            NameTKID="$(grep -w "$user" /etc/passwd | awk -F ':' '{split($5, a, ","); print a[2]}')"
            [[ -z "$NameTKID" ]] && NameTKID="$user"
            echo -e "\033[1;31m [ SYSTEM ] \033[1;37m"
        fi

        [[ -z "$limite" ]] && limite="5"
        sl="$(dias_restantes_user "$user")"

        if [[ "$limite" = "HWID" ]]; then
            echo "$user:$user:HWID:$sl:$NameTKID" >> "$bc"
            echo -e "\033[1;37mUser $NameTKID \033[0;35m[\033[0;36m$limite\033[0;35m]\033[0;31m Backup [\033[1;31mOK\033[1;37m] con $sl DIAS\033[0m"
        elif [[ "$limite" = "TOKEN" ]]; then
            echo "$user:$passTK:TOKEN:$sl:$NameTKID" >> "$bc"
            echo -e "\033[1;37mUser $NameTKID \033[0;35m[\033[0;36m$limite\033[0;35m]\033[0;31m Backup [\033[1;31mOK\033[1;37m] con $sl DIAS\033[0m"
        elif [[ "$limite" =~ ^[0-9]+$ ]]; then
            echo "$user:$NameTKID:$limite:$sl:$NameTKID" >> "$bc"
            echo -e "\033[1;37mUser $user \033[0;35m[\033[0;36mSSH\033[0;35m]\033[0;31m Backup [\033[1;31mOK\033[1;37m] con $sl DIAS\033[0m"
        else
            echo "$user:$NameTKID:5:$sl:$NameTKID" >> "$bc"
            echo -e "\033[1;37mUser $user \033[0;35m[\033[0;36mSSH\033[0;35m]\033[0;31m Backup [\033[1;31mOK\033[1;37m] con $sl DIAS\033[0m"
        fi

        i=$((i + 1))
    done

    msg -bar3
    echo -e "\033[1;31mBackup Completado !!!\033[0m"
    echo
    echo -e "\033[1;37mLos usuarios $i se encuentra en el archivo \033[1;31m $bc \033[1;37m"
    msg -bar3
    print_center -verm2 ' NOTA IMPORTANTE !!!\n RECUERDA RESPALDAR ESTE FICHERO!'
    msg -bar3
    print_center -verd ' Si esta usando maquina, Montalo Online\n Para luego usar el Link del Fichero, y puedas .\nDescargarlo desde cualquier sitio con acceso WEB\n  Ejemplo : http://ip-del-vps:portFTP/tu-fichero '
    msg -bar3

    read -rp " PRESIONA ENTER PARA CARGAR ONLINE"

    removeonline "$arquivo_move"
}

removeonline() {
    local arquivo_move="$1"

    [[ -z "$arquivo_move" ]] && return

    [[ -d "$WEB_DIR2" && -e "$WEB_DIR2/$arquivo_move" ]] && rm -f "$WEB_DIR2/$arquivo_move" >/dev/null 2>&1
    [[ -d "$WEB_DIR1" && -e "$WEB_DIR1/$arquivo_move" ]] && rm -f "$WEB_DIR1/$arquivo_move" >/dev/null 2>&1

    print_center -verd "${cor[5]}Extraxion Exitosa"
    msg -bar3
    print_center -verd "SUBIENDO"
    subironline "$arquivo_move"
}

subironline() {
    local arquivo_move="$1"
    local IP portFTP

    mkdir -p "$WEB_DIR1" "$WEB_DIR2"

    [[ ! -e "$WEB_DIR2/index.html" ]] && touch "$WEB_DIR2/index.html"
    [[ ! -e "$WEB_DIR1/index.html" ]] && touch "$WEB_DIR1/index.html"

    chmod -R 755 /var/www 2>/dev/null

    cp "$BACKUP_DIR/$arquivo_move" "$WEB_DIR1/$arquivo_move" 2>/dev/null
    cp "$BACKUP_DIR/$arquivo_move" "$WEB_DIR2/$arquivo_move" 2>/dev/null
    cp "$BACKUP_DIR/$arquivo_move" "$WEB_DIR1/$arquivo_move.html" 2>/dev/null
    cp "$BACKUP_DIR/$arquivo_move" "$WEB_DIR2/$arquivo_move.html" 2>/dev/null

    service apache2 restart >/dev/null 2>&1
    service nginx restart >/dev/null 2>&1

    IP="$(get_ip_backup)"
    portFTP="$(get_port_web)"

    msg -bar3
    print_center -verd "PARA RESTAURAR USA \n\n http://$IP:${portFTP}/$arquivo_move\n\n"
    msg -bar3
    print_center -verm2 "PARA VISUALIZAR EN LA WEB \n\n http://$IP:${portFTP}/$arquivo_move.html\n\n"
    msg -bar3
    print_center -verd "${cor[5]}Carga Exitosa!"
    msg -bar3
    read -rp "PRESIONE ENTER PARA RETORNAR"
}

crear_usuario_restore() {
    local USER="$1"
    local CLAVE="$2"
    local LIMITE="$3"
    local DIAS="$4"
    local NameTKID="$5"
    local valid

    valid=$(date '+%Y-%m-%d' -d " +$DIAS days")

    if id "$USER" >/dev/null 2>&1; then
        echo -e "\033[1;37m\033[1;31m$USER \033[1;37mEXISTE: \033[1;31m${CLAVE}  [\033[1;31mFAILED\033[1;37m]\033[0m"
        return
    fi

    useradd -M -s /bin/false -e "$valid" -c "$LIMITE,$NameTKID" "$USER" 2>/dev/null || {
        echo -e "\033[1;37m\033[1;31m$USER \033[1;37mESTADO  [\033[1;31mFAILED\033[1;37m]\033[0m"
        return
    }

    echo "$USER:$CLAVE" | chpasswd 2>/dev/null

    if [[ "$LIMITE" = "HWID" || "$LIMITE" = "TOKEN" ]]; then
        echo "senha: $NameTKID" > "$USERDIR/$USER"
        echo -e "\033[1;31m$NameTKID \033[1;37mRESTORE: \033[1;31m$LIMITE - \033[1;37m[\033[1;31mOk\033[1;37m] \033[1;37mcon\033[1;31m ${DIAS} \033[1;37m Dias\033[0m"
    else
        echo "senha: ${CLAVE}" > "$USERDIR/$USER"
        echo -e "\033[1;31m$USER \033[1;37mRESTORE: \033[1;31m${CLAVE} - \033[1;37m[\033[1;31mOk\033[1;37m] \033[1;37mcon\033[1;31m ${DIAS} \033[1;37m Dias\033[0m"
    fi

    echo "limite: $LIMITE" >> "$USERDIR/$USER"
    echo "data: $valid" >> "$USERDIR/$USER"
    echo "pass: $CLAVE" >> "$USERDIR/$USER"
}

restaurar_usuarios_online() {
    cd "$HOME" || return

    clear
    msg -bar3
    print_center -verd '  \e[97m\033[1;41m LINK DE FICHERO WEB FILE\033[0m'
    msg -bar3
    print_center -verm2 ' AQUI VA EL ENLACE DEL FICHERO \n PARA PODER SER RESTAURDO PEGALO AQUI \n RECUERDA NO COLOCAR CARACTERES ESPECIALES'
    msg -bar3
    print_center -verd ' NO SE RESTAURAN ** OPENVPN FILES **'
    msg -bar3

    echo -ne "\033[1;33mINGRESA ENLACE DEL FICHERO "
    read -rp " : " url1

    wget -q -O recovery "$url1" && echo -e "\033[1;31m- \033[1;32mFile Exito!" || {
        echo -e "\033[1;31m- \033[1;31mFile Fallo"
        read -rp "ENTER para volver..."
        return
    }

    echo -e "\033[1;37mRestaurando Usuarios...\033[0m"

    [[ -e "$HOME/recovery" ]] && arq="$HOME/recovery" || return

    while IFS=: read -r USER CLAVE LIMITE DIAS NameTKID; do
        [[ -z "$USER" ]] && continue
        crear_usuario_restore "$USER" "$CLAVE" "$LIMITE" "$DIAS" "$NameTKID"
    done < "$arq"

    msg -bar3
    read -rp "PRESIONE ENTER PARA RETORNAR"
}

restaurar_usuarios_local() {
    cd "$HOME" || return

    echo "INGRESE LA RUTA LOCAL DONDE TIENES ALOJADO EL FICHERO "
    echo -e "  EJEMPLO : /root/file.txt "
    read -rp "Pega TU RUTA : " url1

    if [[ -e "$url1" ]]; then
        echo -e " FILE ENCONTRADO \n"
        arq="$url1"
    else
        echo -e " FILE NO FOUND \n"
        read -rp "ENTER para volver..."
        return
    fi

    echo -e "\033[1;37mRestaurando Usuarios de ... $arq\033[0m \n"
    msg -bar3

    while IFS=: read -r USER CLAVE LIMITE DIAS NameTKID; do
        [[ -z "$USER" ]] && continue
        [[ -z "$CLAVE" ]] && CLAVE="$USER"
        crear_usuario_restore "$USER" "$CLAVE" "$LIMITE" "$DIAS" "$NameTKID"
    done < "$arq"

    msg -bar3
    read -rp "PRESIONE ENTER PARA RETORNAR"
}

while true; do
    clear
    header
    print_center -verm2 'ADVERTENCIA!!!\n RECUERDA QUE EL BACKUP DEBE SER ALMACENADO \n FUERA DEL VPS PARA EVITAR PERDIDAS \n UNA VEZ RESTAURADO EL SERVIDOR RECUPERA EL \n FICHERO, SEA ONLINE O LOCAL !'
    msg -bar3
    echo -e "\033[0;35m [${cor[2]}01\033[0;35m]\033[0;33m ${flech}${cor[3]} RESPALDAR USUARIOS   \033[0;31m[ $(msg -verm2 ' ONLINE') \033[0;31m]"
    echo -e "\033[0;35m [${cor[2]}02\033[0;35m]\033[0;33m ${flech}${cor[3]} RESTAURAR USUARIOS   \033[0;31m[ $(msg -verd ' ONLINE') \033[0;31m]"
    echo -e "\033[0;35m [${cor[2]}03\033[0;35m]\033[0;33m ${flech}${cor[3]} RESTAURAR USUARIOS   \033[0;31m[ $(msg -verd ' LOCAL') \033[0;31m]"
    msg -bar3
    echo -e " \033[0;35m [${cor[2]}0\033[0;35m]\033[0;33m ${flech} \033[1;37m\e[3;33m[ REGRESAR ]\e[0m"
    msg -bar3

    read -rp "ECOJE: " option

    case "$option" in
        0|00) break ;;
        1|01) backup_de_usuarios ;;
        2|02) restaurar_usuarios_online ;;
        3|03) restaurar_usuarios_local ;;
    esac
done
