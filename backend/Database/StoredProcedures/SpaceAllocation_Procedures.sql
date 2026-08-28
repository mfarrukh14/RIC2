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
        sa.RackDrawrId AS RackDrawerId,
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
    FROM Inv.SpaceAllocations sa
    LEFT JOIN Inv.Stores s ON sa.StoreId = s.StoreId
    LEFT JOIN Inv.Items i ON sa.ItemId = i.Id
    LEFT JOIN Inv.Racks r ON sa.RackId = r.Id
    LEFT JOIN Inv.RackRows rr ON sa.RackRowId = rr.Id
    LEFT JOIN Inv.RackColumns rc ON sa.RackColumnId = rc.Id
    LEFT JOIN Inv.RackDrawrs rd ON sa.RackDrawrId = rd.Id
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
    @Id INT
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
        sa.RackDrawrId AS RackDrawerId,
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
    FROM Inv.SpaceAllocations sa
    LEFT JOIN Inv.Stores s ON sa.StoreId = s.StoreId
    LEFT JOIN Inv.Items i ON sa.ItemId = i.Id
    LEFT JOIN Inv.Racks r ON sa.RackId = r.Id
    LEFT JOIN Inv.RackRows rr ON sa.RackRowId = rr.Id
    LEFT JOIN Inv.RackColumns rc ON sa.RackColumnId = rc.Id
    LEFT JOIN Inv.RackDrawrs rd ON sa.RackDrawrId = rd.Id
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
    @StoreId INT,
    @ItemId INT,
    @FeeId INT = NULL,
    @RackId INT,
    @RackRowId INT = NULL,
    @RackColumnId INT = NULL,
    @RackDrawerId INT = NULL,
    @MedicineId INT = NULL,
    @IsActive BIT = 1,
    @CreatedById INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Inv.SpaceAllocations (
        StoreId,
        ItemId,
        FeeId,
        RackId,
        RackRowId,
        RackColumnId,
        RackDrawrId,
        MedicineId,
        IsActive,
        CreatedById,
        CreatedOn
    )
    VALUES (
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

    SELECT SCOPE_IDENTITY() AS Id;
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
    @Id INT,
    @StoreId INT,
    @ItemId INT,
    @FeeId INT = NULL,
    @RackId INT,
    @RackRowId INT = NULL,
    @RackColumnId INT = NULL,
    @RackDrawerId INT = NULL,
    @MedicineId INT = NULL,
    @IsActive BIT,
    @ModifiedById INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Inv.SpaceAllocations
    SET 
        StoreId = @StoreId,
        ItemId = @ItemId,
        FeeId = @FeeId,
        RackId = @RackId,
        RackRowId = @RackRowId,
        RackColumnId = @RackColumnId,
        RackDrawrId = @RackDrawerId,
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
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM Inv.SpaceAllocations WHERE Id = @Id;
END
GO

PRINT 'SpaceAllocation stored procedures created successfully';
