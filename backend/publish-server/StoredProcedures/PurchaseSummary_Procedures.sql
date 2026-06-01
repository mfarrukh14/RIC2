USE InventoryManagementDB_SP;
GO

-- =============================================
-- 1. PurchaseSummary_GetAll - Get all purchase summary records with filters
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
    @InvoiceNo NVARCHAR(100) = NULL,
    @ReportType NVARCHAR(50) = NULL
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
        b.Name                AS BranchName,
        CAST(NULL AS INT)     AS ItemTypeId,
        CAST(NULL AS NVARCHAR(MAX)) AS ItemTypeName,
        CAST(NULL AS NVARCHAR(50))  AS ReportType
    FROM dbo.PurchaseSummaries ps
    LEFT JOIN dbo.Branches b ON ps.BranchId = b.Id
    LEFT JOIN dbo.Stores s   ON ps.StoreId  = s.StoreId
    LEFT JOIN dbo.Vendors v  ON ps.VendorId = v.Id
    WHERE ps.IsActive = 1
        AND (@BranchId IS NULL OR ps.BranchId = @BranchId)
        AND (@StoreId  IS NULL OR ps.StoreId  = @StoreId)
        AND (@InventoryDateStart IS NULL OR ps.SummaryDate >= @InventoryDateStart)
        AND (@InventoryDateEnd   IS NULL OR ps.SummaryDate <= @InventoryDateEnd)
    ORDER BY ps.SummaryDate DESC, ps.Id DESC;

    -- Return summary totals
    SELECT
        CAST(0 AS INT) AS TotalQuantity,
        ISNULL(SUM(ps.TotalAmount), 0) AS TotalAmount,
        CAST(0 AS DECIMAL(18,2)) AS TotalAdvanceTax,
        CAST(0 AS DECIMAL(18,2)) AS TotalDiscount,
        ISNULL(SUM(ps.TotalAmount), 0) AS TotalPrice
    FROM dbo.PurchaseSummaries ps
    WHERE ps.IsActive = 1
        AND (@BranchId IS NULL OR ps.BranchId = @BranchId)
        AND (@StoreId  IS NULL OR ps.StoreId  = @StoreId)
        AND (@InventoryDateStart IS NULL OR ps.SummaryDate >= @InventoryDateStart)
        AND (@InventoryDateEnd   IS NULL OR ps.SummaryDate <= @InventoryDateEnd);
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
        b.Name                AS BranchName,
        CAST(NULL AS INT)     AS ItemTypeId,
        CAST(NULL AS NVARCHAR(MAX)) AS ItemTypeName,
        CAST(NULL AS NVARCHAR(50))  AS ReportType
    FROM dbo.PurchaseSummaries ps
    LEFT JOIN dbo.Branches b ON ps.BranchId = b.Id
    LEFT JOIN dbo.Stores s   ON ps.StoreId  = s.StoreId
    LEFT JOIN dbo.Vendors v  ON ps.VendorId = v.Id
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

    INSERT INTO dbo.PurchaseSummaries (
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

    UPDATE dbo.PurchaseSummaries
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

    UPDATE dbo.PurchaseSummaries
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
    SELECT Id, Name
    FROM dbo.Branches
    WHERE IsActive = 1
    ORDER BY Name;

    -- Stores
    SELECT StoreId AS Id, StoreName AS Name
    FROM dbo.Stores
    WHERE IsActive = 1
    ORDER BY StoreName;

    -- Item Types
    SELECT Id, Name
    FROM dbo.ItemTypes
    WHERE IsActive = 1
    ORDER BY Name;

    -- Vendors
    SELECT Id, Name
    FROM dbo.Vendors
    WHERE IsActive = 1
    ORDER BY Name;

    -- Items
    SELECT Id, Name
    FROM dbo.Items
    WHERE IsActive = 1
    ORDER BY Name;
END
GO

PRINT 'All PurchaseSummary stored procedures created successfully';
