-- =============================================================================
-- Inv.Inventories is the "Add Inventory" batch header table, fully migrated
-- 1:1 from iHealthCure.dbo.Inventories (31148 new vs 31146 old). This script
-- only ADDS a nullable QID column and backfills it via UPDATE on EXISTING
-- rows. No row is deleted, no other column is touched. It is a prerequisite
-- for migrating the historical Inv.InventoryDetails line items, which need
-- to resolve their InventoryId FK back to the right header row.
--
-- Match key: CreatedOn alone, which is unique on both sides (31148/31148 new,
-- 31146/31146 old) - unlike Users/PharmacyMedicinesStocks it was never reset.
-- =============================================================================

IF COL_LENGTH('Inv.Inventories', 'QID') IS NULL
BEGIN
    ALTER TABLE Inv.Inventories ADD QID UNIQUEIDENTIFIER NULL;
END
GO

IF OBJECT_ID('dbo.Inventories_Backfill_Backup', 'U') IS NOT NULL
    DROP TABLE dbo.Inventories_Backfill_Backup;
CREATE TABLE dbo.Inventories_Backfill_Backup (
    RowId INT NOT NULL,
    OldQID UNIQUEIDENTIFIER NULL,
    CapturedOn DATETIME NOT NULL DEFAULT GETUTCDATE()
);
INSERT INTO dbo.Inventories_Backfill_Backup (RowId, OldQID)
SELECT Id, QID FROM Inv.Inventories;

UPDATE n
SET n.QID = o.Id
FROM Inv.Inventories n
JOIN iHealthCure.dbo.Inventories o ON o.CreatedOn = n.CreatedOn;

PRINT 'Inventories QID population:';
SELECT COUNT(*) AS Total, COUNT(QID) AS WithQid FROM Inv.Inventories;
