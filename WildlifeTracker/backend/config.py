import os
from datetime import timedelta

# Make loading .env optional so the app can start even if python-dotenv
# is not installed in the current environment (useful for read-only systems).
try:
    from dotenv import load_dotenv

    load_dotenv()
except Exception:
    # dotenv not available — environment variables will still be read from OS
    pass


class Config:
    SECRET_KEY = os.getenv("SECRET_KEY", "change-me-in-production")
    SQLALCHEMY_DATABASE_URI = os.getenv(
        "DATABASE_URL", "mysql+pymysql://root:password@localhost/WildlifeTracker"
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_ENGINE_OPTIONS = {"pool_recycle": 280, "pool_pre_ping": True}

    JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "jwt-secret-change-me")
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=8)
    JWT_REFRESH_TOKEN_EXPIRES = timedelta(days=30)

    ALLOWED_ORIGINS = os.getenv("ALLOWED_ORIGINS", "*").split(",")
    RATELIMIT_DEFAULT = "200/hour"
    RATELIMIT_STORAGE_URL = "memory://"
