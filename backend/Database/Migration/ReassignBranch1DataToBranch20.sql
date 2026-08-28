-- =============================================================================
-- ReassignBranch1DataToBranch20.sql
--
-- Branch 1 ("Ahmed Medical Complex", one disabled user) was @MainBranchId in
-- MigrateFromIHealthCure_HMSMAIN_TF.sql - migrated rows across many tables got
-- bulk-tagged to it as a default, instead of the branch that actually operates
-- this system (Branch 20, "Rawalpindi Institute of Cardiology", 2005 real users).
-- Once GetAll procs were changed to filter strictly by the caller's own branch,
-- this made all of that migrated data (all Racks/RackRows/RackColumns, most
-- Vendors/Manufacturers, some ItemTypes/ItemUnits/Packings) invisible to branch
-- 20 users.
--
-- This script snapshots every affected row (table + primary key + old BranchId)
-- into dbo.BranchReassign_1to20_Backup before updating, so it can be reverted:
--   UPDATE t SET t.BranchId = b.OldBranchId
--   FROM <TargetTable> t JOIN dbo.BranchReassign_1to20_Backup b
--     ON b.TableName = '<TargetTable>' AND t.<PkColumn> = b.RowId
-- =============================================================================

IF OBJECT_ID('dbo.BranchReassign_1to20_Backup', 'U') IS NOT NULL
    DROP TABLE dbo.BranchReassign_1to20_Backup;

CREATE TABLE dbo.BranchReassign_1to20_Backup (
    TableName NVARCHAR(128) NOT NULL,
    RowId INT NOT NULL,
    OldBranchId INT NOT NULL,
    CapturedOn DATETIME NOT NULL DEFAULT GETUTCDATE()
);

-- Snapshot
INSERT INTO dbo.BranchReassign_1to20_Backup (TableName, RowId, OldBranchId)
SELECT 'Inv.Vendors', Id, BranchId FROM Inv.Vendors WHERE BranchId = 1;
INSERT INTO dbo.BranchReassign_1to20_Backup (TableName, RowId, OldBranchId)
SELECT 'Pharmacy.Manufacturers', ManufacturerId, BranchId FROM Pharmacy.Manufacturers WHERE BranchId = 1;
INSERT INTO dbo.BranchReassign_1to20_Backup (TableName, RowId, OldBranchId)
SELECT 'Inv.Racks', Id, BranchId FROM Inv.Racks WHERE BranchId = 1;
INSERT INTO dbo.BranchReassign_1to20_Backup (TableName, RowId, OldBranchId)
SELECT 'Inv.RackColumns', Id, BranchId FROM Inv.RackColumns WHERE BranchId = 1;
INSERT INTO dbo.BranchReassign_1to20_Backup (TableName, RowId, OldBranchId)
SELECT 'Inv.RackDrawrs', Id, BranchId FROM Inv.RackDrawrs WHERE BranchId = 1;
INSERT INTO dbo.BranchReassign_1to20_Backup (TableName, RowId, OldBranchId)
SELECT 'Inv.RackRows', Id, BranchId FROM Inv.RackRows WHERE BranchId = 1;
INSERT INTO dbo.BranchReassign_1to20_Backup (TableName, RowId, OldBranchId)
SELECT 'Inv.SurgicalGroups', Id, BranchId FROM Inv.SurgicalGroups WHERE BranchId = 1;
INSERT INTO dbo.BranchReassign_1to20_Backup (TableName, RowId, OldBranchId)
SELECT 'Inv.AssetAllocations', Id, BranchId FROM Inv.AssetAllocations WHERE BranchId = 1;
INSERT INTO dbo.BranchReassign_1to20_Backup (TableName, RowId, OldBranchId)
SELECT 'Inv.ItemTypes', Id, BranchId FROM Inv.ItemTypes WHERE BranchId = 1;
INSERT INTO dbo.BranchReassign_1to20_Backup (TableName, RowId, OldBranchId)
SELECT 'Inv.ItemUnits', Id, BranchId FROM Inv.ItemUnits WHERE BranchId = 1;
INSERT INTO dbo.BranchReassign_1to20_Backup (TableName, RowId, OldBranchId)
SELECT 'Inv.Packings', Id, BranchId FROM Inv.Packings WHERE BranchId = 1;

PRINT 'Snapshot rows captured:';
SELECT TableName, COUNT(*) AS RowsCaptured FROM dbo.BranchReassign_1to20_Backup GROUP BY TableName;

-- Reassign
UPDATE Inv.Vendors SET BranchId = 20 WHERE BranchId = 1;
UPDATE Pharmacy.Manufacturers SET BranchId = 20 WHERE BranchId = 1;
UPDATE Inv.Racks SET BranchId = 20 WHERE BranchId = 1;
UPDATE Inv.RackColumns SET BranchId = 20 WHERE BranchId = 1;
UPDATE Inv.RackDrawrs SET BranchId = 20 WHERE BranchId = 1;
UPDATE Inv.RackRows SET BranchId = 20 WHERE BranchId = 1;
UPDATE Inv.SurgicalGroups SET BranchId = 20 WHERE BranchId = 1;
UPDATE Inv.AssetAllocations SET BranchId = 20 WHERE BranchId = 1;
UPDATE Inv.ItemTypes SET BranchId = 20 WHERE BranchId = 1;
UPDATE Inv.ItemUnits SET BranchId = 20 WHERE BranchId = 1;
UPDATE Inv.Packings SET BranchId = 20 WHERE BranchId = 1;

PRINT 'Reassignment complete. Post-update branch distribution:';
SELECT 'Vendors', BranchId, COUNT(*) FROM Inv.Vendors GROUP BY BranchId;
SELECT 'Manufacturers (Pharmacy)', BranchId, COUNT(*) FROM Pharmacy.Manufacturers GROUP BY BranchId;
SELECT 'Racks', BranchId, COUNT(*) FROM Inv.Racks GROUP BY BranchId;
SELECT 'RackColumns', BranchId, COUNT(*) FROM Inv.RackColumns GROUP BY BranchId;
SELECT 'RackDrawrs', BranchId, COUNT(*) FROM Inv.RackDrawrs GROUP BY BranchId;
SELECT 'RackRows', BranchId, COUNT(*) FROM Inv.RackRows GROUP BY BranchId;
SELECT 'SurgicalGroups', BranchId, COUNT(*) FROM Inv.SurgicalGroups GROUP BY BranchId;
SELECT 'AssetAllocations', BranchId, COUNT(*) FROM Inv.AssetAllocations GROUP BY BranchId;
SELECT 'ItemTypes', BranchId, COUNT(*) FROM Inv.ItemTypes GROUP BY BranchId;
SELECT 'ItemUnits', BranchId, COUNT(*) FROM Inv.ItemUnits GROUP BY BranchId;
SELECT 'Packings', BranchId, COUNT(*) FROM Inv.Packings GROUP BY BranchId;
