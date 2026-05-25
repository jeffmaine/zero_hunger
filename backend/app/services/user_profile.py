from uuid import UUID

from fastapi import UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import ListingStatus, UserRole
from app.cruds import listing as listing_crud
from app.cruds import user as user_crud
from app.exceptions.custom import BadRequestException
from app.models.user import User
from app.schemas.profile import FcmTokenUpdate, ProfilePublic, ProfileStats, ProfileUpdate
from app.services import cloudinary


async def count_meals_shared(db: AsyncSession, donor_uuid: UUID) -> int:
    listings = await listing_crud.list_by_donor(db, donor_uuid)
    return sum(1 for l in listings if l.status == ListingStatus.COMPLETED.value)


def profile_from_user(user: User, meals_shared: int = 0) -> ProfilePublic:
    return ProfilePublic(
        id=user.uuid,
        name=user.name,
        email=user.email,
        role=user.role,
        phone=user.phone,
        latitude=user.latitude,
        longitude=user.longitude,
        location_label=user.location_label,
        avatar_url=user.avatar_url,
        organization_name=user.organization_name,
        bio=user.bio,
        is_verified=user.is_verified,
        auth_provider=user.auth_provider,
        created_at=user.created_at,
        stats=ProfileStats(
            meals_shared=meals_shared,
            member_since=user.created_at,
            successful_pickups=getattr(user, "successful_pickups", 0) or 0,
            claim_no_shows=getattr(user, "claim_no_shows", 0) or 0,
        ),
    )


async def get_my_profile(db: AsyncSession, user: User) -> ProfilePublic:
    meals = 0
    if user.role == UserRole.DONOR:
        meals = await count_meals_shared(db, user.uuid)
    return profile_from_user(user, meals)


async def update_my_profile(db: AsyncSession, user: User, data: ProfileUpdate) -> ProfilePublic:
    if data.name is not None:
        user.name = data.name.strip()
    if data.phone is not None:
        user.phone = data.phone.strip()
    if data.organization_name is not None:
        user.organization_name = data.organization_name.strip() or None
    if data.bio is not None:
        user.bio = data.bio.strip() or None
    if data.avatar_url is not None:
        user.avatar_url = data.avatar_url.strip() or None
    if data.location_label is not None:
        user.location_label = data.location_label.strip() or None
    await user_crud.update_user(db, user)
    return await get_my_profile(db, user)


async def update_fcm_token(db: AsyncSession, user: User, data: FcmTokenUpdate) -> None:
    token = (data.token or "").strip() or None
    user.fcm_token = token
    await user_crud.update_user(db, user)


async def upload_avatar(db: AsyncSession, user: User, file: UploadFile) -> ProfilePublic:
    content = await file.read()
    if len(content) > 5 * 1024 * 1024:
        raise BadRequestException("Image must be under 5MB", code="FILE_TOO_LARGE")
    user.avatar_url = cloudinary.upload_image(content)
    await user_crud.update_user(db, user)
    return await get_my_profile(db, user)
