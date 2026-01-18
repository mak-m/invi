# Example: Ecommerce Order Acceptance with INVI

This example shows how to handle order placement with transactional inventory reservation. Part 1 demonstrates single-location operations, Part 2 shows multi-location inventory with automatic selection using SortKey.

> **API Compatibility**: INVI API v0.2+
> **Last Updated**: 2026-02-02

---

# Part 1: Single Location Order Acceptance

## Scenario
- **Products**: WIDGET-A, WIDGET-B
- **Location**: Single warehouse
- **Initial Stock**: 5 units of WIDGET-A, 3 units of WIDGET-B
- **Process**: Reserve → Payment → Pack or Release

## Workflow Explanation

### Step 1: Setup Location and Items
We create a single warehouse location and two product items (WIDGET-A and WIDGET-B).

### Step 2: Receive Initial Stock
We receive initial inventory without batch tracking (assignmentPrimaryId = null). This sets the stock to 5 units of WIDGET-A and 3 units of WIDGET-B.

### Step 3: Reserve Inventory for Order
When a customer orders 2x WIDGET-A and 1x WIDGET-B, we atomically:
- Reduce stock by the ordered amounts
- Increase reserved inventory with the order ID (ORDER-001)

This ensures inventory is held for this specific order.

### Step 4a: Payment Success - Move to Packing
If payment succeeds, we move the reserved inventory to packing status. The inventory remains associated with ORDER-001 but changes from "reserved" to "packing" state.

### Step 4b: Payment Failure - Release Reservation
If payment fails, the order is cancelled, or the customer abandons the cart, we release the reserved inventory back to stock. This makes it available for other orders.

---

# Part 2: Multi-Location Order Acceptance with Automatic Selection

## Scenario
- **Products**: WIDGET-A spread across multiple warehouses and shelves
- **Locations**: 
  - ~/WH-East/Shelf-1 (older stock, SortKey 100)
  - ~/WH-East/Shelf-2 (newer stock, SortKey 200)
  - ~/WH-West/Shelf-1 (older stock, SortKey 150)
- **Challenge**: Which warehouse and shelf should fulfill the order?
- **Solution**: Use `/api/assignments/change` with location path to let INVI select inventory based on SortKey priority

## The Multi-Location Challenge

When inventory is spread across multiple warehouses and shelves, the Order Management System (OMS) must decide which location should fulfill an order. Factors include:
- Customer address (which warehouse is closer?)
- Shipping speed of different warehouses

However, once a warehouse is selected, there may still be multiple sublocations (shelves, bins) with the requested inventory. **SortKey** determines which specific inventory gets reserved first within that warehouse.

### Why SortKey Matters
- **FIFO for perishables**: Lower SortKey = higher priority (ships first)
- **Batch prioritization**: Certain batches can be prioritized for quality or business reasons
- **Automatic selection**: OMS doesn't need to know exact shelf locations

> **Why lower SortKey comes first**: SortKey can represent "best-before date" or expiration date as a UNIX timestamp. Lower values mean earlier dates, so inventory with lower SortKey should be consumed. This same logic works for any prioritization scheme where lower numbers = higher urgency.

### The `change` Operation

The `/api/assignments/change` endpoint allows specifying a **root location** rather than exact paths. INVI automatically selects inventory from sublocations, prioritizing lowest SortKey first.

**Key difference from `set`**: The `change` operation moves inventory hierarchically - you specify the root location and INVI finds the inventory within that subtree.

## Workflow Explanation

### Step 1: Setup Multi-Location Structure
We create a hierarchical location structure with two warehouses (WH-East, WH-West), each with shelves. We also create the WIDGET-A product.

### Step 2: Receive Stock with Different SortKeys
We receive inventory at different locations with different SortKeys:
- WH-East/Shelf-1: 10 units, SortKey 100 (oldest, highest priority)
- WH-East/Shelf-2: 15 units, SortKey 200 (newer, lower priority)
- WH-West/Shelf-1: 8 units, SortKey 150 (medium priority)

Lower SortKey values will be picked first when reserving inventory.

### Step 3: Check Total Inventory by Warehouse
We can query total inventory at a warehouse level to see aggregated amounts across all shelves.

### Step 4: Reserve Using `change` - Automatic Location Selection
When a customer in the eastern region orders 12 units, the OMS decides WH-East should fulfill. Using the `change` endpoint with rootLocation "~/WH-East", INVI automatically:
- Takes all 10 units from Shelf-1 (SortKey 100, oldest batch)
- Takes 2 units from Shelf-2 (SortKey 200, newer batch)
- Places reserved inventory at Shelf-1 location

This implements automatic FIFO without the OMS knowing exact shelf locations.

> **Note on `fromAssignmentPrimaryId`**: When omitted, INVI automatically selects inventory from ANY stock assignment within the specified location, prioritizing by SortKey (lowest first). If specified, INVI will ONLY reserve from that specific batch.

**Expected result**: The response shows that Shelf-1 stock is now 0, Shelf-2 stock is 13, and reserved inventory of 12 units is at Shelf-1.

### Step 5: Second Order - Insufficient Inventory
When a customer orders 20 units from WH-East (only 13 remain), the operation fails with an "Insufficient inventory" error. The `allOrNothing` policy ensures no partial reservation occurs.

### Step 6: Reserve from Different Warehouse
The OMS switches to WH-West and successfully reserves 5 units for ORDER-003.

### Step 7: Payment Success - Move to Packing
When ORDER-002 payment succeeds, we use `change` to move the 12 reserved units to packing status within WH-East.

### Step 8: Payment Failure - Release Reservation
When ORDER-003 payment fails, we release the 5 reserved units back to stock in WH-West.

### Step 9: View Detailed Inventory State
The detailed view shows the final state:
- WH-East/Shelf-2: 13 units in stock (BATCH-A-WEEK2)
- WH-East/Shelf-1: 12 units in packing (ORDER-002)
- WH-West/Shelf-1: 8 units in stock (BATCH-A-WEEK1-W)

## How This Solves Multi-Location Challenges

### 1. OMS Controls Warehouse Selection
- OMS decides which warehouse fulfills based on customer location, shipping requirements
- INVI respects the `rootPath` constraint in the `change` operation

### 2. Automatic Sublocation Selection
- Within chosen warehouse, INVI automatically picks from shelves/bins
- No need for OMS to track exact shelf locations
- SortKey ensures correct priority (FIFO, batch priority, etc.)

### 3. Hierarchical Inventory Operations
- Specify root location (e.g., `~/WH-East`)
- INVI handles all sublocations (Shelf-1, Shelf-2, etc.)
- Lower SortKey inventory consumed first

### 4. Atomic Multi-Location Operations
- `allOrNothing` policy works across sublocations
- Either full order reserves or entire operation fails
- No partial reservations across shelves

### 5. SortKey Use Cases
- **Best-before dates**: Store expiration as UNIX timestamp in SortKey - earlier dates (lower values) consumed first
- **Production dates**: Use production timestamp - older batches (lower SortKey) ship first (FIFO)
- **Quality tiers**: Premium stock gets higher SortKey, reserved only after regular stock depletes
- **Damage/clearance**: Damaged goods get lowest SortKey for immediate disposal priority
- **Any urgency-based priority**: Lower SortKey = higher urgency/priority

---

# Executable Code

The following commands can be run sequentially to demonstrate the complete workflow. Compare the results with the explanations above.

## Setup

```bash
# Set API root URL (defaults to localhost:5279 if not set)
API_ROOT="${API_ROOT:-http://localhost:5279}"
```

## Part 1: Single Location Commands

```bash
# Step 1: Create warehouse and products
curl -X POST "$API_ROOT/api/locations" \
  -H "Content-Type: application/json" \
  -d '{"parentFullPath": "~", "primaryName": "Warehouse"}'

curl -X POST "$API_ROOT/api/inventoryitems" \
  -H "Content-Type: application/json" \
  -d '{"PrimaryId": "WIDGET-A"}'

curl -X POST "$API_ROOT/api/inventoryitems" \
  -H "Content-Type: application/json" \
  -d '{"PrimaryId": "WIDGET-B"}'

# Step 2: Receive initial stock
curl -X POST "$API_ROOT/api/assignments/set" \
  -H "Content-Type: application/json" \
  -d '{
    "commands": [
      {"path": "~/Warehouse", "itemPrimaryId": "WIDGET-A", "assignmentKind": "stock", "amount": 5, "amountType": "absolute"},
      {"path": "~/Warehouse", "itemPrimaryId": "WIDGET-B", "assignmentKind": "stock", "amount": 3, "amountType": "absolute"}
    ],
    "assignPolicy": "allOrNothing"
  }' | jq .

# Step 3: Reserve inventory for ORDER-001
curl -X POST "$API_ROOT/api/assignments/set" \
  -H "Content-Type: application/json" \
  -d '{
    "commands": [
      {"path": "~/Warehouse", "itemPrimaryId": "WIDGET-A", "assignmentKind": "stock", "amount": -2, "amountType": "delta"},
      {"path": "~/Warehouse", "itemPrimaryId": "WIDGET-A", "assignmentKind": "reserved", "assignmentPrimaryId": "ORDER-001", "amount": 2, "amountType": "delta"},
      {"path": "~/Warehouse", "itemPrimaryId": "WIDGET-B", "assignmentKind": "stock", "amount": -1, "amountType": "delta"},
      {"path": "~/Warehouse", "itemPrimaryId": "WIDGET-B", "assignmentKind": "reserved", "assignmentPrimaryId": "ORDER-001", "amount": 1, "amountType": "delta"}
    ],
    "assignPolicy": "allOrNothing"
  }' | jq .

# Step 4a: Payment success - move to packing
curl -X POST "$API_ROOT/api/assignments/set" \
  -H "Content-Type: application/json" \
  -d '{
    "commands": [
      {"path": "~/Warehouse", "itemPrimaryId": "WIDGET-A", "assignmentKind": "reserved", "assignmentPrimaryId": "ORDER-001", "amount": -2, "amountType": "delta"},
      {"path": "~/Warehouse", "itemPrimaryId": "WIDGET-A", "assignmentKind": "packing", "assignmentPrimaryId": "ORDER-001", "amount": 2, "amountType": "delta"},
      {"path": "~/Warehouse", "itemPrimaryId": "WIDGET-B", "assignmentKind": "reserved", "assignmentPrimaryId": "ORDER-001", "amount": -1, "amountType": "delta"},
      {"path": "~/Warehouse", "itemPrimaryId": "WIDGET-B", "assignmentKind": "packing", "assignmentPrimaryId": "ORDER-001", "amount": 1, "amountType": "delta"}
    ],
    "assignPolicy": "allOrNothing"
  }' | jq .

# Step 4b (Alternative): Payment failure - release reservation
# Note: Only run this if you didn't run Step 4a, or reset the state first
# curl -X POST "$API_ROOT/api/assignments/set" \
#   -H "Content-Type: application/json" \
#   -d '{
#     "commands": [
#       {"path": "~/Warehouse", "itemPrimaryId": "WIDGET-A", "assignmentKind": "reserved", "assignmentPrimaryId": "ORDER-001", "amount": -2, "amountType": "delta"},
#       {"path": "~/Warehouse", "itemPrimaryId": "WIDGET-A", "assignmentKind": "stock", "amount": 2, "amountType": "delta"},
#       {"path": "~/Warehouse", "itemPrimaryId": "WIDGET-B", "assignmentKind": "reserved", "assignmentPrimaryId": "ORDER-001", "amount": -1, "amountType": "delta"},
#       {"path": "~/Warehouse", "itemPrimaryId": "WIDGET-B", "assignmentKind": "stock", "amount": 1, "amountType": "delta"}
#     ],
#     "assignPolicy": "allOrNothing"
#   }'
```

## Part 2: Multi-Location Commands

```bash
# Step 1: Setup multi-location structure
curl -X POST "$API_ROOT/api/locations" \
  -H "Content-Type: application/json" \
  -d '{"parentFullPath": "~", "primaryName": "WH-East"}'

curl -X POST "$API_ROOT/api/locations" \
  -H "Content-Type: application/json" \
  -d '{"parentFullPath": "~/WH-East", "primaryName": "Shelf-1"}'

curl -X POST "$API_ROOT/api/locations" \
  -H "Content-Type: application/json" \
  -d '{"parentFullPath": "~/WH-East", "primaryName": "Shelf-2"}'

curl -X POST "$API_ROOT/api/locations" \
  -H "Content-Type: application/json" \
  -d '{"parentFullPath": "~", "primaryName": "WH-West"}'

curl -X POST "$API_ROOT/api/locations" \
  -H "Content-Type: application/json" \
  -d '{"parentFullPath": "~/WH-West", "primaryName": "Shelf-1"}'

curl -X POST "$API_ROOT/api/inventoryitems" \
  -H "Content-Type: application/json" \
  -d '{"PrimaryId": "WIDGET-A"}'

# Step 2: Receive stock with different SortKeys
curl -X POST "$API_ROOT/api/assignments/set" \
  -H "Content-Type: application/json" \
  -d '{
    "commands": [
      {"path": "~/WH-East/Shelf-1", "itemPrimaryId": "WIDGET-A", "assignmentKind": "stock", "sortKey": 100, "amount": 10, "amountType": "absolute"},
      {"path": "~/WH-East/Shelf-2", "itemPrimaryId": "WIDGET-A", "assignmentKind": "stock", "sortKey": 200, "amount": 15, "amountType": "absolute"},
      {"path": "~/WH-West/Shelf-1", "itemPrimaryId": "WIDGET-A", "assignmentKind": "stock", "sortKey": 150, "amount": 8, "amountType": "absolute"}
    ],
    "assignPolicy": "allOrNothing"
  }' | jq .

# Step 3: Check total inventory by warehouse
curl -X POST "$API_ROOT/api/assignments/total" \
  -H "Content-Type: application/json" \
  -d '{"rootPath": "~/WH-East"}'

curl -X POST "$API_ROOT/api/assignments/total" \
  -H "Content-Type: application/json" \
  -d '{"rootPath": "~/WH-West"}'

# Step 4: Reserve using change - automatic location selection
curl -X POST "$API_ROOT/api/assignments/change" \
  -H "Content-Type: application/json" \
  -d '{
    "commands": [
      {"rootLocation": "~/WH-East", "itemPrimaryId": "WIDGET-A", "sourceKind": "stock", "destinationKind": "reserved", "destinationPrimaryId": "ORDER-002", "totalAmount": 12}
    ],
    "assignPolicy": "allOrNothing"
  }' | jq .

# Step 5: Second order - insufficient inventory (will fail)
curl -X POST "$API_ROOT/api/assignments/change" \
  -H "Content-Type: application/json" \
  -d '{
    "commands": [
      {"rootLocation": "~/WH-East", "itemPrimaryId": "WIDGET-A", "sourceKind": "stock", "destinationKind": "reserved", "destinationPrimaryId": "ORDER-003", "totalAmount": 20}
    ],
    "assignPolicy": "allOrNothing"
  }' | jq .

# Step 6: Reserve from different warehouse
curl -X POST "$API_ROOT/api/assignments/change" \
  -H "Content-Type: application/json" \
  -d '{
    "commands": [
      {"rootLocation": "~/WH-West", "itemPrimaryId": "WIDGET-A", "sourceKind": "stock", "destinationKind": "reserved", "destinationPrimaryId": "ORDER-003", "totalAmount": 5}
    ],
    "assignPolicy": "allOrNothing"
  }' | jq .

# Step 7: Payment success - move to packing
curl -X POST "$API_ROOT/api/assignments/change" \
  -H "Content-Type: application/json" \
  -d '{
    "commands": [
      {"rootLocation": "~/WH-East", "itemPrimaryId": "WIDGET-A", "sourceKind": "reserved", "sourcePrimaryId": "ORDER-002", "destinationKind": "packing", "destinationPrimaryId": "ORDER-002", "totalAmount": 12}
    ],
    "assignPolicy": "allOrNothing"
  }' | jq .

# Step 8: Payment failure - release reservation
curl -X POST "$API_ROOT/api/assignments/change" \
  -H "Content-Type: application/json" \
  -d '{
    "commands": [
      {"rootLocation": "~/WH-West", "itemPrimaryId": "WIDGET-A", "sourceKind": "reserved", "sourcePrimaryId": "ORDER-003", "destinationKind": "stock", "totalAmount": 5}
    ],
    "assignPolicy": "allOrNothing"
  }' | jq .

# Step 9: View detailed inventory state
curl -X POST "$API_ROOT/api/assignments/detailed" \
  -H "Content-Type: application/json" \
  -d '{"rootPath": "~"}'
```
