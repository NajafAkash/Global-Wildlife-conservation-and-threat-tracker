from datetime import datetime, timezone
from extensions import db

class Organization(db.Model):
    __tablename__ = "organizations"
    org_id        = db.Column(db.Integer, primary_key=True)
    name          = db.Column(db.String(150), nullable=False)
    type          = db.Column(db.Enum("ngo","government","research","private"), nullable=False)
    country       = db.Column(db.String(100))
    website       = db.Column(db.String(255))
    contact_email = db.Column(db.String(100))
    created_at    = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

class User(db.Model):
    __tablename__ = "users"
    user_id       = db.Column(db.Integer, primary_key=True)
    username      = db.Column(db.String(50), unique=True, nullable=False)
    email         = db.Column(db.String(100), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    role          = db.Column(db.Enum("admin","researcher","viewer"), default="viewer")
    org_id        = db.Column(db.Integer, db.ForeignKey("organizations.org_id"))
    created_at    = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    last_login    = db.Column(db.DateTime)
    is_active     = db.Column(db.Boolean, default=True)

    def to_dict(self):
        return {
            "user_id": self.user_id, "username": self.username,
            "email": self.email, "role": self.role,
            "org_id": self.org_id, "created_at": str(self.created_at)
        }

class ConservationStatus(db.Model):
    __tablename__ = "conservation_status"
    status_id    = db.Column(db.Integer, primary_key=True)
    code         = db.Column(db.String(10), unique=True, nullable=False)
    name         = db.Column(db.String(80), nullable=False)
    threat_level = db.Column(db.String(20))
    description  = db.Column(db.Text)
    color_hex    = db.Column(db.String(7))

    def to_dict(self):
        return {k: v for k, v in self.__dict__.items() if not k.startswith("_")}

class Habitat(db.Model):
    __tablename__ = "habitats"
    habitat_id   = db.Column(db.Integer, primary_key=True)
    name         = db.Column(db.String(100), nullable=False)
    biome        = db.Column(db.String(80))
    climate_zone = db.Column(db.String(80))
    description  = db.Column(db.Text)

class Species(db.Model):
    __tablename__    = "species"
    species_id       = db.Column(db.Integer, primary_key=True)
    common_name      = db.Column(db.String(120), nullable=False)
    scientific_name  = db.Column(db.String(120), unique=True, nullable=False)
    family           = db.Column(db.String(100))
    order            = db.Column("order", db.String(100))
    class_           = db.Column("class", db.String(100))
    kingdom          = db.Column(db.String(50), default="Animalia")
    status_id        = db.Column(db.Integer, db.ForeignKey("conservation_status.status_id"))
    habitat_id       = db.Column(db.Integer, db.ForeignKey("habitats.habitat_id"))
    population_est   = db.Column(db.BigInteger)
    population_trend = db.Column(db.String(20), default="unknown")
    origin_era       = db.Column(db.String(80))
    description      = db.Column(db.Text)
    image_url        = db.Column(db.String(500))
    added_by         = db.Column(db.Integer, db.ForeignKey("users.user_id"))
    created_at       = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at       = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    status  = db.relationship("ConservationStatus", backref="species")
    habitat = db.relationship("Habitat", backref="species")

    def to_dict(self, include_relations=False):
        d = {
            "species_id": self.species_id,
            "common_name": self.common_name,
            "scientific_name": self.scientific_name,
            "family": self.family,
            "population_est": self.population_est,
            "population_trend": self.population_trend,
            "origin_era": self.origin_era,
            "description": self.description,
            "image_url": self.image_url,
            "created_at": str(self.created_at),
        }
        if include_relations:
            d["status"] = self.status.to_dict() if self.status else None
        return d

class Threat(db.Model):
    __tablename__ = "threats"
    threat_id    = db.Column(db.Integer, primary_key=True)
    name         = db.Column(db.String(100), unique=True, nullable=False)
    category     = db.Column(db.String(50))
    description  = db.Column(db.Text)
    severity     = db.Column(db.String(20))

    def to_dict(self):
        return {k: v for k, v in self.__dict__.items() if not k.startswith("_")}

species_threats_table = db.Table("species_threats",
    db.Column("id",           db.Integer, primary_key=True),
    db.Column("species_id",   db.Integer, db.ForeignKey("species.species_id")),
    db.Column("threat_id",    db.Integer, db.ForeignKey("threats.threat_id")),
    db.Column("impact_level", db.String(20)),
    db.Column("notes",        db.Text),
    db.Column("recorded_at",  db.Date)
)

class Location(db.Model):
    __tablename__ = "locations"
    location_id  = db.Column(db.Integer, primary_key=True)
    name         = db.Column(db.String(150))
    country      = db.Column(db.String(100), nullable=False)
    region       = db.Column(db.String(100))
    latitude     = db.Column(db.Numeric(10, 7))
    longitude    = db.Column(db.Numeric(10, 7))
    area_km2     = db.Column(db.Numeric(12, 2))
    is_protected = db.Column(db.Boolean, default=False)

    def to_dict(self):
        return {
            "location_id": self.location_id, "name": self.name,
            "country": self.country, "region": self.region,
            "latitude": float(self.latitude), "longitude": float(self.longitude),
            "area_km2": float(self.area_km2) if self.area_km2 else None,
            "is_protected": self.is_protected
        }

class TrackingReport(db.Model):
    __tablename__   = "tracking_reports"
    report_id       = db.Column(db.Integer, primary_key=True)
    species_id      = db.Column(db.Integer, db.ForeignKey("species.species_id"), nullable=False)
    location_id     = db.Column(db.Integer, db.ForeignKey("locations.location_id"))
    reported_by     = db.Column(db.Integer, db.ForeignKey("users.user_id"))
    report_date     = db.Column(db.Date, nullable=False, default=lambda: datetime.now(timezone.utc).date())
    population_obs  = db.Column(db.Integer)
    health_status   = db.Column(db.String(20))
    threat_ids      = db.Column(db.JSON)  #-- FIXED: Added missing column
    notes           = db.Column(db.Text)
    verified        = db.Column(db.Boolean, default=False)
    created_at      = db.Column(db.DateTime, default=datetime.utcnow)

    species  = db.relationship("Species", backref="reports")
    location = db.relationship("Location", backref="reports")

class PreventionPlan(db.Model):
    __tablename__ = "prevention_plans"
    plan_id       = db.Column(db.Integer, primary_key=True)
    species_id    = db.Column(db.Integer, db.ForeignKey("species.species_id"), nullable=False)
    org_id        = db.Column(db.Integer, db.ForeignKey("organizations.org_id"))
    title         = db.Column(db.String(200), nullable=False)
    action_steps  = db.Column(db.Text, nullable=False)
    start_date    = db.Column(db.Date)
    end_date      = db.Column(db.Date)
    budget_usd    = db.Column(db.Numeric(15, 2))
    success_rate  = db.Column(db.Numeric(5, 2))
    status        = db.Column(db.String(20), default="planned")
    created_by    = db.Column(db.Integer, db.ForeignKey("users.user_id"))
    created_at    = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

class AnalyticsLog(db.Model):
    __tablename__ = "analytics_logs"
    log_id       = db.Column(db.Integer, primary_key=True)
    user_id      = db.Column(db.Integer, db.ForeignKey("users.user_id"))
    action       = db.Column(db.String(100), nullable=False)
    entity_type  = db.Column(db.String(50))
    entity_id    = db.Column(db.Integer)
    log_metadata = db.Column(db.JSON)
    ip_address   = db.Column(db.String(45))
    created_at   = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))