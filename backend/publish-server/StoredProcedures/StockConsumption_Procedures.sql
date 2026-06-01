-- =============================================
-- Stock Consumption Stored Procedures
-- =============================================

-- Get All Stock Consumptions
CREATE OR ALTER PROCEDURE StockConsumption_GetAll
    @BranchId UNIQUEIDENTIFIER = NULL,
    @StoreId UNIQUEIDENTIFIER = NULL,
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        scd.StockConsumptionId AS Id,
        s.StoreName,
        i.Name AS ItemName,
        CAST(scd.Type AS NVARCHAR(50)) AS Type,
        st.Name AS StockType,
        scd.Quantity,
        ISNULL(u.Name, '') AS CreatedBy,
        sc.CreatedOn
    FROM dbo.StockConsumptionDetails scd
    INNER JOIN dbo.StockConsumptions sc ON scd.StockConsumptionId = sc.Id
    LEFT JOIN dbo.Stores s ON CAST(sc.StoreId AS NVARCHAR(50)) = CAST(s.StoreId AS NVARCHAR(50))
    LEFT JOIN dbo.Items i ON scd.ItemId = i.Id
    LEFT JOIN dbo.StockTypes st ON scd.StockTypeId = st.Id
    LEFT JOIN dbo.Users u ON CAST(sc.CreatedById AS NVARCHAR(50)) = CAST(u.Id AS NVARCHAR(50))
    WHERE sc.IsDeleted = 0
        AND scd.IsDeleted = 0
        AND (@BranchId IS NULL OR sc.BranchId = @BranchId)
        AND (@StoreId IS NULL OR CAST(sc.StoreId AS NVARCHAR(50)) = CAST(@StoreId AS NVARCHAR(50)))
        AND (@StartDate IS NULL OR sc.CreatedOn >= @StartDate)
        AND (@EndDate IS NULL OR sc.CreatedOn <= @EndDate)
    ORDER BY sc.CreatedOn DESC;
END
GO

-- Get Stock Consumption By ID
CREATE OR ALTER PROCEDURE StockConsumption_GetById
    @Id UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    -- Get main stock consumption
    SELECT 
        sc.Id,
        sc.StoreId,
        s.StoreName,
        sc.Type,
        sc.BranchId,
        b.Name AS BranchName,
        sc.VoucherId,
        sc.IsActive,
        sc.CreatedById,
        ISNULL(cu.Name, '') AS CreatedByName,
        sc.CreatedOn,
        sc.ModifiedById,
        sc.ModifiedOn,
        sc.IsDeleted,
        sc.Remarks
    FROM dbo.StockConsumptions sc
    LEFT JOIN dbo.Stores s ON CAST(sc.StoreId AS NVARCHAR(50)) = CAST(s.StoreId AS NVARCHAR(50))
    LEFT JOIN dbo.Branches b ON CAST(sc.BranchId AS NVARCHAR(50)) = CAST(b.Id AS NVARCHAR(50))
    LEFT JOIN dbo.Users cu ON CAST(sc.CreatedById AS NVARCHAR(50)) = CAST(cu.Id AS NVARCHAR(50))
    WHERE sc.Id = @Id AND sc.IsDeleted = 0;

    -- Get details
    SELECT 
        scd.Id,
        scd.StockConsumptionId,
        scd.StoreId,
        s.StoreName,
        scd.ItemId,
        i.Name AS ItemName,
        scd.Type,
        scd.StockTypeId,
        st.Name AS StockTypeName,
        scd.Quantity,
        scd.BranchId,
        scd.InventoryItemId,
        scd.SysBatchNo,
        scd.BatchNo,
        scd.IsActive,
        scd.CreatedById,
        scd.CreatedOn,
        scd.ModifiedById,
        scd.ModifiedOn,
        scd.IsDeleted
    FROM dbo.StockConsumptionDetails scd
    LEFT JOIN dbo.Stores s ON CAST(scd.StoreId AS NVARCHAR(50)) = CAST(s.StoreId AS NVARCHAR(50))
    LEFT JOIN dbo.Items i ON scd.ItemId = i.Id
    LEFT JOIN dbo.StockTypes st ON scd.StockTypeId = st.Id
    WHERE scd.StockConsumptionId = @Id AND scd.IsDeleted = 0;
END
GO

-- Insert Stock Consumption
CREATE OR ALTER PROCEDURE StockConsumption_Insert
    @Id UNIQUEIDENTIFIER,
    @StoreId UNIQUEIDENTIFIER,
    @BranchId UNIQUEIDENTIFIER,
    @Type INT,
    @CreatedById UNIQUEIDENTIFIER = NULL,
    @CreatedOn DATETIME,
    @Remarks NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.StockConsumptions (
        Id, StoreId, Type, BranchId, CreatedById, CreatedOn, IsActive, IsDeleted, Remarks
    )
    VALUES (
        @Id, @StoreId, @Type, @BranchId, @CreatedById, @CreatedOn, 1, 0, @Remarks
    );
END
GO

-- Update Stock Consumption
CREATE OR ALTER PROCEDURE StockConsumption_Update
    @Id UNIQUEIDENTIFIER,
    @StoreId UNIQUEIDENTIFIER,
    @BranchId UNIQUEIDENTIFIER,
    @Type INT,
    @ModifiedById UNIQUEIDENTIFIER = NULL,
    @ModifiedOn DATETIME,
    @Remarks NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.StockConsumptions
    SET 
        StoreId = @StoreId,
        Type = @Type,
        BranchId = @BranchId,
        ModifiedById = @ModifiedById,
        ModifiedOn = @ModifiedOn,
        Remarks = @Remarks
    WHERE Id = @Id;
END
GO

-- Delete Stock Consumption (soft delete)
CREATE OR ALTER PROCEDURE StockConsumption_Delete
    @Id UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.StockConsumptions
    SET IsDeleted = 1
    WHERE Id = @Id;

    UPDATE dbo.StockConsumptionDetails
    SET IsDeleted = 1
    WHERE StockConsumptionId = @Id;
END
GO

-- Insert Stock Consumption Detail
CREATE OR ALTER PROCEDURE StockConsumptionDetail_Insert
    @Id UNIQUEIDENTIFIER,
    @StockConsumptionId UNIQUEIDENTIFIER,
    @StoreId UNIQUEIDENTIFIER,
    @ItemId INT,
    @Type INT,
    @StockTypeId INT,
    @Quantity DECIMAL(18,2),
    @BranchId UNIQUEIDENTIFIER,
    @CreatedById UNIQUEIDENTIFIER = NULL,
    @CreatedOn DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.StockConsumptionDetails (
        Id, StockConsumptionId, StoreId, ItemId, Type, StockTypeId, Quantity, 
        BranchId, CreatedById, CreatedOn, IsActive, IsDeleted
    )
    VALUES (
        @Id, @StockConsumptionId, @StoreId, @ItemId, @Type, @StockTypeId, @Quantity,
        @BranchId, @CreatedById, @CreatedOn, 1, 0
    );
END
GO

-- Delete Stock Consumption Details by Consumption ID
CREATE OR ALTER PROCEDURE StockConsumptionDetail_DeleteByConsumptionId
    @StockConsumptionId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.StockConsumptionDetails
    SET IsDeleted = 1
    WHERE StockConsumptionId = @StockConsumptionId;
END
GO
