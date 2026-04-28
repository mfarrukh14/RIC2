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
        b.Name AS BranchName,
        ri.StoreId,
        s.StoreName AS StoreName,
        NULL AS ItemTypeId,
        NULL AS ItemTypeName,
        NULL AS ItemId,
        NULL AS ItemName,
        ISNULL((SELECT SUM(rii.Quantity) FROM dbo.ReturnInventoryItems rii WHERE rii.ReturnInventoryId = ri.Id AND rii.IsActive = 1), 0) AS ReturnQuantity,
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
    FROM dbo.ReturnInventory ri
    LEFT JOIN dbo.Branches b ON ri.BranchId = b.Id
    LEFT JOIN dbo.Stores s ON ri.StoreId = s.StoreId
    LEFT JOIN dbo.Vendors v ON ri.VendorId = v.Id
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
        b.Name AS BranchName,
        ri.StoreId,
        s.StoreName AS StoreName,
        NULL AS ItemTypeId,
        NULL AS ItemTypeName,
        NULL AS ItemId,
        NULL AS ItemName,
        ISNULL((SELECT SUM(rii.Quantity) FROM dbo.ReturnInventoryItems rii WHERE rii.ReturnInventoryId = ri.Id AND rii.IsActive = 1), 0) AS ReturnQuantity,
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
    FROM dbo.ReturnInventory ri
    LEFT JOIN dbo.Branches b ON ri.BranchId = b.Id
    LEFT JOIN dbo.Stores s ON ri.StoreId = s.StoreId
    LEFT JOIN dbo.Vendors v ON ri.VendorId = v.Id
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
        SELECT @NextId = ISNULL(MAX(Id), 0) + 1 FROM dbo.ReturnInventory;
        SET @InventoryNo = 'RET-' + RIGHT('00000' + CAST(@NextId AS VARCHAR(5)), 5);
    END
    
    INSERT INTO dbo.ReturnInventory (
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
        INSERT INTO dbo.ReturnInventoryItems (ItemId, ReturnInventoryId, Quantity, Reason, Notes, IsActive, CreatedOn)
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
    
    UPDATE dbo.ReturnInventory
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
    
    UPDATE dbo.ReturnInventory
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
    
    SELECT Id, Name FROM dbo.Branches WHERE IsActive = 1 ORDER BY Name;
    SELECT StoreId AS Id, StoreName AS Name FROM dbo.Stores WHERE IsActive = 1 ORDER BY StoreName;
    SELECT Id, Name FROM dbo.ItemTypes WHERE IsActive = 1 ORDER BY Name;
    SELECT Id, Name FROM dbo.StockTypes WHERE IsActive = 1 ORDER BY Name;
    SELECT Id, Name FROM dbo.Vendors WHERE IsActive = 1 ORDER BY Name;
    SELECT Id, Name FROM dbo.Items WHERE IsActive = 1 ORDER BY Name;
END
GO

PRINT 'All dbo.ReturnInventory stored procedures created successfully';

