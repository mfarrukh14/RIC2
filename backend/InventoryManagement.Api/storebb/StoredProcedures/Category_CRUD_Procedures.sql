-- =============================================
-- Category CRUD Stored Procedures
-- =============================================

-- Get Category By Id
IF OBJECT_ID('Category_GetById', 'P') IS NOT NULL
    DROP PROCEDURE Category_GetById;
GO

CREATE PROCEDURE Category_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        Id,
        Name,
        Description,
        IsActive,
        CreatedOn,
        ModifiedOn
    FROM Categories
    WHERE Id = @Id;
END
GO

-- Insert Category
IF OBJECT_ID('Category_Insert', 'P') IS NOT NULL
    DROP PROCEDURE Category_Insert;
GO

CREATE PROCEDURE Category_Insert
    @Name NVARCHAR(255),
    @Description NVARCHAR(MAX) = NULL,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO Categories (Name, Description, IsActive, CreatedOn)
    VALUES (@Name, @Description, @IsActive, GETDATE());
    
    SELECT SCOPE_IDENTITY() AS Id;
END
GO

-- Update Category
IF OBJECT_ID('Category_Update', 'P') IS NOT NULL
    DROP PROCEDURE Category_Update;
GO

CREATE PROCEDURE Category_Update
    @Id INT,
    @Name NVARCHAR(255),
    @Description NVARCHAR(MAX) = NULL,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE Categories
    SET 
        Name = @Name,
        Description = @Description,
        IsActive = @IsActive,
        ModifiedOn = GETDATE()
    WHERE Id = @Id;
    
    SELECT @@ROWCOUNT AS RowsAffected;
END
GO

-- Delete Category (Soft Delete - actually just deactivate)
IF OBJECT_ID('Category_Delete', 'P') IS NOT NULL
    DROP PROCEDURE Category_Delete;
GO

CREATE PROCEDURE Category_Delete
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Just deactivate instead of delete to preserve referential integrity
    UPDATE Categories
    SET 
        IsActive = 0,
        ModifiedOn = GETDATE()
    WHERE Id = @Id;
    
    SELECT @@ROWCOUNT AS RowsAffected;
END
GO

PRINT 'Category CRUD stored procedures created successfully.';
