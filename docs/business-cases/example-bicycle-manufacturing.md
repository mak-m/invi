# Example: Bicycle Manufacturing with INVI

This example shows how to track inventory through a bicycle production process using the INVI API.

> **API Compatibility**: INVI API v0.2+
> **Last Updated**: 2026-02-02

## Scenario Overview

- **Product**: Bicycle
- **Parts**: Frames and Wheels  
- **Recipe**: 1 bicycle needs 1 frame + 2 wheels
- **Production Order**: ORDER_PROD-2001
- **Process**: Receive parts → Reserve for production → Consume parts and produce bicycles
- **Note**: This example focuses on order-based reservation. For batch tracking examples, see [Lot Tracking and Recall](example-lot-tracking-recalls.md)

## What This Example Demonstrates

### 1. Tracking Inventory States
- **Stock**: Available inventory (`assignmentKind: "stock"`)
- **Reserved**: Parts allocated to a specific production order (`assignmentKind: "reserved", assignmentPrimaryId: "ORDER_PROD-2001"`)
- Each state change is recorded explicitly with complete audit trail

### 2. Atomic Multi-Command Transactions
**All commands in a single request execute together or fail together**, preventing:
- Partial updates (receiving frames but not wheels)
- Race conditions (two orders reserving the same inventory simultaneously)
- Inventory inconsistencies

**Examples in this workflow**:
- **Step 3**: Receive 50 frames AND 120 wheels atomically - if one fails, neither is received
- **Step 4**: Reserve frames AND wheels for production - prevents incomplete production orders
- **Step 5**: Consume parts AND create bicycles simultaneously - parts disappear exactly when products appear

### 3. Production Workflow
1. **Receive parts**: 50 frames + 120 wheels arrive as general stock
2. **Reserve for production**: Allocate 20 frames + 40 wheels to ORDER_PROD-2001
3. **Consume and produce**: Use reserved parts to create 20 bicycles
4. **Final state**: 30 frames + 80 wheels remain in stock, 20 bicycles created

### 4. Traceability Through GroupId
Every transaction gets a unique `groupId` that links all related changes:
- **Production transaction**: Frame consumption + wheel consumption + bicycle creation all share one groupId
- Enables forward trace: "Which batches created this product?"
- Enables backward trace: "Where did these parts come from?"

### 5. Assignment PrimaryId Usage
- **Stock (`assignmentPrimaryId: null`)**: General available inventory (not tied to specific order/batch)
- **Reserved (`assignmentPrimaryId: "ORDER_PROD-2001"`)**: Inventory allocated to specific production order
- This identifies **why** the assignment exists (for which order)

## Expected Results

After running the complete script:

**Inventory State:**
- FRAME: 30 units in stock (50 received - 20 consumed)
- WHEEL: 80 units in stock (120 received - 40 consumed)
- BICYCLE: 20 units in stock (newly produced)

**History Shows:**
- 3 atomic transactions (each with unique groupId)
- Complete audit trail of all state transitions
- Traceability from input parts to output products

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
    "primaryName": "Warehouse"
  }'

echo -e "\n\n=== Step 2: Create Inventory Items ==="
curl -X POST "$API_ROOT/api/inventoryitems" \
  -H "Content-Type: application/json" \
  -d '{"PrimaryId": "FRAME"}'

curl -X POST "$API_ROOT/api/inventoryitems" \
  -H "Content-Type: application/json" \
  -d '{"PrimaryId": "WHEEL"}'

curl -X POST "$API_ROOT/api/inventoryitems" \
  -H "Content-Type: application/json" \
  -d '{"PrimaryId": "BICYCLE"}'

echo -e "\n\n=== Step 3: Receive Parts (Atomic Transaction) ==="
echo "Receiving 50 frames + 120 wheels together..."
curl -X POST "$API_ROOT/api/assignments/set" \
  -H "Content-Type: application/json" \
  -d '{
    "commands": [
      {
        "path": "~/Warehouse",
        "itemPrimaryId": "WHEEL",
        "assignmentKind": "stock",
        "assignmentPrimaryId": null,
        "amount": 120,
        "amountType": "absolute"
      },
      {
        "path": "~/Warehouse",
        "itemPrimaryId": "FRAME",
        "assignmentKind": "stock",
        "assignmentPrimaryId": null,
        "amount": 50,
        "amountType": "absolute"
      }
    ],
    "assignPolicy": "allOrNothing"
  }'

echo -e "\n\n=== Step 4: Reserve Parts for Production Order (Atomic Transaction) ==="
echo "Reserving 20 frames + 40 wheels for ORDER_PROD-2001..."
curl -X POST "$API_ROOT/api/assignments/set" \
  -H "Content-Type: application/json" \
  -d '{
    "commands": [
      {
        "path": "~/Warehouse",
        "itemPrimaryId": "FRAME",
        "assignmentKind": "stock",
        "assignmentPrimaryId": null,
        "amount": -20,
        "amountType": "delta"
      },
      {
        "path": "~/Warehouse",
        "itemPrimaryId": "FRAME",
        "assignmentKind": "reserved",
        "assignmentPrimaryId": "ORDER_PROD-2001",
        "amount": 20,
        "amountType": "delta"
      },
      {
        "path": "~/Warehouse",
        "itemPrimaryId": "WHEEL",
        "assignmentKind": "stock",
        "assignmentPrimaryId": null,
        "amount": -40,
        "amountType": "delta"
      },
      {
        "path": "~/Warehouse",
        "itemPrimaryId": "WHEEL",
        "assignmentKind": "reserved",
        "assignmentPrimaryId": "ORDER_PROD-2001",
        "amount": 40,
        "amountType": "delta"
      }
    ],
    "assignPolicy": "allOrNothing"
  }'

echo -e "\n\n=== Step 5: Consume Parts and Produce Bicycles (Atomic Transaction) ==="
echo "Consuming reserved parts and creating 20 bicycles..."
curl -X POST "$API_ROOT/api/assignments/set" \
  -H "Content-Type: application/json" \
  -d '{
    "commands": [
      {
        "path": "~/Warehouse",
        "itemPrimaryId": "FRAME",
        "assignmentKind": "reserved",
        "assignmentPrimaryId": "ORDER_PROD-2001",
        "amount": -20,
        "amountType": "delta"
      },
      {
        "path": "~/Warehouse",
        "itemPrimaryId": "WHEEL",
        "assignmentKind": "reserved",
        "assignmentPrimaryId": "ORDER_PROD-2001",
        "amount": -40,
        "amountType": "delta"
      },
      {
        "path": "~/Warehouse",
        "itemPrimaryId": "BICYCLE",
        "assignmentKind": "stock",
        "assignmentPrimaryId": null,
        "amount": 20,
        "amountType": "delta"
      }
    ],
    "assignPolicy": "allOrNothing"
  }'

echo -e "\n\n=== Step 6: Check Current Inventory State ==="
echo "Total inventory across warehouse:"
curl -X POST "$API_ROOT/api/assignments/total" \
  -H "Content-Type: application/json" \
  -d '{
    "rootPath": "~/Warehouse"
  }' | jq .

echo -e "\n\nDetailed inventory by location:"
curl -X POST "$API_ROOT/api/assignments/detailed" \
  -H "Content-Type: application/json" \
  -d '{
    "rootPath": "~/Warehouse"
  }' | jq .

echo -e "\n\n=== Step 7: View History (Last Hour) ==="
FROM=$(date -u -v-1H '+%Y-%m-%dT%H:%M:%SZ')
TO=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

echo "History for FRAME item:"
curl -X GET "$API_ROOT/api/inventoryhistory?from=$FROM&to=$TO&itemId=FRAME" | jq .

echo -e "\n\nAll changes at Warehouse location (TSV format):"
curl -H "Accept: text/tsv" \
  -X GET "$API_ROOT/api/inventoryhistory?from=$FROM&to=$TO&locationPath=~/Warehouse" \
  | column -t -s $'\t'

echo -e "\n\n=== Script Complete ==="
```

## Understanding the Output

### Expected Inventory Total Response
```json
{
  "items": [
    {
      "itemPrimaryId": "FRAME",
      "amounts": [
        {"kind": "stock", "amount": 30}
      ]
    },
    {
      "itemPrimaryId": "WHEEL",
      "amounts": [
        {"kind": "stock", "amount": 80}
      ]
    },
    {
      "itemPrimaryId": "BICYCLE",
      "amounts": [
        {"kind": "stock", "amount": 20}
      ]
    }
  ]
}
```

### Expected History Output (TSV)
```
Timestamp            OperationName   ItemPrimaryId  LocationPath  AssignmentKind  AssignmentPrimaryId  AmountBefore  AmountAfter  GroupId
02/02/2026 12:39:32  SetAssignments  WHEEL          ~/Warehouse   stock           null                 0             120          2046534b-e621...
02/02/2026 12:39:32  SetAssignments  FRAME          ~/Warehouse   stock           null                 0             50           2046534b-e621...
02/02/2026 12:39:41  SetAssignments  FRAME          ~/Warehouse   stock           null                 50            30           4844f1a2-1a5c...
02/02/2026 12:39:41  SetAssignments  WHEEL          ~/Warehouse   stock           null                 120           80           4844f1a2-1a5c...
02/02/2026 12:39:41  SetAssignments  FRAME          ~/Warehouse   reserved        ORDER_PROD-2001      0             20           4844f1a2-1a5c...
02/02/2026 12:39:41  SetAssignments  WHEEL          ~/Warehouse   reserved        ORDER_PROD-2001      0             40           4844f1a2-1a5c...
02/02/2026 12:39:49  SetAssignments  FRAME          ~/Warehouse   reserved        ORDER_PROD-2001      20            0            da31796a-988f...
02/02/2026 12:39:49  SetAssignments  WHEEL          ~/Warehouse   reserved        ORDER_PROD-2001      40            0            da31796a-988f...
02/02/2026 12:39:49  SetAssignments  BICYCLE        ~/Warehouse   stock           null                 0             20           da31796a-988f...
```

**Key observations:**
- **GroupId `2046534b...`**: Initial receive transaction (2 events - frames and wheels received together)
- **GroupId `4844f1a2...`**: Reservation transaction (4 events - stock reduced, reserved increased for both items)
- **GroupId `da31796a...`**: Production transaction (3 events - reserved consumed, bicycles created)
- All events in each transaction share the same groupId, proving atomicity

---

## How This Solves Manufacturing Challenges

### 1. Tracking States (Available/Reserved/Consumed)
- Different `assignmentKind` values represent inventory states
- Can query current state at any moment
- Every state change is recorded with timestamp and groupId

### 2. Recording Exact Timing
- Every assignment change is automatically timestamped by INVI
- History endpoint shows when each state transition occurred
- Can audit: "When did parts move from stock → reserved → consumed?"

### 3. Maintaining Accuracy Across Complex Builds
- Each part (frames, wheels) tracked separately as different items
- Amounts always balance: 20 frames + 40 wheels consumed = 20 bicycles produced
- **Atomic transactions** ensure all related changes succeed together or fail together
- No risk of partial updates or race conditions

### 4. Traceability: Which Parts Went Into Which Products
- **GroupId** groups related changes in a single transaction
- **AssignmentPrimaryId** identifies orders (ORDER_PROD-2001)
- Together they show the transformation chain
- History queries reveal complete forward and backward traces through the supply chain
