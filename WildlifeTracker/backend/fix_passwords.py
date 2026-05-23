from app import create_app
from extensions import db, bcrypt
from models.models import User

app = create_app()

with app.app_context():
    users = User.query.all()
    for u in users:
        if "placeholder" in u.password_hash:
            # Match the passwords expected by the frontend Quick Login buttons
            if u.username == "admin":
                pwd = "Admin@123"
            elif u.username == "researcher1":
                pwd = "Research@123"
            else:
                pwd = "View@123"
            
            u.password_hash = bcrypt.generate_password_hash(pwd).decode('utf-8')
            print(f"Updated hash for {u.username}")
    
    db.session.commit()
    print("All passwords hashed successfully!")