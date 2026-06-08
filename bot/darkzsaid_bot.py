#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import subprocess
import time
import urllib.parse
import urllib.request
from datetime import datetime, timedelta
from pathlib import Path

CONF = Path("/etc/darkzsaid/bot/bot.conf")
DATA_DIR = Path("/opt/darkzsaid/data")
USERDIR = Path("/etc/adm-lite/userDIR")
UDP_USERS = Path("/etc/darkzsaid/usuarios")
DB = DATA_DIR / "usuarios.db"
ADMINS_DB = DATA_DIR / "admins.db"

DATA_DIR.mkdir(parents=True, exist_ok=True)

# DarkZsaid fix: si /etc/adm-lite/userDIR existe como archivo, respaldarlo y crear carpeta
try:
    USERDIR = pathlib.Path("/etc/adm-lite/userDIR")
    if USERDIR.exists() and not USERDIR.is_dir():
        backup = pathlib.Path(f"/etc/adm-lite/userDIR.bak_{int(time.time())}")
        shutil.move(str(USERDIR), str(backup))
    USERDIR.mkdir(parents=True, exist_ok=True)
except Exception:
    pass

# USERDIR mkdir ya protegido arriba
UDP_USERS.mkdir(parents=True, exist_ok=True)

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
API = f"https://api.telegram.org/bot{TOKEN}"

def run(cmd):
    try:
        return subprocess.check_output(cmd, shell=True, text=True, stderr=subprocess.DEVNULL).strip()
    except Exception:
        return ""

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

def is_super(chat_id):
    return str(chat_id) == str(ADMIN_ID)

def load_admins():
    admins = {}
    if ADMINS_DB.exists():
        for line in ADMINS_DB.read_text(errors="ignore").splitlines():
            parts = line.strip().split("|")
            if len(parts) >= 2:
                try:
                    admins[parts[0]] = int(parts[1])
                except Exception:
                    admins[parts[0]] = 0
    return admins

def save_admins(admins):
    lines = []
    for admin_id, credits in sorted(admins.items()):
        lines.append(f"{admin_id}|{credits}")
    ADMINS_DB.write_text("\n".join(lines) + ("\n" if lines else ""), encoding="utf-8")

def is_reseller(chat_id):
    if is_super(chat_id):
        return True
    admins = load_admins()
    return str(chat_id) in admins and admins[str(chat_id)] > 0

def get_creditos(chat_id):
    if is_super(chat_id):
        return 999999
    admins = load_admins()
    return admins.get(str(chat_id), 0)

def add_creditos(admin_id, cantidad):
    admins = load_admins()
    admin_id = str(admin_id)
    admins[admin_id] = admins.get(admin_id, 0) + int(cantidad)
    save_admins(admins)
    return admins[admin_id]

def restar_creditos(admin_id, cantidad):
    admins = load_admins()
    admin_id = str(admin_id)
    admins[admin_id] = max(0, admins.get(admin_id, 0) - int(cantidad))
    save_admins(admins)
    return admins[admin_id]

def consumir_credito(chat_id):
    if is_super(chat_id):
        return True
    admins = load_admins()
    cid = str(chat_id)
    if admins.get(cid, 0) <= 0:
        return False
    admins[cid] -= 1
    save_admins(admins)
    return True

def get_ip():
    return run("hostname -I | awk '{print $1}'") or "IP"

def blocked_menu(chat_id):
    send(chat_id, f"""<b>DARKZSAID BOT SSH</b>
━━━━━━━━━━━━━━━━━━━━
⛔ <b>ACCESO BLOQUEADO</b>
━━━━━━━━━━━━━━━━━━━━

Tu ID de Telegram es:
<code>{chat_id}</code>

Solicita autorización al administrador.

Uso:
<code>/login contraseña</code>
""")

def super_menu(chat_id):
    ip = get_ip()
    send(chat_id, f"""<b>DARKZSAID BOT SSH</b>
━━━━━━━━━━━━━━━━━━━━
👑 <b>BIENVENIDO SUPER ADMIN PREMIUM</b>
━━━━━━━━━━━━━━━━━━━━

<b>MENU DE ACCIONES RAPIDAS</b>
━━━━━━━━━━━━━━━━━━━━

🌐 <b>IP Asignada:</b> <code>{ip}</code>

<b>Usuarios</b>
/agregar     -> Agregar usuario SSH
/token       -> Agregar usuario TOKEN
/hwid        -> Agregar usuario HWID
/demo        -> Crear usuario demo 1 dia
/usreg       -> Lista de usuarios
/usuarios    -> Lista de usuarios
/usconnect   -> Usuarios conectados
/conectados  -> Usuarios conectados
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
/creditos ID cantidad -> Autorizar creditos
/restar ID cantidad   -> Quitar creditos
/admins               -> Ver admins

<b>Herramientas Extra</b>
/backup      -> Generar respaldo de clientes
/checkuser   -> Link CheckUser

━━━━━━━━━━━━━━━━━━━━
Creditos: <code>∞</code>
━━━━━━━━━━━━━━━━━━━━
""")

def reseller_menu(chat_id):
    ip = get_ip()
    cr = get_creditos(chat_id)
    send(chat_id, f"""<b>DARKZSAID BOT SSH</b>
━━━━━━━━━━━━━━━━━━━━
<b>BIENVENIDO ADMIN RESELLER</b>
━━━━━━━━━━━━━━━━━━━━

<b>MENU DE ACCIONES RAPIDAS</b>
━━━━━━━━━━━━━━━━━━━━

🌐 <b>IP Asignada:</b> <code>{ip}</code>

<b>Usuarios</b>
/agregar     -> Agregar usuario SSH
/token       -> Agregar usuario TOKEN
/hwid        -> Agregar usuario HWID
/demo        -> Crear usuario demo 1 dia
/usreg       -> Lista de usuarios
/usuarios    -> Lista de usuarios
/usconnect   -> Usuarios conectados
/conectados  -> Usuarios conectados
/borrar      -> Eliminar usuario

<b>Renovaciones</b>
/renovar     -> Renovacion directa
/renovarM    -> Renovacion dias +
/renovarQ    -> Renovacion dias -

<b>Cuenta</b>
/creditos    -> Ver mis creditos

━━━━━━━━━━━━━━━━━━━━
Creditos: <code>{cr}</code>
━━━━━━━━━━━━━━━━━━━━
""")

def menu(chat_id):
    if is_super(chat_id):
        super_menu(chat_id)
    elif is_reseller(chat_id):
        reseller_menu(chat_id)
    else:
        blocked_menu(chat_id)

def crear_usuario_linux(user, password, dias, limite="1", tipo="NORMAL", nombre=""):
    if not user or not password:
        return False, "Usuario o contraseña vacío."

    if run(f"id {user}"):
        return False, f"El usuario {user} ya existe."

    try:
        dias_int = int(dias)
    except Exception:
        return False, "Los días deben ser número."

    expira = (datetime.now() + timedelta(days=dias_int)).strftime("%Y-%m-%d")

    cmds = [
        f"useradd -M -s /bin/false {user}",
        f"HASH=$(openssl passwd -6 '{password}') && usermod -p \"$HASH\" '{user}'",
        f"chage -E {expira} {user}",
    ]

    for c in cmds:
        r = subprocess.run(c, shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if r.returncode != 0:
            subprocess.run(f"userdel -r {user}", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            return False, "No se pudo crear el usuario Linux."

    (USERDIR / user).write_text(
        f"senha: {password}\nlimite: {limite}\ndata: {expira}\npass: {password}\n",
        encoding="utf-8"
    )

    (UDP_USERS / user).write_text(
        f"senha: {password}\npass: {password}\nusuario: {user}\nuser: {user}\nnombre: {nombre or user}\nlimite: {limite}\ndata: {expira}\n",
        encoding="utf-8"
    )

    with DB.open("a", encoding="utf-8") as f:
        f.write(f"{user}|{password}|{dias}|{limite}|{expira}|{tipo}|{nombre or user}|{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")

    for script in [
        "/opt/darkzsaid/menus/sync_hysteria_passwords.sh",
        "/opt/darkzsaid/menus/sync_udpmod_users.sh",
    ]:
        if Path(script).exists():
            subprocess.run(f"bash {script} >/dev/null 2>&1 || true", shell=True)

    subprocess.run("systemctl restart udpmod.service >/dev/null 2>&1 || true", shell=True)

    return True, expira

def get_user_records():
    records = []
    seen = set()

    if DB.exists():
        for line in DB.read_text(errors="ignore").splitlines():
            parts = line.split("|")
            if len(parts) >= 1 and parts[0].strip():
                user = parts[0].strip()
                password = parts[1].strip() if len(parts) > 1 else ""
                expira = parts[4].strip() if len(parts) > 4 else ""
                key = user.lower()
                if key not in seen:
                    records.append({
                        "user": user,
                        "password": password,
                        "expira": expira,
                        "source": "db"
                    })
                    seen.add(key)

    for folder in [USERDIR, UDP_USERS]:
        if folder.exists():
            for f in folder.glob("*"):
                if f.is_file():
                    user = f.name.strip()
                    key = user.lower()
                    if key not in seen:
                        password = ""
                        expira = ""
                        txt = f.read_text(errors="ignore")
                        for line in txt.splitlines():
                            low = line.lower()
                            if low.startswith("senha:") or low.startswith("pass:"):
                                password = line.split(":", 1)[1].strip()
                            elif low.startswith("data:"):
                                expira = line.split(":", 1)[1].strip()
                        records.append({
                            "user": user,
                            "password": password,
                            "expira": expira,
                            "source": "file"
                        })
                        seen.add(key)

    return records


def listar_usuarios():
    usuarios = []
    for r in get_user_records():
        user = r.get("user", "")
        password = r.get("password", "")
        expira = r.get("expira", "")
        usuarios.append(f"• {user} | Pass: {password or '-'} | Expira: {expira or '-'}")
    return usuarios


def renovar_usuario(user, dias):
    if not run(f"id {user}"):
        return False, "Usuario no existe."

    try:
        dias_int = int(dias)
    except Exception:
        return False, "Los días deben ser número."

    expira = (datetime.now() + timedelta(days=dias_int)).strftime("%Y-%m-%d")
    r = subprocess.run(f"chage -E {expira} {user}", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if r.returncode != 0:
        return False, "No se pudo renovar."

    for f in [USERDIR / user, UDP_USERS / user]:
        if f.exists():
            txt = f.read_text(errors="ignore").splitlines()
            nuevo = []
            puso = False
            for line in txt:
                if line.lower().startswith("data:"):
                    nuevo.append(f"data: {expira}")
                    puso = True
                else:
                    nuevo.append(line)
            if not puso:
                nuevo.append(f"data: {expira}")
            f.write_text("\n".join(nuevo) + "\n", encoding="utf-8")

    return True, expira

def resolver_usuario_borrar(valor):
    records = get_user_records()

    # Permitir borrar por número: /borrar 1
    if str(valor).isdigit():
        idx = int(valor) - 1
        if 0 <= idx < len(records):
            return records[idx]["user"]

    # Permitir borrar por nombre, ignorando mayúsculas/minúsculas
    for r in records:
        if r["user"].lower() == str(valor).lower():
            return r["user"]

    # También revisar Linux directamente
    linux_user = run(f"getent passwd {valor} | cut -d: -f1")
    if linux_user:
        return linux_user

    return ""


def borrar_usuario(user):
    real_user = resolver_usuario_borrar(user)
    if not real_user:
        return False, f"No encontré el usuario: {user}"

    deleted_any = False

    # Borrar usuario Linux si existe
    if run(f"getent passwd {real_user}"):
        subprocess.run(f"userdel -r {real_user} >/dev/null 2>&1 || userdel {real_user} >/dev/null 2>&1 || true", shell=True)
        if not run(f"getent passwd {real_user}"):
            deleted_any = True

    # Borrar archivos relacionados, sensible y no sensible a mayúsculas
    for folder in [USERDIR, UDP_USERS]:
        if folder.exists():
            for f in list(folder.glob("*")):
                if f.name.lower() == real_user.lower():
                    try:
                        f.unlink()
                        deleted_any = True
                    except Exception:
                        pass

    # Borrar líneas del DB
    if DB.exists():
        old_lines = DB.read_text(errors="ignore").splitlines()
        new_lines = []
        removed_db = False

        for line in old_lines:
            parts = line.split("|")
            first = parts[0].strip() if parts else ""
            if first.lower() == real_user.lower():
                removed_db = True
                continue
            new_lines.append(line)

        if removed_db:
            DB.write_text("\n".join(new_lines) + ("\n" if new_lines else ""), encoding="utf-8")
            deleted_any = True

    # Re-sincronizar UDPMod/Hysteria si existe script
    for script in [
        "/opt/darkzsaid/menus/sync_hysteria_passwords.sh",
        "/opt/darkzsaid/menus/sync_udpmod_users.sh",
    ]:
        if Path(script).exists():
            subprocess.run(f"bash {script} >/dev/null 2>&1 || true", shell=True)

    subprocess.run("systemctl restart udpmod.service >/dev/null 2>&1 || true", shell=True)

    # Verificación final
    still_linux = bool(run(f"getent passwd {real_user}"))
    still_file = any(
        f.name.lower() == real_user.lower()
        for folder in [USERDIR, UDP_USERS] if folder.exists()
        for f in folder.glob("*")
    )
    still_db = False
    if DB.exists():
        for line in DB.read_text(errors="ignore").splitlines():
            parts = line.split("|")
            if parts and parts[0].strip().lower() == real_user.lower():
                still_db = True
                break

    if still_linux or still_file or still_db:
        return False, f"No se pudo eliminar completamente: {real_user}"

    if deleted_any:
        return True, real_user

    return False, f"No encontré datos para eliminar: {real_user}"


def usuarios_conectados():
    out = run("who")
    return out if out else "No hay usuarios conectados."

def info_puertos():
    return run("ss -lntup | grep -E ':22|:80|:443|:36712|:5667|:7300'") or "No se encontraron puertos."

def require_auth(chat_id):
    if is_super(chat_id) or is_reseller(chat_id):
        return True
    blocked_menu(chat_id)
    return False

def require_super(chat_id):
    if is_super(chat_id):
        return True
    send(chat_id, "⛔ Opción disponible solo para SUPER ADMIN.")
    return False

def process_message(msg):
    chat_id = msg.get("chat", {}).get("id")
    text = (msg.get("text") or "").strip()
    if not chat_id or not text:
        return

    parts = text.split()
    cmd = parts[0].lower()
    args = parts[1:]

    if cmd == "/start":
        menu(chat_id)
        return

    if cmd == "/login":
        if len(args) >= 1 and args[0] == BOT_PASS:
            send(chat_id, "Solicitud recibida. Envía tu ID al administrador para recibir créditos.\n\nTu ID:\n<code>%s</code>" % chat_id)
        else:
            blocked_menu(chat_id)
        return

    if cmd == "/creditos":
        if is_super(chat_id) and len(args) >= 2:
            admin_id, cantidad = args[0], args[1]
            total = add_creditos(admin_id, cantidad)
            send(chat_id, f"""✅ <b>AUTORIZACION EMITIDA EXITOSAMENTE</b>

El ID <code>{admin_id}</code> ya puede administrar.

Créditos asignados: <code>{total}</code>

1 crédito equivale a 30 días por user.
""")
            try:
                send(admin_id, f"✅ Has sido autorizado.\nCréditos disponibles: <code>{total}</code>\n\nToca /start")
            except Exception:
                pass
            return
        else:
            send(chat_id, f"Créditos disponibles: <code>{get_creditos(chat_id)}</code>\nID: <code>{chat_id}</code>")
            return

    if cmd in ["/restar", "/admkil", "/admkill"]:
        if not require_super(chat_id):
            return
        if len(args) < 2:
            send(chat_id, "Uso:\n<code>/restar ID cantidad</code>")
            return
        total = restar_creditos(args[0], args[1])
        send(chat_id, f"✅ Créditos actualizados.\nID: <code>{args[0]}</code>\nCréditos: <code>{total}</code>")
        return

    if cmd == "/admins":
        if not require_super(chat_id):
            return
        admins = load_admins()
        if not admins:
            send(chat_id, "No hay admins reseller registrados.")
        else:
            txt = "\n".join([f"• {k} | Créditos: {v}" for k, v in admins.items()])
            send(chat_id, "<b>Admins reseller:</b>\n\n" + txt)
        return

    if not require_auth(chat_id):
        return

    if cmd == "/agregar":
        if len(args) < 4:
            send(chat_id, "Uso:\n<code>/agregar usuario clave dias limite</code>")
            return
        if not consumir_credito(chat_id):
            send(chat_id, "⛔ No tienes créditos disponibles.")
            return
        user, password, dias, limite = args[0], args[1], args[2], args[3]
        ok, res = crear_usuario_linux(user, password, dias, limite, "NORMAL", user)
        if ok:
            send(chat_id, f"✅ Usuario creado\n\nUsuario: <code>{user}</code>\nContraseña: <code>{password}</code>\nExpira: <code>{res}</code>\nLímite: <code>{limite}</code>\nCréditos restantes: <code>{get_creditos(chat_id)}</code>")
        else:
            add_creditos(chat_id, 1) if not is_super(chat_id) else None
            send(chat_id, f"❌ {res}")

    elif cmd == "/token":
        if len(args) < 3:
            send(chat_id, "Uso:\n<code>/token nombre token dias</code>")
            return
        if not consumir_credito(chat_id):
            send(chat_id, "⛔ No tienes créditos disponibles.")
            return
        nombre, token, dias = args[0], args[1], args[2]
        ok, res = crear_usuario_linux(token, token, dias, "TOKEN", "TOKEN", nombre)
        if ok:
            send(chat_id, f"✅ Token creado\n\nNombre: <code>{nombre}</code>\nUsuario/Token: <code>{token}</code>\nPass TK: <code>{token}</code>\nExpira: <code>{res}</code>\nCréditos restantes: <code>{get_creditos(chat_id)}</code>")
        else:
            add_creditos(chat_id, 1) if not is_super(chat_id) else None
            send(chat_id, f"❌ {res}")

    elif cmd == "/hwid":
        if len(args) < 3:
            send(chat_id, "Uso:\n<code>/hwid nombre codigo_hwid dias</code>")
            return
        if not consumir_credito(chat_id):
            send(chat_id, "⛔ No tienes créditos disponibles.")
            return
        nombre, hwid, dias = args[0], args[1], args[2]
        ok, res = crear_usuario_linux(hwid, hwid, dias, "HWID", "HWID", nombre)
        if ok:
            send(chat_id, f"✅ HWID creado\n\nNombre: <code>{nombre}</code>\nUsuario/HWID: <code>{hwid}</code>\nExpira: <code>{res}</code>\nCréditos restantes: <code>{get_creditos(chat_id)}</code>")
        else:
            add_creditos(chat_id, 1) if not is_super(chat_id) else None
            send(chat_id, f"❌ {res}")

    elif cmd == "/demo":
        if not consumir_credito(chat_id):
            send(chat_id, "⛔ No tienes créditos disponibles.")
            return
        user = f"demo{int(time.time()) % 10000}"
        password = "1234"
        ok, res = crear_usuario_linux(user, password, 1, "1", "DEMO", user)
        if ok:
            send(chat_id, f"✅ Demo creado\n\nUsuario: <code>{user}</code>\nContraseña: <code>{password}</code>\nExpira: <code>{res}</code>\nCréditos restantes: <code>{get_creditos(chat_id)}</code>")
        else:
            add_creditos(chat_id, 1) if not is_super(chat_id) else None
            send(chat_id, f"❌ {res}")

    elif cmd in ["/usuarios", "/usreg"]:
        usuarios = listar_usuarios()
        send(chat_id, "No hay usuarios registrados." if not usuarios else "<b>Usuarios registrados:</b>\n\n" + "\n".join(usuarios[:80]))

    elif cmd in ["/conectados", "/usconnect"]:
        send(chat_id, f"<b>Usuarios conectados:</b>\n<pre>{usuarios_conectados()}</pre>")

    elif cmd in ["/borrar", "/deluser", "/eliminar"]:
        records = get_user_records()

        if len(args) < 1:
            if not records:
                send(chat_id, "No hay usuarios registrados para eliminar.")
                return

            lista = []
            for i, r in enumerate(records, 1):
                lista.append(f"{i}) {r['user']} | Pass: {r.get('password') or '-'} | Expira: {r.get('expira') or '-'}")

            send(chat_id, "<b>Usuarios para eliminar:</b>\n\n" + "\n".join(lista) + "\n\nUso:\n<code>/borrar numero</code>\nEjemplo:\n<code>/borrar 1</code>")
            return

        ok, res = borrar_usuario(args[0])
        if ok:
            send(chat_id, f"✅ Usuario eliminado correctamente: <code>{res}</code>")
        else:
            send(chat_id, f"❌ {res}")

    elif cmd in ["/renovar", "/renovarm"]:
        if len(args) < 2:
            send(chat_id, "Uso:\n<code>/renovar usuario dias</code>")
            return
        ok, res = renovar_usuario(args[0], args[1])
        send(chat_id, f"✅ Usuario renovado\nUsuario: <code>{args[0]}</code>\nNueva fecha: <code>{res}</code>" if ok else f"❌ {res}")

    elif cmd == "/renovarq":
        send(chat_id, "Para renovación directa usa:\n<code>/renovar usuario dias</code>")

    elif cmd == "/puertos":
        if not require_super(chat_id):
            return
        send(chat_id, f"<b>Puertos activos:</b>\n<pre>{info_puertos()}</pre>")

    elif cmd == "/infovps":
        if not require_super(chat_id):
            return
        info = run("hostnamectl | head -5; echo; free -h; echo; uptime")
        send(chat_id, f"<b>Info VPS:</b>\n<pre>{info}</pre>")

    elif cmd == "/backup":
        if not require_super(chat_id):
            return
        send(chat_id, "Backup se gestiona desde el panel.")

    elif cmd == "/checkuser":
        if not require_super(chat_id):
            return
        ip = get_ip()
        send(chat_id, f"CheckUser:\n<code>http://{ip}:8080</code>")

    else:
        send(chat_id, "Comando no reconocido. Usa /start")

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
            msg = upd.get("message")
            if msg:
                try:
                    process_message(msg)
                except Exception as e:
                    print(f"PROCESS ERROR: {e}", flush=True)

if __name__ == "__main__":
    main()
