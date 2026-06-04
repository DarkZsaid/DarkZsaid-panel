#!/bin/bash

pantalla_limpia() {
    printf '\033c'
}


limpiar_pantalla() {
    printf '\033[H\033[2J\033[3J'
}


ROJO="\e[31m"
VERDE="\e[32m"
AMARILLO="\e[33m"
AZUL="\e[34m"
CYAN="\e[36m"
BLANCO="\e[97m"
RESET="\e[0m"
BOLD="\e[1m"

SCRIPT="/opt/darkzsaid/ssh-ws-direct.py"
SERVICE="/etc/systemd/system/darkzsaid-ws80.service"

pausa() {
    echo ""
    read -p "Presiona ENTER para continuar..."
}

titulo() {
    limpiar_pantalla
    echo -e "${ROJO}════════════════════════════════════════════${RESET}"
    echo -e "${BLANCO}${BOLD}        SOCKS PYTHON DIRECTO WS             ${RESET}"
    echo -e "${ROJO}════════════════════════════════════════════${RESET}"
    echo ""
}

estado_ws80() {
    if systemctl is-active --quiet darkzsaid-ws80 2>/dev/null; then
        echo -e "${VERDE}[ON]${RESET}"
    else
        echo -e "${ROJO}[OFF]${RESET}"
    fi
}

crear_script_ws80() {
cat > "$SCRIPT" <<'PY'
#!/usr/bin/env python3
import socket
import threading

LISTEN_HOST = "0.0.0.0"
LISTEN_PORT = 80

SSH_HOST = "127.0.0.1"
SSH_PORT = 22

RESPONSE_200 = (
    "HTTP/1.1 200 Connection established ADM SJCC\r\n"
    "Connection: keep-alive\r\n"
    "Proxy-Agent: ADM SJCC\r\n"
    "X-Powered-By: DarkZsaid\r\n"
    "\r\n"
).encode()

BUFFER_SIZE = 65535

def pipe(src, dst):
    try:
        while True:
            data = src.recv(BUFFER_SIZE)
            if not data:
                break
            dst.sendall(data)
    except Exception:
        pass
    finally:
        try:
            src.close()
        except Exception:
            pass
        try:
            dst.close()
        except Exception:
            pass

def handle_client(client, addr):
    ssh = None
    try:
        client.settimeout(10)

        try:
            data = client.recv(BUFFER_SIZE)
        except Exception:
            data = b""

        if data:
            client.sendall(RESPONSE_200)

        ssh = socket.create_connection((SSH_HOST, SSH_PORT), timeout=10)

        client.settimeout(None)
        ssh.settimeout(None)

        t1 = threading.Thread(target=pipe, args=(client, ssh), daemon=True)
        t2 = threading.Thread(target=pipe, args=(ssh, client), daemon=True)

        t1.start()
        t2.start()

        t1.join()
        t2.join()

    except Exception:
        try:
            client.close()
        except Exception:
            pass
        try:
            if ssh:
                ssh.close()
        except Exception:
            pass

def main():
    print("DarkZsaid SSH WS Direct 200 Establish ADM SJCC")
    print(f"Escuchando en {LISTEN_HOST}:{LISTEN_PORT}")
    print(f"Redirigiendo a {SSH_HOST}:{SSH_PORT}")

    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind((LISTEN_HOST, LISTEN_PORT))
    server.listen(500)

    while True:
        client, addr = server.accept()
        threading.Thread(target=handle_client, args=(client, addr), daemon=True).start()

if __name__ == "__main__":
    main()
PY

chmod +x "$SCRIPT"
}

crear_servicio_ws80() {
cat > "$SERVICE" <<'EOSERVICE'
[Unit]
Description=DarkZsaid SSH WS Direct 200 Establish ADM SJCC
After=network.target ssh.service

[Service]
Type=simple
ExecStart=/usr/bin/python3 /opt/darkzsaid/ssh-ws-direct.py
Restart=always
RestartSec=3
User=root

[Install]
WantedBy=multi-user.target
EOSERVICE

systemctl daemon-reload
systemctl enable darkzsaid-ws80 >/dev/null 2>&1
}

activar_ws80() {
    titulo
    echo -e "${CYAN}Activando SOCKS PYTHON DIRECTO WS con 200 Establish ADM SJCC...${RESET}"
    echo ""

    crear_script_ws80
    crear_servicio_ws80

    systemctl stop nginx 2>/dev/null || true
    systemctl disable nginx 2>/dev/null || true

    pkill -f "socks-python" 2>/dev/null || true
    pkill -f "ssh-ws-direct.py" 2>/dev/null || true

    ufw allow 80/tcp 2>/dev/null || true
    ufw reload 2>/dev/null || true

    systemctl restart darkzsaid-ws80

    sleep 2

    echo -e "${AMARILLO}Estado:${RESET} $(estado_ws80)"
    echo ""
    echo -e "${AMARILLO}Puerto 80:${RESET}"
    ss -tulnp | grep ':80' || echo "Puerto 80 no aparece activo."

    echo ""
    echo -e "${AMARILLO}Respuesta:${RESET}"
    echo -e "GET / HTTP/1.1\r\nHost: test\r\n\r\n" | nc -w 2 127.0.0.1 80 2>/dev/null || true

    echo ""
    echo -e "${VERDE}Método activado correctamente.${RESET}"
    pausa
}

detener_ws80() {
    titulo
    systemctl stop darkzsaid-ws80 2>/dev/null || true
    echo -e "${AMARILLO}SOCKS PYTHON DIRECTO WS detenido.${RESET}"
    pausa
}

reiniciar_ws80() {
    titulo
    systemctl restart darkzsaid-ws80 2>/dev/null || true
    sleep 2
    echo -e "${AMARILLO}Estado:${RESET} $(estado_ws80)"
    echo ""
    ss -tulnp | grep ':80' || echo "Puerto 80 no aparece activo."
    pausa
}

estado_detallado() {
    titulo
    echo -e "${AMARILLO}Estado:${RESET} $(estado_ws80)"
    echo ""
    echo -e "${AMARILLO}Servicio:${RESET}"
    systemctl status darkzsaid-ws80 --no-pager -l 2>/dev/null | head -30 || echo "Servicio no creado."
    echo ""
    echo -e "${AMARILLO}Puerto 80:${RESET}"
    ss -tulnp | grep ':80' || echo "Puerto 80 no aparece activo."
    echo ""
    echo -e "${AMARILLO}Respuesta 200 Establish:${RESET}"
    echo -e "GET / HTTP/1.1\r\nHost: test\r\n\r\n" | nc -w 2 127.0.0.1 80 2>/dev/null || true
    pausa
}

while true; do
    titulo
    echo -e "${ROJO}[01]${RESET} ${CYAN}➜${RESET} ${BLANCO}ACTIVAR 200 ESTABLISH ADM SJCC${RESET} $(estado_ws80)"
    echo -e "${ROJO}[02]${RESET} ${CYAN}➜${RESET} ${BLANCO}DETENER${RESET}"
    echo -e "${ROJO}[03]${RESET} ${CYAN}➜${RESET} ${BLANCO}REINICIAR${RESET}"
    echo -e "${ROJO}[04]${RESET} ${CYAN}➜${RESET} ${BLANCO}VER ESTADO${RESET}"
    echo ""
    echo -e "${ROJO}[00]${RESET} ${CYAN}➜${RESET} ${BLANCO}VOLVER${RESET}"
    echo ""
    read -p "Opción: " opc; printf '\033c'

    case "$opc" in
        1|01) activar_ws80 ;;
        2|02) detener_ws80 ;;
        3|03) reiniciar_ws80 ;;
        4|04) estado_detallado ;;
        0|00) exit 0 ;;
        *) echo -e "${ROJO}Opción inválida.${RESET}"; sleep 1 ;;
    esac
done
