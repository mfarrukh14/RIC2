-- Stored Procedures for RackColumns table

-- Get All Rack Columns
CREATE OR ALTER PROCEDURE RackColumn_GetAll
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        rc.Id,
        rc.Name,
        rc.Description,
        rc.StoreId,
        rc.RackId,
        rc.BranchId,
        rc.IsActive,
        rc.CreatedById,
        rc.CreatedOn,
        rc.ModifiedById,
        rc.ModifiedOn,
        s.StoreName,
        r.Name AS RackName
    FROM dbo.RackColumns rc
    LEFT JOIN dbo.Stores s ON rc.StoreId = s.StoreId
    LEFT JOIN dbo.Racks r ON rc.RackId = r.Id
    ORDER BY rc.Name;
END
GO

-- Get Rack Column By ID
CREATE OR ALTER PROCEDURE RackColumn_GetById
    @Id UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        rc.Id,
        rc.Name,
        rc.Description,
        rc.StoreId,
        rc.RackId,
        rc.BranchId,
        rc.IsActive,
        rc.CreatedById,
        rc.CreatedOn,
        rc.ModifiedById,
        rc.ModifiedOn,
        s.StoreName,
        r.Name AS RackName
    FROM dbo.RackColumns rc
    LEFT JOIN dbo.Stores s ON rc.StoreId = s.StoreId
    LEFT JOIN dbo.Racks r ON rc.RackId = r.Id
    WHERE rc.Id = @Id;
END
GO

-- Get Rack Columns By RackId
CREATE OR ALTER PROCEDURE RackColumn_GetByRackId
    @RackId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        rc.Id,
        rc.Name,
        rc.Description,
        rc.StoreId,
        rc.RackId,
        rc.BranchId,
        rc.IsActive,
        rc.CreatedById,
        rc.CreatedOn,
        rc.ModifiedById,
        rc.ModifiedOn,
        s.StoreName,
        r.Name AS RackName
    FROM dbo.RackColumns rc
    LEFT JOIN dbo.Stores s ON rc.StoreId = s.StoreId
    LEFT JOIN dbo.Racks r ON rc.RackId = r.Id
    WHERE rc.RackId = @RackId
    ORDER BY rc.Name;
END
GO

-- Insert Rack Column
CREATE OR ALTER PROCEDURE RackColumn_Insert
    @Id UNIQUEIDENTIFIER,
    @Name NVARCHAR(MAX),
    @Description NVARCHAR(MAX) = NULL,
    @StoreId INT,
    @RackId INT,
    @BranchId UNIQUEIDENTIFIER = NULL,
    @IsActive BIT
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO dbo.RackColumns (
        Id, Name, Description, StoreId, RackId, BranchId, IsActive, CreatedOn
    )
    VALUES (
        @Id, @Name, @Description, @StoreId, @RackId, @BranchId, @IsActive, GETUTCDATE()
    );
END
GO

-- Update Rack Column
CREATE OR ALTER PROCEDURE RackColumn_Update
    @Id UNIQUEIDENTIFIER,
    @Name NVARCHAR(MAX),
    @Description NVARCHAR(MAX) = NULL,
    @StoreId INT,
    @RackId INT,
    @BranchId UNIQUEIDENTIFIER = NULL,
    @IsActive BIT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE dbo.RackColumns
    SET 
        Name = @Name,
        Description = @Description,
        StoreId = @StoreId,
        RackId = @RackId,
        BranchId = @BranchId,
        IsActive = @IsActive,
        ModifiedOn = GETUTCDATE()
    WHERE Id = @Id;
END
GO

-- Delete Rack Column
CREATE OR ALTER PROCEDURE RackColumn_Delete
    @Id UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check if the rack column is being used by any rack drawers
    IF EXISTS (SELECT 1 FROM dbo.RackDrawers WHERE RackColumnId = @Id)
    BEGIN
        RAISERROR('Cannot delete rack column. It is being used by one or more rack drawers.', 16, 1);
        RETURN;
    END
    
    DELETE FROM dbo.RackColumns
    WHERE Id = @Id;
END
GO
