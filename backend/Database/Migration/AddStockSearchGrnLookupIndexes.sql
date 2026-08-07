-- =============================================
-- Fix Stock_Search timing out / hanging with no data
-- =============================================
-- Stock_Search's OUTER APPLY resolves the item name for TypeBit 4/5 rows (Medicine/Fee -
-- ~71% of Pharmacy.PharmacyMedicinesStocks' 26,755 rows, since BranchMedicineId/
-- BranchSubServiceId are 100% NULL on every live row) by matching
-- p.SysBatchNo = g.InvoiceNo AND p.BatchNo = gi.BatchNo against Inv.GoodsReceivingNotes
-- (30,567 rows) / Inv.GRNItems (44,802 rows). Neither GoodsReceivingNotes.InvoiceNo nor
-- GRNItems.BatchNo had an index - only PKs and IX_GRNItems_GRNId existed - so this
-- correlated subquery ran a full scan of both tables for every one of ~19,000 qualifying
-- stock rows: a full-scan nested loop, which is why the query (and every page built on top
-- of Stock_Search) simply hung/timed out instead of erroring, making it look like "no
-- data" rather than "broken query".
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_GoodsReceivingNotes_InvoiceNo' AND object_id = OBJECT_ID('Inv.GoodsReceivingNotes'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_GoodsReceivingNotes_InvoiceNo
    ON Inv.GoodsReceivingNotes (InvoiceNo)
    INCLUDE (Id);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_GRNItems_BatchNo' AND object_id = OBJECT_ID('Inv.GRNItems'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_GRNItems_BatchNo
    ON Inv.GRNItems (BatchNo)
    INCLUDE (GRNId, DenormalizedItemName);
END
GO

PRINT 'Stock_Search GRN lookup indexes created successfully';
GO
