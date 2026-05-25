from datetime import datetime, timedelta, timezone
from typing import Any, Optional

from jose import JWTError, jwt

from app.core.config import Config
from app.core.enums import OneTimeTokenType, TokenType


def _token_config(token_type: TokenType | OneTimeTokenType) -> dict:
    if token_type == TokenType.ACCESS:
        return {
            "secret": Config.ACCESS_SECRET,
            "expires": timedelta(minutes=Config.ACCESS_TOKEN_EXPIRE_MINUTES),
        }
    if token_type == TokenType.REFRESH:
        return {
            "secret": Config.REFRESH_SECRET,
            "expires": timedelta(days=Config.REFRESH_TOKEN_EXPIRE_DAYS),
        }
    return {"secret": Config.SECRET_KEY, "expires": timedelta(minutes=15)}


def create_token(
    subject: Any,
    token_type: TokenType | OneTimeTokenType,
    extra_claims: Optional[dict] = None,
) -> str:
    cfg = _token_config(token_type)
    expire = datetime.now(timezone.utc) + cfg["expires"]
    payload = {"sub": str(subject), "type": token_type.value, "exp": expire}
    if extra_claims:
        payload.update(extra_claims)
    return jwt.encode(payload, cfg["secret"], algorithm=Config.ALGORITHM)


def decode_token(
    token: str,
    token_type: TokenType | OneTimeTokenType,
) -> Optional[str]:
    cfg = _token_config(token_type)
    try:
        payload = jwt.decode(token, cfg["secret"], algorithms=[Config.ALGORITHM])
        if payload.get("type") != token_type.value:
            return None
        return payload.get("sub")
    except JWTError:
        return None


def decode_token_full(
    token: str,
    token_type: TokenType | OneTimeTokenType,
) -> Optional[dict]:
    cfg = _token_config(token_type)
    try:
        payload = jwt.decode(token, cfg["secret"], algorithms=[Config.ALGORITHM])
        if payload.get("type") != token_type.value:
            return None
        return payload
    except JWTError:
        return None
