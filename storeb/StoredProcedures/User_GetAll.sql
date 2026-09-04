-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Get all users for dropdown/selection
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'User_GetAll')
    DROP PROCEDURE [dbo].[User_GetAll]
GO

CREATE PROCEDURE [dbo].[User_GetAll]
AS
BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #UserLookup
    (
        Id INT NOT NULL PRIMARY KEY,
        Name NVARCHAR(4000) NULL,
        Email NVARCHAR(256) NULL,
        UserName NVARCHAR(256) NULL,
        Department NVARCHAR(256) NULL,
        Designation NVARCHAR(256) NULL,
        IsActive BIT NOT NULL
    );

    -- Note: DropDown.DD_Users is intentionally not used here. It requires mandatory
    -- @UserTypeId/@BranchId/@OrganizationId parameters we have no generic value for,
    -- and Microsoft.Data.SqlClient surfaces its parameter error as a SqlException even
    -- when caught by TRY/CATCH in T-SQL. dbo.Users below is sufficient on its own.
    IF COL_LENGTH('dbo.Users', 'UserID') IS NOT NULL
    BEGIN
        INSERT INTO #UserLookup (Id, Name, Email, UserName, Department, Designation, IsActive)
        EXEC sp_executesql N'
            SELECT
                raw.UserID AS Id,
                COALESCE(NULLIF(LTRIM(RTRIM(emp.FullName)), ''''), NULLIF(LTRIM(RTRIM(raw.UserName)), ''''), CONCAT(''User '', CAST(raw.UserID AS NVARCHAR(20)))) AS Name,
                CAST(NULL AS NVARCHAR(256)) AS Email,
                raw.UserName,
                CAST(NULL AS NVARCHAR(256)) AS Department,
                CAST(NULL AS NVARCHAR(256)) AS Designation,
                CAST(CASE WHEN ISNULL(raw.Status, 1) = 1 THEN 1 ELSE 0 END AS BIT) AS IsActive
            FROM dbo.Users raw
            LEFT JOIN dbo.Employee emp ON emp.EmpID = raw.EmpID
            WHERE ISNULL(raw.Status, 1) = 1
              AND NULLIF(LTRIM(RTRIM(raw.UserName)), '''') IS NOT NULL
              AND NOT EXISTS (
                  SELECT 1
                  FROM #UserLookup existing
                  WHERE existing.Id = raw.UserID
              );';
    END

    ELSE IF COL_LENGTH('dbo.Users', 'Id') IS NOT NULL
    BEGIN
        INSERT INTO #UserLookup (Id, Name, Email, UserName, Department, Designation, IsActive)
        EXEC sp_executesql N'
            SELECT
                raw.Id,
                raw.Name,
                raw.Email,
                raw.UserName,
                raw.Department,
                raw.Designation,
                CAST(ISNULL(raw.IsActive, 1) AS BIT) AS IsActive
            FROM dbo.Users raw
            WHERE ISNULL(raw.IsActive, 1) = 1
              AND NULLIF(LTRIM(RTRIM(raw.Name)), '''') IS NOT NULL
              AND NOT EXISTS (
                  SELECT 1
                  FROM #UserLookup existing
                  WHERE existing.Id = raw.Id
              );';
    END

    SELECT
        Id,
        Name,
        Email,
        UserName,
        Department,
        Designation,
        IsActive
    FROM #UserLookup
    ORDER BY Name;
END