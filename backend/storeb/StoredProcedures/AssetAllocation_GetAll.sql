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
    
    SELECT 
        aa.Id,
        aa.Notes AS Remarks,
        aa.AllocatedDate,
        NULL AS ReturnDate,
        aa.UserId,
        u.Name as UserName,
        u.Email as UserEmail,
        u.Department as UserDepartment,
        aa.DepartmentId,
        d.Name as DepartmentName,
        aa.SubDepartmentId,
        sd.Name as SubDepartmentName,
        aa.RoomId,
        r.Name as RoomName,
        r.Building,
        r.Floor,
        aa.ItemId,
        aa.BranchId,
        b.Name as BranchName,
        CAST(0 AS BIT) AS IsReturn,
        NULL AS ReturnRemarks,
        aa.Quantity,
        NULL AS InventoryItemId,
        NULL AS InventoryItemName,
        aa.SerialNumber,
        NULL AS Model,
        NULL AS ItemStatus,
        NULL AS PurchasePrice,
        NULL AS CurrentValue,
        NULL AS SysBatchNo,
        NULL AS BatchNo,
        aa.IsActive,
        aa.CreatedById,
        aa.CreatedOn,
        aa.ModifiedById,
        aa.ModifiedOn
    FROM dbo.AssetAllocations aa
    LEFT JOIN dbo.Users u ON aa.UserId = u.Id
    LEFT JOIN dbo.Departments d ON aa.DepartmentId = d.Id
    LEFT JOIN dbo.SubDepartments sd ON aa.SubDepartmentId = sd.Id
    LEFT JOIN dbo.Rooms r ON aa.RoomId = r.Id
    LEFT JOIN dbo.Branches b ON aa.BranchId = b.Id
    WHERE aa.IsActive = 1
    ORDER BY aa.AllocatedDate DESC;
END