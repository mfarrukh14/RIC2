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

    -- Note: DropDown.DD_Users is intentionally not used here. It requires mandatory
    -- @UserTypeId/@BranchId/@OrganizationId parameters we have no generic value for,
    -- and Microsoft.Data.SqlClient surfaces its parameter error as a SqlException even
    -- when caught by TRY/CATCH in T-SQL. dbo.Users below is sufficient on its own.
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
        bld.Name as Building,
        flr.Name as Floor,
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
    FROM Inv.AssetAllocations aa
    LEFT JOIN #UserLookup u ON aa.UserId = u.Id
    LEFT JOIN Inv.Rooms r ON aa.RoomId = r.Id
    LEFT JOIN dbo.Rooms dr ON aa.RoomId = dr.RID
    LEFT JOIN dbo.Building bld ON dr.BID = bld.BID
    LEFT JOIN dbo.Floors flr ON dr.FID = flr.FID
    LEFT JOIN Inv.Departments d ON aa.DepartmentId = d.Id
    LEFT JOIN Inv.SubDepartments sd ON aa.SubDepartmentId = sd.Id
    LEFT JOIN Inv.Branches b ON aa.BranchId = b.Id
    LEFT JOIN Inv.Items i ON aa.ItemId = i.Id
    LEFT JOIN Data.Brands br ON i.BrandId = br.Id
    LEFT JOIN Inv.ItemTypes it ON i.ItemTypeId = it.Id
    WHERE aa.IsActive = 1 
        AND (@StartDate IS NULL OR aa.AllocatedDate >= @StartDate)
        AND (@EndDate IS NULL OR aa.AllocatedDate <= @EndDate)
        AND (
            (@AllocationType = 'Room' AND aa.RoomId IS NOT NULL AND (@RoomId IS NULL OR aa.RoomId = @RoomId))
            OR 
            (@AllocationType = 'User' AND aa.UserId IS NOT NULL AND (@UserId IS NULL OR aa.UserId = @UserId))
        )
        AND (@AssetId IS NULL OR aa.ItemId = @AssetId)
        AND (@Building IS NULL OR bld.Name = @Building)
        AND (@Floor IS NULL OR flr.Name = @Floor)
    ORDER BY aa.AllocatedDate DESC, aa.Id DESC;
END
GO