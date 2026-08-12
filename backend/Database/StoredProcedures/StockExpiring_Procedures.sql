-- =============================================
-- Stock Expiring Stored Procedures
-- =============================================

-- =============================================
-- Get Expiring Stock with Filters
-- =============================================
CREATE OR ALTER PROCEDURE StockExpiring_GetExpiringStock
    @StoreId INT = NULL,
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL,
    @ItemIds NVARCHAR(MAX) = NULL, -- Comma-separated list of item IDs
    @SearchTerm NVARCHAR(255) = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    -- Create temp table for item IDs if provided
    DECLARE @ItemIdTable TABLE (ItemId INT);

    IF @ItemIds IS NOT NULL AND @ItemIds != ''
    BEGIN
        INSERT INTO @ItemIdTable (ItemId)
        SELECT CAST(value AS INT)
        FROM STRING_SPLIT(@ItemIds, ',')
        WHERE value != '';
    END

    DECLARE @Offset INT = (CASE WHEN @PageNumber < 1 THEN 0 ELSE @PageNumber - 1 END) * (CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END);
    DECLARE @Take INT = CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END;

    -- LEFT JOIN Inv.Items, not INNER - id.ItemId is NULL for ~82% of eligible rows
    -- (Medicine/SubService-sourced Add Inventory lines, same ratio documented in
    -- InventoryDetail_StockEffect_Live.sql's header) - the INNER JOIN was silently
    -- dropping those rows entirely (12211 eligible -> only 2209 ever shown). Name
    -- resolved via the same Medicine/Fee lookup Item_GetAllWithMedicines already
    -- uses for these same MedicineId/SubServiceId columns.
    ;WITH Filtered AS (
        SELECT
            id.Id,
            COALESCE(i.Name, med.MedicineFullName, fee.Name, '(item not found)') AS ItemName,
            st.Name AS StockType,
            CAST(id.Id AS NVARCHAR(50)) AS BatchNo, -- Using ID as batch number since no BatchNo column
            id.MfgDate,
            id.ExpiryDate,
            id.TotalItems,
            inv.StoreId,
            s.StoreName
        FROM Inv.InventoryDetails id
        INNER JOIN Inv.Inventories inv ON id.InventoryId = inv.Id
        LEFT JOIN Inv.Items i ON id.ItemId = i.Id
        LEFT JOIN Pharmacy.Medicines med ON id.MedicineId = med.MedicineId
        LEFT JOIN Account.Fees fee ON id.SubServiceId = fee.Id
        LEFT JOIN Inv.PharmacyStores s ON inv.StoreId = s.StoreId
        LEFT JOIN Inv.StockTypes st ON inv.StockTypeId = st.Id
        WHERE id.TotalItems > 0
            AND id.ExpiryDate IS NOT NULL
            AND id.ExpiryDate >= GETDATE() -- Only non-expired items
            AND (@StoreId IS NULL OR inv.StoreId = @StoreId)
            AND (@StartDate IS NULL OR id.ExpiryDate >= @StartDate)
            AND (@EndDate IS NULL OR id.ExpiryDate <= @EndDate)
            AND (@ItemIds IS NULL OR @ItemIds = '' OR id.ItemId IN (SELECT ItemId FROM @ItemIdTable))
            AND (
                @SearchTerm IS NULL
                OR COALESCE(i.Name, med.MedicineFullName, fee.Name, '') LIKE '%' + @SearchTerm + '%'
                OR st.Name LIKE '%' + @SearchTerm + '%'
            )
    )
    SELECT *, COUNT(*) OVER() AS TotalCount
    FROM Filtered
    ORDER BY ExpiryDate ASC
    OFFSET @Offset ROWS FETCH NEXT @Take ROWS ONLY;
END
GO
