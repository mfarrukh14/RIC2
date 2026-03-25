-- =============================================
-- Stored Procedures for ContingentBills
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
    @DateEnd DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        cb.Id,
        cb.FinancialYearId,
        fy.Name AS FinancialYearName,
        cb.PurchaseOrderTypeId,
        pot.Name AS PurchaseOrderTypeName,
        cb.PurchaseOrderDate,
        cb.VendorId,
        v.Name AS VendorName,
        cb.BudgetSetupId,
        cb.BillNo,
        cb.BillDate,
        cb.BudgetAllotment,
        cb.BillAmount,
        cb.TotalPreviousBill,
        cb.TotalUptoDate,
        cb.AvailableBalance,
        cb.GrandTotal,
        cb.TaxAmount,
        cb.NetPayment,
        cb.AmountInWords,
        cb.Stamp1,
        cb.Stamp2,
        cb.Stamp3,
        cb.Stamp4,
        cb.Stamp5,
        cb.Stamp6,
        cb.TermsAndConditions,
        cb.PreAuditedAmount,
        cb.PreAuditedAmountInWords,
        cb.TokenNo,
        cb.AuditDate,
        cb.DisplayStampFormatForAuditSection,
        cb.IsClosed,
        cb.Remarks,
        cb.RegisterPageNo,
        cb.SRNO,
        cb.BranchId,
        b.Name AS BranchName,
        cb.ContingentBillStatusId,
        cb.AssignedToId,
        cb.AssignedFromId,
        cb.ApprovedById,
        cb.CreatedById,
        cb.CreatedOn,
        cb.ModifiedById,
        cb.ModifiedOn,
        cb.IsDeleted,
        cb.IsActive
    FROM dbo.ContingentBills cb
    LEFT JOIN dbo.FinancialYears fy ON cb.FinancialYearId = fy.Id
    LEFT JOIN dbo.PurchaseOrderTypes pot ON cb.PurchaseOrderTypeId = pot.Id
    LEFT JOIN dbo.Vendors v ON cb.VendorId = v.Id
    LEFT JOIN dbo.Branches b ON cb.BranchId = b.Id
    WHERE cb.IsDeleted = 0 
        AND (@BudgetSetupId IS NULL OR cb.BudgetSetupId = @BudgetSetupId)
        AND (@VendorId IS NULL OR cb.VendorId = @VendorId)
        AND (@FinancialYearId IS NULL OR cb.FinancialYearId = @FinancialYearId)
        AND (@PurchaseOrderTypeId IS NULL OR cb.PurchaseOrderTypeId = @PurchaseOrderTypeId)
        AND (@ContingentBillStatusId IS NULL OR cb.ContingentBillStatusId = @ContingentBillStatusId)
        AND (@DateStart IS NULL OR cb.BillDate >= @DateStart)
        AND (@DateEnd IS NULL OR cb.BillDate <= @DateEnd)
    ORDER BY cb.CreatedOn DESC;
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
        cb.FinancialYearId,
        fy.Name AS FinancialYearName,
        cb.PurchaseOrderTypeId,
        pot.Name AS PurchaseOrderTypeName,
        cb.PurchaseOrderDate,
        cb.VendorId,
        v.Name AS VendorName,
        cb.BudgetSetupId,
        cb.BillNo,
        cb.BillDate,
        cb.BudgetAllotment,
        cb.BillAmount,
        cb.TotalPreviousBill,
        cb.TotalUptoDate,
        cb.AvailableBalance,
        cb.GrandTotal,
        cb.TaxAmount,
        cb.NetPayment,
        cb.AmountInWords,
        cb.Stamp1,
        cb.Stamp2,
        cb.Stamp3,
        cb.Stamp4,
        cb.Stamp5,
        cb.Stamp6,
        cb.TermsAndConditions,
        cb.PreAuditedAmount,
        cb.PreAuditedAmountInWords,
        cb.TokenNo,
        cb.AuditDate,
        cb.DisplayStampFormatForAuditSection,
        cb.IsClosed,
        cb.Remarks,
        cb.RegisterPageNo,
        cb.SRNO,
        cb.BranchId,
        b.Name AS BranchName,
        cb.ContingentBillStatusId,
        cb.AssignedToId,
        cb.AssignedFromId,
        cb.ApprovedById,
        cb.CreatedById,
        cb.CreatedOn,
        cb.ModifiedById,
        cb.ModifiedOn,
        cb.IsDeleted,
        cb.IsActive
    FROM dbo.ContingentBills cb
    LEFT JOIN dbo.FinancialYears fy ON cb.FinancialYearId = fy.Id
    LEFT JOIN dbo.PurchaseOrderTypes pot ON cb.PurchaseOrderTypeId = pot.Id
    LEFT JOIN dbo.Vendors v ON cb.VendorId = v.Id
    LEFT JOIN dbo.Branches b ON cb.BranchId = b.Id
    WHERE cb.Id = @Id AND cb.IsDeleted = 0;
END
GO

-- 3. Insert Contingent Bill
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'ContingentBills_Insert')
    DROP PROCEDURE ContingentBills_Insert;
GO

CREATE PROCEDURE ContingentBills_Insert
    @FinancialYearId INT,
    @PurchaseOrderTypeId INT,
    @PurchaseOrderDate DATETIME,
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

    INSERT INTO dbo.ContingentBills (
        FinancialYearId,
        PurchaseOrderTypeId,
        PurchaseOrderDate,
        VendorId,
        BudgetSetupId,
        BillNo,
        BillDate,
        BudgetAllotment,
        BillAmount,
        TotalPreviousBill,
        TotalUptoDate,
        AvailableBalance,
        GrandTotal,
        TaxAmount,
        NetPayment,
        AmountInWords,
        Stamp1,
        Stamp2,
        Stamp3,
        Stamp4,
        Stamp5,
        Stamp6,
        TermsAndConditions,
        PreAuditedAmount,
        PreAuditedAmountInWords,
        TokenNo,
        AuditDate,
        DisplayStampFormatForAuditSection,
        IsClosed,
        Remarks,
        RegisterPageNo,
        SRNO,
        BranchId,
        ContingentBillStatusId,
        AssignedToId,
        AssignedFromId,
        ApprovedById,
        CreatedById,
        CreatedOn,
        IsDeleted,
        IsActive
    )
    VALUES (
        @FinancialYearId,
        @PurchaseOrderTypeId,
        @PurchaseOrderDate,
        @VendorId,
        @BudgetSetupId,
        @BillNo,
        @BillDate,
        @BudgetAllotment,
        @BillAmount,
        @TotalPreviousBill,
        @TotalUptoDate,
        @AvailableBalance,
        @GrandTotal,
        @TaxAmount,
        @NetPayment,
        @AmountInWords,
        @Stamp1,
        @Stamp2,
        @Stamp3,
        @Stamp4,
        @Stamp5,
        @Stamp6,
        @TermsAndConditions,
        @PreAuditedAmount,
        @PreAuditedAmountInWords,
        @TokenNo,
        @AuditDate,
        @DisplayStampFormatForAuditSection,
        @IsClosed,
        @Remarks,
        @RegisterPageNo,
        @SRNO,
        @BranchId,
        @ContingentBillStatusId,
        @AssignedToId,
        @AssignedFromId,
        @ApprovedById,
        @CreatedById,
        GETDATE(),
        0,
        1
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
    @FinancialYearId INT,
    @PurchaseOrderTypeId INT,
    @PurchaseOrderDate DATETIME,
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

    UPDATE dbo.ContingentBills
    SET 
        FinancialYearId = @FinancialYearId,
        PurchaseOrderTypeId = @PurchaseOrderTypeId,
        PurchaseOrderDate = @PurchaseOrderDate,
        VendorId = @VendorId,
        BudgetSetupId = @BudgetSetupId,
        BillNo = @BillNo,
        BillDate = @BillDate,
        BudgetAllotment = @BudgetAllotment,
        BillAmount = @BillAmount,
        TotalPreviousBill = @TotalPreviousBill,
        TotalUptoDate = @TotalUptoDate,
        AvailableBalance = @AvailableBalance,
        GrandTotal = @GrandTotal,
        TaxAmount = @TaxAmount,
        NetPayment = @NetPayment,
        AmountInWords = @AmountInWords,
        Stamp1 = @Stamp1,
        Stamp2 = @Stamp2,
        Stamp3 = @Stamp3,
        Stamp4 = @Stamp4,
        Stamp5 = @Stamp5,
        Stamp6 = @Stamp6,
        TermsAndConditions = @TermsAndConditions,
        PreAuditedAmount = @PreAuditedAmount,
        PreAuditedAmountInWords = @PreAuditedAmountInWords,
        TokenNo = @TokenNo,
        AuditDate = @AuditDate,
        DisplayStampFormatForAuditSection = @DisplayStampFormatForAuditSection,
        IsClosed = @IsClosed,
        Remarks = @Remarks,
        RegisterPageNo = @RegisterPageNo,
        SRNO = @SRNO,
        ContingentBillStatusId = @ContingentBillStatusId,
        AssignedToId = @AssignedToId,
        AssignedFromId = @AssignedFromId,
        ApprovedById = @ApprovedById,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETDATE()
    WHERE Id = @Id AND IsDeleted = 0;

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

    UPDATE dbo.ContingentBills
    SET 
        IsDeleted = 1,
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
    FROM dbo.FinancialYears
    WHERE IsActive = 1
    ORDER BY Name;

    -- Purchase Order Types
    SELECT 
        Id,
        Name
    FROM dbo.PurchaseOrderTypes
    WHERE IsActive = 1
    ORDER BY Name;

    -- Vendors
    SELECT 
        Id,
        Name
    FROM dbo.Vendors
    WHERE IsActive = 1
    ORDER BY Name;

    -- Branches
    SELECT 
        Id,
        Name
    FROM dbo.Branches
    WHERE IsActive = 1
    ORDER BY Name;
END
GO

PRINT 'All ContingentBills stored procedures created successfully.';
