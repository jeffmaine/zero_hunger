from __future__ import annotations

from typing import Optional

from datetime import datetime

from sqlalchemy import Boolean, DateTime, Enum, Float, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.enums import UserRole
from app.models.base import BaseModel
from app.models.mixin import SoftDeleteMixin, TimestampMixin


class User(TimestampMixin, SoftDeleteMixin, BaseModel):
    __tablename__ = "users"

    name: Mapped[str] = mapped_column(String(120), nullable=False)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False, default="")
    role: Mapped[UserRole] = mapped_column(
        Enum(UserRole, values_callable=lambda obj: [e.value for e in obj], native_enum=False),
        nullable=False,
        index=True,
    )
    phone: Mapped[str] = mapped_column(String(20), nullable=False, default="")
    auth_provider: Mapped[str] = mapped_column(String(20), nullable=False, default="manual")
    latitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    longitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    location_label: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    avatar_url: Mapped[Optional[str]] = mapped_column(String(512), nullable=True)
    organization_name: Mapped[Optional[str]] = mapped_column(String(200), nullable=True)
    bio: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    successful_pickups: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    claim_no_shows: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    last_successful_pickup_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    fcm_token: Mapped[Optional[str]] = mapped_column(String(512), nullable=True)

    listings: Mapped[list["FoodListing"]] = relationship(
        "FoodListing", back_populates="donor", lazy="dynamic"
    )

    def __repr__(self) -> str:
        return f"<User {self.email}>"
