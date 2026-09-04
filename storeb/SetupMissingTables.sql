-- =============================================
-- Setup Missing Tables and Stored Procedures
-- Run this script to fix the "Invalid object name" errors
-- =============================================

USE InventoryManagementDB_SP;
GO

-- =============================================
-- 1. Create SpaceAllocations Table
-- =============================================
PRINT 'Creating SpaceAllocations table...';
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SpaceAllocations')
BEGIN
    CREATE TABLE dbo.SpaceAllocations (
        Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        StoreId INT NOT NULL,
        ItemId UNIQUEIDENTIFIER NOT NULL,
        FeeId UNIQUEIDENTIFIER,
        RackId INT NOT NULL,
        RackRowId UNIQUEIDENTIFIER,
        RackColumnId UNIQUEIDENTIFIER,
        RackDrawerId UNIQUEIDENTIFIER,
        MedicineId UNIQUEIDENTIFIER,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById UNIQUEIDENTIFIER,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById UNIQUEIDENTIFIER,
        ModifiedOn DATETIME,
        CONSTRAINT FK_SpaceAllocations_Stores FOREIGN KEY (StoreId) REFERENCES dbo.Stores(StoreId),
        CONSTRAINT FK_SpaceAllocations_Racks FOREIGN KEY (RackId) REFERENCES dbo.Racks(Id),
        CONSTRAINT FK_SpaceAllocations_RackRows FOREIGN KEY (RackRowId) REFERENCES dbo.RackRows(Id),
        CONSTRAINT FK_SpaceAllocations_RackColumns FOREIGN KEY (RackColumnId) REFERENCES dbo.RackColumns(Id),
        CONSTRAINT FK_SpaceAllocations_RackDrawers FOREIGN KEY (RackDrawerId) REFERENCES dbo.RackDrawers(Id)
    );
    
    PRINT '✓ SpaceAllocations table created successfully';
END
ELSE
BEGIN
    PRINT '✓ SpaceAllocations table already exists';
END
GO

-- =============================================
-- 2. Create SpaceAllocation Stored Procedures
-- =============================================
PRINT 'Creating SpaceAllocation stored procedures...';
GO

-- SpaceAllocation_GetAll
IF OBJECT_ID('dbo.SpaceAllocation_GetAll', 'P') IS NOT NULL
    DROP PROCEDURE dbo.SpaceAllocation_GetAll;
GO

CREATE PROCEDURE dbo.SpaceAllocation_GetAll
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        sa.Id,
        sa.StoreId,
        sa.ItemId,
        sa.FeeId,
        sa.RackId,
        sa.RackRowId,
        sa.RackColumnId,
        sa.RackDrawerId,
        sa.MedicineId,
        sa.IsActive,
        sa.CreatedById,
        sa.CreatedOn,
        sa.ModifiedById,
        sa.ModifiedOn,
        s.StoreName AS StoreName,
        i.Name AS ItemName,
        r.Name AS RackName,
        rr.Name AS RowName,
        rc.Name AS ColumnName,
        rd.Name AS DrawerName
    FROM dbo.SpaceAllocations sa
    LEFT JOIN dbo.Stores s ON sa.StoreId = s.StoreId
    LEFT JOIN dbo.Items i ON CAST(SUBSTRING(CAST(sa.ItemId AS VARCHAR(36)), 1, 8) AS INT) = i.Id
    LEFT JOIN dbo.Racks r ON sa.RackId = r.Id
    LEFT JOIN dbo.RackRows rr ON sa.RackRowId = rr.Id
    LEFT JOIN dbo.RackColumns rc ON sa.RackColumnId = rc.Id
    LEFT JOIN dbo.RackDrawers rd ON sa.RackDrawerId = rd.Id
    ORDER BY sa.CreatedOn DESC;
END
GO

PRINT '✓ SpaceAllocation_GetAll created';
GO

-- SpaceAllocation_GetById
IF OBJECT_ID('dbo.SpaceAllocation_GetById', 'P') IS NOT NULL
    DROP PROCEDURE dbo.SpaceAllocation_GetById;
GO

CREATE PROCEDURE dbo.SpaceAllocation_GetById
    @Id UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        sa.Id,
        sa.StoreId,
        sa.ItemId,
        sa.FeeId,
        sa.RackId,
        sa.RackRowId,
        sa.RackColumnId,
        sa.RackDrawerId,
        sa.MedicineId,
        sa.IsActive,
        sa.CreatedById,
        sa.CreatedOn,
        sa.ModifiedById,
        sa.ModifiedOn,
        s.StoreName AS StoreName,
        i.Name AS ItemName,
        r.Name AS RackName,
        rr.Name AS RowName,
        rc.Name AS ColumnName,
        rd.Name AS DrawerName
    FROM dbo.SpaceAllocations sa
    LEFT JOIN dbo.Stores s ON sa.StoreId = s.StoreId
    LEFT JOIN dbo.Items i ON CAST(SUBSTRING(CAST(sa.ItemId AS VARCHAR(36)), 1, 8) AS INT) = i.Id
    LEFT JOIN dbo.Racks r ON sa.RackId = r.Id
    LEFT JOIN dbo.RackRows rr ON sa.RackRowId = rr.Id
    LEFT JOIN dbo.RackColumns rc ON sa.RackColumnId = rc.Id
    LEFT JOIN dbo.RackDrawers rd ON sa.RackDrawerId = rd.Id
    WHERE sa.Id = @Id;
END
GO

PRINT '✓ SpaceAllocation_GetById created';
GO

-- SpaceAllocation_Insert
IF OBJECT_ID('dbo.SpaceAllocation_Insert', 'P') IS NOT NULL
    DROP PROCEDURE dbo.SpaceAllocation_Insert;
GO

CREATE PROCEDURE dbo.SpaceAllocation_Insert
    @Id UNIQUEIDENTIFIER OUTPUT,
    @StoreId INT,
    @ItemId UNIQUEIDENTIFIER,
    @FeeId UNIQUEIDENTIFIER = NULL,
    @RackId INT,
    @RackRowId UNIQUEIDENTIFIER = NULL,
    @RackColumnId UNIQUEIDENTIFIER = NULL,
    @RackDrawerId UNIQUEIDENTIFIER = NULL,
    @MedicineId UNIQUEIDENTIFIER = NULL,
    @IsActive BIT = 1,
    @CreatedById UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SET @Id = NEWID();

    INSERT INTO dbo.SpaceAllocations (
        Id,
        StoreId,
        ItemId,
        FeeId,
        RackId,
        RackRowId,
        RackColumnId,
        RackDrawerId,
        MedicineId,
        IsActive,
        CreatedById,
        CreatedOn
    )
    VALUES (
        @Id,
        @StoreId,
        @ItemId,
        @FeeId,
        @RackId,
        @RackRowId,
        @RackColumnId,
        @RackDrawerId,
        @MedicineId,
        @IsActive,
        @CreatedById,
        GETDATE()
    );
END
GO

PRINT '✓ SpaceAllocation_Insert created';
GO

-- SpaceAllocation_Update
IF OBJECT_ID('dbo.SpaceAllocation_Update', 'P') IS NOT NULL
    DROP PROCEDURE dbo.SpaceAllocation_Update;
GO

CREATE PROCEDURE dbo.SpaceAllocation_Update
    @Id UNIQUEIDENTIFIER,
    @StoreId INT,
    @ItemId UNIQUEIDENTIFIER,
    @FeeId UNIQUEIDENTIFIER = NULL,
    @RackId INT,
    @RackRowId UNIQUEIDENTIFIER = NULL,
    @RackColumnId UNIQUEIDENTIFIER = NULL,
    @RackDrawerId UNIQUEIDENTIFIER = NULL,
    @MedicineId UNIQUEIDENTIFIER = NULL,
    @IsActive BIT = 1,
    @ModifiedById UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.SpaceAllocations
    SET 
        StoreId = @StoreId,
        ItemId = @ItemId,
        FeeId = @FeeId,
        RackId = @RackId,
        RackRowId = @RackRowId,
        RackColumnId = @RackColumnId,
        RackDrawerId = @RackDrawerId,
        MedicineId = @MedicineId,
        IsActive = @IsActive,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETDATE()
    WHERE Id = @Id;
END
GO

PRINT '✓ SpaceAllocation_Update created';
GO

-- SpaceAllocation_Delete
IF OBJECT_ID('dbo.SpaceAllocation_Delete', 'P') IS NOT NULL
    DROP PROCEDURE dbo.SpaceAllocation_Delete;
GO

CREATE PROCEDURE dbo.SpaceAllocation_Delete
    @Id UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM dbo.SpaceAllocations WHERE Id = @Id;
END
GO

PRINT '✓ SpaceAllocation_Delete created';
GO

-- =============================================
-- 3. Create StockWithExpiry Stored Procedure
-- =============================================
PRINT 'Creating StockWithExpiry stored procedure...';
GO

IF OBJECT_ID('dbo.StockWithExpiry_GetAll', 'P') IS NOT NULL
    DROP PROCEDURE dbo.StockWithExpiry_GetAll;
GO

CREATE PROCEDURE dbo.StockWithExpiry_GetAll
    @BranchId INT = NULL,
    @StoreId INT = NULL,
    @ItemType VARCHAR(50) = NULL,
    @ItemId INT = NULL,
    @CategoryId INT = NULL,
    @IsExpensiveItem BIT = NULL,
    @IsFridgeItem BIT = NULL,
    @MinimumPanicLevelOnly BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        id.Id,
        i.Id AS ItemId,
        i.Name AS ItemName,
        inv.StoreId,
        st.StoreName,
        CAST(id.Id AS NVARCHAR(50)) AS BatchNumber,
        id.ExpiryDate,
        id.TotalItems AS Quantity,
        ISNULL(sty.StockTypeName, 'Regular') AS StockType,
        
        -- Rack Location Information (from SpaceAllocations)
        sa.RackId,
        r.Name AS RackName,
        sa.RackRowId,
        rr.Name AS RowNumber,
        sa.RackColumnId,
        rc.Name AS ColumnNumber,
        sa.RackDrawerId,
        rd.Name AS DrawerNumber,
        
        -- MPL and Stock Status
        ISNULL(i.MinimumPanicLevel, 0) AS MPL,
        CASE 
            WHEN id.TotalItems <= ISNULL(i.MinimumPanicLevel, 0) THEN 1
            ELSE 0
        END AS IsBelowMPL,
        
        -- Item Details
        it.Name AS ItemType,
        CAST(0 AS BIT) AS IsExpensiveItem,
        i.IsFridgeItem,
        i.CategoryId,
        
        -- Total Items in Transition
        (SELECT ISNULL(SUM(id2.TotalItems), 0) 
         FROM InventoryDetails id2
         INNER JOIN Inventories inv2 ON id2.InventoryId = inv2.Id
         WHERE id2.ItemId = i.Id AND inv2.StoreId = inv.StoreId) AS TotalItemsInTransition,
        
        inv.ModifiedOn,
        inv.ModifiedById,
        inv.CreatedOn,
        inv.CreatedById
        
    FROM dbo.InventoryDetails id
    INNER JOIN dbo.Inventories inv ON id.InventoryId = inv.Id
    INNER JOIN dbo.Items i ON id.ItemId = i.Id
    INNER JOIN dbo.Stores st ON inv.StoreId = st.StoreId
    LEFT JOIN dbo.ItemTypes it ON i.ItemTypeId = it.Id
    LEFT JOIN dbo.StockTypes sty ON inv.StockTypeId = sty.StockTypeId
    LEFT JOIN dbo.SpaceAllocations sa ON CAST(SUBSTRING(CAST(sa.ItemId AS VARCHAR(36)), 1, 8) AS INT) = i.Id
    LEFT JOIN dbo.Racks r ON sa.RackId = r.Id
    LEFT JOIN dbo.RackRows rr ON sa.RackRowId = rr.Id
    LEFT JOIN dbo.RackColumns rc ON sa.RackColumnId = rc.Id
    LEFT JOIN dbo.RackDrawers rd ON sa.RackDrawerId = rd.Id
    
    WHERE 
        (@BranchId IS NULL OR inv.BranchId = @BranchId)
        AND (@StoreId IS NULL OR inv.StoreId = @StoreId)
        AND (@ItemType IS NULL OR it.Name = @ItemType)
        AND (@ItemId IS NULL OR i.Id = @ItemId)
        AND (@CategoryId IS NULL OR i.CategoryId = @CategoryId)
        AND (@IsFridgeItem IS NULL OR i.IsFridgeItem = @IsFridgeItem)
        AND (@MinimumPanicLevelOnly = 0 OR id.TotalItems <= ISNULL(i.MinimumPanicLevel, 0))
        AND id.TotalItems > 0
        AND inv.IsActive = 1
        
    ORDER BY 
        CASE WHEN id.TotalItems <= ISNULL(i.MinimumPanicLevel, 0) THEN 0 ELSE 1 END,
        id.ExpiryDate ASC,
        i.Name;
END
GO

PRINT '✓ StockWithExpiry_GetAll created';
GO

PRINT '';
PRINT '=============================================';
PRINT 'All tables and stored procedures created successfully!';
PRINT 'You can now restart your API application.';
PRINT '=============================================';
