-- =============================================
-- Create ItemUnits Table
-- Based on the provided database schema
-- =============================================

-- Create ItemUnits table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ItemUnits')
BEGIN
    CREATE TABLE dbo.ItemUnits (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(MAX) NOT NULL,
        Description NVARCHAR(MAX) NULL,
        BranchId INT NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NOT NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETUTCDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL,
        
        -- Foreign key constraint
        CONSTRAINT FK_ItemUnits_Branches_BranchId 
            FOREIGN KEY (BranchId) REFERENCES dbo.Branches(Id)
    );
    
    PRINT 'ItemUnits table created successfully!';
END
ELSE
BEGIN
    PRINT 'ItemUnits table already exists.';
END

-- Insert sample data matching the UI screenshot
IF NOT EXISTS (SELECT * FROM dbo.ItemUnits WHERE Name = 'Job')
BEGIN
    INSERT INTO dbo.ItemUnits (Name, Description, BranchId, IsActive, CreatedById, CreatedOn)
    VALUES 
    ('Job', NULL, 1, 1, 1, GETUTCDATE()),
    ('ft', NULL, 1, 1, 1, GETUTCDATE()),
    ('coil', NULL, 2, 1, 1, GETUTCDATE()),
    ('Vials', NULL, 1, 1, 1, GETUTCDATE()),
    ('Rim', NULL, 2, 1, 1, GETUTCDATE()),
    ('Liters', NULL, 1, 1, 1, GETUTCDATE()),
    ('Tubes', NULL, 2, 1, 1, GETUTCDATE()),
    ('meter', NULL, 1, 1, 1, GETUTCDATE()),
    ('Cans', NULL, 1, 1, 1, GETUTCDATE()),
    ('cft', NULL, 2, 1, 1, GETUTCDATE());
    
    PRINT 'Sample item units data inserted successfully!';
END
ELSE
BEGIN
    PRINT 'Sample item units data already exists.';
END

PRINT 'ItemUnits table setup completed!';