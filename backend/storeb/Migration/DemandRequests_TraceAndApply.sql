PRINT '=== DemandRequests: dup check on DemandRequestNumber (source) ===';
;WITH dup AS (
    SELECT DemandRequestNumber, COUNT(DISTINCT BranchId) AS DistinctBranches, COUNT(*) AS Cnt
    FROM iHealthCure.dbo.DemandRequests
    WHERE DemandRequestNumber IS NOT NULL
    GROUP BY DemandRequestNumber HAVING COUNT(*) > 1
)
SELECT DistinctBranches, COUNT(*) FROM dup GROUP BY DistinctBranches;

;WITH Src AS (
    SELECT DemandRequestNumber, BranchId FROM iHealthCure.dbo.DemandRequests
    WHERE DemandRequestNumber IS NOT NULL
      AND DemandRequestNumber IN (SELECT DemandRequestNumber FROM iHealthCure.dbo.DemandRequests GROUP BY DemandRequestNumber HAVING COUNT(*) = 1)
),
Dst AS (
    SELECT Id, DemandRequestNumber, BranchId AS CurrentBranchId FROM Inv.DemandRequests
    WHERE DemandRequestNumber IS NOT NULL
      AND DemandRequestNumber IN (SELECT DemandRequestNumber FROM Inv.DemandRequests GROUP BY DemandRequestNumber HAVING COUNT(*) = 1)
)
SELECT d.Id, d.CurrentBranchId, bm.BranchId AS CorrectBranchId, bm.BranchName
INTO #DrFix
FROM Dst d
JOIN Src s ON s.DemandRequestNumber = d.DemandRequestNumber
JOIN dbo.BranchQidMap bm ON bm.QID = s.BranchId;

PRINT 'Matched:';
SELECT COUNT(*) FROM #DrFix;
PRINT 'Branch breakdown:';
SELECT CorrectBranchId, BranchName, COUNT(*) FROM #DrFix GROUP BY CorrectBranchId, BranchName ORDER BY COUNT(*) DESC;
PRINT 'Needs change (current != correct):';
SELECT COUNT(*) FROM #DrFix WHERE CurrentBranchId <> CorrectBranchId OR CurrentBranchId IS NULL;

PRINT 'Unmatched (no source DemandRequestNumber match) - current branch distribution:';
SELECT dr.BranchId, COUNT(*)
FROM Inv.DemandRequests dr
LEFT JOIN #DrFix f ON f.Id = dr.Id
WHERE f.Id IS NULL
GROUP BY dr.BranchId;

INSERT INTO dbo.BranchReassign_1to20_Backup (TableName, RowId, OldBranchId)
SELECT 'Inv.DemandRequests (re-trace)', Id, CurrentBranchId FROM #DrFix WHERE CurrentBranchId <> CorrectBranchId OR CurrentBranchId IS NULL;

UPDATE d SET d.BranchId = f.CorrectBranchId
FROM Inv.DemandRequests d JOIN #DrFix f ON f.Id = d.Id
WHERE d.BranchId <> f.CorrectBranchId OR d.BranchId IS NULL;

DROP TABLE #DrFix;

PRINT 'Post-correction branch distribution:';
SELECT BranchId, COUNT(*) FROM Inv.DemandRequests GROUP BY BranchId;
