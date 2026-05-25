from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies import get_authenticated_user, get_donor_user, get_receiver_user
from app.db.session import get_db_session
from app.models.user import User
from app.schemas.claim import ClaimCollect, ClaimCreate, ClaimLimitsResponse, ClaimPublic
from app.services import claim as claim_service

router = APIRouter(prefix="/claims", tags=["Claims"])


@router.get("/limits", response_model=ClaimLimitsResponse)
async def claim_limits(
    db: AsyncSession = Depends(get_db_session),
    receiver: User = Depends(get_receiver_user),
):
    return await claim_service.get_claim_limits(db, receiver)


@router.post("", response_model=ClaimPublic, status_code=201)
async def create_claim(
    data: ClaimCreate,
    db: AsyncSession = Depends(get_db_session),
    receiver: User = Depends(get_receiver_user),
):
    return await claim_service.create_claim(db, receiver, data.listing_id)


@router.get("", response_model=list[ClaimPublic])
async def list_claims(
    db: AsyncSession = Depends(get_db_session),
    user: User = Depends(get_authenticated_user),
):
    return await claim_service.list_for_user(db, user)


@router.get("/listing/{listing_id}", response_model=list[ClaimPublic])
async def claims_for_listing(
    listing_id: UUID,
    db: AsyncSession = Depends(get_db_session),
    donor: User = Depends(get_donor_user),
):
    return await claim_service.list_for_listing(db, listing_id, donor)


@router.put("/{claim_id}/approve", response_model=ClaimPublic)
async def approve_claim(
    claim_id: UUID,
    db: AsyncSession = Depends(get_db_session),
    donor: User = Depends(get_donor_user),
):
    return await claim_service.approve_claim(db, claim_id, donor)


@router.put("/{claim_id}/reject", response_model=ClaimPublic)
async def reject_claim(
    claim_id: UUID,
    db: AsyncSession = Depends(get_db_session),
    donor: User = Depends(get_donor_user),
):
    return await claim_service.reject_claim(db, claim_id, donor)


@router.post("/{claim_id}/collect", response_model=ClaimPublic)
async def collect_claim(
    claim_id: UUID,
    data: ClaimCollect,
    db: AsyncSession = Depends(get_db_session),
    donor: User = Depends(get_donor_user),
):
    return await claim_service.collect_claim(db, claim_id, donor, data.pickup_code)


@router.post("/{claim_id}/no-show", response_model=ClaimPublic)
async def mark_no_show(
    claim_id: UUID,
    db: AsyncSession = Depends(get_db_session),
    donor: User = Depends(get_donor_user),
):
    return await claim_service.mark_no_show(db, claim_id, donor)
