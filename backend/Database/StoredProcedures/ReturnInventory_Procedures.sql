-- =============================================
-- 1. ReturnInventory_GetAll
-- =============================================
CREATE OR ALTER PROCEDURE dbo.ReturnInventory_GetAll
    @BranchId INT = NULL,
    @StoreId INT = NULL,
    @ItemTypeId INT = NULL,
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL,
    @PurchaseOrderNo NVARCHAR(50) = NULL,
    @ItemId INT = NULL,
    @InventoryNo NVARCHAR(50) = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (CASE WHEN @PageNumber < 1 THEN 0 ELSE @PageNumber - 1 END) * (CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END);
    DECLARE @Take INT = CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END;

    SELECT
        ri.Id,
        ri.ReturnNumber AS InventoryNo,
        ri.PurchaseOrderNo,
        ri.BranchId,
        b.Name AS BranchName,
        ri.StoreId,
        s.StoreName AS StoreName,
        ri.ItemTypeId,
        it.Name AS ItemTypeName,
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
        ri.ModifiedOn,
        COUNT(*) OVER() AS TotalCount
    FROM Inv.ReturnInventory ri
    LEFT JOIN Inv.Branches b ON ri.BranchId = b.Id
    LEFT JOIN Inv.PharmacyStores s ON ri.StoreId = s.StoreId
    LEFT JOIN Inv.ItemTypes it ON ri.ItemTypeId = it.Id
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
        AND (@ItemTypeId IS NULL OR ri.ItemTypeId = @ItemTypeId)
        AND (@StartDate IS NULL OR ri.ReturnDate >= @StartDate)
        AND (@EndDate IS NULL OR ri.ReturnDate <= @EndDate)
        AND (@PurchaseOrderNo IS NULL OR ri.PurchaseOrderNo = @PurchaseOrderNo)
        AND (@InventoryNo IS NULL OR ri.ReturnNumber LIKE '%' + @InventoryNo + '%')
        AND (@ItemId IS NULL OR EXISTS (
            SELECT 1 FROM Inv.ReturnInventoryItems rii2
            WHERE rii2.ReturnInventoryId = ri.Id AND rii2.ItemId = @ItemId AND rii2.IsActive = 1
        ))
    ORDER BY ri.CreatedOn DESC
    OFFSET @Offset ROWS FETCH NEXT @Take ROWS ONLY;
END
GO

-- =============================================
-- 2. ReturnInventory_GetById
-- =============================================
CREATE OR ALTER PROCEDURE dbo.ReturnInventory_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ri.Id,
        ri.ReturnNumber AS InventoryNo,
        ri.PurchaseOrderNo,
        ri.BranchId,
        b.Name AS BranchName,
        ri.StoreId,
        s.StoreName AS StoreName,
        ri.ItemTypeId,
        it.Name AS ItemTypeName,
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
    LEFT JOIN Inv.Branches b ON ri.BranchId = b.Id
    LEFT JOIN Inv.PharmacyStores s ON ri.StoreId = s.StoreId
    LEFT JOIN Inv.ItemTypes it ON ri.ItemTypeId = it.Id
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
-- Pure header+item insert - no stock/PO/GRN side effects. Those are applied by
-- ReturnInventoryService in the same SqlTransaction before this runs, mirroring
-- the StockAdjustmentService pattern (proc for bookkeeping rows, C# for the
-- cross-table stock math so it can be validated/rolled back together).
-- =============================================
CREATE OR ALTER PROCEDURE dbo.ReturnInventory_Insert
    @InventoryNo NVARCHAR(50) = NULL,
    @PurchaseOrderNo NVARCHAR(50) = NULL,
    @BranchId INT,
    @StoreId INT,
    @ItemTypeId INT = NULL,
    @ItemId INT,
    @ReturnQuantity INT,
    @VendorId INT = NULL,
    @ReturnDate DATETIME = NULL,
    @Reason NVARCHAR(MAX) = NULL,
    @Notes NVARCHAR(MAX) = NULL,
    @CreatedById INT
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
        ReturnNumber, PurchaseOrderNo, BranchId, StoreId, ItemTypeId, VendorId,
        ReturnDate, Reason, Notes, Status,
        IsActive, CreatedById, CreatedOn
    )
    VALUES (
        @InventoryNo, @PurchaseOrderNo, @BranchId, @StoreId, @ItemTypeId, @VendorId,
        @ReturnDate, @Reason, @Notes, 'Completed',
        1, @CreatedById, GETDATE()
    );

    DECLARE @NewId INT = SCOPE_IDENTITY();

    INSERT INTO Inv.ReturnInventoryItems (ItemId, ReturnInventoryId, Quantity, Reason, Notes, IsActive, CreatedOn)
    VALUES (@ItemId, @NewId, @ReturnQuantity, @Reason, @Notes, 1, GETDATE());

    SELECT @NewId AS Id;
END
GO

-- =============================================
-- 4. ReturnInventory_Update
-- Header-only edit (store/vendor/date/reason/notes). Does not re-apply stock
-- effects - matches original behavior; quantity/item corrections should be
-- done via a new return rather than editing a past one.
-- =============================================
CREATE OR ALTER PROCEDURE dbo.ReturnInventory_Update
    @Id INT,
    @PurchaseOrderNo NVARCHAR(50) = NULL,
    @StoreId INT,
    @ItemTypeId INT = NULL,
    @VendorId INT = NULL,
    @ReturnDate DATETIME,
    @Reason NVARCHAR(MAX) = NULL,
    @Notes NVARCHAR(MAX) = NULL,
    @ModifiedById INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Inv.ReturnInventory
    SET
        PurchaseOrderNo = @PurchaseOrderNo,
        StoreId = @StoreId,
        ItemTypeId = @ItemTypeId,
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
CREATE OR ALTER PROCEDURE dbo.ReturnInventory_Delete
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
CREATE OR ALTER PROCEDURE dbo.ReturnInventory_GetLookupData
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id, Name FROM Inv.Branches WHERE IsActive = 1 ORDER BY Name;
    SELECT StoreId AS Id, StoreName AS Name FROM Inv.PharmacyStores WHERE IsActive = 1 ORDER BY StoreName;
    SELECT Id, Name FROM Inv.ItemTypes WHERE IsActive = 1 ORDER BY Name;
    SELECT Id, Name FROM Inv.Vendors WHERE IsActive = 1 ORDER BY Name;
END
GO

PRINT 'All Inv.ReturnInventory stored procedures created successfully';
