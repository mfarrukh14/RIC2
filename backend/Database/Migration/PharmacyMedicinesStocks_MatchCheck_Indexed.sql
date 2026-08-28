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

PRINT 'Src rows / unique keys:';
SELECT COUNT(*) AS Total,
    (SELECT COUNT(*) FROM (SELECT 1 AS x FROM #SrcKeyed GROUP BY CreatedOn, TotalItemsInStock, SysBatchNo, BatchNo, MinimumPanicLevel, Price, TypeBit HAVING COUNT(*) = 1) u) AS UniqueGroups
FROM #SrcKeyed;

PRINT 'Matched rows (src unique key = dst unique key):';
;WITH SrcDup AS (
    SELECT CreatedOn, TotalItemsInStock, SysBatchNo, BatchNo, MinimumPanicLevel, Price, TypeBit, COUNT(*) AS Cnt
    FROM #SrcKeyed GROUP BY CreatedOn, TotalItemsInStock, SysBatchNo, BatchNo, MinimumPanicLevel, Price, TypeBit
),
DstDup AS (
    SELECT CreatedOn, TotalItemsInStock, SysBatchNo, BatchNo, MinimumPanicLevel, Price, TypeBit, COUNT(*) AS Cnt
    FROM #DstKeyed GROUP BY CreatedOn, TotalItemsInStock, SysBatchNo, BatchNo, MinimumPanicLevel, Price, TypeBit
)
SELECT COUNT(*)
FROM #DstKeyed d
JOIN #SrcKeyed s ON s.CreatedOn = d.CreatedOn AND s.TotalItemsInStock = d.TotalItemsInStock
    AND s.SysBatchNo = d.SysBatchNo AND s.BatchNo = d.BatchNo AND s.MinimumPanicLevel = d.MinimumPanicLevel
    AND s.Price = d.Price AND s.TypeBit = d.TypeBit
JOIN SrcDup sd ON sd.CreatedOn = s.CreatedOn AND sd.TotalItemsInStock = s.TotalItemsInStock AND sd.SysBatchNo = s.SysBatchNo AND sd.BatchNo = s.BatchNo AND sd.MinimumPanicLevel = s.MinimumPanicLevel AND sd.Price = s.Price AND sd.TypeBit = s.TypeBit AND sd.Cnt = 1
JOIN DstDup dd ON dd.CreatedOn = d.CreatedOn AND dd.TotalItemsInStock = d.TotalItemsInStock AND dd.SysBatchNo = d.SysBatchNo AND dd.BatchNo = d.BatchNo AND dd.MinimumPanicLevel = d.MinimumPanicLevel AND dd.Price = d.Price AND dd.TypeBit = d.TypeBit AND dd.Cnt = 1;

DROP TABLE #SrcKeyed;
DROP TABLE #DstKeyed;
