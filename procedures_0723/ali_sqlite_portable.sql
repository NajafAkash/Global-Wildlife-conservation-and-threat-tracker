-- ============================================================
--  WildlifeCareChecker | Muhammad Ali (24P-0723)
--  Part 2: SQLite3 Portable Version
--
--  This is the single-file, offline/portable version of the
--  project. Run it with: sqlite3 wildlife.db < ali_sqlite.sql
--  Or open wildlife.db in DB Browser for SQLite.
--
--  Key differences from MySQL version:
--    - No AUTO_INCREMENT  → use INTEGER PRIMARY KEY (SQLite auto-increments)
--    - No CHECK(Role IN…) → enforced via a trigger instead
--    - No DECIMAL(5,2)    → use REAL
--    - No DATABASE / USE  → SQLite is a single file, no concept of databases
--    - FOREIGN KEY support requires: PRAGMA foreign_keys = ON;
-- ============================================================

PRAGMA foreign_keys = ON;   -- must be turned on per connection in SQLite


-- ---------------------------------------------------------------
--  TABLES
-- ---------------------------------------------------------------

CREATE TABLE IF NOT EXISTS User (
    User_ID    INTEGER PRIMARY KEY,   -- SQLite auto-increments this
    User_Name  TEXT    NOT NULL UNIQUE,
    Password   TEXT    NOT NULL,
    Role       TEXT    NOT NULL DEFAULT 'Viewer'
);

-- SQLite has no CHECK constraint on IN(...) reliably in older versions,
-- so we enforce the Role rule with a trigger.
CREATE TRIGGER IF NOT EXISTS trg_User_Role_Check
BEFORE INSERT ON User
BEGIN
    SELECT RAISE(ABORT, 'Role must be Admin or Viewer')
    WHERE NEW.Role NOT IN ('Admin', 'Viewer');
END;

CREATE TRIGGER IF NOT EXISTS trg_User_Role_Check_Update
BEFORE UPDATE OF Role ON User
BEGIN
    SELECT RAISE(ABORT, 'Role must be Admin or Viewer')
    WHERE NEW.Role NOT IN ('Admin', 'Viewer');
END;


CREATE TABLE IF NOT EXISTS Conservation_Status (
    Status_ID         INTEGER PRIMARY KEY,
    Status_Name       TEXT    NOT NULL,
    Threat_Level      TEXT,
    Criteria_for_Status TEXT
);


CREATE TABLE IF NOT EXISTS Animal (
    Animal_ID          INTEGER PRIMARY KEY,
    Common_Name        TEXT    NOT NULL,
    Scientific_Name    TEXT,
    General_Description TEXT,
    Origin_Era         TEXT,
    Status_ID          INTEGER,
    FOREIGN KEY (Status_ID) REFERENCES Conservation_Status(Status_ID)
        ON DELETE SET NULL
);


CREATE TABLE IF NOT EXISTS Species_History (
    History_ID          INTEGER PRIMARY KEY,
    Animal_ID           INTEGER NOT NULL,
    Era_Name            TEXT    NOT NULL,
    Population_Estimate INTEGER,
    Habitat_Type        TEXT,
    FOREIGN KEY (Animal_ID) REFERENCES Animal(Animal_ID)
        ON DELETE CASCADE
);


CREATE TABLE IF NOT EXISTS Prevention_Plan (
    Plan_ID              INTEGER PRIMARY KEY,
    Animal_ID            INTEGER NOT NULL,
    Action_Steps         TEXT    NOT NULL,
    Organization_Involved TEXT,
    Success_Rate         REAL,           -- REAL replaces DECIMAL in SQLite
    FOREIGN KEY (Animal_ID) REFERENCES Animal(Animal_ID)
        ON DELETE CASCADE
);


-- ---------------------------------------------------------------
--  VIEWS  (identical logic to MySQL views — syntax is the same)
-- ---------------------------------------------------------------

CREATE VIEW IF NOT EXISTS vw_Animal_Full_Profile AS
SELECT
    a.Animal_ID,
    a.Common_Name,
    a.Scientific_Name,
    a.General_Description,
    a.Origin_Era,
    cs.Status_Name,
    cs.Threat_Level,
    cs.Criteria_for_Status
FROM Animal a
LEFT JOIN Conservation_Status cs ON a.Status_ID = cs.Status_ID;


CREATE VIEW IF NOT EXISTS vw_AtRisk_Animals_With_Plans AS
SELECT
    a.Animal_ID,
    a.Common_Name,
    a.Scientific_Name,
    cs.Status_Name,
    cs.Threat_Level,
    pp.Plan_ID,
    pp.Action_Steps,
    pp.Organization_Involved,
    pp.Success_Rate
FROM Animal a
JOIN Conservation_Status cs ON a.Status_ID = cs.Status_ID
JOIN Prevention_Plan     pp ON a.Animal_ID = pp.Animal_ID
WHERE cs.Threat_Level IN ('High', 'Critical', 'Endangered', 'At Risk');


CREATE VIEW IF NOT EXISTS vw_Species_Timeline AS
SELECT
    a.Animal_ID,
    a.Common_Name,
    a.Scientific_Name,
    sh.History_ID,
    sh.Era_Name,
    sh.Population_Estimate,
    sh.Habitat_Type
FROM Animal a
JOIN Species_History sh ON a.Animal_ID = sh.Animal_ID
ORDER BY a.Common_Name, sh.Era_Name;


-- ---------------------------------------------------------------
--  SAMPLE DATA  (for testing & quick search demos)
-- ---------------------------------------------------------------

INSERT INTO User (User_Name, Password, Role) VALUES
    ('admin_ali',   'hashed_password_1', 'Admin'),
    ('viewer_test', 'hashed_password_2', 'Viewer');

INSERT INTO Conservation_Status (Status_Name, Threat_Level, Criteria_for_Status) VALUES
    ('Vulnerable',        'High',     'Population declined >30% over 10 years'),
    ('Endangered',        'Critical', 'Population declined >50% over 10 years'),
    ('Critically Endangered', 'At Risk', 'Fewer than 250 mature individuals remain'),
    ('Extinct in Wild',   'Extinct',  'No individuals surviving outside captivity'),
    ('Least Concern',     'Low',      'Population stable, no major threats');

INSERT INTO Animal (Common_Name, Scientific_Name, General_Description, Origin_Era, Status_ID) VALUES
    ('Giant Panda',   'Ailuropoda melanoleuca', 'Large bear-like mammal from central China.',      'Pleistocene Era', 1),
    ('Snow Leopard',  'Panthera uncia',         'Mountain cat native to Central Asian ranges.',    'Pleistocene Era', 2),
    ('Amur Leopard',  'Panthera pardus orientalis','Rarest big cat in the world.',                 'Holocene Era',    3),
    ('Woolly Mammoth','Mammuthus primigenius',   'Ice-age elephant, now extinct.',                 'Pleistocene Era', 4),
    ('Common Pigeon', 'Columba livia',           'Highly adaptable bird found worldwide.',         'Holocene Era',    5);

INSERT INTO Species_History (Animal_ID, Era_Name, Population_Estimate, Habitat_Type) VALUES
    (1, 'Pleistocene Era', 100000, 'Bamboo forests'),
    (1, '20th Century',     2500,  'Fragmented bamboo reserves'),
    (1, 'Modern Day',       1864,  'Protected reserves, China'),
    (2, 'Pleistocene Era',  50000, 'Mountain ranges'),
    (2, 'Modern Day',        4500, 'Central Asian highlands'),
    (3, 'Modern Day',          84, 'Russian Far East forests'),
    (4, 'Pleistocene Era', 500000, 'Arctic tundra, grasslands'),
    (4, '10000 BCE',          200, 'Isolated Arctic islands'),
    (5, 'Modern Day',   400000000, 'Urban and rural worldwide');

INSERT INTO Prevention_Plan (Animal_ID, Action_Steps, Organization_Involved, Success_Rate) VALUES
    (1, 'Expand bamboo reserve corridors. Ban poaching. Captive breeding program.',
        'WWF, Chinese Government', 82.50),
    (2, 'Anti-poaching patrols. Prey base restoration. Transboundary protection agreements.',
        'Snow Leopard Trust', 65.00),
    (3, 'Strict anti-poaching laws. Land corridor creation. Cross-border conservation with China.',
        'WWF, Russian Government', 55.00);


-- ---------------------------------------------------------------
--  QUICK SEARCH QUERIES (for portable/offline use)
-- ---------------------------------------------------------------

-- Search by animal name
-- SELECT * FROM vw_Animal_Full_Profile WHERE Common_Name LIKE '%Panda%';

-- Get survival roadmap for a specific animal
-- SELECT * FROM vw_AtRisk_Animals_With_Plans WHERE Common_Name = 'Giant Panda';

-- View all species timelines
-- SELECT * FROM vw_Species_Timeline;

-- Animals with no prevention plan (admin alert)
-- SELECT a.Animal_ID, a.Common_Name, cs.Threat_Level
-- FROM Animal a
-- JOIN Conservation_Status cs ON a.Status_ID = cs.Status_ID
-- LEFT JOIN Prevention_Plan pp ON a.Animal_ID = pp.Animal_ID
-- WHERE cs.Threat_Level IN ('High','Critical','Endangered','At Risk')
--   AND pp.Plan_ID IS NULL;
