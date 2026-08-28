-- =============================================================================
-- Clear demo/seed rows from HMSMAIN_TF's Inv/Pharmacy/Data schema tables before
-- running MigrateFromIHealthCure_HMSMAIN_TF.sql. Deletes only module tables -
-- never touches dbo.Users/Departments/Rooms/Branches.
-- Ordered child-before-parent so it's safe even where FK constraints exist.
-- =============================================================================
SET NOCOUNT ON;
PRINT '=== Clearing demo/seed data on HMSMAIN_TF (Inv/Pharmacy/Data schema) ===';

-- Deepest children first
DELETE FROM Inv.DemandRequestItems;
DELETE FROM Inv.DemandRequestLifeCycles;
DELETE FROM Inv.PurchaseOrderItems;
DELETE FROM Inv.PurchaseOrderStatus;         -- per-PO status history log (singular table)
DELETE FROM Inv.InventoryDetails;
DELETE FROM Inv.InventoryItems;
DELETE FROM Inv.GRNItems;
DELETE FROM Inv.StockConsumptionDetails;
DELETE FROM Inv.StockAdjustmentDetails;
DELETE FROM Inv.StockAuditItems;
DELETE FROM Inv.TransferInventoryItems;
DELETE FROM Inv.ReturnInventoryItems;
DELETE FROM Inv.RackDrawrs;
DELETE FROM Inv.RackColumns;
DELETE FROM Inv.RackRows;
DELETE FROM Inv.PurchaseRequisitionAttachments;
DELETE FROM Inv.PurchaseRequisitionLifeCycles;
DELETE FROM Inv.PurchaseRequisitionItems;

-- Mid-level
DELETE FROM Inv.DemandRequests;
DELETE FROM Inv.PurchaseOrders;
DELETE FROM Inv.Inventories;
DELETE FROM Inv.GoodsReceivingNotes;
DELETE FROM Inv.StockConsumptions;
DELETE FROM Inv.StockAdjustments;
DELETE FROM Inv.StockAudits;
DELETE FROM Inv.TransferInventory;
DELETE FROM Inv.ReturnInventory;
DELETE FROM Inv.Racks;
DELETE FROM Inv.PurchaseRequisitions;
DELETE FROM Inv.SpaceAllocations;
DELETE FROM Inv.StoreAllocationToUser;
DELETE FROM Inv.StockTypeAssociations;
DELETE FROM Inv.AssetAllocations;
DELETE FROM Inv.ContingentBills;
DELETE FROM Inv.EstimatedPurchaseOrders;
DELETE FROM Inv.DemandWiseValues;
DELETE FROM Inv.PurchaseSummaries;
DELETE FROM Inv.PurchaseSummaryInvoices;
DELETE FROM Inv.ItemTypeSaleLevels;
DELETE FROM Inv.SampleCollectionConsumptionItems;
DELETE FROM Inv.SurgicalItemGroups;
DELETE FROM Inv.Stocks;
DELETE FROM Data.SurgicalItemGroups;

-- Items depend on master lookups
DELETE FROM Inv.Items;

-- Master lookups
DELETE FROM Inv.Vendors;
DELETE FROM Pharmacy.Manufacturers;
DELETE FROM Data.Brands;
DELETE FROM Inv.ItemTypes;
DELETE FROM Inv.ItemUnits;
DELETE FROM Inv.Categories;
DELETE FROM Inv.ItemCategories;
DELETE FROM Inv.PurchaseOrderTypes;
DELETE FROM Inv.PurchaseOrderStatuses;       -- status lookup (plural table)
DELETE FROM Inv.PurchaseRequisitionStatus;
DELETE FROM Inv.DemandRequestStatuses;
DELETE FROM Inv.StockTypes;
DELETE FROM Pharmacy.PharmacyStores;

PRINT '=== Demo data cleared ===';
