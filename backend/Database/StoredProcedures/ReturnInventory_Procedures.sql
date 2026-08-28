USE InventoryManagementDB_SP;
GO

-- =============================================
-- 1. ReturnInventory_GetAll
-- =============================================
CREATE OR ALTER PROCEDURE ReturnInventory_GetAll
    @BranchId INT = NULL,
    @StoreId INT = NULL,
    @ItemTypeId INT = NULL,
    @ItemType NVARCHAR(50) = NULL,
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL,
    @PurchaseOrderNo NVARCHAR(50) = NULL,
    @ItemId INT = NULL,
    @InventoryNo NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        ri.Id,
        ri.ReturnNumber AS InventoryNo,
        NULL AS PurchaseOrderNo,
        ri.BranchId,
        b.BranchName AS BranchName,
        ri.StoreId,
        s.StoreName AS StoreName,
        NULL AS ItemTypeId,
        NULL AS ItemTypeName,
        primaryItem.ItemId,
        primaryItem.ItemName,
        ISNULL(itemTotals.ReturnQuantity, 0) AS ReturnQuantity,
        NULL AS StockTypeId,
        NULL AS StockTypeName,
        ri.VendorId,
        v.Name AS VendorName,
        ri.ReturnDate,
        ri.Reason,
        ri.Notes,
        ri.IsActive,
        ri.CreatedById,
        ri.CreatedOn,
        ri.ModifiedById,
        ri.ModifiedOn
    FROM Inv.ReturnInventory ri
    LEFT JOIN dbo.Branch b ON ri.BranchId = b.BranchId
    LEFT JOIN Inv.Stores s ON ri.StoreId = s.StoreId
    LEFT JOIN Inv.Vendors v ON ri.VendorId = v.Id
    OUTER APPLY (
        SELECT TOP (1)
            rii.ItemId,
            i.Name AS ItemName
        FROM Inv.ReturnInventoryItems rii
        LEFT JOIN Inv.Items i ON rii.ItemId = i.Id
        WHERE rii.ReturnInventoryId = ri.Id
            AND rii.IsActive = 1
        ORDER BY rii.Id DESC
    ) primaryItem
    OUTER APPLY (
        SELECT SUM(rii.Quantity) AS ReturnQuantity
        FROM Inv.ReturnInventoryItems rii
        WHERE rii.ReturnInventoryId = ri.Id
            AND rii.IsActive = 1
    ) itemTotals
    WHERE ri.IsActive = 1
        AND (@BranchId IS NULL OR ri.BranchId = @BranchId)
        AND (@StoreId IS NULL OR ri.StoreId = @StoreId)
        AND (@StartDate IS NULL OR ri.ReturnDate >= @StartDate)
        AND (@EndDate IS NULL OR ri.ReturnDate <= @EndDate)
    ORDER BY ri.CreatedOn DESC;
END
GO

-- =============================================
-- 2. ReturnInventory_GetById
-- =============================================
CREATE OR ALTER PROCEDURE ReturnInventory_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        ri.Id,
        ri.ReturnNumber AS InventoryNo,
        NULL AS PurchaseOrderNo,
        ri.BranchId,
        b.BranchName AS BranchName,
        ri.StoreId,
        s.StoreName AS StoreName,
        NULL AS ItemTypeId,
        NULL AS ItemTypeName,
        primaryItem.ItemId,
        primaryItem.ItemName,
        ISNULL(itemTotals.ReturnQuantity, 0) AS ReturnQuantity,
        NULL AS StockTypeId,
        NULL AS StockTypeName,
        ri.VendorId,
        v.Name AS VendorName,
        ri.ReturnDate,
        ri.Reason,
        ri.Notes,
        ri.IsActive,
        ri.CreatedById,
        ri.CreatedOn,
        ri.ModifiedById,
        ri.ModifiedOn
    FROM Inv.ReturnInventory ri
    LEFT JOIN dbo.Branch b ON ri.BranchId = b.BranchId
    LEFT JOIN Inv.Stores s ON ri.StoreId = s.StoreId
    LEFT JOIN Inv.Vendors v ON ri.VendorId = v.Id
    OUTER APPLY (
        SELECT TOP (1)
            rii.ItemId,
            i.Name AS ItemName
        FROM Inv.ReturnInventoryItems rii
        LEFT JOIN Inv.Items i ON rii.ItemId = i.Id
        WHERE rii.ReturnInventoryId = ri.Id
            AND rii.IsActive = 1
        ORDER BY rii.Id DESC
    ) primaryItem
    OUTER APPLY (
        SELECT SUM(rii.Quantity) AS ReturnQuantity
        FROM Inv.ReturnInventoryItems rii
        WHERE rii.ReturnInventoryId = ri.Id
            AND rii.IsActive = 1
    ) itemTotals
    WHERE ri.Id = @Id;
END
GO

-- =============================================
-- 3. ReturnInventory_Insert
-- =============================================
CREATE OR ALTER PROCEDURE ReturnInventory_Insert
    @InventoryNo NVARCHAR(50) = NULL,
    @PurchaseOrderNo NVARCHAR(50) = NULL,
    @BranchId INT = NULL,
    @StoreId INT = NULL,
    @ItemTypeId INT = NULL,
    @ItemId INT = NULL,
    @ItemName NVARCHAR(MAX) = NULL,
    @ReturnQuantity INT = 0,
    @StockTypeId INT = NULL,
    @VendorId INT = NULL,
    @ReturnDate DATETIME = NULL,
    @Reason NVARCHAR(MAX) = NULL,
    @Notes NVARCHAR(MAX) = NULL,
    @CreatedById INT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @ReturnDate IS NULL
        SET @ReturnDate = GETDATE();
    
    IF @InventoryNo IS NULL
    BEGIN
        DECLARE @NextId INT;
        SELECT @NextId = ISNULL(MAX(Id), 0) + 1 FROM Inv.ReturnInventory;
        SET @InventoryNo = 'RET-' + RIGHT('00000' + CAST(@NextId AS VARCHAR(5)), 5);
    END
    
    INSERT INTO Inv.ReturnInventory (
        ReturnNumber, BranchId, StoreId, VendorId,
        ReturnDate, Reason, Notes, Status,
        IsActive, CreatedById, CreatedOn
    )
    VALUES (
        @InventoryNo, @BranchId, @StoreId, @VendorId,
        @ReturnDate, @Reason, @Notes, 'Pending',
        1, @CreatedById, GETDATE()
    );
    
    DECLARE @NewId INT = SCOPE_IDENTITY();
    
    IF @ItemId IS NOT NULL
    BEGIN
        INSERT INTO Inv.ReturnInventoryItems (ItemId, ReturnInventoryId, Quantity, Reason, Notes, IsActive, CreatedOn)
        VALUES (@ItemId, @NewId, @ReturnQuantity, @Reason, @Notes, 1, GETDATE());
    END
    
    SELECT @NewId AS Id;
END
GO

-- =============================================
-- 4. ReturnInventory_Update
-- =============================================
CREATE OR ALTER PROCEDURE ReturnInventory_Update
    @Id INT,
    @InventoryNo NVARCHAR(50) = NULL,
    @PurchaseOrderNo NVARCHAR(50) = NULL,
    @BranchId INT = NULL,
    @StoreId INT = NULL,
    @ItemTypeId INT = NULL,
    @ItemId INT = NULL,
    @ItemName NVARCHAR(MAX) = NULL,
    @ReturnQuantity INT = 0,
    @StockTypeId INT = NULL,
    @VendorId INT = NULL,
    @ReturnDate DATETIME = NULL,
    @Reason NVARCHAR(MAX) = NULL,
    @Notes NVARCHAR(MAX) = NULL,
    @ModifiedById INT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE Inv.ReturnInventory
    SET 
        BranchId = @BranchId,
        StoreId = @StoreId,
        VendorId = @VendorId,
        ReturnDate = @ReturnDate,
        Reason = @Reason,
        Notes = @Notes,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETDATE()
    WHERE Id = @Id;
    
    SELECT @@ROWCOUNT AS RowsAffected;
END
GO

-- =============================================
-- 5. ReturnInventory_Delete
-- =============================================
CREATE OR ALTER PROCEDURE ReturnInventory_Delete
    @Id INT,
    @ModifiedById INT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE Inv.ReturnInventory
    SET 
        IsActive = 0,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETDATE()
    WHERE Id = @Id;
    
    SELECT @@ROWCOUNT AS RowsAffected;
END
GO

-- =============================================
-- 6. ReturnInventory_GetLookupData
-- =============================================
CREATE OR ALTER PROCEDURE ReturnInventory_GetLookupData
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT BranchId AS Id, BranchName AS Name FROM dbo.Branch WHERE IsActive = 1 ORDER BY BranchName;
    SELECT StoreId AS Id, StoreName AS Name FROM Inv.Stores WHERE IsActive = 1 ORDER BY StoreName;
    SELECT Id, Name FROM Inv.ItemTypes WHERE IsActive = 1 ORDER BY Name;
    SELECT Id, Name FROM Inv.StockTypes WHERE IsActive = 1 ORDER BY Name;
    SELECT Id, Name FROM Inv.Vendors WHERE IsActive = 1 ORDER BY Name;
    SELECT Id, Name FROM Inv.Items WHERE IsActive = 1 ORDER BY Name;
END
GO

PRINT 'All Inv.ReturnInventory stored procedures created successfully';

