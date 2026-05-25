import secrets
from datetime import datetime, timezone
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Config
from app.core.enums import ClaimStatus, ListingStatus, NotificationType, UserRole
from app.cruds import claim as claim_crud
from app.cruds import listing as listing_crud
from app.cruds import user as user_crud
from app.exceptions.custom import BadRequestException, ForbiddenException, NotFoundException
from app.models.claim import Claim
from app.models.user import User
from app.schemas.claim import ClaimLimitsResponse, ClaimPublic
from app.services import claim_fairness
from app.services import listing as listing_service
from app.services import notification as notification_service


def _generate_pickup_code() -> str:
    return f"{secrets.randbelow(10000):04d}"


async def claim_to_public(
    db: AsyncSession,
    claim: Claim,
    include_listing: bool = True,
    *,
    priority_rank: int | None = None,
    receiver_pickups: int | None = None,
    receiver_no_shows: int | None = None,
) -> ClaimPublic:
    listing_data = None
    if include_listing:
        listing = await listing_crud.get_listing_by_uuid(db, claim.listing_uuid)
        donor = await user_crud.get_user_by_uuid(db, listing.donor_uuid) if listing else None
        if listing:
            listing_data = listing_service.listing_to_public(listing, donor)
    receiver = await user_crud.get_user_by_uuid(db, claim.receiver_uuid)
    show_code = claim.status in (
        ClaimStatus.APPROVED.value,
        ClaimStatus.COLLECTED.value,
    )
    return ClaimPublic(
        id=claim.uuid,
        listing_id=claim.listing_uuid,
        receiver_id=claim.receiver_uuid,
        status=ClaimStatus(claim.status),
        created_at=claim.created_at,
        listing=listing_data,
        receiver_name=receiver.name.split()[0] if receiver else None,
        pickup_code=claim.pickup_code if show_code else None,
        collected_at=claim.collected_at,
        priority_rank=priority_rank,
        receiver_pickups=receiver_pickups,
        receiver_no_shows=receiver_no_shows,
    )


async def get_claim_limits(db: AsyncSession, receiver: User) -> ClaimLimitsResponse:
    active = await claim_crud.count_active_for_receiver(db, receiver.uuid)
    no_shows = receiver.claim_no_shows or 0
    can_claim = True
    message = None
    cooldown_ends = None

    if no_shows >= Config.MAX_CLAIM_NO_SHOWS:
        can_claim = False
        message = (
            f"Account paused after {Config.MAX_CLAIM_NO_SHOWS} missed pickups. "
            "Contact support if you need help."
        )
    elif active >= Config.MAX_ACTIVE_CLAIMS_PER_RECEIVER:
        can_claim = False
        message = (
            f"You have {active} active claim(s). "
            f"Maximum is {Config.MAX_ACTIVE_CLAIMS_PER_RECEIVER}."
        )
    elif receiver.last_successful_pickup_at is not None:
        last = receiver.last_successful_pickup_at
        if last.tzinfo is None:
            last = last.replace(tzinfo=timezone.utc)
        from datetime import timedelta

        cooldown_ends = last + timedelta(hours=Config.CLAIM_COOLDOWN_HOURS)
        if datetime.now(timezone.utc) < cooldown_ends:
            can_claim = False
            message = "Short cooldown after your last successful pickup."

    return ClaimLimitsResponse(
        max_active_claims=Config.MAX_ACTIVE_CLAIMS_PER_RECEIVER,
        active_claims=active,
        cooldown_hours=Config.CLAIM_COOLDOWN_HOURS,
        can_claim=can_claim,
        cooldown_ends_at=cooldown_ends,
        message=message,
        claim_no_shows=no_shows,
        max_no_shows=Config.MAX_CLAIM_NO_SHOWS,
    )


async def create_claim(db: AsyncSession, receiver: User, listing_uuid: UUID) -> ClaimPublic:
    await claim_fairness.assert_receiver_can_claim(db, receiver)

    listing = await listing_crud.get_listing_by_uuid(db, listing_uuid)
    if not listing:
        raise NotFoundException("Listing not found", code="NOT_FOUND")
    if listing.status != ListingStatus.AVAILABLE.value:
        raise BadRequestException("Listing is not available", code="NOT_AVAILABLE")
    if await claim_crud.has_active_claim(db, listing_uuid):
        raise BadRequestException("Listing already has an active claim", code="CLAIM_EXISTS")
    if await claim_crud.get_receiver_active_claim(db, listing_uuid, receiver.uuid):
        raise BadRequestException(
            "You already have an active claim on this listing",
            code="DUPLICATE_CLAIM",
        )
    claim = Claim(
        listing_uuid=listing_uuid,
        receiver_uuid=receiver.uuid,
        status=ClaimStatus.PENDING.value,
    )
    claim = await claim_crud.create_claim(db, claim)
    receiver_name = receiver.name
    await notification_service.notify_new_claim(
        db, listing.donor_uuid, listing, claim.uuid, receiver_name
    )
    return await claim_to_public(db, claim)


async def list_for_user(db: AsyncSession, user: User) -> list[ClaimPublic]:
    if user.role == UserRole.RECEIVER:
        claims = await claim_crud.list_by_receiver(db, user.uuid)
    else:
        claims = await claim_crud.list_by_donor(db, user.uuid)
    return [await claim_to_public(db, c) for c in claims]


async def _reject_other_pending(
    db: AsyncSession,
    listing_uuid: UUID,
    *,
    except_claim_uuid: UUID | None,
    listing_title: str,
    listing_uuid_for_notify: UUID,
) -> None:
    others = await claim_crud.list_pending_for_listing(
        db, listing_uuid, exclude_uuid=except_claim_uuid
    )
    for other in others:
        other.status = ClaimStatus.REJECTED.value
        await claim_crud.update_claim(db, other)
        await notification_service.notify_claim_decision(
            db,
            other.receiver_uuid,
            approved=False,
            listing_title=listing_title,
            listing_uuid=listing_uuid_for_notify,
            claim_uuid=other.uuid,
        )


async def list_for_listing(db: AsyncSession, listing_uuid: UUID, donor: User) -> list[ClaimPublic]:
    listing = await listing_crud.get_listing_by_uuid(db, listing_uuid)
    if not listing or listing.donor_uuid != donor.uuid:
        raise ForbiddenException("Not your listing", code="FORBIDDEN")
    claims = await claim_crud.list_for_listing(db, listing_uuid)
    pending = [c for c in claims if c.status == ClaimStatus.PENDING.value]
    non_pending = [c for c in claims if c.status != ClaimStatus.PENDING.value]

    ranked: list[tuple[Claim, User]] = []
    for c in pending:
        receiver = await user_crud.get_user_by_uuid(db, c.receiver_uuid)
        if receiver:
            ranked.append((c, receiver))
    ranked.sort(key=lambda pair: claim_fairness.pending_claim_sort_key(pair[1], pair[0]))

    out: list[ClaimPublic] = []
    for rank, (c, r) in enumerate(ranked, start=1):
        out.append(
            await claim_to_public(
                db,
                c,
                include_listing=False,
                priority_rank=rank,
                receiver_pickups=r.successful_pickups or 0,
                receiver_no_shows=r.claim_no_shows or 0,
            )
        )

    status_order = {
        ClaimStatus.APPROVED.value: 0,
        ClaimStatus.COLLECTED.value: 1,
        ClaimStatus.REJECTED.value: 2,
    }
    non_pending.sort(
        key=lambda c: (status_order.get(c.status, 9), -(c.created_at.timestamp())),
    )
    for c in non_pending:
        out.append(await claim_to_public(db, c, include_listing=False))
    return out


async def approve_claim(db: AsyncSession, claim_uuid: UUID, donor: User) -> ClaimPublic:
    claim = await claim_crud.get_claim_by_uuid(db, claim_uuid)
    if not claim:
        raise NotFoundException("Claim not found", code="NOT_FOUND")
    listing = await listing_crud.get_listing_by_uuid(db, claim.listing_uuid)
    if not listing or listing.donor_uuid != donor.uuid:
        raise ForbiddenException("Not your listing", code="FORBIDDEN")
    if claim.status != ClaimStatus.PENDING.value:
        raise BadRequestException("Claim is not pending", code="INVALID_STATUS")
    claim.status = ClaimStatus.APPROVED.value
    claim.pickup_code = _generate_pickup_code()
    listing.status = ListingStatus.CLAIMED.value
    await listing_crud.update_listing(db, listing)
    await claim_crud.update_claim(db, claim)
    await _reject_other_pending(
        db,
        listing.uuid,
        except_claim_uuid=claim.uuid,
        listing_title=listing.title,
        listing_uuid_for_notify=listing.uuid,
    )
    await notification_service.notify_claim_decision(
        db,
        claim.receiver_uuid,
        approved=True,
        listing_title=listing.title,
        listing_uuid=listing.uuid,
        claim_uuid=claim.uuid,
    )
    return await claim_to_public(db, claim)


async def reject_claim(db: AsyncSession, claim_uuid: UUID, donor: User) -> ClaimPublic:
    claim = await claim_crud.get_claim_by_uuid(db, claim_uuid)
    if not claim:
        raise NotFoundException("Claim not found", code="NOT_FOUND")
    listing = await listing_crud.get_listing_by_uuid(db, claim.listing_uuid)
    if not listing or listing.donor_uuid != donor.uuid:
        raise ForbiddenException("Not your listing", code="FORBIDDEN")
    if claim.status != ClaimStatus.PENDING.value:
        raise BadRequestException("Claim is not pending", code="INVALID_STATUS")
    claim.status = ClaimStatus.REJECTED.value
    if listing.status == ListingStatus.CLAIMED.value:
        listing.status = ListingStatus.AVAILABLE.value
        await listing_crud.update_listing(db, listing)
    await claim_crud.update_claim(db, claim)
    await notification_service.notify_claim_decision(
        db,
        claim.receiver_uuid,
        approved=False,
        listing_title=listing.title,
        listing_uuid=listing.uuid,
        claim_uuid=claim.uuid,
    )
    return await claim_to_public(db, claim)


async def collect_claim(
    db: AsyncSession, claim_uuid: UUID, donor: User, pickup_code: str
) -> ClaimPublic:
    claim = await claim_crud.get_claim_by_uuid(db, claim_uuid)
    if not claim:
        raise NotFoundException("Claim not found", code="NOT_FOUND")
    listing = await listing_crud.get_listing_by_uuid(db, claim.listing_uuid)
    if not listing or listing.donor_uuid != donor.uuid:
        raise ForbiddenException("Not your listing", code="FORBIDDEN")
    if claim.status != ClaimStatus.APPROVED.value:
        raise BadRequestException("Claim must be approved before pickup", code="INVALID_STATUS")
    if not claim.pickup_code or claim.pickup_code != pickup_code.strip():
        raise BadRequestException("Incorrect pickup code", code="INVALID_PICKUP_CODE")

    now = datetime.now(timezone.utc)
    claim.status = ClaimStatus.COLLECTED.value
    claim.collected_at = now
    listing.status = ListingStatus.COMPLETED.value
    await listing_crud.update_listing(db, listing)
    await claim_crud.update_claim(db, claim)

    receiver = await user_crud.get_user_by_uuid(db, claim.receiver_uuid)
    if receiver:
        await claim_fairness.record_successful_pickup(db, receiver)

    return await claim_to_public(db, claim)


async def _apply_no_show(
    db: AsyncSession,
    claim: Claim,
    listing,
    *,
    listing_status_after: ListingStatus,
    notify_body: str,
) -> None:
    receiver = await user_crud.get_user_by_uuid(db, claim.receiver_uuid)
    if receiver:
        await claim_fairness.record_no_show(db, receiver)

    claim.status = ClaimStatus.REJECTED.value
    claim.pickup_code = None
    await claim_crud.update_claim(db, claim)

    listing.status = listing_status_after.value
    await listing_crud.update_listing(db, listing)

    await _reject_other_pending(
        db,
        listing.uuid,
        except_claim_uuid=None,
        listing_title=listing.title,
        listing_uuid_for_notify=listing.uuid,
    )

    await notification_service.create(
        db,
        user_uuid=claim.receiver_uuid,
        ntype=NotificationType.CLAIM_REJECTED,
        title="Pickup missed",
        body=notify_body,
        listing_uuid=listing.uuid,
        claim_uuid=claim.uuid,
    )


async def mark_no_show(db: AsyncSession, claim_uuid: UUID, donor: User) -> ClaimPublic:
    claim = await claim_crud.get_claim_by_uuid(db, claim_uuid)
    if not claim:
        raise NotFoundException("Claim not found", code="NOT_FOUND")
    listing = await listing_crud.get_listing_by_uuid(db, claim.listing_uuid)
    if not listing or listing.donor_uuid != donor.uuid:
        raise ForbiddenException("Not your listing", code="FORBIDDEN")
    if claim.status != ClaimStatus.APPROVED.value:
        raise BadRequestException(
            "Only approved claims can be marked as no-show",
            code="INVALID_STATUS",
        )

    await _apply_no_show(
        db,
        claim,
        listing,
        listing_status_after=ListingStatus.AVAILABLE,
        notify_body="Marked as no-show — food is available for others again.",
    )
    return await claim_to_public(db, claim, include_listing=False)


async def process_expired_listing_claim(db: AsyncSession, listing) -> None:
    """Record no-show when a listing expires with an uncollected approved claim."""
    claim = await claim_crud.get_approved_for_listing(db, listing.uuid)
    if not claim:
        return
    await _apply_no_show(
        db,
        claim,
        listing,
        listing_status_after=ListingStatus.EXPIRED,
        notify_body="Listing expired before pickup — counted as a missed pickup.",
    )
