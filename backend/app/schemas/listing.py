from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field

from app.core.enums import ListingCategory, ListingStatus
from app.schemas.auth import UserPublic


class ListingCreate(BaseModel):
    title: str = Field(min_length=3, max_length=200)
    description: Optional[str] = Field(default=None, max_length=2000)
    quantity: str = Field(min_length=1, max_length=100)
    category: ListingCategory
    image_url: Optional[str] = None
    pickup_deadline: datetime
    latitude: Optional[float] = Field(default=None, ge=-90, le=90)
    longitude: Optional[float] = Field(default=None, ge=-180, le=180)
    pickup_location_label: Optional[str] = Field(default=None, max_length=255)


class ListingUpdate(BaseModel):
    title: Optional[str] = Field(default=None, min_length=3, max_length=200)
    description: Optional[str] = None
    quantity: Optional[str] = None
    category: Optional[ListingCategory] = None
    image_url: Optional[str] = None
    pickup_deadline: Optional[datetime] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    pickup_location_label: Optional[str] = Field(default=None, max_length=255)


class ListingStatusPatch(BaseModel):
    status: ListingStatus


class ListingPublic(BaseModel):
    id: UUID
    donor_id: UUID
    title: str
    description: Optional[str]
    quantity: str
    category: ListingCategory
    image_url: Optional[str]
    pickup_deadline: datetime
    latitude: float
    longitude: float
    status: ListingStatus
    created_at: datetime
    distance_km: Optional[float] = None
    donor_name: Optional[str] = None
    donor_verified: Optional[bool] = None
    listed_today: Optional[bool] = None
    pickup_location_label: Optional[str] = None


class ListingDetail(ListingPublic):
    donor: Optional[UserPublic] = None


class ImageUploadResponse(BaseModel):
    image_url: str
