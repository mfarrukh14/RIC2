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
        NULL AS ItemId,
        NULL AS ItemName,
        ISNULL((SELECT SUM(ti.Quantity) FROM Inv.TransferInventoryItems ti WHERE ti.TransferInventoryId = t.Id AND ti.IsActive = 1), 0) AS Quantity,
        t.TransferDate,
        t.Status,
        t.Notes,
        t.IsActive,
        t.CreatedOn
    FROM Inv.TransferInventory t
    LEFT JOIN Inv.Stores fs ON t.FromStoreId = fs.StoreId
    LEFT JOIN Inv.Stores ts ON t.ToStoreId = ts.StoreId
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
        NULL AS ItemId,
        NULL AS ItemName,
        ISNULL((SELECT SUM(ti.Quantity) FROM Inv.TransferInventoryItems ti WHERE ti.TransferInventoryId = t.Id AND ti.IsActive = 1), 0) AS Quantity,
        t.TransferDate,
        t.Status,
        t.Notes,
        t.IsActive,
        t.CreatedById,
        t.CreatedOn,
        t.ModifiedById,
        t.ModifiedOn
    FROM Inv.TransferInventory t
    LEFT JOIN Inv.Stores fs ON t.FromStoreId = fs.StoreId
    LEFT JOIN Inv.Stores ts ON t.ToStoreId = ts.StoreId
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
    @CreatedById INT
AS
BEGIN
    SET NOCOUNT ON;
    
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
        @TransferNumber, @FromStoreId, @ToStoreId, NULL,
        ISNULL(@TransferDate, GETDATE()), @Status, @Notes,
        1, @CreatedById, GETDATE()
    );
    
    DECLARE @NewId INT = SCOPE_IDENTITY();
    
    IF @ItemId IS NOT NULL
    BEGIN
        INSERT INTO Inv.TransferInventoryItems (TransferInventoryId, ItemId, Quantity, Notes, IsActive, CreatedOn)
        VALUES (@NewId, @ItemId, @Quantity, @Notes, 1, GETDATE());
    END
    
    SELECT @NewId as Id;
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
    
    -- Inv.Stores
    SELECT StoreId as Id, StoreName as Name
    FROM Inv.Stores
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

PRINT 'All Inv.TransferInventory stored procedures created successfully';

