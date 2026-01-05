from http.server import BaseHTTPRequestHandler, HTTPServer

class EchoHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        print(self.path)
        print(self.headers)
        self.wfile.write(f"Request path: {self.path}\n".encode())
        self.wfile.write(f"Headers:\n{self.headers}\n".encode())

    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        post_data = self.rfile.read(content_length) if content_length else b''
        self.send_response(200)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        self.wfile.write(f"Request path: {self.path}\n".encode())
        self.wfile.write(f"Headers:\n{self.headers}\n".encode())
        self.wfile.write(f"Body:\n{post_data.decode(errors='replace')}\n".encode())

def run(server_class=HTTPServer, handler_class=EchoHandler, port=8000):
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)
    print(f"Starting echo server on port {port}...")
    httpd.serve_forever()

if __name__ == '__main__':
    run()