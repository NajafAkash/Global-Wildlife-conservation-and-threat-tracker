# Global Wildlife Conservation & Threat Tracker

## Project Structure
```
wildlife_tracker/
├── backend/
│   ├── app.py                    # Flask entry point
│   ├── config.py                 # Configuration
│   ├── extensions.py             # Flask extensions (db, jwt, bcrypt)
│   ├── requirements.txt          # Python dependencies
│   ├── models/
│   │   └── models.py             # SQLAlchemy ORM models
│   └── routes/
│       ├── auth.py               # Auth endpoints
│       ├── species.py            # Species CRUD
│       └── other_routes.py       # Threats, reports, analytics, etc.
├── frontend/
│   └── templates/
│       ├── login.html            # Login page
│       └── dashboard.html        # Main dashboard
├── database/
│   ├── schema.sql                # Full MySQL schema
│   └── seed.sql                  # Sample data
└── docs/
    └── README.md
```

## Setup

### 1. Database
```sql
mysql -u root -p < database/schema.sql
mysql -u root -p WildlifeTracker < database/seed.sql
```

### 2. Backend
```bash
cd backend
pip install -r requirements.txt
cp .env.example .env   # edit your DB credentials
python app.py
```

### 3. Frontend
Open `frontend/templates/login.html` in browser or serve via Flask templates.

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /api/auth/login | Login |
| POST | /api/auth/register | Register |
| GET | /api/auth/me | Current user |
| GET | /api/species | List species (filter: q, status, trend) |
| POST | /api/species | Create species (admin/researcher) |
| PUT | /api/species/:id | Update species |
| DELETE | /api/species/:id | Delete species (admin only) |
| GET | /api/species/stats/summary | Dashboard stats |
| GET | /api/threats | List threats + affected count |
| POST | /api/species/:id/threats | Assign threat to species |
| GET | /api/reports | List tracking reports |
| POST | /api/reports | Submit field report |
| GET | /api/analytics/dashboard | Full dashboard data |
| GET | /api/locations | List all locations |
| GET | /api/plans | List prevention plans |
| POST | /api/plans | Create prevention plan |

## Default Credentials (seed data)
- **Admin:** `admin` / `Admin@123`
- **Researcher:** `researcher1` / `Research@123`
- **Viewer:** `viewer1` / `View@123`

## Tech Stack
- **Frontend:** HTML5, CSS3, Vanilla JS, Chart.js
- **Backend:** Python 3.11+, Flask 3.0, SQLAlchemy 2.0
- **Database:** MySQL 8.0
- **Auth:** JWT (flask-jwt-extended), bcrypt
