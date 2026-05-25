from fastapi import APIRouter, Depends, File, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies import get_authenticated_user
from app.db.session import get_db_session
from app.models.user import User
from app.schemas.profile import FcmTokenUpdate, ProfilePublic, ProfileUpdate
from app.services import user_profile as profile_service

router = APIRouter(prefix="/users", tags=["Users"])


@router.get("/me/profile", response_model=ProfilePublic)
async def get_profile(
    db: AsyncSession = Depends(get_db_session),
    user: User = Depends(get_authenticated_user),
):
    return await profile_service.get_my_profile(db, user)


@router.put("/me/fcm-token", status_code=204)
async def update_fcm_token(
    data: FcmTokenUpdate,
    db: AsyncSession = Depends(get_db_session),
    user: User = Depends(get_authenticated_user),
):
    await profile_service.update_fcm_token(db, user, data)


@router.patch("/me", response_model=ProfilePublic)
async def update_profile(
    data: ProfileUpdate,
    db: AsyncSession = Depends(get_db_session),
    user: User = Depends(get_authenticated_user),
):
    return await profile_service.update_my_profile(db, user, data)


@router.post("/me/avatar", response_model=ProfilePublic)
async def upload_avatar(
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db_session),
    user: User = Depends(get_authenticated_user),
):
    return await profile_service.upload_avatar(db, user, file)
