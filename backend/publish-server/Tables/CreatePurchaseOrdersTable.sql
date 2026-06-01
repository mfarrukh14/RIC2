IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'PurchaseOrders' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.PurchaseOrders
    (
        PurchaseOrderId INT IDENTITY(1,1) PRIMARY KEY,
        PONumber NVARCHAR(50) NOT NULL,
        ManualPONumber NVARCHAR(100) NULL,
        StoreId INT NOT NULL,
        VendorId INT NOT NULL,
        POValidityDate DATETIME2 NULL,
        Subject NVARCHAR(500) NULL,
        Instructions NVARCHAR(MAX) NULL,
        TermsAndConditions NVARCHAR(MAX) NULL,
        Status NVARCHAR(50) NOT NULL CONSTRAINT DF_PurchaseOrders_Status DEFAULT ('Pending'),
        TotalQuantity DECIMAL(18, 2) NOT NULL CONSTRAINT DF_PurchaseOrders_TotalQuantity DEFAULT (0),
        TotalAmount DECIMAL(18, 2) NOT NULL CONSTRAINT DF_PurchaseOrders_TotalAmount DEFAULT (0),
        IsActive BIT NOT NULL CONSTRAINT DF_PurchaseOrders_IsActive DEFAULT (1),
        CreatedById INT NULL,
        CreatedOn DATETIME2 NOT NULL CONSTRAINT DF_PurchaseOrders_CreatedOn DEFAULT (SYSUTCDATETIME()),
        ModifiedById INT NULL,
        ModifiedOn DATETIME2 NULL,
        CONSTRAINT UQ_PurchaseOrders_PONumber UNIQUE (PONumber),
        CONSTRAINT FK_PurchaseOrders_Stores FOREIGN KEY (StoreId) REFERENCES dbo.Stores(StoreId),
        CONSTRAINT FK_PurchaseOrders_Vendors FOREIGN KEY (VendorId) REFERENCES dbo.Vendors(Id)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'PurchaseOrderItems' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.PurchaseOrderItems
    (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        PurchaseOrderId INT NOT NULL,
        ItemId INT NOT NULL,
        ItemType NVARCHAR(50) NULL,
        PacketQuantity DECIMAL(18, 2) NULL,
        UnitQuantity DECIMAL(18, 2) NOT NULL,
        PacketPrice DECIMAL(18, 2) NULL,
        UnitPrice DECIMAL(18, 2) NOT NULL,
        TotalPrice DECIMAL(18, 2) NOT NULL,
        IsActive BIT NOT NULL CONSTRAINT DF_PurchaseOrderItems_IsActive DEFAULT (1),
        CreatedById INT NULL,
        CreatedOn DATETIME2 NOT NULL CONSTRAINT DF_PurchaseOrderItems_CreatedOn DEFAULT (SYSUTCDATETIME()),
        ModifiedById INT NULL,
        ModifiedOn DATETIME2 NULL,
        CONSTRAINT FK_PurchaseOrderItems_PurchaseOrders FOREIGN KEY (PurchaseOrderId) REFERENCES dbo.PurchaseOrders(PurchaseOrderId),
        CONSTRAINT FK_PurchaseOrderItems_Items FOREIGN KEY (ItemId) REFERENCES dbo.Items(Id)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_PurchaseOrderItems_PurchaseOrderId' AND object_id = OBJECT_ID('dbo.PurchaseOrderItems'))
BEGIN
    CREATE INDEX IX_PurchaseOrderItems_PurchaseOrderId ON dbo.PurchaseOrderItems(PurchaseOrderId);
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Vendors WHERE Name = 'MediSupply Traders')
BEGIN
    INSERT INTO dbo.Vendors (Name, Description, IsActive, CreatedOn)
    VALUES ('MediSupply Traders', 'Medical supplies vendor', 1, SYSUTCDATETIME());
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Vendors WHERE Name = 'CarePlus Disposables')
BEGIN
    INSERT INTO dbo.Vendors (Name, Description, IsActive, CreatedOn)
    VALUES ('CarePlus Disposables', 'Disposable equipment vendor', 1, SYSUTCDATETIME());
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Stores WHERE StoreName = 'Medicine Store')
BEGIN
    INSERT INTO dbo.Stores (StoreName, StoreCode, Description, IsActive, CreatedOn)
    VALUES ('Medicine Store', 'MED', 'Medicine store', 1, SYSUTCDATETIME());
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Stores WHERE StoreName = 'Main Disposable Store')
BEGIN
    INSERT INTO dbo.Stores (StoreName, StoreCode, Description, IsActive, CreatedOn)
    VALUES ('Main Disposable Store', 'MDS', 'Main disposable store', 1, SYSUTCDATETIME());
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Items WHERE Name = 'Syringe 10ml')
BEGIN
    INSERT INTO dbo.Items (Name, Description, IsActive, CreatedOn)
    VALUES ('Syringe 10ml', 'Standard syringe', 1, SYSUTCDATETIME());
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Items WHERE Name = 'ECG Electrodes')
BEGIN
    INSERT INTO dbo.Items (Name, Description, IsActive, CreatedOn)
    VALUES ('ECG Electrodes', 'ECG electrodes', 1, SYSUTCDATETIME());
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Items WHERE Name = 'IV Cannula 20G')
BEGIN
    INSERT INTO dbo.Items (Name, Description, IsActive, CreatedOn)
    VALUES ('IV Cannula 20G', 'Peripheral IV cannula', 1, SYSUTCDATETIME());
END
GO

DECLARE @MedicineStoreId INT = (SELECT TOP 1 StoreId FROM dbo.Stores WHERE StoreName = 'Medicine Store' ORDER BY StoreId);
DECLARE @MainDisposableStoreId INT = (SELECT TOP 1 StoreId FROM dbo.Stores WHERE StoreName = 'Main Disposable Store' ORDER BY StoreId);
DECLARE @MediSupplyVendorId INT = (SELECT TOP 1 Id FROM dbo.Vendors WHERE Name = 'MediSupply Traders' ORDER BY Id);
DECLARE @CarePlusVendorId INT = (SELECT TOP 1 Id FROM dbo.Vendors WHERE Name = 'CarePlus Disposables' ORDER BY Id);
DECLARE @SyringeItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = 'Syringe 10ml' ORDER BY Id);
DECLARE @ElectrodeItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = 'ECG Electrodes' ORDER BY Id);
DECLARE @CannulaItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = 'IV Cannula 20G' ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrders WHERE PONumber = 'PO-0401AAAPO001')
BEGIN
    INSERT INTO dbo.PurchaseOrders
    (
        PONumber,
        ManualPONumber,
        StoreId,
        VendorId,
        POValidityDate,
        Subject,
        Instructions,
        TermsAndConditions,
        Status,
        TotalQuantity,
        TotalAmount,
        IsActive,
        CreatedById,
        CreatedOn
    )
    VALUES
    (
        'PO-0401AAAPO001',
        'MPO-1001',
        @MedicineStoreId,
        @MediSupplyVendorId,
        DATEADD(DAY, 14, SYSUTCDATETIME()),
        'Monthly medicine replenishment',
        'Deliver all approved items in sealed cartons.',
        'Payment after stock verification.',
        'Pending',
        180,
        3300,
        1,
        1,
        DATEADD(DAY, -6, SYSUTCDATETIME())
    );

    DECLARE @PurchaseOrderSeed1 INT = CAST(SCOPE_IDENTITY() AS INT);

    INSERT INTO dbo.PurchaseOrderItems
    (
        PurchaseOrderId,
        ItemId,
        ItemType,
        PacketQuantity,
        UnitQuantity,
        PacketPrice,
        UnitPrice,
        TotalPrice,
        IsActive,
        CreatedById,
        CreatedOn
    )
    VALUES
    (@PurchaseOrderSeed1, @SyringeItemId, 'Disposable', 6, 120, 1200, 10, 1200, 1, 1, DATEADD(DAY, -6, SYSUTCDATETIME())),
    (@PurchaseOrderSeed1, @CannulaItemId, 'Medicine', 2, 60, 2100, 35, 2100, 1, 1, DATEADD(DAY, -6, SYSUTCDATETIME()));
END
GO

DECLARE @MedicineStoreId INT = (SELECT TOP 1 StoreId FROM dbo.Stores WHERE StoreName = 'Medicine Store' ORDER BY StoreId);
DECLARE @MainDisposableStoreId INT = (SELECT TOP 1 StoreId FROM dbo.Stores WHERE StoreName = 'Main Disposable Store' ORDER BY StoreId);
DECLARE @MediSupplyVendorId INT = (SELECT TOP 1 Id FROM dbo.Vendors WHERE Name = 'MediSupply Traders' ORDER BY Id);
DECLARE @CarePlusVendorId INT = (SELECT TOP 1 Id FROM dbo.Vendors WHERE Name = 'CarePlus Disposables' ORDER BY Id);
DECLARE @SyringeItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = 'Syringe 10ml' ORDER BY Id);
DECLARE @ElectrodeItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = 'ECG Electrodes' ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrders WHERE PONumber = 'PO-0401AAAPO002')
BEGIN
    INSERT INTO dbo.PurchaseOrders
    (
        PONumber,
        ManualPONumber,
        StoreId,
        VendorId,
        POValidityDate,
        Subject,
        Instructions,
        TermsAndConditions,
        Status,
        TotalQuantity,
        TotalAmount,
        IsActive,
        CreatedById,
        CreatedOn
    )
    VALUES
    (
        'PO-0401AAAPO002',
        'MPO-1002',
        @MainDisposableStoreId,
        @CarePlusVendorId,
        DATEADD(DAY, 7, SYSUTCDATETIME()),
        'Disposable items urgent order',
        'Urgent supply required before weekend.',
        'Partial delivery allowed.',
        'Approved',
        200,
        2800,
        1,
        1,
        DATEADD(DAY, -3, SYSUTCDATETIME())
    );

    DECLARE @PurchaseOrderSeed2 INT = CAST(SCOPE_IDENTITY() AS INT);

    INSERT INTO dbo.PurchaseOrderItems
    (
        PurchaseOrderId,
        ItemId,
        ItemType,
        PacketQuantity,
        UnitQuantity,
        PacketPrice,
        UnitPrice,
        TotalPrice,
        IsActive,
        CreatedById,
        CreatedOn
    )
    VALUES
    (@PurchaseOrderSeed2, @ElectrodeItemId, 'Disposable', 4, 80, 1600, 20, 1600, 1, 1, DATEADD(DAY, -3, SYSUTCDATETIME())),
    (@PurchaseOrderSeed2, @SyringeItemId, 'Disposable', 6, 120, 1200, 10, 1200, 1, 1, DATEADD(DAY, -3, SYSUTCDATETIME()));
END
GO