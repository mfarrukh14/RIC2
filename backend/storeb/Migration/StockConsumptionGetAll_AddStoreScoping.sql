-- Adds store-scoped access control to StockConsumption_GetAll - same pattern
-- as StockSearch_AddStoreScoping.sql, see that file's header for the full
-- rationale.
CREATE OR ALTER PROCEDURE StockConsumption_GetAll
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

    SELECT
        scd.StockConsumptionId AS Id,
        s.StoreName,
        COALESCE(i.Name, m.MedicineFullName, f.Name) AS ItemName,
        CAST(scd.Type AS NVARCHAR(50)) AS Type,
        st.Name AS StockType,
        scd.Quantity,
        ISNULL(e.FullName, '') AS CreatedBy,
        sc.CreatedOn,
        COUNT(*) OVER() AS TotalCount
    FROM Inv.StockConsumptionDetails scd
    INNER JOIN Inv.StockConsumptions sc ON scd.StockConsumptionId = sc.Id
    LEFT JOIN Inv.PharmacyStores s ON sc.StoreId = s.StoreId
    LEFT JOIN Inv.Items i ON scd.ItemId = i.Id
    LEFT JOIN Pharmacy.Medicines m ON scd.MedicineId = m.MedicineId
    LEFT JOIN Account.Fees f ON scd.SubServiceId = f.Id
    LEFT JOIN Inv.StockTypes st ON scd.StockTypeId = st.Id
    LEFT JOIN dbo.Users u ON sc.CreatedById = u.UserID
    LEFT JOIN dbo.Employee e ON u.EmpID = e.EmpID
    WHERE sc.IsDeleted = 0
        AND scd.IsDeleted = 0
        AND (@BranchId IS NULL OR sc.BranchId = @BranchId)
        AND (@StoreId IS NULL OR sc.StoreId = @StoreId)
        AND (@IsAdmin = 1 OR sc.StoreId IN (SELECT StoreId FROM @AllowedStoreIdTable))
        AND (@StartDate IS NULL OR sc.CreatedOn >= @StartDate)
        AND (@EndDate IS NULL OR sc.CreatedOn <= @EndDate)
        AND (
            @SearchTerm IS NULL OR @SearchTerm = ''
            OR s.StoreName LIKE '%' + @SearchTerm + '%'
            OR i.Name LIKE '%' + @SearchTerm + '%'
            OR m.MedicineFullName LIKE '%' + @SearchTerm + '%'
            OR f.Name LIKE '%' + @SearchTerm + '%'
        )
    ORDER BY sc.CreatedOn DESC
    OFFSET @Offset ROWS FETCH NEXT @Take ROWS ONLY;
END
