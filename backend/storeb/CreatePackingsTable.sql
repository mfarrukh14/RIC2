-- =============================================
-- Create Packings Table
-- Based on the provided database schema
-- =============================================

-- Create Packings table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Packings')
BEGIN
    CREATE TABLE dbo.Packings (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(MAX) NOT NULL,
        Description NVARCHAR(MAX) NULL,
        Pack INT NULL,
        Leaf INT NULL,
        NumberOfItems INT NULL,
        BranchId INT NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NOT NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETUTCDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL,
        
        -- Foreign key constraint
        CONSTRAINT FK_Packings_Branches_BranchId 
            FOREIGN KEY (BranchId) REFERENCES dbo.Branches(Id)
    );
    
    PRINT 'Packings table created successfully!';
END
ELSE
BEGIN
    PRINT 'Packings table already exists.';
END

-- Insert sample data matching the UI screenshot
IF NOT EXISTS (SELECT * FROM dbo.Packings WHERE Name = 'Unit')
BEGIN
    INSERT INTO dbo.Packings (Name, Description, Pack, Leaf, NumberOfItems, BranchId, IsActive, CreatedById, CreatedOn)
    VALUES 
    ('Unit', 'Single unit packaging', 1, 1, 1, 1, 1, 1, GETUTCDATE()),
    ('Box', 'Box packaging for multiple units', 1, 1, 10, 1, 1, 1, GETUTCDATE());
    
    PRINT 'Sample packings data inserted successfully!';
END
ELSE
BEGIN
    PRINT 'Sample packings data already exists.';
END

PRINT 'Packings table setup completed!';