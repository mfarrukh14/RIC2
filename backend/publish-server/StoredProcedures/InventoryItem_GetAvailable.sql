-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Get all available inventory items for allocation
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'InventoryItem_GetAvailable')
    DROP PROCEDURE [dbo].[InventoryItem_GetAvailable]
GO

CREATE PROCEDURE [dbo].[InventoryItem_GetAvailable]
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        ii.Id,
        i.Name,
        i.Description,
        ii.RegistrationNumber AS SerialNumber,
        i.Model,
        i.BrandId,
        b.Name as BrandName,
        i.ItemTypeId,
        it.Name as ItemTypeName,
        i.UnitId AS ItemUnitId,
        iu.Name as ItemUnitName,
        ii.ManufacturerId,
        m.Name as ManufacturerName,
        ii.CreatedOn AS PurchaseDate,
        NULL AS PurchasePrice,
        NULL AS CurrentValue,
        NULL AS Condition,
        NULL AS Status,
        ii.BranchId,
        br.Name as BranchName,
        ii.IsActive
    FROM dbo.InventoryItems ii
    INNER JOIN dbo.Items i ON ii.ItemId = i.Id
    LEFT JOIN dbo.Brands b ON i.BrandId = b.Id
    LEFT JOIN dbo.ItemTypes it ON i.ItemTypeId = it.Id
    LEFT JOIN dbo.ItemUnits iu ON i.UnitId = iu.Id
    LEFT JOIN dbo.Manufacturers m ON ii.ManufacturerId = m.Id
    LEFT JOIN dbo.Branches br ON ii.BranchId = br.Id
    WHERE ii.IsActive = 1 AND ii.BalanceTotalItems > 0
    ORDER BY i.Name;
END