USE InventoryManagementDB_SP;
GO

-- =============================================
-- 1. TransferInventory_GetAll
-- =============================================
CREATE OR ALTER PROCEDURE TransferInventory_GetAll
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        t.Id,
        t.TransferNumber AS DRNo,
        t.FromStoreId,
        fs.StoreName as FromStoreName,
        t.ToStoreId,
        ts.StoreName as ToStoreName,
        NULL AS StockTypeId,
        NULL AS StockTypeName,
        ti.ItemId,
        i.Name AS ItemName,
        ISNULL((SELECT SUM(ti2.Quantity) FROM Inv.TransferInventoryItems ti2 WHERE ti2.TransferInventoryId = t.Id AND ti2.IsActive = 1), 0) AS Quantity,
        t.TransferDate,
        t.Status,
        t.Notes,
        t.IsActive,
        t.CreatedOn
    FROM Inv.TransferInventory t
    LEFT JOIN Inv.PharmacyStores fs ON t.FromStoreId = fs.StoreId
    LEFT JOIN Inv.PharmacyStores ts ON t.ToStoreId = ts.StoreId
    OUTER APPLY (
        SELECT TOP 1 ItemId
        FROM Inv.TransferInventoryItems
        WHERE TransferInventoryId = t.Id AND IsActive = 1
        ORDER BY Id
    ) ti
    LEFT JOIN Inv.Items i ON ti.ItemId = i.Id
    WHERE t.IsActive = 1
    ORDER BY t.CreatedOn DESC;
END
GO

-- =============================================
-- 2. TransferInventory_GetById
-- =============================================
CREATE OR ALTER PROCEDURE TransferInventory_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        t.Id,
        t.TransferNumber AS DRNo,
        t.FromStoreId,
        fs.StoreName as FromStoreName,
        t.ToStoreId,
        ts.StoreName as ToStoreName,
        NULL AS StockTypeId,
        NULL AS StockTypeName,
        ti.ItemId,
        i.Name AS ItemName,
        ISNULL((SELECT SUM(ti2.Quantity) FROM Inv.TransferInventoryItems ti2 WHERE ti2.TransferInventoryId = t.Id AND ti2.IsActive = 1), 0) AS Quantity,
        t.TransferDate,
        t.Status,
        t.Notes,
        t.IsActive,
        t.CreatedById,
        t.CreatedOn,
        t.ModifiedById,
        t.ModifiedOn
    FROM Inv.TransferInventory t
    LEFT JOIN Inv.PharmacyStores fs ON t.FromStoreId = fs.StoreId
    LEFT JOIN Inv.PharmacyStores ts ON t.ToStoreId = ts.StoreId
    OUTER APPLY (
        SELECT TOP 1 ItemId
        FROM Inv.TransferInventoryItems
        WHERE TransferInventoryId = t.Id AND IsActive = 1
        ORDER BY Id
    ) ti
    LEFT JOIN Inv.Items i ON ti.ItemId = i.Id
    WHERE t.Id = @Id;
END
GO

-- =============================================
-- 3. TransferInventory_Insert
-- =============================================
CREATE OR ALTER PROCEDURE TransferInventory_Insert
    @FromStoreId INT,
    @ToStoreId INT,
    @StockTypeId INT = NULL,
    @ItemId INT = NULL,
    @ItemName NVARCHAR(MAX) = NULL,
    @Quantity INT = 0,
    @TransferDate DATETIME = NULL,
    @Status NVARCHAR(50) = 'Pending',
    @Notes NVARCHAR(MAX) = NULL,
    @BranchId INT = NULL,
    @CreatedById INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Block transferring more than is actually on hand for this item in the
    -- source store, per Pharmacy.PharmacyMedicinesStocks - the live-balance table the
    -- real HMS pharmacy operations update (also used by Stock Consumption, Stock Audit,
    -- and the Stock search page - see Stock_Procedures.sql header for why it's not
    -- Inv.Stocks).
    DECLARE @Available INT = 0;
    IF @ItemId IS NOT NULL
    BEGIN
        SELECT @Available = ISNULL(SUM(TotalItemsInStock), 0)
        FROM Pharmacy.PharmacyMedicinesStocks
        WHERE ItemId = @ItemId AND StoreId = @FromStoreId;

        IF @Quantity > @Available
        BEGIN
            DECLARE @ItemNameForError NVARCHAR(255) = (SELECT Name FROM Inv.Items WHERE Id = @ItemId);
            DECLARE @StoreNameForError NVARCHAR(255) = (SELECT StoreName FROM Inv.PharmacyStores WHERE StoreId = @FromStoreId);
            RAISERROR('Cannot transfer %d unit(s) of ''%s'' - only %d available in ''%s''.', 16, 1, @Quantity, @ItemNameForError, @Available, @StoreNameForError);
            RETURN;
        END
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @TransferNumber NVARCHAR(50);
        DECLARE @NextId INT;
        SELECT @NextId = ISNULL(MAX(Id), 0) + 1 FROM Inv.TransferInventory;
        SET @TransferNumber = 'DR-' + RIGHT('00000' + CAST(@NextId AS VARCHAR(5)), 5);

        INSERT INTO Inv.TransferInventory (
            TransferNumber, FromStoreId, ToStoreId, BranchId,
            TransferDate, Status, Notes,
            IsActive, CreatedById, CreatedOn
        )
        VALUES (
            @TransferNumber, @FromStoreId, @ToStoreId, @BranchId,
            ISNULL(@TransferDate, GETDATE()), @Status, @Notes,
            1, @CreatedById, GETDATE()
        );

        DECLARE @NewId INT = SCOPE_IDENTITY();

        IF @ItemId IS NOT NULL
        BEGIN
            INSERT INTO Inv.TransferInventoryItems (TransferInventoryId, ItemId, Quantity, Notes, IsActive, CreatedOn)
            VALUES (@NewId, @ItemId, @Quantity, @Notes, 1, GETDATE());

            -- Move the balance in Pharmacy.PharmacyMedicinesStocks: decrement the source
            -- store, increment (or create) the destination store's row. No BranchId
            -- column on this table (branch is only reachable via the store).
            UPDATE Pharmacy.PharmacyMedicinesStocks
            SET TotalItemsInStock = TotalItemsInStock - @Quantity,
                ModifiedOn = GETDATE()
            WHERE ItemId = @ItemId AND StoreId = @FromStoreId;

            IF EXISTS (SELECT 1 FROM Pharmacy.PharmacyMedicinesStocks WHERE ItemId = @ItemId AND StoreId = @ToStoreId)
            BEGIN
                UPDATE Pharmacy.PharmacyMedicinesStocks
                SET TotalItemsInStock = ISNULL(TotalItemsInStock, 0) + @Quantity,
                    ModifiedOn = GETDATE()
                WHERE ItemId = @ItemId AND StoreId = @ToStoreId;
            END
            ELSE
            BEGIN
                INSERT INTO Pharmacy.PharmacyMedicinesStocks (ItemId, TotalItemsInStock, MinimumPanicLevel, TotalItemsInTransition, TypeBit, StoreId, CreatedBy, CreatedOn)
                VALUES (@ItemId, @Quantity, 0, 0, 15, @ToStoreId, 1, GETDATE());
            END
        END

        COMMIT TRANSACTION;
        SELECT @NewId as Id;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- =============================================
-- 3b. TransferInventory_GetAvailableQuantity
-- =============================================
CREATE OR ALTER PROCEDURE TransferInventory_GetAvailableQuantity
    @StoreId INT,
    @ItemId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT ISNULL(SUM(TotalItemsInStock), 0) AS AvailableQuantity
    FROM Pharmacy.PharmacyMedicinesStocks
    WHERE ItemId = @ItemId
      AND StoreId = @StoreId;
END
GO

-- =============================================
-- 4. TransferInventory_Update
-- =============================================
CREATE OR ALTER PROCEDURE TransferInventory_Update
    @Id INT,
    @FromStoreId INT,
    @ToStoreId INT,
    @StockTypeId INT = NULL,
    @ItemId INT = NULL,
    @ItemName NVARCHAR(MAX) = NULL,
    @Quantity INT = 0,
    @Status NVARCHAR(50) = NULL,
    @Notes NVARCHAR(MAX) = NULL,
    @ModifiedById INT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE Inv.TransferInventory
    SET
        FromStoreId = @FromStoreId,
        ToStoreId = @ToStoreId,
        Status = ISNULL(@Status, Status),
        Notes = @Notes,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETDATE()
    WHERE Id = @Id;
    
    SELECT @@ROWCOUNT as AffectedRows;
END
GO

-- =============================================
-- 5. TransferInventory_Delete
-- =============================================
CREATE OR ALTER PROCEDURE TransferInventory_Delete
    @Id INT,
    @ModifiedById INT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE Inv.TransferInventory
    SET
        IsActive = 0,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETDATE()
    WHERE Id = @Id;
    
    SELECT @@ROWCOUNT as AffectedRows;
END
GO

-- =============================================
-- 6. TransferInventory_GetLookupData
-- =============================================
CREATE OR ALTER PROCEDURE TransferInventory_GetLookupData
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Inv.PharmacyStores
    SELECT StoreId as Id, StoreName as Name
    FROM Inv.PharmacyStores
    WHERE IsActive = 1
    ORDER BY StoreName;

    -- Stock Types
    SELECT Id, Name
    FROM Inv.StockTypes
    WHERE IsActive = 1
    ORDER BY Name;

    -- Inv.Items
    SELECT Id, Name
    FROM Inv.Items
    WHERE IsActive = 1
    ORDER BY Name;
END
GO

PRINT 'All TransferInventory stored procedures created successfully';

