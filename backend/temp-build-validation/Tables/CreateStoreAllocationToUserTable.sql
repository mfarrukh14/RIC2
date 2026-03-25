-- =============================================
-- Create StoreAllocationToUser Table
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'StoreAllocationToUser')
BEGIN
    CREATE TABLE dbo.StoreAllocationToUser (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        StoreId INT NOT NULL,
        EmployeeId INT NOT NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById INT,
        ModifiedOn DATETIME,
        CONSTRAINT FK_StoreAllocationToUser_Stores FOREIGN KEY (StoreId) REFERENCES dbo.Stores(StoreId)
    );
    
    PRINT 'StoreAllocationToUser table created successfully';
END
ELSE
BEGIN
    PRINT 'StoreAllocationToUser table already exists';
END
GO
