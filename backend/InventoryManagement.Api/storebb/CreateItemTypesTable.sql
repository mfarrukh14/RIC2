-- =============================================
-- Create ItemTypes Table
-- Based on the provided database schema
-- =============================================

-- Create ItemTypes table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ItemTypes')
BEGIN
    CREATE TABLE dbo.ItemTypes (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(MAX) NOT NULL,
        Description NVARCHAR(MAX) NULL,
        Value INT NULL,
        BranchId INT NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NOT NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETUTCDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL,
        
        -- Foreign key constraint
        CONSTRAINT FK_ItemTypes_Branches_BranchId 
            FOREIGN KEY (BranchId) REFERENCES dbo.Branches(Id)
    );
    
    PRINT 'ItemTypes table created successfully!';
END
ELSE
BEGIN
    PRINT 'ItemTypes table already exists.';
END

-- Insert sample data matching the UI screenshot
IF NOT EXISTS (SELECT * FROM dbo.ItemTypes WHERE Name = 'IT Equipments')
BEGIN
    INSERT INTO dbo.ItemTypes (Name, Description, Value, BranchId, IsActive, CreatedById, CreatedOn)
    VALUES 
    ('IT Equipments', NULL, 14, 1, 1, 1, GETUTCDATE()),
    ('Painter Item', NULL, 33, 1, 1, 1, GETUTCDATE()),
    ('Building Maintenance', NULL, 32, 2, 1, 1, GETUTCDATE()),
    ('Sanitary Item', NULL, 30, 1, 1, 1, GETUTCDATE()),
    ('Carpenter Item', NULL, 29, 2, 1, 1, GETUTCDATE()),
    ('Electric Item', NULL, 28, 1, 1, 1, GETUTCDATE()),
    ('Stationary', NULL, 27, 2, 1, 1, GETUTCDATE()),
    ('Bio Medical Equipment Parts', 'Bio Medical Equipment Parts', 26, 1, 1, 1, GETUTCDATE()),
    ('Bio Medical Equipment', 'Bio Medical Equipment', 25, 1, 1, 1, GETUTCDATE()),
    ('Rafting', NULL, 15, 2, 1, 1, GETUTCDATE());
    
    PRINT 'Sample item types data inserted successfully!';
END
ELSE
BEGIN
    PRINT 'Sample item types data already exists.';
END

PRINT 'ItemTypes table setup completed!';