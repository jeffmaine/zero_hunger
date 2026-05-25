from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.core.enums import ClaimStatus
from app.schemas.listing import ListingPublic


class ClaimCreate(BaseModel):
    listing_id: UUID


class ClaimCollect(BaseModel):
    pickup_code: str = Field(min_length=4, max_length=4, pattern=r"^\d{4}$")


class ClaimPublic(BaseModel):
    id: UUID
    listing_id: UUID
    receiver_id: UUID
    status: ClaimStatus
    created_at: datetime
    listing: ListingPublic | None = None
    receiver_name: str | None = None
    pickup_code: str | None = None
    collected_at: datetime | None = None
    priority_rank: int | None = None
    receiver_pickups: int | None = None
    receiver_no_shows: int | None = None


class ClaimLimitsResponse(BaseModel):
    max_active_claims: int
    active_claims: int
    cooldown_hours: int
    can_claim: bool
    cooldown_ends_at: datetime | None = None
    message: str | None = None
    claim_no_shows: int = 0
    max_no_shows: int = 3
