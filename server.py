#!/usr/bin/env python3
"""
Simple HTTP Server for Testing MAME WASM
Usage: python server.py
Then open: http://localhost:8000/test_vanilla.html
"""

import http.server
import socketserver
import os
import sys
from pathlib import Path

PORT = 8000

class CORSRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate')
        super().end_headers()

    def log_message(self, format, *args):
        print(f"[{self.log_date_time_string()}] {format % args}")

if __name__ == '__main__':
    os.chdir(Path(__file__).parent)
    
    try:
        with socketserver.TCPServer(("", PORT), CORSRequestHandler) as httpd:
            print(f"\n[*] MAME WASM Test Server")
            print(f"[*] Listening on http://localhost:{PORT}")
            print(f"[*] Test page: http://localhost:{PORT}/test_vanilla.html")
            print(f"[*] Press Ctrl+C to stop\n")
            httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n[*] Server stopped.")
        sys.exit(0)
    except OSError as e:
        print(f"[-] Error: {e}")
        print(f"[-] Port {PORT} may already be in use. Try killing existing server or using different port.")
        sys.exit(1)
