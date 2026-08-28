IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Vendors' AND schema_id = SCHEMA_ID('dbo'))
    AND NOT EXISTS (SELECT 1 FROM dbo.Vendors WHERE Name = 'SterileCare Supplies')
BEGIN
    INSERT INTO dbo.Vendors (Name, Description, IsActive, CreatedOn)
    VALUES ('SterileCare Supplies', 'Emergency procurement vendor', 1, SYSUTCDATETIME());
END
GO

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Manufacturers' AND schema_id = SCHEMA_ID('dbo'))
    AND NOT EXISTS (SELECT 1 FROM dbo.Manufacturers WHERE Name = 'CardioMed Devices')
BEGIN
    INSERT INTO dbo.Manufacturers (Name, Description, IsActive, CreatedOn)
    VALUES ('CardioMed Devices', 'Cardiology equipment manufacturer', 1, SYSUTCDATETIME());
END
GO

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Manufacturers' AND schema_id = SCHEMA_ID('dbo'))
    AND NOT EXISTS (SELECT 1 FROM dbo.Manufacturers WHERE Name = 'Vital Surgical Works')
BEGIN
    INSERT INTO dbo.Manufacturers (Name, Description, IsActive, CreatedOn)
    VALUES ('Vital Surgical Works', 'Disposable and surgical goods manufacturer', 1, SYSUTCDATETIME());
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Stores WHERE StoreName = 'Emergency Store')
BEGIN
    INSERT INTO dbo.Stores (StoreName, StoreCode, Description, IsActive, CreatedOn)
    VALUES ('Emergency Store', 'EMS', 'Emergency stock holding store', 1, SYSUTCDATETIME());
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Items WHERE Name = 'Defibrillator Pads')
BEGIN
    INSERT INTO dbo.Items (Name, Description, IsActive, CreatedOn)
    VALUES ('Defibrillator Pads', 'Disposable defibrillator electrode pads', 1, SYSUTCDATETIME());
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Items WHERE Name = 'Central Line Kit')
BEGIN
    INSERT INTO dbo.Items (Name, Description, IsActive, CreatedOn)
    VALUES ('Central Line Kit', 'Sterile central line insertion kit', 1, SYSUTCDATETIME());
END
GO

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Inventories' AND schema_id = SCHEMA_ID('dbo'))
    AND EXISTS (SELECT 1 FROM sys.tables WHERE name = 'InventoryDetails' AND schema_id = SCHEMA_ID('dbo'))
    AND NOT EXISTS (SELECT 1 FROM dbo.Inventories WHERE InvoiceNo = 'EPO-SEED-INV-001')
BEGIN
    DECLARE @BranchId INT = (SELECT TOP 1 Id FROM dbo.Branches ORDER BY Id);
    DECLARE @StockTypeId INT = (SELECT TOP 1 StockTypeId FROM dbo.StockTypes ORDER BY StockTypeId);
    DECLARE @MedicineStoreId INT = (SELECT TOP 1 StoreId FROM dbo.Stores WHERE StoreName = 'Medicine Store' ORDER BY StoreId);
    DECLARE @EmergencyStoreId INT = (SELECT TOP 1 StoreId FROM dbo.Stores WHERE StoreName = 'Emergency Store' ORDER BY StoreId);
    DECLARE @MediSupplyVendorId INT = (SELECT TOP 1 Id FROM dbo.Vendors WHERE Name = 'MediSupply Traders' ORDER BY Id);
    DECLARE @SterileCareVendorId INT = (SELECT TOP 1 Id FROM dbo.Vendors WHERE Name = 'SterileCare Supplies' ORDER BY Id);
    DECLARE @CardioMedManufacturerId INT = (SELECT TOP 1 Id FROM dbo.Manufacturers WHERE Name = 'CardioMed Devices' ORDER BY Id);
    DECLARE @VitalSurgicalManufacturerId INT = (SELECT TOP 1 Id FROM dbo.Manufacturers WHERE Name = 'Vital Surgical Works' ORDER BY Id);
    DECLARE @SyringeItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = 'Syringe 10ml' ORDER BY Id);
    DECLARE @DefibPadsItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = 'Defibrillator Pads' ORDER BY Id);
    DECLARE @CentralLineItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = 'Central Line Kit' ORDER BY Id);

    INSERT INTO dbo.Inventories
    (
        PurchaseOrderNumber,
        InvoiceNo,
        VendorId,
        StoreId,
        BranchId,
        IsActive,
        CreatedById,
        CreatedOn,
        IsFinalized,
        StockTypeId,
        TotalBuyingPrice
    )
    VALUES
    ('EPO-PO-001', 'EPO-SEED-INV-001', @MediSupplyVendorId, @MedicineStoreId, @BranchId, 1, 1, DATEADD(DAY, -22, SYSUTCDATETIME()), 1, @StockTypeId, 1500),
    ('EPO-PO-002', 'EPO-SEED-INV-002', @SterileCareVendorId, @EmergencyStoreId, @BranchId, 1, 1, DATEADD(DAY, -18, SYSUTCDATETIME()), 1, @StockTypeId, 2400),
    ('EPO-PO-003', 'EPO-SEED-INV-003', @SterileCareVendorId, @EmergencyStoreId, @BranchId, 1, 1, DATEADD(DAY, -12, SYSUTCDATETIME()), 1, @StockTypeId, 1200);

    DECLARE @InventorySeed1 INT = (SELECT TOP 1 Id FROM dbo.Inventories WHERE InvoiceNo = 'EPO-SEED-INV-001' ORDER BY Id DESC);
    DECLARE @InventorySeed2 INT = (SELECT TOP 1 Id FROM dbo.Inventories WHERE InvoiceNo = 'EPO-SEED-INV-002' ORDER BY Id DESC);
    DECLARE @InventorySeed3 INT = (SELECT TOP 1 Id FROM dbo.Inventories WHERE InvoiceNo = 'EPO-SEED-INV-003' ORDER BY Id DESC);

    INSERT INTO dbo.InventoryDetails
    (
        InventoryId,
        ItemId,
        ManufacturerId,
        TotalItems,
        UnitBuyingPrice,
        TotalBuyingPrice,
        UnitSellingPrice,
        TotalSellingPrice
    )
    VALUES
    (@InventorySeed1, @SyringeItemId, @VitalSurgicalManufacturerId, 150, 10, 1500, 13, 1950),
    (@InventorySeed2, @DefibPadsItemId, @CardioMedManufacturerId, 40, 60, 2400, 75, 3000),
    (@InventorySeed3, @CentralLineItemId, @VitalSurgicalManufacturerId, 90, 13.33, 1200, 18, 1620);
END
GO

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'StockConsumptions' AND schema_id = SCHEMA_ID('dbo'))
    AND EXISTS (SELECT 1 FROM sys.tables WHERE name = 'StockConsumptionDetails' AND schema_id = SCHEMA_ID('dbo'))
    AND NOT EXISTS (SELECT 1 FROM dbo.StockConsumptions WHERE Remarks = 'Estimated PO seed consumption batch')
BEGIN
    DECLARE @MedicineStoreId INT = (SELECT TOP 1 StoreId FROM dbo.Stores WHERE StoreName = 'Medicine Store' ORDER BY StoreId);
    DECLARE @EmergencyStoreId INT = (SELECT TOP 1 StoreId FROM dbo.Stores WHERE StoreName = 'Emergency Store' ORDER BY StoreId);
    DECLARE @SyringeItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = 'Syringe 10ml' ORDER BY Id);
    DECLARE @DefibPadsItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = 'Defibrillator Pads' ORDER BY Id);
    DECLARE @CentralLineItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = 'Central Line Kit' ORDER BY Id);
    DECLARE @StockTypeId INT = (SELECT TOP 1 StockTypeId FROM dbo.StockTypes ORDER BY StockTypeId);
    DECLARE @MedicineStoreGuid UNIQUEIDENTIFIER = CONVERT(UNIQUEIDENTIFIER, '00000000-0000-0000-0000-' + RIGHT(REPLICATE('0', 12) + CAST(@MedicineStoreId AS VARCHAR(12)), 12));
    DECLARE @EmergencyStoreGuid UNIQUEIDENTIFIER = CONVERT(UNIQUEIDENTIFIER, '00000000-0000-0000-0000-' + RIGHT(REPLICATE('0', 12) + CAST(@EmergencyStoreId AS VARCHAR(12)), 12));
    DECLARE @BranchGuid UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000001';

    INSERT INTO dbo.StockConsumptions
    (
        Id,
        StoreId,
        Type,
        BranchId,
        IsActive,
        CreatedOn,
        IsDeleted,
        Remarks
    )
    VALUES
    ('11111111-1111-1111-1111-111111111111', @MedicineStoreGuid, 1, @BranchGuid, 1, DATEADD(DAY, -7, SYSUTCDATETIME()), 0, 'Estimated PO seed consumption batch'),
    ('22222222-2222-2222-2222-222222222222', @EmergencyStoreGuid, 1, @BranchGuid, 1, DATEADD(DAY, -5, SYSUTCDATETIME()), 0, 'Estimated PO seed consumption batch');

    INSERT INTO dbo.StockConsumptionDetails
    (
        Id,
        StoreId,
        ItemId,
        Type,
        StockTypeId,
        Quantity,
        BranchId,
        IsActive,
        CreatedOn,
        IsDeleted,
        StockConsumptionId
    )
    VALUES
    ('11111111-1111-1111-1111-AAAAAAAAAAA1', @MedicineStoreGuid, @SyringeItemId, 1, @StockTypeId, 140, @BranchGuid, 1, DATEADD(DAY, -7, SYSUTCDATETIME()), 0, '11111111-1111-1111-1111-111111111111'),
    ('22222222-2222-2222-2222-BBBBBBBBBBB2', @EmergencyStoreGuid, @CentralLineItemId, 1, @StockTypeId, 18, @BranchGuid, 1, DATEADD(DAY, -5, SYSUTCDATETIME()), 0, '22222222-2222-2222-2222-222222222222');
END
GO