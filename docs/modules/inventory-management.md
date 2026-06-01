# Inventory Management Module

## Purpose

The Inventory Management module is the intake and master-data side of the system. It is responsible for defining the reference data needed to receive inventory, capturing new inventory receipts, and storing the header-detail records that later feed stock availability, stock valuation, expiry tracking, and store-level reporting.

This documentation is based on the currently implemented UI and API surfaces in the React frontend and the ASP.NET Core API.

## Functional Scope

This module currently covers these business areas:

- Vendor, manufacturer, brand, packing, item type, item unit, and item category maintenance.
- Item master maintenance.
- Inventory header creation and update.
- Inventory detail line creation and update.
- Inventory receiving / GRN-style intake.
- Transfer and return related screens that build on inventory records.
- Purchase summary and related inventory-facing views.

In the UI, these concerns appear under the Inventory Management sidebar group.

## Main UI Surfaces

- Add Inventory
- Add Items
- Inventory Receiving (GRN)
- Vendors
- Manufacturers
- Brands
- Packing Types
- Item Types
- Item Units
- Item Category
- Transfer Inventory
- Return Inventory Wrt Items
- Purchase Summary
- Purchase Summary Wrt

## Main Backend Surfaces

### Inventory APIs

| Endpoint | Purpose |
| --- | --- |
| `GET /api/inventories` | Load inventory headers for list pages |
| `GET /api/inventories/{id}` | Load one inventory header plus detail rows |
| `POST /api/inventories` | Create inventory header |
| `PUT /api/inventories/{id}` | Update inventory header |
| `DELETE /api/inventories/{id}` | Soft/hard delete handled by stored procedure |
| `POST /api/inventories/details` | Create an inventory detail row |
| `PUT /api/inventories/details/{id}` | Update an inventory detail row |
| `DELETE /api/inventories/details/{id}` | Delete an inventory detail row |
| `GET /api/inventories/lookup` | Return vendors, stores, stock types, items, manufacturers, branches, categories, and brands |

### Core Service Layer

- `InventoryService.GetAllAsync`
- `InventoryService.GetByIdAsync`
- `InventoryService.CreateAsync`
- `InventoryService.UpdateAsync`
- `InventoryService.CreateDetailAsync`
- `InventoryService.GetLookupDataAsync`

### Stored Procedure Dependencies

- `Inventory_GetAll`
- `Inventory_GetById`
- `Inventory_Insert`
- `Inventory_Update`
- `Inventory_Delete`
- `InventoryDetail_Insert`
- `InventoryDetail_Update`
- `InventoryDetail_Delete`
- `Inventory_GetLookupData`

## Core Data Objects

### Inventory Header

The header represents one receiving transaction and stores:

- Vendor
- Store
- Branch
- Stock type
- Vendor invoice number and timestamp
- Purchase and tax summary values
- Total buying price and related calculations

### Inventory Detail

Each detail line represents one item/batch-like receipt row and stores:

- Item and manufacturer
- Manufacturing and expiry dates
- Box, packet, and total item quantities
- Buying and selling prices
- Discount, GST, retail charges, and advance tax values
- Profit per item and margin calculations

### Lookup Data

Lookup data is loaded in one round trip and includes:

- Vendors
- Stores
- Stock types
- Items
- Manufacturers
- Branches
- Categories
- Brands

This is important because the inventory form depends on these lists before the user can submit a valid header and detail line.

## End-to-End Data Flow

```mermaid
flowchart LR
    User[Inventory user] --> UI[Inventory list and form pages]
    UI --> Lookup[GET /api/inventories/lookup]
    Lookup --> ServiceLookup[InventoryService.GetLookupDataAsync]
    ServiceLookup --> SPLookup[Inventory_GetLookupData]
    SPLookup --> DB[(SQL Server)]

    UI --> HeaderPost[POST /api/inventories]
    HeaderPost --> HeaderService[InventoryService.CreateAsync]
    HeaderService --> HeaderSP[Inventory_Insert]
    HeaderSP --> DB

    UI --> DetailPost[POST /api/inventories/details]
    DetailPost --> DetailService[InventoryService.CreateDetailAsync]
    DetailService --> DetailSP[InventoryDetail_Insert]
    DetailSP --> DB

    DB --> ReadBack[GET /api/inventories and GET /api/inventories/{id}]
    ReadBack --> UI
    DB --> StockModule[Downstream stock and reporting module]
```

## Practical Workflow

### 1. Form preparation

The frontend first loads lookup data from `GET /api/inventories/lookup`. This provides the valid vendor, store, branch, stock type, item, and manufacturer choices needed to build a complete transaction.

### 2. Header capture

The user enters the transactional header:

- Vendor
- Store
- Branch
- Stock type
- Vendor invoice number
- Vendor invoice date

The API persists this through `Inventory_Insert`.

### 3. Detail capture

The user then enters item-level data such as quantity, manufacturer, expiry, buying price, selling price, and applicable charges.

The frontend computes several totals before submission, including:

- Total items
- Total buying price
- Advance tax amount
- Total selling price
- Profit per item
- Profit margin

These values are then submitted through `POST /api/inventories/details`.

### 4. Retrieval and review

List screens call `GET /api/inventories`. Detail screens call `GET /api/inventories/{id}` and receive:

- One inventory header
- A second result set containing detail lines

### 5. Downstream consumption

Once inventory is stored, stock-facing modules read from inventory-related tables and stored procedures to calculate:

- Current stock balances
- Latest stock type per item/store
- Stock value
- Expiry reports
- Flow and movement reports

## Data Ownership and Boundaries

This module owns the receipt transaction and the core intake master data. It does not directly present itself as the operational stock ledger UI. Instead, it creates the source records that the stock module reads and interprets.

In practical terms:

- Inventory defines what came in.
- Stock determines what is now available and how it moves.

## Integration With Other Modules

### Upstream dependencies

- Store records must exist before inventory can be assigned to a store.
- Stock types must exist before an inventory transaction can classify stock.
- Item and manufacturer masters improve data quality for details.

### Downstream consumers

- Stock search and MPL views
- Stock balance and valuation reports
- Expiry reporting
- Stock flow reporting
- Stock adjustments and consumption screens

## Key Implementation Notes

- The current frontend submits inventory in two steps: header first, then one detail payload.
- The backend can load header plus multiple detail rows when reading by id.
- The lookup API is a critical dependency because several other screens reuse the same store, item, branch, and stock type lists.
- The service currently passes a hard-coded user id for create/update/delete in several inventory operations, which means audit attribution is not yet fully tied to authenticated users.

## Operational Risks and Review Points

- If lookup data is incomplete, the inventory form becomes partially unusable.
- If header creation succeeds but detail creation fails, the system can be left with a header that has missing or incomplete item lines.
- Client-side financial calculations improve responsiveness, but the database layer should remain the final authority for any accounting-critical totals.

## Simplified Module Narrative

The Inventory Management module answers one main question: what inventory entered the system, in what quantity, at what cost, for which store, and under which stock type. Everything after that, including availability, shortage alerts, expiry analysis, and stock movement reporting, depends on this module being correct.