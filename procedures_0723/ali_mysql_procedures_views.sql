-- ============================================================
--  WildlifeCareChecker | Muhammad Ali (24P-0723)
--  Part 1: Stored Procedures & Views (Frontend-to-Data Logic)
--  Part 3: At-Risk Animal → Prevention Plan Queries
-- ============================================================

USE WildlifeCareChecker;


-- ==============================================================
--  SECTION 1 — VIEWS
--  Views act as "virtual tables" that the frontend queries
--  directly instead of writing raw JOINs every time.
-- ==============================================================

-- View 1: Full animal profile with conservation status attached
-- Frontend use: Display animal info card with its threat level
CREATE OR REPLACE VIEW vw_Animal_Full_Profile AS
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


-- View 2: Animals currently "At Risk" with their prevention plans
-- Frontend use: Dashboard listing endangered animals + their survival roadmap
CREATE OR REPLACE VIEW vw_AtRisk_Animals_With_Plans AS
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
JOIN Conservation_Status cs  ON a.Status_ID     = cs.Status_ID
JOIN Prevention_Plan     pp  ON a.Animal_ID      = pp.Animal_ID
WHERE cs.Threat_Level IN ('High', 'Critical', 'Endangered', 'At Risk');


-- View 3: Species timeline (animal + all its historical records)
-- Frontend use: Timeline/history page for a chosen animal
CREATE OR REPLACE VIEW vw_Species_Timeline AS
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


-- ==============================================================
--  SECTION 2 — STORED PROCEDURES (CRUD LOGIC)
--  Each procedure maps to one CRUD operation the frontend calls.
-- ==============================================================

-- ---------------------------------------------------------------
-- CREATE procedures
-- ---------------------------------------------------------------

DELIMITER $$

-- Add a new animal (Admin only action from the frontend)
CREATE PROCEDURE sp_Create_Animal (
    IN p_Common_Name        VARCHAR(100),
    IN p_Scientific_Name    VARCHAR(100),
    IN p_Description        TEXT,
    IN p_Origin_Era         VARCHAR(50),
    IN p_Status_ID          INT
)
BEGIN
    INSERT INTO Animal (Common_Name, Scientific_Name, General_Description, Origin_Era, Status_ID)
    VALUES (p_Common_Name, p_Scientific_Name, p_Description, p_Origin_Era, p_Status_ID);

    -- Return the new animal's ID so the frontend can redirect to its page
    SELECT LAST_INSERT_ID() AS New_Animal_ID;
END$$


-- Add a historical record for an existing animal
CREATE PROCEDURE sp_Create_Species_History (
    IN p_Animal_ID          INT,
    IN p_Era_Name           VARCHAR(50),
    IN p_Population_Estimate INT,
    IN p_Habitat_Type       VARCHAR(100)
)
BEGIN
    INSERT INTO Species_History (Animal_ID, Era_Name, Population_Estimate, Habitat_Type)
    VALUES (p_Animal_ID, p_Era_Name, p_Population_Estimate, p_Habitat_Type);

    SELECT LAST_INSERT_ID() AS New_History_ID;
END$$


-- Add a prevention plan for an at-risk animal
CREATE PROCEDURE sp_Create_Prevention_Plan (
    IN p_Animal_ID              INT,
    IN p_Action_Steps           TEXT,
    IN p_Organization_Involved  VARCHAR(100),
    IN p_Success_Rate           DECIMAL(5,2)
)
BEGIN
    INSERT INTO Prevention_Plan (Animal_ID, Action_Steps, Organization_Involved, Success_Rate)
    VALUES (p_Animal_ID, p_Action_Steps, p_Organization_Involved, p_Success_Rate);

    SELECT LAST_INSERT_ID() AS New_Plan_ID;
END$$


-- ---------------------------------------------------------------
-- READ procedures
-- ---------------------------------------------------------------

-- Search animals by name (Viewer and Admin — main search bar)
CREATE PROCEDURE sp_Search_Animal (
    IN p_Search_Term VARCHAR(100)
)
BEGIN
    SELECT *
    FROM vw_Animal_Full_Profile
    WHERE Common_Name    LIKE CONCAT('%', p_Search_Term, '%')
       OR Scientific_Name LIKE CONCAT('%', p_Search_Term, '%');
END$$


-- Get full profile of one animal by ID
CREATE PROCEDURE sp_Get_Animal_By_ID (
    IN p_Animal_ID INT
)
BEGIN
    SELECT * FROM vw_Animal_Full_Profile
    WHERE Animal_ID = p_Animal_ID;
END$$


-- Get all historical records for one animal
CREATE PROCEDURE sp_Get_Species_History (
    IN p_Animal_ID INT
)
BEGIN
    SELECT * FROM Species_History
    WHERE Animal_ID = p_Animal_ID
    ORDER BY Era_Name;
END$$


-- ---------------------------------------------------------------
-- UPDATE procedures
-- ---------------------------------------------------------------

-- Update an animal's conservation status
-- (Called from the frontend when admin submits new status)
CREATE PROCEDURE sp_Update_Animal_Status (
    IN p_Animal_ID  INT,
    IN p_Status_ID  INT
)
BEGIN
    UPDATE Animal
    SET Status_ID = p_Status_ID
    WHERE Animal_ID = p_Animal_ID;

    SELECT ROW_COUNT() AS Rows_Updated;
END$$


-- Update population estimate in species history
-- (Called when an admin enters a new environmental report's numbers)
CREATE PROCEDURE sp_Update_Population (
    IN p_History_ID          INT,
    IN p_New_Population      INT
)
BEGIN
    UPDATE Species_History
    SET Population_Estimate = p_New_Population
    WHERE History_ID = p_History_ID;

    SELECT ROW_COUNT() AS Rows_Updated;
END$$


-- Update a prevention plan's action steps and success rate
CREATE PROCEDURE sp_Update_Prevention_Plan (
    IN p_Plan_ID            INT,
    IN p_Action_Steps       TEXT,
    IN p_Success_Rate       DECIMAL(5,2)
)
BEGIN
    UPDATE Prevention_Plan
    SET Action_Steps  = p_Action_Steps,
        Success_Rate  = p_Success_Rate
    WHERE Plan_ID = p_Plan_ID;

    SELECT ROW_COUNT() AS Rows_Updated;
END$$


-- ---------------------------------------------------------------
-- DELETE procedures
-- ---------------------------------------------------------------

-- Delete an animal (cascades to history + prevention plan via FK constraints)
CREATE PROCEDURE sp_Delete_Animal (
    IN p_Animal_ID INT
)
BEGIN
    DELETE FROM Animal
    WHERE Animal_ID = p_Animal_ID;

    SELECT ROW_COUNT() AS Rows_Deleted;
END$$


-- Delete a single historical record (keeps the animal intact)
CREATE PROCEDURE sp_Delete_Species_History (
    IN p_History_ID INT
)
BEGIN
    DELETE FROM Species_History
    WHERE History_ID = p_History_ID;

    SELECT ROW_COUNT() AS Rows_Deleted;
END$$


DELIMITER ;


-- ==============================================================
--  SECTION 3 — ACTIONABLE PREVENTION PLAN QUERIES
--  These are the "Survival Roadmap" queries Muhammad Ali must
--  write. When a user looks up an at-risk animal, these queries
--  fire to display its full prevention roadmap.
-- ==============================================================

-- Query 3-A: Survival Roadmap — given an animal name, show
--            its conservation status + every prevention plan step
SELECT
    a.Common_Name,
    a.Scientific_Name,
    cs.Status_Name,
    cs.Threat_Level,
    pp.Plan_ID,
    pp.Action_Steps         AS Survival_Steps,
    pp.Organization_Involved,
    pp.Success_Rate         AS Success_Rate_Percent
FROM Animal a
JOIN Conservation_Status cs ON a.Status_ID  = cs.Status_ID
JOIN Prevention_Plan     pp ON a.Animal_ID  = pp.Animal_ID
WHERE a.Common_Name = 'Giant Panda'   -- replace with a parameter / frontend input
ORDER BY pp.Success_Rate DESC;


-- Query 3-B: List ALL at-risk animals that have NO prevention plan yet
--            (Admin dashboard alert — these animals need urgent attention)
SELECT
    a.Animal_ID,
    a.Common_Name,
    a.Scientific_Name,
    cs.Status_Name,
    cs.Threat_Level
FROM Animal a
JOIN  Conservation_Status cs ON a.Status_ID = cs.Status_ID
LEFT JOIN Prevention_Plan pp ON a.Animal_ID = pp.Animal_ID
WHERE cs.Threat_Level IN ('High', 'Critical', 'Endangered', 'At Risk')
  AND pp.Plan_ID IS NULL
ORDER BY cs.Threat_Level, a.Common_Name;


-- Query 3-C: Best-performing prevention plans across all species
--            (Success rate >= 70%) — shows what is actually working
SELECT
    a.Common_Name,
    cs.Threat_Level,
    pp.Organization_Involved,
    pp.Action_Steps,
    pp.Success_Rate
FROM Prevention_Plan pp
JOIN Animal              a  ON pp.Animal_ID = a.Animal_ID
JOIN Conservation_Status cs ON a.Status_ID  = cs.Status_ID
WHERE pp.Success_Rate >= 70.00
ORDER BY pp.Success_Rate DESC;


-- Query 3-D: Prevention plan lookup using the vw_AtRisk_Animals_With_Plans view
--            (This is what the frontend calls for the "Survival Roadmap" page)
SELECT *
FROM vw_AtRisk_Animals_With_Plans
ORDER BY Threat_Level, Common_Name;
