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
    FROM Inv.RackRows rr
    LEFT JOIN Inv.PharmacyStores s ON rr.StoreId = s.StoreId
    LEFT JOIN Inv.Racks r ON rr.RackId = r.Id
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
    @Id INT
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
    FROM Inv.RackRows rr
    LEFT JOIN Inv.PharmacyStores s ON rr.StoreId = s.StoreId
    LEFT JOIN Inv.Racks r ON rr.RackId = r.Id
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
    FROM Inv.RackRows rr
    LEFT JOIN Inv.PharmacyStores s ON rr.StoreId = s.StoreId
    LEFT JOIN Inv.Racks r ON rr.RackId = r.Id
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
    @Name NVARCHAR(255),
    @Description NVARCHAR(MAX) = NULL,
    @StoreId INT,
    @RackId INT,
    @BranchId INT = NULL,
    @IsActive BIT = 1,
    @CreatedById INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 FROM Inv.RackRows
        WHERE StoreId = @StoreId AND RackId = @RackId AND LTRIM(RTRIM(Name)) = LTRIM(RTRIM(@Name))
    )
    BEGIN
        DECLARE @RackName VARCHAR(255) = (SELECT CAST(Name AS VARCHAR(255)) FROM Inv.Racks WHERE Id = @RackId);
        DECLARE @StoreName VARCHAR(255) = (SELECT CAST(StoreName AS VARCHAR(255)) FROM Inv.PharmacyStores WHERE StoreId = @StoreId);
        RAISERROR('This rack row already exists in rack ''%s'' and store ''%s''.', 16, 1, @RackName, @StoreName);
        RETURN;
    END

    INSERT INTO Inv.RackRows (
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
        @Name,
        @Description,
        @StoreId,
        @RackId,
        @BranchId,
        @IsActive,
        @CreatedById,
        GETDATE()
    );

    SELECT SCOPE_IDENTITY() AS Id;
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
    @Id INT,
    @Name NVARCHAR(255),
    @Description NVARCHAR(MAX) = NULL,
    @StoreId INT,
    @RackId INT,
    @BranchId INT = NULL,
    @IsActive BIT,
    @ModifiedById INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 FROM Inv.RackRows
        WHERE StoreId = @StoreId AND RackId = @RackId AND LTRIM(RTRIM(Name)) = LTRIM(RTRIM(@Name)) AND Id <> @Id
    )
    BEGIN
        DECLARE @RackName VARCHAR(255) = (SELECT CAST(Name AS VARCHAR(255)) FROM Inv.Racks WHERE Id = @RackId);
        DECLARE @StoreName VARCHAR(255) = (SELECT CAST(StoreName AS VARCHAR(255)) FROM Inv.PharmacyStores WHERE StoreId = @StoreId);
        RAISERROR('This rack row already exists in rack ''%s'' and store ''%s''.', 16, 1, @RackName, @StoreName);
        RETURN;
    END

    UPDATE Inv.RackRows
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
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if the rack row is being used by any rack drawers
    IF EXISTS (SELECT 1 FROM Inv.RackDrawrs WHERE RackRowId = @Id)
    BEGIN
        RAISERROR('Cannot delete rack row. It is being used by one or more rack drawers.', 16, 1);
        RETURN;
    END

    DELETE FROM Inv.RackRows WHERE Id = @Id;
END
GO

PRINT 'RackRow stored procedures created successfully';
