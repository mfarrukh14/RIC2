-- Create TransferInventory table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TransferInventory')
BEGIN
    CREATE TABLE dbo.TransferInventory (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        DRNo NVARCHAR(50) NOT NULL,
        FromStoreId INT NOT NULL,
        ToStoreId INT NOT NULL,
        StockTypeId INT NOT NULL,
        ItemId INT NOT NULL,
        ItemName NVARCHAR(MAX),
        Quantity INT NOT NULL,
        TransferDate DATETIME NOT NULL DEFAULT GETDATE(),
        Status NVARCHAR(50) DEFAULT 'Pending',
        Notes NVARCHAR(MAX),
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById INT,
        ModifiedOn DATETIME,
        CONSTRAINT FK_Transfer_FromStore FOREIGN KEY (FromStoreId) REFERENCES Stores(StoreId),
        CONSTRAINT FK_Transfer_ToStore FOREIGN KEY (ToStoreId) REFERENCES Stores(StoreId),
        CONSTRAINT FK_Transfer_StockType FOREIGN KEY (StockTypeId) REFERENCES StockTypes(StockTypeId),
        CONSTRAINT FK_Transfer_Item FOREIGN KEY (ItemId) REFERENCES Items(Id)
    );
    PRINT 'TransferInventory table created successfully';
END
ELSE
BEGIN
    PRINT 'TransferInventory table already exists';
END
GO
