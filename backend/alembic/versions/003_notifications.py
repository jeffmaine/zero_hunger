"""In-app notifications table

Revision ID: 003
Revises: 002
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "003"
down_revision: Union[str, None] = "002"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "notifications",
        sa.Column("uuid", sa.UUID(), server_default=sa.text("gen_random_uuid()"), nullable=False),
        sa.Column("user_uuid", sa.UUID(), nullable=False),
        sa.Column("type", sa.String(40), nullable=False),
        sa.Column("title", sa.String(200), nullable=False),
        sa.Column("body", sa.String(500), nullable=False),
        sa.Column("listing_uuid", sa.UUID(), nullable=True),
        sa.Column("claim_uuid", sa.UUID(), nullable=True),
        sa.Column("read_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["user_uuid"], ["users.uuid"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["listing_uuid"], ["food_listings.uuid"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["claim_uuid"], ["claims.uuid"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("uuid"),
    )
    op.create_index("ix_notifications_user_uuid", "notifications", ["user_uuid"])
    op.create_index("ix_notifications_user_read", "notifications", ["user_uuid", "read_at"])


def downgrade() -> None:
    op.drop_index("ix_notifications_user_read", table_name="notifications")
    op.drop_index("ix_notifications_user_uuid", table_name="notifications")
    op.drop_table("notifications")
