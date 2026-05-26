#!/usr/bin/env python3
import json
import time
import urllib.parse
import urllib.request
from pathlib import Path

CONF = Path("/etc/darkzsaid/bot/bot.conf")

def load_conf():
    data = {}
    if CONF.exists():
        for line in CONF.read_text(errors="ignore").splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            data[k.strip()] = v.strip().strip('"').strip("'")
    return data

conf = load_conf()
TOKEN = conf.get("BOT_TOKEN", "")
ADMIN_ID = conf.get("ADMIN_ID") or conf.get("BOT_LOGIN", "")
BOT_PASS = conf.get("BOT_PASS", "DarkZsaid")

if not TOKEN:
    print("FALTA TOKEN EN /etc/darkzsaid/bot/bot.conf", flush=True)
    while True:
        time.sleep(60)

API = f"https://api.telegram.org/bot{TOKEN}"

def api(method, payload=None):
    try:
        data = urllib.parse.urlencode(payload or {}).encode()
        with urllib.request.urlopen(f"{API}/{method}", data=data, timeout=20) as r:
            return json.loads(r.read().decode())
    except Exception as e:
        print(f"API ERROR {method}: {e}", flush=True)
        return {}

def send(chat_id, text):
    api("sendMessage", {
        "chat_id": chat_id,
        "text": text,
        "parse_mode": "HTML"
    })

def is_admin(chat_id):
    return str(chat_id) == str(ADMIN_ID)


def menu(chat_id):
    send(chat_id, """<b>DARKZSAID BOT SSH</b>
━━━━━━━━━━━━━━━━━━━━
<b>BIENVENIDO SUPER ADMIN PREMIUM</b>
━━━━━━━━━━━━━━━━━━━━

<b>MENU DE ACCIONES RAPIDAS</b>
━━━━━━━━━━━━━━━━━━━━

<b>Usuarios</b>
/agregar     -> Agregar usuario SSH
/token       -> Agregar usuario TOKEN
/hwid        -> Agregar usuario HWID
/demo        -> Crear usuario demo 1 dia
/usreg       -> Lista de usuarios
/usconnect   -> Usuarios conectados
/borrar      -> Eliminar usuario

<b>Renovaciones</b>
/renovar     -> Renovacion directa
/renovarM    -> Renovacion dias +
/renovarQ    -> Renovacion dias -

<b>VPS</b>
/puertos     -> Puertos activos
/infovps     -> Informacion del VPS
/liberados   -> Usuarios liberados

<b>Gestion de Admin</b>
/aggADM      -> Agregar admin
/creditos    -> Autorizar creditos
/admkil      -> Quitar autorizacion

<b>Herramientas Extra</b>
/backup      -> Generar respaldo de clientes
/restore     -> Restaurar clientes externos
/checkuser   -> Link CheckUser

━━━━━━━━━━━━━━━━━━━━
""")

def main():
    print("DarkZsaid Bot iniciado", flush=True)
    offset = 0

    while True:
        res = api("getUpdates", {
            "timeout": 5,
            "offset": offset,
            "allowed_updates": json.dumps(["message"])
        })

        if not res.get("ok"):
            time.sleep(2)
            continue

        for upd in res.get("result", []):
            offset = max(offset, upd.get("update_id", 0) + 1)
            msg = upd.get("message") or {}
            chat = msg.get("chat") or {}
            chat_id = chat.get("id")
            text = (msg.get("text") or "").strip()

            if not chat_id or not text:
                continue

            if text.startswith("/start"):
                menu(chat_id)
            elif text.startswith("/creditos"):
                send(chat_id, f"ID: <code>{chat_id}</code>")
            elif text.startswith("/usuarios"):
                send(chat_id, "Bot activo. La lista de usuarios se gestiona desde el panel.")
            elif text.startswith("/conectados"):
                send(chat_id, "Bot activo. Conectados se revisa desde el panel.")
            elif text.startswith("/checkuser"):
                send(chat_id, "CheckUser se activa desde el panel.")
            elif text.startswith("/login"):
                send(chat_id, "Acceso recibido. Usa /start")
            else:
                send(chat_id, "Comando no reconocido. Usa /start")

if __name__ == "__main__":
    main()
