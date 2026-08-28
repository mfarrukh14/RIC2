;WITH Src AS (
    SELECT Name, CreatedOn, BranchId FROM iHealthCure.dbo.SurgicalItemGroups
    WHERE Name IN (SELECT Name FROM iHealthCure.dbo.SurgicalItemGroups GROUP BY Name, CreatedOn HAVING COUNT(*) = 1)
),
Dst AS (
    SELECT Id, Name, CreatedOn, BranchId AS CurrentBranchId FROM Inv.SurgicalItemGroups
    WHERE Name IN (SELECT Name FROM Inv.SurgicalItemGroups GROUP BY Name, CreatedOn HAVING COUNT(*) = 1)
)
SELECT d.Id, d.CurrentBranchId, bm.BranchId AS CorrectBranchId, bm.BranchName
INTO #Fix
FROM Dst d
JOIN Src s ON s.Name = d.Name AND s.CreatedOn = d.CreatedOn
JOIN dbo.BranchQidMap bm ON bm.QID = s.BranchId;

SELECT COUNT(*) AS Matched FROM #Fix;
SELECT CorrectBranchId, BranchName, COUNT(*) FROM #Fix GROUP BY CorrectBranchId, BranchName;

UPDATE t SET t.BranchId = f.CorrectBranchId
FROM Inv.SurgicalItemGroups t JOIN #Fix f ON f.Id = t.Id
WHERE t.BranchId <> f.CorrectBranchId OR t.BranchId IS NULL;

DROP TABLE #Fix;

-- Any leftover (no unique source match) - default to 20
UPDATE Inv.SurgicalItemGroups SET BranchId = 20 WHERE BranchId = 1;

SELECT BranchId, COUNT(*) FROM Inv.SurgicalItemGroups GROUP BY BranchId;
