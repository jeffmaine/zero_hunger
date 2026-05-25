# Zero Hunger — Build Guide

| Field | Value |
|-------|--------|
| **Architecture** | Ohun-style async SQLAlchemy (see [build_arch_prompt.md](./build_arch_prompt.md)) |
| **Status** | Backend complete · Flutter UI in `mobile/` |
| **Related** | [README.md](./README.md) · [mvp.md](./mvp.md) · [prd.md](./prd.md) · [uiux.md](./uiux.md) · [flutter.md](./flutter.md) · [location.md](./location.md) |

## Stack (backend)

- FastAPI + **async SQLAlchemy 2.0** + asyncpg + Alembic
- JWT (separate access/refresh secrets) + Google OAuth
- Layering: `routers` → `services` → `cruds` → `models`
- Ohun reference: `/Users/jeffmaine/Documents/workspace/ohun/application/ohun_backend_copy`

## Quick start

```bash
docker compose up -d db
cd backend && python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
alembic upgrade head
python -m scripts.seed_admin
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

API: http://localhost:8000/docs

## Project layout

```
backend/app/
├── main.py
├── api/dependencies.py
├── api/v1/routers/
├── core/config.py, enums.py, logging.py, scheduler.py
├── db/session.py          # AsyncDatabase
├── models/                # SQLAlchemy + mixins
├── cruds/
├── services/
├── utils/tokens.py, response.py
├── exceptions/
└── middleware/
alembic/versions/
```

## API (`/api/v1`)

| Area | Endpoints |
|------|-----------|
| Health | `GET /health` |
| Auth | `POST /auth/register`, `/login`, `/refresh`, `GET /me` |
| Google | `GET /oauth/google/login`, `/callback`, `POST /authenticate`, `/mobile` |
| Location | `PATCH /auth/location` (save user coords) |
| Listings | `GET /listings?lat&lng&radius&expiry_before`, `GET /listings/map`, CRUD |
| Claims | `POST /claims`, approve/reject |
| Admin | users, stats, ban, remove listing |

## Next

1. Flutter mobile — [flutter.md](./flutter.md) + [uiux.md](./uiux.md) §7
2. Backend gaps: `PATCH /claims/{id}/collected`, pytest, rate limits
3. Admin web dashboard
4. FCM push — see `mobile/FCM_SETUP.md` (`FCM_ENABLED` + `firebase-admin`)
