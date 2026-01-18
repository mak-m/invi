# Business Case: Inventory Accuracy and Cycle Counting

## Overview
Your warehouse management system shows 100 units on the shelf, but when someone physically counts them, there are only 92. This discrepancy happens constantly due to theft, damage, miscounts during receiving, or picking errors. If you don't catch these errors, you'll oversell products, disappoint customers, and lose trust in your inventory data.

## The Problem
Inventory systems track what *should* be there based on transactions. But reality doesn't always match:
- Items get damaged and discarded without updating the system
- Theft (internal or external) reduces physical inventory
- Receiving errors: system says 100 arrived, but only 95 were actually delivered
- Picking errors: worker takes 5 but scans 3
- Location mistakes: items are in the wrong place so they can't be found

When the numbers don't match, you face serious consequences:
1. **Overselling**: Your system says you have 10 units, you sell them all, but you actually only have 8
2. **Operational chaos**: Workers can't find products because they're not where the system says
3. **Lost trust**: If the numbers are wrong often enough, nobody believes the system anymore

## The Solution: Cycle Counting

Instead of shutting down your entire warehouse once a year for a "full physical inventory," you count a small section every day. Over time, you count everything, but without stopping operations.

### How It Works
1. **Count a location**: A worker physically counts one item at one location
2. **Compare to system**: The system calculates what *should* be there based on all assignments
3. **Handle discrepancies**:
   - **Match**: No action needed
   - **Shortage (fewer than expected)**: Reduce assignments to match reality
   - **Surplus (more than expected)**: Investigate and manually adjust

### Why This Matters
- **Continuous accuracy**: Keep inventory data reliable without shutting down
- **Root cause analysis**: Frequent counts help identify patterns (e.g., "aisle 5 always has shortages")
- **Prevent overselling**: Catch discrepancies before they cause customer problems
- **Trust in the system**: When counts match regularly, people believe the data

## How INVI Helps

### Cycle Count Operation
INVI provides a dedicated `/api/assignments/cycle-count` endpoint that:
- Calculates total inventory at a location (across all assignment kinds)
- Compares it to your physical count
- **Auto-resolves shortages**: Automatically reduces low-priority assignments first (highest sortKey)
- **Flags surpluses**: Requires manual investigation when you find more than expected

### Smart Auto-Resolution for Shortages
When auto-resolution is enabled and there's a shortage:
1. INVI reduces assignments starting with the **highest sortKey** (lowest priority)
2. If the shortage is larger than one assignment, it continues to the next highest sortKey
3. This ensures you don't accidentally reduce reserved/critical inventory

### Manual Resolution for Surpluses
When you find more inventory than expected, INVI requires manual investigation because:
- You need to determine which assignment kind to increase (stock? damaged? quarantine?)
- Unexpected surplus could indicate theft was recorded but didn't happen, or mis-delivery
- Better to investigate than to make assumptions

## Common Challenges

### 1. Which items to count?
**ABC Analysis**: Count high-value or fast-moving items more frequently than slow movers.

### 2. What if counts never match?
This indicates systematic problems:
- Poor receiving procedures
- Inadequate training
- Theft
- Items stored in wrong locations

Fix the root cause, not just the symptoms.

### 3. Should we stop operations to count?
No! That's the point of cycle counting. Count during slow periods or off-hours, but don't stop.

## Real-World Scenario

A distribution center counts 25-50 locations daily:
- **Monday**: Count aisle 1, shelves 1-5
- **Tuesday**: Count aisle 1, shelves 6-10
- System tracks: "Aisle 1 shelf 3 has discrepancies 3 weeks in a row"
- Investigation reveals: Workers often grab from shelf 3 but scan shelf 4's barcode
- **Fix the process**: Improve signage, retrain workers
- **Result**: Inventory accuracy improves from 85% to 98%

---

## Working Example

See [Cycle Counting with INVI API](example-cycle-counting.md) for a complete, executable example showing how to:
- Set up inventory across multiple locations
- Perform cycle counts at specific locations
- Handle exact matches (no discrepancy)
- Auto-resolve shortages by reducing low-priority assignments
- Handle surpluses that require manual resolution
- Track accuracy trends over time

