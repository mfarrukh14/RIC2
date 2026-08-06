-- Stored procedure to get stock balance report
CREATE OR ALTER PROCEDURE StockBalance_GetReport
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL,
    @Store NVARCHAR(255) = NULL,
    @Branch NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @OpeningPurchase DECIMAL(18,2) = 0;
    DECLARE @OpeningSale DECIMAL(18,2) = 0;
    DECLARE @PurchasePurchase DECIMAL(18,2) = 0;
    DECLARE @PurchaseSale DECIMAL(18,2) = 0;
    DECLARE @SalePurchase DECIMAL(18,2) = 0;
    DECLARE @SaleSale DECIMAL(18,2) = 0;
    DECLARE @ClosingPurchase DECIMAL(18,2) = 0;
    DECLARE @ClosingSale DECIMAL(18,2) = 0;

    -- Calculate Opening Stock (items received before start date)
    SELECT
        @OpeningPurchase = ISNULL(SUM(gi.TotalBuyingPrice), 0),
        @OpeningSale = ISNULL(SUM(gi.TotalSellingPrice), 0)
    FROM
        Inv.GRNItems gi
    INNER JOIN
        Inv.GoodsReceivingNotes grn ON gi.GRNId = grn.Id
    LEFT JOIN
        Inv.PurchaseOrders po ON grn.PurchaseOrderId = po.PurchaseOrderId
    LEFT JOIN
        Inv.PharmacyStores s ON po.StoreId = s.StoreId
    WHERE
        grn.DateAndTime < ISNULL(@StartDate, '1900-01-01')
        AND (@Store IS NULL OR s.StoreName = @Store);

    -- Calculate Purchase Stock (items received within date range)
    SELECT
        @PurchasePurchase = ISNULL(SUM(gi.TotalBuyingPrice), 0),
        @PurchaseSale = ISNULL(SUM(gi.TotalSellingPrice), 0)
    FROM
        Inv.GRNItems gi
    INNER JOIN
        Inv.GoodsReceivingNotes grn ON gi.GRNId = grn.Id
    LEFT JOIN
        Inv.PurchaseOrders po ON grn.PurchaseOrderId = po.PurchaseOrderId
    LEFT JOIN
        Inv.PharmacyStores s ON po.StoreId = s.StoreId
    WHERE
        grn.DateAndTime >= ISNULL(@StartDate, '1900-01-01')
        AND grn.DateAndTime <= ISNULL(@EndDate, '9999-12-31')
        AND (@Store IS NULL OR s.StoreName = @Store);

    -- Calculate Sale Stock (consumption within date range), valued at each
    -- item's average GRN buying/selling price since consumption records
    -- don't carry their own price
    SELECT
        @SalePurchase = ISNULL(SUM(scd.Quantity * ISNULL(ip.AvgBuyingPrice, 0)), 0),
        @SaleSale = ISNULL(SUM(scd.Quantity * ISNULL(ip.AvgSellingPrice, 0)), 0)
    FROM
        Inv.StockConsumptionDetails scd
    INNER JOIN
        Inv.StockConsumptions sc ON scd.StockConsumptionId = sc.Id
    LEFT JOIN
        Inv.PharmacyStores s ON scd.StoreId = s.StoreId
    OUTER APPLY (
        SELECT AVG(gi.UnitBuyingPrice) AS AvgBuyingPrice, AVG(gi.UnitSellingPrice) AS AvgSellingPrice
        FROM Inv.GRNItems gi
        WHERE gi.ItemId = scd.ItemId
    ) ip
    WHERE
        sc.CreatedOn >= ISNULL(@StartDate, '1900-01-01')
        AND sc.CreatedOn <= ISNULL(@EndDate, '9999-12-31')
        AND (@Store IS NULL OR s.StoreName = @Store);

    -- Calculate Closing Stock
    SET @ClosingPurchase = @OpeningPurchase + @PurchasePurchase - @SalePurchase;
    SET @ClosingSale = @OpeningSale + @PurchaseSale - @SaleSale;

    -- Return all values
    SELECT
        @OpeningPurchase AS OpeningStockPurchase,
        @OpeningSale AS OpeningStockSale,
        @PurchasePurchase AS PurchaseStockPurchase,
        @PurchaseSale AS PurchaseStockSale,
        0.00 AS PatientBillReturnPurchase,
        0.00 AS PatientBillReturnSale,
        0.00 AS BuyDemandReceivedStockPurchase,
        0.00 AS BuyDemandReceivedStockSale,
        0.00 AS ProcedureMedicinesReceivedStockPurchase,
        0.00 AS ProcedureMedicinesReceivedStockSale,
        0.00 AS ProcedureFeeReceivedPurchase,
        0.00 AS ProcedureFeeReceivedSale,
        0.00 AS OrdersReceivedPurchase,
        0.00 AS OrdersReceivedSale,
        0.00 AS AssetAllocationReceivedStockPurchase,
        0.00 AS AssetAllocationReceivedStockSale,
        0.00 AS CustomerChallanFormsReceivedPurchase,
        0.00 AS CustomerChallanFormsReceivedSale,
        0.00 AS StockAuditPurchase,
        0.00 AS StockAuditSale,
        0.00 AS SampleCollectionConsumptionItemsReceivedPurchase,
        0.00 AS SampleCollectionConsumptionItemsReceivedSale,
        0.00 AS StockWastageReceivedPurchase,
        0.00 AS StockWastageReceivedSale,
        0.00 AS StockReturnReceivedPurchase,
        0.00 AS StockReturnReceivedSale,
        @SalePurchase AS SaleStockPurchase,
        @SaleSale AS SaleStockSale,
        0.00 AS PurchaseReturnPurchase,
        0.00 AS PurchaseReturnSale,
        0.00 AS StockExpiredAndDamagedPurchase,
        0.00 AS StockExpiredAndDamagedSale,
        0.00 AS SaleDemandIssuedStockPurchase,
        0.00 AS SaleDemandIssuedStockSale,
        0.00 AS ProcedureMedicinesPurchase,
        0.00 AS ProcedureMedicinesSale,
        0.00 AS ProcedureFeePurchase,
        0.00 AS ProcedureFeeSale,
        0.00 AS OrdersIssuedPurchase,
        0.00 AS OrdersIssuedSale,
        0.00 AS AssetAllocationPurchase,
        0.00 AS AssetAllocationSale,
        0.00 AS CustomerChallanFormsIssuedPurchase,
        0.00 AS CustomerChallanFormsIssuedSale,
        0.00 AS StockAuditOutPurchase,
        0.00 AS StockAuditOutSale,
        0.00 AS SampleCollectionConsumptionItemsIssuedPurchase,
        0.00 AS SampleCollectionConsumptionItemsIssuedSale,
        0.00 AS StockWastagePurchase,
        0.00 AS StockWastageSale,
        0.00 AS StockReturnPurchase,
        0.00 AS StockReturnSale,
        @ClosingPurchase AS ClosingStockPurchase,
        @ClosingSale AS ClosingStockSale;
END;
GO
