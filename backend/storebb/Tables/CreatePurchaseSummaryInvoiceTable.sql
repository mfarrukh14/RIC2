USE InventoryManagementDB_SP;
GO

-- Create PurchaseSummaryInvoice table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PurchaseSummaryInvoice')
BEGIN
    CREATE TABLE PurchaseSummaryInvoice (
        Id INT PRIMARY KEY IDENTITY(1,1),
        InvoiceDate DATETIME NOT NULL,
        InvoiceNo NVARCHAR(100) NOT NULL,
        VendorId INT NULL,
        VendorName NVARCHAR(MAX) NULL,
        Amount DECIMAL(18, 2) NOT NULL,
        AdvanceTax DECIMAL(18, 2) NULL,
        Discount DECIMAL(18, 2) NULL,
        TotalAmount DECIMAL(18, 2) NOT NULL,
        BranchId INT NULL,
        StoreId INT NULL,
        InventoryDate DATETIME NULL,
        ReportType NVARCHAR(50) NULL, -- 'Purchase', 'Return', 'Both'
        InvoiceType NVARCHAR(50) NULL, -- Additional type field
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NOT NULL DEFAULT 1,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL,
        
        CONSTRAINT FK_PurchaseSummaryInvoice_Branch FOREIGN KEY (BranchId) REFERENCES Branches(Id),
        CONSTRAINT FK_PurchaseSummaryInvoice_Store FOREIGN KEY (StoreId) REFERENCES Stores(StoreId),
        CONSTRAINT FK_PurchaseSummaryInvoice_Vendor FOREIGN KEY (VendorId) REFERENCES Vendors(Id)
    );
    
    PRINT 'PurchaseSummaryInvoice table created successfully';
END
ELSE
BEGIN
    PRINT 'PurchaseSummaryInvoice table already exists';
END
GO
