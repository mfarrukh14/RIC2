-- Stored procedure to get stock value items report
CREATE OR ALTER PROCEDURE StockValueItems_GetReport
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL,
    @Store NVARCHAR(255) = NULL,
    @ItemType NVARCHAR(255) = NULL,
    @SearchTerm NVARCHAR(255) = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (CASE WHEN @PageNumber < 1 THEN 0 ELSE @PageNumber - 1 END) * (CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END);
    DECLARE @Take INT = CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END;

    -- LEFT JOIN Inv.Items, not INNER - gi.ItemId is NULL for ~86% of eligible rows
    -- (Medicine/Fee-sourced GRN lines, same ratio documented in
    -- MigratePurchaseSummary_iHealthCure_HMSMAIN_TF.sql's header) - the INNER JOIN
    -- was silently dropping those rows entirely (42455 eligible -> only 5724 ever
    -- shown). Name resolved via DenormalizedItemName the same way GRNItems already
    -- falls back to elsewhere in this schema (see Stock_Procedures.sql's fallback
    -- OUTER APPLY for the same column).
    ;WITH Filtered AS (
        SELECT
            COALESCE(s.StoreName, 'Unassigned Store') AS StoreName,
            COALESCE(i.Name, gi.DenormalizedItemName, '(item not found)') AS Name,
            gi.BatchNo AS BatchNo,
            SUM(COALESCE(gi.RemainingQuantity, gi.TotalItem, 0)) AS TotalItems,
            CAST(AVG(CAST(COALESCE(gi.UnitBuyingPrice, 0) AS DECIMAL(18, 2))) AS DECIMAL(18, 2)) AS UnitPurchaseRate,
            SUM(COALESCE(gi.TotalBuyingPrice, 0)) AS TotalPurchaseRate,
            CAST(AVG(CAST(COALESCE(gi.UnitSellingPrice, 0) AS DECIMAL(18, 2))) AS DECIMAL(18, 2)) AS UnitSaleRate,
            SUM(COALESCE(gi.TotalSellingPrice, 0)) AS TotalSaleRate
        FROM
            Inv.GRNItems gi
        LEFT JOIN
            Inv.Items i ON gi.ItemId = i.Id
        INNER JOIN
            Inv.GoodsReceivingNotes grn ON gi.GRNId = grn.Id
        LEFT JOIN
            Inv.PurchaseOrders po ON grn.PurchaseOrderId = po.PurchaseOrderId
        LEFT JOIN
            Inv.PharmacyStores s ON po.StoreId = s.StoreId
        LEFT JOIN
            Inv.ItemTypes it ON i.ItemTypeId = it.Id
        WHERE
            grn.IsActive = 1
            AND (@StartDate IS NULL OR grn.DateAndTime >= @StartDate)
            AND (@EndDate IS NULL OR grn.DateAndTime <= @EndDate)
            AND (@Store IS NULL OR s.StoreName = @Store)
            AND (@ItemType IS NULL OR it.Name = @ItemType)
            AND gi.BatchNo IS NOT NULL
        GROUP BY
            COALESCE(s.StoreName, 'Unassigned Store'), COALESCE(i.Name, gi.DenormalizedItemName, '(item not found)'), gi.BatchNo
    )
    SELECT *, COUNT(*) OVER() AS TotalCount
    FROM Filtered
    WHERE @SearchTerm IS NULL OR Name LIKE '%' + @SearchTerm + '%' OR BatchNo LIKE '%' + @SearchTerm + '%' OR StoreName LIKE '%' + @SearchTerm + '%'
    ORDER BY StoreName, Name, BatchNo
    OFFSET @Offset ROWS FETCH NEXT @Take ROWS ONLY;
END;
GO
