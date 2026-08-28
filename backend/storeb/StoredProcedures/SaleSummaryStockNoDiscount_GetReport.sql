-- Stored Procedure: SaleSummaryStockNoDiscount_GetReport
-- Description: Item-wise sale summary (no discount breakdown), grouped by item.
--
-- Previously a permanent stub ("WHERE 1=0 -- Returns no rows, just structure" - never
-- wired to a real table). The real, live sale/dispense record is
-- Pharmacy.PharmacyChallanForms/PharmacyChallanFormDetails - the same pair
-- PharmacyService.GetItemWiseSaleAsync already reads successfully for the working "Item
-- Wise Sale" page (ChallanTypes 'Final' = completed sale, 'Refund' = return; both included,
-- matching that precedent). UnitPurchaseRate comes straight off
-- d.ItemUnitBuyingPrice (captured per line at sale time); UnitSaleRate is Total/Quantity.
CREATE OR ALTER PROCEDURE SaleSummaryStockNoDiscount_GetReport
    @Store NVARCHAR(255) = NULL,
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        COALESCE(m.MedicineFullName, ii.Name, 'Unassigned') AS Name,
        CASE WHEN SUM(d.Quantity) <> 0 THEN SUM(d.ItemUnitBuyingPrice * d.Quantity) / SUM(d.Quantity) ELSE 0 END AS UnitPurchaseRate,
        CASE WHEN SUM(d.Quantity) <> 0 THEN SUM(d.Total) / SUM(d.Quantity) ELSE 0 END AS UnitSaleRate,
        SUM(d.Quantity) AS Quantity
    FROM Pharmacy.PharmacyChallanFormDetails d
    INNER JOIN Pharmacy.PharmacyChallanForms f ON f.Id = d.PharmacyChallanFormsId
    LEFT JOIN Account.ChallanTypes ct ON ct.Id = f.ChallanTypeId
    LEFT JOIN Inv.PharmacyStores s ON s.StoreId = f.StoreId
    LEFT JOIN Pharmacy.Medicines m ON m.MedicineId = d.MedicineId
    LEFT JOIN Inv.Items ii ON ii.Id = d.ItemId
    WHERE ct.Name IN ('Final', 'Refund') AND d.Quantity > 0
      AND (@Store IS NULL OR @Store = '' OR s.StoreName = @Store)
      AND (@StartDate IS NULL OR f.Timestamp >= @StartDate)
      AND (@EndDate IS NULL OR f.Timestamp < DATEADD(DAY, 1, @EndDate))
    GROUP BY COALESCE(m.MedicineFullName, ii.Name, 'Unassigned')
    ORDER BY Name;
END
GO
