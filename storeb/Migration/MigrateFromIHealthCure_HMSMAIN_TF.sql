-- =============================================================================
-- Migrate master data + current balances from iHealthCure (legacy, dbo.* schema,
-- uniqueidentifier PKs) into HMSMAIN_TF's Inv/Pharmacy/Data schema (int PKs).
--
-- Run this ON HMSMAIN_TF (or with HMSMAIN_TF as the connection's current
-- database) - it reaches iHealthCure via 3-part names since both databases
-- live on the same server (10.10.10.103).
--
-- SCOPE / ASSUMPTIONS (confirmed with the user before writing this):
--   - Target: HMSMAIN_TF only. IPPHMS / IPPHMSLOCAL are not touched.
--   - dbo.Users / dbo.Departments / dbo.Rooms / dbo.Branches are NOT touched -
--     they already hold real, live, shared HMS data. Nothing here inserts,
--     updates, or deletes rows in those tables.
--   - Because we don't migrate Branches, every migrated row's BranchId is
--     pinned to HMSMAIN_TF's existing "Main Branch" (dbo.Branches.Id = 1).
--     iHealthCure's 26-branch granularity is not preserved.
--   - Because we don't migrate Users, CreatedById/ModifiedById columns are
--     left NULL on migrated rows (timestamps ARE preserved). StoreAllocation-
--     ToUser is skipped entirely since it has nothing but a UserId FK.
--   - No branch filtering on the iHealthCure side - all of it is migrated
--     (per explicit instruction), scoped only by "master data + current
--     balances", not full multi-million-row transaction history
--     (StockTransactionHistories etc. are intentionally NOT migrated).
--   - Where a target column has no source equivalent, or a source column has
--     no target column, it is left NULL / dropped - never invented.
--   - Existing demo/seed rows in Inv/Pharmacy/Data schema tables are assumed
--     to have already been cleared by ClearDemoData_HMSMAIN_TF.sql (run first).
--
-- ID REMAPPING: iHealthCure uses uniqueidentifier PKs; our schema uses
-- int IDENTITY. Every table with a remapped PK builds a #XMap(OldId,NewId)
-- temp table. SQL Server's OUTPUT clause on a plain INSERT...SELECT cannot
-- reference the source query's columns - only MERGE's OUTPUT can - so every
-- such insert is written as "MERGE ... USING (subquery incl. OldId) ... WHEN
-- NOT MATCHED THEN INSERT ... OUTPUT src.OldId, inserted.NewPK". ON 1=0 makes
-- it always insert (never match), since the target was already cleared.
-- All #temp tables live for the duration of this single sqlcmd session, so
-- run this whole file in ONE sqlcmd invocation (sqlcmd -i), not statement by
-- statement.
-- =============================================================================

SET NOCOUNT ON;
PRINT '=== Starting iHealthCure -> HMSMAIN_TF migration ===';

DECLARE @MainBranchId INT = 1; -- dbo.Branches "Main Branch" - see header note above

-- =============================================================================
-- PHASE 1: Master / lookup tables (no dependency on other migrated tables)
-- =============================================================================

PRINT 'Phase 1: StockTypes';
CREATE TABLE #StockTypeMap (OldId INT PRIMARY KEY, NewId INT);
SET IDENTITY_INSERT Inv.StockTypes ON;
INSERT INTO Inv.StockTypes (Id, Name, Description, IsActive, IsDeleted, CreatedOn)
OUTPUT inserted.Id, inserted.Id INTO #StockTypeMap(NewId, OldId)
SELECT Id, Name, Description, 1, 0, GETDATE()
FROM iHealthCure.dbo.StockTypes;
SET IDENTITY_INSERT Inv.StockTypes OFF;

PRINT 'Phase 1: ItemTypes';
CREATE TABLE #ItemTypeMap (OldId UNIQUEIDENTIFIER PRIMARY KEY, NewId INT);
MERGE INTO Inv.ItemTypes AS tgt
USING (SELECT Id AS OldId, Name, Description, IsActive, CreatedOn, ModifiedOn, Value FROM iHealthCure.dbo.ItemTypes) AS s
ON 1 = 0
WHEN NOT MATCHED THEN
    INSERT (Name, Description, BranchId, IsActive, CreatedOn, ModifiedOn, Value)
    VALUES (s.Name, s.Description, @MainBranchId, s.IsActive, s.CreatedOn, s.ModifiedOn, s.Value)
OUTPUT s.OldId, inserted.Id INTO #ItemTypeMap(OldId, NewId);

PRINT 'Phase 1: ItemUnits';
CREATE TABLE #ItemUnitMap (OldId UNIQUEIDENTIFIER PRIMARY KEY, NewId INT);
MERGE INTO Inv.ItemUnits AS tgt
USING (SELECT Id AS OldId, Name, Description, IsActive, CreatedOn, ModifiedOn FROM iHealthCure.dbo.ItemUnits) AS s
ON 1 = 0
WHEN NOT MATCHED THEN
    INSERT (Name, Description, BranchId, IsActive, CreatedOn, ModifiedOn)
    VALUES (s.Name, s.Description, @MainBranchId, s.IsActive, s.CreatedOn, s.ModifiedOn)
OUTPUT s.OldId, inserted.Id INTO #ItemUnitMap(OldId, NewId);

PRINT 'Phase 1: Categories';
CREATE TABLE #CategoryMap (OldId UNIQUEIDENTIFIER PRIMARY KEY, NewId INT);
MERGE INTO Inv.Categories AS tgt
USING (SELECT Id AS OldId, Name, Description, IsActive, CreatedOn, ModifiedOn FROM iHealthCure.dbo.Categories) AS s
ON 1 = 0
WHEN NOT MATCHED THEN
    INSERT (Name, Description, IsActive, CreatedOn, ModifiedOn)
    VALUES (s.Name, s.Description, s.IsActive, s.CreatedOn, s.ModifiedOn)
OUTPUT s.OldId, inserted.Id INTO #CategoryMap(OldId, NewId);

PRINT 'Phase 1: Brands';
CREATE TABLE #BrandMap (OldId UNIQUEIDENTIFIER PRIMARY KEY, NewId INT);
MERGE INTO Data.Brands AS tgt
USING (SELECT Id AS OldId, Name, Description, IsActive, CreatedOn, ModifiedOn FROM iHealthCure.dbo.Brands) AS s
ON 1 = 0
WHEN NOT MATCHED THEN
    INSERT (Name, Description, BranchId, IsActive, CreatedOn, ModifiedOn)
    VALUES (s.Name, s.Description, @MainBranchId, s.IsActive, s.CreatedOn, s.ModifiedOn)
OUTPUT s.OldId, inserted.Id INTO #BrandMap(OldId, NewId);

PRINT 'Phase 1: Vendors';
CREATE TABLE #VendorMap (OldId UNIQUEIDENTIFIER PRIMARY KEY, NewId INT);
MERGE INTO Inv.Vendors AS tgt
USING (
    SELECT Id AS OldId, Name, Description, Email, CNo, Address, NTN, STN, CPName1, CPEmail1, CPContactNumber1,
        CPName2, CPEmail2, CPContactNumber2, IsActive, CreatedOn, ModifiedOn,
        Code, VendorOrCustomer, IncomeTaxStatus, VendorType, TaxPayerStatus, SaleTaxType,
        ExemptUnderSRO, CreditStatus, NetDueDays, CreditLimit, FaxNo, IsVerified
    FROM iHealthCure.dbo.Vendors
) AS s
ON 1 = 0
WHEN NOT MATCHED THEN
    INSERT (
        Name, Description, Email, CNo, Address, NTN, STN, CPName1, CPEmail1, CPContactNumber1,
        CPName2, CPEmail2, CPContactNumber2, BranchId, IsActive, CreatedOn, ModifiedOn,
        Code, VendorOrCustomer, IncomeTaxStatus, VendorType, TaxPayerStatus, SaleTaxType,
        ExemptUnderSRO, CreditStatus, NetDueDays, CreditLimit, FaxNo, IsVerified
    )
    VALUES (
        s.Name, s.Description, s.Email, s.CNo, s.Address, s.NTN, s.STN, s.CPName1, s.CPEmail1, s.CPContactNumber1,
        s.CPName2, s.CPEmail2, s.CPContactNumber2, @MainBranchId, s.IsActive, s.CreatedOn, s.ModifiedOn,
        s.Code, s.VendorOrCustomer, s.IncomeTaxStatus, s.VendorType, s.TaxPayerStatus, s.SaleTaxType,
        s.ExemptUnderSRO, s.CreditStatus, s.NetDueDays, s.CreditLimit, s.FaxNo, s.IsVerified
    )
OUTPUT s.OldId, inserted.Id INTO #VendorMap(OldId, NewId);

PRINT 'Phase 1: Manufacturers';
CREATE TABLE #ManufacturerMap (OldId UNIQUEIDENTIFIER PRIMARY KEY, NewId INT);
MERGE INTO Pharmacy.Manufacturers AS tgt
USING (
    SELECT Id AS OldId, Name, Email, CNo, Address, Description, CreatedOn, ModifiedOn, IsActive,
        NTN, STN, CPName1, CPEmail1, CPContactNumber1, CPName2, CPEmail2, CPContactNumber2, RegisteredOwner
    FROM iHealthCure.dbo.Manufacturers
) AS s
ON 1 = 0
WHEN NOT MATCHED THEN
    INSERT (
        Name, Email, MobileNo, Address, Description, CreatedOn, ModifiedOn, IsDeleted, IsActive,
        NTN, STN, CPName1, CPEmail1, CPContactNumber1, CPName2, CPEmail2, CPContactNumber2,
        BranchId, RegisteredOwner
    )
    VALUES (
        s.Name, s.Email, s.CNo, s.Address, s.Description, s.CreatedOn, s.ModifiedOn, 0, s.IsActive,
        s.NTN, s.STN, s.CPName1, s.CPEmail1, s.CPContactNumber1, s.CPName2, s.CPEmail2, s.CPContactNumber2,
        @MainBranchId, s.RegisteredOwner
    )
OUTPUT s.OldId, inserted.ManufacturerId INTO #ManufacturerMap(OldId, NewId);

PRINT 'Phase 1: PurchaseOrderTypes';
CREATE TABLE #POTypeMap (OldId UNIQUEIDENTIFIER PRIMARY KEY, NewId INT);
MERGE INTO Inv.PurchaseOrderTypes AS tgt
USING (SELECT Id AS OldId, Name, Description, IsActive, CreatedOn, ModifiedOn FROM iHealthCure.dbo.PurchaseOrderTypes) AS s
ON 1 = 0
WHEN NOT MATCHED THEN
    INSERT (Name, Description, IsActive, CreatedOn, ModifiedOn)
    VALUES (s.Name, s.Description, s.IsActive, s.CreatedOn, s.ModifiedOn)
OUTPUT s.OldId, inserted.Id INTO #POTypeMap(OldId, NewId);

PRINT 'Phase 1: PurchaseOrderStatuses (lookup)';
CREATE TABLE #POStatusMap (OldId UNIQUEIDENTIFIER PRIMARY KEY, NewId INT, StatusName NVARCHAR(255));
MERGE INTO Inv.PurchaseOrderStatuses AS tgt
USING (SELECT Id AS OldId, Name, Description, IsActive, CreatedOn FROM iHealthCure.dbo.PurchaseOrderStatus) AS s
ON 1 = 0
WHEN NOT MATCHED THEN
    INSERT (StatusName, Description, IsActive, CreatedOn)
    VALUES (s.Name, s.Description, s.IsActive, s.CreatedOn)
OUTPUT s.OldId, inserted.PurchaseOrderStatusId, s.Name INTO #POStatusMap(OldId, NewId, StatusName);

PRINT 'Phase 1: PurchaseRequisitionStatus';
CREATE TABLE #PRStatusMap (OldId UNIQUEIDENTIFIER PRIMARY KEY, NewId INT);
MERGE INTO Inv.PurchaseRequisitionStatus AS tgt
USING (
    SELECT Id AS OldId, Name,
        CASE WHEN value IN (0,1) THEN 'Pending' WHEN value IN (2,3,4,5) THEN 'Processed' ELSE 'Closed' END AS Category,
        IsActive, CreatedOn
    FROM iHealthCure.dbo.PurchaseRequisitionStatus
) AS s
ON 1 = 0
WHEN NOT MATCHED THEN
    INSERT (Name, Category, IsActive, CreatedOn)
    VALUES (s.Name, s.Category, s.IsActive, s.CreatedOn)
OUTPUT s.OldId, inserted.Id INTO #PRStatusMap(OldId, NewId);

PRINT 'Phase 1: DemandRequestStatuses';
CREATE TABLE #DRStatusMap (OldId UNIQUEIDENTIFIER PRIMARY KEY, NewId INT);
MERGE INTO Inv.DemandRequestStatuses AS tgt
USING (SELECT Id AS OldId, Name, Description, IsActive, CreatedOn, ModifiedOn, Value FROM iHealthCure.dbo.DemandRequestStatus) AS s
ON 1 = 0
WHEN NOT MATCHED THEN
    INSERT (Name, Description, BranchId, IsActive, CreatedOn, ModifiedOn, Value)
    VALUES (s.Name, s.Description, @MainBranchId, s.IsActive, s.CreatedOn, s.ModifiedOn, s.Value)
OUTPUT s.OldId, inserted.Id INTO #DRStatusMap(OldId, NewId);

PRINT 'Phase 1: SurgicalItemGroups';
CREATE TABLE #SurgicalGroupMap (OldId UNIQUEIDENTIFIER PRIMARY KEY, NewId INT);
MERGE INTO Inv.SurgicalItemGroups AS tgt
USING (SELECT Id AS OldId, Name, Description, IsActive, CreatedOn, ModifiedOn, ISNULL(IsDeleted, 0) AS IsDeleted FROM iHealthCure.dbo.SurgicalItemGroups) AS s
ON 1 = 0
WHEN NOT MATCHED THEN
    INSERT (Name, Description, BranchId, IsActive, CreatedOn, ModifiedOn, IsDeleted)
    VALUES (s.Name, s.Description, @MainBranchId, s.IsActive, s.CreatedOn, s.ModifiedOn, s.IsDeleted)
OUTPUT s.OldId, inserted.Id INTO #SurgicalGroupMap(OldId, NewId);

-- Best-effort match of iHealthCure Departments to HMSMAIN_TF's EXISTING live
-- dbo.Departments by name (we do not insert into dbo.Departments). Note the
-- target's PK column is "DID", not "Id".
PRINT 'Phase 1: Department name-match map (read-only, no inserts)';
CREATE TABLE #DepartmentMap (OldId UNIQUEIDENTIFIER PRIMARY KEY, NewId INT);
INSERT INTO #DepartmentMap (OldId, NewId)
SELECT src.Id, tgt.DID
FROM iHealthCure.dbo.Departments src
JOIN dbo.Departments tgt ON LTRIM(RTRIM(tgt.Name)) = LTRIM(RTRIM(src.Name));

PRINT 'Phase 1 complete.';

-- =============================================================================
-- PHASE 2: Items, PharmacyStores (depend on Phase 1 lookups)
-- =============================================================================

PRINT 'Phase 2: Items';
CREATE TABLE #ItemMap (OldId UNIQUEIDENTIFIER PRIMARY KEY, NewId INT);
MERGE INTO Inv.Items AS tgt
USING (
    SELECT
        src.Id AS OldId, src.Name, src.Description, src.BarCode, it.NewId AS ItemTypeId, br.NewId AS BrandId,
        src.Model, src.Specification, ISNULL(cat.NewId, (SELECT MIN(Id) FROM Inv.Categories)) AS CategoryId,
        iu.NewId AS UnitId, src.IsActive, src.CreatedOn, src.ModifiedOn, src.Frequency, src.IsProduct,
        src.BatchExpiryRequired, src.DescriptionForSale, su.NewId AS SaleUnitId, src.Conversion, src.CaseContains,
        src.HSCode, src.RetailPrice, src.SalePrice, src.CostMethod, src.Preference, src.Colour,
        src.MinimumPanicLevel, src.IsHideNameFromBill, src.QuantityPerPacket, src.IsExpensiveItem,
        src.IsFridgeItem, src.Code, src.MarketPrice, src.MinimumOrderPrice, src.MinimumOrderQuantity,
        src.StripPerPacket, src.PackageType, src.PackageSize
    FROM iHealthCure.dbo.Items src
    LEFT JOIN #ItemTypeMap it ON it.OldId = src.ItemTypeId
    LEFT JOIN #BrandMap br ON br.OldId = src.BrandId
    LEFT JOIN #CategoryMap cat ON cat.OldId = src.CategoryId
    LEFT JOIN #ItemUnitMap iu ON iu.OldId = src.UnitId
    LEFT JOIN #ItemUnitMap su ON su.OldId = src.SaleUnitId
) AS s
ON 1 = 0
WHEN NOT MATCHED THEN
    INSERT (
        Name, Description, BarCode, ItemTypeId, BrandId, Model, Specification, CategoryId,
        UnitId, BranchId, IsActive, CreatedOn, ModifiedOn, Frequency, IsProduct,
        BatchExpiryRequired, DescriptionForSale, SaleUnitId, Conversion, CaseContains,
        HSCode, RetailPrice, SalePrice, CostMethod, Preference, Colour, MinimumPanicLevel,
        IsHideNameFromBill, QuantityPerPacket, IsExpensiveItem, IsFridgeItem, Code,
        MarketPrice, MinimumOrderPrice, MinimumOrderQuantity, StripPerPacket, PackageType,
        PackageSize
    )
    VALUES (
        s.Name, s.Description, s.BarCode, s.ItemTypeId, s.BrandId, s.Model, s.Specification, s.CategoryId,
        s.UnitId, @MainBranchId, s.IsActive, s.CreatedOn, s.ModifiedOn, s.Frequency, s.IsProduct,
        s.BatchExpiryRequired, s.DescriptionForSale, s.SaleUnitId, s.Conversion, s.CaseContains,
        s.HSCode, s.RetailPrice, s.SalePrice, s.CostMethod, s.Preference, s.Colour, s.MinimumPanicLevel,
        s.IsHideNameFromBill, s.QuantityPerPacket, s.IsExpensiveItem, s.IsFridgeItem, s.Code,
        s.MarketPrice, s.MinimumOrderPrice, s.MinimumOrderQuantity, s.StripPerPacket, s.PackageType,
        s.PackageSize
    )
OUTPUT s.OldId, inserted.Id INTO #ItemMap(OldId, NewId);

PRINT 'Phase 2: PharmacyStores';
CREATE TABLE #StoreMap (OldId UNIQUEIDENTIFIER PRIMARY KEY, NewId INT);
MERGE INTO Pharmacy.PharmacyStores AS tgt
USING (
    SELECT src.Id AS OldId, src.Name, src.Description, src.OpeningTime, src.ClosingTime, src.IsActive,
        src.CreatedOn, src.ModifiedOn, src.Address, src.Email, src.CellNumber, src.NTN, src.GSTN,
        src.EnglishNote, src.UrduNote, src.ServiceCharges, src.IsPercentageServiceCharges, src.GST,
        src.IsPercentageGST, ISNULL(st.Name, '') AS StoreTypeName
    FROM iHealthCure.dbo.PharmacyStores src
    LEFT JOIN iHealthCure.dbo.StoreTypes st ON st.Id = src.StoreTypeId
) AS s
ON 1 = 0
WHEN NOT MATCHED THEN
    INSERT (
        Name, Description, BranchId, OpeningTime, ClosingTime, IsActive, CreatedOn, ModifiedOn,
        IsDeleted, Address, Email, CellNumber, NTN, GSTN, EnglishNote, UrduNote,
        ServiceCharges, IsPercentageServiceCharges, GST, IsPercentageGST,
        StoreTypeName, ReceiptTypeName, POSTypeName, PricingTypeName, DayClosingName
    )
    VALUES (
        -- Source has no IsDeleted column - target's NOT NULL IsDeleted is hardcoded 0.
        -- Denormalized *TypeName columns beyond StoreTypeName have no source equivalent
        -- and are NOT NULL on target, so an empty string satisfies the constraint
        -- without inventing a specific value (per "fill empty" guidance).
        s.Name, s.Description, @MainBranchId, s.OpeningTime, s.ClosingTime, s.IsActive, s.CreatedOn, s.ModifiedOn,
        0, s.Address, s.Email, s.CellNumber, s.NTN, s.GSTN, s.EnglishNote, s.UrduNote,
        s.ServiceCharges, s.IsPercentageServiceCharges, s.GST, s.IsPercentageGST,
        s.StoreTypeName, '', '', '', ''
    )
OUTPUT s.OldId, inserted.Id INTO #StoreMap(OldId, NewId);

PRINT 'Phase 2 complete.';

-- =============================================================================
-- PHASE 3: Racks / RackRows / RackColumns / RackDrawrs (depend on PharmacyStores)
-- =============================================================================

PRINT 'Phase 3: Racks';
CREATE TABLE #RackMap (OldId UNIQUEIDENTIFIER PRIMARY KEY, NewId INT);
MERGE INTO Inv.Racks AS tgt
USING (
    SELECT src.Id AS OldId, src.Name, src.Description, src.Location, src.NumberOfRows, src.NumberOfCols,
        src.NumberOfDrawrs, ISNULL(s.NewId, (SELECT MIN(Id) FROM Pharmacy.PharmacyStores)) AS StoreId,
        src.IsActive, src.CreatedOn, src.ModifiedOn
    FROM iHealthCure.dbo.Racks src
    LEFT JOIN #StoreMap s ON s.OldId = src.StoreId
) AS s2
ON 1 = 0
WHEN NOT MATCHED THEN
    INSERT (Name, Description, Location, NumberOfRows, NumberOfCols, NumberOfDrawrs, StoreId, BranchId, IsActive, CreatedOn, ModifiedOn, IsDeleted)
    VALUES (s2.Name, s2.Description, s2.Location, s2.NumberOfRows, s2.NumberOfCols, s2.NumberOfDrawrs, s2.StoreId, @MainBranchId, s2.IsActive, s2.CreatedOn, s2.ModifiedOn, 0)
OUTPUT s2.OldId, inserted.Id INTO #RackMap(OldId, NewId);

PRINT 'Phase 3: RackRows';
CREATE TABLE #RackRowMap (OldId UNIQUEIDENTIFIER PRIMARY KEY, NewId INT);
MERGE INTO Inv.RackRows AS tgt
USING (
    SELECT src.Id AS OldId, src.Name, src.Description,
        ISNULL(s.NewId, (SELECT MIN(Id) FROM Pharmacy.PharmacyStores)) AS StoreId, r.NewId AS RackId,
        src.IsActive, src.CreatedOn, src.ModifiedOn
    FROM iHealthCure.dbo.RackRows src
    LEFT JOIN #StoreMap s ON s.OldId = src.StoreId
    JOIN #RackMap r ON r.OldId = src.RackId
) AS s2
ON 1 = 0
WHEN NOT MATCHED THEN
    INSERT (Name, Description, StoreId, RackId, BranchId, IsActive, CreatedOn, ModifiedOn, IsDeleted)
    VALUES (s2.Name, s2.Description, s2.StoreId, s2.RackId, @MainBranchId, s2.IsActive, s2.CreatedOn, s2.ModifiedOn, 0)
OUTPUT s2.OldId, inserted.Id INTO #RackRowMap(OldId, NewId);

PRINT 'Phase 3: RackColumns';
CREATE TABLE #RackColumnMap (OldId UNIQUEIDENTIFIER PRIMARY KEY, NewId INT);
MERGE INTO Inv.RackColumns AS tgt
USING (
    SELECT src.Id AS OldId, src.Name, src.Description,
        ISNULL(s.NewId, (SELECT MIN(Id) FROM Pharmacy.PharmacyStores)) AS StoreId, r.NewId AS RackId,
        src.IsActive, src.CreatedOn, src.ModifiedOn
    FROM iHealthCure.dbo.RackColumns src
    LEFT JOIN #StoreMap s ON s.OldId = src.StoreId
    JOIN #RackMap r ON r.OldId = src.RackId
) AS s2
ON 1 = 0
WHEN NOT MATCHED THEN
    INSERT (Name, Description, StoreId, RackId, BranchId, IsActive, CreatedOn, ModifiedOn, IsDeleted)
    VALUES (s2.Name, s2.Description, s2.StoreId, s2.RackId, @MainBranchId, s2.IsActive, s2.CreatedOn, s2.ModifiedOn, 0)
OUTPUT s2.OldId, inserted.Id INTO #RackColumnMap(OldId, NewId);

PRINT 'Phase 3: RackDrawrs';
INSERT INTO Inv.RackDrawrs (Name, Description, StoreId, RackId, RackRowId, RackColumnId, BranchId, IsActive, CreatedOn, ModifiedOn, IsDeleted)
SELECT src.Name, src.Description, ISNULL(s.NewId, (SELECT MIN(Id) FROM Pharmacy.PharmacyStores)),
    r.NewId, rr.NewId, rc.NewId, @MainBranchId, src.IsActive, src.CreatedOn, src.ModifiedOn, 0
FROM iHealthCure.dbo.RackDrawrs src
LEFT JOIN #StoreMap s ON s.OldId = src.StoreId
JOIN #RackMap r ON r.OldId = src.RackId
LEFT JOIN #RackRowMap rr ON rr.OldId = src.RackRowId
LEFT JOIN #RackColumnMap rc ON rc.OldId = src.RackColumnId;

PRINT 'Phase 3 complete.';

-- =============================================================================
-- PHASE 4: PurchaseOrders / PurchaseOrderItems
-- Target's PurchaseOrders shape has already diverged from the legacy source
-- (denormalized Status string, no PO-type column, aggregate totals) - mapped
-- as closely as the target schema allows.
-- =============================================================================

PRINT 'Phase 4: PurchaseOrders';
CREATE TABLE #PurchaseOrderMap (OldId UNIQUEIDENTIFIER PRIMARY KEY, NewId INT);
MERGE INTO Inv.PurchaseOrders AS tgt
USING (
    SELECT src.Id AS OldId,
        ISNULL(src.PurchaseOrderNumber, CONVERT(NVARCHAR(50), src.Id)) AS PONumber,
        src.ManualPurchaseOrderNumber AS ManualPONumber,
        ISNULL(s.NewId, (SELECT MIN(Id) FROM Pharmacy.PharmacyStores)) AS StoreId,
        ISNULL(v.NewId, (SELECT MIN(Id) FROM Inv.Vendors)) AS VendorId,
        src.POValidityDate, src.Subject, src.Instructions, src.TermsAndConditions,
        ISNULL(ps.StatusName, 'Unknown') AS Status,
        ISNULL((SELECT SUM(Quantity) FROM iHealthCure.dbo.PurchaseOrderItems poi WHERE poi.PurchaseOrderId = src.Id), 0) AS TotalQuantity,
        ISNULL((SELECT SUM(Quantity * Price) FROM iHealthCure.dbo.PurchaseOrderItems poi WHERE poi.PurchaseOrderId = src.Id), 0) AS TotalAmount,
        src.IsActive, src.CreatedOn, src.ModifiedOn
    FROM iHealthCure.dbo.PurchaseOrders src
    LEFT JOIN #StoreMap s ON s.OldId = src.StoreId
    LEFT JOIN #VendorMap v ON v.OldId = src.VendorId
    LEFT JOIN #POStatusMap ps ON ps.OldId = src.PurchaseOrderStatusId
) AS s2
ON 1 = 0
WHEN NOT MATCHED THEN
    INSERT (PONumber, ManualPONumber, StoreId, VendorId, POValidityDate, Subject, Instructions, TermsAndConditions, Status, TotalQuantity, TotalAmount, IsActive, CreatedOn, ModifiedOn)
    VALUES (s2.PONumber, s2.ManualPONumber, s2.StoreId, s2.VendorId, s2.POValidityDate, s2.Subject, s2.Instructions, s2.TermsAndConditions, s2.Status, s2.TotalQuantity, s2.TotalAmount, s2.IsActive, s2.CreatedOn, s2.ModifiedOn)
OUTPUT s2.OldId, inserted.PurchaseOrderId INTO #PurchaseOrderMap(OldId, NewId);

PRINT 'Phase 4: PurchaseOrderItems';
INSERT INTO Inv.PurchaseOrderItems (PurchaseOrderId, ItemId, UnitQuantity, UnitPrice, TotalPrice, IsActive, CreatedOn, ModifiedOn)
SELECT po.NewId, i.NewId, src.Quantity, src.Price, (src.Quantity * src.Price), src.IsActive, src.CreatedOn, src.ModifiedOn
FROM iHealthCure.dbo.PurchaseOrderItems src
JOIN #PurchaseOrderMap po ON po.OldId = src.PurchaseOrderId
JOIN #ItemMap i ON i.OldId = src.ItemId;

PRINT 'Phase 4 complete.';

-- =============================================================================
-- PHASE 5: Inventories (GRN-equivalent) / InventoryItems
-- =============================================================================

PRINT 'Phase 5: Inventories';
CREATE TABLE #InventoryMap (OldId UNIQUEIDENTIFIER PRIMARY KEY, NewId INT);
MERGE INTO Inv.Inventories AS tgt
USING (
    SELECT src.Id AS OldId, src.PurchaseOrderNumber, src.InvoiceNo, po.NewId AS PurchaseOrderId,
        ISNULL(v.NewId, (SELECT MIN(Id) FROM Inv.Vendors)) AS VendorId,
        ISNULL(s.NewId, (SELECT MIN(Id) FROM Pharmacy.PharmacyStores)) AS StoreId,
        src.IsActive, src.CreatedOn, src.ModifiedOn,
        CASE WHEN src.IsFinalized = 1 THEN 1 ELSE 0 END AS IsFinalized,
        st.NewId AS StockTypeId, src.VendorInvoiceNumber, src.VendorInvoiceTimestamp, src.Amount, src.Discount,
        src.DiscountType, src.Total, src.PaidAmount, src.PaymentStatusId, src.TotalPaidAmount,
        src.IsPaymentPending, src.TotalBuyingPrice, src.ReceiptPath, src.AdvanceTaxPercentage,
        src.AdvanceTaxCalculatedAmount, src.RetailCharges, src.RetailChargesType, src.GSTCharges,
        src.RetailChargesCalculatedAmount, src.GSTChargesCalculatedAmount, src.ManualPurchaseOrderNumber
    FROM iHealthCure.dbo.Inventories src
    LEFT JOIN #PurchaseOrderMap po ON po.OldId = src.PurchaseOrderId
    LEFT JOIN #VendorMap v ON v.OldId = src.VendorId
    LEFT JOIN #StoreMap s ON s.OldId = src.StoreId
    LEFT JOIN #StockTypeMap st ON st.OldId = src.StockTypeId
) AS s2
ON 1 = 0
WHEN NOT MATCHED THEN
    INSERT (
        PurchaseOrderNumber, InvoiceNo, PurchaseOrderId, VendorId, StoreId, BranchId, IsActive,
        CreatedOn, ModifiedOn, IsFinalized, StockTypeId, VendorInvoiceNumber, VendorInvoiceTimestamp,
        Amount, Discount, DiscountType, Total, PaidAmount, PaymentStatusId, TotalPaidAmount,
        IsPaymentPending, TotalBuyingPrice, ReceiptPath, AdvanceTaxPercentage,
        AdvanceTaxCalculatedAmount, RetailCharges, RetailChargesType, GSTCharges,
        RetailChargesCalculatedAmount, GSTChargesCalculatedAmount, ManualPurchaseOrderNumber
    )
    VALUES (
        s2.PurchaseOrderNumber, s2.InvoiceNo, s2.PurchaseOrderId, s2.VendorId, s2.StoreId, @MainBranchId, s2.IsActive,
        s2.CreatedOn, s2.ModifiedOn, s2.IsFinalized, s2.StockTypeId, s2.VendorInvoiceNumber, s2.VendorInvoiceTimestamp,
        s2.Amount, s2.Discount, s2.DiscountType, s2.Total, s2.PaidAmount, s2.PaymentStatusId, s2.TotalPaidAmount,
        s2.IsPaymentPending, s2.TotalBuyingPrice, s2.ReceiptPath, s2.AdvanceTaxPercentage,
        s2.AdvanceTaxCalculatedAmount, s2.RetailCharges, s2.RetailChargesType, s2.GSTCharges,
        s2.RetailChargesCalculatedAmount, s2.GSTChargesCalculatedAmount, s2.ManualPurchaseOrderNumber
    )
OUTPUT s2.OldId, inserted.Id INTO #InventoryMap(OldId, NewId);

PRINT 'Phase 5: InventoryItems';
INSERT INTO Inv.InventoryItems (
    InventoryId, ItemId, ManufacturerId, ManufacturingDate, ExpiryDate, RegistrationNumber,
    LotNumber, Batch, NumberOfPackets, ItemsPerPacket, TotalItems, TotalBuyingPriceId,
    UnitBuyingPriceId, UnitSellingPriceId, TotalSellingPriceId, BranchId, IsActive, CreatedOn,
    ModifiedOn, NumberOfBoxes, StockTypeId, SysBatchNo, BalanceTotalItems, Amount, Discount,
    DiscountType, Total, RetailCharges, RetailChargesType, IsDeleted, AdvanceTaxPercentage,
    AdvanceTaxCalculatedAmount, GSTCharges, GSTChargesType, RetailChargesCalculatedAmount,
    GSTChargesCalculatedAmount, Preference
)
SELECT
    inv.NewId, i.NewId, ISNULL(m.NewId, (SELECT MIN(ManufacturerId) FROM Pharmacy.Manufacturers)),
    src.ManufacturingDate, src.ExpiryDate, src.RegistrationNumber, src.LotNumber, src.Batch,
    src.NumberOfPackets, src.ItemsPerPacket, src.TotalItems,
    0, 0, 0, 0, -- TotalBuyingPriceId/UnitBuyingPriceId/UnitSellingPriceId/TotalSellingPriceId:
                 -- these were FKs into a separate legacy Prices table we are not migrating;
                 -- left at 0 (not a real Prices.Id) since the target column is NOT NULL and
                 -- has no equivalent source of truth once Prices is out of scope.
    @MainBranchId, src.IsActive, src.CreatedOn, src.ModifiedOn, src.NumberOfBoxes,
    st.NewId, src.SysBatchNo, src.BalanceTotalItems, src.Amount, src.Discount, src.DiscountType,
    src.Total, src.RetailCharges, src.RetailChargesType, ISNULL(src.IsDeleted, 0),
    src.AdvanceTaxPercentage, src.AdvanceTaxCalculatedAmount, src.GSTCharges, src.GSTChargesType,
    src.RetailChargesCalculatedAmount, src.GSTChargesCalculatedAmount, src.Preference
FROM iHealthCure.dbo.InventoryItems src
JOIN #InventoryMap inv ON inv.OldId = src.InventoryId
JOIN #ItemMap i ON i.OldId = src.ItemId
LEFT JOIN #ManufacturerMap m ON m.OldId = src.ManufacturerId
LEFT JOIN #StockTypeMap st ON st.OldId = src.StockTypeId;

PRINT 'Phase 5 complete.';

-- =============================================================================
-- PHASE 6: Current stock balance (Inv.Stocks) <- PharmacyMedicinesStocks
-- =============================================================================

PRINT 'Phase 6: Stocks (current balance)';
INSERT INTO Inv.Stocks (ItemId, TotalItems, MinimumPanicLevel, BranchId, StoreId, IsActive, CreatedOn, ModifiedOn)
SELECT i.NewId, CAST(src.TotalItemsInStock AS INT), src.MinimumPanicLevel, @MainBranchId, s.NewId,
    1, src.CreatedOn, src.ModifiedOn
FROM iHealthCure.dbo.PharmacyMedicinesStocks src
JOIN #StoreMap s ON s.OldId = src.StoreId
JOIN #ItemMap i ON i.OldId = src.ItemId;

PRINT 'Phase 6 complete.';

-- =============================================================================
-- PHASE 7: StockConsumptions / StockConsumptionDetails
-- =============================================================================

PRINT 'Phase 7: StockConsumptions';
CREATE TABLE #StockConsumptionMap (OldId UNIQUEIDENTIFIER PRIMARY KEY, NewId INT);
MERGE INTO Inv.StockConsumptions AS tgt
USING (
    SELECT src.Id AS OldId, s.NewId AS StoreId, src.Type, src.IsActive, src.CreatedOn, src.ModifiedOn, ISNULL(src.IsDeleted, 0) AS IsDeleted, src.Remarks
    FROM iHealthCure.dbo.StockConsumptions src
    JOIN #StoreMap s ON s.OldId = src.StoreId
) AS s2
ON 1 = 0
WHEN NOT MATCHED THEN
    INSERT (StoreId, Type, BranchId, IsActive, CreatedOn, ModifiedOn, IsDeleted, Remarks)
    VALUES (s2.StoreId, s2.Type, @MainBranchId, s2.IsActive, s2.CreatedOn, s2.ModifiedOn, s2.IsDeleted, s2.Remarks)
OUTPUT s2.OldId, inserted.Id INTO #StockConsumptionMap(OldId, NewId);

PRINT 'Phase 7: StockConsumptionDetails';
INSERT INTO Inv.StockConsumptionDetails (StoreId, ItemId, Type, StockTypeId, Quantity, BranchId, SysBatchNo, BatchNo, IsActive, CreatedOn, ModifiedOn, IsDeleted, StockConsumptionId)
SELECT s.NewId, i.NewId, src.Type, ISNULL(st.NewId, (SELECT MIN(Id) FROM Inv.StockTypes)), src.Quantity,
    @MainBranchId, src.SysBatchNo, src.BatchNo, src.IsActive, src.CreatedOn, src.ModifiedOn,
    ISNULL(src.IsDeleted, 0), sc.NewId
FROM iHealthCure.dbo.StockConsumptionDetails src
JOIN #StoreMap s ON s.OldId = src.StoreId
JOIN #ItemMap i ON i.OldId = src.ItemId
LEFT JOIN #StockTypeMap st ON st.OldId = src.StockTypeId
LEFT JOIN #StockConsumptionMap sc ON sc.OldId = src.StockConsumptionId;

PRINT 'Phase 7 complete.';

-- =============================================================================
-- PHASE 8: StockAdjustments / StockAdjustmentDetails
-- =============================================================================

PRINT 'Phase 8: StockAdjustments';
CREATE TABLE #StockAdjustmentMap (OldId UNIQUEIDENTIFIER PRIMARY KEY, NewId INT);
MERGE INTO Inv.StockAdjustments AS tgt
USING (
    SELECT src.Id AS OldId, s.NewId AS StoreId, src.Type, src.IsActive, src.CreatedOn, src.ModifiedOn, ISNULL(src.IsDeleted, 0) AS IsDeleted
    FROM iHealthCure.dbo.StockAdjustments src
    JOIN #StoreMap s ON s.OldId = src.StoreId
) AS s2
ON 1 = 0
WHEN NOT MATCHED THEN
    INSERT (StoreId, Type, BranchId, IsActive, CreatedOn, ModifiedOn, IsDeleted)
    VALUES (s2.StoreId, s2.Type, @MainBranchId, s2.IsActive, s2.CreatedOn, s2.ModifiedOn, s2.IsDeleted)
OUTPUT s2.OldId, inserted.Id INTO #StockAdjustmentMap(OldId, NewId);

PRINT 'Phase 8: StockAdjustmentDetails';
INSERT INTO Inv.StockAdjustmentDetails (StockAdjustmentId, ItemId, Type, StockTypeId, Quantity, BranchId, CreatedOn, ModifiedOn, IsActive, IsDeleted, SysBatchNo, BatchNo)
SELECT sa.NewId, i.NewId, src.Type, ISNULL(st.NewId, (SELECT MIN(Id) FROM Inv.StockTypes)), src.Quantity,
    @MainBranchId, src.CreatedOn, src.ModifiedOn, 1, ISNULL(src.IsDeleted, 0), src.SysBatchNo, src.BatchNo
FROM iHealthCure.dbo.StockAdjustmentDetails src
JOIN #ItemMap i ON i.OldId = src.ItemId
LEFT JOIN #StockTypeMap st ON st.OldId = src.StockTypeId
JOIN #StockAdjustmentMap sa ON sa.OldId = src.StockAdjustmentId;

PRINT 'Phase 8 complete.';

-- =============================================================================
-- PHASE 9: DemandRequests / DemandRequestItems
-- =============================================================================

PRINT 'Phase 9: DemandRequests';
CREATE TABLE #DemandRequestMap (OldId UNIQUEIDENTIFIER PRIMARY KEY, NewId INT);
MERGE INTO Inv.DemandRequests AS tgt
USING (
    SELECT src.Id AS OldId,
        ISNULL(sTo.NewId, (SELECT MIN(Id) FROM Pharmacy.PharmacyStores)) AS RequestedToStoreId,
        dept.NewId AS RequestingDepartmentId, sFrom.NewId AS RequestingStoreId, src.DemandNotes,
        ISNULL(drs.NewId, (SELECT MIN(Id) FROM Inv.DemandRequestStatuses)) AS DemandRequestStatusId,
        src.DriverName, src.VehicleNumber, src.ContactNumber, src.Detail,
        src.DemandRequestNumber, src.IsManual, src.IsActive, src.CreatedOn, src.ModifiedOn,
        src.ApprovedDate, src.RejectedDate, src.IssuedDate, src.ReceivedDate, src.StockTypeId,
        src.TotalUnitBuyingPrice, src.LastTotalUnitBuyingPrice, src.RequestNumber, src.IndentNumber
    FROM iHealthCure.dbo.DemandRequests src
    LEFT JOIN #StoreMap sTo ON sTo.OldId = src.RequestedToStoreId
    LEFT JOIN #StoreMap sFrom ON sFrom.OldId = src.RequestingStoreId
    LEFT JOIN #DepartmentMap dept ON dept.OldId = src.RequestingDepartmentId
    LEFT JOIN #DRStatusMap drs ON drs.OldId = src.DemandRequestStatusId
) AS s2
ON 1 = 0
WHEN NOT MATCHED THEN
    INSERT (
        RequestedToStoreId, RequestingDepartmentId, RequestingStoreId, DemandNotes,
        DemandRequestStatusId, BranchId, DriverName, VehicleNumber, ContactNumber, Detail,
        DemandRequestNumber, IsManual, IsActive, CreatedOn, ModifiedOn, ApprovedDate, RejectedDate,
        IssuedDate, ReceivedDate, StockTypeId, TotalUnitBuyingPrice, LastTotalUnitBuyingPrice,
        RequestNumber, IndentNumber
    )
    VALUES (
        s2.RequestedToStoreId, s2.RequestingDepartmentId, s2.RequestingStoreId, s2.DemandNotes,
        s2.DemandRequestStatusId, @MainBranchId, s2.DriverName, s2.VehicleNumber, s2.ContactNumber, s2.Detail,
        s2.DemandRequestNumber, s2.IsManual, s2.IsActive, s2.CreatedOn, s2.ModifiedOn, s2.ApprovedDate, s2.RejectedDate,
        s2.IssuedDate, s2.ReceivedDate, s2.StockTypeId, s2.TotalUnitBuyingPrice, s2.LastTotalUnitBuyingPrice,
        s2.RequestNumber, s2.IndentNumber
    )
OUTPUT s2.OldId, inserted.Id INTO #DemandRequestMap(OldId, NewId);

PRINT 'Phase 9: DemandRequestItems';
INSERT INTO Inv.DemandRequestItems (DemandRequestId, ItemId, RequestedQuantity, ApprovedQuantity, IssuedQuantity, Notes, IsActive, CreatedOn)
SELECT dr.NewId, i.NewId, src.RequestedQuantity, src.ApprovedQuantity, src.IssuedQuantity, src.Remarks, src.IsActive, src.CreatedOn
FROM iHealthCure.dbo.DemandRequestItems src
JOIN #DemandRequestMap dr ON dr.OldId = src.DemandRequestId
JOIN #ItemMap i ON i.OldId = src.ItemId; -- target ItemId is NOT NULL; rows with no item match are dropped

PRINT 'Phase 9 complete.';

-- =============================================================================
-- PHASE 10: TransferInventory / TransferInventoryItems
-- Source (StockTransitions) is item-level and tied to a DemandRequest; target
-- is a simple header+lines transfer record. Grouped one header per source
-- DemandRequest+store-pair, with each transition row becoming a line.
-- =============================================================================

PRINT 'Phase 10: TransferInventory (grouped from StockTransitions)';
CREATE TABLE #TransferHeaderMap (OldDemandRequestId UNIQUEIDENTIFIER, OldFromStore UNIQUEIDENTIFIER, OldToStore UNIQUEIDENTIFIER, NewId INT);
MERGE INTO Inv.TransferInventory AS tgt
USING (
    SELECT g.DemandRequestId, g.RequestedStoreId, g.RequestingStoreId, g.FirstCreatedOn,
        ISNULL(sFrom.NewId, (SELECT MIN(Id) FROM Pharmacy.PharmacyStores)) AS FromStoreId,
        ISNULL(sTo.NewId, (SELECT MIN(Id) FROM Pharmacy.PharmacyStores)) AS ToStoreId
    FROM (
        SELECT DemandRequestId, RequestedStoreId, RequestingStoreId, MIN(CreatedOn) AS FirstCreatedOn
        FROM iHealthCure.dbo.StockTransitions
        GROUP BY DemandRequestId, RequestedStoreId, RequestingStoreId
    ) g
    LEFT JOIN #StoreMap sFrom ON sFrom.OldId = g.RequestedStoreId
    LEFT JOIN #StoreMap sTo ON sTo.OldId = g.RequestingStoreId
) AS s2
ON 1 = 0
WHEN NOT MATCHED THEN
    INSERT (FromStoreId, ToStoreId, BranchId, TransferDate, Status, IsActive, CreatedOn)
    VALUES (s2.FromStoreId, s2.ToStoreId, @MainBranchId, s2.FirstCreatedOn, 'Migrated', 1, s2.FirstCreatedOn)
OUTPUT s2.DemandRequestId, s2.RequestedStoreId, s2.RequestingStoreId, inserted.Id
    INTO #TransferHeaderMap(OldDemandRequestId, OldFromStore, OldToStore, NewId);

PRINT 'Phase 10: TransferInventoryItems';
INSERT INTO Inv.TransferInventoryItems (TransferInventoryId, ItemId, Quantity, IsActive, CreatedOn)
SELECT th.NewId, i.NewId, src.TotalItemsInTransition, 1, src.CreatedOn
FROM iHealthCure.dbo.StockTransitions src
JOIN #ItemMap i ON i.OldId = src.ItemId
JOIN #TransferHeaderMap th ON th.OldDemandRequestId = src.DemandRequestId
    AND th.OldFromStore = src.RequestedStoreId AND th.OldToStore = src.RequestingStoreId;

PRINT 'Phase 10 complete.';

-- =============================================================================
-- PHASE 11: PurchaseRequisitions / PurchaseRequisitionItems
-- =============================================================================

PRINT 'Phase 11: PurchaseRequisitions';
CREATE TABLE #PurchaseRequisitionMap (OldId UNIQUEIDENTIFIER PRIMARY KEY, NewId INT);
MERGE INTO Inv.PurchaseRequisitions AS tgt
USING (
    SELECT src.Id AS OldId,
        ISNULL(src.PurchaseRequestNumber, CONVERT(NVARCHAR(50), src.Id)) AS PRNumber,
        dr.NewId AS DemandRequestId, src.DemandNo, s.NewId AS StoreId, src.DistributionPlan,
        ISNULL(src.Priority, 1) AS Priority, src.DateRequiredBy, ISNULL(src.PRType, 1) AS PRType,
        v.NewId AS VendorId, src.SuggestedProcurementMethod, src.Subject, src.ScopeOfWork,
        src.Instructions, src.PRRemarks AS Remarks, src.GoodsDeliveredContactPerson, src.GoodsDeliveredCellNumber,
        src.GoodsDeliveredEmail, src.GoodsDeliveredTelephone, src.GoodsDeliveredFaxNo,
        src.GoodsDeliveryAddress, src.TermsAndConditions, ISNULL(src.ExecutionType, 1) AS ExecutionType,
        ISNULL(src.IsRequestForQuation, 0) AS IsRequestForQuotation, src.RFQBidNumber, src.VendorQuoteNo, src.VendorQuoteDate,
        src.WorkOrderRequestNumber, ISNULL(src.IsTechnicalReviewed, 0) AS IsTechnicalReviewed,
        ISNULL(src.PGrandTotal, 0) AS TotalEstimatedCost, ISNULL(src.TotalBudget, 0) AS TotalBudget,
        ISNULL(prs.NewId, (SELECT MIN(Id) FROM Inv.PurchaseRequisitionStatus)) AS PurchaseRequisitionStatusId,
        ISNULL(src.IsClosed, 0) AS IsClosed, src.IsActive, src.CreatedOn, src.ModifiedOn
    FROM iHealthCure.dbo.PurchaseRequisitions src
    LEFT JOIN #DemandRequestMap dr ON dr.OldId = src.DemandRequestId
    LEFT JOIN #StoreMap s ON s.OldId = src.StoreId
    LEFT JOIN #VendorMap v ON v.OldId = src.VendorId
    LEFT JOIN #PRStatusMap prs ON prs.OldId = src.PurchaseRequisitionStatusId
) AS s2
ON 1 = 0
WHEN NOT MATCHED THEN
    INSERT (
        PRNumber, DemandRequestId, DemandNo, BranchId, StoreId, DistributionPlan, Priority,
        DateRequiredBy, PRType, VendorId, SuggestedProcurementMethod, Subject, ScopeOfWork,
        Instructions, Remarks, GoodsDeliveredContactPerson, GoodsDeliveredCellNumber,
        GoodsDeliveredEmail, GoodsDeliveredTelephone, GoodsDeliveredFaxNo, GoodsDeliveryAddress,
        TermsAndConditions, ExecutionType, IsRequestForQuotation, RFQBidNumber, VendorQuoteNo,
        VendorQuoteDate, WorkOrderRequestNumber, IsTechnicalReviewed, TotalEstimatedCost,
        TotalBudget, PurchaseRequisitionStatusId, IsClosed, IsActive, CreatedOn, ModifiedOn
    )
    VALUES (
        s2.PRNumber, s2.DemandRequestId, s2.DemandNo, @MainBranchId, s2.StoreId, s2.DistributionPlan, s2.Priority,
        s2.DateRequiredBy, s2.PRType, s2.VendorId, s2.SuggestedProcurementMethod, s2.Subject, s2.ScopeOfWork,
        s2.Instructions, s2.Remarks, s2.GoodsDeliveredContactPerson, s2.GoodsDeliveredCellNumber,
        s2.GoodsDeliveredEmail, s2.GoodsDeliveredTelephone, s2.GoodsDeliveredFaxNo, s2.GoodsDeliveryAddress,
        s2.TermsAndConditions, s2.ExecutionType, s2.IsRequestForQuotation, s2.RFQBidNumber, s2.VendorQuoteNo,
        s2.VendorQuoteDate, s2.WorkOrderRequestNumber, s2.IsTechnicalReviewed, s2.TotalEstimatedCost,
        s2.TotalBudget, s2.PurchaseRequisitionStatusId, s2.IsClosed, s2.IsActive, s2.CreatedOn, s2.ModifiedOn
    )
OUTPUT s2.OldId, inserted.Id INTO #PurchaseRequisitionMap(OldId, NewId);

PRINT 'Phase 11: PurchaseRequisitionItems';
INSERT INTO Inv.PurchaseRequisitionItems (PurchaseRequisitionId, ItemId, Quantity, UnitEstimatedCost, TotalEstimatedCost, AvailableBudget, BudgetRestriction, Remarks, IsActive, CreatedOn, ModifiedOn, IsDeleted)
SELECT pr.NewId, i.NewId, ISNULL(src.Quantity, 0), ISNULL(src.Price, 0), ISNULL(src.TotalPrice, 0),
    src.AvaliableBudget, src.BudgetRectriction, src.POIRemarks, src.IsActive, src.CreatedOn, src.ModifiedOn, ISNULL(src.IsDeleted, 0)
FROM iHealthCure.dbo.PurchaseRequisitionItems src
JOIN #PurchaseRequisitionMap pr ON pr.OldId = src.PurchaseRequisitionId
LEFT JOIN #ItemMap i ON i.OldId = src.ItemId
WHERE i.NewId IS NOT NULL; -- target ItemId is nullable but rows without any item aren't useful

PRINT 'Phase 11 complete.';

-- =============================================================================
-- PHASE 12: StockTypeAssociations
-- =============================================================================

PRINT 'Phase 12: StockTypeAssociations';
INSERT INTO Inv.StockTypeAssociations (StoreId, StockTypeId, PharmacyStoreId, StockTypes, PatientTypes, IsActive, CreatedOn)
SELECT s.NewId, ISNULL(src.StockTypes, (SELECT MIN(Id) FROM Inv.StockTypes)), s.NewId, src.StockTypes, src.PatientTypes,
    CASE WHEN src.IsActive = 1 THEN 1 ELSE 0 END, src.CreatedOn
FROM iHealthCure.dbo.StockTypeAssociations src
JOIN #StoreMap s ON s.OldId = src.PharmacyStoreId;

PRINT 'Phase 12 complete.';

-- =============================================================================
-- Cleanup
-- =============================================================================
DROP TABLE IF EXISTS #StockTypeMap, #ItemTypeMap, #ItemUnitMap, #CategoryMap, #BrandMap,
    #VendorMap, #ManufacturerMap, #POTypeMap, #POStatusMap, #PRStatusMap, #DRStatusMap,
    #SurgicalGroupMap, #DepartmentMap, #ItemMap, #StoreMap, #RackMap, #RackRowMap,
    #RackColumnMap, #PurchaseOrderMap, #InventoryMap, #StockConsumptionMap,
    #StockAdjustmentMap, #DemandRequestMap, #TransferHeaderMap, #PurchaseRequisitionMap;

PRINT '=== Migration complete ===';
