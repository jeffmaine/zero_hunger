# Firebase Cloud Messaging setup

Push is **optional** until you configure Firebase. In-app notifications work without FCM.

## 1. Firebase project

1. Create a project at [Firebase Console](https://console.firebase.google.com/).
2. Add an **Android** app (`com.zerohunger.zero_hunger`) and **iOS** app (`com.zerohunger.zeroHunger`).
3. Download `google-services.json` → `mobile/android/app/google-services.json`
4. Download `GoogleService-Info.plist` → `mobile/ios/Runner/GoogleService-Info.plist`
5. Enable **Cloud Messaging** in the project.

## 2. Flutter

```bash
cd mobile
dart pub global activate flutterfire_cli
flutterfire configure
flutter pub get
flutter run --dart-define=ENABLE_FCM=true
```

`flutterfire configure` overwrites `lib/firebase_options.dart` with real values.

## 3. Backend

1. Firebase Console → Project settings → **Service accounts** → Generate new private key.
2. Save JSON outside the repo (e.g. `backend/firebase-service-account.json`).
3. In `backend/.env`:

```env
FCM_ENABLED=true
FIREBASE_CREDENTIALS_PATH=/absolute/path/to/firebase-service-account.json
```

4. Migrate and restart API:

```bash
cd backend && pip install -r requirements.txt
alembic upgrade head
uvicorn app.main:app --reload
```

## 4. Verify

- Log in on a **physical device** (simulators are unreliable for FCM).
- Create or approve a claim → donor/receiver should get a push.
- Tap notification → app opens the relevant listing or claims screen.

## Triggers (MVP)

| Event | Push recipient |
|-------|----------------|
| New claim on listing | Donor |
| Claim approved / rejected | Receiver |
| Pickup missed (no-show) | Receiver |
