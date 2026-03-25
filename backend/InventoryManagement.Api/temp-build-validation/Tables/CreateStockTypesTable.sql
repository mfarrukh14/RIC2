-- =============================================
-- Create StockTypes Table (Must be created before Inventories and GRN)
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'StockTypes')
BEGIN
    CREATE TABLE [dbo].[StockTypes] (
        [StockTypeId] INT IDENTITY(1,1) PRIMARY KEY,
        [StockTypeName] NVARCHAR(100) NOT NULL,
        [Description] NVARCHAR(500),
        [IsActive] BIT NOT NULL DEFAULT 1
    );
    
    -- Insert default stock types
    INSERT INTO [dbo].[StockTypes] ([StockTypeName], [Description], [IsActive])
    VALUES 
        ('Regular', 'Regular stock type', 1),
        ('Consignment', 'Consignment stock', 1),
        ('Sample', 'Sample stock', 1);
    
    PRINT 'StockTypes table created successfully with sample data';
END
ELSE
BEGIN
    PRINT 'StockTypes table already exists';
END
GO
