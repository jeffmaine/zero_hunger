# Zero Hunger

Mobile-first food redistribution for Nigeria — connect donors with receivers and NGOs. Donors list surplus food; receivers claim it; fairness rules limit hoarding and no-shows.

**Stack:** FastAPI (async SQLAlchemy) · PostgreSQL · Flutter · Docker · optional FCM push

**Repository:** https://github.com/jeffmaine/zero_hunger

---

## What is deployed where

| Component | How it runs | Typical URL |
|-----------|-------------|-------------|
| **Backend API** | Docker on AWS EC2 (or local) | `http://<server-ip>:8000/api/v1` |
| **API docs (Swagger)** | Same host | `http://<server-ip>:8000/docs` |
| **Flutter app** | Built on your machine → **Google Play** / APK | Not a website — see [mobile/DEPLOY.md](mobile/DEPLOY.md) |

The mobile app talks to the API over HTTP(S). Update the API host in `mobile/lib/core/constants.dart` (`kDeployedApiBase`) or at build time with `--dart-define=API_BASE=...`.

**Check API from your laptop:**

```bash
curl -m 10 http://<server-ip>:8000/
```

If that hangs, open **EC2 security group → inbound TCP 8000** (SSH on port 22 alone is not enough).

---

## Quick start (local development)

### Prerequisites

- Docker (for Postgres)
- Python 3.11+ and `backend/.venv`
- Flutter 3.9+ ([mobile/README.md](mobile/README.md))

### Backend

```bash
docker compose up -d db
cd backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # edit secrets
alembic upgrade head
python -m scripts.seed_admin
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

- API: http://127.0.0.1:8000/docs  
- Default admin (change in production): `admin@zerohunger.local` / `adminchange123`

### Mobile

```bash
cd mobile
flutter pub get
flutter run
```

Point at local API (Android emulator):

```bash
flutter run --dart-define=API_BASE=http://10.0.2.2:8000/api/v1
```

Point at EC2:

```bash
flutter run --dart-define=API_BASE=http://<server-ip>:8000/api/v1
```

---

## Production deploy (EC2 + Docker)

Full guide: **[deploy/aws-ec2.md](deploy/aws-ec2.md)**

```bash
# On Ubuntu EC2
git clone https://github.com/jeffmaine/zero_hunger.git
cd zero_hunger
cp backend/.env.example backend/.env   # production secrets; never commit
mkdir -p backend/secrets              # Firebase service account JSON (optional)
docker compose up -d --build
docker compose exec api alembic upgrade head
docker compose exec api python -m scripts.seed_admin
```

**Security group:** allow inbound **22** (SSH) and **8000** (API).

**`.env` highlights:**

- `DB_PASSWORD` and `POSTGRES_PASSWORD` must match (see `docker-compose.yml`)
- `GOOGLE_CLIENT_ID` = Google **Web** OAuth client ID (for mobile Google Sign-In) — [mobile/GOOGLE_SIGNIN.md](mobile/GOOGLE_SIGNIN.md)
- `FCM_ENABLED=true` + `FIREBASE_CREDENTIALS_PATH=/app/secrets/...` for push — [mobile/FCM_SETUP.md](mobile/FCM_SETUP.md)

More: [DEPLOY.md](DEPLOY.md)

---

## Release mobile app (Google Play)

The app is **not** deployed to EC2. Build a release bundle and upload to Play Console.

```bash
cd mobile
flutter build appbundle --release \
  --dart-define=API_BASE=http://<server-ip>:8000/api/v1 \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
```

Output: `mobile/build/app/outputs/bundle/release/app-release.aab`

Sideload APK for testing:

```bash
flutter build apk --release --dart-define=API_BASE=http://<server-ip>:8000/api/v1
# → build/app/outputs/flutter-apk/app-release.apk
```

Details: **[mobile/DEPLOY.md](mobile/DEPLOY.md)**

---

## Project layout

```
zero_hunger/
├── backend/app/          # FastAPI — routers, services, models
├── backend/alembic/      # DB migrations
├── mobile/lib/           # Flutter UI (donor + receiver)
├── docker-compose.yml    # API + Postgres for server/local
├── deploy/aws-ec2.md     # EC2 walkthrough
└── DEPLOY.md             # Deploy index
```

---

## Features (MVP)

- Donor: post food, edit/pause listings, approve/reject claims, pickup codes, no-show
- Receiver: nearby feed + map, claim limits, cooldown, my claims (pending / approved / collected / rejected)
- In-app notifications + optional FCM push
- Google Sign-In (requires Web client ID on mobile + `GOOGLE_CLIENT_ID` on API)
- Hyperlocal matching (lat/lng + radius)

---

## More guides

| Doc | Purpose |
|-----|---------|
| [DEPLOY.md](DEPLOY.md) | Deploy overview |
| [deploy/aws-ec2.md](deploy/aws-ec2.md) | AWS EC2 setup |
| [mobile/DEPLOY.md](mobile/DEPLOY.md) | Play Store / release builds |
| [mobile/GOOGLE_SIGNIN.md](mobile/GOOGLE_SIGNIN.md) | Google OAuth setup |
| [mobile/FCM_SETUP.md](mobile/FCM_SETUP.md) | Push notifications |
| [mobile/README.md](mobile/README.md) | Flutter app notes |

API reference when the server is running: `http://<server-ip>:8000/docs`

---

## Secrets (never commit)

- `backend/.env`
- `backend/secrets/` (Firebase admin JSON)
- `google-services.json`, `GoogleService-Info.plist`
- `mobile/android/key.properties` (Play signing)

---

## Troubleshooting

| Problem | What to check |
|---------|----------------|
| `curl` to public IP hangs | EC2 security group port **8000**; `curl` on server: `curl http://127.0.0.1:8000/` |
| App stuck on splash | API reachable? Stale token — clear app data; see splash/bootstrap timeout in mobile |
| Google login fails | [mobile/GOOGLE_SIGNIN.md](mobile/GOOGLE_SIGNIN.md) — Web client ID on app + API, Android SHA-1 |
| `flutter build` disk full | Free space; `rm -rf mobile/build ~/.gradle/caches` |
| Gradle file lock | `cd mobile/android && ./gradlew --stop && rm -rf ../android/.gradle` |

---

## License

Private / project use — see repository owner.
