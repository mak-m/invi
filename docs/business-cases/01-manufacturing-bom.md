# Business Case: Manufacturing from Parts

## Overview
When you build products from parts, you must keep track of every part you use and every product you make. If you lose track, you either run out of parts or think you have finished goods that don’t actually exist.

## The Problem
Products often have layers: a finished product is made from sub‑assemblies, and those sub‑assemblies are made from smaller parts. Keeping accurate counts across all these layers is hard but essential.

### How It Works (Simple View)
1. Decide what to build (e.g., 10 bikes).
2. Figure out the parts needed (e.g., 20 wheels, 10 frames).
3. Set those parts aside so other orders don’t use them.
4. Build the product and reduce the parts used.
5. Add the finished products to inventory.

### Why This Is Important
- If the parts are not accounted for correctly, production stops or products get lost.
- If counts are wrong, you might either under‑promise or delay orders.
- A reliable record of which parts went into which products is important. In case of defects such records allow to narrow down the amount of defective products to recall.

### Common Challenges
- Tracking which parts are available, which are reserved for orders, and which are already used.
- Recording exactly when parts are consumed and when finished products are created.
- Maintaining accurate counts when a single product requires many different parts.
- Keeping a history of what parts went into each finished product for traceability.

---

## Working Example

See [Bicycle Manufacturing with INVI API](example-bicycle-manufacturing.md) for a complete, executable example showing how to:
- Receive parts and track them by batch
- Reserve materials for production orders
- Consume parts and produce finished goods atomically
- Query current inventory state
- Trace which specific batches of parts went into which finished products using history and GroupId

