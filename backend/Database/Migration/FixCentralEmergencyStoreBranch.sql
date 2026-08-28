-- Central Store (149) and Emergency Store (148) were left on @MainBranchId=1 by
-- MigrateFromIHealthCure_HMSMAIN_TF.sql along with everything else it inserted.
-- Every other PharmacyStore already correctly has BranchId=20 (RIC). Fixing just
-- these 2 so stock movements through them log with the right BranchId going
-- forward (Pharmacy.TR_PharmacyMedicinesStocks_LogTransactions derives BranchId
-- from this table).
IF OBJECT_ID('dbo.BranchReassign_1to20_Backup', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.BranchReassign_1to20_Backup (
        TableName NVARCHAR(128) NOT NULL,
        RowId INT NOT NULL,
        OldBranchId INT NOT NULL,
        CapturedOn DATETIME NOT NULL DEFAULT GETUTCDATE()
    );
END

INSERT INTO dbo.BranchReassign_1to20_Backup (TableName, RowId, OldBranchId)
SELECT 'Inv.PharmacyStores', StoreId, BranchId FROM Inv.PharmacyStores WHERE StoreId IN (148, 149) AND BranchId = 1;

UPDATE Inv.PharmacyStores SET BranchId = 20 WHERE StoreId IN (148, 149) AND BranchId = 1;

SELECT StoreId, StoreName, BranchId FROM Inv.PharmacyStores WHERE StoreId IN (148, 149);
