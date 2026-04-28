SET NOCOUNT ON;

DECLARE @BranchId INT = COALESCE((SELECT TOP 1 Id FROM Inv.Branches WHERE IsActive = 1 ORDER BY Id), 1);
DECLARE @CreatedById INT = COALESCE((SELECT TOP 1 UserID FROM dbo.Users ORDER BY UserID), 1);
DECLARE @DepartmentId INT = (SELECT TOP 1 Id FROM Inv.Departments ORDER BY Id);
DECLARE @SubDepartmentId INT = (SELECT TOP 1 Id FROM Inv.SubDepartments WHERE DepartmentId = @DepartmentId ORDER BY Id);
DECLARE @RoomId INT = (SELECT TOP 1 Id FROM Inv.Rooms ORDER BY Id);

DECLARE @MedicineStoreId INT = COALESCE((SELECT TOP 1 StoreId FROM Inv.Stores WHERE StoreName = 'Medicine Store' ORDER BY StoreId), (SELECT TOP 1 StoreId FROM Inv.Stores WHERE IsActive = 1 ORDER BY StoreId));
DECLARE @DisposableStoreId INT = COALESCE((SELECT TOP 1 StoreId FROM Inv.Stores WHERE StoreName = 'Main Disposable Store' ORDER BY StoreId), (SELECT TOP 1 StoreId FROM Inv.Stores WHERE IsActive = 1 AND StoreId <> @MedicineStoreId ORDER BY StoreId));
DECLARE @EmergencyStoreId INT = COALESCE((SELECT TOP 1 StoreId FROM Inv.Stores WHERE StoreName = 'Emergency Store' ORDER BY StoreId), (SELECT TOP 1 StoreId FROM Inv.Stores WHERE IsActive = 1 AND StoreId NOT IN (@MedicineStoreId, @DisposableStoreId) ORDER BY StoreId));
DECLARE @RackStoreId INT = COALESCE(
    (SELECT TOP 1 s.StoreId FROM Inv.Stores s INNER JOIN Pharmacy.PharmacyStores ps ON ps.Id = s.StoreId WHERE s.StoreId = @DisposableStoreId),
    (SELECT TOP 1 s.StoreId FROM Inv.Stores s INNER JOIN Pharmacy.PharmacyStores ps ON ps.Id = s.StoreId WHERE s.StoreId = @EmergencyStoreId),
    (SELECT TOP 1 s.StoreId FROM Inv.Stores s INNER JOIN Pharmacy.PharmacyStores ps ON ps.Id = s.StoreId ORDER BY s.StoreId)
);

DECLARE @RegularStockTypeId INT = COALESCE((SELECT TOP 1 Id FROM Inv.StockTypes WHERE Name = 'Regular' ORDER BY Id), (SELECT TOP 1 Id FROM Inv.StockTypes ORDER BY Id));
DECLARE @DonationStockTypeId INT = COALESCE((SELECT TOP 1 Id FROM Inv.StockTypes WHERE Name = 'Donation' ORDER BY Id), @RegularStockTypeId);
DECLARE @Vendor1Id INT = (SELECT TOP 1 Id FROM Inv.Vendors WHERE IsActive = 1 ORDER BY Id);
DECLARE @Vendor2Id INT = COALESCE((SELECT TOP 1 Id FROM Inv.Vendors WHERE IsActive = 1 AND Id <> @Vendor1Id ORDER BY Id), @Vendor1Id);
DECLARE @Manufacturer1Id INT = (SELECT TOP 1 Id FROM Inv.Manufacturers ORDER BY Id);
DECLARE @Manufacturer2Id INT = COALESCE((SELECT TOP 1 Id FROM Inv.Manufacturers WHERE Id <> @Manufacturer1Id ORDER BY Id), @Manufacturer1Id);
DECLARE @Brand1Id INT = (SELECT TOP 1 Id FROM Inv.Brands WHERE IsActive = 1 ORDER BY Id);
DECLARE @Brand2Id INT = COALESCE((SELECT TOP 1 Id FROM Inv.Brands WHERE IsActive = 1 AND Id <> @Brand1Id ORDER BY Id), @Brand1Id);
DECLARE @ItemType1Id INT = (SELECT TOP 1 Id FROM Inv.ItemTypes ORDER BY Id);
DECLARE @ItemType2Id INT = COALESCE((SELECT TOP 1 Id FROM Inv.ItemTypes WHERE Id <> @ItemType1Id ORDER BY Id), @ItemType1Id);
DECLARE @UnitId INT = (SELECT TOP 1 Id FROM Inv.ItemUnits ORDER BY Id);
DECLARE @PackingId INT = (SELECT TOP 1 Id FROM Inv.Packings ORDER BY Id);
DECLARE @CategoryId INT = (SELECT TOP 1 Id FROM Inv.Categories ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM Inv.PurchaseOrderTypes WHERE Name = 'Local Purchase')
BEGIN
    INSERT INTO Inv.PurchaseOrderTypes (Name, Description, IsActive, CreatedById, CreatedOn)
    VALUES ('Local Purchase', 'Seeded HMS local purchase type', 1, 'seed', GETDATE());
END;

IF NOT EXISTS (SELECT 1 FROM Inv.PurchaseOrderTypes WHERE Name = 'Emergency Purchase')
BEGIN
    INSERT INTO Inv.PurchaseOrderTypes (Name, Description, IsActive, CreatedById, CreatedOn)
    VALUES ('Emergency Purchase', 'Seeded HMS emergency purchase type', 1, 'seed', GETDATE());
END;

IF NOT EXISTS (SELECT 1 FROM Inv.DemandRequestStatuses WHERE Name = 'Pending')
BEGIN
    INSERT INTO Inv.DemandRequestStatuses (Name, Description, BranchId, IsActive, CreatedById, CreatedOn, ModifiedOn, Value)
    VALUES ('Pending', 'Seeded pending status', @BranchId, 1, @CreatedById, GETDATE(), GETDATE(), 1);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.DemandRequestStatuses WHERE Name = 'Approved')
BEGIN
    INSERT INTO Inv.DemandRequestStatuses (Name, Description, BranchId, IsActive, CreatedById, CreatedOn, ModifiedOn, Value)
    VALUES ('Approved', 'Seeded approved status', @BranchId, 1, @CreatedById, GETDATE(), GETDATE(), 2);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.DemandRequestStatuses WHERE Name = 'Issued')
BEGIN
    INSERT INTO Inv.DemandRequestStatuses (Name, Description, BranchId, IsActive, CreatedById, CreatedOn, ModifiedOn, Value)
    VALUES ('Issued', 'Seeded issued status', @BranchId, 1, @CreatedById, GETDATE(), GETDATE(), 3);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.DemandRequestStatuses WHERE Name = 'Received')
BEGIN
    INSERT INTO Inv.DemandRequestStatuses (Name, Description, BranchId, IsActive, CreatedById, CreatedOn, ModifiedOn, Value)
    VALUES ('Received', 'Seeded received status', @BranchId, 1, @CreatedById, GETDATE(), GETDATE(), 4);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.ItemTypeSaleLevels WHERE ItemTypeId = @ItemType1Id)
BEGIN
    INSERT INTO Inv.ItemTypeSaleLevels (ItemTypeId, FastRunningLevel, SlowMovingLevel, DeadLevel, BranchId, IsActive, CreatedById, CreatedOn)
    VALUES (@ItemType1Id, 80, 40, 10, @BranchId, 1, @CreatedById, GETDATE());
END;

IF NOT EXISTS (SELECT 1 FROM Inv.ItemTypeSaleLevels WHERE ItemTypeId = @ItemType2Id)
BEGIN
    INSERT INTO Inv.ItemTypeSaleLevels (ItemTypeId, FastRunningLevel, SlowMovingLevel, DeadLevel, BranchId, IsActive, CreatedById, CreatedOn)
    VALUES (@ItemType2Id, 50, 25, 5, @BranchId, 1, @CreatedById, GETDATE());
END;

IF NOT EXISTS (SELECT 1 FROM Inv.Items WHERE Name = 'HMS Seed Syringe 10ml')
BEGIN
    INSERT INTO Inv.Items (Name, Description, ItemTypeId, BrandId, CategoryId, PackingId, UnitId, BranchId, IsActive, CreatedById, CreatedOn, ModifiedOn, IsProduct, BatchExpiryRequired, Conversion, CaseContains, RetailPrice, SalePrice, CostMethod, Preference, MinimumPanicLevel, IsExpensiveItem, IsFridgeItem, Code, MarketPrice, QuantityPerPacket)
    VALUES ('HMS Seed Syringe 10ml', 'Seed disposable syringe for HMS testing', @ItemType1Id, @Brand1Id, @CategoryId, @PackingId, @UnitId, @BranchId, 1, @CreatedById, GETDATE(), GETDATE(), 1, 1, 1, 10, 12, 10, 0, 0, 25, 0, 0, 'HMS-SYR-10', 11, 10);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.Items WHERE Name = 'HMS Seed IV Cannula 20G')
BEGIN
    INSERT INTO Inv.Items (Name, Description, ItemTypeId, BrandId, CategoryId, PackingId, UnitId, BranchId, IsActive, CreatedById, CreatedOn, ModifiedOn, IsProduct, BatchExpiryRequired, Conversion, CaseContains, RetailPrice, SalePrice, CostMethod, Preference, MinimumPanicLevel, IsExpensiveItem, IsFridgeItem, Code, MarketPrice, QuantityPerPacket)
    VALUES ('HMS Seed IV Cannula 20G', 'Seed IV cannula for HMS testing', @ItemType1Id, @Brand2Id, @CategoryId, @PackingId, @UnitId, @BranchId, 1, @CreatedById, GETDATE(), GETDATE(), 1, 1, 1, 10, 38, 35, 0, 0, 20, 0, 0, 'HMS-CAN-20', 36, 10);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.Items WHERE Name = 'HMS Seed ECG Electrode')
BEGIN
    INSERT INTO Inv.Items (Name, Description, ItemTypeId, BrandId, CategoryId, PackingId, UnitId, BranchId, IsActive, CreatedById, CreatedOn, ModifiedOn, IsProduct, BatchExpiryRequired, Conversion, CaseContains, RetailPrice, SalePrice, CostMethod, Preference, MinimumPanicLevel, IsExpensiveItem, IsFridgeItem, Code, MarketPrice, QuantityPerPacket)
    VALUES ('HMS Seed ECG Electrode', 'Seed ECG electrode for HMS testing', @ItemType2Id, @Brand1Id, @CategoryId, @PackingId, @UnitId, @BranchId, 1, @CreatedById, GETDATE(), GETDATE(), 1, 1, 1, 20, 22, 20, 0, 0, 15, 0, 0, 'HMS-ECG-01', 21, 20);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.Items WHERE Name = 'HMS Seed Test Tube 5ml')
BEGIN
    INSERT INTO Inv.Items (Name, Description, ItemTypeId, BrandId, CategoryId, PackingId, UnitId, BranchId, IsActive, CreatedById, CreatedOn, ModifiedOn, IsProduct, BatchExpiryRequired, Conversion, CaseContains, RetailPrice, SalePrice, CostMethod, Preference, MinimumPanicLevel, IsExpensiveItem, IsFridgeItem, Code, MarketPrice, QuantityPerPacket)
    VALUES ('HMS Seed Test Tube 5ml', 'Seed laboratory tube for HMS testing', @ItemType2Id, @Brand2Id, @CategoryId, @PackingId, @UnitId, @BranchId, 1, @CreatedById, GETDATE(), GETDATE(), 1, 1, 1, 50, 7, 5, 0, 0, 100, 0, 0, 'HMS-TUBE-5', 6, 50);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.Items WHERE Name = 'HMS Seed Vaccine Vial')
BEGIN
    INSERT INTO Inv.Items (Name, Description, ItemTypeId, BrandId, CategoryId, PackingId, UnitId, BranchId, IsActive, CreatedById, CreatedOn, ModifiedOn, IsProduct, BatchExpiryRequired, Conversion, CaseContains, RetailPrice, SalePrice, CostMethod, Preference, MinimumPanicLevel, IsExpensiveItem, IsFridgeItem, Code, MarketPrice, QuantityPerPacket)
    VALUES ('HMS Seed Vaccine Vial', 'Seed fridge-sensitive vial for HMS testing', @ItemType1Id, @Brand1Id, @CategoryId, @PackingId, @UnitId, @BranchId, 1, @CreatedById, GETDATE(), GETDATE(), 1, 1, 1, 1, 165, 150, 0, 0, 8, 1, 1, 'HMS-VAC-01', 155, 1);
END;

DECLARE @SyringeItemId INT = (SELECT TOP 1 Id FROM Inv.Items WHERE Name = 'HMS Seed Syringe 10ml' ORDER BY Id);
DECLARE @CannulaItemId INT = (SELECT TOP 1 Id FROM Inv.Items WHERE Name = 'HMS Seed IV Cannula 20G' ORDER BY Id);
DECLARE @ElectrodeItemId INT = (SELECT TOP 1 Id FROM Inv.Items WHERE Name = 'HMS Seed ECG Electrode' ORDER BY Id);
DECLARE @TubeItemId INT = (SELECT TOP 1 Id FROM Inv.Items WHERE Name = 'HMS Seed Test Tube 5ml' ORDER BY Id);
DECLARE @VaccineItemId INT = (SELECT TOP 1 Id FROM Inv.Items WHERE Name = 'HMS Seed Vaccine Vial' ORDER BY Id);

DECLARE @Po1Id INT;
IF NOT EXISTS (SELECT 1 FROM Inv.PurchaseOrders WHERE PONumber = 'PO-HMS-SEED-001')
BEGIN
    INSERT INTO Inv.PurchaseOrders (PONumber, ManualPONumber, StoreId, VendorId, POValidityDate, Subject, Instructions, TermsAndConditions, Status, TotalQuantity, TotalAmount, IsActive, CreatedById, CreatedOn)
    VALUES ('PO-HMS-SEED-001', 'MPO-HMS-001', @MedicineStoreId, @Vendor1Id, DATEADD(DAY, 14, GETDATE()), 'Seeded medicine replenishment', 'Deliver by next shift', 'Payment after verification', 'Approved', 220, 4860, 1, @CreatedById, DATEADD(DAY, -12, GETDATE()));
    SET @Po1Id = CAST(SCOPE_IDENTITY() AS INT);

    INSERT INTO Inv.PurchaseOrderItems (PurchaseOrderId, ItemId, ItemType, PacketQuantity, UnitQuantity, PacketPrice, UnitPrice, TotalPrice, IsActive, CreatedById, CreatedOn)
    VALUES
        (@Po1Id, @SyringeItemId, 'Disposable', 8, 160, 1600, 10, 1600, 1, @CreatedById, DATEADD(DAY, -12, GETDATE())),
        (@Po1Id, @CannulaItemId, 'Disposable', 3, 60, 2100, 35, 2100, 1, @CreatedById, DATEADD(DAY, -12, GETDATE())),
        (@Po1Id, @VaccineItemId, 'Medicine', 1, 12, 1160, 96.67, 1160, 1, @CreatedById, DATEADD(DAY, -12, GETDATE()));

    INSERT INTO Inv.PurchaseOrderStatus (PurchaseOrderId, Status, Notes, CreatedById, CreatedOn)
    VALUES (@Po1Id, 'Approved', 'Seeded approved purchase order', @CreatedById, DATEADD(DAY, -11, GETDATE()));
END
ELSE
BEGIN
    SET @Po1Id = (SELECT TOP 1 PurchaseOrderId FROM Inv.PurchaseOrders WHERE PONumber = 'PO-HMS-SEED-001' ORDER BY PurchaseOrderId);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.PurchaseOrderItems WHERE PurchaseOrderId = @Po1Id AND ItemId = @SyringeItemId)
BEGIN
    INSERT INTO Inv.PurchaseOrderItems (PurchaseOrderId, ItemId, ItemType, PacketQuantity, UnitQuantity, PacketPrice, UnitPrice, TotalPrice, IsActive, CreatedById, CreatedOn)
    VALUES (@Po1Id, @SyringeItemId, 'Disposable', 8, 160, 1600, 10, 1600, 1, @CreatedById, DATEADD(DAY, -12, GETDATE()));
END;

IF NOT EXISTS (SELECT 1 FROM Inv.PurchaseOrderItems WHERE PurchaseOrderId = @Po1Id AND ItemId = @CannulaItemId)
BEGIN
    INSERT INTO Inv.PurchaseOrderItems (PurchaseOrderId, ItemId, ItemType, PacketQuantity, UnitQuantity, PacketPrice, UnitPrice, TotalPrice, IsActive, CreatedById, CreatedOn)
    VALUES (@Po1Id, @CannulaItemId, 'Disposable', 3, 60, 2100, 35, 2100, 1, @CreatedById, DATEADD(DAY, -12, GETDATE()));
END;

IF NOT EXISTS (SELECT 1 FROM Inv.PurchaseOrderItems WHERE PurchaseOrderId = @Po1Id AND ItemId = @VaccineItemId)
BEGIN
    INSERT INTO Inv.PurchaseOrderItems (PurchaseOrderId, ItemId, ItemType, PacketQuantity, UnitQuantity, PacketPrice, UnitPrice, TotalPrice, IsActive, CreatedById, CreatedOn)
    VALUES (@Po1Id, @VaccineItemId, 'Medicine', 1, 12, 1160, 96.67, 1160, 1, @CreatedById, DATEADD(DAY, -12, GETDATE()));
END;

IF NOT EXISTS (SELECT 1 FROM Inv.PurchaseOrderStatus WHERE PurchaseOrderId = @Po1Id AND Status = 'Approved')
BEGIN
    INSERT INTO Inv.PurchaseOrderStatus (PurchaseOrderId, Status, Notes, CreatedById, CreatedOn)
    VALUES (@Po1Id, 'Approved', 'Seeded approved purchase order', @CreatedById, DATEADD(DAY, -11, GETDATE()));
END;

DECLARE @Po2Id INT;
IF NOT EXISTS (SELECT 1 FROM Inv.PurchaseOrders WHERE PONumber = 'PO-HMS-SEED-002')
BEGIN
    INSERT INTO Inv.PurchaseOrders (PONumber, ManualPONumber, StoreId, VendorId, POValidityDate, Subject, Instructions, TermsAndConditions, Status, TotalQuantity, TotalAmount, IsActive, CreatedById, CreatedOn)
    VALUES ('PO-HMS-SEED-002', 'MPO-HMS-002', @DisposableStoreId, @Vendor2Id, DATEADD(DAY, 10, GETDATE()), 'Seeded disposables and lab order', 'Handle with care', 'Partial delivery allowed', 'Pending', 330, 3760, 1, @CreatedById, DATEADD(DAY, -7, GETDATE()));
    SET @Po2Id = CAST(SCOPE_IDENTITY() AS INT);

    INSERT INTO Inv.PurchaseOrderItems (PurchaseOrderId, ItemId, ItemType, PacketQuantity, UnitQuantity, PacketPrice, UnitPrice, TotalPrice, IsActive, CreatedById, CreatedOn)
    VALUES
        (@Po2Id, @ElectrodeItemId, 'Disposable', 5, 100, 2000, 20, 2000, 1, @CreatedById, DATEADD(DAY, -7, GETDATE())),
        (@Po2Id, @TubeItemId, 'Item', 4, 200, 800, 4, 800, 1, @CreatedById, DATEADD(DAY, -7, GETDATE())),
        (@Po2Id, @SyringeItemId, 'Disposable', 8, 160, 960, 6, 960, 1, @CreatedById, DATEADD(DAY, -7, GETDATE()));

    INSERT INTO Inv.PurchaseOrderStatus (PurchaseOrderId, Status, Notes, CreatedById, CreatedOn)
    VALUES (@Po2Id, 'Pending', 'Seeded pending purchase order', @CreatedById, DATEADD(DAY, -6, GETDATE()));
END
ELSE
BEGIN
    SET @Po2Id = (SELECT TOP 1 PurchaseOrderId FROM Inv.PurchaseOrders WHERE PONumber = 'PO-HMS-SEED-002' ORDER BY PurchaseOrderId);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.PurchaseOrderItems WHERE PurchaseOrderId = @Po2Id AND ItemId = @ElectrodeItemId)
BEGIN
    INSERT INTO Inv.PurchaseOrderItems (PurchaseOrderId, ItemId, ItemType, PacketQuantity, UnitQuantity, PacketPrice, UnitPrice, TotalPrice, IsActive, CreatedById, CreatedOn)
    VALUES (@Po2Id, @ElectrodeItemId, 'Disposable', 5, 100, 2000, 20, 2000, 1, @CreatedById, DATEADD(DAY, -7, GETDATE()));
END;

IF NOT EXISTS (SELECT 1 FROM Inv.PurchaseOrderItems WHERE PurchaseOrderId = @Po2Id AND ItemId = @TubeItemId)
BEGIN
    INSERT INTO Inv.PurchaseOrderItems (PurchaseOrderId, ItemId, ItemType, PacketQuantity, UnitQuantity, PacketPrice, UnitPrice, TotalPrice, IsActive, CreatedById, CreatedOn)
    VALUES (@Po2Id, @TubeItemId, 'Item', 4, 200, 800, 4, 800, 1, @CreatedById, DATEADD(DAY, -7, GETDATE()));
END;

IF NOT EXISTS (SELECT 1 FROM Inv.PurchaseOrderItems WHERE PurchaseOrderId = @Po2Id AND ItemId = @SyringeItemId)
BEGIN
    INSERT INTO Inv.PurchaseOrderItems (PurchaseOrderId, ItemId, ItemType, PacketQuantity, UnitQuantity, PacketPrice, UnitPrice, TotalPrice, IsActive, CreatedById, CreatedOn)
    VALUES (@Po2Id, @SyringeItemId, 'Disposable', 8, 160, 960, 6, 960, 1, @CreatedById, DATEADD(DAY, -7, GETDATE()));
END;

IF NOT EXISTS (SELECT 1 FROM Inv.PurchaseOrderStatus WHERE PurchaseOrderId = @Po2Id AND Status = 'Pending')
BEGIN
    INSERT INTO Inv.PurchaseOrderStatus (PurchaseOrderId, Status, Notes, CreatedById, CreatedOn)
    VALUES (@Po2Id, 'Pending', 'Seeded pending purchase order', @CreatedById, DATEADD(DAY, -6, GETDATE()));
END;

IF NOT EXISTS (SELECT 1 FROM Inv.GoodsReceivingNotes WHERE InvoiceNo = 'GRN-HMS-SEED-001')
BEGIN
    INSERT INTO Inv.GoodsReceivingNotes (PurchaseOrderId, InvoiceNo, PONumber, StockTypeId, DateAndTime, VendorInvoiceNo, VendorInvoiceDate, VendorId, IsActive, CreatedById, CreatedOn)
    VALUES (@Po1Id, 'GRN-HMS-SEED-001', 'PO-HMS-SEED-001', @RegularStockTypeId, DATEADD(DAY, -9, GETDATE()), 'VINV-HMS-001', DATEADD(DAY, -9, GETDATE()), @Vendor1Id, 1, @CreatedById, DATEADD(DAY, -9, GETDATE()));

    DECLARE @Grn1Id INT = CAST(SCOPE_IDENTITY() AS INT);

    INSERT INTO Inv.GRNItems (GRNId, ItemId, ManufacturerId, MfgDate, ExpiryDate, RegistrationNumber, LotNo, BatchNo, NoOfBoxes, NoOfPackets, ItemPerPacket, TotalItem, PackQuantity, ReceivedQuantity, RemainingQuantity, TotalBuyingPrice, UnitBuyingPrice, AdvanceTaxPercentage, AdvanceTaxAmount, Discount, DiscountAmount, RetailCharges, RetailChargesAmount, GSTCharges, GSTChargesAmount, UnitSellingPrice, TotalSellingPrice, ProfitMarginPerItem, ProfitPerItem)
    VALUES
        (@Grn1Id, @SyringeItemId, @Manufacturer1Id, DATEADD(MONTH, -2, GETDATE()), DATEADD(MONTH, 10, GETDATE()), 'REG-HMS-001', 'LOT-HMS-001', 'BATCH-HMS-001', 8, 16, 10, 160, 10, 160, 140, 1600, 10, 0, 0, 0, 0, 0, 0, 0, 0, 12, 1920, 2, 320),
        (@Grn1Id, @CannulaItemId, @Manufacturer2Id, DATEADD(MONTH, -1, GETDATE()), DATEADD(MONTH, 14, GETDATE()), 'REG-HMS-002', 'LOT-HMS-002', 'BATCH-HMS-002', 3, 6, 10, 60, 10, 60, 48, 2100, 35, 0, 0, 0, 0, 0, 0, 0, 0, 38, 2280, 3, 180),
        (@Grn1Id, @VaccineItemId, @Manufacturer1Id, DATEADD(MONTH, -1, GETDATE()), DATEADD(MONTH, 6, GETDATE()), 'REG-HMS-003', 'LOT-HMS-003', 'BATCH-HMS-003', 1, 12, 1, 12, 1, 12, 9, 1160, 96.67, 0, 0, 0, 0, 0, 0, 0, 0, 150, 1800, 53.33, 640);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.GoodsReceivingNotes WHERE InvoiceNo = 'GRN-HMS-SEED-002')
BEGIN
    INSERT INTO Inv.GoodsReceivingNotes (PurchaseOrderId, InvoiceNo, PONumber, StockTypeId, DateAndTime, VendorInvoiceNo, VendorInvoiceDate, VendorId, IsActive, CreatedById, CreatedOn)
    VALUES (@Po2Id, 'GRN-HMS-SEED-002', 'PO-HMS-SEED-002', @DonationStockTypeId, DATEADD(DAY, -4, GETDATE()), 'VINV-HMS-002', DATEADD(DAY, -4, GETDATE()), @Vendor2Id, 1, @CreatedById, DATEADD(DAY, -4, GETDATE()));

    DECLARE @Grn2Id INT = CAST(SCOPE_IDENTITY() AS INT);

    INSERT INTO Inv.GRNItems (GRNId, ItemId, ManufacturerId, MfgDate, ExpiryDate, RegistrationNumber, LotNo, BatchNo, NoOfBoxes, NoOfPackets, ItemPerPacket, TotalItem, PackQuantity, ReceivedQuantity, RemainingQuantity, TotalBuyingPrice, UnitBuyingPrice, AdvanceTaxPercentage, AdvanceTaxAmount, Discount, DiscountAmount, RetailCharges, RetailChargesAmount, GSTCharges, GSTChargesAmount, UnitSellingPrice, TotalSellingPrice, ProfitMarginPerItem, ProfitPerItem)
    VALUES
        (@Grn2Id, @ElectrodeItemId, @Manufacturer1Id, DATEADD(MONTH, -3, GETDATE()), DATEADD(MONTH, 8, GETDATE()), 'REG-HMS-004', 'LOT-HMS-004', 'BATCH-HMS-004', 5, 10, 10, 100, 10, 100, 90, 2000, 20, 0, 0, 0, 0, 0, 0, 0, 0, 22, 2200, 2, 200),
        (@Grn2Id, @TubeItemId, @Manufacturer2Id, DATEADD(MONTH, -1, GETDATE()), DATEADD(MONTH, 18, GETDATE()), 'REG-HMS-005', 'LOT-HMS-005', 'BATCH-HMS-005', 4, 8, 25, 200, 25, 200, 180, 800, 4, 0, 0, 0, 0, 0, 0, 0, 0, 5, 1000, 1, 200);
END;

DECLARE @Grn1IdExisting INT = (SELECT TOP 1 Id FROM Inv.GoodsReceivingNotes WHERE InvoiceNo = 'GRN-HMS-SEED-001' ORDER BY Id);
DECLARE @Grn2IdExisting INT = (SELECT TOP 1 Id FROM Inv.GoodsReceivingNotes WHERE InvoiceNo = 'GRN-HMS-SEED-002' ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM Inv.GRNItems WHERE GRNId = @Grn1IdExisting AND ItemId = @SyringeItemId)
BEGIN
    INSERT INTO Inv.GRNItems (GRNId, ItemId, ManufacturerId, MfgDate, ExpiryDate, RegistrationNumber, LotNo, BatchNo, NoOfBoxes, NoOfPackets, ItemPerPacket, TotalItem, PackQuantity, ReceivedQuantity, RemainingQuantity, TotalBuyingPrice, UnitBuyingPrice, AdvanceTaxPercentage, AdvanceTaxAmount, Discount, DiscountAmount, RetailCharges, RetailChargesAmount, GSTCharges, GSTChargesAmount, UnitSellingPrice, TotalSellingPrice, ProfitMarginPerItem, ProfitPerItem)
    VALUES (@Grn1IdExisting, @SyringeItemId, @Manufacturer1Id, DATEADD(MONTH, -2, GETDATE()), DATEADD(MONTH, 10, GETDATE()), 'REG-HMS-001', 'LOT-HMS-001', 'BATCH-HMS-001', 8, 16, 10, 160, 10, 160, 140, 1600, 10, 0, 0, 0, 0, 0, 0, 0, 0, 12, 1920, 2, 320);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.GRNItems WHERE GRNId = @Grn1IdExisting AND ItemId = @CannulaItemId)
BEGIN
    INSERT INTO Inv.GRNItems (GRNId, ItemId, ManufacturerId, MfgDate, ExpiryDate, RegistrationNumber, LotNo, BatchNo, NoOfBoxes, NoOfPackets, ItemPerPacket, TotalItem, PackQuantity, ReceivedQuantity, RemainingQuantity, TotalBuyingPrice, UnitBuyingPrice, AdvanceTaxPercentage, AdvanceTaxAmount, Discount, DiscountAmount, RetailCharges, RetailChargesAmount, GSTCharges, GSTChargesAmount, UnitSellingPrice, TotalSellingPrice, ProfitMarginPerItem, ProfitPerItem)
    VALUES (@Grn1IdExisting, @CannulaItemId, @Manufacturer2Id, DATEADD(MONTH, -1, GETDATE()), DATEADD(MONTH, 14, GETDATE()), 'REG-HMS-002', 'LOT-HMS-002', 'BATCH-HMS-002', 3, 6, 10, 60, 10, 60, 48, 2100, 35, 0, 0, 0, 0, 0, 0, 0, 0, 38, 2280, 3, 180);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.GRNItems WHERE GRNId = @Grn1IdExisting AND ItemId = @VaccineItemId)
BEGIN
    INSERT INTO Inv.GRNItems (GRNId, ItemId, ManufacturerId, MfgDate, ExpiryDate, RegistrationNumber, LotNo, BatchNo, NoOfBoxes, NoOfPackets, ItemPerPacket, TotalItem, PackQuantity, ReceivedQuantity, RemainingQuantity, TotalBuyingPrice, UnitBuyingPrice, AdvanceTaxPercentage, AdvanceTaxAmount, Discount, DiscountAmount, RetailCharges, RetailChargesAmount, GSTCharges, GSTChargesAmount, UnitSellingPrice, TotalSellingPrice, ProfitMarginPerItem, ProfitPerItem)
    VALUES (@Grn1IdExisting, @VaccineItemId, @Manufacturer1Id, DATEADD(MONTH, -1, GETDATE()), DATEADD(MONTH, 6, GETDATE()), 'REG-HMS-003', 'LOT-HMS-003', 'BATCH-HMS-003', 1, 12, 1, 12, 1, 12, 9, 1160, 96.67, 0, 0, 0, 0, 0, 0, 0, 0, 150, 1800, 53.33, 640);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.GRNItems WHERE GRNId = @Grn2IdExisting AND ItemId = @ElectrodeItemId)
BEGIN
    INSERT INTO Inv.GRNItems (GRNId, ItemId, ManufacturerId, MfgDate, ExpiryDate, RegistrationNumber, LotNo, BatchNo, NoOfBoxes, NoOfPackets, ItemPerPacket, TotalItem, PackQuantity, ReceivedQuantity, RemainingQuantity, TotalBuyingPrice, UnitBuyingPrice, AdvanceTaxPercentage, AdvanceTaxAmount, Discount, DiscountAmount, RetailCharges, RetailChargesAmount, GSTCharges, GSTChargesAmount, UnitSellingPrice, TotalSellingPrice, ProfitMarginPerItem, ProfitPerItem)
    VALUES (@Grn2IdExisting, @ElectrodeItemId, @Manufacturer1Id, DATEADD(MONTH, -3, GETDATE()), DATEADD(MONTH, 8, GETDATE()), 'REG-HMS-004', 'LOT-HMS-004', 'BATCH-HMS-004', 5, 10, 10, 100, 10, 100, 90, 2000, 20, 0, 0, 0, 0, 0, 0, 0, 0, 22, 2200, 2, 200);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.GRNItems WHERE GRNId = @Grn2IdExisting AND ItemId = @TubeItemId)
BEGIN
    INSERT INTO Inv.GRNItems (GRNId, ItemId, ManufacturerId, MfgDate, ExpiryDate, RegistrationNumber, LotNo, BatchNo, NoOfBoxes, NoOfPackets, ItemPerPacket, TotalItem, PackQuantity, ReceivedQuantity, RemainingQuantity, TotalBuyingPrice, UnitBuyingPrice, AdvanceTaxPercentage, AdvanceTaxAmount, Discount, DiscountAmount, RetailCharges, RetailChargesAmount, GSTCharges, GSTChargesAmount, UnitSellingPrice, TotalSellingPrice, ProfitMarginPerItem, ProfitPerItem)
    VALUES (@Grn2IdExisting, @TubeItemId, @Manufacturer2Id, DATEADD(MONTH, -1, GETDATE()), DATEADD(MONTH, 18, GETDATE()), 'REG-HMS-005', 'LOT-HMS-005', 'BATCH-HMS-005', 4, 8, 25, 200, 25, 200, 180, 800, 4, 0, 0, 0, 0, 0, 0, 0, 0, 5, 1000, 1, 200);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.Inventories WHERE InvoiceNo = 'INV-HMS-SEED-001')
BEGIN
    INSERT INTO Inv.Inventories (PurchaseOrderNumber, InvoiceNo, PurchaseOrderId, VendorId, StoreId, BranchId, IsActive, CreatedById, CreatedOn, ModifiedById, ModifiedOn, IsFinalized, StockTypeId, VendorInvoiceNumber, VendorInvoiceTimestamp, Amount, Discount, DiscountType, Total, PaidAmount, IsPaymentPending, TotalBuyingPrice, AdvanceTaxPercentage, AdvanceTaxCalculatedAmount, RetailCharges, RetailChargesCalculatedAmount, GSTCharges, GSTChargesCalculatedAmount, ManualPurchaseOrderNumber)
    VALUES ('PO-HMS-SEED-001', 'INV-HMS-SEED-001', @Po1Id, @Vendor1Id, @MedicineStoreId, @BranchId, 1, @CreatedById, DATEADD(DAY, -9, GETDATE()), @CreatedById, DATEADD(DAY, -9, GETDATE()), 1, @RegularStockTypeId, 'VINV-HMS-001', DATEADD(DAY, -9, GETDATE()), 4860, 0, 0, 4860, 0, 0, 4860, 0, 0, 0, 0, 0, 0, 'MPO-HMS-001');
END;

IF NOT EXISTS (SELECT 1 FROM Inv.Inventories WHERE InvoiceNo = 'INV-HMS-SEED-002')
BEGIN
    INSERT INTO Inv.Inventories (PurchaseOrderNumber, InvoiceNo, PurchaseOrderId, VendorId, StoreId, BranchId, IsActive, CreatedById, CreatedOn, ModifiedById, ModifiedOn, IsFinalized, StockTypeId, VendorInvoiceNumber, VendorInvoiceTimestamp, Amount, Discount, DiscountType, Total, PaidAmount, IsPaymentPending, TotalBuyingPrice, AdvanceTaxPercentage, AdvanceTaxCalculatedAmount, RetailCharges, RetailChargesCalculatedAmount, GSTCharges, GSTChargesCalculatedAmount, ManualPurchaseOrderNumber)
    VALUES ('PO-HMS-SEED-002', 'INV-HMS-SEED-002', @Po2Id, @Vendor2Id, @DisposableStoreId, @BranchId, 1, @CreatedById, DATEADD(DAY, -4, GETDATE()), @CreatedById, DATEADD(DAY, -4, GETDATE()), 1, @DonationStockTypeId, 'VINV-HMS-002', DATEADD(DAY, -4, GETDATE()), 2800, 0, 0, 2800, 0, 0, 2800, 0, 0, 0, 0, 0, 0, 'MPO-HMS-002');
END;

DECLARE @Inventory1Id INT = (SELECT TOP 1 Id FROM Inv.Inventories WHERE InvoiceNo = 'INV-HMS-SEED-001' ORDER BY Id);
DECLARE @Inventory2Id INT = (SELECT TOP 1 Id FROM Inv.Inventories WHERE InvoiceNo = 'INV-HMS-SEED-002' ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM Inv.InventoryDetails WHERE InventoryId = @Inventory1Id AND ItemId = @SyringeItemId)
BEGIN
    INSERT INTO Inv.InventoryDetails (InventoryId, ItemId, ManufacturerId, MfgDate, ExpiryDate, NoOfBoxes, NoOfPackets, ItemsPerPacket, TotalItems, PackQuantity, UnitBuyingPrice, TotalBuyingPrice, AdvanceTaxPercentage, AdvanceTaxAmount, Discount, DiscountAmount, RetailCharges, RetailChargesAmount, GSTCharges, GSTChargesAmount, UnitSellingPrice, TotalSellingPrice, ProfitMarginPerItem, ProfitPerItem)
    VALUES
        (@Inventory1Id, @SyringeItemId, @Manufacturer1Id, DATEADD(MONTH, -2, GETDATE()), DATEADD(MONTH, 10, GETDATE()), 8, 16, 10, 160, 10, 10, 1600, 0, 0, 0, 0, 0, 0, 0, 0, 12, 1920, 2, 320),
        (@Inventory1Id, @CannulaItemId, @Manufacturer2Id, DATEADD(MONTH, -1, GETDATE()), DATEADD(MONTH, 14, GETDATE()), 3, 6, 10, 60, 10, 35, 2100, 0, 0, 0, 0, 0, 0, 0, 0, 38, 2280, 3, 180),
        (@Inventory1Id, @VaccineItemId, @Manufacturer1Id, DATEADD(MONTH, -1, GETDATE()), DATEADD(MONTH, 6, GETDATE()), 1, 12, 1, 12, 1, 96.67, 1160, 0, 0, 0, 0, 0, 0, 0, 0, 150, 1800, 53.33, 640);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.InventoryDetails WHERE InventoryId = @Inventory2Id AND ItemId = @ElectrodeItemId)
BEGIN
    INSERT INTO Inv.InventoryDetails (InventoryId, ItemId, ManufacturerId, MfgDate, ExpiryDate, NoOfBoxes, NoOfPackets, ItemsPerPacket, TotalItems, PackQuantity, UnitBuyingPrice, TotalBuyingPrice, AdvanceTaxPercentage, AdvanceTaxAmount, Discount, DiscountAmount, RetailCharges, RetailChargesAmount, GSTCharges, GSTChargesAmount, UnitSellingPrice, TotalSellingPrice, ProfitMarginPerItem, ProfitPerItem)
    VALUES
        (@Inventory2Id, @ElectrodeItemId, @Manufacturer1Id, DATEADD(MONTH, -3, GETDATE()), DATEADD(MONTH, 8, GETDATE()), 5, 10, 10, 100, 10, 20, 2000, 0, 0, 0, 0, 0, 0, 0, 0, 22, 2200, 2, 200),
        (@Inventory2Id, @TubeItemId, @Manufacturer2Id, DATEADD(MONTH, -1, GETDATE()), DATEADD(MONTH, 18, GETDATE()), 4, 8, 25, 200, 25, 4, 800, 0, 0, 0, 0, 0, 0, 0, 0, 5, 1000, 1, 200);
END;

DECLARE @Po1SyringeLineId INT = (SELECT TOP 1 Id FROM Inv.PurchaseOrderItems WHERE PurchaseOrderId = @Po1Id AND ItemId = @SyringeItemId ORDER BY Id);
DECLARE @Po1CannulaLineId INT = (SELECT TOP 1 Id FROM Inv.PurchaseOrderItems WHERE PurchaseOrderId = @Po1Id AND ItemId = @CannulaItemId ORDER BY Id);
DECLARE @Po1VaccineLineId INT = (SELECT TOP 1 Id FROM Inv.PurchaseOrderItems WHERE PurchaseOrderId = @Po1Id AND ItemId = @VaccineItemId ORDER BY Id);
DECLARE @Po2ElectrodeLineId INT = (SELECT TOP 1 Id FROM Inv.PurchaseOrderItems WHERE PurchaseOrderId = @Po2Id AND ItemId = @ElectrodeItemId ORDER BY Id);
DECLARE @Po2TubeLineId INT = (SELECT TOP 1 Id FROM Inv.PurchaseOrderItems WHERE PurchaseOrderId = @Po2Id AND ItemId = @TubeItemId ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM Inv.InventoryItems WHERE InventoryId = @Inventory1Id AND ItemId = @SyringeItemId)
BEGIN
    INSERT INTO Inv.InventoryItems (InventoryId, ItemId, ManufacturerId, ManufacturingDate, ExpiryDate, Batch, NumberOfPackets, ItemsPerPacket, TotalItems, TotalBuyingPriceId, UnitBuyingPriceId, UnitSellingPriceId, TotalSellingPriceId, BranchId, IsActive, CreatedById, CreatedOn, ModifiedById, ModifiedOn, NumberOfBoxes, PurchaseOrderItemId, StockTypeId, SysBatchNo, BalanceTotalItems, Amount, Discount, DiscountType, Total, RetailCharges, RetailChargesType, IsDeleted, AdvanceTaxPercentage, AdvanceTaxCalculatedAmount, GSTCharges, GSTChargesType, RetailChargesCalculatedAmount, GSTChargesCalculatedAmount)
    VALUES
        (@Inventory1Id, @SyringeItemId, @Manufacturer1Id, DATEADD(MONTH, -2, GETDATE()), DATEADD(MONTH, 10, GETDATE()), 'BATCH-HMS-001', 16, 10, 160, 0, 0, 0, 0, @BranchId, 1, @CreatedById, DATEADD(DAY, -9, GETDATE()), @CreatedById, DATEADD(DAY, -9, GETDATE()), 8, @Po1SyringeLineId, @RegularStockTypeId, 'SYS-BATCH-HMS-001', 140, 1600, 0, 0, 1600, 0, 0, 0, 0, 0, 0, 0, 0, 0),
        (@Inventory1Id, @CannulaItemId, @Manufacturer2Id, DATEADD(MONTH, -1, GETDATE()), DATEADD(MONTH, 14, GETDATE()), 'BATCH-HMS-002', 6, 10, 60, 0, 0, 0, 0, @BranchId, 1, @CreatedById, DATEADD(DAY, -9, GETDATE()), @CreatedById, DATEADD(DAY, -9, GETDATE()), 3, @Po1CannulaLineId, @RegularStockTypeId, 'SYS-BATCH-HMS-002', 48, 2100, 0, 0, 2100, 0, 0, 0, 0, 0, 0, 0, 0, 0),
        (@Inventory1Id, @VaccineItemId, @Manufacturer1Id, DATEADD(MONTH, -1, GETDATE()), DATEADD(MONTH, 6, GETDATE()), 'BATCH-HMS-003', 12, 1, 12, 0, 0, 0, 0, @BranchId, 1, @CreatedById, DATEADD(DAY, -9, GETDATE()), @CreatedById, DATEADD(DAY, -9, GETDATE()), 1, @Po1VaccineLineId, @RegularStockTypeId, 'SYS-BATCH-HMS-003', 9, 1160, 0, 0, 1160, 0, 0, 0, 0, 0, 0, 0, 0, 0);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.InventoryItems WHERE InventoryId = @Inventory2Id AND ItemId = @ElectrodeItemId)
BEGIN
    INSERT INTO Inv.InventoryItems (InventoryId, ItemId, ManufacturerId, ManufacturingDate, ExpiryDate, Batch, NumberOfPackets, ItemsPerPacket, TotalItems, TotalBuyingPriceId, UnitBuyingPriceId, UnitSellingPriceId, TotalSellingPriceId, BranchId, IsActive, CreatedById, CreatedOn, ModifiedById, ModifiedOn, NumberOfBoxes, PurchaseOrderItemId, StockTypeId, SysBatchNo, BalanceTotalItems, Amount, Discount, DiscountType, Total, RetailCharges, RetailChargesType, IsDeleted, AdvanceTaxPercentage, AdvanceTaxCalculatedAmount, GSTCharges, GSTChargesType, RetailChargesCalculatedAmount, GSTChargesCalculatedAmount)
    VALUES
        (@Inventory2Id, @ElectrodeItemId, @Manufacturer1Id, DATEADD(MONTH, -3, GETDATE()), DATEADD(MONTH, 8, GETDATE()), 'BATCH-HMS-004', 10, 10, 100, 0, 0, 0, 0, @BranchId, 1, @CreatedById, DATEADD(DAY, -4, GETDATE()), @CreatedById, DATEADD(DAY, -4, GETDATE()), 5, @Po2ElectrodeLineId, @DonationStockTypeId, 'SYS-BATCH-HMS-004', 90, 2000, 0, 0, 2000, 0, 0, 0, 0, 0, 0, 0, 0, 0),
        (@Inventory2Id, @TubeItemId, @Manufacturer2Id, DATEADD(MONTH, -1, GETDATE()), DATEADD(MONTH, 18, GETDATE()), 'BATCH-HMS-005', 8, 25, 200, 0, 0, 0, 0, @BranchId, 1, @CreatedById, DATEADD(DAY, -4, GETDATE()), @CreatedById, DATEADD(DAY, -4, GETDATE()), 4, @Po2TubeLineId, @DonationStockTypeId, 'SYS-BATCH-HMS-005', 180, 800, 0, 0, 800, 0, 0, 0, 0, 0, 0, 0, 0, 0);
END;

DECLARE @RackId INT;
IF NOT EXISTS (SELECT 1 FROM Inv.Racks WHERE Name = 'HMS Seed Rack A')
BEGIN
    INSERT INTO Inv.Racks (Name, Description, Location, NumberOfRows, NumberOfCols, NumberOfDrawrs, StoreId, BranchId, CreatedById, CreatedOn, IsDeleted, IsActive)
    VALUES ('HMS Seed Rack A', 'Seed rack for stock expiry testing', 'Seeded main aisle', 2, 2, 2, @RackStoreId, @BranchId, @CreatedById, GETDATE(), 0, 1);
END;
SET @RackId = (SELECT TOP 1 Id FROM Inv.Racks WHERE Name = 'HMS Seed Rack A' ORDER BY Id);

DECLARE @RackRowId INT;
IF NOT EXISTS (SELECT 1 FROM Inv.RackRows WHERE Name = 'Row A1' AND RackId = @RackId)
BEGIN
    INSERT INTO Inv.RackRows (Name, Description, StoreId, RackId, BranchId, CreatedById, CreatedOn, IsDeleted, IsActive)
    VALUES ('Row A1', 'Seed rack row', @RackStoreId, @RackId, @BranchId, @CreatedById, GETDATE(), 0, 1);
END;
SET @RackRowId = (SELECT TOP 1 Id FROM Inv.RackRows WHERE Name = 'Row A1' AND RackId = @RackId ORDER BY Id);

DECLARE @RackColumnId INT;
IF NOT EXISTS (SELECT 1 FROM Inv.RackColumns WHERE Name = 'Column A1' AND RackId = @RackId)
BEGIN
    INSERT INTO Inv.RackColumns (Name, Description, StoreId, RackId, BranchId, CreatedById, CreatedOn, IsDeleted, IsActive)
    VALUES ('Column A1', 'Seed rack column', @RackStoreId, @RackId, @BranchId, @CreatedById, GETDATE(), 0, 1);
END;
SET @RackColumnId = (SELECT TOP 1 Id FROM Inv.RackColumns WHERE Name = 'Column A1' AND RackId = @RackId ORDER BY Id);

DECLARE @RackDrawrId INT;
IF NOT EXISTS (SELECT 1 FROM Inv.RackDrawrs WHERE Name = 'Drawer A1' AND RackId = @RackId)
BEGIN
    INSERT INTO Inv.RackDrawrs (Name, Description, StoreId, RackId, RackRowId, RackColumnId, BranchId, CreatedById, CreatedOn, IsDeleted, IsActive)
    VALUES ('Drawer A1', 'Seed rack drawer', @RackStoreId, @RackId, @RackRowId, @RackColumnId, @BranchId, @CreatedById, GETDATE(), 0, 1);
END;
SET @RackDrawrId = (SELECT TOP 1 Id FROM Inv.RackDrawrs WHERE Name = 'Drawer A1' AND RackId = @RackId ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM Inv.SpaceAllocations WHERE ItemId = @SyringeItemId AND StoreId = @RackStoreId)
BEGIN
    INSERT INTO Inv.SpaceAllocations (StoreId, ItemId, RackId, RackRowId, RackColumnId, RackDrawrId, CreatedById, CreatedOn, IsDeleted, IsActive, BranchId)
    VALUES (@RackStoreId, @SyringeItemId, @RackId, @RackRowId, @RackColumnId, @RackDrawrId, @CreatedById, GETDATE(), 0, 1, @BranchId);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.SpaceAllocations WHERE ItemId = @CannulaItemId AND StoreId = @RackStoreId)
BEGIN
    INSERT INTO Inv.SpaceAllocations (StoreId, ItemId, RackId, RackRowId, RackColumnId, RackDrawrId, CreatedById, CreatedOn, IsDeleted, IsActive, BranchId)
    VALUES (@RackStoreId, @CannulaItemId, @RackId, @RackRowId, @RackColumnId, @RackDrawrId, @CreatedById, GETDATE(), 0, 1, @BranchId);
END;

DECLARE @TransferId INT;
IF NOT EXISTS (SELECT 1 FROM Inv.TransferInventory WHERE TransferNumber = 'TI-HMS-SEED-001')
BEGIN
    INSERT INTO Inv.TransferInventory (TransferNumber, FromStoreId, ToStoreId, BranchId, TransferDate, Notes, Status, IsActive, CreatedById, CreatedOn)
    VALUES ('TI-HMS-SEED-001', @MedicineStoreId, @EmergencyStoreId, @BranchId, DATEADD(DAY, -2, GETDATE()), 'Seeded inter-store transfer', 'Completed', 1, @CreatedById, DATEADD(DAY, -2, GETDATE()));
END;
SET @TransferId = (SELECT TOP 1 Id FROM Inv.TransferInventory WHERE TransferNumber = 'TI-HMS-SEED-001' ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM Inv.TransferInventoryItems WHERE TransferInventoryId = @TransferId AND ItemId = @SyringeItemId)
BEGIN
    INSERT INTO Inv.TransferInventoryItems (TransferInventoryId, ItemId, Quantity, Notes, IsActive, CreatedOn)
    VALUES (@TransferId, @SyringeItemId, 24, 'Seeded transfer item', 1, DATEADD(DAY, -2, GETDATE()));
END;

IF NOT EXISTS (SELECT 1 FROM Inv.TransferInventoryItems WHERE TransferInventoryId = @TransferId AND ItemId = @ElectrodeItemId)
BEGIN
    INSERT INTO Inv.TransferInventoryItems (TransferInventoryId, ItemId, Quantity, Notes, IsActive, CreatedOn)
    VALUES (@TransferId, @ElectrodeItemId, 10, 'Seeded transfer item', 1, DATEADD(DAY, -2, GETDATE()));
END;

DECLARE @ReturnId INT;
IF NOT EXISTS (SELECT 1 FROM Inv.ReturnInventory WHERE ReturnNumber = 'RI-HMS-SEED-001')
BEGIN
    INSERT INTO Inv.ReturnInventory (ReturnNumber, VendorId, StoreId, BranchId, ReturnDate, Reason, Notes, Status, IsActive, CreatedById, CreatedOn)
    VALUES ('RI-HMS-SEED-001', @Vendor1Id, @MedicineStoreId, @BranchId, DATEADD(DAY, -1, GETDATE()), 'Damaged outer packs', 'Seeded vendor return', 'Submitted', 1, @CreatedById, DATEADD(DAY, -1, GETDATE()));
END;
SET @ReturnId = (SELECT TOP 1 Id FROM Inv.ReturnInventory WHERE ReturnNumber = 'RI-HMS-SEED-001' ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM Inv.ReturnInventoryItems WHERE ReturnInventoryId = @ReturnId AND ItemId = @CannulaItemId)
BEGIN
    INSERT INTO Inv.ReturnInventoryItems (ReturnInventoryId, ItemId, Quantity, Reason, Notes, IsActive, CreatedOn)
    VALUES (@ReturnId, @CannulaItemId, 5, 'Packaging issue', 'Seeded return item', 1, DATEADD(DAY, -1, GETDATE()));
END;

DECLARE @InventoryItemSyringeId INT = (SELECT TOP 1 Id FROM Inv.InventoryItems WHERE InventoryId = @Inventory1Id AND ItemId = @SyringeItemId ORDER BY Id);

DECLARE @StockAdjustmentId INT;
IF NOT EXISTS (SELECT 1 FROM Inv.StockAdjustments WHERE StoreId = @MedicineStoreId AND CAST(CreatedOn AS DATE) = CAST(DATEADD(DAY, -1, GETDATE()) AS DATE))
BEGIN
    INSERT INTO Inv.StockAdjustments (StoreId, Type, VoucherId, BranchId, CreatedById, CreatedOn, IsActive, IsDeleted)
    VALUES (@MedicineStoreId, 1, NULL, @BranchId, @CreatedById, DATEADD(DAY, -1, GETDATE()), 1, 0);
END;
SET @StockAdjustmentId = (SELECT TOP 1 Id FROM Inv.StockAdjustments WHERE StoreId = @MedicineStoreId ORDER BY Id DESC);

IF NOT EXISTS (SELECT 1 FROM Inv.StockAdjustmentDetails WHERE StockAdjustmentId = @StockAdjustmentId AND ItemId = @SyringeItemId)
BEGIN
    INSERT INTO Inv.StockAdjustmentDetails (StockAdjustmentId, ItemId, Type, StockTypeId, Quantity, BranchId, CreatedById, CreatedOn, IsActive, IsDeleted, InventoryItemId, SysBatchNo, BatchNo, PurchaseValue, SaleValue)
    VALUES (@StockAdjustmentId, @SyringeItemId, 1, @RegularStockTypeId, 4, @BranchId, @CreatedById, DATEADD(DAY, -1, GETDATE()), 1, 0, @InventoryItemSyringeId, 'SYS-BATCH-HMS-001', 'BATCH-HMS-001', 40, 48);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.PurchaseSummaries WHERE Notes = 'Seeded HMS purchase summary')
BEGIN
    INSERT INTO Inv.PurchaseSummaries (StoreId, BranchId, VendorId, SummaryDate, TotalAmount, Status, Notes, IsActive, CreatedById, CreatedOn)
    VALUES (@MedicineStoreId, @BranchId, @Vendor1Id, GETDATE(), 4860, 'Open', 'Seeded HMS purchase summary', 1, @CreatedById, GETDATE());
END;

DECLARE @PurchaseSummaryId INT = (SELECT TOP 1 Id FROM Inv.PurchaseSummaries WHERE Notes = 'Seeded HMS purchase summary' ORDER BY Id DESC);

IF NOT EXISTS (SELECT 1 FROM Inv.PurchaseSummaryInvoices WHERE PurchaseSummaryId = @PurchaseSummaryId AND InvoiceNumber = 'PSI-HMS-001')
BEGIN
    INSERT INTO Inv.PurchaseSummaryInvoices (PurchaseSummaryId, InvoiceNumber, InvoiceDate, Amount, Notes, IsActive, CreatedOn)
    VALUES (@PurchaseSummaryId, 'PSI-HMS-001', GETDATE(), 4860, 'Seeded HMS purchase summary invoice', 1, GETDATE());
END;

IF NOT EXISTS (SELECT 1 FROM Inv.ContingentBills WHERE BillNumber = 'CB-HMS-SEED-001')
BEGIN
    INSERT INTO Inv.ContingentBills (BillNumber, VendorId, StoreId, BranchId, BillDate, Amount, Notes, Status, IsActive, CreatedById, CreatedOn)
    VALUES ('CB-HMS-SEED-001', @Vendor2Id, @DisposableStoreId, @BranchId, GETDATE(), 1250, 'Seeded contingent bill', 'Pending', 1, @CreatedById, GETDATE());
END;

IF NOT EXISTS (SELECT 1 FROM Inv.StoreAllocationToUser WHERE StoreId = @MedicineStoreId AND UserId = @CreatedById)
BEGIN
    INSERT INTO Inv.StoreAllocationToUser (StoreId, UserId, BranchId, IsActive, CreatedById, CreatedOn)
    VALUES (@MedicineStoreId, @CreatedById, @BranchId, 1, @CreatedById, GETDATE());
END;

IF NOT EXISTS (SELECT 1 FROM Inv.AssetAllocations WHERE AllocationNumber = 'AA-HMS-SEED-001')
BEGIN
    INSERT INTO Inv.AssetAllocations (ItemId, BranchId, DepartmentId, SubDepartmentId, UserId, RoomId, AllocatedDate, AllocationNumber, SerialNumber, Quantity, Condition, Notes, IsActive, CreatedById, CreatedOn)
    VALUES (@ElectrodeItemId, @BranchId, @DepartmentId, @SubDepartmentId, @CreatedById, @RoomId, GETDATE(), 'AA-HMS-SEED-001', 'SER-HMS-001', 2, 'Good', 'Seeded asset allocation', 1, @CreatedById, GETDATE());
END;

DECLARE @IssuedStatusId INT = (SELECT TOP 1 Id FROM Inv.DemandRequestStatuses WHERE Name = 'Issued' ORDER BY Id);
DECLARE @PendingStatusId INT = (SELECT TOP 1 Id FROM Inv.DemandRequestStatuses WHERE Name = 'Pending' ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM Inv.DemandRequests WHERE DemandRequestNumber = 'DR-HMS-SEED-001')
BEGIN
    INSERT INTO Inv.DemandRequests (RequestedToStoreId, RequestingDepartmentId, RequestingStoreId, DemandNotes, DemandRequestStatusId, BranchId, Detail, DemandRequestNumber, IsManual, IsActive, CreatedById, CreatedOn, ModifiedById, ModifiedOn, ApprovedDate, IssuedDate, StockTypeId, TotalUnitBuyingPrice, RequestNumber, IndentNumber)
    VALUES (@EmergencyStoreId, @DepartmentId, @MedicineStoreId, 'Seeded issued demand request', @IssuedStatusId, @BranchId, 'Seeded detail', 'DR-HMS-SEED-001', 1, 1, @CreatedById, DATEADD(DAY, -1, GETDATE()), @CreatedById, DATEADD(DAY, -1, GETDATE()), DATEADD(DAY, -1, GETDATE()), DATEADD(HOUR, -12, GETDATE()), @RegularStockTypeId, 640, 'REQ-HMS-SEED-001', 'IND-HMS-SEED-001');
END;

DECLARE @DemandRequest1Id INT = (SELECT TOP 1 Id FROM Inv.DemandRequests WHERE DemandRequestNumber = 'DR-HMS-SEED-001' ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM Inv.DemandRequestItems WHERE DemandRequestId = @DemandRequest1Id AND ItemId = @SyringeItemId)
BEGIN
    INSERT INTO Inv.DemandRequestItems (DemandRequestId, ItemId, RequestedQuantity, ApprovedQuantity, IssuedQuantity, ReceivedQuantity, Notes, IsActive, CreatedOn)
    VALUES
        (@DemandRequest1Id, @SyringeItemId, 40, 35, 30, 0, 'Seeded issued syringe line', 1, DATEADD(DAY, -1, GETDATE())),
        (@DemandRequest1Id, @VaccineItemId, 8, 8, 6, 0, 'Seeded issued vaccine line', 1, DATEADD(DAY, -1, GETDATE()));
END;

IF NOT EXISTS (SELECT 1 FROM Inv.DemandRequests WHERE DemandRequestNumber = 'DR-HMS-SEED-002')
BEGIN
    INSERT INTO Inv.DemandRequests (RequestedToStoreId, RequestingDepartmentId, RequestingStoreId, DemandNotes, DemandRequestStatusId, BranchId, Detail, DemandRequestNumber, IsManual, IsActive, CreatedById, CreatedOn, ModifiedById, ModifiedOn, StockTypeId, TotalUnitBuyingPrice, RequestNumber, IndentNumber)
    VALUES (@DisposableStoreId, @DepartmentId, @EmergencyStoreId, 'Seeded pending demand request', @PendingStatusId, @BranchId, 'Seeded pending detail', 'DR-HMS-SEED-002', 1, 1, @CreatedById, GETDATE(), @CreatedById, GETDATE(), @DonationStockTypeId, 220, 'REQ-HMS-SEED-002', 'IND-HMS-SEED-002');
END;

DECLARE @DemandRequest2Id INT = (SELECT TOP 1 Id FROM Inv.DemandRequests WHERE DemandRequestNumber = 'DR-HMS-SEED-002' ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM Inv.DemandRequestItems WHERE DemandRequestId = @DemandRequest2Id AND ItemId = @ElectrodeItemId)
BEGIN
    INSERT INTO Inv.DemandRequestItems (DemandRequestId, ItemId, RequestedQuantity, ApprovedQuantity, IssuedQuantity, ReceivedQuantity, Notes, IsActive, CreatedOn)
    VALUES (@DemandRequest2Id, @ElectrodeItemId, 15, 0, 0, 0, 'Seeded pending electrode line', 1, GETDATE());
END;