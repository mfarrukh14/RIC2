-- =============================================
-- Create Purchase Requisition tables (Inv schema)
-- Ported from the old iHealthCure system's PurchaseRequisitions /
-- PurchaseRequisitionItems / PurchaseRequisitionLifeCycles / PurchaseRequisitionStatus
-- (dbo.*, uniqueidentifier PKs) - rebuilt here with int PKs matching this app's
-- Inv schema conventions. RFQ/WorkOrder/TechnicalReview fields are kept as plain
-- data columns for parity; this app does not implement separate RFQ-bidding or
-- Work-Order-authority workflow screens (that's covered by the separate Eproc
-- procurement schema already present in this database).
-- =============================================

IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE t.name = 'PurchaseRequisitionStatus' AND s.name = 'Inv')
BEGIN
    CREATE TABLE Inv.PurchaseRequisitionStatus (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(50) NOT NULL,
        -- Which of the 3 list tabs this status falls under.
        Category NVARCHAR(20) NOT NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE()
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM Inv.PurchaseRequisitionStatus)
BEGIN
    INSERT INTO Inv.PurchaseRequisitionStatus (Name, Category) VALUES
        ('Pending', 'Pending'),
        ('Forward', 'Pending'),
        ('Approved', 'Processed'),
        ('Open', 'Processed'),
        ('Partially Received', 'Processed'),
        ('On Hold', 'Processed'),
        ('Received', 'Closed'),
        ('Closed', 'Closed'),
        ('Rejected', 'Closed'),
        ('Cancelled', 'Closed');
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE t.name = 'BudgetHeads' AND s.name = 'Inv')
BEGIN
    CREATE TABLE Inv.BudgetHeads (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        ObjectCode NVARCHAR(20) NULL,
        ObjectClassification NVARCHAR(200) NOT NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE()
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM Inv.BudgetHeads)
BEGIN
    INSERT INTO Inv.BudgetHeads (ObjectCode, ObjectClassification) VALUES
        ('A01', 'Medical & Surgical Store'),
        ('A02', 'Medicines & Pharmaceuticals'),
        ('A03', 'Equipment & Machinery'),
        ('A04', 'Repair & Maintenance'),
        ('A05', 'General Stores & Supplies');
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE t.name = 'PurchaseRequisitions' AND s.name = 'Inv')
BEGIN
    CREATE TABLE Inv.PurchaseRequisitions (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        PRNumber NVARCHAR(30) NOT NULL,
        DemandRequestId INT NULL,
        DemandNo NVARCHAR(50) NULL,
        BranchId INT NOT NULL,
        StoreId INT NULL,
        DepartmentId INT NULL,
        FinancialYearId INT NULL,
        DistributionPlan NVARCHAR(200) NULL,
        Priority INT NOT NULL DEFAULT 1, -- 1 Routine, 2 Urgent
        DateRequiredBy DATETIME NULL,
        PRType INT NOT NULL DEFAULT 1,
        VendorId INT NULL,
        SuggestedProcurementMethod NVARCHAR(200) NULL,
        Subject NVARCHAR(300) NULL,
        ScopeOfWork NVARCHAR(MAX) NULL,
        Instructions NVARCHAR(MAX) NULL,
        Remarks NVARCHAR(MAX) NULL,
        GoodsDeliveredContactPerson NVARCHAR(150) NULL,
        GoodsDeliveredCellNumber NVARCHAR(50) NULL,
        GoodsDeliveredEmail NVARCHAR(150) NULL,
        GoodsDeliveredTelephone NVARCHAR(50) NULL,
        GoodsDeliveredFaxNo NVARCHAR(50) NULL,
        GoodsDeliveryAddress NVARCHAR(300) NULL,
        TermsAndConditions NVARCHAR(MAX) NULL,
        ExecutionType INT NOT NULL DEFAULT 1, -- 1 Purchase, 2 WorkOrder, 3 RFQ
        IsRequestForQuotation BIT NOT NULL DEFAULT 0,
        RFQBidNumber NVARCHAR(50) NULL,
        VendorQuoteNo NVARCHAR(50) NULL,
        VendorQuoteDate DATETIME NULL,
        WorkOrderRequestNumber NVARCHAR(50) NULL,
        IsTechnicalReviewed BIT NOT NULL DEFAULT 0,
        TechnicalReviewRemarks NVARCHAR(MAX) NULL,
        TechnicalReviewedById INT NULL,
        TechnicalReviewedOn DATETIME NULL,
        TotalEstimatedCost DECIMAL(18,2) NOT NULL DEFAULT 0,
        TotalBudget DECIMAL(18,2) NOT NULL DEFAULT 0,
        PurchaseRequisitionStatusId INT NOT NULL,
        AssignedToId INT NULL,
        IsClosed BIT NOT NULL DEFAULT 0,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL,
        CONSTRAINT UQ_PurchaseRequisitions_PRNumber UNIQUE (PRNumber),
        CONSTRAINT FK_PurchaseRequisitions_Status FOREIGN KEY (PurchaseRequisitionStatusId) REFERENCES Inv.PurchaseRequisitionStatus(Id),
        CONSTRAINT FK_PurchaseRequisitions_Vendors FOREIGN KEY (VendorId) REFERENCES Inv.Vendors(Id),
        CONSTRAINT FK_PurchaseRequisitions_FinancialYears FOREIGN KEY (FinancialYearId) REFERENCES Inv.FinancialYears(Id),
        CONSTRAINT FK_PurchaseRequisitions_DemandRequests FOREIGN KEY (DemandRequestId) REFERENCES Inv.DemandRequests(Id)
    );
    CREATE INDEX IX_PurchaseRequisitions_StatusId ON Inv.PurchaseRequisitions(PurchaseRequisitionStatusId);
    CREATE INDEX IX_PurchaseRequisitions_BranchId ON Inv.PurchaseRequisitions(BranchId);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE t.name = 'PurchaseRequisitionItems' AND s.name = 'Inv')
BEGIN
    CREATE TABLE Inv.PurchaseRequisitionItems (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        PurchaseRequisitionId INT NOT NULL,
        ItemId INT NULL,
        Quantity INT NOT NULL,
        UnitEstimatedCost DECIMAL(18,2) NOT NULL DEFAULT 0,
        TotalEstimatedCost DECIMAL(18,2) NOT NULL DEFAULT 0,
        BudgetHeadId INT NULL,
        AvailableBudget DECIMAL(18,2) NULL,
        BudgetRestriction NVARCHAR(200) NULL,
        Remarks NVARCHAR(MAX) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL,
        IsDeleted BIT NOT NULL DEFAULT 0,
        CONSTRAINT FK_PurchaseRequisitionItems_PurchaseRequisitions FOREIGN KEY (PurchaseRequisitionId) REFERENCES Inv.PurchaseRequisitions(Id),
        CONSTRAINT FK_PurchaseRequisitionItems_Items FOREIGN KEY (ItemId) REFERENCES Inv.Items(Id),
        CONSTRAINT FK_PurchaseRequisitionItems_BudgetHeads FOREIGN KEY (BudgetHeadId) REFERENCES Inv.BudgetHeads(Id)
    );
    CREATE INDEX IX_PurchaseRequisitionItems_PRId ON Inv.PurchaseRequisitionItems(PurchaseRequisitionId);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE t.name = 'PurchaseRequisitionLifeCycles' AND s.name = 'Inv')
BEGIN
    CREATE TABLE Inv.PurchaseRequisitionLifeCycles (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        PurchaseRequisitionId INT NOT NULL,
        PurchaseRequisitionStatusId INT NULL,
        FromUserId INT NULL,
        ToUserId INT NULL,
        Remarks NVARCHAR(500) NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT FK_PurchaseRequisitionLifeCycles_PurchaseRequisitions FOREIGN KEY (PurchaseRequisitionId) REFERENCES Inv.PurchaseRequisitions(Id),
        CONSTRAINT FK_PurchaseRequisitionLifeCycles_Status FOREIGN KEY (PurchaseRequisitionStatusId) REFERENCES Inv.PurchaseRequisitionStatus(Id)
    );
    CREATE INDEX IX_PurchaseRequisitionLifeCycles_PRId ON Inv.PurchaseRequisitionLifeCycles(PurchaseRequisitionId);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE t.name = 'PurchaseRequisitionAttachments' AND s.name = 'Inv')
BEGIN
    CREATE TABLE Inv.PurchaseRequisitionAttachments (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        PurchaseRequisitionId INT NOT NULL,
        FileName NVARCHAR(260) NOT NULL,
        FileUrl NVARCHAR(500) NOT NULL,
        UploadedById INT NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT FK_PurchaseRequisitionAttachments_PurchaseRequisitions FOREIGN KEY (PurchaseRequisitionId) REFERENCES Inv.PurchaseRequisitions(Id)
    );
END
GO
