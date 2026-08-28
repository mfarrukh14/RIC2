IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'PurchaseOrderStatuses' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.PurchaseOrderStatuses
    (
        PurchaseOrderStatusId INT IDENTITY(1,1) PRIMARY KEY,
        StatusName NVARCHAR(100) NOT NULL,
        Description NVARCHAR(MAX) NULL,
        IsActive BIT NOT NULL CONSTRAINT DF_PurchaseOrderStatuses_IsActive DEFAULT (1),
        CreatedOn DATETIME2 NOT NULL CONSTRAINT DF_PurchaseOrderStatuses_CreatedOn DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT UQ_PurchaseOrderStatuses_StatusName UNIQUE (StatusName)
    );
END
GO

IF COL_LENGTH('dbo.PurchaseOrderStatuses', 'Description') IS NULL
BEGIN
    ALTER TABLE dbo.PurchaseOrderStatuses
    ADD Description NVARCHAR(MAX) NULL;
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrderStatuses WHERE StatusName = 'Before Enter')
BEGIN
    INSERT INTO dbo.PurchaseOrderStatuses (StatusName, Description, IsActive)
    VALUES ('Before Enter', 'Before Enter', 1);
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrderStatuses WHERE StatusName = 'Approved')
BEGIN
    INSERT INTO dbo.PurchaseOrderStatuses (StatusName, Description, IsActive)
    VALUES ('Approved', 'Approved', 1);
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrderStatuses WHERE StatusName = 'Pending')
BEGIN
    INSERT INTO dbo.PurchaseOrderStatuses (StatusName, Description, IsActive)
    VALUES ('Pending', 'Pending', 1);
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrderStatuses WHERE StatusName = 'Recieved')
BEGIN
    INSERT INTO dbo.PurchaseOrderStatuses (StatusName, Description, IsActive)
    VALUES ('Recieved', 'Recieved', 1);
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrderStatuses WHERE StatusName = 'Rejected')
BEGIN
    INSERT INTO dbo.PurchaseOrderStatuses (StatusName, Description, IsActive)
    VALUES ('Rejected', 'Rejected', 1);
END
GO