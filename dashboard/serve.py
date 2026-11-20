#!/usr/bin/env python3
import http.server
import socketserver
import socket
import os
import sys

PORT = 3000
DIRECTORY = os.path.dirname(os.path.abspath(__file__))

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate')
        super().end_headers()

def get_local_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"

if __name__ == "__main__":
    os.chdir(DIRECTORY)
    local_ip = get_local_ip()

    # Agar 3000 band bo'lsa, 3001, 3002 ni tekshirish
    server = None
    for p in range(PORT, PORT + 20):
        try:
            server = socketserver.TCPServer(("", p), Handler)
            PORT = p
            break
        except OSError:
            continue

    if not server:
        print("❌ Port topilmadi.")
        sys.exit(1)

    print("\n" + "=" * 55)
    print("⚡ ARENA BOSS DASHBOARD MUVAFFAQIYATLI ISHGA TUSHDI!")
    print("=" * 55)
    print(f"💻 Kompyuterda ochish:  http://localhost:{PORT}")
    print(f"📱 Telefonda ochish:    http://{local_ip}:{PORT}")
    print("=" * 55)
    print("Boshqaruv markazini to'xtatish uchun: Ctrl + C bosing\n")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nServer to'xtatildi.")
        server.server_close()
