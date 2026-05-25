from __future__ import annotations

import uuid as _uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import DateTime, Float, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import BaseModel
from app.models.mixin import SoftDeleteMixin, TimestampMixin


class FoodListing(TimestampMixin, SoftDeleteMixin, BaseModel):
    __tablename__ = "food_listings"

    donor_uuid: Mapped[_uuid.UUID] = mapped_column(
        ForeignKey("users.uuid", ondelete="CASCADE"), index=True, nullable=False
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    quantity: Mapped[str] = mapped_column(String(100), nullable=False)
    category: Mapped[str] = mapped_column(String(30), nullable=False, index=True)
    image_url: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    pickup_deadline: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    latitude: Mapped[float] = mapped_column(Float, nullable=False)
    longitude: Mapped[float] = mapped_column(Float, nullable=False)
    pickup_location_label: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="available", index=True)

    donor: Mapped["User"] = relationship("User", back_populates="listings")
    claims: Mapped[list["Claim"]] = relationship("Claim", back_populates="listing", lazy="dynamic")
