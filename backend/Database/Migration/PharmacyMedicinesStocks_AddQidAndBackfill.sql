-- =============================================================================
-- Pharmacy.PharmacyMedicinesStocks is the LIVE stock ledger (rows go back to
-- 2019, still being written to today) - never wipe/reimport this table.
-- MigratePharmacyMedicinesStocks_HMSMAIN_TF.sql originally left BranchMedicineId
-- /BranchSubServiceId NULL because no destination table tracked those iHealthCure
-- GUIDs at the time. Both now exist (Pharmacy.BranchMedicines.Qid,
-- Data.BranchFees.QID, both 100% populated) - this script adds a QID column
-- (additive, nullable) and backfills BranchMedicineId/BranchSubServiceId on
-- EXISTING rows via UPDATE only. No row is deleted; no balance/quantity column
-- is touched.
--
-- The original migration's #StoreMap/#ItemMap used Name+CreatedOn matching,
-- but Pharmacy.PharmacyStores/Inv.Items CreatedOn have since been reset to a
-- uniform recent timestamp by an unrelated later process - Name alone is still
-- unique on both sides (145/145 stores, 3224/3224 items) and is used instead.
-- =============================================================================

IF COL_LENGTH('Pharmacy.PharmacyMedicinesStocks', 'QID') IS NULL
BEGIN
    ALTER TABLE Pharmacy.PharmacyMedicinesStocks ADD QID UNIQUEIDENTIFIER NULL;
END
GO

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

;WITH StoreMap AS (
    SELECT src.Id AS OldId, tgt.Id AS NewId FROM iHealthCure.dbo.PharmacyStores src JOIN Pharmacy.PharmacyStores tgt ON tgt.Name = src.Name
),
ItemMap AS (
    SELECT src.Id AS OldId, tgt.Id AS NewId FROM iHealthCure.dbo.Items src JOIN Inv.Items tgt ON tgt.Name = src.Name
),
SrcMapped AS (
    SELECT src.Id AS SrcQid, sm.NewId AS NewStoreId, im.NewId AS NewItemId, src.CreatedOn, src.TotalItemsInStock,
        src.SysBatchNo, src.BatchNo, src.BranchMedicineId, src.BranchSubServiceId,
        CONCAT(sm.NewId,'|',ISNULL(im.NewId,-1),'|',src.CreatedOn,'|',ISNULL(src.SysBatchNo,''),'|',ISNULL(src.BatchNo,''),'|',src.TotalItemsInStock) AS MatchKey
    FROM iHealthCure.dbo.PharmacyMedicinesStocks src
    JOIN StoreMap sm ON sm.OldId = src.StoreId
    LEFT JOIN ItemMap im ON im.OldId = src.ItemId
),
SrcUnique AS (
    SELECT * FROM SrcMapped WHERE MatchKey IN (SELECT MatchKey FROM SrcMapped GROUP BY MatchKey HAVING COUNT(*) = 1)
),
DstMapped AS (
    SELECT ID, CONCAT(StoreId,'|',ISNULL(ItemId,-1),'|',CreatedOn,'|',ISNULL(SysBatchNo,''),'|',ISNULL(BatchNo,''),'|',TotalItemsInStock) AS MatchKey
    FROM Pharmacy.PharmacyMedicinesStocks
),
DstUnique AS (
    SELECT * FROM DstMapped WHERE MatchKey IN (SELECT MatchKey FROM DstMapped GROUP BY MatchKey HAVING COUNT(*) = 1)
)
UPDATE p
SET p.QID = s.SrcQid
FROM Pharmacy.PharmacyMedicinesStocks p
JOIN DstUnique d ON d.ID = p.ID
JOIN SrcUnique s ON s.MatchKey = d.MatchKey;

PRINT 'Rows matched and QID populated:';
SELECT COUNT(*) FROM Pharmacy.PharmacyMedicinesStocks WHERE QID IS NOT NULL;

-- Backfill BranchMedicineId from the now-populated QID -> source BranchMedicineId -> BranchMedicines.Qid
UPDATE p
SET p.BranchMedicineId = bm.Id
FROM Pharmacy.PharmacyMedicinesStocks p
JOIN iHealthCure.dbo.PharmacyMedicinesStocks src ON src.Id = p.QID
JOIN Pharmacy.BranchMedicines bm ON bm.Qid = src.BranchMedicineId
WHERE p.BranchMedicineId IS NULL AND src.BranchMedicineId IS NOT NULL;

-- Backfill BranchSubServiceId from the now-populated QID -> source BranchSubServiceId -> Data.BranchFees.QID
UPDATE p
SET p.BranchSubServiceId = bf.Id
FROM Pharmacy.PharmacyMedicinesStocks p
JOIN iHealthCure.dbo.PharmacyMedicinesStocks src ON src.Id = p.QID
JOIN Data.BranchFees bf ON bf.QID = src.BranchSubServiceId
WHERE p.BranchSubServiceId IS NULL AND src.BranchSubServiceId IS NOT NULL;

PRINT 'Final population counts:';
SELECT COUNT(*) AS Total,
    COUNT(QID) AS WithQid,
    COUNT(BranchMedicineId) AS WithBranchMedicineId,
    COUNT(BranchSubServiceId) AS WithBranchSubServiceId,
    COUNT(ItemId) AS WithItemId
FROM Pharmacy.PharmacyMedicinesStocks;
