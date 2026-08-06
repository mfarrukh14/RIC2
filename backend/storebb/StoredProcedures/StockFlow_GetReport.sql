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
        -- Add Inventory Records (Received) - this app's other stock-receiving path
        -- alongside GRN below. Confirmed against the old system: its equivalent
        -- (Inventories/InventoryItems) was the PRIMARY receiving mechanism, always
        -- funneled through SP_Stock_UpdateStockBalance (which both updated the real
        -- balance and wrote a StockTransactions ledger row - see
        -- InventoryDetail_StockEffect_Live.sql for the matching fix on our side, since
        -- neither this table nor GRN previously touched Inv.Stocks at all here).
        SELECT
            inv.CreatedOn,
            'Inventory' AS TransactionType,
            CAST(inv.Id AS NVARCHAR(50)) AS RefNumber,
            i.Name AS ItemName,
            '' AS DemandRequestedStore,
            st.Name AS StockType,
            0.00 AS OpeningQuantity,
            ISNULL(d.TotalItems, 0) AS ReceivedQuantity,
            0.00 AS IssuedQuantity,
            ISNULL(d.TotalItems, 0) AS BalanceQuantity,
            NULL AS BatchNo,
            ISNULL(e.FullName, '') AS ActionBy
        FROM Inv.Inventories inv
        INNER JOIN Inv.InventoryDetails d ON d.InventoryId = inv.Id
        LEFT JOIN Inv.Items i ON d.ItemId = i.Id
        LEFT JOIN Pharmacy.StockTypes st ON inv.StockTypeId = st.Id
        LEFT JOIN Users u ON inv.CreatedById = u.UserID
        LEFT JOIN Employee e ON e.EmpID = u.EmpID
        WHERE inv.IsActive = 1
            AND (@StartDate IS NULL OR inv.CreatedOn >= @StartDate)
            AND (@EndDate IS NULL OR inv.CreatedOn <= @EndDate)
            AND (@Item IS NULL OR i.Name LIKE '%' + @Item + '%')
            AND (@StoreId IS NULL OR inv.StoreId = @StoreId)

        UNION ALL

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
        WHERE grn.IsActive = 1
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
        -- DemandRequests.RequestingStoreId/RequestedToStoreId are keyed into
        -- Inv.PharmacyStores - the same table that backs @Store everywhere else in this
        -- report (confirmed against DemandRequestService.cs, which resolves both store
        -- columns via Inv.PharmacyStores for the HMS schema). Inv.Stores is an unrelated,
        -- near-empty legacy table (Main Warehouse/OT Store/ER Store) whose IDs happen to
        -- overlap - joining against it produced blank or wrong store names. @Store only
        -- matches the requesting side here (not RequestedToStoreId) so the
        -- DemandRequestedStore column always shows the filtered store itself when a
        -- filter is active - rows where the store only fulfilled someone else's request
        -- are intentionally excluded rather than shown under a different store's name.
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
        LEFT JOIN Inv.PharmacyStores sReq ON dr.RequestingStoreId = sReq.StoreId
        LEFT JOIN Pharmacy.StockTypes st ON dr.StockTypeId = st.Id
        LEFT JOIN Users u ON dr.CreatedById = u.UserID
        LEFT JOIN Employee e ON e.EmpID = u.EmpID
        WHERE dr.IsActive = 1
            AND (@StartDate IS NULL OR dr.CreatedOn >= @StartDate)
            AND (@EndDate IS NULL OR dr.CreatedOn <= @EndDate)
            AND (@Item IS NULL OR i.Name LIKE '%' + @Item + '%')
            AND (@DemandRequestNo IS NULL OR dr.DemandRequestNumber LIKE '%' + @DemandRequestNo + '%')
            AND (@StoreId IS NULL OR dr.RequestingStoreId = @StoreId)

        UNION ALL

        -- Asset Allocations (Issued to a room/department) - matches the old system's
        -- "Asset Allocation" transaction source type in its stock ledger. Inv.AssetAllocations
        -- has no StoreId column in this schema (allocations are tracked by
        -- room/department, not by store), so - same as Demand Requests above - @Store
        -- does not filter this branch.
        SELECT
            aa.CreatedOn,
            'AssetAllocation' AS TransactionType,
            ISNULL(aa.AllocationNumber, CAST(aa.Id AS NVARCHAR(50))) AS RefNumber,
            i.Name AS ItemName,
            '' AS DemandRequestedStore,
            CAST(NULL AS NVARCHAR(100)) AS StockType,
            0.00 AS OpeningQuantity,
            0.00 AS ReceivedQuantity,
            aa.Quantity AS IssuedQuantity,
            0.00 AS BalanceQuantity,
            NULL AS BatchNo,
            ISNULL(e.FullName, '') AS ActionBy
        FROM Inv.AssetAllocations aa
        LEFT JOIN Inv.Items i ON aa.ItemId = i.Id
        LEFT JOIN Users u ON aa.CreatedById = u.UserID
        LEFT JOIN Employee e ON e.EmpID = u.EmpID
        WHERE aa.IsActive = 1
            AND (@StartDate IS NULL OR aa.CreatedOn >= @StartDate)
            AND (@EndDate IS NULL OR aa.CreatedOn <= @EndDate)
            AND (@Item IS NULL OR i.Name LIKE '%' + @Item + '%')
    ) AS StockMovements
    ORDER BY DateTime DESC;
END
GO

PRINT 'Stock Flow stored procedure created successfully.';
GO
