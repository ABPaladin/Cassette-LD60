"""Local HTTP server with anonymous CORS, mirroring LD's opaque sandbox iframe."""
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
class Handler(SimpleHTTPRequestHandler):
    def log_message(self,*args): pass
    def __init__(self,*args,**kwargs): super().__init__(*args,directory=str(Path('build').resolve()),**kwargs)
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin','*')
        self.send_header('Cache-Control','no-store')
        super().end_headers()
if __name__ == '__main__': ThreadingHTTPServer(('127.0.0.1',8765),Handler).serve_forever()
