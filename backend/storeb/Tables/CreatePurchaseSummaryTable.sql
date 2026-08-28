USE InventoryManagementDB_SP;
GO

-- Create PurchaseSummary table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PurchaseSummary')
BEGIN
    CREATE TABLE PurchaseSummary (
        Id INT PRIMARY KEY IDENTITY(1,1),
        PurchaseDate DATETIME NOT NULL,
        BatchNo NVARCHAR(100) NULL,
        ItemId INT NOT NULL,
        ItemName NVARCHAR(MAX) NOT NULL,
        StoreId INT NULL,
        StoreName NVARCHAR(MAX) NULL,
        VendorId INT NULL,
        VendorName NVARCHAR(MAX) NULL,
        InvoiceNo NVARCHAR(100) NULL,
        InvoiceDate DATETIME NULL,
        Quantity INT NOT NULL,
        Amount DECIMAL(18, 2) NOT NULL,
        AdvanceTax DECIMAL(18, 2) NULL,
        Discount DECIMAL(18, 2) NULL,
        TotalPrice DECIMAL(18, 2) NOT NULL,
        BranchId INT NULL,
        ItemTypeId INT NULL,
        ReportType NVARCHAR(50) NULL, -- 'Purchase', 'Return', 'Both'
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NOT NULL DEFAULT 1,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL,
        
        CONSTRAINT FK_PurchaseSummary_Branch FOREIGN KEY (BranchId) REFERENCES Branches(Id),
        CONSTRAINT FK_PurchaseSummary_Store FOREIGN KEY (StoreId) REFERENCES Stores(StoreId),
        CONSTRAINT FK_PurchaseSummary_Item FOREIGN KEY (ItemId) REFERENCES Items(Id),
        CONSTRAINT FK_PurchaseSummary_Vendor FOREIGN KEY (VendorId) REFERENCES Vendors(Id),
        CONSTRAINT FK_PurchaseSummary_ItemType FOREIGN KEY (ItemTypeId) REFERENCES ItemTypes(Id)
    );
    
    PRINT 'PurchaseSummary table created successfully';
END
ELSE
BEGIN
    PRINT 'PurchaseSummary table already exists';
END
GO
