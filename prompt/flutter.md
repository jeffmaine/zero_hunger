# Zero Hunger — Flutter implementation guide

| Field | Value |
|-------|--------|
| **Stack** | Flutter · Riverpod · Dio · GoRouter |
| **Design** | [uiux.md](./uiux.md) (tokens, components, screens) |
| **API** | [mvp.md](./mvp.md) (`/api/v1`) |
| **Location** | [location.md](./location.md) |

---

## 1. Project layout

```
lib/
├── main.dart
├── app.dart                   # MaterialApp + ProviderScope + GoRouter
├── core/
│   ├── constants.dart         # API base URL, default radius, map keys
│   ├── theme.dart             # See uiux.md §3.8
│   └── router.dart            # Routes + auth redirect
├── models/                    # JSON ↔ API (match backend schemas)
├── services/
│   ├── api_service.dart       # Dio + Bearer interceptor + 401 → login
│   ├── auth_service.dart      # register, login, refresh, secure storage
│   ├── location_service.dart  # geolocator → PATCH /auth/location
│   └── fcm_service.dart       # Phase 4 — Firebase messaging
├── providers/
│   ├── auth_provider.dart
│   ├── listing_provider.dart
│   └── claim_provider.dart
├── screens/                   # See §3 build order
└── widgets/
    ├── food_card.dart         # Compact card — uiux.md §5.5
    ├── status_badge.dart
    ├── category_chip.dart     # Maps to API categories (mvp.md)
    ├── skeleton_card.dart
    ├── primary_button.dart
    └── image_upload_field.dart
```

---

## 2. Auth and session

1. Register with role from onboarding (`donor` | `receiver`; `volunteer` Phase 2).
2. Store **access + refresh** tokens in `flutter_secure_storage` (never `SharedPreferences`).
3. Dio: `Authorization: Bearer <access>`; on 401 try `POST /auth/refresh`, else clear and → login.
4. After login, request location permission → `PATCH /auth/location` with device coords.
5. Role guards in router: donor vs receiver shells (separate bottom nav — uiux.md §5.9).

No social login, no biometric in MVP.

---

## 3. Screen build order

Implement in this order (matches uiux.md §7):

| # | Screen | Key API |
|---|--------|---------|
| 1 | Splash → onboarding → register/login | `/auth/*` |
| 2 | Receiver nearby feed | `GET /listings?lat&lng&radius&category` |
| 3 | Food detail + claim confirm | `GET /listings/{id}`, `POST /claims` |
| 4 | Donor create listing | `POST /listings`, image upload |
| 5 | Donor my listings + approve/reject | mine, `PUT /claims/{id}/approve` |
| 6 | Receiver my claims | `GET /claims` |
| 7 | Map tab | `GET /listings/map` |
| 8 | Profile + notification settings | `GET /auth/me` |

**Phase 2:** `volunteer_screen.dart`, deliveries API.

---

## 4. Navigation shells

```
Launch
├── First launch → Splash → Onboarding (3) → Register
└── Returning    → Splash → Login → Role home

Donor bottom nav:    Home · My listings · Post (FAB) · Profile
Receiver bottom nav: Nearby · Map · My claims · Profile
```

- **Post FAB** (donor): 56dp circle `#2D6A4F`, elevated 12dp above bar — opens create listing.
- No hamburger / drawer. No list/map toggle on feed (map is its own tab).

---

## 5. UX behaviour rules

1. **Distance + expiry** on every list card (uiux.md §5.5).
2. Expiry text → orange at &lt;4h, stronger urgency at &lt;1h (detail can use &lt;2h per uiux).
3. **Skeleton loaders** on lists — no center spinners.
4. Images: `cached_network_image` + Cloudinary transforms.
5. Primary CTAs: full-width, min 52dp height on detail/forms.
6. Inline validation on **blur**, not only on submit.
7. Empty states: neutral copy (uiux.md §9) — no pity language.
8. Offline: cached feed + banner (uiux.md §5.10).
9. Location prompt on first browse/post with short rationale.
10. Category chips are **UI labels** mapped to API: `cooked_meal`, `groceries`, `baked_goods`, `fruits`, `beverages`.

---

## 6. Location (critical)

- Search center = device GPS or user-adjusted pin — **not** city name matching.
- Display “Lagos Island” (or similar) as a **geocoded label** only.
- Default radius from config; chips 2 / 5 / 10 km (uiux.md §5.7).
- Details: [location.md](./location.md).

---

## 7. Supporting screens (after core loop)

| Screen | Notes |
|--------|--------|
| Splash | Green `#2D6A4F`, logo + “Rescue food. Feed community.” · ~2s · no animation |
| Onboarding 3 | Donate · Claim · Role select (cards) |
| Login / Register | See uiux.md §7.6; phone `+234` |
| Map | Full-screen map, custom pin, bottom preview card |
| Profile | Stats tiles, settings rows, logout |

Volunteer tab: Phase 2 only.

---

## 8. Widget ↔ API mapping

| Widget | Backend field / note |
|--------|----------------------|
| `FoodCard.id` | listing `id` (uuid) |
| Distance | haversine from search center |
| Status chip | `listing.status` + claim state on detail |
| Verified badge | `donor_verified` on public listing |

---

*Flutter guide v1 — aligns with backend in `backend/app/`*
