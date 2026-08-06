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
    FROM Inv.RackDrawrs rd
    LEFT JOIN Inv.PharmacyStores s ON rd.StoreId = s.StoreId
    LEFT JOIN Inv.Racks r ON rd.RackId = r.Id
    LEFT JOIN Inv.RackRows rr ON rd.RackRowId = rr.Id
    LEFT JOIN Inv.RackColumns rc ON rd.RackColumnId = rc.Id
    ORDER BY rd.Name;
END
GO

-- Get Rack Drawer By ID
CREATE OR ALTER PROCEDURE RackDrawer_GetById
    @Id INT
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
    FROM Inv.RackDrawrs rd
    LEFT JOIN Inv.PharmacyStores s ON rd.StoreId = s.StoreId
    LEFT JOIN Inv.Racks r ON rd.RackId = r.Id
    LEFT JOIN Inv.RackRows rr ON rd.RackRowId = rr.Id
    LEFT JOIN Inv.RackColumns rc ON rd.RackColumnId = rc.Id
    WHERE rd.Id = @Id;
END
GO

-- Insert Rack Drawer
CREATE OR ALTER PROCEDURE RackDrawer_Insert
    @Name NVARCHAR(MAX),
    @Description NVARCHAR(MAX) = NULL,
    @StoreId INT,
    @RackId INT,
    @RackRowId INT = NULL,
    @RackColumnId INT = NULL,
    @BranchId INT = NULL,
    @IsActive BIT
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO Inv.RackDrawrs (
        Name, Description, StoreId, RackId, RackRowId, RackColumnId,
        BranchId, IsActive, CreatedOn
    )
    VALUES (
        @Name, @Description, @StoreId, @RackId, @RackRowId, @RackColumnId,
        @BranchId, @IsActive, GETUTCDATE()
    );

    SELECT SCOPE_IDENTITY() AS Id;
END
GO

-- Update Rack Drawer
CREATE OR ALTER PROCEDURE RackDrawer_Update
    @Id INT,
    @Name NVARCHAR(MAX),
    @Description NVARCHAR(MAX) = NULL,
    @StoreId INT,
    @RackId INT,
    @RackRowId INT = NULL,
    @RackColumnId INT = NULL,
    @BranchId INT = NULL,
    @IsActive BIT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE Inv.RackDrawrs
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
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DELETE FROM Inv.RackDrawrs
    WHERE Id = @Id;
END
GO
