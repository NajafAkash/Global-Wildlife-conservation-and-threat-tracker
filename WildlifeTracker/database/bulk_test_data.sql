USE WildlifeTracker;

-- ── 1. Add New Habitats ──────────────────────────────────────────
INSERT INTO habitats (name, biome, climate_zone) VALUES
('Congo Basin Rainforest', 'Tropical Rainforest', 'Tropical'),
('Great Barrier Reef',     'Marine',              'Tropical'),
('Mojave Desert',          'Desert',              'Arid'),
('Siberian Tundra',        'Tundra',              'Polar'),
('Madagascar Dry Forests', 'Dry Forest',          'Tropical');

-- ── 2. Add 20 New Species ────────────────────────────────────────
-- Statuses: 3=CR, 4=EN, 5=VU, 6=NT, 7=LC. Added by user 1 (Admin)
INSERT INTO species (common_name, scientific_name, family, status_id, habitat_id, population_est, population_trend, added_by) VALUES
('Black Rhinoceros', 'Diceros bicornis', 'Rhinocerotidae', 3, 7, 5630, 'increasing', 1),
('Mountain Gorilla', 'Gorilla beringei beringei', 'Hominidae', 4, 9, 1063, 'increasing', 1),
('Hawksbill Turtle', 'Eretmochelys imbricata', 'Cheloniidae', 3, 10, 20000, 'decreasing', 1),
('Galapagos Penguin', 'Spheniscus mendiculus', 'Spheniscidae', 4, 10, 1200, 'decreasing', 1),
('Polar Bear', 'Ursus maritimus', 'Ursidae', 5, 4, 26000, 'decreasing', 1),
('Cheetah', 'Acinonyx jubatus', 'Felidae', 5, 7, 7100, 'decreasing', 1),
('Red Panda', 'Ailurus fulgens', 'Ailuridae', 4, 8, 10000, 'decreasing', 1),
('Koala', 'Phascolarctos cinereus', 'Phascolarctidae', 5, 1, 330000, 'decreasing', 1),
('Green Turtle', 'Chelonia mydas', 'Cheloniidae', 4, 10, 85000, 'decreasing', 1),
('Javan Rhinoceros', 'Rhinoceros sondaicus', 'Rhinocerotidae', 3, 6, 75, 'stable', 1),
('Saola', 'Pseudoryx nghetinhensis', 'Bovidae', 3, 6, 25, 'decreasing', 1),
('Kakapo', 'Strigops habroptilus', 'Strigopidae', 3, 1, 252, 'increasing', 1),
('Gharial', 'Gavialis gangeticus', 'Gavialidae', 3, 6, 650, 'increasing', 1),
('Bluefin Tuna', 'Thunnus thynnus', 'Scombridae', 4, 5, 45000, 'decreasing', 1),
('Whale Shark', 'Rhincodon typus', 'Rhincodontidae', 4, 5, 120000, 'decreasing', 1),
('Snowy Owl', 'Bubo scandiacus', 'Strigidae', 5, 4, 28000, 'decreasing', 1),
('Komodo Dragon', 'Varanus komodoensis', 'Varanidae', 4, 7, 3000, 'stable', 1),
('Emperor Penguin', 'Aptenodytes forsteri', 'Spheniscidae', 6, 4, 595000, 'decreasing', 1),
('Monarch Butterfly', 'Danaus plexippus', 'Nymphalidae', 4, 1, 250000, 'decreasing', 1),
('Narwhal', 'Monodon monoceros', 'Monodontidae', 7, 4, 170000, 'stable', 1);

-- ── 3. Add 10 New Global Locations ───────────────────────────────
INSERT INTO locations (name, country, region, latitude, longitude, area_km2, is_protected) VALUES
('Congo National Park', 'DRC', 'Congo Basin', -0.5000, 24.0000, 30000.00, TRUE),
('Great Barrier Reef', 'Australia', 'Queensland', -18.2800, 147.7000, 344400.00, TRUE),
('Yellowstone NP', 'USA', 'Wyoming', 44.4200, -110.5800, 8983.00, TRUE),
('Serengeti NP', 'Tanzania', 'Mara', -2.3300, 34.8300, 14750.00, TRUE),
('Galapagos Islands', 'Ecuador', 'Galapagos', -0.6500, -90.3500, 8010.00, TRUE),
('Svalbard Reserve', 'Norway', 'Svalbard', 78.0000, 16.0000, 61000.00, TRUE),
('Madagascar Forests', 'Madagascar', 'Atsinanana', -18.0000, 48.0000, 4500.00, TRUE),
('Gobi Desert', 'Mongolia', 'Ömnögovi', 43.0000, 105.0000, 1295000.00, FALSE),
('Kruger National Park', 'South Africa', 'Mpumalanga', -23.9800, 31.5500, 19485.00, TRUE),
('Kaziranga NP', 'India', 'Assam', 26.5700, 93.1600, 430.00, TRUE);

-- ── 4. Assign Threats to Species ─────────────────────────────────
INSERT INTO species_threats (species_id, threat_id, impact_level) VALUES
(9, 1, 'critical'), (9, 2, 'high'), (10, 1, 'critical'), (11, 4, 'high'),
(12, 3, 'moderate'), (13, 2, 'high'), (14, 1, 'critical'), (15, 2, 'high'),
(16, 5, 'critical'), (17, 3, 'high'), (18, 1, 'moderate'), (19, 2, 'high'),
(20, 3, 'critical'), (21, 4, 'high'), (22, 1, 'critical'), (23, 3, 'moderate'),
(24, 4, 'high'), (25, 2, 'high'), (26, 1, 'critical'), (27, 3, 'high');

-- ── 5. Add Prevention Plans ──────────────────────────────────────
INSERT INTO prevention_plans (species_id, org_id, title, action_steps, budget_usd, success_rate, status, created_by) VALUES
(9, 1, 'Rhino Horn Anti-Poaching Taskforce', 'Drone surveillance and armed patrols.', 1200000, 45.5, 'active', 1),
(10, 2, 'Gorilla Habitat Expansion', 'Buying private land for expansion.', 850000, 88.0, 'completed', 1),
(12, 1, 'Galapagos Marine Sanctuary', 'Strict no-fishing zones enforced by navy.', 4500000, 92.0, 'active', 1),
(13, 4, 'Polar Bear Ice Research', 'Satellite tracking of ice floes.', 600000, 30.0, 'active', 1),
(16, 5, 'Kakapo Breeding Facility', 'Island predator eradication.', 250000, 95.5, 'completed', 1),
(19, 1, 'Snowy Owl Tundra Protect', 'Monitor breeding grounds.', 150000, 40.0, 'planned', 1),
(21, 2, 'Monarch Corridor USA', 'Planting milkweed across 3 states.', 350000, 68.0, 'active', 1);

-- ── 6. Add 50 Tracking Reports (Spread over 6 Months) ────────────
-- (Using researcher user ID 2)
INSERT INTO tracking_reports (species_id, location_id, reported_by, report_date, population_obs, health_status, notes, verified) VALUES
(1, 1, 2, DATE_SUB(CURDATE(), INTERVAL 160 DAY), 12, 'healthy', 'Routine sighting.', TRUE),
(2, 2, 2, DATE_SUB(CURDATE(), INTERVAL 150 DAY), 4, 'stressed', 'Food shortage noted.', TRUE),
(9, 9, 2, DATE_SUB(CURDATE(), INTERVAL 140 DAY), 2, 'healthy', 'Rhino tracks found.', TRUE),
(10, 9, 2, DATE_SUB(CURDATE(), INTERVAL 130 DAY), 18, 'healthy', 'Troop moving to higher ground.', TRUE),
(12, 13, 2, DATE_SUB(CURDATE(), INTERVAL 125 DAY), 45, 'healthy', 'Penguin colony stable.', TRUE),
(13, 14, 2, DATE_SUB(CURDATE(), INTERVAL 120 DAY), 1, 'stressed', 'Bear found far inland.', FALSE),
(14, 9, 2, DATE_SUB(CURDATE(), INTERVAL 115 DAY), 3, 'healthy', 'Cheetah cubs spotted.', TRUE),
(5, 5, 2, DATE_SUB(CURDATE(), INTERVAL 110 DAY), 2, 'healthy', 'Whale surfacing.', TRUE),
(6, 6, 2, DATE_SUB(CURDATE(), INTERVAL 105 DAY), 45, 'stressed', 'Elephant herd near village.', TRUE),
(8, 8, 2, DATE_SUB(CURDATE(), INTERVAL 100 DAY), 1, 'injured', 'Tiger caught in snare.', TRUE),
(9, 9, 2, DATE_SUB(CURDATE(), INTERVAL 95 DAY), 3, 'healthy', 'Rhino grazing.', TRUE),
(15, 8, 2, DATE_SUB(CURDATE(), INTERVAL 90 DAY), 14, 'healthy', 'Red pandas in canopy.', FALSE),
(16, 2, 2, DATE_SUB(CURDATE(), INTERVAL 85 DAY), 50, 'healthy', 'Koala population count.', TRUE),
(17, 10, 2, DATE_SUB(CURDATE(), INTERVAL 80 DAY), 120, 'stressed', 'Turtles entangled in nets.', TRUE),
(18, 9, 2, DATE_SUB(CURDATE(), INTERVAL 75 DAY), 1, 'healthy', 'Rare Javan sighting.', TRUE),
(19, 9, 2, DATE_SUB(CURDATE(), INTERVAL 70 DAY), 2, 'healthy', 'Saola captured on camera trap.', TRUE),
(20, 2, 2, DATE_SUB(CURDATE(), INTERVAL 65 DAY), 15, 'healthy', 'Kakapo mating season.', TRUE),
(21, 10, 2, DATE_SUB(CURDATE(), INTERVAL 60 DAY), 25, 'healthy', 'Gharials basking on riverbank.', TRUE),
(22, 10, 2, DATE_SUB(CURDATE(), INTERVAL 55 DAY), 500, 'stressed', 'Tuna school overfished area.', FALSE),
(23, 10, 2, DATE_SUB(CURDATE(), INTERVAL 50 DAY), 4, 'healthy', 'Whale sharks feeding.', TRUE),
(24, 14, 2, DATE_SUB(CURDATE(), INTERVAL 45 DAY), 12, 'healthy', 'Owls migrating.', TRUE),
(25, 13, 2, DATE_SUB(CURDATE(), INTERVAL 40 DAY), 8, 'stressed', 'Dragons lacking prey.', TRUE),
(26, 14, 2, DATE_SUB(CURDATE(), INTERVAL 35 DAY), 300, 'healthy', 'Emperor colony thriving.', TRUE),
(27, 3, 2, DATE_SUB(CURDATE(), INTERVAL 30 DAY), 1500, 'healthy', 'Monarch migration peak.', TRUE),
(28, 14, 2, DATE_SUB(CURDATE(), INTERVAL 25 DAY), 40, 'healthy', 'Narwhal pod sighted.', TRUE),
(1, 1, 2, DATE_SUB(CURDATE(), INTERVAL 20 DAY), 14, 'healthy', 'Pandas eating bamboo.', TRUE),
(2, 2, 2, DATE_SUB(CURDATE(), INTERVAL 15 DAY), 2, 'injured', 'Leopard with limp.', TRUE),
(3, 3, 2, DATE_SUB(CURDATE(), INTERVAL 10 DAY), 1, 'healthy', 'Amur leopard territory mark.', FALSE),
(4, 4, 2, DATE_SUB(CURDATE(), INTERVAL 8 DAY), 12, 'healthy', 'Orangutan nest count.', TRUE),
(5, 5, 2, DATE_SUB(CURDATE(), INTERVAL 6 DAY), 3, 'healthy', 'Whale pod breaching.', TRUE),
(6, 6, 2, DATE_SUB(CURDATE(), INTERVAL 5 DAY), 80, 'healthy', 'Elephant watering hole.', TRUE),
(7, 7, 2, DATE_SUB(CURDATE(), INTERVAL 4 DAY), 1, 'stressed', 'Vaquita acoustic detection.', FALSE),
(8, 8, 2, DATE_SUB(CURDATE(), INTERVAL 3 DAY), 4, 'healthy', 'Tigress with cubs.', TRUE),
(9, 9, 2, DATE_SUB(CURDATE(), INTERVAL 2 DAY), 2, 'healthy', 'Rhinos resting.', TRUE),
(10, 9, 2, DATE_SUB(CURDATE(), INTERVAL 1 DAY), 22, 'healthy', 'Gorillas interacting with researchers.', TRUE);