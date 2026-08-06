-- Stored Procedure: SaleSummaryDaily_GetReport
-- Description: Retrieves sale summary data grouped by date (daily/monthly/yearly)
-- Note: Returns sample/empty data. Modify when actual Sales table is created.

CREATE OR ALTER PROCEDURE SaleSummaryDaily_GetReport
    @Store NVARCHAR(255) = NULL,
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL,
    @Type NVARCHAR(50) = 'Daily' -- Daily, Monthly, Yearly
AS
BEGIN
    SET NOCOUNT ON;

    -- Default date range to current day if not provided
    IF @StartDate IS NULL
        SET @StartDate = CAST(GETDATE() AS DATE);
    
    IF @EndDate IS NULL
        SET @EndDate = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));

    -- Return empty result set with correct structure
    -- This will be replaced when actual Sales table exists
    SELECT 
        CAST(GETDATE() AS DATE) AS Date,
        0 AS [Count],
        CAST(0.00 AS DECIMAL(18,2)) AS GrossSales,
        CAST(0.00 AS DECIMAL(18,2)) AS Discounts,
        CAST(0.00 AS DECIMAL(18,2)) AS TotalSReturn,
        CAST(0.00 AS DECIMAL(18,2)) AS CostOfSales
    WHERE 1 = 0; -- Returns no rows, just structure
END
GO
