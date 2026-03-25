USE InventoryManagementDB_SP;
GO

-- =============================================
-- 1. PurchaseSummary_GetAll - Get all purchase summary records with filters
-- =============================================
CREATE OR ALTER PROCEDURE PurchaseSummary_GetAll
    @BranchId INT = NULL,
    @StoreId INT = NULL,
    @ItemTypeId INT = NULL,
    @ItemType NVARCHAR(50) = NULL, -- 'Medicine', 'Disposable', 'Item', or NULL for All
    @InvoiceDateStart DATETIME = NULL,
    @InvoiceDateEnd DATETIME = NULL,
    @InventoryDateStart DATETIME = NULL,
    @InventoryDateEnd DATETIME = NULL,
    @ItemId INT = NULL,
    @InvoiceNo NVARCHAR(100) = NULL,
    @ReportType NVARCHAR(50) = NULL -- 'Purchase', 'Return', 'Both'
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        ps.Id,
        ps.PurchaseDate,
        ps.BatchNo,
        ps.ItemId,
        ps.ItemName,
        ps.StoreId,
        ps.StoreName,
        ps.VendorId,
        ps.VendorName,
        ps.InvoiceNo,
        ps.InvoiceDate,
        ps.Quantity,
        ps.Amount,
        ps.AdvanceTax,
        ps.Discount,
        ps.TotalPrice,
        ps.BranchId,
        b.Name AS BranchName,
        ps.ItemTypeId,
        it.Name AS ItemTypeName,
        ps.ReportType
    FROM PurchaseSummary ps
    LEFT JOIN Branches b ON ps.BranchId = b.Id
    LEFT JOIN ItemTypes it ON ps.ItemTypeId = it.Id
    WHERE ps.IsActive = 1
        AND (@BranchId IS NULL OR ps.BranchId = @BranchId)
        AND (@StoreId IS NULL OR ps.StoreId = @StoreId)
        AND (@ItemTypeId IS NULL OR ps.ItemTypeId = @ItemTypeId)
        AND (@ItemType IS NULL OR it.Name = @ItemType)
        AND (@InvoiceDateStart IS NULL OR ps.InvoiceDate >= @InvoiceDateStart)
        AND (@InvoiceDateEnd IS NULL OR ps.InvoiceDate <= @InvoiceDateEnd)
        AND (@InventoryDateStart IS NULL OR ps.PurchaseDate >= @InventoryDateStart)
        AND (@InventoryDateEnd IS NULL OR ps.PurchaseDate <= @InventoryDateEnd)
        AND (@ItemId IS NULL OR ps.ItemId = @ItemId)
        AND (@InvoiceNo IS NULL OR ps.InvoiceNo LIKE '%' + @InvoiceNo + '%')
        AND (@ReportType IS NULL OR @ReportType = 'Both' OR ps.ReportType = @ReportType)
    ORDER BY ps.PurchaseDate DESC, ps.Id DESC;
    
    -- Return summary totals
    SELECT 
        SUM(ps.Quantity) AS TotalQuantity,
        SUM(ps.Amount) AS TotalAmount,
        SUM(ps.AdvanceTax) AS TotalAdvanceTax,
        SUM(ps.Discount) AS TotalDiscount,
        SUM(ps.TotalPrice) AS TotalPrice
    FROM PurchaseSummary ps
    LEFT JOIN ItemTypes it ON ps.ItemTypeId = it.Id
    WHERE ps.IsActive = 1
        AND (@BranchId IS NULL OR ps.BranchId = @BranchId)
        AND (@StoreId IS NULL OR ps.StoreId = @StoreId)
        AND (@ItemTypeId IS NULL OR ps.ItemTypeId = @ItemTypeId)
        AND (@ItemType IS NULL OR it.Name = @ItemType)
        AND (@InvoiceDateStart IS NULL OR ps.InvoiceDate >= @InvoiceDateStart)
        AND (@InvoiceDateEnd IS NULL OR ps.InvoiceDate <= @InvoiceDateEnd)
        AND (@InventoryDateStart IS NULL OR ps.PurchaseDate >= @InventoryDateStart)
        AND (@InventoryDateEnd IS NULL OR ps.PurchaseDate <= @InventoryDateEnd)
        AND (@ItemId IS NULL OR ps.ItemId = @ItemId)
        AND (@InvoiceNo IS NULL OR ps.InvoiceNo LIKE '%' + @InvoiceNo + '%')
        AND (@ReportType IS NULL OR @ReportType = 'Both' OR ps.ReportType = @ReportType);
END
GO

-- =============================================
-- 2. PurchaseSummary_GetById - Get a single purchase summary record by ID
-- =============================================
CREATE OR ALTER PROCEDURE PurchaseSummary_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        ps.Id,
        ps.PurchaseDate,
        ps.BatchNo,
        ps.ItemId,
        ps.ItemName,
        ps.StoreId,
        ps.StoreName,
        ps.VendorId,
        ps.VendorName,
        ps.InvoiceNo,
        ps.InvoiceDate,
        ps.Quantity,
        ps.Amount,
        ps.AdvanceTax,
        ps.Discount,
        ps.TotalPrice,
        ps.BranchId,
        b.Name AS BranchName,
        ps.ItemTypeId,
        it.Name AS ItemTypeName,
        ps.ReportType,
        ps.IsActive,
        ps.CreatedById,
        ps.CreatedOn,
        ps.ModifiedById,
        ps.ModifiedOn
    FROM PurchaseSummary ps
    LEFT JOIN Branches b ON ps.BranchId = b.Id
    LEFT JOIN ItemTypes it ON ps.ItemTypeId = it.Id
    WHERE ps.Id = @Id;
END
GO

-- =============================================
-- 3. PurchaseSummary_Insert - Insert a new purchase summary record
-- =============================================
CREATE OR ALTER PROCEDURE PurchaseSummary_Insert
    @PurchaseDate DATETIME,
    @BatchNo NVARCHAR(100) = NULL,
    @ItemId INT,
    @ItemName NVARCHAR(MAX),
    @StoreId INT = NULL,
    @StoreName NVARCHAR(MAX) = NULL,
    @VendorId INT = NULL,
    @VendorName NVARCHAR(MAX) = NULL,
    @InvoiceNo NVARCHAR(100) = NULL,
    @InvoiceDate DATETIME = NULL,
    @Quantity INT,
    @Amount DECIMAL(18, 2),
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
    
    INSERT INTO PurchaseSummary (
        PurchaseDate,
        BatchNo,
        ItemId,
        ItemName,
        StoreId,
        StoreName,
        VendorId,
        VendorName,
        InvoiceNo,
        InvoiceDate,
        Quantity,
        Amount,
        AdvanceTax,
        Discount,
        TotalPrice,
        BranchId,
        ItemTypeId,
        ReportType,
        IsActive,
        CreatedById,
        CreatedOn
    )
    VALUES (
        @PurchaseDate,
        @BatchNo,
        @ItemId,
        @ItemName,
        @StoreId,
        @StoreName,
        @VendorId,
        @VendorName,
        @InvoiceNo,
        @InvoiceDate,
        @Quantity,
        @Amount,
        @AdvanceTax,
        @Discount,
        @TotalPrice,
        @BranchId,
        @ItemTypeId,
        @ReportType,
        1,
        @CreatedById,
        GETDATE()
    );
    
    SELECT SCOPE_IDENTITY() AS Id;
END
GO

-- =============================================
-- 4. PurchaseSummary_Update - Update an existing purchase summary record
-- =============================================
CREATE OR ALTER PROCEDURE PurchaseSummary_Update
    @Id INT,
    @PurchaseDate DATETIME,
    @BatchNo NVARCHAR(100) = NULL,
    @ItemId INT,
    @ItemName NVARCHAR(MAX),
    @StoreId INT = NULL,
    @StoreName NVARCHAR(MAX) = NULL,
    @VendorId INT = NULL,
    @VendorName NVARCHAR(MAX) = NULL,
    @InvoiceNo NVARCHAR(100) = NULL,
    @InvoiceDate DATETIME = NULL,
    @Quantity INT,
    @Amount DECIMAL(18, 2),
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
    
    UPDATE PurchaseSummary
    SET 
        PurchaseDate = @PurchaseDate,
        BatchNo = @BatchNo,
        ItemId = @ItemId,
        ItemName = @ItemName,
        StoreId = @StoreId,
        StoreName = @StoreName,
        VendorId = @VendorId,
        VendorName = @VendorName,
        InvoiceNo = @InvoiceNo,
        InvoiceDate = @InvoiceDate,
        Quantity = @Quantity,
        Amount = @Amount,
        AdvanceTax = @AdvanceTax,
        Discount = @Discount,
        TotalPrice = @TotalPrice,
        BranchId = @BranchId,
        ItemTypeId = @ItemTypeId,
        ReportType = @ReportType,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETDATE()
    WHERE Id = @Id;
    
    SELECT @@ROWCOUNT AS RowsAffected;
END
GO

-- =============================================
-- 5. PurchaseSummary_Delete - Soft delete a purchase summary record
-- =============================================
CREATE OR ALTER PROCEDURE PurchaseSummary_Delete
    @Id INT,
    @ModifiedById INT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE PurchaseSummary
    SET 
        IsActive = 0,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETDATE()
    WHERE Id = @Id;
    
    SELECT @@ROWCOUNT AS RowsAffected;
END
GO

-- =============================================
-- 6. PurchaseSummary_GetLookupData - Get all lookup data for dropdowns
-- =============================================
CREATE OR ALTER PROCEDURE PurchaseSummary_GetLookupData
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Get Branches
    SELECT Id, Name
    FROM Branches
    WHERE IsActive = 1
    ORDER BY Name;
    
    -- Get Stores
    SELECT StoreId AS Id, StoreName AS Name
    FROM Stores
    WHERE IsActive = 1
    ORDER BY StoreName;
    
    -- Get Item Types
    SELECT Id, Name
    FROM ItemTypes
    WHERE IsActive = 1
    ORDER BY Name;
    
    -- Get Vendors
    SELECT Id, Name
    FROM Vendors
    WHERE IsActive = 1
    ORDER BY Name;
    
    -- Get Items
    SELECT Id, Name
    FROM Items
    WHERE IsActive = 1
    ORDER BY Name;
END
GO

PRINT 'All PurchaseSummary stored procedures created successfully';
