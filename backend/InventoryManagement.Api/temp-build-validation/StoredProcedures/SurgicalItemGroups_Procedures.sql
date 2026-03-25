-- =============================================
-- Stored Procedures for SurgicalItemGroups
-- =============================================

-- 1. Get All Surgical Item Groups
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SurgicalItemGroups_GetAll')
    DROP PROCEDURE SurgicalItemGroups_GetAll;
GO

CREATE PROCEDURE SurgicalItemGroups_GetAll
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        sg.Id,
        sg.Name,
        sg.Description,
        sg.BranchId,
        b.Name AS BranchName,
        sg.SubServiceId,
        sg.IsActive,
        sg.CreatedById,
        sg.CreatedOn,
        sg.ModifiedById,
        sg.ModifiedOn,
        sg.IsDeleted
    FROM dbo.SurgicalItemGroups sg
    LEFT JOIN dbo.Branches b ON sg.BranchId = b.Id
    WHERE sg.IsDeleted = 0 AND sg.IsActive = 1
    ORDER BY sg.CreatedOn DESC;
END
GO

-- 2. Get Surgical Item Group By Id
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SurgicalItemGroups_GetById')
    DROP PROCEDURE SurgicalItemGroups_GetById;
GO

CREATE PROCEDURE SurgicalItemGroups_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        sg.Id,
        sg.Name,
        sg.Description,
        sg.BranchId,
        b.Name AS BranchName,
        sg.SubServiceId,
        sg.IsActive,
        sg.CreatedById,
        sg.CreatedOn,
        sg.ModifiedById,
        sg.ModifiedOn,
        sg.IsDeleted
    FROM dbo.SurgicalItemGroups sg
    LEFT JOIN dbo.Branches b ON sg.BranchId = b.Id
    WHERE sg.Id = @Id AND sg.IsDeleted = 0;
END
GO

-- 3. Insert Surgical Item Group
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SurgicalItemGroups_Insert')
    DROP PROCEDURE SurgicalItemGroups_Insert;
GO

CREATE PROCEDURE SurgicalItemGroups_Insert
    @Name NVARCHAR(MAX) = NULL,
    @Description NVARCHAR(MAX) = NULL,
    @BranchId INT,
    @SubServiceId NVARCHAR(450) = NULL,
    @CreatedById NVARCHAR(450) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.SurgicalItemGroups (
        Name,
        Description,
        BranchId,
        SubServiceId,
        CreatedById,
        CreatedOn,
        IsDeleted,
        IsActive
    )
    VALUES (
        @Name,
        @Description,
        @BranchId,
        @SubServiceId,
        @CreatedById,
        GETDATE(),
        0,
        1
    );

    SELECT SCOPE_IDENTITY() AS Id;
END
GO

-- 4. Update Surgical Item Group
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SurgicalItemGroups_Update')
    DROP PROCEDURE SurgicalItemGroups_Update;
GO

CREATE PROCEDURE SurgicalItemGroups_Update
    @Id INT,
    @Name NVARCHAR(MAX) = NULL,
    @Description NVARCHAR(MAX) = NULL,
    @BranchId INT,
    @SubServiceId NVARCHAR(450) = NULL,
    @ModifiedById NVARCHAR(450) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.SurgicalItemGroups
    SET 
        Name = @Name,
        Description = @Description,
        BranchId = @BranchId,
        SubServiceId = @SubServiceId,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETDATE()
    WHERE Id = @Id AND IsDeleted = 0;

    SELECT @@ROWCOUNT AS RowsAffected;
END
GO

-- 5. Delete Surgical Item Group (Soft Delete)
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SurgicalItemGroups_Delete')
    DROP PROCEDURE SurgicalItemGroups_Delete;
GO

CREATE PROCEDURE SurgicalItemGroups_Delete
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.SurgicalItemGroups
    SET 
        IsDeleted = 1,
        IsActive = 0,
        ModifiedOn = GETDATE()
    WHERE Id = @Id;

    SELECT @@ROWCOUNT AS RowsAffected;
END
GO

-- 6. Get Lookup Data
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SurgicalItemGroups_GetLookupData')
    DROP PROCEDURE SurgicalItemGroups_GetLookupData;
GO

CREATE PROCEDURE SurgicalItemGroups_GetLookupData
AS
BEGIN
    SET NOCOUNT ON;

    -- Branches
    SELECT 
        Id,
        Name
    FROM dbo.Branches
    WHERE IsActive = 1
    ORDER BY Name;
END
GO

PRINT 'All SurgicalItemGroups stored procedures created successfully.';
