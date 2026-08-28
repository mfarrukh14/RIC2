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
        COALESCE(s.StoreName, 'Unassigned Store') AS StoreName,
        i.Name AS Name,
        gi.BatchNo AS BatchNo,
        SUM(COALESCE(gi.RemainingQuantity, gi.TotalItem, 0)) AS TotalItems,
        CAST(AVG(CAST(COALESCE(gi.UnitBuyingPrice, 0) AS DECIMAL(18, 2))) AS DECIMAL(18, 2)) AS UnitPurchaseRate,
        SUM(COALESCE(gi.TotalBuyingPrice, 0)) AS TotalPurchaseRate,
        CAST(AVG(CAST(COALESCE(gi.UnitSellingPrice, 0) AS DECIMAL(18, 2))) AS DECIMAL(18, 2)) AS UnitSaleRate,
        SUM(COALESCE(gi.TotalSellingPrice, 0)) AS TotalSaleRate
    FROM 
        Inv.GRNItems gi
    INNER JOIN 
        Inv.Items i ON gi.ItemId = i.Id
    INNER JOIN 
        Inv.GoodsReceivingNotes grn ON gi.GRNId = grn.Id
    LEFT JOIN
        dbo.PurchaseOrders po ON grn.PurchaseOrderId = po.PurchaseOrderId
    LEFT JOIN 
        Inv.Stores s ON po.StoreId = s.StoreId
    LEFT JOIN
        Inv.ItemTypes it ON i.ItemTypeId = it.Id
    WHERE 
        (@StartDate IS NULL OR grn.DateAndTime >= @StartDate)
        AND (@EndDate IS NULL OR grn.DateAndTime <= @EndDate)
        AND (@Store IS NULL OR s.StoreName = @Store)
        AND (@ItemType IS NULL OR it.Name = @ItemType)
        AND gi.BatchNo IS NOT NULL
    GROUP BY 
        COALESCE(s.StoreName, 'Unassigned Store'), i.Name, gi.BatchNo
    ORDER BY 
        COALESCE(s.StoreName, 'Unassigned Store'), i.Name, gi.BatchNo;
END;
GO
