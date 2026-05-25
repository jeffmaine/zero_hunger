from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies import get_admin_user
from app.cruds import user as user_crud
from app.db.session import get_db_session
from app.exceptions.custom import NotFoundException
from app.models.claim import Claim
from app.models.listing import FoodListing
from app.models.user import User
from app.schemas.auth import UserPublic
from app.services import listing as listing_service

router = APIRouter(prefix="/admin", tags=["Admin"])


@router.get("/users", response_model=list[UserPublic])
async def list_users(
    db: AsyncSession = Depends(get_db_session),
    _admin: User = Depends(get_admin_user),
):
    users = await user_crud.list_users(db)
    return [UserPublic.from_user(u) for u in users]


@router.patch("/users/{user_id}/ban")
async def ban_user(
    user_id: UUID,
    db: AsyncSession = Depends(get_db_session),
    _admin: User = Depends(get_admin_user),
):
    user = await user_crud.get_user_by_uuid(db, user_id)
    if not user:
        raise NotFoundException("User not found", code="NOT_FOUND")
    user.is_active = False
    await user_crud.update_user(db, user)
    return {"status": "banned", "user_id": str(user_id)}


@router.delete("/listings/{listing_id}", status_code=204)
async def remove_listing(
    listing_id: UUID,
    db: AsyncSession = Depends(get_db_session),
    admin: User = Depends(get_admin_user),
):
    await listing_service.soft_delete(db, listing_id, admin)


@router.get("/stats")
async def stats(
    db: AsyncSession = Depends(get_db_session),
    _admin: User = Depends(get_admin_user),
):
    users = (await db.execute(select(func.count()).select_from(User).where(User.deleted_at.is_(None)))).scalar()
    listings = (
        await db.execute(
            select(func.count()).select_from(FoodListing).where(FoodListing.deleted_at.is_(None))
        )
    ).scalar()
    claims = (await db.execute(select(func.count()).select_from(Claim))).scalar()
    return {"users": users, "listings": listings, "claims": claims}
