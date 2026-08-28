-- =============================================
-- Stored Procedures for SurgicalItemGroups
-- =============================================

-- 1. Get All Surgical Item Groups
CREATE OR ALTER PROCEDURE SurgicalItemGroups_GetAll
    @BranchId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        sg.Id,
        sg.Name,
        sg.Description,
        sg.BranchId,
        b.Name AS BranchName,
        sg.SubServiceName AS SubServiceId,
        sg.IsActive,
        sg.CreatedById,
        sg.CreatedOn,
        sg.ModifiedById,
        sg.ModifiedOn,
        sg.IsDeleted
    FROM Inv.SurgicalGroups sg
    LEFT JOIN Inv.Branches b ON sg.BranchId = b.Id
    WHERE sg.IsDeleted = 0 AND sg.IsActive = 1 AND sg.BranchId = @BranchId
    ORDER BY sg.CreatedOn DESC;
END
GO

-- 2. Get Surgical Item Group By Id
CREATE OR ALTER PROCEDURE SurgicalItemGroups_GetById
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
        sg.SubServiceName AS SubServiceId,
        sg.IsActive,
        sg.CreatedById,
        sg.CreatedOn,
        sg.ModifiedById,
        sg.ModifiedOn,
        sg.IsDeleted
    FROM Inv.SurgicalGroups sg
    LEFT JOIN Inv.Branches b ON sg.BranchId = b.Id
    WHERE sg.Id = @Id AND sg.IsDeleted = 0;
END
GO

-- 3. Insert Surgical Item Group
CREATE OR ALTER PROCEDURE SurgicalItemGroups_Insert
    @Name NVARCHAR(MAX) = NULL,
    @Description NVARCHAR(MAX) = NULL,
    @BranchId INT,
    @SubServiceId NVARCHAR(450) = NULL,
    @CreatedById NVARCHAR(450) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- SubServiceId is a free-text service label from the UI, not a real
    -- foreign key (the underlying column is an unrelated int), so it is
    -- stored in SubServiceName instead.
    INSERT INTO Inv.SurgicalGroups (
        Name,
        Description,
        BranchId,
        SubServiceName,
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
        TRY_CONVERT(INT, @CreatedById),
        GETDATE(),
        0,
        1
    );

    SELECT SCOPE_IDENTITY() AS Id;
END
GO

-- 4. Update Surgical Item Group
CREATE OR ALTER PROCEDURE SurgicalItemGroups_Update
    @Id INT,
    @Name NVARCHAR(MAX) = NULL,
    @Description NVARCHAR(MAX) = NULL,
    @BranchId INT,
    @SubServiceId NVARCHAR(450) = NULL,
    @ModifiedById NVARCHAR(450) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Inv.SurgicalGroups
    SET
        Name = @Name,
        Description = @Description,
        BranchId = @BranchId,
        SubServiceName = @SubServiceId,
        ModifiedById = TRY_CONVERT(INT, @ModifiedById),
        ModifiedOn = GETDATE()
    WHERE Id = @Id AND IsDeleted = 0;

    SELECT @@ROWCOUNT AS RowsAffected;
END
GO

-- 5. Delete Surgical Item Group (Soft Delete)
CREATE OR ALTER PROCEDURE SurgicalItemGroups_Delete
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Inv.SurgicalGroups
    SET
        IsDeleted = 1,
        IsActive = 0,
        ModifiedOn = GETDATE()
    WHERE Id = @Id;

    SELECT @@ROWCOUNT AS RowsAffected;
END
GO

-- 6. Get Lookup Data
CREATE OR ALTER PROCEDURE SurgicalItemGroups_GetLookupData
AS
BEGIN
    SET NOCOUNT ON;

    -- Branches
    SELECT
        Id,
        Name
    FROM Inv.Branches
    WHERE IsActive = 1
    ORDER BY Name;
END
GO

PRINT 'All SurgicalItemGroups stored procedures created successfully.';
