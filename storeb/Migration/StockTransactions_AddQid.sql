-- Run once, before any batch. Additive only - no existing row touched.
IF COL_LENGTH('Inv.StockTransactions', 'QID') IS NULL
BEGIN
    ALTER TABLE Inv.StockTransactions ADD QID UNIQUEIDENTIFIER NULL;
END
GO
PRINT 'QID column ready on Inv.StockTransactions.';
