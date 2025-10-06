USE InventoryManagementDB_SP;
GO

-- =============================================
-- 1. PurchaseSummaryInvoice_GetAll - Get all invoice summary records with filters
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
    @ReportType NVARCHAR(50) = NULL, -- 'Purchase', 'Return', 'Both'
    @InvoiceType NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        psi.Id,
        psi.InvoiceDate,
        psi.InvoiceNo,
        psi.VendorId,
        psi.VendorName,
        psi.Amount,
        psi.AdvanceTax,
        psi.Discount,
        psi.TotalAmount,
        psi.BranchId,
        b.Name AS BranchName,
        psi.StoreId,
        s.StoreName,
        psi.InventoryDate,
        psi.ReportType,
        psi.InvoiceType
    FROM PurchaseSummaryInvoice psi
    LEFT JOIN Branches b ON psi.BranchId = b.Id
    LEFT JOIN Stores s ON psi.StoreId = s.StoreId
    WHERE psi.IsActive = 1
        AND (@BranchId IS NULL OR psi.BranchId = @BranchId)
        AND (@StoreId IS NULL OR psi.StoreId = @StoreId)
        AND (@InventoryDateStart IS NULL OR psi.InventoryDate >= @InventoryDateStart)
        AND (@InventoryDateEnd IS NULL OR psi.InventoryDate <= @InventoryDateEnd)
        AND (@VendorId IS NULL OR psi.VendorId = @VendorId)
        AND (@InvoiceDateStart IS NULL OR psi.InvoiceDate >= @InvoiceDateStart)
        AND (@InvoiceDateEnd IS NULL OR psi.InvoiceDate <= @InvoiceDateEnd)
        AND (@InvoiceNo IS NULL OR psi.InvoiceNo LIKE '%' + @InvoiceNo + '%')
        AND (@ReportType IS NULL OR @ReportType = 'Both' OR psi.ReportType = @ReportType)
        AND (@InvoiceType IS NULL OR psi.InvoiceType = @InvoiceType)
    ORDER BY psi.InvoiceDate DESC, psi.Id DESC;
    
    -- Return summary totals
    SELECT 
        SUM(psi.Amount) AS TotalAmount,
        SUM(psi.AdvanceTax) AS TotalAdvanceTax,
        SUM(psi.Discount) AS TotalDiscount,
        SUM(psi.TotalAmount) AS GrandTotal
    FROM PurchaseSummaryInvoice psi
    WHERE psi.IsActive = 1
        AND (@BranchId IS NULL OR psi.BranchId = @BranchId)
        AND (@StoreId IS NULL OR psi.StoreId = @StoreId)
        AND (@InventoryDateStart IS NULL OR psi.InventoryDate >= @InventoryDateStart)
        AND (@InventoryDateEnd IS NULL OR psi.InventoryDate <= @InventoryDateEnd)
        AND (@VendorId IS NULL OR psi.VendorId = @VendorId)
        AND (@InvoiceDateStart IS NULL OR psi.InvoiceDate >= @InvoiceDateStart)
        AND (@InvoiceDateEnd IS NULL OR psi.InvoiceDate <= @InvoiceDateEnd)
        AND (@InvoiceNo IS NULL OR psi.InvoiceNo LIKE '%' + @InvoiceNo + '%')
        AND (@ReportType IS NULL OR @ReportType = 'Both' OR psi.ReportType = @ReportType)
        AND (@InvoiceType IS NULL OR psi.InvoiceType = @InvoiceType);
END
GO

-- =============================================
-- 2. PurchaseSummaryInvoice_GetById - Get a single invoice summary record by ID
-- =============================================
CREATE OR ALTER PROCEDURE PurchaseSummaryInvoice_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        psi.Id,
        psi.InvoiceDate,
        psi.InvoiceNo,
        psi.VendorId,
        psi.VendorName,
        psi.Amount,
        psi.AdvanceTax,
        psi.Discount,
        psi.TotalAmount,
        psi.BranchId,
        b.Name AS BranchName,
        psi.StoreId,
        s.StoreName,
        psi.InventoryDate,
        psi.ReportType,
        psi.InvoiceType,
        psi.IsActive,
        psi.CreatedById,
        psi.CreatedOn,
        psi.ModifiedById,
        psi.ModifiedOn
    FROM PurchaseSummaryInvoice psi
    LEFT JOIN Branches b ON psi.BranchId = b.Id
    LEFT JOIN Stores s ON psi.StoreId = s.StoreId
    WHERE psi.Id = @Id;
END
GO

-- =============================================
-- 3. PurchaseSummaryInvoice_Insert - Insert a new invoice summary record
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
    
    INSERT INTO PurchaseSummaryInvoice (
        InvoiceDate,
        InvoiceNo,
        VendorId,
        VendorName,
        Amount,
        AdvanceTax,
        Discount,
        TotalAmount,
        BranchId,
        StoreId,
        InventoryDate,
        ReportType,
        InvoiceType,
        IsActive,
        CreatedById,
        CreatedOn
    )
    VALUES (
        @InvoiceDate,
        @InvoiceNo,
        @VendorId,
        @VendorName,
        @Amount,
        @AdvanceTax,
        @Discount,
        @TotalAmount,
        @BranchId,
        @StoreId,
        @InventoryDate,
        @ReportType,
        @InvoiceType,
        1,
        @CreatedById,
        GETDATE()
    );
    
    SELECT SCOPE_IDENTITY() AS Id;
END
GO

-- =============================================
-- 4. PurchaseSummaryInvoice_Update - Update an existing invoice summary record
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
    
    UPDATE PurchaseSummaryInvoice
    SET 
        InvoiceDate = @InvoiceDate,
        InvoiceNo = @InvoiceNo,
        VendorId = @VendorId,
        VendorName = @VendorName,
        Amount = @Amount,
        AdvanceTax = @AdvanceTax,
        Discount = @Discount,
        TotalAmount = @TotalAmount,
        BranchId = @BranchId,
        StoreId = @StoreId,
        InventoryDate = @InventoryDate,
        ReportType = @ReportType,
        InvoiceType = @InvoiceType,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETDATE()
    WHERE Id = @Id;
    
    SELECT @@ROWCOUNT AS RowsAffected;
END
GO

-- =============================================
-- 5. PurchaseSummaryInvoice_Delete - Soft delete an invoice summary record
-- =============================================
CREATE OR ALTER PROCEDURE PurchaseSummaryInvoice_Delete
    @Id INT,
    @ModifiedById INT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE PurchaseSummaryInvoice
    SET 
        IsActive = 0,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETDATE()
    WHERE Id = @Id;
    
    SELECT @@ROWCOUNT AS RowsAffected;
END
GO

-- =============================================
-- 6. PurchaseSummaryInvoice_GetLookupData - Get all lookup data for dropdowns
-- =============================================
CREATE OR ALTER PROCEDURE PurchaseSummaryInvoice_GetLookupData
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
    
    -- Get Vendors
    SELECT Id, Name
    FROM Vendors
    WHERE IsActive = 1
    ORDER BY Name;
END
GO

PRINT 'All PurchaseSummaryInvoice stored procedures created successfully';
