# Store Management Module

## Purpose

The Store Management module defines where inventory lives and who is allowed to operate against it. It captures store master data, store hierarchy, operational settings, location and contact details, and the mapping between stores and users.

This module is foundational because inventory receipts, stock searches, stock associations, and multiple reporting surfaces depend on valid store records.

## Functional Scope

This module currently covers these concerns:

- Store master creation, update, deletion, and listing.
- Store hierarchy and configuration.
- Store-level contact, location, pricing, and day-closing settings.
- Shared pharmacy store dropdown access for other modules.
- Store allocation to user.

In the UI, the broader Stores Management area also contains stock reporting pages, but this document focuses on the store-configuration side of that area.

## Main UI Surfaces

- Store Management
- Stores Allocation To User

These pages are used as configuration and control surfaces rather than transactional receiving screens.

## Main Backend Surfaces

### Store APIs

| Endpoint | Purpose |
| --- | --- |
| `GET /api/Store` | List stores |
| `GET /api/Store/{id}` | Get one store |
| `POST /api/Store` | Create a store |
| `PUT /api/Store/{id}` | Update a store |
| `DELETE /api/Store/{id}` | Delete a store if dependencies allow |
| `POST /api/Store/pharmacy-store-dropdown` | Return store dropdown data for dependent modules |

### Store Allocation APIs

| Endpoint | Purpose |
| --- | --- |
| `GET /api/StoreAllocationToUser` | List store-user allocations |
| `GET /api/StoreAllocationToUser/{id}` | Get one allocation |
| `POST /api/StoreAllocationToUser` | Create an allocation |
| `PUT /api/StoreAllocationToUser/{id}` | Update an allocation |
| `DELETE /api/StoreAllocationToUser/{id}` | Delete an allocation |
| `GET /api/StoreAllocationToUser/employee-dropdown` | Return employee dropdown data |

### Core Service Layer

- `StoreService`
- `StoreAllocationToUserService`

### Stored Procedure Dependencies

Store master:

- `Store_GetAll`
- `Store_GetById`
- `Store_Insert`
- `Store_Update`
- `Store_Delete`

Store allocation:

- `StoreAllocationToUser_GetAll`
- `StoreAllocationToUser_GetById`
- `StoreAllocationToUser_Insert`
- `StoreAllocationToUser_Update`
- `StoreAllocationToUser_Delete`

Shared dropdown and employee sources:

- `DropDown.SP_DDL_AllPharmacyStore`
- `DropDown.DD_Users`

## Core Data Objects

### Store

The store entity is relatively rich and includes:

- Identity: store id, name, code, description.
- Hierarchy: parent store id.
- Physical location: building, floor, room, address, latitude, longitude, country, province, city.
- Operational behavior: store type, receipt type, POS type, queue behavior, token handling.
- Financial settings: GST, service charges, pricing type, payable and closing accounts.
- Status and audit metadata.

### Store Dropdown Item

Many other screens do not need the full store model. They only need a compact pair of values:

- `value`
- `text`

This is how the pharmacy store dropdown is exposed to dependent modules.

### Store Allocation To User

This entity links:

- One store
- One user
- One active flag

It is used to control which employee is associated with which operational store.

## End-to-End Data Flow

```mermaid
flowchart LR
    Admin[Admin or setup user] --> StoreUI[StoreManagementPage]
    StoreUI --> StoreApi[/api/Store]
    StoreApi --> StoreService[StoreService]
    StoreService --> StoreSPs[Store_GetAll / Store_Insert / Store_Update / Store_Delete]
    StoreSPs --> DB[(SQL Server)]

    Admin --> AllocationUI[StoreAllocationToUserPage]
    AllocationUI --> StoreDropdown[/api/Store/pharmacy-store-dropdown]
    AllocationUI --> EmployeeDropdown[/api/StoreAllocationToUser/employee-dropdown]
    StoreDropdown --> SharedStoreSource[DropDown.SP_DDL_AllPharmacyStore]
    EmployeeDropdown --> SharedUserSource[DropDown.DD_Users]
    SharedStoreSource --> DB
    SharedUserSource --> DB

    AllocationUI --> AllocationApi[/api/StoreAllocationToUser]
    AllocationApi --> AllocationService[StoreAllocationToUserService]
    AllocationService --> AllocationSPs[StoreAllocationToUser_*]
    AllocationSPs --> DB

    DB --> InventoryModule[Inventory and stock modules consume store ids]
```

## Practical Workflow

### 1. Store creation and maintenance

An administrator creates a store record from the Store Management page. The page sends a full request model that includes operational, financial, and address-related settings.

The API persists the record through the store stored procedures and returns the created or updated store for later display.

### 2. Store listing and filtering

The UI lists stores and supports search by fields like:

- Store name
- Store code
- Store type

This gives administrators a fast way to verify whether a store exists before it is used elsewhere.

### 3. Shared dropdown publication

Other screens do not query the store table directly from the UI. Instead, they usually request a constrained dropdown list using the pharmacy store dropdown endpoint.

This matters because it standardizes how store selection works across:

- Store allocation screens
- Stock type associations
- Other store-dependent flows

### 4. User allocation

The Store Allocation To User page loads:

- Stores from the shared store dropdown endpoint
- Employees from the employee dropdown endpoint

The user then creates or updates the mapping. That mapping is stored through the `StoreAllocationToUser_*` stored procedures.

## Module Dependencies

### Downstream consumers

Store data is reused throughout the platform:

- Inventory lookup data uses stores for receiving transactions.
- Stock search filters use stores for scoping availability.
- Stock type associations bind stock behavior to a pharmacy store.
- Reporting pages group, filter, and summarize by store.

### External and shared sources

The implementation also uses shared HMS-compatible dropdown sources for stores and users when those sources exist and have the expected shape.

That means this module is both:

- A local store master owner for CRUD flows.
- A compatibility consumer of shared dropdown surfaces for cross-system integration.

## Key Implementation Notes

- The store model is not just a name/code record; it carries many operational settings that change downstream behavior.
- The dropdown endpoint defaults branch filtering when the client does not provide values, which helps the UI boot successfully with minimal parameters.
- Store deletion is guarded by dependency checks in the stored procedure path.
- Store allocation prefers shared employee sources instead of assuming a local employee table shape.

## Operational Risks and Review Points

- A wrong store hierarchy or inactive store can create confusion in receiving and reporting screens.
- If dropdown sources and local store data drift apart, users may see selection mismatches across modules.
- Because stores are a root dependency, bad master data here propagates into inventory, stock, and reporting records.

## Simplified Module Narrative

The Store Management module answers two basic questions for the rest of the system:

- Which stores exist, and how are they configured?
- Which people are allowed to operate against those stores?

Once those two questions are answered reliably, the inventory and stock modules can use store ids as a stable anchor for transactions, balances, and reports.