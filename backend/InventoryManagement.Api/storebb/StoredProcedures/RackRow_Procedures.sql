-- =============================================
-- RackRow Stored Procedures
-- =============================================

-- =============================================
-- Procedure: RackRow_GetAll
-- Description: Retrieve all rack rows with store and rack names
-- =============================================
IF OBJECT_ID('dbo.RackRow_GetAll', 'P') IS NOT NULL
    DROP PROCEDURE dbo.RackRow_GetAll;
GO

CREATE PROCEDURE dbo.RackRow_GetAll
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        rr.Id,
        rr.Name,
        rr.Description,
        rr.StoreId,
        rr.RackId,
        rr.BranchId,
        rr.IsActive,
        rr.CreatedById,
        rr.CreatedOn,
        rr.ModifiedById,
        rr.ModifiedOn,
        s.StoreName AS StoreName,
        r.Name AS RackName
    FROM dbo.RackRows rr
    LEFT JOIN dbo.Stores s ON rr.StoreId = s.StoreId
    LEFT JOIN dbo.Racks r ON rr.RackId = r.Id
    ORDER BY rr.Name;
END
GO

-- =============================================
-- Procedure: RackRow_GetById
-- Description: Retrieve a specific rack row by ID
-- =============================================
IF OBJECT_ID('dbo.RackRow_GetById', 'P') IS NOT NULL
    DROP PROCEDURE dbo.RackRow_GetById;
GO

CREATE PROCEDURE dbo.RackRow_GetById
    @Id UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        rr.Id,
        rr.Name,
        rr.Description,
        rr.StoreId,
        rr.RackId,
        rr.BranchId,
        rr.IsActive,
        rr.CreatedById,
        rr.CreatedOn,
        rr.ModifiedById,
        rr.ModifiedOn,
        s.StoreName AS StoreName,
        r.Name AS RackName
    FROM dbo.RackRows rr
    LEFT JOIN dbo.Stores s ON rr.StoreId = s.StoreId
    LEFT JOIN dbo.Racks r ON rr.RackId = r.Id
    WHERE rr.Id = @Id;
END
GO

-- =============================================
-- Procedure: RackRow_GetByRackId
-- Description: Retrieve all rack rows for a specific rack
-- =============================================
IF OBJECT_ID('dbo.RackRow_GetByRackId', 'P') IS NOT NULL
    DROP PROCEDURE dbo.RackRow_GetByRackId;
GO

CREATE PROCEDURE dbo.RackRow_GetByRackId
    @RackId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        rr.Id,
        rr.Name,
        rr.Description,
        rr.StoreId,
        rr.RackId,
        rr.BranchId,
        rr.IsActive,
        rr.CreatedById,
        rr.CreatedOn,
        rr.ModifiedById,
        rr.ModifiedOn,
        s.StoreName AS StoreName,
        r.Name AS RackName
    FROM dbo.RackRows rr
    LEFT JOIN dbo.Stores s ON rr.StoreId = s.StoreId
    LEFT JOIN dbo.Racks r ON rr.RackId = r.Id
    WHERE rr.RackId = @RackId
    ORDER BY rr.Name;
END
GO

-- =============================================
-- Procedure: RackRow_Insert
-- Description: Insert a new rack row
-- =============================================
IF OBJECT_ID('dbo.RackRow_Insert', 'P') IS NOT NULL
    DROP PROCEDURE dbo.RackRow_Insert;
GO

CREATE PROCEDURE dbo.RackRow_Insert
    @Id UNIQUEIDENTIFIER,
    @Name NVARCHAR(255),
    @Description NVARCHAR(MAX) = NULL,
    @StoreId INT,
    @RackId INT,
    @BranchId UNIQUEIDENTIFIER = NULL,
    @IsActive BIT = 1,
    @CreatedById UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.RackRows (
        Id,
        Name,
        Description,
        StoreId,
        RackId,
        BranchId,
        IsActive,
        CreatedById,
        CreatedOn
    )
    VALUES (
        @Id,
        @Name,
        @Description,
        @StoreId,
        @RackId,
        @BranchId,
        @IsActive,
        @CreatedById,
        GETDATE()
    );
END
GO

-- =============================================
-- Procedure: RackRow_Update
-- Description: Update an existing rack row
-- =============================================
IF OBJECT_ID('dbo.RackRow_Update', 'P') IS NOT NULL
    DROP PROCEDURE dbo.RackRow_Update;
GO

CREATE PROCEDURE dbo.RackRow_Update
    @Id UNIQUEIDENTIFIER,
    @Name NVARCHAR(255),
    @Description NVARCHAR(MAX) = NULL,
    @StoreId INT,
    @RackId INT,
    @BranchId UNIQUEIDENTIFIER = NULL,
    @IsActive BIT,
    @ModifiedById UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.RackRows
    SET 
        Name = @Name,
        Description = @Description,
        StoreId = @StoreId,
        RackId = @RackId,
        BranchId = @BranchId,
        IsActive = @IsActive,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETDATE()
    WHERE Id = @Id;
END
GO

-- =============================================
-- Procedure: RackRow_Delete
-- Description: Delete a rack row (with FK check for rack drawers)
-- =============================================
IF OBJECT_ID('dbo.RackRow_Delete', 'P') IS NOT NULL
    DROP PROCEDURE dbo.RackRow_Delete;
GO

CREATE PROCEDURE dbo.RackRow_Delete
    @Id UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if the rack row is being used by any rack drawers
    IF EXISTS (SELECT 1 FROM dbo.RackDrawers WHERE RackRowId = @Id)
    BEGIN
        RAISERROR('Cannot delete rack row. It is being used by one or more rack drawers.', 16, 1);
        RETURN;
    END

    DELETE FROM dbo.RackRows WHERE Id = @Id;
END
GO

PRINT 'RackRow stored procedures created successfully';
