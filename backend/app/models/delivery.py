"""Phase 2 volunteer deliveries — table only for MVP."""

from __future__ import annotations

import uuid as _uuid

from sqlalchemy import ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import BaseModel
from app.models.mixin import TimestampMixin


class Delivery(TimestampMixin, BaseModel):
    __tablename__ = "deliveries"

    listing_uuid: Mapped[_uuid.UUID] = mapped_column(
        ForeignKey("food_listings.uuid", ondelete="CASCADE"), index=True, nullable=False
    )
    volunteer_uuid: Mapped[_uuid.UUID] = mapped_column(
        ForeignKey("users.uuid", ondelete="CASCADE"), index=True, nullable=False
    )
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="assigned")
