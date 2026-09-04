USE InventoryManagementDB_SP;
GO

-- =============================================
-- 1. PurchaseSummaryInvoice_GetAll
--
-- NOTE: this tracked file had drifted from what's actually deployed (a stub
-- reading the empty Inv.PurchaseSummaryInvoices table, ignoring most filter
-- params entirely). The block below is the real, currently-deployed
-- implementation, re-synced from the live database (HMSMAIN_TF) plus the
-- Inventory Date Range fix described below.
--
-- Invoice/header-wise view - one row per GRN (goods receiving note), aggregating
-- its item lines - as opposed to PurchaseSummary_GetAll which is one row per item
-- line. Sourced from the real GRN data instead of the empty
-- Inv.PurchaseSummaryInvoices stub table (1 row, no vendor/branch/store detail).
--
-- Logic ported from the old iHealthCure system's
-- USP_Inventory_GETNetPurchaseSummaryInvoiceWiseReport (Inventories -> our
-- GoodsReceivingNotes), same date-range/report-type semantics as
-- PurchaseSummary_GetAll (see that file's header comment for why "Invoice Date
-- Range" uses the GRN's own date while "Inventory Date Range" was originally
-- meant to use the linked Purchase Order's CreatedOn).
--
-- FIX: "Inventory Date Range" filtering on po.CreatedOn alone was a no-op in
-- practice - only 2 of 30,567 active GoodsReceivingNotes rows have a linked
-- PurchaseOrder at all, so po.CreatedOn is NULL on ~100% of rows and the filter
-- silently excluded almost everything the moment either date bound was set.
-- Falls back to GoodsReceivingNotes.CreatedOn (a real column that's populated
-- on every row) when there's no linked PO, while still preferring the PO's
-- CreatedOn on the handful of rows that do have one.
--
-- FIX: same problem, different column - filtering by @VendorId = g.VendorId
-- alone was a near-total no-op too, since only 2 of 30,567 rows have a live
-- VendorId FK; the other 30,564 only carry the migrated
-- GoodsReceivingNotes.DenormalizedVendorName text (see
-- MigratePurchaseSummary_iHealthCure_HMSMAIN_TF.sql header - Vendors couldn't
-- get a safe FK match at migration time). Every one of the 524 distinct
-- denormalized vendor names has an exact match in Inv.Vendors, so the selected
-- @VendorId is resolved to its name once and compared against
-- DenormalizedVendorName as a fallback, the same way VendorName is already
-- displayed via COALESCE(v.Name, g.DenormalizedVendorName) below.
--
-- Old system stored a header-level Amount/Total/Discount directly on the
-- Inventory row. The new schema only has item-level figures (Inv.GRNItems), so
-- this aggregates them per GRN instead - same end result (invoice totals), just
-- computed bottom-up rather than read off a pre-saved header field. The old
-- system's PurchaseOrderReturns union branch (negative adjustment rows for
-- purchase returns against an invoice) has no equivalent table in the new schema
-- yet, so it isn't included here.
--
-- Paginated - see PaginationHelper.cs / GRN_GetAll for the shared convention.
-- @PageNumber/@PageSize default to page 1 of 10 and apply only to the records
-- result set below; the totals result set that follows always sums over the
-- full filtered set regardless of which page is showing.
-- =============================================
CREATE OR ALTER PROCEDURE PurchaseSummaryInvoice_GetAll
    @BranchId INT = NULL,
    @StoreId INT = NULL,
    @InventoryDateStart DATETIME = NULL,
    @InventoryDateEnd DATETIME = NULL,
    @VendorId INT = NULL,
    @InvoiceDateStart DATETIME = NULL,
    @InvoiceDateEnd DATETIME = NULL,
    @InvoiceNo NVARCHAR(100) = NULL,
    @ReportType NVARCHAR(50) = NULL,
    @InvoiceType NVARCHAR(50) = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (CASE WHEN @PageNumber < 1 THEN 0 ELSE @PageNumber - 1 END) * (CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END);
    DECLARE @Take INT = CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END;
    DECLARE @VendorName NVARCHAR(255) = (SELECT Name FROM Inv.Vendors WHERE Id = @VendorId);

    SELECT
        g.Id,
        ISNULL(g.DateAndTime, g.CreatedOn) AS InvoiceDate,
        ISNULL(g.InvoiceNo, '') AS InvoiceNo,
        g.VendorId,
        COALESCE(v.Name, g.DenormalizedVendorName) AS VendorName,
        ISNULL(agg.Amount, 0) AS Amount,
        ISNULL(agg.AdvanceTax, 0) AS AdvanceTax,
        ISNULL(agg.Discount, 0) AS Discount,
        ISNULL(agg.TotalPrice, 0) AS TotalAmount,
        s.BranchId,
        b.Name AS BranchName,
        ISNULL(po.StoreId, g.StoreId) AS StoreId,
        s.StoreName,
        ISNULL(po.CreatedOn, g.CreatedOn) AS InventoryDate,
        @ReportType AS ReportType,
        CAST(NULL AS NVARCHAR(50)) AS InvoiceType,
        COUNT(*) OVER() AS TotalCount
    FROM Inv.GoodsReceivingNotes g
    LEFT JOIN Inv.PurchaseOrders po ON g.PurchaseOrderId = po.PurchaseOrderId
    LEFT JOIN Inv.PharmacyStores s ON ISNULL(po.StoreId, g.StoreId) = s.StoreId
    LEFT JOIN Inv.Branches b ON s.BranchId = b.Id
    LEFT JOIN Inv.Vendors v ON g.VendorId = v.Id
    OUTER APPLY (
        SELECT
            SUM(ISNULL(gi.ReceivedQuantity, 0) * ISNULL(gi.UnitBuyingPrice, 0)) AS Amount,
            SUM(ISNULL(gi.AdvanceTaxAmount, 0)) AS AdvanceTax,
            SUM(ISNULL(gi.DiscountAmount, 0)) AS Discount,
            SUM((ISNULL(gi.ReceivedQuantity, 0) * ISNULL(gi.UnitBuyingPrice, 0)) + ISNULL(gi.AdvanceTaxAmount, 0)) AS TotalPrice
        FROM Inv.GRNItems gi
        WHERE gi.GRNId = g.Id
    ) agg
    WHERE g.IsActive = 1
        AND (@BranchId IS NULL OR s.BranchId = @BranchId)
        AND (@StoreId IS NULL OR ISNULL(po.StoreId, g.StoreId) = @StoreId)
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
    ORDER BY ISNULL(g.DateAndTime, g.CreatedOn) DESC, g.Id DESC
    OFFSET @Offset ROWS FETCH NEXT @Take ROWS ONLY;

    -- Return summary totals (same filters, NOT paginated - always the full filtered scope)
    SELECT
        ISNULL(SUM(ISNULL(agg.Amount, 0)), 0) AS TotalAmount,
        ISNULL(SUM(ISNULL(agg.AdvanceTax, 0)), 0) AS TotalAdvanceTax,
        ISNULL(SUM(ISNULL(agg.Discount, 0)), 0) AS TotalDiscount,
        ISNULL(SUM(ISNULL(agg.TotalPrice, 0)), 0) AS GrandTotal
    FROM Inv.GoodsReceivingNotes g
    LEFT JOIN Inv.PurchaseOrders po ON g.PurchaseOrderId = po.PurchaseOrderId
    LEFT JOIN Inv.PharmacyStores s ON ISNULL(po.StoreId, g.StoreId) = s.StoreId
    OUTER APPLY (
        SELECT
            SUM(ISNULL(gi.ReceivedQuantity, 0) * ISNULL(gi.UnitBuyingPrice, 0)) AS Amount,
            SUM(ISNULL(gi.AdvanceTaxAmount, 0)) AS AdvanceTax,
            SUM(ISNULL(gi.DiscountAmount, 0)) AS Discount,
            SUM((ISNULL(gi.ReceivedQuantity, 0) * ISNULL(gi.UnitBuyingPrice, 0)) + ISNULL(gi.AdvanceTaxAmount, 0)) AS TotalPrice
        FROM Inv.GRNItems gi
        WHERE gi.GRNId = g.Id
    ) agg
    WHERE g.IsActive = 1
        AND (@BranchId IS NULL OR s.BranchId = @BranchId)
        AND (@StoreId IS NULL OR ISNULL(po.StoreId, g.StoreId) = @StoreId)
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
-- 2. PurchaseSummaryInvoice_GetById
-- =============================================
CREATE OR ALTER PROCEDURE PurchaseSummaryInvoice_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        psi.Id,
        psi.InvoiceDate,
        ISNULL(psi.InvoiceNumber, '') AS InvoiceNo,
        CAST(NULL AS INT)             AS VendorId,
        CAST(NULL AS NVARCHAR(MAX))   AS VendorName,
        ISNULL(psi.Amount, 0)         AS Amount,
        CAST(NULL AS DECIMAL(18,2))   AS AdvanceTax,
        CAST(NULL AS DECIMAL(18,2))   AS Discount,
        ISNULL(psi.Amount, 0)         AS TotalAmount,
        CAST(NULL AS INT)             AS BranchId,
        CAST(NULL AS NVARCHAR(MAX))   AS BranchName,
        CAST(NULL AS INT)             AS StoreId,
        CAST(NULL AS NVARCHAR(MAX))   AS StoreName,
        CAST(NULL AS DATETIME)        AS InventoryDate,
        CAST(NULL AS NVARCHAR(50))    AS ReportType,
        CAST(NULL AS NVARCHAR(50))    AS InvoiceType
    FROM Inv.PurchaseSummaryInvoices psi
    WHERE psi.Id = @Id;
END
GO

-- =============================================
-- 3. PurchaseSummaryInvoice_Insert
-- =============================================
CREATE OR ALTER PROCEDURE PurchaseSummaryInvoice_Insert
    @InvoiceDate DATETIME,
    @InvoiceNo NVARCHAR(100),
    @VendorId INT = NULL,
    @VendorName NVARCHAR(MAX) = NULL,
    @Amount DECIMAL(18, 2),
    @AdvanceTax DECIMAL(18, 2) = NULL,
    @Discount DECIMAL(18, 2) = NULL,
    @TotalAmount DECIMAL(18, 2),
    @BranchId INT = NULL,
    @StoreId INT = NULL,
    @InventoryDate DATETIME = NULL,
    @ReportType NVARCHAR(50) = NULL,
    @InvoiceType NVARCHAR(50) = NULL,
    @CreatedById INT = 1
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Inv.PurchaseSummaryInvoices (
        PurchaseSummaryId, InvoiceNumber, InvoiceDate,
        Amount, Notes, IsActive, CreatedOn
    )
    VALUES (
        0, @InvoiceNo, @InvoiceDate,
        @Amount, '', 1, GETDATE()
    );

    SELECT SCOPE_IDENTITY() AS Id;
END
GO

-- =============================================
-- 4. PurchaseSummaryInvoice_Update
-- =============================================
CREATE OR ALTER PROCEDURE PurchaseSummaryInvoice_Update
    @Id INT,
    @InvoiceDate DATETIME,
    @InvoiceNo NVARCHAR(100),
    @VendorId INT = NULL,
    @VendorName NVARCHAR(MAX) = NULL,
    @Amount DECIMAL(18, 2),
    @AdvanceTax DECIMAL(18, 2) = NULL,
    @Discount DECIMAL(18, 2) = NULL,
    @TotalAmount DECIMAL(18, 2),
    @BranchId INT = NULL,
    @StoreId INT = NULL,
    @InventoryDate DATETIME = NULL,
    @ReportType NVARCHAR(50) = NULL,
    @InvoiceType NVARCHAR(50) = NULL,
    @ModifiedById INT = 1
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Inv.PurchaseSummaryInvoices
    SET
        InvoiceNumber = @InvoiceNo,
        InvoiceDate   = @InvoiceDate,
        Amount        = @Amount
    WHERE Id = @Id;

    SELECT @@ROWCOUNT AS RowsAffected;
END
GO

-- =============================================
-- 5. PurchaseSummaryInvoice_Delete
-- =============================================
CREATE OR ALTER PROCEDURE PurchaseSummaryInvoice_Delete
    @Id INT,
    @ModifiedById INT = 1
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Inv.PurchaseSummaryInvoices
    SET IsActive = 0
    WHERE Id = @Id;

    SELECT @@ROWCOUNT AS RowsAffected;
END
GO

-- =============================================
-- 6. PurchaseSummaryInvoice_GetLookupData
-- =============================================
CREATE OR ALTER PROCEDURE PurchaseSummaryInvoice_GetLookupData
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

    -- Vendors
    SELECT Id, Name
    FROM Inv.Vendors
    WHERE IsActive = 1
    ORDER BY Name;
END
GO

PRINT 'All PurchaseSummaryInvoice stored procedures created successfully';
