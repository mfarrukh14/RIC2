-- Stored procedure to get GRN report by batch number
CREATE PROCEDURE GRN_GetReportByBatch
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
        CAST(grn.PurchaseOrderId AS NVARCHAR(50)) AS PONumber,
        '' AS PODate,
        '' AS ManualPONumber,
        st.StockTypeName AS StockType,
        'Regular' AS Regular,
        s.StoreName AS StoreName,
        v.Name AS VendorName,
        v.Address AS VendorAddress,
        v.Email AS VendorEmail,
        v.CNo AS VendorContactNo
    FROM 
        GoodsReceivingNotes grn
    INNER JOIN 
        GRNItems gi ON grn.Id = gi.GRNId
    INNER JOIN 
        Items i ON gi.ItemId = i.Id
    LEFT JOIN 
        StockTypes st ON grn.StockTypeId = st.StockTypeId
    LEFT JOIN 
        Stores s ON grn.StockTypeId = s.StoreId
    LEFT JOIN 
        Vendors v ON grn.VendorId = v.Id
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
        gi.RetailCharges,
        gi.RetailChargesAmount,
        gi.GSTCharges,
        gi.GSTChargesAmount,
        gi.TotalSellingPrice AS TotalSalePrice,
        gi.ProfitMarginPerItem AS Margin,
        gi.TotalBuyingPrice AS Amount,
        gi.Discount,
        (gi.TotalBuyingPrice - gi.DiscountAmount) AS Total
    FROM 
        GRNItems gi
    INNER JOIN 
        Items i ON gi.ItemId = i.Id
    LEFT JOIN 
        Manufacturers m ON gi.ManufacturerId = m.Id
    WHERE 
        gi.BatchNo = @BatchNo
        AND i.Name = @ItemName;
END;
GO
