-- =============================================
-- Stock Adjustment Stored Procedures
-- =============================================

-- Get All Stock Adjustments
CREATE OR ALTER PROCEDURE StockAdjustment_GetAll
    @BranchId INT = NULL,
    @StoreId INT = NULL,
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        sa.Id,
        s.StoreName,
        CAST('' AS NVARCHAR(MAX)) AS ItemNames,
        CAST('' AS NVARCHAR(MAX)) AS StockType,
        ISNULL(u.Name, '') AS ActionBy,
        sa.CreatedOn AS ActionOn,
        CAST(0 AS DECIMAL(18,2)) AS TotalQuantity,
        CAST(0 AS DECIMAL(18,2)) AS TotalPurchaseValue,
        CAST(0 AS DECIMAL(18,2)) AS TotalSaleValue
    FROM dbo.StockAdjustments sa
    LEFT JOIN dbo.Stores s ON sa.StoreId = s.StoreId
    LEFT JOIN dbo.Users u ON sa.CreatedById = u.Id
    WHERE sa.IsDeleted = 0
        AND (@BranchId IS NULL OR sa.BranchId = @BranchId)
        AND (@StoreId IS NULL OR sa.StoreId = @StoreId)
        AND (@StartDate IS NULL OR sa.CreatedOn >= @StartDate)
        AND (@EndDate IS NULL OR sa.CreatedOn <= @EndDate)
    ORDER BY sa.CreatedOn DESC;
END
GO

-- Get Stock Adjustment By ID
CREATE OR ALTER PROCEDURE StockAdjustment_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Get main stock adjustment
    SELECT 
        sa.Id,
        sa.StoreId,
        s.StoreName,
        sa.Type,
        CASE sa.Type 
            WHEN 1 THEN 'Less/Decrease'
            WHEN 2 THEN 'Issue'
            ELSE 'Unknown'
        END AS TypeName,
        sa.VoucherId,
        sa.BranchId,
        b.Name AS BranchName,
        sa.CreatedById,
        ISNULL(cu.Name, '') AS CreatedByName,
        sa.CreatedOn,
        sa.ModifiedById,
        sa.ModifiedOn,
        sa.IsActive,
        sa.IsDeleted
    FROM dbo.StockAdjustments sa
    LEFT JOIN dbo.Stores s ON sa.StoreId = s.StoreId
    LEFT JOIN dbo.Branches b ON sa.BranchId = b.Id
    LEFT JOIN dbo.Users cu ON sa.CreatedById = cu.Id
    WHERE sa.Id = @Id AND sa.IsDeleted = 0;

    -- Get details
    SELECT 
        sad.Id,
        sad.StockAdjustmentId,
        sad.ItemId,
        i.Name AS ItemName,
        sad.Type,
        CASE sad.Type 
            WHEN 1 THEN 'Less/Decrease'
            WHEN 2 THEN 'Issue'
            ELSE 'Unknown'
        END AS TypeName,
        sad.StockTypeId,
        st.StockTypeName,
        sad.Quantity,
        sad.BranchId,
        sad.CreatedById,
        sad.CreatedOn,
        sad.ModifiedById,
        sad.ModifiedOn,
        sad.IsActive,
        sad.IsDeleted,
        sad.SaleValue,
        sad.PurchaseValue
    FROM dbo.StockAdjustmentDetails sad
    LEFT JOIN dbo.InventoryItems i ON sad.ItemId = i.Id
    LEFT JOIN dbo.StockTypes st ON sad.StockTypeId = st.StockTypeId
    WHERE sad.StockAdjustmentId = @Id AND sad.IsDeleted = 0;
END
GO

-- Insert Stock Adjustment
CREATE OR ALTER PROCEDURE StockAdjustment_Insert
    @Id INT OUTPUT,
    @StoreId INT,
    @BranchId INT,
    @Type INT,
    @CreatedById INT = NULL,
    @CreatedOn DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.StockAdjustments (
        StoreId, Type, BranchId, CreatedById, CreatedOn, IsActive, IsDeleted
    )
    VALUES (
        @StoreId, @Type, @BranchId, @CreatedById, @CreatedOn, 1, 0
    );
    
    SET @Id = SCOPE_IDENTITY();
END
GO

-- Update Stock Adjustment
CREATE OR ALTER PROCEDURE StockAdjustment_Update
    @Id INT,
    @StoreId INT,
    @BranchId INT,
    @Type INT,
    @ModifiedById INT = NULL,
    @ModifiedOn DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.StockAdjustments
    SET 
        StoreId = @StoreId,
        Type = @Type,
        BranchId = @BranchId,
        ModifiedById = @ModifiedById,
        ModifiedOn = @ModifiedOn
    WHERE Id = @Id;
END
GO

-- Delete Stock Adjustment (soft delete)
CREATE OR ALTER PROCEDURE StockAdjustment_Delete
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.StockAdjustments
    SET IsDeleted = 1
    WHERE Id = @Id;

    UPDATE dbo.StockAdjustmentDetails
    SET IsDeleted = 1
    WHERE StockAdjustmentId = @Id;
END
GO

-- Insert Stock Adjustment Detail
CREATE OR ALTER PROCEDURE StockAdjustmentDetail_Insert
    @Id INT OUTPUT,
    @StockAdjustmentId INT,
    @ItemId INT,
    @Type INT,
    @StockTypeId INT,
    @Quantity DECIMAL(18,2),
    @SaleValue DECIMAL(18,2) = NULL,
    @BranchId INT,
    @CreatedById INT = NULL,
    @CreatedOn DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.StockAdjustmentDetails (
        StockAdjustmentId, ItemId, Type, StockTypeId, Quantity, 
        SaleValue, BranchId, CreatedById, CreatedOn, IsActive, IsDeleted
    )
    VALUES (
        @StockAdjustmentId, @ItemId, @Type, @StockTypeId, @Quantity,
        @SaleValue, @BranchId, @CreatedById, @CreatedOn, 1, 0
    );
    
    SET @Id = SCOPE_IDENTITY();
END
GO

-- Delete Stock Adjustment Details by Adjustment ID
CREATE OR ALTER PROCEDURE StockAdjustmentDetail_DeleteByAdjustmentId
    @StockAdjustmentId INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.StockAdjustmentDetails
    SET IsDeleted = 1
    WHERE StockAdjustmentId = @StockAdjustmentId;
END
GO
