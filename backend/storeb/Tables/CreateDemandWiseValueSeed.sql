IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'PurchaseSummary' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    DECLARE @RicBranchId INT = (SELECT TOP 1 Id FROM dbo.Branches WHERE Name = 'Rawalpindi Institute of Cardiology' ORDER BY Id);
    DECLARE @AcademicStoreId INT = (SELECT TOP 1 StoreId FROM dbo.Stores WHERE StoreName = 'Academic Affair Store' ORDER BY StoreId);
    DECLARE @VendorId INT = (SELECT TOP 1 Id FROM dbo.Vendors WHERE Name = 'MediSupply Traders' ORDER BY Id);
    DECLARE @ElectrodeItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = 'ECG Electrodes' ORDER BY Id);
    DECLARE @SyringeItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = 'Syringe 10ml' ORDER BY Id);

    IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseSummary WHERE InvoiceNo = 'DWV-PS-001')
    BEGIN
        INSERT INTO dbo.PurchaseSummary
        (
            PurchaseDate,
            BatchNo,
            ItemId,
            ItemName,
            StoreId,
            StoreName,
            VendorId,
            VendorName,
            InvoiceNo,
            InvoiceDate,
            Quantity,
            Amount,
            AdvanceTax,
            Discount,
            TotalPrice,
            BranchId,
            ItemTypeId,
            ReportType,
            IsActive,
            CreatedById,
            CreatedOn
        )
        VALUES
        (DATEADD(DAY, -6, SYSUTCDATETIME()), 'AA-ECG-2403', @ElectrodeItemId, 'ECG Electrodes', @AcademicStoreId, 'Academic Affair Store', @VendorId, 'MediSupply Traders', 'DWV-PS-001', DATEADD(DAY, -6, SYSUTCDATETIME()), 120, 14.50, 0, 0, 1740.00, @RicBranchId, NULL, 'Purchase', 1, 1, DATEADD(DAY, -6, SYSUTCDATETIME())),
        (DATEADD(DAY, -5, SYSUTCDATETIME()), 'AA-SYR-2403', @SyringeItemId, 'Syringe 10ml', @AcademicStoreId, 'Academic Affair Store', @VendorId, 'MediSupply Traders', 'DWV-PS-002', DATEADD(DAY, -5, SYSUTCDATETIME()), 200, 9.75, 0, 0, 1950.00, @RicBranchId, NULL, 'Purchase', 1, 1, DATEADD(DAY, -5, SYSUTCDATETIME()));
    END
END
GO

DECLARE @RicBranchId INT = (SELECT TOP 1 Id FROM dbo.Branches WHERE Name = 'Rawalpindi Institute of Cardiology' ORDER BY Id);
DECLARE @AcademicStoreId INT = (SELECT TOP 1 StoreId FROM dbo.Stores WHERE StoreName = 'Academic Affair Store' ORDER BY StoreId);
DECLARE @ElectrodeItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = 'ECG Electrodes' ORDER BY Id);
DECLARE @SyringeItemId INT = (SELECT TOP 1 Id FROM dbo.Items WHERE Name = 'Syringe 10ml' ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM dbo.DemandRequests WHERE DRNo = 'DR-DWV-0001')
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
        'DR-DWV-0001',
        'DWV-106101',
        DATEADD(DAY, -2, SYSUTCDATETIME()),
        DATEADD(DAY, -1, SYSUTCDATETIME()),
        @RicBranchId,
        @AcademicStoreId,
        @AcademicStoreId,
        1,
        'Issued',
        'Demand wise value seed record for academic affairs store.',
        1,
        1,
        DATEADD(DAY, -2, SYSUTCDATETIME()),
        1,
        DATEADD(DAY, -1, SYSUTCDATETIME())
    );

    DECLARE @DemandWiseValueDemandId INT = CAST(SCOPE_IDENTITY() AS INT);

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
    (@DemandWiseValueDemandId, @ElectrodeItemId, 45, 40, @RicBranchId, 1, 1, DATEADD(DAY, -2, SYSUTCDATETIME()), 'Issued ECG electrodes', 1, 40, 40, 0),
    (@DemandWiseValueDemandId, @SyringeItemId, 80, 75, @RicBranchId, 1, 1, DATEADD(DAY, -2, SYSUTCDATETIME()), 'Issued syringes', 1, 75, 75, 0);

    INSERT INTO dbo.DemandRequestLifeCycles
    (
        DemandRequestId,
        DemandRequestStatusId,
        UserId,
        ActionByName,
        CreatedOn
    )
    SELECT @DemandWiseValueDemandId, DemandRequestStatusId, 1, 'Mr. Jalil Ahmed', DATEADD(DAY, -2, SYSUTCDATETIME())
    FROM dbo.DemandRequestStatuses
    WHERE StatusName = 'Pending';

    INSERT INTO dbo.DemandRequestLifeCycles
    (
        DemandRequestId,
        DemandRequestStatusId,
        UserId,
        ActionByName,
        CreatedOn
    )
    SELECT @DemandWiseValueDemandId, DemandRequestStatusId, 1, 'Mr. Jalil Ahmed', DATEADD(DAY, -1, SYSUTCDATETIME())
    FROM dbo.DemandRequestStatuses
    WHERE StatusName IN ('Issued', 'Issue');
END
GO