#!/bin/bash

CONF="/etc/darkzsaid/bot/bot.conf"
USERDIR="/etc/adm-lite/userDIR"
OFFSET_FILE="/etc/darkzsaid/bot/offset"
REGISTER_LOG="/etc/adm-lite/registerBOT.log"

mkdir -p /etc/darkzsaid/bot "$USERDIR" /etc/adm-lite /bin/ejecutar

[[ -f "$CONF" ]] && source "$CONF"

TOKEN="${BOT_TOKEN}"
ADMIN_ID="${ADMIN_ID}"

api_get() {
    curl -s "https://api.telegram.org/bot${TOKEN}/$1"
}

api_post() {
    local method="$1"
    shift
    curl -s -X POST "https://api.telegram.org/bot${TOKEN}/${method}" "$@" >/dev/null
}

send_msg() {
    local chat="$1"
    local text="$2"

    api_post sendMessage \
        -d chat_id="$chat" \
        -d parse_mode="HTML" \
        --data-urlencode text="$text"
}

is_admin() {
    local chat="$1"

    [[ -z "$ADMIN_ID" ]] && return 0
    [[ "$chat" = "$ADMIN_ID" ]]
}

ip_vps() {
    hostname -I 2>/dev/null | awk '{print $1}'
}

fecha_exp() {
    local dias="$1"
    date '+%Y-%m-%d' -d " +$dias days"
}

fecha_show() {
    local dias="$1"
    date '+%d/%m/%Y' -d " +$dias days"
}

dias_restantes() {
    local user="$1"
    local data_user data_user_sec data_sec diff dias

    data_sec=$(date +%s)
    data_user=$(chage -l "$user" 2>/dev/null | grep -i "Account expires" | awk -F ":" '{print $2}' | xargs)

    if [[ -z "$data_user" || "$data_user" = "never" ]]; then
        echo "Null"
        return
    fi

    data_user_sec=$(date +%s --date="$data_user" 2>/dev/null)
    [[ -z "$data_user_sec" ]] && echo "Null" && return

    diff=$((data_user_sec - data_sec))
    dias=$((diff / 86400))

    if [[ "$dias" -lt 0 ]]; then
        echo "CADUCADO"
    else
        echo "$dias"
    fi
}

crear_usuario_linux() {
    local user="$1"
    local pass="$2"
    local dias="$3"
    local limite="$4"
    local visible="$5"

    [[ -z "$visible" ]] && visible="$user"

    local valid
    valid="$(fecha_exp "$dias")"

    if id "$user" >/dev/null 2>&1; then
        return 2
    fi

    useradd -M -s /bin/false -e "$valid" -c "$limite,$visible" "$user" 2>/dev/null || return 1
    echo "$user:$pass" | chpasswd 2>/dev/null || {
        userdel "$user" 2>/dev/null
        return 1
    }

    {
        echo "senha: $visible"
        echo "limite: $limite"
        echo "data: $valid"
        echo "pass: $pass"
    } > "$USERDIR/$user"

    return 0
}

registrar_reseller() {
    local chat="$1"
    local user="$2"

    grep -q "^${chat}|${user}$" "$REGISTER_LOG" 2>/dev/null || echo "${chat}|${user}" >> "$REGISTER_LOG"
}

menu_start() {
    local chat="$1"
    local tipo=" BIENVENIDO ADMIN RESELLER"

    [[ "$chat" = "$ADMIN_ID" || -z "$ADMIN_ID" ]] && tipo="� BIENVENIDO SUPER ADMIN PREMIUM"

    send_msg "$chat" "<b>${tipo}</b>

<b>COMANDOS DISPONIBLES</b>

� /agregar     •➝ <i>Agregar usuario SSH</i>
• /token       ➝ <i>Agregar usuario TOKEN</i>
• /hwid        ➝ <i>Agregar usuario HWID</i>

• /usuarios    ➝ <i>Lista de usuarios</i>
• /conectados  ➝ <i>Usuarios conectados</i>
• /usconnect   ➝ <i>Usuarios conectados reseller</i>

• /renovar     ➝ <i>Renovación directa</i>
• /renovarM    ➝ <i>Renovación + días ➕</i>
• /renovarQ    ➝ <i>Renovación - días ➖</i>

• /backup      ➝ <i>Generar Respaldo de Clientes</i>
• /restore     ➝ <i>Restaurar Clientes Externos</i>

<b>FORMATOS:</b>
<code>/agregar user clave dias limite</code>
<code>/token nombre token dias</code>
<code>/hwid nombre codigo_hwid dias</code>
<code>/renovar user dias</code>"
}

cmd_agregar() {
    local chat="$1"
    local name="$2"
    local pass="$3"
    local dias="$4"
    local limit="$5"

    if [[ -z "$name" || -z "$pass" || -z "$dias" || -z "$limit" ]]; then
        send_msg "$chat" "DEBES ENVIAR EL COMANDO
<code>/agregar Nombre_User Clave Tiempo Limite</code>

Ejemplo:
<code>/agregar steven 1234 30 2</code>"
        return
    fi

    crear_usuario_linux "$name" "$pass" "$dias" "$limit" "$name"
    r=$?

    if [[ "$r" = "2" ]]; then
        send_msg "$chat" "❌ USUARIO YA EXISTE: <code>$name</code>"
        return
    elif [[ "$r" != "0" ]]; then
        send_msg "$chat" "❌ Error, Usuario no creado"
        return
    fi

    registrar_reseller "$chat" "$name"

    ip="$(ip_vps)"
    datexp="$(fecha_show "$dias")"

    msg="<b>✅ USUARIO SSH CREADO</b>

HOST/IP : <code>${ip}</code>
USUARIO : <code>${name}</code>
SENHA   : <code>${pass}</code>
LIMITE  : <code>${limit}</code>
VALIDEZ : <code>${datexp}</code>
DIAS    : <code>${dias}</code>"

    [[ -e /etc/adm-lite/slow/dnsi/server.pub ]] && msg+="
KEY PUBLIC : <code>$(cat /etc/adm-lite/slow/dnsi/server.pub)</code>"

    send_msg "$chat" "$msg"
}

cmd_token() {
    local chat="$1"
    local nombre="$2"
    local token_user="$3"
    local dias="$4"

    if [[ -z "$nombre" || -z "$token_user" ]]; then
        send_msg "$chat" "DEBES ENVIAR EL COMANDO
<code>/token Nombre_User token dias</code>

Ejemplo:
<code>/token User123 c2e4ad4y9gcsbs 30</code>"
        return
    fi

    [[ -z "$dias" ]] && dias="30"

    [[ -e /bin/ejecutar/token ]] && passTOKEN="$(cat /bin/ejecutar/token)" || passTOKEN="DarkZsaidPlus"

    crear_usuario_linux "$token_user" "$passTOKEN" "$dias" "TOKEN" "$nombre"
    r=$?

    if [[ "$r" = "2" ]]; then
        send_msg "$chat" "❌ TOKEN YA EXISTE: <code>$token_user</code>"
        return
    elif [[ "$r" != "0" ]]; then
        send_msg "$chat" "❌ Error, Token no creado"
        return
    fi

    registrar_reseller "$chat" "$token_user"

    ip="$(ip_vps)"
    datexp="$(fecha_show "$dias")"

    msg="<b>✅ USUARIO TOKEN CREADO</b>

HOST/IP : <code>${ip}</code>
USUARIO : <code>${nombre}</code>
TOKEN   : <code>${token_user}</code>
PASS TK : <code>${passTOKEN}</code>
VALIDEZ : <code>${datexp}</code>
DIAS    : <code>${dias}</code>"

    [[ -e /etc/adm-lite/slow/dnsi/server.pub ]] && msg+="
KEY PUBLIC : <code>$(cat /etc/adm-lite/slow/dnsi/server.pub)</code>"

    send_msg "$chat" "$msg"
}

cmd_hwid() {
    local chat="$1"
    local nombre="$2"
    local hwid="$3"
    local dias="$4"

    if [[ -z "$nombre" || -z "$hwid" ]]; then
        send_msg "$chat" "DEBES ENVIAR EL COMANDO
<code>/hwid Nombre_User codigo_hwid dias</code>

Ejemplo:
<code>/hwid User123 c2e4ad4y9gcsbs 30</code>"
        return
    fi

    [[ -z "$dias" ]] && dias="30"

    crear_usuario_linux "$hwid" "$hwid" "$dias" "HWID" "$nombre"
    r=$?

    if [[ "$r" = "2" ]]; then
        send_msg "$chat" "❌ HWID YA EXISTE: <code>$hwid</code>"
        return
    elif [[ "$r" != "0" ]]; then
        send_msg "$chat" "❌ Error, HWID no creado"
        return
    fi

    registrar_reseller "$chat" "$hwid"

    ip="$(ip_vps)"
    datexp="$(fecha_show "$dias")"

    msg="<b>✅ USUARIO HWID CREADO</b>

HOST/IP : <code>${ip}</code>
USUARIO : <code>${nombre}</code>
HWID    : <code>${hwid}</code>
VALIDEZ : <code>${datexp}</code>
DIAS    : <code>${dias}</code>"

    [[ -e /etc/adm-lite/slow/dnsi/server.pub ]] && msg+="
KEY PUBLIC : <code>$(cat /etc/adm-lite/slow/dnsi/server.pub)</code>"

    send_msg "$chat" "$msg"
}

cmd_usuarios() {
    local chat="$1"
    local texto="<b> USUARIOS REGISTRADOS</b>

<code>Usuario|Senha|Limite|Dias</code>
"

    if ! ls "$USERDIR"/* >/dev/null 2>&1; then
        send_msg "$chat" "No hay usuarios registrados."
        return
    fi

    for f in "$USERDIR"/*; do
        namer="$(basename "$f")"
        sen="$(grep -i '^senha:' "$f" | awk '{print $2}')"
        limit="$(grep -i '^limite:' "$f" | awk '{print $2}')"
        dias="$(dias_restantes "$namer")"

        [[ "$limit" = "HWID" || "$limit" = "TOKEN" ]] && {
            sen="$namer"
            namer="$(grep -i '^senha:' "$f" | awk '{print $2}')"
        }

        texto+="${namer}|${sen}|${limit}|${dias}
"
    done

    send_msg "$chat" "$texto"
}

cmd_conectados() {
    local chat="$1"
    local texto="<b>FUNCION CONECTADOS</b>

"
    local total=0

    for f in "$USERDIR"/*; do
        [[ -f "$f" ]] || continue
        user="$(basename "$f")"

        ssh_open=$(pgrep -u "$user" -f "sshd: $user" | wc -l)
        ssh_drop=0
        ssh_ovpn=0

        [[ -e /etc/default/dropbear ]] && ssh_drop=$(ps aux | grep -i dropbear | grep "$user" | grep -v grep | wc -l)
        [[ -e /etc/openvpn/openvpn-status.log ]] && ssh_ovpn=$(grep -w "$user" /etc/openvpn/openvpn-status.log 2>/dev/null | wc -l)

        user_pid=$((ssh_open + ssh_drop + ssh_ovpn))

        if [[ "$user_pid" -gt 0 ]]; then
            texto+="� <code>${user}</code> •➝ ${user_pid} conexiones
"
            total=$((total + user_pid))
        fi
    done

    texto+="
<b>TOTAL ONLINE:</b> <code>${total}</code>"

    send_msg "$chat" "$texto"
}

cmd_renovar() {
    local chat="$1"
    local user="$2"
    local dias="$3"

    if [[ -z "$user" || -z "$dias" ]]; then
        send_msg "$chat" "RENOVACION CON REINICIO DE DIAS

DEBES ENVIAR EL COMANDO
<code>/renovar Nombre_User dias</code>

Ejemplo:
<code>/renovar user123 30</code>"
        return
    fi

    if ! id "$user" >/dev/null 2>&1; then
        send_msg "$chat" "❌ Usuario no existe: <code>$user</code>"
        return
    fi

    valid="$(fecha_exp "$dias")"

    chage -E "$valid" "$user" 2>/dev/null
    usermod -e "$valid" "$user" 2>/dev/null

    [[ -f "$USERDIR/$user" ]] && sed -i "s|^data:.*|data: $valid|" "$USERDIR/$user"

    limit="$(grep -i '^limite:' "$USERDIR/$user" 2>/dev/null | awk '{print $2}')"
    [[ -z "$limit" ]] && limit="null"

    send_msg "$chat" "✅ CLIENTE RENOVADO CON ${dias} DIAS

USUARIO : <code>$user</code>
CADUCA  : <code>$valid</code>
LIMITE  : <code>$limit</code>"
}

cmd_renovarM() {
    local chat="$1"
    local user="$2"
    local dias_add="$3"

    if [[ -z "$user" || -z "$dias_add" ]]; then
        send_msg "$chat" "RENOVACION CON DIAS ACUMULATIVOS

DEBES ENVIAR EL COMANDO
<code>/renovarM Nombre_User dias</code>"
        return
    fi

    actual="$(dias_restantes "$user")"
    [[ "$actual" = "CADUCADO" || "$actual" = "Null" ]] && actual=0

    nuevo=$((actual + dias_add))
    cmd_renovar "$chat" "$user" "$nuevo"
}

cmd_renovarQ() {
    local chat="$1"
    local user="$2"
    local dias_quitar="$3"

    if [[ -z "$user" || -z "$dias_quitar" ]]; then
        send_msg "$chat" "RENOVACION CON PRORRATEO DE DIAS ( ➖ )

DEBES ENVIAR EL COMANDO
<code>/renovarQ Nombre_User dias</code>"
        return
    fi

    actual="$(dias_restantes "$user")"
    [[ "$actual" = "CADUCADO" || "$actual" = "Null" ]] && actual=0

    if [[ "$dias_quitar" -gt "$actual" ]]; then
        send_msg "$chat" "LOS DIAS SON MAYOR AL TIEMPO RESTANTE !!!"
        return
    fi

    nuevo=$((actual - dias_quitar))
    cmd_renovar "$chat" "$user" "$nuevo"
}

cmd_backup() {
    local chat="$1"
    local file="/var/www/html/backup_usuarios.txt"

    mkdir -p /var/www/html

    : > "$file"

    [[ -e /bin/ejecutar/token ]] && passTK="$(cat /bin/ejecutar/token)" || passTK="DarkZsaidPlus"

    for user in $(cat /etc/passwd | grep 'home' | grep 'false' | grep -v 'syslog' | cut -d: -f1 | sort); do
        if [[ -f "$USERDIR/$user" ]]; then
            pass="$(grep -i '^senha:' "$USERDIR/$user" | awk '{print $2}')"
            limite="$(grep -i '^limite:' "$USERDIR/$user" | awk '{print $2}')"
            NameTKID="$pass"
        else
            limite="$(grep -w "$user" /etc/passwd | awk -F ':' '{split($5, a, ","); print a[1]}')"
            NameTKID="$(grep -w "$user" /etc/passwd | awk -F ':' '{split($5, a, ","); print a[2]}')"
        fi

        [[ -z "$limite" ]] && limite="5"
        sl="$(dias_restantes "$user")"
        [[ "$sl" = "CADUCADO" || "$sl" = "Null" ]] && sl="1"

        if [[ "$limite" = "HWID" ]]; then
            echo "$user:$user:HWID:$sl:$NameTKID" >> "$file"
        elif [[ "$limite" = "TOKEN" ]]; then
            echo "$user:$passTK:TOKEN:$sl:$NameTKID" >> "$file"
        else
            echo "$user:$NameTKID:$limite:$sl:$NameTKID" >> "$file"
        fi
    done

    ipserver="$(ip_vps)"
    portFTP="80"

    send_msg "$chat" " Link de Descarga:
<code>http://${ipserver}:${portFTP}/backup_usuarios.txt</code>"
}

cmd_restore() {
    local chat="$1"
    local url="$2"

    if [[ -z "$url" ]]; then
        send_msg "$chat" "�⚠️ Debes enviar el enlace del fichero de backup.

Ejemplo:
<code>/restore http://mi-servidor/backup.txt</code>"
        return
    fi

    tmp="/tmp/darkzsaid_restore_bot.txt"

    wget -q -O "$tmp" "$url" || {
        send_msg "$chat" "❌ No se pudo descargar el archivo desde: $url"
        return
    }

    while IFS=: read -r USER CLAVE LIMITE DIAS NameTKID; do
        [[ -z "$USER" ]] && continue
        crear_usuario_linux "$USER" "$CLAVE" "$DIAS" "$LIMITE" "$NameTKID"
    done < "$tmp"

    rm -f "$tmp"

    send_msg "$chat" "✅ Restauración completada."
}

handle_cmd() {
    local chat="$1"
    local text="$2"

    cmd="$(echo "$text" | awk '{print $1}')"
    a1="$(echo "$text" | awk '{print $2}')"
    a2="$(echo "$text" | awk '{print $3}')"
    a3="$(echo "$text" | awk '{print $4}')"
    a4="$(echo "$text" | awk '{print $5}')"

    case "$cmd" in
        /start|/menu) menu_start "$chat" ;;
        /agregar) cmd_agregar "$chat" "$a1" "$a2" "$a3" "$a4" ;;
        /token) cmd_token "$chat" "$a1" "$a2" "$a3" ;;
        /hwid) cmd_hwid "$chat" "$a1" "$a2" "$a3" ;;
        /usuarios) cmd_usuarios "$chat" ;;
        /conectados|/usconnect) cmd_conectados "$chat" ;;
        /renovar) cmd_renovar "$chat" "$a1" "$a2" ;;
        /renovarM) cmd_renovarM "$chat" "$a1" "$a2" ;;
        /renovarQ) cmd_renovarQ "$chat" "$a1" "$a2" ;;
        /backup) cmd_backup "$chat" ;;
        /restore) cmd_restore "$chat" "$a1" ;;
        *) send_msg "$chat" "COMANDO NO RECONOCIDO, TOCA /start" ;;
    esac
}

main_loop() {
    [[ -z "$TOKEN" ]] && exit 1

    offset="$(cat "$OFFSET_FILE" 2>/dev/null)"
    [[ -z "$offset" ]] && offset=0

    while true; do
        updates="$(api_get "getUpdates?timeout=30&offset=$offset")"

        ids="$(echo "$updates" | grep -o '"update_id":[0-9]*' | cut -d: -f2)"

        for update_id in $ids; do
            block="$(echo "$updates" | tr '{' '\n' | grep "\"update_id\":$update_id" -A30)"
            chat="$(echo "$block" | grep -o '"chat":{"id":[0-9-]*' | grep -o '[0-9-]*$' | head -1)"
            text="$(echo "$block" | grep -o '"text":"[^"]*"' | head -1 | sed 's/"text":"//;s/"$//')"

            offset=$((update_id + 1))
            echo "$offset" > "$OFFSET_FILE"

            [[ -z "$chat" || -z "$text" ]] && continue

            if ! is_admin "$chat"; then
                send_msg "$chat" "CONTACTA AL CREADOR DEL BOT"
                continue
            fi

            handle_cmd "$chat" "$text"
        done

        sleep 2
    done
}

main_loop
