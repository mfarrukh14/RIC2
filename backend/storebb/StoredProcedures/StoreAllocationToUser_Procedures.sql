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

    -- EmployeeName resolves the real person's name (Employee.FullName, falling
    -- back to First+Last), not the login UserName.
    SELECT
        sa.Id,
        sa.StoreId,
        s.StoreName,
        sa.UserId,
        ISNULL(
            NULLIF(LTRIM(RTRIM(ISNULL(e.FullName, ISNULL(e.FirstName, '') + ' ' + ISNULL(e.LastName, '')))), ''),
            CAST(sa.UserId AS NVARCHAR(255))
        ) AS EmployeeName,
        sa.IsActive,
        sa.CreatedById,
        sa.CreatedOn,
        sa.ModifiedById,
        sa.ModifiedOn
    FROM Inv.StoreAllocationToUser sa
    INNER JOIN Inv.PharmacyStores s ON sa.StoreId = s.StoreId
    LEFT JOIN dbo.Users u ON sa.UserId = u.UserID
    LEFT JOIN dbo.Employee e ON u.EmpID = e.EmpID
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
        sa.UserId,
        ISNULL(
            NULLIF(LTRIM(RTRIM(ISNULL(e.FullName, ISNULL(e.FirstName, '') + ' ' + ISNULL(e.LastName, '')))), ''),
            CAST(sa.UserId AS NVARCHAR(255))
        ) AS EmployeeName,
        sa.IsActive,
        sa.CreatedById,
        sa.CreatedOn,
        sa.ModifiedById,
        sa.ModifiedOn
    FROM Inv.StoreAllocationToUser sa
    INNER JOIN Inv.PharmacyStores s ON sa.StoreId = s.StoreId
    LEFT JOIN dbo.Users u ON sa.UserId = u.UserID
    LEFT JOIN dbo.Employee e ON u.EmpID = e.EmpID
    WHERE sa.Id = @Id;
END
GO

-- =============================================
-- Procedure: StoreAllocationToUser_Insert
-- =============================================
CREATE OR ALTER PROCEDURE StoreAllocationToUser_Insert
    @StoreId INT,
    @UserId INT,
    @IsActive BIT = 1,
    @CreatedById INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UsersIdColumn SYSNAME = CASE
        WHEN COL_LENGTH('dbo.Users', 'Id') IS NOT NULL THEN 'Id'
        WHEN COL_LENGTH('dbo.Users', 'UserID') IS NOT NULL THEN 'UserID'
        ELSE NULL
    END;
    DECLARE @UserExists BIT = 0;
    DECLARE @BranchId INT = NULL;

    IF @UsersIdColumn IS NULL
    BEGIN
        THROW 50001, 'Selected user was not found in dbo.Users.', 1;
    END

    DECLARE @UserExistsSql NVARCHAR(MAX) = N'
SELECT TOP 1 @UserExists = 1
FROM dbo.Users
WHERE ' + QUOTENAME(@UsersIdColumn) + N' = @UserId;';

    EXEC sys.sp_executesql
        @UserExistsSql,
        N'@UserId INT, @UserExists BIT OUTPUT',
        @UserId = @UserId,
        @UserExists = @UserExists OUTPUT;

    IF @UserExists = 0
    BEGIN
        THROW 50001, 'Selected user was not found in dbo.Users.', 1;
    END

    IF COL_LENGTH('Inv.PharmacyStores', 'BranchId') IS NOT NULL
    BEGIN
        SELECT TOP 1 @BranchId = BranchId
        FROM Inv.PharmacyStores
        WHERE StoreId = @StoreId;
    END

    INSERT INTO Inv.StoreAllocationToUser (
        StoreId, UserId, BranchId, IsActive, CreatedById, CreatedOn
    )
    VALUES (
        @StoreId, @UserId, @BranchId, @IsActive, @CreatedById, GETDATE()
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
    @UserId INT,
    @IsActive BIT,
    @ModifiedById INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UsersIdColumn SYSNAME = CASE
        WHEN COL_LENGTH('dbo.Users', 'Id') IS NOT NULL THEN 'Id'
        WHEN COL_LENGTH('dbo.Users', 'UserID') IS NOT NULL THEN 'UserID'
        ELSE NULL
    END;
    DECLARE @UserExists BIT = 0;
    DECLARE @BranchId INT = NULL;

    IF @UsersIdColumn IS NULL
    BEGIN
        THROW 50001, 'Selected user was not found in dbo.Users.', 1;
    END

    DECLARE @UserExistsSql NVARCHAR(MAX) = N'
SELECT TOP 1 @UserExists = 1
FROM dbo.Users
WHERE ' + QUOTENAME(@UsersIdColumn) + N' = @UserId;';

    EXEC sys.sp_executesql
        @UserExistsSql,
        N'@UserId INT, @UserExists BIT OUTPUT',
        @UserId = @UserId,
        @UserExists = @UserExists OUTPUT;

    IF @UserExists = 0
    BEGIN
        THROW 50001, 'Selected user was not found in dbo.Users.', 1;
    END

    IF COL_LENGTH('Inv.PharmacyStores', 'BranchId') IS NOT NULL
    BEGIN
        SELECT TOP 1 @BranchId = BranchId
        FROM Inv.PharmacyStores
        WHERE StoreId = @StoreId;
    END

    UPDATE Inv.StoreAllocationToUser
    SET
        StoreId = @StoreId,
        UserId = @UserId,
        BranchId = @BranchId,
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

    DELETE FROM Inv.StoreAllocationToUser WHERE Id = @Id;
END
GO

PRINT 'StoreAllocationToUser stored procedures created successfully';
GO
