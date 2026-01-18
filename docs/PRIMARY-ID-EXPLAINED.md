# Understanding primaryId in Inventory Items

## What is primaryId?

In INVI, `primaryId` is the **main identifier** for inventory items within the system. It serves as the primary key that uniquely identifies each item in your inventory database.

## Why is it called primaryId?

The name `primaryId` reflects its role as the **primary identifier** in INVI's database. However, in real-world warehouse operations, multiple identification systems typically operate in parallel:

### Common Identification Systems in Warehouses

1. **SKU (Stock Keeping Unit)**
   - Internal product codes unique to your business
   - Example: `SHIRT-BLU-L-001`

2. **GTIN (Global Trade Item Number)**
   - Standardized international product identifiers
   - Includes UPC, EAN, and other barcode standards
   - Example: `00012345678905`

3. **Warehouse-Specific Barcodes**
   - Custom barcodes for internal tracking
   - May encode location, batch, or other metadata
   - Example: `WH1-A5-BIN3-12345`

4. **Manufacturer Part Numbers**
   - Original equipment manufacturer (OEM) identifiers
   - Example: `MPN-ABC-123-XYZ`

5. **Lot/Batch Numbers**
   - Track groups of items produced or received together
   - Example: `LOT-2024-Q1-0042`

## How to Use primaryId with Other Identifiers

Since warehouses use multiple identification systems simultaneously, you need to choose which identifier to use as the `primaryId` in INVI.

### Strategy 1: Use SKU as primaryId
```json
{
  "primaryId": "SHIRT-BLU-L-001"
}
```
**Pros**: SKUs are often the primary identifier in business systems  
**Cons**: Must maintain external mapping to GTINs and barcodes

### Strategy 2: Use GTIN as primaryId
```json
{
  "primaryId": "00012345678905"
}
```
**Pros**: Standardized, works across systems and partners  
**Cons**: Not all items have GTINs (custom or bulk products)

### Strategy 3: Use Internal UUID as primaryId
```json
{
  "primaryId": "550e8400-e29b-41d4-a716-446655440000"
}
```
**Pros**: Guaranteed uniqueness, no conflicts  
**Cons**: Requires mapping for all human-readable identifiers

## Managing Multiple Identifiers

For now, if you need to work with multiple identifier types (SKU, GTIN, barcodes), maintain a mapping in your application layer or a separate database table that links INVI's `primaryId` to your other identifiers.

**Future enhancement**: INVI will support arbitrary attributes on items and locations, allowing you to store these mappings directly within INVI (e.g., storing both SKU and GTIN as attributes on the same inventory item).

## Key Takeaway

The `primaryId` is called "primary" because it's the **single identifier** that INVI uses internally as the main key. Since real warehouses use multiple identification systems in parallel (SKUs, GTINs, barcodes, etc.), you choose which one to use as the `primaryId`. This design keeps INVI flexible—you control your identification strategy while INVI handles the inventory transactions reliably.
