-- =============================================
-- Category CRUD Stored Procedures
-- =============================================

CREATE OR ALTER PROCEDURE Category_GetById
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
    FROM Inv.Categories
    WHERE Id = @Id;
END
GO

CREATE OR ALTER PROCEDURE Category_Insert
    @Name NVARCHAR(255),
    @Description NVARCHAR(MAX) = NULL,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Inv.Categories (Name, Description, IsActive, CreatedOn)
    VALUES (@Name, @Description, @IsActive, GETDATE());

    SELECT SCOPE_IDENTITY() AS Id;
END
GO

CREATE OR ALTER PROCEDURE Category_Update
    @Id INT,
    @Name NVARCHAR(255),
    @Description NVARCHAR(MAX) = NULL,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Inv.Categories
    SET
        Name = @Name,
        Description = @Description,
        IsActive = @IsActive,
        ModifiedOn = GETDATE()
    WHERE Id = @Id;

    SELECT @@ROWCOUNT AS RowsAffected;
END
GO

-- Permanently delete a category
CREATE OR ALTER PROCEDURE Category_Delete
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM Inv.Categories
    WHERE Id = @Id;

    SELECT @@ROWCOUNT AS RowsAffected;
END
GO

PRINT 'Category CRUD stored procedures created successfully.';
