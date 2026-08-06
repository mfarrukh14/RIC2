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
    FROM Inv.RackColumns rc
    LEFT JOIN Inv.PharmacyStores s ON rc.StoreId = s.StoreId
    LEFT JOIN Inv.Racks r ON rc.RackId = r.Id
    ORDER BY rc.Name;
END
GO

-- Get Rack Column By ID
CREATE OR ALTER PROCEDURE RackColumn_GetById
    @Id INT
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
    FROM Inv.RackColumns rc
    LEFT JOIN Inv.PharmacyStores s ON rc.StoreId = s.StoreId
    LEFT JOIN Inv.Racks r ON rc.RackId = r.Id
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
    FROM Inv.RackColumns rc
    LEFT JOIN Inv.PharmacyStores s ON rc.StoreId = s.StoreId
    LEFT JOIN Inv.Racks r ON rc.RackId = r.Id
    WHERE rc.RackId = @RackId
    ORDER BY rc.Name;
END
GO

-- Insert Rack Column
CREATE OR ALTER PROCEDURE RackColumn_Insert
    @Name NVARCHAR(MAX),
    @Description NVARCHAR(MAX) = NULL,
    @StoreId INT,
    @RackId INT,
    @BranchId INT = NULL,
    @IsActive BIT
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO Inv.RackColumns (
        Name, Description, StoreId, RackId, BranchId, IsActive, CreatedOn
    )
    VALUES (
        @Name, @Description, @StoreId, @RackId, @BranchId, @IsActive, GETUTCDATE()
    );

    SELECT SCOPE_IDENTITY() AS Id;
END
GO

-- Update Rack Column
CREATE OR ALTER PROCEDURE RackColumn_Update
    @Id INT,
    @Name NVARCHAR(MAX),
    @Description NVARCHAR(MAX) = NULL,
    @StoreId INT,
    @RackId INT,
    @BranchId INT = NULL,
    @IsActive BIT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE Inv.RackColumns
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
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check if the rack column is being used by any rack drawers
    IF EXISTS (SELECT 1 FROM Inv.RackDrawrs WHERE RackColumnId = @Id)
    BEGIN
        RAISERROR('Cannot delete rack column. It is being used by one or more rack drawers.', 16, 1);
        RETURN;
    END
    
    DELETE FROM Inv.RackColumns
    WHERE Id = @Id;
END
GO
