-- =============================================
-- Get all GRNs (Goods Receiving Notes)
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GRN_GetAll')
    DROP PROCEDURE [dbo].[GRN_GetAll]
GO

CREATE PROCEDURE [dbo].[GRN_GetAll]
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        g.Id,
        g.PurchaseOrderId,
        g.PONumber,
        g.InvoiceNo,
        g.StockTypeId,
        st.Name as StockTypeName,
        g.VendorId,
        v.Name as VendorName,
        g.DateAndTime,
        g.IsActive,
        g.CreatedOn
    FROM Inv.GoodsReceivingNotes g
    LEFT JOIN Inv.Vendors v ON g.VendorId = v.Id
    LEFT JOIN Inv.StockTypes st ON g.StockTypeId = st.Id
    WHERE g.IsActive = 1
    ORDER BY g.CreatedOn DESC;
END
GO

-- =============================================
-- Get GRN by ID with items
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GRN_GetById')
    DROP PROCEDURE [dbo].[GRN_GetById]
GO

CREATE PROCEDURE [dbo].[GRN_GetById]
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Get header
    SELECT 
        g.Id,
        g.PurchaseOrderId,
        g.PONumber,
        g.VendorId,
        v.Name as VendorName,
        g.InvoiceNo,
        g.StockTypeId,
        st.Name as StockTypeName,
        g.DateAndTime,
        g.VendorInvoiceNo,
        g.VendorInvoiceDate,
        g.IsActive,
        g.CreatedById,
        g.CreatedOn,
        g.ModifiedById,
        g.ModifiedOn
    FROM Inv.GoodsReceivingNotes g
    LEFT JOIN Inv.Vendors v ON g.VendorId = v.Id
    LEFT JOIN Inv.StockTypes st ON g.StockTypeId = st.Id
    WHERE g.Id = @Id;
    
    -- Get items
    SELECT
        gi.Id,
        gi.GRNId,
        gi.ItemId,
        gi.MedicineId,
        gi.SubServiceId,
        COALESCE(i.Name, med.MedicineFullName, f.Name) as ItemName,
        gi.ManufacturerId,
        m.Name as ManufacturerName,
        gi.MfgDate,
        gi.ExpiryDate,
        gi.RegistrationNumber,
        gi.LotNo,
        gi.BatchNo,
        gi.NoOfBoxes,
        gi.NoOfPackets,
        gi.ItemPerPacket,
        gi.TotalItem,
        gi.PackQuantity,
        gi.ReceivedQuantity,
        gi.RemainingQuantity,
        gi.TotalBuyingPrice,
        gi.UnitBuyingPrice,
        gi.AdvanceTaxPercentage,
        gi.AdvanceTaxAmount,
        gi.Discount,
        gi.DiscountAmount,
        gi.RetailCharges,
        gi.RetailChargesAmount,
        gi.GSTCharges,
        gi.GSTChargesAmount,
        gi.UnitSellingPrice,
        gi.TotalSellingPrice,
        gi.ProfitMarginPerItem,
        gi.ProfitPerItem
    FROM Inv.GRNItems gi
    LEFT JOIN Inv.Items i ON gi.ItemId = i.Id
    LEFT JOIN Pharmacy.Medicines med ON gi.MedicineId = med.MedicineId
    LEFT JOIN Account.Fees f ON gi.SubServiceId = f.Id
    LEFT JOIN Inv.Manufacturers m ON gi.ManufacturerId = m.Id
    WHERE gi.GRNId = @Id;
END
GO

-- =============================================
-- Insert GRN with items
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GRN_Insert')
    DROP PROCEDURE [dbo].[GRN_Insert]
GO

CREATE PROCEDURE [dbo].[GRN_Insert]
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
        PONumber, VendorId, InvoiceNo, StockTypeId,
        DateAndTime, VendorInvoiceNo, VendorInvoiceDate,
        IsActive, CreatedById, CreatedOn
    )
    VALUES (
        @PONumber, @VendorId, @InvoiceNo, @StockTypeId,
        ISNULL(@DateAndTime, GETDATE()), @VendorInvoiceNo, @VendorInvoiceDate,
        1, @CreatedById, GETDATE()
    );
    
    SELECT SCOPE_IDENTITY() as Id;
END
GO

-- =============================================
-- Insert GRN item
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GRNItem_Insert')
    DROP PROCEDURE [dbo].[GRNItem_Insert]
GO

CREATE PROCEDURE [dbo].[GRNItem_Insert]
    @GRNId INT,
    @ItemId INT,
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
    
    INSERT INTO Inv.GRNItems (
        GRNId, ItemId, ManufacturerId, MfgDate, ExpiryDate,
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
        @GRNId, @ItemId, @ManufacturerId, @MfgDate, @ExpiryDate,
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
    
    SELECT SCOPE_IDENTITY() as Id;
END
GO

-- =============================================
-- Update GRN header
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GRN_Update')
    DROP PROCEDURE [dbo].[GRN_Update]
GO

CREATE PROCEDURE [dbo].[GRN_Update]
    @Id INT,
    @InvoiceNo NVARCHAR(100) = NULL,
    @PONumber NVARCHAR(100) = NULL,
    @StockTypeId INT = NULL,
    @DateAndTime DATETIME = NULL,
    @VendorInvoiceNo NVARCHAR(100) = NULL,
    @VendorInvoiceDate DATETIME = NULL,
    @ModifiedById INT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE Inv.GoodsReceivingNotes
    SET 
        InvoiceNo = @InvoiceNo,
        PONumber = @PONumber,
        StockTypeId = @StockTypeId,
        DateAndTime = @DateAndTime,
        VendorInvoiceNo = @VendorInvoiceNo,
        VendorInvoiceDate = @VendorInvoiceDate,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETDATE()
    WHERE Id = @Id;
    
    SELECT @@ROWCOUNT as AffectedRows;
END
GO

-- =============================================
-- Delete GRN (soft delete)
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GRN_Delete')
    DROP PROCEDURE [dbo].[GRN_Delete]
GO

CREATE PROCEDURE [dbo].[GRN_Delete]
    @Id INT,
    @ModifiedById INT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE Inv.GoodsReceivingNotes
    SET 
        IsActive = 0,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETDATE()
    WHERE Id = @Id;
    
    SELECT @@ROWCOUNT as AffectedRows;
END
GO

-- =============================================
-- Get lookup data for GRN dropdowns
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GRN_GetLookupData')
    DROP PROCEDURE [dbo].[GRN_GetLookupData]
GO

CREATE PROCEDURE [dbo].[GRN_GetLookupData]
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
    FROM Inv.Manufacturers 
    WHERE IsActive = 1 
    ORDER BY Name;
END
GO
