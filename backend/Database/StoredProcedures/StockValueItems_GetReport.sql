-- Stored procedure to get stock value items report
CREATE PROCEDURE StockValueItems_GetReport
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL,
    @Store NVARCHAR(255) = NULL,
    @ItemType NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        s.StoreName AS StoreName,
        i.Name AS Name,
        gi.BatchNo AS BatchNo,
        SUM(gi.TotalItem) AS TotalItems,
        AVG(gi.UnitBuyingPrice) AS UnitPurchaseRate,
        SUM(gi.TotalBuyingPrice) AS TotalPurchaseRate,
        AVG(gi.UnitSellingPrice) AS UnitSaleRate,
        SUM(gi.TotalSellingPrice) AS TotalSaleRate
    FROM 
        GRNItems gi
    INNER JOIN 
        Items i ON gi.ItemId = i.Id
    INNER JOIN 
        GoodsReceivingNotes grn ON gi.GRNId = grn.Id
    LEFT JOIN 
        Stores s ON grn.StockTypeId = s.StoreId
    WHERE 
        (@StartDate IS NULL OR grn.DateAndTime >= @StartDate)
        AND (@EndDate IS NULL OR grn.DateAndTime <= @EndDate)
        AND (@Store IS NULL OR s.StoreName = @Store)
        AND gi.BatchNo IS NOT NULL
    GROUP BY 
        s.StoreName, i.Name, gi.BatchNo
    ORDER BY 
        s.StoreName, i.Name, gi.BatchNo;
END;
GO
