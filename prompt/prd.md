# Zero Hunger — Product Requirements Document (PRD)

| Field | Value |
|-------|--------|
| **Product** | Zero Hunger |
| **Version** | 1.0 |
| **Status** | Draft — MVP |
| **Last updated** | 2026-05-25 |
| **Related docs** | [README.md](./README.md) · [mvp.md](./mvp.md) · [uiux.md](./uiux.md) · [flutter.md](./flutter.md) |

---

## 1. Executive summary

Zero Hunger is a mobile-first platform that reduces food waste in Nigeria by connecting organizations and individuals with surplus food to people and groups who need it. The MVP proves that donors will list food, receivers will discover and claim it nearby, and both sides will complete self-pickup with minimal coordination overhead.

**MVP promise:** Post surplus food → find it on a map → claim → approve → pick up — without payments, delivery logistics, or heavy trust infrastructure on day one.

---

## 2. Problem statement

### Context

Nigeria faces significant food insecurity alongside high levels of preventable food waste from restaurants, supermarkets, bakeries, hotels, and households. Surplus food often goes to landfill because there is no simple, trusted way to match it with nearby recipients before it spoils.

### Problems we solve

| Problem | Who feels it | Impact |
|---------|----------------|--------|
| Surplus food is discarded | Donors (businesses, individuals) | Waste, cost, missed social impact |
| Hard to find timely, local food aid | Receivers (students, NGOs, families) | Hunger, reliance on informal networks |
| Coordination is manual and fragmented | Both sides | Missed matches, spoilage, no audit trail |
| No visibility into what is available nearby | Receivers | Time spent calling or traveling blindly |

### What we are not solving in MVP

- Monetization or payments
- Long-haul or volunteer-mediated delivery
- Full identity verification or background checks
- National-scale inventory or supply-chain analytics

---

## 3. Goals and success metrics

### Product goals (MVP)

1. **Validate the core loop** — Donors list food; receivers claim and pick up within the pickup window.
2. **Prove local discovery** — Receivers find relevant listings by distance and category.
3. **Enable trust at minimum viable level** — Donor approves claims; admin can moderate abuse.
4. **Ship a stable mobile experience** — Reliable auth, listings, claims, maps, and push notifications.

### Success metrics (first 90 days post-launch)

| Metric | Target | Notes |
|--------|--------|-------|
| Registered donors | 50+ | Mix of businesses and individuals |
| Registered receivers | 200+ | Students, NGOs, shelters, families |
| Listings created | 100+ | At least one per active donor |
| Claims submitted | 150+ | Indicates receiver engagement |
| Claim → pickup completed rate | ≥ 60% | Approved claims that reach `collected` / listing `completed` |
| Median time listing → first claim | < 4 hours | Signals discovery works |
| Listing expiry without claim | < 40% | Room to improve matching/notifications |
| Critical bugs in core flow | 0 open P0 | Auth, list, claim, approve, map |

### Non-goals for MVP

- Revenue or donor fees
- AI matching, blockchain provenance, or chatbots
- Volunteer delivery network (Phase 2)

---

## 4. Target users and personas

### Primary personas (Phase 1)

**Amaka — Restaurant manager (Donor)**  
Runs a busy kitchen in Lagos. Has leftover trays daily. Wants a fast way to post food with photo, quantity, and pickup deadline without phone tag. Success = listing claimed and picked up before close.

**Chidi — University student (Receiver)**  
Limited budget, lives near campus. Checks phone for free meals within walking distance. Success = sees nearby listing, gets approved, picks up on time.

**Fatima — NGO coordinator (Receiver)**  
Coordinates food for a shelter. Needs category filters and reliable pickup windows. Success = plans pickups for approved claims across multiple listings.

**Admin — Platform operator**  
Reviews spam, bans bad actors, removes fraudulent listings. Success = dashboard shows users, listings, and basic stats; actions take effect immediately.

### Secondary persona (Phase 2)

**Tunde — Volunteer**  
Willing to pick up approved food and deliver to receivers who cannot travel. Deferred until self-pickup loop is validated.

---

## 5. User stories and acceptance criteria

### Epic A — Authentication and onboarding

| ID | Story | Acceptance criteria |
|----|--------|---------------------|
| A1 | As a new user, I register with email, password, role, and phone so I can use the app. | Role is `donor` or `receiver`; password meets minimum rules; JWT + refresh returned; errors are clear. |
| A2 | As a returning user, I log in and stay signed in across sessions. | Token stored securely; refresh works before forced re-login; logout clears tokens. |
| A3 | As a user, I only access features for my role. | Donor cannot claim food; receiver cannot create listings; API returns 403 for wrong role. |

### Epic B — Donor listings

| ID | Story | Acceptance criteria |
|----|--------|---------------------|
| B1 | As a donor, I create a listing with title, description, quantity, category, photo, pickup deadline, and location. | Image uploads to Cloudinary; listing appears as `available`; visible on my listings screen. |
| B2 | As a donor, I edit or soft-delete my listing before it is completed. | Only own listings; deleted listings hidden from public browse. |
| B3 | As a donor, I see claims on my listings and approve or reject them. | One pending claim per listing at a time; receiver gets push on decision. |
| B4 | As a donor, I mark a listing completed after pickup. | Status moves to `completed`; no new claims accepted. |
| B5 | As a donor, I get reminded before pickup deadline. | Push notification ~2 hours before deadline (donor + approved receiver). |

### Epic C — Receiver discovery and claims

| ID | Story | Acceptance criteria |
|----|--------|---------------------|
| C1 | As a receiver, I browse nearby available food on a list and map. | Filter by distance (radius), category, expiry; results sorted by relevance/distance. |
| C2 | As a receiver, I view listing details before claiming. | Photo, description, quantity, deadline, donor location (approx), category shown. |
| C3 | As a receiver, I submit a claim on an available listing. | Claim status `pending`; donor notified; cannot claim same listing twice while pending/approved. |
| C4 | As a receiver, I track my claims and their status. | List shows pending, approved, rejected, collected states. |
| C5 | As a receiver, I get notified of new food near me. | Push when new listing within 5 km (configurable later). |

### Epic D — Platform safety and admin

| ID | Story | Acceptance criteria |
|----|--------|---------------------|
| D1 | As an admin, I view users and platform stats. | Web dashboard; user list and aggregate counts. |
| D2 | As an admin, I ban a user or remove a listing. | Banned user cannot authenticate; listing soft-deleted from public view. |
| D3 | As the system, I expire listings past pickup deadline. | Scheduled job sets status `expired`; not claimable. |
| D4 | As the system, I limit abusive posting. | Rate limits on listing/claim creation; consistent error responses. |

### Epic E — Volunteer delivery (Phase 2 — out of MVP scope)

| ID | Story | Acceptance criteria |
|----|--------|---------------------|
| E1 | As a volunteer, I accept delivery tasks for approved claims. | Deferred; see [mvp.md](./mvp.md) Phase 2. |

---

## 6. Functional requirements

### 6.1 Must have (P0) — Phase 1 MVP

- User registration and login with role selection (`donor`, `receiver`)
- JWT access + refresh token flow
- Donor: create, read, update, soft-delete own listings
- Donor: upload listing image (client compress → Cloudinary)
- Donor: set pickup deadline and location (lat/lng)
- Donor: approve/reject claims on own listings
- Donor: mark listing completed
- Receiver: browse listings with distance and category filters
- Receiver: map view of nearby listings (Google Maps)
- Receiver: submit claim (one active claim per listing)
- Receiver: view own claim history and status
- Push notifications: new nearby listing, claim decision, deadline reminder
- Automatic listing expiry after `pickup_deadline`
- Admin web dashboard: users, ban user, delete listing, basic stats
- Health check endpoint for ops

### 6.2 Should have (P1) — still MVP if time allows

- `is_verified` flag on users (display only; admin sets manually)
- Listing categories enforced in UI filters
- Empty, loading, and error states on all primary screens
- Client-side image compression before upload

### 6.3 Could have (P2) — post-MVP

- Volunteer delivery flow
- In-app messaging between donor and receiver
- Donor/receiver ratings
- Verification workflow (document upload)
- Analytics dashboard for donors

### 6.4 Will not have (Won’t)

- Payments or tipping
- AI recommendations
- Blockchain or NFT “proof of donation”
- Multi-language (English only for MVP)
- iOS and Android feature parity beyond Flutter single codebase

---

## 7. User experience requirements

### Design principles

- **Mobile-first** — Primary flows optimized for one-handed use on mid-range Android devices common in Nigeria.
- **Speed over polish** — Few taps to post or claim; default sensible deadlines and categories.
- **Clarity of state** — Every listing and claim shows explicit status (available, pending, approved, etc.).
- **Trust through transparency** — Show pickup deadline, location area, and category; no hidden claim rules.

### Key screens (mobile)

| Area | Screens |
|------|---------|
| Auth | Splash, login, register (with role) |
| Donor | Dashboard, create listing, my listings, claims on listing |
| Receiver | Nearby food (list + map), detail, my claims |
| Shared | Profile/settings (minimal), notification permission |

### Admin (web)

- Login (admin role)
- User list with ban action
- Listing moderation (soft delete)
- Stats overview (users, listings, claims counts)

### Accessibility and localization

- MVP: English UI; minimum 44pt touch targets where feasible
- Post-MVP: Hausa, Yoruba, Igbo consideration

---

## 8. Business rules

| Rule | Description |
|------|-------------|
| One claim slot | Only one `pending` or `approved` claim per listing at a time |
| Listing lifecycle | `available` → `claimed` (on approve) → `completed` or `expired` |
| Claim lifecycle | `pending` → `approved` \| `rejected` → `collected` (receiver picked up) |
| Pickup window | Receiver must pick up before `pickup_deadline`; listing auto-expires after |
| Distance default | Browse default radius 5 km; API accepts `lat`, `lng`, `radius` |
| Soft delete | Users and listings use `deleted_at`; not shown in public queries |
| Ban | `is_active = false` prevents login and API access |
| Rate limits | Applied to `POST /listings` and `POST /claims` to reduce spam |

---

## 9. Non-functional requirements (product view)

| Area | Requirement |
|------|-------------|
| **Availability** | API target 99% uptime during pilot (single-region EC2 acceptable) |
| **Performance** | Listing search < 2s p95 on 3G; image upload < 10s for compressed photo |
| **Security** | HTTPS only; bcrypt passwords; JWT on protected routes; secrets in env, not repo |
| **Privacy** | Store minimum PII (name, email, phone, coarse location); no payment data |
| **Scalability** | MVP sized for hundreds of concurrent users; haversine OK without PostGIS |
| **Observability** | `/health` for load balancer; structured logs on API errors |
| **Compliance** | Pilot terms of use and privacy policy before public launch (legal review TBD) |

Visual and interaction details: [uiux.md](./uiux.md). Technical implementation: [mvp.md](./mvp.md) §11.

---

## 10. Release plan

Aligned with engineering phases in [mvp.md](./mvp.md) §2.

| Milestone | User-visible outcome | Week |
|-----------|----------------------|------|
| M1 — Foundation | Register, login, role-based home navigation | 1 |
| M2 — Listings | Donors post food with photos | 2 |
| M3 — Claims & map | Receivers browse, map, and claim | 3 |
| M4 — Notifications | Push for claims, nearby food, deadlines | 4 |
| M5 — Admin | Web moderation and polish | 5 |
| M6 — Launch | Production deploy, smoke tests, pilot users | 6 |

**Launch criteria (M6)**

- [ ] Core loop works end-to-end on production API
- [ ] At least 5 pilot donors and 20 pilot receivers onboarded
- [ ] Admin can ban user and remove listing
- [ ] No open P0 defects on auth, listings, claims, map
- [ ] Privacy policy and terms linked in app

**Phase 2 trigger:** Phase 1 metrics met (see §3) and qualitative feedback that delivery would unlock more completions.

---

## 11. Dependencies, assumptions, and risks

### Dependencies

| Dependency | Owner | Risk if delayed |
|------------|--------|-----------------|
| Google Maps API keys | Engineering | Map browse blocked |
| Firebase (FCM) project | Engineering | No push notifications |
| Cloudinary account | Engineering | No listing photos |
| Supabase / PostgreSQL | Engineering | No persistence |
| AWS EC2 + domain + SSL | Engineering/Ops | No production launch |
| Pilot donor partners | Product/Ops | Low listing volume |

### Assumptions

- Users have smartphones with GPS and intermittent mobile data
- Donors can photograph food and set realistic pickup windows
- Self-pickup is acceptable for majority of MVP users
- English-first UI is sufficient for initial Lagos (or single-city) pilot

### Risks and mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Fake or spam listings | High | High | Rate limits, admin moderation, soft delete |
| Food safety liability concerns | Medium | High | Terms disclaim donor responsibility; pickup-as-is language |
| Low receiver density | Medium | Medium | Start single city; notify receivers within 5 km |
| Donor churn if claims slow | Medium | Medium | Push on new claims; simplify approve UI |
| Scope creep (volunteers, payments) | High | High | PRD scope lock; Phase 2 doc only after M6 |

---

## 12. Open questions

| # | Question | Owner | Due |
|---|----------|-------|-----|
| 1 | Pilot city: Lagos only or multi-city day one? | Product | Before M1 |
| 2 | Default pickup deadline (e.g. 4h vs end of day)? | Product | Before M2 |
| 3 | Show donor business name vs individual name? | Product/Design | Before M2 |
| 4 | Legal review for terms, privacy, food liability | Legal/Ops | Before M6 |
| 5 | Manual `is_verified` process for NGOs/restaurants | Ops | Before M5 |

---

## 13. Document map

| Document | Audience | Contents |
|----------|----------|----------|
| **prd.md** (this file) | Product, design, stakeholders | Why, who, what, success metrics, stories, scope |
| **uiux.md** | Design, engineering | Colors, components, screens, flows, copy |
| **mvp.md** | Engineering | Stack, API, schema, folders, infra, NFRs |

When requirements conflict, **PRD defines product intent**; **mvp.md defines implementation**. Update both when scope changes, with PRD first for user-facing decisions.

---

*PRD v1.0 — Zero Hunger MVP*
