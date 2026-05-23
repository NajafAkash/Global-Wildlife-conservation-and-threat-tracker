from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from extensions import db
from models.models import Threat, TrackingReport, AnalyticsLog, Location, PreventionPlan, Species, User
from sqlalchemy import text

threats_bp   = Blueprint("threats",   __name__)
reports_bp   = Blueprint("reports",   __name__)
analytics_bp = Blueprint("analytics", __name__)
locations_bp = Blueprint("locations", __name__)
plans_bp     = Blueprint("plans",     __name__)


# ── Threats ──────────────────────────────────────────────────
@threats_bp.get("/threats")
def list_threats():
    try:
        rows = db.session.execute(text("""
            SELECT t.*, COUNT(st.species_id) AS affected_species
            FROM threats t
            LEFT JOIN species_threats st ON t.threat_id = st.threat_id
            GROUP BY t.threat_id ORDER BY affected_species DESC
        """)).fetchall()
        return jsonify([dict(r._mapping) for r in rows])
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@threats_bp.post("/threats")
@jwt_required()
def create_threat():
    try:
        data = request.get_json()
        t = Threat(**{k: data[k] for k in ["name","category","severity","description"] if k in data})
        db.session.add(t)
        db.session.commit()
        return jsonify(t.to_dict()), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500


@threats_bp.post("/species/<int:sid>/threats")
@jwt_required()
def assign_threat(sid):
    try:
        data = request.get_json()
        db.session.execute(text("""
            INSERT IGNORE INTO species_threats (species_id, threat_id, impact_level, notes, recorded_at)
            VALUES (:sid, :tid, :lvl, :notes, CURDATE())
        """), {"sid": sid, "tid": data["threat_id"], "lvl": data.get("impact_level","moderate"), "notes": data.get("notes","")})
        db.session.commit()
        return jsonify({"message": "Threat assigned"})
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500


# ── Tracking Reports ──────────────────────────────────────────
@reports_bp.get("/reports")
def list_reports():
    try:
        page  = int(request.args.get("page", 1))
        per   = min(int(request.args.get("per_page", 20)), 100)
        sid   = request.args.get("species_id")
        query = TrackingReport.query
        if sid:
            query = query.filter_by(species_id=int(sid))
        p = query.order_by(TrackingReport.report_date.desc()).paginate(page=page, per_page=per, error_out=False)
        return jsonify({
            "data": [{
                "report_id": r.report_id, "species_id": r.species_id,
                "report_date": str(r.report_date), "population_obs": r.population_obs,
                "health_status": r.health_status, "notes": r.notes, "verified": r.verified,
                "species_name": r.species.common_name if r.species else None,
                "location": r.location.to_dict() if r.location else None
            } for r in p.items],
            "total": p.total, "pages": p.pages
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@reports_bp.post("/reports")
@jwt_required()
def create_report():
    try:
        uid  = int(get_jwt_identity())
        data = request.get_json()
        r = TrackingReport(
            species_id=data["species_id"], location_id=data.get("location_id"),
            reported_by=uid, population_obs=data.get("population_obs"),
            health_status=data.get("health_status","unknown"), notes=data.get("notes"),
            report_date=data.get("report_date")
        )
        db.session.add(r)
        db.session.commit()
        return jsonify({"report_id": r.report_id}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500


@reports_bp.put("/reports/<int:rid>/verify")
@jwt_required()
def verify_report(rid):
    try:
        uid  = int(get_jwt_identity())
        user = User.query.get(uid)
        if user.role not in ("admin","researcher"):
            return jsonify({"error": "Insufficient permissions"}), 403
        r = TrackingReport.query.get_or_404(rid)
        r.verified = True
        db.session.commit()
        return jsonify({"message": "Verified"})
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500


# ── Analytics ────────────────────────────────────────────────
@analytics_bp.get("/analytics/dashboard")
@jwt_required()
def dashboard():
    try:
        totals = db.session.execute(text("""
            SELECT
                (SELECT COUNT(*) FROM species)             AS total_species,
                (SELECT COUNT(*) FROM tracking_reports)    AS total_reports,
                (SELECT COUNT(*) FROM prevention_plans)    AS total_plans,
                (SELECT COUNT(*) FROM locations)           AS total_locations,
                (SELECT COUNT(*) FROM species
                 WHERE status_id IN (SELECT status_id FROM conservation_status WHERE threat_level IN ('critical','high')))
                                                           AS at_risk_species
        """)).fetchone()

        status_dist = db.session.execute(text("""
            SELECT cs.name, cs.color_hex, COUNT(s.species_id) AS count
            FROM conservation_status cs
            LEFT JOIN species s ON s.status_id = cs.status_id
            GROUP BY cs.status_id
        """)).fetchall()

        top_threats = db.session.execute(text("""
            SELECT t.name, t.category, t.severity, COUNT(st.species_id) AS species_count
            FROM threats t
            LEFT JOIN species_threats st ON t.threat_id = st.threat_id
            GROUP BY t.threat_id ORDER BY species_count DESC LIMIT 5
        """)).fetchall()

        trend_data = db.session.execute(text("""
            SELECT DATE_FORMAT(report_date,'%Y-%m') AS month, COUNT(*) AS reports
            FROM tracking_reports
            WHERE report_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
            GROUP BY month ORDER BY month
        """)).fetchall()

        return jsonify({
            "totals":      dict(totals._mapping),
            "status_dist": [dict(r._mapping) for r in status_dist],
            "top_threats": [dict(r._mapping) for r in top_threats],
            "trend_data":  [dict(r._mapping) for r in trend_data],
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@analytics_bp.get("/analytics/logs")
@jwt_required()
def get_logs():
    try:
        uid  = int(get_jwt_identity())
        user = User.query.get(uid)
        if user.role != "admin":
            return jsonify({"error": "Admin only"}), 403
        logs = AnalyticsLog.query.order_by(AnalyticsLog.created_at.desc()).limit(200).all()
        return jsonify([{
            "log_id": l.log_id, "user_id": l.user_id, "action": l.action,
            "entity_type": l.entity_type, "entity_id": l.entity_id,
            "created_at": str(l.created_at)
        } for l in logs])
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ── Locations ────────────────────────────────────────────────
@locations_bp.get("/locations")
def list_locations():
    try:
        locs = Location.query.all()
        return jsonify([l.to_dict() for l in locs])
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@locations_bp.post("/locations")
@jwt_required()
def create_location():
    try:
        data = request.get_json()
        loc  = Location(**data)
        db.session.add(loc)
        db.session.commit()
        return jsonify(loc.to_dict()), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500


# ── Prevention Plans ─────────────────────────────────────────
@plans_bp.get("/plans")
def list_plans():
    try:
        sid   = request.args.get("species_id")
        query = PreventionPlan.query
        if sid:
            query = query.filter_by(species_id=int(sid))
        plans = query.all()
        return jsonify([{
            "plan_id": p.plan_id, "species_id": p.species_id, "title": p.title,
            "action_steps": p.action_steps, "success_rate": float(p.success_rate) if p.success_rate else None,
            "status": p.status, "start_date": str(p.start_date), "end_date": str(p.end_date),
            "budget_usd": float(p.budget_usd) if p.budget_usd else None
        } for p in plans])
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@plans_bp.post("/plans")
@jwt_required()
def create_plan():
    try:
        uid  = int(get_jwt_identity())
        data = request.get_json()
        p = PreventionPlan(created_by=uid, **{k: data[k] for k in
            ["species_id","title","action_steps","start_date","end_date","budget_usd","success_rate","org_id","status"]
            if k in data})
        db.session.add(p)
        db.session.commit()
        return jsonify({"plan_id": p.plan_id}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500


@plans_bp.put("/plans/<int:pid>")
@jwt_required()
def update_plan(pid):
    try:
        p    = PreventionPlan.query.get_or_404(pid)
        data = request.get_json()
        for f in ["title","action_steps","success_rate","status","budget_usd"]:
            if f in data:
                setattr(p, f, data[f])
        db.session.commit()
        return jsonify({"message": "Updated"})
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500