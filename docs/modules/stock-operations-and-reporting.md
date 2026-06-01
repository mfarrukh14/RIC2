# Stock Operations And Reporting Module

## Purpose

The Stock Operations and Reporting module is the runtime view of what inventory became after intake. It answers questions such as:

- What is currently in stock?
- Where is it stored?
- What is below minimum panic level?
- What expired or is about to expire?
- What changed because of audits, adjustments, or consumption?
- What is the financial value of current stock?

This module depends heavily on inventory receipts and store configuration, but it is the main operational layer used to monitor, reconcile, and report stock.

## Functional Scope

This module currently covers:

- Stock search and minimum panic level views.
- Stock type maintenance.
- Stock type association by pharmacy store and patient type.
- Stock audits.
- Stock adjustments.
- Stock consumption.
- Stock flow reporting.
- Stock balance reporting.
- Stock value reporting.
- Stock detail reporting.
- Expiry and least-expiry reporting.
- Rack and space-related stock context in the broader store area.

## Main UI Surfaces

- Stock
- Stock Audit
- Stock Stats
- Stock Adjustment
- Stock Consumption
- Stock Flow
- Stock Type
- Stock Type Association
- Stock Expiring
- Stock Expired
- Stock Value Wrt Items
- Stock Detail Record
- Stock Balance Report
- Stock With Least Expiry

## Main Backend Surfaces

### Search, setup, and operational APIs

| Endpoint | Purpose |
| --- | --- |
| `POST /api/stocks/search` | Search live stock using filters |
| `GET /api/stocktypes` and CRUD variants | Maintain stock types |
| `GET /api/stocktypeassociations` and CRUD variants | Link store, stock type, and patient type |
| `GET /api/stockadjustments` and CRUD variants | Record manual stock adjustments |
| `GET /api/stockconsumptions` and CRUD variants | Record stock consumption |
| `POST /api/stockaudits/search` | Search audit candidates |
| `POST /api/stockaudits` | Create stock audit |

### Reporting APIs

| Endpoint | Purpose |
| --- | --- |
| `GET /api/stockflow` | Show movement over time |
| `GET /api/stockbalancereport` | Show opening, in, out, and closing balances |
| `GET /api/stockvalueitems` | Show stock valuation by item and batch |
| `GET /api/stockvalueitems/report` | Show GRN report by batch |
| `GET /api/stockdetailrecords` | Show detailed stock movement summaries |
| `GET /api/stockwithexpiry` | Show stock with location, expiry, and MPL context |
| `GET /api/stockexpiring` or `POST /api/stockexpiring/search` | Show expiring stock |
| `POST /api/stockstats/search` | Return opening, received, issued, and balance metrics |

## Core Data Objects

### Stock search record

The stock search result includes fields such as:

- Item id and item name
- Stock type
- Total items
- Minimum panic level
- Store id and branch id
- Item type and category information
- Flags such as fridge item and consumption item

### Stock type association

This record binds:

- Pharmacy store id
- Stock type
- Patient type

It is important because the same store can behave differently depending on stock and patient context.

### Adjustment and consumption records

These records capture stock reductions or corrections and usually include:

- Store and branch
- Type of operation
- Item and stock type
- Quantity
- Audit metadata

### Reporting records

Report models summarize stock from different angles:

- Movement by transaction type
- Value by item and batch
- Balance by time window
- Expiry risk and location

## End-to-End Data Flow

```mermaid
flowchart LR
    InventoryIn[Inventory receipts and GRN] --> StockData[Stock tables and movement history]
    Adjustments[Stock adjustments] --> StockData
    Consumption[Stock consumptions] --> StockData
    Audits[Stock audits] --> StockData
    TypeAssoc[Stock type associations] --> StockData

    StockUI[Stock and reporting pages] --> QueryApis[/api/stocks/search and stock report APIs]
    QueryApis --> Services[Stock services and report services]
    Services --> Procedures[Stored procedures and fallback SQL]
    Procedures --> StockData
    StockData --> ResultSets[(SQL Server result sets)]
    ResultSets --> StockUI
```

## Request and Processing Patterns

### 1. Stock search

The Stock page builds a filter payload containing values such as:

- Branch id
- Store id
- Item type id
- Item id
- Category ids
- Stock type id
- General type
- Stock availability
- Minimum panic level only flag

The backend then:

1. Checks whether the `Stock_Search` stored procedure exists.
2. Uses it when available.
3. Falls back to inline SQL over `Inv.Stocks`, `Inv.Items`, `Inv.InventoryDetails`, `Inv.Inventories`, and related tables when needed.

That fallback behavior is a meaningful implementation detail because it reduces the risk of the page breaking when the stored procedure is missing in a given environment.

### 2. Stock type and stock type association setup

Before stock is interpreted correctly, administrators can maintain:

- Stock types
- Store-stock-patient associations

Those definitions shape how receiving and downstream reporting should categorize stock.

### 3. Stock-changing transactions

Operational screens such as adjustment and consumption write records that change stock state. These writes are then visible in movement and balance reports.

Typical examples:

- A manual correction reduces or increases stock.
- A consumption event issues items out of stock.
- An audit records physical-vs-system differences.

### 4. Reporting and analysis

Read-only report endpoints aggregate stock into business views such as:

- Opening, received, issued, and balance quantities.
- Purchase and sale valuation.
- Batch-level GRN traceability.
- Expiry risk.
- Movement history over a date range.

## Module Dependencies

### Upstream dependencies

- Inventory receipts supply the incoming stock records.
- Store records scope stock by store and branch.
- Item, category, manufacturer, and stock type masters provide the metadata used in filters and reports.

### Downstream business value

This module supports:

- Daily operational decision-making.
- Reconciliation and audit activities.
- Financial visibility.
- Early warning for shortage and expiry.

## Key Implementation Notes

- The stock search page reuses lookup data from the inventory module for stores, items, and stock types.
- Stock services rely heavily on stored procedures, but at least the search path has a resilient fallback query.
- Several report services are read-only and optimized around specific stored procedure result shapes.
- The expiry-oriented models also expose storage location details such as rack, row, column, and drawer.

## Operational Risks and Review Points

- If upstream inventory is incomplete or wrong, stock balances and reports become misleading.
- If stock adjustments or consumptions are posted without strong controls, balance reports will drift from reality.
- Stock type associations are a small setup table with large downstream impact because filtering and store behavior depend on them.

## Simplified Module Narrative

The Stock Operations and Reporting module turns raw inventory transactions into operational truth. It is the part of the system that tells users what they have, what changed, what is low, what is expiring, and what the stock is worth.