# Supply Chain Module

## Purpose

The Supply Chain module manages the planning and request-to-fulfillment side of stock movement. It starts when a branch or store identifies demand, continues through demand tracking and procurement planning, and ends when stock is received and the request status is updated.

This module is distinct from Inventory Management and Stock Operations:

- Inventory Management records formal inventory intake and item-level receipt data.
- Stock Operations shows current balances, movements, audits, and reports.
- Supply Chain coordinates why stock is being requested, what should be procured, and when a request has been fulfilled.

## Functional Scope

Based on the current UI and API implementation, this module covers:

- Demand request creation and listing.
- Demand request detail and lifecycle tracking.
- Receive-stock confirmation against issued demands.
- Purchase order creation and listing.
- Estimated purchase order analysis.
- Related workflow screens for pending, approved, and received demand handling.

In the sidebar, the Supply Chain group currently contains:

- Demand Wise Value
- Estimated Purchase Order
- Purchase Order
- Purchase Order Type
- Purchase Order Status
- Place Demand
- Pending Demands
- Approved Demands
- Receive Stock
- Received Stock Status
- Demand Request Status
- Stock Transitions

Not every screen in that group has a dedicated controller in the current slice reviewed here, but the central demand and purchase workflow is implemented and active.

## Main UI Surfaces

### Demand workflow pages

- Place Demand
- Pending Demands
- Approved Demands
- Receive Stock
- Received Stock Status
- Demand Request Status

### Procurement workflow pages

- Estimated Purchase Order
- Purchase Order
- Purchase Order Type
- Purchase Order Status

### Planning and transition pages

- Demand Wise Value
- Stock Transitions

## Main Backend Surfaces

### Demand request APIs

| Endpoint | Purpose |
| --- | --- |
| `GET /api/demandrequests` | List demand requests with filters |
| `GET /api/demandrequests/{id}` | Load one demand request and its items |
| `GET /api/demandrequests/{id}/lifecycle` | Load lifecycle/history entries |
| `POST /api/demandrequests` | Create a new demand request |
| `POST /api/demandrequests/{id}/receive` | Mark a demand as received and update quantities |

### Purchase order APIs

| Endpoint | Purpose |
| --- | --- |
| `GET /api/purchaseorders` | List purchase orders |
| `GET /api/purchaseorders/{id}` | Load one purchase order and its items |
| `POST /api/purchaseorders` | Create a purchase order |

### Planning / analytical APIs

| Endpoint | Purpose |
| --- | --- |
| `GET /api/estimatedpurchaseorders` | Return estimated purchase order data |

## Core Service Layer

- `DemandRequestService`
- `PurchaseOrderService`
- `EstimatedPurchaseOrderService`

## Core Data Objects

### Demand Request

The demand request is the primary planning object. It captures:

- Demand request number and indent number.
- Requesting branch.
- Requesting store and requested store.
- Stock type.
- Date range.
- Status.
- Remarks.
- Requested items and quantities.

Each request also exposes summarized fields used by the UI:

- Items count.
- Total requested quantity.
- Aggregated item summary.

### Demand Request Item

Each demand request contains item rows with:

- Item id and item name.
- Requested quantity.
- Approved quantity.
- Issued quantity.
- Remaining quantity.
- Stock type context.
- Remarks.

### Purchase Order

The purchase order represents the procurement action taken after planning. It captures:

- Generated PO number.
- Manual PO number.
- Store.
- Vendor.
- Validity date.
- Subject, instructions, and terms.
- Status.
- Total quantity and total amount.

### Purchase Order Item

Each line item stores:

- Item id.
- Item type.
- Packet quantity and unit quantity.
- Packet price and unit price.
- Total price.

## How Data Moves Through The Module

```mermaid
flowchart LR
    Requester[Branch or store user] --> DemandUI[Place Demand page]
    DemandUI --> DemandApi[/api/demandrequests]
    DemandApi --> DemandService[DemandRequestService]
    DemandService --> DemandDB[(Demand requests and items)]

    DemandDB --> ReviewPages[Pending and approved demand views]
    ReviewPages --> POUI[Purchase Order page]
    POUI --> POApi[/api/purchaseorders]
    POApi --> POService[PurchaseOrderService]
    POService --> PODB[(Purchase orders and items)]

    DemandDB --> EstimatedApi[/api/estimatedpurchaseorders]
    EstimatedApi --> Planning[Estimated purchase analysis]

    DemandDB --> ReceiveUI[Receive Stock page]
    ReceiveUI --> ReceiveApi[/api/demandrequests/{id}/receive]
    ReceiveApi --> DemandService
    DemandService --> StatusUpdate[Status and received quantity update]
    StatusUpdate --> InventoryStock[Inventory and stock modules consume fulfilled demand]
```

## Practical Workflow

### 1. Demand is raised

The Place Demand page loads the reference data needed to build a request:

- Branches
- Stores
- Stock types
- Items

The user fills in:

- Branch
- Requested store
- Stock type
- Date range
- Item lines and quantities
- Optional remarks

The frontend then submits the request to `POST /api/demandrequests`.

### 2. Demand request is persisted

`DemandRequestService.CreateAsync` creates:

- One demand request header
- One or more demand request item rows

It also generates request numbers when the caller does not provide them. This means the module can bootstrap a usable request without the user needing to manually create official identifiers.

### 3. Demand is reviewed and tracked

Demand list and detail pages read from:

- `GET /api/demandrequests`
- `GET /api/demandrequests/{id}`

The service returns both summary and detail views, including:

- Status
- Item counts
- Requested totals
- Item-level quantities

If the environment supports lifecycle history, `GET /api/demandrequests/{id}/lifecycle` returns status trail entries such as who acted and when.

### 4. Procurement planning is prepared

Two planning paths are visible in the codebase:

- Estimated purchase order analysis via `GET /api/estimatedpurchaseorders`
- Formal purchase order creation via `POST /api/purchaseorders`

The Purchase Order page loads:

- Vendors
- Stores
- Items

It then builds a PO with item lines, quantities, pricing, and supplier context.

### 5. Purchase order is created

`PurchaseOrderService.CreateAsync` creates:

- One purchase order header
- Multiple purchase order item rows

The service also calculates:

- Total quantity
- Total amount

and assigns a generated PO number. Newly created purchase orders default to a pending status.

### 6. Stock is received against demand

The Receive Stock page filters issued demand requests and allows a user to confirm receipt. When the user submits a receive action:

- `POST /api/demandrequests/{id}/receive` is called.
- The demand header status is updated to `Received`.
- The indent number is filled if needed.
- Each demand item receives a `ReceivedQuantity` value based on issued or requested quantity.

This closes the loop from planning to fulfillment.

## Key Data Flows In Plain Language

### Demand flow

Need identified -> demand request created -> reviewed by status -> eventually issued -> received by destination store.

### Procurement flow

Need aggregated -> estimated procurement view consulted -> purchase order created for vendor -> procurement information stored for later fulfillment and tracking.

### Handoff flow

Once a demand is received or a purchase order results in actual goods arriving, the process hands off to the inventory and stock modules where physical intake, stock balance, and reporting take over.

## Module Dependencies

### Upstream dependencies

This module relies on valid:

- Branch records.
- Store records.
- Stock types.
- Items.
- Vendors.

### Downstream dependencies

This module feeds:

- Inventory intake planning.
- Stock receiving and availability.
- Demand lifecycle reporting.
- Procurement tracking.

## Implementation Notes

- `DemandRequestService` and `PurchaseOrderService` normalize schema names so the same logic can run against standard or HMS-style environments.
- Demand lifecycle history may be empty in HMS mode because the lifecycle table is not always present there.
- The Receive Stock page intentionally filters to issued requests before allowing receipt confirmation.
- Purchase orders are currently created independently from the UI using vendor, store, and item lookups rather than an explicit server-side conversion from a demand request.

## Operational Risks and Review Points

- A demand request can be valid structurally but still be weak operationally if store, branch, or stock type selections are inconsistent.
- Lifecycle visibility may differ between environments because not all databases expose the same history table.
- The current purchase-order flow is operationally useful, but the code reviewed here does not yet show a strong, explicit referential link from a demand request to a purchase order.
- Receiving updates demand status and quantities, but actual inventory intake still depends on the inventory module for full stock recording.

## Simplified Module Narrative

The Supply Chain module answers the planning question of the platform: what stock is needed, who asked for it, what procurement action was taken, and whether the requested stock has been received. It is the workflow bridge between business demand and the formal inventory and stock records managed by the other modules.