"""Soft fairness rules for receivers claiming food."""

from datetime import datetime, timedelta, timezone

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Config
from app.cruds import claim as claim_crud
from app.cruds import user as user_crud
from app.exceptions.custom import BadRequestException
from app.models.claim import Claim
from app.models.user import User


def _utc_now() -> datetime:
    return datetime.now(timezone.utc)


def pending_claim_sort_key(receiver: User, claim: Claim) -> tuple:
    """Lower sorts first: fewer no-shows, fewer past pickups, longer wait."""
    return (
        receiver.claim_no_shows or 0,
        receiver.successful_pickups or 0,
        claim.created_at,
    )


async def assert_receiver_can_claim(db: AsyncSession, receiver: User) -> None:
    if (receiver.claim_no_shows or 0) >= Config.MAX_CLAIM_NO_SHOWS:
        raise BadRequestException(
            f"Account paused after {Config.MAX_CLAIM_NO_SHOWS} missed pickups. "
            "Contact support if you need help.",
            code="CLAIM_NO_SHOW_LIMIT",
        )

    active = await claim_crud.count_active_for_receiver(db, receiver.uuid)
    if active >= Config.MAX_ACTIVE_CLAIMS_PER_RECEIVER:
        raise BadRequestException(
            f"You can have at most {Config.MAX_ACTIVE_CLAIMS_PER_RECEIVER} active claims at a time. "
            "Complete or wait for a decision on existing claims first.",
            code="CLAIM_LIMIT_REACHED",
        )

    if receiver.last_successful_pickup_at is not None:
        last = receiver.last_successful_pickup_at
        if last.tzinfo is None:
            last = last.replace(tzinfo=timezone.utc)
        cooldown_until = last + timedelta(hours=Config.CLAIM_COOLDOWN_HOURS)
        now = _utc_now()
        if now < cooldown_until:
            remaining = cooldown_until - now
            hours = int(remaining.total_seconds() // 3600) + 1
            raise BadRequestException(
                f"Please wait about {hours} hour(s) after your last pickup before claiming again.",
                code="CLAIM_COOLDOWN",
            )


async def record_successful_pickup(db: AsyncSession, receiver: User) -> None:
    receiver.successful_pickups = (receiver.successful_pickups or 0) + 1
    receiver.last_successful_pickup_at = _utc_now()
    await user_crud.update_user(db, receiver)


async def record_no_show(db: AsyncSession, receiver: User) -> None:
    receiver.claim_no_shows = (receiver.claim_no_shows or 0) + 1
    await user_crud.update_user(db, receiver)
