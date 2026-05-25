"""Add location labels for users and listings

Revision ID: 002
Revises: 001
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "002"
down_revision: Union[str, None] = "001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("users", sa.Column("location_label", sa.String(255), nullable=True))
    op.add_column(
        "food_listings",
        sa.Column("pickup_location_label", sa.String(255), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("food_listings", "pickup_location_label")
    op.drop_column("users", "location_label")
