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
    @BranchId UNIQUEIDENTIFIER = NULL,
    @StoreId UNIQUEIDENTIFIER = NULL,
    @ItemTypeId INT = NULL,
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
    
    -- Get stock items with audit information
    SELECT DISTINCT
        i.Id AS ItemId,
        i.Name AS ItemName,
        st.StockTypeName AS StockType,
        CAST(0 AS FLOAT) AS TotalItems,
        CAST(0 AS FLOAT) AS QtyOnShelf,
        CAST(0 AS FLOAT) AS Difference,
        ISNULL(i.MinimumPanicLevel, 0) AS MPL,
        ISNULL(i.RetailPrice, 0) AS SalePrice,
        ISNULL(i.QuantityPerPacket, 0) AS QuantityPerPacket,
        i.ModifiedOn
    FROM dbo.Items i
    LEFT JOIN dbo.StockTypes st ON i.ItemTypeId = st.StockTypeId
    WHERE 
        (@ItemTypeId IS NULL OR i.ItemTypeId = @ItemTypeId)
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
    @StoreId UNIQUEIDENTIFIER,
    @BranchId UNIQUEIDENTIFIER,
    @StockAuditDate DATETIME,
    @Remarks NVARCHAR(MAX) = NULL,
    @CreatedById UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @NewId UNIQUEIDENTIFIER = NEWID();
    
    INSERT INTO dbo.StockAudits (
        Id,
        StoreId,
        BranchId,
        StockAuditDate,
        Remarks,
        IsActive,
        CreatedById,
        CreatedOn,
        IsDeleted
    )
    VALUES (
        @NewId,
        @StoreId,
        @BranchId,
        @StockAuditDate,
        @Remarks,
        1,
        @CreatedById,
        GETDATE(),
        0
    );
    
    SELECT 
        Id,
        StoreId,
        BranchId,
        StockAuditDate,
        Remarks,
        IsActive,
        CreatedById,
        CreatedOn,
        ModifiedById,
        ModifiedOn,
        IsDeleted
    FROM dbo.StockAudits
    WHERE Id = @NewId;
END
GO

PRINT 'Stock Audit stored procedures created successfully';
