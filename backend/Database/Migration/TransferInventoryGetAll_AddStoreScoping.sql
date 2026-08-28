-- Adds store-scoped access control to TransferInventory_GetAll - a transfer
-- has two store legs (From/To), so unlike a single-store list, a non-admin
-- sees a transfer if EITHER their From or To store is one they're allowed to
-- see (they may only be assigned the receiving store, for instance, and still
-- legitimately need to see stock arriving there). Same
-- IsAdmin/AllowedStoreIds pattern as StockSearch_AddStoreScoping.sql.
CREATE OR ALTER PROCEDURE TransferInventory_GetAll
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

    ;WITH FilteredTransfers AS (
        SELECT
            t.Id,
            t.TransferNumber AS DRNo,
            t.FromStoreId,
            fs.StoreName as FromStoreName,
            t.ToStoreId,
            ts.StoreName as ToStoreName,
            NULL AS StockTypeId,
            NULL AS StockTypeName,
            ti.ItemId,
            i.Name AS ItemName,
            ISNULL((SELECT SUM(ti2.Quantity) FROM Inv.TransferInventoryItems ti2 WHERE ti2.TransferInventoryId = t.Id AND ti2.IsActive = 1), 0) AS Quantity,
            t.TransferDate,
            t.Status,
            t.Notes,
            t.IsActive,
            t.CreatedOn
        FROM Inv.TransferInventory t
        LEFT JOIN Inv.PharmacyStores fs ON t.FromStoreId = fs.StoreId
        LEFT JOIN Inv.PharmacyStores ts ON t.ToStoreId = ts.StoreId
        OUTER APPLY (
            SELECT TOP 1 ItemId
            FROM Inv.TransferInventoryItems
            WHERE TransferInventoryId = t.Id AND IsActive = 1
            ORDER BY Id
        ) ti
        LEFT JOIN Inv.Items i ON ti.ItemId = i.Id
        WHERE t.IsActive = 1
            AND (
                @IsAdmin = 1
                OR t.FromStoreId IN (SELECT StoreId FROM @AllowedStoreIdTable)
                OR t.ToStoreId IN (SELECT StoreId FROM @AllowedStoreIdTable)
            )
            AND (
                @SearchTerm IS NULL OR @SearchTerm = ''
                OR t.TransferNumber LIKE '%' + @SearchTerm + '%'
                OR fs.StoreName LIKE '%' + @SearchTerm + '%'
                OR ts.StoreName LIKE '%' + @SearchTerm + '%'
                OR i.Name LIKE '%' + @SearchTerm + '%'
            )
    )
    SELECT *, COUNT(*) OVER() AS TotalCount
    FROM FilteredTransfers
    ORDER BY CreatedOn DESC
    OFFSET @Offset ROWS FETCH NEXT @Take ROWS ONLY;
END
