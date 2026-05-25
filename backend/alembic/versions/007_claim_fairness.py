"""Claim fairness: pickup codes, collect timestamp, receiver stats

Revision ID: 007
Revises: 006
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "007"
down_revision: Union[str, None] = "006"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("claims", sa.Column("pickup_code", sa.String(4), nullable=True))
    op.add_column("claims", sa.Column("collected_at", sa.DateTime(timezone=True), nullable=True))

    op.add_column(
        "users",
        sa.Column("successful_pickups", sa.Integer(), server_default="0", nullable=False),
    )
    op.add_column(
        "users",
        sa.Column("claim_no_shows", sa.Integer(), server_default="0", nullable=False),
    )
    op.add_column(
        "users",
        sa.Column("last_successful_pickup_at", sa.DateTime(timezone=True), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("users", "last_successful_pickup_at")
    op.drop_column("users", "claim_no_shows")
    op.drop_column("users", "successful_pickups")
    op.drop_column("claims", "collected_at")
    op.drop_column("claims", "pickup_code")
