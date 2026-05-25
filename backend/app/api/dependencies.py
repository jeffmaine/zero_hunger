from fastapi import Depends
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import UserRole
from app.db.session import get_db_session
from app.exceptions.custom import ForbiddenException
from app.models.user import User
from app.services.auth import get_current_user

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")


async def get_authenticated_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db_session),
) -> User:
    return await get_current_user(db, token)


async def get_donor_user(user: User = Depends(get_authenticated_user)) -> User:
    if user.role != UserRole.DONOR:
        raise ForbiddenException("Donor role required", code="FORBIDDEN")
    return user


async def get_receiver_user(user: User = Depends(get_authenticated_user)) -> User:
    if user.role != UserRole.RECEIVER:
        raise ForbiddenException("Receiver role required", code="FORBIDDEN")
    return user


async def get_admin_user(user: User = Depends(get_authenticated_user)) -> User:
    if user.role != UserRole.ADMIN:
        raise ForbiddenException("Admin access required", code="FORBIDDEN")
    return user
