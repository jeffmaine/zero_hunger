from typing import Any, List, Sequence

from fastapi import Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from sqlalchemy.exc import IntegrityError
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.core.logging import get_logger
from app.exceptions.custom import BaseAppException
from app.utils.response import error_response

logger = get_logger(__name__)


async def http_exception_handler(request: Request, exc: StarletteHTTPException) -> JSONResponse:
    logger.warning("HTTP %d on %s %s: %s", exc.status_code, request.method, request.url.path, exc.detail)
    return error_response(status_code=exc.status_code, message=str(exc.detail))


def _format_validation_errors(raw_errors: Sequence[Any]) -> List[dict]:
    formatted: List[dict] = []
    for err in raw_errors:
        loc = err.get("loc", ())
        formatted.append(
            {
                "field": ".".join(str(part) for part in loc),
                "message": err.get("msg", "Validation error"),
                "type": err.get("type", "value_error"),
            }
        )
    return formatted


async def validation_exception_handler(
    request: Request, exc: RequestValidationError
) -> JSONResponse:
    errors = _format_validation_errors(exc.errors())
    return error_response(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        message="Validation error",
        errors=errors,
        code="VALIDATION_ERROR",
    )


async def integrity_error_handler(request: Request, exc: IntegrityError) -> JSONResponse:
    pgcode = getattr(exc.orig, "pgcode", None)
    if pgcode == "23505":
        return error_response(
            status_code=status.HTTP_409_CONFLICT,
            message="A record with the given details already exists.",
            code="DUPLICATE_ENTRY",
        )
    return error_response(
        status_code=status.HTTP_400_BAD_REQUEST,
        message="A data conflict occurred.",
        code="INTEGRITY_ERROR",
    )


async def app_exception_handler(request: Request, exc: BaseAppException) -> JSONResponse:
    if exc.status_code >= 500:
        logger.error("Server error on %s %s: %s", request.method, request.url.path, exc.message)
    else:
        logger.warning("Client error on %s %s: %s", request.method, request.url.path, exc.message)
    return error_response(
        status_code=exc.status_code,
        message=exc.message,
        errors=exc.errors,
        code=exc.code,
    )


async def generic_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    logger.error("Unhandled on %s %s: %s", request.method, request.url.path, exc, exc_info=True)
    return error_response(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        message="Internal server error",
        code="INTERNAL_ERROR",
    )
