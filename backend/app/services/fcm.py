"""Firebase Cloud Messaging — optional; no-op when FCM_ENABLED is false."""

from __future__ import annotations

import asyncio
from pathlib import Path
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Config
from app.core.logging import get_logger
from app.cruds import user as user_crud

logger = get_logger(__name__)

_app_initialized = False


def init_firebase() -> bool:
    """Initialize Firebase Admin SDK once at startup. Returns True if push can be sent."""
    global _app_initialized
    if _app_initialized:
        return True
    if not Config.FCM_ENABLED:
        logger.info("FCM disabled (FCM_ENABLED=false)")
        return False
    cred_path = (Config.FIREBASE_CREDENTIALS_PATH or "").strip()
    if not cred_path or not Path(cred_path).is_file():
        logger.warning(
            "FCM_ENABLED but FIREBASE_CREDENTIALS_PATH missing or not a file — push disabled"
        )
        return False
    try:
        import firebase_admin
        from firebase_admin import credentials

        if not firebase_admin._apps:
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
        _app_initialized = True
        logger.info("Firebase Admin initialized for FCM")
        return True
    except Exception as exc:
        logger.exception("Firebase Admin init failed: %s", exc)
        return False


def _send_sync(token: str, title: str, body: str, data: dict[str, str]) -> None:
    from firebase_admin import messaging

    message = messaging.Message(
        notification=messaging.Notification(title=title, body=body),
        data=data,
        token=token,
        android=messaging.AndroidConfig(priority="high"),
        apns=messaging.APNSConfig(
            payload=messaging.APNSPayload(aps=messaging.Aps(sound="default", badge=1))
        ),
    )
    messaging.send(message)


async def send_to_user(
    db: AsyncSession,
    user_uuid: UUID,
    *,
    title: str,
    body: str,
    notification_type: str,
    listing_uuid: UUID | None = None,
    claim_uuid: UUID | None = None,
) -> None:
    if not _app_initialized:
        return
    user = await user_crud.get_user_by_uuid(db, user_uuid)
    if not user or not user.fcm_token:
        return

    data: dict[str, str] = {"type": notification_type}
    if listing_uuid:
        data["listing_id"] = str(listing_uuid)
    if claim_uuid:
        data["claim_id"] = str(claim_uuid)

    try:
        await asyncio.to_thread(_send_sync, user.fcm_token, title, body, data)
        logger.info("FCM sent to user %s (%s)", user_uuid, notification_type)
    except Exception as exc:
        err_name = type(exc).__name__
        if err_name in ("UnregisteredError", "SenderIdMismatchError", "NotFoundError"):
            user.fcm_token = None
            await user_crud.update_user(db, user)
            logger.info("Cleared invalid FCM token for user %s", user_uuid)
        else:
            logger.warning("FCM send failed for user %s: %s", user_uuid, exc)
