"""Create admin user. Run from backend/: python -m scripts.seed_admin"""

import asyncio
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.enums import AuthProvider, UserRole
from app.cruds.user import create_user, get_user_by_email
from app.db.session import database
from app.models.user import User
from app.services.auth import hash_password

ADMIN_EMAIL = os.environ.get("ADMIN_EMAIL", "admin@zerohunger.local")
ADMIN_PASSWORD = os.environ.get("ADMIN_PASSWORD", "adminchange123")
ADMIN_NAME = os.environ.get("ADMIN_NAME", "Platform Admin")


async def seed() -> None:
    await database.startup()
    async with database.get_session() as db:
        if await get_user_by_email(db, ADMIN_EMAIL):
            print(f"Admin already exists: {ADMIN_EMAIL}")
            return
        user = User(
            name=ADMIN_NAME,
            email=ADMIN_EMAIL,
            hashed_password=hash_password(ADMIN_PASSWORD),
            role=UserRole.ADMIN,
            phone="+2340000000000",
            auth_provider=AuthProvider.MANUAL.value,
            is_verified=True,
        )
        await create_user(db, user)
        print(f"Admin created: {ADMIN_EMAIL}")
    await database.shutdown()


if __name__ == "__main__":
    asyncio.run(seed())
