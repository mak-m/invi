# INVI Ledger - Installation Guide

Complete guide to installing and running INVI Ledger in your environment.

## Prerequisites

### Required
- **Docker**: Version 20.10 or higher
- **Docker Compose**: Version 2.0 or higher
- **System Resources**:
  - 2GB RAM minimum (4GB recommended)
  - 10GB disk space
  - 2 CPU cores minimum

### Optional
- **curl** or **wget**: For health checks
- **jq**: For JSON parsing in scripts

## Docker Authentication (If Needed)

If you're pulling from a private registry or need to avoid rate limits:

```bash
# Login to GitHub Container Registry
echo YOUR_GITHUB_TOKEN | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin
```

**Note:** Public images from `ghcr.io/mak-m/invi` don't require authentication.

---

## Installation Methods

### Method 1: Docker Compose (Recommended)

This is the simplest way to get INVI running with all dependencies.

#### Step 1: Create Project Directory

```bash
mkdir invi-ledger
cd invi-ledger
```

#### Step 2: Download Configuration Files

```bash
# Create docker-compose.yml and .env.example
# Copy the files from this repository or create them manually
# See the repository root for example files

# Copy environment template
cp .env.example .env
```

#### Step 3: Configure Environment

Edit `.env` file:

```bash
# Required: Set a strong password
POSTGRES_PASSWORD=YourStrongPasswordHere123!

# Optional: Customize other settings
API_PORT=8080
POSTGRES_DB=InviLedger
POSTGRES_USER=inviuser
```

#### Step 4: Start Services

```bash
docker compose up -d
```

#### Step 5: Wait for Services to be Ready

```bash
# Wait for API to be healthy
until curl -f http://localhost:8080/api/admin/version 2>/dev/null; do
  echo "Waiting for API to start..."
  sleep 2
done
echo "✓ API is ready!"
```

#### Step 6: Apply Database Migrations

```bash
curl -X POST http://localhost:8080/api/admin/upgrade
```

#### Step 7: Access the API

- **API Base URL**: http://localhost:8080
- **Swagger UI**: http://localhost:8080/swagger (set `ENVIRONMENT=Development` in `.env` to enable)
- **Health Check**: http://localhost:8080/api/admin/version

---

### Method 2: Docker Run (Manual Setup)

For more control over the setup.

#### Step 1: Create Network

```bash
docker network create invi-network
```

#### Step 2: Start PostgreSQL

```bash
docker run -d \
  --name invi-postgres \
  --network invi-network \
  -e POSTGRES_DB=InviLedger \
  -e POSTGRES_USER=inviuser \
  -e POSTGRES_PASSWORD=YourPassword123! \
  -v invi-postgres-data:/var/lib/postgresql/data \
  -p 5432:5432 \
  postgres:17
```

#### Step 3: Wait for PostgreSQL

```bash
# Wait until ready
docker exec invi-postgres pg_isready -U inviuser
```

#### Step 4: Start INVI Ledger API

```bash
docker run -d \
  --name invi-ledger-api \
  --network invi-network \
  -e ConnectionStrings__DefaultConnection="Username=inviuser;Password=YourPassword123!;Host=invi-postgres;Port=5432;Database=InviLedger" \
  -e ASPNETCORE_ENVIRONMENT=Production \
  -p 8080:8080 \
  ghcr.io/mak-m/invi:latest
```

#### Step 5: Wait for API to Start

```bash
# Wait for API to be ready
until curl -f http://localhost:8080/api/admin/version 2>/dev/null; do
  echo "Waiting for API to start..."
  sleep 2
done
echo "✓ API is ready!"
```

#### Step 6: Apply Database Migrations

```bash
curl -X POST http://localhost:8080/api/admin/upgrade
```

---

## API Security

INVI Ledger does not currently implement authentication. For production deployments:
- Deploy behind a reverse proxy with authentication
- Use firewall rules to restrict access
- Enable HTTPS via reverse proxy

---

## Upgrading INVI

### Step 1: Stop Current Version

```bash
docker compose down
```

### Step 2: Update Version in .env (Optional)

```bash
# Edit .env to pin to a specific version
INVI_VERSION=1.2.0

# Or leave as 'latest' to always use the newest release
# INVI_VERSION=latest
```

### Step 3: Start New Version

```bash
# This will automatically pull the new version
docker compose up -d
```

### Step 4: Wait for Services

```bash
# Wait for API to be ready
until curl -f http://localhost:8080/api/admin/version 2>/dev/null; do
  echo "Waiting for API..."
  sleep 2
done
```

### Step 5: Apply Database Migrations

```bash
# Check if migrations are needed
curl http://localhost:8080/api/admin/upgrade

# Apply migrations if needed
curl -X POST http://localhost:8080/api/admin/upgrade
```

### Step 6: Verify Upgrade

```bash
# Check version
curl http://localhost:8080/api/admin/version

# Verify changelog
curl http://localhost:8080/api/admin/changelog
```

---

## Uninstallation

### Remove Services (Keep Data)

```bash
docker compose down
```

### Remove Services and Data

```bash
docker compose down -v
```

### Complete Cleanup

```bash
# Stop and remove containers
docker compose down -v

# Remove images
docker rmi ghcr.io/mak-m/invi:latest
docker rmi postgres:17

# Remove network
docker network rm invi-network
```

---

## Troubleshooting Installation

### Issue: Services Won't Start

**Check logs:**
```bash
docker compose logs invi-ledger-api
docker compose logs postgres
```

**Common causes:**
- Port already in use (change `API_PORT` in `.env`)
- Insufficient resources (check Docker Desktop settings)
- Missing environment variables

### Issue: Database Connection Failed

**Verify PostgreSQL is healthy:**
```bash
docker compose ps postgres
docker exec invi-postgres pg_isready -U inviuser
```

**Check connection string:**
```bash
docker compose config | grep ConnectionStrings
```

### Issue: Cannot Pull Image

**Login to registry:**
```bash
docker login ghcr.io
```

**Check image exists:**
```bash
docker pull ghcr.io/mak-m/invi:latest
```

### Issue: Health Check Fails

**Wait longer** (migrations can take 30-60 seconds on first start)

**Check API logs:**
```bash
docker logs invi-ledger-api
```

**Test manually:**
```bash
curl -v http://localhost:8080/api/admin/version
```

---

## Next Steps

- [Configuration Guide](./CONFIGURATION.md) - Customize your installation
- [Troubleshooting](./TROUBLESHOOTING.md) - Debug common issues
