;WITH SrcCounts AS (
    SELECT Name, CreatedOn, COUNT(*) AS Cnt, MIN(BranchId) AS SrcBranchQid
    FROM iHealthCure.dbo.Vendors
    GROUP BY Name, CreatedOn
),
DestCounts AS (
    SELECT Name, CreatedOn, COUNT(*) AS Cnt
    FROM Inv.Vendors
    GROUP BY Name, CreatedOn
)
SELECT
    d.Id, d.Name, d.CreatedOn,
    d.BranchId AS CurrentBranchId,
    bm.BranchId AS CorrectBranchId,
    bm.BranchName AS CorrectBranchName
INTO #VendorCorrections
FROM Inv.Vendors d
JOIN DestCounts dc ON dc.Name = d.Name AND dc.CreatedOn = d.CreatedOn AND dc.Cnt = 1
JOIN SrcCounts sc ON sc.Name = d.Name AND sc.CreatedOn = d.CreatedOn AND sc.Cnt = 1
JOIN dbo.BranchQidMap bm ON bm.QID = sc.SrcBranchQid;

PRINT 'Total destination vendors:';
SELECT COUNT(*) FROM Inv.Vendors;

PRINT 'Certain matches found:';
SELECT COUNT(*) FROM #VendorCorrections;

PRINT 'Branch breakdown of certain matches:';
SELECT CorrectBranchId, CorrectBranchName, COUNT(*) FROM #VendorCorrections GROUP BY CorrectBranchId, CorrectBranchName ORDER BY COUNT(*) DESC;

PRINT 'How many need an actual change from current (20)?';
SELECT COUNT(*) FROM #VendorCorrections WHERE CurrentBranchId <> CorrectBranchId OR CurrentBranchId IS NULL;

PRINT 'Unmatched destination vendors (no source match found):';
SELECT v.Id, v.Name, v.CreatedOn, v.BranchId
FROM Inv.Vendors v
LEFT JOIN #VendorCorrections c ON c.Id = v.Id
WHERE c.Id IS NULL;

DROP TABLE #VendorCorrections;
