You are building the backend for a mobile-first food redistribution platform called “Zero Hunger”.

IMPORTANT:
You MUST use the backend architecture from this existing project as the PRIMARY reference and foundation:

/Users/jeffmaine/Documents/workspace/ohun/application/ohun_backend_copy

This is NOT just inspiration.

You are expected to:

* reuse the existing authentication architecture
* reuse the existing SQLAlchemy setup
* reuse the existing JWT implementation
* reuse the existing Google OAuth implementation
* reuse the dependency injection/auth guards
* reuse the database/session structure
* reuse the middleware/security patterns
* reuse the environment/config structure
* reuse exception/response handling patterns

The goal is to ADAPT the existing backend architecture to the new Zero Hunger platform — not replace it with an entirely different stack or architecture.

IMPORTANT ARCHITECTURE RULES

DO NOT:

* switch to SQLModel
* introduce a different ORM architecture
* redesign auth from scratch
* replace the database/session structure
* invent a completely different project organization

Instead:

* preserve the proven backend architecture
* extend it cleanly for the new domain models and APIs

PROJECT CONTEXT

Zero Hunger is a mobile-first platform where:

* donors post surplus food
* receivers browse and claim food
* volunteers later assist with deliveries

Tech stack:

* FastAPI
* SQLAlchemy
* PostgreSQL
* JWT auth
* Google OAuth
* Cloudinary
* Docker
* Flutter frontend

FIRST TASK (MANDATORY)

Before generating any code:

1. Inspect the reference backend carefully.
2. Analyze:

   * authentication flow
   * JWT utilities
   * Google OAuth implementation
   * SQLAlchemy setup
   * DB session management
   * dependency injection
   * middleware
   * role handling
   * configuration structure
   * exception handling
   * router organization
3. Reuse these patterns directly where applicable.

You should preserve the backend philosophy and architecture style of the reference project.

IMPLEMENTATION STRATEGY

STEP 1 — CLONE ARCHITECTURE
Replicate the same:

* folder structure
* DB setup
* auth architecture
* dependency patterns
* middleware structure
* service organization

Then rename/adapt for Zero Hunger.

STEP 2 — ADAPT DOMAIN MODELS
Create SQLAlchemy models for:

* users
* food listings
* claims
* deliveries

Use the SAME SQLAlchemy patterns from the reference backend.

STEP 3 — AUTH SYSTEM
Reuse/adapt:

* JWT login flow
* refresh token logic
* Google OAuth flow
* password hashing
* auth dependencies
* current user extraction
* role guards

DO NOT redesign auth.

STEP 4 — CORE ROUTERS
Implement:

* auth routes
* listings routes
* claims routes

STEP 5 — DATABASE MIGRATIONS
Use the SAME Alembic/migration strategy from the reference backend.

STEP 6 — BUSINESS LOGIC
Adapt the existing backend architecture to support:

* food listings
* nearby filtering
* food claims
* listing completion
* notification hooks

PROJECT REQUIREMENTS

Users:

* donor
* receiver
* volunteer
* admin

Food Listing Fields:

* title
* description
* quantity
* image_url
* pickup_deadline
* latitude
* longitude
* status

Claim Flow:

* pending
* approved
* rejected
* collected

IMPORTANT DEVELOPMENT RULES

1. Preserve the existing backend architecture.
2. Preserve the existing auth philosophy.
3. Reuse stable code patterns whenever possible.
4. Keep implementation modular.
5. Avoid introducing unnecessary abstractions.
6. Focus on production-grade backend quality.
7. Backend stability is higher priority than frontend speed right now.

EXPECTED OUTPUT

Generate:

* adapted backend structure
* reused SQLAlchemy setup
* reused auth architecture
* reused JWT utilities
* reused Google auth integration
* new domain models
* updated routers
* updated services
* Docker setup
* migration setup
* environment configuration

Begin by:

1. deeply inspecting the reference backend
2. identifying reusable authentication/database architecture
3. scaffolding the new backend using the SAME architectural style
