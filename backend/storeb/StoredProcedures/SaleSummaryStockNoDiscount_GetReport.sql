-- Stored Procedure: SaleSummaryStockNoDiscount_GetReport
-- Description: Retrieves sale summary by stock without discount information
-- Note: Returns sample/empty data. Modify when actual Sales table is created.

CREATE OR ALTER PROCEDURE SaleSummaryStockNoDiscount_GetReport
    @Store NVARCHAR(255) = NULL,
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL
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
        CAST('' AS NVARCHAR(255)) AS Name,
        CAST(0.00 AS DECIMAL(18,2)) AS UnitPurchaseRate,
        CAST(0.00 AS DECIMAL(18,2)) AS UnitSaleRate,
        CAST(0.00 AS DECIMAL(18,2)) AS Quantity
    WHERE 1 = 0; -- Returns no rows, just structure
END
GO
