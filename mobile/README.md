# Zero Hunger — Mobile app

Flutter client for the [Zero Hunger API](../README.md). Connects donors and receivers for surplus food in Nigeria.

**Production API (default on device builds):** `http://3.251.66.229:8000/api/v1` — see `lib/core/constants.dart` → `kDeployedApiBase`.

**Ship to stores:** [DEPLOY.md](DEPLOY.md) · **Google Sign-In:** [GOOGLE_SIGNIN.md](GOOGLE_SIGNIN.md) · **Push (optional):** [FCM_SETUP.md](FCM_SETUP.md)

---

## Requirements

- Flutter 3.9+ (`flutter doctor`)
- Running API (local Docker or EC2)
- Android: API 21+ · iOS: Xcode for device/simulator builds

---

## Run (development)

### 1. Start the API

```bash
# From repo root
docker compose up -d db
cd backend && source .venv/bin/activate
alembic upgrade head
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Docs: http://127.0.0.1:8000/docs

### 2. Run the app

```bash
cd mobile
flutter pub get
flutter run
```

**API URL resolution** (first match wins):

1. `--dart-define=API_BASE=...`
2. `kNgrokApiBase` in `lib/core/constants.dart` (optional tunnel)
3. `kDeployedApiBase` (EC2)
4. Emulator/simulator localhost fallback

| Target | Typical `API_BASE` |
|--------|-------------------|
| Physical phone → EC2 | `http://3.251.66.229:8000/api/v1` |
| Android emulator → local API | `http://10.0.2.2:8000/api/v1` |
| iOS simulator → local API | `http://127.0.0.1:8000/api/v1` |

Example against EC2:

```bash
flutter run --dart-define=API_BASE=http://3.251.66.229:8000/api/v1
```

Optional ngrok: set `kNgrokApiBase` in `constants.dart`, run `ngrok http 8000`, then `flutter run` (no dart-define needed if ngrok URL is in constants).

---

## Release build (APK)

```bash
cd mobile
flutter build apk --release \
  --dart-define=API_BASE=http://3.251.66.229:8000/api/v1
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

Play Store bundle and signing: [DEPLOY.md](DEPLOY.md).

---

## Features (MVP)

### Auth & roles

- Onboarding → **donor**, **receiver**, or **volunteer** (volunteer sign-up is Phase 2; UI explains this)
- Email/password register & login
- **Google Sign-In** on login and register (role chosen before continuing with Google)
- JWT access/refresh; secure token storage

### Receiver

- **Pickup area** — not only live GPS: search a junction/area, use current location, drag map center, save to profile ([`location_picker_sheet.dart`](lib/widgets/location_picker_sheet.dart))
- Nearby feed + **OpenStreetMap** map tab (no Google Maps API key required)
- Search radius 2 / 5 / 10 km
- Food detail: claim with limits banner; button shows **pending / approved / claimed** (no double-claim)
- Claims tabs: Pending · Approved · Collected · Rejected
- Notifications bell

### Donor

- Dashboard home, my listings, post food
- **Pickup window** picker: presets (2h, 4h, 6h, tonight, tomorrow) + custom date/time ([`pickup_deadline_picker.dart`](lib/widgets/pickup_deadline_picker.dart))
- Listing detail: fair-ordered claim queue, approve/reject, pickup code, confirm pickup, no-show
- Extend deadline, pause/cancel listing

### Shared

- Profile, edit profile, avatar upload (Cloudinary via API)
- Pull-to-refresh; Riverpod + go_router shells (donor/receiver tabs)

---

## Google Sign-In (Android)

Needs **two** OAuth clients in the same Google Cloud project:

| Type | Purpose |
|------|---------|
| **Web** | `GOOGLE_CLIENT_ID` in `backend/.env` + Flutter `serverClientId` |
| **Android** | Package `com.zerohunger.zero_hunger` + debug/release SHA-1 |

Flutter Web client ID: `kGoogleWebClientIdFallback` in `constants.dart`, or:

```bash
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

Print debug SHA-1:

```bash
./scripts/print_android_sha1.sh
```

Full steps: [GOOGLE_SIGNIN.md](GOOGLE_SIGNIN.md).

---

## Optional: push notifications (FCM)

1. `flutterfire configure` in `mobile/`
2. Place Firebase service account on API host; set `FCM_ENABLED` in backend `.env`
3. Run with `--dart-define=ENABLE_FCM=true`

Details: [FCM_SETUP.md](FCM_SETUP.md).

---

## Project structure

```
lib/
  core/           theme, router, constants (API URL, categories, Google client)
  models/         User, listing, claim, enums
  providers/      Riverpod (auth, geo, listings, claims, notifications, …)
  services/       Dio API, auth, Google, location, FCM
  screens/        auth, onboarding, home, donor, claims, profile, shells
  widgets/        FoodCard, pickup area/deadline pickers, badges, …
  utils/          formatting, claim UI, pickup area/deadline copy, auth navigation
scripts/
  print_android_sha1.sh   # Google Cloud Android OAuth setup
```

**Routing:** `lib/core/router.dart` — single `GoRouter`; auth changes use `refreshListenable` (do not `ref.watch` auth on the router provider or tabs reset).

**Location state:** `geoProvider` — `device*` vs `search*` coordinates; feed/map/claims use search center.

---

## App icon

Source: `assets/icon/app_icon.png`. After changes:

```bash
dart run flutter_launcher_icons
```

Uninstall the old app from the device/emulator, then `flutter run` again.

---

## Troubleshooting

| Issue | What to check |
|-------|----------------|
| API unreachable on phone | EC2 security group TCP **8000**; `curl http://<ip>:8000/` from laptop |
| Google `ApiException: 10` | Android OAuth client + SHA-1 — [GOOGLE_SIGNIN.md](GOOGLE_SIGNIN.md) |
| Google token rejected | Same **Web** client ID on API and app |
| No listings | Pickup area set; radius; listings exist near coordinates |
| Build fails (disk full) | `flutter clean`; clear `~/.gradle/caches`; free disk space |
| Stale app icon | Uninstall app, rebuild |

---

## Related docs

- [../README.md](../README.md) — repo overview, EC2 deploy
- [DEPLOY.md](DEPLOY.md) — Play Store, APK, signing
- [GOOGLE_SIGNIN.md](GOOGLE_SIGNIN.md) — OAuth setup
- [FCM_SETUP.md](FCM_SETUP.md) — push notifications
