-- Backfills QID/BranchMedicineId/BranchSubServiceId on Pharmacy.PharmacyMedicinesStocks
-- (the live stock ledger a separate, external frontend reads via BranchMedicineId -
-- which is why medicine quantities show as 0 there: BranchMedicineId is currently
-- NULL on every row). Matched WITHOUT StoreId (StoreId's own correctness is a
-- separate, unresolved question - see conversation) using CreatedOn+TotalItemsInStock
-- +SysBatchNo+BatchNo+MinimumPanicLevel+Price+TypeBit, all copied verbatim from
-- iHealthCure at the original migration and confirmed 99.2% uniquely matchable
-- (26533/26754). No row is deleted; TotalItemsInStock/StoreId/any balance column
-- is never touched - only the previously-always-NULL QID/BranchMedicineId/
-- BranchSubServiceId columns are filled in where a confident match exists.

IF OBJECT_ID('tempdb..#SrcKeyed') IS NOT NULL DROP TABLE #SrcKeyed;
SELECT
    Id AS SrcId,
    BranchMedicineId,
    BranchSubServiceId,
    CAST(CreatedOn AS DATETIME2(3)) AS CreatedOn,
    TotalItemsInStock,
    CAST(ISNULL(SysBatchNo,'') AS NVARCHAR(100)) AS SysBatchNo,
    CAST(ISNULL(BatchNo,'') AS NVARCHAR(100)) AS BatchNo,
    ISNULL(MinimumPanicLevel,-1) AS MinimumPanicLevel,
    ISNULL(Price,-1) AS Price,
    TypeBit
INTO #SrcKeyed
FROM iHealthCure.dbo.PharmacyMedicinesStocks;

IF OBJECT_ID('tempdb..#DstKeyed') IS NOT NULL DROP TABLE #DstKeyed;
SELECT
    ID AS DstId,
    CAST(CreatedOn AS DATETIME2(3)) AS CreatedOn,
    TotalItemsInStock,
    CAST(ISNULL(SysBatchNo,'') AS NVARCHAR(100)) AS SysBatchNo,
    CAST(ISNULL(BatchNo,'') AS NVARCHAR(100)) AS BatchNo,
    ISNULL(MinimumPanicLevel,-1) AS MinimumPanicLevel,
    ISNULL(Price,-1) AS Price,
    TypeBit
INTO #DstKeyed
FROM Pharmacy.PharmacyMedicinesStocks;

CREATE INDEX IX_Src ON #SrcKeyed (CreatedOn, TotalItemsInStock, SysBatchNo, BatchNo, MinimumPanicLevel, Price, TypeBit);
CREATE INDEX IX_Dst ON #DstKeyed (CreatedOn, TotalItemsInStock, SysBatchNo, BatchNo, MinimumPanicLevel, Price, TypeBit);

IF OBJECT_ID('tempdb..#Matched') IS NOT NULL DROP TABLE #Matched;
;WITH SrcDup AS (
    SELECT CreatedOn, TotalItemsInStock, SysBatchNo, BatchNo, MinimumPanicLevel, Price, TypeBit, COUNT(*) AS Cnt
    FROM #SrcKeyed GROUP BY CreatedOn, TotalItemsInStock, SysBatchNo, BatchNo, MinimumPanicLevel, Price, TypeBit
),
DstDup AS (
    SELECT CreatedOn, TotalItemsInStock, SysBatchNo, BatchNo, MinimumPanicLevel, Price, TypeBit, COUNT(*) AS Cnt
    FROM #DstKeyed GROUP BY CreatedOn, TotalItemsInStock, SysBatchNo, BatchNo, MinimumPanicLevel, Price, TypeBit
)
SELECT d.DstId, s.SrcId, s.BranchMedicineId, s.BranchSubServiceId
INTO #Matched
FROM #DstKeyed d
JOIN #SrcKeyed s ON s.CreatedOn = d.CreatedOn AND s.TotalItemsInStock = d.TotalItemsInStock
    AND s.SysBatchNo = d.SysBatchNo AND s.BatchNo = d.BatchNo AND s.MinimumPanicLevel = d.MinimumPanicLevel
    AND s.Price = d.Price AND s.TypeBit = d.TypeBit
JOIN SrcDup sd ON sd.CreatedOn = s.CreatedOn AND sd.TotalItemsInStock = s.TotalItemsInStock AND sd.SysBatchNo = s.SysBatchNo AND sd.BatchNo = s.BatchNo AND sd.MinimumPanicLevel = s.MinimumPanicLevel AND sd.Price = s.Price AND sd.TypeBit = s.TypeBit AND sd.Cnt = 1
JOIN DstDup dd ON dd.CreatedOn = d.CreatedOn AND dd.TotalItemsInStock = d.TotalItemsInStock AND dd.SysBatchNo = d.SysBatchNo AND dd.BatchNo = d.BatchNo AND dd.MinimumPanicLevel = d.MinimumPanicLevel AND dd.Price = d.Price AND dd.TypeBit = d.TypeBit AND dd.Cnt = 1;

PRINT 'Rows matched:';
SELECT COUNT(*) FROM #Matched;

-- Backup before writing
IF OBJECT_ID('dbo.PharmacyMedicinesStocks_Backfill_Backup', 'U') IS NOT NULL
    DROP TABLE dbo.PharmacyMedicinesStocks_Backfill_Backup;
CREATE TABLE dbo.PharmacyMedicinesStocks_Backfill_Backup (
    RowId INT NOT NULL,
    OldQID UNIQUEIDENTIFIER NULL,
    OldBranchMedicineId INT NULL,
    OldBranchSubServiceId INT NULL,
    CapturedOn DATETIME NOT NULL DEFAULT GETUTCDATE()
);
INSERT INTO dbo.PharmacyMedicinesStocks_Backfill_Backup (RowId, OldQID, OldBranchMedicineId, OldBranchSubServiceId)
SELECT ID, QID, BranchMedicineId, BranchSubServiceId FROM Pharmacy.PharmacyMedicinesStocks;

-- Populate QID
UPDATE p SET p.QID = m.SrcId
FROM Pharmacy.PharmacyMedicinesStocks p JOIN #Matched m ON m.DstId = p.ID;

-- Backfill BranchMedicineId via BranchMedicines.Qid
UPDATE p SET p.BranchMedicineId = bm.Id
FROM Pharmacy.PharmacyMedicinesStocks p
JOIN #Matched m ON m.DstId = p.ID
JOIN Pharmacy.BranchMedicines bm ON bm.Qid = m.BranchMedicineId
WHERE p.BranchMedicineId IS NULL AND m.BranchMedicineId IS NOT NULL;

-- Backfill BranchSubServiceId via Data.BranchFees.QID
UPDATE p SET p.BranchSubServiceId = bf.Id
FROM Pharmacy.PharmacyMedicinesStocks p
JOIN #Matched m ON m.DstId = p.ID
JOIN Data.BranchFees bf ON bf.QID = m.BranchSubServiceId
WHERE p.BranchSubServiceId IS NULL AND m.BranchSubServiceId IS NOT NULL;

PRINT 'Final population counts:';
SELECT COUNT(*) AS Total,
    COUNT(QID) AS WithQid,
    COUNT(BranchMedicineId) AS WithBranchMedicineId,
    COUNT(BranchSubServiceId) AS WithBranchSubServiceId,
    COUNT(ItemId) AS WithItemId
FROM Pharmacy.PharmacyMedicinesStocks;

DROP TABLE #SrcKeyed;
DROP TABLE #DstKeyed;
DROP TABLE #Matched;
