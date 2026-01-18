# Inventory Management Business Cases

This directory contains real-world inventory management problems that businesses face every day. Each case explains the problem in plain language so anyone can understand the challenge.

## Business Cases

### [01. Manufacturing with Bill of Materials](01-manufacturing-bom.md)

When you build products from parts, you need to track which parts go into which products. If you use 100 screws to make 10 chairs, your inventory needs to show 10 more chairs and 100 fewer screws. The challenge is keeping track of everything accurately, especially when products contain sub-assemblies that themselves contain parts.

**Industries**: Manufacturing, assembly operations

---

### [02. Lot Tracking and Batch Traceability for Recalls](02-lot-tracking-recalls.md)

A **batch** (or "lot") is a group of items made or received together. When you discover a problem with one batch (like contaminated ingredients), you need to quickly find every customer who received products from that batch. You also need to trace backward to find which supplier delivered the bad materials. This is critical for food, medicine, and anything that could harm people.

**Industries**: Food & beverage, pharmaceuticals, cosmetics, medical devices

---

### [03. Multi-Location Inventory Synchronization](03-multi-location-sync.md)

If you have warehouses in three cities, you need to know what's in each one without calling them on the phone. When you move products between locations, both locations need to show the right numbers. The biggest problem: selling the last item to two customers at once because your systems didn't update fast enough.

**Industries**: Retail chains, distribution networks, ecommerce

---

### [04. Consignment and Vendor-Managed Inventory (VMI)](04-consignment-vmi.md)

**Consignment** means a supplier puts their products in your warehouse, but they still own them until you use or sell them. You only pay when you actually use the items. The tricky part is tracking what belongs to whom and knowing exactly when ownership changes hands.

**Industries**: Retail, manufacturing supplies, automotive, aerospace

---

### [05. Returns and Reverse Logistics](05-returns-reverse-logistics.md)

**Reverse logistics** is moving goods backward — from customers back to the warehouse. Customers return products, and you need to figure out: Can you resell it as new? Does it need repair? Should you throw it away? Each returned item could take a different path, and you need to track everything while processing refunds quickly.

**Industries**: Ecommerce, retail, electronics, apparel

---

### [06. Kitting and Bundling Operations](06-kitting-bundling.md)

You sell gift sets that contain 3 different products packaged together. When someone orders the gift set, you need to reduce inventory for all 3 items. If you pre-assemble 100 gift sets, those 3 items are no longer available to sell separately. Managing what's a component vs. what's a kit gets complicated.

**Industries**: Subscription boxes, gift sets, promotional bundles

---

### [07. Demand Forecasting and Stockout Prevention](07-demand-forecasting-stockouts.md)

Order too much and your money sits in unsold inventory. Order too little and you have a **stockout** — you lose sales because you're out of stock. The challenge is predicting how much customers will buy so you have just enough inventory — not too much, not too little.

**Industries**: All retail and distribution businesses

---

### [08. Inventory Accuracy and Cycle Counting](08-inventory-accuracy-cycle-counting.md)

Your computer says you have 50 units, but when you count the shelf, there are only 45. Products get stolen, damaged, or miscounted. The challenge is regularly checking your physical inventory against your records and reacting when the numbers don't match.

**Industries**: All warehousing and distribution operations

---

### [09. Perishable Inventory Management](09-perishable-inventory-management.md)

Milk expires in 7 days. If you don't sell it by then, you throw it away and lose money. You need to sell the oldest milk first (**FIFO** — First In, First Out), mark down prices as expiration approaches, and order carefully so you don't have too much inventory spoiling on your shelves.

**Industries**: Grocery stores, restaurants, food service, pharmacies, florists

---

### [10. Accepting Sales Orders in Ecommerce](10-ecommerce-order-acceptance.md)

When 10 customers try to buy your last 5 items at the same time, you need to accept exactly 5 orders and reject the rest — this requires **atomic** (all-or-nothing) operations. The challenge is checking inventory and reserving it fast enough that you never oversell, while also releasing inventory immediately when payments fail so other customers can buy.

**Industries**: Ecommerce, online retail, direct-to-consumer brands
