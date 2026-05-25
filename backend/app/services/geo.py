import math
from datetime import datetime
from typing import Optional

from app.core.config import Config
from app.exceptions.custom import BadRequestException


def haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    r = 6371.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dlon / 2) ** 2
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def bounding_box(lat: float, lng: float, radius_km: float) -> tuple[float, float, float, float]:
    """Return (min_lat, max_lat, min_lng, max_lng) for SQL pre-filter."""
    lat_delta = radius_km / 111.0
    lng_delta = radius_km / (111.0 * max(math.cos(math.radians(lat)), 0.01))
    return lat - lat_delta, lat + lat_delta, lng - lng_delta, lng + lng_delta


def clamp_radius_km(radius_km: float | None) -> float:
    radius = radius_km if radius_km is not None else Config.DEFAULT_SEARCH_RADIUS_KM
    if radius < 0.5:
        raise BadRequestException("radius must be at least 0.5 km", code="INVALID_RADIUS")
    if radius > Config.MAX_SEARCH_RADIUS_KM:
        raise BadRequestException(
            f"radius cannot exceed {Config.MAX_SEARCH_RADIUS_KM} km",
            code="INVALID_RADIUS",
        )
    return radius


def is_within_radius(
    center_lat: float,
    center_lng: float,
    point_lat: float,
    point_lng: float,
    radius_km: float,
) -> bool:
    return haversine_km(center_lat, center_lng, point_lat, point_lng) <= radius_km


def listing_is_pickup_valid(pickup_deadline: datetime, now: datetime, expiry_before: Optional[datetime]) -> bool:
    deadline = pickup_deadline
    if deadline.tzinfo is None:
        from datetime import timezone

        deadline = deadline.replace(tzinfo=timezone.utc)
    if now.tzinfo is None:
        from datetime import timezone

        now = now.replace(tzinfo=timezone.utc)
    if deadline <= now:
        return False
    if expiry_before:
        eb = expiry_before
        if eb.tzinfo is None:
            from datetime import timezone

            eb = eb.replace(tzinfo=timezone.utc)
        if deadline > eb:
            return False
    return True
