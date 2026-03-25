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
        ii.Name,
        ii.Description,
        ii.SerialNumber,
        ii.Model,
        ii.BrandId,
        b.Name as BrandName,
        ii.ItemTypeId,
        it.Name as ItemTypeName,
        ii.ItemUnitId,
        iu.Name as ItemUnitName,
        ii.ManufacturerId,
        m.Name as ManufacturerName,
        ii.PurchaseDate,
        ii.PurchasePrice,
        ii.CurrentValue,
        ii.Condition,
        ii.Status,
        ii.BranchId,
        br.Name as BranchName,
        ii.IsActive
    FROM dbo.InventoryItems ii
    LEFT JOIN dbo.Brands b ON ii.BrandId = b.Id
    LEFT JOIN dbo.ItemTypes it ON ii.ItemTypeId = it.Id
    LEFT JOIN dbo.ItemUnits iu ON ii.ItemUnitId = iu.Id
    LEFT JOIN dbo.Manufacturers m ON ii.ManufacturerId = m.Id
    LEFT JOIN dbo.Branches br ON ii.BranchId = br.Id
    WHERE ii.IsActive = 1 AND ii.Status IN ('Available', 'Good')
    ORDER BY ii.Name;
END