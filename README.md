# INVI Ledger

INVI is a **transactional inventory ledger** - a high-performance inventory management system (IMS) designed for enterprises in fulfillment, logistics, and inventory domains. It provides a reliable API to solve complex inventory challenges and serves as the single source of truth for all inventory concerns in your organization.

### Core Features

**Transactional Inventory Storage**
- **WHAT**: Track all inventory items
- **WHERE**: Know exact locations of inventory
- **HOW MUCH**: Real-time quantity tracking
- **WHY**: Track purpose and history (sale, inspection, fulfillment, etc.)

**Data Integrity & Reliability**
- **RESTful API**: Modern HTTP-based API for easy integration with any system that can make HTTP requests
- **PostgreSQL 17**: Enterprise-grade relational database ensures ACID compliance and data durability
- **Docker Containers**: Portable, isolated deployment that runs consistently across development, staging, and production

### What INVI is NOT

INVI is a **core inventory component**, not a complete end-user application. It does not include:
- ❌ A user interface (UI)
- ❌ Order Management System (OMS) features
- ❌ Fulfillment Management System (FMS) features
- ❌ Warehouse Management System (WMS) features

INVI provides the foundational inventory ledger that you build your IMS and UI around. It integrates with other systems via its REST API, serving as the single source of truth for inventory.

---

## Quick Start

### Prerequisites

- Docker and Docker Compose installed
- 2GB RAM available
- Internet connection to pull images

### Run with Docker Compose

1. **Create project directory with configuration files:**
   ```bash
   mkdir invi-ledger
   cd invi-ledger
   # Copy docker-compose.yml and .env.example from this repository
   # Then:
   cp .env.example .env
   # Edit .env and set POSTGRES_PASSWORD
   ```

2. **Start the services:**
   ```bash
   docker compose up -d
   ```

3. **Apply database migrations:**
   ```bash
   curl -X POST http://localhost:8080/api/admin/upgrade
   ```

4. **Verify it's running:**
   ```bash
   curl http://localhost:8080/api/admin/version
   ```

5. **Access the API:**
   - API: http://localhost:8080
   - Swagger UI: http://localhost:8080/swagger (only available when `ENVIRONMENT=Development`)

### Stop the services

```bash
docker compose down
```

To also remove data:
```bash
docker compose down -v
```

---

## What's Included

- **INVI Ledger API**: RESTful API for inventory management
- **PostgreSQL 17**: Database for persistent storage
- **Database migrations**: Apply via Admin API after first startup

---

## API Endpoints

### Inventory Items
- `GET /api/inventoryitems` - List all inventory items
- `GET /api/inventoryitems/{primaryId}` - Get specific item by ID
- `POST /api/inventoryitems` - Create new item
- `PUT /api/inventoryitems/{primaryId}` - Update item ID (rename)
- `DELETE /api/inventoryitems/{primaryId}` - Delete item (fails if item has assignments)

**Note**: See [Understanding primaryId](./docs/PRIMARY-ID-EXPLAINED.md) to learn why it's called primaryId and how to work with multiple identifier types (SKUs, GTINs, barcodes).

### Locations (Hierarchical Storage)

Locations represent **where** inventory is stored. They form a hierarchical tree structure similar to a file system.

**Location Paths:**
- All paths start from the root: `~`
- Child locations use `/` as separator: `~/Warehouse-A/Aisle-5/Shelf-3`
- Like directories: a location can contain both inventory and child locations
- Queries can target entire subtrees (e.g., "all inventory in Warehouse-A and its children")

**Physical or Logical:**
- Locations don't have to be physical places
- Can represent logical groupings: `~/Suppliers/Acme`, `~/Categories/Electronics/Phones`
- Mix and match: `~/Warehouse-A/Quarantine` or `~/Virtual/Reserved-For-VIP-Customers`

**Operations:**
- `GET /api/locations?fromPath={path}&recursive={true|false}` - List locations
  - `fromPath`: Starting point in the tree (e.g., `~/Warehouse-A`)
  - `recursive=true`: Returns all descendants
  - `recursive=false`: Returns only direct children
  
- `GET /api/locations/stat?path={path}` - Get specific location by exact path
  
- `POST /api/locations` - Create new location
  - Requires parent path and primary name
  - Example: Parent `~/Warehouse-A`, Name `Aisle-5` → Creates `~/Warehouse-A/Aisle-5`
  
- `DELETE /api/locations` - Delete location (requires path in request body)
  - Fails if location has children or inventory

### Assignments (Inventory Transactions)

Assignments represent **how much** inventory is allocated for different purposes at each location.

**Understanding Assignment Primary ID:**

Each assignment can have an optional `assignmentPrimaryId` that identifies **why** the assignment exists or **what specific entity** it's associated with:

- **For generic inventory**: Use `null` - e.g., `{kind: "stock", primaryId: null}` represents general available stock
- **For order-specific inventory**: Use order ID - e.g., `{kind: "reserved", primaryId: "ORDER-12345"}` reserves inventory for a specific order
- **For batch/lot tracking**: Use batch ID - e.g., `{kind: "stock", primaryId: "BATCH-2024-A"}` tracks inventory by batch
- **For shipment tracking**: Use shipment ID - e.g., `{kind: "shipped", primaryId: "CUST-001"}` tracks what was shipped to whom

**Important Matching Behavior:**
- When querying or changing assignments, `primaryId` filters are **exact match only**
- `primaryId: null` matches ONLY assignments with null primaryId (not "any primaryId")
- `primaryId: "BATCH-A"` matches ONLY assignments with that exact value
- For automatic batch selection (FIFO/FEFO), use `sortKey` instead of `primaryId`

**Query Operations:**
- `POST /api/assignments/total` - Query aggregated inventory amounts
  - Sums inventory across an entire location tree (e.g., "Total reserved inventory in all warehouses")
  - Groups by item and assignment kind
  - Can filter by item, assignment kind, or assignment ID
  
- `POST /api/assignments/detailed` - Query inventory with location breakdown
  - Shows inventory amounts at each specific location within a tree
  - Includes location paths, assignment IDs, and sort keys for each assignment
  - Useful for understanding inventory distribution

**Transaction Operations:**
- `POST /api/assignments/set` - Set assignment amounts (allocate, reserve, etc.)
  - Sets exact amounts or applies deltas (add/subtract)
  - Atomic operation: all-or-nothing by default
  - Prevents negative inventory
  - Use cases: Reserve inventory for orders, allocate to fulfillment, etc.
  
- `POST /api/assignments/change` - Transfer inventory between assignment kinds
  - Moves inventory from source to destination (e.g., "Available" → "Reserved")
  - Processes across location trees using lowest sort-key assignments first
  - Atomic: either all changes succeed or none do
  - Use cases: Fulfill orders, move from quarantine to available, etc.
  
- `POST /api/assignments/cycle-count` - Reconcile physical counts
  - Compares physical count with system total at a location
  - Set `allowAutoResolution: true` to auto-resolve shortages (reduces low-priority assignments first)
  - Requires manual resolution for surpluses or when auto-resolution is disabled
  - Returns status: NoDiscrepancy, DiscrepancyResolved, or ManualResolutionRequired

### Inventory History
- `GET /api/inventoryhistory` - Query inventory change history
  - Required: `from` and `to` (datetime range)
  - Required: at least one of `locationPath` or `itemId`
  - Returns timestamped events showing amount changes, operation names, and grouping IDs

### Admin
- `GET /api/admin/version` - Get application version
- `GET /api/admin/changelog` - Get release history
- `GET /api/admin/upgrade` - Check for pending database migrations
- `POST /api/admin/upgrade` - Apply pending database migrations

---

## Documentation

- [Installation Guide](./docs/INSTALLATION.md) - Detailed setup instructions
- [Configuration Guide](./docs/CONFIGURATION.md) - Environment variables and settings
- [Monitoring Guide](./docs/MONITORING.md) - Health checks and monitoring
- [Troubleshooting](./docs/TROUBLESHOOTING.md) - Common issues and solutions
- [Business Cases](./docs/business-cases/README.md) - Real-world inventory management scenarios
- [Understanding primaryId](./docs/PRIMARY-ID-EXPLAINED.md) - Working with multiple identifier types
- [Privacy Policy](./PRIVACY.md) - Our commitment to not collecting your data
- [License](./LICENSE) - Terms of use

### Helper Scripts

- **Setup Validation**: `./validate-setup.sh` - Verify your environment is configured correctly

---

## Feedback and Bug Reports

We welcome your feedback and bug reports!

### Report a Bug

Found a bug? Please [open an issue](https://github.com/mak-m/invi/issues/new) with:
- Clear description of the problem
- Steps to reproduce
- Expected vs actual behavior
- Your environment (OS, Docker version, INVI version)
- Relevant logs (if applicable)

### Request a Feature

Have an idea? [Create a feature request](https://github.com/mak-m/invi/issues/new) describing:
- What problem it solves
- How you envision it working
- Why it would be valuable

### General Feedback

Questions, suggestions, or comments? Open an issue on [GitHub Issues](https://github.com/mak-m/invi/issues).

---

## Version Information

Check the current version:
```bash
curl http://localhost:8080/api/admin/version
```

View release history:
```bash
curl http://localhost:8080/api/admin/changelog
```
