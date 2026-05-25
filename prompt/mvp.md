# Zero Hunger — MVP Product Specification

| Field | Value |
|-------|--------|
| **Related docs** | [README.md](./README.md) (index) · [prd.md](./prd.md) · [uiux.md](./uiux.md) · [location.md](./location.md) · [flutter.md](./flutter.md) |

## 1. Overview

**Zero Hunger** is a mobile-first food redistribution platform for Nigeria. It connects food donors (restaurants, supermarkets, bakeries, hotels, individuals) with receivers (students, NGOs, shelters, low-income families) and, in a later phase, volunteers who facilitate pickups and deliveries.

**Goal:** A clean, working MVP — no payments, no AI, no blockchain. Food listing, claiming, pickup coordination, geolocation, and notifications.

### Core product flow (Phase 1)

```
Restaurant posts food
        ↓
Nearby receiver sees listing
        ↓
Receiver claims food
        ↓
Donor approves
        ↓
Receiver picks up (self-pickup)
        ↓
Donation completed
```

### Out of scope (MVP)

- Payments, AI, blockchain
- Volunteer delivery flow (Phase 2)
- PostGIS / advanced geo indexing (haversine is sufficient for MVP)

---

## 2. Phased delivery

| Phase | Scope | Duration |
|-------|--------|----------|
| **1 — Foundation** | Project setup, DB schema, JWT auth, Flutter navigation | Week 1 |
| **2 — Core listings** | CRUD listings, Cloudinary upload, listing card UI | Week 2 |
| **3 — Claims & map** | Claim flow, Google Maps nearby view, distance filtering | Week 3 |
| **4 — Notifications** | FCM push, listing expiry worker (APScheduler) | Week 4 |
| **5 — Admin & polish** | Admin web dashboard, moderation, error/loading states | Week 5 |
| **6 — Deploy** | Docker, EC2, Supabase, smoke testing | Week 6 |
| **Phase 2 (post-MVP)** | Volunteer delivery flow, delivery notifications | TBD |

Phase 1 validates demand with **donor + receiver + self-pickup only**. Volunteer logistics add state, notifications, and edge cases — defer until core loop is proven.

---

## 3. User roles

| Role | Description | Phase |
|------|-------------|-------|
| **Donor** | Posts surplus food listings | 1 |
| **Receiver** | Browses and claims available food | 1 |
| **Volunteer** | Accepts and completes delivery tasks | 2 |
| **Admin** | Moderates platform via web dashboard | 1 |

---

## 4. Tech stack

| Layer | Technology |
|-------|------------|
| Mobile | Flutter + Riverpod + Dio |
| Maps | Google Maps SDK |
| Push notifications | Firebase Cloud Messaging |
| Backend | FastAPI (Python) |
| Database | PostgreSQL via Supabase |
| ORM | SQLAlchemy 2.0 (async) |
| Auth | JWT (python-jose) + refresh tokens |
| Image storage | Cloudinary |
| Admin UI | Next.js or React + Vite (web only, not Flutter) |
| Deployment | AWS EC2 + Docker |
| Background jobs (MVP) | APScheduler (listing expiry); Celery + Redis later if needed |

### Architecture

```
Flutter Mobile App  ──►  FastAPI (/api/v1)  ──►  PostgreSQL (Supabase)
                              ▲
Admin Dashboard (Web)  ───────┘
```

---

## 5. Data model

```sql
-- Users
id, name, email, password_hash, role, phone,
latitude, longitude, is_active, is_verified,  -- is_verified for trust (restaurants, NGOs, volunteers)
deleted_at, created_at

-- Food listings
id, donor_id (FK), title, description, quantity, category,  -- see categories below
image_url, pickup_deadline, latitude, longitude,
status [available | claimed | completed | expired],
deleted_at, created_at

-- Claims
id, listing_id (FK), receiver_id (FK),
status [pending | approved | rejected | collected],
created_at

-- Deliveries (Phase 2)
id, listing_id (FK), volunteer_id (FK),
status [assigned | in_progress | completed], created_at
```

**Listing categories:** `cooked_meal`, `groceries`, `baked_goods`, `fruits`, `beverages`

**Soft deletes:** `deleted_at TIMESTAMP NULL` on users and listings for moderation, recovery, and analytics.

---

## 6. API specification

Base path: `/api/v1`

OpenAPI tags: `Auth`, `Listings`, `Claims`, `Deliveries` (Phase 2), `Admin`, `Health`

### Health

```
GET  /health          → { "status": "ok" }   # load balancers, monitoring
```

### Auth

```
POST  /auth/register
POST  /auth/login
POST  /auth/refresh               # access + refresh tokens
GET   /auth/me
PATCH /auth/location              # persist user lat/lng (see location.md)
```

### Listings

```
GET    /listings                  # query: lat, lng, radius, category, expiry_before
GET    /listings/map              # map pins (lighter payload)
GET    /listings/mine             # donor's listings
POST   /listings                  # donor only
GET    /listings/{id}
PUT    /listings/{id}             # donor only (own listing)
DELETE /listings/{id}             # donor only — soft delete
PATCH  /listings/{id}/status      # mark completed
POST   /listings/{id}/upload-image
```

### Claims

```
POST  /claims                     # receiver only
GET   /claims                     # receiver: own; donor: claims on their listings
PUT   /claims/{id}/approve        # donor only
PUT   /claims/{id}/reject         # donor only
PATCH /claims/{id}/collected      # receiver marks pickup done (implement if missing)
```

### Deliveries (Phase 2)

```
POST /deliveries
PUT  /deliveries/{id}/complete
```

### Admin

```
GET    /admin/users
PATCH  /admin/users/{id}/ban
DELETE /admin/listings/{id}         # soft delete
GET    /admin/stats
```

**Error shape (all endpoints):**

```json
{ "detail": "message", "code": "ERROR_CODE" }
```

---

## 7. Authentication

1. User registers and selects role (`donor` | `receiver` | `volunteer` in Phase 2).
2. Credentials validated; password stored as bcrypt hash.
3. Short-lived access token + refresh token returned.
4. Flutter stores tokens in `flutter_secure_storage`.
5. Dio interceptor attaches `Bearer` access token; refresh via `POST /auth/refresh` on expiry.
6. `get_current_user()` decodes JWT on protected routes.
7. Role guards enforce endpoint permissions.

---

## 8. Feature behaviors

### Food listing (donor)

- Upload image → Cloudinary → store `image_url`.
- Set `pickup_deadline`; APScheduler job marks listings `expired` past deadline.
- Lifecycle: `available → claimed → completed`.

### Food claiming (receiver)

- Filter by distance (haversine), category, expiry window.
- Submit claim → `pending`; donor approves or rejects → FCM to receiver.
- One active claim per listing at a time.

### Delivery (volunteer — Phase 2)

- Volunteer sees approved claims needing pickup.
- Accept task → delivery `in_progress` → complete → listing `completed`, FCM to receiver.

### Notifications (FCM)

| Trigger | Recipient |
|---------|-----------|
| New listing within 5 km | Nearby receivers |
| Claim approved / rejected | Receiver |
| Pickup deadline in 2 h | Donor + receiver |
| Delivery completed (Phase 2) | Receiver |

---

## 9. Project structure

**Backend (implemented):** see [build.md](./build.md) and [build_arch_prompt.md](./build_arch_prompt.md). Entry: `uvicorn app.main:app` from `backend/`.

**Flutter (not started):** see [flutter.md](./flutter.md).

**Admin (web):** separate app under `admin/` or own repo — Next.js or Vite; same `/api/v1` admin routes.

---

## 10. Infrastructure

Use repo root **`docker-compose.yml`** (Postgres). Backend run instructions: [build.md](./build.md).

---

## 11. Non-functional requirements

- Input validation via Pydantic on all endpoints.
- Passwords hashed with bcrypt.
- Rate limiting on write endpoints (e.g. slowapi or nginx) to prevent spam listings.
- Images compressed client-side before upload.
- Distance via haversine (no PostGIS for MVP).
- Consistent API error shape (see §6).
- Flutter: loading, empty, error, and success states on all data screens.
- Do not build features outside this spec until Phase 1 phases 1–6 are complete.

---

## 12. Post-MVP backlog

Items worth adding after launch validation:

| Item | Notes |
|------|--------|
| Refresh token rotation / revoke | Harden auth beyond MVP refresh endpoint |
| Celery + Redis | Replace APScheduler if job volume grows |
| PostGIS | If radius queries become a bottleneck |
| Verification workflow | Admin flow to set `is_verified` |
| nginx rate limiting | Alternative to in-app slowapi at scale |

---

*Technical source of truth for implementation. Product intent and acceptance criteria: [prd.md](./prd.md).*
