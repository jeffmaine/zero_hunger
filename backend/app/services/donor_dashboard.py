from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import ListingStatus, NotificationType
from app.cruds import claim as claim_crud
from app.cruds import listing as listing_crud
from app.cruds import notification as notification_crud
from app.cruds import user as user_crud
from app.models.user import User
from app.schemas.donor_dashboard import DonorDashboardResponse, DonorStats, NearbyActivityItem
from app.services import notification as notification_service
from app.services.geo import haversine_km
from app.services.listing import list_nearby, listing_to_public


async def _sync_claim_notifications(db: AsyncSession, donor: User) -> None:
    """Backfill in-app notifications for pending claims (e.g. before notifications table existed)."""
    pending = await claim_crud.list_pending_for_donor(db, donor.uuid)
    for claim in pending:
        exists = await notification_crud.exists_for_user_claim_type(
            db,
            donor.uuid,
            claim.uuid,
            NotificationType.CLAIM_RECEIVED.value,
        )
        if exists:
            continue
        listing = await listing_crud.get_listing_by_uuid(db, claim.listing_uuid)
        receiver = await user_crud.get_user_by_uuid(db, claim.receiver_uuid)
        if not listing or not receiver:
            continue
        try:
            async with db.begin_nested():
                await notification_service.notify_new_claim(
                    db, donor.uuid, listing, claim.uuid, receiver.name
                )
        except Exception:
            continue


async def _build_nearby_activity(
    db: AsyncSession,
    donor: User,
    lat: float | None,
    lng: float | None,
    radius_km: float | None,
) -> list[NearbyActivityItem]:
    activity: list[NearbyActivityItem] = []

    if lat is not None and lng is not None:
        nearby = await list_nearby(db, lat, lng, radius_km)
        for item in nearby.listings:
            if item.donor_id == donor.uuid:
                continue
            activity.append(
                NearbyActivityItem(
                    listing_id=item.id,
                    donor_id=item.donor_id,
                    donor_name=item.donor_name or "Someone",
                    listing_title=item.title,
                    image_url=item.image_url,
                    created_at=item.created_at,
                    distance_km=item.distance_km,
                )
            )
            if len(activity) >= 8:
                return activity

        if activity:
            return activity

    # Fallback: recent community posts when geo is unavailable or no nearby matches
    rows = await listing_crud.list_recent_available_excluding_donor(db, donor.uuid, limit=8)
    for listing in rows:
        donor_user = await user_crud.get_user_by_uuid(db, listing.donor_uuid)
        dist = None
        if lat is not None and lng is not None:
            dist = round(haversine_km(lat, lng, listing.latitude, listing.longitude), 2)
        activity.append(
            NearbyActivityItem(
                listing_id=listing.uuid,
                donor_id=listing.donor_uuid,
                donor_name=donor_user.name if donor_user else "Someone",
                listing_title=listing.title,
                image_url=listing.image_url,
                created_at=listing.created_at,
                distance_km=dist,
            )
        )
    return activity


async def get_donor_dashboard(
    db: AsyncSession,
    donor: User,
    lat: float | None,
    lng: float | None,
    radius_km: float | None = None,
) -> DonorDashboardResponse:
    donor_uuid = donor.uuid
    await _sync_claim_notifications(db, donor)

    listings = await listing_crud.list_by_donor(db, donor_uuid)
    active_statuses = {ListingStatus.AVAILABLE.value, ListingStatus.CLAIMED.value}
    active_count = sum(1 for listing in listings if listing.status in active_statuses)
    pending_claims = await claim_crud.count_pending_for_donor(db, donor_uuid)
    unread_notifications = await notification_crud.count_unread(db, donor_uuid)

    recent_candidates = [
        listing for listing in listings if listing.status in active_statuses
    ]
    recent = [listing_to_public(listing, donor) for listing in recent_candidates[:3]]
    activity = await _build_nearby_activity(db, donor, lat, lng, radius_km)

    return DonorDashboardResponse(
        stats=DonorStats(
            active_listings=active_count,
            total_posted=len(listings),
            pending_claims=pending_claims,
            unread_notifications=unread_notifications,
        ),
        recent_listings=recent[:3],
        nearby_activity=activity,
    )
