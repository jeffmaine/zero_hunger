from fastapi import APIRouter, Depends, Query, Request
from fastapi.responses import RedirectResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Config
from app.db.session import get_db_session
from app.exceptions.custom import BadRequestException
from app.schemas.auth import GoogleAuthRequest, GoogleMobileAuthRequest, TokenResponse
from app.services import oauth as oauth_service

router = APIRouter(prefix="/oauth/google", tags=["Google Auth"])


@router.get("/login")
async def google_login(as_json: bool = Query(False)):
    url = oauth_service.get_google_login_url()
    if as_json:
        return {"url": url}
    return RedirectResponse(url=url)


@router.get("/callback")
async def google_callback(request: Request):
    code = request.query_params.get("code")
    if not code:
        raise BadRequestException("Missing authorization code", code="MISSING_CODE")
    session_token = await oauth_service.create_google_session_token(code)
    base = Config.FRONTEND_REDIRECT_URL.rstrip("/")
    return RedirectResponse(url=f"{base}?session_token={session_token}")


@router.post("/authenticate", response_model=TokenResponse)
async def google_authenticate(
    data: GoogleAuthRequest,
    db: AsyncSession = Depends(get_db_session),
):
    access, refresh = await oauth_service.authenticate_session_token(
        db, data.session_token, data.role, data.phone
    )
    return TokenResponse(access_token=access, refresh_token=refresh)


@router.post("/mobile", response_model=TokenResponse)
async def google_mobile(
    data: GoogleMobileAuthRequest,
    db: AsyncSession = Depends(get_db_session),
):
    access, refresh = await oauth_service.authenticate_google_id_token(db, data)
    return TokenResponse(access_token=access, refresh_token=refresh)
