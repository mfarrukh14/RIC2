-- Stored procedure to get GRN report by batch number
CREATE OR ALTER PROCEDURE GRN_GetReportByBatch
    @BatchNo NVARCHAR(255),
    @ItemName NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    -- Get GRN header information
    SELECT TOP 1
        grn.InvoiceNo AS InventoryNo,
        'System' AS EnteredBy,
        grn.DateAndTime,
        COALESCE(po.PONumber, CAST(grn.PurchaseOrderId AS NVARCHAR(50))) AS PONumber,
        '' AS PODate,
        COALESCE(po.ManualPONumber, '') AS ManualPONumber,
        st.Name AS StockType,
        'Regular' AS Regular,
        COALESCE(s.StoreName, 'Unassigned Store') AS StoreName,
        v.Name AS VendorName,
        v.Address AS VendorAddress,
        v.Email AS VendorEmail,
        v.CNo AS VendorContactNo
    FROM 
        Inv.GoodsReceivingNotes grn
    INNER JOIN 
        Inv.GRNItems gi ON grn.Id = gi.GRNId
    INNER JOIN 
        Inv.Items i ON gi.ItemId = i.Id
    LEFT JOIN
        Inv.PurchaseOrders po ON grn.PurchaseOrderId = po.PurchaseOrderId
    LEFT JOIN 
        Inv.StockTypes st ON grn.StockTypeId = st.Id
    LEFT JOIN 
        Inv.PharmacyStores s ON po.StoreId = s.StoreId
    LEFT JOIN 
        Inv.Vendors v ON grn.VendorId = v.Id
    WHERE 
        gi.BatchNo = @BatchNo
        AND i.Name = @ItemName;

    -- Get GRN items
    SELECT 
        i.Name AS Items,
        m.Name AS Mfr,
        gi.MfgDate,
        gi.ExpiryDate AS ExpDate,
        gi.BatchNo,
        gi.NoOfBoxes AS Boxes,
        gi.NoOfPackets AS Packs,
        gi.ItemPerPacket AS QtyPerPack,
        gi.TotalItem AS TotalQty,
        gi.PackQuantity AS PackQty,
        gi.TotalBuyingPrice AS TotalPrice,
        gi.UnitBuyingPrice AS UnitPrice,
        gi.AdvanceTaxPercentage AS AdvanceTax,
        gi.AdvanceTaxAmount,
        gi.UnitSellingPrice AS UnitSalePrice,
        CAST(CASE WHEN gi.RetailCharges = 1 THEN 1 ELSE 0 END AS DECIMAL(18, 2)) AS RetailCharges,
        gi.RetailChargesAmount,
        CAST(CASE WHEN gi.GSTCharges = 1 THEN 1 ELSE 0 END AS DECIMAL(18, 2)) AS GSTCharges,
        gi.GSTChargesAmount,
        gi.TotalSellingPrice AS TotalSalePrice,
        gi.ProfitMarginPerItem AS Margin,
        gi.TotalBuyingPrice AS Amount,
        CAST(COALESCE(gi.DiscountAmount, 0) AS DECIMAL(18, 2)) AS Discount,
        (gi.TotalBuyingPrice - gi.DiscountAmount) AS Total
    FROM 
        Inv.GRNItems gi
    INNER JOIN 
        Inv.Items i ON gi.ItemId = i.Id
    LEFT JOIN 
        Inv.Manufacturers m ON gi.ManufacturerId = m.Id
    WHERE 
        gi.BatchNo = @BatchNo
        AND i.Name = @ItemName;
END;
GO
