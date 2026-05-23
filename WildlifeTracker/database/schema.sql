-- ============================================================
--  Global Wildlife Conservation & Threat Tracker
--  MySQL Schema v1.0
-- ============================================================

CREATE DATABASE IF NOT EXISTS WildlifeTracker CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE WildlifeTracker;

-- ── Users ────────────────────────────────────────────────────
CREATE TABLE users (
    user_id       INT PRIMARY KEY AUTO_INCREMENT,
    username      VARCHAR(50)  NOT NULL UNIQUE,
    email         VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role          ENUM('admin','researcher','viewer') NOT NULL DEFAULT 'viewer',
    org_id        INT,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login    TIMESTAMP NULL,
    is_active     BOOLEAN DEFAULT TRUE
);

-- ── Organizations ────────────────────────────────────────────
CREATE TABLE organizations (
    org_id       INT PRIMARY KEY AUTO_INCREMENT,
    name         VARCHAR(150) NOT NULL,
    type         ENUM('ngo','government','research','private') NOT NULL,
    country      VARCHAR(100),
    website      VARCHAR(255),
    contact_email VARCHAR(100),
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE users ADD FOREIGN KEY (org_id) REFERENCES organizations(org_id) ON DELETE SET NULL;

-- ── Conservation Status ──────────────────────────────────────
CREATE TABLE conservation_status (
    status_id    INT PRIMARY KEY AUTO_INCREMENT,
    code         VARCHAR(10)  NOT NULL UNIQUE,
    name         VARCHAR(80)  NOT NULL,
    threat_level ENUM('extinct','critical','high','moderate','low','none') NOT NULL,
    description  TEXT,
    color_hex    VARCHAR(7)
);

INSERT INTO conservation_status (code, name, threat_level, color_hex) VALUES
('EX',  'Extinct',              'extinct',  '#1a1a2e'),
('EW',  'Extinct in Wild',      'critical', '#4a0e0e'),
('CR',  'Critically Endangered','critical', '#dc2626'),
('EN',  'Endangered',           'high',     '#ea580c'),
('VU',  'Vulnerable',           'moderate', '#d97706'),
('NT',  'Near Threatened',      'low',      '#ca8a04'),
('LC',  'Least Concern',        'none',     '#16a34a');

-- ── Habitats ─────────────────────────────────────────────────
CREATE TABLE habitats (
    habitat_id   INT PRIMARY KEY AUTO_INCREMENT,
    name         VARCHAR(100) NOT NULL,
    biome        VARCHAR(80),
    climate_zone VARCHAR(80),
    description  TEXT
);

-- ── Species ──────────────────────────────────────────────────
CREATE TABLE species (
    species_id       INT PRIMARY KEY AUTO_INCREMENT,
    common_name      VARCHAR(120) NOT NULL,
    scientific_name  VARCHAR(120) NOT NULL UNIQUE,
    family           VARCHAR(100),
    `order`          VARCHAR(100),
    class            VARCHAR(100),
    kingdom          ENUM('Animalia','Plantae','Fungi','Protista') DEFAULT 'Animalia',
    status_id        INT,
    habitat_id       INT,
    population_est   BIGINT,
    population_trend ENUM('increasing','stable','decreasing','unknown') DEFAULT 'unknown',
    origin_era       VARCHAR(80),
    description      TEXT,
    image_url        VARCHAR(500),
    added_by         INT,
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (status_id)  REFERENCES conservation_status(status_id) ON DELETE SET NULL,
    FOREIGN KEY (habitat_id) REFERENCES habitats(habitat_id) ON DELETE SET NULL,
    FOREIGN KEY (added_by)   REFERENCES users(user_id) ON DELETE SET NULL
);

-- ── Locations ────────────────────────────────────────────────
CREATE TABLE locations (
    location_id  INT PRIMARY KEY AUTO_INCREMENT,
    name         VARCHAR(150),
    country      VARCHAR(100) NOT NULL,
    region       VARCHAR(100),
    latitude     DECIMAL(10,7) NOT NULL,
    longitude    DECIMAL(10,7) NOT NULL,
    area_km2     DECIMAL(12,2),
    is_protected BOOLEAN DEFAULT FALSE
);

-- ── Species Locations (many-to-many) ────────────────────────
CREATE TABLE species_locations (
    id          INT PRIMARY KEY AUTO_INCREMENT,
    species_id  INT NOT NULL,
    location_id INT NOT NULL,
    recorded_at DATE,
    notes       TEXT,
    FOREIGN KEY (species_id)  REFERENCES species(species_id)  ON DELETE CASCADE,
    FOREIGN KEY (location_id) REFERENCES locations(location_id) ON DELETE CASCADE,
    UNIQUE KEY uq_species_loc (species_id, location_id)
);

-- ── Threats ──────────────────────────────────────────────────
CREATE TABLE threats (
    threat_id    INT PRIMARY KEY AUTO_INCREMENT,
    name         VARCHAR(100) NOT NULL UNIQUE,
    category     ENUM('poaching','habitat_loss','climate_change','pollution','invasive_species','disease','illegal_trade','other') NOT NULL,
    description  TEXT,
    severity     ENUM('critical','high','moderate','low') DEFAULT 'moderate'
);

INSERT INTO threats (name, category, severity) VALUES
('Illegal Poaching',          'poaching',         'critical'),
('Deforestation',             'habitat_loss',     'critical'),
('Climate Change',            'climate_change',   'high'),
('Ocean Pollution',           'pollution',        'high'),
('Illegal Wildlife Trade',    'illegal_trade',    'critical'),
('Invasive Species',          'invasive_species', 'moderate'),
('Agricultural Expansion',    'habitat_loss',     'high'),
('Industrial Pollution',      'pollution',        'high'),
('Drought & Water Scarcity',  'climate_change',   'moderate'),
('Disease Outbreak',          'disease',          'moderate');

-- ── Species Threats (many-to-many) ──────────────────────────
CREATE TABLE species_threats (
    id           INT PRIMARY KEY AUTO_INCREMENT,
    species_id   INT NOT NULL,
    threat_id    INT NOT NULL,
    impact_level ENUM('critical','high','moderate','low') DEFAULT 'moderate',
    notes        TEXT,
    recorded_at  DATE DEFAULT (CURRENT_DATE),
    FOREIGN KEY (species_id) REFERENCES species(species_id) ON DELETE CASCADE,
    FOREIGN KEY (threat_id)  REFERENCES threats(threat_id)  ON DELETE CASCADE,
    UNIQUE KEY uq_species_threat (species_id, threat_id)
);

-- ── Tracking Reports ─────────────────────────────────────────
CREATE TABLE tracking_reports (
    report_id      INT PRIMARY KEY AUTO_INCREMENT,
    species_id     INT NOT NULL,
    location_id    INT,
    reported_by    INT,
    report_date    DATE NOT NULL DEFAULT (CURRENT_DATE),
    population_obs INT,
    health_status  ENUM('healthy','stressed','injured','unknown') DEFAULT 'unknown',
    threat_ids     JSON,
    notes          TEXT,
    verified       BOOLEAN DEFAULT FALSE,
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (species_id)  REFERENCES species(species_id)  ON DELETE CASCADE,
    FOREIGN KEY (location_id) REFERENCES locations(location_id) ON DELETE SET NULL,
    FOREIGN KEY (reported_by) REFERENCES users(user_id) ON DELETE SET NULL
);

-- ── Prevention Plans ─────────────────────────────────────────
CREATE TABLE prevention_plans (
    plan_id      INT PRIMARY KEY AUTO_INCREMENT,
    species_id   INT NOT NULL,
    org_id       INT,
    title        VARCHAR(200) NOT NULL,
    action_steps TEXT NOT NULL,
    start_date   DATE,
    end_date     DATE,
    budget_usd   DECIMAL(15,2),
    success_rate DECIMAL(5,2),
    status       ENUM('planned','active','completed','cancelled') DEFAULT 'planned',
    created_by   INT,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (species_id) REFERENCES species(species_id) ON DELETE CASCADE,
    FOREIGN KEY (org_id)     REFERENCES organizations(org_id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(user_id) ON DELETE SET NULL
);

-- ── Analytics Logs ───────────────────────────────────────────
CREATE TABLE analytics_logs (
    log_id      INT PRIMARY KEY AUTO_INCREMENT,
    user_id     INT,
    action      VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50),
    entity_id   INT,
    log_metadata JSON,  -- FIXED FROM metadata TO log_metadata
    ip_address  VARCHAR(45),
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL
);

-- ── Species History ──────────────────────────────────────────
CREATE TABLE species_history (
    history_id          INT PRIMARY KEY AUTO_INCREMENT,
    species_id          INT NOT NULL,
    era_name            VARCHAR(80) NOT NULL,
    population_estimate BIGINT,
    habitat_type        VARCHAR(120),
    recorded_at         DATE,
    notes               TEXT,
    FOREIGN KEY (species_id) REFERENCES species(species_id) ON DELETE CASCADE
);

-- ── Views ────────────────────────────────────────────────────
CREATE OR REPLACE VIEW vw_species_dashboard AS
SELECT
    s.species_id, s.common_name, s.scientific_name, s.population_est,
    s.population_trend, s.image_url,
    cs.code AS status_code, cs.name AS status_name,
    cs.threat_level, cs.color_hex,
    h.name AS habitat_name, h.biome,
    COUNT(DISTINCT st.threat_id)  AS threat_count,
    COUNT(DISTINCT sl.location_id) AS location_count
FROM species s
LEFT JOIN conservation_status cs ON s.status_id  = cs.status_id
LEFT JOIN habitats h              ON s.habitat_id = h.habitat_id
LEFT JOIN species_threats st      ON s.species_id = st.species_id
LEFT JOIN species_locations sl    ON s.species_id = sl.species_id
GROUP BY s.species_id;

CREATE OR REPLACE VIEW vw_threat_summary AS
SELECT
    t.threat_id, t.name, t.category, t.severity,
    COUNT(st.species_id) AS affected_species
FROM threats t
LEFT JOIN species_threats st ON t.threat_id = st.threat_id
GROUP BY t.threat_id
ORDER BY affected_species DESC;

CREATE OR REPLACE VIEW vw_analytics_summary AS
SELECT
    DATE(created_at) AS log_date,
    action,
    COUNT(*) AS occurrences
FROM analytics_logs
GROUP BY DATE(created_at), action
ORDER BY log_date DESC;

-- ── Indexes ──────────────────────────────────────────────────
CREATE INDEX idx_species_status   ON species(status_id);
CREATE INDEX idx_species_name     ON species(common_name);
CREATE INDEX idx_reports_date     ON tracking_reports(report_date);
CREATE INDEX idx_logs_created     ON analytics_logs(created_at);
CREATE INDEX idx_species_sci_name ON species(scientific_name);