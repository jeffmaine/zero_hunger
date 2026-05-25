# Deploy Zero Hunger on AWS EC2 (Docker)

Yes — **EC2** is the right AWS choice for this stack: one VM running Docker Compose (API + Postgres).

---

## Overview

```text
Internet → EC2 security group (port 8000) → Docker: api:8000
                                              └── db (Postgres, internal only)
```

Later: put **HTTPS** in front with ALB + ACM, or nginx + Let’s Encrypt on the same instance.

---

## 1. Launch an EC2 instance

| Setting | Recommendation |
|--------|----------------|
| **AMI** | Ubuntu Server 22.04 LTS |
| **Instance type** | `t3.small` (2 GB RAM) minimum; `t3.micro` only for a quick smoke test |
| **Storage** | 20–30 GB gp3 |
| **Key pair** | Create/download `.pem` — you need it to SSH |
| **Security group** | See below |

### Security group (inbound)

| Type | Port | Source | Purpose |
|------|------|--------|---------|
| SSH | 22 | **Your IP only** | Admin access |
| Custom TCP | 8000 | `0.0.0.0/0` (or your IP first, then open for mobile testers) | API |
| — | **Do not** open 5432 | — | Postgres stays inside Docker |

### Connect

```bash
chmod 400 ~/Downloads/your-key.pem
ssh -i ~/Downloads/your-key.pem ubuntu@EC2_PUBLIC_IP
```

---

## 2. Install Docker on the instance

```bash
sudo apt-get update
sudo apt-get install -y git ca-certificates curl
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker ubuntu
```

Log out and back in so `docker` works without `sudo`:

```bash
exit
ssh -i ~/Downloads/your-key.pem ubuntu@EC2_PUBLIC_IP
docker --version
```

---

## 3. Clone the app

```bash
cd ~
git clone git@github.com:jeffmaine/zero_hunger.git
cd zero_hunger
```

If the server has no GitHub SSH key, use HTTPS:

```bash
git clone https://github.com/jeffmaine/zero_hunger.git
```

---

## 4. Configure environment

```bash
cp backend/.env.example backend/.env
nano backend/.env
```

**Required for production:**

```env
ENVIRONMENT=production

SECRET_KEY=<run: python3 -c "import secrets; print(secrets.token_urlsafe(48))">
ACCESS_SECRET=<another random string>
REFRESH_SECRET=<another random string>

DB_NAME=zerohunger
DB_USER=postgres
DB_PASSWORD=<strong-password>
POSTGRES_PASSWORD=<same as DB_PASSWORD>

CORS_ORIGINS=*

# Optional but recommended for real usage
CLOUDINARY_CLOUD_NAME=...
CLOUDINARY_API_KEY=...
CLOUDINARY_API_SECRET=...

FCM_ENABLED=true
FIREBASE_CREDENTIALS_PATH=/app/secrets/firebase-service-account.json
```

**Firebase key on the server:**

```bash
mkdir -p backend/secrets
nano backend/secrets/firebase-service-account.json
# paste JSON from Firebase Console, save
```

Or from your Mac:

```bash
scp -i ~/Downloads/your-key.pem \
  backend/secrets/firebase-service-account.json \
  ubuntu@EC2_PUBLIC_IP:~/zero_hunger/backend/secrets/
```

---

## 5. Start the stack

From `~/zero_hunger`:

```bash
docker compose up -d --build
docker compose ps
docker compose exec api alembic upgrade head
docker compose exec api python -m scripts.seed_admin
```

Check logs if anything fails:

```bash
docker compose logs -f api
```

---

## 6. Verify API

On your Mac:

```bash
curl http://EC2_PUBLIC_IP:8000/
curl http://EC2_PUBLIC_IP:8000/docs
```

Default admin (change password after first login): see `README.md` / seed script output.

---

## 7. Point the mobile app at EC2

```bash
cd mobile
flutter run --dart-define=API_BASE=http://EC2_PUBLIC_IP:8000/api/v1
```

For release builds, set `API_BASE` to your public URL. **HTTP + IP is fine for testing**; production should use **HTTPS** and a domain.

---

## 8. HTTPS (recommended before real users)

**Simple path on same EC2:** install Caddy or nginx, reverse proxy `https://api.yourdomain.com` → `localhost:8000`, open ports 80/443 in the security group.

**AWS path:** Application Load Balancer + ACM certificate + target group on port 8000.

---

## Useful commands

```bash
cd ~/zero_hunger
docker compose pull          # after git pull
docker compose up -d --build # rebuild API after code changes
docker compose exec api alembic upgrade head
docker compose logs -f api
docker compose down            # stop (data kept in volume)
```

---

## Updating after a git push

```bash
cd ~/zero_hunger
git pull
docker compose up -d --build
docker compose exec api alembic upgrade head
```

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `Connection refused` on :8000 | Security group must allow 8000; `docker compose ps` shows api **Up** |
| API exits on start | `docker compose logs api` — often bad `.env` or DB password mismatch |
| `POSTGRES_PASSWORD` / login failed | `POSTGRES_PASSWORD` and `DB_PASSWORD` in `.env` must match |
| FCM errors | JSON file at `backend/secrets/`, path `/app/secrets/...` in `.env` |
| Mobile can’t reach API | Use **public IP**, not `localhost`; phone needs internet route to EC2 |

---

## Cost ballpark

- `t3.small` ≈ $15–20/mo (region-dependent)
- Stop the instance when not demoing to save money (EBS storage still billed)
