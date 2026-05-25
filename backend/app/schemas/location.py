from datetime import datetime
from typing import Literal, Optional
from uuid import UUID

from pydantic import BaseModel, Field

from app.core.enums import ListingStatus
from app.schemas.listing import ListingPublic


class Coordinates(BaseModel):
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)


class UserLocationUpdate(BaseModel):
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)
    label: Optional[str] = Field(default=None, max_length=255, description="Display only, e.g. Yaba, Lagos")
    source: Optional[Literal["gps", "manual", "hybrid"]] = None


class ListingMapPin(BaseModel):
    id: UUID
    title: str
    latitude: float
    longitude: float
    distance_km: float
    pickup_deadline: datetime
    status: ListingStatus


class NearbyListingsResponse(BaseModel):
    center: Coordinates
    radius_km: float
    count: int
    listings: list[ListingPublic]


class MapListingsResponse(BaseModel):
    center: Coordinates
    radius_km: float
    count: int
    pins: list[ListingMapPin]
