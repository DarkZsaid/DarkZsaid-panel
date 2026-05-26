#!/usr/bin/env python3
import datetime
import json
import os
import pwd
import socket
import subprocess
import urllib.parse
from http.server import BaseHTTPRequestHandler, HTTPServer

USERDIR = "/etc/adm-lite/userDIR"
CONF_DIR = "/etc/darkzsaid/checkuser"
ACTIVE_FLAG = os.path.join(CONF_DIR, "show_active_users.on")

def run_cmd(cmd):
    try:
        return subprocess.check_output(cmd, shell=True, text=True, stderr=subprocess.DEVNULL).strip()
    except Exception:
        return ""

def get_ip():
    ip = run_cmd("hostname -I | awk '{print $1}'")
    return ip or "0.0.0.0"

def panel_users():
    users = []
    for p in pwd.getpwall():
        if p.pw_uid >= 1000 and p.pw_name not in ("nobody",):
            if p.pw_shell in ("/bin/false", "/usr/sbin/nologin", "/sbin/nologin") or "/home" in p.pw_dir:
                users.append(p.pw_name)
    return sorted(set(users))

def userdir_value(user, key):
    path = os.path.join(USERDIR, user)
    if not os.path.isfile(path):
        return ""
    try:
        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            for line in f:
                if line.lower().startswith(key.lower() + ":"):
                    return line.split(":", 1)[1].strip()
    except Exception:
        return ""
    return ""

def passwd_comment_limit(user):
    try:
        gecos = pwd.getpwnam(user).pw_gecos or ""
        return gecos.split(",")[0].strip()
    except Exception:
        return ""

def expire_raw(user):
    data = userdir_value(user, "data")
    if data:
        return data

    out = run_cmd(f"chage -l {user} | grep -i 'Account expires' | awk -F ':' '{{print $2}}' | xargs")
    if out and out.lower() != "never":
        return out
    return ""

def parse_expire(value):
    if not value:
        return None

    formats = [
        "%Y-%m-%d",
        "%Y/%m/%d",
        "%d/%m/%Y",
        "%b %d, %Y",
        "%B %d, %Y",
        "%d %b %Y",
        "%d %B %Y",
    ]

    for fmt in formats:
        try:
            return datetime.datetime.strptime(value, fmt).date()
        except Exception:
            pass

    try:
        out = run_cmd(f"date -d '{value}' '+%Y-%m-%d'")
        if out:
            return datetime.datetime.strptime(out, "%Y-%m-%d").date()
    except Exception:
        return None

    return None

def format_date(d, fmt):
    if d is None:
        return "Null"
    if fmt == "2":
        return d.strftime("%d/%m/%Y")
    return d.strftime("%Y/%m/%d")

def days_left(d):
    if d is None:
        return "Null"
    diff = (d - datetime.date.today()).days
    if diff < 0:
        return "CADUCADO"
    return str(diff)

def is_locked(user):
    out = run_cmd(f"passwd -S {user} | awk '{{print $2}}'")
    return out == "L"

def online_count(user):
    ssh_open = run_cmd(f"pgrep -u {user} -f 'sshd: {user}' | wc -l")
    drop = run_cmd(f"ps aux | grep -i dropbear | grep '{user}' | grep -v grep | wc -l")
    ovpn = "0"
    if os.path.exists("/etc/openvpn/openvpn-status.log"):
        ovpn = run_cmd(f"grep -w '{user}' /etc/openvpn/openvpn-status.log | wc -l")
    try:
        return int(ssh_open or 0) + int(drop or 0) + int(ovpn or 0)
    except Exception:
        return 0

def user_info(user, fmt):
    visible = userdir_value(user, "senha") or user
    password = userdir_value(user, "pass") or userdir_value(user, "clave") or visible
    limit = userdir_value(user, "limite") or passwd_comment_limit(user) or "1"

    exp = parse_expire(expire_raw(user))
    dias = days_left(exp)

    if is_locked(user):
        status = "BLOQUEADO"
    elif dias == "CADUCADO":
        status = "CADUCADO"
    else:
        status = "ACTIVO"

    return {
        "usuario": user,
        "nombre": visible,
        "senha": password,
        "limite": limit,
        "caduca": format_date(exp, fmt),
        "dias": dias,
        "estado": status,
        "online": online_count(user),
    }

def as_text(data, show_active):
    lines = []
    lines.append("DARKZSAID CHECKUSER")
    lines.append(f"IP: {get_ip()}")
    lines.append("FORMATO: usuario|senha|limite|caduca|dias|estado|online")
    lines.append("")

    for u in data:
        if not show_active and u["online"] > 0:
            # Original tiene opción de mostrar/ocultar usuarios activos en app.
            # Si está desactivado, no se listan conectados como activos especiales.
            pass
        lines.append(
            f'{u["nombre"]}|{u["senha"]}|{u["limite"]}|{u["caduca"]}|{u["dias"]}|{u["estado"]}|{u["online"]}'
        )
    return "\n".join(lines) + "\n"

class Handler(BaseHTTPRequestHandler):
    server_version = "DarkZsaidCheckUser/1.0"

    def log_message(self, fmt, *args):
        return

    def send(self, code, body, ctype="text/plain; charset=utf-8"):
        raw = body.encode("utf-8", errors="ignore")
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        qs = urllib.parse.parse_qs(parsed.query)

        fmt = os.environ.get("CHECKUSER_FORMAT", "1")
        show_active = os.path.exists(ACTIVE_FLAG)

        if parsed.path not in ("/", "/checkUser", "/checkuser", "/json"):
            self.send(404, "NOT FOUND\n")
            return

        user_filter = qs.get("user", [""])[0]

        users = panel_users()
        if user_filter:
            users = [u for u in users if u == user_filter]

        data = [user_info(u, fmt) for u in users]

        if parsed.path == "/json":
            self.send(200, json.dumps({
                "service": "DarkZsaid CheckUser",
                "ip": get_ip(),
                "total": len(data),
                "users": data
            }, ensure_ascii=False, indent=2), "application/json; charset=utf-8")
        else:
            self.send(200, as_text(data, show_active))

def main():
    port = int(os.environ.get("CHECKUSER_PORT", "90"))
    host = "0.0.0.0"
    HTTPServer((host, port), Handler).serve_forever()

if __name__ == "__main__":
    main()
