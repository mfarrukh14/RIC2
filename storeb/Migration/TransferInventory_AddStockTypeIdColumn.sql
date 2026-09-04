-- Inv.TransferInventory never had a StockTypeId column. The create/edit form
-- collects Stock Type and TransferInventoryService already sent @StockTypeId
-- to TransferInventory_Insert/Update, but both procs silently dropped it (no
-- column to write it to), and GetAll/GetById hardcoded NULL for it. This adds
-- the column so the value the user picks is actually persisted and can be
-- shown on the Transfer Report PDF. Existing rows are left NULL rather than
-- backfilled with a guessed value - only new/updated transfers get a real one.
--
-- See TransferInventory_Procedures.sql for the matching Insert/Update/GetAll/
-- GetById changes that read and write this column.
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('Inv.TransferInventory') AND name = 'StockTypeId'
)
BEGIN
    ALTER TABLE Inv.TransferInventory ADD StockTypeId INT NULL;
END
GO
