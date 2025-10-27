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
        r.NumberOfDraws,
        r.BranchId,
        r.IsActive,
        r.CreatedOn
    FROM dbo.Racks r
    WHERE r.IsActive = 1
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
        r.NumberOfDraws,
        r.BranchId,
        r.IsActive,
        r.CreatedOn
    FROM dbo.Racks r
    WHERE r.Id = @Id;
END
GO

-- =============================================
-- Insert Rack
-- =============================================
CREATE OR ALTER PROCEDURE Rack_Insert
    @Name NVARCHAR(MAX),
    @StoreId UNIQUEIDENTIFIER,
    @Description NVARCHAR(MAX) = NULL,
    @Location NVARCHAR(MAX) = NULL,
    @NumberOfRows INT,
    @NumberOfCols INT,
    @NumberOfDraws INT,
    @BranchId UNIQUEIDENTIFIER,
    @CreatedById UNIQUEIDENTIFIER,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO dbo.Racks (
        Name,
        StoreId,
        Description,
        Location,
        NumberOfRows,
        NumberOfCols,
        NumberOfDraws,
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
        @NumberOfDraws,
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
    @StoreId UNIQUEIDENTIFIER,
    @Description NVARCHAR(MAX) = NULL,
    @Location NVARCHAR(MAX) = NULL,
    @NumberOfRows INT,
    @NumberOfCols INT,
    @NumberOfDraws INT,
    @ModifiedById UNIQUEIDENTIFIER,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE dbo.Racks
    SET 
        Name = @Name,
        StoreId = @StoreId,
        Description = @Description,
        Location = @Location,
        NumberOfRows = @NumberOfRows,
        NumberOfCols = @NumberOfCols,
        NumberOfDraws = @NumberOfDraws,
        IsActive = @IsActive,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETDATE()
    WHERE Id = @Id;
    
    SELECT @Id AS Id;
END
GO

-- =============================================
-- Delete Rack (Soft Delete)
-- =============================================
CREATE OR ALTER PROCEDURE Rack_Delete
    @Id INT,
    @ModifiedById UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE dbo.Racks
    SET 
        IsActive = 0,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETDATE()
    WHERE Id = @Id;
END
GO

PRINT 'Rack CRUD stored procedures created successfully';
