-- Racks
PRINT '=== Racks ===';
;WITH Src AS (
    SELECT Name, CreatedOn, BranchId FROM iHealthCure.dbo.Racks
    WHERE Name IN (SELECT Name FROM iHealthCure.dbo.Racks GROUP BY Name, CreatedOn HAVING COUNT(*) = 1)
),
Dst AS (
    SELECT Id, Name, CreatedOn, BranchId AS CurrentBranchId FROM Inv.Racks
    WHERE Name IN (SELECT Name FROM Inv.Racks GROUP BY Name, CreatedOn HAVING COUNT(*) = 1)
)
SELECT d.Id, d.Name, d.CurrentBranchId, bm.BranchId AS CorrectBranchId, bm.BranchName
INTO #RackFix
FROM Dst d
JOIN Src s ON s.Name = d.Name AND s.CreatedOn = d.CreatedOn
JOIN dbo.BranchQidMap bm ON bm.QID = s.BranchId;

SELECT COUNT(*) AS Matched FROM #RackFix;
SELECT CorrectBranchId, BranchName, COUNT(*) FROM #RackFix GROUP BY CorrectBranchId, BranchName;
SELECT COUNT(*) AS NeedsChange FROM #RackFix WHERE CurrentBranchId <> CorrectBranchId OR CurrentBranchId IS NULL;

INSERT INTO dbo.BranchReassign_1to20_Backup (TableName, RowId, OldBranchId)
SELECT 'Inv.Racks (re-trace)', Id, CurrentBranchId FROM #RackFix WHERE CurrentBranchId <> CorrectBranchId OR CurrentBranchId IS NULL;

UPDATE r SET r.BranchId = f.CorrectBranchId
FROM Inv.Racks r JOIN #RackFix f ON f.Id = r.Id
WHERE r.BranchId <> f.CorrectBranchId OR r.BranchId IS NULL;

DROP TABLE #RackFix;
SELECT BranchId, COUNT(*) FROM Inv.Racks GROUP BY BranchId;

-- RackRows
PRINT '=== RackRows ===';
;WITH Src AS (
    SELECT Name, CreatedOn, BranchId FROM iHealthCure.dbo.RackRows
    WHERE Name IN (SELECT Name FROM iHealthCure.dbo.RackRows GROUP BY Name, CreatedOn HAVING COUNT(*) = 1)
),
Dst AS (
    SELECT Id, Name, CreatedOn, BranchId AS CurrentBranchId FROM Inv.RackRows
    WHERE Name IN (SELECT Name FROM Inv.RackRows GROUP BY Name, CreatedOn HAVING COUNT(*) = 1)
)
SELECT d.Id, d.Name, d.CurrentBranchId, bm.BranchId AS CorrectBranchId, bm.BranchName
INTO #RackRowFix
FROM Dst d
JOIN Src s ON s.Name = d.Name AND s.CreatedOn = d.CreatedOn
JOIN dbo.BranchQidMap bm ON bm.QID = s.BranchId;

SELECT COUNT(*) AS Matched FROM #RackRowFix;
SELECT CorrectBranchId, BranchName, COUNT(*) FROM #RackRowFix GROUP BY CorrectBranchId, BranchName;

INSERT INTO dbo.BranchReassign_1to20_Backup (TableName, RowId, OldBranchId)
SELECT 'Inv.RackRows (re-trace)', Id, CurrentBranchId FROM #RackRowFix WHERE CurrentBranchId <> CorrectBranchId OR CurrentBranchId IS NULL;

UPDATE r SET r.BranchId = f.CorrectBranchId
FROM Inv.RackRows r JOIN #RackRowFix f ON f.Id = r.Id
WHERE r.BranchId <> f.CorrectBranchId OR r.BranchId IS NULL;

DROP TABLE #RackRowFix;
SELECT BranchId, COUNT(*) FROM Inv.RackRows GROUP BY BranchId;

-- RackColumns
PRINT '=== RackColumns ===';
;WITH Src AS (
    SELECT Name, CreatedOn, BranchId FROM iHealthCure.dbo.RackColumns
    WHERE Name IN (SELECT Name FROM iHealthCure.dbo.RackColumns GROUP BY Name, CreatedOn HAVING COUNT(*) = 1)
),
Dst AS (
    SELECT Id, Name, CreatedOn, BranchId AS CurrentBranchId FROM Inv.RackColumns
    WHERE Name IN (SELECT Name FROM Inv.RackColumns GROUP BY Name, CreatedOn HAVING COUNT(*) = 1)
)
SELECT d.Id, d.Name, d.CurrentBranchId, bm.BranchId AS CorrectBranchId, bm.BranchName
INTO #RackColFix
FROM Dst d
JOIN Src s ON s.Name = d.Name AND s.CreatedOn = d.CreatedOn
JOIN dbo.BranchQidMap bm ON bm.QID = s.BranchId;

SELECT COUNT(*) AS Matched FROM #RackColFix;
SELECT CorrectBranchId, BranchName, COUNT(*) FROM #RackColFix GROUP BY CorrectBranchId, BranchName;

INSERT INTO dbo.BranchReassign_1to20_Backup (TableName, RowId, OldBranchId)
SELECT 'Inv.RackColumns (re-trace)', Id, CurrentBranchId FROM #RackColFix WHERE CurrentBranchId <> CorrectBranchId OR CurrentBranchId IS NULL;

UPDATE r SET r.BranchId = f.CorrectBranchId
FROM Inv.RackColumns r JOIN #RackColFix f ON f.Id = r.Id
WHERE r.BranchId <> f.CorrectBranchId OR r.BranchId IS NULL;

DROP TABLE #RackColFix;
SELECT BranchId, COUNT(*) FROM Inv.RackColumns GROUP BY BranchId;

-- SurgicalItemGroups (destination table is Inv.SurgicalGroups)
PRINT '=== SurgicalGroups ===';
;WITH Src AS (
    SELECT Name, CreatedOn, BranchId FROM iHealthCure.dbo.SurgicalItemGroups
    WHERE Name IN (SELECT Name FROM iHealthCure.dbo.SurgicalItemGroups GROUP BY Name, CreatedOn HAVING COUNT(*) = 1)
),
Dst AS (
    SELECT Id, Name, CreatedOn, BranchId AS CurrentBranchId FROM Inv.SurgicalGroups
    WHERE Name IN (SELECT Name FROM Inv.SurgicalGroups GROUP BY Name, CreatedOn HAVING COUNT(*) = 1)
)
SELECT d.Id, d.Name, d.CurrentBranchId, bm.BranchId AS CorrectBranchId, bm.BranchName
INTO #SurgFix
FROM Dst d
JOIN Src s ON s.Name = d.Name AND s.CreatedOn = d.CreatedOn
JOIN dbo.BranchQidMap bm ON bm.QID = s.BranchId;

SELECT COUNT(*) AS Matched FROM #SurgFix;
SELECT * FROM #SurgFix;

INSERT INTO dbo.BranchReassign_1to20_Backup (TableName, RowId, OldBranchId)
SELECT 'Inv.SurgicalGroups (re-trace)', Id, CurrentBranchId FROM #SurgFix WHERE CurrentBranchId <> CorrectBranchId OR CurrentBranchId IS NULL;

UPDATE r SET r.BranchId = f.CorrectBranchId
FROM Inv.SurgicalGroups r JOIN #SurgFix f ON f.Id = r.Id
WHERE r.BranchId <> f.CorrectBranchId OR r.BranchId IS NULL;

DROP TABLE #SurgFix;
SELECT BranchId, COUNT(*) FROM Inv.SurgicalGroups GROUP BY BranchId;
