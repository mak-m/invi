# INVI Ledger - Monitoring Guide

Monitor INVI Ledger using its Admin API endpoints.

## Health Check Endpoints

### Basic Health Check

```bash
curl http://localhost:8080/api/admin/version
```

**Success Response:**
```json
{
  "version": "1.0.0"
}
```

**What this tells you:**
- ✅ INVI Ledger API is running and responding
- ✅ Application started successfully

**Use case:** Quick check to verify the service is up.

---

### Comprehensive Health Check

```bash
curl http://localhost:8080/api/admin/upgrade
```

**Success Response:**
```json
{
  "hasPendingMigrations": false
}
```

**What this tells you:**
- ✅ INVI Ledger API is running
- ✅ Can communicate with database
- ✅ Database schema is current (no pending migrations)

**Error Response (503):**
```json
{
  "error": "Database unavailable"
}
```

**What this tells you:**
- ✅ INVI Ledger API is running
- ❌ Cannot communicate with database

**Use case:** Verify the entire INVI stack is operational (API + database connectivity).

---

## Monitoring Strategy

### Basic Monitoring

Check if INVI is responsive:

```bash
# Simple availability check
curl -f http://localhost:8080/api/admin/version || echo "INVI is down"
```

### Comprehensive Monitoring

Check full stack health:

```bash
# Check API and database
curl -f http://localhost:8080/api/admin/upgrade || echo "INVI system failure"
```

---

## Health Check Script

**invi-health.sh:**
```bash
#!/bin/bash

API_URL="${INVI_API_URL:-http://localhost:8080}"

echo "Checking INVI Ledger..."

# Check if INVI is responding
echo -n "Service: "
if curl -sf "$API_URL/api/admin/version" > /dev/null 2>&1; then
  VERSION=$(curl -s "$API_URL/api/admin/version" | grep -o '"version":"[^"]*"' | cut -d'"' -f4)
  echo "✓ Running (v$VERSION)"
else
  echo "✗ Not responding"
  exit 1
fi

# Check if INVI can access database
echo -n "Database Access: "
RESPONSE=$(curl -s -w "%{http_code}" "$API_URL/api/admin/upgrade")
HTTP_CODE="${RESPONSE: -3}"

if [ "$HTTP_CODE" = "200" ]; then
  echo "✓ OK"
else
  echo "✗ Failed (HTTP $HTTP_CODE)"
  exit 1
fi

echo "All checks passed ✓"
```

**Usage:**
```bash
chmod +x invi-health.sh

# Check local instance
./invi-health.sh

# Check remote instance
INVI_API_URL=https://invi.example.com ./invi-health.sh
```

---

## Integration with Monitoring Tools

### HTTP Monitoring Services

Configure external monitors (UptimeRobot, Pingdom, Uptime.com, etc.):

**Endpoint:** `/api/admin/upgrade`  
**Method:** GET  
**Expected Status:** 200  
**Expected Body Contains:** `"hasPendingMigrations"`  
**Check Interval:** 60 seconds  

### Prometheus

```yaml
scrape_configs:
  - job_name: 'invi'
    metrics_path: '/api/admin/version'
    static_configs:
      - targets: ['your-server:8080']
```

### Nagios/Icinga

```bash
define command{
  command_name check_invi
  command_line $USER1$/check_http -H $HOSTADDRESS$ -p 8080 -u /api/admin/upgrade -e 200
}
```

---

## Monitoring Checklist

**Critical Checks:**
- [ ] `/api/admin/version` responds with HTTP 200
- [ ] `/api/admin/upgrade` responds with HTTP 200

**Alert Conditions:**
- `/api/admin/version` fails → INVI is down
- `/api/admin/upgrade` returns 503 → INVI cannot access database
- Response time > 5 seconds → Performance issue

---

## View Installed Version and Changelog

### Check Current Version

```bash
curl http://localhost:8080/api/admin/version
```

Shows the currently running version.

### View Release History

```bash
curl http://localhost:8080/api/admin/changelog
```

**Response:**
```json
{
  "entries": [
    {
      "version": "1.0.0",
      "date": "2026-01-20",
      "sections": [
        {
          "category": "Added",
          "items": ["Initial release"]
        }
      ]
    }
  ]
}
```

**Use case:** View release notes for the currently installed version.

---

## Simple Monitoring Examples

### Cron Job

```cron
# Check every 5 minutes
*/5 * * * * curl -sf http://localhost:8080/api/admin/upgrade || echo "INVI DOWN" | mail -s "Alert" admin@example.com
```

### Shell Script with Alerts

```bash
#!/bin/bash

if ! curl -sf http://localhost:8080/api/admin/upgrade > /dev/null; then
  # Send alert (customize for your notification system)
  echo "INVI is down!" | mail -s "ALERT" admin@example.com
fi
```

### Continuous Monitoring Loop

```bash
# Monitor in real-time
while true; do
  if curl -sf http://localhost:8080/api/admin/upgrade > /dev/null; then
    echo "$(date): ✓ OK"
  else
    echo "$(date): ✗ FAILED"
  fi
  sleep 60
done
```

---

## What Each Endpoint Checks

| Endpoint | What It Verifies |
|----------|------------------|
| `/api/admin/version` | API is running |
| `/api/admin/upgrade` | API is running AND can connect to database |

**Recommendation:** Use `/api/admin/upgrade` for production monitoring as it provides a complete health check.

---

## Next Steps

- [Troubleshooting](./TROUBLESHOOTING.md) - Debug issues detected by monitoring
- [Installation Guide](./INSTALLATION.md) - Production deployment
- [Configuration Guide](./CONFIGURATION.md) - Performance tuning
