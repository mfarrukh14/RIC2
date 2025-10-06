USE InventoryManagementDB_SP;
GO

-- =============================================
-- 1. ReturnInventory_GetAll - Get all return inventory records with filters
-- =============================================
CREATE OR ALTER PROCEDURE ReturnInventory_GetAll
    @BranchId INT = NULL,
    @StoreId INT = NULL,
    @ItemTypeId INT = NULL,
    @ItemType NVARCHAR(50) = NULL, -- 'Medicine', 'Disposable', 'Item', or NULL for All
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
        ri.InventoryNo,
        ri.PurchaseOrderNo,
        ri.BranchId,
        b.Name AS BranchName,
        ri.StoreId,
        s.StoreName AS StoreName,
        ri.ItemTypeId,
        it.Name AS ItemTypeName,
        ri.ItemId,
        ri.ItemName,
        ri.ReturnQuantity,
        ri.StockTypeId,
        st.StockTypeName AS StockTypeName,
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
    FROM ReturnInventory ri
    LEFT JOIN Branches b ON ri.BranchId = b.Id
    LEFT JOIN Stores s ON ri.StoreId = s.StoreId
    LEFT JOIN ItemTypes it ON ri.ItemTypeId = it.Id
    LEFT JOIN StockTypes st ON ri.StockTypeId = st.StockTypeId
    LEFT JOIN Vendors v ON ri.VendorId = v.Id
    WHERE ri.IsActive = 1
        AND (@BranchId IS NULL OR ri.BranchId = @BranchId)
        AND (@StoreId IS NULL OR ri.StoreId = @StoreId)
        AND (@ItemTypeId IS NULL OR ri.ItemTypeId = @ItemTypeId)
        AND (@ItemType IS NULL OR it.Name = @ItemType)
        AND (@StartDate IS NULL OR ri.ReturnDate >= @StartDate)
        AND (@EndDate IS NULL OR ri.ReturnDate <= @EndDate)
        AND (@PurchaseOrderNo IS NULL OR ri.PurchaseOrderNo LIKE '%' + @PurchaseOrderNo + '%')
        AND (@ItemId IS NULL OR ri.ItemId = @ItemId)
        AND (@InventoryNo IS NULL OR ri.InventoryNo LIKE '%' + @InventoryNo + '%')
    ORDER BY ri.CreatedOn DESC;
END
GO

-- =============================================
-- 2. ReturnInventory_GetById - Get a single return inventory record by ID
-- =============================================
CREATE OR ALTER PROCEDURE ReturnInventory_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        ri.Id,
        ri.InventoryNo,
        ri.PurchaseOrderNo,
        ri.BranchId,
        b.Name AS BranchName,
        ri.StoreId,
        s.StoreName AS StoreName,
        ri.ItemTypeId,
        it.Name AS ItemTypeName,
        ri.ItemId,
        ri.ItemName,
        ri.ReturnQuantity,
        ri.StockTypeId,
        st.StockTypeName AS StockTypeName,
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
    FROM ReturnInventory ri
    LEFT JOIN Branches b ON ri.BranchId = b.Id
    LEFT JOIN Stores s ON ri.StoreId = s.StoreId
    LEFT JOIN ItemTypes it ON ri.ItemTypeId = it.Id
    LEFT JOIN StockTypes st ON ri.StockTypeId = st.StockTypeId
    LEFT JOIN Vendors v ON ri.VendorId = v.Id
    WHERE ri.Id = @Id;
END
GO

-- =============================================
-- 3. ReturnInventory_Insert - Insert a new return inventory record
-- =============================================
CREATE OR ALTER PROCEDURE ReturnInventory_Insert
    @InventoryNo NVARCHAR(50) = NULL,
    @PurchaseOrderNo NVARCHAR(50) = NULL,
    @BranchId INT = NULL,
    @StoreId INT = NULL,
    @ItemTypeId INT = NULL,
    @ItemId INT,
    @ItemName NVARCHAR(MAX),
    @ReturnQuantity INT,
    @StockTypeId INT = NULL,
    @VendorId INT = NULL,
    @ReturnDate DATETIME = NULL,
    @Reason NVARCHAR(MAX) = NULL,
    @Notes NVARCHAR(MAX) = NULL,
    @CreatedById INT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Set default return date if not provided
    IF @ReturnDate IS NULL
        SET @ReturnDate = GETDATE();
    
    INSERT INTO ReturnInventory (
        InventoryNo,
        PurchaseOrderNo,
        BranchId,
        StoreId,
        ItemTypeId,
        ItemId,
        ItemName,
        ReturnQuantity,
        StockTypeId,
        VendorId,
        ReturnDate,
        Reason,
        Notes,
        IsActive,
        CreatedById,
        CreatedOn
    )
    VALUES (
        @InventoryNo,
        @PurchaseOrderNo,
        @BranchId,
        @StoreId,
        @ItemTypeId,
        @ItemId,
        @ItemName,
        @ReturnQuantity,
        @StockTypeId,
        @VendorId,
        @ReturnDate,
        @Reason,
        @Notes,
        1,
        @CreatedById,
        GETDATE()
    );
    
    SELECT SCOPE_IDENTITY() AS Id;
END
GO

-- =============================================
-- 4. ReturnInventory_Update - Update an existing return inventory record
-- =============================================
CREATE OR ALTER PROCEDURE ReturnInventory_Update
    @Id INT,
    @InventoryNo NVARCHAR(50) = NULL,
    @PurchaseOrderNo NVARCHAR(50) = NULL,
    @BranchId INT = NULL,
    @StoreId INT = NULL,
    @ItemTypeId INT = NULL,
    @ItemId INT,
    @ItemName NVARCHAR(MAX),
    @ReturnQuantity INT,
    @StockTypeId INT = NULL,
    @VendorId INT = NULL,
    @ReturnDate DATETIME,
    @Reason NVARCHAR(MAX) = NULL,
    @Notes NVARCHAR(MAX) = NULL,
    @ModifiedById INT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE ReturnInventory
    SET 
        InventoryNo = @InventoryNo,
        PurchaseOrderNo = @PurchaseOrderNo,
        BranchId = @BranchId,
        StoreId = @StoreId,
        ItemTypeId = @ItemTypeId,
        ItemId = @ItemId,
        ItemName = @ItemName,
        ReturnQuantity = @ReturnQuantity,
        StockTypeId = @StockTypeId,
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
-- 5. ReturnInventory_Delete - Soft delete a return inventory record
-- =============================================
CREATE OR ALTER PROCEDURE ReturnInventory_Delete
    @Id INT,
    @ModifiedById INT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE ReturnInventory
    SET 
        IsActive = 0,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETDATE()
    WHERE Id = @Id;
    
    SELECT @@ROWCOUNT AS RowsAffected;
END
GO

-- =============================================
-- 6. ReturnInventory_GetLookupData - Get all lookup data for dropdowns
-- =============================================
CREATE OR ALTER PROCEDURE ReturnInventory_GetLookupData
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Get Branches
    SELECT Id, Name
    FROM Branches
    WHERE IsActive = 1
    ORDER BY Name;
    
    -- Get Stores
    SELECT StoreId AS Id, StoreName AS Name
    FROM Stores
    WHERE IsActive = 1
    ORDER BY StoreName;
    
    -- Get Item Types
    SELECT Id, Name
    FROM ItemTypes
    WHERE IsActive = 1
    ORDER BY Name;
    
    -- Get Stock Types
    SELECT StockTypeId AS Id, StockTypeName AS Name
    FROM StockTypes
    WHERE IsActive = 1
    ORDER BY StockTypeName;
    
    -- Get Vendors
    SELECT Id, Name
    FROM Vendors
    WHERE IsActive = 1
    ORDER BY Name;
    
    -- Get Items
    SELECT Id, Name
    FROM Items
    WHERE IsActive = 1
    ORDER BY Name;
END
GO

PRINT 'All ReturnInventory stored procedures created successfully';
