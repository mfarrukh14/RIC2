USE InventoryManagementDB_SP;
GO

-- =============================================
-- 1. PurchaseSummary_GetAll - Get all purchase summary records with filters
--
-- NOTE: this tracked file had drifted from what's actually deployed (a stub
-- reading the empty Inv.PurchaseSummaries table, with most output columns
-- hardcoded to NULL/0 and several filter params ignored entirely). The block
-- below is the real, currently-deployed implementation, re-synced from the
-- live database (HMSMAIN_TF) plus the Inventory Date Range fix described below.
--
-- Sourced from the real GRN item-level data (Inv.GRNItems / Inv.GoodsReceivingNotes),
-- not the empty Inv.PurchaseSummaries stub table.
--
-- Logic ported from the old iHealthCure system's USP_GetNetPurchaseSummary
-- (Inventories/InventoryItems -> our GoodsReceivingNotes/GRNItems), kept
-- behaviorally identical despite the renamed tables:
--   - "Invoice Date Range" filters the GRN's own date (old: Inventory.CreatedOn,
--     here: GoodsReceivingNotes.DateAndTime - the field that plays that role in
--     the new schema's naming).
--   - "Inventory Date Range" was originally meant to filter the linked Purchase
--     Order's CreatedOn (old: po.CreatedOn) - the naming is swapped from what
--     you'd expect, matching the old system exactly, not a typo.
--   - @ReportType is NOT about which date range applies - it filters whether the
--     GRN has a PO number attached: 'PurchaseOrder' = has one, 'Inventory' = does
--     not, NULL/'Both' = no filter.
--   - Total = Qty * UnitPrice + AdvanceTax. Discount is NOT subtracted from Total
--     (matches the old system's TotalPrice formula exactly - Discount is a
--     separate, informational column).
--
-- FIX: "Inventory Date Range" filtering on po.CreatedOn alone was a no-op in
-- practice - only 2 of 30,567 active GoodsReceivingNotes rows have a linked
-- PurchaseOrder at all, so po.CreatedOn is NULL on ~100% of rows and the filter
-- silently excluded almost everything the moment either date bound was set (same
-- bug as PurchaseSummaryInvoice_GetAll - see that file's header for the fuller
-- writeup). Falls back to GoodsReceivingNotes.CreatedOn (a real column populated
-- on every row) when there's no linked PO, while still preferring the PO's
-- CreatedOn on the handful of rows that do have one.
--
-- ADDED: @VendorId filter (this report previously had no vendor filter at all -
-- VendorName only ever appeared as an unfilterable display column). Uses the
-- same name-fallback as PurchaseSummaryInvoice_GetAll's @VendorId fix: only 2 of
-- 30,567 rows have a live VendorId FK, the rest carry only the migrated
-- GoodsReceivingNotes.DenormalizedVendorName text, so the selected @VendorId is
-- resolved to its catalog name once and matched against that text too.
--
-- MIGRATED-DATA support (see MigratePurchaseSummary_iHealthCure_HMSMAIN_TF.sql):
--   - Old system UNIONed three separate item source tables (Items/BranchMedicines/
--     BranchFees) keyed by a TypeBit (4/5/15). The migration could only build a
--     safe live FK for the "Items" case (13% of rows) - Medicine/Fee purchases
--     (87%) are migrated with GRNItems.SourceType set and their name carried as
--     plain text in GRNItems.DenormalizedItemName, with no Inv.Items row at all.
--     Items is therefore LEFT JOINed (was INNER), and ItemName/ItemTypeName fall
--     back to the denormalized text / SourceType so migrated Medicine/Fee rows
--     still show up instead of being silently dropped.
--   - @ItemType has no separate "Fee" bucket in the UI (only All/Medicine/
--     Disposable/Item) - Fee-typed rows fall into the "Item" bucket, same as
--     any other non-Medicine/non-Disposable row.
--   - VendorName falls back to GoodsReceivingNotes.DenormalizedVendorName when
--     VendorId has no live match (see migration script header for why Vendors
--     couldn't get a safe FK - not invented here, just not dropped).
--   - StoreName/StoreId fall back to GoodsReceivingNotes.StoreId when there is
--     no linked Purchase Order to resolve a store through (the old Inventories
--     table had its own direct StoreId; migrated rows preserve that here).
--
-- Old system INNER JOINed Manufacturers too - not surfaced in this report's
-- output at all, so no join is needed for it either way.
--
-- Paginated - see PaginationHelper.cs / PurchaseSummaryInvoice_GetAll for the
-- shared convention. @PageNumber/@PageSize default to page 1 of 10 and apply
-- only to the records result set below; the totals result set that follows
-- always sums over the full filtered set regardless of which page is showing.
-- =============================================
CREATE OR ALTER PROCEDURE PurchaseSummary_GetAll
    @BranchId INT = NULL,
    @StoreId INT = NULL,
    @ItemTypeId INT = NULL,
    @ItemType NVARCHAR(50) = NULL,
    @InvoiceDateStart DATETIME = NULL,
    @InvoiceDateEnd DATETIME = NULL,
    @InventoryDateStart DATETIME = NULL,
    @InventoryDateEnd DATETIME = NULL,
    @ItemId INT = NULL,
    @VendorId INT = NULL,
    @InvoiceNo NVARCHAR(100) = NULL,
    @ReportType NVARCHAR(50) = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (CASE WHEN @PageNumber < 1 THEN 0 ELSE @PageNumber - 1 END) * (CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END);
    DECLARE @Take INT = CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END;
    DECLARE @VendorName NVARCHAR(255) = (SELECT Name FROM Inv.Vendors WHERE Id = @VendorId);

    SELECT
        gi.Id,
        g.DateAndTime AS PurchaseDate,
        gi.BatchNo,
        gi.ItemId,
        COALESCE(i.Name, gi.DenormalizedItemName, '(item not found)') AS ItemName,
        ISNULL(po.StoreId, g.StoreId) AS StoreId,
        s.StoreName,
        g.VendorId,
        COALESCE(v.Name, g.DenormalizedVendorName) AS VendorName,
        g.InvoiceNo,
        g.DateAndTime AS InvoiceDate,
        ISNULL(gi.ReceivedQuantity, 0) AS Quantity,
        ISNULL(gi.UnitBuyingPrice, 0) AS Amount,
        ISNULL(gi.AdvanceTaxAmount, 0) AS AdvanceTax,
        ISNULL(gi.DiscountAmount, 0) AS Discount,
        (ISNULL(gi.ReceivedQuantity, 0) * ISNULL(gi.UnitBuyingPrice, 0)) + ISNULL(gi.AdvanceTaxAmount, 0) AS TotalPrice,
        s.BranchId,
        b.Name AS BranchName,
        i.ItemTypeId,
        COALESCE(it.Name, CASE WHEN gi.SourceType IN ('Medicine', 'Fee') THEN gi.SourceType ELSE NULL END) AS ItemTypeName,
        @ReportType AS ReportType,
        COUNT(*) OVER() AS TotalCount
    FROM Inv.GRNItems gi
    JOIN Inv.GoodsReceivingNotes g ON gi.GRNId = g.Id
    LEFT JOIN Inv.Items i ON gi.ItemId = i.Id
    LEFT JOIN Inv.PurchaseOrders po ON g.PurchaseOrderId = po.PurchaseOrderId
    LEFT JOIN Inv.PharmacyStores s ON ISNULL(po.StoreId, g.StoreId) = s.StoreId
    LEFT JOIN Inv.Branches b ON s.BranchId = b.Id
    LEFT JOIN Inv.Vendors v ON g.VendorId = v.Id
    LEFT JOIN Inv.ItemTypes it ON i.ItemTypeId = it.Id
    WHERE g.IsActive = 1
        AND (@BranchId IS NULL OR s.BranchId = @BranchId)
        AND (@StoreId IS NULL OR ISNULL(po.StoreId, g.StoreId) = @StoreId)
        AND (@ItemTypeId IS NULL OR i.ItemTypeId = @ItemTypeId)
        AND (
            @ItemType IS NULL OR @ItemType = 'All'
            OR (@ItemType = 'Medicine' AND (it.Name = 'Medicine' OR gi.SourceType = 'Medicine'))
            OR (@ItemType = 'Disposable' AND it.Name = 'Disposables')
            OR (@ItemType = 'Item' AND gi.SourceType <> 'Medicine' AND ISNULL(it.Name, '') <> 'Disposables')
        )
        AND (@ItemId IS NULL OR gi.ItemId = @ItemId)
        AND (@VendorId IS NULL OR g.VendorId = @VendorId OR g.DenormalizedVendorName = @VendorName)
        AND (@InvoiceNo IS NULL OR g.InvoiceNo LIKE '%' + @InvoiceNo + '%')
        AND (@InvoiceDateStart IS NULL OR g.DateAndTime >= @InvoiceDateStart)
        AND (@InvoiceDateEnd IS NULL OR g.DateAndTime <= @InvoiceDateEnd)
        AND (@InventoryDateStart IS NULL OR ISNULL(po.CreatedOn, g.CreatedOn) >= @InventoryDateStart)
        AND (@InventoryDateEnd IS NULL OR ISNULL(po.CreatedOn, g.CreatedOn) <= @InventoryDateEnd)
        AND (
            @ReportType IS NULL OR @ReportType = 'Both'
            OR (@ReportType = 'PurchaseOrder' AND ISNULL(g.PONumber, '') <> '')
            OR (@ReportType = 'Inventory' AND ISNULL(g.PONumber, '') = '')
        )
    ORDER BY g.DateAndTime DESC, gi.Id DESC
    OFFSET @Offset ROWS FETCH NEXT @Take ROWS ONLY;

    -- Return summary totals (same filters, NOT paginated - always the full filtered scope)
    SELECT
        ISNULL(SUM(ISNULL(gi.ReceivedQuantity, 0)), 0) AS TotalQuantity,
        ISNULL(SUM(ISNULL(gi.UnitBuyingPrice, 0)), 0) AS TotalAmount,
        ISNULL(SUM(ISNULL(gi.AdvanceTaxAmount, 0)), 0) AS TotalAdvanceTax,
        ISNULL(SUM(ISNULL(gi.DiscountAmount, 0)), 0) AS TotalDiscount,
        ISNULL(SUM((ISNULL(gi.ReceivedQuantity, 0) * ISNULL(gi.UnitBuyingPrice, 0)) + ISNULL(gi.AdvanceTaxAmount, 0)), 0) AS TotalPrice
    FROM Inv.GRNItems gi
    JOIN Inv.GoodsReceivingNotes g ON gi.GRNId = g.Id
    LEFT JOIN Inv.Items i ON gi.ItemId = i.Id
    LEFT JOIN Inv.PurchaseOrders po ON g.PurchaseOrderId = po.PurchaseOrderId
    LEFT JOIN Inv.PharmacyStores s ON ISNULL(po.StoreId, g.StoreId) = s.StoreId
    LEFT JOIN Inv.ItemTypes it ON i.ItemTypeId = it.Id
    WHERE g.IsActive = 1
        AND (@BranchId IS NULL OR s.BranchId = @BranchId)
        AND (@StoreId IS NULL OR ISNULL(po.StoreId, g.StoreId) = @StoreId)
        AND (@ItemTypeId IS NULL OR i.ItemTypeId = @ItemTypeId)
        AND (
            @ItemType IS NULL OR @ItemType = 'All'
            OR (@ItemType = 'Medicine' AND (it.Name = 'Medicine' OR gi.SourceType = 'Medicine'))
            OR (@ItemType = 'Disposable' AND it.Name = 'Disposables')
            OR (@ItemType = 'Item' AND gi.SourceType <> 'Medicine' AND ISNULL(it.Name, '') <> 'Disposables')
        )
        AND (@ItemId IS NULL OR gi.ItemId = @ItemId)
        AND (@VendorId IS NULL OR g.VendorId = @VendorId OR g.DenormalizedVendorName = @VendorName)
        AND (@InvoiceNo IS NULL OR g.InvoiceNo LIKE '%' + @InvoiceNo + '%')
        AND (@InvoiceDateStart IS NULL OR g.DateAndTime >= @InvoiceDateStart)
        AND (@InvoiceDateEnd IS NULL OR g.DateAndTime <= @InvoiceDateEnd)
        AND (@InventoryDateStart IS NULL OR ISNULL(po.CreatedOn, g.CreatedOn) >= @InventoryDateStart)
        AND (@InventoryDateEnd IS NULL OR ISNULL(po.CreatedOn, g.CreatedOn) <= @InventoryDateEnd)
        AND (
            @ReportType IS NULL OR @ReportType = 'Both'
            OR (@ReportType = 'PurchaseOrder' AND ISNULL(g.PONumber, '') <> '')
            OR (@ReportType = 'Inventory' AND ISNULL(g.PONumber, '') = '')
        );
END
GO

-- =============================================
-- 2. PurchaseSummary_GetById
-- =============================================
CREATE OR ALTER PROCEDURE PurchaseSummary_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ps.Id,
        ps.SummaryDate        AS PurchaseDate,
        CAST(NULL AS NVARCHAR(100)) AS BatchNo,
        CAST(0 AS INT)        AS ItemId,
        CAST('' AS NVARCHAR(MAX)) AS ItemName,
        ps.StoreId,
        s.StoreName           AS StoreName,
        ps.VendorId,
        v.Name                AS VendorName,
        CAST(NULL AS NVARCHAR(100)) AS InvoiceNo,
        CAST(NULL AS DATETIME) AS InvoiceDate,
        CAST(0 AS INT)        AS Quantity,
        CAST(0 AS DECIMAL(18,2)) AS Amount,
        CAST(NULL AS DECIMAL(18,2)) AS AdvanceTax,
        CAST(NULL AS DECIMAL(18,2)) AS Discount,
        ps.TotalAmount        AS TotalPrice,
        ps.BranchId,
        b.BranchName          AS BranchName,
        CAST(NULL AS INT)     AS ItemTypeId,
        CAST(NULL AS NVARCHAR(MAX)) AS ItemTypeName,
        CAST(NULL AS NVARCHAR(50))  AS ReportType
    FROM Inv.PurchaseSummaries ps
    LEFT JOIN dbo.Branch b ON ps.BranchId = b.BranchId
    LEFT JOIN Inv.Stores s   ON ps.StoreId  = s.StoreId
    LEFT JOIN Inv.Vendors v  ON ps.VendorId = v.Id
    WHERE ps.Id = @Id;
END
GO

-- =============================================
-- 3. PurchaseSummary_Insert
-- =============================================
CREATE OR ALTER PROCEDURE PurchaseSummary_Insert
    @PurchaseDate DATETIME,
    @BatchNo NVARCHAR(100) = NULL,
    @ItemId INT = 0,
    @ItemName NVARCHAR(MAX) = '',
    @StoreId INT = NULL,
    @StoreName NVARCHAR(MAX) = NULL,
    @VendorId INT = NULL,
    @VendorName NVARCHAR(MAX) = NULL,
    @InvoiceNo NVARCHAR(100) = NULL,
    @InvoiceDate DATETIME = NULL,
    @Quantity INT = 0,
    @Amount DECIMAL(18, 2) = 0,
    @AdvanceTax DECIMAL(18, 2) = NULL,
    @Discount DECIMAL(18, 2) = NULL,
    @TotalPrice DECIMAL(18, 2),
    @BranchId INT = NULL,
    @ItemTypeId INT = NULL,
    @ReportType NVARCHAR(50) = NULL,
    @CreatedById INT = 1
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Inv.PurchaseSummaries (
        SummaryDate, StoreId, VendorId, TotalAmount,
        BranchId, Notes, Status,
        IsActive, CreatedById, CreatedOn
    )
    VALUES (
        @PurchaseDate, @StoreId, @VendorId, @TotalPrice,
        @BranchId, '', 'Active',
        1, @CreatedById, GETDATE()
    );

    SELECT SCOPE_IDENTITY() AS Id;
END
GO

-- =============================================
-- 4. PurchaseSummary_Update
-- =============================================
CREATE OR ALTER PROCEDURE PurchaseSummary_Update
    @Id INT,
    @PurchaseDate DATETIME,
    @BatchNo NVARCHAR(100) = NULL,
    @ItemId INT = 0,
    @ItemName NVARCHAR(MAX) = '',
    @StoreId INT = NULL,
    @StoreName NVARCHAR(MAX) = NULL,
    @VendorId INT = NULL,
    @VendorName NVARCHAR(MAX) = NULL,
    @InvoiceNo NVARCHAR(100) = NULL,
    @InvoiceDate DATETIME = NULL,
    @Quantity INT = 0,
    @Amount DECIMAL(18, 2) = 0,
    @AdvanceTax DECIMAL(18, 2) = NULL,
    @Discount DECIMAL(18, 2) = NULL,
    @TotalPrice DECIMAL(18, 2),
    @BranchId INT = NULL,
    @ItemTypeId INT = NULL,
    @ReportType NVARCHAR(50) = NULL,
    @ModifiedById INT = 1
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Inv.PurchaseSummaries
    SET
        SummaryDate  = @PurchaseDate,
        StoreId      = @StoreId,
        VendorId     = @VendorId,
        TotalAmount  = @TotalPrice,
        BranchId     = @BranchId,
        ModifiedById = @ModifiedById,
        ModifiedOn   = GETDATE()
    WHERE Id = @Id;

    SELECT @@ROWCOUNT AS RowsAffected;
END
GO

-- =============================================
-- 5. PurchaseSummary_Delete
-- =============================================
CREATE OR ALTER PROCEDURE PurchaseSummary_Delete
    @Id INT,
    @ModifiedById INT = 1
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Inv.PurchaseSummaries
    SET
        IsActive     = 0,
        ModifiedById = @ModifiedById,
        ModifiedOn   = GETDATE()
    WHERE Id = @Id;

    SELECT @@ROWCOUNT AS RowsAffected;
END
GO

-- =============================================
-- 6. PurchaseSummary_GetLookupData
-- =============================================
CREATE OR ALTER PROCEDURE PurchaseSummary_GetLookupData
AS
BEGIN
    SET NOCOUNT ON;

    -- Branches
    SELECT BranchId AS Id, BranchName AS Name
    FROM dbo.Branch
    WHERE IsActive = 1
    ORDER BY Name;

    -- Stores
    SELECT StoreId AS Id, StoreName AS Name
    FROM Inv.Stores
    WHERE IsActive = 1
    ORDER BY StoreName;

    -- Item Types
    SELECT Id, Name
    FROM Inv.ItemTypes
    WHERE IsActive = 1
    ORDER BY Name;

    -- Vendors
    SELECT Id, Name
    FROM Inv.Vendors
    WHERE IsActive = 1
    ORDER BY Name;

    -- Items
    SELECT Id, Name
    FROM Inv.Items
    WHERE IsActive = 1
    ORDER BY Name;
END
GO

PRINT 'All PurchaseSummary stored procedures created successfully';
