from __future__ import annotations

import uuid as _uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import DateTime, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import BaseModel
from app.models.mixin import TimestampMixin


class Notification(TimestampMixin, BaseModel):
    __tablename__ = "notifications"

    user_uuid: Mapped[_uuid.UUID] = mapped_column(
        ForeignKey("users.uuid", ondelete="CASCADE"), index=True, nullable=False
    )
    type: Mapped[str] = mapped_column(String(40), nullable=False, index=True)
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    body: Mapped[str] = mapped_column(Text, nullable=False)
    listing_uuid: Mapped[Optional[_uuid.UUID]] = mapped_column(
        ForeignKey("food_listings.uuid", ondelete="SET NULL"), nullable=True
    )
    claim_uuid: Mapped[Optional[_uuid.UUID]] = mapped_column(
        ForeignKey("claims.uuid", ondelete="SET NULL"), nullable=True
    )
    read_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
