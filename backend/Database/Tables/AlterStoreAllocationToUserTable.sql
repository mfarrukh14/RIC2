-- =============================================
-- Align StoreAllocationToUser Table with UserId-based allocation
-- =============================================
IF OBJECT_ID('dbo.StoreAllocationToUser', 'U') IS NOT NULL
BEGIN
    IF COL_LENGTH('dbo.StoreAllocationToUser', 'UserId') IS NULL
    BEGIN
        IF COL_LENGTH('dbo.StoreAllocationToUser', 'EmployeeId') IS NOT NULL
        BEGIN
            EXEC sp_rename 'dbo.StoreAllocationToUser.EmployeeId', 'UserId', 'COLUMN';
            PRINT 'StoreAllocationToUser column EmployeeId renamed to UserId';
        END
        ELSE
        BEGIN
            ALTER TABLE dbo.StoreAllocationToUser ADD UserId INT NULL;
            PRINT 'StoreAllocationToUser column UserId added';
        END
    END

    IF COL_LENGTH('dbo.StoreAllocationToUser', 'BranchId') IS NULL
    BEGIN
        ALTER TABLE dbo.StoreAllocationToUser ADD BranchId INT NULL;
        PRINT 'StoreAllocationToUser column BranchId added';
    END

    DECLARE @UsersIdColumn SYSNAME = CASE
        WHEN COL_LENGTH('dbo.Users', 'Id') IS NOT NULL THEN 'Id'
        WHEN COL_LENGTH('dbo.Users', 'UserID') IS NOT NULL THEN 'UserID'
        ELSE NULL
    END;
    DECLARE @UsersNameColumn SYSNAME = CASE
        WHEN COL_LENGTH('dbo.Users', 'Name') IS NOT NULL THEN 'Name'
        WHEN COL_LENGTH('dbo.Users', 'UserName') IS NOT NULL THEN 'UserName'
        WHEN COL_LENGTH('dbo.Users', 'FullName') IS NOT NULL THEN 'FullName'
        ELSE NULL
    END;

    IF COL_LENGTH('dbo.StoreAllocationToUser', 'EmployeeName') IS NOT NULL
       AND @UsersIdColumn IS NOT NULL
       AND @UsersNameColumn IS NOT NULL
    BEGIN
        DECLARE @UserMigrationSql NVARCHAR(MAX) = N'
UPDATE sa
SET UserId = COALESCE(sa.UserId, u.' + QUOTENAME(@UsersIdColumn) + N')
FROM dbo.StoreAllocationToUser sa
INNER JOIN dbo.Users u
    ON LTRIM(RTRIM(CONVERT(NVARCHAR(255), u.' + QUOTENAME(@UsersNameColumn) + N'))) = LTRIM(RTRIM(sa.EmployeeName))
WHERE (sa.UserId IS NULL OR sa.UserId = 0)
  AND sa.EmployeeName IS NOT NULL
  AND LTRIM(RTRIM(sa.EmployeeName)) <> '''';';

        EXEC sys.sp_executesql @UserMigrationSql;
        PRINT 'StoreAllocationToUser legacy EmployeeName values mapped to UserId where possible';
    END

    PRINT 'StoreAllocationToUser table aligned to UserId-based allocation';
END
ELSE
BEGIN
    PRINT 'StoreAllocationToUser table does not exist; no alignment needed';
END
GO
