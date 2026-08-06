-- =============================================
-- Create Inv.DemandRequestLifeCycles Table
-- Targets the live Inv schema (int PKs, matching Inv.DemandRequests /
-- Inv.DemandRequestStatuses) - CreateDemandRequestsTables.sql's
-- dbo.DemandRequestLifeCycles was written for a different (unapplied) fallback
-- schema and never matched the deployed HMS_Jun26 database.
-- =============================================
IF NOT EXISTS (
    SELECT 1 FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.name = 'DemandRequestLifeCycles' AND s.name = 'Inv'
)
BEGIN
    CREATE TABLE Inv.DemandRequestLifeCycles (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        DemandRequestId INT NOT NULL,
        DemandRequestStatusId INT NOT NULL,
        FromUserId INT NULL,
        ToUserId INT NULL,
        Remarks NVARCHAR(500) NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT FK_DemandRequestLifeCycles_DemandRequests FOREIGN KEY (DemandRequestId) REFERENCES Inv.DemandRequests(Id),
        CONSTRAINT FK_DemandRequestLifeCycles_Statuses FOREIGN KEY (DemandRequestStatusId) REFERENCES Inv.DemandRequestStatuses(Id)
    );

    CREATE INDEX IX_DemandRequestLifeCycles_DemandRequestId ON Inv.DemandRequestLifeCycles(DemandRequestId);

    PRINT 'Inv.DemandRequestLifeCycles table created successfully';
END
ELSE
BEGIN
    PRINT 'Inv.DemandRequestLifeCycles table already exists';
END
GO
