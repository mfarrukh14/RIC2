-- =============================================
-- Stock Audit Stored Procedures
-- =============================================

-- =============================================
-- StockAudit_Search
-- =============================================
IF OBJECT_ID('dbo.StockAudit_Search', 'P') IS NOT NULL
    DROP PROCEDURE dbo.StockAudit_Search;
GO

CREATE PROCEDURE dbo.StockAudit_Search
    @BranchId INT = NULL,
    @StoreId INT = NULL,
    @ItemTypeId INT = NULL,
    @StockTypeId INT = NULL,
    @ItemIds NVARCHAR(MAX) = NULL, -- Comma-separated INTs
    @ManufacturerIds NVARCHAR(MAX) = NULL -- Comma-separated INTs
AS
BEGIN
    SET NOCOUNT ON;

    -- Create temp tables for multi-value parameters
    CREATE TABLE #ItemIds (ItemId INT);
    CREATE TABLE #ManufacturerIds (ManufacturerId INT);

    -- Parse ItemIds
    IF @ItemIds IS NOT NULL AND @ItemIds != ''
    BEGIN
        INSERT INTO #ItemIds (ItemId)
        SELECT TRY_CAST(value AS INT)
        FROM STRING_SPLIT(@ItemIds, ',')
        WHERE TRY_CAST(value AS INT) IS NOT NULL;
    END

    -- Parse ManufacturerIds
    IF @ManufacturerIds IS NOT NULL AND @ManufacturerIds != ''
    BEGIN
        INSERT INTO #ManufacturerIds (ManufacturerId)
        SELECT TRY_CAST(value AS INT)
        FROM STRING_SPLIT(@ManufacturerIds, ',')
        WHERE TRY_CAST(value AS INT) IS NOT NULL;
    END

    -- Base the list on actual stock on hand (Inv.Stocks) so @BranchId/@StoreId filters
    -- mean something and TotalItems reflects real quantities instead of hardcoded zeros.
    -- Stock type comes from the most recent active inventory receipt for this item+store,
    -- same technique Stock_Search's fallback query uses - Inv.Items has no StockTypeId of
    -- its own, so joining Items directly to Inv.StockTypes (the previous bug) is meaningless.
    SELECT
        i.Id AS ItemId,
        i.Name AS ItemName,
        COALESCE(st.Name, 'Regular') AS StockType,
        CAST(ISNULL(s.TotalItems, 0) AS FLOAT) AS TotalItems,
        CAST(0 AS FLOAT) AS QtyOnShelf,
        CAST(0 AS FLOAT) AS Difference,
        CAST(COALESCE(s.MinimumPanicLevel, i.MinimumPanicLevel, 0) AS FLOAT) AS MPL,
        CAST(ISNULL(i.RetailPrice, 0) AS DECIMAL(18,2)) AS SalePrice,
        CAST(ISNULL(i.QuantityPerPacket, 0) AS FLOAT) AS QuantityPerPacket,
        s.ModifiedOn
    FROM Inv.Stocks s
    INNER JOIN Inv.Items i ON s.ItemId = i.Id
    OUTER APPLY
    (
        SELECT TOP 1 inv.StockTypeId
        FROM Inv.InventoryDetails details
        INNER JOIN Inv.Inventories inv ON details.InventoryId = inv.Id
        WHERE details.ItemId = s.ItemId
          AND inv.StoreId = s.StoreId
          AND inv.IsActive = 1
        ORDER BY COALESCE(inv.ModifiedOn, inv.CreatedOn) DESC, inv.Id DESC
    ) latestInventory
    LEFT JOIN Inv.StockTypes st ON latestInventory.StockTypeId = st.Id
    WHERE s.IsActive = 1
        AND (@BranchId IS NULL OR s.BranchId = @BranchId)
        AND (@StoreId IS NULL OR s.StoreId = @StoreId)
        AND (@ItemTypeId IS NULL OR i.ItemTypeId = @ItemTypeId)
        AND (@StockTypeId IS NULL OR latestInventory.StockTypeId = @StockTypeId)
        AND (NOT EXISTS(SELECT 1 FROM #ItemIds) OR i.Id IN (SELECT ItemId FROM #ItemIds))
        AND (NOT EXISTS(SELECT 1 FROM #ManufacturerIds) OR i.BrandId IN (SELECT ManufacturerId FROM #ManufacturerIds))
    ORDER BY i.Name;

    DROP TABLE #ItemIds;
    DROP TABLE #ManufacturerIds;
END
GO

-- =============================================
-- StockAudit_Insert
-- =============================================
IF OBJECT_ID('dbo.StockAudit_Insert', 'P') IS NOT NULL
    DROP PROCEDURE dbo.StockAudit_Insert;
GO

CREATE PROCEDURE dbo.StockAudit_Insert
    @StoreId INT,
    @BranchId INT,
    @AuditDate DATETIME,
    @Notes NVARCHAR(MAX) = NULL,
    @CreatedById INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO Inv.StockAudits (
        StoreId,
        BranchId,
        AuditDate,
        Notes,
        IsActive,
        CreatedById,
        CreatedOn
    )
    VALUES (
        @StoreId,
        @BranchId,
        @AuditDate,
        @Notes,
        1,
        @CreatedById,
        GETDATE()
    );
    
    DECLARE @NewId INT = SCOPE_IDENTITY();
    
    SELECT 
        Id,
        StoreId,
        BranchId,
        AuditDate,
        Notes,
        IsActive,
        CreatedById,
        CreatedOn,
        ModifiedById,
        ModifiedOn
    FROM Inv.StockAudits
    WHERE Id = @NewId;
END
GO

-- =============================================
-- StockAudit_GetAll
-- History list of past stock audits (Date/Store/Remarks/CreatedOn), matching the
-- old system's SP_GET_StockAudit - that proc never did any item-level comparison,
-- it was purely a browsable log of previously-submitted audits. StockAudit_Search
-- above (QtyOnShelf/Difference) has no equivalent in the old system at all; this
-- proc is what actually matches "how the old one worked" for Stock Audit.
-- =============================================
IF OBJECT_ID('dbo.StockAudit_GetAll', 'P') IS NOT NULL
    DROP PROCEDURE dbo.StockAudit_GetAll;
GO

CREATE PROCEDURE dbo.StockAudit_GetAll
    @BranchId INT = NULL,
    @StoreId INT = NULL,
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        sa.Id,
        sa.AuditDate,
        sa.StoreId,
        s.StoreName,
        sa.BranchId,
        b.Name AS BranchName,
        sa.Notes AS Remarks,
        sa.IsActive,
        sa.CreatedById,
        sa.CreatedOn,
        sa.ModifiedById,
        sa.ModifiedOn
    FROM Inv.StockAudits sa
    LEFT JOIN Inv.PharmacyStores s ON sa.StoreId = s.StoreId
    LEFT JOIN Inv.Branches b ON sa.BranchId = b.Id
    WHERE sa.IsActive = 1
        AND (@BranchId IS NULL OR sa.BranchId = @BranchId)
        AND (@StoreId IS NULL OR sa.StoreId = @StoreId)
        AND (@StartDate IS NULL OR sa.AuditDate >= @StartDate)
        AND (@EndDate IS NULL OR sa.AuditDate <= @EndDate)
    ORDER BY sa.AuditDate DESC, sa.Id DESC;
END
GO

PRINT 'Stock Audit stored procedures created successfully';
