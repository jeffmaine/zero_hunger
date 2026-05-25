import secrets

from passlib.context import CryptContext
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import AuthProvider, TokenType, UserRole
from app.core.logging import get_logger
from app.cruds import user as user_crud
from app.exceptions.custom import (
    BadRequestException,
    DuplicateEntryException,
    ForbiddenException,
    UnauthorizedException,
)
from app.models.user import User
from app.schemas.auth import LoginRequest, RegisterRequest
from app.utils.tokens import create_token, decode_token

logger = get_logger(__name__)
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


def issue_tokens(user: User) -> tuple[str, str]:
    return (
        create_token(user.uuid, TokenType.ACCESS),
        create_token(user.uuid, TokenType.REFRESH),
    )


async def register_user(db: AsyncSession, data: RegisterRequest) -> tuple[str, str]:
    if data.role in (UserRole.ADMIN, UserRole.VOLUNTEER):
        raise BadRequestException(
            "Cannot self-register as admin or volunteer",
            code="INVALID_ROLE",
        )
    if await user_crud.get_user_by_email(db, data.email):
        raise DuplicateEntryException("Email already registered", code="EMAIL_EXISTS")
    user = User(
        name=data.name,
        email=data.email.lower(),
        hashed_password=hash_password(data.password),
        role=data.role,
        phone=data.phone,
        auth_provider=AuthProvider.MANUAL.value,
        latitude=data.latitude,
        longitude=data.longitude,
    )
    user = await user_crud.create_user(db, user)
    logger.info("Registered user %s as %s", user.email, user.role)
    return issue_tokens(user)


async def login_user(db: AsyncSession, data: LoginRequest) -> tuple[str, str]:
    user = await user_crud.get_user_by_email(db, data.email)
    if user and user.auth_provider == AuthProvider.GOOGLE.value:
        raise BadRequestException("Use Google sign-in for this account", code="USE_GOOGLE_AUTH")
    if not user or not verify_password(data.password, user.hashed_password):
        raise UnauthorizedException("Invalid email or password", code="INVALID_CREDENTIALS")
    if not user.is_active:
        raise ForbiddenException("Account is inactive", code="ACCOUNT_INACTIVE")
    return issue_tokens(user)


async def get_current_user(db: AsyncSession, token: str) -> User:
    user_uuid = decode_token(token, TokenType.ACCESS)
    if not user_uuid:
        raise UnauthorizedException("Invalid or expired token", code="INVALID_TOKEN")
    from uuid import UUID

    user = await user_crud.get_user_by_uuid(db, UUID(user_uuid))
    if not user or not user.is_active:
        raise UnauthorizedException("User not found or inactive", code="USER_NOT_FOUND")
    return user


async def refresh_access_token(db: AsyncSession, token: str) -> tuple[str, str]:
    user_uuid = decode_token(token, TokenType.REFRESH)
    if not user_uuid:
        raise UnauthorizedException("Invalid refresh token", code="INVALID_REFRESH")
    from uuid import UUID

    user = await user_crud.get_user_by_uuid(db, UUID(user_uuid))
    if not user or not user.is_active:
        raise UnauthorizedException("User not found", code="USER_NOT_FOUND")
    return issue_tokens(user)


async def get_or_create_google_user(
    db: AsyncSession,
    email: str,
    name: str,
    role: UserRole,
    phone: str = "",
    avatar_url: str | None = None,
) -> User:
    user = await user_crud.get_user_by_email(db, email)
    if user:
        if not user.is_active:
            raise ForbiddenException("Account is inactive", code="ACCOUNT_INACTIVE")
        if avatar_url and not user.avatar_url:
            user.avatar_url = avatar_url
            await user_crud.update_user(db, user)
        return user
    if role in (UserRole.ADMIN, UserRole.VOLUNTEER):
        raise BadRequestException("Invalid role for Google signup", code="INVALID_ROLE")
    user = User(
        name=name or email.split("@")[0],
        email=email.lower(),
        hashed_password=hash_password(secrets.token_urlsafe(32)),
        role=role,
        phone=phone,
        auth_provider=AuthProvider.GOOGLE.value,
        is_verified=True,
        avatar_url=avatar_url,
    )
    return await user_crud.create_user(db, user)
