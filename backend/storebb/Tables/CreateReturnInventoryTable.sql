-- ReturnInventory / ReturnInventoryItems live under the Inv schema (already deployed).
-- This script is idempotent: it creates the tables if missing, and adds the
-- PurchaseOrderNo / ItemTypeId columns used by the "Return Inventory Wrt Items"
-- feature if an older version of the table is present without them.
IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'Inv' AND t.name = 'ReturnInventory')
BEGIN
    CREATE TABLE Inv.ReturnInventory (
        Id INT PRIMARY KEY IDENTITY(1,1),
        ReturnNumber NVARCHAR(50) NULL,
        PurchaseOrderNo NVARCHAR(50) NULL,
        VendorId INT NULL,
        StoreId INT NOT NULL,
        BranchId INT NOT NULL,
        ItemTypeId INT NULL,
        ReturnDate DATETIME NOT NULL DEFAULT GETDATE(),
        Reason NVARCHAR(MAX) NULL,
        Notes NVARCHAR(MAX) NULL,
        Status NVARCHAR(50) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL,

        CONSTRAINT FK_ReturnInventory_Store FOREIGN KEY (StoreId) REFERENCES Inv.PharmacyStores(StoreId),
        CONSTRAINT FK_ReturnInventory_ItemType FOREIGN KEY (ItemTypeId) REFERENCES Inv.ItemTypes(Id),
        CONSTRAINT FK_ReturnInventory_Vendor FOREIGN KEY (VendorId) REFERENCES Inv.Vendors(Id)
    );

    PRINT 'Inv.ReturnInventory table created successfully';
END
ELSE
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.ReturnInventory') AND name = 'PurchaseOrderNo')
    BEGIN
        ALTER TABLE Inv.ReturnInventory ADD PurchaseOrderNo NVARCHAR(50) NULL;
        PRINT 'Added PurchaseOrderNo to Inv.ReturnInventory';
    END

    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.ReturnInventory') AND name = 'ItemTypeId')
    BEGIN
        ALTER TABLE Inv.ReturnInventory ADD ItemTypeId INT NULL;
        PRINT 'Added ItemTypeId to Inv.ReturnInventory';
    END

    PRINT 'Inv.ReturnInventory table already exists';
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'Inv' AND t.name = 'ReturnInventoryItems')
BEGIN
    CREATE TABLE Inv.ReturnInventoryItems (
        Id INT PRIMARY KEY IDENTITY(1,1),
        ReturnInventoryId INT NOT NULL,
        ItemId INT NOT NULL,
        Quantity INT NOT NULL,
        Reason NVARCHAR(MAX) NULL,
        Notes NVARCHAR(MAX) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),

        CONSTRAINT FK_ReturnInventoryItems_Return FOREIGN KEY (ReturnInventoryId) REFERENCES Inv.ReturnInventory(Id),
        CONSTRAINT FK_ReturnInventoryItems_Item FOREIGN KEY (ItemId) REFERENCES Inv.Items(Id)
    );

    PRINT 'Inv.ReturnInventoryItems table created successfully';
END
ELSE
BEGIN
    PRINT 'Inv.ReturnInventoryItems table already exists';
END
GO
