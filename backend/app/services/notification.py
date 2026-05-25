"""In-app notifications and FCM push (when FCM_ENABLED)."""

from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import NotificationType
from app.core.logging import get_logger
from app.cruds import notification as notification_crud
from app.exceptions.custom import NotFoundException
from app.models.listing import FoodListing
from app.models.notification import Notification
from app.models.user import User
from app.schemas.notification import NotificationListResponse, NotificationPublic, UnreadCountResponse
from app.services import fcm as fcm_service

logger = get_logger(__name__)


def _to_public(n: Notification) -> NotificationPublic:
    return NotificationPublic(
        id=n.uuid,
        type=NotificationType(n.type),
        title=n.title,
        body=n.body,
        listing_id=n.listing_uuid,
        claim_id=n.claim_uuid,
        read_at=n.read_at,
        created_at=n.created_at,
    )


async def create(
    db: AsyncSession,
    *,
    user_uuid: UUID,
    ntype: NotificationType,
    title: str,
    body: str,
    listing_uuid: UUID | None = None,
    claim_uuid: UUID | None = None,
) -> NotificationPublic:
    row = Notification(
        user_uuid=user_uuid,
        type=ntype.value,
        title=title,
        body=body,
        listing_uuid=listing_uuid,
        claim_uuid=claim_uuid,
    )
    created = await notification_crud.create_notification(db, row)
    logger.info("Notification %s → user %s", ntype.value, user_uuid)
    await fcm_service.send_to_user(
        db,
        user_uuid,
        title=title,
        body=body,
        notification_type=ntype.value,
        listing_uuid=listing_uuid,
        claim_uuid=claim_uuid,
    )
    return _to_public(created)


async def list_for_user(
    db: AsyncSession,
    user: User,
    *,
    unread_only: bool = False,
    limit: int = 50,
) -> NotificationListResponse:
    rows = await notification_crud.list_for_user(
        db, user.uuid, limit=limit, unread_only=unread_only
    )
    unread = await notification_crud.count_unread(db, user.uuid)
    return NotificationListResponse(
        unread_count=unread,
        notifications=[_to_public(r) for r in rows],
    )


async def unread_count(db: AsyncSession, user: User) -> UnreadCountResponse:
    count = await notification_crud.count_unread(db, user.uuid)
    return UnreadCountResponse(unread_count=count)


async def mark_read(db: AsyncSession, user: User, notification_uuid: UUID) -> NotificationPublic:
    row = await notification_crud.get_by_uuid_for_user(db, notification_uuid, user.uuid)
    if not row:
        raise NotFoundException("Notification not found", code="NOT_FOUND")
    updated = await notification_crud.mark_read(db, row)
    return _to_public(updated)


async def mark_all_read(db: AsyncSession, user: User) -> UnreadCountResponse:
    await notification_crud.mark_all_read(db, user.uuid)
    return UnreadCountResponse(unread_count=0)


async def notify_new_claim(
    db: AsyncSession,
    donor_uuid: UUID,
    listing: FoodListing,
    claim_uuid: UUID,
    receiver_name: str,
) -> None:
    if await notification_crud.exists_for_user_claim_type(
        db,
        donor_uuid,
        claim_uuid,
        NotificationType.CLAIM_RECEIVED.value,
    ):
        return
    name = first_name(receiver_name)
    title = format_listing_title(listing.title)
    await create(
        db,
        user_uuid=donor_uuid,
        ntype=NotificationType.CLAIM_RECEIVED,
        title="New claim on your food",
        body=f"{name} wants to claim {title}. Review and approve when ready.",
        listing_uuid=listing.uuid,
        claim_uuid=claim_uuid,
    )

async def notify_claim_decision(
    db: AsyncSession,
    receiver_uuid: UUID,
    *,
    approved: bool,
    listing_title: str,
    listing_uuid: UUID,
    claim_uuid: UUID,
) -> None:
    title = format_listing_title(listing_title)
    ntype = (
        NotificationType.CLAIM_APPROVED if approved else NotificationType.CLAIM_REJECTED
    )
    if await notification_crud.exists_for_user_claim_type(
        db, receiver_uuid, claim_uuid, ntype.value
    ):
        return
    if approved:
        await create(
            db,
            user_uuid=receiver_uuid,
            ntype=NotificationType.CLAIM_APPROVED,
            title="Claim approved",
            body=f"Your claim for {title} was approved. Head to pickup before the deadline.",
            listing_uuid=listing_uuid,
            claim_uuid=claim_uuid,
        )
    else:
        await create(
            db,
            user_uuid=receiver_uuid,
            ntype=NotificationType.CLAIM_REJECTED,
            title="Claim not approved",
            body=f"Your claim for {title} was declined. Browse other food nearby.",
            listing_uuid=listing_uuid,
            claim_uuid=claim_uuid,
        )

def format_listing_title(title: str) -> str:
    parts = [p.capitalize() for p in title.strip().split() if p]
    return " ".join(parts) if parts else title


def first_name(full_name: str) -> str:
    part = full_name.strip().split()
    return part[0].capitalize() if part else "Someone"
