-- =============================================
-- Stock Flow Report Stored Procedure
-- =============================================

USE InventoryManagementDB_SP;
GO

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
        -- GRN Records (Received)
        SELECT 
            grn.CreatedOn,
            'GRN' AS TransactionType,
            CAST(grn.Id AS NVARCHAR(50)) AS RefNumber,
            i.Name AS ItemName,
            '' AS DemandRequestedStore,
            st.StockTypeName AS StockType,
            0.00 AS OpeningQuantity,
            grni.ReceivedQuantity AS ReceivedQuantity,
            0.00 AS IssuedQuantity,
            grni.ReceivedQuantity AS BalanceQuantity,
            grni.BatchNo,
            ISNULL(u.Name, '') AS ActionBy
        FROM dbo.GoodsReceivingNotes grn
        INNER JOIN dbo.GRNItems grni ON grn.Id = grni.GRNId
        LEFT JOIN dbo.Items i ON grni.ItemId = i.Id
        LEFT JOIN dbo.StockTypes st ON grn.StockTypeId = st.StockTypeId
        LEFT JOIN dbo.Users u ON grn.CreatedById = u.Id
        WHERE 1=1
            AND (@StartDate IS NULL OR grn.CreatedOn >= @StartDate)
            AND (@EndDate IS NULL OR grn.CreatedOn <= @EndDate)
            AND (@Item IS NULL OR i.Name LIKE '%' + @Item + '%')

        UNION ALL

        -- Transfer Inventory Records (Issued/Received)
        SELECT 
            t.CreatedOn,
            'Transfer' AS TransactionType,
            t.DRNo AS RefNumber,
            t.ItemName,
            ISNULL(sTo.StoreName, '') AS DemandRequestedStore,
            st.StockTypeName AS StockType,
            0.00 AS OpeningQuantity,
            CASE WHEN @Store IS NULL OR t.ToStoreId = CAST(@Store AS INT) THEN t.Quantity ELSE 0.00 END AS ReceivedQuantity,
            CASE WHEN @Store IS NULL OR t.FromStoreId = CAST(@Store AS INT) THEN t.Quantity ELSE 0.00 END AS IssuedQuantity,
            0.00 AS BalanceQuantity,
            NULL AS BatchNo,
            ISNULL(u.Name, '') AS ActionBy
        FROM dbo.TransferInventory t
        LEFT JOIN dbo.StockTypes st ON t.StockTypeId = st.StockTypeId
        LEFT JOIN dbo.Stores sTo ON t.ToStoreId = sTo.StoreId
        LEFT JOIN dbo.Users u ON t.CreatedById = u.Id
        WHERE t.IsActive = 1
            AND (@StartDate IS NULL OR t.CreatedOn >= @StartDate)
            AND (@EndDate IS NULL OR t.CreatedOn <= @EndDate)
            AND (@Item IS NULL OR t.ItemName LIKE '%' + @Item + '%')
            AND (@DemandRequestNo IS NULL OR t.DRNo LIKE '%' + @DemandRequestNo + '%')

        UNION ALL

        -- Stock Adjustments (Can be positive or negative)
        SELECT 
            sa.CreatedOn,
            CASE WHEN sa.Type = 1 THEN 'Adjustment(+)' ELSE 'Adjustment(-)' END AS TransactionType,
            CAST(sa.Id AS NVARCHAR(50)) AS RefNumber,
            i.Name AS ItemName,
            '' AS DemandRequestedStore,
            st.StockTypeName AS StockType,
            0.00 AS OpeningQuantity,
            CASE WHEN sa.Type = 1 THEN sad.Quantity ELSE 0.00 END AS ReceivedQuantity,
            CASE WHEN sa.Type = 2 THEN sad.Quantity ELSE 0.00 END AS IssuedQuantity,
            0.00 AS BalanceQuantity,
            NULL AS BatchNo,
            ISNULL(u.Name, '') AS ActionBy
        FROM dbo.StockAdjustments sa
        INNER JOIN dbo.StockAdjustmentDetails sad ON sa.Id = sad.StockAdjustmentId
        LEFT JOIN dbo.InventoryItems i ON sad.ItemId = i.Id
        LEFT JOIN dbo.StockTypes st ON sad.StockTypeId = st.StockTypeId
        LEFT JOIN dbo.Users u ON sa.CreatedById = u.Id
        WHERE sa.IsDeleted = 0
            AND (@StartDate IS NULL OR sa.CreatedOn >= @StartDate)
            AND (@EndDate IS NULL OR sa.CreatedOn <= @EndDate)
            AND (@Item IS NULL OR i.Name LIKE '%' + @Item + '%')

        UNION ALL

        -- Stock Consumption (Issued)
        SELECT 
            sc.CreatedOn,
            'Consumption' AS TransactionType,
            CAST(sc.Id AS NVARCHAR(50)) AS RefNumber,
            i.Name AS ItemName,
            '' AS DemandRequestedStore,
            st.StockTypeName AS StockType,
            0.00 AS OpeningQuantity,
            0.00 AS ReceivedQuantity,
            scd.Quantity AS IssuedQuantity,
            0.00 AS BalanceQuantity,
            scd.BatchNo,
            ISNULL(u.Name, '') AS ActionBy
        FROM dbo.StockConsumptions sc
        INNER JOIN dbo.StockConsumptionDetails scd ON sc.Id = scd.StockConsumptionId
        LEFT JOIN dbo.InventoryItems i ON scd.ItemId = i.Id
        LEFT JOIN dbo.StockTypes st ON scd.StockTypeId = st.StockTypeId
        LEFT JOIN dbo.Users u ON CAST(sc.CreatedById AS NVARCHAR(50)) = CAST(u.Id AS NVARCHAR(50))
        WHERE sc.IsDeleted = 0
            AND scd.IsDeleted = 0
            AND (@StartDate IS NULL OR sc.CreatedOn >= @StartDate)
            AND (@EndDate IS NULL OR sc.CreatedOn <= @EndDate)
            AND (@Item IS NULL OR i.Name LIKE '%' + @Item + '%')
    ) AS StockMovements
    ORDER BY DateTime DESC;
END
GO

PRINT 'Stock Flow stored procedure created successfully.';
GO
