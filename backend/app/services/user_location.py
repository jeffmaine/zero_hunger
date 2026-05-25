from sqlalchemy.ext.asyncio import AsyncSession

from app.cruds import user as user_crud
from app.models.user import User
from app.schemas.auth import UserPublic
from app.schemas.location import UserLocationUpdate


async def update_user_location(db: AsyncSession, user: User, data: UserLocationUpdate) -> UserPublic:
    user.latitude = data.latitude
    user.longitude = data.longitude
    if data.label is not None:
        user.location_label = data.label
    await user_crud.update_user(db, user)
    return UserPublic.from_user(user)
