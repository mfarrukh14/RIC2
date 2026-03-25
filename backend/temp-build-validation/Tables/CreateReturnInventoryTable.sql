USE InventoryManagementDB_SP;
GO

-- Create ReturnInventory table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ReturnInventory')
BEGIN
    CREATE TABLE ReturnInventory (
        Id INT PRIMARY KEY IDENTITY(1,1),
        InventoryNo NVARCHAR(50) NULL,
        PurchaseOrderNo NVARCHAR(50) NULL,
        BranchId INT NULL,
        StoreId INT NULL,
        ItemTypeId INT NULL,
        ItemId INT NULL,
        ItemName NVARCHAR(MAX) NULL,
        ReturnQuantity INT NOT NULL,
        StockTypeId INT NULL,
        VendorId INT NULL,
        ReturnDate DATETIME NOT NULL DEFAULT GETDATE(),
        Reason NVARCHAR(MAX) NULL,
        Notes NVARCHAR(MAX) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NOT NULL DEFAULT 1,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL,
        
        CONSTRAINT FK_ReturnInventory_Branch FOREIGN KEY (BranchId) REFERENCES Branches(Id),
        CONSTRAINT FK_ReturnInventory_Store FOREIGN KEY (StoreId) REFERENCES Stores(StoreId),
        CONSTRAINT FK_ReturnInventory_ItemType FOREIGN KEY (ItemTypeId) REFERENCES ItemTypes(Id),
        CONSTRAINT FK_ReturnInventory_Item FOREIGN KEY (ItemId) REFERENCES Items(Id),
        CONSTRAINT FK_ReturnInventory_StockType FOREIGN KEY (StockTypeId) REFERENCES StockTypes(StockTypeId),
        CONSTRAINT FK_ReturnInventory_Vendor FOREIGN KEY (VendorId) REFERENCES Vendors(Id)
    );
    
    PRINT 'ReturnInventory table created successfully';
END
ELSE
BEGIN
    PRINT 'ReturnInventory table already exists';
END
GO
