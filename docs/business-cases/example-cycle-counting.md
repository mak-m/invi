# Example: Cycle Counting with INVI

This example shows how to perform cycle counts to maintain inventory accuracy using the INVI API.

> **API Compatibility**: INVI API v0.2+
> **Last Updated**: 2026-02-02

---

## Scenario

- **Warehouse**: Distribution center with multiple aisles
- **Items**: Electronics inventory (LAPTOP, MONITOR, KEYBOARD)
- **Assignments**: Stock and reserved inventory with different priorities (sortKeys)
- **Process**: Daily cycle counts to verify accuracy

---

## Workflow Explanation

### Step 1: Create Locations
Set up a warehouse with two aisles (Aisle-1 and Aisle-2) for organizing inventory.

### Step 2: Create Inventory Items
Register three products: LAPTOP, MONITOR, and KEYBOARD.

### Step 3: Set Up Initial Inventory
Create inventory with different assignment kinds and **sortKeys** (priority levels):

**Aisle-1 (Laptops):**
- 50 units in stock (sortKey: 10 - medium priority)
- 10 units reserved for ORDER-001 (sortKey: 5 - high priority, protected)
- 3 units damaged (sortKey: 100 - low priority, reduced first)

**Aisle-2:**
- 75 monitors in stock
- 120 keyboards in stock

**Why sortKey matters**: When auto-resolving shortages, INVI reduces assignments with the **highest sortKey first** (lowest priority). This protects important inventory like reserved orders.

### Step 4: Scenario 1 - Exact Match (No Discrepancy)
Worker counts keyboards in Aisle-2 and finds exactly 120 units.

**Expected result**: `"status": "NoDiscrepancy"` - physical count matches system total.

### Step 5: Scenario 2 - Shortage with Auto-Resolution
Worker counts laptops in Aisle-1 and finds only 58 units.

**System expects**: 63 total (50 stock + 10 reserved + 3 damaged)
**Shortage**: 5 units missing

**With `allowAutoResolution: true`**, INVI automatically reduces lowest-priority inventory first:
1. First reduces "damaged" (sortKey 100): 3 → 0 (removes 3 units)
2. Then reduces "stock" (sortKey 10): 50 → 48 (removes 2 units)
3. **"reserved" (sortKey 5) is NOT touched** - highest priority protected

**Result**: `"status": "DiscrepancyResolved"` with details of what changed.

### Step 6: Scenario 3 - Surplus (Requires Manual Resolution)
Worker counts monitors in Aisle-2 and finds 80 units (system expects only 75).

**Surplus of 5 units** - INVI does NOT auto-adjust because:
- You need to decide: Should this increase "stock"? "quarantine"? "damaged"?
- Could indicate a receiving error, mis-delivery, or incorrect theft record
- Better to investigate than assume

**Result**: `"status": "ManualResolutionRequired"` with current assignments listed.

### Step 7: Scenario 4 - Shortage Without Auto-Resolution
Same shortage as Step 5, but with `allowAutoResolution: false`.

**Use case**: High-value items where you want human review of all discrepancies.

**Result**: `"status": "ManualResolutionRequired"` - system reports the discrepancy but makes no changes.

### Step 8: Manually Resolve Surplus
After investigating the monitor surplus (determined to be unscanned receiving), manually add 5 units to stock using `/api/assignments/set`.

Then verify with another cycle count - should now show `"NoDiscrepancy"`.

---

## Expected Results

### Auto-Resolution Priority Order
When resolving shortages, INVI reduces assignments in this order:
1. Highest sortKey first (lowest priority inventory)
2. Protects low sortKey assignments (high priority like reservations)

### When Manual Resolution Is Required
- **Surpluses**: Always require investigation
- **Shortages with `allowAutoResolution: false`**: For human review
- **Large discrepancies**: Consider investigating before accepting auto-resolution

---

## Best Practices

### SortKey Strategy
Set sortKeys to reflect priority:
- **Low sortKey (0-20)**: Reserved orders, critical stock - protected during auto-resolution
- **Medium sortKey (20-50)**: General stock
- **High sortKey (50-100+)**: Damaged, quarantine, low-priority - reduced first

### When to Use Auto-Resolution
- **Enable** for: Low-value items, expected shrinkage scenarios
- **Disable** for: High-value items, when you want full audit trail

### Count Frequency
- **Daily**: Fast-moving, high-value items
- **Weekly**: Medium movers
- **Monthly**: Slow movers, low-value items

---

## Complete Runnable Script

Copy and run this entire block:

```bash
#!/bin/bash

# Setup
API_ROOT="${API_ROOT:-http://localhost:5279}"

echo "=== Step 1: Create Locations ==="
curl -X POST "$API_ROOT/api/locations" \
  -H "Content-Type: application/json" \
  -d '{
    "parentFullPath": "~",
    "primaryName": "Warehouse"
  }'

curl -X POST "$API_ROOT/api/locations" \
  -H "Content-Type: application/json" \
  -d '{
    "parentFullPath": "~/Warehouse",
    "primaryName": "Aisle-1"
  }'

curl -X POST "$API_ROOT/api/locations" \
  -H "Content-Type: application/json" \
  -d '{
    "parentFullPath": "~/Warehouse",
    "primaryName": "Aisle-2"
  }'

echo -e "\n\n=== Step 2: Create Inventory Items ==="
curl -X POST "$API_ROOT/api/inventoryitems" \
  -H "Content-Type: application/json" \
  -d '{"PrimaryId": "LAPTOP"}'

curl -X POST "$API_ROOT/api/inventoryitems" \
  -H "Content-Type: application/json" \
  -d '{"PrimaryId": "MONITOR"}'

curl -X POST "$API_ROOT/api/inventoryitems" \
  -H "Content-Type: application/json" \
  -d '{"PrimaryId": "KEYBOARD"}'

echo -e "\n\n=== Step 3: Set Up Initial Inventory ==="
# Aisle-1: Laptops with stock, reserved, and damaged assignments
curl -X POST "$API_ROOT/api/assignments/set" \
  -H "Content-Type: application/json" \
  -d '{
    "commands": [
      {
        "path": "~/Warehouse/Aisle-1",
        "itemPrimaryId": "LAPTOP",
        "assignmentKind": "stock",
        "assignmentPrimaryId": null,
        "sortKey": 10,
        "amount": 50,
        "amountType": "absolute"
      },
      {
        "path": "~/Warehouse/Aisle-1",
        "itemPrimaryId": "LAPTOP",
        "assignmentKind": "reserved",
        "assignmentPrimaryId": "ORDER-001",
        "sortKey": 5,
        "amount": 10,
        "amountType": "absolute"
      },
      {
        "path": "~/Warehouse/Aisle-1",
        "itemPrimaryId": "LAPTOP",
        "assignmentKind": "damaged",
        "assignmentPrimaryId": null,
        "sortKey": 100,
        "amount": 3,
        "amountType": "absolute"
      }
    ]
  }'

# Aisle-2: Monitors and keyboards
curl -X POST "$API_ROOT/api/assignments/set" \
  -H "Content-Type: application/json" \
  -d '{
    "commands": [
      {
        "path": "~/Warehouse/Aisle-2",
        "itemPrimaryId": "MONITOR",
        "assignmentKind": "stock",
        "assignmentPrimaryId": null,
        "sortKey": 10,
        "amount": 75,
        "amountType": "absolute"
      },
      {
        "path": "~/Warehouse/Aisle-2",
        "itemPrimaryId": "KEYBOARD",
        "assignmentKind": "stock",
        "assignmentPrimaryId": null,
        "sortKey": 10,
        "amount": 120,
        "amountType": "absolute"
      }
    ]
  }'

echo -e "\n\n=== Step 4: Scenario 1 - Exact Match (No Discrepancy) ==="
echo "Counting keyboards in Aisle-2: physical count = 120"
curl -X POST "$API_ROOT/api/assignments/cycle-count" \
  -H "Content-Type: application/json" \
  -d '{
    "locationPath": "~/Warehouse/Aisle-2",
    "itemPrimaryId": "KEYBOARD",
    "physicalCount": 120,
    "allowAutoResolution": true
  }' | jq .

echo -e "\n\n=== Step 5: Scenario 2 - Shortage with Auto-Resolution ==="
echo "Counting laptops in Aisle-1: physical count = 58 (system expects 63)"
curl -X POST "$API_ROOT/api/assignments/cycle-count" \
  -H "Content-Type: application/json" \
  -d '{
    "locationPath": "~/Warehouse/Aisle-1",
    "itemPrimaryId": "LAPTOP",
    "physicalCount": 58,
    "allowAutoResolution": true
  }' | jq .

echo -e "\n\n=== Step 6: Scenario 3 - Surplus (Requires Manual Resolution) ==="
echo "Counting monitors in Aisle-2: physical count = 80 (system expects 75)"
curl -X POST "$API_ROOT/api/assignments/cycle-count" \
  -H "Content-Type: application/json" \
  -d '{
    "locationPath": "~/Warehouse/Aisle-2",
    "itemPrimaryId": "MONITOR",
    "physicalCount": 80,
    "allowAutoResolution": true
  }' | jq .

echo -e "\n\n=== Step 7: Scenario 4 - Shortage Without Auto-Resolution ==="
echo "Re-checking laptops with auto-resolution disabled..."
echo "(Note: After Step 5, laptop total is now 58, so this should show NoDiscrepancy)"
curl -X POST "$API_ROOT/api/assignments/cycle-count" \
  -H "Content-Type: application/json" \
  -d '{
    "locationPath": "~/Warehouse/Aisle-1",
    "itemPrimaryId": "LAPTOP",
    "physicalCount": 55,
    "allowAutoResolution": false
  }' | jq .

echo -e "\n\n=== Step 8: Manually Resolve Surplus ==="
echo "Adding 5 monitors to match physical count of 80..."
curl -X POST "$API_ROOT/api/assignments/set" \
  -H "Content-Type: application/json" \
  -d '{
    "commands": [
      {
        "path": "~/Warehouse/Aisle-2",
        "itemPrimaryId": "MONITOR",
        "assignmentKind": "stock",
        "assignmentPrimaryId": null,
        "amount": 5,
        "amountType": "delta"
      }
    ]
  }'

echo -e "\n\nVerifying with another cycle count..."
curl -X POST "$API_ROOT/api/assignments/cycle-count" \
  -H "Content-Type: application/json" \
  -d '{
    "locationPath": "~/Warehouse/Aisle-2",
    "itemPrimaryId": "MONITOR",
    "physicalCount": 80,
    "allowAutoResolution": true
  }' | jq .

echo -e "\n\n=== Final Inventory State ==="
curl -X POST "$API_ROOT/api/assignments/detailed" \
  -H "Content-Type: application/json" \
  -d '{"rootPath": "~/Warehouse"}' | jq .

echo -e "\n\n=== Script Complete ==="
```
