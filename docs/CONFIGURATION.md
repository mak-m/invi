# INVI Ledger - Configuration Guide

Complete reference for configuring INVI Ledger.

## Environment Variables

### Application Version

| Variable | Default | Description |
|----------|---------|-------------|
| `INVI_VERSION` | `latest` | Docker image tag to use (e.g., `1.0.0`, `latest`) |

**Example:**
```bash
INVI_VERSION=1.0.456
```

---

### API Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `API_PORT` | `8080` | Port to expose the API on |
| `ENVIRONMENT` | `Production` | ASP.NET Core environment (`Development`, `Staging`, `Production`) |

**Example:**
```bash
API_PORT=8080
ENVIRONMENT=Production
```

---

### Database Configuration

| Variable | Required | Recommended | Description |
|----------|----------|-------------|-------------|
| `POSTGRES_DB` | No* | `InviLedger` | Database name |
| `POSTGRES_USER` | No* | `inviuser` | Database username |
| `POSTGRES_PASSWORD` | **Yes** | - | Database password (must be strong) |
| `POSTGRES_PORT` | No | `5432` | PostgreSQL port |

*While these have defaults in the PostgreSQL container, you should set them explicitly to ensure the API connection string matches.

**Example:**
```bash
POSTGRES_DB=InviLedger
POSTGRES_USER=inviuser
POSTGRES_PASSWORD=YourSecurePassword123!
POSTGRES_PORT=5432
```

**Password Requirements:**
- Minimum 12 characters
- Mix of letters, numbers, and symbols
- Avoid common words

---

## Connection String Format

The complete connection string format:

```
Username={user};Password={password};Host={host};Port={port};Database={dbname}
```

**Example:**
```
Username=inviuser;Password=SecurePass123!;Host=postgres;Port=5432;Database=InviLedger
```

### Additional Connection String Options

| Option | Description | Example |
|--------|-------------|---------|
| `Pooling` | Enable connection pooling | `Pooling=true` |
| `MinPoolSize` | Minimum connections | `MinPoolSize=5` |
| `MaxPoolSize` | Maximum connections | `MaxPoolSize=100` |
| `Timeout` | Connection timeout (seconds) | `Timeout=30` |
| `CommandTimeout` | Command timeout (seconds) | `CommandTimeout=30` |

---

## Configuration Files

### .env File

The `.env` file should be placed in the same directory as `docker-compose.yml`.

**Example `.env`:**
```bash
# Application
INVI_VERSION=latest
API_PORT=8080
ENVIRONMENT=Production

# Database
POSTGRES_DB=InviLedger
POSTGRES_USER=inviuser
POSTGRES_PASSWORD=YourSecurePassword123!
POSTGRES_PORT=5432
```

### docker-compose.yml

Override settings directly in `docker-compose.yml` if needed:

```yaml
services:
  invi-ledger-api:
    environment:
      ConnectionStrings__DefaultConnection: "Username=customuser;Password=custompass;Host=postgres;Port=5432;Database=CustomDB"
      ASPNETCORE_ENVIRONMENT: Staging
```

---

## Environment-Specific Configurations

### Development Environment

```bash
INVI_VERSION=latest
API_PORT=8080
ENVIRONMENT=Development
POSTGRES_DB=InviLedger_Dev
POSTGRES_USER=devuser
POSTGRES_PASSWORD=DevPassword123!
```

### Staging Environment

```bash
INVI_VERSION=1.0.456
API_PORT=8080
ENVIRONMENT=Staging
POSTGRES_DB=InviLedger_Staging
POSTGRES_USER=staginguser
POSTGRES_PASSWORD=StagingSecurePass123!
```

### Production Environment

```bash
INVI_VERSION=1.0.456
API_PORT=8080
ENVIRONMENT=Production
POSTGRES_DB=InviLedger
POSTGRES_USER=inviuser
POSTGRES_PASSWORD=ProductionSecurePass456!
```

---

## Advanced Configuration

### Custom PostgreSQL Configuration

Create a custom PostgreSQL configuration file:

**postgresql.conf:**
```conf
# Connection settings
max_connections = 200
shared_buffers = 256MB

# Performance tuning
effective_cache_size = 1GB
maintenance_work_mem = 64MB
work_mem = 4MB

# Logging
log_destination = 'stderr'
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d.log'
```

**Mount in docker-compose.yml:**
```yaml
services:
  postgres:
    volumes:
      - ./postgresql.conf:/etc/postgresql/postgresql.conf
      - postgres-data:/var/lib/postgresql/data
    command: postgres -c config_file=/etc/postgresql/postgresql.conf
```

### Resource Limits

**docker-compose.yml:**
```yaml
services:
  invi-ledger-api:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4G
        reservations:
          cpus: '1.0'
          memory: 2G
  
  postgres:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4G
        reservations:
          cpus: '1.0'
          memory: 2G
```

---

## Security Best Practices

### 1. Secure Passwords

❌ **Bad:**
```bash
POSTGRES_PASSWORD=password
POSTGRES_PASSWORD=admin123
```

✅ **Good:**
```bash
POSTGRES_PASSWORD=$(openssl rand -base64 32)
```

### 2. Environment Variables

Never commit `.env` to version control:

**.gitignore:**
```
.env
*.env
```

### 3. Secrets Management

For production, use a secrets manager:

**Using Docker Secrets:**
```yaml
services:
  invi-ledger-api:
    secrets:
      - db_password
    environment:
      ConnectionStrings__DefaultConnection: "Username=inviuser;Password_File=/run/secrets/db_password;Host=postgres;Port=5432;Database=InviLedger"

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

### 4. Network Isolation

Remove public database port in production:

```yaml
services:
  postgres:
    # Remove this in production:
    # ports:
    #   - "5432:5432"
```

---

## Troubleshooting Configuration

### Issue: Cannot Connect to Database

**Check connection string:**
```bash
docker compose config | grep ConnectionStrings
```

**Verify environment variables:**
```bash
docker compose config | grep -A 5 environment
```

### Issue: Configuration Not Applied

**Restart services:**
```bash
docker compose down
docker compose up -d
```

**Check if .env is loaded:**
```bash
docker compose config
```

### Issue: Password Special Characters

Some characters need escaping in connection strings. Use URL encoding:

| Character | Encoded |
|-----------|---------|
| `@` | `%40` |
| `#` | `%23` |
| `&` | `%26` |
| `=` | `%3D` |

**Example:**
```bash
# Password: Pass@word#123
POSTGRES_PASSWORD=Pass%40word%23123
```

---

## Configuration Validation

Create a validation script:

**validate-config.sh:**
```bash
#!/bin/bash

# Check required variables
if [ -z "$POSTGRES_PASSWORD" ]; then
    echo "ERROR: POSTGRES_PASSWORD not set"
    exit 1
fi

# Check password strength
if [ ${#POSTGRES_PASSWORD} -lt 12 ]; then
    echo "WARNING: Password should be at least 12 characters"
fi

# Check API port
if [ "$API_PORT" -lt 1024 ] && [ "$(id -u)" != "0" ]; then
    echo "WARNING: Ports below 1024 require root privileges"
fi

echo "Configuration validation passed"
```

---

## Next Steps

- [Installation Guide](./INSTALLATION.md) - Install INVI
- [Troubleshooting](./TROUBLESHOOTING.md) - Debug issues
