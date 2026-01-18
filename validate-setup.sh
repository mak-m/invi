#!/bin/bash

echo "=== INVI Ledger Setup Validation ==="
echo ""

ERRORS=0
WARNINGS=0

# Check Docker
echo -n "Docker: "
if command -v docker >/dev/null 2>&1; then
  DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | tr -d ',')
  echo "✓ Installed ($DOCKER_VERSION)"
else
  echo "✗ Not installed"
  echo "  Install from: https://docs.docker.com/get-docker/"
  ERRORS=$((ERRORS+1))
fi

# Check Docker Compose
echo -n "Docker Compose: "
if command -v docker compose >/dev/null 2>&1; then
  COMPOSE_VERSION=$(docker compose version --short)
  echo "✓ Installed ($COMPOSE_VERSION)"
else
  echo "✗ Not installed"
  echo "  Install Docker Desktop or: https://docs.docker.com/compose/install/"
  ERRORS=$((ERRORS+1))
fi

# Check docker-compose.yml
echo -n "docker-compose.yml: "
if [ -f "docker-compose.yml" ]; then
  echo "✓ Exists"
else
  echo "✗ Missing"
  echo "  Download from: https://github.com/mak-m/invi"
  ERRORS=$((ERRORS+1))
fi

# Check .env file
echo -n ".env file: "
if [ -f ".env" ]; then
  echo "✓ Exists"
  
  # Check if password is set
  if grep -q "POSTGRES_PASSWORD=ChangeMeToAStrongPassword" .env 2>/dev/null; then
    echo "  ⚠ Warning: Default password detected"
    echo "    Edit .env and set a strong password"
    WARNINGS=$((WARNINGS+1))
  elif grep -q "POSTGRES_PASSWORD=" .env; then
    # Check password strength
    PASSWORD=$(grep "POSTGRES_PASSWORD=" .env | cut -d'=' -f2)
    if [ ${#PASSWORD} -lt 12 ]; then
      echo "  ⚠ Warning: Password should be at least 12 characters"
      WARNINGS=$((WARNINGS+1))
    fi
  else
    echo "  ✗ POSTGRES_PASSWORD not set"
    ERRORS=$((ERRORS+1))
  fi
else
  echo "✗ Missing"
  echo "  Copy .env.example to .env and configure"
  ERRORS=$((ERRORS+1))
fi

# Check if INVI is running
echo ""
echo "=== Runtime Status ==="
echo -n "INVI API: "
if curl -sf http://localhost:8080/api/admin/version >/dev/null 2>&1; then
  VERSION=$(curl -s http://localhost:8080/api/admin/version 2>/dev/null | grep -o '"version":"[^"]*"' | cut -d'"' -f4)
  echo "✓ Running (v$VERSION)"
  
  # Check database connectivity
  echo -n "Database: "
  if curl -sf http://localhost:8080/api/admin/upgrade >/dev/null 2>&1; then
    echo "✓ Connected"
  else
    echo "✗ Not connected"
    ERRORS=$((ERRORS+1))
  fi
else
  echo "Not running"
  echo "  Start with: docker compose up -d"
fi

# Check Docker resources
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  echo ""
  echo "=== Docker Resources ==="
  
  # Check available memory
  TOTAL_MEM=$(docker info --format '{{.MemTotal}}' 2>/dev/null)
  if [ -n "$TOTAL_MEM" ] && [ "$TOTAL_MEM" -gt 0 ]; then
    MEM_GB=$((TOTAL_MEM / 1024 / 1024 / 1024))
    echo -n "Memory: ${MEM_GB}GB "
    if [ "$MEM_GB" -lt 2 ]; then
      echo "⚠ Warning: 2GB recommended"
      WARNINGS=$((WARNINGS+1))
    else
      echo "✓"
    fi
  fi
  
  # Check disk space
  AVAILABLE_SPACE=$(df -h . | awk 'NR==2 {print $4}')
  echo "Disk space available: $AVAILABLE_SPACE"
fi

# Summary
echo ""
echo "=== Summary ==="
if [ $ERRORS -eq 0 ]; then
  echo "✓ Setup validation passed"
  if [ $WARNINGS -gt 0 ]; then
    echo "  $WARNINGS warning(s) - review above"
  fi
  exit 0
else
  echo "✗ Setup validation failed"
  echo "  $ERRORS error(s)"
  if [ $WARNINGS -gt 0 ]; then
    echo "  $WARNINGS warning(s)"
  fi
  echo ""
  echo "Fix the errors above and run this script again"
  exit 1
fi
