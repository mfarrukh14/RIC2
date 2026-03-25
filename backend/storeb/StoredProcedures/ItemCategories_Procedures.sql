-- =============================================
-- ItemCategories Stored Procedures
-- =============================================

-- Get All ItemCategories
IF OBJECT_ID('ItemCategories_GetAll', 'P') IS NOT NULL
    DROP PROCEDURE ItemCategories_GetAll;
GO

CREATE PROCEDURE ItemCategories_GetAll
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        Id,
        Name,
        Description,
        IsActive,
        IsDeleted,
        CreatedById,
        CreatedOn,
        ModifiedById,
        ModifiedOn
    FROM ItemCategories
    WHERE IsDeleted = 0
    ORDER BY Name;
END
GO

-- Get ItemCategory By Id
IF OBJECT_ID('ItemCategories_GetById', 'P') IS NOT NULL
    DROP PROCEDURE ItemCategories_GetById;
GO

CREATE PROCEDURE ItemCategories_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        Id,
        Name,
        Description,
        IsActive,
        IsDeleted,
        CreatedById,
        CreatedOn,
        ModifiedById,
        ModifiedOn
    FROM ItemCategories
    WHERE Id = @Id AND IsDeleted = 0;
END
GO

-- Insert ItemCategory
IF OBJECT_ID('ItemCategories_Insert', 'P') IS NOT NULL
    DROP PROCEDURE ItemCategories_Insert;
GO

CREATE PROCEDURE ItemCategories_Insert
    @Name NVARCHAR(255),
    @Description NVARCHAR(MAX) = NULL,
    @IsActive BIT = 1,
    @CreatedById NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO ItemCategories (Name, Description, IsActive, CreatedById, CreatedOn)
    VALUES (@Name, @Description, @IsActive, @CreatedById, GETDATE());
    
    SELECT SCOPE_IDENTITY() AS Id;
END
GO

-- Update ItemCategory
IF OBJECT_ID('ItemCategories_Update', 'P') IS NOT NULL
    DROP PROCEDURE ItemCategories_Update;
GO

CREATE PROCEDURE ItemCategories_Update
    @Id INT,
    @Name NVARCHAR(255),
    @Description NVARCHAR(MAX) = NULL,
    @IsActive BIT = 1,
    @ModifiedById NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE ItemCategories
    SET 
        Name = @Name,
        Description = @Description,
        IsActive = @IsActive,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETDATE()
    WHERE Id = @Id AND IsDeleted = 0;
    
    SELECT @@ROWCOUNT AS RowsAffected;
END
GO

-- Delete ItemCategory (Soft Delete)
IF OBJECT_ID('ItemCategories_Delete', 'P') IS NOT NULL
    DROP PROCEDURE ItemCategories_Delete;
GO

CREATE PROCEDURE ItemCategories_Delete
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE ItemCategories
    SET 
        IsDeleted = 1,
        ModifiedOn = GETDATE()
    WHERE Id = @Id;
    
    SELECT @@ROWCOUNT AS RowsAffected;
END
GO

PRINT 'All ItemCategories stored procedures created successfully.';
