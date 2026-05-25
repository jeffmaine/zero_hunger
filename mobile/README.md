# Zero Hunger — Mobile app

Flutter client for the Zero Hunger API. Design: [../prompt/uiux.md](../prompt/uiux.md).

## Run

```bash
# Terminal 1 — API + DB
docker compose up -d db
cd backend && source .venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Terminal 2 — App
cd mobile
flutter pub get
flutter run
```

### API URL (ngrok — default)

The app uses your ngrok tunnel (see `lib/core/constants.dart` → `kNgrokApiBase`):

`https://collene-pentagrid-krishna.ngrok-free.dev/api/v1`

Works on **emulator and physical device** — no `10.0.2.2` needed.

**On your Mac**, keep the API running and ngrok forwarding:

```bash
# Terminal 1
cd backend && uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Terminal 2
ngrok http 8000
```

Test: `curl https://collene-pentagrid-krishna.ngrok-free.dev/api/v1/health`

**Switch back to local-only** (no ngrok): set `kNgrokApiBase = ''` in `constants.dart`, or:

```bash
flutter run --dart-define=API_BASE=http://10.0.2.2:8000/api/v1   # Android emulator
```

| Platform | Local URL (when ngrok cleared) |
|----------|-------------------------------|
| Android Emulator | `http://10.0.2.2:8000/api/v1` |
| iOS Simulator | `http://127.0.0.1:8000/api/v1` |

## Structure

- `lib/core/` — theme, router, constants
- `lib/services/` — Dio API, auth, location
- `lib/providers/` — Riverpod state
- `lib/screens/` — UI by flow (auth, home, donor, claims, profile)
- `lib/widgets/` — FoodCard, badges, skeletons

## MVP screens

- Splash → onboarding → register/login
- **Receiver:** nearby feed, map (pin preview), claims, profile, food detail + claim
- **Donor:** home, my listings, post food FAB, profile

Map tab uses a styled pin canvas (no Google Maps API key required for MVP UI). Add `google_maps_flutter` when you have a Maps key.

### Google Sign-In

1. Set `GOOGLE_CLIENT_ID` in `backend/.env` (same Web client ID used for token verify).
2. For Android, pass the **Web client** ID to Flutter:
   ```bash
   flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
   ```
3. Add iOS URL scheme from Google Cloud (see [google_sign_in](https://pub.dev/packages/google_sign_in) setup).

Login and register screens include **Continue with Google**.

### App icon

Custom icon source: `assets/icon/app_icon.png`. Regenerate platform icons after changes:

```bash
dart run flutter_launcher_icons
```

Then uninstall the app from the emulator and `flutter run` again to see the new icon.
