from fastapi import APIRouter

from app.api.v1.routers import admin, auth, claims, donors, google_auth, health, listings, notifications, users

router = APIRouter()
router.include_router(health.router)
router.include_router(auth.router)
router.include_router(users.router)
router.include_router(google_auth.router)
router.include_router(listings.router)
router.include_router(claims.router)
router.include_router(donors.router)
router.include_router(notifications.router)
router.include_router(admin.router)
