-- Create TransferInventory table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TransferInventory')
BEGIN
    CREATE TABLE dbo.TransferInventory (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        DRNo NVARCHAR(50) NOT NULL,
        FromStoreId INT NOT NULL,
        ToStoreId INT NOT NULL,
        StockTypeId INT NOT NULL,
        ItemId INT NOT NULL,
        ItemName NVARCHAR(MAX),
        Quantity INT NOT NULL,
        TransferDate DATETIME NOT NULL DEFAULT GETDATE(),
        Status NVARCHAR(50) DEFAULT 'Pending',
        Notes NVARCHAR(MAX),
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById INT,
        ModifiedOn DATETIME,
        CONSTRAINT FK_Transfer_FromStore FOREIGN KEY (FromStoreId) REFERENCES Stores(StoreId),
        CONSTRAINT FK_Transfer_ToStore FOREIGN KEY (ToStoreId) REFERENCES Stores(StoreId),
        CONSTRAINT FK_Transfer_StockType FOREIGN KEY (StockTypeId) REFERENCES StockTypes(StockTypeId),
        CONSTRAINT FK_Transfer_Item FOREIGN KEY (ItemId) REFERENCES Items(Id)
    );
    PRINT 'TransferInventory table created successfully';
END
ELSE
BEGIN
    PRINT 'TransferInventory table already exists';
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Stores WHERE StoreName = 'Dental Store')
BEGIN
    INSERT INTO dbo.Stores (StoreName, StoreCode, Description, IsActive, CreatedOn)
    VALUES ('Dental Store', 'DS', 'Dental consumables requesting store', 1, GETDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Stores WHERE StoreName = 'Main Disposable Store')
BEGIN
    INSERT INTO dbo.Stores (StoreName, StoreCode, Description, IsActive, CreatedOn)
    VALUES ('Main Disposable Store', 'MDS', 'Main disposable store', 1, GETDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Stores WHERE StoreName = 'Medicine Store')
BEGIN
    INSERT INTO dbo.Stores (StoreName, StoreCode, Description, IsActive, CreatedOn)
    VALUES ('Medicine Store', 'MED', 'Medicine issue store', 1, GETDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Stores WHERE StoreName = 'Main Stock & Accessories Store')
BEGIN
    INSERT INTO dbo.Stores (StoreName, StoreCode, Description, IsActive, CreatedOn)
    VALUES ('Main Stock & Accessories Store', 'MSAS', 'Main stock and accessories store', 1, GETDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Stores WHERE StoreName = 'Main Laboratory Store')
BEGIN
    INSERT INTO dbo.Stores (StoreName, StoreCode, Description, IsActive, CreatedOn)
    VALUES ('Main Laboratory Store', 'MLS', 'Main laboratory store', 1, GETDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Items WHERE Name = 'Syringe Cutter')
BEGIN
    INSERT INTO dbo.Items (Name, Description, IsActive, CreatedOn)
    VALUES ('Syringe Cutter', 'Disposable syringe cutter', 1, GETDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Items WHERE Name = '0.75 mm 2 core Shielded Communication/control Cable')
BEGIN
    INSERT INTO dbo.Items (Name, Description, IsActive, CreatedOn)
    VALUES ('0.75 mm 2 core Shielded Communication/control Cable', 'Communication and control cable', 1, GETDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Items WHERE Name = '03 Way Solenoid Valve Part NO. 471828721 Make, Electrolnux Italy')
BEGIN
    INSERT INTO dbo.Items (Name, Description, IsActive, CreatedOn)
    VALUES ('03 Way Solenoid Valve Part NO. 471828721 Make, Electrolnux Italy', 'Solenoid valve spare part', 1, GETDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Items WHERE Name = '1/8 Drain Valve For O2 Generator')
BEGIN
    INSERT INTO dbo.Items (Name, Description, IsActive, CreatedOn)
    VALUES ('1/8 Drain Valve For O2 Generator', 'Drain valve for oxygen generator', 1, GETDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Items WHERE Name = '12 lead ECG Cable For ETT Machine')
BEGIN
    INSERT INTO dbo.Items (Name, Description, IsActive, CreatedOn)
    VALUES ('12 lead ECG Cable For ETT Machine', 'ECG cable for ETT machine', 1, GETDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Items WHERE Name = '32" Full HD 1080p LED')
BEGIN
    INSERT INTO dbo.Items (Name, Description, IsActive, CreatedOn)
    VALUES ('32" Full HD 1080p LED', 'Display panel item', 1, GETDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Items WHERE Name = '5 Port Gigabit Desktop Switch')
BEGIN
    INSERT INTO dbo.Items (Name, Description, IsActive, CreatedOn)
    VALUES ('5 Port Gigabit Desktop Switch', 'Network switch', 1, GETDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Items WHERE Name = '50 inch Android LED Haier')
BEGIN
    INSERT INTO dbo.Items (Name, Description, IsActive, CreatedOn)
    VALUES ('50 inch Android LED Haier', 'Haier display screen', 1, GETDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Items WHERE Name = '5ml plastic Tube')
BEGIN
    INSERT INTO dbo.Items (Name, Description, IsActive, CreatedOn)
    VALUES ('5ml plastic Tube', 'Plastic laboratory tube', 1, GETDATE());
END
GO

DECLARE @DentalStoreId INT = (SELECT TOP 1 StoreId FROM dbo.Stores WHERE StoreName = 'Dental Store' ORDER BY StoreId);
DECLARE @MainDisposableStoreId INT = (SELECT TOP 1 StoreId FROM dbo.Stores WHERE StoreName = 'Main Disposable Store' ORDER BY StoreId);
DECLARE @MedicineStoreId INT = (SELECT TOP 1 StoreId FROM dbo.Stores WHERE StoreName = 'Medicine Store' ORDER BY StoreId);
DECLARE @MainStockAccessoriesStoreId INT = (SELECT TOP 1 StoreId FROM dbo.Stores WHERE StoreName = 'Main Stock & Accessories Store' ORDER BY StoreId);
DECLARE @MainLaboratoryStoreId INT = (SELECT TOP 1 StoreId FROM dbo.Stores WHERE StoreName = 'Main Laboratory Store' ORDER BY StoreId);
DECLARE @RegularStockTypeId INT = (SELECT TOP 1 Id FROM dbo.StockTypes WHERE Name = 'Regular' ORDER BY Id);
DECLARE @SyringeCutterItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = 'Syringe Cutter' ORDER BY Id);
DECLARE @CableItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = '0.75 mm 2 core Shielded Communication/control Cable' ORDER BY Id);
DECLARE @SolenoidItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = '03 Way Solenoid Valve Part NO. 471828721 Make, Electrolnux Italy' ORDER BY Id);
DECLARE @DrainValveItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = '1/8 Drain Valve For O2 Generator' ORDER BY Id);
DECLARE @EcgCableItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = '12 lead ECG Cable For ETT Machine' ORDER BY Id);
DECLARE @Led32ItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = '32" Full HD 1080p LED' ORDER BY Id);
DECLARE @SwitchItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = '5 Port Gigabit Desktop Switch' ORDER BY Id);
DECLARE @HaierItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = '50 inch Android LED Haier' ORDER BY Id);
DECLARE @PlasticTubeItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = '5ml plastic Tube' ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM dbo.TransferInventory WHERE DRNo = 'DR-0401AAAB8093')
BEGIN
    INSERT INTO dbo.TransferInventory
    (
        DRNo,
        FromStoreId,
        ToStoreId,
        StockTypeId,
        ItemId,
        ItemName,
        Quantity,
        TransferDate,
        Status,
        Notes,
        IsActive,
        CreatedById,
        CreatedOn
    )
    VALUES
    ('DR-0401AAAB8093', @DentalStoreId, @MainDisposableStoreId, @RegularStockTypeId, @SyringeCutterItemId, 'Syringe Cutter', 1, '2022-08-26T10:49:00', 'Pending', 'Seeded test transition row', 1, 1, '2022-08-26T10:49:00'),
    ('DR-0401AAAB8094', @MedicineStoreId, @MainDisposableStoreId, @RegularStockTypeId, @SyringeCutterItemId, 'Syringe Cutter', 155, '2022-08-27T09:15:00', 'Pending', 'Seeded grouped transition row', 1, 1, '2022-08-27T09:15:00'),
    ('DR-0401AAAB8095', @MainStockAccessoriesStoreId, @MainDisposableStoreId, @RegularStockTypeId, @CableItemId, '0.75 mm 2 core Shielded Communication/control Cable', 1, '2022-08-27T11:20:00', 'Pending', 'Seeded grouped transition row', 1, 1, '2022-08-27T11:20:00'),
    ('DR-0401AAAB8096', @MainStockAccessoriesStoreId, @MainDisposableStoreId, @RegularStockTypeId, @SolenoidItemId, '03 Way Solenoid Valve Part NO. 471828721 Make, Electrolnux Italy', 1, '2022-08-28T08:30:00', 'Pending', 'Seeded grouped transition row', 1, 1, '2022-08-28T08:30:00'),
    ('DR-0401AAAB8097', @MainStockAccessoriesStoreId, @MainDisposableStoreId, @RegularStockTypeId, @DrainValveItemId, '1/8 Drain Valve For O2 Generator', 1, '2022-08-28T12:10:00', 'Pending', 'Seeded grouped transition row', 1, 1, '2022-08-28T12:10:00'),
    ('DR-0401AAAB8098', @MainStockAccessoriesStoreId, @MainDisposableStoreId, @RegularStockTypeId, @EcgCableItemId, '12 lead ECG Cable For ETT Machine', 4, '2022-08-29T13:25:00', 'Pending', 'Seeded grouped transition row', 1, 1, '2022-08-29T13:25:00'),
    ('DR-0401AAAB8099', @MainStockAccessoriesStoreId, @MainDisposableStoreId, @RegularStockTypeId, @Led32ItemId, '32" Full HD 1080p LED', 1, '2022-08-29T15:40:00', 'Pending', 'Seeded grouped transition row', 1, 1, '2022-08-29T15:40:00'),
    ('DR-0401AAAB8100', @MainStockAccessoriesStoreId, @MainDisposableStoreId, @RegularStockTypeId, @SwitchItemId, '5 Port Gigabit Desktop Switch', 5, '2022-08-30T09:05:00', 'Pending', 'Seeded grouped transition row', 1, 1, '2022-08-30T09:05:00'),
    ('DR-0401AAAB8101', @MainStockAccessoriesStoreId, @MainDisposableStoreId, @RegularStockTypeId, @HaierItemId, '50 inch Android LED Haier', 1, '2022-08-30T11:45:00', 'Pending', 'Seeded grouped transition row', 1, 1, '2022-08-30T11:45:00'),
    ('DR-0401AAAB8102', @MainLaboratoryStoreId, @MainDisposableStoreId, @RegularStockTypeId, @PlasticTubeItemId, '5ml plastic Tube', 2000, '2022-08-31T10:00:00', 'Pending', 'Seeded grouped transition row', 1, 1, '2022-08-31T10:00:00');
END
GO
