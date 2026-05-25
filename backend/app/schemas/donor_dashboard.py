from datetime import datetime
from uuid import UUID

from pydantic import BaseModel

from app.schemas.listing import ListingPublic


class DonorStats(BaseModel):
    active_listings: int
    total_posted: int
    pending_claims: int
    unread_notifications: int = 0


class NearbyActivityItem(BaseModel):
    listing_id: UUID
    donor_id: UUID
    donor_name: str
    listing_title: str
    image_url: str | None = None
    created_at: datetime
    distance_km: float | None = None


class DonorDashboardResponse(BaseModel):
    stats: DonorStats
    recent_listings: list[ListingPublic]
    nearby_activity: list[NearbyActivityItem]
