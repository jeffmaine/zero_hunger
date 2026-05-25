from typing import Any, Dict, List, Optional, Union

from fastapi import status
from fastapi.encoders import jsonable_encoder
from fastapi.responses import JSONResponse


def success_response(
    status_code: int = status.HTTP_200_OK,
    message: str = "Request successful",
    data: Any = None,
) -> JSONResponse:
    if data is not None:
        if isinstance(data, list):
            data = [
                item.model_dump() if hasattr(item, "model_dump") else item
                for item in data
            ]
        elif hasattr(data, "model_dump"):
            data = data.model_dump()
    return JSONResponse(
        status_code=status_code,
        content=jsonable_encoder(
            {"status": "success", "message": message, "data": data if data is not None else {}}
        ),
    )


def error_response(
    status_code: int = status.HTTP_400_BAD_REQUEST,
    message: str = "An error occurred",
    errors: Optional[Union[str, Dict[str, Any], List[Dict[str, Any]]]] = None,
    code: Optional[str] = None,
) -> JSONResponse:
    details: dict = {}
    if code:
        details["code"] = code
    if isinstance(errors, dict):
        details.update(errors)
    elif errors is not None:
        details["detail"] = errors
    else:
        details["detail"] = message
    return JSONResponse(
        status_code=status_code,
        content=jsonable_encoder(
            {"status": "error", "message": message, "details": details}
        ),
    )
