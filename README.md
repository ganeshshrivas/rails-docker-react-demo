# Rails Demo — Full-Stack Production Starter

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
| `RAILS_ENV` | `development`, `test`, or `production` |
| `VITE_API_URL` | Frontend API base path (default `/api`) |

---

## Nginx routing

Configured in `frontend/nginx/default.conf`:

- `/` → React static files (SPA fallback to `index.html`)
- `/api/*` → Rails backend (`/api` prefix stripped)

---

## CI/CD (GitHub Actions)

Workflow: `.github/workflows/deploy.yml`

### On every push / PR to `main`

1. Run Rails tests (with Postgres service)
2. Run frontend Vitest suite

### On push to `main` (after tests pass)

1. Build and push Docker images to Docker Hub
2. SSH into EC2, pull images, run `docker compose -f docker-compose.prod.yml up -d`

### Required GitHub secrets

| Secret | Description |
|--------|-------------|
| `DOCKERHUB_USERNAME` | Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token |
| `EC2_HOST` | EC2 public IP or hostname |
| `EC2_USER` | SSH user (e.g. `ubuntu`) |
| `EC2_SSH_KEY` | Private SSH key (PEM contents) |
| `JWT_SECRET` | Production JWT secret |
| `SECRET_KEY_BASE` | Production Rails secret |

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

### 3. Install Docker on EC2

```bash
ssh ubuntu@<EC2_HOST>

sudo apt-get update
sudo apt-get install -y ca-certificates curl git
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
newgrp docker
```

### 4. Clone repository

```bash
git clone https://github.com/<your-org>/rails_demo.git ~/rails_demo
cd ~/rails_demo
cp .env.example .env
```

Edit `.env` with production secrets and add:

```bash
echo "DOCKERHUB_USERNAME=your_dockerhub_user" >> .env
```

### 5. Login to Docker Hub (on EC2)

```bash
docker login
```

### 6. Run production stack

```bash
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d
```

Visit `http://<EC2_PUBLIC_IP>`.

### 7. Domain + HTTPS (recommended)

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
