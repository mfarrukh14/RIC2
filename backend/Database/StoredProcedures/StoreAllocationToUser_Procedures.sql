-- =============================================
-- StoreAllocationToUser Stored Procedures
-- =============================================

-- =============================================
-- Procedure: StoreAllocationToUser_GetAll
-- =============================================
CREATE OR ALTER PROCEDURE StoreAllocationToUser_GetAll
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        sa.Id,
        sa.StoreId,
        s.StoreName,
        ISNULL(u.Name, '') AS EmployeeName,
        sa.IsActive,
        sa.CreatedById,
        sa.CreatedOn,
        sa.ModifiedById,
        sa.ModifiedOn
    FROM dbo.StoreAllocationToUser sa
    INNER JOIN dbo.Stores s ON sa.StoreId = s.StoreId
    LEFT JOIN dbo.Users u ON sa.UserId = u.Id
    ORDER BY sa.CreatedOn DESC;
END
GO

-- =============================================
-- Procedure: StoreAllocationToUser_GetById
-- =============================================
CREATE OR ALTER PROCEDURE StoreAllocationToUser_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        sa.Id,
        sa.StoreId,
        s.StoreName,
        ISNULL(u.Name, '') AS EmployeeName,
        sa.IsActive,
        sa.CreatedById,
        sa.CreatedOn,
        sa.ModifiedById,
        sa.ModifiedOn
    FROM dbo.StoreAllocationToUser sa
    INNER JOIN dbo.Stores s ON sa.StoreId = s.StoreId
    LEFT JOIN dbo.Users u ON sa.UserId = u.Id
    WHERE sa.Id = @Id;
END
GO

-- =============================================
-- Procedure: StoreAllocationToUser_Insert
-- =============================================
CREATE OR ALTER PROCEDURE StoreAllocationToUser_Insert
    @StoreId INT,
    @EmployeeName NVARCHAR(255),
    @IsActive BIT = 1,
    @CreatedById INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UserId INT;
    SELECT TOP 1 @UserId = Id FROM dbo.Users WHERE Name = @EmployeeName;

    INSERT INTO dbo.StoreAllocationToUser (
        StoreId, UserId, BranchId, IsActive, CreatedById, CreatedOn
    )
    VALUES (
        @StoreId, @UserId, 1, @IsActive, @CreatedById, GETDATE()
    );

    SELECT SCOPE_IDENTITY() AS Id;
END
GO

-- =============================================
-- Procedure: StoreAllocationToUser_Update
-- =============================================
CREATE OR ALTER PROCEDURE StoreAllocationToUser_Update
    @Id INT,
    @StoreId INT,
    @EmployeeName NVARCHAR(255),
    @IsActive BIT,
    @ModifiedById INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UserId INT;
    SELECT TOP 1 @UserId = Id FROM dbo.Users WHERE Name = @EmployeeName;

    UPDATE dbo.StoreAllocationToUser
    SET 
        StoreId = @StoreId,
        UserId = @UserId,
        IsActive = @IsActive,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETDATE()
    WHERE Id = @Id;
END
GO

-- =============================================
-- Procedure: StoreAllocationToUser_Delete
-- =============================================
CREATE OR ALTER PROCEDURE StoreAllocationToUser_Delete
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM dbo.StoreAllocationToUser WHERE Id = @Id;
END
GO

PRINT 'StoreAllocationToUser stored procedures created successfully';
GO
