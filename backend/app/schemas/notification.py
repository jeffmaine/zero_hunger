from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel

from app.core.enums import NotificationType


class NotificationPublic(BaseModel):
    id: UUID
    type: NotificationType
    title: str
    body: str
    listing_id: Optional[UUID] = None
    claim_id: Optional[UUID] = None
    read_at: Optional[datetime] = None
    created_at: datetime

    @property
    def is_read(self) -> bool:
        return self.read_at is not None


class NotificationListResponse(BaseModel):
    unread_count: int
    notifications: list[NotificationPublic]


class UnreadCountResponse(BaseModel):
    unread_count: int
