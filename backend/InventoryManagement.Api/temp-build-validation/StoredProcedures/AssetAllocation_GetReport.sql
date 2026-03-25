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
    
    SELECT 
        aa.Id,
        aa.AllocatedDate,
        aa.ReturnDate,
        aa.Quantity,
        aa.Remarks,
        aa.IsReturn,
        aa.ReturnRemarks,
        -- Asset/Inventory Item Information
        ii.Id as AssetId,
        ii.Name as AssetName,
        ii.SerialNumber,
        ii.Model,
        ii.PurchasePrice as UnitPrice,
        (ii.PurchasePrice * aa.Quantity) as TotalPrice,
        -- User Information
        u.Id as UserId,
        u.Name as UserName,
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
        m.Name as ManufacturerName,
        -- Allocation Number (generated)
        CONCAT('ALLOC-', YEAR(aa.AllocatedDate), '-', 
               FORMAT(aa.Id, '0000')) as AllocationNo
    FROM dbo.AssetAllocations aa
    LEFT JOIN dbo.Users u ON aa.UserId = u.Id
    LEFT JOIN dbo.Rooms r ON aa.RoomId = r.Id
    LEFT JOIN dbo.Departments d ON aa.DepartmentId = d.Id
    LEFT JOIN dbo.SubDepartments sd ON aa.SubDepartmentId = sd.Id
    LEFT JOIN dbo.Branches b ON aa.BranchId = b.Id
    LEFT JOIN dbo.InventoryItems ii ON aa.InventoryItemId = ii.Id
    LEFT JOIN dbo.Brands br ON ii.BrandId = br.Id
    LEFT JOIN dbo.ItemTypes it ON ii.ItemTypeId = it.Id
    LEFT JOIN dbo.Manufacturers m ON ii.ManufacturerId = m.Id
    WHERE aa.IsActive = 1 
        AND aa.IsDeleted = 0
        AND (@StartDate IS NULL OR aa.AllocatedDate >= @StartDate)
        AND (@EndDate IS NULL OR aa.AllocatedDate <= @EndDate)
        AND (
            (@AllocationType = 'Room' AND aa.RoomId IS NOT NULL AND (@RoomId IS NULL OR aa.RoomId = @RoomId))
            OR 
            (@AllocationType = 'User' AND aa.UserId IS NOT NULL AND (@UserId IS NULL OR aa.UserId = @UserId))
        )
        AND (@AssetId IS NULL OR aa.InventoryItemId = @AssetId)
        AND (@Building IS NULL OR r.Building = @Building)
        AND (@Floor IS NULL OR r.Floor = @Floor)
    ORDER BY aa.AllocatedDate DESC, aa.Id DESC;
END
GO