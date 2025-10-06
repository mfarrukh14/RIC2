-- =============================================
-- Stored Procedures for ItemTypeSaleLevels
-- =============================================

-- 1. Get All Item Type Sale Levels
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'ItemTypeSaleLevels_GetAll')
    DROP PROCEDURE ItemTypeSaleLevels_GetAll;
GO

CREATE PROCEDURE ItemTypeSaleLevels_GetAll
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        itsl.Id,
        itsl.ItemTypeId,
        it.Name AS ItemTypeName,
        itsl.FastRunningLevel,
        itsl.SlowMovingLevel,
        itsl.DeadLevel,
        itsl.BranchId,
        b.Name AS BranchName,
        itsl.IsActive,
        itsl.CreatedById,
        itsl.CreatedOn,
        itsl.ModifiedById,
        itsl.ModifiedOn,
        itsl.IsDeleted
    FROM dbo.ItemTypeSaleLevels itsl
    LEFT JOIN dbo.ItemTypes it ON itsl.ItemTypeId = it.Id
    LEFT JOIN dbo.Branches b ON itsl.BranchId = b.Id
    WHERE itsl.IsDeleted = 0 AND itsl.IsActive = 1
    ORDER BY itsl.CreatedOn DESC;
END
GO

-- 2. Get Item Type Sale Level By Id
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'ItemTypeSaleLevels_GetById')
    DROP PROCEDURE ItemTypeSaleLevels_GetById;
GO

CREATE PROCEDURE ItemTypeSaleLevels_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        itsl.Id,
        itsl.ItemTypeId,
        it.Name AS ItemTypeName,
        itsl.FastRunningLevel,
        itsl.SlowMovingLevel,
        itsl.DeadLevel,
        itsl.BranchId,
        b.Name AS BranchName,
        itsl.IsActive,
        itsl.CreatedById,
        itsl.CreatedOn,
        itsl.ModifiedById,
        itsl.ModifiedOn,
        itsl.IsDeleted
    FROM dbo.ItemTypeSaleLevels itsl
    LEFT JOIN dbo.ItemTypes it ON itsl.ItemTypeId = it.Id
    LEFT JOIN dbo.Branches b ON itsl.BranchId = b.Id
    WHERE itsl.Id = @Id AND itsl.IsDeleted = 0;
END
GO

-- 3. Insert Item Type Sale Level
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'ItemTypeSaleLevels_Insert')
    DROP PROCEDURE ItemTypeSaleLevels_Insert;
GO

CREATE PROCEDURE ItemTypeSaleLevels_Insert
    @ItemTypeId INT,
    @FastRunningLevel INT,
    @SlowMovingLevel INT,
    @DeadLevel INT,
    @BranchId INT,
    @CreatedById NVARCHAR(450) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.ItemTypeSaleLevels (
        ItemTypeId,
        FastRunningLevel,
        SlowMovingLevel,
        DeadLevel,
        BranchId,
        CreatedById,
        CreatedOn,
        IsDeleted,
        IsActive
    )
    VALUES (
        @ItemTypeId,
        @FastRunningLevel,
        @SlowMovingLevel,
        @DeadLevel,
        @BranchId,
        @CreatedById,
        GETDATE(),
        0,
        1
    );

    SELECT SCOPE_IDENTITY() AS Id;
END
GO

-- 4. Update Item Type Sale Level
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'ItemTypeSaleLevels_Update')
    DROP PROCEDURE ItemTypeSaleLevels_Update;
GO

CREATE PROCEDURE ItemTypeSaleLevels_Update
    @Id INT,
    @ItemTypeId INT,
    @FastRunningLevel INT,
    @SlowMovingLevel INT,
    @DeadLevel INT,
    @BranchId INT,
    @ModifiedById NVARCHAR(450) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.ItemTypeSaleLevels
    SET 
        ItemTypeId = @ItemTypeId,
        FastRunningLevel = @FastRunningLevel,
        SlowMovingLevel = @SlowMovingLevel,
        DeadLevel = @DeadLevel,
        BranchId = @BranchId,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETDATE()
    WHERE Id = @Id AND IsDeleted = 0;

    SELECT @@ROWCOUNT AS RowsAffected;
END
GO

-- 5. Delete Item Type Sale Level (Soft Delete)
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'ItemTypeSaleLevels_Delete')
    DROP PROCEDURE ItemTypeSaleLevels_Delete;
GO

CREATE PROCEDURE ItemTypeSaleLevels_Delete
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.ItemTypeSaleLevels
    SET 
        IsDeleted = 1,
        IsActive = 0,
        ModifiedOn = GETDATE()
    WHERE Id = @Id;

    SELECT @@ROWCOUNT AS RowsAffected;
END
GO

-- 6. Get Lookup Data
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'ItemTypeSaleLevels_GetLookupData')
    DROP PROCEDURE ItemTypeSaleLevels_GetLookupData;
GO

CREATE PROCEDURE ItemTypeSaleLevels_GetLookupData
AS
BEGIN
    SET NOCOUNT ON;

    -- Item Types
    SELECT 
        Id,
        Name
    FROM dbo.ItemTypes
    WHERE IsActive = 1
    ORDER BY Name;

    -- Branches
    SELECT 
        Id,
        Name
    FROM dbo.Branches
    WHERE IsActive = 1
    ORDER BY Name;
END
GO

PRINT 'All ItemTypeSaleLevels stored procedures created successfully.';
