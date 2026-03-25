-- =============================================
-- SpaceAllocation Stored Procedures
-- =============================================

-- =============================================
-- Procedure: SpaceAllocation_GetAll
-- Description: Retrieve all space allocations with related entity names
-- =============================================
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

-- =============================================
-- Procedure: SpaceAllocation_GetById
-- Description: Retrieve a specific space allocation by ID
-- =============================================
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

-- =============================================
-- Procedure: SpaceAllocation_Insert
-- Description: Insert a new space allocation
-- =============================================
IF OBJECT_ID('dbo.SpaceAllocation_Insert', 'P') IS NOT NULL
    DROP PROCEDURE dbo.SpaceAllocation_Insert;
GO

CREATE PROCEDURE dbo.SpaceAllocation_Insert
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
    @CreatedById UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;

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

-- =============================================
-- Procedure: SpaceAllocation_Update
-- Description: Update an existing space allocation
-- =============================================
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
    @IsActive BIT,
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

-- =============================================
-- Procedure: SpaceAllocation_Delete
-- Description: Delete a space allocation
-- =============================================
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

PRINT 'SpaceAllocation stored procedures created successfully';
