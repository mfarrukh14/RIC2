-- =============================================
-- Create Brands Table
-- Based on the provided database schema
-- =============================================

-- Create Brands table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Brands')
BEGIN
    CREATE TABLE dbo.Brands (
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
        CONSTRAINT FK_Brands_Branches_BranchId 
            FOREIGN KEY (BranchId) REFERENCES dbo.Branches(Id)
    );
    
    PRINT 'Brands table created successfully!';
END
ELSE
BEGIN
    PRINT 'Brands table already exists.';
END

-- Insert sample data matching the UI screenshot
IF NOT EXISTS (SELECT * FROM dbo.Brands WHERE Name = 'Acan USA')
BEGIN
    INSERT INTO dbo.Brands (Name, Description, BranchId, IsActive, CreatedById, CreatedOn)
    VALUES 
    ('Acan USA', 'Medical equipment brand from USA', 1, 1, 1, GETUTCDATE()),
    ('Test Brand', 'Test brand for development', 1, 1, 1, GETUTCDATE()),
    ('adravax (adrenaline)', 'Adrenaline medication brand', 2, 1, 1, GETUTCDATE()),
    ('SJM Master Series', 'SJM Master medical device series', 1, 1, 1, GETUTCDATE()),
    ('Valvuzid-5 (Bisoprolol fumarate)', 'Bisoprolol fumarate medication', 3, 1, 1, GETUTCDATE()),
    ('Cobas Pro', 'cobas® pro integrated solutions. Simplicity meets excellence. Designed to meet your mid- to high-volume clinical chemistry and immunochemistry testing needs.', 1, 1, 1, GETUTCDATE()),
    ('Hitrasact sr 5.4mg', 'Sustained release medication', 2, 1, 1, GETUTCDATE()),
    ('Green IV Catheter', 'Sterile EO Manufactured by Silver Surgical', 1, 1, 1, GETUTCDATE()),
    ('Chana', 'Teflon Sheet', 3, 1, 1, GETUTCDATE()),
    ('Renewal Applied 069502 Unison', 'Medical device renewal application', 1, 1, 1, GETUTCDATE());
    
    PRINT 'Sample brands data inserted successfully!';
END
ELSE
BEGIN
    PRINT 'Sample brands data already exists.';
END

PRINT 'Brands table setup completed!';