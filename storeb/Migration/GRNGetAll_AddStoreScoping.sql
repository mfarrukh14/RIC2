-- Adds store-scoped access control to GRN_GetAll. Store resolution mirrors
-- PurchaseSummary_GetAll/PurchaseSummaryInvoice_GetAll's ISNULL(po.StoreId,
-- g.StoreId) - Inv.GoodsReceivingNotes' own StoreId column is the direct link
-- (added for GRNs with no Purchase Order attached), falling back to the
-- linked PurchaseOrder's StoreId when there is one.
CREATE OR ALTER PROCEDURE [dbo].[GRN_GetAll]
    @PageNumber INT = 1,
    @PageSize INT = 5,
    @Search NVARCHAR(200) = NULL,
    @IsAdmin BIT = 0,
    @AllowedStoreIds NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (CASE WHEN @PageNumber < 1 THEN 0 ELSE @PageNumber - 1 END) * (CASE WHEN @PageSize < 1 THEN 5 ELSE @PageSize END);
    DECLARE @Take INT = CASE WHEN @PageSize < 1 THEN 5 ELSE @PageSize END;
    DECLARE @SearchTrimmed NVARCHAR(200) = NULLIF(LTRIM(RTRIM(@Search)), '');
    DECLARE @AllowedStoreIdTable TABLE (StoreId INT);

    IF @IsAdmin = 0 AND @AllowedStoreIds IS NOT NULL AND LTRIM(RTRIM(@AllowedStoreIds)) <> ''
    BEGIN
        INSERT INTO @AllowedStoreIdTable (StoreId)
        SELECT TRY_CAST(value AS INT)
        FROM STRING_SPLIT(@AllowedStoreIds, ',')
        WHERE TRY_CAST(value AS INT) IS NOT NULL;
    END

    SELECT
        g.Id,
        g.PurchaseOrderId,
        g.PONumber,
        g.InvoiceNo,
        g.StockTypeId,
        st.Name as StockTypeName,
        g.VendorId,
        COALESCE(v.Name, g.DenormalizedVendorName) as VendorName,
        g.DateAndTime,
        g.IsActive,
        g.CreatedOn,
        COUNT(*) OVER() AS TotalCount
    FROM Inv.GoodsReceivingNotes g
    LEFT JOIN Inv.PurchaseOrders po ON g.PurchaseOrderId = po.PurchaseOrderId
    LEFT JOIN Inv.Vendors v ON g.VendorId = v.Id
    LEFT JOIN Inv.StockTypes st ON g.StockTypeId = st.Id
    WHERE g.IsActive = 1
        AND (@IsAdmin = 1 OR ISNULL(po.StoreId, g.StoreId) IN (SELECT StoreId FROM @AllowedStoreIdTable))
        AND (
            @SearchTrimmed IS NULL
            OR ISNULL(g.InvoiceNo, '') LIKE '%' + @SearchTrimmed + '%'
            OR ISNULL(g.PONumber, '') LIKE '%' + @SearchTrimmed + '%'
            OR ISNULL(st.Name, '') LIKE '%' + @SearchTrimmed + '%'
            OR ISNULL(COALESCE(v.Name, g.DenormalizedVendorName), '') LIKE '%' + @SearchTrimmed + '%'
        )
    ORDER BY g.CreatedOn DESC, g.Id DESC
    OFFSET @Offset ROWS FETCH NEXT @Take ROWS ONLY;
END
