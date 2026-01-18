# Example: Lot Tracking and Recall with INVI

This example shows how to track batches through production and perform a recall trace using the INVI API.

> **API Compatibility**: INVI API v0.2+
> **Last Updated**: 2026-02-02

---

## When This Approach Works

This example uses `assignmentPrimaryId` to store batch IDs. **This works when**:
- You **manually select** which specific batch to consume in production
- You track batch consumption via transaction history (`/api/inventoryhistory`) and `groupId`
- You use `/api/assignments/set` with explicit batch primaryIds

**This approach does NOT work for**:
- Automatic batch selection (FIFO/FEFO) using `/api/assignments/change` endpoint
- When you want to consume "any available batch" without specifying which one

**For automatic batch selection**, use `sortKey` to prioritize batches (lower sortKey = consumed first) and keep `assignmentPrimaryId: null` for stock.

---

## Scenario

- **Product**: Packaged Salad
- **Ingredients**: Lettuce, Tomatoes, Dressing
- **Batches**: 
  - BATCH_LETTUCE-2024-A (defective - will be recalled)
  - BATCH_LETTUCE-2024-B (good)
  - BATCH_TOMATO-501
  - BATCH_DRESSING-300
- **Finished Product Batches**: BATCH_SALAD-1001, BATCH_SALAD-1002
- **Customers**: CUST-001, CUST-002, CUST-003

---

## Workflow Explanation

### Step 1: Create Location
Set up a processing facility location where all production happens.

### Step 2: Create Inventory Items
Register the items we'll track: LETTUCE, TOMATO, DRESSING (ingredients), and SALAD (finished product).

### Step 3: Receive Ingredient Batches
Receive ingredients from suppliers, each with a batch ID stored in `assignmentPrimaryId`:
- 100 units of LETTUCE batch A
- 100 units of LETTUCE batch B  
- 150 units of TOMATO
- 80 units of DRESSING

### Step 4: Produce Salad Batch 1001 (Using Defective Lettuce)
Create 50 salads using specific ingredient batches. The key here is **BATCH_LETTUCE-2024-A** is used — this batch will later be found defective.

All changes in this transaction share the same `groupId`, linking:
- Consumption of 50 lettuce (batch A)
- Consumption of 50 tomatoes
- Consumption of 50 dressing
- Creation of 50 salads (batch 1001)

### Step 5: Produce Salad Batch 1002 (Using Good Lettuce)
Create another 50 salads using **BATCH_LETTUCE-2024-B** (good batch). This batch is unaffected by the recall.

### Step 6: Ship to Customers
Ship finished salads to different customers:
- CUST-001 receives 20 salads from batch 1001 (defective)
- CUST-002 receives 10 salads from batch 1001 (defective)
- CUST-003 receives 40 salads from batch 1002 (good)

### Step 7: RECALL - Trace Defective Batch
When a defect is discovered in BATCH_LETTUCE-2024-A:

1. Query history for LETTUCE to find when batch A was consumed
2. Get the `groupId` from that consumption event
3. Find which SALAD batch was created in the same transaction (same groupId)
4. Find which customers received that salad batch

**Result**: Only CUST-001 and CUST-002 need to be contacted. CUST-003 is safe.

### Step 8: Verify Good Batches
Confirm CUST-003 only received products from BATCH_SALAD-1002, which used good ingredients.

---

## Expected Results

### Traceability Chain
- **Forward trace**: BATCH_LETTUCE-2024-A → BATCH_SALAD-1001 → CUST-001, CUST-002
- **Backward trace**: CUST-001 shipment → BATCH_SALAD-1001 → BATCH_LETTUCE-2024-A

### Precision Recall
- Only 30 units need recall (20 from CUST-001, 10 from CUST-002)
- 40 units at CUST-003 are confirmed good
- Minimizes recall scope and cost

---

## Complete Runnable Script

Copy and run this entire block:

```bash
#!/bin/bash

# Setup
API_ROOT="${API_ROOT:-http://localhost:5279}"

echo "=== Step 1: Create Location ==="
curl -X POST "$API_ROOT/api/locations" \
  -H "Content-Type: application/json" \
  -d '{
    "parentFullPath": "~",
    "primaryName": "ProcessingFacility"
  }'

echo -e "\n\n=== Step 2: Create Inventory Items ==="
curl -X POST "$API_ROOT/api/inventoryitems" \
  -H "Content-Type: application/json" \
  -d '{"PrimaryId": "LETTUCE"}'

curl -X POST "$API_ROOT/api/inventoryitems" \
  -H "Content-Type: application/json" \
  -d '{"PrimaryId": "TOMATO"}'

curl -X POST "$API_ROOT/api/inventoryitems" \
  -H "Content-Type: application/json" \
  -d '{"PrimaryId": "DRESSING"}'

curl -X POST "$API_ROOT/api/inventoryitems" \
  -H "Content-Type: application/json" \
  -d '{"PrimaryId": "SALAD"}'

echo -e "\n\n=== Step 3: Receive Ingredient Batches ==="
curl -X POST "$API_ROOT/api/assignments/set" \
  -H "Content-Type: application/json" \
  -d '{
    "commands": [
      {
        "path": "~/ProcessingFacility",
        "itemPrimaryId": "LETTUCE",
        "assignmentKind": "stock",
        "assignmentPrimaryId": "BATCH_LETTUCE-2024-A",
        "amount": 100,
        "amountType": "absolute"
      },
      {
        "path": "~/ProcessingFacility",
        "itemPrimaryId": "LETTUCE",
        "assignmentKind": "stock",
        "assignmentPrimaryId": "BATCH_LETTUCE-2024-B",
        "amount": 100,
        "amountType": "absolute"
      },
      {
        "path": "~/ProcessingFacility",
        "itemPrimaryId": "TOMATO",
        "assignmentKind": "stock",
        "assignmentPrimaryId": "BATCH_TOMATO-501",
        "amount": 150,
        "amountType": "absolute"
      },
      {
        "path": "~/ProcessingFacility",
        "itemPrimaryId": "DRESSING",
        "assignmentKind": "stock",
        "assignmentPrimaryId": "BATCH_DRESSING-300",
        "amount": 80,
        "amountType": "absolute"
      }
    ],
    "assignPolicy": "allOrNothing"
  }'

echo -e "\n\n=== Step 4: Produce Salad Batch 1001 (Using Defective Lettuce) ==="
curl -X POST "$API_ROOT/api/assignments/set" \
  -H "Content-Type: application/json" \
  -d '{
    "commands": [
      {
        "path": "~/ProcessingFacility",
        "itemPrimaryId": "LETTUCE",
        "assignmentKind": "stock",
        "assignmentPrimaryId": "BATCH_LETTUCE-2024-A",
        "amount": -50,
        "amountType": "delta"
      },
      {
        "path": "~/ProcessingFacility",
        "itemPrimaryId": "TOMATO",
        "assignmentKind": "stock",
        "assignmentPrimaryId": "BATCH_TOMATO-501",
        "amount": -50,
        "amountType": "delta"
      },
      {
        "path": "~/ProcessingFacility",
        "itemPrimaryId": "DRESSING",
        "assignmentKind": "stock",
        "assignmentPrimaryId": "BATCH_DRESSING-300",
        "amount": -50,
        "amountType": "delta"
      },
      {
        "path": "~/ProcessingFacility",
        "itemPrimaryId": "SALAD",
        "assignmentKind": "stock",
        "assignmentPrimaryId": "BATCH_SALAD-1001",
        "amount": 50,
        "amountType": "delta"
      }
    ],
    "assignPolicy": "allOrNothing"
  }'

echo -e "\n\n=== Step 5: Produce Salad Batch 1002 (Using Good Lettuce) ==="
curl -X POST "$API_ROOT/api/assignments/set" \
  -H "Content-Type: application/json" \
  -d '{
    "commands": [
      {
        "path": "~/ProcessingFacility",
        "itemPrimaryId": "LETTUCE",
        "assignmentKind": "stock",
        "assignmentPrimaryId": "BATCH_LETTUCE-2024-B",
        "amount": -50,
        "amountType": "delta"
      },
      {
        "path": "~/ProcessingFacility",
        "itemPrimaryId": "TOMATO",
        "assignmentKind": "stock",
        "assignmentPrimaryId": "BATCH_TOMATO-501",
        "amount": -50,
        "amountType": "delta"
      },
      {
        "path": "~/ProcessingFacility",
        "itemPrimaryId": "DRESSING",
        "assignmentKind": "stock",
        "assignmentPrimaryId": "BATCH_DRESSING-300",
        "amount": -30,
        "amountType": "delta"
      },
      {
        "path": "~/ProcessingFacility",
        "itemPrimaryId": "SALAD",
        "assignmentKind": "stock",
        "assignmentPrimaryId": "BATCH_SALAD-1002",
        "amount": 50,
        "amountType": "delta"
      }
    ],
    "assignPolicy": "allOrNothing"
  }'

echo -e "\n\n=== Step 6: Ship to Customers ==="
# Ship BATCH_SALAD-1001 (defective) to CUST-001 and CUST-002
curl -X POST "$API_ROOT/api/assignments/set" \
  -H "Content-Type: application/json" \
  -d '{
    "commands": [
      {
        "path": "~/ProcessingFacility",
        "itemPrimaryId": "SALAD",
        "assignmentKind": "stock",
        "assignmentPrimaryId": "BATCH_SALAD-1001",
        "amount": -30,
        "amountType": "delta"
      },
      {
        "path": "~/ProcessingFacility",
        "itemPrimaryId": "SALAD",
        "assignmentKind": "shipped",
        "assignmentPrimaryId": "CUST-001",
        "amount": 20,
        "amountType": "delta"
      },
      {
        "path": "~/ProcessingFacility",
        "itemPrimaryId": "SALAD",
        "assignmentKind": "shipped",
        "assignmentPrimaryId": "CUST-002",
        "amount": 10,
        "amountType": "delta"
      }
    ],
    "assignPolicy": "allOrNothing"
  }'

# Ship BATCH_SALAD-1002 (good) to CUST-003
curl -X POST "$API_ROOT/api/assignments/set" \
  -H "Content-Type: application/json" \
  -d '{
    "commands": [
      {
        "path": "~/ProcessingFacility",
        "itemPrimaryId": "SALAD",
        "assignmentKind": "stock",
        "assignmentPrimaryId": "BATCH_SALAD-1002",
        "amount": -40,
        "amountType": "delta"
      },
      {
        "path": "~/ProcessingFacility",
        "itemPrimaryId": "SALAD",
        "assignmentKind": "shipped",
        "assignmentPrimaryId": "CUST-003",
        "amount": 40,
        "amountType": "delta"
      }
    ],
    "assignPolicy": "allOrNothing"
  }'

echo -e "\n\n=== Step 7: RECALL - Trace Defective Batch ==="
FROM=$(date -u -v-1H '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -d '1 hour ago' '+%Y-%m-%dT%H:%M:%SZ')
TO=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

echo "Finding when defective lettuce was consumed..."
curl -s -X GET "$API_ROOT/api/inventoryhistory?from=$FROM&to=$TO&itemId=LETTUCE" | jq '.events[] | select(.assignmentPrimaryId == "BATCH_LETTUCE-2024-A")'

echo -e "\n\nGetting GroupId from consumption event..."
GROUP_ID=$(curl -s -X GET "$API_ROOT/api/inventoryhistory?from=$FROM&to=$TO&itemId=LETTUCE" \
  | jq -r '.events[] | select(.assignmentPrimaryId == "BATCH_LETTUCE-2024-A" and .amountAfter < .amountBefore) | .groupId' \
  | head -1)

echo "Production transaction GroupId: $GROUP_ID"

echo -e "\n\nFinding which salad batch was created with defective lettuce..."
curl -s -X GET "$API_ROOT/api/inventoryhistory?from=$FROM&to=$TO&itemId=SALAD" \
  | jq ".events[] | select(.groupId == \"$GROUP_ID\")"

echo -e "\n\nFinding customers who received defective batch..."
AFFECTED_BATCH=$(curl -s -X GET "$API_ROOT/api/inventoryhistory?from=$FROM&to=$TO&itemId=SALAD" \
  | jq -r ".events[] | select(.groupId == \"$GROUP_ID\" and .itemPrimaryId == \"SALAD\") | .assignmentPrimaryId" \
  | head -1)

echo "Defective finished product batch: $AFFECTED_BATCH"
echo -e "\nCustomers who received $AFFECTED_BATCH:"
curl -s -X GET "$API_ROOT/api/inventoryhistory?from=$FROM&to=$TO&itemId=SALAD" \
  | jq ".events[] | select(.assignmentKind == \"shipped\")"

echo -e "\n\n=== Step 8: Verify Good Batches ==="
echo "Customers who received UNAFFECTED batch BATCH_SALAD-1002:"
curl -s -X GET "$API_ROOT/api/inventoryhistory?from=$FROM&to=$TO&itemId=SALAD" \
  | jq '.events[] | select(.assignmentPrimaryId == "BATCH_SALAD-1002" or .assignmentPrimaryId == "CUST-003")'

echo -e "\n\n=== Script Complete ==="
```
