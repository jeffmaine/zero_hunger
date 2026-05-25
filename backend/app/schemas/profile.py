from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field

from app.core.enums import UserRole


class FcmTokenUpdate(BaseModel):
    token: Optional[str] = Field(default=None, max_length=512)


class ProfileUpdate(BaseModel):
    name: Optional[str] = Field(default=None, min_length=2, max_length=120)
    phone: Optional[str] = Field(default=None, min_length=7, max_length=20)
    organization_name: Optional[str] = Field(default=None, max_length=200)
    bio: Optional[str] = Field(default=None, max_length=500)
    avatar_url: Optional[str] = Field(default=None, max_length=512)
    location_label: Optional[str] = Field(default=None, max_length=255)


class ProfileStats(BaseModel):
    meals_shared: int = 0
    member_since: datetime
    successful_pickups: int = 0
    claim_no_shows: int = 0


class ProfilePublic(BaseModel):
    id: UUID
    name: str
    email: str
    role: UserRole
    phone: str
    latitude: Optional[float]
    longitude: Optional[float]
    location_label: Optional[str] = None
    avatar_url: Optional[str] = None
    organization_name: Optional[str] = None
    bio: Optional[str] = None
    is_verified: bool
    auth_provider: str
    created_at: datetime
    stats: ProfileStats
