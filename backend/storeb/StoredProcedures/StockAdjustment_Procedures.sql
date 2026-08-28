-- =============================================
-- Stock Adjustment Stored Procedures
-- =============================================

-- Get All Stock Adjustments
-- Paginated - filter/sort/page the cheap header columns FIRST (two-phase CTE,
-- same convention as Stock_Search), then only run the expensive per-row
-- STRING_AGG/SUM aggregation over StockAdjustmentDetails for the @PageSize
-- rows that actually make it onto the page, instead of for all header rows.
-- @SearchTerm only matches StoreName/ActionBy (the columns available before
-- aggregation) - it can't cheaply match ItemNames since that's a computed
-- aggregate that would require evaluating it for every row first.
CREATE OR ALTER PROCEDURE StockAdjustment_GetAll
    @BranchId INT = NULL,
    @StoreId INT = NULL,
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL,
    @SearchTerm NVARCHAR(200) = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (CASE WHEN @PageNumber < 1 THEN 0 ELSE @PageNumber - 1 END) * (CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END);
    DECLARE @Take INT = CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END;

    ;WITH FilteredHeaders AS (
        SELECT
            sa.Id,
            s.StoreName,
            ISNULL(e.FullName, (e.FirstName + ' ' + e.LastName)) AS ActionBy,
            sa.CreatedOn AS ActionOn
        FROM Inv.StockAdjustments sa
        LEFT JOIN Inv.PharmacyStores s ON sa.StoreId = s.StoreId
        LEFT JOIN dbo.Users u ON sa.CreatedById = u.UserID
        LEFT JOIN dbo.Employee e ON e.EmpID = u.EmpID
        WHERE sa.IsDeleted = 0
            AND (@BranchId IS NULL OR sa.BranchId = @BranchId)
            AND (@StoreId IS NULL OR sa.StoreId = @StoreId)
            AND (@StartDate IS NULL OR sa.CreatedOn >= @StartDate)
            AND (@EndDate IS NULL OR sa.CreatedOn <= @EndDate)
            AND (
                @SearchTerm IS NULL OR @SearchTerm = ''
                OR s.StoreName LIKE '%' + @SearchTerm + '%'
                OR e.FullName LIKE '%' + @SearchTerm + '%'
            )
    ),
    Paged AS (
        SELECT *, COUNT(*) OVER() AS TotalCount
        FROM FilteredHeaders
        ORDER BY ActionOn DESC
        OFFSET @Offset ROWS FETCH NEXT @Take ROWS ONLY
    )
    SELECT
        Paged.Id,
        Paged.StoreName,
        agg.ItemNames,
        agg.StockType,
        Paged.ActionBy,
        Paged.ActionOn,
        ISNULL(agg.TotalQuantity, 0) AS TotalQuantity,
        ISNULL(agg.TotalPurchaseValue, 0) AS TotalPurchaseValue,
        ISNULL(agg.TotalSaleValue, 0) AS TotalSaleValue,
        Paged.TotalCount
    FROM Paged
    OUTER APPLY (
        SELECT
            STRING_AGG(COALESCE(i.Name, m.MedicineFullName, f.Name), ', ') AS ItemNames,
            (
                SELECT TOP 1 st2.Name
                FROM Inv.StockAdjustmentDetails d2
                LEFT JOIN Inv.StockTypes st2 ON d2.StockTypeId = st2.Id
                WHERE d2.StockAdjustmentId = Paged.Id AND d2.IsDeleted = 0
            ) AS StockType,
            SUM(d.Quantity) AS TotalQuantity,
            SUM(ISNULL(d.PurchaseValue, 0)) AS TotalPurchaseValue,
            SUM(ISNULL(d.SaleValue, 0)) AS TotalSaleValue
        FROM Inv.StockAdjustmentDetails d
        LEFT JOIN Inv.Items i ON d.ItemId = i.Id
        LEFT JOIN Pharmacy.Medicines m ON d.MedicineId = m.MedicineId
        LEFT JOIN Account.Fees f ON d.SubServiceId = f.Id
        WHERE d.StockAdjustmentId = Paged.Id AND d.IsDeleted = 0
    ) agg
    ORDER BY Paged.ActionOn DESC;
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
        ISNULL(e.FullName, (e.FirstName + ' ' + e.LastName)) AS CreatedByName,
        sa.CreatedOn,
        sa.ModifiedById,
        sa.ModifiedOn,
        sa.IsActive,
        sa.IsDeleted
    FROM Inv.StockAdjustments sa
    LEFT JOIN Inv.PharmacyStores s ON sa.StoreId = s.StoreId
    LEFT JOIN Inv.Branches b ON sa.BranchId = b.Id
    LEFT JOIN dbo.Users cu ON sa.CreatedById = cu.UserID
    LEFT JOIN dbo.Employee e ON e.EmpID = cu.EmpID
    WHERE sa.Id = @Id AND sa.IsDeleted = 0;

    -- Get details
    SELECT
        sad.Id,
        sad.StockAdjustmentId,
        sad.ItemId,
        i.Name AS ItemName,
        sad.MedicineId,
        m.MedicineFullName AS MedicineName,
        sad.SubServiceId,
        f.Name AS SubServiceName,
        sad.Type,
        CASE sad.Type
            WHEN 1 THEN 'Less/Decrease'
            WHEN 2 THEN 'Issue'
            ELSE 'Unknown'
        END AS TypeName,
        sad.StockTypeId,
        st.Name AS StockTypeName,
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
    FROM Inv.StockAdjustmentDetails sad
    LEFT JOIN Inv.Items i ON sad.ItemId = i.Id
    LEFT JOIN Pharmacy.Medicines m ON sad.MedicineId = m.MedicineId
    LEFT JOIN Account.Fees f ON sad.SubServiceId = f.Id
    LEFT JOIN Inv.StockTypes st ON sad.StockTypeId = st.Id
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

    INSERT INTO Inv.StockAdjustments (
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

    UPDATE Inv.StockAdjustments
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

    UPDATE Inv.StockAdjustments
    SET IsDeleted = 1
    WHERE Id = @Id;

    UPDATE Inv.StockAdjustmentDetails
    SET IsDeleted = 1
    WHERE StockAdjustmentId = @Id;
END
GO

-- Insert Stock Adjustment Detail
CREATE OR ALTER PROCEDURE StockAdjustmentDetail_Insert
    @Id INT OUTPUT,
    @StockAdjustmentId INT,
    @ItemId INT = NULL,
    @MedicineId INT = NULL,
    @SubServiceId INT = NULL,
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

    INSERT INTO Inv.StockAdjustmentDetails (
        StockAdjustmentId, ItemId, MedicineId, SubServiceId, Type, StockTypeId, Quantity,
        SaleValue, BranchId, CreatedById, CreatedOn, IsActive, IsDeleted
    )
    VALUES (
        @StockAdjustmentId, @ItemId, @MedicineId, @SubServiceId, @Type, @StockTypeId, @Quantity,
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

    UPDATE Inv.StockAdjustmentDetails
    SET IsDeleted = 1
    WHERE StockAdjustmentId = @StockAdjustmentId;
END
GO
