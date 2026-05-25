from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies import get_donor_user
from app.db.session import get_db_session
from app.models.user import User
from app.schemas.donor_dashboard import DonorDashboardResponse
from app.services import donor_dashboard as donor_dashboard_service

router = APIRouter(prefix="/donors", tags=["Donors"])


@router.get("/me/dashboard", response_model=DonorDashboardResponse)
async def donor_dashboard(
    lat: float | None = Query(default=None, ge=-90, le=90),
    lng: float | None = Query(default=None, ge=-180, le=180),
    radius: float | None = Query(default=None, ge=0.5, le=50),
    db: AsyncSession = Depends(get_db_session),
    donor: User = Depends(get_donor_user),
):
    if lat is None and donor.latitude is not None:
        lat = donor.latitude
    if lng is None and donor.longitude is not None:
        lng = donor.longitude
    return await donor_dashboard_service.get_donor_dashboard(db, donor, lat, lng, radius)
