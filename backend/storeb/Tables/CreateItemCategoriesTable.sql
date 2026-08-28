-- Create ItemCategories table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ItemCategories')
BEGIN
    CREATE TABLE ItemCategories (
        Id INT PRIMARY KEY IDENTITY(1,1),
        Name NVARCHAR(255) NOT NULL,
        Description NVARCHAR(MAX) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        IsDeleted BIT NOT NULL DEFAULT 0,
        CreatedById NVARCHAR(255) NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById NVARCHAR(255) NULL,
        ModifiedOn DATETIME NULL
    );

    PRINT 'ItemCategories table created successfully.';
END
ELSE
BEGIN
    PRINT 'ItemCategories table already exists.';
END
GO
