# Zero Hunger

Food redistribution platform (Nigeria MVP).

## Docs

- [prompt/build.md](prompt/build.md) — run guide
- [prompt/build_arch_prompt.md](prompt/build_arch_prompt.md) — backend architecture rules
- [prompt/mvp.md](prompt/mvp.md) — API spec
- [prompt/prd.md](prompt/prd.md) — product requirements
- [prompt/uiux.md](prompt/uiux.md) — design system

## Backend

Async **SQLAlchemy** + FastAPI (Ohun-style architecture). Not SQLModel.

```bash
docker compose up -d db
cd backend && source .venv/bin/activate
pip install -r requirements.txt && cp .env.example .env
alembic upgrade head
python -m scripts.seed_admin
uvicorn app.main:app --reload --port 8000
```

Default admin: `admin@zerohunger.local` / `adminchange123` (change in production).

## Layout

```
backend/app/     # FastAPI application
alembic/         # migrations
prompt/          # specs
docker-compose.yml
```

## Mobile

```bash
cd mobile && flutter pub get && flutter run
```

FCM: see [mobile/FCM_SETUP.md](mobile/FCM_SETUP.md).

## Deploy (Docker)

```bash
# On a server with Docker — copy backend/.env (not in git) first
docker compose up -d --build
docker compose exec api alembic upgrade head
```

API: port `8000`. Set production secrets in `backend/.env`.
