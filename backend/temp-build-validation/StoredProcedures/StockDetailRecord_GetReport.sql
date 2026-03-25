-- Stored procedure to get pharmacy stock detail records
CREATE PROCEDURE StockDetailRecord_GetReport
    @Branch NVARCHAR(255) = NULL,
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL,
    @Store NVARCHAR(255) = NULL,
    @Vendor NVARCHAR(255) = NULL,
    @StockType NVARCHAR(255) = NULL,
    @Item NVARCHAR(255) = NULL,
    @ItemType NVARCHAR(255) = NULL,
    @SaleType NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Calculate opening, received, issued, and balance for each item
    WITH StockMovements AS (
        SELECT 
            i.Name,
            st.StockTypeName AS StockType,
            gi.UnitBuyingPrice AS BuyingPrice,
            gi.UnitSellingPrice AS SellingPrice,
            -- Opening: items received before start date
            ISNULL(SUM(CASE WHEN grn.DateAndTime < ISNULL(@StartDate, '1900-01-01') THEN gi.TotalItem ELSE 0 END), 0) AS Opening,
            -- Received: items received within date range
            ISNULL(SUM(CASE WHEN grn.DateAndTime >= ISNULL(@StartDate, '1900-01-01') 
                           AND grn.DateAndTime <= ISNULL(@EndDate, '9999-12-31') THEN gi.TotalItem ELSE 0 END), 0) AS Received,
            -- Issued: for now, we'll calculate as consumption or transfers
            0 AS Issued
        FROM 
            GRNItems gi
        INNER JOIN 
            Items i ON gi.ItemId = i.Id
        INNER JOIN 
            GoodsReceivingNotes grn ON gi.GRNId = grn.Id
        LEFT JOIN 
            StockTypes st ON grn.StockTypeId = st.StockTypeId
        LEFT JOIN 
            Stores s ON grn.StockTypeId = s.StoreId
        LEFT JOIN 
            Vendors v ON grn.VendorId = v.Id
        WHERE 
            (@Store IS NULL OR s.StoreName = @Store)
            AND (@Vendor IS NULL OR v.Name = @Vendor)
            AND (@StockType IS NULL OR st.StockTypeName = @StockType)
            AND (@Item IS NULL OR i.Name LIKE '%' + @Item + '%')
        GROUP BY 
            i.Name, st.StockTypeName, gi.UnitBuyingPrice, gi.UnitSellingPrice
    )
    SELECT 
        Name,
        StockType,
        BuyingPrice,
        SellingPrice,
        Opening,
        Received,
        Issued,
        (Opening + Received - Issued) AS Balance
    FROM 
        StockMovements
    WHERE 
        (Opening + Received - Issued) > 0 OR Received > 0
    ORDER BY 
        Name, StockType;
END;
GO
