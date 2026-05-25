from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies import get_authenticated_user
from app.db.session import get_db_session
from app.models.user import User
from app.schemas.auth import (
    LoginRequest,
    RefreshRequest,
    RegisterRequest,
    TokenResponse,
    UserPublic,
)
from app.schemas.location import UserLocationUpdate
from app.services import auth as auth_service
from app.services import user_location as location_service

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post("/register", response_model=TokenResponse, status_code=201)
async def register(data: RegisterRequest, db: AsyncSession = Depends(get_db_session)):
    access, refresh = await auth_service.register_user(db, data)
    return TokenResponse(access_token=access, refresh_token=refresh)


async def _parse_login(request: Request) -> LoginRequest:
    content_type = request.headers.get("content-type", "")
    if "application/json" in content_type:
        body = await request.json()
        return LoginRequest.model_validate(body)
    form = await request.form()
    email = form.get("username") or form.get("email")
    password = form.get("password")
    if not email or not password:
        raise HTTPException(status_code=422, detail="username (email) and password required")
    return LoginRequest(email=str(email), password=str(password))


@router.post("/login", response_model=TokenResponse)
async def login(request: Request, db: AsyncSession = Depends(get_db_session)):
    data = await _parse_login(request)
    access, refresh = await auth_service.login_user(db, data)
    return TokenResponse(access_token=access, refresh_token=refresh)


@router.post("/refresh", response_model=TokenResponse)
async def refresh(data: RefreshRequest, db: AsyncSession = Depends(get_db_session)):
    access, refresh_tok = await auth_service.refresh_access_token(db, data.refresh_token)
    return TokenResponse(access_token=access, refresh_token=refresh_tok)


@router.get("/me", response_model=UserPublic)
async def me(user: User = Depends(get_authenticated_user)):
    return UserPublic.from_user(user)


@router.patch("/location", response_model=UserPublic)
async def update_location(
    data: UserLocationUpdate,
    db: AsyncSession = Depends(get_db_session),
    user: User = Depends(get_authenticated_user),
):
    """
    Save the user's search/home coordinates (GPS, manual geocode, or hybrid override).
    Flutter should call this after permission grant or manual area selection.
    """
    return await location_service.update_user_location(db, user, data)
