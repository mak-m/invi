# Business Case: Tracking Batches for Recalls

## Overview
Many products are made or received in batches (also called "lots"). A **batch** is a group of items produced or received together — for example, all the milk bottled on the same day, or all the pills made from the same ingredient mix.

If something goes wrong with one batch, companies must quickly find where those items went. This is especially important for food, medicine, and anything that could harm people.

## The Problem
When a defect or contamination is found, you need to answer two questions fast:
1. Which products are affected?
2. Who received them?
If you can’t answer quickly, recalls become bigger, more expensive, and more dangerous.

### How It Works (Simple View)
1. Give each batch a clear ID when it arrives or is made.
2. Keep items from the same batch together when possible.
3. Record which batch goes into which product.
4. Record which batch goes out to which customer.

### What Can Get Complicated
- One batch may be split across multiple locations.
- One product may contain materials from several batches.
- A batch may be moved between warehouses.

### Why This Is Important
- You must know exactly where affected products went.
- You must know which supplier batch caused the problem.
- If this is wrong, people can get hurt and recalls become much larger.

### Common Challenges
- Tracking a batch through many steps of production.
- Finding answers fast during a recall.
- Making sure expired or rejected batches are never shipped.

### Real-World Scenario
A food company finds contamination in one ingredient batch:
1. Find every product made with that batch.
2. Find every customer who received those products.
3. Recall only those items (not everything).

---

## Working Example

See [Lot Tracking and Recall with INVI API](example-lot-tracking-recalls.md) for a complete, executable example showing how to:
- Track inventory by batch ID throughout the supply chain
- Record which ingredient batches are consumed in production (manual batch selection)
- Record which finished product batches are shipped to which customers
- Perform recall tracing when a defect is discovered using transaction history
- Use GroupId to link ingredient batches to finished product batches

**Note**: This approach uses `assignmentPrimaryId` for batch tracking with **explicit batch selection**. For workflows requiring automatic batch selection (FIFO/FEFO), use `sortKey` instead of `primaryId` for batch prioritization.

