#!/usr/bin/env python3
import json
import os
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.error import URLError
from urllib.request import Request, urlopen


def metadata_region():
    fallback = os.environ.get("AWS_REGION", "")
    token = None

    try:
        token_request = Request(
            "http://169.254.169.254/latest/api/token",
            method="PUT",
            headers={"X-aws-ec2-metadata-token-ttl-seconds": "60"},
        )
        with urlopen(token_request, timeout=1) as response:
            token = response.read().decode("utf-8")

        document_request = Request(
            "http://169.254.169.254/latest/dynamic/instance-identity/document",
            headers={"X-aws-ec2-metadata-token": token},
        )
        with urlopen(document_request, timeout=1) as response:
            document = json.loads(response.read().decode("utf-8"))
            return document.get("region", fallback)
    except (TimeoutError, URLError, OSError, json.JSONDecodeError):
        return fallback


class HealthHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path != "/health":
            self.send_response(404)
            self.end_headers()
            return

        body = {
            "service": os.environ.get("SERVICE_NAME", "rewards"),
            "status": "ok",
            "commit": os.environ.get("COMMIT_SHA", ""),
            "region": metadata_region(),
        }
        payload = json.dumps(body, separators=(",", ":")).encode("utf-8")

        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def log_message(self, format, *args):
        sys.stdout.write("%s - %s\n" % (self.address_string(), format % args))


def main():
    if not os.environ.get("APP_SECRET"):
        raise RuntimeError("APP_SECRET is required")

    port = int(os.environ.get("APP_PORT", "8080"))
    server = ThreadingHTTPServer(("0.0.0.0", port), HealthHandler)
    server.serve_forever()


if __name__ == "__main__":
    main()

