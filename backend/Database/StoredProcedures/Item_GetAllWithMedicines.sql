-- =============================================================================
-- Unified Item/Medicine/Disposable lookup for transaction-entry dropdowns
-- (Stock Consumption, Stock Adjustment, GRN, Purchase Order, Purchase
-- Requisition, Demand Request). Mirrors the original iHealthCure system's
-- SP_DispensedMedicineItem_GetItemsMedicineDisposablesForSelect2: on that
-- frontend, items/medicines/disposables are picked from one combined list
-- even though they live in separate tables here too (Inv.Items,
-- Pharmacy.Medicines, Account.Fees filtered to the "Disposable" fee type).
-- Exactly one of ItemId/MedicineId/SubServiceId is populated per row - the
-- caller passes whichever one back when saving a line, same as the three
-- already-nullable ItemId/MedicineId/SubServiceId columns on the detail
-- tables (InventoryItems, StockAdjustmentDetails, StockConsumptionDetails,
-- DemandRequestItems, PurchaseOrderItems, PurchaseRequisitionItems, Stocks).
--
-- Does NOT touch Pharmacy.Medicines/Account.Fees - those are the hospital's
-- own live shared data, read-only from this module's perspective.
-- =============================================================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'Item_GetAllWithMedicines')
    DROP PROCEDURE [dbo].[Item_GetAllWithMedicines]
GO

CREATE PROCEDURE [dbo].[Item_GetAllWithMedicines]
    @Search NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH Combined AS (
        SELECT TOP 100
            i.Id AS ItemId, CAST(NULL AS INT) AS MedicineId, CAST(NULL AS INT) AS SubServiceId,
            'Item' AS SourceType, i.Name, i.BarCode, i.RetailPrice AS Price, i.IsActive
        FROM Inv.Items i
        WHERE i.IsActive = 1
            AND (@Search IS NULL OR i.Name LIKE '%' + @Search + '%' OR i.BarCode = @Search)
        ORDER BY i.Name

        UNION ALL

        SELECT TOP 100
            CAST(NULL AS INT), m.MedicineId, CAST(NULL AS INT),
            'Medicine', m.MedicineFullName, m.BarCode, ISNULL(m.MRP, m.PricePerUnit), m.IsActive
        FROM Pharmacy.Medicines m
        WHERE m.IsActive = 1 AND ISNULL(m.IsDeleted, 0) = 0
            AND (@Search IS NULL OR m.MedicineFullName LIKE '%' + @Search + '%' OR m.BarCode = @Search)
        ORDER BY m.MedicineFullName

        UNION ALL

        SELECT TOP 100
            CAST(NULL AS INT), CAST(NULL AS INT), f.Id,
            'Disposable', f.Name, f.BarCode, p.Total, CAST(CASE WHEN f.IsActive = 1 THEN 1 ELSE 0 END AS BIT)
        FROM Account.Fees f
        JOIN Account.FeeTypes ft ON ft.FeeTypeId = f.FeeTypeId AND ft.Name = 'Disposable'
        LEFT JOIN Data.Prices p ON p.PriceId = f.PriceId
        WHERE f.IsActive = 1 AND ISNULL(f.IsDeleted, 0) = 0
            AND (@Search IS NULL OR f.Name LIKE '%' + @Search + '%' OR f.BarCode = @Search)
        ORDER BY f.Name
    )
    SELECT ItemId, MedicineId, SubServiceId, SourceType, Name, BarCode, Price, IsActive
    FROM Combined
    ORDER BY Name;
END
GO
