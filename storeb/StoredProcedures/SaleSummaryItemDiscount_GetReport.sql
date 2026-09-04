-- Stored Procedure: SaleSummaryItemDiscount_GetReport
-- Description: Item-wise sale summary including discount amount, grouped by item.
--
-- Previously a permanent stub ("WHERE 1=0" - never wired to a real table). Same live
-- source as SaleSummaryStockNoDiscount_GetReport (see its header comment for why):
-- Pharmacy.PharmacyChallanForms/PharmacyChallanFormDetails. DiscountAmount sums every
-- discount bucket the challan detail line can carry (department/sub-department,
-- individual-package, patient-category, panel-package) - a sale can only ever have been
-- discounted through one of these paths at a time, so summing is safe and mirrors what
-- Total already nets against.
CREATE OR ALTER PROCEDURE SaleSummaryItemDiscount_GetReport
    @Store NVARCHAR(255) = NULL,
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL,
    @Item NVARCHAR(255) = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (CASE WHEN @PageNumber < 1 THEN 0 ELSE @PageNumber - 1 END) * (CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END);
    DECLARE @Take INT = CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END;

    ;WITH Summary AS (
        SELECT
            COALESCE(m.MedicineFullName, ii.Name, 'Unassigned') AS Name,
            CASE WHEN SUM(d.Quantity) <> 0 THEN SUM(d.ItemUnitBuyingPrice * d.Quantity) / SUM(d.Quantity) ELSE 0 END AS UnitPurchaseRate,
            CASE WHEN SUM(d.Quantity) <> 0 THEN SUM(d.Total) / SUM(d.Quantity) ELSE 0 END AS UnitSaleRate,
            SUM(d.Quantity) AS Quantity,
            SUM(ISNULL(d.SubDepartmentDiscount, 0) + ISNULL(d.DepartmentDiscount, 0)
                + ISNULL(d.IndividualPackageDiscount, 0) + ISNULL(d.PatientCategoryDiscount, 0)
                + ISNULL(d.PanelPackageDiscount, 0)) AS DiscountAmount
        FROM Pharmacy.PharmacyChallanFormDetails d
        INNER JOIN Pharmacy.PharmacyChallanForms f ON f.Id = d.PharmacyChallanFormsId
        LEFT JOIN Account.ChallanTypes ct ON ct.Id = f.ChallanTypeId
        LEFT JOIN Inv.PharmacyStores s ON s.StoreId = f.StoreId
        LEFT JOIN Pharmacy.Medicines m ON m.MedicineId = d.MedicineId
        LEFT JOIN Inv.Items ii ON ii.Id = d.ItemId
        WHERE ct.Name IN ('Final', 'Refund') AND d.Quantity > 0
          AND (@Store IS NULL OR @Store = '' OR s.StoreName = @Store)
          AND (@Item IS NULL OR @Item = '' OR COALESCE(m.MedicineFullName, ii.Name, 'Unassigned') = @Item)
          AND (@StartDate IS NULL OR f.Timestamp >= @StartDate)
          AND (@EndDate IS NULL OR f.Timestamp < DATEADD(DAY, 1, @EndDate))
        GROUP BY COALESCE(m.MedicineFullName, ii.Name, 'Unassigned')
    )
    SELECT
        Name,
        UnitPurchaseRate,
        UnitSaleRate,
        Quantity,
        DiscountAmount,
        COUNT(*) OVER() AS TotalCount
    FROM Summary
    ORDER BY Name
    OFFSET @Offset ROWS FETCH NEXT @Take ROWS ONLY;
END
GO
