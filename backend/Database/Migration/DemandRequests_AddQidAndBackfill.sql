-- =============================================================================
-- Inv.DemandRequests is fully migrated 1:1 from iHealthCure.dbo.DemandRequests
-- (58597 new vs 58593 old, CreatedOn preserved from the original migration on
-- both sides - unlike Users/PharmacyMedicinesStocks it was never reset).
-- This script only ADDS a nullable QID column and backfills it via UPDATE on
-- EXISTING rows. No row is deleted, no other column is touched.
--
-- Match key: DemandRequestNumber + CreatedOn, unique on both sides
-- (58597/58597 new, 58593/58593 old) - resolves 58593/58597 (99.99%).
-- =============================================================================

IF COL_LENGTH('Inv.DemandRequests', 'QID') IS NULL
BEGIN
    ALTER TABLE Inv.DemandRequests ADD QID UNIQUEIDENTIFIER NULL;
END
GO

IF OBJECT_ID('dbo.DemandRequests_Backfill_Backup', 'U') IS NOT NULL
    DROP TABLE dbo.DemandRequests_Backfill_Backup;
CREATE TABLE dbo.DemandRequests_Backfill_Backup (
    RowId INT NOT NULL,
    OldQID UNIQUEIDENTIFIER NULL,
    CapturedOn DATETIME NOT NULL DEFAULT GETUTCDATE()
);
INSERT INTO dbo.DemandRequests_Backfill_Backup (RowId, OldQID)
SELECT Id, QID FROM Inv.DemandRequests;

UPDATE n
SET n.QID = o.Id
FROM Inv.DemandRequests n
JOIN iHealthCure.dbo.DemandRequests o
    ON o.DemandRequestNumber = n.DemandRequestNumber AND o.CreatedOn = n.CreatedOn;

PRINT 'DemandRequests QID population:';
SELECT COUNT(*) AS Total, COUNT(QID) AS WithQid FROM Inv.DemandRequests;
