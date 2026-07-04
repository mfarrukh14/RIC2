-- =============================================
-- Author: System Generated
-- Create date: 2025-10-03
-- Description: Get asset allocation report with filters
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'AssetAllocation_GetReport')
    DROP PROCEDURE [dbo].[AssetAllocation_GetReport]
GO

CREATE PROCEDURE [dbo].[AssetAllocation_GetReport]
    @StartDate DATETIME2 = NULL,
    @EndDate DATETIME2 = NULL,
    @AllocationType NVARCHAR(10) = 'Room', -- 'Room' or 'User'
    @RoomId INT = NULL,
    @UserId INT = NULL,
    @AssetId INT = NULL,
    @Building NVARCHAR(100) = NULL,
    @Floor NVARCHAR(50) = NULL
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

    IF OBJECT_ID('DropDown.DD_Users', 'P') IS NOT NULL
    BEGIN
        BEGIN TRY
            CREATE TABLE #DropdownUsers
            (
                value INT NULL,
                text NVARCHAR(4000) NULL
            );

            INSERT INTO #DropdownUsers (value, text)
            EXEC [DropDown].[DD_Users];

            INSERT INTO #UserLookup (Id, Name, Email, UserName, Department, Designation, IsActive)
            SELECT
                du.value,
                du.text,
                NULL,
                NULL,
                NULL,
                NULL,
                CAST(1 AS BIT)
            FROM
            (
                SELECT
                    value,
                    MAX(NULLIF(LTRIM(RTRIM(text)), '')) AS text
                FROM #DropdownUsers
                WHERE value IS NOT NULL
                GROUP BY value
            ) du
            WHERE du.text IS NOT NULL;
        END TRY
        BEGIN CATCH
            -- DropDown.DD_Users signature can vary across HMS deployments (e.g. requires @UserTypeId).
            -- Fall back to dbo.Users below instead of failing the whole procedure.
        END CATCH
    END
    IF COL_LENGTH('dbo.Users', 'UserID') IS NOT NULL
    BEGIN
        INSERT INTO #UserLookup (Id, Name, Email, UserName, Department, Designation, IsActive)
        EXEC sp_executesql N'
            SELECT
                raw.UserID,
                COALESCE(NULLIF(LTRIM(RTRIM(raw.UserName)), ''''), CONCAT(''User '', CAST(raw.UserID AS NVARCHAR(20)))),
                NULL,
                raw.UserName,
                NULL,
                NULL,
                CAST(CASE WHEN ISNULL(raw.Status, 1) = 1 THEN 1 ELSE 0 END AS BIT)
            FROM dbo.Users raw
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
                CAST(ISNULL(raw.IsActive, 1) AS BIT)
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
        aa.Id,
        aa.AllocatedDate,
        NULL AS ReturnDate,
        aa.Quantity,
        aa.Notes AS Remarks,
        CAST(0 AS BIT) AS IsReturn,
        NULL AS ReturnRemarks,
        -- Asset/Item Information
        i.Id as AssetId,
        COALESCE(i.Name, CONCAT('Item ', CAST(aa.ItemId AS NVARCHAR(20)))) as AssetName,
        aa.SerialNumber,
        NULL AS Model,
        NULL AS UnitPrice,
        NULL AS TotalPrice,
        -- User Information
        aa.UserId as UserId,
        COALESCE(u.Name, CONCAT('User ', CAST(aa.UserId AS NVARCHAR(20)))) as UserName,
        u.Email as UserEmail,
        u.Department as UserDepartment,
        u.Designation as UserDesignation,
        -- Room Information
        r.Id as RoomId,
        r.Name as RoomName,
        r.Building,
        r.Floor,
        r.Description as RoomDescription,
        -- Department Information
        d.Id as DepartmentId,
        d.Name as DepartmentName,
        sd.Id as SubDepartmentId,
        sd.Name as SubDepartmentName,
        -- Branch Information
        b.Id as BranchId,
        b.Name as BranchName,
        -- Additional Item Details
        br.Name as BrandName,
        it.Name as ItemTypeName,
        NULL as ManufacturerName,
        -- Allocation Number
        aa.AllocationNumber AS AllocationNo
    FROM dbo.AssetAllocations aa
    LEFT JOIN #UserLookup u ON aa.UserId = u.Id
    LEFT JOIN dbo.Rooms r ON aa.RoomId = r.Id
    LEFT JOIN dbo.Departments d ON aa.DepartmentId = d.Id
    LEFT JOIN dbo.SubDepartments sd ON aa.SubDepartmentId = sd.Id
    LEFT JOIN dbo.Branches b ON aa.BranchId = b.Id
    LEFT JOIN dbo.Items i ON aa.ItemId = i.Id
    LEFT JOIN dbo.Brands br ON i.BrandId = br.Id
    LEFT JOIN dbo.ItemTypes it ON i.ItemTypeId = it.Id
    WHERE aa.IsActive = 1 
        AND (@StartDate IS NULL OR aa.AllocatedDate >= @StartDate)
        AND (@EndDate IS NULL OR aa.AllocatedDate <= @EndDate)
        AND (
            (@AllocationType = 'Room' AND aa.RoomId IS NOT NULL AND (@RoomId IS NULL OR aa.RoomId = @RoomId))
            OR 
            (@AllocationType = 'User' AND aa.UserId IS NOT NULL AND (@UserId IS NULL OR aa.UserId = @UserId))
        )
        AND (@AssetId IS NULL OR aa.ItemId = @AssetId)
        AND (@Building IS NULL OR r.Building = @Building)
        AND (@Floor IS NULL OR r.Floor = @Floor)
    ORDER BY aa.AllocatedDate DESC, aa.Id DESC;
END
GO