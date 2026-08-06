-- =============================================
-- 1. PurchaseSummary_GetAll - Get all purchase summary records with filters
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
--   - "Inventory Date Range" filters the linked Purchase Order's CreatedOn (old:
--     po.CreatedOn) - yes, the naming is swapped from what you'd expect; this
--     matches the old system exactly, not a typo.
--   - @ReportType is NOT about which date range applies - it filters whether the
--     GRN has a PO number attached: 'PurchaseOrder' = has one, 'Inventory' = does
--     not, NULL/'Both' = no filter.
--   - Total = Qty * UnitPrice + AdvanceTax. Discount is NOT subtracted from Total
--     (matches the old system's TotalPrice formula exactly - Discount is a
--     separate, informational column).
--   - Old system UNIONed three separate item source tables (Items/BranchMedicines/
--     BranchFees) keyed by a TypeBit (4/5/15) because item master data was split
--     across tables there. The new schema already unifies all of that into
--     Inv.Items + Inv.ItemTypes, so the equivalent split is just a filter on
--     ItemTypeId/@ItemType - no UNION needed.
--   - Old system INNER JOINed Items (and Manufacturers) - a GRN line whose item no
--     longer exists is silently excluded, not shown as a placeholder. Matched here
--     with an INNER JOIN.
--
-- Store note: the old Inventories table had its own StoreId column directly. The
-- new GoodsReceivingNotes table does not - store is only reachable via the linked
-- Purchase Order (Inv.PurchaseOrders.StoreId). A GRN with no linked PO therefore
-- has no resolvable store here, which the old system never had to deal with.
-- =============================================
CREATE OR ALTER PROCEDURE dbo.PurchaseSummary_GetAll
    @BranchId INT = NULL,
    @StoreId INT = NULL,
    @ItemTypeId INT = NULL,
    @ItemType NVARCHAR(50) = NULL,
    @InvoiceDateStart DATETIME = NULL,
    @InvoiceDateEnd DATETIME = NULL,
    @InventoryDateStart DATETIME = NULL,
    @InventoryDateEnd DATETIME = NULL,
    @ItemId INT = NULL,
    @InvoiceNo NVARCHAR(100) = NULL,
    @ReportType NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        gi.Id,
        g.DateAndTime AS PurchaseDate,
        gi.BatchNo,
        gi.ItemId,
        i.Name AS ItemName,
        po.StoreId,
        s.StoreName,
        g.VendorId,
        v.Name AS VendorName,
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
        it.Name AS ItemTypeName,
        @ReportType AS ReportType
    FROM Inv.GRNItems gi
    JOIN Inv.GoodsReceivingNotes g ON gi.GRNId = g.Id
    JOIN Inv.Items i ON gi.ItemId = i.Id
    LEFT JOIN Inv.PurchaseOrders po ON g.PurchaseOrderId = po.PurchaseOrderId
    LEFT JOIN Inv.PharmacyStores s ON po.StoreId = s.StoreId
    LEFT JOIN Inv.Branches b ON s.BranchId = b.Id
    LEFT JOIN Inv.Vendors v ON g.VendorId = v.Id
    LEFT JOIN Inv.ItemTypes it ON i.ItemTypeId = it.Id
    WHERE g.IsActive = 1
        AND (@BranchId IS NULL OR s.BranchId = @BranchId)
        AND (@StoreId IS NULL OR po.StoreId = @StoreId)
        AND (@ItemTypeId IS NULL OR i.ItemTypeId = @ItemTypeId)
        AND (
            @ItemType IS NULL OR @ItemType = 'All'
            OR (@ItemType = 'Medicine' AND it.Name = 'Medicine')
            OR (@ItemType = 'Disposable' AND it.Name = 'Disposables')
            OR (@ItemType = 'Item' AND (it.Name IS NULL OR it.Name NOT IN ('Medicine', 'Disposables')))
        )
        AND (@ItemId IS NULL OR gi.ItemId = @ItemId)
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
    ORDER BY g.DateAndTime DESC, gi.Id DESC;

    -- Return summary totals (same filters)
    SELECT
        ISNULL(SUM(ISNULL(gi.ReceivedQuantity, 0)), 0) AS TotalQuantity,
        ISNULL(SUM(ISNULL(gi.UnitBuyingPrice, 0)), 0) AS TotalAmount,
        ISNULL(SUM(ISNULL(gi.AdvanceTaxAmount, 0)), 0) AS TotalAdvanceTax,
        ISNULL(SUM(ISNULL(gi.DiscountAmount, 0)), 0) AS TotalDiscount,
        ISNULL(SUM((ISNULL(gi.ReceivedQuantity, 0) * ISNULL(gi.UnitBuyingPrice, 0)) + ISNULL(gi.AdvanceTaxAmount, 0)), 0) AS TotalPrice
    FROM Inv.GRNItems gi
    JOIN Inv.GoodsReceivingNotes g ON gi.GRNId = g.Id
    JOIN Inv.Items i ON gi.ItemId = i.Id
    LEFT JOIN Inv.PurchaseOrders po ON g.PurchaseOrderId = po.PurchaseOrderId
    LEFT JOIN Inv.PharmacyStores s ON po.StoreId = s.StoreId
    LEFT JOIN Inv.ItemTypes it ON i.ItemTypeId = it.Id
    WHERE g.IsActive = 1
        AND (@BranchId IS NULL OR s.BranchId = @BranchId)
        AND (@StoreId IS NULL OR po.StoreId = @StoreId)
        AND (@ItemTypeId IS NULL OR i.ItemTypeId = @ItemTypeId)
        AND (
            @ItemType IS NULL OR @ItemType = 'All'
            OR (@ItemType = 'Medicine' AND it.Name = 'Medicine')
            OR (@ItemType = 'Disposable' AND it.Name = 'Disposables')
            OR (@ItemType = 'Item' AND (it.Name IS NULL OR it.Name NOT IN ('Medicine', 'Disposables')))
        )
        AND (@ItemId IS NULL OR gi.ItemId = @ItemId)
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
-- 2. PurchaseSummary_GetById
-- =============================================
CREATE OR ALTER PROCEDURE dbo.PurchaseSummary_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        gi.Id,
        g.DateAndTime AS PurchaseDate,
        gi.BatchNo,
        gi.ItemId,
        i.Name AS ItemName,
        po.StoreId,
        s.StoreName,
        g.VendorId,
        v.Name AS VendorName,
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
        it.Name AS ItemTypeName,
        CAST(NULL AS NVARCHAR(50)) AS ReportType
    FROM Inv.GRNItems gi
    JOIN Inv.GoodsReceivingNotes g ON gi.GRNId = g.Id
    JOIN Inv.Items i ON gi.ItemId = i.Id
    LEFT JOIN Inv.PurchaseOrders po ON g.PurchaseOrderId = po.PurchaseOrderId
    LEFT JOIN Inv.PharmacyStores s ON po.StoreId = s.StoreId
    LEFT JOIN Inv.Branches b ON s.BranchId = b.Id
    LEFT JOIN Inv.Vendors v ON g.VendorId = v.Id
    LEFT JOIN Inv.ItemTypes it ON i.ItemTypeId = it.Id
    WHERE gi.Id = @Id;
END
GO

-- =============================================
-- 3. PurchaseSummary_Insert
-- Kept pointed at Inv.PurchaseSummaries (not used by the report page, which is
-- read-only against GRN data above) - fixed only to reference the correct live
-- schema instead of the nonexistent dbo.PurchaseSummaries/dbo.Branches/dbo.Stores.
-- =============================================
CREATE OR ALTER PROCEDURE dbo.PurchaseSummary_Insert
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
CREATE OR ALTER PROCEDURE dbo.PurchaseSummary_Update
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
CREATE OR ALTER PROCEDURE dbo.PurchaseSummary_Delete
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
CREATE OR ALTER PROCEDURE dbo.PurchaseSummary_GetLookupData
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
