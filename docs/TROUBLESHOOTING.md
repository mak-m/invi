# INVI Ledger - Troubleshooting Guide

Common issues and solutions for INVI Ledger.

## Quick Diagnostics

Run these commands first to gather information:

```bash
# Check service status
docker compose ps

# View logs
docker compose logs invi-ledger-api
docker compose logs postgres

# Check health
curl http://localhost:8080/api/admin/version

# Check resources
docker stats --no-stream
```

---

## Common Issues

### Services Won't Start

**Symptoms:**
- `docker compose up` fails
- Containers exit immediately
- "Port already in use" errors

**Solutions:**

1. **Check if port is in use:**
```bash
# Check port 8080
lsof -i :8080

# Or on Linux
netstat -tlnp | grep 8080

# Change port in .env
API_PORT=8081
```

2. **Check Docker resources:**
```bash
docker system df
docker system prune  # Remove unused data
```

3. **View detailed logs:**
```bash
docker compose up  # Run without -d to see logs
```

---

### Database Connection Fails

**Symptoms:**
- API logs show "Could not connect to database"
- Health check returns unhealthy
- PostgreSQL connection errors

**Solutions:**

1. **Verify PostgreSQL is running:**
```bash
docker compose ps postgres
docker exec invi-postgres pg_isready -U inviuser
```

2. **Check connection string:**
```bash
docker compose config | grep ConnectionStrings
```

3. **Verify password:**
```bash
# Test connection manually
docker exec -it invi-postgres psql -U inviuser -d InviLedger
```

4. **Check network:**
```bash
docker network ls
docker network inspect invi-ledger_invi-network
```

---

### API Returns 500 Errors

**Symptoms:**
- All API calls return 500 Internal Server Error
- Swagger UI doesn't load
- Database migrations haven't run

**Solutions:**

1. **Check API logs:**
```bash
docker logs invi-ledger-api --tail 100
```

2. **Apply migrations via API:**
```bash
curl -X POST http://localhost:8080/api/admin/upgrade
```

3. **Verify database schema:**
```bash
docker exec invi-postgres psql -U inviuser -d InviLedger -c "\dt"
```

---

### Health Check Fails

**Symptoms:**
- `/api/admin/version` endpoint returns error
- Container shows as unhealthy

**Solutions:**

1. **Wait for API to be ready:**
```bash
until curl -f http://localhost:8080/api/admin/version 2>/dev/null; do
  echo "Waiting for API..."
  sleep 2
done
```

2. **Check if API is listening:**
```bash
docker exec invi-ledger-api curl http://localhost:8080/api/admin/version
```

3. **Disable health check temporarily:**
```yaml
# docker-compose.yml
services:
  invi-ledger-api:
    # healthcheck:
    #   test: ["CMD", "curl", "-f", "http://localhost:8080/api/admin/version"]
```

---

### Cannot Pull Docker Image

**Symptoms:**
- "unauthorized" or "not found" errors
- Cannot pull from ghcr.io

**Solutions:**

1. **Login to registry:**
```bash
# GitHub Container Registry
echo YOUR_GITHUB_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin
```

2. **Check image exists:**
```bash
# Try pulling explicitly
docker pull ghcr.io/mak-m/invi:latest
```

3. **Check image name:**
```bash
# Verify in .env
cat .env | grep INVI_VERSION
```

---

### Data Not Persisting

**Symptoms:**
- Data disappears after restart
- Database is empty after `docker compose down`

**Solutions:**

1. **Check volumes:**
```bash
docker volume ls
docker volume inspect invi_postgres-data
```

2. **Don't use `-v` flag:**
```bash
# This DELETES volumes:
docker compose down -v  # ❌

# This keeps data:
docker compose down     # ✅
```

3. **Backup data:**
```bash
docker exec invi-postgres pg_dump -U inviuser InviLedger > backup.sql
```

---

### Slow Performance

**Symptoms:**
- API responds slowly
- High CPU/memory usage
- Timeouts

**Solutions:**

1. **Check resources:**
```bash
docker stats
```

2. **Increase limits:**
```yaml
# docker-compose.yml
services:
  invi-ledger-api:
    deploy:
      resources:
        limits:
          memory: 4G
```

3. **Check database connections:**
```bash
docker exec invi-postgres psql -U inviuser -d InviLedger -c "SELECT count(*) FROM pg_stat_activity;"
```

4. **Review logs for errors:**
```bash
docker compose logs invi-ledger-api | grep -i error
```

---

### Swagger UI Not Loading

**Symptoms:**
- `/swagger` returns 404
- Swagger UI blank page

**Solutions:**

1. **Check environment:**
```bash
# Swagger only enabled when ENVIRONMENT=Development
docker compose config | grep ENVIRONMENT
```

2. **Enable Swagger:**
```bash
# Edit .env
ENVIRONMENT=Development

# Restart services
docker compose down
docker compose up -d
```

3. **Access directly:**
```
http://localhost:8080/swagger/index.html
```

---

## Diagnostic Commands

### View All Logs

```bash
# All services
docker compose logs

# Specific service
docker compose logs invi-ledger-api

# Follow logs
docker compose logs -f

# Last 100 lines
docker compose logs --tail=100
```

### Check Service Health

```bash
# Service status
docker compose ps

# Detailed inspect
docker inspect invi-ledger-api

# Health check
curl -v http://localhost:8080/api/admin/version
```

### Database Diagnostics

```bash
# Connect to database
docker exec -it invi-postgres psql -U inviuser -d InviLedger

# List tables
docker exec invi-postgres psql -U inviuser -d InviLedger -c "\dt"

# Check connections
docker exec invi-postgres psql -U inviuser -d InviLedger -c "SELECT count(*) FROM pg_stat_activity;"

# Database size
docker exec invi-postgres psql -U inviuser -d InviLedger -c "SELECT pg_size_pretty(pg_database_size('InviLedger'));"
```

### Network Diagnostics

```bash
# List networks
docker network ls

# Inspect network
docker network inspect invi-ledger_invi-network

# Test connectivity
docker exec invi-ledger-api ping postgres
```

---

## Reset Everything

If all else fails, completely reset:

```bash
# Stop and remove everything
docker compose down -v

# Remove images
docker rmi ghcr.io/mak-m/invi:latest postgres:17

# Clean Docker
docker system prune -a

# Start fresh
docker compose up -d
```

---

## Getting Help

### Collect Information

When reporting issues, include:

1. **Docker version:**
```bash
docker --version
docker compose version
```

2. **System info:**
```bash
# macOS/Linux
uname -a

# Resources
docker info | grep -i memory
```

3. **Logs:**
```bash
docker compose logs > logs.txt
```

4. **Configuration:**
```bash
docker compose config > config.yml
```

### Contact Support

- Documentation: [README](../README.md)
- Configuration: [CONFIGURATION.md](./CONFIGURATION.md)
- Installation: [INSTALLATION.md](./INSTALLATION.md)
