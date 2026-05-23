from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, create_refresh_token, jwt_required, get_jwt_identity
from extensions import db, bcrypt
from models.models import User, AnalyticsLog
from datetime import datetime

auth_bp = Blueprint("auth", __name__)


@auth_bp.post("/auth/login")
def login():
    data = request.get_json()
    user = User.query.filter_by(username=data.get("username"), is_active=True).first()
    if not user or not bcrypt.check_password_hash(user.password_hash, data.get("password", "")):
        return jsonify({"error": "Invalid credentials"}), 401

    user.last_login = datetime.utcnow()
    db.session.commit()

    db.session.add(AnalyticsLog(user_id=user.user_id, action="login", ip_address=request.remote_addr))
    db.session.commit()

    return jsonify({
        "access_token":  create_access_token(identity=str(user.user_id)),
        "refresh_token": create_refresh_token(identity=str(user.user_id)),
        "user": user.to_dict()
    })


@auth_bp.post("/auth/register")
def register():
    data = request.get_json()
    if User.query.filter_by(username=data["username"]).first():
        return jsonify({"error": "Username taken"}), 409
    if User.query.filter_by(email=data["email"]).first():
        return jsonify({"error": "Email already registered"}), 409

    user = User(
        username=data["username"],
        email=data["email"],
        password_hash=bcrypt.generate_password_hash(data["password"]).decode(),
        role=data.get("role", "viewer"),
        org_id=data.get("org_id")
    )
    db.session.add(user)
    db.session.commit()
    return jsonify({"message": "User created", "user_id": user.user_id}), 201


@auth_bp.post("/auth/refresh")
@jwt_required(refresh=True)
def refresh():
    return jsonify({"access_token": create_access_token(identity=get_jwt_identity())})


@auth_bp.get("/auth/me")
@jwt_required()
def me():
    user = User.query.get_or_404(int(get_jwt_identity()))
    return jsonify(user.to_dict())
