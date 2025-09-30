-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Get asset allocation by ID with related data
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'AssetAllocation_GetById')
    DROP PROCEDURE [dbo].[AssetAllocation_GetById]
GO

CREATE PROCEDURE [dbo].[AssetAllocation_GetById]
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        aa.Id,
        aa.Remarks,
        aa.AllocatedDate,
        aa.ReturnDate,
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
        aa.IsReturn,
        aa.ReturnRemarks,
        aa.Quantity,
        aa.InventoryItemId,
        ii.Name as InventoryItemName,
        ii.SerialNumber,
        ii.Model,
        ii.Status as ItemStatus,
        ii.PurchasePrice,
        ii.CurrentValue,
        aa.SysBatchNo,
        aa.BatchNo,
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
    LEFT JOIN dbo.InventoryItems ii ON aa.InventoryItemId = ii.Id
    WHERE aa.Id = @Id AND aa.IsActive = 1 AND aa.IsDeleted = 0;
END