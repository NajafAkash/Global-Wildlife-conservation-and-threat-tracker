from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from extensions import db
from models.models import Species, ConservationStatus, Habitat, User, AnalyticsLog
from sqlalchemy import or_, text

species_bp = Blueprint("species", __name__)


def _log(user_id, action, entity_id):
    try:
        db.session.add(AnalyticsLog(user_id=user_id, action=action, entity_type="species", entity_id=entity_id))
        db.session.flush()
    except Exception as e:
        print(f"Logging error: {e}")


@species_bp.get("/species")
def list_species():
    try:
        q      = request.args.get("q", "")
        status = request.args.get("status")
        trend  = request.args.get("trend")
        page   = int(request.args.get("page", 1))
        per    = min(int(request.args.get("per_page", 20)), 100)

        query = Species.query
        if q:
            query = query.filter(or_(
                Species.common_name.ilike(f"%{q}%"),
                Species.scientific_name.ilike(f"%{q}%")
            ))
        if status:
            query = query.join(ConservationStatus).filter(ConservationStatus.code == status)
        if trend:
            query = query.filter(Species.population_trend == trend)

        paginated = query.paginate(page=page, per_page=per, error_out=False)
        return jsonify({
            "data":  [s.to_dict(include_relations=True) for s in paginated.items],
            "total": paginated.total,
            "pages": paginated.pages,
            "page":  page
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@species_bp.get("/species/<int:species_id>")
def get_species(species_id):
    try:
        s = Species.query.get_or_404(species_id)
        return jsonify(s.to_dict(include_relations=True))
    except Exception as e:
        return jsonify({"error": str(e)}), 404


@species_bp.post("/species")
@jwt_required()
def create_species():
    try:
        data = request.get_json()
        uid  = int(get_jwt_identity())
        user = User.query.get(uid)
        if user.role not in ("admin", "researcher"):
            return jsonify({"error": "Insufficient permissions"}), 403

        s = Species(
            common_name     =data["common_name"],
            scientific_name =data["scientific_name"],
            family          =data.get("family"),
            population_est  =data.get("population_est"),
            population_trend=data.get("population_trend", "unknown"),
            status_id       =data.get("status_id"),
            habitat_id      =data.get("habitat_id"),
            origin_era      =data.get("origin_era"),
            description     =data.get("description"),
            image_url       =data.get("image_url"),
            added_by        =uid
        )
        db.session.add(s)
        db.session.flush()
        _log(uid, "create_species", s.species_id)
        db.session.commit()
        return jsonify(s.to_dict()), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500


@species_bp.put("/species/<int:species_id>")
@jwt_required()
def update_species(species_id):
    try:
        uid  = int(get_jwt_identity())
        user = User.query.get(uid)
        if user.role not in ("admin", "researcher"):
            return jsonify({"error": "Insufficient permissions"}), 403

        s    = Species.query.get_or_404(species_id)
        data = request.get_json()
        for field in ["common_name","scientific_name","family","population_est",
                      "population_trend","status_id","habitat_id","description","image_url","origin_era"]:
            if field in data:
                setattr(s, field, data[field])

        _log(uid, "update_species", species_id)
        db.session.commit()
        return jsonify(s.to_dict())
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500


@species_bp.delete("/species/<int:species_id>")
@jwt_required()
def delete_species(species_id):
    try:
        uid  = int(get_jwt_identity())
        user = User.query.get(uid)
        if user.role != "admin":
            return jsonify({"error": "Admin only"}), 403

        s = Species.query.get_or_404(species_id)
        _log(uid, "delete_species", species_id)
        db.session.delete(s)
        db.session.commit()
        return jsonify({"message": "Deleted"})
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500


@species_bp.get("/species/stats/summary")
def stats_summary():
    try:
        rows = db.session.execute(text("""
            SELECT cs.code, cs.name, cs.color_hex, COUNT(s.species_id) AS total
            FROM conservation_status cs
            LEFT JOIN species s ON s.status_id = cs.status_id
            GROUP BY cs.status_id ORDER BY cs.status_id
        """)).fetchall()

        trend = db.session.execute(text("""
            SELECT population_trend, COUNT(*) AS cnt
            FROM species GROUP BY population_trend
        """)).fetchall()

        return jsonify({
            "by_status": [dict(r._mapping) for r in rows],
            "by_trend":  [dict(r._mapping) for r in trend],
            "total":     Species.query.count()
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500