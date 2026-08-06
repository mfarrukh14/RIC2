-- =============================================
-- Racks CRUD Stored Procedures
-- =============================================

-- =============================================
-- Get All Racks
-- =============================================
CREATE OR ALTER PROCEDURE Rack_GetAll
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        r.Id,
        r.Name,
        r.StoreId,
        NULL AS StoreName,
        r.Description,
        r.Location,
        r.NumberOfRows,
        r.NumberOfCols,
        r.NumberOfDrawrs,
        r.BranchId,
        r.IsActive,
        r.CreatedOn
    FROM Inv.Racks r
    ORDER BY r.CreatedOn DESC;
END
GO

-- =============================================
-- Get Rack By Id
-- =============================================
CREATE OR ALTER PROCEDURE Rack_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        r.Id,
        r.Name,
        r.StoreId,
        NULL AS StoreName,
        r.Description,
        r.Location,
        r.NumberOfRows,
        r.NumberOfCols,
        r.NumberOfDrawrs,
        r.BranchId,
        r.IsActive,
        r.CreatedOn
    FROM Inv.Racks r
    WHERE r.Id = @Id;
END
GO

-- =============================================
-- Insert Rack
-- =============================================
CREATE OR ALTER PROCEDURE Rack_Insert
    @Name NVARCHAR(MAX),
    @StoreId INT,
    @Description NVARCHAR(MAX) = NULL,
    @Location NVARCHAR(MAX) = NULL,
    @NumberOfRows INT,
    @NumberOfCols INT,
    @NumberOfDrawrs INT,
    @BranchId INT,
    @CreatedById INT,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO Inv.Racks (
        Name,
        StoreId,
        Description,
        Location,
        NumberOfRows,
        NumberOfCols,
        NumberOfDrawrs,
        BranchId,
        IsActive,
        CreatedById,
        CreatedOn
    )
    VALUES (
        @Name,
        @StoreId,
        @Description,
        @Location,
        @NumberOfRows,
        @NumberOfCols,
        @NumberOfDrawrs,
        @BranchId,
        @IsActive,
        @CreatedById,
        GETDATE()
    );
    
    SELECT SCOPE_IDENTITY() AS Id;
END
GO

-- =============================================
-- Update Rack
-- =============================================
CREATE OR ALTER PROCEDURE Rack_Update
    @Id INT,
    @Name NVARCHAR(MAX),
    @StoreId INT,
    @Description NVARCHAR(MAX) = NULL,
    @Location NVARCHAR(MAX) = NULL,
    @NumberOfRows INT,
    @NumberOfCols INT,
    @NumberOfDrawrs INT,
    @ModifiedById INT,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE Inv.Racks
    SET 
        Name = @Name,
        StoreId = @StoreId,
        Description = @Description,
        Location = @Location,
        NumberOfRows = @NumberOfRows,
        NumberOfCols = @NumberOfCols,
        NumberOfDrawrs = @NumberOfDrawrs,
        IsActive = @IsActive,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETDATE()
    WHERE Id = @Id;
    
    SELECT @Id AS Id;
END
GO

-- =============================================
-- Delete Rack (permanent)
-- =============================================
CREATE OR ALTER PROCEDURE Rack_Delete
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM Inv.Racks
    WHERE Id = @Id;
END
GO

PRINT 'Rack CRUD stored procedures created successfully';
