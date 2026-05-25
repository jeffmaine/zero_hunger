"""Request-ID middleware for log correlation (adapted from Ohun backend)."""

from __future__ import annotations

import secrets
from contextvars import ContextVar
from typing import Any, Callable

request_id_ctx: ContextVar[str] = ContextVar("request_id", default="-")
_REQUEST_ID_HEADER = b"x-request-id"


class RequestIDMiddleware:
    def __init__(self, app: Any) -> None:
        self.app = app

    async def __call__(self, scope: dict, receive: Callable, send: Callable) -> None:
        if scope["type"] not in ("http", "websocket"):
            await self.app(scope, receive, send)
            return
        rid = None
        for header_name, header_value in scope.get("headers", []):
            if header_name == _REQUEST_ID_HEADER:
                rid = header_value.decode("latin-1")
                break
        if not rid:
            rid = secrets.token_hex(16)
        token = request_id_ctx.set(rid)

        async def send_with_request_id(message: dict) -> None:
            if message["type"] == "http.response.start":
                headers = list(message.get("headers", []))
                headers.append((_REQUEST_ID_HEADER, rid.encode("latin-1")))
                message["headers"] = headers
            await send(message)

        try:
            await self.app(scope, receive, send_with_request_id)
        finally:
            request_id_ctx.reset(token)
