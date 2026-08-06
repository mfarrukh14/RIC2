-- =============================================
-- Wire GRN (Inventory Receiving) into a real Purchase Order and into Inv.Stocks.
--
-- Per user decision: GRN receiving is tied to a selected Purchase Order (not a
-- standalone Store field like "Add Inventory"), and the store credited is the PO's
-- own StoreId. This also completes GRN_GetPODetails, which GRNService.cs already
-- calls but which never existed on this DB (GRNPage.jsx was wired to mock data as a
-- placeholder). GetAllAsync/GetByIdAsync already read PurchaseOrderId as NOT NULL,
-- confirming this was always the intended design, just never finished.
--
-- Targets the live Inv schema (int PKs) that HMS_Jun26 actually runs.
-- =============================================

IF OBJECT_ID('dbo.GRN_Insert', 'P') IS NOT NULL
    DROP PROCEDURE dbo.GRN_Insert;
GO

CREATE PROCEDURE dbo.GRN_Insert
    @PurchaseOrderId INT,
    @PONumber NVARCHAR(100),
    @VendorId INT,
    @InvoiceNo NVARCHAR(100) = NULL,
    @StockTypeId INT = NULL,
    @DateAndTime DATETIME = NULL,
    @VendorInvoiceNo NVARCHAR(100) = NULL,
    @VendorInvoiceDate DATETIME = NULL,
    @CreatedById INT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Inv.GoodsReceivingNotes (
        PurchaseOrderId, PONumber, VendorId, InvoiceNo, StockTypeId,
        DateAndTime, VendorInvoiceNo, VendorInvoiceDate,
        IsActive, CreatedById, CreatedOn
    )
    VALUES (
        @PurchaseOrderId, @PONumber, @VendorId, @InvoiceNo, @StockTypeId,
        ISNULL(@DateAndTime, GETDATE()), @VendorInvoiceNo, @VendorInvoiceDate,
        1, @CreatedById, GETDATE()
    );

    SELECT SCOPE_IDENTITY() as Id;
END
GO

IF OBJECT_ID('dbo.GRNItem_Insert', 'P') IS NOT NULL
    DROP PROCEDURE dbo.GRNItem_Insert;
GO

CREATE PROCEDURE dbo.GRNItem_Insert
    @GRNId INT,
    @ItemId INT = NULL,
    @MedicineId INT = NULL,
    @SubServiceId INT = NULL,
    @ManufacturerId INT = NULL,
    @MfgDate DATETIME = NULL,
    @ExpiryDate DATETIME = NULL,
    @RegistrationNumber NVARCHAR(100) = NULL,
    @LotNo NVARCHAR(100) = NULL,
    @BatchNo NVARCHAR(100) = NULL,
    @NoOfBoxes INT = NULL,
    @NoOfPackets INT = NULL,
    @ItemPerPacket INT = NULL,
    @TotalItem INT = NULL,
    @PackQuantity INT = NULL,
    @ReceivedQuantity INT = NULL,
    @RemainingQuantity INT = NULL,
    @TotalBuyingPrice DECIMAL(18,2) = NULL,
    @UnitBuyingPrice DECIMAL(18,2) = NULL,
    @AdvanceTaxPercentage DECIMAL(18,2) = NULL,
    @AdvanceTaxAmount DECIMAL(18,2) = NULL,
    @Discount BIT = 0,
    @DiscountAmount DECIMAL(18,2) = NULL,
    @RetailCharges BIT = 0,
    @RetailChargesAmount DECIMAL(18,2) = NULL,
    @GSTCharges BIT = 0,
    @GSTChargesAmount DECIMAL(18,2) = NULL,
    @UnitSellingPrice DECIMAL(18,2) = NULL,
    @TotalSellingPrice DECIMAL(18,2) = NULL,
    @ProfitMarginPerItem DECIMAL(18,2) = NULL,
    @ProfitPerItem DECIMAL(18,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    INSERT INTO Inv.GRNItems (
        GRNId, ItemId, MedicineId, SubServiceId, ManufacturerId, MfgDate, ExpiryDate,
        RegistrationNumber, LotNo, BatchNo,
        NoOfBoxes, NoOfPackets, ItemPerPacket, TotalItem, PackQuantity,
        ReceivedQuantity, RemainingQuantity,
        TotalBuyingPrice, UnitBuyingPrice,
        AdvanceTaxPercentage, AdvanceTaxAmount,
        Discount, DiscountAmount,
        RetailCharges, RetailChargesAmount,
        GSTCharges, GSTChargesAmount,
        UnitSellingPrice, TotalSellingPrice,
        ProfitMarginPerItem, ProfitPerItem
    )
    VALUES (
        @GRNId, @ItemId, @MedicineId, @SubServiceId, @ManufacturerId, @MfgDate, @ExpiryDate,
        @RegistrationNumber, @LotNo, @BatchNo,
        @NoOfBoxes, @NoOfPackets, @ItemPerPacket, @TotalItem, @PackQuantity,
        @ReceivedQuantity, @RemainingQuantity,
        @TotalBuyingPrice, @UnitBuyingPrice,
        @AdvanceTaxPercentage, @AdvanceTaxAmount,
        @Discount, @DiscountAmount,
        @RetailCharges, @RetailChargesAmount,
        @GSTCharges, @GSTChargesAmount,
        @UnitSellingPrice, @TotalSellingPrice,
        @ProfitMarginPerItem, @ProfitPerItem
    );

    DECLARE @NewItemId INT = SCOPE_IDENTITY();

    -- Credit Inv.Stocks for the store on the GRN's linked Purchase Order - same
    -- upsert pattern as AddStockAsync / InventoryDetail_Insert's fix.
    DECLARE @StoreId INT, @BranchId INT;
    SELECT @StoreId = po.StoreId, @BranchId = ps.BranchId
    FROM Inv.GoodsReceivingNotes g
    INNER JOIN Inv.PurchaseOrders po ON po.PurchaseOrderId = g.PurchaseOrderId
    LEFT JOIN Inv.PharmacyStores ps ON ps.StoreId = po.StoreId
    WHERE g.Id = @GRNId;

    IF @ReceivedQuantity IS NOT NULL AND @ReceivedQuantity > 0 AND @StoreId IS NOT NULL
    BEGIN
        IF EXISTS (SELECT 1 FROM Inv.Stocks WHERE StoreId = @StoreId AND IsActive = 1
            AND ((@ItemId IS NOT NULL AND ItemId = @ItemId) OR (@MedicineId IS NOT NULL AND MedicineId = @MedicineId) OR (@SubServiceId IS NOT NULL AND SubServiceId = @SubServiceId)))
            UPDATE Inv.Stocks
            SET TotalItems = ISNULL(TotalItems, 0) + @ReceivedQuantity, ModifiedOn = GETDATE()
            WHERE StoreId = @StoreId AND IsActive = 1
                AND ((@ItemId IS NOT NULL AND ItemId = @ItemId) OR (@MedicineId IS NOT NULL AND MedicineId = @MedicineId) OR (@SubServiceId IS NOT NULL AND SubServiceId = @SubServiceId));
        ELSE
            INSERT INTO Inv.Stocks (ItemId, MedicineId, SubServiceId, StoreId, BranchId, TotalItems, IsActive, CreatedOn)
            VALUES (@ItemId, @MedicineId, @SubServiceId, @StoreId, @BranchId, @ReceivedQuantity, 1, GETDATE());
    END

    COMMIT TRANSACTION;

    SELECT @NewItemId as Id;
END
GO

IF OBJECT_ID('dbo.GRN_Delete', 'P') IS NOT NULL
    DROP PROCEDURE dbo.GRN_Delete;
GO

CREATE PROCEDURE dbo.GRN_Delete
    @Id INT,
    @ModifiedById INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    -- Reverse every line's credit before deactivating the whole receipt, same as
    -- Inventory_Delete.
    UPDATE s
    SET s.TotalItems = ISNULL(s.TotalItems, 0) - gi.ReceivedQuantity, s.ModifiedOn = GETDATE()
    FROM Inv.Stocks s
    INNER JOIN Inv.GRNItems gi
        ON (gi.ItemId IS NOT NULL AND gi.ItemId = s.ItemId)
        OR (gi.MedicineId IS NOT NULL AND gi.MedicineId = s.MedicineId)
        OR (gi.SubServiceId IS NOT NULL AND gi.SubServiceId = s.SubServiceId)
    INNER JOIN Inv.GoodsReceivingNotes g ON g.Id = gi.GRNId
    INNER JOIN Inv.PurchaseOrders po ON po.PurchaseOrderId = g.PurchaseOrderId
    WHERE g.Id = @Id AND s.StoreId = po.StoreId AND s.IsActive = 1
      AND gi.ReceivedQuantity IS NOT NULL AND gi.ReceivedQuantity > 0;

    UPDATE Inv.GoodsReceivingNotes
    SET
        IsActive = 0,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETDATE()
    WHERE Id = @Id;

    DECLARE @RowsAffected INT = @@ROWCOUNT;

    COMMIT TRANSACTION;

    SELECT @RowsAffected as AffectedRows;
END
GO

IF OBJECT_ID('dbo.GRN_GetPODetails', 'P') IS NOT NULL
    DROP PROCEDURE dbo.GRN_GetPODetails;
GO

CREATE PROCEDURE dbo.GRN_GetPODetails
    @PurchaseOrderId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        po.PurchaseOrderId AS Id,
        po.PONumber,
        po.VendorId,
        ISNULL(v.Name, '') AS VendorName,
        po.CreatedOn AS DateAndTime,
        po.Status
    FROM Inv.PurchaseOrders po
    LEFT JOIN Inv.Vendors v ON v.Id = po.VendorId
    WHERE po.PurchaseOrderId = @PurchaseOrderId AND po.IsActive = 1;

    -- Already-received quantity is summed across every prior (active) GRN raised
    -- against this same PO, so re-receiving a PO in multiple partial shipments shows
    -- the correct running Remaining Quantity.
    SELECT
        poi.Id,
        poi.PurchaseOrderId,
        poi.ItemId,
        poi.MedicineId,
        poi.SubServiceId,
        COALESCE(i.Name, m.MedicineFullName, f.Name, '') AS ItemName,
        CAST(poi.UnitQuantity AS INT) AS OrderedQuantity,
        ISNULL(CAST(received.ReceivedQty AS INT), 0) AS ReceivedQuantity,
        CAST(poi.UnitQuantity AS INT) - ISNULL(CAST(received.ReceivedQty AS INT), 0) AS RemainingQuantity,
        poi.UnitPrice AS Rate,
        poi.TotalPrice AS TotalAmount
    FROM Inv.PurchaseOrderItems poi
    LEFT JOIN Inv.Items i ON i.Id = poi.ItemId
    LEFT JOIN Pharmacy.Medicines m ON m.MedicineId = poi.MedicineId
    LEFT JOIN Account.Fees f ON f.Id = poi.SubServiceId
    OUTER APPLY (
        SELECT SUM(gi.ReceivedQuantity) AS ReceivedQty
        FROM Inv.GRNItems gi
        INNER JOIN Inv.GoodsReceivingNotes g ON g.Id = gi.GRNId
        WHERE g.PurchaseOrderId = @PurchaseOrderId AND g.IsActive = 1
            AND ((poi.ItemId IS NOT NULL AND gi.ItemId = poi.ItemId)
              OR (poi.MedicineId IS NOT NULL AND gi.MedicineId = poi.MedicineId)
              OR (poi.SubServiceId IS NOT NULL AND gi.SubServiceId = poi.SubServiceId))
    ) received
    WHERE poi.PurchaseOrderId = @PurchaseOrderId AND poi.IsActive = 1
    ORDER BY poi.Id;
END
GO

IF OBJECT_ID('dbo.GRN_GetLookupData', 'P') IS NOT NULL
    DROP PROCEDURE dbo.GRN_GetLookupData;
GO

CREATE PROCEDURE dbo.GRN_GetLookupData
AS
BEGIN
    SET NOCOUNT ON;

    -- Vendors
    SELECT Id, Name
    FROM Inv.Vendors
    WHERE IsActive = 1
    ORDER BY Name;

    -- Stock Types
    SELECT Id, Name
    FROM Inv.StockTypes
    WHERE IsActive = 1
    ORDER BY Name;

    -- Manufacturers
    SELECT Id, Name
    FROM Inv.PharmacyManufacturers
    WHERE IsActive = 1
    ORDER BY Name;

    -- Purchase Orders available to receive against
    SELECT po.PurchaseOrderId AS Id, po.PONumber, v.Name AS VendorName
    FROM Inv.PurchaseOrders po
    LEFT JOIN Inv.Vendors v ON v.Id = po.VendorId
    WHERE po.IsActive = 1
    ORDER BY po.CreatedOn DESC;
END
GO

PRINT 'GRN stock-effect and PO-details procedures updated successfully.';
