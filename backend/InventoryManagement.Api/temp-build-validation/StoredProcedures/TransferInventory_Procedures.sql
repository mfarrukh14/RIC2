-- =============================================
-- Get all transfer inventory records
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'TransferInventory_GetAll')
    DROP PROCEDURE [dbo].[TransferInventory_GetAll]
GO

CREATE PROCEDURE [dbo].[TransferInventory_GetAll]
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        t.Id,
        t.DRNo,
        t.FromStoreId,
        fs.StoreName as FromStoreName,
        t.ToStoreId,
        ts.StoreName as ToStoreName,
        t.StockTypeId,
        st.StockTypeName,
        t.ItemId,
        t.ItemName,
        t.Quantity,
        t.TransferDate,
        t.Status,
        t.Notes,
        t.IsActive,
        t.CreatedOn
    FROM dbo.TransferInventory t
    LEFT JOIN dbo.Stores fs ON t.FromStoreId = fs.StoreId
    LEFT JOIN dbo.Stores ts ON t.ToStoreId = ts.StoreId
    LEFT JOIN dbo.StockTypes st ON t.StockTypeId = st.StockTypeId
    WHERE t.IsActive = 1
    ORDER BY t.CreatedOn DESC;
END
GO

-- =============================================
-- Get transfer inventory by ID
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'TransferInventory_GetById')
    DROP PROCEDURE [dbo].[TransferInventory_GetById]
GO

CREATE PROCEDURE [dbo].[TransferInventory_GetById]
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        t.Id,
        t.DRNo,
        t.FromStoreId,
        fs.StoreName as FromStoreName,
        t.ToStoreId,
        ts.StoreName as ToStoreName,
        t.StockTypeId,
        st.StockTypeName,
        t.ItemId,
        t.ItemName,
        t.Quantity,
        t.TransferDate,
        t.Status,
        t.Notes,
        t.IsActive,
        t.CreatedById,
        t.CreatedOn,
        t.ModifiedById,
        t.ModifiedOn
    FROM dbo.TransferInventory t
    LEFT JOIN dbo.Stores fs ON t.FromStoreId = fs.StoreId
    LEFT JOIN dbo.Stores ts ON t.ToStoreId = ts.StoreId
    LEFT JOIN dbo.StockTypes st ON t.StockTypeId = st.StockTypeId
    WHERE t.Id = @Id;
END
GO

-- =============================================
-- Insert transfer inventory
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'TransferInventory_Insert')
    DROP PROCEDURE [dbo].[TransferInventory_Insert]
GO

CREATE PROCEDURE [dbo].[TransferInventory_Insert]
    @FromStoreId INT,
    @ToStoreId INT,
    @StockTypeId INT,
    @ItemId INT,
    @ItemName NVARCHAR(MAX),
    @Quantity INT,
    @TransferDate DATETIME = NULL,
    @Status NVARCHAR(50) = 'Pending',
    @Notes NVARCHAR(MAX) = NULL,
    @CreatedById INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @DRNo NVARCHAR(50);
    
    -- Generate DR Number (DR-0401AAAE + incremental number)
    DECLARE @NextId INT;
    SELECT @NextId = ISNULL(MAX(Id), 0) + 1 FROM dbo.TransferInventory;
    SET @DRNo = 'DR-0401AAA' + RIGHT('00000' + CAST(@NextId AS VARCHAR(5)), 5);
    
    INSERT INTO dbo.TransferInventory (
        DRNo, FromStoreId, ToStoreId, StockTypeId, ItemId, ItemName,
        Quantity, TransferDate, Status, Notes,
        IsActive, CreatedById, CreatedOn
    )
    VALUES (
        @DRNo, @FromStoreId, @ToStoreId, @StockTypeId, @ItemId, @ItemName,
        @Quantity, ISNULL(@TransferDate, GETDATE()), @Status, @Notes,
        1, @CreatedById, GETDATE()
    );
    
    SELECT SCOPE_IDENTITY() as Id;
END
GO

-- =============================================
-- Update transfer inventory
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'TransferInventory_Update')
    DROP PROCEDURE [dbo].[TransferInventory_Update]
GO

CREATE PROCEDURE [dbo].[TransferInventory_Update]
    @Id INT,
    @FromStoreId INT,
    @ToStoreId INT,
    @StockTypeId INT,
    @ItemId INT,
    @ItemName NVARCHAR(MAX),
    @Quantity INT,
    @Status NVARCHAR(50) = NULL,
    @Notes NVARCHAR(MAX) = NULL,
    @ModifiedById INT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE dbo.TransferInventory
    SET 
        FromStoreId = @FromStoreId,
        ToStoreId = @ToStoreId,
        StockTypeId = @StockTypeId,
        ItemId = @ItemId,
        ItemName = @ItemName,
        Quantity = @Quantity,
        Status = ISNULL(@Status, Status),
        Notes = @Notes,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETDATE()
    WHERE Id = @Id;
    
    SELECT @@ROWCOUNT as AffectedRows;
END
GO

-- =============================================
-- Delete transfer inventory (soft delete)
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'TransferInventory_Delete')
    DROP PROCEDURE [dbo].[TransferInventory_Delete]
GO

CREATE PROCEDURE [dbo].[TransferInventory_Delete]
    @Id INT,
    @ModifiedById INT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE dbo.TransferInventory
    SET 
        IsActive = 0,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETDATE()
    WHERE Id = @Id;
    
    SELECT @@ROWCOUNT as AffectedRows;
END
GO

-- =============================================
-- Get lookup data for transfer inventory
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'TransferInventory_GetLookupData')
    DROP PROCEDURE [dbo].[TransferInventory_GetLookupData]
GO

CREATE PROCEDURE [dbo].[TransferInventory_GetLookupData]
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Stores
    SELECT StoreId as Id, StoreName as Name
    FROM dbo.Stores
    WHERE IsActive = 1
    ORDER BY StoreName;
    
    -- Stock Types
    SELECT StockTypeId as Id, StockTypeName as Name
    FROM dbo.StockTypes
    WHERE IsActive = 1
    ORDER BY StockTypeName;
    
    -- Items
    SELECT Id, Name
    FROM dbo.Items
    WHERE IsActive = 1
    ORDER BY Name;
END
GO
