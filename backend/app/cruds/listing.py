from datetime import datetime, timezone
from typing import Optional
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import ListingStatus
from app.models.listing import FoodListing
from app.services.geo import bounding_box


async def get_listing_by_uuid(db: AsyncSession, listing_uuid: UUID) -> Optional[FoodListing]:
    result = await db.execute(
        select(FoodListing).where(
            FoodListing.uuid == listing_uuid,
            FoodListing.deleted_at.is_(None),
        )
    )
    return result.scalar_one_or_none()


async def create_listing(db: AsyncSession, listing: FoodListing) -> FoodListing:
    db.add(listing)
    await db.commit()
    await db.refresh(listing)
    return listing


async def update_listing(db: AsyncSession, listing: FoodListing) -> FoodListing:
    await db.commit()
    await db.refresh(listing)
    return listing


async def list_available_in_bbox(
    db: AsyncSession,
    lat: float,
    lng: float,
    radius_km: float,
    category: Optional[str] = None,
    expiry_before: Optional[datetime] = None,
) -> list[FoodListing]:
    """SQL bounding-box pre-filter; haversine applied in service layer."""
    min_lat, max_lat, min_lng, max_lng = bounding_box(lat, lng, radius_km)
    now = datetime.now(timezone.utc)

    stmt = select(FoodListing).where(
        FoodListing.deleted_at.is_(None),
        FoodListing.status == ListingStatus.AVAILABLE.value,
        FoodListing.latitude >= min_lat,
        FoodListing.latitude <= max_lat,
        FoodListing.longitude >= min_lng,
        FoodListing.longitude <= max_lng,
        FoodListing.pickup_deadline > now,
    )
    if category:
        stmt = stmt.where(FoodListing.category == category)
    if expiry_before:
        stmt = stmt.where(FoodListing.pickup_deadline <= expiry_before)
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def list_by_donor(db: AsyncSession, donor_uuid: UUID) -> list[FoodListing]:
    result = await db.execute(
        select(FoodListing)
        .where(FoodListing.donor_uuid == donor_uuid, FoodListing.deleted_at.is_(None))
        .order_by(FoodListing.created_at.desc())
    )
    return list(result.scalars().all())


async def list_recent_available_excluding_donor(
    db: AsyncSession,
    donor_uuid: UUID,
    *,
    limit: int = 8,
) -> list[FoodListing]:
    """Recent available listings from other donors (fallback when geo is missing)."""
    now = datetime.now(timezone.utc)
    result = await db.execute(
        select(FoodListing)
        .where(
            FoodListing.deleted_at.is_(None),
            FoodListing.donor_uuid != donor_uuid,
            FoodListing.status == ListingStatus.AVAILABLE.value,
            FoodListing.pickup_deadline > now,
        )
        .order_by(FoodListing.created_at.desc())
        .limit(limit)
    )
    return list(result.scalars().all())


async def list_expirable(db: AsyncSession) -> list[FoodListing]:
    result = await db.execute(
        select(FoodListing).where(
            FoodListing.deleted_at.is_(None),
            FoodListing.status.in_(
                [ListingStatus.AVAILABLE.value, ListingStatus.CLAIMED.value]
            ),
        )
    )
    return list(result.scalars().all())
