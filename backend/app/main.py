from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy.exc import IntegrityError
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.api.v1.routers import router as v1_router
from app.core.config import Config
from app.core.logging import setup_logging, get_logger
from app.core.scheduler import scheduler, setup_scheduler
from app.services import fcm as fcm_service
from app.db.session import database
from app.exceptions import BaseAppException
from app.exceptions.handler import (
    app_exception_handler,
    generic_exception_handler,
    http_exception_handler,
    integrity_error_handler,
    validation_exception_handler,
)
from app.middleware.request_id import RequestIDMiddleware

setup_logging()
logger = get_logger(__name__)


@asynccontextmanager
async def lifespan(_app: FastAPI):
    await database.startup()
    fcm_service.init_firebase()
    setup_scheduler()
    scheduler.start()
    logger.info("Scheduler started")
    yield
    scheduler.shutdown(wait=False)
    await database.shutdown()


app = FastAPI(
    title=Config.APP_NAME,
    description=Config.APP_DESCRIPTION,
    version=Config.APP_VERSION,
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)


@app.middleware("http")
async def enforce_request_size_limit(request: Request, call_next):
    content_length = request.headers.get("content-length")
    if content_length is not None:
        try:
            if int(content_length) > Config.MAX_REQUEST_BODY_BYTES:
                return JSONResponse(
                    status_code=413,
                    content={"status": "error", "message": "Request payload too large"},
                )
        except ValueError:
            return JSONResponse(
                status_code=400,
                content={"status": "error", "message": "Invalid Content-Length header"},
            )
    return await call_next(request)


cors_origins = [o.strip() for o in Config.CORS_ORIGINS.split(",") if o.strip()]
app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=True,
    allow_methods=[m.strip() for m in Config.CORS_METHODS.split(",")],
    allow_headers=[h.strip() for h in Config.CORS_HEADERS.split(",")],
)
app.add_middleware(GZipMiddleware, minimum_size=1000)
app.add_middleware(RequestIDMiddleware)

app.add_exception_handler(StarletteHTTPException, http_exception_handler)
app.add_exception_handler(RequestValidationError, validation_exception_handler)
app.add_exception_handler(IntegrityError, integrity_error_handler)
app.add_exception_handler(BaseAppException, app_exception_handler)
app.add_exception_handler(Exception, generic_exception_handler)

app.include_router(v1_router, prefix="/api/v1")


@app.get("/")
async def root():
    return {"name": Config.APP_NAME, "docs": "/docs", "api": "/api/v1"}
