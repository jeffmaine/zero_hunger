# Zero Hunger — UI/UX Design Specification

| Field | Value |
|-------|--------|
| **Product** | Zero Hunger |
| **Version** | 2.0 |
| **Status** | Draft — MVP (Phase 1) |
| **Last updated** | 2026-05-25 |
| **Platforms** | Flutter mobile (donor + receiver); web admin dashboard |
| **Related docs** | [README.md](./README.md) · [prd.md](./prd.md) · [mvp.md](./mvp.md) · [flutter.md](./flutter.md) · [location.md](./location.md) |

---

## 1. Design north star

### Product positioning

Lean toward **calm operational utility** — reliable, useful, calm — not an emotional donation campaign.

| Feel like | Do not feel like |
|-----------|------------------|
| Community food redistribution tool | Charity portal or welfare system |
| Logistics you can trust | Pity-driven “help the needy” app |
| Practical infrastructure | Social media or fintech glamour |

Zero Hunger is **utility infrastructure** for matching surplus food with people nearby. Interfaces are fast, calm, and dignified — optimized for mid-range Android on variable 3G in Nigeria.

**One-line test:** Would a restaurant manager post during a busy service, and would a student claim without feeling stigmatized? If either answer is no, simplify.

### The anchor principle: dignified UX

This principle matters more than color or typography. It defines the product.

Most charity-focused apps accidentally make users feel **exposed**, **judged**, or **dependent**. Zero Hunger designs for **redistribution**, not pity.

| Design choice | Why |
|---------------|-----|
| “Claim food” not “Request charity” | Words shape emotional experience |
| No leaderboards or “most in need” | Avoid ranking human need |
| Neutral claim flow | Transaction, not appeal |
| No hunger stock photography | No emotional manipulation in empty states |
| Receiver privacy on claims | First name only; no profile stalking |

**One-line test for copy and UI:** Would a receiver feel like they’re using a useful app — not asking for handouts?

---

## 2. Design principles

| Principle | What it means in practice |
|-----------|---------------------------|
| **Dignified UX** | See §1 — non-negotiable on every screen |
| **Calm operational utility** | Less emotional imagery; more clarity, status, and action |
| **Distance + expiry first** | Users decide on *how close* and *how soon* before donor story or long descriptions |
| **Urgency is intentional** | Orange only for time-critical UI — never generic CTAs |
| **Speed over decoration** | Post or claim in ≤ 4 taps from home; sensible defaults |
| **Clarity of state** | Label + color chip on every listing and claim |
| **Thumb-first** | Bottom nav; primary actions in thumb zone (walking, markets, bikes) |
| **Offline-tolerant** | Cached feed, skeletons, optimistic UI where safe, explicit retry |
| **Minimal motion** | Confirm actions and improve clarity only — no decorative animation |
| **Accessible by default** | 44dp targets, 16px inputs, icon + text on chips and nav |

---

## 3. Visual design system

### 3.1 Color philosophy

- **One primary green** — all green UI derives from `#2D6A4F` (trustworthy, grounded, mature — not bright “eco startup” green).
- **One urgency orange** — `#E07B00` for time sensitivity only.
- **Warm off-white background** — `#F5F7F2` for long scroll, low-end screens, night use (softer than pure white).
- **Neutral gray scale** — text hierarchy, dividers, inactive states (do not improvise grays per screen).

### 3.2 Primary green scale

Generated from **Primary Green: `#2D6A4F`** (`green-500`). Do not hand-pick unrelated greens.

| Token | Hex | Usage |
|-------|-----|--------|
| `green-50` | `#F1F8F4` | Success backgrounds, verified badge bg |
| `green-100` | `#D8EDE3` | Status chip backgrounds (available, approved) |
| `green-200` | `#B7DFC9` | Hover / pressed tint (web admin) |
| `green-500` | `#2D6A4F` | **Primary** — buttons, active nav, links, brand |
| `green-700` | `#1B4332` | Pressed states, completed text, app bar (optional) |

### 3.3 Neutral gray scale

| Token | Hex | Usage |
|-------|-----|--------|
| `gray-100` | `#F1F3EF` | Subtle fills, expired chip bg, skeleton base |
| `gray-300` | `#D7DBD2` | Borders, dividers, disabled borders |
| `gray-500` | `#6B7280` | Secondary text, captions, meta lines |
| `gray-700` | `#374151` | Primary text (alternative to near-black) |
| `textPrimary` | `#1A1A1A` | Headings, card titles (max contrast on `background`) |
| `textDisabled` | `#9E9E9E` | Disabled controls |

### 3.4 Semantic colors

| Token | Hex | Usage |
|-------|-----|--------|
| `background` | `#F5F7F2` | Screen background |
| `surface` | `#FFFFFF` | Cards, sheets, inputs |
| `accent` | `#E07B00` | **Urgency only** — expiry, deadline &lt; 2h, countdown |
| `error` | `#C1121F` | Errors, reject actions |

**Color rules**

- Never use `accent` for branding, success, or generic buttons.
- Status chips: `green-100` + `green-500` text, or gray scale — always with text label (§5.3).
- Map pins: `green-500` available · `gray-500` expired · `accent` if &lt; 2h to deadline.

### 3.5 Typography

**System fonts only** — Roboto (Android), SF Pro (iOS). No custom font downloads (network, size, performance matter in Nigeria).

| Token | Size | Weight | Use |
|-------|------|--------|-----|
| `display` | 24px | 500 | Screen titles |
| `title` | 20px | 500 | Section headers |
| `body` | 16px | 400 | Body, **all inputs** (prevents iOS auto-zoom) |
| `bodySmall` | 14px | 400 | Secondary copy |
| `caption` | 12px | 400 | Distance, deadline, trust labels |
| `label` | 14px | 500 | Buttons, chips, nav |

Line height: 1.4× body; 1.2× titles.

### 3.6 Spacing and layout

| Token | Value |
|-------|--------|
| `spaceXs` | 4px |
| `spaceSm` | 8px |
| `spaceMd` | 16px |
| `spaceLg` | 24px |
| Screen horizontal padding | 16px |
| Card corner radius | 12px |
| Compact card min height | ~88dp (list scan target) |
| Bottom nav height | 56px + safe area |

### 3.7 Elevation

- Cards: flat `surface` + 1px `gray-300` border — no heavy shadows (`0 1px 3px rgba(0,0,0,0.06)` max).
- Bottom sheets: soft upward shadow only.
- **Donor Post FAB:** 56dp circle `#2D6A4F`, white + icon, 12dp above bottom bar — create listing only.
- Elsewhere: full-width primary buttons (52dp on forms/detail).

### 3.8 Flutter theme mapping

Implement in `lib/core/theme.dart`:

```dart
// Primary green scale
const green50  = Color(0xFFF1F8F4);
const green100 = Color(0xFFD8EDE3);
const green200 = Color(0xFFB7DFC9);
const green500 = Color(0xFF2D6A4F); // seed / primary
const green700 = Color(0xFF1B4332);

// Neutral gray scale
const gray100 = Color(0xFFF1F3EF);
const gray300 = Color(0xFFD7DBD2);
const gray500 = Color(0xFF6B7280);
const gray700 = Color(0xFF374151);

const kBackground = Color(0xFFF5F7F2);
const kSurface    = Color(0xFFFFFFFF);
const kAccent     = Color(0xFFE07B00);  // urgency only
const kError      = Color(0xFFC1121F);
```

Use `ColorScheme.fromSeed(seedColor: green500)`; map `primary` → `green500`, `primaryContainer` → `green100`, `onSurfaceVariant` → `gray500`.

---

## 4. Iconography and imagery

| Area | Guidance |
|------|----------|
| Icons | Material Symbols Outlined; 24dp standard, 20dp inline |
| Listing photos | Square thumbnail 72×72dp on card; 4:3 on detail; compress &lt; 500 KB |
| Empty states | Icon + headline + action — **no** hunger stock photos or pity imagery |
| Splash / logo | Simple mark in `green-500` on `background` — operational, not campaign |

**Photo upload (donor):** camera/gallery → compress → progress → thumbnail + “Change photo”.

---

## 5. Component library

### 5.1 Primary button

- Full-width on forms; min height 48dp  
- Fill: `green-500`, text: white  
- Disabled: 40% opacity  
- Loading: 20dp spinner, disable tap  

### 5.2 Secondary / destructive

| Variant | Style |
|---------|--------|
| Secondary | Outlined `green-500` |
| Destructive | Text or outline `error` |

### 5.3 Status chip

Icon or dot + **text label** always.

| Status | Background | Text |
|--------|------------|------|
| Available | `green-100` | `green-500` |
| Pending | `#FFF3E0` | `#E65100` |
| Approved | `green-100` | `green-500` |
| Rejected | `#FFEBEE` | `error` |
| Expired | `gray-100` | `gray-500` |
| Completed | `green-100` | `green-700` |

### 5.4 Trust indicators

Small, subtle — reduce food-safety and scam anxiety without cluttering the card.

| Indicator | When shown | Visual |
|-----------|------------|--------|
| **Verified** | `is_verified` donor | `green-50` pill + check + “Verified” (restaurant/NGO) |
| **Listed today** | `created_at` is today | Caption + “Listed today” (freshness signal) |
| **Pickup by {time}** | Always on card | Clock icon; `accent` if &lt; 2h |

On **food detail** only (not compact card): optional “Pickup area: {neighborhood}” after approve.

Do not use trust badges for pity (“Trusted charity partner”) — keep operational.

### 5.5 Food card — compact (default)

**Hierarchy rule:** distance and expiry dominate; title second; trust tags minimal; CTA last.

Feeds must scan fast — compact cards outperform tall hero cards in logistics apps.

```
┌──────────────────────────────────────────────────┐
│ ┌────┐  Jollof rice packs          [Available]   │
│ │img │  📍 1.2 km  ·  ⏰ Pickup before 7:00 PM  │  ← accent if <2h
│ │72dp│  ✓ Verified  ·  Listed today              │  ← trust row, caption
│ └────┘  [ Claim food ]                           │  ← receiver; omit donor
└──────────────────────────────────────────────────┘
```

| Element | Spec |
|---------|------|
| Thumbnail | 72×72dp, radius 8dp, left |
| Title | `title` token, max 2 lines, ellipsis |
| Meta row 1 | Distance + deadline (icons + `caption`) |
| Meta row 2 | Trust indicators only when applicable |
| CTA | Compact button or text button inline; full-width only if no room |
| Card padding | 12dp; margin bottom 8dp |
| Tap | Whole row → detail (except CTA tap claims / navigates) |

**Donor variant:** same layout; no Claim CTA; status chip + pending claim badge count.

**Detail screen:** may use larger hero image — list stays compact.

### 5.6 Form inputs

- Outlined, 16px text, `gray-300` border  
- Inline `error` below field  
- Deadline presets: **Today 6 PM** · **Today 9 PM** · **Tomorrow 12 PM** · **Custom**

### 5.7 Filter bar (receiver)

- Category chips: All · Cooked · Groceries · Baked · Fruits · Drinks  
- Radius: **2 km · 5 km · 10 km** (default 5 km)  
- List / Map toggle in app bar

### 5.8 Map pin callout

- Mini compact card: thumbnail, title, distance, deadline  
- Tap → food detail

### 5.9 Bottom navigation

Mandatory for thumb reach in motion contexts. Role-specific — no irrelevant tabs.

**Donor:** Home · My listings · Post (center) · Profile  

**Receiver:** Nearby · My claims · Profile  

### 5.10 Resilient UI states (offline-first patterns)

Critical for weak signal and poor connectivity — **more important than fancy animation**.

| Pattern | Implementation |
|---------|----------------|
| Skeleton loaders | Compact card skeletons (gray-100 blocks) on first load |
| Cached last feed | Show last successful nearby fetch with timestamp: “Updated 12 min ago” |
| Offline banner | Top banner: “Offline — showing saved results” + Retry when online |
| Pull to refresh | Always available on Nearby and My claims |
| Optimistic UI | Claim tap → immediate “Pending” on My claims; rollback on API error |
| Retry | Every error state: icon + message + **Retry** button |
| Image fallback | Placeholder icon if thumbnail fails to load |
| Upload queue | Donor photo: show progress; allow retry on fail (MVP: inline error OK) |

Never block the app when location or network is denied — degrade with message and cached/manual path.

---

## 6. Information architecture

```
App launch
├── Splash
├── Auth → Login | Register (role cards)
├── Donor shell
│   ├── Dashboard
│   ├── Create / Edit listing
│   ├── My listings → Detail → Claims
│   └── Profile
└── Receiver shell
    ├── Nearby (list | map)     ← MVP UX priority #1
    ├── Food detail → Claim confirm
    ├── My claims
    └── Profile
```

**Admin (web):** Login → Dashboard (stats) → Users · Listings  

Phase 2: Volunteer tab — not MVP.

---

## 7. Screen specifications (MVP priority order)

Design and build screens in this order — they define the MVP experience:

| Priority | Screen / component | Section |
|----------|-------------------|---------|
| 1 | Nearby food feed (list) | §7.1 |
| 2 | Food card component | §5.4–5.5 |
| 3 | Food detail | §7.2 |
| 4 | Create listing flow | §7.3 |
| 5 | Claim confirmation | §7.4 |
| 6 | Bottom navigation shells | §5.9 |
| 7 | Notifications entry (profile + system) | §7.5 |

---

### 7.1 Nearby food feed (receiver) — P1

- Header: greeting + **geocoded area label** (display only — search uses GPS/radius per [location.md](./location.md), not city matching)  
- Optional search field (local filter / future)  
- Sticky category + radius chips (2 / 5 / 10 km)  
- **Compact food cards** (§5.5), sort nearest first — **not** full-width hero cards in the list  
- Pull to refresh; offline banner + cached feed (§5.10)  
- Empty: “No food nearby right now” + neutral subcopy (§9)  
- Skeleton: 5 compact card skeletons  

**Map:** separate bottom-nav tab (§7.7), not a list/map toggle on this screen.

---

### 7.2 Food detail (receiver) — P3

- Hero image (4:3), title, category, quantity  
- **Prominent:** distance · pickup deadline (`accent` if urgent)  
- Trust row: Verified · Listed today  
- Short description (collapsed if long)  
- Area/neighborhood before approve; exact pickup after approve (policy)  
- Donor: “Posted by {name}” — no poverty framing  
- Fixed bottom: **Claim food** (disabled if expired / already claimed)  

---

### 7.3 Create listing (donor) — P4

- Single scroll: photo, title, quantity, category chips, deadline presets, location  
- Operational copy: “Post surplus food” not “Donate”  
- Location rationale: “So people nearby can pick up”  
- Success snackbar → My listings  
- Edit + soft delete with confirm  

---

### 7.4 Claim confirmation — P5

- Bottom sheet or light screen  
- Listing summary (compact)  
- Copy: “The donor will review your claim. You’ll be notified when it’s approved.”  
- **Confirm claim** → optimistic pending on My claims (§5.10)  

---

### 7.5 Notifications — P7

- OS permission prompt after first claim (not on cold launch)  
- Profile: “Notifications” → system settings  
- In-app: no separate feed required for MVP — rely on push + My claims status  
- Banner on My claims if notifications denied  

**Push copy:** see §9.

---

### 7.6 Auth & onboarding (before P1)

| Screen | Layout |
|--------|--------|
| **Splash** | Full `#2D6A4F`; leaf icon + “Zero Hunger”; tagline “Rescue food. Feed community.” · ~2s static → onboarding or login |
| **Onboarding ×3** | Illustration top 45%; copy bottom; dots + Next; Skip top-right. Final step: role cards (Donor / Receiver / Volunteer*) — selected = green border + `#e8f5e1` fill. *Volunteer UI visible but routes Phase 2 |
| **Login** | Logo, email, password (show/hide), “Log in”, forgot link, register link; field errors inline `#b33a3a` |
| **Register** | Name, phone (+234), email, password, confirm, role (from onboarding); strength indicator; “Create account” |

### 7.7 Map tab (receiver)

- Full-screen Google Map; muted palette  
- Pin: white circle + green leaf, 40dp; cluster count if stacked  
- Tap pin → bottom preview card (thumb, title, distance, expiry, Claim)  
- Top: search-style bar + category chips (same as feed)

### 7.8 Supporting screens (after P1–P7)

| Screen | Notes |
|--------|--------|
| Donor dashboard | Stats + recent compact cards; FAB → create listing |
| My listings | Tabs: Active · Completed · Expired |
| Listing claims | Approve (green ghost) / Reject (destructive); receiver first name only |
| My claims | Pending · Approved · Collected; “Mark as collected” when approved |
| Profile | Avatar initials, role badge, stats tiles, settings rows, logout |
| Admin web | Tables, ban/remove, stats — desktop 1024px+ |

Implementation checklist: [flutter.md](./flutter.md).

---

## 8. Key user flows

```
Receiver: Nearby → Detail → Confirm claim → My claims (Pending)
          → Push approved → Pickup (maps) → Done

Donor:    Dashboard → Create → Publish → Claims → Approve → Complete
```

**Targets:** claim flow ≤ 4 taps from Nearby; repeat donor post &lt; 90s.

---

## 9. Copy and voice

Redistribution language only.

| Do | Don’t |
|----|--------|
| Share food, Claim food, Pick up by | Donate, Request help, Beneficiary, Charity |
| Surplus food, Available nearby | Leftovers, Free handout, Needy |
| Claim pending, Approved | Waiting for charity approval |
| Listed today | Fresh charity meal |

**Push notifications**

| Event | Title | Body |
|-------|--------|------|
| New nearby | Food near you | {title} — {distance} away |
| Claim approved | Claim approved | Pick up {title} by {time} |
| Claim rejected | Claim not approved | Still open to others |
| Deadline soon | Pickup soon | {title} — within 2 hours |

Tone: neutral, brief, actionable. No exclamation spam.

---

## 10. Motion and feedback

This is **utility infrastructure**, not social media or fintech glamour.

| Allowed | Avoid |
|---------|--------|
| Platform default page transitions | Lottie, parallax, hero animations |
| Pull-to-refresh indicator | Decorative micro-interactions |
| Snackbar confirm / error | Bouncy buttons, confetti |
| Light haptic on error | Motion for branding |

Respect `reduce motion` — disable nonessential transitions.

---

## 11. Accessibility

| Requirement | Implementation |
|-------------|----------------|
| Touch targets | Min 44×44dp |
| Inputs | Min 16px |
| Contrast | WCAG AA on `background` / `surface` |
| Status | Never color-only — icon + text |
| Screen reader | Card: “{title}, 1.2 kilometers, pickup before 7 PM, verified, available” |

---

## 12. Permissions UX

| Permission | When | If denied |
|------------|------|-----------|
| Location | First browse or post | Cached/manual area message |
| Camera / photos | First listing photo | Explain; retry |
| Notifications | After first claim | Banner on My claims |

---

## 13. MVP vs Phase 2 UI

| Phase 1 | Phase 2 |
|---------|---------|
| Donor + receiver, self-pickup | Volunteer tab, delivery tracking |
| Compact feed + detail hero | Optional delivery CTA on claim |
| English | Hausa, Yoruba, Igbo |

---

## 14. Design deliverables checklist

### Phase A — Define MVP UX (in order)

- [ ] **1.** Nearby food feed wireframe + compact card layout  
- [ ] **2.** `FoodCard` component spec (receiver + donor variants)  
- [ ] **3.** Food detail screen  
- [ ] **4.** Create listing flow  
- [ ] **5.** Claim confirmation flow  
- [ ] **6.** Bottom navigation shells (donor + receiver)  
- [ ] **7.** Notifications permission + push copy review  

### Phase B — Systemize in code

- [ ] `theme.dart` with green + gray scales (§3.8)  
- [ ] `StatusChip`, `TrustBadge`, `PrimaryButton`, `FilterChips`  
- [ ] Skeleton, empty, error, offline states (§5.10)  
- [ ] Admin web tables (desktop)  

Do not add new theory docs until Phase A screens exist in Figma or Flutter.

---

## 15. Document map

| Document | Role |
|----------|------|
| **[README.md](./README.md)** | Index — start here; canonical stack facts |
| **uiux.md** | Positioning, tokens, components, screens, copy |
| **prd.md** | Personas, stories, acceptance criteria |
| **mvp.md** | Engineering, API, data model |
| **flutter.md** | App structure, nav, build order |
| **location.md** | Geo search rules |

**prd.md** wins on scope; **uiux.md** wins on presentation; **location.md** wins on geo.

---

## 16. Design decisions log

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Product tone | Calm operational utility | Long-term trust over emotional campaign |
| Primary color | `#2D6A4F` + generated scale | One green family — visual consistency |
| Orange | Urgency only | Preserves hierarchy |
| Background | `#F5F7F2` | Softer than white for scroll and night |
| Fonts | System only | Performance and size in NG market |
| Card layout | Compact horizontal | Fast scan; logistics pattern |
| Core card data | Distance + expiry first | Primary user decision drivers |
| Charity language | Banned | Dignified UX |
| Motion | Minimal | Utility app, weak networks |
| Offline | Cached feed + retry | Connectivity reality |

---

*UI/UX v1.1 — Zero Hunger MVP*
