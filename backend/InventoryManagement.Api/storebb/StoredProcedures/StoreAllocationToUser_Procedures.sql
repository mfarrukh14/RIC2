-- =============================================
-- StoreAllocationToUser Stored Procedures
-- =============================================

-- =============================================
-- Procedure: StoreAllocationToUser_GetAll
-- =============================================
IF OBJECT_ID('dbo.StoreAllocationToUser_GetAll', 'P') IS NOT NULL
    DROP PROCEDURE dbo.StoreAllocationToUser_GetAll;
GO

CREATE PROCEDURE dbo.StoreAllocationToUser_GetAll
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        sa.Id,
        sa.StoreId,
        s.StoreName,
        sa.EmployeeName,
        sa.IsActive,
        sa.CreatedById,
        sa.CreatedOn,
        sa.ModifiedById,
        sa.ModifiedOn
    FROM dbo.StoreAllocationToUser sa
    INNER JOIN dbo.Stores s ON sa.StoreId = s.StoreId
    ORDER BY sa.CreatedOn DESC;
END
GO

-- =============================================
-- Procedure: StoreAllocationToUser_GetById
-- =============================================
IF OBJECT_ID('dbo.StoreAllocationToUser_GetById', 'P') IS NOT NULL
    DROP PROCEDURE dbo.StoreAllocationToUser_GetById;
GO

CREATE PROCEDURE dbo.StoreAllocationToUser_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        sa.Id,
        sa.StoreId,
        s.StoreName,
        sa.EmployeeName,
        sa.IsActive,
        sa.CreatedById,
        sa.CreatedOn,
        sa.ModifiedById,
        sa.ModifiedOn
    FROM dbo.StoreAllocationToUser sa
    INNER JOIN dbo.Stores s ON sa.StoreId = s.StoreId
    WHERE sa.Id = @Id;
END
GO

-- =============================================
-- Procedure: StoreAllocationToUser_Insert
-- =============================================
IF OBJECT_ID('dbo.StoreAllocationToUser_Insert', 'P') IS NOT NULL
    DROP PROCEDURE dbo.StoreAllocationToUser_Insert;
GO

CREATE PROCEDURE dbo.StoreAllocationToUser_Insert
    @StoreId INT,
    @EmployeeName NVARCHAR(255),
    @IsActive BIT = 1,
    @CreatedById INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.StoreAllocationToUser (
        StoreId, EmployeeName, IsActive, CreatedById, CreatedOn
    )
    VALUES (
        @StoreId, @EmployeeName, @IsActive, @CreatedById, GETDATE()
    );

    SELECT SCOPE_IDENTITY() AS Id;
END
GO

-- =============================================
-- Procedure: StoreAllocationToUser_Update
-- =============================================
IF OBJECT_ID('dbo.StoreAllocationToUser_Update', 'P') IS NOT NULL
    DROP PROCEDURE dbo.StoreAllocationToUser_Update;
GO

CREATE PROCEDURE dbo.StoreAllocationToUser_Update
    @Id INT,
    @StoreId INT,
    @EmployeeName NVARCHAR(255),
    @IsActive BIT,
    @ModifiedById INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.StoreAllocationToUser
    SET 
        StoreId = @StoreId,
        EmployeeName = @EmployeeName,
        IsActive = @IsActive,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETDATE()
    WHERE Id = @Id;
END
GO

-- =============================================
-- Procedure: StoreAllocationToUser_Delete
-- =============================================
IF OBJECT_ID('dbo.StoreAllocationToUser_Delete', 'P') IS NOT NULL
    DROP PROCEDURE dbo.StoreAllocationToUser_Delete;
GO

CREATE PROCEDURE dbo.StoreAllocationToUser_Delete
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM dbo.StoreAllocationToUser WHERE Id = @Id;
END
GO

PRINT 'StoreAllocationToUser stored procedures created successfully';
GO
