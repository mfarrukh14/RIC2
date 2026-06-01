IF NOT EXISTS (SELECT 1 FROM dbo.Branches WHERE Name = 'Rawalpindi Institute of Cardiology')
BEGIN
    INSERT INTO dbo.Branches (Name, Code, Address, IsActive, CreatedOn)
    VALUES ('Rawalpindi Institute of Cardiology', 'RIC', 'Rawalpindi', 1, GETUTCDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Branches WHERE Name = 'Cardiac Emergency Unit')
BEGIN
    INSERT INTO dbo.Branches (Name, Code, Address, IsActive, CreatedOn)
    VALUES ('Cardiac Emergency Unit', 'CEU', 'Rawalpindi', 1, GETUTCDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Stores WHERE StoreName = 'Echo Store')
BEGIN
    INSERT INTO dbo.Stores (StoreName, StoreCode, Description, IsActive, CreatedOn)
    VALUES ('Echo Store', 'ECHO', 'Supply chain receiving store for echo consumables', 1, GETDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Stores WHERE StoreName = 'Central Supply Store')
BEGIN
    INSERT INTO dbo.Stores (StoreName, StoreCode, Description, IsActive, CreatedOn)
    VALUES ('Central Supply Store', 'CSS', 'Central supply chain store', 1, GETDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Stores WHERE StoreName = 'Medicine Store')
BEGIN
    INSERT INTO dbo.Stores (StoreName, StoreCode, Description, IsActive, CreatedOn)
    VALUES ('Medicine Store', 'MED', 'Medicine receiving store', 1, GETDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Stores WHERE StoreName = 'Main Stock & Accessories Store')
BEGIN
    INSERT INTO dbo.Stores (StoreName, StoreCode, Description, IsActive, CreatedOn)
    VALUES ('Main Stock & Accessories Store', 'MSAS', 'Main stock and accessories store', 1, GETDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Stores WHERE StoreName = 'Main Disposable Store')
BEGIN
    INSERT INTO dbo.Stores (StoreName, StoreCode, Description, IsActive, CreatedOn)
    VALUES ('Main Disposable Store', 'MDS', 'Main disposable receiving store', 1, GETDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Items WHERE Name = 'ECG Electrodes')
BEGIN
    INSERT INTO dbo.Items (Name, Description, IsActive, CreatedOn)
    VALUES ('ECG Electrodes', 'Disposable ECG electrode pack', 1, GETDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Items WHERE Name = 'Syringe 10ml')
BEGIN
    INSERT INTO dbo.Items (Name, Description, IsActive, CreatedOn)
    VALUES ('Syringe 10ml', 'Standard disposable syringe', 1, GETDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Items WHERE Name = 'IV Cannula 20G')
BEGIN
    INSERT INTO dbo.Items (Name, Description, IsActive, CreatedOn)
    VALUES ('IV Cannula 20G', 'Peripheral IV cannula', 1, GETDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Items WHERE Name = 'Solution Xylocaine 4% (Lidocaine HCL) 50mL')
BEGIN
    INSERT INTO dbo.Items (Name, Description, IsActive, CreatedOn)
    VALUES ('Solution Xylocaine 4% (Lidocaine HCL) 50mL', 'Lidocaine solution vial', 1, GETDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Items WHERE Name = 'battery 12v - 7Ah')
BEGIN
    INSERT INTO dbo.Items (Name, Description, IsActive, CreatedOn)
    VALUES ('battery 12v - 7Ah', '12v battery', 1, GETDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Items WHERE Name = 'ECHO Probe (30BT)')
BEGIN
    INSERT INTO dbo.Items (Name, Description, IsActive, CreatedOn)
    VALUES ('ECHO Probe (30BT)', 'Echo probe', 1, GETDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Items WHERE Name = 'Disposable Face Mask, Polythene Gloves, Gauze Roll')
BEGIN
    INSERT INTO dbo.Items (Name, Description, IsActive, CreatedOn)
    VALUES ('Disposable Face Mask, Polythene Gloves, Gauze Roll', 'Mixed consumables set', 1, GETDATE());
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'DemandRequests' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.DemandRequests
    (
        DemandRequestId INT IDENTITY(1,1) PRIMARY KEY,
        DRNo NVARCHAR(50) NOT NULL,
        IndentNo NVARCHAR(50) NULL,
        DateFrom DATETIME2 NOT NULL,
        DateTo DATETIME2 NOT NULL,
        BranchId INT NOT NULL,
        RequestingStoreId INT NULL,
        RequestedStoreId INT NOT NULL,
        StockTypeId INT NULL,
        Status NVARCHAR(50) NOT NULL CONSTRAINT DF_DemandRequests_Status DEFAULT ('Pending'),
        Remarks NVARCHAR(MAX) NULL,
        IsActive BIT NOT NULL CONSTRAINT DF_DemandRequests_IsActive DEFAULT (1),
        CreatedById INT NULL,
        CreatedOn DATETIME2 NOT NULL CONSTRAINT DF_DemandRequests_CreatedOn DEFAULT (SYSUTCDATETIME()),
        ModifiedById INT NULL,
        ModifiedOn DATETIME2 NULL,
        CONSTRAINT UQ_DemandRequests_DRNo UNIQUE (DRNo),
        CONSTRAINT FK_DemandRequests_Branches FOREIGN KEY (BranchId) REFERENCES dbo.Branches(Id),
        CONSTRAINT FK_DemandRequests_RequestingStore FOREIGN KEY (RequestingStoreId) REFERENCES dbo.Stores(StoreId),
        CONSTRAINT FK_DemandRequests_Stores FOREIGN KEY (RequestedStoreId) REFERENCES dbo.Stores(StoreId),
        CONSTRAINT FK_DemandRequests_StockTypes FOREIGN KEY (StockTypeId) REFERENCES dbo.StockTypes(StockTypeId)
    );
END
GO

IF COL_LENGTH('dbo.DemandRequests', 'RequestingStoreId') IS NULL
BEGIN
    ALTER TABLE dbo.DemandRequests
    ADD RequestingStoreId INT NULL;
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = 'FK_DemandRequests_RequestingStore'
)
BEGIN
    ALTER TABLE dbo.DemandRequests
    ADD CONSTRAINT FK_DemandRequests_RequestingStore FOREIGN KEY (RequestingStoreId) REFERENCES dbo.Stores(StoreId);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'DemandRequestItems' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.DemandRequestItems
    (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        DemandRequestId INT NOT NULL,
        ItemId INT NULL,
        RequestedQuantity INT NOT NULL,
        ApprovedQuantity INT NULL,
        BranchId INT NOT NULL,
        MedicineId INT NULL,
        SubServiceId INT NULL,
        IsActive BIT NOT NULL CONSTRAINT DF_DemandRequestItems_IsActive DEFAULT (1),
        CreatedById INT NULL,
        CreatedOn DATETIME2 NOT NULL CONSTRAINT DF_DemandRequestItems_CreatedOn DEFAULT (SYSUTCDATETIME()),
        ModifiedById INT NULL,
        ModifiedOn DATETIME2 NULL,
        Remarks NVARCHAR(MAX) NULL,
        StockTypeId INT NULL,
        IssuedQuantity INT NULL,
        IssuingQuantity INT NULL,
        RemainingQuantity INT NULL,
        CONSTRAINT FK_DemandRequestItems_DemandRequests FOREIGN KEY (DemandRequestId) REFERENCES dbo.DemandRequests(DemandRequestId),
        CONSTRAINT FK_DemandRequestItems_Items FOREIGN KEY (ItemId) REFERENCES dbo.Items(Id),
        CONSTRAINT FK_DemandRequestItems_Branches FOREIGN KEY (BranchId) REFERENCES dbo.Branches(Id),
        CONSTRAINT FK_DemandRequestItems_StockTypes FOREIGN KEY (StockTypeId) REFERENCES dbo.StockTypes(StockTypeId)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'DemandRequestStatuses' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.DemandRequestStatuses
    (
        DemandRequestStatusId INT IDENTITY(1,1) PRIMARY KEY,
        StatusName NVARCHAR(100) NOT NULL,
        Description NVARCHAR(MAX) NULL,
        IsActive BIT NOT NULL CONSTRAINT DF_DemandRequestStatuses_IsActive DEFAULT (1),
        CreatedOn DATETIME2 NOT NULL CONSTRAINT DF_DemandRequestStatuses_CreatedOn DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT UQ_DemandRequestStatuses_StatusName UNIQUE (StatusName)
    );
END
GO

IF COL_LENGTH('dbo.DemandRequestStatuses', 'Description') IS NULL
BEGIN
    ALTER TABLE dbo.DemandRequestStatuses
    ADD Description NVARCHAR(MAX) NULL;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'DemandRequestLifeCycles' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.DemandRequestLifeCycles
    (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        DemandRequestId INT NOT NULL,
        DemandRequestStatusId INT NOT NULL,
        UserId INT NULL,
        ActionByName NVARCHAR(150) NULL,
        CreatedOn DATETIME2 NOT NULL CONSTRAINT DF_DemandRequestLifeCycles_CreatedOn DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT FK_DemandRequestLifeCycles_DemandRequests FOREIGN KEY (DemandRequestId) REFERENCES dbo.DemandRequests(DemandRequestId),
        CONSTRAINT FK_DemandRequestLifeCycles_DemandRequestStatuses FOREIGN KEY (DemandRequestStatusId) REFERENCES dbo.DemandRequestStatuses(DemandRequestStatusId)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_DemandRequestLifeCycles_DemandRequestId' AND object_id = OBJECT_ID('dbo.DemandRequestLifeCycles'))
BEGIN
    CREATE INDEX IX_DemandRequestLifeCycles_DemandRequestId ON dbo.DemandRequestLifeCycles(DemandRequestId);
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.DemandRequestStatuses WHERE StatusName = 'Draft')
BEGIN
    INSERT INTO dbo.DemandRequestStatuses (StatusName, Description, IsActive)
    VALUES ('Draft', 'Draft', 1);
END
GO

UPDATE dbo.DemandRequestStatuses
SET Description = 'Draft'
WHERE StatusName = 'Draft' AND (Description IS NULL OR LTRIM(RTRIM(Description)) = '');
GO

IF NOT EXISTS (SELECT 1 FROM dbo.DemandRequestStatuses WHERE StatusName = 'Pending')
BEGIN
    INSERT INTO dbo.DemandRequestStatuses (StatusName, Description, IsActive)
    VALUES ('Pending', 'Pending', 1);
END
GO

UPDATE dbo.DemandRequestStatuses
SET Description = 'Pending'
WHERE StatusName = 'Pending' AND (Description IS NULL OR LTRIM(RTRIM(Description)) = '');
GO

IF NOT EXISTS (SELECT 1 FROM dbo.DemandRequestStatuses WHERE StatusName = 'Approved')
BEGIN
    INSERT INTO dbo.DemandRequestStatuses (StatusName, Description, IsActive)
    VALUES ('Approved', 'Approved', 1);
END
GO

UPDATE dbo.DemandRequestStatuses
SET Description = 'Approved'
WHERE StatusName = 'Approved' AND (Description IS NULL OR LTRIM(RTRIM(Description)) = '');
GO

IF NOT EXISTS (SELECT 1 FROM dbo.DemandRequestStatuses WHERE StatusName = 'Issued')
BEGIN
    INSERT INTO dbo.DemandRequestStatuses (StatusName, Description, IsActive)
    VALUES ('Issued', 'Issued', 1);
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.DemandRequestStatuses WHERE StatusName = 'Issue')
BEGIN
    INSERT INTO dbo.DemandRequestStatuses (StatusName, Description, IsActive)
    VALUES ('Issue', 'Issue', 1);
END
GO

UPDATE dbo.DemandRequestStatuses
SET Description = 'Issued'
WHERE StatusName = 'Issued' AND (Description IS NULL OR LTRIM(RTRIM(Description)) = '');
GO

IF NOT EXISTS (SELECT 1 FROM dbo.DemandRequestStatuses WHERE StatusName = 'Print Detail')
BEGIN
    INSERT INTO dbo.DemandRequestStatuses (StatusName, Description, IsActive)
    VALUES ('Print Detail', 'Print Detail', 1);
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.DemandRequestStatuses WHERE StatusName = 'Partial Issued')
BEGIN
    INSERT INTO dbo.DemandRequestStatuses (StatusName, Description, IsActive)
    VALUES ('Partial Issued', 'Partial Issued', 1);
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.DemandRequestStatuses WHERE StatusName = 'Received')
BEGIN
    INSERT INTO dbo.DemandRequestStatuses (StatusName, Description, IsActive)
    VALUES ('Received', 'Received', 1);
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.DemandRequestStatuses WHERE StatusName = 'Rejected')
BEGIN
    INSERT INTO dbo.DemandRequestStatuses (StatusName, Description, IsActive)
    VALUES ('Rejected', 'Rejected', 1);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_DemandRequestItems_DemandRequestId' AND object_id = OBJECT_ID('dbo.DemandRequestItems'))
BEGIN
    CREATE INDEX IX_DemandRequestItems_DemandRequestId ON dbo.DemandRequestItems(DemandRequestId);
END
GO

DECLARE @RicBranchId INT = (SELECT TOP 1 Id FROM dbo.Branches WHERE Name = 'Rawalpindi Institute of Cardiology' ORDER BY Id);
DECLARE @EmergencyBranchId INT = (SELECT TOP 1 Id FROM dbo.Branches WHERE Name = 'Cardiac Emergency Unit' ORDER BY Id);
DECLARE @EchoStoreId INT = (SELECT TOP 1 StoreId FROM dbo.Stores WHERE StoreName = 'Echo Store' ORDER BY StoreId);
DECLARE @CentralSupplyStoreId INT = (SELECT TOP 1 StoreId FROM dbo.Stores WHERE StoreName = 'Central Supply Store' ORDER BY StoreId);
DECLARE @MedicineStoreId INT = (SELECT TOP 1 StoreId FROM dbo.Stores WHERE StoreName = 'Medicine Store' ORDER BY StoreId);
DECLARE @MainStockAccessoriesStoreId INT = (SELECT TOP 1 StoreId FROM dbo.Stores WHERE StoreName = 'Main Stock & Accessories Store' ORDER BY StoreId);
DECLARE @MainDisposableStoreId INT = (SELECT TOP 1 StoreId FROM dbo.Stores WHERE StoreName = 'Main Disposable Store' ORDER BY StoreId);
DECLARE @DefaultStockTypeId INT = (SELECT TOP 1 StockTypeId FROM dbo.StockTypes WHERE IsActive = 1 ORDER BY StockTypeId);
DECLARE @ElectrodeItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = 'ECG Electrodes' ORDER BY Id);
DECLARE @SyringeItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = 'Syringe 10ml' ORDER BY Id);
DECLARE @CannulaItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = 'IV Cannula 20G' ORDER BY Id);
DECLARE @XylocaineItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = 'Solution Xylocaine 4% (Lidocaine HCL) 50mL' ORDER BY Id);
DECLARE @BatteryItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = 'battery 12v - 7Ah' ORDER BY Id);
DECLARE @EchoProbeItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = 'ECHO Probe (30BT)' ORDER BY Id);
DECLARE @ConsumablesItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = 'Disposable Face Mask, Polythene Gloves, Gauze Roll' ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM dbo.DemandRequests WHERE DRNo = 'DR-0001')
BEGIN
    INSERT INTO dbo.DemandRequests
    (
        DRNo,
        IndentNo,
        DateFrom,
        DateTo,
        BranchId,
        RequestingStoreId,
        RequestedStoreId,
        StockTypeId,
        Status,
        Remarks,
        IsActive,
        CreatedById,
        CreatedOn
    )
    VALUES
    (
        'DR-0001',
        'IND-0001',
        DATEADD(DAY, -2, SYSUTCDATETIME()),
        DATEADD(DAY, 5, SYSUTCDATETIME()),
        @RicBranchId,
        @EchoStoreId,
        @EchoStoreId,
        @DefaultStockTypeId,
        'Pending',
        'Urgent replenishment for echo lab consumables.',
        1,
        1,
        DATEADD(HOUR, -6, SYSUTCDATETIME())
    );

    DECLARE @DemandRequestId1 INT = CAST(SCOPE_IDENTITY() AS INT);

    INSERT INTO dbo.DemandRequestItems
    (
        DemandRequestId,
        ItemId,
        RequestedQuantity,
        ApprovedQuantity,
        BranchId,
        IsActive,
        CreatedById,
        CreatedOn,
        Remarks,
        StockTypeId,
        IssuedQuantity,
        IssuingQuantity,
        RemainingQuantity
    )
    VALUES
    (@DemandRequestId1, @ElectrodeItemId, 120, 0, @RicBranchId, 1, 1, DATEADD(HOUR, -6, SYSUTCDATETIME()), 'For OPD and echo diagnostics', @DefaultStockTypeId, 0, 0, 120),
    (@DemandRequestId1, @SyringeItemId, 80, 0, @RicBranchId, 1, 1, DATEADD(HOUR, -6, SYSUTCDATETIME()), 'For contrast administration', @DefaultStockTypeId, 0, 0, 80);

    INSERT INTO dbo.DemandRequestLifeCycles
    (
        DemandRequestId,
        DemandRequestStatusId,
        UserId,
        ActionByName,
        CreatedOn
    )
    SELECT @DemandRequestId1, drs.DemandRequestStatusId, NULL, 'Miss Ruth Yaqoob', DATEADD(HOUR, -9, SYSUTCDATETIME())
    FROM dbo.DemandRequestStatuses drs
    WHERE drs.StatusName = 'Draft';

    INSERT INTO dbo.DemandRequestLifeCycles
    (
        DemandRequestId,
        DemandRequestStatusId,
        UserId,
        ActionByName,
        CreatedOn
    )
    SELECT @DemandRequestId1, drs.DemandRequestStatusId, NULL, 'Miss Ruth Yaqoob', DATEADD(HOUR, -6, SYSUTCDATETIME())
    FROM dbo.DemandRequestStatuses drs
    WHERE drs.StatusName = 'Pending';
END
GO

DECLARE @EmergencyBranchId INT = (SELECT TOP 1 Id FROM dbo.Branches WHERE Name = 'Cardiac Emergency Unit' ORDER BY Id);
DECLARE @CentralSupplyStoreId INT = (SELECT TOP 1 StoreId FROM dbo.Stores WHERE StoreName = 'Central Supply Store' ORDER BY StoreId);
DECLARE @DefaultStockTypeId INT = (SELECT TOP 1 StockTypeId FROM dbo.StockTypes WHERE IsActive = 1 ORDER BY StockTypeId);
DECLARE @CannulaItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = 'IV Cannula 20G' ORDER BY Id);
DECLARE @SyringeItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = 'Syringe 10ml' ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM dbo.DemandRequests WHERE DRNo = 'DR-0002')
BEGIN
    INSERT INTO dbo.DemandRequests
    (
        DRNo,
        IndentNo,
        DateFrom,
        DateTo,
        BranchId,
        RequestingStoreId,
        RequestedStoreId,
        StockTypeId,
        Status,
        Remarks,
        IsActive,
        CreatedById,
        CreatedOn
    )
    VALUES
    (
        'DR-0002',
        'IND-0002',
        DATEADD(DAY, -1, SYSUTCDATETIME()),
        DATEADD(DAY, 3, SYSUTCDATETIME()),
        @EmergencyBranchId,
        @CentralSupplyStoreId,
        @CentralSupplyStoreId,
        @DefaultStockTypeId,
        'Approved',
        'Emergency unit floor stock top-up.',
        1,
        1,
        DATEADD(HOUR, -2, SYSUTCDATETIME())
    );

    DECLARE @DemandRequestId2 INT = CAST(SCOPE_IDENTITY() AS INT);

    INSERT INTO dbo.DemandRequestItems
    (
        DemandRequestId,
        ItemId,
        RequestedQuantity,
        ApprovedQuantity,
        BranchId,
        IsActive,
        CreatedById,
        CreatedOn,
        Remarks,
        StockTypeId,
        IssuedQuantity,
        IssuingQuantity,
        RemainingQuantity
    )
    VALUES
    (@DemandRequestId2, @CannulaItemId, 60, 60, @EmergencyBranchId, 1, 1, DATEADD(HOUR, -2, SYSUTCDATETIME()), 'Approved for emergency crash cart refill', @DefaultStockTypeId, 20, 10, 40),
    (@DemandRequestId2, @SyringeItemId, 150, 100, @EmergencyBranchId, 1, 1, DATEADD(HOUR, -2, SYSUTCDATETIME()), 'Partial issue already started', @DefaultStockTypeId, 40, 20, 110);

    INSERT INTO dbo.DemandRequestLifeCycles
    (
        DemandRequestId,
        DemandRequestStatusId,
        UserId,
        ActionByName,
        CreatedOn
    )
    SELECT @DemandRequestId2, drs.DemandRequestStatusId, NULL, 'Miss Ruth Yaqoob', DATEADD(HOUR, -5, SYSUTCDATETIME())
    FROM dbo.DemandRequestStatuses drs
    WHERE drs.StatusName = 'Draft';

    INSERT INTO dbo.DemandRequestLifeCycles
    (
        DemandRequestId,
        DemandRequestStatusId,
        UserId,
        ActionByName,
        CreatedOn
    )
    SELECT @DemandRequestId2, drs.DemandRequestStatusId, NULL, 'Miss Ruth Yaqoob', DATEADD(HOUR, -3, SYSUTCDATETIME())
    FROM dbo.DemandRequestStatuses drs
    WHERE drs.StatusName = 'Pending';

    INSERT INTO dbo.DemandRequestLifeCycles
    (
        DemandRequestId,
        DemandRequestStatusId,
        UserId,
        ActionByName,
        CreatedOn
    )
    SELECT @DemandRequestId2, drs.DemandRequestStatusId, NULL, 'Dr Ayesha Siddiqua', DATEADD(HOUR, -2, SYSUTCDATETIME())
    FROM dbo.DemandRequestStatuses drs
    WHERE drs.StatusName = 'Approved';
END
GO

DECLARE @RicBranchId INT = (SELECT TOP 1 Id FROM dbo.Branches WHERE Name = 'Rawalpindi Institute of Cardiology' ORDER BY Id);
DECLARE @EchoStoreId INT = (SELECT TOP 1 StoreId FROM dbo.Stores WHERE StoreName = 'Echo Store' ORDER BY StoreId);
DECLARE @MedicineStoreId INT = (SELECT TOP 1 StoreId FROM dbo.Stores WHERE StoreName = 'Medicine Store' ORDER BY StoreId);
DECLARE @DefaultStockTypeId INT = (SELECT TOP 1 StockTypeId FROM dbo.StockTypes WHERE IsActive = 1 ORDER BY StockTypeId);
DECLARE @XylocaineItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = 'Solution Xylocaine 4% (Lidocaine HCL) 50mL' ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM dbo.DemandRequests WHERE DRNo = 'DR-0401AAAE6932')
BEGIN
    INSERT INTO dbo.DemandRequests
    (
        DRNo,
        IndentNo,
        DateFrom,
        DateTo,
        BranchId,
        RequestingStoreId,
        RequestedStoreId,
        StockTypeId,
        Status,
        Remarks,
        IsActive,
        CreatedById,
        CreatedOn
    )
    VALUES
    (
        'DR-0401AAAE6932',
        '105100',
        '2024-12-12T08:58:00',
        '2024-12-14T13:32:00',
        @RicBranchId,
        @EchoStoreId,
        @MedicineStoreId,
        @DefaultStockTypeId,
        'Issued',
        'Primary receive stock test request.',
        1,
        1,
        '2024-12-12T08:58:00'
    );

    DECLARE @DemandRequestId3 INT = CAST(SCOPE_IDENTITY() AS INT);

    INSERT INTO dbo.DemandRequestItems
    (
        DemandRequestId,
        ItemId,
        RequestedQuantity,
        ApprovedQuantity,
        BranchId,
        IsActive,
        CreatedById,
        CreatedOn,
        Remarks,
        StockTypeId,
        IssuedQuantity,
        IssuingQuantity,
        RemainingQuantity
    )
    VALUES
    (@DemandRequestId3, @XylocaineItemId, 2, 2, @RicBranchId, 1, 1, '2024-12-12T08:58:00', 'Issued to Medicine Store', @DefaultStockTypeId, 2, 2, 0);

    INSERT INTO dbo.DemandRequestLifeCycles (DemandRequestId, DemandRequestStatusId, UserId, ActionByName, CreatedOn)
    SELECT @DemandRequestId3, drs.DemandRequestStatusId, NULL, 'Miss Sonia Fiaz', '2024-12-12T08:58:00'
    FROM dbo.DemandRequestStatuses drs WHERE drs.StatusName = 'Draft';

    INSERT INTO dbo.DemandRequestLifeCycles (DemandRequestId, DemandRequestStatusId, UserId, ActionByName, CreatedOn)
    SELECT @DemandRequestId3, drs.DemandRequestStatusId, NULL, 'Miss Sonia Fiaz', '2024-12-12T08:58:00'
    FROM dbo.DemandRequestStatuses drs WHERE drs.StatusName = 'Pending';

    INSERT INTO dbo.DemandRequestLifeCycles (DemandRequestId, DemandRequestStatusId, UserId, ActionByName, CreatedOn)
    SELECT @DemandRequestId3, drs.DemandRequestStatusId, NULL, 'Mr. Jalil Ahmed', '2024-12-13T10:25:00'
    FROM dbo.DemandRequestStatuses drs WHERE drs.StatusName = 'Pending';

    INSERT INTO dbo.DemandRequestLifeCycles (DemandRequestId, DemandRequestStatusId, UserId, ActionByName, CreatedOn)
    SELECT @DemandRequestId3, drs.DemandRequestStatusId, NULL, 'Mr. Jalil Ahmed', '2024-12-14T13:32:00'
    FROM dbo.DemandRequestStatuses drs WHERE drs.StatusName = 'Approved';

    INSERT INTO dbo.DemandRequestLifeCycles (DemandRequestId, DemandRequestStatusId, UserId, ActionByName, CreatedOn)
    SELECT @DemandRequestId3, drs.DemandRequestStatusId, NULL, 'Mr. Jalil Ahmed', '2024-12-14T13:32:00'
    FROM dbo.DemandRequestStatuses drs WHERE drs.StatusName = 'Issue';
END
GO

DECLARE @RicBranchId INT = (SELECT TOP 1 Id FROM dbo.Branches WHERE Name = 'Rawalpindi Institute of Cardiology' ORDER BY Id);
DECLARE @EchoStoreId INT = (SELECT TOP 1 StoreId FROM dbo.Stores WHERE StoreName = 'Echo Store' ORDER BY StoreId);
DECLARE @MainStockAccessoriesStoreId INT = (SELECT TOP 1 StoreId FROM dbo.Stores WHERE StoreName = 'Main Stock & Accessories Store' ORDER BY StoreId);
DECLARE @DefaultStockTypeId INT = (SELECT TOP 1 StockTypeId FROM dbo.StockTypes WHERE IsActive = 1 ORDER BY StockTypeId);
DECLARE @BatteryItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = 'battery 12v - 7Ah' ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM dbo.DemandRequests WHERE DRNo = 'DR-0401AAAD5224')
BEGIN
    INSERT INTO dbo.DemandRequests
    (
        DRNo,
        IndentNo,
        DateFrom,
        DateTo,
        BranchId,
        RequestingStoreId,
        RequestedStoreId,
        StockTypeId,
        Status,
        Remarks,
        IsActive,
        CreatedById,
        CreatedOn
    )
    VALUES
    (
        'DR-0401AAAD5224',
        '105116',
        '2024-05-28T09:00:00',
        '2024-05-29T13:19:00',
        @RicBranchId,
        @EchoStoreId,
        @MainStockAccessoriesStoreId,
        @DefaultStockTypeId,
        'Issued',
        'Stock issuance for accessories store.',
        1,
        1,
        '2024-05-28T09:00:00'
    );

    DECLARE @DemandRequestId4 INT = CAST(SCOPE_IDENTITY() AS INT);

    INSERT INTO dbo.DemandRequestItems
    (
        DemandRequestId,
        ItemId,
        RequestedQuantity,
        ApprovedQuantity,
        BranchId,
        IsActive,
        CreatedById,
        CreatedOn,
        Remarks,
        StockTypeId,
        IssuedQuantity,
        IssuingQuantity,
        RemainingQuantity
    )
    VALUES
    (@DemandRequestId4, @BatteryItemId, 1, 1, @RicBranchId, 1, 1, '2024-05-28T09:00:00', 'Issued battery item', @DefaultStockTypeId, 1, 1, 0);
END
GO

DECLARE @RicBranchId INT = (SELECT TOP 1 Id FROM dbo.Branches WHERE Name = 'Rawalpindi Institute of Cardiology' ORDER BY Id);
DECLARE @EchoStoreId INT = (SELECT TOP 1 StoreId FROM dbo.Stores WHERE StoreName = 'Echo Store' ORDER BY StoreId);
DECLARE @MainStockAccessoriesStoreId INT = (SELECT TOP 1 StoreId FROM dbo.Stores WHERE StoreName = 'Main Stock & Accessories Store' ORDER BY StoreId);
DECLARE @DefaultStockTypeId INT = (SELECT TOP 1 StockTypeId FROM dbo.StockTypes WHERE IsActive = 1 ORDER BY StockTypeId);
DECLARE @EchoProbeItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = 'ECHO Probe (30BT)' ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM dbo.DemandRequests WHERE DRNo = 'DR-0401AAAE5550')
BEGIN
    INSERT INTO dbo.DemandRequests
    (
        DRNo,
        IndentNo,
        DateFrom,
        DateTo,
        BranchId,
        RequestingStoreId,
        RequestedStoreId,
        StockTypeId,
        Status,
        Remarks,
        IsActive,
        CreatedById,
        CreatedOn
    )
    VALUES
    (
        'DR-0401AAAE5550',
        '105173',
        '2024-10-17T08:30:00',
        '2024-10-18T09:56:00',
        @RicBranchId,
        @EchoStoreId,
        @MainStockAccessoriesStoreId,
        @DefaultStockTypeId,
        'Issued',
        'Issued echo probe item.',
        1,
        1,
        '2024-10-17T08:30:00'
    );

    DECLARE @DemandRequestId5 INT = CAST(SCOPE_IDENTITY() AS INT);

    INSERT INTO dbo.DemandRequestItems
    (
        DemandRequestId,
        ItemId,
        RequestedQuantity,
        ApprovedQuantity,
        BranchId,
        IsActive,
        CreatedById,
        CreatedOn,
        Remarks,
        StockTypeId,
        IssuedQuantity,
        IssuingQuantity,
        RemainingQuantity
    )
    VALUES
    (@DemandRequestId5, @EchoProbeItemId, 1, 1, @RicBranchId, 1, 1, '2024-10-17T08:30:00', 'Issued echo probe', @DefaultStockTypeId, 1, 1, 0);
END
GO

DECLARE @RicBranchId INT = (SELECT TOP 1 Id FROM dbo.Branches WHERE Name = 'Rawalpindi Institute of Cardiology' ORDER BY Id);
DECLARE @EchoStoreId INT = (SELECT TOP 1 StoreId FROM dbo.Stores WHERE StoreName = 'Echo Store' ORDER BY StoreId);
DECLARE @MainDisposableStoreId INT = (SELECT TOP 1 StoreId FROM dbo.Stores WHERE StoreName = 'Main Disposable Store' ORDER BY StoreId);
DECLARE @DefaultStockTypeId INT = (SELECT TOP 1 StockTypeId FROM dbo.StockTypes WHERE IsActive = 1 ORDER BY StockTypeId);
DECLARE @ConsumablesItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = 'Disposable Face Mask, Polythene Gloves, Gauze Roll' ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM dbo.DemandRequests WHERE DRNo = 'DR-0401AAAD5656')
BEGIN
    INSERT INTO dbo.DemandRequests
    (
        DRNo,
        IndentNo,
        DateFrom,
        DateTo,
        BranchId,
        RequestingStoreId,
        RequestedStoreId,
        StockTypeId,
        Status,
        Remarks,
        IsActive,
        CreatedById,
        CreatedOn
    )
    VALUES
    (
        'DR-0401AAAD5656',
        '105122',
        '2024-06-12T10:00:00',
        '2024-06-14T11:05:00',
        @RicBranchId,
        @EchoStoreId,
        @MainDisposableStoreId,
        @DefaultStockTypeId,
        'Issued',
        'Issued consumables request.',
        1,
        1,
        '2024-06-12T10:00:00'
    );

    DECLARE @DemandRequestId6 INT = CAST(SCOPE_IDENTITY() AS INT);

    INSERT INTO dbo.DemandRequestItems
    (
        DemandRequestId,
        ItemId,
        RequestedQuantity,
        ApprovedQuantity,
        BranchId,
        IsActive,
        CreatedById,
        CreatedOn,
        Remarks,
        StockTypeId,
        IssuedQuantity,
        IssuingQuantity,
        RemainingQuantity
    )
    VALUES
    (@DemandRequestId6, @ConsumablesItemId, 6, 6, @RicBranchId, 1, 1, '2024-06-12T10:00:00', 'Issued disposable consumables', @DefaultStockTypeId, 6, 6, 0);
END
GO

DECLARE @RicBranchId INT = (SELECT TOP 1 Id FROM dbo.Branches WHERE Name = 'Rawalpindi Institute of Cardiology' ORDER BY Id);
DECLARE @EchoStoreId INT = (SELECT TOP 1 StoreId FROM dbo.Stores WHERE StoreName = 'Echo Store' ORDER BY StoreId);
DECLARE @MedicineStoreId INT = (SELECT TOP 1 StoreId FROM dbo.Stores WHERE StoreName = 'Medicine Store' ORDER BY StoreId);
DECLARE @MainStockAccessoriesStoreId INT = (SELECT TOP 1 StoreId FROM dbo.Stores WHERE StoreName = 'Main Stock & Accessories Store' ORDER BY StoreId);
DECLARE @MainDisposableStoreId INT = (SELECT TOP 1 StoreId FROM dbo.Stores WHERE StoreName = 'Main Disposable Store' ORDER BY StoreId);
DECLARE @DefaultStockTypeId INT = (SELECT TOP 1 StockTypeId FROM dbo.StockTypes WHERE IsActive = 1 ORDER BY StockTypeId);
DECLARE @ElectrodeItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = 'ECG Electrodes' ORDER BY Id);
DECLARE @SyringeItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = 'Syringe 10ml' ORDER BY Id);
DECLARE @XylocaineItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = 'Solution Xylocaine 4% (Lidocaine HCL) 50mL' ORDER BY Id);
DECLARE @EchoProbeItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = 'ECHO Probe (30BT)' ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM dbo.DemandRequests WHERE DRNo = 'DR-0401AAAR1001')
BEGIN
    INSERT INTO dbo.DemandRequests
    (
        DRNo,
        IndentNo,
        DateFrom,
        DateTo,
        BranchId,
        RequestingStoreId,
        RequestedStoreId,
        StockTypeId,
        Status,
        Remarks,
        IsActive,
        CreatedById,
        CreatedOn,
        ModifiedById,
        ModifiedOn
    )
    VALUES
    (
        'DR-0401AAAR1001',
        '106001',
        '2025-02-20T08:59:00',
        '2025-02-27T08:15:00',
        @RicBranchId,
        @EchoStoreId,
        @MedicineStoreId,
        @DefaultStockTypeId,
        'Received',
        'Received stock status test record.',
        1,
        1,
        '2025-02-20T08:59:00',
        1,
        '2025-02-27T08:15:00'
    );

    DECLARE @DemandRequestId7 INT = CAST(SCOPE_IDENTITY() AS INT);

    INSERT INTO dbo.DemandRequestItems
    (
        DemandRequestId,
        ItemId,
        RequestedQuantity,
        ApprovedQuantity,
        BranchId,
        IsActive,
        CreatedById,
        CreatedOn,
        ModifiedById,
        ModifiedOn,
        Remarks,
        StockTypeId,
        IssuedQuantity,
        IssuingQuantity,
        RemainingQuantity
    )
    VALUES
    (@DemandRequestId7, @ElectrodeItemId, 12, 10, @RicBranchId, 1, 1, '2025-02-20T08:59:00', 1, '2025-02-27T08:15:00', 'Received ECG electrodes', @DefaultStockTypeId, 10, 10, 0),
    (@DemandRequestId7, @SyringeItemId, 8, 8, @RicBranchId, 1, 1, '2025-02-20T08:59:00', 1, '2025-02-27T08:15:00', 'Received syringes', @DefaultStockTypeId, 8, 8, 0);

    INSERT INTO dbo.DemandRequestLifeCycles (DemandRequestId, DemandRequestStatusId, UserId, ActionByName, CreatedOn)
    SELECT @DemandRequestId7, drs.DemandRequestStatusId, NULL, 'Miss Mehreen Ashraf', '2025-02-20T08:59:00'
    FROM dbo.DemandRequestStatuses drs WHERE drs.StatusName = 'Pending';

    INSERT INTO dbo.DemandRequestLifeCycles (DemandRequestId, DemandRequestStatusId, UserId, ActionByName, CreatedOn)
    SELECT @DemandRequestId7, drs.DemandRequestStatusId, NULL, 'Mr. Muhammad Waqas Rizvi', '2025-02-20T13:40:00'
    FROM dbo.DemandRequestStatuses drs WHERE drs.StatusName = 'Approved';

    INSERT INTO dbo.DemandRequestLifeCycles (DemandRequestId, DemandRequestStatusId, UserId, ActionByName, CreatedOn)
    SELECT @DemandRequestId7, drs.DemandRequestStatusId, NULL, 'Mr. Muhammad Waqas Rizvi', '2025-02-20T13:45:00'
    FROM dbo.DemandRequestStatuses drs WHERE drs.StatusName = 'Issue';

    INSERT INTO dbo.DemandRequestLifeCycles (DemandRequestId, DemandRequestStatusId, UserId, ActionByName, CreatedOn)
    SELECT @DemandRequestId7, drs.DemandRequestStatusId, NULL, 'Miss Mehreen Ashraf', '2025-02-27T08:15:00'
    FROM dbo.DemandRequestStatuses drs WHERE drs.StatusName = 'Received';
END
GO

DECLARE @RicBranchId INT = (SELECT TOP 1 Id FROM dbo.Branches WHERE Name = 'Rawalpindi Institute of Cardiology' ORDER BY Id);
DECLARE @EchoStoreId INT = (SELECT TOP 1 StoreId FROM dbo.Stores WHERE StoreName = 'Echo Store' ORDER BY StoreId);
DECLARE @MainStockAccessoriesStoreId INT = (SELECT TOP 1 StoreId FROM dbo.Stores WHERE StoreName = 'Main Stock & Accessories Store' ORDER BY StoreId);
DECLARE @DefaultStockTypeId INT = (SELECT TOP 1 StockTypeId FROM dbo.StockTypes WHERE IsActive = 1 ORDER BY StockTypeId);
DECLARE @XylocaineItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = 'Solution Xylocaine 4% (Lidocaine HCL) 50mL' ORDER BY Id);
DECLARE @EchoProbeItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = 'ECHO Probe (30BT)' ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM dbo.DemandRequests WHERE DRNo = 'DR-0401AAAR1002')
BEGIN
    INSERT INTO dbo.DemandRequests
    (
        DRNo,
        IndentNo,
        DateFrom,
        DateTo,
        BranchId,
        RequestingStoreId,
        RequestedStoreId,
        StockTypeId,
        Status,
        Remarks,
        IsActive,
        CreatedById,
        CreatedOn,
        ModifiedById,
        ModifiedOn
    )
    VALUES
    (
        'DR-0401AAAR1002',
        '106002',
        '2024-05-25T09:15:00',
        '2024-05-25T09:37:00',
        @RicBranchId,
        @EchoStoreId,
        @MainStockAccessoriesStoreId,
        @DefaultStockTypeId,
        'Received',
        'Second received stock test record.',
        1,
        1,
        '2024-05-25T09:15:00',
        1,
        '2024-05-25T09:37:00'
    );

    DECLARE @DemandRequestId8 INT = CAST(SCOPE_IDENTITY() AS INT);

    INSERT INTO dbo.DemandRequestItems
    (
        DemandRequestId,
        ItemId,
        RequestedQuantity,
        ApprovedQuantity,
        BranchId,
        IsActive,
        CreatedById,
        CreatedOn,
        ModifiedById,
        ModifiedOn,
        Remarks,
        StockTypeId,
        IssuedQuantity,
        IssuingQuantity,
        RemainingQuantity
    )
    VALUES
    (@DemandRequestId8, @XylocaineItemId, 3, 3, @RicBranchId, 1, 1, '2024-05-25T09:15:00', 1, '2024-05-25T09:37:00', 'Received xylocaine solution', @DefaultStockTypeId, 3, 3, 0),
    (@DemandRequestId8, @EchoProbeItemId, 1, 1, @RicBranchId, 1, 1, '2024-05-25T09:15:00', 1, '2024-05-25T09:37:00', 'Received echo probe', @DefaultStockTypeId, 1, 1, 0);

    INSERT INTO dbo.DemandRequestLifeCycles (DemandRequestId, DemandRequestStatusId, UserId, ActionByName, CreatedOn)
    SELECT @DemandRequestId8, drs.DemandRequestStatusId, NULL, 'Miss Mehreen Ashraf', '2024-05-25T09:15:00'
    FROM dbo.DemandRequestStatuses drs WHERE drs.StatusName = 'Pending';

    INSERT INTO dbo.DemandRequestLifeCycles (DemandRequestId, DemandRequestStatusId, UserId, ActionByName, CreatedOn)
    SELECT @DemandRequestId8, drs.DemandRequestStatusId, NULL, 'Mr. Muhammad Waqas Rizvi', '2024-05-25T09:25:00'
    FROM dbo.DemandRequestStatuses drs WHERE drs.StatusName = 'Approved';

    INSERT INTO dbo.DemandRequestLifeCycles (DemandRequestId, DemandRequestStatusId, UserId, ActionByName, CreatedOn)
    SELECT @DemandRequestId8, drs.DemandRequestStatusId, NULL, 'Mr. Muhammad Waqas Rizvi', '2024-05-25T09:30:00'
    FROM dbo.DemandRequestStatuses drs WHERE drs.StatusName = 'Issue';

    INSERT INTO dbo.DemandRequestLifeCycles (DemandRequestId, DemandRequestStatusId, UserId, ActionByName, CreatedOn)
    SELECT @DemandRequestId8, drs.DemandRequestStatusId, NULL, 'Miss Mehreen Ashraf', '2024-05-25T09:37:00'
    FROM dbo.DemandRequestStatuses drs WHERE drs.StatusName = 'Received';
END
GO

DECLARE @RicBranchId INT = (SELECT TOP 1 Id FROM dbo.Branches WHERE Name = 'Rawalpindi Institute of Cardiology' ORDER BY Id);
DECLARE @EchoStoreId INT = (SELECT TOP 1 StoreId FROM dbo.Stores WHERE StoreName = 'Echo Store' ORDER BY StoreId);
DECLARE @MainDisposableStoreId INT = (SELECT TOP 1 StoreId FROM dbo.Stores WHERE StoreName = 'Main Disposable Store' ORDER BY StoreId);
DECLARE @DefaultStockTypeId INT = (SELECT TOP 1 StockTypeId FROM dbo.StockTypes WHERE IsActive = 1 ORDER BY StockTypeId);
DECLARE @SyringeItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = 'Syringe 10ml' ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM dbo.DemandRequests WHERE DRNo = 'DR-0401AAAR1003')
BEGIN
    INSERT INTO dbo.DemandRequests
    (
        DRNo,
        IndentNo,
        DateFrom,
        DateTo,
        BranchId,
        RequestingStoreId,
        RequestedStoreId,
        StockTypeId,
        Status,
        Remarks,
        IsActive,
        CreatedById,
        CreatedOn,
        ModifiedById,
        ModifiedOn
    )
    VALUES
    (
        'DR-0401AAAR1003',
        '106003',
        '2024-03-12T08:20:00',
        '2024-03-12T08:56:00',
        @RicBranchId,
        @EchoStoreId,
        @MainDisposableStoreId,
        @DefaultStockTypeId,
        'Received',
        'Third received stock test record.',
        1,
        1,
        '2024-03-12T08:20:00',
        1,
        '2024-03-12T08:56:00'
    );

    DECLARE @DemandRequestId9 INT = CAST(SCOPE_IDENTITY() AS INT);

    INSERT INTO dbo.DemandRequestItems
    (
        DemandRequestId,
        ItemId,
        RequestedQuantity,
        ApprovedQuantity,
        BranchId,
        IsActive,
        CreatedById,
        CreatedOn,
        ModifiedById,
        ModifiedOn,
        Remarks,
        StockTypeId,
        IssuedQuantity,
        IssuingQuantity,
        RemainingQuantity
    )
    VALUES
    (@DemandRequestId9, @SyringeItemId, 25, 20, @RicBranchId, 1, 1, '2024-03-12T08:20:00', 1, '2024-03-12T08:56:00', 'Received syringes for disposable store', @DefaultStockTypeId, 20, 20, 0);

    INSERT INTO dbo.DemandRequestLifeCycles (DemandRequestId, DemandRequestStatusId, UserId, ActionByName, CreatedOn)
    SELECT @DemandRequestId9, drs.DemandRequestStatusId, NULL, 'Miss Mehreen Ashraf', '2024-03-12T08:20:00'
    FROM dbo.DemandRequestStatuses drs WHERE drs.StatusName = 'Pending';

    INSERT INTO dbo.DemandRequestLifeCycles (DemandRequestId, DemandRequestStatusId, UserId, ActionByName, CreatedOn)
    SELECT @DemandRequestId9, drs.DemandRequestStatusId, NULL, 'Mr. Muhammad Waqas Rizvi', '2024-03-12T08:35:00'
    FROM dbo.DemandRequestStatuses drs WHERE drs.StatusName = 'Approved';

    INSERT INTO dbo.DemandRequestLifeCycles (DemandRequestId, DemandRequestStatusId, UserId, ActionByName, CreatedOn)
    SELECT @DemandRequestId9, drs.DemandRequestStatusId, NULL, 'Mr. Muhammad Waqas Rizvi', '2024-03-12T08:44:00'
    FROM dbo.DemandRequestStatuses drs WHERE drs.StatusName = 'Issue';

    INSERT INTO dbo.DemandRequestLifeCycles (DemandRequestId, DemandRequestStatusId, UserId, ActionByName, CreatedOn)
    SELECT @DemandRequestId9, drs.DemandRequestStatusId, NULL, 'Miss Mehreen Ashraf', '2024-03-12T08:56:00'
    FROM dbo.DemandRequestStatuses drs WHERE drs.StatusName = 'Received';
END
GO

DECLARE @DemandRequestIdSeed1 INT = (SELECT TOP 1 DemandRequestId FROM dbo.DemandRequests WHERE DRNo = 'DR-0001');

IF @DemandRequestIdSeed1 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.DemandRequestLifeCycles WHERE DemandRequestId = @DemandRequestIdSeed1)
BEGIN
    INSERT INTO dbo.DemandRequestLifeCycles
    (
        DemandRequestId,
        DemandRequestStatusId,
        UserId,
        ActionByName,
        CreatedOn
    )
    SELECT @DemandRequestIdSeed1, drs.DemandRequestStatusId, NULL, 'Miss Ruth Yaqoob', DATEADD(HOUR, -9, SYSUTCDATETIME())
    FROM dbo.DemandRequestStatuses drs
    WHERE drs.StatusName = 'Draft';

    INSERT INTO dbo.DemandRequestLifeCycles
    (
        DemandRequestId,
        DemandRequestStatusId,
        UserId,
        ActionByName,
        CreatedOn
    )
    SELECT @DemandRequestIdSeed1, drs.DemandRequestStatusId, NULL, 'Miss Ruth Yaqoob', DATEADD(HOUR, -6, SYSUTCDATETIME())
    FROM dbo.DemandRequestStatuses drs
    WHERE drs.StatusName = 'Pending';
END
GO

DECLARE @DemandRequestIdSeed2 INT = (SELECT TOP 1 DemandRequestId FROM dbo.DemandRequests WHERE DRNo = 'DR-0002');

IF @DemandRequestIdSeed2 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.DemandRequestLifeCycles WHERE DemandRequestId = @DemandRequestIdSeed2)
BEGIN
    INSERT INTO dbo.DemandRequestLifeCycles
    (
        DemandRequestId,
        DemandRequestStatusId,
        UserId,
        ActionByName,
        CreatedOn
    )
    SELECT @DemandRequestIdSeed2, drs.DemandRequestStatusId, NULL, 'Miss Ruth Yaqoob', DATEADD(HOUR, -5, SYSUTCDATETIME())
    FROM dbo.DemandRequestStatuses drs
    WHERE drs.StatusName = 'Draft';

    INSERT INTO dbo.DemandRequestLifeCycles
    (
        DemandRequestId,
        DemandRequestStatusId,
        UserId,
        ActionByName,
        CreatedOn
    )
    SELECT @DemandRequestIdSeed2, drs.DemandRequestStatusId, NULL, 'Miss Ruth Yaqoob', DATEADD(HOUR, -3, SYSUTCDATETIME())
    FROM dbo.DemandRequestStatuses drs
    WHERE drs.StatusName = 'Pending';

    INSERT INTO dbo.DemandRequestLifeCycles
    (
        DemandRequestId,
        DemandRequestStatusId,
        UserId,
        ActionByName,
        CreatedOn
    )
    SELECT @DemandRequestIdSeed2, drs.DemandRequestStatusId, NULL, 'Dr Ayesha Siddiqua', DATEADD(HOUR, -2, SYSUTCDATETIME())
    FROM dbo.DemandRequestStatuses drs
    WHERE drs.StatusName = 'Approved';
END
GO