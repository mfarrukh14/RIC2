-- =============================================
-- Stock Flow Report Stored Procedure
-- =============================================

CREATE OR ALTER PROCEDURE StockFlow_GetReport
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL,
    @Store NVARCHAR(255) = NULL,
    @Item NVARCHAR(255) = NULL,
    @InventoryNo NVARCHAR(100) = NULL,
    @ChallanNo NVARCHAR(100) = NULL,
    @InvoiceNo NVARCHAR(100) = NULL,
    @DemandRequestNo NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StoreId INT = TRY_CAST(@Store AS INT);

    -- This is a composite report that shows stock movements from multiple sources

    SELECT
        CreatedOn AS DateTime,
        TransactionType,
        RefNumber,
        ItemName,
        DemandRequestedStore,
        StockType,
        OpeningQuantity,
        ReceivedQuantity,
        IssuedQuantity,
        BalanceQuantity,
        BatchNo,
        ActionBy
    FROM (
        -- GRN Records (Received) - GRNs have no StoreId of their own in this schema,
        -- so @Store doesn't filter this branch.
        SELECT
            grn.CreatedOn,
            'GRN' AS TransactionType,
            CAST(grn.Id AS NVARCHAR(50)) AS RefNumber,
            i.Name AS ItemName,
            '' AS DemandRequestedStore,
            st.Name AS StockType,
            0.00 AS OpeningQuantity,
            grni.ReceivedQuantity AS ReceivedQuantity,
            0.00 AS IssuedQuantity,
            grni.ReceivedQuantity AS BalanceQuantity,
            grni.BatchNo,
            ISNULL(e.FullName, '') AS ActionBy
        FROM Inv.GoodsReceivingNotes grn
        INNER JOIN Inv.GRNItems grni ON grn.Id = grni.GRNId
        LEFT JOIN Inv.Items i ON grni.ItemId = i.Id
        LEFT JOIN Pharmacy.StockTypes st ON grn.StockTypeId = st.Id
        LEFT JOIN Users u ON grn.CreatedById = u.UserID
        LEFT JOIN Employee e ON e.EmpID = u.EmpID
        WHERE 1 = 1
            AND (@StartDate IS NULL OR grn.CreatedOn >= @StartDate)
            AND (@EndDate IS NULL OR grn.CreatedOn <= @EndDate)
            AND (@Item IS NULL OR i.Name LIKE '%' + @Item + '%')
            AND (@InventoryNo IS NULL OR grn.PONumber LIKE '%' + @InventoryNo + '%')
            AND (@InvoiceNo IS NULL OR grn.InvoiceNo LIKE '%' + @InvoiceNo + '%')

        UNION ALL

        -- Transfer Inventory Records (Issued from source store, Received at destination store)
        SELECT
            t.CreatedOn,
            'Transfer' AS TransactionType,
            ISNULL(t.TransferNumber, CAST(t.Id AS NVARCHAR(50))) AS RefNumber,
            i.Name AS ItemName,
            ISNULL(sTo.StoreName, '') AS DemandRequestedStore,
            CAST(NULL AS NVARCHAR(100)) AS StockType,
            0.00 AS OpeningQuantity,
            ti.Quantity AS ReceivedQuantity,
            ti.Quantity AS IssuedQuantity,
            0.00 AS BalanceQuantity,
            NULL AS BatchNo,
            ISNULL(e.FullName, '') AS ActionBy
        FROM Inv.TransferInventory t
        INNER JOIN Inv.TransferInventoryItems ti ON ti.TransferInventoryId = t.Id
        LEFT JOIN Inv.Items i ON ti.ItemId = i.Id
        LEFT JOIN Inv.PharmacyStores sTo ON t.ToStoreId = sTo.StoreId
        LEFT JOIN Users u ON t.CreatedById = u.UserID
        LEFT JOIN Employee e ON e.EmpID = u.EmpID
        WHERE t.IsActive = 1
            AND (@StartDate IS NULL OR t.CreatedOn >= @StartDate)
            AND (@EndDate IS NULL OR t.CreatedOn <= @EndDate)
            AND (@Item IS NULL OR i.Name LIKE '%' + @Item + '%')
            AND (@StoreId IS NULL OR t.FromStoreId = @StoreId OR t.ToStoreId = @StoreId)

        UNION ALL

        -- Stock Adjustments (Can be positive or negative)
        -- sad.ItemId references Inv.Items directly - it is not a lookup key into
        -- Inv.InventoryItems (a separate, unrelated stock-lot table), so the previous
        -- indirect join through it never matched and left ItemName NULL for every row.
        SELECT
            sa.CreatedOn,
            CASE WHEN sa.Type = 1 THEN 'Adjustment(+)' ELSE 'Adjustment(-)' END AS TransactionType,
            CAST(sa.Id AS NVARCHAR(50)) AS RefNumber,
            items.Name AS ItemName,
            ISNULL(s.StoreName, '') AS DemandRequestedStore,
            st.Name AS StockType,
            0.00 AS OpeningQuantity,
            CASE WHEN sa.Type = 1 THEN sad.Quantity ELSE 0.00 END AS ReceivedQuantity,
            CASE WHEN sa.Type = 2 THEN sad.Quantity ELSE 0.00 END AS IssuedQuantity,
            0.00 AS BalanceQuantity,
            NULL AS BatchNo,
            ISNULL(e.FullName, '') AS ActionBy
        FROM Inv.StockAdjustments sa
        INNER JOIN Inv.StockAdjustmentDetails sad ON sa.Id = sad.StockAdjustmentId
        LEFT JOIN Inv.Items items ON sad.ItemId = items.Id
        LEFT JOIN Inv.PharmacyStores s ON sa.StoreId = s.StoreId
        LEFT JOIN Pharmacy.StockTypes st ON sad.StockTypeId = st.Id
        LEFT JOIN Users u ON sa.CreatedById = u.UserID
        LEFT JOIN Employee e ON e.EmpID = u.EmpID
        WHERE sa.IsDeleted = 0
            AND (@StartDate IS NULL OR sa.CreatedOn >= @StartDate)
            AND (@EndDate IS NULL OR sa.CreatedOn <= @EndDate)
            AND (@Item IS NULL OR items.Name LIKE '%' + @Item + '%')
            AND (@StoreId IS NULL OR sa.StoreId = @StoreId)

        UNION ALL

        -- Stock Consumption (Issued) - same indirect-join bug as Adjustments, fixed the
        -- same way; filters by the consumption detail's own store (the store it was
        -- actually consumed from), not just the header's.
        SELECT
            sc.CreatedOn,
            'Consumption' AS TransactionType,
            CAST(sc.Id AS NVARCHAR(50)) AS RefNumber,
            items.Name AS ItemName,
            ISNULL(s.StoreName, '') AS DemandRequestedStore,
            st.Name AS StockType,
            0.00 AS OpeningQuantity,
            0.00 AS ReceivedQuantity,
            scd.Quantity AS IssuedQuantity,
            0.00 AS BalanceQuantity,
            scd.BatchNo,
            ISNULL(e.FullName, '') AS ActionBy
        FROM Inv.StockConsumptions sc
        INNER JOIN Inv.StockConsumptionDetails scd ON sc.Id = scd.StockConsumptionId
        LEFT JOIN Inv.Items items ON scd.ItemId = items.Id
        LEFT JOIN Inv.PharmacyStores s ON scd.StoreId = s.StoreId
        LEFT JOIN Pharmacy.StockTypes st ON scd.StockTypeId = st.Id
        LEFT JOIN Users u ON sc.CreatedById = u.UserID
        LEFT JOIN Employee e ON e.EmpID = u.EmpID
        WHERE sc.IsDeleted = 0
            AND scd.IsDeleted = 0
            AND (@StartDate IS NULL OR sc.CreatedOn >= @StartDate)
            AND (@EndDate IS NULL OR sc.CreatedOn <= @EndDate)
            AND (@Item IS NULL OR items.Name LIKE '%' + @Item + '%')
            AND (@StoreId IS NULL OR scd.StoreId = @StoreId)

        UNION ALL

        -- Demand Requests (Issued from the fulfilling store, Received at the requesting
        -- store) - this is the only transaction source @DemandRequestNo can ever match
        -- against, so it needs its own branch for that filter to mean anything at all.
        -- IMPORTANT: DemandRequests.RequestingStoreId/RequestedToStoreId are keyed into
        -- Inv.Stores, a completely different store table than Inv.PharmacyStores (which
        -- backs the @Store filter and every other branch here) - the two share numeric
        -- IDs that refer to different physical stores. So @Store deliberately does NOT
        -- filter this branch; it would silently match the wrong store.
        SELECT
            dr.CreatedOn,
            'DemandRequest' AS TransactionType,
            dr.DemandRequestNumber AS RefNumber,
            i.Name AS ItemName,
            ISNULL(sReq.StoreName, '') AS DemandRequestedStore,
            st.Name AS StockType,
            0.00 AS OpeningQuantity,
            ISNULL(dri.ReceivedQuantity, 0) AS ReceivedQuantity,
            ISNULL(dri.IssuedQuantity, 0) AS IssuedQuantity,
            0.00 AS BalanceQuantity,
            NULL AS BatchNo,
            ISNULL(e.FullName, '') AS ActionBy
        FROM Inv.DemandRequests dr
        INNER JOIN Inv.DemandRequestItems dri ON dri.DemandRequestId = dr.Id
        LEFT JOIN Inv.Items i ON dri.ItemId = i.Id
        LEFT JOIN Inv.Stores sReq ON dr.RequestingStoreId = sReq.StoreId
        LEFT JOIN Pharmacy.StockTypes st ON dr.StockTypeId = st.Id
        LEFT JOIN Users u ON dr.CreatedById = u.UserID
        LEFT JOIN Employee e ON e.EmpID = u.EmpID
        WHERE dr.IsActive = 1
            AND (@StartDate IS NULL OR dr.CreatedOn >= @StartDate)
            AND (@EndDate IS NULL OR dr.CreatedOn <= @EndDate)
            AND (@Item IS NULL OR i.Name LIKE '%' + @Item + '%')
            AND (@DemandRequestNo IS NULL OR dr.DemandRequestNumber LIKE '%' + @DemandRequestNo + '%')
    ) AS StockMovements
    ORDER BY DateTime DESC;
END
GO

PRINT 'Stock Flow stored procedure created successfully.';
GO
