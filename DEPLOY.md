# Fast deploy checklist

## 1. Push to GitHub

```bash
cd zero_hunger
git remote add origin https://github.com/YOUR_USER/zero_hunger.git
git branch -M main
git push -u origin main
```

Create the empty repo on GitHub first (no README), then run the commands above.

## 2. AWS EC2 (recommended)

**Full walkthrough:** [deploy/aws-ec2.md](deploy/aws-ec2.md)

Quick version: Ubuntu EC2 → install Docker → clone repo → `backend/.env` → `docker compose up -d --build` → open port **8000** in security group.

## 3. Any server (Docker)

1. Clone the repo.
2. `cp backend/.env.example backend/.env` — set `DB_PASSWORD` and `POSTGRES_PASSWORD` to the **same** value.
3. Put Firebase JSON in `backend/secrets/` (mounted at `/app/secrets` in the API container).
4. Start:

```bash
docker compose up -d --build
docker compose exec api alembic upgrade head
```

5. Point mobile `API_BASE` to `http://YOUR_SERVER_IP:8000/api/v1`.
6. Add HTTPS before production users (nginx/Caddy or AWS ALB).

## 4. Mobile builds

- Android: `flutter build apk --release`
- iOS: Xcode archive (needs Apple dev account)

Do **not** commit `.env`, Firebase JSON keys, or `google-services.json`.
