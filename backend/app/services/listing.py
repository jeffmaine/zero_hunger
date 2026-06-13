from datetime import datetime, timezone
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Config
from app.core.enums import ListingCategory, ListingStatus, UserRole
from app.cruds import listing as listing_crud
from app.cruds import user as user_crud
from app.exceptions.custom import ForbiddenException, NotFoundException
from app.models.listing import FoodListing
from app.models.user import User
from app.schemas.listing import ListingCreate, ListingPublic, ListingUpdate
from app.schemas.location import Coordinates, ListingMapPin, MapListingsResponse, NearbyListingsResponse
from app.services.geo import clamp_radius_km, haversine_km, is_within_radius, listing_is_pickup_valid


def listing_to_public(
    listing: FoodListing,
    donor: User | None = None,
    distance_km: float | None = None,
) -> ListingPublic:
    now = datetime.now(timezone.utc)
    created = listing.created_at
    if created.tzinfo is None:
        created = created.replace(tzinfo=timezone.utc)
    return ListingPublic(
        id=listing.uuid,
        donor_id=listing.donor_uuid,
        title=listing.title,
        description=listing.description,
        quantity=listing.quantity,
        category=ListingCategory(listing.category),
        image_url=listing.image_url,
        pickup_deadline=listing.pickup_deadline,
        latitude=listing.latitude,
        longitude=listing.longitude,
        status=ListingStatus(listing.status),
        created_at=listing.created_at,
        distance_km=round(distance_km, 2) if distance_km is not None else None,
        donor_name=donor.name if donor else None,
        donor_verified=donor.is_verified if donor else None,
        listed_today=created.date() == now.date(),
        pickup_location_label=listing.pickup_location_label,
    )


async def create_listing(db: AsyncSession, donor: User, data: ListingCreate) -> ListingPublic:
    lat = data.latitude
    lng = data.longitude
    if lat is None and donor.latitude is not None:
        lat = donor.latitude
    if lng is None and donor.longitude is not None:
        lng = donor.longitude
    if lat is None or lng is None:
        from app.exceptions.custom import BadRequestException

        raise BadRequestException(
            "Pickup latitude and longitude are required (or set your profile location first)",
            code="MISSING_LOCATION",
        )
    pickup_label = data.pickup_location_label or donor.location_label
    listing = FoodListing(
        donor_uuid=donor.uuid,
        title=data.title,
        description=data.description,
        quantity=data.quantity,
        category=data.category.value,
        image_url=data.image_url,
        pickup_deadline=data.pickup_deadline,
        latitude=lat,
        longitude=lng,
        pickup_location_label=pickup_label,
        status=ListingStatus.AVAILABLE.value,
    )
    listing = await listing_crud.create_listing(db, listing)
    return listing_to_public(listing, donor)


async def get_listing_public(
    db: AsyncSession,
    listing_uuid: UUID,
    lat: float | None = None,
    lng: float | None = None,
) -> ListingPublic:
    listing = await listing_crud.get_listing_by_uuid(db, listing_uuid)
    if not listing:
        raise NotFoundException("Listing not found", code="NOT_FOUND")
    donor = await user_crud.get_user_by_uuid(db, listing.donor_uuid)
    dist = None
    if lat is not None and lng is not None:
        dist = haversine_km(lat, lng, listing.latitude, listing.longitude)
    return listing_to_public(listing, donor, dist)


async def list_nearby(
    db: AsyncSession,
    lat: float,
    lng: float,
    radius_km: float | None = None,
    category: ListingCategory | None = None,
    expiry_before: datetime | None = None,
) -> NearbyListingsResponse:
    from datetime import timezone

    radius = clamp_radius_km(radius_km or Config.DEFAULT_SEARCH_RADIUS_KM)
    cat = category.value if category else None
    now = datetime.now(timezone.utc)
    candidates = await listing_crud.list_available_in_bbox(
        db, lat, lng, radius, cat, expiry_before
    )
    results: list[ListingPublic] = []
    for listing in candidates:
        if not listing_is_pickup_valid(listing.pickup_deadline, now, expiry_before):
            continue
        dist = haversine_km(lat, lng, listing.latitude, listing.longitude)
        if not is_within_radius(lat, lng, listing.latitude, listing.longitude, radius):
            continue
        donor = await user_crud.get_user_by_uuid(db, listing.donor_uuid)
        results.append(listing_to_public(listing, donor, dist))
    results.sort(key=lambda x: x.distance_km or 999)
    return NearbyListingsResponse(
        center=Coordinates(latitude=lat, longitude=lng),
        radius_km=radius,
        count=len(results),
        listings=results,
    )


async def list_map_pins(
    db: AsyncSession,
    lat: float,
    lng: float,
    radius_km: float | None = None,
    category: ListingCategory | None = None,
    expiry_before: datetime | None = None,
) -> MapListingsResponse:
    nearby = await list_nearby(db, lat, lng, radius_km, category, expiry_before)
    pins = [
        ListingMapPin(
            id=item.id,
            title=item.title,
            latitude=item.latitude,
            longitude=item.longitude,
            distance_km=item.distance_km or 0,
            pickup_deadline=item.pickup_deadline,
            status=item.status,
        )
        for item in nearby.listings
    ]
    return MapListingsResponse(
        center=nearby.center,
        radius_km=nearby.radius_km,
        count=len(pins),
        pins=pins,
    )


async def list_mine(db: AsyncSession, donor: User) -> list[ListingPublic]:
    listings = await listing_crud.list_by_donor(db, donor.uuid)
    return [listing_to_public(listing) for listing in listings]


async def update_listing(
    db: AsyncSession, listing_uuid: UUID, donor: User, data: ListingUpdate
) -> ListingPublic:
    listing = await listing_crud.get_listing_by_uuid(db, listing_uuid)
    if not listing:
        raise NotFoundException("Listing not found", code="NOT_FOUND")
    if listing.donor_uuid != donor.uuid:
        raise ForbiddenException("Not your listing", code="FORBIDDEN")
    dump = data.model_dump(exclude_unset=True)
    if "category" in dump and dump["category"] is not None:
        dump["category"] = dump["category"].value
    for field, value in dump.items():
        setattr(listing, field, value)
    listing = await listing_crud.update_listing(db, listing)
    return listing_to_public(listing, donor)


async def soft_delete(db: AsyncSession, listing_uuid: UUID, user: User) -> None:
    listing = await listing_crud.get_listing_by_uuid(db, listing_uuid)
    if not listing:
        raise NotFoundException("Listing not found", code="NOT_FOUND")
    if listing.donor_uuid != user.uuid and user.role != UserRole.ADMIN:
        raise ForbiddenException("Not allowed", code="FORBIDDEN")
    listing.deleted_at = datetime.now(timezone.utc)
    await listing_crud.update_listing(db, listing)


async def patch_status(
    db: AsyncSession, listing_uuid: UUID, donor: User, status: ListingStatus
) -> ListingPublic:
    listing = await listing_crud.get_listing_by_uuid(db, listing_uuid)
    if not listing:
        raise NotFoundException("Listing not found", code="NOT_FOUND")
    if listing.donor_uuid != donor.uuid:
        raise ForbiddenException("Not your listing", code="FORBIDDEN")
    listing.status = status.value
    listing = await listing_crud.update_listing(db, listing)
    return listing_to_public(listing, donor)


async def expire_past_deadline(db: AsyncSession) -> int:
    from app.services import claim as claim_service

    now = datetime.now(timezone.utc)
    count = 0
    for listing in await listing_crud.list_expirable(db):
        deadline = listing.pickup_deadline
        if deadline.tzinfo is None:
            deadline = deadline.replace(tzinfo=timezone.utc)
        if deadline < now:
            if listing.status == ListingStatus.CLAIMED.value:
                await claim_service.process_expired_listing_claim(db, listing)
            else:
                listing.status = ListingStatus.EXPIRED.value
            count += 1
    if count:
        await db.commit()
    return count
