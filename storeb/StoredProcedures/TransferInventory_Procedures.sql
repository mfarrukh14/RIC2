USE InventoryManagementDB_SP;
GO

-- =============================================
-- 1. TransferInventory_GetAll
-- =============================================
-- Adds store-scoped access control to TransferInventory_GetAll - a transfer
-- has two store legs (From/To), so unlike a single-store list, a non-admin
-- sees a transfer if EITHER their From or To store is one they're allowed to
-- see (they may only be assigned the receiving store, for instance, and still
-- legitimately need to see stock arriving there). Same
-- IsAdmin/AllowedStoreIds pattern as StockSearch_AddStoreScoping.sql.
--
-- TransferredByName is resolved from t.CreatedById via Users -> Employee,
-- same pattern as DemandRequestService's RequestedByName - used by the
-- Transfer Report PDF's "Transferred By" field.
CREATE OR ALTER PROCEDURE TransferInventory_GetAll
    @SearchTerm NVARCHAR(200) = NULL,
    @IsAdmin BIT = 0,
    @AllowedStoreIds NVARCHAR(MAX) = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (CASE WHEN @PageNumber < 1 THEN 0 ELSE @PageNumber - 1 END) * (CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END);
    DECLARE @Take INT = CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END;
    DECLARE @AllowedStoreIdTable TABLE (StoreId INT);

    IF @IsAdmin = 0 AND @AllowedStoreIds IS NOT NULL AND LTRIM(RTRIM(@AllowedStoreIds)) <> ''
    BEGIN
        INSERT INTO @AllowedStoreIdTable (StoreId)
        SELECT TRY_CAST(value AS INT)
        FROM STRING_SPLIT(@AllowedStoreIds, ',')
        WHERE TRY_CAST(value AS INT) IS NOT NULL;
    END

    ;WITH FilteredTransfers AS (
        SELECT
            t.Id,
            t.TransferNumber AS DRNo,
            t.FromStoreId,
            fs.StoreName as FromStoreName,
            t.ToStoreId,
            ts.StoreName as ToStoreName,
            t.StockTypeId,
            stk.Name AS StockTypeName,
            ti.ItemId,
            i.Name AS ItemName,
            ISNULL((SELECT SUM(ti2.Quantity) FROM Inv.TransferInventoryItems ti2 WHERE ti2.TransferInventoryId = t.Id AND ti2.IsActive = 1), 0) AS Quantity,
            t.TransferDate,
            t.Status,
            t.Notes,
            t.IsActive,
            t.CreatedOn,
            ISNULL(e.FullName, NULLIF(LTRIM(RTRIM(ISNULL(e.FirstName, '') + ' ' + ISNULL(e.LastName, ''))), '')) AS TransferredByName
        FROM Inv.TransferInventory t
        LEFT JOIN Inv.PharmacyStores fs ON t.FromStoreId = fs.StoreId
        LEFT JOIN Inv.PharmacyStores ts ON t.ToStoreId = ts.StoreId
        LEFT JOIN Inv.StockTypes stk ON stk.Id = t.StockTypeId
        OUTER APPLY (
            SELECT TOP 1 ItemId
            FROM Inv.TransferInventoryItems
            WHERE TransferInventoryId = t.Id AND IsActive = 1
            ORDER BY Id
        ) ti
        LEFT JOIN Inv.Items i ON ti.ItemId = i.Id
        LEFT JOIN Users u ON u.UserID = t.CreatedById
        LEFT JOIN Employee e ON e.EmpID = u.EmpID
        WHERE t.IsActive = 1
            AND (
                @IsAdmin = 1
                OR t.FromStoreId IN (SELECT StoreId FROM @AllowedStoreIdTable)
                OR t.ToStoreId IN (SELECT StoreId FROM @AllowedStoreIdTable)
            )
            AND (
                @SearchTerm IS NULL OR @SearchTerm = ''
                OR t.TransferNumber LIKE '%' + @SearchTerm + '%'
                OR fs.StoreName LIKE '%' + @SearchTerm + '%'
                OR ts.StoreName LIKE '%' + @SearchTerm + '%'
                OR i.Name LIKE '%' + @SearchTerm + '%'
            )
    )
    SELECT *, COUNT(*) OVER() AS TotalCount
    FROM FilteredTransfers
    ORDER BY CreatedOn DESC
    OFFSET @Offset ROWS FETCH NEXT @Take ROWS ONLY;
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
        t.StockTypeId,
        stk.Name AS StockTypeName,
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
        t.ModifiedOn,
        ISNULL(e.FullName, NULLIF(LTRIM(RTRIM(ISNULL(e.FirstName, '') + ' ' + ISNULL(e.LastName, ''))), '')) AS TransferredByName
    FROM Inv.TransferInventory t
    LEFT JOIN Inv.PharmacyStores fs ON t.FromStoreId = fs.StoreId
    LEFT JOIN Inv.PharmacyStores ts ON t.ToStoreId = ts.StoreId
    LEFT JOIN Inv.StockTypes stk ON stk.Id = t.StockTypeId
    OUTER APPLY (
        SELECT TOP 1 ItemId
        FROM Inv.TransferInventoryItems
        WHERE TransferInventoryId = t.Id AND IsActive = 1
        ORDER BY Id
    ) ti
    LEFT JOIN Inv.Items i ON ti.ItemId = i.Id
    LEFT JOIN Users u ON u.UserID = t.CreatedById
    LEFT JOIN Employee e ON e.EmpID = u.EmpID
    WHERE t.Id = @Id;
END
GO

-- =============================================
-- 3. TransferInventory_Insert
-- =============================================
-- @BranchId must actually be used (Inv.TransferInventory.BranchId is NOT
-- NULL) - a prior version of this proc hardcoded NULL here, which the C#
-- layer's real @BranchId parameter silently overrode nothing for, breaking
-- every insert. Caught via a live round-trip test while wiring StockTypeId.
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

    DECLARE @TransferNumber NVARCHAR(50);
    DECLARE @NextId INT;
    SELECT @NextId = ISNULL(MAX(Id), 0) + 1 FROM Inv.TransferInventory;
    SET @TransferNumber = 'DR-' + RIGHT('00000' + CAST(@NextId AS VARCHAR(5)), 5);

    INSERT INTO Inv.TransferInventory (
        TransferNumber, FromStoreId, ToStoreId, BranchId, StockTypeId,
        TransferDate, Status, Notes,
        IsActive, CreatedById, CreatedOn
    )
    VALUES (
        @TransferNumber, @FromStoreId, @ToStoreId, @BranchId, @StockTypeId,
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
        StockTypeId = @StockTypeId,
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

