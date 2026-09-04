-- Stored Procedure: SaleSummaryDaily_GetReport
-- Description: Sale summary grouped by date/month/year.
--
-- Previously a permanent stub ("WHERE 1=0" - never wired to a real table). Same live
-- source as SaleSummaryStockNoDiscount_GetReport (see its header comment for why):
-- Pharmacy.PharmacyChallanForms/PharmacyChallanFormDetails. 'Final' challans are completed
-- sales (GrossSales/Discounts/CostOfSales/Count); 'Refund' challans are returns
-- (TotalSReturn) - SaleSummaryDailyService already nets TotalSales = GrossSales - Discounts
-- and NetSale = TotalSales - TotalSReturn client-side, so this proc only needs to supply
-- the raw per-bucket components.
CREATE OR ALTER PROCEDURE SaleSummaryDaily_GetReport
    @Store NVARCHAR(255) = NULL,
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL,
    @Type NVARCHAR(50) = 'Daily', -- Daily, Monthly, Yearly
    @PageNumber INT = 1,
    @PageSize INT = 2147483647 -- default "unpaged" so the internal summary-totals fetch can reuse this proc unchanged
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (CASE WHEN @PageNumber < 1 THEN 0 ELSE @PageNumber - 1 END) * (CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END);
    DECLARE @Take INT = CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END;

    ;WITH Base AS (
        SELECT
            f.Id AS FormId,
            CASE @Type
                WHEN 'Monthly' THEN DATEFROMPARTS(YEAR(f.Timestamp), MONTH(f.Timestamp), 1)
                WHEN 'Yearly' THEN DATEFROMPARTS(YEAR(f.Timestamp), 1, 1)
                ELSE CAST(f.Timestamp AS DATE)
            END AS BucketDate,
            ct.Name AS ChallanTypeName,
            d.Total,
            d.Quantity,
            d.ItemUnitBuyingPrice,
            ISNULL(d.SubDepartmentDiscount, 0) + ISNULL(d.DepartmentDiscount, 0)
                + ISNULL(d.IndividualPackageDiscount, 0) + ISNULL(d.PatientCategoryDiscount, 0)
                + ISNULL(d.PanelPackageDiscount, 0) AS LineDiscount
        FROM Pharmacy.PharmacyChallanFormDetails d
        INNER JOIN Pharmacy.PharmacyChallanForms f ON f.Id = d.PharmacyChallanFormsId
        LEFT JOIN Account.ChallanTypes ct ON ct.Id = f.ChallanTypeId
        LEFT JOIN Inv.PharmacyStores s ON s.StoreId = f.StoreId
        WHERE ct.Name IN ('Final', 'Refund') AND d.Quantity > 0
          AND (@Store IS NULL OR @Store = '' OR s.StoreName = @Store)
          AND (@StartDate IS NULL OR f.Timestamp >= @StartDate)
          AND (@EndDate IS NULL OR f.Timestamp < DATEADD(DAY, 1, @EndDate))
    ),
    Bucketed AS (
        SELECT
            BucketDate AS Date,
            COUNT(DISTINCT CASE WHEN ChallanTypeName = 'Final' THEN FormId END) AS [Count],
            SUM(CASE WHEN ChallanTypeName = 'Final' THEN Total ELSE 0 END) AS GrossSales,
            SUM(CASE WHEN ChallanTypeName = 'Final' THEN LineDiscount ELSE 0 END) AS Discounts,
            SUM(CASE WHEN ChallanTypeName = 'Refund' THEN Total ELSE 0 END) AS TotalSReturn,
            SUM(CASE WHEN ChallanTypeName = 'Final' THEN ItemUnitBuyingPrice * Quantity ELSE 0 END) AS CostOfSales
        FROM Base
        GROUP BY BucketDate
    )
    SELECT
        Date,
        [Count],
        GrossSales,
        Discounts,
        TotalSReturn,
        CostOfSales,
        COUNT(*) OVER() AS TotalCount
    FROM Bucketed
    ORDER BY Date DESC
    OFFSET @Offset ROWS FETCH NEXT @Take ROWS ONLY;
END
GO
