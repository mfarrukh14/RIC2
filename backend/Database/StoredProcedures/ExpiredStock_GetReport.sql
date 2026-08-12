-- =============================================
-- Expired Stock Report Stored Procedure
-- =============================================

CREATE OR ALTER PROCEDURE ExpiredStock_GetReport
    @StoreName NVARCHAR(255) = NULL,
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL,
    @Item NVARCHAR(255) = NULL,
    @SearchTerm NVARCHAR(255) = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (CASE WHEN @PageNumber < 1 THEN 0 ELSE @PageNumber - 1 END) * (CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END);
    DECLARE @Take INT = CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END;

    -- Get items that have already expired (ExpDate < GETDATE())
    -- LEFT JOIN Inv.Items, not INNER - grni.ItemId is NULL for every Medicine/Fee-
    -- sourced GRN line (87% of all lines, see MigratePurchaseSummary_iHealthCure_
    -- HMSMAIN_TF.sql header for the same ratio elsewhere), which was silently
    -- dropping all 3098 currently-expired rows before this fix - the report always
    -- came back empty. DenormalizedItemName (populated at GRN entry time) covers
    -- the name for those rows the way it already does elsewhere in this schema.
    ;WITH Filtered AS (
        SELECT
            COALESCE(i.Name, grni.DenormalizedItemName, '(item not found)') AS Name,
            st.Name AS StockType,
            grni.BatchNo,
            grni.MfgDate,
            grni.ExpiryDate AS ExpDate,
            grni.RemainingQuantity AS TotalItems
        FROM Inv.GRNItems grni
        INNER JOIN Inv.GoodsReceivingNotes grn ON grni.GRNId = grn.Id
        LEFT JOIN Inv.Items i ON grni.ItemId = i.Id
        LEFT JOIN Inv.StockTypes st ON grn.StockTypeId = st.Id
        WHERE grni.ExpiryDate < GETDATE()
            AND grni.RemainingQuantity > 0
            AND (@StartDate IS NULL OR grni.ExpiryDate >= @StartDate)
            AND (@EndDate IS NULL OR grni.ExpiryDate <= @EndDate)
            AND (@Item IS NULL OR COALESCE(i.Name, grni.DenormalizedItemName, '') LIKE '%' + @Item + '%')
            AND (
                @SearchTerm IS NULL
                OR COALESCE(i.Name, grni.DenormalizedItemName, '') LIKE '%' + @SearchTerm + '%'
                OR st.Name LIKE '%' + @SearchTerm + '%'
                OR grni.BatchNo LIKE '%' + @SearchTerm + '%'
            )
    )
    SELECT *, COUNT(*) OVER() AS TotalCount
    FROM Filtered
    ORDER BY ExpDate ASC
    OFFSET @Offset ROWS FETCH NEXT @Take ROWS ONLY;
END
GO

PRINT 'Expired Stock stored procedure created successfully.';
GO
