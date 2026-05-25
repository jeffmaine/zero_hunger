# Zero Hunger — Location & Geospatial System

| Field | Value |
|-------|--------|
| **Related** | [mvp.md](./mvp.md) · [uiux.md](./uiux.md) · [build.md](./build.md) |

## Design goal

Hyper-local food redistribution — **radius matching only**, not city/state string matching.

- User in Lagos (Yaba) sees listings within `radius` km of their search point.
- User in Abuja does **not** see Lagos listings (different center + radius).
- Distance matters more than city names.

## Stored coordinates

| Entity | Fields | Required when |
|--------|--------|----------------|
| **User** | `latitude`, `longitude` | Optional at signup; required for browse/map (client sends search point) |
| **Food listing** | `latitude`, `longitude` | Required on create (pickup point) |

Manual country/state/city/area is a **Flutter UX** step → geocode to lat/lng → API only receives floats.

## Location acquisition (mobile)

| Mode | Flow |
|------|------|
| **GPS (preferred)** | Permission → device coords → `PATCH /auth/location` + browse with same coords |
| **Manual fallback** | Pick area → geocode client-side → `PATCH /auth/location` |
| **Hybrid** | GPS first; user can override via manual |

**UX rule:** Do not force permission on cold start. Show feed shell → banner: “Enable location to see food near you” → then GPS or manual.

## Matching algorithm (MVP)

1. **Haversine** great-circle distance (km) between search point and each listing pickup point.
2. **Bounding-box pre-filter** in SQL to reduce rows (same center + radius).
3. Include listing iff `distance_km <= radius`.
4. Sort by `distance_km` ascending.
5. Only `status = available`, not deleted, `pickup_deadline > now` (and optional `expiry_before`).

PostGIS is **post-MVP** when listing volume grows.

## API

### Update user search/home location

```
PATCH /api/v1/auth/location
Authorization: Bearer …
{
  "latitude": 6.5153,
  "longitude": 3.3711,
  "label": "Yaba, Lagos"        // optional display only
}
```

### Browse nearby (list)

```
GET /api/v1/listings?lat={lat}&lng={lng}&radius={km}&category={opt}&expiry_before={iso}
Authorization: Bearer …
```

| Param | Default | Notes |
|-------|---------|-------|
| `lat` | required | Search center (-90..90) |
| `lng` | required | Search center (-180..180) |
| `radius` | 5 | km, 0.5–50 |
| `category` | all | Listing category enum |
| `expiry_before` | none | Only listings with `pickup_deadline` before this time |

### Map pins (minimal)

```
GET /api/v1/listings/map?lat=&lng=&radius=
```

Returns `{ center, radius_km, pins: [{ id, title, latitude, longitude, distance_km, pickup_deadline, status }] }`.

### Create listing (donor)

```
POST /api/v1/listings
{ …, "latitude": 6.52, "longitude": 3.38 }
```

If omitted, backend may default to donor’s saved `users.latitude/longitude` when set.

## Response format (browse)

```json
{
  "center": { "latitude": 6.5153, "longitude": 3.3711 },
  "radius_km": 5,
  "count": 12,
  "listings": [
    {
      "id": "uuid",
      "title": "Jollof rice packs",
      "latitude": 6.5244,
      "longitude": 3.3792,
      "distance_km": 1.2,
      "pickup_deadline": "2026-05-26T18:00:00Z",
      "status": "available"
    }
  ]
}
```

## Flutter contract

1. Persist last search center in local state (and optionally sync via `PATCH /auth/location`).
2. **Nearby feed:** `GET /listings?lat=&lng=&radius=5`
3. **Map:** same coords → `GET /listings/map` or plot `listings[].latitude/longitude`
4. **Dio:** attach JWT; no location in headers — always query params for search.
5. **Google Maps SDK:** client-only; backend does not call Google.

## Rules summary

| Rule | Implementation |
|------|----------------|
| No city-only matching | Filter by haversine + radius only |
| No cross-region leakage | User must pass true local lat/lng; default radius 5 km |
| GPS not required at signup | `latitude`/`longitude` optional on register |
| GPS required for browse | 400 if `lat`/`lng` missing on GET /listings |
| Listing pickup location | Per-listing lat/lng at post time |

## Config (backend `.env`)

```
DEFAULT_SEARCH_RADIUS_KM=5
MAX_SEARCH_RADIUS_KM=50
```
