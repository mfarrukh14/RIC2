-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Get all asset allocations with related data
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'AssetAllocation_GetAll')
    DROP PROCEDURE [dbo].[AssetAllocation_GetAll]
GO

CREATE PROCEDURE [dbo].[AssetAllocation_GetAll]
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
        aa.Notes AS Remarks,
        aa.AllocatedDate,
        NULL AS ReturnDate,
        aa.UserId,
        COALESCE(u.Name, CONCAT('User ', CAST(aa.UserId AS NVARCHAR(20)))) as UserName,
        u.Email as UserEmail,
        u.Department as UserDepartment,
        aa.DepartmentId,
        d.Name as DepartmentName,
        aa.SubDepartmentId,
        sd.Name as SubDepartmentName,
        aa.RoomId,
        r.Name as RoomName,
        bld.Name as Building,
        flr.Name as Floor,
        aa.ItemId,
        aa.BranchId,
        b.Name as BranchName,
        CAST(0 AS BIT) AS IsReturn,
        NULL AS ReturnRemarks,
        aa.Quantity,
        NULL AS InventoryItemId,
        i.Name AS InventoryItemName,
        aa.SerialNumber,
        NULL AS Model,
        aa.Condition AS ItemStatus,
        NULL AS PurchasePrice,
        NULL AS CurrentValue,
        NULL AS SysBatchNo,
        NULL AS BatchNo,
        aa.IsActive,
        aa.CreatedById,
        aa.CreatedOn,
        aa.ModifiedById,
        aa.ModifiedOn
    FROM Inv.AssetAllocations aa
    LEFT JOIN #UserLookup u ON aa.UserId = u.Id
    LEFT JOIN Inv.Departments d ON aa.DepartmentId = d.Id
    LEFT JOIN Inv.SubDepartments sd ON aa.SubDepartmentId = sd.Id
    LEFT JOIN Inv.Rooms r ON aa.RoomId = r.Id
    LEFT JOIN dbo.Rooms dr ON aa.RoomId = dr.RID
    LEFT JOIN dbo.Building bld ON dr.BID = bld.BID
    LEFT JOIN dbo.Floors flr ON dr.FID = flr.FID
    LEFT JOIN Inv.Branches b ON aa.BranchId = b.Id
    LEFT JOIN Inv.Items i ON aa.ItemId = i.Id
    ORDER BY aa.AllocatedDate DESC, aa.Id DESC;
END