-- =============================================
-- Stock Type CRUD Stored Procedures
-- =============================================

-- =============================================
-- Get All Stock Types
-- =============================================
CREATE OR ALTER PROCEDURE StockType_GetAll
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        StockTypeId AS Id,
        StockTypeName AS Name,
        Description,
        IsActive
    FROM dbo.StockTypes
    WHERE IsActive = 1
    ORDER BY StockTypeName;
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
        StockTypeId AS Id,
        StockTypeName AS Name,
        Description,
        IsActive
    FROM dbo.StockTypes
    WHERE StockTypeId = @Id;
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
        INSERT INTO dbo.StockTypes (StockTypeName, Description, IsActive)
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
        UPDATE dbo.StockTypes
        SET 
            StockTypeName = @Name,
            Description = @Description
        WHERE StockTypeId = @Id;
        
        SELECT @@ROWCOUNT AS RowsAffected;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- =============================================
-- Delete Stock Type (Soft Delete)
-- =============================================
CREATE OR ALTER PROCEDURE StockType_Delete
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        UPDATE dbo.StockTypes
        SET IsActive = 0
        WHERE StockTypeId = @Id;
        
        SELECT @@ROWCOUNT AS RowsAffected;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO
