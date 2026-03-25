-- =============================================
-- Create Stores Table (Must be created before Inventories)
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Stores')
BEGIN
    CREATE TABLE [dbo].[Stores] (
        [StoreId] INT IDENTITY(1,1) PRIMARY KEY,
        [StoreName] NVARCHAR(200) NOT NULL,
        [StoreCode] NVARCHAR(50),
        [Description] NVARCHAR(500),
        [IsActive] BIT NOT NULL DEFAULT 1,
        [CreatedOn] DATETIME DEFAULT GETDATE(),
        [ModifiedOn] DATETIME
    );
    
    -- Insert default store
    INSERT INTO [dbo].[Stores] ([StoreName], [StoreCode], [Description], [IsActive])
    VALUES ('Academic Affair Store', 'AAS', 'Main Academic Affairs Store', 1);
    
    PRINT 'Stores table created successfully with sample data';
END
ELSE
BEGIN
    PRINT 'Stores table already exists';
END
GO
