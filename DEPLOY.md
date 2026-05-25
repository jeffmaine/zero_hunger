# Fast deploy checklist

## 1. Push to GitHub

```bash
cd zero_hunger
git remote add origin https://github.com/YOUR_USER/zero_hunger.git
git branch -M main
git push -u origin main
```

Create the empty repo on GitHub first (no README), then run the commands above.

## 2. Run on a server (Docker)

1. Clone the repo on your VPS (DigitalOcean, AWS EC2, etc.).
2. Copy env: `cp backend/.env.example backend/.env` and fill secrets.
3. Put Firebase service account at `backend/secrets/` (gitignored).
4. Start:

```bash
docker compose up -d --build
docker compose exec api alembic upgrade head
```

5. Point your domain or IP to port `8000` (use nginx/Caddy for HTTPS in production).
6. Update mobile `API_BASE` / ngrok URL to your public API URL.

## 3. Mobile builds

- Android: `flutter build apk --release`
- iOS: Xcode archive (needs Apple dev account)

Do **not** commit `.env`, Firebase JSON keys, or `google-services.json`.
