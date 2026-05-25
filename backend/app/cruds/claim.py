from typing import Optional
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import ClaimStatus
from app.models.claim import Claim
from app.models.listing import FoodListing


async def get_claim_by_uuid(db: AsyncSession, claim_uuid: UUID) -> Optional[Claim]:
    result = await db.execute(select(Claim).where(Claim.uuid == claim_uuid))
    return result.scalar_one_or_none()


async def create_claim(db: AsyncSession, claim: Claim) -> Claim:
    db.add(claim)
    await db.commit()
    await db.refresh(claim)
    return claim


async def update_claim(db: AsyncSession, claim: Claim) -> Claim:
    await db.commit()
    await db.refresh(claim)
    return claim


async def has_active_claim(db: AsyncSession, listing_uuid: UUID) -> bool:
    result = await db.execute(
        select(Claim).where(
            Claim.listing_uuid == listing_uuid,
            Claim.status.in_([ClaimStatus.PENDING.value, ClaimStatus.APPROVED.value]),
        )
    )
    return result.scalar_one_or_none() is not None


async def get_receiver_active_claim(
    db: AsyncSession, listing_uuid: UUID, receiver_uuid: UUID
) -> Optional[Claim]:
    result = await db.execute(
        select(Claim).where(
            Claim.listing_uuid == listing_uuid,
            Claim.receiver_uuid == receiver_uuid,
            Claim.status.in_([ClaimStatus.PENDING.value, ClaimStatus.APPROVED.value]),
        )
    )
    return result.scalar_one_or_none()


async def list_by_receiver(db: AsyncSession, receiver_uuid: UUID) -> list[Claim]:
    result = await db.execute(
        select(Claim)
        .where(Claim.receiver_uuid == receiver_uuid)
        .order_by(Claim.created_at.desc())
    )
    return list(result.scalars().all())


async def list_by_donor(db: AsyncSession, donor_uuid: UUID) -> list[Claim]:
    result = await db.execute(
        select(Claim)
        .join(FoodListing, Claim.listing_uuid == FoodListing.uuid)
        .where(FoodListing.donor_uuid == donor_uuid)
        .order_by(Claim.created_at.desc())
    )
    return list(result.scalars().all())


async def list_pending_for_donor(db: AsyncSession, donor_uuid: UUID) -> list[Claim]:
    result = await db.execute(
        select(Claim)
        .join(FoodListing, Claim.listing_uuid == FoodListing.uuid)
        .where(
            FoodListing.donor_uuid == donor_uuid,
            FoodListing.deleted_at.is_(None),
            Claim.status == ClaimStatus.PENDING.value,
        )
        .order_by(Claim.created_at.desc())
    )
    return list(result.scalars().all())


async def count_pending_for_donor(db: AsyncSession, donor_uuid: UUID) -> int:
    from sqlalchemy import func

    result = await db.execute(
        select(func.count())
        .select_from(Claim)
        .join(FoodListing, Claim.listing_uuid == FoodListing.uuid)
        .where(
            FoodListing.donor_uuid == donor_uuid,
            FoodListing.deleted_at.is_(None),
            Claim.status == ClaimStatus.PENDING.value,
        )
    )
    return int(result.scalar_one())


async def count_active_for_receiver(db: AsyncSession, receiver_uuid: UUID) -> int:
    from sqlalchemy import func

    result = await db.execute(
        select(func.count())
        .select_from(Claim)
        .where(
            Claim.receiver_uuid == receiver_uuid,
            Claim.status.in_([ClaimStatus.PENDING.value, ClaimStatus.APPROVED.value]),
        )
    )
    return int(result.scalar_one())


async def get_approved_for_listing(db: AsyncSession, listing_uuid: UUID) -> Optional[Claim]:
    result = await db.execute(
        select(Claim).where(
            Claim.listing_uuid == listing_uuid,
            Claim.status == ClaimStatus.APPROVED.value,
        )
    )
    return result.scalar_one_or_none()


async def list_for_listing(db: AsyncSession, listing_uuid: UUID) -> list[Claim]:
    result = await db.execute(
        select(Claim)
        .where(Claim.listing_uuid == listing_uuid)
        .order_by(Claim.created_at.desc())
    )
    return list(result.scalars().all())


async def list_pending_for_listing(
    db: AsyncSession, listing_uuid: UUID, *, exclude_uuid: UUID | None = None
) -> list[Claim]:
    stmt = select(Claim).where(
        Claim.listing_uuid == listing_uuid,
        Claim.status == ClaimStatus.PENDING.value,
    )
    if exclude_uuid is not None:
        stmt = stmt.where(Claim.uuid != exclude_uuid)
    result = await db.execute(stmt.order_by(Claim.created_at.asc()))
    return list(result.scalars().all())
