from __future__ import annotations

import uuid as _uuid

from datetime import datetime
from typing import Optional

from sqlalchemy import DateTime, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import BaseModel
from app.models.mixin import TimestampMixin


class Claim(TimestampMixin, BaseModel):
    __tablename__ = "claims"

    listing_uuid: Mapped[_uuid.UUID] = mapped_column(
        ForeignKey("food_listings.uuid", ondelete="CASCADE"), index=True, nullable=False
    )
    receiver_uuid: Mapped[_uuid.UUID] = mapped_column(
        ForeignKey("users.uuid", ondelete="CASCADE"), index=True, nullable=False
    )
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="pending", index=True)
    pickup_code: Mapped[Optional[str]] = mapped_column(String(4), nullable=True)
    collected_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)

    listing: Mapped["FoodListing"] = relationship("FoodListing", back_populates="claims")
    receiver: Mapped["User"] = relationship("User")
