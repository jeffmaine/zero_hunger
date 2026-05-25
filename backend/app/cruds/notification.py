from datetime import datetime, timezone
from uuid import UUID

from sqlalchemy import func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.notification import Notification


async def exists_for_user_claim_type(
    db: AsyncSession,
    user_uuid: UUID,
    claim_uuid: UUID,
    ntype: str,
) -> bool:
    result = await db.execute(
        select(Notification.uuid)
        .where(
            Notification.user_uuid == user_uuid,
            Notification.claim_uuid == claim_uuid,
            Notification.type == ntype,
        )
        .limit(1)
    )
    return result.scalar_one_or_none() is not None


async def create_notification(db: AsyncSession, notification: Notification) -> Notification:
    db.add(notification)
    await db.commit()
    await db.refresh(notification)
    return notification


async def list_for_user(
    db: AsyncSession,
    user_uuid: UUID,
    *,
    limit: int = 50,
    unread_only: bool = False,
) -> list[Notification]:
    stmt = (
        select(Notification)
        .where(Notification.user_uuid == user_uuid)
        .order_by(Notification.created_at.desc())
        .limit(limit)
    )
    if unread_only:
        stmt = stmt.where(Notification.read_at.is_(None))
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def count_unread(db: AsyncSession, user_uuid: UUID) -> int:
    result = await db.execute(
        select(func.count())
        .select_from(Notification)
        .where(Notification.user_uuid == user_uuid, Notification.read_at.is_(None))
    )
    return int(result.scalar_one())


async def get_by_uuid_for_user(
    db: AsyncSession, notification_uuid: UUID, user_uuid: UUID
) -> Notification | None:
    result = await db.execute(
        select(Notification).where(
            Notification.uuid == notification_uuid,
            Notification.user_uuid == user_uuid,
        )
    )
    return result.scalar_one_or_none()


async def mark_read(db: AsyncSession, notification: Notification) -> Notification:
    if notification.read_at is None:
        notification.read_at = datetime.now(timezone.utc)
        await db.commit()
        await db.refresh(notification)
    return notification


async def mark_all_read(db: AsyncSession, user_uuid: UUID) -> int:
    now = datetime.now(timezone.utc)
    result = await db.execute(
        update(Notification)
        .where(Notification.user_uuid == user_uuid, Notification.read_at.is_(None))
        .values(read_at=now)
    )
    await db.commit()
    return result.rowcount or 0
