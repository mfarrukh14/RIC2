-- Per-action item audit log for demand request dispatch/receive - mirrors the legacy
-- system's DemandRequestItemLogs table, trimmed to this schema's Items-only item model.
-- Each dispatch or receive call inserts one row per item touched, recording the delta
-- quantity for that action plus the resulting cumulative Issued/Received/Remaining
-- quantities, so partial dispatch/receive history stays auditable even though
-- DemandRequestItems itself only stores the current cumulative totals.
IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'Inv' AND t.name = 'DemandRequestItemLogs')
BEGIN
    CREATE TABLE Inv.DemandRequestItemLogs
    (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        DemandRequestId INT NOT NULL,
        DemandRequestItemId INT NOT NULL,
        ItemId INT NULL,
        ActionType NVARCHAR(20) NOT NULL,
        Quantity INT NOT NULL,
        IssuedQuantity INT NULL,
        ReceivedQuantity INT NULL,
        RemainingQuantity INT NULL,
        CreatedById INT NULL,
        CreatedOn DATETIME NOT NULL CONSTRAINT DF_DemandRequestItemLogs_CreatedOn DEFAULT (GETDATE()),
        CONSTRAINT FK_DemandRequestItemLogs_DemandRequests FOREIGN KEY (DemandRequestId) REFERENCES Inv.DemandRequests(Id),
        CONSTRAINT FK_DemandRequestItemLogs_DemandRequestItems FOREIGN KEY (DemandRequestItemId) REFERENCES Inv.DemandRequestItems(Id)
    );

    CREATE INDEX IX_DemandRequestItemLogs_DemandRequestId ON Inv.DemandRequestItemLogs(DemandRequestId);
END
GO

PRINT 'Inv.DemandRequestItemLogs verified.';
GO
