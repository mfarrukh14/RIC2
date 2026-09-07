SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.StockValueItems_GetReport
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL,
    @Store NVARCHAR(255) = NULL,
    @ItemType NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        COALESCE(s.StoreName, 'Unassigned Store') AS StoreName,
        i.Name AS Name,
        gi.BatchNo AS BatchNo,
        SUM(COALESCE(gi.RemainingQuantity, gi.TotalItem, 0)) AS TotalItems,
        CAST(AVG(CAST(COALESCE(gi.UnitBuyingPrice, 0) AS DECIMAL(18, 2))) AS DECIMAL(18, 2)) AS UnitPurchaseRate,
        SUM(COALESCE(gi.TotalBuyingPrice, 0)) AS TotalPurchaseRate,
        CAST(AVG(CAST(COALESCE(gi.UnitSellingPrice, 0) AS DECIMAL(18, 2))) AS DECIMAL(18, 2)) AS UnitSaleRate,
        SUM(COALESCE(gi.TotalSellingPrice, 0)) AS TotalSaleRate
    FROM Inv.GRNItems gi
    INNER JOIN Inv.Items i ON gi.ItemId = i.Id
    INNER JOIN Inv.GoodsReceivingNotes grn ON gi.GRNId = grn.Id
    LEFT JOIN Inv.PharmacyStores s ON grn.StoreId = s.StoreId
    LEFT JOIN Inv.ItemTypes it ON i.ItemTypeId = it.Id
    WHERE (@StartDate IS NULL OR grn.DateAndTime >= @StartDate)
      AND (@EndDate IS NULL OR grn.DateAndTime <= @EndDate)
      AND (@Store IS NULL OR s.StoreName = @Store)
      AND (@ItemType IS NULL OR it.Name = @ItemType)
      AND gi.BatchNo IS NOT NULL
    GROUP BY COALESCE(s.StoreName, 'Unassigned Store'), i.Name, gi.BatchNo
    ORDER BY COALESCE(s.StoreName, 'Unassigned Store'), i.Name, gi.BatchNo;
END;
GO

CREATE OR ALTER PROCEDURE dbo.GRN_GetReportByBatch
    @BatchNo NVARCHAR(255),
    @ItemName NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        grn.InvoiceNo AS InventoryNo,
        'System' AS EnteredBy,
        grn.DateAndTime,
        COALESCE(po.PONumber, CAST(grn.PurchaseOrderId AS NVARCHAR(50))) AS PONumber,
        '' AS PODate,
        COALESCE(po.ManualPONumber, '') AS ManualPONumber,
        COALESCE(st.Name, '') AS StockType,
        'Regular' AS Regular,
        COALESCE(s.StoreName, 'Unassigned Store') AS StoreName,
        COALESCE(v.Name, '') AS VendorName,
        COALESCE(v.Address, '') AS VendorAddress,
        COALESCE(v.Email, '') AS VendorEmail,
        COALESCE(v.CNo, '') AS VendorContactNo
    FROM Inv.GoodsReceivingNotes grn
    INNER JOIN Inv.GRNItems gi ON grn.Id = gi.GRNId
    INNER JOIN Inv.Items i ON gi.ItemId = i.Id
    LEFT JOIN Inv.PurchaseOrders po ON grn.PurchaseOrderId = po.PurchaseOrderId
    LEFT JOIN Inv.StockTypes st ON grn.StockTypeId = st.Id
    LEFT JOIN Inv.PharmacyStores s ON grn.StoreId = s.StoreId
    LEFT JOIN Inv.Vendors v ON grn.VendorId = v.Id
    WHERE gi.BatchNo = @BatchNo
      AND i.Name = @ItemName;

    SELECT
        i.Name AS Items,
        COALESCE(m.Name, '') AS Mfr,
        gi.MfgDate,
        gi.ExpiryDate AS ExpDate,
        gi.BatchNo,
        gi.NoOfBoxes AS Boxes,
        gi.NoOfPackets AS Packs,
        gi.ItemPerPacket AS QtyPerPack,
        gi.TotalItem AS TotalQty,
        gi.PackQuantity AS PackQty,
        gi.TotalBuyingPrice AS TotalPrice,
        gi.UnitBuyingPrice AS UnitPrice,
        gi.AdvanceTaxPercentage AS AdvanceTax,
        gi.AdvanceTaxAmount,
        gi.UnitSellingPrice AS UnitSalePrice,
        CAST(CASE WHEN gi.RetailCharges = 1 THEN 1 ELSE 0 END AS DECIMAL(18, 2)) AS RetailCharges,
        gi.RetailChargesAmount,
        CAST(CASE WHEN gi.GSTCharges = 1 THEN 1 ELSE 0 END AS DECIMAL(18, 2)) AS GSTCharges,
        gi.GSTChargesAmount,
        gi.TotalSellingPrice AS TotalSalePrice,
        gi.ProfitMarginPerItem AS Margin,
        gi.TotalBuyingPrice AS Amount,
        CAST(COALESCE(gi.DiscountAmount, 0) AS DECIMAL(18, 2)) AS Discount,
        gi.TotalBuyingPrice - COALESCE(gi.DiscountAmount, 0) AS Total
    FROM Inv.GRNItems gi
    INNER JOIN Inv.Items i ON gi.ItemId = i.Id
    LEFT JOIN Inv.PharmacyManufacturers m ON gi.ManufacturerId = m.Id
    WHERE gi.BatchNo = @BatchNo
      AND i.Name = @ItemName;
END;
GO

-- Paginated (@PageNumber/@PageSize) to match what InventoryManagement.Api's
-- StockWithExpiryService.cs actually calls, and structured to filter/sort/
-- paginate on the cheap columns first, then run the expensive per-row lookups
-- (batch OUTER APPLY, rack/space-allocation join, transition-quantity subquery)
-- only against the resulting page - not the full filtered set (tens of
-- thousands of rows for a branch), which previously took ~20s+ for one page.
CREATE OR ALTER PROCEDURE dbo.StockWithExpiry_GetAll
    @BranchId INT = NULL,
    @StoreId INT = NULL,
    @ItemType VARCHAR(50) = NULL,
    @ItemId INT = NULL,
    @CategoryId INT = NULL,
    @IsExpensiveItem BIT = NULL,
    @IsFridgeItem BIT = NULL,
    @MinimumPanicLevelOnly BIT = 0,
    @PageNumber INT = 1,
    @PageSize INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (CASE WHEN @PageNumber < 1 THEN 0 ELSE @PageNumber - 1 END) * (CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END);
    DECLARE @Take INT = CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END;

    ;WITH Filtered AS (
        SELECT
            id.Id,
            id.InventoryId,
            i.Id AS ItemId,
            i.Name AS ItemName,
            inv.StoreId,
            st.StoreName,
            id.ExpiryDate,
            CAST(COALESCE(id.TotalItems, 0) AS INT) AS Quantity,
            ISNULL(sty.Name, 'Regular') AS StockType,
            CAST(ISNULL(i.MinimumPanicLevel, 0) AS FLOAT) AS MPL,
            CASE
                WHEN COALESCE(id.TotalItems, 0) <= ISNULL(i.MinimumPanicLevel, 0) THEN 1
                ELSE 0
            END AS IsBelowMPL,
            it.Name AS ItemType,
            i.IsExpensiveItem,
            i.IsFridgeItem,
            i.CategoryId,
            inv.CreatedOn,
            inv.CreatedById,
            inv.ModifiedOn,
            inv.ModifiedById
        FROM Inv.InventoryDetails id
        INNER JOIN Inv.Inventories inv ON id.InventoryId = inv.Id
        INNER JOIN Inv.Items i ON id.ItemId = i.Id
        INNER JOIN Inv.PharmacyStores st ON inv.StoreId = st.StoreId
        LEFT JOIN Inv.ItemTypes it ON i.ItemTypeId = it.Id
        LEFT JOIN Inv.StockTypes sty ON inv.StockTypeId = sty.Id
        WHERE (@BranchId IS NULL OR inv.BranchId = @BranchId)
          AND (@StoreId IS NULL OR inv.StoreId = @StoreId)
          AND (@ItemType IS NULL OR it.Name = @ItemType)
          AND (@ItemId IS NULL OR i.Id = @ItemId)
          AND (@CategoryId IS NULL OR i.CategoryId = @CategoryId)
          AND (@IsExpensiveItem IS NULL OR i.IsExpensiveItem = @IsExpensiveItem)
          AND (@IsFridgeItem IS NULL OR i.IsFridgeItem = @IsFridgeItem)
          AND (@MinimumPanicLevelOnly = 0 OR COALESCE(id.TotalItems, 0) <= ISNULL(i.MinimumPanicLevel, 0))
          AND COALESCE(id.TotalItems, 0) > 0
          AND inv.IsActive = 1
    ),
    Paged AS (
        SELECT *, COUNT(*) OVER() AS TotalCount
        FROM Filtered
        ORDER BY IsBelowMPL DESC, ExpiryDate ASC, ItemName
        OFFSET @Offset ROWS FETCH NEXT @Take ROWS ONLY
    )
    SELECT
        Paged.Id,
        Paged.ItemId,
        Paged.ItemName,
        Paged.StoreId,
        Paged.StoreName,
        COALESCE(ii.Batch, ii.SysBatchNo, CAST(Paged.Id AS NVARCHAR(50))) AS BatchNumber,
        Paged.ExpiryDate,
        Paged.Quantity,
        Paged.StockType,
        sa.RackId,
        r.Name AS RackName,
        sa.RackRowId,
        rr.Name AS RowNumber,
        sa.RackColumnId,
        rc.Name AS ColumnNumber,
        sa.RackDrawrId AS RackDrawerId,
        rd.Name AS DrawerNumber,
        Paged.MPL,
        Paged.IsBelowMPL,
        Paged.ItemType,
        Paged.IsExpensiveItem,
        Paged.IsFridgeItem,
        Paged.CategoryId,
        (
            SELECT ISNULL(SUM(COALESCE(id2.TotalItems, 0)), 0)
            FROM Inv.InventoryDetails id2
            INNER JOIN Inv.Inventories inv2 ON id2.InventoryId = inv2.Id
            WHERE id2.ItemId = Paged.ItemId
              AND inv2.StoreId = Paged.StoreId
        ) AS TotalItemsInTransition,
        Paged.CreatedOn,
        Paged.CreatedById,
        Paged.ModifiedOn,
        Paged.ModifiedById,
        Paged.TotalCount
    FROM Paged
    OUTER APPLY (
        SELECT TOP 1 ii.Batch, ii.SysBatchNo
        FROM Inv.InventoryItems ii
        WHERE ii.InventoryId = Paged.InventoryId
          AND ii.ItemId = Paged.ItemId
          AND ii.IsActive = 1
          AND (ii.IsDeleted = 0 OR ii.IsDeleted IS NULL)
        ORDER BY ii.Id DESC
    ) ii
    LEFT JOIN Inv.SpaceAllocations sa ON sa.ItemId = Paged.ItemId AND sa.IsActive = 1 AND sa.IsDeleted = 0
    LEFT JOIN Inv.Racks r ON sa.RackId = r.Id
    LEFT JOIN Inv.RackRows rr ON sa.RackRowId = rr.Id
    LEFT JOIN Inv.RackColumns rc ON sa.RackColumnId = rc.Id
    LEFT JOIN Inv.RackDrawrs rd ON sa.RackDrawrId = rd.Id
    ORDER BY
        Paged.IsBelowMPL DESC,
        Paged.ExpiryDate ASC,
        Paged.ItemName;
END;
GO