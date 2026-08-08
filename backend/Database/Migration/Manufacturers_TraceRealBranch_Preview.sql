;WITH SrcCounts AS (
    SELECT Name, CreatedOn, COUNT(*) AS Cnt, MIN(BranchId) AS SrcBranchQid
    FROM iHealthCure.dbo.Manufacturers
    GROUP BY Name, CreatedOn
),
DestCounts AS (
    SELECT Name, CreatedOn, COUNT(*) AS Cnt
    FROM Pharmacy.Manufacturers
    GROUP BY Name, CreatedOn
)
SELECT
    'CERTAIN' AS Confidence,
    d.ManufacturerId, d.Name, d.CreatedOn,
    d.BranchId AS CurrentBranchId,
    bm.BranchId AS CorrectBranchId,
    bm.BranchName AS CorrectBranchName
INTO #ManufacturerCorrections
FROM Pharmacy.Manufacturers d
JOIN DestCounts dc ON dc.Name = d.Name AND dc.CreatedOn = d.CreatedOn AND dc.Cnt = 1
JOIN SrcCounts sc ON sc.Name = d.Name AND sc.CreatedOn = d.CreatedOn AND sc.Cnt = 1
JOIN dbo.BranchQidMap bm ON bm.QID = sc.SrcBranchQid;

PRINT 'Certain matches found:';
SELECT COUNT(*) FROM #ManufacturerCorrections;

PRINT 'Of those, how many actually differ from current BranchId (need updating)?';
SELECT COUNT(*) FROM #ManufacturerCorrections WHERE CurrentBranchId <> CorrectBranchId OR CurrentBranchId IS NULL;

PRINT 'Breakdown of correct branch assignments among the certain matches:';
SELECT CorrectBranchId, CorrectBranchName, COUNT(*) FROM #ManufacturerCorrections GROUP BY CorrectBranchId, CorrectBranchName ORDER BY COUNT(*) DESC;

PRINT 'Sample of rows that would actually change:';
SELECT TOP 20 * FROM #ManufacturerCorrections WHERE CurrentBranchId <> CorrectBranchId OR CurrentBranchId IS NULL;

DROP TABLE #ManufacturerCorrections;

PRINT '--- Now the heuristic (ambiguous, duplicate Name+CreatedOn) side ---';
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
)
SELECT
    'HEURISTIC' AS Confidence,
    d.ManufacturerId, d.Name, d.CreatedOn, d.rn, d.GroupCnt AS DestGroupCnt, s.GroupCnt AS SrcGroupCnt,
    bm.BranchId AS HeuristicBranchId, bm.BranchName AS HeuristicBranchName
FROM DestDup d
JOIN SrcDup s ON s.Name = d.Name AND s.CreatedOn = d.CreatedOn AND s.rn = d.rn
JOIN dbo.BranchQidMap bm ON bm.QID = s.BranchId
WHERE d.GroupCnt > 1
ORDER BY d.Name, d.rn;
