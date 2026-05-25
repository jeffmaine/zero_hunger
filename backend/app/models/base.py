from __future__ import annotations

import uuid as _uuid

from sqlalchemy import UUID, text
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    pass


class BaseModel(Base):
    __abstract__ = True

    uuid: Mapped[_uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=_uuid.uuid4,
        server_default=text("gen_random_uuid()"),
    )
