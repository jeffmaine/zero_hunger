# Zero Hunger — Documentation index

**Product:** Mobile-first food redistribution for Nigeria — utility, not charity.  
**Status:** Backend implemented (async SQLAlchemy) · Flutter app in `mobile/`.

Use this index instead of one mega-spec. Each doc owns one concern; nothing is duplicated here.

---

## Which doc to read

| Doc | Use when you need… |
|-----|-------------------|
| [prd.md](./prd.md) | Why we're building it, personas, user stories, success metrics, scope boundaries |
| [mvp.md](./mvp.md) | Tech stack, data model, **API contract**, auth, infra, phased roadmap |
| [uiux.md](./uiux.md) | Design north star, tokens, components, **screens**, copy, accessibility |
| [location.md](./location.md) | Hyperlocal matching (radius + haversine) — **not city-based search** |
| [build.md](./build.md) | How to run the backend today, layout of `backend/app/` |
| [build_arch_prompt.md](./build_arch_prompt.md) | Ohun-style backend rules (async SQLAlchemy, JWT, Alembic) |
| [flutter.md](./flutter.md) | Flutter app structure, navigation, providers, build order |

**Precedence:** `prd.md` (scope) → `uiux.md` (UX/copy) → `mvp.md` (API/engineering). `location.md` overrides any city-matching wording in older drafts.

---

## Canonical facts (do not contradict in new prompts)

| Topic | Truth in this repo |
|-------|-------------------|
| ORM | **SQLAlchemy 2.0 async** + Alembic — not SQLModel |
| API base | `/api/v1` — see [mvp.md](./mvp.md) and OpenAPI at `/docs` |
| Geo | Listings matched by **lat/lng + radius** ([location.md](./location.md)) |
| Listing categories (API) | `cooked_meal`, `groceries`, `baked_goods`, `fruits`, `beverages` |
| Feed card layout | **Compact horizontal** (72dp thumb) — not full-width hero cards in the list |
| Phase 1 roles | Donor + receiver + admin (web). **Volunteer delivery = Phase 2** |
| Tokens | Access + refresh JWT; `flutter_secure_storage` on mobile |

---

## MVP build order (engineering)

| Week | Focus | Docs |
|------|--------|------|
| 1 | Backend verified E2E + Flutter scaffold, theme, auth shell | build.md, flutter.md §1–2 |
| 2 | Listings CRUD, feed, food card, skeletons | uiux.md §5–7, mvp.md §6 |
| 3 | Claims, map tab, location | location.md, flutter.md §3 |
| 4 | FCM + expiry worker | mvp.md §8 |
| 5 | Profile, empty/error/offline states | uiux.md §5.10 |
| 6 | Docker deploy, smoke tests | mvp.md §10, root `docker-compose.yml` |

---

## What we dropped from “v2 mega-prompt”

Removed on purpose (already covered or wrong for this repo):

- Duplicate tech stack / Docker / backend folder trees (wrong SQLModel layout)
- Duplicate SQL schema and API tables (see **mvp.md**)
- City-based “Lagos Island” matching (replaced by **location.md**)
- UI category chips “Rice · Bread · Soup” as API enums (map to **mvp** categories in Flutter)
- Repeated design-token tables (see **uiux.md** §3)
- Repeated push-notification tables (see **uiux.md** §9 and **mvp.md** §8)

---

*Last updated: 2026-05-25*
