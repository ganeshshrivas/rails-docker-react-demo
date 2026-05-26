# Rails Demo — Full-Stack Production Starter working demo

Rails 7 API + React (Vite) + PostgreSQL + JWT auth, containerized with Docker and deployable to AWS EC2 via GitHub Actions.

## Project structure

```
backend/          # Rails 7 API-only app
frontend/         # React + Vite SPA (Nginx in production)
nginx/            # Nginx documentation (config lives in frontend/nginx)
docker-compose.yml
.github/workflows/deploy.yml
```

## Tech stack

| Layer | Stack |
|-------|--------|
| Backend | Ruby on Rails 7.1 (API), PostgreSQL, JWT (`jwt` gem), `bcrypt` |
| Frontend | React 19, Vite, Axios, React Router |
| Infra | Docker Compose, Nginx reverse proxy, GitHub Actions, EC2 |

---

## Local setup (without Docker)

### Prerequisites

- Ruby 3.2+
- Node.js 22+
- PostgreSQL 16+

### Backend

```bash
cd backend
cp .env.example .env
bundle install
bin/rails db:create db:migrate db:seed
bin/rails server
```

API runs at `http://localhost:3000`.

### Frontend

```bash
cd frontend
cp .env.example .env
npm install
npm run dev
```

App runs at `http://localhost:5173` with Vite proxying `/api` to Rails.

---

## Docker run (recommended)

### 1. Configure environment

```bash
cp .env.example .env
```

Edit `.env` and set strong values for `JWT_SECRET` and `SECRET_KEY_BASE`.

### 2. Start the stack

```bash
docker compose up --build
```

| Service | URL |
|---------|-----|
| Frontend (Nginx) | http://localhost |
| API (via proxy) | http://localhost/api |

### 3. Database

Migrations run automatically on backend startup via `docker-entrypoint.sh` (`rails db:prepare`).

Seed demo data (optional):

```bash
docker compose exec backend bundle exec rails db:seed
```

Demo user: `demo@example.com` / `password123`

---

## API endpoints

All authenticated routes require header: `Authorization: Bearer <token>`

### Auth

| Method | Path | Body | Description |
|--------|------|------|-------------|
| POST | `/api/signup` | `{ "user": { "name", "email", "password" } }` | Register, returns JWT |
| POST | `/api/login` | `{ "user": { "email", "password" } }` | Login, returns JWT |

### User

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/me` | Current user profile |

### Posts (scoped to current user)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/posts` | List own posts |
| POST | `/api/posts` | Create post |
| GET | `/api/posts/:id` | Show own post |
| PUT | `/api/posts/:id` | Update own post |
| DELETE | `/api/posts/:id` | Delete own post |

Example signup:

```bash
curl -X POST http://localhost/api/signup \
  -H "Content-Type: application/json" \
  -d '{"user":{"name":"Jane","email":"jane@example.com","password":"password123"}}'
```

---

## Environment variables

| Variable | Description |
|----------|-------------|
| `JWT_SECRET` | Secret for signing JWTs |
| `SECRET_KEY_BASE` | Rails secret key base |
| `DATABASE_HOST` | Postgres host (`postgres` in Docker) |
| `DATABASE_USERNAME` | DB user (default `postgres`) |
| `DATABASE_PASSWORD` | DB password (default `postgres`) |
| `DATABASE_NAME` | Database name |
| `RAILS_ENV` | `development`, `test`, `staging`, or `production` |
| `DEPLOY_ENV` | `staging` or `production` (EC2 deploy script only) |
| `VITE_API_URL` | Frontend API base path (default `/api`) |

---

## Nginx routing

Configured in `frontend/nginx/default.conf`:

- `/` → React static files (SPA fallback to `index.html`)
- `/api/*` → Rails backend (`/api` prefix stripped)

---

## CI/CD (GitHub Actions)

Workflow: `.github/workflows/deploy.yml`

### Environments

| Environment | Trigger | Docker image tag | Compose file |
|-------------|---------|------------------|--------------|
| **Staging** | Push to `main` | `:staging` | `docker-compose.staging.yml` |
| **Production** | Push tag `v*` (e.g. `v1.0.0`) | `:production` | `docker-compose.prod.yml` |

Staging and production use **separate EC2 instances** and **separate secrets**. Images are tagged separately so a staging deploy never overwrites production images on Docker Hub.

### On every push / PR to `main`

1. Run Rails tests (with Postgres service)
2. Run frontend Vitest suite

### On push to `main` (after tests pass)

1. Build and push images tagged `staging` (+ commit SHA)
2. Deploy to the **staging** GitHub environment → staging EC2

### On push of version tag `v*` (after tests pass)

1. Build and push images tagged `production` (+ tag name)
2. Deploy to the **production** GitHub environment → production EC2

Release example:

```bash
git tag v1.0.0
git push origin v1.0.0
```

### GitHub configuration (step by step)

#### 1. Secrets (repository defaults + optional environment overrides)

Put **shared defaults** in **Repository secrets**. Override any value on the **staging** or **production** environment only when it must differ (e.g. different `EC2_HOST` or `JWT_SECRET`).

GitHub resolves `${{ secrets.NAME }}` on jobs with `environment: staging|production` as:

1. Environment secret (if defined for that environment)
2. Otherwise **repository secret**

| Secret | Typical location | Description |
|--------|------------------|-------------|
| `DOCKERHUB_USERNAME` | Repository | Docker Hub username |
| `DOCKERHUB_TOKEN` | Repository | Docker Hub access token |
| `EC2_USER` | Repository | SSH user (`ubuntu` / `ec2-user`) |
| `EC2_SSH_KEY` | Repository | SSH private key (PEM) |
| `VITE_API_URL` | Repository | Frontend build API path (default `/api`) |
| `FRONTEND_API_URL` | Repository | Alias for `VITE_API_URL` if not using `VITE_API_URL` |
| `JWT_SECRET` | Repository or environment | JWT signing secret |
| `SECRET_KEY_BASE` | Repository or environment | Rails secret key base |
| `EC2_HOST` | **Environment** (per host) | EC2 IP or DNS — usually different per env |

Do not create an environment secret with an **empty** value; it blocks the repository fallback. Remove the name from the environment if you want the repository value.

#### 2. GitHub Environments

In **Settings → Environments**, create two environments:

**`staging`** and **`production`**

Use the **same secret names** as repository secrets. Only add a secret to an environment when it should **override** the repository value (required: `EC2_HOST` per server; optional: `JWT_SECRET`, `SECRET_KEY_BASE` if they differ).

| Secret | Override on environment? |
|--------|---------------------------|
| `EC2_HOST` | Yes — different IP per environment |
| `JWT_SECRET`, `SECRET_KEY_BASE` | Optional — omit to use repository defaults |
| `DOCKERHUB_*`, `EC2_USER`, `EC2_SSH_KEY`, `VITE_API_URL` | Usually repository only |
| `DEPLOY_GITHUB_TOKEN` | Optional — repository or environment |

Optional: enable **Required reviewers** on the `production` environment so releases need approval before deploy.

#### 3. EC2 instances

Launch **two** instances (or reuse one only for staging while testing):

| | Staging | Production |
|---|---------|------------|
| Purpose | Pre-release testing | Live traffic |
| AMI | Ubuntu 24.04 LTS (recommended) | Same |
| Security group | 22 (your IP), 80, 443 | Same |
| App path on server | `~/rails_demo` | `~/rails_demo` |

Generate secrets on your machine:

```bash
# JWT_SECRET (32+ random bytes, base64)
openssl rand -base64 32

# SECRET_KEY_BASE (64+ random bytes)
openssl rand -hex 64
```

Use **different** values for staging and production.

#### 4. First deploy

1. Configure repository + environment secrets above.
2. Push to `main` → staging deploy runs automatically.
3. Tag a release → production deploy runs:

   ```bash
   git tag v1.0.0 && git push origin v1.0.0
   ```

On a fresh EC2 host, `scripts/ec2-bootstrap.sh` installs Docker, logs in to Docker Hub, pulls the correct `:staging` or `:production` images, and starts the stack.

---

## Production deployment (AWS EC2)

### 1. Launch EC2 instance

- AMI: **Ubuntu 24.04 LTS**
- Instance type: `t3.small` or larger
- Storage: 20 GB+

### 2. Security group

| Port | Protocol | Source | Purpose |
|------|----------|--------|---------|
| 22 | TCP | Your IP | SSH |
| 80 | TCP | 0.0.0.0/0 | HTTP |
| 443 | TCP | 0.0.0.0/0 | HTTPS |
| 3000 | TCP | Optional | Direct API debug only (not required behind Nginx) |

### 3. First deploy (automated)

On a **fresh** EC2 instance you only need:

1. Security group (step 2)
2. GitHub environment secrets for **staging** or **production** (see CI/CD section)
3. Push to `main` (staging) or push a `v*` tag (production)

Manual setup (optional debugging):

```bash
ssh ubuntu@<EC2_HOST>   # or ec2-user@<EC2_HOST> on Amazon Linux
cd ~/rails_demo && git pull
export DEPLOY_ENV=staging   # or production
export JWT_SECRET=... SECRET_KEY_BASE=... DOCKERHUB_USERNAME=... DOCKERHUB_TOKEN=...
bash scripts/ec2-bootstrap.sh
```

Visit `http://<EC2_PUBLIC_IP>` (staging host or production host).

### 4. Domain + HTTPS (recommended)

Point your domain A record to the EC2 IP, then on EC2:

```bash
sudo apt-get install -y certbot
sudo certbot certonly --standalone -d yourdomain.com
```

Mount certificates into Nginx (extend `frontend/nginx/default.conf` with SSL `listen 443 ssl` and certificate paths), or place a host-level Nginx/Caddy reverse proxy in front of the container.

---

## Development commands

```bash
# Backend tests
cd backend && bundle exec rails test

# Frontend tests
cd frontend && npm test

# RuboCop (optional)
cd backend && bundle exec rubocop
```

---

## Architecture

```mermaid
flowchart LR
  Browser --> Nginx
  Nginx -->|/api/*| Rails
  Nginx -->|/*| React
  Rails --> PostgreSQL
```

---

## License

MIT
