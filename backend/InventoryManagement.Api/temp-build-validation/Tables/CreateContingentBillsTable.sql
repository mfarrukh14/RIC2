-- Create ContingentBills table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ContingentBills')
BEGIN
    CREATE TABLE dbo.ContingentBills (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        FinancialYearId INT NOT NULL,
        PurchaseOrderTypeId INT NOT NULL,
        PurchaseOrderDate DATETIME NOT NULL,
        VendorId INT NOT NULL,
        BudgetSetupId NVARCHAR(450) NULL,
        BillNo NVARCHAR(MAX) NULL,
        BillDate DATETIME NOT NULL,
        BudgetAllotment REAL NULL,
        BillAmount REAL NULL,
        TotalPreviousBill REAL NULL,
        TotalUptoDate REAL NULL,
        AvailableBalance REAL NULL,
        GrandTotal REAL NULL,
        TaxAmount REAL NULL,
        NetPayment REAL NULL,
        AmountInWords NVARCHAR(MAX) NULL,
        Stamp1 NVARCHAR(MAX) NULL,
        Stamp2 NVARCHAR(MAX) NULL,
        Stamp3 NVARCHAR(MAX) NULL,
        Stamp4 NVARCHAR(MAX) NULL,
        Stamp5 NVARCHAR(MAX) NULL,
        Stamp6 NVARCHAR(MAX) NULL,
        TermsAndConditions NVARCHAR(MAX) NULL,
        PreAuditedAmount REAL NULL,
        PreAuditedAmountInWords NVARCHAR(MAX) NULL,
        TokenNo NVARCHAR(MAX) NULL,
        AuditDate DATETIME NULL,
        DisplayStampFormatForAuditSection BIT NULL,
        IsClosed BIT NOT NULL DEFAULT 0,
        Remarks NVARCHAR(MAX) NULL,
        RegisterPageNo NVARCHAR(MAX) NULL,
        SRNO NVARCHAR(MAX) NULL,
        BranchId INT NOT NULL,
        ContingentBillStatusId INT NULL,
        AssignedToId INT NULL,
        AssignedFromId INT NULL,
        ApprovedById INT NULL,
        CreatedById NVARCHAR(450) NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById NVARCHAR(450) NULL,
        ModifiedOn DATETIME NULL,
        IsDeleted BIT NOT NULL DEFAULT 0,
        IsActive BIT NOT NULL DEFAULT 1,
        CONSTRAINT FK_dbo_ContingentBills_dbo_Branches_BranchId FOREIGN KEY (BranchId) REFERENCES dbo.Branches(Id),
        CONSTRAINT FK_dbo_ContingentBills_dbo_FinancialYears_FinancialYearId FOREIGN KEY (FinancialYearId) REFERENCES dbo.FinancialYears(Id),
        CONSTRAINT FK_dbo_ContingentBills_dbo_PurchaseOrderTypes_PurchaseOrderTypeId FOREIGN KEY (PurchaseOrderTypeId) REFERENCES dbo.PurchaseOrderTypes(Id),
        CONSTRAINT FK_dbo_ContingentBills_dbo_Vendors_VendorId FOREIGN KEY (VendorId) REFERENCES dbo.Vendors(Id)
    );

    PRINT 'ContingentBills table created successfully.';
END
ELSE
BEGIN
    PRINT 'ContingentBills table already exists.';
END
GO
