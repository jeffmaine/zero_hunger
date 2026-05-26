# Mobile app deployment (Flutter)

## What is already “live”

| What | URL / artifact |
|------|----------------|
| **Backend API** (EC2) | `http://3.251.66.229:8000/api/v1` |
| **API docs** | http://3.251.66.229:8000/docs |
| **Flutter app** | **Not on EC2** — you **build** it and upload to **Google Play** (or share an APK) |

There is no single “app URL” like a website unless you also ship **Flutter web** (optional, below).

The release app is configured to call your EC2 API via `kDeployedApiBase` in `lib/core/constants.dart`.

---

## For Google Play submission (Android)

### 1. Production API URL in the build

Default in repo:

```dart
const String kDeployedApiBase = 'http://3.251.66.229:8000/api/v1';
```

Override at build time if IP changes:

```bash
flutter build appbundle --release \
  --dart-define=API_BASE=http://3.251.66.229:8000/api/v1
```

**Play Store / Data safety:** Google prefers **HTTPS** for production. Plan a domain + TLS (e.g. `https://api.yourdomain.com/api/v1`) and rebuild before public launch.

### 2. Create a signing key (once)

```bash
keytool -genkey -v -keystore ~/zero-hunger-upload.keystore -alias upload \
  -keyalg RSA -keysize 2048 -validity 10000
```

Create `mobile/android/key.properties` (do **not** commit):

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=/Users/YOU/zero-hunger-upload.keystore
```

Wire signing in `android/app/build.gradle.kts` (see [Flutter Android deployment](https://docs.flutter.dev/deployment/android)).

### 3. Build the Play Store bundle (AAB)

```bash
cd mobile
flutter build appbundle --release
```

Output:

```text
build/app/outputs/bundle/release/app-release.aab
```

Upload **this file** in [Google Play Console](https://play.google.com/console) → your app → **Production** or **Internal testing**.

### 4. “Live link” for testers (before public store)

| Method | What you get |
|--------|----------------|
| **Internal testing** | Play Console invite link (emails) — best for “submit” review track |
| **Closed testing** | Same, limited testers |
| **Firebase App Distribution** | Download link for APK testers |
| **Direct APK** | `flutter build apk --release` → share `app-release.apk` (sideload) |

Internal testing is the usual “live” Android URL: Play Console generates an **opt-in link** after you upload the AAB.

### 5. Play Console checklist

- [ ] App name, icon, screenshots
- [ ] **Privacy policy URL** (required) — can use a GitHub Pages or Notion public page
- [ ] Package name: `com.zerohunger.zero_hunger`
- [ ] Data safety form (location, account data)
- [ ] Release AAB uploaded
- [ ] Backend reachable from user devices (EC2 port 8000 + security group)

---

## iOS (App Store)

Requires Mac + Apple Developer Program ($99/year).

```bash
cd mobile
flutter build ipa --release \
  --dart-define=API_BASE=http://3.251.66.229:8000/api/v1
```

Open `ios/Runner.xcworkspace` in Xcode → **Product → Archive** → **Distribute** → TestFlight or App Store.

TestFlight gives you a **test link** (like Play internal testing).

---

## Optional: Flutter **web** (if you need a browser URL)

Only needed if reviewers or users must open the app in Chrome/Safari.

```bash
flutter build web --release \
  --dart-define=API_BASE=http://3.251.66.229:8000/api/v1
```

Host `build/web/` on:

- Firebase Hosting
- AWS S3 + CloudFront
- Netlify / Vercel

Example live URL: `https://zerohunger.web.app` — **separate** from the Play Store app.

---

## Quick reference

```bash
# Test release APK on your phone (USB / sideload)
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk

# Google Play upload
flutter build appbundle --release
# → build/app/outputs/bundle/release/app-release.aab
```

**Backend:** already on EC2.  
**Mobile:** build AAB → Play Console → internal testing link = your “live app” for submission.
