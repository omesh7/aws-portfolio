from http.server import HTTPServer, BaseHTTPRequestHandler
import json
from app import lambda_handler

class GameHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        
        # Create Lambda event format
        event = {
            'body': post_data.decode('utf-8'),
            'headers': dict(self.headers)
        }
        
        # Call Lambda handler
        response = lambda_handler(event, None)
        
        # Send response
        self.send_response(response['statusCode'])
        for header, value in response['headers'].items():
            self.send_header(header, value)
        self.end_headers()
        self.wfile.write(response['body'].encode())
    
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()

if __name__ == '__main__':
    server = HTTPServer(('localhost', 8000), GameHandler)
    print("Local Lambda server running on http://localhost:8000")
    server.serve_forever()