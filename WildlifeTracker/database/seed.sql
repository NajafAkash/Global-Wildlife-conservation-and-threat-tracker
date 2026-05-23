-- ============================================================
--  WildlifeTracker — Seed Data
-- ============================================================
USE WildlifeTracker;

INSERT INTO organizations (name, type, country, website) VALUES
('World Wildlife Fund',         'ngo',        'Switzerland', 'https://wwf.org'),
('IUCN',                        'ngo',        'Switzerland', 'https://iucn.org'),
('Chinese Ministry of Ecology', 'government', 'China',       NULL),
('Snow Leopard Trust',          'ngo',        'USA',         'https://snowleopard.org'),
('WWF Russia',                  'ngo',        'Russia',      'https://wwf.ru');

-- Password: Admin@123 (bcrypt hash placeholder)
INSERT INTO users (username, email, password_hash, role, org_id) VALUES
('admin',       'admin@wildlife.org',      '$2b$12$placeholder_admin_hash',    'admin',      1),
('researcher1', 'r1@wildlife.org',         '$2b$12$placeholder_res_hash',      'researcher', 2),
('viewer1',     'viewer@wildlife.org',     '$2b$12$placeholder_view_hash',     'viewer',     NULL);

INSERT INTO habitats (name, biome, climate_zone) VALUES
('Bamboo Forests of Sichuan',  'Temperate Forest',  'Temperate'),
('Central Asian Highlands',    'Alpine',            'Subalpine'),
('Russian Far East Taiga',     'Boreal Forest',     'Continental'),
('Arctic Tundra',              'Tundra',            'Polar'),
('Tropical Coral Reefs',       'Marine',            'Tropical'),
('Amazon Rainforest',          'Tropical Rainforest','Tropical'),
('African Savanna',            'Savanna',           'Tropical'),
('Himalayan Mountains',        'Alpine',            'Subalpine');

INSERT INTO species (common_name, scientific_name, family, `order`, class, status_id, habitat_id, population_est, population_trend, origin_era, description, added_by) VALUES
('Giant Panda',      'Ailuropoda melanoleuca',    'Ursidae',    'Carnivora',    'Mammalia', 4, 1, 1864,  'increasing',  'Pleistocene', 'Large bear-like mammal endemic to central China, known for its black-and-white coloring.', 1),
('Snow Leopard',     'Panthera uncia',            'Felidae',    'Carnivora',    'Mammalia', 4, 2, 4500,  'decreasing',  'Pleistocene', 'Elusive mountain cat native to the rugged mountains of Central Asia.', 1),
('Amur Leopard',     'Panthera pardus orientalis','Felidae',    'Carnivora',    'Mammalia', 3, 3, 84,    'increasing',  'Holocene',    'The world''s rarest big cat, found in the Russian Far East.', 1),
('Sumatran Orangutan','Pongo abelii',             'Hominidae',  'Primates',     'Mammalia', 3, 6, 13846, 'decreasing',  'Holocene',    'Critically endangered great ape found only in North Sumatra.', 2),
('Blue Whale',       'Balaenoptera musculus',     'Balaenidae', 'Artiodactyla', 'Mammalia', 4, 5, 10000, 'increasing',  'Pliocene',    'The largest animal ever known to have lived on Earth.', 2),
('African Elephant', 'Loxodonta africana',        'Elephantidae','Proboscidea',  'Mammalia', 5, 7, 415000,'decreasing',  'Pleistocene', 'The largest land animal, keystone species of the African savanna.', 1),
('Vaquita',          'Phocoena sinus',            'Phocoenidae','Artiodactyla', 'Mammalia', 3, 5, 10,    'decreasing',  'Holocene',    'The world''s smallest and most critically endangered porpoise.', 2),
('Bengal Tiger',     'Panthera tigris tigris',    'Felidae',    'Carnivora',    'Mammalia', 4, 6, 2500,  'increasing',  'Pleistocene', 'The largest tiger subspecies, found across the Indian subcontinent.', 1);

INSERT INTO locations (name, country, region, latitude, longitude, area_km2, is_protected) VALUES
('Wolong Nature Reserve',   'China',      'Sichuan',          30.9200, 102.9800, 2000.00,  TRUE),
('Snow Leopard Habitat',    'Mongolia',   'Altai Mountains',  48.0000,  89.0000, 50000.00, FALSE),
('Land of the Leopard NP',  'Russia',     'Primorsky Krai',   43.2500, 131.5000, 2620.00,  TRUE),
('Gunung Leuser NP',        'Indonesia',  'North Sumatra',     3.7500,  97.2500, 7927.00,  TRUE),
('Southern Ocean',          'Antarctica', 'South Atlantic',  -60.0000, -45.0000, NULL,     FALSE),
('Amboseli National Park',  'Kenya',      'Rift Valley',       2.6527,  37.2606, 392.00,   TRUE),
('Gulf of California',      'Mexico',     'Baja California',  27.0000,-110.0000, NULL,     TRUE),
('Sundarbans',              'Bangladesh', 'Khulna Division',  21.9497,  89.1833, 10000.00, TRUE);

INSERT INTO species_locations (species_id, location_id, recorded_at) VALUES
(1,1,'2024-01-15'),(2,2,'2024-02-10'),(3,3,'2024-03-05'),
(4,4,'2024-01-20'),(5,5,'2024-04-12'),(6,6,'2024-02-28'),
(7,7,'2024-05-01'),(8,8,'2024-03-18');

INSERT INTO species_threats (species_id, threat_id, impact_level) VALUES
(1,1,'high'),(1,2,'critical'),(1,5,'moderate'),
(2,1,'critical'),(2,3,'high'),(2,7,'moderate'),
(3,1,'critical'),(3,2,'critical'),(3,5,'high'),
(4,2,'critical'),(4,5,'critical'),(4,7,'critical'),
(5,1,'high'),(5,4,'critical'),(5,3,'high'),
(6,1,'critical'),(6,7,'high'),(6,2,'high'),
(7,1,'critical'),(7,4,'high'),(7,5,'critical'),
(8,1,'high'),(8,2,'high'),(8,3,'moderate');

INSERT INTO prevention_plans (species_id, org_id, title, action_steps, start_date, end_date, budget_usd, success_rate, status, created_by) VALUES
(1, 1, 'Giant Panda Recovery Program', 'Expand bamboo corridors. Enforce anti-poaching laws. Run captive breeding program. Habitat restoration.', '2020-01-01','2025-12-31', 5000000.00, 82.50, 'active', 1),
(2, 4, 'Snow Leopard Conservation Initiative', 'Anti-poaching patrols. Prey base restoration. Transboundary agreements with 12 range countries.', '2021-06-01','2026-05-31', 2000000.00, 65.00, 'active', 1),
(3, 5, 'Amur Leopard Land Corridor Project', 'Strict anti-poaching enforcement. Land corridor creation. Cross-border cooperation with China.', '2022-01-01','2027-12-31', 3500000.00, 55.00, 'active', 1),
(6, 1, 'African Elephant Anti-Poaching Plan', 'Deploy ranger units. GPS tracking collars. International ivory trade ban enforcement.', '2019-01-01','2024-12-31', 8000000.00, 71.00, 'active', 1);

INSERT INTO tracking_reports (species_id, location_id, reported_by, report_date, population_obs, health_status, notes, verified) VALUES
(1, 1, 2, '2025-01-10', 22,  'healthy',  'Healthy breeding pair observed near bamboo grove.', TRUE),
(2, 2, 2, '2025-02-14', 8,   'stressed', 'Signs of food stress due to prey decline.', TRUE),
(3, 3, 2, '2025-03-01', 3,   'healthy',  'Three individuals spotted via camera trap.', TRUE),
(6, 6, 2, '2025-04-05', 340, 'healthy',  'Large herd migration monitored via aerial survey.', TRUE),
(7, 7, 2, '2025-05-02', 2,   'stressed', 'Only 2 individuals confirmed alive. Urgent.', FALSE);
