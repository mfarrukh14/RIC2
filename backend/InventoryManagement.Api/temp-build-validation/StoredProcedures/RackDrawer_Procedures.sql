-- Stored Procedures for RackDrawers table

-- Get All Rack Drawers
CREATE OR ALTER PROCEDURE RackDrawer_GetAll
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        rd.Id,
        rd.Name,
        rd.Description,
        rd.StoreId,
        rd.RackId,
        rd.RackRowId,
        rd.RackColumnId,
        rd.BranchId,
        rd.IsActive,
        rd.CreatedById,
        rd.CreatedOn,
        rd.ModifiedById,
        rd.ModifiedOn,
        s.StoreName,
        r.Name AS RackName,
        rr.Name AS RowName,
        rc.Name AS ColumnName
    FROM dbo.RackDrawers rd
    LEFT JOIN dbo.Stores s ON rd.StoreId = s.StoreId
    LEFT JOIN dbo.Racks r ON rd.RackId = r.Id
    LEFT JOIN dbo.RackRows rr ON rd.RackRowId = rr.Id
    LEFT JOIN dbo.RackColumns rc ON rd.RackColumnId = rc.Id
    ORDER BY rd.Name;
END
GO

-- Get Rack Drawer By ID
CREATE OR ALTER PROCEDURE RackDrawer_GetById
    @Id UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        rd.Id,
        rd.Name,
        rd.Description,
        rd.StoreId,
        rd.RackId,
        rd.RackRowId,
        rd.RackColumnId,
        rd.BranchId,
        rd.IsActive,
        rd.CreatedById,
        rd.CreatedOn,
        rd.ModifiedById,
        rd.ModifiedOn,
        s.StoreName,
        r.Name AS RackName,
        rr.Name AS RowName,
        rc.Name AS ColumnName
    FROM dbo.RackDrawers rd
    LEFT JOIN dbo.Stores s ON rd.StoreId = s.StoreId
    LEFT JOIN dbo.Racks r ON rd.RackId = r.Id
    LEFT JOIN dbo.RackRows rr ON rd.RackRowId = rr.Id
    LEFT JOIN dbo.RackColumns rc ON rd.RackColumnId = rc.Id
    WHERE rd.Id = @Id;
END
GO

-- Insert Rack Drawer
CREATE OR ALTER PROCEDURE RackDrawer_Insert
    @Id UNIQUEIDENTIFIER,
    @Name NVARCHAR(MAX),
    @Description NVARCHAR(MAX) = NULL,
    @StoreId INT,
    @RackId INT,
    @RackRowId UNIQUEIDENTIFIER = NULL,
    @RackColumnId UNIQUEIDENTIFIER = NULL,
    @BranchId UNIQUEIDENTIFIER = NULL,
    @IsActive BIT
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO dbo.RackDrawers (
        Id, Name, Description, StoreId, RackId, RackRowId, RackColumnId,
        BranchId, IsActive, CreatedOn
    )
    VALUES (
        @Id, @Name, @Description, @StoreId, @RackId, @RackRowId, @RackColumnId,
        @BranchId, @IsActive, GETUTCDATE()
    );
END
GO

-- Update Rack Drawer
CREATE OR ALTER PROCEDURE RackDrawer_Update
    @Id UNIQUEIDENTIFIER,
    @Name NVARCHAR(MAX),
    @Description NVARCHAR(MAX) = NULL,
    @StoreId INT,
    @RackId INT,
    @RackRowId UNIQUEIDENTIFIER = NULL,
    @RackColumnId UNIQUEIDENTIFIER = NULL,
    @BranchId UNIQUEIDENTIFIER = NULL,
    @IsActive BIT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE dbo.RackDrawers
    SET 
        Name = @Name,
        Description = @Description,
        StoreId = @StoreId,
        RackId = @RackId,
        RackRowId = @RackRowId,
        RackColumnId = @RackColumnId,
        BranchId = @BranchId,
        IsActive = @IsActive,
        ModifiedOn = GETUTCDATE()
    WHERE Id = @Id;
END
GO

-- Delete Rack Drawer
CREATE OR ALTER PROCEDURE RackDrawer_Delete
    @Id UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    
    DELETE FROM dbo.RackDrawers
    WHERE Id = @Id;
END
GO
