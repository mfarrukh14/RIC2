-- =============================================
-- Stored Procedures for ContingentBills (HMS-compatible)
-- =============================================

-- 1. Get All Contingent Bills
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'ContingentBills_GetAll')
    DROP PROCEDURE ContingentBills_GetAll;
GO

CREATE PROCEDURE ContingentBills_GetAll
    @BudgetSetupId NVARCHAR(450) = NULL,
    @VendorId INT = NULL,
    @FinancialYearId INT = NULL,
    @PurchaseOrderTypeId INT = NULL,
    @ContingentBillStatusId INT = NULL,
    @DateStart DATETIME = NULL,
    @DateEnd DATETIME = NULL,
    @SearchTerm NVARCHAR(200) = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (CASE WHEN @PageNumber < 1 THEN 0 ELSE @PageNumber - 1 END) * (CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END);
    DECLARE @Take INT = CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END;

    SELECT
        cb.Id,
        0 AS FinancialYearId,
        NULL AS FinancialYearName,
        0 AS PurchaseOrderTypeId,
        NULL AS PurchaseOrderTypeName,
        cb.BillDate AS PurchaseOrderDate,
        cb.VendorId,
        v.Name AS VendorName,
        CAST(cb.BudgetHeadId AS NVARCHAR(450)) AS BudgetSetupId,
        d.Name AS BudgetSetupName,
        cb.BillNumber AS BillNo,
        cb.BillDate,
        CAST(NULL AS REAL) AS BudgetAllotment,
        CAST(cb.Amount AS REAL) AS BillAmount,
        CAST(NULL AS REAL) AS TotalPreviousBill,
        CAST(NULL AS REAL) AS TotalUptoDate,
        CAST(NULL AS REAL) AS AvailableBalance,
        CAST(NULL AS REAL) AS GrandTotal,
        CAST(NULL AS REAL) AS TaxAmount,
        CAST(NULL AS REAL) AS NetPayment,
        NULL AS AmountInWords,
        NULL AS Stamp1,
        NULL AS Stamp2,
        NULL AS Stamp3,
        NULL AS Stamp4,
        NULL AS Stamp5,
        NULL AS Stamp6,
        NULL AS TermsAndConditions,
        CAST(NULL AS REAL) AS PreAuditedAmount,
        NULL AS PreAuditedAmountInWords,
        NULL AS TokenNo,
        NULL AS AuditDate,
        NULL AS DisplayStampFormatForAuditSection,
        CAST(0 AS BIT) AS IsClosed,
        cb.Notes AS Remarks,
        NULL AS RegisterPageNo,
        NULL AS SRNO,
        cb.BranchId,
        b.Name AS BranchName,
        NULL AS ContingentBillStatusId,
        NULL AS AssignedToId,
        NULL AS AssignedFromId,
        NULL AS ApprovedById,
        CAST(cb.CreatedById AS NVARCHAR(450)) AS CreatedById,
        cb.CreatedOn,
        CAST(cb.ModifiedById AS NVARCHAR(450)) AS ModifiedById,
        cb.ModifiedOn,
        CAST(0 AS BIT) AS IsDeleted,
        cb.IsActive,
        COUNT(*) OVER() AS TotalCount
    FROM Inv.ContingentBills cb
    LEFT JOIN Inv.Vendors v ON cb.VendorId = v.Id
    LEFT JOIN Inv.Branches b ON cb.BranchId = b.Id
    LEFT JOIN Inv.Departments d ON cb.BudgetHeadId = d.Id
    WHERE cb.IsActive = 1
        AND (@VendorId IS NULL OR cb.VendorId = @VendorId)
        AND (@DateStart IS NULL OR cb.BillDate >= @DateStart)
        AND (@DateEnd IS NULL OR cb.BillDate <= @DateEnd)
        AND (@BudgetSetupId IS NULL OR cb.BudgetHeadId = TRY_CAST(@BudgetSetupId AS INT))
        AND (
            @SearchTerm IS NULL OR @SearchTerm = ''
            OR cb.BillNumber LIKE '%' + @SearchTerm + '%'
            OR v.Name LIKE '%' + @SearchTerm + '%'
        )
    ORDER BY cb.CreatedOn DESC
    OFFSET @Offset ROWS FETCH NEXT @Take ROWS ONLY;
END
GO

-- 2. Get Contingent Bill By Id
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'ContingentBills_GetById')
    DROP PROCEDURE ContingentBills_GetById;
GO

CREATE PROCEDURE ContingentBills_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        cb.Id,
        0 AS FinancialYearId,
        NULL AS FinancialYearName,
        0 AS PurchaseOrderTypeId,
        NULL AS PurchaseOrderTypeName,
        cb.BillDate AS PurchaseOrderDate,
        cb.VendorId,
        v.Name AS VendorName,
        CAST(cb.BudgetHeadId AS NVARCHAR(450)) AS BudgetSetupId,
        d.Name AS BudgetSetupName,
        cb.BillNumber AS BillNo,
        cb.BillDate,
        CAST(NULL AS REAL) AS BudgetAllotment,
        CAST(cb.Amount AS REAL) AS BillAmount,
        CAST(NULL AS REAL) AS TotalPreviousBill,
        CAST(NULL AS REAL) AS TotalUptoDate,
        CAST(NULL AS REAL) AS AvailableBalance,
        CAST(NULL AS REAL) AS GrandTotal,
        CAST(NULL AS REAL) AS TaxAmount,
        CAST(NULL AS REAL) AS NetPayment,
        NULL AS AmountInWords,
        NULL AS Stamp1,
        NULL AS Stamp2,
        NULL AS Stamp3,
        NULL AS Stamp4,
        NULL AS Stamp5,
        NULL AS Stamp6,
        NULL AS TermsAndConditions,
        CAST(NULL AS REAL) AS PreAuditedAmount,
        NULL AS PreAuditedAmountInWords,
        NULL AS TokenNo,
        NULL AS AuditDate,
        NULL AS DisplayStampFormatForAuditSection,
        CAST(0 AS BIT) AS IsClosed,
        cb.Notes AS Remarks,
        NULL AS RegisterPageNo,
        NULL AS SRNO,
        cb.BranchId,
        b.Name AS BranchName,
        NULL AS ContingentBillStatusId,
        NULL AS AssignedToId,
        NULL AS AssignedFromId,
        NULL AS ApprovedById,
        CAST(cb.CreatedById AS NVARCHAR(450)) AS CreatedById,
        cb.CreatedOn,
        CAST(cb.ModifiedById AS NVARCHAR(450)) AS ModifiedById,
        cb.ModifiedOn,
        CAST(0 AS BIT) AS IsDeleted,
        cb.IsActive
    FROM Inv.ContingentBills cb
    LEFT JOIN Inv.Vendors v ON cb.VendorId = v.Id
    LEFT JOIN Inv.Branches b ON cb.BranchId = b.Id
    LEFT JOIN Inv.Departments d ON cb.BudgetHeadId = d.Id
    WHERE cb.Id = @Id;
END
GO

-- 3. Insert Contingent Bill
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'ContingentBills_Insert')
    DROP PROCEDURE ContingentBills_Insert;
GO

CREATE PROCEDURE ContingentBills_Insert
    @FinancialYearId INT = NULL,
    @PurchaseOrderTypeId INT = NULL,
    @PurchaseOrderDate DATETIME = NULL,
    @VendorId INT,
    @BudgetSetupId NVARCHAR(450) = NULL,
    @BillNo NVARCHAR(MAX) = NULL,
    @BillDate DATETIME,
    @BudgetAllotment REAL = NULL,
    @BillAmount REAL = NULL,
    @TotalPreviousBill REAL = NULL,
    @TotalUptoDate REAL = NULL,
    @AvailableBalance REAL = NULL,
    @GrandTotal REAL = NULL,
    @TaxAmount REAL = NULL,
    @NetPayment REAL = NULL,
    @AmountInWords NVARCHAR(MAX) = NULL,
    @Stamp1 NVARCHAR(MAX) = NULL,
    @Stamp2 NVARCHAR(MAX) = NULL,
    @Stamp3 NVARCHAR(MAX) = NULL,
    @Stamp4 NVARCHAR(MAX) = NULL,
    @Stamp5 NVARCHAR(MAX) = NULL,
    @Stamp6 NVARCHAR(MAX) = NULL,
    @TermsAndConditions NVARCHAR(MAX) = NULL,
    @PreAuditedAmount REAL = NULL,
    @PreAuditedAmountInWords NVARCHAR(MAX) = NULL,
    @TokenNo NVARCHAR(MAX) = NULL,
    @AuditDate DATETIME = NULL,
    @DisplayStampFormatForAuditSection BIT = NULL,
    @IsClosed BIT = 0,
    @Remarks NVARCHAR(MAX) = NULL,
    @RegisterPageNo NVARCHAR(MAX) = NULL,
    @SRNO NVARCHAR(MAX) = NULL,
    @BranchId INT,
    @ContingentBillStatusId INT = NULL,
    @AssignedToId INT = NULL,
    @AssignedFromId INT = NULL,
    @ApprovedById INT = NULL,
    @CreatedById NVARCHAR(450) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DefaultStoreId INT = (SELECT TOP 1 StoreId FROM Inv.PharmacyStores WHERE IsActive = 1 ORDER BY StoreId);

    INSERT INTO Inv.ContingentBills (
        BillNumber,
        Amount,
        BillDate,
        BranchId,
        StoreId,
        VendorId,
        BudgetHeadId,
        Status,
        Notes,
        IsActive,
        CreatedById,
        CreatedOn
    )
    VALUES (
        @BillNo,
        @BillAmount,
        @BillDate,
        @BranchId,
        @DefaultStoreId,
        @VendorId,
        TRY_CAST(@BudgetSetupId AS INT),
        'Pending',
        @Remarks,
        1,
        CASE WHEN @CreatedById IS NOT NULL THEN TRY_CAST(@CreatedById AS INT) ELSE NULL END,
        GETDATE()
    );

    SELECT SCOPE_IDENTITY() AS Id;
END
GO

-- 4. Update Contingent Bill
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'ContingentBills_Update')
    DROP PROCEDURE ContingentBills_Update;
GO

CREATE PROCEDURE ContingentBills_Update
    @Id INT,
    @FinancialYearId INT = NULL,
    @PurchaseOrderTypeId INT = NULL,
    @PurchaseOrderDate DATETIME = NULL,
    @VendorId INT,
    @BudgetSetupId NVARCHAR(450) = NULL,
    @BillNo NVARCHAR(MAX) = NULL,
    @BillDate DATETIME,
    @BudgetAllotment REAL = NULL,
    @BillAmount REAL = NULL,
    @TotalPreviousBill REAL = NULL,
    @TotalUptoDate REAL = NULL,
    @AvailableBalance REAL = NULL,
    @GrandTotal REAL = NULL,
    @TaxAmount REAL = NULL,
    @NetPayment REAL = NULL,
    @AmountInWords NVARCHAR(MAX) = NULL,
    @Stamp1 NVARCHAR(MAX) = NULL,
    @Stamp2 NVARCHAR(MAX) = NULL,
    @Stamp3 NVARCHAR(MAX) = NULL,
    @Stamp4 NVARCHAR(MAX) = NULL,
    @Stamp5 NVARCHAR(MAX) = NULL,
    @Stamp6 NVARCHAR(MAX) = NULL,
    @TermsAndConditions NVARCHAR(MAX) = NULL,
    @PreAuditedAmount REAL = NULL,
    @PreAuditedAmountInWords NVARCHAR(MAX) = NULL,
    @TokenNo NVARCHAR(MAX) = NULL,
    @AuditDate DATETIME = NULL,
    @DisplayStampFormatForAuditSection BIT = NULL,
    @IsClosed BIT = 0,
    @Remarks NVARCHAR(MAX) = NULL,
    @RegisterPageNo NVARCHAR(MAX) = NULL,
    @SRNO NVARCHAR(MAX) = NULL,
    @ContingentBillStatusId INT = NULL,
    @AssignedToId INT = NULL,
    @AssignedFromId INT = NULL,
    @ApprovedById INT = NULL,
    @ModifiedById NVARCHAR(450) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Inv.ContingentBills
    SET
        BillNumber = @BillNo,
        Amount = @BillAmount,
        BillDate = @BillDate,
        VendorId = @VendorId,
        BudgetHeadId = TRY_CAST(@BudgetSetupId AS INT),
        Notes = @Remarks,
        ModifiedById = CASE WHEN @ModifiedById IS NOT NULL THEN TRY_CAST(@ModifiedById AS INT) ELSE NULL END,
        ModifiedOn = GETDATE()
    WHERE Id = @Id;

    SELECT @@ROWCOUNT AS RowsAffected;
END
GO

-- 5. Delete Contingent Bill (Soft Delete)
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'ContingentBills_Delete')
    DROP PROCEDURE ContingentBills_Delete;
GO

CREATE PROCEDURE ContingentBills_Delete
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Inv.ContingentBills
    SET 
        IsActive = 0,
        ModifiedOn = GETDATE()
    WHERE Id = @Id;

    SELECT @@ROWCOUNT AS RowsAffected;
END
GO

-- 6. Get Lookup Data
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'ContingentBills_GetLookupData')
    DROP PROCEDURE ContingentBills_GetLookupData;
GO

CREATE PROCEDURE ContingentBills_GetLookupData
AS
BEGIN
    SET NOCOUNT ON;

    -- Financial Years
    SELECT 
        Id,
        Name
    FROM Inv.FinancialYears
    WHERE IsActive = 1
    ORDER BY Name;

    -- Purchase Order Types
    SELECT 
        Id,
        Name
    FROM Inv.PurchaseOrderTypes
    WHERE IsActive = 1
    ORDER BY Name;

    -- Vendors
    SELECT 
        Id,
        Name
    FROM Inv.Vendors
    WHERE IsActive = 1
    ORDER BY Name;

    -- Branches
    SELECT
        Id,
        Name
    FROM Inv.Branches
    WHERE IsActive = 1
    ORDER BY Name;

    -- Departments (used as Budget Head for now). Inv.Departments has many
    -- duplicate Name rows; collapse to one row per distinct Name (lowest Id).
    ;WITH DedupedDepartments AS (
        SELECT
            Id, Name,
            ROW_NUMBER() OVER (PARTITION BY Name ORDER BY Id) AS rn
        FROM Inv.Departments
        WHERE IsActive = 1
    )
    SELECT Id, Name
    FROM DedupedDepartments
    WHERE rn = 1
    ORDER BY Name;
END
GO

PRINT 'All ContingentBills stored procedures created successfully.';
