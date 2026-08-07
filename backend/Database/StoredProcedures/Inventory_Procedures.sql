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
        st.Name as StockTypeName,
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
        (SELECT ISNULL(SUM(TotalItems), 0) FROM Inv.InventoryDetails WHERE InventoryId = i.Id) as TotalQuantity
    FROM Inv.Inventories i
    LEFT JOIN Inv.Vendors v ON i.VendorId = v.Id
    LEFT JOIN Inv.PharmacyStores s ON i.StoreId = s.StoreId
    LEFT JOIN Inv.Branches b ON i.BranchId = b.Id
    LEFT JOIN Inv.StockTypes st ON i.StockTypeId = st.Id
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
        st.Name as StockTypeName,
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
        (SELECT ISNULL(SUM(TotalItems), 0) FROM Inv.InventoryDetails WHERE InventoryId = i.Id) as TotalQuantity
    FROM Inv.Inventories i
    LEFT JOIN Inv.Vendors v ON i.VendorId = v.Id
    LEFT JOIN Inv.PharmacyStores s ON i.StoreId = s.StoreId
    LEFT JOIN Inv.Branches b ON i.BranchId = b.Id
    LEFT JOIN Inv.StockTypes st ON i.StockTypeId = st.Id
    WHERE i.Id = @Id;
    
    -- Get details
    SELECT
        id.Id,
        id.InventoryId,
        id.ItemId,
        id.MedicineId,
        id.SubServiceId,
        COALESCE(it.Name, med.MedicineFullName, f.Name) as ItemName,
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
    FROM Inv.InventoryDetails id
    LEFT JOIN Inv.Items it ON id.ItemId = it.Id
    LEFT JOIN Pharmacy.Medicines med ON id.MedicineId = med.MedicineId
    LEFT JOIN Account.Fees f ON id.SubServiceId = f.Id
    LEFT JOIN Inv.Manufacturers m ON id.ManufacturerId = m.Id
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
    
    INSERT INTO Inv.Inventories (
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
    
    UPDATE Inv.Inventories
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

-- Inventory_Delete / InventoryDetail_Insert / InventoryDetail_Update /
-- InventoryDetail_Delete are
-- defined in InventoryDetail_StockEffect_Live.sql, not here - that version
-- also credits/reverses the live stock ledger (which these never did) and supports
-- MedicineId/SubServiceId. Do not redefine them in this file: alphabetically
-- "Inventory_Procedures.sql" sorts AFTER "InventoryDetail_StockEffect_Live.sql"
-- and would silently overwrite the correct version on a fresh deploy.

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
    SELECT Id, Name FROM Inv.Vendors WHERE IsActive = 1 ORDER BY Name;
    
    -- Stores
    SELECT StoreId as Id, StoreName as Name FROM Inv.PharmacyStores WHERE IsActive = 1 ORDER BY StoreName;
    
    -- Stock Types
    SELECT Id, Name FROM Inv.StockTypes WHERE IsActive = 1 ORDER BY Name;
    
    -- Items
    SELECT Id, Name FROM Inv.Items WHERE IsActive = 1 ORDER BY Name;
    
    -- Manufacturers
    SELECT Id, Name FROM Inv.Manufacturers WHERE IsActive = 1 ORDER BY Name;
    
    -- Branches
    SELECT Id, Name FROM Inv.Branches WHERE IsActive = 1 ORDER BY Name;
    
    -- Categories
    SELECT Id, Name FROM Inv.Categories WHERE IsActive = 1 ORDER BY Name;
    
    -- Brands
    SELECT Id, Name FROM Data.Brands WHERE IsActive = 1 ORDER BY Name;
END
GO
