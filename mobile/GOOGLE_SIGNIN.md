# Google Sign-In setup (Android + EC2 API)

Google login needs **three** pieces aligned. If any is missing, you get a blank error or "not configured".

## 1. Google Cloud project

1. Open [Google Cloud Console](https://console.cloud.google.com/) → **APIs & Services** → **Credentials**.
2. Configure **OAuth consent screen** (External is fine for testing; add your email as test user).
3. Create **OAuth 2.0 Client ID → Web application**  
   - Copy the **Client ID** (ends with `.apps.googleusercontent.com`).  
   - This is your **Web client ID** — used on **both** backend and mobile.

4. Create **OAuth 2.0 Client ID → Android**  
   - Package name: `com.zerohunger.zero_hunger`  
   - SHA-1 certificate fingerprint (debug keystore):

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1
```

Paste the SHA-1 into the Android client. Without this, Google picker may work but **idToken stays null**.

---

## 2. Backend (local + EC2)

In `backend/.env`:

```env
GOOGLE_CLIENT_ID=123456789-xxxx.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-web-client-secret
```

Use the **Web** client ID for `GOOGLE_CLIENT_ID` (same ID you pass to Flutter).

**EC2:** edit `~/zero_hunger/backend/.env` the same way, then:

```bash
docker compose up -d --build
```

---

## 3. Flutter (mobile)

**Option A — dart-define (good for CI):**

```bash
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

**Option B — constants file (good for daily dev):**

In `lib/core/constants.dart`, set:

```dart
const String kGoogleWebClientIdFallback = 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';
```

Restart the app (full restart, not hot reload).

---

## 4. Verify

1. App log on start should **not** say `Google Sign-In: not configured`.
2. Tap **Continue with Google** → pick account → should land on home.
3. If server error: check API logs: `docker compose logs api --tail 30`

| Error in app | Fix |
|--------------|-----|
| Not set up on this build | Step 3 — Web client ID on mobile |
| Server: not configured | Step 2 — `GOOGLE_CLIENT_ID` on API host |
| No ID token / SHA-1 | Step 1 — Android OAuth client + SHA-1 |
| Server rejected token | Web client ID must **match** on backend and mobile |

---

## Same API URL as login

Google exchange uses your normal API base (`http://3.251.66.229:8000/api/v1`). Email/password and Google must hit the **same** backend with Google env vars set.
