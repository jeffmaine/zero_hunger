import secrets
from urllib.parse import urlencode

import httpx
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Config
from app.core.enums import OneTimeTokenType, TokenType, UserRole
from app.core.logging import get_logger
from app.exceptions.custom import BadRequestException, UnauthorizedException
from app.schemas.auth import GoogleMobileAuthRequest
from app.services.auth import get_or_create_google_user, issue_tokens
from app.utils.tokens import create_token, decode_token_full

logger = get_logger(__name__)

GOOGLE_AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth"
GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token"
GOOGLE_USERINFO_URL = "https://www.googleapis.com/oauth2/v3/userinfo"


def get_google_login_url() -> str:
    if not Config.google_configured:
        raise BadRequestException("Google OAuth not configured", code="GOOGLE_NOT_CONFIGURED")
    params = {
        "client_id": Config.GOOGLE_CLIENT_ID,
        "redirect_uri": Config.GOOGLE_REDIRECT_URI,
        "response_type": "code",
        "scope": "openid email profile",
        "state": secrets.token_urlsafe(16),
        "access_type": "offline",
    }
    return f"{GOOGLE_AUTH_URL}?{urlencode(params)}"


async def exchange_code_for_token(code: str) -> dict:
    async with httpx.AsyncClient() as client:
        response = await client.post(
            GOOGLE_TOKEN_URL,
            data={
                "code": code,
                "client_id": Config.GOOGLE_CLIENT_ID,
                "client_secret": Config.GOOGLE_CLIENT_SECRET,
                "redirect_uri": Config.GOOGLE_REDIRECT_URI,
                "grant_type": "authorization_code",
            },
        )
        if response.status_code != 200:
            raise UnauthorizedException("Failed to exchange Google code", code="GOOGLE_TOKEN_ERROR")
        return response.json()


async def fetch_google_userinfo(access_token: str) -> dict:
    async with httpx.AsyncClient() as client:
        response = await client.get(
            GOOGLE_USERINFO_URL,
            headers={"Authorization": f"Bearer {access_token}"},
        )
        if response.status_code != 200:
            raise UnauthorizedException("Failed to fetch Google profile", code="GOOGLE_USERINFO_ERROR")
        return response.json()


async def create_google_session_token(code: str) -> str:
    token_data = await exchange_code_for_token(code)
    google_access = token_data.get("access_token")
    if not google_access:
        raise UnauthorizedException("No access token from Google", code="GOOGLE_TOKEN_ERROR")
    profile = await fetch_google_userinfo(google_access)
    email = profile.get("email")
    if not email:
        raise BadRequestException("Google account has no email", code="GOOGLE_NO_EMAIL")
    return create_token(
        email,
        OneTimeTokenType.GOOGLE_SESSION,
        extra_claims={"name": profile.get("name"), "picture": profile.get("picture")},
    )


async def authenticate_session_token(
    db: AsyncSession,
    session_token: str,
    role: UserRole,
    phone: str,
) -> tuple[str, str]:
    payload = decode_token_full(session_token, OneTimeTokenType.GOOGLE_SESSION)
    if not payload:
        raise UnauthorizedException("Invalid Google session", code="INVALID_GOOGLE_SESSION")
    email = payload.get("sub")
    if not email:
        raise UnauthorizedException("Invalid Google session payload", code="INVALID_GOOGLE_SESSION")
    user = await get_or_create_google_user(
        db,
        email=email,
        name=payload.get("name", ""),
        role=role,
        phone=phone,
        avatar_url=payload.get("picture"),
    )
    logger.info("Google authenticate: %s", email)
    return issue_tokens(user)


async def authenticate_google_id_token(
    db: AsyncSession,
    data: GoogleMobileAuthRequest,
) -> tuple[str, str]:
    if not Config.GOOGLE_CLIENT_ID:
        raise BadRequestException("Google OAuth not configured", code="GOOGLE_NOT_CONFIGURED")
    try:
        from google.oauth2 import id_token as google_id_token
        from google.auth.transport import requests as google_requests

        idinfo = google_id_token.verify_oauth2_token(
            data.id_token,
            google_requests.Request(),
            Config.GOOGLE_CLIENT_ID,
        )
    except Exception as exc:
        raise UnauthorizedException("Invalid Google ID token", code="INVALID_GOOGLE_TOKEN") from exc
    email = idinfo.get("email")
    if not email:
        raise BadRequestException("Google token missing email", code="GOOGLE_NO_EMAIL")
    user = await get_or_create_google_user(
        db,
        email=email,
        name=idinfo.get("name", ""),
        role=data.role,
        phone=data.phone,
        avatar_url=idinfo.get("picture"),
    )
    return issue_tokens(user)
