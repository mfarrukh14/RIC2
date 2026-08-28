-- Corrects Pharmacy.Manufacturers.BranchId (currently all blanket-set to 20 by
-- ReassignBranch1DataToBranch20.sql) using the real per-row branch recovered from
-- iHealthCure.dbo.Manufacturers via dbo.BranchQidMap. 234 rows have a unique
-- Name+CreatedOn in both source and destination (certain match - all already
-- happen to be branch 20, so no change). The remaining 470 rows are 235
-- same-name-different-branch pairs in the source (e.g. "HP" exists under both
-- Model Pharmacy and RIC with identical Email/Phone/CreatedOn) - matched via a
-- best-effort ordering heuristic (source physical row order via %%physloc%%,
-- matched position-for-position against destination ManufacturerId order),
-- validated at 234/235 groups following one consistent pattern before applying.
-- NOT certain like the unique-name rows - flagged as such in the backup log.

INSERT INTO dbo.BranchReassign_1to20_Backup (TableName, RowId, OldBranchId)
SELECT 'Pharmacy.Manufacturers (heuristic re-trace)', ManufacturerId, BranchId
FROM Pharmacy.Manufacturers
WHERE Name IN (
    SELECT Name FROM Pharmacy.Manufacturers GROUP BY Name, CreatedOn HAVING COUNT(*) > 1
);

;WITH SrcDup AS (
    SELECT Id AS SrcId, Name, CreatedOn, BranchId,
        ROW_NUMBER() OVER (PARTITION BY Name, CreatedOn ORDER BY %%physloc%%) AS rn,
        COUNT(*) OVER (PARTITION BY Name, CreatedOn) AS GroupCnt
    FROM iHealthCure.dbo.Manufacturers
),
DestDup AS (
    SELECT ManufacturerId, Name, CreatedOn,
        ROW_NUMBER() OVER (PARTITION BY Name, CreatedOn ORDER BY ManufacturerId) AS rn,
        COUNT(*) OVER (PARTITION BY Name, CreatedOn) AS GroupCnt
    FROM Pharmacy.Manufacturers
),
Matched AS (
    SELECT d.ManufacturerId, bm.BranchId AS HeuristicBranchId
    FROM DestDup d
    JOIN SrcDup s ON s.Name = d.Name AND s.CreatedOn = d.CreatedOn AND s.rn = d.rn
    JOIN dbo.BranchQidMap bm ON bm.QID = s.BranchId
    WHERE d.GroupCnt > 1
)
UPDATE pm
SET pm.BranchId = m.HeuristicBranchId
FROM Pharmacy.Manufacturers pm
JOIN Matched m ON m.ManufacturerId = pm.ManufacturerId;

PRINT 'Post-correction Pharmacy.Manufacturers branch distribution:';
SELECT BranchId, COUNT(*) FROM Pharmacy.Manufacturers GROUP BY BranchId;
