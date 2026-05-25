from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies import get_authenticated_user
from app.db.session import get_db_session
from app.models.user import User
from app.schemas.notification import NotificationListResponse, NotificationPublic, UnreadCountResponse
from app.services import notification as notification_service

router = APIRouter(prefix="/notifications", tags=["Notifications"])


@router.get("", response_model=NotificationListResponse)
async def list_notifications(
    unread_only: bool = Query(default=False),
    limit: int = Query(default=50, ge=1, le=100),
    db: AsyncSession = Depends(get_db_session),
    user: User = Depends(get_authenticated_user),
):
    return await notification_service.list_for_user(db, user, unread_only=unread_only, limit=limit)


@router.get("/unread-count", response_model=UnreadCountResponse)
async def get_unread_count(
    db: AsyncSession = Depends(get_db_session),
    user: User = Depends(get_authenticated_user),
):
    return await notification_service.unread_count(db, user)


@router.patch("/{notification_id}/read", response_model=NotificationPublic)
async def read_notification(
    notification_id: UUID,
    db: AsyncSession = Depends(get_db_session),
    user: User = Depends(get_authenticated_user),
):
    return await notification_service.mark_read(db, user, notification_id)


@router.post("/read-all", response_model=UnreadCountResponse)
async def read_all_notifications(
    db: AsyncSession = Depends(get_db_session),
    user: User = Depends(get_authenticated_user),
):
    return await notification_service.mark_all_read(db, user)
