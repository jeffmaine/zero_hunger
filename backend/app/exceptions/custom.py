from typing import Any, Dict, Optional

from fastapi import status


class BaseAppException(Exception):
    __slots__ = ("message", "status_code", "errors", "code")

    default_status_code: int = status.HTTP_400_BAD_REQUEST
    default_message: str = "An application error occurred"
    default_code: str = "APP_ERROR"

    def __init__(
        self,
        message: Optional[str] = None,
        status_code: Optional[int] = None,
        errors: Optional[Dict[str, Any]] = None,
        code: Optional[str] = None,
    ) -> None:
        self.message = message or self.default_message
        self.status_code = status_code or self.default_status_code
        self.errors = errors or {}
        self.code = code or self.default_code
        super().__init__(self.message)


class BadRequestException(BaseAppException):
    default_status_code = status.HTTP_400_BAD_REQUEST
    default_message = "Invalid request"
    default_code = "BAD_REQUEST"


class UnauthorizedException(BaseAppException):
    default_status_code = status.HTTP_401_UNAUTHORIZED
    default_message = "Authentication required"
    default_code = "UNAUTHORIZED"


class ForbiddenException(BaseAppException):
    default_status_code = status.HTTP_403_FORBIDDEN
    default_message = "Access forbidden"
    default_code = "FORBIDDEN"


class NotFoundException(BaseAppException):
    default_status_code = status.HTTP_404_NOT_FOUND
    default_message = "Resource not found"
    default_code = "NOT_FOUND"


class DuplicateEntryException(BaseAppException):
    default_status_code = status.HTTP_409_CONFLICT
    default_message = "Duplicate entry detected"
    default_code = "DUPLICATE_ENTRY"
