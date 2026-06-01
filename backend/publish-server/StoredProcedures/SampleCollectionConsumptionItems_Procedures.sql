-- =============================================
-- Stored Procedures for SampleCollectionConsumptionItems
-- =============================================

-- 1. Get All Sample Collection Consumption Items
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SampleCollectionConsumptionItems_GetAll')
    DROP PROCEDURE SampleCollectionConsumptionItems_GetAll;
GO

CREATE PROCEDURE SampleCollectionConsumptionItems_GetAll
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        sc.Id,
        sc.ItemId,
        i.Name AS ItemName,
        sc.MedicineId,
        sc.FeeId,
        sc.DepartmentId,
        d.Name AS DepartmentName,
        sc.BranchId,
        b.Name AS BranchName,
        sc.Quantity,
        sc.CreatedById,
        sc.CreatedOn,
        sc.ModifiedById,
        sc.ModifiedOn,
        sc.IsDeleted,
        sc.IsActive
    FROM dbo.SampleCollectionConsumptionItems sc
    LEFT JOIN dbo.Items i ON sc.ItemId = i.Id
    LEFT JOIN dbo.Departments d ON sc.DepartmentId = d.Id
    LEFT JOIN dbo.Branches b ON sc.BranchId = b.Id
    WHERE sc.IsDeleted = 0 AND sc.IsActive = 1
    ORDER BY sc.CreatedOn DESC;
END
GO

-- 2. Get Sample Collection Consumption Item By Id
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SampleCollectionConsumptionItems_GetById')
    DROP PROCEDURE SampleCollectionConsumptionItems_GetById;
GO

CREATE PROCEDURE SampleCollectionConsumptionItems_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        sc.Id,
        sc.ItemId,
        i.Name AS ItemName,
        sc.MedicineId,
        sc.FeeId,
        sc.DepartmentId,
        d.Name AS DepartmentName,
        sc.BranchId,
        b.Name AS BranchName,
        sc.Quantity,
        sc.CreatedById,
        sc.CreatedOn,
        sc.ModifiedById,
        sc.ModifiedOn,
        sc.IsDeleted,
        sc.IsActive
    FROM dbo.SampleCollectionConsumptionItems sc
    LEFT JOIN dbo.Items i ON sc.ItemId = i.Id
    LEFT JOIN dbo.Departments d ON sc.DepartmentId = d.Id
    LEFT JOIN dbo.Branches b ON sc.BranchId = b.Id
    WHERE sc.Id = @Id AND sc.IsDeleted = 0;
END
GO

-- 3. Insert Sample Collection Consumption Item
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SampleCollectionConsumptionItems_Insert')
    DROP PROCEDURE SampleCollectionConsumptionItems_Insert;
GO

CREATE PROCEDURE SampleCollectionConsumptionItems_Insert
    @ItemId INT,
    @MedicineId INT = NULL,
    @FeeId INT = NULL,
    @DepartmentId INT,
    @BranchId INT,
    @Quantity INT,
    @CreatedById NVARCHAR(450) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.SampleCollectionConsumptionItems (
        ItemId,
        MedicineId,
        FeeId,
        DepartmentId,
        BranchId,
        Quantity,
        CreatedById,
        CreatedOn,
        IsDeleted,
        IsActive
    )
    VALUES (
        @ItemId,
        @MedicineId,
        @FeeId,
        @DepartmentId,
        @BranchId,
        @Quantity,
        @CreatedById,
        GETDATE(),
        0,
        1
    );

    SELECT SCOPE_IDENTITY() AS Id;
END
GO

-- 4. Update Sample Collection Consumption Item
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SampleCollectionConsumptionItems_Update')
    DROP PROCEDURE SampleCollectionConsumptionItems_Update;
GO

CREATE PROCEDURE SampleCollectionConsumptionItems_Update
    @Id INT,
    @ItemId INT,
    @MedicineId INT = NULL,
    @FeeId INT = NULL,
    @DepartmentId INT,
    @BranchId INT,
    @Quantity INT,
    @ModifiedById NVARCHAR(450) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.SampleCollectionConsumptionItems
    SET 
        ItemId = @ItemId,
        MedicineId = @MedicineId,
        FeeId = @FeeId,
        DepartmentId = @DepartmentId,
        BranchId = @BranchId,
        Quantity = @Quantity,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETDATE()
    WHERE Id = @Id AND IsDeleted = 0;

    SELECT @@ROWCOUNT AS RowsAffected;
END
GO

-- 5. Delete Sample Collection Consumption Item (Soft Delete)
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SampleCollectionConsumptionItems_Delete')
    DROP PROCEDURE SampleCollectionConsumptionItems_Delete;
GO

CREATE PROCEDURE SampleCollectionConsumptionItems_Delete
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.SampleCollectionConsumptionItems
    SET 
        IsDeleted = 1,
        IsActive = 0,
        ModifiedOn = GETDATE()
    WHERE Id = @Id;

    SELECT @@ROWCOUNT AS RowsAffected;
END
GO

-- 6. Get Lookup Data
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SampleCollectionConsumptionItems_GetLookupData')
    DROP PROCEDURE SampleCollectionConsumptionItems_GetLookupData;
GO

CREATE PROCEDURE SampleCollectionConsumptionItems_GetLookupData
AS
BEGIN
    SET NOCOUNT ON;

    -- Departments
    SELECT 
        Id,
        Name
    FROM dbo.Departments
    WHERE IsActive = 1
    ORDER BY Name;

    -- Items
    SELECT 
        Id,
        Name
    FROM dbo.Items
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

PRINT 'All SampleCollectionConsumptionItems stored procedures created successfully.';
