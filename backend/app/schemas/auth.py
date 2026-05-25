from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field

from app.core.enums import UserRole


class RegisterRequest(BaseModel):
    name: str = Field(min_length=2, max_length=120)
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    role: UserRole
    phone: str = Field(min_length=7, max_length=20)
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class RefreshRequest(BaseModel):
    refresh_token: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class GoogleAuthRequest(BaseModel):
    session_token: str
    role: UserRole = UserRole.RECEIVER
    phone: str = ""


class GoogleMobileAuthRequest(BaseModel):
    id_token: str
    role: UserRole = UserRole.RECEIVER
    phone: str = ""


class UserPublic(BaseModel):
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

    @classmethod
    def from_user(cls, user) -> "UserPublic":
        return cls(
            id=user.uuid,
            name=user.name,
            email=user.email,
            role=user.role,
            phone=user.phone,
            latitude=user.latitude,
            longitude=user.longitude,
            location_label=user.location_label,
            avatar_url=getattr(user, "avatar_url", None),
            organization_name=getattr(user, "organization_name", None),
            bio=getattr(user, "bio", None),
            is_verified=user.is_verified,
            auth_provider=user.auth_provider,
            created_at=user.created_at,
        )
