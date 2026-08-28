USE InventoryManagementDB_SP;
GO

-- =============================================
-- 1. PurchaseSummaryInvoice_GetAll
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
    @InvoiceType NVARCHAR(50) = NULL
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
    WHERE psi.IsActive = 1
        AND (@InvoiceDateStart IS NULL OR psi.InvoiceDate >= @InvoiceDateStart)
        AND (@InvoiceDateEnd   IS NULL OR psi.InvoiceDate <= @InvoiceDateEnd)
        AND (@InvoiceNo IS NULL OR psi.InvoiceNumber LIKE '%' + @InvoiceNo + '%')
    ORDER BY psi.InvoiceDate DESC, psi.Id DESC;

    -- Return summary totals
    SELECT
        ISNULL(SUM(psi.Amount), 0) AS TotalAmount,
        CAST(0 AS DECIMAL(18,2))   AS TotalAdvanceTax,
        CAST(0 AS DECIMAL(18,2))   AS TotalDiscount,
        ISNULL(SUM(psi.Amount), 0) AS GrandTotal
    FROM Inv.PurchaseSummaryInvoices psi
    WHERE psi.IsActive = 1
        AND (@InvoiceDateStart IS NULL OR psi.InvoiceDate >= @InvoiceDateStart)
        AND (@InvoiceDateEnd   IS NULL OR psi.InvoiceDate <= @InvoiceDateEnd)
        AND (@InvoiceNo IS NULL OR psi.InvoiceNumber LIKE '%' + @InvoiceNo + '%');
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
