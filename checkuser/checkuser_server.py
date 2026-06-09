#!/usr/bin/env python3
import os
import datetime
from http.server import BaseHTTPRequestHandler, HTTPServer

PORT = int(os.environ.get("CHECKUSER_PORT", "2095"))

USERDIR = "/etc/adm-lite/userDIR"
SSH_DB = "/opt/darkzsaid/data/usuarios_ssh.db"
TOKEN_DB = "/etc/darkzsaid/token_users.db"

def parse_date(value):
    value = (value or "").strip()
    if not value:
        return None
    value = value.split()[0]
    for fmt in ("%Y-%m-%d", "%Y/%m/%d", "%d/%m/%Y"):
        try:
            return datetime.datetime.strptime(value, fmt).date()
        except Exception:
            pass
    return None

def days_left(value):
    d = parse_date(value)
    if not d:
        return "Null"
    return str(max((d - datetime.date.today()).days, 0))

def fmt_date(value):
    d = parse_date(value)
    if not d:
        return "Null"
    return d.strftime("%d/%m/%Y")

def read_userdir():
    users = {}
    if not os.path.isdir(USERDIR):
        os.makedirs(USERDIR, exist_ok=True)

    for name in sorted(os.listdir(USERDIR)):
        path = os.path.join(USERDIR, name)
        if not os.path.isfile(path):
            continue

        senha = ""
        limite = "1"
        data = ""

        try:
            with open(path, "r", encoding="utf-8", errors="ignore") as f:
                for line in f:
                    line = line.strip()
                    low = line.lower()
                    if low.startswith("senha:"):
                        senha = line.split(":", 1)[1].strip()
                    elif low.startswith("limite:"):
                        limite = line.split(":", 1)[1].strip()
                    elif low.startswith("data:"):
                        data = line.split(":", 1)[1].strip()
        except Exception:
            continue

        if not senha:
            senha = name

        users[name] = {
            "usuario": name,
            "senha": senha,
            "limite": limite or "1",
            "caduca": fmt_date(data),
            "dias": days_left(data),
            "estado": "ACTIVO",
            "online": "0",
        }

    return users

def row(u):
    return f"{u['usuario']}|{u['senha']}|{u['limite']}|{u['caduca']}|{u['dias']}|{u['estado']}|{u['online']}"

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        return

    def send_text(self, text, code=200):
        self.send_response(code)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(text.encode("utf-8", errors="ignore"))

    def do_GET(self):
        path = self.path.split("?", 1)[0]

        # Compatible con la app buena:
        # http://IP:2095/checkUser
        if path not in ("/", "/checkUser", "/checkuser", "/CheckUser"):
            return self.send_text("NOT FOUND\n", 404)

        users = read_userdir()

        lines = []
        for user in sorted(users):
            lines.append(row(users[user]))

        self.send_text("\n".join(lines) + "\n")

if __name__ == "__main__":
    os.makedirs(USERDIR, exist_ok=True)
    server = HTTPServer(("0.0.0.0", PORT), Handler)
    print(f"DarkZsaid CheckUser activo en puerto {PORT}", flush=True)
    server.serve_forever()
