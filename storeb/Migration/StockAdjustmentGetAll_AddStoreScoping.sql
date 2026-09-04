-- Adds store-scoped access control to StockAdjustment_GetAll - same pattern
-- as StockSearch_AddStoreScoping.sql, see that file's header for the full
-- rationale (BaseController.IsAdmin/AllowedStoreIds from Inv.StoreAllocationToUser).
CREATE OR ALTER PROCEDURE StockAdjustment_GetAll
    @BranchId INT = NULL,
    @StoreId INT = NULL,
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL,
    @SearchTerm NVARCHAR(200) = NULL,
    @IsAdmin BIT = 0,
    @AllowedStoreIds NVARCHAR(MAX) = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (CASE WHEN @PageNumber < 1 THEN 0 ELSE @PageNumber - 1 END) * (CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END);
    DECLARE @Take INT = CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END;
    DECLARE @AllowedStoreIdTable TABLE (StoreId INT);

    IF @IsAdmin = 0 AND @AllowedStoreIds IS NOT NULL AND LTRIM(RTRIM(@AllowedStoreIds)) <> ''
    BEGIN
        INSERT INTO @AllowedStoreIdTable (StoreId)
        SELECT TRY_CAST(value AS INT)
        FROM STRING_SPLIT(@AllowedStoreIds, ',')
        WHERE TRY_CAST(value AS INT) IS NOT NULL;
    END

    ;WITH FilteredHeaders AS (
        SELECT
            sa.Id,
            s.StoreName,
            ISNULL(e.FullName, (e.FirstName + ' ' + e.LastName)) AS ActionBy,
            sa.CreatedOn AS ActionOn
        FROM Inv.StockAdjustments sa
        LEFT JOIN Inv.PharmacyStores s ON sa.StoreId = s.StoreId
        LEFT JOIN dbo.Users u ON sa.CreatedById = u.UserID
        LEFT JOIN dbo.Employee e ON e.EmpID = u.EmpID
        WHERE sa.IsDeleted = 0
            AND (@BranchId IS NULL OR sa.BranchId = @BranchId)
            AND (@StoreId IS NULL OR sa.StoreId = @StoreId)
            AND (@IsAdmin = 1 OR sa.StoreId IN (SELECT StoreId FROM @AllowedStoreIdTable))
            AND (@StartDate IS NULL OR sa.CreatedOn >= @StartDate)
            AND (@EndDate IS NULL OR sa.CreatedOn <= @EndDate)
            AND (
                @SearchTerm IS NULL OR @SearchTerm = ''
                OR s.StoreName LIKE '%' + @SearchTerm + '%'
                OR e.FullName LIKE '%' + @SearchTerm + '%'
            )
    ),
    Paged AS (
        SELECT *, COUNT(*) OVER() AS TotalCount
        FROM FilteredHeaders
        ORDER BY ActionOn DESC
        OFFSET @Offset ROWS FETCH NEXT @Take ROWS ONLY
    )
    SELECT
        Paged.Id,
        Paged.StoreName,
        agg.ItemNames,
        agg.StockType,
        Paged.ActionBy,
        Paged.ActionOn,
        ISNULL(agg.TotalQuantity, 0) AS TotalQuantity,
        ISNULL(agg.TotalPurchaseValue, 0) AS TotalPurchaseValue,
        ISNULL(agg.TotalSaleValue, 0) AS TotalSaleValue,
        Paged.TotalCount
    FROM Paged
    OUTER APPLY (
        SELECT
            STRING_AGG(COALESCE(i.Name, m.MedicineFullName, f.Name), ', ') AS ItemNames,
            (
                SELECT TOP 1 st2.Name
                FROM Inv.StockAdjustmentDetails d2
                LEFT JOIN Inv.StockTypes st2 ON d2.StockTypeId = st2.Id
                WHERE d2.StockAdjustmentId = Paged.Id AND d2.IsDeleted = 0
            ) AS StockType,
            SUM(d.Quantity) AS TotalQuantity,
            SUM(ISNULL(d.PurchaseValue, 0)) AS TotalPurchaseValue,
            SUM(ISNULL(d.SaleValue, 0)) AS TotalSaleValue
        FROM Inv.StockAdjustmentDetails d
        LEFT JOIN Inv.Items i ON d.ItemId = i.Id
        LEFT JOIN Pharmacy.Medicines m ON d.MedicineId = m.MedicineId
        LEFT JOIN Account.Fees f ON d.SubServiceId = f.Id
        WHERE d.StockAdjustmentId = Paged.Id AND d.IsDeleted = 0
    ) agg
    ORDER BY Paged.ActionOn DESC;
END
