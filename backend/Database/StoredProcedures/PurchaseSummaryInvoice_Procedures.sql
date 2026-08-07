-- =============================================
-- 1. PurchaseSummaryInvoice_GetAll
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
-- Range" uses the GRN's own date while "Inventory Date Range" uses the linked
-- Purchase Order's CreatedOn).
--
-- Old system stored a header-level Amount/Total/Discount directly on the
-- Inventory row. The new schema only has item-level figures (Inv.GRNItems), so
-- this aggregates them per GRN instead - same end result (invoice totals), just
-- computed bottom-up rather than read off a pre-saved header field. The old
-- system's PurchaseOrderReturns union branch (negative adjustment rows for
-- purchase returns against an invoice) has no equivalent table in the new schema
-- yet, so it isn't included here.
-- =============================================
CREATE OR ALTER PROCEDURE dbo.PurchaseSummaryInvoice_GetAll
    @BranchId INT = NULL,
    @StoreId INT = NULL,
    @InventoryDateStart DATETIME = NULL,
    @InventoryDateEnd DATETIME = NULL,
    @VendorId INT = NULL,
    @InvoiceDateStart DATETIME = NULL,
    @InvoiceDateEnd DATETIME = NULL,
    @InvoiceNo NVARCHAR(100) = NULL,
    @ReportType NVARCHAR(50) = NULL,
    @InvoiceType NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

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
        po.CreatedOn AS InventoryDate,
        @ReportType AS ReportType,
        CAST(NULL AS NVARCHAR(50)) AS InvoiceType
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
        AND (@VendorId IS NULL OR g.VendorId = @VendorId)
        AND (@InvoiceNo IS NULL OR g.InvoiceNo LIKE '%' + @InvoiceNo + '%')
        AND (@InvoiceDateStart IS NULL OR g.DateAndTime >= @InvoiceDateStart)
        AND (@InvoiceDateEnd IS NULL OR g.DateAndTime <= @InvoiceDateEnd)
        AND (@InventoryDateStart IS NULL OR po.CreatedOn >= @InventoryDateStart)
        AND (@InventoryDateEnd IS NULL OR po.CreatedOn <= @InventoryDateEnd)
        AND (
            @ReportType IS NULL OR @ReportType = 'Both'
            OR (@ReportType = 'PurchaseOrder' AND ISNULL(g.PONumber, '') <> '')
            OR (@ReportType = 'Inventory' AND ISNULL(g.PONumber, '') = '')
        )
    ORDER BY ISNULL(g.DateAndTime, g.CreatedOn) DESC, g.Id DESC;

    -- Return summary totals (same filters)
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
        AND (@VendorId IS NULL OR g.VendorId = @VendorId)
        AND (@InvoiceNo IS NULL OR g.InvoiceNo LIKE '%' + @InvoiceNo + '%')
        AND (@InvoiceDateStart IS NULL OR g.DateAndTime >= @InvoiceDateStart)
        AND (@InvoiceDateEnd IS NULL OR g.DateAndTime <= @InvoiceDateEnd)
        AND (@InventoryDateStart IS NULL OR po.CreatedOn >= @InventoryDateStart)
        AND (@InventoryDateEnd IS NULL OR po.CreatedOn <= @InventoryDateEnd)
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
CREATE OR ALTER PROCEDURE dbo.PurchaseSummaryInvoice_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

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
        po.CreatedOn AS InventoryDate,
        CAST(NULL AS NVARCHAR(50)) AS ReportType,
        CAST(NULL AS NVARCHAR(50)) AS InvoiceType
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
    WHERE g.Id = @Id;
END
GO

-- =============================================
-- 3. PurchaseSummaryInvoice_Insert
-- Kept pointed at Inv.PurchaseSummaryInvoices (not used by the report page,
-- which is read-only against GRN data above) - fixed only to reference the
-- correct live schema.
-- =============================================
CREATE OR ALTER PROCEDURE dbo.PurchaseSummaryInvoice_Insert
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
CREATE OR ALTER PROCEDURE dbo.PurchaseSummaryInvoice_Update
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
CREATE OR ALTER PROCEDURE dbo.PurchaseSummaryInvoice_Delete
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
CREATE OR ALTER PROCEDURE dbo.PurchaseSummaryInvoice_GetLookupData
AS
BEGIN
    SET NOCOUNT ON;

    -- Branches
    SELECT Id, Name
    FROM Inv.Branches
    WHERE IsActive = 1
    ORDER BY Name;

    -- Stores
    SELECT StoreId AS Id, StoreName AS Name
    FROM Inv.PharmacyStores
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
