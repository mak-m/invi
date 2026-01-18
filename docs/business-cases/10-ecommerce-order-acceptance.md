# Business Case: Accepting Sales Orders in Ecommerce

## Overview
When customers place orders on your online store, you need to check if you have enough inventory to fulfill them completely and immediately reserve that inventory so other customers can't buy the same products.

## The Problem
Multiple customers can browse and order at the exact same time. If you have 5 items in stock and 10 customers try to buy them simultaneously, you need to accept orders on a first-come basis until inventory runs out - not oversell.

### How It Works (Simple View)
1. Customer adds items to cart and proceeds to checkout.
2. System attempts to reserve inventory for the order.
3. If successful (enough inventory available), all items are reserved together in one operation — this is called an **atomic** transaction, meaning either everything succeeds or nothing changes. If there's not enough inventory, the system returns an error and makes no changes.
4. Customer completes payment.
5. Order moves to fulfillment with inventory already reserved.
6. If payment fails, release all reserved inventory back to stock.

### Why This Is Important
- **Overselling** damages customer trust and causes cancellations.
- **Partial fulfillment** frustrates customers who expected complete orders.
- Without **atomic operations** (all-or-nothing transactions), two customers could accidentally buy the same last item at the same time.
- Payment failures need quick inventory release so items become available again.

### Common Challenges
- Preventing overselling when many orders happen at once.
- Ensuring complete order fulfillment (all items available or reject the order).
- Releasing inventory quickly when payments fail or orders are cancelled.
- Showing accurate "in stock" counts on product pages.
- Handling inventory across multiple warehouses (which location gets to process inventory further).

### Real-World Scenario
An online store has 3 units of a popular item left. During a sale:
- Customer A adds 2 units to cart and starts checkout - inventory reserved.
- Customer B tries to checkout with 3 units - order rejected (not enough available).
- Customer A's payment fails - 2 units released immediately.
- Customer B retries and successfully reserves 2 units.
- Customer C can now only see 1 unit available.

Without proper atomic reservation, the store could accept multiple orders for the same inventory, leading to overselling and customer disappointment.

## See It In Action

[**Example: Ecommerce Order Acceptance with INVI**](example-ecommerce-order-acceptance.md) - Complete walkthrough showing single and multi-location order acceptance with automatic inventory selection.
