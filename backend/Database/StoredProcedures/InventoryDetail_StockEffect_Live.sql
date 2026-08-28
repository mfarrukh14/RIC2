-- =============================================
-- Wire "Add Inventory" (Inv.Inventories/Inv.InventoryDetails) into the real
-- live-balance table Pharmacy.PharmacyMedicinesStocks, and into the Stock Flow report.
--
-- Root cause: this app has two parallel stock-receiving paths - "Add Inventory"
-- (Inv.Inventories/InventoryDetails) and GRN (Inv.GoodsReceivingNotes/GRNItems).
-- Neither one ever touched a live stock ledger (confirmed by reading their deployed
-- procs on this DB) despite representing real receiving events with a StoreId and a
-- quantity. The old system's equivalent (Inventories/InventoryItems) always fed
-- through SP_Stock_UpdateStockBalance (TransactionSourceType=1), which both updated
-- the balance AND wrote a StockTransactions ledger row - so "Add Inventory" was
-- always a real, visible stock movement there. This script makes
-- InventoryDetail_Insert/Update/Delete and Inventory_Delete do the equivalent here:
-- credit/reverse the stock ledger directly (matching the AddStockAsync/
-- RemoveStockAsync upsert pattern already used by StockAdjustmentService/
-- StockConsumptionDetail_Insert), keeping it self-contained in SQL like
-- StockConsumptionDetail_Insert already is.
--
-- Targets Pharmacy.PharmacyMedicinesStocks, not Inv.Stocks - investigation found the
-- latter is a one-time migrated snapshot the app's own features had been reading/
-- writing in isolation, already diverged 44% from the live ledger the real HMS
-- pharmacy operations actually update (see Stock_Procedures.sql header for the full
-- writeup). That table has no BranchId/IsActive columns, and its product-key columns
-- are ItemId/BranchMedicineId/BranchSubServiceId (not ItemId/MedicineId/SubServiceId).
--
-- A line can identify its product via ItemId, MedicineId, or SubServiceId (exactly
-- one populated) - see Item_GetAllWithMedicines / ProductKey.
-- =============================================

-- Inv.Inventories/Inv.InventoryDetails carry filtered indexes, which require
-- QUOTED_IDENTIFIER ON to write through (see Inventory_Procedures.sql header).
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.InventoryDetail_Insert', 'P') IS NOT NULL
    DROP PROCEDURE dbo.InventoryDetail_Insert;
GO

CREATE PROCEDURE dbo.InventoryDetail_Insert
    @InventoryId INT,
    @ItemId INT = NULL,
    @MedicineId INT = NULL,
    @SubServiceId INT = NULL,
    @ManufacturerId INT = NULL,
    @MfgDate DATETIME = NULL,
    @ExpiryDate DATETIME = NULL,
    @NoOfBoxes INT = NULL,
    @NoOfPackets INT = NULL,
    @ItemsPerPacket INT = NULL,
    @TotalItems INT = NULL,
    @PackQuantity INT = NULL,
    @UnitBuyingPrice REAL = NULL,
    @TotalBuyingPrice REAL = NULL,
    @AdvanceTaxPercentage REAL = NULL,
    @AdvanceTaxAmount REAL = NULL,
    @Discount BIT = NULL,
    @DiscountAmount REAL = NULL,
    @RetailCharges BIT = NULL,
    @RetailChargesAmount REAL = NULL,
    @GSTCharges BIT = NULL,
    @GSTChargesAmount REAL = NULL,
    @UnitSellingPrice REAL = NULL,
    @TotalSellingPrice REAL = NULL,
    @ProfitMarginPerItem REAL = NULL,
    @ProfitPerItem REAL = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    INSERT INTO Inv.InventoryDetails (
        InventoryId, ItemId, MedicineId, SubServiceId, ManufacturerId, MfgDate, ExpiryDate,
        NoOfBoxes, NoOfPackets, ItemsPerPacket, TotalItems, PackQuantity,
        UnitBuyingPrice, TotalBuyingPrice, AdvanceTaxPercentage, AdvanceTaxAmount,
        Discount, DiscountAmount, RetailCharges, RetailChargesAmount,
        GSTCharges, GSTChargesAmount, UnitSellingPrice, TotalSellingPrice,
        ProfitMarginPerItem, ProfitPerItem
    )
    VALUES (
        @InventoryId, @ItemId, @MedicineId, @SubServiceId, @ManufacturerId, @MfgDate, @ExpiryDate,
        @NoOfBoxes, @NoOfPackets, @ItemsPerPacket, @TotalItems, @PackQuantity,
        @UnitBuyingPrice, @TotalBuyingPrice, @AdvanceTaxPercentage, @AdvanceTaxAmount,
        @Discount, @DiscountAmount, @RetailCharges, @RetailChargesAmount,
        @GSTCharges, @GSTChargesAmount, @UnitSellingPrice, @TotalSellingPrice,
        @ProfitMarginPerItem, @ProfitPerItem
    );

    DECLARE @NewDetailId INT = SCOPE_IDENTITY();
    DECLARE @StoreId INT;
    SELECT @StoreId = StoreId FROM Inv.Inventories WHERE Id = @InventoryId;

    IF @TotalItems IS NOT NULL AND @TotalItems > 0 AND @StoreId IS NOT NULL
    BEGIN
        IF EXISTS (SELECT 1 FROM Pharmacy.PharmacyMedicinesStocks WHERE StoreId = @StoreId
            AND ((@ItemId IS NOT NULL AND ItemId = @ItemId) OR (@MedicineId IS NOT NULL AND BranchMedicineId = @MedicineId) OR (@SubServiceId IS NOT NULL AND BranchSubServiceId = @SubServiceId)))
            UPDATE Pharmacy.PharmacyMedicinesStocks
            SET TotalItemsInStock = ISNULL(TotalItemsInStock, 0) + @TotalItems, ModifiedOn = GETDATE()
            WHERE StoreId = @StoreId
                AND ((@ItemId IS NOT NULL AND ItemId = @ItemId) OR (@MedicineId IS NOT NULL AND BranchMedicineId = @MedicineId) OR (@SubServiceId IS NOT NULL AND BranchSubServiceId = @SubServiceId));
        ELSE
            INSERT INTO Pharmacy.PharmacyMedicinesStocks (ItemId, BranchMedicineId, BranchSubServiceId, StoreId, TotalItemsInStock, MinimumPanicLevel, TotalItemsInTransition, TypeBit, CreatedBy, CreatedOn)
            VALUES (@ItemId, @MedicineId, @SubServiceId, @StoreId, @TotalItems, 0, 0,
                CASE WHEN @ItemId IS NOT NULL THEN 15 WHEN @MedicineId IS NOT NULL THEN 4 WHEN @SubServiceId IS NOT NULL THEN 5 ELSE NULL END,
                1, GETDATE());
    END

    COMMIT TRANSACTION;

    SELECT @NewDetailId as Id;
END
GO

IF OBJECT_ID('dbo.InventoryDetail_Update', 'P') IS NOT NULL
    DROP PROCEDURE dbo.InventoryDetail_Update;
GO

CREATE PROCEDURE dbo.InventoryDetail_Update
    @Id INT,
    @ItemId INT = NULL,
    @MedicineId INT = NULL,
    @SubServiceId INT = NULL,
    @ManufacturerId INT = NULL,
    @MfgDate DATETIME = NULL,
    @ExpiryDate DATETIME = NULL,
    @NoOfBoxes INT = NULL,
    @NoOfPackets INT = NULL,
    @ItemsPerPacket INT = NULL,
    @TotalItems INT = NULL,
    @PackQuantity INT = NULL,
    @UnitBuyingPrice REAL = NULL,
    @TotalBuyingPrice REAL = NULL,
    @AdvanceTaxPercentage REAL = NULL,
    @AdvanceTaxAmount REAL = NULL,
    @Discount BIT = NULL,
    @DiscountAmount REAL = NULL,
    @RetailCharges BIT = NULL,
    @RetailChargesAmount REAL = NULL,
    @GSTCharges BIT = NULL,
    @GSTChargesAmount REAL = NULL,
    @UnitSellingPrice REAL = NULL,
    @TotalSellingPrice REAL = NULL,
    @ProfitMarginPerItem REAL = NULL,
    @ProfitPerItem REAL = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    -- Undo whatever this line previously credited before applying the new quantity -
    -- same reversal-then-reapply pattern as StockAdjustmentService.UpdateAsync.
    DECLARE @OldItemId INT, @OldMedicineId INT, @OldSubServiceId INT, @OldTotalItems INT, @StoreId INT;
    SELECT @OldItemId = d.ItemId, @OldMedicineId = d.MedicineId, @OldSubServiceId = d.SubServiceId,
        @OldTotalItems = d.TotalItems, @StoreId = inv.StoreId
    FROM Inv.InventoryDetails d
    INNER JOIN Inv.Inventories inv ON inv.Id = d.InventoryId
    WHERE d.Id = @Id;

    IF @OldTotalItems IS NOT NULL AND @OldTotalItems > 0 AND @StoreId IS NOT NULL
        UPDATE Pharmacy.PharmacyMedicinesStocks
        SET TotalItemsInStock = ISNULL(TotalItemsInStock, 0) - @OldTotalItems, ModifiedOn = GETDATE()
        WHERE StoreId = @StoreId
            AND ((@OldItemId IS NOT NULL AND ItemId = @OldItemId) OR (@OldMedicineId IS NOT NULL AND BranchMedicineId = @OldMedicineId) OR (@OldSubServiceId IS NOT NULL AND BranchSubServiceId = @OldSubServiceId));

    UPDATE Inv.InventoryDetails
    SET
        ItemId = @ItemId,
        MedicineId = @MedicineId,
        SubServiceId = @SubServiceId,
        ManufacturerId = @ManufacturerId,
        MfgDate = @MfgDate,
        ExpiryDate = @ExpiryDate,
        NoOfBoxes = @NoOfBoxes,
        NoOfPackets = @NoOfPackets,
        ItemsPerPacket = @ItemsPerPacket,
        TotalItems = @TotalItems,
        PackQuantity = @PackQuantity,
        UnitBuyingPrice = @UnitBuyingPrice,
        TotalBuyingPrice = @TotalBuyingPrice,
        AdvanceTaxPercentage = @AdvanceTaxPercentage,
        AdvanceTaxAmount = @AdvanceTaxAmount,
        Discount = @Discount,
        DiscountAmount = @DiscountAmount,
        RetailCharges = @RetailCharges,
        RetailChargesAmount = @RetailChargesAmount,
        GSTCharges = @GSTCharges,
        GSTChargesAmount = @GSTChargesAmount,
        UnitSellingPrice = @UnitSellingPrice,
        TotalSellingPrice = @TotalSellingPrice,
        ProfitMarginPerItem = @ProfitMarginPerItem,
        ProfitPerItem = @ProfitPerItem
    WHERE Id = @Id;

    DECLARE @RowsAffected INT = @@ROWCOUNT;

    IF @TotalItems IS NOT NULL AND @TotalItems > 0 AND @StoreId IS NOT NULL
    BEGIN
        IF EXISTS (SELECT 1 FROM Pharmacy.PharmacyMedicinesStocks WHERE StoreId = @StoreId
            AND ((@ItemId IS NOT NULL AND ItemId = @ItemId) OR (@MedicineId IS NOT NULL AND BranchMedicineId = @MedicineId) OR (@SubServiceId IS NOT NULL AND BranchSubServiceId = @SubServiceId)))
            UPDATE Pharmacy.PharmacyMedicinesStocks
            SET TotalItemsInStock = ISNULL(TotalItemsInStock, 0) + @TotalItems, ModifiedOn = GETDATE()
            WHERE StoreId = @StoreId
                AND ((@ItemId IS NOT NULL AND ItemId = @ItemId) OR (@MedicineId IS NOT NULL AND BranchMedicineId = @MedicineId) OR (@SubServiceId IS NOT NULL AND BranchSubServiceId = @SubServiceId));
        ELSE
            INSERT INTO Pharmacy.PharmacyMedicinesStocks (ItemId, BranchMedicineId, BranchSubServiceId, StoreId, TotalItemsInStock, MinimumPanicLevel, TotalItemsInTransition, TypeBit, CreatedBy, CreatedOn)
            VALUES (@ItemId, @MedicineId, @SubServiceId, @StoreId, @TotalItems, 0, 0,
                CASE WHEN @ItemId IS NOT NULL THEN 15 WHEN @MedicineId IS NOT NULL THEN 4 WHEN @SubServiceId IS NOT NULL THEN 5 ELSE NULL END,
                1, GETDATE());
    END

    COMMIT TRANSACTION;

    SELECT @RowsAffected as AffectedRows;
END
GO

IF OBJECT_ID('dbo.InventoryDetail_Delete', 'P') IS NOT NULL
    DROP PROCEDURE dbo.InventoryDetail_Delete;
GO

CREATE PROCEDURE dbo.InventoryDetail_Delete
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    DECLARE @ItemId INT, @MedicineId INT, @SubServiceId INT, @TotalItems INT, @StoreId INT;
    SELECT @ItemId = d.ItemId, @MedicineId = d.MedicineId, @SubServiceId = d.SubServiceId,
        @TotalItems = d.TotalItems, @StoreId = inv.StoreId
    FROM Inv.InventoryDetails d
    INNER JOIN Inv.Inventories inv ON inv.Id = d.InventoryId
    WHERE d.Id = @Id;

    IF @TotalItems IS NOT NULL AND @TotalItems > 0 AND @StoreId IS NOT NULL
        UPDATE Pharmacy.PharmacyMedicinesStocks
        SET TotalItemsInStock = ISNULL(TotalItemsInStock, 0) - @TotalItems, ModifiedOn = GETDATE()
        WHERE StoreId = @StoreId
            AND ((@ItemId IS NOT NULL AND ItemId = @ItemId) OR (@MedicineId IS NOT NULL AND BranchMedicineId = @MedicineId) OR (@SubServiceId IS NOT NULL AND BranchSubServiceId = @SubServiceId));

    DELETE FROM Inv.InventoryDetails WHERE Id = @Id;

    DECLARE @RowsAffected INT = @@ROWCOUNT;

    COMMIT TRANSACTION;

    SELECT @RowsAffected as AffectedRows;
END
GO

IF OBJECT_ID('dbo.Inventory_Delete', 'P') IS NOT NULL
    DROP PROCEDURE dbo.Inventory_Delete;
GO

CREATE PROCEDURE dbo.Inventory_Delete
    @Id INT,
    @ModifiedById INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    -- Cancelling the whole receipt reverses every line's credit, same as deleting
    -- each detail individually.
    UPDATE s
    SET s.TotalItemsInStock = ISNULL(s.TotalItemsInStock, 0) - d.TotalItems, s.ModifiedOn = GETDATE()
    FROM Pharmacy.PharmacyMedicinesStocks s
    INNER JOIN Inv.InventoryDetails d
        ON (d.ItemId IS NOT NULL AND d.ItemId = s.ItemId)
        OR (d.MedicineId IS NOT NULL AND d.MedicineId = s.BranchMedicineId)
        OR (d.SubServiceId IS NOT NULL AND d.SubServiceId = s.BranchSubServiceId)
    INNER JOIN Inv.Inventories inv ON inv.Id = d.InventoryId
    WHERE inv.Id = @Id AND s.StoreId = inv.StoreId
      AND d.TotalItems IS NOT NULL AND d.TotalItems > 0;

    UPDATE Inv.Inventories
    SET
        IsActive = 0,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETDATE()
    WHERE Id = @Id;

    DECLARE @RowsAffected INT = @@ROWCOUNT;

    COMMIT TRANSACTION;

    SELECT @RowsAffected as AffectedRows;
END
GO

PRINT 'Inventory detail stock-effect procedures updated successfully.';
