#####################
"""
Global Wildlife Conservation & Threat Tracker — Flask app.py
"""
import os, threading, webbrowser
from flask import Flask, render_template, jsonify
from flask_cors import CORS
from config import Config
from extensions import db, jwt, bcrypt, limiter
from routes.auth_routes   import auth_bp
from routes.species_routes import species_bp
from routes.other_routes  import threats_bp, reports_bp, analytics_bp, locations_bp, plans_bp


def create_app(config=Config):
    basedir        = os.path.dirname(__file__)
    templates_path = os.path.abspath(os.path.join(basedir, "..", "frontend", "templates"))
    static_path    = os.path.abspath(os.path.join(basedir, "..", "frontend"))

    app = Flask(__name__,
                template_folder=templates_path,
                static_folder=static_path,
                static_url_path="")

    app.config.from_object(config)
    CORS(app, resources={r"/api/*": {"origins": "*"}})

    db.init_app(app)
    jwt.init_app(app)
    bcrypt.init_app(app)
    limiter.init_app(app)

    for bp in [auth_bp, species_bp, threats_bp, reports_bp, analytics_bp, locations_bp, plans_bp]:
        app.register_blueprint(bp, url_prefix="/api")

    @app.get("/api/health")
    def health():
        return jsonify({"status": "ok", "version": "1.0.0"})

    # Serve pages via render_template so Flask finds them in templates folder
    @app.get("/")
    @app.get("/login")
    def login_page():
        return render_template("login.html")

    @app.get("/dashboard")
    def dashboard_page():
        return render_template("dashboard.html")

    return app


if __name__ == "__main__":
    app  = create_app()
    port = int(os.getenv("PORT", 5000))
    url  = f"http://127.0.0.1:{port}/"
    try:
        threading.Timer(1.2, lambda: webbrowser.open(url)).start()
    except Exception:
        pass
    print(f"\n  Wildlife Tracker running at: {url}\n")
    app.run(debug=True, port=port, use_reloader=False)