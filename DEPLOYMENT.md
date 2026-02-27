# Deployment Guide — Hetzner via Kamal

## Infrastructure Overview

- **Server:** Hetzner CPX22 VPS in Nuremberg (nbg1), `188.245.75.73`
- **OS:** Ubuntu 24.04 LTS (x86_64)
- **Deployment tool:** [Kamal 2](https://kamal-deploy.org/)
- **Container registry:** Docker Hub (`yshmarov/corsego`)
- **Database:** PostgreSQL 17 (Kamal accessory container)
- **Object storage:** AWS S3 (`corsego-production` bucket, eu-central-1)
- **SSL:** Let's Encrypt, auto-provisioned by kamal-proxy
- **Domain:** `corsego.com` (DNS managed via Namecheap)

## Hetzner Server Provisioning

To provision a new server from scratch:

1. Go to [Hetzner Cloud Console](https://console.hetzner.cloud/) and create a new project (or use an existing one)
2. Click **Add Server** with the following settings:
   - **Location:** Nuremberg (same region as other infrastructure)
   - **Image:** Ubuntu (latest LTS)
   - **Type:** Shared vCPU, x86 — CPX22 (2 vCPU, 4 GB RAM) is a good starting point
   - **SSH keys:** add your public key (see [SSH Key Setup](#ssh-key-setup) below)
   - **Networking:** ensure IPv4 is enabled (required for Kamal SSH access)
   - **Name:** something descriptive (e.g., `corsego-production`)
   - **Skip:** Volumes, Firewalls, Backups, Placement groups, Labels, Cloud config (not needed — Kamal handles provisioning, ufw handles firewall)
3. Note the assigned public IPv4 address
4. Update `config/deploy.yml` with the new IP in three places:
   - `servers.web`
   - `builder.remote` (ssh://root@NEW_IP)
   - `accessories.db.host`

## Prerequisites

On your local machine:

```bash
gem install kamal          # Install Kamal CLI
docker login               # Authenticate with Docker Hub
```

### SSH Key Setup

You need an SSH key to access the Hetzner server. If you don't have one:

```bash
# Generate an Ed25519 key (recommended)
ssh-keygen -t ed25519

# Copy your public key — paste this into Hetzner Cloud when creating the server
cat ~/.ssh/id_ed25519.pub
```

Verify you can connect after the server is provisioned:

```bash
ssh root@188.245.75.73
```

### Secrets

Kamal reads secrets from environment variables via `.kamal/secrets`. **Both must be set before every deploy**, otherwise containers will boot with missing credentials (e.g., database connection failures).

Add these to your `~/.zshrc` (or `~/.bashrc`) so they persist across terminal sessions:

```bash
export KAMAL_REGISTRY_PASSWORD=<docker-hub-access-token>
export POSTGRES_PASSWORD=<postgres-password>
```

After editing, run `source ~/.zshrc` or open a new terminal.

`RAILS_MASTER_KEY` is read automatically from `config/master.key` (not an env var).

#### Where to find each secret

| Secret | Source | How to retrieve/regenerate |
|---|---|---|
| `KAMAL_REGISTRY_PASSWORD` | Docker Hub access token | [hub.docker.com/settings/security](https://hub.docker.com/settings/security) → New Access Token (one token works for all repos) |
| `POSTGRES_PASSWORD` | Set during first `kamal setup` | Generate with `openssl rand -hex 32`. Retrieve from running container: `ssh root@188.245.75.73 'docker inspect corsego-db --format "{{range .Config.Env}}{{println .}}{{end}}"'` |
| `RAILS_MASTER_KEY` | `config/master.key` (git-ignored) | Already on disk; back it up securely — losing it means you can't decrypt credentials |

## Configuration Files

| File | Purpose |
|---|---|
| `config/deploy.yml` | Kamal deployment config (servers, services, accessories) |
| `.kamal/secrets` | Maps env vars/files to Kamal secrets (never commit raw credentials) |
| `Dockerfile` | Multi-stage production Docker image (Ruby, Bun, assets) |
| `.dockerignore` | Files excluded from Docker build context |
| `bin/docker-entrypoint` | Container startup script (jemalloc, db:migrate) |
| `config/storage.yml` | ActiveStorage services (AWS S3 for production) |

## First-Time Setup Checklist

Follow these steps in order to go from a bare Hetzner server to a running production app:

1. **Provision server** — create a Hetzner VPS in Nuremberg and add your SSH key (see [Hetzner Server Provisioning](#hetzner-server-provisioning))
2. **Verify SSH access:** `ssh root@188.245.75.73`
3. **Point DNS** — add A records for `@` and `www` to the server IP (see [DNS Configuration](#dns-configuration))
4. **Export all required env vars** in your terminal (see [Secrets](#secrets)):
   ```bash
   export KAMAL_REGISTRY_PASSWORD=<docker-hub-access-token>
   export POSTGRES_PASSWORD=<postgres-password>
   ```
5. **Run `kamal setup`** — this installs Docker on the server, boots all containers (web, database), and provisions SSL via Let's Encrypt
6. **Harden the server** — configure ufw and fail2ban (see [Server Hardening](#server-hardening))
7. **Add Docker cleanup cron** (see [Docker Cleanup Cron](#docker-cleanup-cron))
8. **Verify the deployment:**
    ```bash
    curl https://corsego.com/up
    # Should return 200 OK
    ```

## Deploying

Kamal deploys whatever commit is currently checked out on your **local machine** — it clones from your local git repo, not GitHub. **All changes must be committed** before deploying; Kamal ignores uncommitted files.

**Before every deploy**, ensure the required env vars are exported in your current shell session (deploy will fail with `flag needs an argument: 'p' in -p` if these are missing):

```bash
source ~/.zshrc    # Load env vars if not already set
```

Or export them manually:

```bash
export KAMAL_REGISTRY_PASSWORD=<docker-hub-access-token>
export POSTGRES_PASSWORD=<postgres-password>
```

Then run:

```bash
# Standard deploy (build, push, boot new containers)
kamal deploy

# Force rebuild without Docker cache
kamal build push --no-cache && kamal deploy

# First-time setup (provisions server, installs Docker, boots everything)
kamal setup
```

Kamal builds the Docker image remotely on the Hetzner server (`builder.remote` in `deploy.yml`), so no cross-compilation or QEMU emulation is needed.

**Database migrations** run automatically on every deploy — the Docker entrypoint (`bin/docker-entrypoint`) runs `db:migrate` on boot. We use `db:migrate` instead of `db:prepare` because `db:prepare` also runs seeds, which can fail in production (e.g., seed mailers requiring SMTP).

### Rollback

If a deploy introduces a bug, roll back to a previous version:

```bash
# List recent deployed containers to find a good version
kamal app containers

# Roll back to a specific git SHA
kamal rollback <git-sha>
```

## Common Commands

### Application

```bash
kamal console              # Rails console (interactive)
kamal shell                # Bash shell inside web container
kamal dbc                  # Rails database console (psql)
kamal logs                 # Tail web server logs
kamal app details          # Show running container details
```

### Direct Server Access

```bash
ssh root@188.245.75.73                            # SSH into the server
docker ps                                    # List running containers
docker logs corsego-web-latest --tail 50     # Web container logs
docker logs corsego-db --tail 50             # PostgreSQL logs
```

### Database

```bash
# psql via the database container
docker exec -it corsego-db psql -U corsego -d corsego_production

# Quick query
docker exec corsego-db psql -U corsego -d corsego_production -c "SELECT COUNT(*) FROM users;"
```

### Database Backup & Restore

**Backup (dump from Hetzner):**

```bash
# Run from your local machine
ssh root@188.245.75.73 'docker exec corsego-db pg_dump -U corsego -Fc corsego_production' > ~/Desktop/corsego_backup.dump
```

**Restore (load a dump into Hetzner):**

```bash
# 1. Upload dump to server
scp ~/Desktop/corsego_backup.dump root@188.245.75.73:/tmp/corsego_backup.dump

# 2. Stop app containers to prevent connections during restore
ssh root@188.245.75.73 'docker stop corsego-web-latest'

# 3. Drop and recreate database
ssh root@188.245.75.73 'docker exec corsego-db psql -U corsego -d postgres -c "DROP DATABASE IF EXISTS corsego_production;"'
ssh root@188.245.75.73 'docker exec corsego-db psql -U corsego -d postgres -c "CREATE DATABASE corsego_production OWNER corsego;"'

# 4. Restore
ssh root@188.245.75.73 'docker exec -i corsego-db pg_restore --no-owner --no-privileges --dbname=corsego_production -U corsego < /tmp/corsego_backup.dump'

# 5. Restart containers
ssh root@188.245.75.73 'docker start corsego-web-latest'
```

## Architecture Diagram

```
                ┌─────────────────────────────────────────┐
                │     Hetzner VPS — Nuremberg (nbg1)       │
                │     188.245.75.73                             │
                │                                         │
  HTTPS :443 ──►│  kamal-proxy (Let's Encrypt SSL)        │
                │       │                                 │
                │       ▼                                 │
                │  corsego-web-latest  (:80)               │
                │    └─ Thruster → Puma → Rails           │
                │                                         │
                │  corsego-db                              │
                │    └─ PostgreSQL 17                      │
                │       Volume: corsego_postgres_data      │
                │                                         │
                │  Volume: corsego_storage                 │
                │    └─ Active Storage local files        │
                └─────────────────────────────────────────┘
                         │
                         ▼
                ┌─────────────────────────────────────────┐
                │  AWS S3 — eu-central-1                   │
                │  corsego-production bucket               │
                │    └─ Active Storage uploads             │
                └─────────────────────────────────────────┘
```

## DNS Configuration

DNS is managed via **Namecheap** (Advanced DNS tab).

| Type | Host | Value | TTL |
|---|---|---|---|
| A Record | `@` | `188.245.75.73` | Automatic |
| A Record | `www` | `188.245.75.73` | Automatic |

Keep all other records (blog CNAME, DKIM/SES CNAMEs, TXT records) unchanged.

**Important:** If migrating from another host, delete any existing CNAME records for `@` and `www` **before** adding the A records. CNAME records take priority over A records and will prevent the new A records from working.

After DNS changes, browsers may cache the old DNS for a while. Use incognito mode or flush DNS cache to verify:

```bash
# Check current DNS resolution
dig +short corsego.com A

# Flush macOS DNS cache if needed
sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder

# Test the Hetzner server directly (bypasses DNS)
curl -s -o /dev/null -w "%{http_code}" --resolve corsego.com:443:188.245.75.73 https://corsego.com/up
```

## Monitoring

### Error Tracking — Honeybadger

[Honeybadger](https://www.honeybadger.io/) captures exceptions in production. Configuration is in `config/honeybadger.yml`; the API key is stored in Rails encrypted credentials. Errors are reported automatically in production — no additional setup needed after adding the API key to credentials.

### Health Check / Uptime

The app exposes `GET /up` which returns HTTP 200 when healthy. Point an external uptime monitor at `https://corsego.com/up`:

- [UptimeRobot](https://uptimerobot.com/) (free tier: 5-minute checks)
- [Honeybadger Uptime](https://docs.honeybadger.io/uptime/) (included with Honeybadger plan)

### Server Diagnostics

Run these commands to assess server health:

**System overview (CPU, memory, swap, disk):**

```bash
ssh root@188.245.75.73 'uptime && free -h && swapon --show && df -h /'
```

**Per-container resource usage:**

```bash
ssh root@188.245.75.73 'docker stats --no-stream'
```

**Check for OOM (Out of Memory) kills:**

```bash
ssh root@188.245.75.73 'dmesg | grep -i "out of memory" | tail 5'
```

## Server Hardening

Kamal installs Docker but does **not** harden the server. Run these steps manually on the Hetzner VPS after `kamal setup`.

### Firewall (ufw)

```bash
ssh root@188.245.75.73

ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw default deny incoming
ufw default allow outgoing
ufw enable
ufw status
```

### SSH Brute-Force Protection (fail2ban)

```bash
apt install fail2ban -y
systemctl enable fail2ban
systemctl start fail2ban

# Verify SSH jail is active
fail2ban-client status sshd
```

### Swap

Hetzner VPS instances have no swap by default. Add a 2 GB swap file as a safety net:

```bash
ssh root@188.245.75.73 'fallocate -l 2G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile && echo "/swapfile none swap sw 0 0" >> /etc/fstab'
```

Verify:

```bash
ssh root@188.245.75.73 'swapon --show && free -h'
```

### Docker Cleanup Cron

Old images and build cache accumulate over time. Add a weekly cleanup:

```bash
(crontab -l 2>/dev/null; echo '0 4 * * 0 docker system prune -af --volumes=false >> /var/log/docker-cleanup.log 2>&1') | crontab -
```

This runs every Sunday at 4 AM, removing unused images and containers but preserving data volumes.

## Troubleshooting

**App not responding after deploy:**
```bash
kamal app details                    # Check container state
kamal logs                           # Check for boot errors
ssh root@188.245.75.73 'docker ps'       # Verify containers are running
```

**Database connection issues:**
```bash
# Verify DB container is running and has an IP on the kamal network
docker exec corsego-db pg_isready -U corsego
ssh root@188.245.75.73 'docker inspect corsego-db --format "{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}"'

# If the DB has no IP (empty output), reboot it:
kamal accessory reboot db

# Check DB container logs
docker logs corsego-db --tail 20
```

**SSL certificate issues:**
```bash
# Verify cert via curl
curl -vI https://corsego.com 2>&1 | grep -E 'subject:|issuer:|expire'

# kamal-proxy auto-provisions Let's Encrypt certs when DNS resolves to the server
# If DNS recently changed, redeploy to trigger cert provisioning:
kamal deploy
```

**Missing assets (`application.js` or `application.css` not in asset pipeline):**

The Dockerfile has a two-step asset build: first `bun run build:production` compiles JS/CSS into `app/assets/builds/`, then `rails assets:precompile` fingerprints them into `public/assets/`. If you see this error, verify both steps are present in the Dockerfile and that `.dockerignore` excludes `app/assets/builds/*` (the Docker build regenerates them).

```bash
# Check if assets exist in the running container
kamal shell
ls /rails/public/assets/
```

If assets are missing, force a clean rebuild:

```bash
kamal build push --no-cache && kamal deploy
```

**Disk space:**
```bash
ssh root@188.245.75.73 'df -h'
ssh root@188.245.75.73 'docker system df'

# Clean up unused Docker resources
ssh root@188.245.75.73 'docker system prune -f'
```
