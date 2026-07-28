-- =============================================
-- Stock Type CRUD Stored Procedures
-- (HMS compatible: uses Id/Name columns)
-- =============================================

-- =============================================
-- Get All Stock Types
-- =============================================
CREATE OR ALTER PROCEDURE StockType_GetAll
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        Id,
        Name,
        Description,
        IsActive
    FROM Inv.StockTypes
    ORDER BY Name;
END
GO

-- =============================================
-- Get Stock Type By Id
-- =============================================
CREATE OR ALTER PROCEDURE StockType_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        Id,
        Name,
        Description,
        IsActive
    FROM Inv.StockTypes
    WHERE Id = @Id;
END
GO

-- =============================================
-- Insert Stock Type
-- =============================================
CREATE OR ALTER PROCEDURE StockType_Insert
    @Name NVARCHAR(MAX),
    @Description NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        INSERT INTO Inv.StockTypes (Name, Description, IsActive)
        VALUES (@Name, @Description, 1);
        
        SELECT SCOPE_IDENTITY() AS Id;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- =============================================
-- Update Stock Type
-- =============================================
CREATE OR ALTER PROCEDURE StockType_Update
    @Id INT,
    @Name NVARCHAR(MAX),
    @Description NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        UPDATE Inv.StockTypes
        SET 
            Name = @Name,
            Description = @Description
        WHERE Id = @Id;
        
        SELECT @@ROWCOUNT AS RowsAffected;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- =============================================
-- Delete Stock Type (permanent)
-- =============================================
CREATE OR ALTER PROCEDURE StockType_Delete
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DELETE FROM Inv.StockTypes
        WHERE Id = @Id;

        SELECT @@ROWCOUNT AS RowsAffected;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO
