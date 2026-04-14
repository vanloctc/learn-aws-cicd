"""
Flask Realtime Clock Application
Supports: AWS CodeBuild | CodeDeploy | CodePipeline
Author  : AWS Expert Demo
"""

import os
import logging
import socket
from datetime import datetime
from flask import Flask, render_template, jsonify, request
from flask_cors import CORS


def get_server_ip():
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
            sock.connect(("8.8.8.8", 80))
            return sock.getsockname()[0]
    except Exception:
        try:
            return socket.gethostbyname(socket.gethostname())
        except Exception:
            return "unknown"

# ─── App Factory ────────────────────────────────────────────────────────────
def create_app():
    app = Flask(__name__)
    CORS(app)

    # Logging
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s  %(levelname)-8s  %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    logger = logging.getLogger(__name__)

    # ── Routes ───────────────────────────────────────────────────────────────
    @app.route("/")
    def index():
        logger.info("Serving index page")
        return render_template("index.html")

    @app.route("/api/time")
    def get_time():
        """Return current server time as JSON (polled by front-end)."""
        now = datetime.now()
        client_ip = request.headers.get("X-Forwarded-For", request.remote_addr)
        if client_ip:
            client_ip = client_ip.split(",")[0].strip()
        return jsonify(
            {
                "time": now.strftime("%H:%M:%S"),
                "date": now.strftime("%A, %d %B %Y"),
                "timestamp": now.isoformat(),
                "timezone": str(datetime.now().astimezone().tzname()),
                "server_ip": get_server_ip(),
                "client_ip": client_ip,
            }
        )

    @app.route("/health")
    def health():
        """Health-check endpoint used by ALB / CodeDeploy."""
        return jsonify({"status": "healthy", "service": "realtime-clock"}), 200

    @app.route("/version")
    def version():
        """Return deployment info (populated by CodeBuild env vars)."""
        return jsonify(
            {
                "version": os.getenv("APP_VERSION", "1.0.0"),
                "build_id": os.getenv("CODEBUILD_BUILD_ID", "local"),
                "commit": os.getenv("CODEBUILD_RESOLVED_SOURCE_VERSION", "unknown"),
                "environment": os.getenv("DEPLOY_ENV", "development"),
            }
        )

    return app


# ─── Entry point ────────────────────────────────────────────────────────────
app = create_app()

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8080))
    debug = os.getenv("FLASK_ENV", "production") == "development"
    app.run(host="0.0.0.0", port=port, debug=debug)
