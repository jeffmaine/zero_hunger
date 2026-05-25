from datetime import datetime
from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, File, Query, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies import get_authenticated_user, get_donor_user
from app.core.config import Config
from app.core.enums import ListingCategory
from app.db.session import get_db_session
from app.exceptions.custom import BadRequestException
from app.models.user import User
from app.schemas.auth import UserPublic
from app.schemas.listing import (
    ImageUploadResponse,
    ListingCreate,
    ListingDetail,
    ListingPublic,
    ListingStatusPatch,
    ListingUpdate,
)
from app.schemas.location import MapListingsResponse, NearbyListingsResponse
from app.services import cloudinary, listing as listing_service

router = APIRouter(prefix="/listings", tags=["Listings"])


@router.get("", response_model=NearbyListingsResponse)
async def list_listings(
    db: AsyncSession = Depends(get_db_session),
    lat: Optional[float] = Query(None, ge=-90, le=90, description="Search center latitude"),
    lng: Optional[float] = Query(None, ge=-180, le=180, description="Search center longitude"),
    radius: float = Query(
        Config.DEFAULT_SEARCH_RADIUS_KM,
        ge=0.5,
        le=Config.MAX_SEARCH_RADIUS_KM,
        description="Search radius in km (haversine)",
    ),
    category: Optional[ListingCategory] = None,
    expiry_before: Optional[datetime] = Query(
        None, description="Only listings with pickup_deadline on or before this time"
    ),
    _user: User = Depends(get_authenticated_user),
):
    if lat is None or lng is None:
        raise BadRequestException(
            "lat and lng are required for nearby browse. Use GPS or set your area manually.",
            code="MISSING_LOCATION",
        )
    return await listing_service.list_nearby(db, lat, lng, radius, category, expiry_before)


@router.get("/map", response_model=MapListingsResponse)
async def list_listings_map(
    db: AsyncSession = Depends(get_db_session),
    lat: Optional[float] = Query(None, ge=-90, le=90),
    lng: Optional[float] = Query(None, ge=-180, le=180),
    radius: float = Query(Config.DEFAULT_SEARCH_RADIUS_KM, ge=0.5, le=Config.MAX_SEARCH_RADIUS_KM),
    category: Optional[ListingCategory] = None,
    expiry_before: Optional[datetime] = None,
    _user: User = Depends(get_authenticated_user),
):
    if lat is None or lng is None:
        raise BadRequestException("lat and lng are required for map view", code="MISSING_LOCATION")
    return await listing_service.list_map_pins(db, lat, lng, radius, category, expiry_before)


@router.get("/mine", response_model=list[ListingPublic])
async def my_listings(
    db: AsyncSession = Depends(get_db_session),
    donor: User = Depends(get_donor_user),
):
    return await listing_service.list_mine(db, donor)


@router.post("/upload-image", response_model=ImageUploadResponse)
async def upload_image(
    file: UploadFile = File(...),
    _donor: User = Depends(get_donor_user),
):
    content = await file.read()
    if len(content) > 5 * 1024 * 1024:
        raise BadRequestException("Image must be under 5MB", code="FILE_TOO_LARGE")
    url = cloudinary.upload_image(content)
    return ImageUploadResponse(image_url=url)


@router.post("", response_model=ListingPublic, status_code=201)
async def create_listing(
    data: ListingCreate,
    db: AsyncSession = Depends(get_db_session),
    donor: User = Depends(get_donor_user),
):
    return await listing_service.create_listing(db, donor, data)


@router.get("/{listing_id}", response_model=ListingDetail)
async def get_listing(
    listing_id: UUID,
    db: AsyncSession = Depends(get_db_session),
    _user: User = Depends(get_authenticated_user),
    lat: Optional[float] = Query(None),
    lng: Optional[float] = Query(None),
):
    from app.cruds import listing as listing_crud
    from app.cruds import user as user_crud

    pub = await listing_service.get_listing_public(db, listing_id, lat, lng)
    listing = await listing_crud.get_listing_by_uuid(db, listing_id)
    donor = await user_crud.get_user_by_uuid(db, listing.donor_uuid) if listing else None
    return ListingDetail(**pub.model_dump(), donor=UserPublic.from_user(donor) if donor else None)


@router.put("/{listing_id}", response_model=ListingPublic)
async def update_listing(
    listing_id: UUID,
    data: ListingUpdate,
    db: AsyncSession = Depends(get_db_session),
    donor: User = Depends(get_donor_user),
):
    return await listing_service.update_listing(db, listing_id, donor, data)


@router.delete("/{listing_id}", status_code=204)
async def delete_listing(
    listing_id: UUID,
    db: AsyncSession = Depends(get_db_session),
    donor: User = Depends(get_donor_user),
):
    await listing_service.soft_delete(db, listing_id, donor)


@router.patch("/{listing_id}/status", response_model=ListingPublic)
async def patch_status(
    listing_id: UUID,
    data: ListingStatusPatch,
    db: AsyncSession = Depends(get_db_session),
    donor: User = Depends(get_donor_user),
):
    return await listing_service.patch_status(db, listing_id, donor, data.status)
