-- =============================================
-- Get all inventories with details
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'Inventory_GetAll')
    DROP PROCEDURE [dbo].[Inventory_GetAll]
GO

CREATE PROCEDURE [dbo].[Inventory_GetAll]
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        i.Id,
        i.PurchaseOrderNumber,
        i.InvoiceNo,
        i.PurchaseOrderId,
        i.VendorId,
        v.Name as VendorName,
        i.StoreId,
        s.StoreName,
        i.BranchId,
        b.Name as BranchName,
        i.IsActive,
        i.CreatedById,
        i.CreatedOn,
        i.ModifiedById,
        i.ModifiedOn,
        i.IsFinalized,
        i.StockTypeId,
        st.StockTypeName,
        i.VendorInvoiceNumber,
        i.VendorInvoiceTimestamp,
        i.Amount,
        i.Discount,
        i.DiscountType,
        i.Total,
        i.PaidAmount,
        i.PaymentStatusId,
        i.TotalPaidAmount,
        i.PayableAccountId,
        i.IsPaymentPending,
        i.VoucherId,
        i.TotalVoucherPaidAmount,
        i.TotalBuyingPrice,
        i.ReceiptPath,
        i.AdvanceTaxPercentage,
        i.AdvanceTaxCalculatedAmount,
        i.RetailCharges,
        i.RetailChargesType,
        i.GSTCharges,
        i.RetailChargesCalculatedAmount,
        i.GSTChargesCalculatedAmount,
        i.ManualPurchaseOrderNumber,
        -- Calculate total quantity from details
        (SELECT ISNULL(SUM(TotalItems), 0) FROM InventoryDetails WHERE InventoryId = i.Id) as TotalQuantity
    FROM dbo.Inventories i
    LEFT JOIN dbo.Vendors v ON i.VendorId = v.Id
    LEFT JOIN dbo.Stores s ON i.StoreId = s.StoreId
    LEFT JOIN dbo.Branches b ON i.BranchId = b.Id
    LEFT JOIN dbo.StockTypes st ON i.StockTypeId = st.StockTypeId
    WHERE i.IsActive = 1
    ORDER BY i.CreatedOn DESC;
END
GO

-- =============================================
-- Get inventory by ID with details
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'Inventory_GetById')
    DROP PROCEDURE [dbo].[Inventory_GetById]
GO

CREATE PROCEDURE [dbo].[Inventory_GetById]
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Get header
    SELECT 
        i.Id,
        i.PurchaseOrderNumber,
        i.InvoiceNo,
        i.PurchaseOrderId,
        i.VendorId,
        v.Name as VendorName,
        i.StoreId,
        s.StoreName,
        i.BranchId,
        b.Name as BranchName,
        i.IsActive,
        i.CreatedById,
        i.CreatedOn,
        i.ModifiedById,
        i.ModifiedOn,
        i.IsFinalized,
        i.StockTypeId,
        st.StockTypeName,
        i.VendorInvoiceNumber,
        i.VendorInvoiceTimestamp,
        i.Amount,
        i.Discount,
        i.DiscountType,
        i.Total,
        i.PaidAmount,
        i.PaymentStatusId,
        i.TotalPaidAmount,
        i.PayableAccountId,
        i.IsPaymentPending,
        i.VoucherId,
        i.TotalVoucherPaidAmount,
        i.TotalBuyingPrice,
        i.ReceiptPath,
        i.AdvanceTaxPercentage,
        i.AdvanceTaxCalculatedAmount,
        i.RetailCharges,
        i.RetailChargesType,
        i.GSTCharges,
        i.RetailChargesCalculatedAmount,
        i.GSTChargesCalculatedAmount,
        i.ManualPurchaseOrderNumber,
        -- Calculate total quantity from details
        (SELECT ISNULL(SUM(TotalItems), 0) FROM InventoryDetails WHERE InventoryId = i.Id) as TotalQuantity
    FROM dbo.Inventories i
    LEFT JOIN dbo.Vendors v ON i.VendorId = v.Id
    LEFT JOIN dbo.Stores s ON i.StoreId = s.StoreId
    LEFT JOIN dbo.Branches b ON i.BranchId = b.Id
    LEFT JOIN dbo.StockTypes st ON i.StockTypeId = st.StockTypeId
    WHERE i.Id = @Id;
    
    -- Get details
    SELECT 
        id.Id,
        id.InventoryId,
        id.ItemId,
        it.Name as ItemName,
        id.ManufacturerId,
        m.Name as ManufacturerName,
        id.MfgDate,
        id.ExpiryDate,
        id.NoOfBoxes,
        id.NoOfPackets,
        id.ItemsPerPacket,
        id.TotalItems,
        id.PackQuantity,
        id.UnitBuyingPrice,
        id.TotalBuyingPrice,
        id.AdvanceTaxPercentage,
        id.AdvanceTaxAmount,
        id.Discount,
        id.DiscountAmount,
        id.RetailCharges,
        id.RetailChargesAmount,
        id.GSTCharges,
        id.GSTChargesAmount,
        id.UnitSellingPrice,
        id.TotalSellingPrice,
        id.ProfitMarginPerItem,
        id.ProfitPerItem
    FROM dbo.InventoryDetails id
    LEFT JOIN dbo.Items it ON id.ItemId = it.Id
    LEFT JOIN dbo.Manufacturers m ON id.ManufacturerId = m.Id
    WHERE id.InventoryId = @Id;
END
GO

-- =============================================
-- Insert inventory with details
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'Inventory_Insert')
    DROP PROCEDURE [dbo].[Inventory_Insert]
GO

CREATE PROCEDURE [dbo].[Inventory_Insert]
    @VendorId INT,
    @StoreId INT,
    @BranchId INT,
    @StockTypeId INT,
    @VendorInvoiceNumber NVARCHAR(MAX),
    @VendorInvoiceTimestamp DATETIME,
    @ManualPurchaseOrderNumber NVARCHAR(MAX) = NULL,
    @CreatedById INT
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO dbo.Inventories (
        VendorId, StoreId, BranchId, StockTypeId,
        VendorInvoiceNumber, VendorInvoiceTimestamp,
        ManualPurchaseOrderNumber,
        IsActive, CreatedById, CreatedOn,
        IsFinalized, IsPaymentPending,
        Amount, Total, TotalBuyingPrice
    )
    VALUES (
        @VendorId, @StoreId, @BranchId, @StockTypeId,
        @VendorInvoiceNumber, @VendorInvoiceTimestamp,
        @ManualPurchaseOrderNumber,
        1, @CreatedById, GETDATE(),
        0, 1,
        0, 0, 0
    );
    
    SELECT SCOPE_IDENTITY() as Id;
END
GO

-- =============================================
-- Update inventory header
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'Inventory_Update')
    DROP PROCEDURE [dbo].[Inventory_Update]
GO

CREATE PROCEDURE [dbo].[Inventory_Update]
    @Id INT,
    @VendorId INT,
    @StoreId INT,
    @BranchId INT,
    @StockTypeId INT,
    @VendorInvoiceNumber NVARCHAR(MAX),
    @VendorInvoiceTimestamp DATETIME,
    @ManualPurchaseOrderNumber NVARCHAR(MAX) = NULL,
    @Amount REAL = NULL,
    @Discount REAL = NULL,
    @DiscountType INT = NULL,
    @Total REAL = NULL,
    @AdvanceTaxPercentage REAL = NULL,
    @AdvanceTaxCalculatedAmount REAL = NULL,
    @RetailCharges REAL = NULL,
    @RetailChargesType INT = NULL,
    @GSTCharges REAL = NULL,
    @RetailChargesCalculatedAmount REAL = NULL,
    @GSTChargesCalculatedAmount REAL = NULL,
    @TotalBuyingPrice REAL = NULL,
    @ModifiedById INT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE dbo.Inventories
    SET 
        VendorId = @VendorId,
        StoreId = @StoreId,
        BranchId = @BranchId,
        StockTypeId = @StockTypeId,
        VendorInvoiceNumber = @VendorInvoiceNumber,
        VendorInvoiceTimestamp = @VendorInvoiceTimestamp,
        ManualPurchaseOrderNumber = @ManualPurchaseOrderNumber,
        Amount = ISNULL(@Amount, Amount),
        Discount = @Discount,
        DiscountType = @DiscountType,
        Total = ISNULL(@Total, Total),
        AdvanceTaxPercentage = @AdvanceTaxPercentage,
        AdvanceTaxCalculatedAmount = @AdvanceTaxCalculatedAmount,
        RetailCharges = @RetailCharges,
        RetailChargesType = @RetailChargesType,
        GSTCharges = @GSTCharges,
        RetailChargesCalculatedAmount = @RetailChargesCalculatedAmount,
        GSTChargesCalculatedAmount = @GSTChargesCalculatedAmount,
        TotalBuyingPrice = ISNULL(@TotalBuyingPrice, TotalBuyingPrice),
        ModifiedById = @ModifiedById,
        ModifiedOn = GETDATE()
    WHERE Id = @Id;
    
    SELECT @@ROWCOUNT as AffectedRows;
END
GO

-- =============================================
-- Delete inventory (soft delete)
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'Inventory_Delete')
    DROP PROCEDURE [dbo].[Inventory_Delete]
GO

CREATE PROCEDURE [dbo].[Inventory_Delete]
    @Id INT,
    @ModifiedById INT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE dbo.Inventories
    SET 
        IsActive = 0,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETDATE()
    WHERE Id = @Id;
    
    SELECT @@ROWCOUNT as AffectedRows;
END
GO

-- =============================================
-- Insert inventory detail item
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'InventoryDetail_Insert')
    DROP PROCEDURE [dbo].[InventoryDetail_Insert]
GO

CREATE PROCEDURE [dbo].[InventoryDetail_Insert]
    @InventoryId INT,
    @ItemId INT,
    @ManufacturerId INT = NULL,
    @MfgDate DATETIME = NULL,
    @ExpiryDate DATETIME = NULL,
    @NoOfBoxes INT = NULL,
    @NoOfPackets INT = NULL,
    @ItemsPerPacket INT = NULL,
    @TotalItems INT = NULL,
    @PackQuantity INT = NULL,
    @UnitBuyingPrice REAL = NULL,
    @TotalBuyingPrice REAL = NULL,
    @AdvanceTaxPercentage REAL = NULL,
    @AdvanceTaxAmount REAL = NULL,
    @Discount BIT = NULL,
    @DiscountAmount REAL = NULL,
    @RetailCharges BIT = NULL,
    @RetailChargesAmount REAL = NULL,
    @GSTCharges BIT = NULL,
    @GSTChargesAmount REAL = NULL,
    @UnitSellingPrice REAL = NULL,
    @TotalSellingPrice REAL = NULL,
    @ProfitMarginPerItem REAL = NULL,
    @ProfitPerItem REAL = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO dbo.InventoryDetails (
        InventoryId, ItemId, ManufacturerId, MfgDate, ExpiryDate,
        NoOfBoxes, NoOfPackets, ItemsPerPacket, TotalItems, PackQuantity,
        UnitBuyingPrice, TotalBuyingPrice, AdvanceTaxPercentage, AdvanceTaxAmount,
        Discount, DiscountAmount, RetailCharges, RetailChargesAmount,
        GSTCharges, GSTChargesAmount, UnitSellingPrice, TotalSellingPrice,
        ProfitMarginPerItem, ProfitPerItem
    )
    VALUES (
        @InventoryId, @ItemId, @ManufacturerId, @MfgDate, @ExpiryDate,
        @NoOfBoxes, @NoOfPackets, @ItemsPerPacket, @TotalItems, @PackQuantity,
        @UnitBuyingPrice, @TotalBuyingPrice, @AdvanceTaxPercentage, @AdvanceTaxAmount,
        @Discount, @DiscountAmount, @RetailCharges, @RetailChargesAmount,
        @GSTCharges, @GSTChargesAmount, @UnitSellingPrice, @TotalSellingPrice,
        @ProfitMarginPerItem, @ProfitPerItem
    );
    
    SELECT SCOPE_IDENTITY() as Id;
END
GO

-- =============================================
-- Update inventory detail item
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'InventoryDetail_Update')
    DROP PROCEDURE [dbo].[InventoryDetail_Update]
GO

CREATE PROCEDURE [dbo].[InventoryDetail_Update]
    @Id INT,
    @ItemId INT,
    @ManufacturerId INT = NULL,
    @MfgDate DATETIME = NULL,
    @ExpiryDate DATETIME = NULL,
    @NoOfBoxes INT = NULL,
    @NoOfPackets INT = NULL,
    @ItemsPerPacket INT = NULL,
    @TotalItems INT = NULL,
    @PackQuantity INT = NULL,
    @UnitBuyingPrice REAL = NULL,
    @TotalBuyingPrice REAL = NULL,
    @AdvanceTaxPercentage REAL = NULL,
    @AdvanceTaxAmount REAL = NULL,
    @Discount BIT = NULL,
    @DiscountAmount REAL = NULL,
    @RetailCharges BIT = NULL,
    @RetailChargesAmount REAL = NULL,
    @GSTCharges BIT = NULL,
    @GSTChargesAmount REAL = NULL,
    @UnitSellingPrice REAL = NULL,
    @TotalSellingPrice REAL = NULL,
    @ProfitMarginPerItem REAL = NULL,
    @ProfitPerItem REAL = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE dbo.InventoryDetails
    SET 
        ItemId = @ItemId,
        ManufacturerId = @ManufacturerId,
        MfgDate = @MfgDate,
        ExpiryDate = @ExpiryDate,
        NoOfBoxes = @NoOfBoxes,
        NoOfPackets = @NoOfPackets,
        ItemsPerPacket = @ItemsPerPacket,
        TotalItems = @TotalItems,
        PackQuantity = @PackQuantity,
        UnitBuyingPrice = @UnitBuyingPrice,
        TotalBuyingPrice = @TotalBuyingPrice,
        AdvanceTaxPercentage = @AdvanceTaxPercentage,
        AdvanceTaxAmount = @AdvanceTaxAmount,
        Discount = @Discount,
        DiscountAmount = @DiscountAmount,
        RetailCharges = @RetailCharges,
        RetailChargesAmount = @RetailChargesAmount,
        GSTCharges = @GSTCharges,
        GSTChargesAmount = @GSTChargesAmount,
        UnitSellingPrice = @UnitSellingPrice,
        TotalSellingPrice = @TotalSellingPrice,
        ProfitMarginPerItem = @ProfitMarginPerItem,
        ProfitPerItem = @ProfitPerItem
    WHERE Id = @Id;
    
    SELECT @@ROWCOUNT as AffectedRows;
END
GO

-- =============================================
-- Delete inventory detail item
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'InventoryDetail_Delete')
    DROP PROCEDURE [dbo].[InventoryDetail_Delete]
GO

CREATE PROCEDURE [dbo].[InventoryDetail_Delete]
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DELETE FROM dbo.InventoryDetails
    WHERE Id = @Id;
    
    SELECT @@ROWCOUNT as AffectedRows;
END
GO

-- =============================================
-- Get lookup data for dropdowns
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'Inventory_GetLookupData')
    DROP PROCEDURE [dbo].[Inventory_GetLookupData]
GO

CREATE PROCEDURE [dbo].[Inventory_GetLookupData]
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Vendors
    SELECT Id, Name FROM dbo.Vendors WHERE IsActive = 1 ORDER BY Name;
    
    -- Stores
    SELECT StoreId as Id, StoreName as Name FROM dbo.Stores WHERE IsActive = 1 ORDER BY StoreName;
    
    -- Stock Types
    SELECT StockTypeId as Id, StockTypeName as Name FROM dbo.StockTypes WHERE IsActive = 1 ORDER BY StockTypeName;
    
    -- Items
    SELECT Id, Name FROM dbo.Items WHERE IsActive = 1 ORDER BY Name;
    
    -- Manufacturers
    SELECT Id, Name FROM dbo.Manufacturers WHERE IsActive = 1 ORDER BY Name;
    
    -- Branches
    SELECT Id, Name FROM dbo.Branches WHERE IsActive = 1 ORDER BY Name;
END
GO
