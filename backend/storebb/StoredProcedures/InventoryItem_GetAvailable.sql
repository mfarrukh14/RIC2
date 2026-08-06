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

    -- Base list is every active catalog item, not just items that happen to have a
    -- received stock lot - items added but never yet stocked must still be selectable.
    -- The most recent qualifying stock lot (if any) is used only to enrich the display
    -- (serial number, manufacturer, branch); its absence must not hide the item.
    SELECT
        i.Id,
        i.Name,
        i.Description,
        stock.SerialNumber,
        i.Model,
        i.BrandId,
        b.Name as BrandName,
        i.ItemTypeId,
        it.Name as ItemTypeName,
        i.UnitId AS ItemUnitId,
        iu.Name as ItemUnitName,
        stock.ManufacturerId,
        m.Name as ManufacturerName,
        stock.PurchaseDate,
        NULL AS PurchasePrice,
        NULL AS CurrentValue,
        NULL AS Condition,
        NULL AS Status,
        stock.BranchId,
        br.Name as BranchName,
        i.IsActive
    FROM Inv.Items i
    OUTER APPLY (
        SELECT TOP 1 ii.RegistrationNumber AS SerialNumber, ii.ManufacturerId, ii.CreatedOn AS PurchaseDate, ii.BranchId
        FROM Inv.InventoryItems ii
        WHERE ii.ItemId = i.Id AND ii.IsActive = 1 AND ii.BalanceTotalItems > 0
        ORDER BY ii.CreatedOn DESC
    ) stock
    LEFT JOIN Inv.Brands b ON i.BrandId = b.Id
    LEFT JOIN Inv.ItemTypes it ON i.ItemTypeId = it.Id
    LEFT JOIN Inv.ItemUnits iu ON i.UnitId = iu.Id
    LEFT JOIN Inv.Manufacturers m ON stock.ManufacturerId = m.Id
    LEFT JOIN Inv.Branches br ON stock.BranchId = br.Id
    WHERE i.IsActive = 1
    ORDER BY i.Name;
END