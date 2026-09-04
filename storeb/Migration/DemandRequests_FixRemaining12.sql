-- The 5 duplicate-numbered pairs all resolve to RIC (QID 5BD60354...) regardless
-- of which specific row is which - verified directly against iHealthCure. The 2
-- seed rows (DR-HMS-SEED-001/002) have no iHealthCure origin at all; RIC is the
-- only sensible branch for them per the pattern seen across all other seed data.
INSERT INTO dbo.BranchReassign_1to20_Backup (TableName, RowId, OldBranchId)
SELECT 'Inv.DemandRequests (remaining 12)', Id, BranchId FROM Inv.DemandRequests WHERE BranchId = 1;

UPDATE Inv.DemandRequests SET BranchId = 20 WHERE BranchId = 1;

SELECT BranchId, COUNT(*) FROM Inv.DemandRequests GROUP BY BranchId;
