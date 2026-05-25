"""Listing paused/cancelled statuses (no schema change — enum values only)

Revision ID: 006
Revises: 005
"""

from typing import Sequence, Union

revision: str = "006"
down_revision: Union[str, None] = "005"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
